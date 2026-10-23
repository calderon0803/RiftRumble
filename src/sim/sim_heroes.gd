## Héroes en la simulación: nivel, movimiento, ataque básico, filo, medidor de
## habilidad, escudos y habilidades persistentes (portales y zonas).
##
## Medidor (docs/personajes/B §0.6, G-3/G-4): la habilidad se lanza a mano al
## llegar al 100 %. Carga por ATAQUE (no por objetivo), por derribo con el ataque
## automático y por daño recibido, con tope por segundo. No carga fuera de combate
## ni mientras la habilidad del héroe está activa; al caer conserva la mitad.
##
## El ataque básico usa la misma lógica de disparo que las torres (el héroe
## lleva un «perfil de torre» que se mueve con él). Las habilidades se eligen
## por `HeroDef.ability_kind`; un héroe nuevo que reutilice un tipo existente
## no necesita código.
extends RefCounted

const MapDef := preload("res://src/content/map_def.gd")

## Valores de prueba del medidor (prov., docs/personajes/B §0.6).
const METER_FULL := 100.0
const METER_PER_ATTACK := 6.0
const METER_PER_KILL := 8.0
## Por cada 1 % de vida máxima perdida.
const METER_PER_HP_PCT := 0.2
const METER_CAP_PER_SECOND := 10.0
## Ticks sin dar ni recibir daño tras los que el héroe está «fuera de combate».
const COMBAT_WINDOW_TICKS := 90
const METER_KEPT_ON_DEATH := 0.5
## Ataques multiblanco: +1 % por objetivo extra, como mucho +2 % (B §0.6).
const METER_PER_EXTRA_TARGET := 1.0
const METER_EXTRA_TARGETS_MAX := 2
## Aplicar control: 3 % por objetivo, el mismo objetivo como mucho cada 3 s.
const METER_PER_CONTROL := 3.0
const CONTROL_METER_COOLDOWN_TICKS := 90
## Tope de escudo: fracción de la vida máxima (B §0.8).
const SHIELD_CAP := 0.4

## Cada héroe: { def: HeroDef, pos, target, spawn: Vector2, edge: int (filo),
##               meter: float (0–100), last_combat: int (tick), sec_start, sec_gain,
##               level, max_hp, atk_mult: float (crecimiento por nivel),
##               hp: float, dead_ticks: int (0 = vivo),
##               shield: float, shield_ticks, block_bonus: int (escudo de habilidad),
##               ability_ticks: int (habilidad propia activa), alt: bool, control_cd,
##               engaged: Array de [slot, id] de enemigos bloqueados,
##               attack: { perfil de torre + hero_index } }
var heroes: Array[Dictionary] = []
## Cada portal: { uid: int, entry, exit: Vector2, ticks: int, link_radius, exit_radius,
##                damage_mult: float, hero_index: int }
var portals: Array[Dictionary] = []
## Cada zona: { uid, pos: Vector2, radius, ticks, damage_per_tick, damage_type,
##              end_effect: EffectDef, hero_index }
var zones: Array[Dictionary] = []


## `level` (1–60) escala la vida y el ataque según el crecimiento del héroe.
func add_hero(def: HeroDef, pos: Vector2, level: int = 1) -> int:
	var index := heroes.size()
	var max_hp: float = def.max_hp * (1.0 + def.growth_hp * (level - 1))
	var atk_mult: float = 1.0 + def.growth_attack * (level - 1)
	heroes.append({
		def = def, pos = pos, target = pos, spawn = pos, edge = 0, meter = 0.0,
		last_combat = -COMBAT_WINDOW_TICKS - 1, sec_start = 0, sec_gain = 0.0,
		level = level, max_hp = max_hp, atk_mult = atk_mult,
		hp = max_hp, dead_ticks = 0, engaged = [],
		shield = 0.0, shield_ticks = 0, block_bonus = 0, ability_ticks = 0, alt = false, control_cd = {},
		attack = {def = def.attack, level = 1, pos = pos, spot = -1, cooldown_ticks = 0,
			invested = 0, hero_index = index, damage_mult = atk_mult},
	})
	return index


## P: el DPS del ataque automático del héroe a su nivel (docs/personajes/H §1).
func power(index: int) -> float:
	var h: Dictionary = heroes[index]
	var atk: TowerDef = h.def.attack
	if atk == null:
		return 0.0
	return TowerDef.at_level(atk.damage, 1) / TowerDef.at_level(atk.interval, 1) * h.atk_mult


func move(world, index: int, destination: Vector2) -> StringName:
	if index < 0 or index >= heroes.size():
		return &"invalid_hero"
	if heroes[index].dead_ticks > 0:
		return &"dead"
	# Los héroes luchan en el camino: el destino se ajusta al punto más cercano.
	var best := destination
	var best_d := INF
	for p in world.paths:
		var q := MapDef.closest_point_on_route(destination, p.points)
		if q.distance_squared_to(destination) < best_d:
			best_d = q.distance_squared_to(destination)
			best = q
	heroes[index].target = best
	return &"ok"


func cast(world, index: int, target: Vector2) -> StringName:
	if index < 0 or index >= heroes.size():
		return &"invalid_hero"
	var h: Dictionary = heroes[index]
	var def: HeroDef = h.def
	if h.dead_ticks > 0:
		return &"dead"
	if h.meter < METER_FULL:
		return &"not_ready"
	if def.ability_kind == HeroDef.ABILITY_BURST_SELF:
		target = h.pos  # sin apuntar
	if h.pos.distance_to(target) > def.ability_range:
		return &"out_of_range"
	match def.ability_kind:
		HeroDef.ABILITY_PORTAL:
			portals.append({
				uid = world.new_uid(), entry = h.pos, exit = target,
				ticks = maxi(1, roundi(def.ability_duration * world.TICK_RATE)),
				link_radius = def.ability_link_radius, exit_radius = def.ability_radius,
				damage_mult = def.ability_damage_mult, hero_index = index,
			})
			world.events.append({type = &"portal_opened", hero = index, entry = h.pos, exit = target})
		HeroDef.ABILITY_LINE_STRIKE:
			if target.is_equal_approx(h.pos):
				return &"invalid_target"
			_line_strike(world, index, target)
		HeroDef.ABILITY_BURST_SELF:
			_burst_self(world, index)
		HeroDef.ABILITY_ZONE:
			zones.append({
				uid = world.new_uid(), pos = target, radius = def.ability_radius,
				ticks = maxi(1, roundi(def.ability_duration * world.TICK_RATE)),
				damage_per_tick = def.ability_zone_power * power(index) / world.TICK_RATE,
				damage_type = def.ability_damage_type, end_effect = def.ability_end_effect,
				hero_index = index,
			})
			h.ability_ticks = zones[-1].ticks
			world.events.append({type = &"zone_opened", hero = index, uid = zones[-1].uid,
				pos = target, radius = def.ability_radius})
		_:
			push_error("Tipo de habilidad desconocido: %s" % def.ability_kind)
			return &"unknown_ability"
	h.meter = 0.0
	world.stats.abilities_used += 1
	return &"ok"


## ¿Está activa la habilidad del héroe? (portal abierto, zona, escudo…).
func ability_active(index: int) -> bool:
	if heroes[index].ability_ticks > 0:
		return true
	for p in portals:
		if p.hero_index == index:
			return true
	return false


## Suma carga al medidor respetando las reglas comunes. Devuelve lo sumado.
func add_meter(world, index: int, amount: float) -> float:
	var h: Dictionary = heroes[index]
	if h.dead_ticks > 0 or h.meter >= METER_FULL or ability_active(index):
		return 0.0
	if world.tick - h.last_combat > COMBAT_WINDOW_TICKS:
		return 0.0  # fuera de combate
	if world.tick - h.sec_start >= world.TICK_RATE:
		h.sec_start = world.tick
		h.sec_gain = 0.0
	var gain := minf(amount, METER_CAP_PER_SECOND - h.sec_gain)
	if gain <= 0.0:
		return 0.0
	h.sec_gain += gain
	h.meter = minf(h.meter + gain, METER_FULL)
	if h.meter >= METER_FULL:
		world.events.append({type = &"hero_ability_ready", hero = index})
	return gain


func mark_combat(world, index: int) -> void:
	heroes[index].last_combat = world.tick


## El héroe ha aplicado control a un enemigo: carga con enfriamiento por objetivo.
func on_control(world, index: int, slot: int) -> void:
	var h: Dictionary = heroes[index]
	var key: int = world.e_id[slot]
	if world.tick - int(h.control_cd.get(key, -CONTROL_METER_COOLDOWN_TICKS - 1)) < CONTROL_METER_COOLDOWN_TICKS:
		return
	h.control_cd[key] = world.tick
	mark_combat(world, index)
	add_meter(world, index, METER_PER_CONTROL)


## Aplica un efecto de la habilidad del héroe y cuenta el control para el medidor.
func apply_control(world, index: int, slot: int, effect: EffectDef) -> void:
	if effect and world.e_alive[slot] == 1 and world.effects.apply(world, slot, effect):
		on_control(world, index, slot)


## Tipo de daño del siguiente golpe (alterna si el héroe tiene `alt_damage_type`).
func attack_damage_type(index: int, base: StringName) -> StringName:
	var h: Dictionary = heroes[index]
	if h.def.alt_damage_type == &"":
		return base
	h.alt = not h.alt
	return h.def.alt_damage_type if h.alt else base


func step(world) -> void:
	for index in heroes.size():
		var h: Dictionary = heroes[index]
		var def: HeroDef = h.def
		if h.ability_ticks > 0:
			h.ability_ticks -= 1
		if h.shield_ticks > 0:
			h.shield_ticks -= 1
			if h.shield_ticks == 0:
				_clear_shield(world, index)
		if h.dead_ticks > 0:
			h.dead_ticks -= 1
			if h.dead_ticks == 0:
				h.hp = h.max_hp
				h.pos = h.spawn
				h.target = h.spawn
				h.attack.pos = h.spawn
				world.events.append({type = &"hero_respawned", hero = index})
			continue
		h.pos = h.pos.move_toward(h.target, def.move_speed * world.DT)
		h.attack.pos = h.pos
		_update_engagement(world, index)
		_enemy_melee(world, index)
		if h.engaged.is_empty():
			h.hp = minf(h.hp + def.regen_per_second * world.DT, h.max_hp)
	_step_zones(world)
	for i in range(portals.size() - 1, -1, -1):
		portals[i].ticks -= 1
		if portals[i].ticks <= 0:
			world.events.append({type = &"portal_closed", hero = portals[i].hero_index})
			portals.remove_at(i)


## Suelta a los enemigos que ya no son válidos o se han alejado y bloquea a
## nuevos (los más avanzados primero) hasta `block_count`.
func _update_engagement(world, index: int) -> void:
	var h: Dictionary = heroes[index]
	var def: HeroDef = h.def
	var keep := []
	for e in h.engaged:
		var slot: int = e[0]
		var valid: bool = world.e_alive[slot] == 1 and world.e_id[slot] == e[1] 				and world.e_pos[slot].distance_to(h.pos) <= def.engage_radius + 0.6
		if valid:
			keep.append(e)
		elif world.e_alive[slot] == 1 and world.e_id[slot] == e[1]:
			world.e_blocker[slot] = -1
	var capacity: int = def.block_count + h.block_bonus
	while keep.size() > capacity:  # p. ej., al acabar el escudo que daba +1
		var e: Array = keep.pop_back()
		world.e_blocker[e[0]] = -1
	h.engaged = keep
	if h.engaged.size() >= capacity or h.pos.distance_to(h.target) > 0.05:
		return  # sin hueco, o caminando: no bloquea a nuevos
	var candidates := []
	for i in world.e_alive.size():
		if world.e_alive[i] == 1 and world.e_blocker[i] < 0 				and world.e_pos[i].distance_to(h.pos) <= def.engage_radius:
			candidates.append([world.e_dist[i], i])
	candidates.sort_custom(func(a, b): return a[0] > b[0])
	for c in candidates.slice(0, capacity - h.engaged.size()):
		var slot: int = c[1]
		world.e_blocker[slot] = index
		world.e_melee_cd[slot] = world.e_melee_ticks[slot]
		h.engaged.append([slot, world.e_id[slot]])
		world.events.append({type = &"hero_engaged", hero = index, slot = slot})


## Los enemigos bloqueados golpean al héroe; si cae, los suelta y reaparecerá.
func _enemy_melee(world, index: int) -> void:
	var h: Dictionary = heroes[index]
	for e in h.engaged:
		var slot: int = e[0]
		world.e_melee_cd[slot] -= 1
		if world.e_melee_cd[slot] <= 0:
			world.e_melee_cd[slot] = world.e_melee_ticks[slot]
			var amount: float = world.e_melee_damage[slot] * (1.0 - h.def.defense)
			var absorbed := minf(amount, h.shield)
			if absorbed > 0.0:
				h.shield -= absorbed
				amount -= absorbed
				if h.shield <= 0.0:
					_clear_shield(world, index)
			h.hp -= amount
			mark_combat(world, index)
			add_meter(world, index, METER_PER_HP_PCT * 100.0 * amount / h.max_hp)
			world.events.append({type = &"hero_hit", hero = index, amount = amount, absorbed = absorbed})
	if h.hp <= 0.0:
		h.hp = 0.0
		for e in h.engaged:
			world.e_blocker[e[0]] = -1
		h.engaged = []
		h.shield = 0.0
		h.shield_ticks = 0
		h.block_bonus = 0
		h.dead_ticks = maxi(1, roundi(h.def.respawn_time * world.TICK_RATE))
		h.edge = 0
		h.meter *= METER_KEPT_ON_DEATH
		world.stats.hero_kos += 1
		world.events.append({type = &"hero_died", hero = index})


## Perfiles de ataque de los héroes vivos (los dispara el mundo como si fueran torres).
func attack_profiles() -> Array:
	var out := []
	for h in heroes:
		if h.def.attack and h.dead_ticks == 0:
			out.append(h.attack)
	return out


## Portal cuya entrada está enlazada con una torre en `tower_pos` (o vacío).
func portal_for(tower_pos: Vector2) -> Dictionary:
	for p in portals:
		if tower_pos.distance_to(p.entry) <= p.link_radius:
			return p
	return {}


## Un ataque básico del héroe ha impactado: filo y medidor (una vez por ataque;
## los objetivos extra de un golpe multiblanco suman un poco, con tope).
func on_basic_hit(world, hero_index: int, extra_targets: int = 0) -> void:
	var h: Dictionary = heroes[hero_index]
	var def: HeroDef = h.def
	mark_combat(world, hero_index)
	if def.edge_per_hit > 0:
		h.edge = mini(h.edge + def.edge_per_hit, def.edge_max)
	add_meter(world, hero_index, METER_PER_ATTACK
		+ METER_PER_EXTRA_TARGET * mini(extra_targets, METER_EXTRA_TARGETS_MAX))


## El ataque básico del héroe ha eliminado a un enemigo.
func on_basic_kill(world, hero_index: int) -> void:
	add_meter(world, hero_index, METER_PER_KILL)


func _line_strike(world, index: int, target: Vector2) -> void:
	var h: Dictionary = heroes[index]
	var def: HeroDef = h.def
	var dir: Vector2 = (target - h.pos).normalized()
	var from: Vector2 = h.pos
	var to: Vector2 = h.pos + dir * def.ability_length
	var damage: float = def.ability_damage + def.ability_damage_per_edge * h.edge
	if def.ability_power > 0.0:
		damage = def.ability_power * power(index)
	var half_width := def.ability_width * 0.5
	# Primero se reúnen los objetivos y después se dañan: matar a uno no altera
	# la lista mientras se recorre.
	var hits := []
	for i in world.e_alive.size():
		if world.e_alive[i] == 1:
			var p: Vector2 = world.e_pos[i]
			if Geometry2D.get_closest_point_to_segment(p, from, to).distance_to(p) <= half_width:
				hits.append(i)
	# En orden desde el héroe: cada atravesado potencia a los siguientes (rampa).
	hits.sort_custom(func(a, b): return from.distance_squared_to(world.e_pos[a]) < from.distance_squared_to(world.e_pos[b]))
	world.events.append({type = &"line_strike", hero = index, from = from, to = to,
		hits = hits.size(), edge = h.edge})
	h.edge = 0
	for k in hits.size():
		var ramp := minf(def.ability_ramp_per_target * k, def.ability_ramp_max)
		if not world.damage_enemy(hits[k], damage * (1.0 + ramp), def.ability_damage_type, def.ability_armor_pierce):
			apply_control(world, index, hits[k], def.ability_effect)


## Área alrededor del héroe: daño, efecto, empuje y escudo a los héroes cercanos.
func _burst_self(world, index: int) -> void:
	var h: Dictionary = heroes[index]
	var def: HeroDef = h.def
	var damage := def.ability_power * power(index)
	var hits := []
	for i in world.e_alive.size():
		if world.e_alive[i] == 1 and world.e_pos[i].distance_to(h.pos) <= def.ability_radius:
			hits.append(i)
	world.events.append({type = &"hero_burst", hero = index, pos = h.pos, radius = def.ability_radius,
		hits = hits.size()})
	for i in hits:
		if damage > 0.0 and world.damage_enemy(i, damage, def.ability_damage_type, def.ability_armor_pierce):
			continue
		if def.ability_push > 0.0:
			world.push_enemy(i, def.ability_push)
		apply_control(world, index, i, def.ability_effect)
	if def.ability_shield > 0.0:
		var ticks := maxi(1, roundi(def.ability_duration * world.TICK_RATE))
		for j in heroes.size():
			var o: Dictionary = heroes[j]
			if o.dead_ticks == 0 and o.pos.distance_to(h.pos) <= def.ability_radius:
				o.shield = minf(maxf(o.shield, def.ability_shield * o.max_hp), SHIELD_CAP * o.max_hp)
				o.shield_ticks = ticks
				o.block_bonus = def.ability_shield_block_bonus
				world.events.append({type = &"hero_shielded", hero = j, amount = o.shield})
		h.ability_ticks = ticks


func _clear_shield(world, index: int) -> void:
	var h: Dictionary = heroes[index]
	h.shield = 0.0
	h.shield_ticks = 0
	h.block_bonus = 0
	world.events.append({type = &"hero_shield_ended", hero = index})


func _step_zones(world) -> void:
	for zi in range(zones.size() - 1, -1, -1):
		var z: Dictionary = zones[zi]
		var inside := []
		for i in world.e_alive.size():
			if world.e_alive[i] == 1 and world.e_pos[i].distance_to(z.pos) <= z.radius:
				inside.append(i)
		for i in inside:
			if world.e_alive[i] == 1:
				world.damage_enemy(i, z.damage_per_tick, z.damage_type)
		z.ticks -= 1
		if z.ticks <= 0:
			zones.remove_at(zi)
			for i in inside:
				apply_control(world, z.hero_index, i, z.end_effect)
			world.events.append({type = &"zone_closed", hero = z.hero_index, uid = z.uid})
