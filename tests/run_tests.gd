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


# --- Mapa del mundo 1, misión 1 ----------------------------------------------

func _load_map() -> Node:
	return load("res://maps/w1/w1_m5.tscn").instantiate()


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
	var mission: MissionDef = db.missions[&"w1_m5"]
	var map: Node = load(mission.map_scene).instantiate()
	var def = map.build_def()
	map.free()
	var w := SimWorld.new(def.routes, 99)
	w.setup_mission(db, mission, def)
	return w


func test_content_is_consistent() -> void:
	var db = _db()
	check(db.towers.size() == 3 and db.enemies.size() >= 3, "3 torres y al menos 3 enemigos cargados")
	var mission: MissionDef = db.missions[&"w1_m5"]
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
	var r := _straight_with(&"enemy_armored")  # armadura 0.6
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
	var r := _straight_with(&"enemy_light")
	var w: SimWorld = r[0]
	var s: int = r[1]
	var corr: EffectDef = _db().towers[&"tower_corrupt"].on_hit_effect
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
	var r := _straight_with(&"enemy_light")
	var w: SimWorld = r[0]
	var s: int = r[1]
	var seal: EffectDef = _db().towers[&"tower_seal"].on_hit_effect
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


func test_bounce_hits_distinct_targets() -> void:
	var w := _world()
	var reb: TowerDef = _db().towers[&"tower_bounce"]  # nivel 1: 2 rebotes → 3 objetivos
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


func test_bounce_weak_against_single_target() -> void:
	var w := _world()
	w.place_tower(_db().towers[&"tower_bounce"], Vector2(4, 1), 1)
	w.spawn_enemy(1000.0, 0.0, 4.0)
	var ev := _run(w, 25)
	check(_count(ev, &"enemy_hit") == 1, "con un solo enemigo no hay rebote (no repite objetivo)")


# --- Economía -------------------------------------------------------------------

func test_economy_rules() -> void:
	var w := _mission_world()
	check(w.gold == 150, "oro inicial 150")
	check(w.build(0, &"tower_corrupt") == &"ok" and w.gold == 80, "construir cuesta 70")
	check(w.build(0, &"tower_seal") == &"occupied", "posición ocupada")
	check(w.build(7, &"tower_seal") == &"invalid_spot", "posición inexistente")
	check(w.build(1, &"no_existe") == &"unknown_tower", "torre desconocida")
	check(w.build(1, &"tower_bounce") == &"ok" and w.gold == 0, "construir la torre de rebote con justo 80")
	check(w.build(2, &"tower_seal") == &"no_gold" and w.gold == 0, "sin oro no se construye ni se gasta")
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
	var casc: EnemyDef = _db().enemies[&"enemy_armored"]
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
	var plan := [[&"build", 1, &"tower_corrupt"], [&"build", 0, &"tower_seal"], [&"build", 2, &"tower_bounce"],
		[&"upgrade", 1], [&"upgrade", 2]]
	var outcome := _play(w, plan)
	check(outcome == SimWorld.Outcome.VICTORY, "con una defensa razonable se gana (vida base %d)" % w.base_hp)


# --- Héroes -----------------------------------------------------------------------

func _hero_world(hero_id: StringName, pos: Vector2) -> SimWorld:
	var w := _world([Vector2(0, 0), Vector2(20, 0)])
	w.heroes.add_hero(_db().heroes[hero_id], pos)
	return w


func test_hero_moves_onto_the_path() -> void:
	var w := _hero_world(&"hero_blade", Vector2(5, 0))
	check(w.move_hero(0, Vector2(9, 3)) == &"ok", "orden de movimiento aceptada")
	check(w.heroes.heroes[0].target.is_equal_approx(Vector2(9, 0)), "el destino se ajusta al camino")
	_run(w, 60)
	check(w.heroes.heroes[0].pos.is_equal_approx(Vector2(9, 0)), "llega al punto del camino y se detiene")


func test_hero_blocks_up_to_capacity() -> void:
	var w := _hero_world(&"hero_portal", Vector2(10, 0))  # bloquea a 2
	var slots := []
	for d in [0.0, 1.5, 3.0]:
		slots.append(w.spawn_enemy(100000.0, 2.0, d))
	_run(w, 30 * 6)
	var blocked := slots.filter(func(s): return w.e_blocker[s] == 0)
	check(blocked.size() == 2, "bloquea a 2 enemigos (%d)" % blocked.size())
	for s in blocked:
		check(w.e_pos[s].distance_to(Vector2(10, 0)) <= 1.0, "los bloqueados se detienen junto al héroe")
	var free: Array = slots.filter(func(s): return w.e_blocker[s] < 0)
	check(free.size() == 1 and w.e_dist[free[0]] > 11.0, "el tercero sigue su camino")
	check(w.heroes.heroes[0].hp < _db().heroes[&"hero_portal"].max_hp, "los bloqueados le hacen daño")


func test_hero_dies_releases_and_respawns() -> void:
	var w := _hero_world(&"hero_portal", Vector2(10, 0))
	var def: HeroDef = _db().heroes[&"hero_portal"]
	var h: Dictionary = w.heroes.heroes[0]
	var e := w.spawn_enemy(100000.0, 2.0, 8.0)
	_run(w, 30)
	check(w.e_blocker[e] == 0, "enemigo bloqueado")
	h.hp = 3.0  # dos golpes de 2 lo derriban
	var ev := _run(w, 70)
	check(_count(ev, &"hero_died") == 1, "el héroe cae")
	check(w.e_blocker[e] == -1, "al caer suelta al enemigo")
	check(w.move_hero(0, Vector2(4, 0)) == &"dead", "caído no acepta órdenes")
	var d0 := w.e_dist[e]
	_run(w, 10)
	check(w.e_dist[e] > d0, "el enemigo liberado avanza")
	ev = _run(w, roundi(def.respawn_time * SimWorld.TICK_RATE))
	check(_count(ev, &"hero_respawned") == 1, "reaparece tras %d s" % roundi(def.respawn_time))
	check(h.hp == def.max_hp and h.pos == h.spawn, "con la vida completa en su posición inicial")


func test_hero_regenerates_when_not_fighting() -> void:
	var w := _hero_world(&"hero_blade", Vector2(10, 0))
	var h: Dictionary = w.heroes.heroes[0]
	h.hp = 10.0
	_run(w, 60)
	var def: HeroDef = _db().heroes[&"hero_blade"]
	check(is_equal_approx(h.hp, 10.0 + def.regen_per_second * 2.0), "recupera %.0f de vida por segundo" % def.regen_per_second)


func test_blade_basic_attack_builds_capped_charge() -> void:
	var w := _hero_world(&"hero_blade", Vector2(6, 1))
	w.spawn_enemy(1000.0, 0.0, 6.0)  # enemigo inmóvil al lado
	var hero: Dictionary = w.heroes.heroes[0]
	_run(w, 30 * 3)  # 3 s a 0,6 s por golpe: 5 golpes
	check(hero.charge == 5, "cada golpe suma carga (%d)" % hero.charge)
	_run(w, 30 * 3)
	check(hero.charge == 6, "la carga se limita a 6")


func test_blade_line_strike_hits_only_aligned_enemies() -> void:
	var w := _hero_world(&"hero_blade", Vector2(0, 5))  # lejos de la ruta: sin ataque básico
	var hero: Dictionary = w.heroes.heroes[0]
	hero.charge = 3
	var aligned := [w.spawn_enemy(1000.0, 0.0, 2.0), w.spawn_enemy(1000.0, 0.0, 4.0)]
	var off := w.spawn_enemy(1000.0, 0.0, 12.0)
	w.heroes.heroes[0].pos = Vector2(0, 0)
	check(w.cast_ability(0, Vector2(1, 0)) == &"ok", "lanza el corte")
	var def: HeroDef = _db().heroes[&"hero_blade"]
	var expected := (def.ability_damage + def.ability_damage_per_charge * 3) * (1.0 - 0.0)
	for s in aligned:
		check(is_equal_approx(1000.0 - w.e_hp[s], expected), "daño %.1f a un enemigo alineado" % expected)
	check(w.e_hp[off] == 1000.0, "un enemigo fuera de la línea no recibe daño")
	check(hero.charge == 0, "el corte consume la carga")
	check(w.cast_ability(0, Vector2(1, 0)) == &"cooldown", "respeta el tiempo de recarga")
	_run(w, roundi(def.ability_cooldown * SimWorld.TICK_RATE))
	check(w.cast_ability(0, Vector2(1, 0)) == &"ok", "disponible al terminar la recarga")


func test_portal_redirects_tower_fire_while_active() -> void:
	var w := _hero_world(&"hero_portal", Vector2(2, 3))
	var def: HeroDef = _db().heroes[&"hero_portal"]
	w.add_tower(Vector2(2, 4), 1.5, 0.5, 2.0, 20.0)  # alcance corto: no llega a la ruta
	var target := w.spawn_enemy(1000.0, 0.0, 15.0)    # en (15, 0), lejos de todo
	var ev := _run(w, 60)
	check(_count(ev, &"enemy_hit") == 0, "sin portal la torre no alcanza al enemigo")
	check(w.cast_ability(0, Vector2(15, 1)) == &"out_of_range", "la salida debe estar en alcance")
	check(w.cast_ability(0, Vector2(9, 1)) == &"ok", "abre el portal")
	w.e_pos[target] = Vector2(9, 0)  # el enemigo junto a la salida
	w.e_dist[target] = 9.0
	ev = _run(w, roundi(def.ability_duration * SimWorld.TICK_RATE))
	var hits := ev.filter(func(e): return e.type == &"enemy_hit" and e.slot == target)
	check(hits.size() >= 5, "con portal la torre alcanza al enemigo (%d impactos)" % hits.size())
	check(is_equal_approx(hits[0].amount, 2.0 * def.ability_damage_mult), "daño ×%.2f a través del portal" % def.ability_damage_mult)
	check(_count(ev, &"portal_closed") == 1, "el portal se cierra al acabar su duración")
	ev = _run(w, 60)
	check(_count(ev, &"enemy_hit") == 0, "cerrado el portal, la torre deja de alcanzarlo")


# --- Sinergia «corrupción en enemigos ralentizados» ------------------------------

func _synergy_world() -> SimWorld:
	var w := _world([Vector2(0, 0), Vector2(20, 0)])
	w.synergies = _db().synergies.values()
	return w


func test_synergy_extra_stack_only_when_slowed() -> void:
	var w := _synergy_world()
	var corr: EffectDef = _db().towers[&"tower_corrupt"].on_hit_effect
	var seal: EffectDef = _db().towers[&"tower_seal"].on_hit_effect
	var normal := w.spawn_enemy(100.0, 0.0, 2.0)
	var slowed := w.spawn_enemy(100.0, 0.0, 10.0)
	w.effects.apply(w, slowed, seal)
	w.effects.apply(w, normal, corr)
	w.effects.apply(w, slowed, corr)
	check(w.effects.stacks_of(normal, &"corruption") == 1, "sin ralentizar: 1 pila")
	check(w.effects.stacks_of(slowed, &"corruption") == 2, "ralentizado: 1 + 1 pila extra")
	var ev := w.drain_events()
	check(_count(ev, &"synergy_triggered") == 1, "la sinergia solo se activa en el ralentizado")


func test_synergy_spreads_on_reaching_max_without_chaining() -> void:
	var w := _synergy_world()
	var corr: EffectDef = _db().towers[&"tower_corrupt"].on_hit_effect
	var seal: EffectDef = _db().towers[&"tower_seal"].on_hit_effect
	var src := w.spawn_enemy(100.0, 0.0, 10.0)
	var near := []
	for d in [9.0, 9.5, 10.5, 11.0]:  # 4 vecinos; la propagación alcanza a 3
		near.append(w.spawn_enemy(100.0, 0.0, d))
	var far := w.spawn_enemy(100.0, 0.0, 16.0)
	for s in near:  # los vecinos también ralentizados: comprueba que no encadenan
		w.effects.apply(w, s, seal)
	w.effects.apply(w, src, seal)
	w.drain_events()
	w.effects.apply(w, src, corr)  # 2 pilas
	check(_count(w.drain_events(), &"synergy_spread") == 0, "no se propaga antes del máximo")
	w.effects.apply(w, src, corr)  # 3 pilas = máximo → propaga
	var ev := w.drain_events()
	var spreads := ev.filter(func(e): return e.type == &"synergy_spread")
	check(spreads.size() == 1 and spreads[0].targets.size() == 3, "se propaga a 3 enemigos cercanos")
	var corrupted := 0
	for s in near:
		corrupted += 1 if w.effects.stacks_of(s, &"corruption") > 0 else 0
	check(corrupted == 3, "3 vecinos corrompidos")
	check(w.effects.stacks_of(far, &"corruption") == 0, "el lejano no se corrompe")
	check(_count(ev, &"synergy_triggered") == 1, "la propagación no reactiva la sinergia (sin cadenas)")
	w.effects.apply(w, src, corr)
	check(_count(w.drain_events(), &"synergy_spread") == 0, "ya en el máximo, no vuelve a propagarse")


## Aceptación: las habilidades cambian el desarrollo del combate.
## Oleada 3 con una sola torre (no basta por sí sola). Kira se coloca en la
## esquina (14, 4) y corta a lo largo de la columna por la que suben los enemigos
## cada vez que su habilidad está lista.
func test_hero_abilities_change_the_outcome() -> void:
	var leaks := []
	for use_abilities in [false, true]:
		var w := _mission_world()
		w.build(1, &"tower_corrupt")
		w.wave_index = 1  # la siguiente es la 3
		w.start_next_wave()
		var blade := 1
		w.move_hero(blade, Vector2(14, 4.5))
		var leaked := 0
		for i in 30 * 60:
			if use_abilities and w.enemy_count > 0:
				w.cast_ability(blade, Vector2(14, 10))
			w.step()
			leaked += _count(w.drain_events(), &"enemy_leaked")
			if not w.wave_active or w.is_over():
				break
		leaks.append(leaked)
	check(leaks[1] < leaks[0], "usar habilidades reduce las fugas (%d → %d)" % [leaks[0], leaks[1]])


# --- Fase 5: jefe, núcleo, invocación, ritmo de oleadas y resultados -------------

func test_core_revives_enemy_once_if_not_destroyed() -> void:
	var w := _world()
	var boss: EnemyDef = _db().enemies[&"enemy_boss_w1"]
	var s := w.spawn(boss, 0, 4.0)
	w.damage_enemy(s, 99999.0, &"magic")
	var ev := w.drain_events()
	check(_count(ev, &"core_dropped") == 1, "al morir deja un núcleo")
	var core: int = ev.filter(func(e): return e.type == &"core_dropped")[0].slot
	check(w.e_def[core] == boss.revive_core, "el núcleo es su EnemyDef de núcleo")
	ev = _run(w, roundi(boss.revive_delay * SimWorld.TICK_RATE))
	var revived := ev.filter(func(e): return e.type == &"enemy_revived")
	check(revived.size() == 1, "si el núcleo sobrevive, el jefe reaparece")
	var r: int = revived[0].slot
	check(is_equal_approx(w.e_hp[r], boss.hp * boss.revive_hp_ratio), "con el %d %% de su vida" % roundi(boss.revive_hp_ratio * 100))
	check(w.e_dist[r] >= 4.0 and w.e_dist[r] < 4.2, "en el mismo punto de la ruta")
	w.damage_enemy(r, 99999.0, &"magic")
	check(_count(w.drain_events(), &"core_dropped") == 0, "solo reaparece una vez")


func test_destroying_core_prevents_revive() -> void:
	var w := _world()
	var boss: EnemyDef = _db().enemies[&"enemy_boss_w1"]
	var s := w.spawn(boss, 0, 4.0)
	w.damage_enemy(s, 99999.0, &"magic")
	var core: int = w.drain_events().filter(func(e): return e.type == &"core_dropped")[0].slot
	w.damage_enemy(core, 99999.0, &"magic")
	var ev := _run(w, roundi(boss.revive_delay * SimWorld.TICK_RATE) + 5)
	check(_count(ev, &"enemy_revived") == 0, "con el núcleo destruido no reaparece")
	check(w.enemy_count == 0, "no queda nada en el mapa")


func test_boss_summons_periodically() -> void:
	var w := _world([Vector2(0, 0), Vector2(200, 0)])  # ruta larga: nadie escapa
	var boss: EnemyDef = _db().enemies[&"enemy_boss_w1"]
	w.spawn(boss, 0, 1.0)
	var ev := _run(w, roundi(boss.summon_interval * SimWorld.TICK_RATE) * 2 + 1)
	check(_count(ev, &"enemy_summoned") == 2, "invoca cada %.0f s" % boss.summon_interval)
	check(w.enemy_count == 1 + 2 * boss.summon_count, "%d invocados en total" % (2 * boss.summon_count))


func test_next_wave_starts_automatically_after_countdown() -> void:
	var w := _mission_world()
	w.start_next_wave()
	var cleared_at := -1
	for i in 30 * 60:
		# Despeja la oleada al instante para medir solo la cuenta atrás.
		for s in w.e_alive.size():
			if w.e_alive[s] == 1:
				w.damage_enemy(s, 99999.0, &"magic")
		w.step()
		var ev := w.drain_events()
		if _count(ev, &"wave_cleared") > 0:
			cleared_at = w.tick
		if _count(ev, &"wave_started") > 0 and cleared_at >= 0:
			var waited := (w.tick - cleared_at) / float(SimWorld.TICK_RATE)
			check(absf(waited - SimWorld.BETWEEN_WAVES) < 0.1, "la oleada 2 empieza sola tras %.0f s (%.2f)" % [SimWorld.BETWEEN_WAVES, waited])
			return
	check(false, "la oleada 2 no empezó sola")


func test_early_call_gives_gold_for_skipped_time() -> void:
	var w := _mission_world()
	w.start_next_wave()
	for i in 30 * 60:
		for s in w.e_alive.size():
			if w.e_alive[s] == 1:
				w.damage_enemy(s, 99999.0, &"magic")
		w.step()
		if not w.wave_active and w.next_wave_ticks > 0:
			break
	_run(w, 30 * 5)  # esperamos 5 s de los 20
	var gold0 := w.gold
	check(w.start_next_wave() == &"ok", "se puede adelantar")
	check(w.gold - gold0 == 15, "oro extra por los 15 s adelantados (%d)" % (w.gold - gold0))
	check(w.next_wave_ticks == -1, "la cuenta atrás se cancela")


func test_stars_and_stats() -> void:
	var w := _mission_world()
	w.outcome = SimWorld.Outcome.VICTORY
	w.base_hp = 20
	check(w.stars() == 3, "base intacta: 3 estrellas")
	w.base_hp = 12
	check(w.stars() == 2, "60 %% de la base: 2 estrellas")
	w.base_hp = 3
	check(w.stars() == 1, "victoria apurada: 1 estrella")
	w.outcome = SimWorld.Outcome.DEFEAT
	check(w.stars() == 0, "derrota: 0 estrellas")
	var w2 := _mission_world()
	w2.build(0, &"tower_corrupt")
	var s := w2.spawn(_db().enemies[&"enemy_light"])
	w2.damage_enemy(s, 999.0, &"magic")
	check(w2.stats.towers_built == 1 and w2.stats.gold_spent == 70, "estadísticas de construcción")
	check(w2.stats.kills == 1 and w2.stats.gold_earned == _db().enemies[&"enemy_light"].bounty, "estadísticas de bajas y oro")


## Aceptación de la Fase 5: la misión completa (5 oleadas + jefe) se puede ganar
## con una defensa razonable y perder sin ella, sin bloqueos del flujo.
func test_full_mission_flow() -> void:
	for plan in [[], [[&"build", 1, &"tower_corrupt"], [&"build", 0, &"tower_seal"], [&"build", 2, &"tower_bounce"],
			[&"upgrade", 1], [&"upgrade", 2], [&"upgrade", 0]]]:
		var w := _mission_world()
		w.start_next_wave()
		w.move_hero(1, Vector2(14, 4.5))
		var waves_started := 0  # el evento de la primera se recoge en el bucle
		for i in 30 * 60 * 12:
			for action in plan:
				if action[0] == &"build" and w.tower_at(action[1]).is_empty():
					w.build(action[1], action[2])
				elif action[0] == &"upgrade" and not w.wave_active:
					w.upgrade(action[1])
			if w.enemy_count > 0:
				w.cast_ability(1, Vector2(14, 10))
			w.step()
			waves_started += _count(w.drain_events(), &"wave_started")
			if w.is_over():
				break
		if plan.is_empty():
			check(w.outcome == SimWorld.Outcome.DEFEAT, "sin torres se pierde")
		else:
			check(w.outcome == SimWorld.Outcome.VICTORY, "con defensa razonable se gana la misión (base %d)" % w.base_hp)
			check(waves_started == 5, "se juegan las 5 oleadas")
			var minutes := w.tick / float(SimWorld.TICK_RATE) / 60.0
			check(minutes >= 3.0 and minutes <= 6.0, "duración en el objetivo de 3–6 min (%.1f)" % minutes)


# --- Campaña (7.1) ----------------------------------------------------------------

const CampaignRules := preload("res://src/content/campaign_rules.gd")


func test_worlds_content() -> void:
	var worlds: Array = CampaignRules.worlds_in_order(_db())
	check(worlds.size() == 6, "6 mundos")
	for i in worlds.size():
		var w: WorldDef = worlds[i]
		check(w.order == i + 1, "orden correcto de %s" % w.id)
		check(w.mission_slots.size() == 5 and w.slot_names.size() == 5, "%s: 5 huecos de misión con nombre" % w.id)
	var w1: WorldDef = worlds[0]
	check(_db().missions.has(StringName(w1.mission_slots[4])), "el hueco del jefe del mundo 1 existe (w1_m5)")
	for id in _db().missions:
		var found := false
		for w: WorldDef in worlds:
			found = found or String(id) in w.mission_slots
		check(found, "la misión %s pertenece a un mundo" % id)


## Campaña de prueba con progreso simulado (sin depender del contenido real).
func _fake_campaign(built: Array) -> Dictionary:
	var db := {worlds = {}, missions = {}}
	for wi in 2:
		var w := WorldDef.new()
		w.id = StringName("t%d" % (wi + 1))
		w.order = wi + 1
		w.mission_slots = PackedStringArray()
		for m in 3:
			var id := "t%d_m%d" % [wi + 1, m + 1]
			w.mission_slots.append(id)
			if id in built:
				db.missions[StringName(id)] = MissionDef.new()
		db.worlds[w.id] = w
	return db


func test_campaign_unlock_rules() -> void:
	var S := CampaignRules.State
	var db := _fake_campaign(["t1_m1", "t1_m3", "t2_m1"])  # t1_m2 aún no construida
	var done := {}
	var progress := func(id): return {victories = 1} if done.has(id) else {}
	check(CampaignRules.mission_state(db, 0, 0, progress) == S.AVAILABLE, "la primera misión está disponible")
	check(CampaignRules.mission_state(db, 0, 1, progress) == S.PLANNED, "un hueco sin misión está en construcción")
	check(CampaignRules.mission_state(db, 0, 2, progress) == S.LOCKED, "la siguiente construida está bloqueada")
	check(not CampaignRules.world_unlocked(db, 1, progress), "el mundo 2 está cerrado")
	done["t1_m1"] = true
	check(CampaignRules.mission_state(db, 0, 0, progress) == S.COMPLETED, "completada tras ganarla")
	check(CampaignRules.mission_state(db, 0, 2, progress) == S.AVAILABLE, "el hueco en construcción no bloquea")
	check(not CampaignRules.world_unlocked(db, 1, progress), "el mundo 2 sigue cerrado sin el jefe")
	done["t1_m3"] = true
	check(CampaignRules.world_unlocked(db, 1, progress), "al completar el mundo 1 se abre el 2")
	check(CampaignRules.mission_state(db, 1, 0, progress) == S.AVAILABLE, "primera misión del mundo 2 disponible")
	var db2 := _fake_campaign(["t1_m1", "t1_m3"])
	var only_last := {"t1_m3": true}
	var progress2 := func(id): return {victories = 1} if only_last.has(id) else {}
	check(CampaignRules.mission_state(db2, 0, 2, progress2) == S.COMPLETED,
		"una misión ya completada sigue disponible aunque falten anteriores")


# --- Elementos de mapa (7.2): monedas, bloques y plataformas -------------------

const MapDefScript := preload("res://src/content/map_def.gd")


## Mundo de prueba: ruta principal (0,0)→(20,0) y atajo (0,4)→(20,4); un héroe.
func _objects_world(objects: Array, spots := PackedVector2Array([Vector2(5, 2), Vector2(10, 2)])) -> SimWorld:
	var map := MapDefScript.new()
	map.size = Vector2i(20, 8)
	map.routes = [PackedVector2Array([Vector2(0, 0), Vector2(20, 0)]),
		PackedVector2Array([Vector2(0, 4), Vector2(20, 4)])]
	map.build_spots = spots
	map.objects = objects
	var w := SimWorld.new(map.routes, 5)
	w.build_spots = map.build_spots
	w.objects.setup(w, map)
	w.heroes.add_hero(_db().heroes[&"hero_blade"], Vector2(15, 0))
	return w


func test_coins_drop_pickup_tap_and_expire() -> void:
	var w := _objects_world([])
	w.mission = MissionDef.new()
	w.mission.coin_drop_chance = 1.0
	w.mission.coin_value = 4
	w.mission.coin_lifetime = 2.0
	var far := w.spawn_enemy(1.0, 0.0, 2.0)
	w.damage_enemy(far, 99.0)
	check(w.objects.coins.size() == 1, "un enemigo eliminado suelta una moneda")
	var uid: int = w.objects.coins[0].uid
	var gold0 := w.gold
	check(w.collect_coin(uid) == &"ok" and w.gold == gold0 + 4, "un toque recoge la moneda (+4 oro)")
	check(w.collect_coin(uid) == &"gone", "no se puede recoger dos veces")
	var near := w.spawn_enemy(1.0, 0.0, 15.2)  # junto al héroe
	w.damage_enemy(near, 99.0)
	w.drain_events()
	_run(w, 1)
	check(w.objects.coins.is_empty() and w.gold == gold0 + 8, "un héroe la recoge al pasar por encima")
	var lost := w.spawn_enemy(1.0, 0.0, 3.0)
	w.damage_enemy(lost, 99.0)
	var ev := _run(w, 61)
	check(_count(ev, &"coin_expired") == 1 and w.objects.coins.is_empty(), "si nadie la recoge, caduca")


func test_heroes_break_blocks_that_open_route_and_spot() -> void:
	var block := {id = "Atajo", kind = &"block", pos = Vector2(15, 1.5),
		props = {hp = 9.0, reward_gold = 30, opens_route = 1, opens_spot = 1}}
	var w := _objects_world([block])
	check(not w.objects.route_open(1) and not w.objects.spot_open(1), "el atajo y la plataforma empiezan cerrados")
	w.content = _db()
	w.gold = 1000
	check(w.build(1, &"tower_corrupt") == &"spot_locked", "no se construye en una posición cerrada")
	w.mission = MissionDef.new()
	w.allowed_towers = PackedStringArray(["tower_corrupt"])
	var wave := WaveDef.new()
	wave.enemies = PackedStringArray(["enemy_light"])
	wave.counts = PackedInt32Array([1])
	wave.spacing = PackedFloat32Array([1.0])
	wave.start_delay = PackedFloat32Array([0.0])
	wave.route = PackedInt32Array([1])
	w.mission.waves = [wave, wave]
	w.start_next_wave()
	_run(w, 2)
	check(w.e_route[0] == 0, "un grupo del atajo cerrado entra por la ruta principal")
	var ev := _run(w, 30 * 3)
	check(_count(ev, &"block_broken") == 1, "el héroe cercano y libre rompe el bloque")
	check(_count(ev, &"route_opened") == 1 and w.objects.route_open(1), "romperlo abre el atajo")
	check(w.objects.spot_open(1) and w.build(1, &"tower_corrupt") == &"ok", "y la posición de construcción")


func test_platform_moves_spot_and_tower() -> void:
	var plat := {id = "Plataforma", kind = &"platform", pos = Vector2(5, 2),
		props = {spot = 0, to = Vector2(5, 6), period = 4.0}}
	var w := _objects_world([plat])
	w.place_tower(TowerDef.new(), w.build_spots[0], 1, 0)
	var t: Dictionary = w.towers[0]
	_run(w, 60)  # medio periodo: en el otro extremo
	check(w.build_spots[0].distance_to(Vector2(5, 6)) < 0.05, "a mitad del periodo la plataforma está en el otro extremo")
	check(t.pos == w.build_spots[0], "la torre se mueve con su plataforma")
	_run(w, 60)
	check(w.build_spots[0].distance_to(Vector2(5, 2)) < 0.05, "y vuelve al terminar el periodo")


## Restricción de diseño: cada misión del mundo 1 se gana con el equipo INICIAL
## (torres y héroes), con alguna colocación de las torres y los héroes quietos
## (un jugador real además los mueve y usa sus habilidades).
func test_world1_missions_winnable_with_starters() -> void:
	var Balance = load("res://tools/balance.gd")
	for id in ["w1_m1", "w1_m2", "w1_m3", "w1_m4", "w1_m5"]:
		var won := false
		var best_stars := 0
		for order in Balance.orders(3):
			var r: Dictionary = Balance.play(_db(), StringName(id), "equipo inicial + mejoras", order)
			if r.world.outcome == SimWorld.Outcome.VICTORY:
				won = true
				best_stars = maxi(best_stars, r.world.stars())
		check(won, "%s se puede ganar con el equipo inicial (mejor: %d★)" % [id, best_stars])
		var lose: Dictionary = Balance.play(_db(), StringName(id), "sin torres")
		check(lose.world.outcome == SimWorld.Outcome.DEFEAT, "%s se pierde sin torres" % id)


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
