## Sala de prueba del movimiento: se construye a partir de un plano de texto.
## «#» = bloque sólido, «K» = donde aparece Kira, cualquier otra cosa = aire.
## Las filas cortas se rellenan con aire.
class_name TestRoom
extends Node2D

const TILE := 32
const LAYOUT := [
	"########################################################################",
	"#......................................................................#",
	"#......................................................................#",
	"#......................................................................#",
	"#......................................................................#",
	"#......................................................................#",
	"#..........................................######......................#",
	"#......................................................................#",
	"#......................................................................#",
	"#.................................######..................#####........#",
	"#......................................................................#",
	"#......................................................................#",
	"#.........................#####..........................###...........#",
	"#......................................................................#",
	"#......................................................................#",
	"#.................#####...........................####.................#",
	"#......................................................................#",
	"#..............................................................#.......#",
	"#.........#####.......................####.....................#.......#",
	"#..............................................................#.......#",
	"#..K...........................................#####...........#.......#",
	"#..............................................#####...........#.......#",
	"########################################################################",
]
const COLOR_BG := Color("141824")
const COLOR_BLOCK := Color("3a4258")
const COLOR_EDGE := Color("6b7896")

var kira: Kira
var spawn := Vector2.ZERO
var size_px := Vector2.ZERO
var _solids: Array[Rect2] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(COLOR_BG)
	_build()
	kira = Kira.new()
	kira.position = spawn
	add_child(kira)
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(size_px.x)
	cam.limit_bottom = int(size_px.y)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	kira.add_child(cam)
	var hud := CanvasLayer.new()
	var label := Label.new()
	label.text = "Moverse: ← → / A D / mando  ·  Saltar: Espacio / Z / botón A (mantén para saltar más)  ·  R: volver al inicio"
	label.position = Vector2(16, 12)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	hud.add_child(label)
	add_child(hud)


func _physics_process(_dt: float) -> void:
	if Input.is_action_just_pressed(Controls.RESET) or kira.position.y > size_px.y + 200:
		kira.respawn(spawn)


func _build() -> void:
	var width := 0
	for row in LAYOUT:
		width = maxi(width, row.length())
	size_px = Vector2(width * TILE, LAYOUT.size() * TILE)
	var body := StaticBody2D.new()
	add_child(body)
	for y in LAYOUT.size():
		var row: String = LAYOUT[y]
		var x := 0
		while x < row.length():
			var ch := row[x]
			if ch == "K":
				spawn = Vector2((x + 0.5) * TILE, (y + 1) * TILE)
			if ch != "#":
				x += 1
				continue
			# Tramo horizontal de bloques: una sola forma de colisión.
			var x0 := x
			while x < row.length() and row[x] == "#":
				x += 1
			var r := Rect2(x0 * TILE, y * TILE, (x - x0) * TILE, TILE)
			_solids.append(r)
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = r.size
			shape.shape = rect
			shape.position = r.get_center()
			body.add_child(shape)
	queue_redraw()


func _draw() -> void:
	for r in _solids:
		draw_rect(r, COLOR_BLOCK)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), COLOR_EDGE)
