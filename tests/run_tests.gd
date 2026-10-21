## Tests headless de la simulación (sin dependencias externas).
## Uso:  godot --headless --path . --script res://tests/run_tests.gd
## Sale con código 0 si todo pasa y con 1 si algo falla.
extends SceneTree

const SimWorld := preload("res://src/sim/sim_world.gd")
const SimPath := preload("res://src/sim/sim_path.gd")
const Iso := preload("res://src/view/iso.gd")
const ContentDB := preload("res://src/content/content_db.gd")

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


# --- Mapa del Reino del Continue ----------------------------------------------

func _load_map() -> Node:
	return load("res://maps/continue_01.tscn").instantiate()


func test_map_def_is_valid() -> void:
	var map := _load_map()
	var def = map.build_def()
	map.free()
	var problems: PackedStringArray = def.validate()
	check(problems.is_empty(), "mapa válido: %s" % ", ".join(problems))
	check(def.routes.size() == 1, "una ruta (MVP)")
	check(def.build_spots.size() == 3, "tres posiciones de construcción, hay %d" % def.build_spots.size())
	var route: PackedVector2Array = def.routes[0]
	check(route[0].x == 0.0 or route[0].y == 0.0, "la ruta entra por un borde del mapa: %s" % route[0])
	var last := route[route.size() - 1]
	check(last.x == def.size.x or last.y == def.size.y, "la ruta sale por un borde del mapa: %s" % last)


func test_tilemap_matches_iso_projection() -> void:
	# El TileMapLayer de Godot y nuestra proyección deben coincidir: si no, la
	# simulación y el suelo dibujado quedarían desalineados.
	var map := _load_map()
	var ground: TileMapLayer = map.get_node("Ground")
	for cell in [Vector2i(0, 0), Vector2i(3, 5), Vector2i(17, 11)]:
		var godot_center := ground.position + ground.map_to_local(cell)
		var ours := Iso.to_screen(Vector2(cell) + Vector2(0.5, 0.5))
		check(godot_center.is_equal_approx(ours), "centro de %s: Godot %s vs Iso %s" % [cell, godot_center, ours])
	map.free()


func test_ground_path_tiles_match_route() -> void:
	var map := _load_map()
	var def = map.build_def()
	var ground: TileMapLayer = map.get_node("Ground")
	var path_tiles: Dictionary = def.path_tiles()
	var mismatches := 0
	for y in def.size.y:
		for x in def.size.x:
			var is_path_tile := ground.get_cell_atlas_coords(Vector2i(x, y)) == Vector2i(3, 0)
			if is_path_tile != path_tiles.has(Vector2i(x, y)):
				mismatches += 1
	map.free()
	check(mismatches == 0, "el camino pintado coincide con la ruta lógica (%d diferencias)" % mismatches)


func test_enemy_traverses_real_map_route() -> void:
	var map := _load_map()
	var def = map.build_def()
	map.free()
	var w := SimWorld.new(def.routes[0], 1)
	var speed := 1.6
	w.spawn_enemy(10.0, speed)
	var expected := int(ceil(w.path.length / speed * SimWorld.TICK_RATE))
	var leaked_at := -1
	for i in expected + 30:
		w.step()
		if _count(w.drain_events(), &"enemy_leaked") > 0:
			leaked_at = w.tick
			break
	check(absi(leaked_at - expected) <= 1, "recorre la ruta en %d ticks (esperado %d)" % [leaked_at, expected])
	check(w.base_hp == 19, "llega a la base y le resta vida")


# --- Contenido -----------------------------------------------------------------

var _db_cache = null


func _db():
	if _db_cache == null:
		_db_cache = ContentDB.load_all()
	return _db_cache


func _mission_world() -> SimWorld:
	var db = _db()
	var mission: MissionDef = db.missions[&"continue_01"]
	var map: Node = load(mission.map_scene).instantiate()
	var def = map.build_def()
	map.free()
	var w := SimWorld.new(def.routes, 99)
	w.setup_mission(db, mission, def)
	return w


func test_content_is_consistent() -> void:
	var db = _db()
	check(db.towers.size() == 3 and db.enemies.size() == 3, "3 torres y 3 enemigos cargados")
	var mission: MissionDef = db.missions[&"continue_01"]
	for t in mission.towers:
		check(db.towers.has(StringName(t)), "la misión usa una torre existente: %s" % t)
	for w in mission.waves:
		for e in w.enemies:
			check(db.enemies.has(StringName(e)), "la oleada usa un enemigo existente: %s" % e)
		check(w.counts.size() == w.enemies.size() and w.spacing.size() == w.enemies.size()
				and w.start_delay.size() == w.enemies.size(), "arrays de la oleada en paralelo")
	for t: TowerDef in db.towers.values():
		var levels := t.max_level()
		for arr in [t.damage, t.interval, t.range_tiles]:
			check(arr.size() == levels, "%s: un valor por nivel" % t.id)


# --- Combate: armadura y efectos --------------------------------------------------

func _straight_with(enemy_id: StringName) -> Array:
	var w := _world()
	var slot := w.spawn(_db().enemies[enemy_id], 0, 5.0)
	w.drain_events()
	return [w, slot]


func test_armor_reduces_by_damage_type() -> void:
	var r := _straight_with(&"cascaron")  # armadura 0.6
	var w: SimWorld = r[0]
	var s: int = r[1]
	var hp := w.e_hp[s]
	w.damage_enemy(s, 10.0, &"kinetic")
	check(is_equal_approx(hp - w.e_hp[s], 4.0), "cinético: 10 × (1 − 0.6) = 4")
	hp = w.e_hp[s]
	w.damage_enemy(s, 10.0, &"magic")
	check(is_equal_approx(hp - w.e_hp[s], 10.0), "mágico ignora la armadura")
	hp = w.e_hp[s]
	w.damage_enemy(s, 10.0, &"digital", 0.5)
	check(is_equal_approx(hp - w.e_hp[s], 7.0), "penetración 0.5: armadura efectiva 0.3")


func test_corruption_amplifies_other_damage_types() -> void:
	var r := _straight_with(&"glitchling")
	var w: SimWorld = r[0]
	var s: int = r[1]
	var corr: EffectDef = _db().towers[&"pixeladora"].on_hit_effect
	for i in 5:
		w.effects.apply(w, s, corr)
	check(w.effects.stacks_of(s, &"corruption") == 3, "la corrupción se limita a 3 pilas")
	w.e_hp[s] = 100.0
	w.damage_enemy(s, 10.0, &"kinetic")
	check(is_equal_approx(100.0 - w.e_hp[s], 14.5), "cinético +45 %% con 3 pilas (%.2f)" % (100.0 - w.e_hp[s]))
	w.e_hp[s] = 100.0
	w.damage_enemy(s, 10.0, &"digital")
	check(is_equal_approx(100.0 - w.e_hp[s], 10.0), "la corrupción no amplifica el daño digital")
	for i in roundi(4.0 * SimWorld.TICK_RATE) + 1:
		w.effects.step(w)
	check(w.effects.stacks_of(s, &"corruption") == 0, "la corrupción expira a los 4 s")


func test_three_seals_root_then_immunity() -> void:
	var r := _straight_with(&"glitchling")
	var w: SimWorld = r[0]
	var s: int = r[1]
	var seal: EffectDef = _db().towers[&"grimorio"].on_hit_effect
	w.effects.apply(w, s, seal)
	check(is_equal_approx(w.effects.speed_mult[s], 0.8), "1 sello: velocidad × 0.8")
	w.effects.apply(w, s, seal)
	check(is_equal_approx(w.effects.speed_mult[s], 0.64), "2 sellos: velocidad × 0.64")
	w.effects.apply(w, s, seal)
	check(w.effects.rooted[s] == 1, "3 sellos: inmovilizado")
	check(w.effects.stacks_of(s, &"seal") == 0, "los sellos se consumen al inmovilizar")
	var d0 := w.e_dist[s]
	for i in 30:  # 1 s < 1.2 s de inmovilización
		w.step()
	check(is_equal_approx(w.e_dist[s], d0), "no avanza mientras está inmovilizado")
	check(not w.effects.apply(w, s, seal), "inmune a nuevos sellos justo después")
	for i in 70:  # > 3 s desde el disparo del efecto
		w.step()
	check(w.effects.rooted[s] == 0 and w.e_dist[s] > d0, "vuelve a moverse")
	check(w.effects.apply(w, s, seal), "acabada la inmunidad, acepta sellos de nuevo")


func test_rebote_hits_distinct_targets() -> void:
	var w := _world()
	var reb: TowerDef = _db().towers[&"rebote"]  # nivel 1: 2 rebotes → 3 objetivos
	w.place_tower(reb, Vector2(4, 1), 1)
	for d in [3.0, 3.6, 4.2, 4.8, 5.4]:
		w.spawn_enemy(1000.0, 0.0, d)
	var ev := _run(w, 25)  # tiempo para un disparo y sus rebotes, no para el segundo
	var hits := ev.filter(func(e): return e.type == &"enemy_hit")
	var slots := {}
	for h in hits:
		slots[h.slot] = true
	check(hits.size() == 3 and slots.size() == 3, "un disparo alcanza 3 enemigos distintos (%d impactos, %d distintos)" % [hits.size(), slots.size()])
	check(hits[1].amount < hits[0].amount, "cada rebote hace menos daño")


func test_rebote_weak_against_single_target() -> void:
	var w := _world()
	w.place_tower(_db().towers[&"rebote"], Vector2(4, 1), 1)
	w.spawn_enemy(1000.0, 0.0, 4.0)
	var ev := _run(w, 25)
	check(_count(ev, &"enemy_hit") == 1, "con un solo enemigo no hay rebote (no repite objetivo)")


# --- Economía -------------------------------------------------------------------

func test_economy_rules() -> void:
	var w := _mission_world()
	check(w.gold == 150, "oro inicial 150")
	check(w.build(0, &"pixeladora") == &"ok" and w.gold == 80, "construir cuesta 70")
	check(w.build(0, &"grimorio") == &"occupied", "posición ocupada")
	check(w.build(7, &"grimorio") == &"invalid_spot", "posición inexistente")
	check(w.build(1, &"no_existe") == &"unknown_tower", "torre desconocida")
	check(w.build(1, &"rebote") == &"ok" and w.gold == 0, "construir Rebote con justo 80")
	check(w.build(2, &"grimorio") == &"no_gold" and w.gold == 0, "sin oro no se construye ni se gasta")
	check(w.upgrade(0) == &"no_gold", "sin oro no se mejora")
	w.gold = 1000
	check(w.upgrade(0) == &"ok" and w.gold == 945, "mejorar a nivel 2 cuesta 55")
	check(w.upgrade(0) == &"ok" and w.upgrade(0) == &"max_level", "nivel máximo 3")
	var invested := 70 + 55 + 90
	var before := w.gold
	check(w.sell(0) == &"ok" and w.gold == before + floori(invested * 0.7), "vender devuelve el 70 % de lo invertido")
	check(w.tower_at(0).is_empty(), "la posición queda libre")
	check(w.sell(0) == &"empty", "no se vende una posición vacía")


func test_kill_bounty_and_leak_damage() -> void:
	var w := _mission_world()
	var casc: EnemyDef = _db().enemies[&"cascaron"]
	var s := w.spawn(casc)
	var gold0 := w.gold
	w.damage_enemy(s, 1000.0, &"magic")
	check(w.gold == gold0 + casc.bounty, "eliminar da la recompensa del enemigo")
	w.spawn(casc, 0, w.path.length - 0.01)
	w.step()
	check(w.base_hp == 20 - casc.base_damage, "al llegar quita base_damage a la base")


# --- Oleadas y resultado -----------------------------------------------------------

func test_wave_spawns_and_blocks_overlap() -> void:
	var w := _mission_world()
	check(w.start_next_wave() == &"ok", "lanza la oleada 1")
	check(w.start_next_wave() == &"wave_active", "no se lanza otra con una activa")
	var spawned := 0
	for i in 30 * 15:
		w.step()
		spawned += _count(w.drain_events(), &"enemy_spawned")
	check(spawned == w.mission.waves[0].total_enemies(), "aparecen los %d enemigos de la oleada" % spawned)


## Estrategia scripted: construye en orden y mejora entre oleadas.
func _play(w: SimWorld, plan: Array) -> SimWorld.Outcome:
	for i in 30 * 60 * 10:
		for action in plan:
			if action[0] == &"build" and w.tower_at(action[1]).is_empty():
				w.build(action[1], action[2])
			elif action[0] == &"upgrade" and not w.wave_active:
				w.upgrade(action[1])
		if not w.wave_active and not w.is_over():
			w.start_next_wave()
		w.step()
		w.drain_events()
		if w.is_over():
			break
	return w.outcome


func test_mission_without_towers_is_lost() -> void:
	var w := _mission_world()
	check(_play(w, []) == SimWorld.Outcome.DEFEAT, "sin torres se pierde")


func test_mission_with_sensible_defense_is_won() -> void:
	var w := _mission_world()
	var plan := [[&"build", 1, &"pixeladora"], [&"build", 0, &"grimorio"], [&"build", 2, &"rebote"],
		[&"upgrade", 1], [&"upgrade", 2]]
	var outcome := _play(w, plan)
	check(outcome == SimWorld.Outcome.VICTORY, "con una defensa razonable se gana (vida base %d)" % w.base_hp)


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
