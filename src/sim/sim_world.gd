## Simulación pura de una partida.
##
## - No depende de Node, del árbol de escena ni de la proyección isométrica.
## - Avanza a tick fijo (`step()`); la vista lee el estado e interpola.
## - Enemigos y proyectiles se guardan en arrays empaquetados (SoA) con
##   reutilización de huecos.
## - Comunica hacia fuera mediante eventos que el consumidor recoge con `drain_events()`.
## - Todo cambio de estado del jugador (construir, mejorar, vender, lanzar
##   oleada) es un comando validado aquí: la interfaz no modifica el estado.
extends RefCounted

const SimPath := preload("res://src/sim/sim_path.gd")
const SimEffects := preload("res://src/sim/sim_effects.gd")
const SimHeroes := preload("res://src/sim/sim_heroes.gd")
const SimObjects := preload("res://src/sim/sim_objects.gd")

const TICK_RATE := 30
const DT := 1.0 / TICK_RATE

## La armadura no reduce este tipo de daño (Arcano).
const ARMOR_IGNORING_TYPE := &"magic"
## La armadura reduce este tipo a la mitad (Energético; decisión G-5).
const ARMOR_HALVING_TYPE := &"energy"

enum Outcome { PLAYING, VICTORY, DEFEAT }

## Segundos entre oleadas antes de que la siguiente empiece sola.
const BETWEEN_WAVES := 20.0
## Oro por segundo adelantado al lanzar una oleada antes de tiempo.
const EARLY_CALL_GOLD_PER_SECOND := 1.0

var paths: Array = []  # Array[SimPath], una por ruta
## Carriles por ruta: lane_paths[ruta][carril]. El carril 0 es la línea central;
## los demás, desplazados a cada lado según el ancho del camino.
var lane_paths: Array = []
var lane_offsets := PackedFloat32Array([0.0])
## Ruta principal (compatibilidad con el código de una sola ruta).
var path: SimPath:
	get:
		return paths[0]
var rng := RandomNumberGenerator.new()
var tick := 0
var base_hp := 20
var gold := 0
var outcome := Outcome.PLAYING
var events: Array[Dictionary] = []
var effects: SimEffects
var heroes: SimHeroes
var objects: SimObjects
## Sinergias activas (SynergyDef); las evalúa el sistema de efectos.
var synergies: Array = []
## Tamaño del mapa en casillas (limita el movimiento de los héroes).
var map_size := Vector2i.ZERO

# --- Contenido (opcional: los tests de bajo nivel funcionan sin él) ---------
var content  # ContentDB
var mission: MissionDef

# --- Enemigos (SoA) ---------------------------------------------------------
var e_alive := PackedByteArray()
var e_id := PackedInt32Array()     # identificador único; detecta huecos reutilizados
var e_route := PackedInt32Array()
var e_lane := PackedInt32Array()
var e_dist := PackedFloat32Array() # distancia recorrida sobre su ruta
var e_speed := PackedFloat32Array()  # casillas por segundo (base)
var e_hp := PackedFloat32Array()
var e_max_hp := PackedFloat32Array()
var e_armor := PackedFloat32Array()
var e_bounty := PackedInt32Array()
var e_base_damage := PackedInt32Array()
var e_pos := PackedVector2Array()
var e_def: Array = []              # EnemyDef o null
var e_blocker := PackedInt32Array()  # héroe que lo bloquea (-1 = ninguno)
var e_melee_damage := PackedFloat32Array()
var e_melee_ticks := PackedInt32Array()  # intervalo entre golpes al héroe
var e_melee_cd := PackedInt32Array()
var e_can_revive := PackedByteArray()
var e_timer := PackedInt32Array()        # núcleo: ticks para revivir · invocador: para invocar
var e_revive_into: Array = []            # núcleo: EnemyDef que revive (o null)
var enemy_count := 0
var _enemy_free: Array[int] = []

# --- Proyectiles (SoA) ------------------------------------------------------
var p_alive := PackedByteArray()
var p_pos := PackedVector2Array()
var p_target_slot := PackedInt32Array()
var p_target_id := PackedInt32Array()
var p_aim := PackedVector2Array()  # última posición conocida del objetivo
var p_speed := PackedFloat32Array()
var p_damage := PackedFloat32Array()
var p_pierce := PackedFloat32Array()
var p_bounces := PackedInt32Array()
var p_tower_def: Array = []        # TowerDef que lo disparó (tipo, efecto, rebote)
var p_hit_ids: Array = []          # ids ya alcanzados (un rebote no repite objetivo)
var p_hero := PackedInt32Array()   # héroe que lo disparó (-1 = torre)
var p_via_portal := PackedByteArray()  # 1 = aún viaja hacia la entrada del portal
var p_portal_exit := PackedVector2Array()
var p_portal_mult := PackedFloat32Array()
var projectile_count := 0
var _projectile_free: Array[int] = []

# --- Torres -----------------------------------------------------------------
## Cada torre: { def: TowerDef, level: int, pos: Vector2, spot: int,
##               cooldown_ticks: int, invested: int }
var towers: Array[Dictionary] = []
var build_spots := PackedVector2Array()

# --- Oleadas ----------------------------------------------------------------
var wave_index := -1          # última oleada lanzada (-1 = ninguna)
var wave_active := false
## Ticks hasta que la siguiente oleada empiece sola (-1 = espera al jugador).
var next_wave_ticks := -1
## Estadísticas de la partida (pantalla de resultados).
var stats := {kills = 0, leaks = 0, gold_earned = 0, gold_spent = 0, towers_built = 0,
	hero_kos = 0, abilities_used = 0, early_bonus = 0}
var _spawn_queue: Array = []  # [tick, EnemyDef, ruta], ordenada por tick

var _next_id := 1
## Identificadores estables de torres y portales (para que la vista los siga
## aunque cambie su contenido).
var _next_uid := 1


func new_uid() -> int:
	_next_uid += 1
	return _next_uid


## `routes`: una ruta (PackedVector2Array) o un Array de rutas.
func _init(routes, seed_value: int = 0) -> void:
	if routes is PackedVector2Array:
		routes = [routes]
	for r in routes:
		paths.append(SimPath.new(r))
	_build_lanes(1.0)
	rng.seed = seed_value
	effects = SimEffects.new()
	heroes = SimHeroes.new()
	objects = SimObjects.new()


## Carriles a ±1/4 del ancho del camino (con 2 casillas: los centros de ambas).
func _build_lanes(path_width: float) -> void:
	var q := path_width * 0.25
	lane_offsets = PackedFloat32Array([0.0, -q, q])
	lane_paths.clear()
	for p: SimPath in paths:
		var lanes := []
		for off in lane_offsets:
			lanes.append(SimPath.new(SimPath.offset_points(p.points, off)))
		lane_paths.append(lanes)


## Configura una partida completa a partir de una misión y del mapa ya leído.
## `hero_ids`: héroes elegidos por el jugador (si se omite, los de la misión).
## `tower_ids`: equipo de torres elegido (si se omite, las de la misión).
func setup_mission(content_db, mission_def: MissionDef, map_def, hero_ids := PackedStringArray(),
		tower_ids := PackedStringArray()) -> void:
	allowed_towers = tower_ids if not tower_ids.is_empty() else mission_def.towers
	if allowed_towers.is_empty():  # sin equipo ni restricción (pruebas): todo el catálogo
		for id in content_db.towers:
			allowed_towers.append(String(id))
		allowed_towers.sort()
	content = content_db
	mission = mission_def
	gold = mission_def.start_gold
	base_hp = mission_def.base_hp
	build_spots = map_def.build_spots
	map_size = map_def.size
	_build_lanes(map_def.path_width)
	objects.setup(self, map_def)
	synergies = content_db.synergies.values()
	var chosen: PackedStringArray = hero_ids if not hero_ids.is_empty() else mission_def.heroes
	for i in chosen.size():
		var def: HeroDef = content_db.heroes[StringName(chosen[i])]
		var spawns: PackedVector2Array = map_def.hero_spawns if not map_def.hero_spawns.is_empty() 				else map_def.build_spots
		heroes.add_hero(def, spawns[i % spawns.size()])


func is_lost() -> bool:
	return outcome == Outcome.DEFEAT


func is_over() -> bool:
	return outcome != Outcome.PLAYING


## Devuelve los eventos acumulados desde la última llamada y los vacía.
func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out


# --- Comandos del jugador -------------------------------------------------------

func tower_at(spot: int) -> Dictionary:
	for t in towers:
		if t.spot == spot:
			return t
	return {}


## Torres que se pueden construir en esta partida (equipo elegido).
var allowed_towers := PackedStringArray()


func can_build(tower_id: StringName) -> bool:
	return mission == null or String(tower_id) in allowed_towers


func build(spot: int, tower_id: StringName) -> StringName:
	if is_over():
		return &"game_over"
	if spot < 0 or spot >= build_spots.size():
		return &"invalid_spot"
	if not objects.spot_open(spot):
		return &"spot_locked"
	if not tower_at(spot).is_empty():
		return &"occupied"
	if content == null or not content.towers.has(tower_id) or not can_build(tower_id):
		return &"unknown_tower"
	var def: TowerDef = content.towers[tower_id]
	var price: int = def.cost[0]
	if gold < price:
		return &"no_gold"
	gold -= price
	stats.gold_spent += price
	stats.towers_built += 1
	var t := place_tower(def, build_spots[spot], 1, spot)
	t.invested = price
	events.append({type = &"tower_built", spot = spot, tower = tower_id})
	return &"ok"


func upgrade_cost(spot: int) -> int:
	var t := tower_at(spot)
	if t.is_empty() or t.level >= t.def.max_level():
		return -1
	return t.def.cost[t.level]


func upgrade(spot: int) -> StringName:
	if is_over():
		return &"game_over"
	var t := tower_at(spot)
	if t.is_empty():
		return &"empty"
	var price := upgrade_cost(spot)
	if price < 0:
		return &"max_level"
	if gold < price:
		return &"no_gold"
	gold -= price
	stats.gold_spent += price
	t.level += 1
	t.invested += price
	events.append({type = &"tower_upgraded", spot = spot, level = t.level})
	return &"ok"


func sell_value(spot: int) -> int:
	var t := tower_at(spot)
	return -1 if t.is_empty() else floori(t.invested * t.def.sell_refund)


func sell(spot: int) -> StringName:
	if is_over():
		return &"game_over"
	var t := tower_at(spot)
	if t.is_empty():
		return &"empty"
	var refund := sell_value(spot)
	gold += refund  # no cuenta como oro ganado: es recuperar inversión
	towers.erase(t)
	events.append({type = &"tower_sold", spot = spot, refund = refund})
	return &"ok"


## Recoger una moneda con un toque.
func collect_coin(uid: int) -> StringName:
	if is_over():
		return &"game_over"
	return objects.collect(self, uid)


func move_hero(index: int, destination: Vector2) -> StringName:
	if is_over():
		return &"game_over"
	return heroes.move(self, index, destination)


func cast_ability(index: int, target: Vector2) -> StringName:
	if is_over():
		return &"game_over"
	return heroes.cast(self, index, target)


func waves_total() -> int:
	return 0 if mission == null else mission.waves.size()


func start_next_wave() -> StringName:
	if is_over():
		return &"game_over"
	if wave_active:
		return &"wave_active"
	if wave_index + 1 >= waves_total():
		return &"no_more_waves"
	if next_wave_ticks > 0:
		var bonus := ceili(next_wave_ticks / float(TICK_RATE) * EARLY_CALL_GOLD_PER_SECOND)
		_earn(bonus)
		stats.early_bonus += bonus
		events.append({type = &"early_call_bonus", gold = bonus})
	next_wave_ticks = -1
	wave_index += 1
	wave_active = true
	var wave: WaveDef = mission.waves[wave_index]
	for g in wave.enemies.size():
		var def: EnemyDef = content.enemies[StringName(wave.enemies[g])]
		var route: int = wave.route[g] if g < wave.route.size() else 0
		route = clampi(route, 0, paths.size() - 1)
		var first := tick + roundi(wave.start_delay[g] * TICK_RATE)
		var every := maxi(1, roundi(wave.spacing[g] * TICK_RATE))
		for i in wave.counts[g]:
			var lane := rng.randi_range(0, lane_offsets.size() - 1)
			_spawn_queue.append([first + i * every, def, route, lane])
	_spawn_queue.sort_custom(func(a, b): return a[0] < b[0])
	events.append({type = &"wave_started", index = wave_index})
	return &"ok"


# --- Creación directa (tests, modo estrés) --------------------------------------

## Enemigo genérico sin definición (tests de bajo nivel y estrés).
func spawn_enemy(hp: float, speed: float, start_dist: float = 0.0, route: int = 0, lane: int = 0) -> int:
	var slot := _alloc_enemy()
	e_def[slot] = null
	e_hp[slot] = hp
	e_max_hp[slot] = hp
	e_speed[slot] = speed
	e_armor[slot] = 0.0
	e_bounty[slot] = 0
	e_base_damage[slot] = 1
	e_melee_damage[slot] = 2.0
	e_melee_ticks[slot] = TICK_RATE
	e_can_revive[slot] = 0
	e_timer[slot] = 0
	e_revive_into[slot] = null
	_finish_spawn(slot, route, start_dist, lane)
	return slot


func spawn(def: EnemyDef, route: int = 0, start_dist: float = 0.0, lane: int = 0) -> int:
	var slot := _alloc_enemy()
	e_def[slot] = def
	e_hp[slot] = def.hp
	e_max_hp[slot] = def.hp
	e_speed[slot] = def.speed
	e_armor[slot] = def.armor
	e_bounty[slot] = def.bounty
	e_base_damage[slot] = def.base_damage
	e_melee_damage[slot] = def.melee_damage
	e_melee_ticks[slot] = maxi(1, roundi(def.melee_interval * TICK_RATE))
	e_can_revive[slot] = 1 if def.revive_core else 0
	e_timer[slot] = maxi(1, roundi(def.summon_interval * TICK_RATE)) if def.summon_enemy else 0
	e_revive_into[slot] = null
	_finish_spawn(slot, route, start_dist, lane)
	return slot


## Torre colocada sin pasar por la economía.
func place_tower(def: TowerDef, pos: Vector2, level := 1, spot := -1) -> Dictionary:
	var t := {uid = new_uid(), def = def, level = level, pos = pos, spot = spot, cooldown_ticks = 0, invested = 0}
	towers.append(t)
	return t


## Atajo de bajo nivel: torre genérica de un solo nivel (tests y estrés).
func add_tower(pos: Vector2, range_tiles: float, interval: float, damage: float,
		projectile_speed: float = 10.0) -> int:
	var def := TowerDef.new()
	def.id = &"generic"
	def.damage = PackedFloat32Array([damage])
	def.interval = PackedFloat32Array([interval])
	def.range_tiles = PackedFloat32Array([range_tiles])
	def.projectile_speed = projectile_speed
	place_tower(def, pos)
	return towers.size() - 1


func _alloc_enemy() -> int:
	if not _enemy_free.is_empty():
		return _enemy_free.pop_back()
	var slot := e_alive.size()
	e_alive.append(0)
	e_id.append(0)
	e_route.append(0)
	e_lane.append(0)
	e_dist.append(0.0)
	e_speed.append(0.0)
	e_hp.append(0.0)
	e_max_hp.append(0.0)
	e_armor.append(0.0)
	e_bounty.append(0)
	e_base_damage.append(0)
	e_pos.append(Vector2.ZERO)
	e_def.append(null)
	e_blocker.append(-1)
	e_can_revive.append(0)
	e_timer.append(0)
	e_revive_into.append(null)
	e_melee_damage.append(0.0)
	e_melee_ticks.append(TICK_RATE)
	e_melee_cd.append(0)
	return slot


func _finish_spawn(slot: int, route: int, start_dist: float, lane: int = 0) -> void:
	e_alive[slot] = 1
	e_id[slot] = _next_id
	_next_id += 1
	e_route[slot] = clampi(route, 0, paths.size() - 1)
	e_lane[slot] = clampi(lane, 0, lane_offsets.size() - 1)
	e_dist[slot] = start_dist
	e_pos[slot] = _enemy_path(slot).sample(start_dist)
	e_blocker[slot] = -1
	e_melee_cd[slot] = 0
	var def: EnemyDef = e_def[slot]
	effects.reset_slot(slot, def.weight if def else EnemyDef.Weight.LIGHT)
	enemy_count += 1
	events.append({type = &"enemy_spawned", slot = slot})


# --- Tick ------------------------------------------------------------------

func step() -> void:
	if is_over():
		return
	_spawn_due()
	_update_wave_timer()
	effects.step(self)
	_update_special_enemies()
	heroes.step(self)
	objects.step(self)
	_move_enemies()
	_update_towers()
	_update_projectiles()
	_check_wave_and_outcome()
	tick += 1


func _update_wave_timer() -> void:
	if next_wave_ticks > 0:
		next_wave_ticks -= 1
		if next_wave_ticks == 0:
			next_wave_ticks = -1
			start_next_wave()


## Núcleos de reaparición e invocadores (jefes y enemigos especiales).
func _update_special_enemies() -> void:
	for i in e_alive.size():
		if e_alive[i] == 0 or e_timer[i] <= 0:
			continue
		e_timer[i] -= 1
		if e_timer[i] > 0:
			continue
		if e_revive_into[i] != null:
			# El núcleo ha sobrevivido: el enemigo vuelve (una sola vez).
			var def: EnemyDef = e_revive_into[i]
			var route := e_route[i]
			var lane := e_lane[i]
			var dist := e_dist[i]
			events.append({type = &"core_expired", slot = i})
			_remove_enemy(i)
			var revived := spawn(def, route, dist, lane)
			e_hp[revived] = def.hp * def.revive_hp_ratio
			e_can_revive[revived] = 0
			events.append({type = &"enemy_revived", slot = revived})
		elif e_def[i] != null and e_def[i].summon_enemy:
			var def: EnemyDef = e_def[i]
			for k in def.summon_count:
				spawn(def.summon_enemy, e_route[i], maxf(e_dist[i] - 0.4 * (k + 1), 0.0),
						rng.randi_range(0, lane_offsets.size() - 1))
			e_timer[i] = maxi(1, roundi(def.summon_interval * TICK_RATE))
			events.append({type = &"enemy_summoned", slot = i, count = def.summon_count})


func _spawn_due() -> void:
	while not _spawn_queue.is_empty() and _spawn_queue[0][0] <= tick:
		var entry: Array = _spawn_queue.pop_front()
		# Un grupo asignado a un atajo aún cerrado entra por la ruta principal.
		var route: int = entry[2] if objects.route_open(entry[2]) else 0
		spawn(entry[1], route, 0.0, entry[3])


func _move_enemies() -> void:
	for i in e_alive.size():
		if e_alive[i] == 0 or effects.rooted[i] == 1 or e_blocker[i] >= 0:
			continue
		var p: SimPath = _enemy_path(i)
		var d := e_dist[i] + e_speed[i] * effects.speed_mult[i] * DT
		e_dist[i] = d
		if d >= p.length:
			base_hp -= e_base_damage[i]
			stats.leaks += 1
			events.append({type = &"enemy_leaked", slot = i, damage = e_base_damage[i]})
			_remove_enemy(i)
		else:
			e_pos[i] = p.sample(d)


func _enemy_path(slot: int) -> SimPath:
	return lane_paths[e_route[slot]][e_lane[slot]]


func _update_towers() -> void:
	for t_index in towers.size():
		_try_fire(towers[t_index], true)
	for profile in heroes.attack_profiles():
		_try_fire(profile, false)


## Lógica de disparo común a torres y ataques básicos de héroes.
## Si no hay objetivo en alcance y la torre está enlazada a un portal, dispara a
## través de él contra enemigos junto a la salida.
func _try_fire(t: Dictionary, can_use_portal: bool) -> void:
	if t.cooldown_ticks > 0:
		t.cooldown_ticks -= 1
		return
	var def: TowerDef = t.def
	var target := _find_first_in_range(t.pos, TowerDef.at_level(def.range_tiles, t.level))
	var portal := {}
	if target < 0 and can_use_portal:
		portal = heroes.portal_for(t.pos)
		if not portal.is_empty():
			target = _find_first_in_range(portal.exit, portal.exit_radius)
	if target < 0:
		return
	var p_slot := _spawn_projectile(t, target)
	if not portal.is_empty():
		p_via_portal[p_slot] = 1
		p_aim[p_slot] = portal.entry
		p_portal_exit[p_slot] = portal.exit
		p_portal_mult[p_slot] = portal.damage_mult
	# Recarga en ticks enteros: sin deriva por acumulación de coma flotante.
	var interval_ticks := maxi(1, roundi(TowerDef.at_level(def.interval, t.level) * TICK_RATE))
	t.cooldown_ticks = interval_ticks - 1
	events.append({type = &"projectile_fired", slot = p_slot, target = target,
		hero = t.get("hero_index", -1), via_portal = not portal.is_empty()})


## Objetivo «primero»: el enemigo más avanzado en su ruta dentro del alcance.
func _find_first_in_range(from: Vector2, range_tiles: float) -> int:
	var best := -1
	var best_dist := -INF
	var r2 := range_tiles * range_tiles
	for i in e_alive.size():
		if e_alive[i] == 0:
			continue
		if from.distance_squared_to(e_pos[i]) <= r2 and e_dist[i] > best_dist:
			best_dist = e_dist[i]
			best = i
	return best


func _spawn_projectile(t: Dictionary, target_slot: int) -> int:
	var slot: int
	if _projectile_free.is_empty():
		slot = p_alive.size()
		p_alive.append(0)
		p_pos.append(Vector2.ZERO)
		p_target_slot.append(0)
		p_target_id.append(0)
		p_aim.append(Vector2.ZERO)
		p_speed.append(0.0)
		p_damage.append(0.0)
		p_pierce.append(0.0)
		p_bounces.append(0)
		p_tower_def.append(null)
		p_hit_ids.append(PackedInt32Array())
		p_hero.append(-1)
		p_via_portal.append(0)
		p_portal_exit.append(Vector2.ZERO)
		p_portal_mult.append(1.0)
	else:
		slot = _projectile_free.pop_back()
	var def: TowerDef = t.def
	p_alive[slot] = 1
	p_pos[slot] = t.pos
	p_target_slot[slot] = target_slot
	p_target_id[slot] = e_id[target_slot]
	p_aim[slot] = e_pos[target_slot]
	p_speed[slot] = def.projectile_speed
	p_damage[slot] = TowerDef.at_level(def.damage, t.level)
	p_pierce[slot] = TowerDef.at_level(def.armor_pierce, t.level)
	p_bounces[slot] = TowerDef.at_level(def.bounces, t.level)
	p_tower_def[slot] = def
	p_hit_ids[slot] = PackedInt32Array()
	p_hero[slot] = t.get("hero_index", -1)
	p_via_portal[slot] = 0
	projectile_count += 1
	return slot


func _update_projectiles() -> void:
	for i in p_alive.size():
		if p_alive[i] == 0:
			continue
		var ts := p_target_slot[i]
		var target_valid := e_alive[ts] == 1 and e_id[ts] == p_target_id[i]
		if p_via_portal[i] == 1:
			# Primer tramo: hacia la entrada del portal; al llegar, sale por la salida.
			var to_entry := p_aim[i] - p_pos[i]
			var step_entry := p_speed[i] * DT
			if to_entry.length() > step_entry:
				p_pos[i] += to_entry.normalized() * step_entry
			else:
				p_pos[i] = p_portal_exit[i]
				p_aim[i] = e_pos[ts] if target_valid else p_portal_exit[i]
				p_via_portal[i] = 0
				p_damage[i] *= p_portal_mult[i]
				events.append({type = &"portal_transit", slot = i})
			continue
		if target_valid:
			p_aim[i] = e_pos[ts]
		var to_aim := p_aim[i] - p_pos[i]
		var step_len := p_speed[i] * DT
		if to_aim.length() > step_len:
			p_pos[i] += to_aim.normalized() * step_len
			continue
		# Llegada al objetivo (o a su última posición si ya no existe).
		p_pos[i] = p_aim[i]
		if target_valid:
			_projectile_hit(i, ts)
			if _try_bounce(i):
				continue
		_free_projectile(i)


func _projectile_hit(p: int, slot: int) -> void:
	var def: TowerDef = p_tower_def[p]
	var hit_ids: PackedInt32Array = p_hit_ids[p]
	hit_ids.append(e_id[slot])
	p_hit_ids[p] = hit_ids
	if p_hero[p] >= 0:
		heroes.on_basic_hit(self, p_hero[p])
	var killed := damage_enemy(slot, p_damage[p], def.damage_type, p_pierce[p])
	if killed and p_hero[p] >= 0:
		heroes.on_basic_kill(self, p_hero[p])
	if not killed and def.on_hit_effect:
		effects.apply(self, slot, def.on_hit_effect)


## Rebote: salta al enemigo vivo más cercano que no haya alcanzado ya.
func _try_bounce(p: int) -> bool:
	if p_bounces[p] <= 0:
		return false
	var def: TowerDef = p_tower_def[p]
	var hit_ids: PackedInt32Array = p_hit_ids[p]
	var best := -1
	var best_d2 := def.bounce_range * def.bounce_range
	for i in e_alive.size():
		if e_alive[i] == 0 or hit_ids.has(e_id[i]):
			continue
		var d2 := p_pos[p].distance_squared_to(e_pos[i])
		if d2 <= best_d2:
			best_d2 = d2
			best = i
	if best < 0:
		return false
	p_bounces[p] -= 1
	p_damage[p] *= def.bounce_damage_mult
	p_target_slot[p] = best
	p_target_id[p] = e_id[best]
	p_aim[p] = e_pos[best]
	events.append({type = &"projectile_bounced", slot = p, target = best})
	return true


func _free_projectile(i: int) -> void:
	p_alive[i] = 0
	p_tower_def[i] = null
	projectile_count -= 1
	_projectile_free.append(i)


## Aplica daño con armadura y efectos. Devuelve true si el enemigo muere.
func damage_enemy(slot: int, amount: float, damage_type: StringName = &"kinetic",
		armor_pierce: float = 0.0) -> bool:
	var armor := 0.0 if damage_type == ARMOR_IGNORING_TYPE else e_armor[slot] * (1.0 - armor_pierce)
	if damage_type == ARMOR_HALVING_TYPE:
		armor *= 0.5
	var final := amount * (1.0 - armor) * effects.damage_taken_mult(slot, damage_type)
	e_hp[slot] -= final
	events.append({type = &"enemy_hit", slot = slot, amount = final, damage_type = damage_type})
	if e_hp[slot] <= 0.0:
		_earn(e_bounty[slot])
		stats.kills += 1
		if mission and mission.coin_drop_chance > 0.0 and rng.randf() < mission.coin_drop_chance:
			objects.spawn_coin(self, e_pos[slot], mission.coin_value, mission.coin_lifetime)
		events.append({type = &"enemy_killed", slot = slot, bounty = e_bounty[slot]})
		var def: EnemyDef = e_def[slot]
		var drops_core := e_can_revive[slot] == 1 and def != null and def.revive_core != null
		var route := e_route[slot]
		var lane := e_lane[slot]
		var dist := e_dist[slot]
		_remove_enemy(slot)
		if drops_core:
			var core := spawn(def.revive_core, route, dist, lane)
			e_revive_into[core] = def
			e_timer[core] = maxi(1, roundi(def.revive_delay * TICK_RATE))
			events.append({type = &"core_dropped", slot = core, of = def.id})
		return true
	return false


func _earn(amount: int) -> void:
	gold += amount
	stats.gold_earned += amount


## Estrellas según la vida restante de la base (0 si no se ha ganado).
func stars() -> int:
	if outcome != Outcome.VICTORY:
		return 0
	var ratio := base_hp / float(mission.base_hp) if mission else 1.0
	return 3 if ratio >= 0.9 else (2 if ratio >= 0.5 else 1)


## Compatibilidad con los tests de la PoC.
func _damage_enemy(slot: int, amount: float) -> void:
	damage_enemy(slot, amount)


func _remove_enemy(slot: int) -> void:
	e_alive[slot] = 0
	e_blocker[slot] = -1
	enemy_count -= 1
	_enemy_free.append(slot)


func _check_wave_and_outcome() -> void:
	if base_hp <= 0:
		base_hp = 0
		outcome = Outcome.DEFEAT
		events.append({type = &"defeat"})
		return
	if wave_active and _spawn_queue.is_empty() and enemy_count == 0:
		wave_active = false
		var bonus: int = mission.waves[wave_index].clear_bonus
		_earn(bonus)
		events.append({type = &"wave_cleared", index = wave_index, bonus = bonus})
		if wave_index + 1 >= waves_total():
			outcome = Outcome.VICTORY
			events.append({type = &"victory"})
		else:
			next_wave_ticks = roundi(BETWEEN_WAVES * TICK_RATE)


## Huella del estado para comprobar determinismo y regresiones.
func state_hash() -> int:
	return hash([tick, base_hp, gold, enemy_count, projectile_count, e_alive, e_dist, e_hp, p_alive, p_pos])
