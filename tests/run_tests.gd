## Tests headless de la simulación (sin dependencias externas).
## Uso:  godot --headless --path . --script res://tests/run_tests.gd
## Sale con código 0 si todo pasa y con 1 si algo falla.
extends SceneTree

const SimWorld := preload("res://src/sim/sim_world.gd")
const SimPath := preload("res://src/sim/sim_path.gd")
const Iso := preload("res://src/view/iso.gd")

## Ruta recta de 10 casillas: (0,0) → (10,0).
const STRAIGHT := [Vector2(0, 0), Vector2(10, 0)]

var _failures := 0
var _checks := 0


func _init() -> void:
	for method in get_method_list():
		var name: String = method.name
		if name.begins_with("test_"):
			var before := _failures
			call(name)
			print("%s %s" % ["PASS" if _failures == before else "FAIL", name])
	print("\n%d comprobaciones, %d fallos" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		push_error("  ✗ " + msg)
		print("  ✗ " + msg)


func _world(points: Array = STRAIGHT) -> SimWorld:
	return SimWorld.new(PackedVector2Array(points), 42)


func _run(w: SimWorld, ticks: int) -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for i in ticks:
		w.step()
		all.append_array(w.drain_events())
	return all


func _count(events: Array[Dictionary], type: StringName) -> int:
	return events.filter(func(e): return e.type == type).size()


# --- Ruta ---------------------------------------------------------------------

func test_path_length_and_sampling() -> void:
	var p := SimPath.new(PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(4, 3)]))
	check(is_equal_approx(p.length, 7.0), "longitud 7, obtenida %f" % p.length)
	check(p.sample(-1.0) == Vector2(0, 0), "antes del inicio → primer punto")
	check(p.sample(2.0).is_equal_approx(Vector2(2, 0)), "d=2 en el primer tramo")
	check(p.sample(4.0).is_equal_approx(Vector2(4, 0)), "d=4 en el codo")
	check(p.sample(5.5).is_equal_approx(Vector2(4, 1.5)), "d=5.5 en el segundo tramo")
	check(p.sample(99.0) == Vector2(4, 3), "después del final → último punto")


func test_iso_roundtrip() -> void:
	for v in [Vector2(0, 0), Vector2(3.5, 7.25), Vector2(15, 2)]:
		check(Iso.to_logical(Iso.to_screen(v)).is_equal_approx(v), "ida y vuelta iso %s" % v)


# --- Movimiento ---------------------------------------------------------------

func test_enemy_reaches_base_in_expected_time() -> void:
	var w := _world()
	w.spawn_enemy(10.0, 2.0)  # 10 casillas a 2 casillas/s = 5 s = 150 ticks
	var leaked_at := -1
	for i in 200:
		w.step()
		if _count(w.drain_events(), &"enemy_leaked") > 0:
			leaked_at = w.tick
			break
	check(absi(leaked_at - 150) <= 1, "llega a la base en ~150 ticks, obtenido %d" % leaked_at)
	check(w.base_hp == 19, "la base pierde 1 de vida")
	check(w.enemy_count == 0, "el enemigo se elimina al llegar")


func test_enemy_follows_path_positions() -> void:
	var w := _world([Vector2(0, 0), Vector2(3, 0), Vector2(3, 3)])
	var slot := w.spawn_enemy(10.0, 3.0)  # 0.1 casillas/tick
	_run(w, 45)  # 4.5 casillas recorridas → (3, 1.5)
	# Tolerancia 1e-3: e_dist es float32 y acumula 45 sumas.
	check(w.e_pos[slot].distance_to(Vector2(3, 1.5)) < 1e-3,"posición tras el codo, obtenida %s" % w.e_pos[slot])


func test_lost_when_base_hp_zero() -> void:
	var w := _world()
	w.base_hp = 2
	for i in 3:
		w.spawn_enemy(10.0, 10.0, 9.9)
	_run(w, 2)
	check(w.is_lost(), "la partida se pierde con base_hp <= 0")
	var tick_before := w.tick
	w.step()
	check(w.tick == tick_before, "una partida perdida no avanza")


# --- Torres y proyectiles -------------------------------------------------------

func test_tower_ignores_out_of_range() -> void:
	var w := _world()
	w.add_tower(Vector2(5, 5), 2.0, 0.5, 1.0)  # distancia a la ruta = 5 > 2
	w.spawn_enemy(100.0, 1.0)
	var ev := _run(w, 150)
	check(_count(ev, &"projectile_fired") == 0, "no dispara fuera de alcance")


func test_tower_fire_interval() -> void:
	var w := _world()
	w.add_tower(Vector2(1, 1), 50.0, 0.5, 0.0)  # alcance enorme, daño 0, intervalo 15 ticks
	w.spawn_enemy(100.0, 0.0)  # enemigo inmóvil
	var ev := _run(w, 90)  # 3 s → disparos en los ticks 0,15,…,75 = 6
	check(_count(ev, &"projectile_fired") == 6, "6 disparos en 3 s, obtenidos %d" % _count(ev, &"projectile_fired"))


func test_tower_targets_first_enemy() -> void:
	var w := _world()
	w.add_tower(Vector2(5, 1), 50.0, 1.0, 0.0)
	var back := w.spawn_enemy(10.0, 0.0, 1.0)
	var front := w.spawn_enemy(10.0, 0.0, 6.0)
	var ev := _run(w, 1)
	var fired := ev.filter(func(e): return e.type == &"projectile_fired")
	check(fired.size() == 1 and fired[0].target == front, "apunta al más avanzado (slot %d, no %d)" % [front, back])


func test_projectile_kills_enemy() -> void:
	var w := _world()
	w.add_tower(Vector2(2, 1), 3.0, 0.5, 2.0, 20.0)
	w.spawn_enemy(5.0, 0.0, 2.0)  # inmóvil en (2,0); 3 impactos de 2 lo eliminan
	var ev := _run(w, 60)
	check(_count(ev, &"enemy_hit") == 3, "3 impactos, obtenidos %d" % _count(ev, &"enemy_hit"))
	check(_count(ev, &"enemy_killed") == 1, "1 eliminación")
	check(w.enemy_count == 0, "no quedan enemigos")
	check(w.projectile_count == 0, "los proyectiles sobrantes desaparecen")


func test_slot_reuse_does_not_retarget_projectile() -> void:
	var w := _world()
	w.add_tower(Vector2(0, 1), 3.0, 10.0, 1.0, 1.0)  # proyectil muy lento
	var a := w.spawn_enemy(1.0, 0.0, 0.5)
	_run(w, 1)  # dispara a A
	w._damage_enemy(a, 99.0)  # A muere antes del impacto
	w.drain_events()  # descarta los eventos de este golpe manual
	var b := w.spawn_enemy(10.0, 0.0, 0.5)  # B reutiliza el hueco de A
	check(a == b, "el hueco se reutiliza")
	var ev := _run(w, 60)
	check(_count(ev, &"enemy_hit") == 0, "el proyectil de A no daña a B")
	check(w.e_hp[b] == 10.0, "B intacto")


# --- Determinismo -------------------------------------------------------------

func test_determinism() -> void:
	var hashes := []
	for run in 2:
		var w := SimWorld.new(PackedVector2Array([Vector2(0, 0), Vector2(8, 0), Vector2(8, 8)]), 7)
		w.add_tower(Vector2(7, 1), 3.0, 0.4, 1.0)
		w.add_tower(Vector2(9, 5), 3.0, 0.7, 2.0)
		for i in 300:
			if i % 10 == 0:
				w.spawn_enemy(5.0, w.rng.randf_range(1.0, 2.0))
			w.step()
			w.drain_events()
		hashes.append(w.state_hash())
	check(hashes[0] == hashes[1], "misma semilla y comandos → mismo estado")
