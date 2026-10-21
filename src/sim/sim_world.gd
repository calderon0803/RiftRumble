## Simulación pura de una partida (PoC).
##
## - No depende de Node, del árbol de escena ni de la proyección isométrica.
## - Avanza a tick fijo (`step()`); la vista lee el estado e interpola.
## - Enemigos y proyectiles se guardan en arrays empaquetados (SoA) con
##   reutilización de huecos, para medir el coste real con cientos de entidades.
## - Comunica hacia fuera mediante eventos que el consumidor recoge con `drain_events()`.
extends RefCounted

const SimPath := preload("res://src/sim/sim_path.gd")

const TICK_RATE := 30
const DT := 1.0 / TICK_RATE

var path: SimPath
var rng := RandomNumberGenerator.new()
var tick := 0
var base_hp := 20
var events: Array[Dictionary] = []

# --- Enemigos (SoA) ---------------------------------------------------------
var e_alive := PackedByteArray()
var e_id := PackedInt32Array()     # identificador único; detecta huecos reutilizados
var e_dist := PackedFloat32Array() # distancia recorrida sobre la ruta
var e_speed := PackedFloat32Array()  # casillas por segundo
var e_hp := PackedFloat32Array()
var e_max_hp := PackedFloat32Array()
var e_pos := PackedVector2Array()
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
var projectile_count := 0
var _projectile_free: Array[int] = []

# --- Torres -----------------------------------------------------------------
## Cada torre: { pos: Vector2, range: float, damage: float, projectile_speed: float,
##               interval_ticks: int, cooldown_ticks: int }
var towers: Array[Dictionary] = []

var _next_id := 1


func _init(waypoints: PackedVector2Array, seed_value: int = 0) -> void:
	path = SimPath.new(waypoints)
	rng.seed = seed_value


func is_lost() -> bool:
	return base_hp <= 0


# --- Comandos -----------------------------------------------------------------

func spawn_enemy(hp: float, speed: float, start_dist: float = 0.0) -> int:
	var slot: int
	if _enemy_free.is_empty():
		slot = e_alive.size()
		e_alive.append(0)
		e_id.append(0)
		e_dist.append(0.0)
		e_speed.append(0.0)
		e_hp.append(0.0)
		e_max_hp.append(0.0)
		e_pos.append(Vector2.ZERO)
	else:
		slot = _enemy_free.pop_back()
	e_alive[slot] = 1
	e_id[slot] = _next_id
	_next_id += 1
	e_dist[slot] = start_dist
	e_speed[slot] = speed
	e_hp[slot] = hp
	e_max_hp[slot] = hp
	e_pos[slot] = path.sample(start_dist)
	enemy_count += 1
	events.append({type = &"enemy_spawned", slot = slot})
	return slot


func add_tower(pos: Vector2, range_tiles: float, interval: float, damage: float,
		projectile_speed: float = 10.0) -> int:
	towers.append({
		pos = pos, range = range_tiles, damage = damage,
		projectile_speed = projectile_speed,
		interval_ticks = maxi(1, roundi(interval * TICK_RATE)), cooldown_ticks = 0,
	})
	return towers.size() - 1


# --- Tick ------------------------------------------------------------------

## Devuelve los eventos acumulados desde la última llamada y los vacía.
func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out


func step() -> void:
	if is_lost():
		return
	_move_enemies()
	_update_towers()
	_update_projectiles()
	tick += 1


func _move_enemies() -> void:
	for i in e_alive.size():
		if e_alive[i] == 0:
			continue
		var d := e_dist[i] + e_speed[i] * DT
		e_dist[i] = d
		if d >= path.length:
			base_hp -= 1
			events.append({type = &"enemy_leaked", slot = i})
			_remove_enemy(i)
		else:
			e_pos[i] = path.sample(d)


func _update_towers() -> void:
	for t_index in towers.size():
		var t: Dictionary = towers[t_index]
		if t.cooldown_ticks > 0:
			t.cooldown_ticks -= 1
			continue
		var target := _find_first_in_range(t.pos, t.range)
		if target < 0:
			continue
		var p_slot := _spawn_projectile(t.pos, target, t.projectile_speed, t.damage)
		# Recarga en ticks enteros: sin deriva por acumulación de coma flotante.
		t.cooldown_ticks = t.interval_ticks - 1
		events.append({type = &"projectile_fired", slot = p_slot, tower = t_index, target = target})


## Objetivo «primero»: el enemigo más avanzado en la ruta dentro del alcance.
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


func _spawn_projectile(from: Vector2, target_slot: int, speed: float, damage: float) -> int:
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
	else:
		slot = _projectile_free.pop_back()
	p_alive[slot] = 1
	p_pos[slot] = from
	p_target_slot[slot] = target_slot
	p_target_id[slot] = e_id[target_slot]
	p_aim[slot] = e_pos[target_slot]
	p_speed[slot] = speed
	p_damage[slot] = damage
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
		# Impacto (o llegada al último punto conocido si el objetivo ya no existe).
		p_pos[i] = p_aim[i]
		if target_valid:
			_damage_enemy(ts, p_damage[i])
		p_alive[i] = 0
		projectile_count -= 1
		_projectile_free.append(i)


func _damage_enemy(slot: int, amount: float) -> void:
	e_hp[slot] -= amount
	events.append({type = &"enemy_hit", slot = slot, amount = amount})
	if e_hp[slot] <= 0.0:
		events.append({type = &"enemy_killed", slot = slot})
		_remove_enemy(slot)


func _remove_enemy(slot: int) -> void:
	e_alive[slot] = 0
	enemy_count -= 1
	_enemy_free.append(slot)


## Huella del estado para comprobar determinismo y regresiones.
func state_hash() -> int:
	return hash([tick, base_hp, enemy_count, projectile_count, e_alive, e_dist, e_hp, p_alive, p_pos])
