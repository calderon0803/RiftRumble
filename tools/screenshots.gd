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
	g.P.x = 13 * 32
	g.cam = g.cam_target()
	await _frames(40)
	await _shot("3_inicio")
	g.meta["kira_talk"] = 1
	g.load_room("kira1", "1")
	g.enemies.clear()
	g.P.x = 12 * 32
	g.P.y = 16 * 32 - g.P.h
	g.room.g[16][10] = "="
	g.room.g[16][11] = "="
	g.room.g[16][12] = "="
	g.cam = g.cam_target()
	await _frames(40)
	await _shot("3b_nivel_kira")
	g.load_room("pasarela", "1")
	g.P.x = 28 * 32
	g.P.y = 15 * 32 - g.P.h
	g.cam = g.cam_target()
	await _frames(40)
	await _shot("4a_pasarela")
	g.load_room("cruce", "1")
	g.P.x = 20 * 32
	g.P.y = 17 * 32 - g.P.h
	g.cam = g.cam_target()
	await _frames(40)
	await _shot("4b_cruce")
	g.load_room("bloque", "1")
	g.P.x = 16 * 32
	g.cam = g.cam_target()
	await _frames(40)
	await _shot("4c_bloque")
	g.load_room("arena2", "1")
	g.P.x = 20 * 32
	await _frames(150)
	await _shot("4d_arena")
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
	g.P.debug = 4
	await _frames(150)
	await _shot("6_rey")
	g.meta["boss"] = true
	g.load_room("patio", "1")
	g.P.x = 15 * 32
	g.P.resonance = 5.0
	g.cam = g.cam_target()
	await _frames(40)
	await _shot("8_patio")
	g.load_room("vestibulo", "1")
	g.P.x = 14 * 32
	g.P.y = 20 * 32 - g.P.h
	g.P.resonance = 4.0
	g.cam = g.cam_target()
	await _frames(40)
	await _shot("8b_vestibulo")
	g.load_room("galeria", "1")
	g.P.x = 27 * 32
	g.P.y = 12 * 32
	g.cam = g.cam_target()
	await _frames(20)
	await _shot("8c_galeria")
	g.load_room("biblioteca", "1")
	g.P.x = 18 * 32
	g.P.y = 16 * 32 - g.P.h
	g.cam = g.cam_target()
	await _frames(60)
	await _shot("9_biblioteca")
	g.meta["kira_talk"] = 2
	g.meta["kira_frags"] = 1
	g.load_room("kira2", "1")
	g.P.x = 8 * 32
	g.enemies[0].idx = 1
	g.cam = g.cam_target()
	await _frames(30)
	await _shot("10_tecnica_kira")
	g.load_room("aula", "1")
	g.P.x = 12 * 32
	await _frames(200)
	await _shot("11_alumno")
	g.load_room("inicio", "1")
	g.meta["up"]["continue"] = 1
	g.run["revive"] = 0
	g.revive_fx = 1.6
	g.P.hp = 3
	await _shot("12_continue_extra")
	g.state = "dead"
	g.dead_t = 2.0
	await _shot("7_continue")
	SaveData.erase()
	quit()
