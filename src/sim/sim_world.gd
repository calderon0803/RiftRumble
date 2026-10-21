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

const TICK_RATE := 30
const DT := 1.0 / TICK_RATE

## La armadura no reduce este tipo de daño.
const ARMOR_IGNORING_TYPE := &"magic"

enum Outcome { PLAYING, VICTORY, DEFEAT }

var paths: Array = []  # Array[SimPath], una por ruta
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

# --- Contenido (opcional: los tests de bajo nivel funcionan sin él) ---------
var content  # ContentDB
var mission: MissionDef

# --- Enemigos (SoA) ---------------------------------------------------------
var e_alive := PackedByteArray()
var e_id := PackedInt32Array()     # identificador único; detecta huecos reutilizados
var e_route := PackedInt32Array()
var e_dist := PackedFloat32Array() # distancia recorrida sobre su ruta
var e_speed := PackedFloat32Array()  # casillas por segundo (base)
var e_hp := PackedFloat32Array()
var e_max_hp := PackedFloat32Array()
var e_armor := PackedFloat32Array()
var e_bounty := PackedInt32Array()
var e_base_damage := PackedInt32Array()
var e_pos := PackedVector2Array()
var e_def: Array = []              # EnemyDef o null
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
var _spawn_queue: Array = []  # [tick, EnemyDef, ruta], ordenada por tick

var _next_id := 1


## `routes`: una ruta (PackedVector2Array) o un Array de rutas.
func _init(routes, seed_value: int = 0) -> void:
	if routes is PackedVector2Array:
		routes = [routes]
	for r in routes:
		paths.append(SimPath.new(r))
	rng.seed = seed_value
	effects = SimEffects.new()


## Configura una partida completa a partir de una misión y del mapa ya leído.
func setup_mission(content_db, mission_def: MissionDef, map_def) -> void:
	content = content_db
	mission = mission_def
	gold = mission_def.start_gold
	base_hp = mission_def.base_hp
	build_spots = map_def.build_spots


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


func can_build(tower_id: StringName) -> bool:
	return mission == null or tower_id in mission.towers


func build(spot: int, tower_id: StringName) -> StringName:
	if is_over():
		return &"game_over"
	if spot < 0 or spot >= build_spots.size():
		return &"invalid_spot"
	if not tower_at(spot).is_empty():
		return &"occupied"
	if content == null or not content.towers.has(tower_id) or not can_build(tower_id):
		return &"unknown_tower"
	var def: TowerDef = content.towers[tower_id]
	var price: int = def.cost[0]
	if gold < price:
		return &"no_gold"
	gold -= price
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
	gold += refund
	towers.erase(t)
	events.append({type = &"tower_sold", spot = spot, refund = refund})
	return &"ok"


func waves_total() -> int:
	return 0 if mission == null else mission.waves.size()


func start_next_wave() -> StringName:
	if is_over():
		return &"game_over"
	if wave_active:
		return &"wave_active"
	if wave_index + 1 >= waves_total():
		return &"no_more_waves"
	wave_index += 1
	wave_active = true
	var wave: WaveDef = mission.waves[wave_index]
	for g in wave.enemies.size():
		var def: EnemyDef = content.enemies[StringName(wave.enemies[g])]
		var route: int = wave.route[g] if g < wave.route.size() else 0
		var first := tick + roundi(wave.start_delay[g] * TICK_RATE)
		var every := maxi(1, roundi(wave.spacing[g] * TICK_RATE))
		for i in wave.counts[g]:
			_spawn_queue.append([first + i * every, def, route])
	_spawn_queue.sort_custom(func(a, b): return a[0] < b[0])
	events.append({type = &"wave_started", index = wave_index})
	return &"ok"


# --- Creación directa (tests, modo estrés) --------------------------------------

## Enemigo genérico sin definición (tests de bajo nivel y estrés).
func spawn_enemy(hp: float, speed: float, start_dist: float = 0.0, route: int = 0) -> int:
	var slot := _alloc_enemy()
	e_def[slot] = null
	e_hp[slot] = hp
	e_max_hp[slot] = hp
	e_speed[slot] = speed
	e_armor[slot] = 0.0
	e_bounty[slot] = 0
	e_base_damage[slot] = 1
	_finish_spawn(slot, route, start_dist)
	return slot


func spawn(def: EnemyDef, route: int = 0, start_dist: float = 0.0) -> int:
	var slot := _alloc_enemy()
	e_def[slot] = def
	e_hp[slot] = def.hp
	e_max_hp[slot] = def.hp
	e_speed[slot] = def.speed
	e_armor[slot] = def.armor
	e_bounty[slot] = def.bounty
	e_base_damage[slot] = def.base_damage
	_finish_spawn(slot, route, start_dist)
	return slot


## Torre colocada sin pasar por la economía.
func place_tower(def: TowerDef, pos: Vector2, level := 1, spot := -1) -> Dictionary:
	var t := {def = def, level = level, pos = pos, spot = spot, cooldown_ticks = 0, invested = 0}
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
	e_dist.append(0.0)
	e_speed.append(0.0)
	e_hp.append(0.0)
	e_max_hp.append(0.0)
	e_armor.append(0.0)
	e_bounty.append(0)
	e_base_damage.append(0)
	e_pos.append(Vector2.ZERO)
	e_def.append(null)
	return slot


func _finish_spawn(slot: int, route: int, start_dist: float) -> void:
	e_alive[slot] = 1
	e_id[slot] = _next_id
	_next_id += 1
	e_route[slot] = clampi(route, 0, paths.size() - 1)
	e_dist[slot] = start_dist
	e_pos[slot] = paths[e_route[slot]].sample(start_dist)
	effects.reset_slot(slot)
	enemy_count += 1
	events.append({type = &"enemy_spawned", slot = slot})


# --- Tick ------------------------------------------------------------------

func step() -> void:
	if is_over():
		return
	_spawn_due()
	effects.step(self)
	_move_enemies()
	_update_towers()
	_update_projectiles()
	_check_wave_and_outcome()
	tick += 1


func _spawn_due() -> void:
	while not _spawn_queue.is_empty() and _spawn_queue[0][0] <= tick:
		var entry: Array = _spawn_queue.pop_front()
		spawn(entry[1], entry[2])


func _move_enemies() -> void:
	for i in e_alive.size():
		if e_alive[i] == 0 or effects.rooted[i] == 1:
			continue
		var p: SimPath = paths[e_route[i]]
		var d := e_dist[i] + e_speed[i] * effects.speed_mult[i] * DT
		e_dist[i] = d
		if d >= p.length:
			base_hp -= e_base_damage[i]
			events.append({type = &"enemy_leaked", slot = i, damage = e_base_damage[i]})
			_remove_enemy(i)
		else:
			e_pos[i] = p.sample(d)


func _update_towers() -> void:
	for t_index in towers.size():
		var t: Dictionary = towers[t_index]
		if t.cooldown_ticks > 0:
			t.cooldown_ticks -= 1
			continue
		var def: TowerDef = t.def
		var target := _find_first_in_range(t.pos, TowerDef.at_level(def.range_tiles, t.level))
		if target < 0:
			continue
		var p_slot := _spawn_projectile(t, target)
		# Recarga en ticks enteros: sin deriva por acumulación de coma flotante.
		var interval_ticks := maxi(1, roundi(TowerDef.at_level(def.interval, t.level) * TICK_RATE))
		t.cooldown_ticks = interval_ticks - 1
		events.append({type = &"projectile_fired", slot = p_slot, tower = t_index, target = target})


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
	projectile_count += 1
	return slot


func _update_projectiles() -> void:
	for i in p_alive.size():
		if p_alive[i] == 0:
			continue
		var ts := p_target_slot[i]
		var target_valid := e_alive[ts] == 1 and e_id[ts] == p_target_id[i]
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
	var killed := damage_enemy(slot, p_damage[p], def.damage_type, p_pierce[p])
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
	var final := amount * (1.0 - armor) * effects.damage_taken_mult(slot, damage_type)
	e_hp[slot] -= final
	events.append({type = &"enemy_hit", slot = slot, amount = final, damage_type = damage_type})
	if e_hp[slot] <= 0.0:
		gold += e_bounty[slot]
		events.append({type = &"enemy_killed", slot = slot, bounty = e_bounty[slot]})
		_remove_enemy(slot)
		return true
	return false


## Compatibilidad con los tests de la PoC.
func _damage_enemy(slot: int, amount: float) -> void:
	damage_enemy(slot, amount)


func _remove_enemy(slot: int) -> void:
	e_alive[slot] = 0
	enemy_count -= 1
	_enemy_free.append(slot)


func _check_wave_and_outcome() -> void:
	if base_hp <= 0:
		outcome = Outcome.DEFEAT
		events.append({type = &"defeat"})
		return
	if wave_active and _spawn_queue.is_empty() and enemy_count == 0:
		wave_active = false
		var bonus: int = mission.waves[wave_index].clear_bonus
		gold += bonus
		events.append({type = &"wave_cleared", index = wave_index, bonus = bonus})
		if wave_index + 1 >= waves_total():
			outcome = Outcome.VICTORY
			events.append({type = &"victory"})


## Huella del estado para comprobar determinismo y regresiones.
func state_hash() -> int:
	return hash([tick, base_hp, gold, enemy_count, projectile_count, e_alive, e_dist, e_hp, p_alive, p_pos])
