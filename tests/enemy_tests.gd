## Tests de los enemigos nuevos (revoloteador y escupidor) en la sala de prueba.
## Uso: godot --headless --path . --script res://tests/enemy_tests.gd
extends SceneTree

const T := 32.0
const FLOOR := 22.0
var _failures := 0
var _checks := 0
var room: TestRoom
var kira: Kira


func check(cond: bool, msg: String) -> void:
	_checks += 1
	print(("  ✓ " if cond else "  ✗ ") + msg)
	if not cond:
		_failures += 1


func _initialize() -> void:
	_run.call_deferred()


func _physics(n: int) -> void:
	for i in n:
		await physics_frame


func _clear() -> void:
	for e in room.enemies:
		if is_instance_valid(e):
			e.queue_free()
	room.enemies.clear()
	for n in room.get_children():
		if n is Projectile:
			n.queue_free()


func _spawn(kind: String, col: float, row: float) -> Node2D:
	var e := Enemies.create(kind, Vector2(col * T, row * T), kira)
	e.died.connect(room._on_enemy_died)
	room.add_child(e)
	room.enemies.append(e)
	return e


func _reset_kira(col: float) -> void:
	kira.respawn(Vector2(col * T, FLOOR * T))
	kira.scripted_input = {"x": 0.0}


func _slash(input := {"x": 0.0, "attack": true}) -> void:
	kira.scripted_input = input
	await _physics(1)
	kira.scripted_input = {"x": 0.0}
	await _physics(int(KiraCombat.COOLDOWN * 60) + 1)


func _projectiles() -> Array:
	return room.get_children().filter(func(n): return n is Projectile and not n.is_queued_for_deletion())


func _run() -> void:
	room = load("res://src/world/test_room.tscn").instantiate()
	root.add_child(room)
	room.hitstop_enabled = false
	room.enemy_spawns.clear()
	kira = room.kira
	_clear()
	await _physics(3)

	print("Revoloteador")
	_reset_kira(4.5)
	var f: Flyer = _spawn("flyer", 25.0, 17.0)
	var home := f.position
	var max_off := 0.0
	for i in 120:
		await physics_frame
		max_off = maxf(max_off, f.position.distance_to(home))
	check(f.state == Flyer.State.HOVER and max_off < 16.0, "lejos de Kira, flota en su sitio (se mueve %.0f px)" % max_off)
	kira.place_at(Vector2(22.5 * T, FLOOR * T))
	var saw_windup := false
	var closest := INF
	var kira_center := kira.position + Vector2(0, -22)
	kira.health.invulnerable = 10.0  # para medir el picado sin que la empuje
	for i in 90:
		await physics_frame
		if f.state == Flyer.State.WINDUP:
			saw_windup = true
		closest = minf(closest, f.position.distance_to(kira_center))
	check(saw_windup, "al acercarse Kira, tiembla para avisar")
	check(closest < 24.0, "y se lanza en picado hacia ella (llega a %.0f px)" % closest)
	kira.place_at(Vector2(4.5 * T, FLOOR * T))
	for i in 300:
		await physics_frame
		if f.state == Flyer.State.HOVER:
			break
	check(f.state == Flyer.State.HOVER and f.position.distance_to(home) < 20.0, "después vuelve a su sitio")
	kira.health.reset()
	kira.health.invulnerable = 0.0

	print("Revoloteador: daño y golpes")
	_clear()
	_reset_kira(10.5)
	await _physics(5)
	var f2: Flyer = _spawn("flyer", 12.0, FLOOR - 0.8)
	f2.set_physics_process(false)  # quieto, a la altura del tajo
	await _physics(2)
	await _slash()
	check(f2.health.hp == Flyer.MAX_HP - 1, "el tajo le quita 1 de vida")
	await _slash()
	check(not is_instance_valid(f2), "2 tajos lo eliminan")
	_clear()
	var f3: Flyer = _spawn("flyer", 30.5, FLOOR - 0.5)
	f3.set_physics_process(false)
	kira.respawn(Vector2(30.5 * T, (FLOOR - 4.0) * T))  # sin el aturdimiento de place_at
	var bounced := false
	for i in 60:
		var near := kira.position.y > f3.position.y - 50.0
		kira.scripted_input = {"x": 0.0, "y": 1.0, "attack": near}
		await physics_frame
		if kira.velocity.y < -400.0:
			bounced = true
			break
	check(bounced, "rebotar sobre él con el tajo hacia abajo")
	kira.scripted_input = {"x": 0.0}
	_clear()
	var f4: Flyer = _spawn("flyer", 3.0, 12.0)  # cerca de la pared izquierda (columna 0)
	f4.state = Flyer.State.DIVE
	f4._dive_dir = Vector2.LEFT
	f4._t = 2.0
	var min_x := f4.position.x
	for i in 40:
		await physics_frame
		min_x = minf(min_x, f4.position.x)
	check(min_x >= 1.0 * T + Flyer.SIZE.x / 2 - 1.0, "no atraviesa las paredes (x mínima %.0f)" % min_x)

	print("Escupidor")
	_clear()
	_reset_kira(4.5)
	var s: Spitter = _spawn("spitter", 30.5, FLOOR)
	await _physics(120)
	check(s.shots_fired == 0, "con Kira lejos no dispara")
	kira.place_at(Vector2(22.5 * T, FLOOR * T))
	kira.health.reset()
	var windup := false
	for i in 90:
		await physics_frame
		if s.state == Spitter.State.WINDUP:
			windup = true
		if s.shots_fired > 0:
			break
	check(windup and s.shots_fired == 1, "a tiro, se ilumina para avisar y dispara")
	var hp0 := kira.health.hp
	for i in 90:
		await physics_frame
		if kira.health.hp < hp0:
			break
	check(kira.health.hp == hp0 - 1, "el proyectil va hacia Kira y le quita un corazón")
	await _physics(2)
	check(_projectiles().is_empty(), "y desaparece al alcanzarla")
	var t0 := s.shots_fired
	await _physics(int(Spitter.COOLDOWN * 60) - 30)
	check(s.shots_fired == t0, "recarga unos 2 s entre disparos")

	print("Cortar proyectiles")
	_clear()
	_reset_kira(20.5)
	kira.motor.facing = 1
	await _physics(5)
	var p := Projectile.new()
	p.position = Vector2(26.0 * T, FLOOR * T - 22.0)
	p.direction = Vector2.LEFT
	room.add_child(p)
	var hp1 := kira.health.hp
	var notches0 := kira.combat.notches
	for i in 60:
		await physics_frame
		if is_instance_valid(p) and absf(p.position.x - kira.position.x) < 50.0:
			kira.scripted_input = {"x": 0.0, "attack": true}
		if not is_instance_valid(p):
			break
	kira.scripted_input = {"x": 0.0}
	await _physics(2)
	check(not is_instance_valid(p) and kira.health.hp == hp1, "el tajo corta el proyectil sin recibir daño")
	check(kira.combat.notches == notches0, "cortarlo no llena muescas")
	var p2 := Projectile.new()
	p2.position = Vector2(40.0 * T, FLOOR * T - 22.0)
	p2.direction = Vector2.RIGHT
	room.add_child(p2)
	await _physics(60)
	check(not is_instance_valid(p2), "al chocar con un bloque desaparece")

	print("Escupidor: golpes")
	_clear()
	_reset_kira(10.5)
	kira.motor.facing = 1
	await _physics(5)
	var s2: Spitter = _spawn("spitter", 11.8, FLOOR)
	for i in 3:
		await _slash()
	check(not is_instance_valid(s2), "3 tajos lo eliminan")

	print("En el mundo")
	var counts := {}
	for id in Rooms.DATA:
		var l := RoomLayout.parse(Rooms.DATA[id].layout, Rooms.DATA[id].origin, id)
		for sp in l.enemy_spawns:
			counts[sp.kind] = counts.get(sp.kind, 0) + 1
		if id == "banco":
			check(l.enemy_spawns.is_empty(), "la sala del banco no tiene enemigos")
	check(counts.get("flyer", 0) == 3 and counts.get("spitter", 0) == 2,
			"revoloteadores y escupidores repartidos por las salas %s" % str(counts))

	room.queue_free()
	print("\n%d/%d comprobaciones correctas" % [_checks - _failures, _checks])
	quit(1 if _failures > 0 else 0)
