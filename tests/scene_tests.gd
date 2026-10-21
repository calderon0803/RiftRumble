## Tests de escena (con el árbol y la vista reales, sin ventana).
## Uso: godot --headless --path . --script res://tests/scene_tests.gd
## Comprueba que reiniciar y pausar no dejan entidades, nodos huérfanos ni
## simulación avanzando.
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


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	var main: Node = load("res://src/view/main.tscn").instantiate()
	root.add_child(main)
	await _frames(5)
	main.autoplay = true
	Engine.time_scale = 4.0

	# Partida en marcha y reinicio repetido.
	await _frames(120)
	main._restart()
	await _frames(90)
	var baseline := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	for i in 10:
		await _frames(60)  # con enemigos, proyectiles y efectos activos
		main._restart()
	await _frames(90)  # deja que se liberen los nodos marcados con queue_free
	var after := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	check(absf(after - baseline) <= 40, "10 reinicios no acumulan nodos (%d → %d)" % [baseline, after])
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0, "sin nodos huérfanos")
	check(main.world.tick < 30 * 4 * 3, "el reinicio crea una simulación nueva (tick %d)" % main.world.tick)

	# Pausa: la simulación no avanza.
	main.paused = true
	var t0: int = main.world.tick
	await _frames(60)
	check(main.world.tick == t0, "en pausa la simulación no avanza")
	main.paused = false
	await _frames(30)
	check(main.world.tick > t0, "al reanudar vuelve a avanzar")

	Engine.time_scale = 1.0
	main.queue_free()
	await _frames(2)

	# Flujo de pantallas: campaña → preparación → partida → volver al mapa.
	var camp: Node = load("res://src/ui/campaign.tscn").instantiate()
	root.add_child(camp)
	current_scene = camp
	await _frames(10)
	camp._open_prep("w1_m5")
	await _frames(5)
	check(not camp._play_button.disabled, "con 2 héroes elegidos se puede jugar")
	camp._toggle_hero(false, camp._chosen[0])
	check(camp._play_button.disabled, "con 1 héroe no se puede jugar")
	camp._toggle_hero(true, "hero_portal" if not "hero_portal" in camp._chosen else "hero_blade")
	var chosen: PackedStringArray = camp._chosen.duplicate()
	# Quita una torre del equipo: la partida solo debe permitir las elegidas.
	var dropped: String = camp._chosen_towers[0]
	camp._toggle_tower(false, dropped, Button.new())
	var camp_towers: PackedStringArray = camp._chosen_towers.duplicate()
	camp._play()
	await _frames(10)
	var game: Node = current_scene
	check(game != null and game.name == "Main", "jugar abre la partida")
	check(root.get_node("Session").mission_id == "w1_m5", "la sesión lleva la misión elegida")
	var hero_ids := []
	for h in game.world.heroes.heroes:
		hero_ids.append(String(h.def.id))
	check(hero_ids == Array(chosen), "la partida usa los héroes elegidos, en ese orden")
	check(Array(game.world.allowed_towers) == Array(camp_towers), "la partida usa el equipo de torres elegido")
	check(game.world.build(0, StringName(dropped)) == &"unknown_tower", "no se puede construir una torre fuera del equipo")
	game._go_to_campaign()
	await _frames(10)
	check(current_scene != null and current_scene.name == "Campaign", "«Volver al mapa» regresa a la campaña")
	current_scene.queue_free()
	await _frames(2)

	print("\n%d comprobaciones, %d fallos" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
