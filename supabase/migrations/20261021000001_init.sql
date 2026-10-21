-- RIFT RUMBLE — esquema inicial de persistencia (Fase 6).
--
-- Principios de seguridad:
--   * El cliente NUNCA escribe directamente en las tablas: no hay políticas de
--     INSERT/UPDATE/DELETE. Todo cambio pasa por funciones SECURITY DEFINER que
--     validan los datos y calculan las recompensas en el servidor.
--   * Cada usuario solo puede LEER sus propias filas (RLS con auth.uid()).
--   * Los resultados son idempotentes: (user_id, client_nonce) es único, así que
--     reenviar el mismo resultado no duplica recompensas.
--   * La partida se simula en el cliente: las validaciones son de verosimilitud,
--     no una prueba de que la partida ocurrió (ver docs/07).

-- ---------------------------------------------------------------------------
-- Catálogo de misiones (lo mantiene el servidor; el cliente solo lo lee).
-- ---------------------------------------------------------------------------
create table public.missions (
  id               text primary key,
  waves_total      int  not null check (waves_total > 0),
  base_hp          int  not null check (base_hp > 0),
  -- Duración mínima verosímil de una victoria, en segundos.
  min_victory_secs int  not null check (min_victory_secs > 0),
  first_clear_reward int not null default 50,
  per_star_reward    int not null default 20,
  replay_reward      int not null default 5
);

insert into public.missions (id, waves_total, base_hp, min_victory_secs)
values ('w1_m1', 5, 20, 150);

-- ---------------------------------------------------------------------------
-- Datos por jugador
-- ---------------------------------------------------------------------------
create table public.profiles (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  created_at   timestamptz not null default now()
);

create table public.wallets (
  user_id uuid primary key references auth.users (id) on delete cascade,
  shards  int  not null default 0 check (shards >= 0)
);

create table public.campaign_progress (
  user_id        uuid not null references auth.users (id) on delete cascade,
  mission_id     text not null references public.missions (id),
  best_stars     int  not null default 0 check (best_stars between 0 and 3),
  best_time_secs int,
  victories      int  not null default 0,
  attempts       int  not null default 0,
  updated_at     timestamptz not null default now(),
  primary key (user_id, mission_id)
);

create table public.match_results (
  id            bigint generated always as identity primary key,
  user_id       uuid not null references auth.users (id) on delete cascade,
  mission_id    text not null references public.missions (id),
  client_nonce  uuid not null,
  outcome       text not null check (outcome in ('victory', 'defeat')),
  stars         int  not null check (stars between 0 and 3),
  base_hp       int  not null,
  waves_reached int  not null,
  duration_secs int  not null,
  stats         jsonb not null default '{}'::jsonb,
  reward        int  not null default 0,
  created_at    timestamptz not null default now(),
  unique (user_id, client_nonce)
);

create index match_results_user_created on public.match_results (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- RLS: solo lectura de lo propio. Sin políticas de escritura.
-- ---------------------------------------------------------------------------
alter table public.missions          enable row level security;
alter table public.profiles          enable row level security;
alter table public.wallets           enable row level security;
alter table public.campaign_progress enable row level security;
alter table public.match_results     enable row level security;

create policy "missions: lectura para usuarios" on public.missions
  for select to authenticated using (true);
create policy "profiles: leer el propio" on public.profiles
  for select to authenticated using (user_id = (select auth.uid()));
create policy "wallets: leer el propio" on public.wallets
  for select to authenticated using (user_id = (select auth.uid()));
create policy "progress: leer el propio" on public.campaign_progress
  for select to authenticated using (user_id = (select auth.uid()));
create policy "results: leer los propios" on public.match_results
  for select to authenticated using (user_id = (select auth.uid()));

-- Defensa adicional: quitar privilegios de escritura directa a los roles de cliente.
revoke insert, update, delete on public.missions, public.profiles, public.wallets,
  public.campaign_progress, public.match_results from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Alta automática de perfil y monedero al crear un usuario (incluidos anónimos).
-- ---------------------------------------------------------------------------
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, 'Guardián-' || upper(substr(replace(new.id::text, '-', ''), 1, 4)));
  insert into public.wallets (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Envío de un resultado de partida (única vía para ganar progreso y monedas).
-- Devuelve el resultado procesado; si el nonce ya existía, devuelve el anterior
-- sin volver a dar recompensa.
-- ---------------------------------------------------------------------------
create function public.submit_match_result(
  p_mission_id    text,
  p_client_nonce  uuid,
  p_outcome       text,
  p_base_hp       int,
  p_waves_reached int,
  p_duration_secs int,
  p_stats         jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user     uuid := auth.uid();
  v_mission  public.missions%rowtype;
  v_existing public.match_results%rowtype;
  v_stars    int := 0;
  v_ratio    numeric;
  v_prev     public.campaign_progress%rowtype;
  v_reward   int := 0;
  v_first    boolean := false;
  v_recent   int;
  v_shards   int;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  -- Idempotencia: el mismo nonce devuelve el resultado ya registrado.
  select * into v_existing from public.match_results
    where user_id = v_user and client_nonce = p_client_nonce;
  if found then
    select shards into v_shards from public.wallets where user_id = v_user;
    return jsonb_build_object('duplicate', true, 'stars', v_existing.stars,
      'reward', v_existing.reward, 'shards', v_shards);
  end if;

  -- Límite de envíos (evita inundar la tabla).
  select count(*) into v_recent from public.match_results
    where user_id = v_user and created_at > now() - interval '1 hour';
  if v_recent >= 60 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  -- Validaciones de verosimilitud.
  select * into v_mission from public.missions where id = p_mission_id;
  if not found then
    raise exception 'unknown_mission' using errcode = 'P0001';
  end if;
  if p_outcome not in ('victory', 'defeat') then
    raise exception 'invalid_outcome' using errcode = 'P0001';
  end if;
  if p_base_hp < 0 or p_base_hp > v_mission.base_hp
     or p_waves_reached < 0 or p_waves_reached > v_mission.waves_total
     or p_duration_secs < 0 or p_duration_secs > 3 * 3600 then
    raise exception 'implausible_result' using errcode = 'P0001';
  end if;
  if p_outcome = 'victory' and (p_base_hp = 0
     or p_waves_reached <> v_mission.waves_total
     or p_duration_secs < v_mission.min_victory_secs) then
    raise exception 'implausible_victory' using errcode = 'P0001';
  end if;
  if p_outcome = 'defeat' and p_base_hp <> 0 then
    raise exception 'implausible_defeat' using errcode = 'P0001';
  end if;

  -- Las estrellas las calcula el servidor (mismas reglas que el juego).
  if p_outcome = 'victory' then
    v_ratio := p_base_hp::numeric / v_mission.base_hp;
    v_stars := case when v_ratio >= 0.9 then 3 when v_ratio >= 0.5 then 2 else 1 end;
  end if;

  -- Recompensa: primera victoria, mejora de estrellas o repetición.
  select * into v_prev from public.campaign_progress
    where user_id = v_user and mission_id = p_mission_id;
  if p_outcome = 'victory' then
    if not found or v_prev.victories = 0 then
      v_first := true;
      v_reward := v_mission.first_clear_reward + v_stars * v_mission.per_star_reward;
    elsif v_stars > v_prev.best_stars then
      v_reward := (v_stars - v_prev.best_stars) * v_mission.per_star_reward;
    else
      v_reward := v_mission.replay_reward;
    end if;
  end if;

  insert into public.match_results (user_id, mission_id, client_nonce, outcome, stars,
    base_hp, waves_reached, duration_secs, stats, reward)
  values (v_user, p_mission_id, p_client_nonce, p_outcome, v_stars, p_base_hp,
    p_waves_reached, p_duration_secs, coalesce(p_stats, '{}'::jsonb), v_reward);

  insert into public.campaign_progress as cp (user_id, mission_id, best_stars, best_time_secs,
    victories, attempts, updated_at)
  values (v_user, p_mission_id, v_stars,
    case when p_outcome = 'victory' then p_duration_secs end,
    case when p_outcome = 'victory' then 1 else 0 end, 1, now())
  on conflict (user_id, mission_id) do update set
    best_stars = greatest(cp.best_stars, excluded.best_stars),
    best_time_secs = case
      when excluded.best_time_secs is null then cp.best_time_secs
      when cp.best_time_secs is null then excluded.best_time_secs
      else least(cp.best_time_secs, excluded.best_time_secs) end,
    victories = cp.victories + excluded.victories,
    attempts = cp.attempts + 1,
    updated_at = now();

  update public.wallets set shards = shards + v_reward where user_id = v_user
    returning shards into v_shards;

  return jsonb_build_object('duplicate', false, 'stars', v_stars, 'reward', v_reward,
    'first_clear', v_first, 'shards', v_shards);
end;
$$;

-- Cambiar el nombre visible (validado en el servidor).
create function public.set_display_name(p_name text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if char_length(trim(p_name)) not between 3 and 24 then
    raise exception 'invalid_name' using errcode = 'P0001';
  end if;
  update public.profiles set display_name = trim(p_name) where user_id = auth.uid();
end;
$$;

-- Solo usuarios autenticados (incluidos anónimos) pueden llamar a las funciones.
revoke execute on function public.submit_match_result(text, uuid, text, int, int, int, jsonb) from public, anon;
grant  execute on function public.submit_match_result(text, uuid, text, int, int, int, jsonb) to authenticated;
revoke execute on function public.set_display_name(text) from public, anon;
grant  execute on function public.set_display_name(text) to authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
