## Abre el juego, lo lleva a varias situaciones y guarda una captura de cada una (para revisar el aspecto sin jugar).
## godot --path . --script res://tools/screenshots.gd -- <carpeta de salida>
extends SceneTree

var out_dir := "user://capturas"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveData.path = "user://capturas_partida.json"
	SaveData.erase()
	var main: Node = load("res://src/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred(main)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("captura ", name)


func _run(main: Node) -> void:
	await _frames(5)
	var g: Game = main.game
	g.time = 2.0
	await _shot("1_titulo")
	g.state = "play"
	g.meta["seen_intro"] = true
	await _frames(10)
	await _shot("2_umbral")
	g.load_room("inicio", "1")
	g.P.x = 9 * 32
	g.cam = g.cam_target()
	await _frames(40)
	await _shot("3_inicio")
	g.load_room("monedas", "1")
	g.P.x = 22 * 32
	await _frames(40)
	await _shot("4_monedas")
	g.load_room("inicio", "1")
	g.enemies.clear()
	var F: Dictionary = g.props.filter(func(o): return o["type"] == "F")[0]
	g.P.x = F["x"] - 9
	g.P.y = F["y"] - g.P.h
	g.cam = g.cam_target()
	await _frames(5)
	g.interact(F)
	await _frames(30)
	await _shot("5_grieta")
	g.pick_boon(g.choice["opts"][0])
	g.load_room("trono", "1")
	g.P.x = 12 * 32
	g.P.filo = 4
	await _frames(150)
	await _shot("6_rey")
	g.state = "dead"
	g.dead_t = 2.0
	await _shot("7_continue")
	SaveData.erase()
	quit()
