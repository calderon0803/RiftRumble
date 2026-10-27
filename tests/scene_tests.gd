## Tests en la sala de prueba real, con física (sin ventana).
## Uso: godot --headless --path . --script res://tests/scene_tests.gd
extends SceneTree

var _failures := 0
var _checks := 0


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


func _run() -> void:
	var room: TestRoom = load("res://src/world/test_room.tscn").instantiate()
	root.add_child(room)
	room.hitstop_enabled = false
	var kira: Kira = room.kira
	_clear_enemies(room)
	kira.scripted_input = {"x": 0.0, "jump": false}
	var floor_y := float((room.LAYOUT.size() - 1) * room.TILE)

	print("Suelo")
	await _physics(30)
	check(kira.is_on_floor(), "aparece y se queda en el suelo")
	check(absf(kira.position.y - floor_y) < 1.0, "los pies a la altura del suelo (%.1f / %.1f)" % [kira.position.y, floor_y])
	await _physics(60)
	check(kira.is_on_floor(), "sigue en el suelo quieta (no rebota ni se despega)")

	print("Pared")
	kira.scripted_input = {"x": 1.0, "jump": false}
	await _physics(420)
	# Bloque de 2 casillas de alto en la columna 47 de la fila del suelo.
	var wall_x := 47.0 * room.TILE
	check(kira.position.x <= wall_x - kira.SIZE.x / 2 + 0.5, "choca con el bloque y no lo atraviesa (x %.1f, pared %.0f)" % [kira.position.x, wall_x])
	check(kira.position.x > wall_x - kira.SIZE.x, "llega hasta tocarlo")
	check(kira.is_on_floor(), "sigue en el suelo contra la pared")

	print("Salto en la sala")
	kira.scripted_input = {"x": 0.0, "jump": false}
	await _physics(10)
	var y0 := kira.position.y
	var top := y0
	kira.scripted_input = {"x": 0.0, "jump": true}
	for i in 50:
		await physics_frame
		top = minf(top, kira.position.y)
	var h := (y0 - top) / KiraMotor.TILE
	var target := KiraMotor.JUMP_HEIGHT / KiraMotor.TILE
	check(h > target * 0.9 and h < target * 1.02, "salta %.2f casillas" % h)
	kira.scripted_input = {"x": 0.0, "jump": false}
	await _physics(5)
	kira.scripted_input = {"x": 1.0, "jump": true}
	await _physics(40)
	check(kira.position.x > 47.0 * room.TILE and kira.is_on_floor(), "puede subirse al bloque de 2 casillas saltando")

	print("Plataformas")
	# Escalera de la izquierda: suelo → plataforma de la fila 18 (cols 10-14) → fila 15 (cols 18-22).
	kira.respawn(Vector2(7.5 * room.TILE, 22.0 * room.TILE))
	kira.scripted_input = {"x": 0.0, "jump": false}
	await _physics(10)
	kira.scripted_input = {"x": 1.0, "jump": true}
	await _physics(24)
	kira.scripted_input = {"x": 0.0, "jump": true}
	await _physics(40)
	check(kira.is_on_floor() and absf(kira.position.y - 18.0 * room.TILE) < 1.0,
			"desde el suelo se sube a la primera plataforma (4 casillas) [%.1f, %.1f]" % [kira.position.x / room.TILE, kira.position.y / room.TILE])
	# Corre hasta el borde y salta desde ahí.
	kira.scripted_input = {"x": 1.0, "jump": false}
	while kira.position.x < 14.3 * room.TILE:
		await physics_frame
	kira.scripted_input = {"x": 1.0, "jump": true}
	await _physics(30)
	kira.scripted_input = {"x": 0.0, "jump": true}
	await _physics(40)
	check(kira.is_on_floor() and absf(kira.position.y - 15.0 * room.TILE) < 1.0,
			"y de ahí a la siguiente (3 casillas más arriba) [%.1f, %.1f]" % [kira.position.x / room.TILE, kira.position.y / room.TILE])

	print("Techo")
	kira.respawn(room.spawn)
	kira.scripted_input = {"x": 0.0, "jump": false}
	await _physics(20)
	# Bajo la plataforma de la columna 10-14 (fila 18): techo a 3 casillas del suelo.
	kira.position.x = 12.5 * room.TILE
	await _physics(5)
	kira.scripted_input = {"x": 0.0, "jump": true}
	var min_y := kira.position.y
	for i in 40:
		await physics_frame
		min_y = minf(min_y, kira.position.y)
	var ceiling_bottom := 19.0 * room.TILE
	check(min_y - kira.SIZE.y >= ceiling_bottom - 1.0, "la cabeza no atraviesa el techo")
	await _physics(60)
	check(kira.is_on_floor(), "vuelve a caer al suelo")

	await _combat(room, kira)
	await _animations(room, kira)

	print("\n%d/%d comprobaciones correctas" % [_checks - _failures, _checks])
	room.queue_free()
	quit(1 if _failures > 0 else 0)


func _clear_enemies(room: TestRoom) -> void:
	room.enemy_spawns.clear()
	for e in room.enemies:
		if is_instance_valid(e):
			e.queue_free()
	room.enemies.clear()


func _crawler_at(room: TestRoom, col: float, row: float) -> Crawler:
	var e := Crawler.new()
	e.position = Vector2(col * room.TILE, row * room.TILE)
	e.died.connect(room._on_enemy_died)
	room.add_child(e)
	room.enemies.append(e)
	return e


func _press(kira: Kira, input: Dictionary, frames: int) -> void:
	kira.scripted_input = input
	await _physics(frames)
	kira.scripted_input = {"x": 0.0}
	await _physics(1)


func _combat(room: TestRoom, kira: Kira) -> void:
	var floor_row := 22.0
	print("Tajo")
	kira.respawn(Vector2(10.5 * room.TILE, floor_row * room.TILE))
	kira.scripted_input = {"x": 0.0}
	await _physics(10)
	var e := _crawler_at(room, 11.9, floor_row)
	e.dir = 1  # se aleja: solo lo alcanza el tajo
	await _physics(1)
	var x_before := e.position.x
	await _press(kira, {"x": 0.0, "attack": true}, 1)
	await _physics(4)
	check(e.health.hp == Crawler.MAX_HP - 1, "el tajo hacia delante le quita 1 de vida")
	check(kira.combat.notches == 1, "y llena una muesca del filo")
	await _physics(10)
	var pushed := (e.position.x - x_before) / room.TILE - Crawler.SPEED * 16.0 / 60.0 / room.TILE
	check(pushed > 0.5, "el enemigo sale despedido hacia atrás (%.1f casillas)" % pushed)
	await _physics(10)
	check(kira.combat.notches == 1, "un mismo tajo golpea una sola vez")
	_clear_enemies(room)

	print("Matar")
	kira.respawn(Vector2(10.5 * room.TILE, floor_row * room.TILE))
	kira.scripted_input = {"x": 0.0}
	await _physics(5)
	var e2 := _crawler_at(room, 11.8, floor_row)
	e2.dir = 1
	for i in 3:
		await _press(kira, {"x": 0.0, "attack": true}, 1)
		await _physics(int(KiraCombat.COOLDOWN * 60) + 1)
		if is_instance_valid(e2):
			e2.position.x = 11.8 * room.TILE  # que siga a tiro
	check(not is_instance_valid(e2), "3 tajos lo eliminan")
	check(room.enemies.is_empty(), "desaparece de la sala")

	print("Daño a Kira")
	kira.respawn(Vector2(10.5 * room.TILE, floor_row * room.TILE))
	kira.scripted_input = {"x": 0.0}
	await _physics(5)
	var e3 := _crawler_at(room, 12.5, floor_row)
	e3.dir = -1
	var hp0 := kira.health.hp
	for i in 60:
		await physics_frame
		if kira.health.hp < hp0:
			break
	check(kira.health.hp == hp0 - 1, "tocar al enemigo quita un corazón")
	check(kira.velocity.x < 0.0, "y la empuja hacia atrás")
	e3.position = kira.position
	await _physics(20)
	check(kira.health.hp == hp0 - 1, "durante 1 s es invulnerable")
	_clear_enemies(room)

	print("Muerte")
	kira.health.hp = 1
	kira.health.invulnerable = 0.0
	_crawler_at(room, kira.position.x / room.TILE + 0.3, floor_row)
	await _physics(5)
	check(kira.health.hp == kira.health.max_hp and kira.position.distance_to(room.spawn) < 40.0,
			"con 0 corazones vuelve al inicio con toda la vida")
	_clear_enemies(room)

	print("Tajo hacia abajo")
	kira.respawn(Vector2(30.5 * room.TILE, floor_row * room.TILE))
	kira.scripted_input = {"x": 0.0}
	await _physics(5)
	var e5 := _crawler_at(room, 30.5, floor_row)
	e5.set_physics_process(false)  # quieto debajo
	kira.position.y -= 3.0 * room.TILE
	kira.velocity = Vector2.ZERO
	var bounced := false
	var enemy_top := e5.position.y - Crawler.SIZE.y
	for i in 60:
		# Golpea cuando el enemigo ya está a tiro, como haría quien juega.
		var near := kira.position.y > enemy_top - 36.0
		kira.scripted_input = {"x": 0.0, "y": 1.0, "attack": near}
		await physics_frame
		if kira.velocity.y < -400.0:
			bounced = true
			break
	check(bounced, "acertar un tajo hacia abajo la hace rebotar")
	check(kira.health.hp == kira.health.max_hp, "sin recibir daño al rebotar")
	_clear_enemies(room)

	print("Tajo de filo")
	kira.respawn(Vector2(10.5 * room.TILE, floor_row * room.TILE))
	kira.scripted_input = {"x": 0.0}
	await _physics(5)
	var e6 := _crawler_at(room, 12.4, floor_row)
	e6.dir = 1
	await _press(kira, {"x": 0.0, "special": true}, 1)
	await _physics(3)
	check(is_instance_valid(e6) and e6.health.hp == Crawler.MAX_HP, "sin muescas no sale")
	e6.position.x = 12.4 * room.TILE
	kira.combat.notches = 3
	await _press(kira, {"x": 0.0, "special": true}, 1)
	await _physics(3)
	check(not is_instance_valid(e6), "con 3 muescas lo elimina de un golpe")
	check(kira.combat.notches == 0, "y gasta las 3")
	_clear_enemies(room)

	print("Patrulla")
	kira.respawn(Vector2(3.5 * room.TILE, floor_row * room.TILE))
	kira.scripted_input = {"x": 0.0}
	var e7 := _crawler_at(room, 39.5, 18.0)  # sobre la plataforma de las columnas 38-41
	var min_x := e7.position.x
	var max_x := e7.position.x
	for i in 300:
		await physics_frame
		min_x = minf(min_x, e7.position.x)
		max_x = maxf(max_x, e7.position.x)
	check(absf(e7.position.y - 18.0 * room.TILE) < 1.0, "no se cae de su plataforma")
	check(max_x - min_x > 1.5 * room.TILE, "va y viene por ella")
	var e8 := _crawler_at(room, 61.0, floor_row)  # entre el bloque y la pared
	e8.dir = 1
	await _physics(120)
	check(e8.position.x < 63.0 * room.TILE and e8.dir == -1, "se da la vuelta al llegar a una pared")
	_clear_enemies(room)


## Espera hasta `frames` fotogramas a que Kira esté en la animación `anim`.
func _wait_anim(kira: Kira, anim: StringName, frames := 30) -> bool:
	for i in frames:
		if kira.rig.current() == anim:
			return true
		await physics_frame
	return kira.rig.current() == anim


func _animations(room: TestRoom, kira: Kira) -> void:
	print("Dibujo y animaciones")
	_clear_enemies(room)
	var sprites := kira.rig.get_children().filter(func(n): return n is Sprite2D)
	check(sprites.size() == 13, "Kira se dibuja por piezas (13 piezas)")
	kira.grant("dash")
	kira.respawn(Vector2(10.5 * room.TILE, 22.0 * room.TILE))
	kira.scripted_input = {"x": 0.0}
	await _physics(10)
	check(await _wait_anim(kira, &"idle"), "quieta: reposo")
	kira.scripted_input = {"x": 1.0}
	check(await _wait_anim(kira, &"run"), "andando: carrera")
	kira.scripted_input = {"x": 1.0, "jump": true}
	check(await _wait_anim(kira, &"jump"), "subiendo: salto")
	check(await _wait_anim(kira, &"fall", 60), "bajando: caída")
	kira.scripted_input = {"x": 0.0}
	await _physics(40)
	kira.scripted_input = {"x": 0.0, "attack": true}
	check(await _wait_anim(kira, &"slash", 3), "tajo hacia delante")
	check(kira.rig.current() == &"slash", "y no lo corta otra animación")
	kira.scripted_input = {"x": 0.0}
	await _physics(30)
	kira.scripted_input = {"x": 0.0, "y": -1.0, "attack": true}
	check(await _wait_anim(kira, &"slash_up", 3), "tajo hacia arriba")
	kira.scripted_input = {"x": 0.0}
	await _physics(30)
	kira.scripted_input = {"x": 0.0, "jump": true}
	await _physics(12)
	kira.scripted_input = {"x": 0.0, "y": 1.0, "jump": true, "attack": true}
	check(await _wait_anim(kira, &"slash_down", 3), "tajo hacia abajo en el aire")
	kira.scripted_input = {"x": 0.0}
	await _physics(60)
	kira.combat.notches = 3
	kira.scripted_input = {"x": 0.0, "special": true}
	check(await _wait_anim(kira, &"special", 3), "tajo de filo")
	kira.scripted_input = {"x": 0.0}
	await _physics(40)
	kira.scripted_input = {"x": 1.0, "dash": true}
	check(await _wait_anim(kira, &"dash", 3), "dash")
	await _physics(3)
	var ghosts := room.get_children().filter(func(n): return n is CutoutRig)
	check(ghosts.size() > 0, "el dash deja una estela de copias de Kira")
	kira.scripted_input = {"x": 0.0}
	await _physics(30)
	kira.health.invulnerable = 0.0
	_crawler_at(room, kira.position.x / room.TILE + 0.3, 22.0)
	check(await _wait_anim(kira, &"hit", 10), "al recibir daño: golpe")
	_clear_enemies(room)
