## Héroes en la simulación: movimiento, ataque básico, carga, habilidades
## activas con recarga y portales activos.
##
## El ataque básico usa la misma lógica de disparo que las torres (el héroe
## lleva un «perfil de torre» que se mueve con él). Las habilidades se eligen
## por `HeroDef.ability_kind`; un héroe nuevo que reutilice un tipo existente
## no necesita código.
extends RefCounted

const MapDef := preload("res://src/content/map_def.gd")

## Cada héroe: { def: HeroDef, pos, target, spawn: Vector2, charge: int,
##               ability_cd: int (ticks), hp: float, dead_ticks: int (0 = vivo),
##               engaged: Array de [slot, id] de enemigos bloqueados,
##               attack: { perfil de torre + hero_index } }
var heroes: Array[Dictionary] = []
## Cada portal: { uid: int, entry, exit: Vector2, ticks: int, link_radius, exit_radius,
##                damage_mult: float, hero_index: int }
var portals: Array[Dictionary] = []


func add_hero(def: HeroDef, pos: Vector2) -> int:
	var index := heroes.size()
	heroes.append({
		def = def, pos = pos, target = pos, spawn = pos, charge = 0, ability_cd = 0,
		hp = def.max_hp, dead_ticks = 0, engaged = [],
		attack = {def = def.attack, level = 1, pos = pos, spot = -1, cooldown_ticks = 0,
			invested = 0, hero_index = index},
	})
	return index


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
	if h.ability_cd > 0:
		return &"cooldown"
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
		_:
			push_error("Tipo de habilidad desconocido: %s" % def.ability_kind)
			return &"unknown_ability"
	h.ability_cd = maxi(1, roundi(def.ability_cooldown * world.TICK_RATE))
	return &"ok"


func step(world) -> void:
	for index in heroes.size():
		var h: Dictionary = heroes[index]
		var def: HeroDef = h.def
		if h.ability_cd > 0:
			h.ability_cd -= 1
		if h.dead_ticks > 0:
			h.dead_ticks -= 1
			if h.dead_ticks == 0:
				h.hp = def.max_hp
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
			h.hp = minf(h.hp + def.regen_per_second * world.DT, def.max_hp)
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
	h.engaged = keep
	if h.engaged.size() >= def.block_count or h.pos.distance_to(h.target) > 0.05:
		return  # sin hueco, o caminando: no bloquea a nuevos
	var candidates := []
	for i in world.e_alive.size():
		if world.e_alive[i] == 1 and world.e_blocker[i] < 0 				and world.e_pos[i].distance_to(h.pos) <= def.engage_radius:
			candidates.append([world.e_dist[i], i])
	candidates.sort_custom(func(a, b): return a[0] > b[0])
	for c in candidates.slice(0, def.block_count - h.engaged.size()):
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
			h.hp -= world.e_melee_damage[slot]
			world.events.append({type = &"hero_hit", hero = index, amount = world.e_melee_damage[slot]})
	if h.hp <= 0.0:
		h.hp = 0.0
		for e in h.engaged:
			world.e_blocker[e[0]] = -1
		h.engaged = []
		h.dead_ticks = maxi(1, roundi(h.def.respawn_time * world.TICK_RATE))
		h.charge = 0
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


## Un golpe del ataque básico de un héroe ha impactado: suma carga.
func on_basic_hit(hero_index: int) -> void:
	var h: Dictionary = heroes[hero_index]
	var def: HeroDef = h.def
	if def.charge_per_hit > 0:
		h.charge = mini(h.charge + def.charge_per_hit, def.charge_max)


func _line_strike(world, index: int, target: Vector2) -> void:
	var h: Dictionary = heroes[index]
	var def: HeroDef = h.def
	var dir: Vector2 = (target - h.pos).normalized()
	var from: Vector2 = h.pos
	var to: Vector2 = h.pos + dir * def.ability_length
	var damage: float = def.ability_damage + def.ability_damage_per_charge * h.charge
	var half_width := def.ability_width * 0.5
	# Primero se reúnen los objetivos y después se dañan: matar a uno no altera
	# la lista mientras se recorre.
	var hits := []
	for i in world.e_alive.size():
		if world.e_alive[i] == 1:
			var p: Vector2 = world.e_pos[i]
			if Geometry2D.get_closest_point_to_segment(p, from, to).distance_to(p) <= half_width:
				hits.append(i)
	world.events.append({type = &"line_strike", hero = index, from = from, to = to,
		hits = hits.size(), charge = h.charge})
	h.charge = 0
	for i in hits:
		world.damage_enemy(i, damage, def.ability_damage_type, def.ability_armor_pierce)
