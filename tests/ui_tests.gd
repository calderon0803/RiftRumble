## Tests del pulido: pantalla de título, menú de pausa, efectos de golpe y fondo.
## Uso: godot --headless --path . --script res://tests/ui_tests.gd
extends SceneTree

const SAVE := "user://test_ui.json"
const T := 32.0
var _failures := 0
var _checks := 0


func check(cond: bool, msg: String) -> void:
	_checks += 1
	print(("  ✓ " if cond else "  ✗ ") + msg)
	if not cond:
		_failures += 1


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame


## Pulsa una acción como si fuera una tecla (un par de fotogramas).
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _frames(1)
	Input.action_release(action)
	await _frames(1)


func _scene() -> Node:
	return current_scene


func _run() -> void:
	SaveGame.active_path = SAVE
	SaveGame.erase(SAVE)
	Controls.ensure()

	print("Título")
	change_scene_to_file("res://src/ui/title.tscn")
	await _frames(3)
	var title := _scene() as TitleScreen
	check(title != null, "el juego arranca en la pantalla de título")
	check(not title.menu._items[0].enabled and title.menu.current_id() == "new",
			"sin partida guardada, «Continuar» está apagado y se empieza en «Partida nueva»")
	title.menu.accept()
	await _frames(4)
	var w := _scene() as World
	check(w != null and w.current.id == Rooms.START, "«Partida nueva» empieza en la sala de inicio")
	w.hitstop_enabled = false

	print("Pausa")
	await _press(Controls.PAUSE)
	check(w.pause_menu.visible and paused, "Esc abre la pausa y detiene el juego")
	var kx := w.kira.position.x
	w.kira.scripted_input = {"x": 1.0}
	await _frames(20)
	check(absf(w.kira.position.x - kx) < 0.5, "en pausa Kira no se mueve")
	w.pause_menu.menu.move(1)
	w.pause_menu.menu.accept()
	await _frames(2)
	check(w.pause_menu._controls.visible, "«Controles» enseña la lista de controles")
	await _press(Controls.PAUSE)
	check(w.pause_menu.visible and w.pause_menu.menu.visible, "Esc vuelve del panel de controles al menú")
	await _press(Controls.PAUSE)
	check(not w.pause_menu.visible and not paused, "y otra vez Esc cierra la pausa")
	await _frames(10)
	check(w.kira.position.x > kx + 1.0, "y el juego sigue")
	w.kira.scripted_input = {"x": 0.0}

	print("Efectos")
	w.kira.health.invulnerable = 0.0
	var hp := w.kira.health.hp
	w.kira.health.damage(1, 1.0)
	w.kira.health_changed.emit(w.kira.health.hp, w.kira.health.max_hp)
	await _frames(1)
	check(w.kira.health.hp == hp - 1 and w.cam.current() > 5.0, "al recibir daño la cámara tiembla fuerte")
	check(w.hud.hurt_flash() > 0.0, "y los bordes destellan en rojo")
	await _frames(30)
	check(w.cam.current() == 0.0 and w.cam.offset == Vector2.ZERO, "el temblor se calma")
	# Acertar a un enemigo: chispas y temblor suave.
	for e in w.enemies:
		e.queue_free()
	w.enemies.clear()
	var c := Enemies.create("crawler", w.kira.position + Vector2(36, 0), w.kira)
	c.set_physics_process(false)
	w._room_node.add_child(c)
	w.enemies.append(c)
	w.kira.health.invulnerable = 5.0
	await _frames(2)
	w.kira.scripted_input = {"x": 0.0, "attack": true}
	await _frames(2)
	w.kira.scripted_input = {"x": 0.0}
	var sparks := w.get_children().filter(func(n): return n is Sparks)
	check(sparks.size() > 0, "al acertar salen chispas")
	check(w.cam.current() > 0.0 and w.cam.current() < 5.0, "y la cámara tiembla un poco")
	# Polvo al aterrizar desde lo alto.
	await _frames(30)
	w.kira.respawn(w.current.rect.position + Vector2(35.5 * T, 17.0 * T))  # zona abierta, 5 casillas sobre el suelo
	var dust := false
	for i in 60:
		await _frames(1)
		if w.get_children().any(func(n): return n is Dust):
			dust = true
			break
	check(dust, "al aterrizar desde lo alto se levanta polvo")

	print("Escenario")
	var themes := {}
	for id in w.layouts:
		themes[w.layouts[id].theme] = true
	check(themes.size() >= 4, "las zonas tienen colores distintos (%d paletas)" % themes.size())
	w.enter_room("pasillo")  # dos pantallas de ancho: la cámara se desplaza
	w.kira.respawn(w.current.rect.position + Vector2(10.5 * T, 22 * T))
	for e in w.enemies:
		e.queue_free()
	w.enemies.clear()
	w.cam.reset_smoothing()
	await _frames(5)
	var bg := w._room_node.get_children().filter(func(n): return n is BackgroundView)
	check(bg.size() == 1, "cada sala tiene su fondo con siluetas")
	var far: Node2D = bg[0]._far
	var p0 := far.position
	w.kira.respawn(w.current.rect.position + Vector2(60.5 * T, 22 * T))
	await _frames(1)
	w.cam.reset_smoothing()
	await _frames(5)
	check(far.position.distance_to(p0) > 10.0, "las siluetas del fondo se desplazan con la cámara (paralaje)")

	print("Volver al título")
	w.save()
	await _press(Controls.PAUSE)
	w.pause_menu.menu.selected = 2
	w.pause_menu.menu.accept()
	await _frames(4)
	var title2 := _scene() as TitleScreen
	check(title2 != null and not paused, "«Volver al título» lleva al título sin pausa")
	check(title2 != null and title2.menu._items[0].enabled and title2.menu.current_id() == "continue",
			"con partida guardada, «Continuar» está disponible y elegido")
	title2.menu.move(1)
	title2.menu.accept()
	await _frames(2)
	check(_scene() is TitleScreen and FileAccess.file_exists(SAVE), "«Partida nueva» con partida guardada pide confirmar")
	title2.menu.accept()
	await _frames(4)
	check(_scene() is World and not SaveGame.load_from(SAVE).has("bench_room"), "al confirmar, borra la partida y empieza de cero")

	SaveGame.erase(SAVE)
	SaveGame.active_path = SaveGame.DEFAULT_PATH
	print("\n%d/%d comprobaciones correctas" % [_checks - _failures, _checks])
	quit(1 if _failures > 0 else 0)
