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
	print("\n%d comprobaciones, %d fallos" % [_checks, _failures])
	main.queue_free()
	await _frames(2)
	quit(1 if _failures > 0 else 0)
