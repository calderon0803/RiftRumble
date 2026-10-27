## Dibuja en una imagen los fotogramas de todas las animaciones de un personaje
## por piezas, para revisarlas sin abrir el juego. Necesita ventana (no --headless).
## Uso: godot --path . --script res://tools/rig_preview.gd -- res://ruta/rig.tres salida.png [anim1,anim2,...]
extends SceneTree

const CutoutRig := preload("res://src/player/rig/cutout_rig.gd")
const Anims := preload("res://src/player/rig/cutout_anims.gd")
const COLS := 8
const CELL := Vector2(120, 130)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var rig: RigDef = load(args[0] if args.size() > 0 else "res://art/kira/kira_rig.tres")
	var out: String = args[1] if args.size() > 1 else "user://rig_preview.png"
	var anims := Anims.ANIMS.keys()
	if args.size() > 2:
		anims = Array(args[2].split(",")).map(func(a): return StringName(a))
	root.size = Vector2i(int(CELL.x * COLS) + 110, int(CELL.y * anims.size()))
	var bg := ColorRect.new()
	bg.color = Color("5fa35a")
	bg.size = Vector2(root.size)
	root.add_child(bg)
	for r in anims.size():
		var label := Label.new()
		label.text = String(anims[r])
		label.position = Vector2(4, r * CELL.y + 4)
		label.add_theme_color_override("font_color", Color("1b2533"))
		root.add_child(label)
		var length := Anims.length(anims[r])
		for c in COLS:
			var t := length * c / float(COLS - 1)
			var node := CutoutRig.new()
			node.setup(rig)
			node.scale = Vector2.ONE * 1.0
			node.position = Vector2(110 + c * CELL.x + CELL.x * 0.5, r * CELL.y + CELL.y - 10)
			root.add_child(node)
			# Se simula desde el principio para que la inercia del pelo y la estela cuenten.
			node.play(anims[r], true)
			var speed := Anims.RUN_REFERENCE_SPEED if anims[r] == &"run" else 0.0
			var steps := int(t * 60.0)
			for k in steps + 1:
				node.update(k / 60.0, false, 1.0, speed)
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(out)
	print("RIG_PREVIEW %s (err=%d)" % [out, err])
	quit()
