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
	var kira: Kira = room.kira
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

	print("\n%d/%d comprobaciones correctas" % [_checks - _failures, _checks])
	room.queue_free()
	quit(1 if _failures > 0 else 0)
