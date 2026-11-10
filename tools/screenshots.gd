## Abre el juego, lo lleva a varias situaciones y guarda una captura de cada una (las del README).
## godot --path . --script res://tools/screenshots.gd -- <carpeta de salida>
extends SceneTree

const SIZE := Vector2i(960, 540)

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
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	image.save_png(out_dir.path_join(name + ".png"))
	print("captura ", name)


## Lleva a Álex a una sala, en la casilla (x, y) del suelo, y espera a que se asiente la cámara.
func _go(g: Game, room: String, entry: String, x: int, y: int, clear := true) -> void:
	g.load_room(room, entry)
	if clear:
		g.enemies.clear()
	g.P.x = x * 32
	g.P.y = (y + 1) * 32 - g.P.h
	g.P.vy = 0
	g.cam = g.cam_target()
	await _frames(45)
	g.banner = {}


func _run(main: Node) -> void:
	await _frames(5)
	var g: Game = main.game
	g.time = 2.0
	await _shot("titulo")
	g.state = "play"
	g.meta["seen_intro"] = true
	await _go(g, "umbral", "P", 26, 14)
	await _shot("umbral")
	await _go(g, "inicio", "pasarela", 62, 14)
	await _shot("kira")
	await _go(g, "pasarela", "inicio", 34, 11, false)
	g.P.face = 1
	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	await _frames(4)
	await _shot("combate")
	await _go(g, "inicio", "pasarela", 36, 9)
	g.interact(g.props.filter(func(o): return o["type"] == "F")[0])
	await _frames(30)
	await _shot("grieta")
	g.state = "play"
	await _go(g, "patio", "trono", 12, 14)
	await _shot("academia")
	await _go(g, "butacas", "cine", 28, 31)
	await _shot("mundo3")
	await _go(g, "cruce", "inicio", 3, 14)
	g.map_pan = Vector2(Data.MAP_ROOMS["cruce"]) + g.P.center() / 32
	g.state = "map"
	await _frames(5)
	await _shot("mapa")
	g.state = "play"
	await _go(g, "umbral", "P", 26, 14)
	g.open_look_editor()
	g.look_edit["look"] = {"peinado": 3, "pelo": 3, "piel": 1, "arriba": 2, "ropa": 2, "abajo": 0, "pantalon": 1, "calzado": 1}
	g.look_edit["sel"] = 3
	await _frames(20)
	await _shot("aspecto")
	g.look_edit = {}
	g.state = "play"
	await _go(g, "trono", "arena2", 36, 14, false)
	await _frames(200)
	await _shot("rey")
	quit()
