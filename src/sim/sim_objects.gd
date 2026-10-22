## Elementos interactivos del mapa: monedas, bloques rompibles y plataformas móviles.
##
## - Monedas: las sueltan enemigos al morir (MissionDef.coin_drop_chance); las
##   recoge un héroe al pasar por encima o el jugador con un toque; caducan.
## - Bloques: tienen vida; los golpean los héroes cercanos que no están luchando.
##   Al romperse dan oro y/o abren una ruta (atajo) o una posición de construcción.
## - Plataformas: desplazan una posición de construcción (y su torre) entre dos
##   puntos con un movimiento de ida y vuelta.
## El mundo se pasa en cada llamada (sin referencia guardada: sin ciclos).
extends RefCounted

## Radio (casillas) en el que un héroe recoge una moneda.
const PICKUP_RADIUS := 0.8
## Distancia extra (casillas) sobre el alcance del héroe para golpear un bloque.
const BLOCK_REACH := 0.6

## Cada bloque: { uid, id, pos, hp, max_hp, alive, reward_gold, opens_route, opens_spot }
var blocks: Array[Dictionary] = []
## Cada plataforma: { uid, id, spot, a, b, period_ticks }
var platforms: Array[Dictionary] = []
## Cada moneda: { uid, pos, value, ticks }
var coins: Array[Dictionary] = []
## Rutas y posiciones cerradas hasta romper su bloque: índice → true.
var closed_routes := {}
var closed_spots := {}
## Recarga de golpe de cada héroe contra bloques: índice de héroe → ticks.
var _hero_block_cd := {}


func setup(world, map_def) -> void:
	for o in map_def.objects:
		var p: Dictionary = o.props
		match o.kind:
			&"block":
				var hp := float(p.get("hp", 20.0))
				var b := {uid = world.new_uid(), id = o.id, pos = o.pos, hp = hp, max_hp = hp, alive = true,
					reward_gold = int(p.get("reward_gold", 0)), opens_route = int(p.get("opens_route", -1)),
					opens_spot = int(p.get("opens_spot", -1))}
				blocks.append(b)
				if b.opens_route >= 0:
					closed_routes[b.opens_route] = true
				if b.opens_spot >= 0:
					closed_spots[b.opens_spot] = true
			&"platform":
				platforms.append({uid = world.new_uid(), id = o.id, spot = int(p.get("spot", 0)),
					a = o.pos, b = Vector2(p.get("to", o.pos)),
					period_ticks = maxi(1, roundi(float(p.get("period", 10.0)) * world.TICK_RATE))})


func route_open(route: int) -> bool:
	return not closed_routes.has(route)


func spot_open(spot: int) -> bool:
	return not closed_spots.has(spot)


func spawn_coin(world, pos: Vector2, value: int, lifetime: float) -> void:
	var c := {uid = world.new_uid(), pos = pos, value = value,
		ticks = maxi(1, roundi(lifetime * world.TICK_RATE))}
	coins.append(c)
	world.events.append({type = &"coin_spawned", uid = c.uid, pos = pos})


## Recoger una moneda con un toque (comando del jugador).
func collect(world, uid: int) -> StringName:
	for i in coins.size():
		if coins[i].uid == uid:
			_collect_at(world, i, -1)
			return &"ok"
	return &"gone"


func step(world) -> void:
	_step_coins(world)
	_step_blocks(world)
	_step_platforms(world)


func _step_coins(world) -> void:
	for i in range(coins.size() - 1, -1, -1):
		var c: Dictionary = coins[i]
		c.ticks -= 1
		var picker := _hero_near(world, c.pos, PICKUP_RADIUS)
		if picker >= 0:
			_collect_at(world, i, picker)
		elif c.ticks <= 0:
			world.events.append({type = &"coin_expired", uid = c.uid})
			coins.remove_at(i)


func _collect_at(world, index: int, hero: int) -> void:
	var c: Dictionary = coins[index]
	world._earn(c.value)
	world.events.append({type = &"coin_collected", uid = c.uid, value = c.value, hero = hero, pos = c.pos})
	coins.remove_at(index)


func _hero_near(world, pos: Vector2, radius: float) -> int:
	for i in world.heroes.heroes.size():
		var h: Dictionary = world.heroes.heroes[i]
		if h.dead_ticks == 0 and h.pos.distance_to(pos) <= radius:
			return i
	return -1


## Los héroes vivos y libres (sin enemigos bloqueados) golpean el bloque al alcance.
func _step_blocks(world) -> void:
	for hi in world.heroes.heroes.size():
		var h: Dictionary = world.heroes.heroes[hi]
		if _hero_block_cd.get(hi, 0) > 0:
			_hero_block_cd[hi] -= 1
			continue
		if h.dead_ticks > 0 or not h.engaged.is_empty() or h.def.attack == null:
			continue
		var atk: TowerDef = h.def.attack
		var reach: float = TowerDef.at_level(atk.range_tiles, 1) + BLOCK_REACH
		for b in blocks:
			if b.alive and h.pos.distance_to(b.pos) <= reach:
				_hit_block(world, b, TowerDef.at_level(atk.damage, 1))
				_hero_block_cd[hi] = maxi(1, roundi(TowerDef.at_level(atk.interval, 1) * world.TICK_RATE))
				break


func _hit_block(world, b: Dictionary, damage: float) -> void:
	b.hp -= damage
	if b.hp < 0.001:  # residuos de coma flotante (p. ej., 9 − 5 × 1,8) cuentan como roto
		b.hp = 0.0
	world.events.append({type = &"block_hit", uid = b.uid, hp = b.hp})
	if b.hp > 0.0:
		return
	b.alive = false
	if b.reward_gold > 0:
		world._earn(b.reward_gold)
	world.events.append({type = &"block_broken", uid = b.uid, reward = b.reward_gold, pos = b.pos})
	if b.opens_route >= 0:
		closed_routes.erase(b.opens_route)
		world.events.append({type = &"route_opened", route = b.opens_route})
	if b.opens_spot >= 0:
		closed_spots.erase(b.opens_spot)
		world.events.append({type = &"spot_opened", spot = b.opens_spot})


## Ida y vuelta suave: la posición de construcción y su torre se mueven juntas.
func _step_platforms(world) -> void:
	for p in platforms:
		var phase: float = float(world.tick % p.period_ticks) / p.period_ticks
		var f: float = 0.5 - 0.5 * cos(TAU * phase)
		var pos: Vector2 = p.a.lerp(p.b, f)
		world.build_spots[p.spot] = pos
		for t in world.towers:
			if t.spot == p.spot:
				t.pos = pos
