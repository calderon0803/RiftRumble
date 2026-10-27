## Sala de prueba: se construye a partir de un plano de texto.
## «#» = bloque sólido, «K» = donde aparece Kira, «c» = rastrero, cualquier otra
## cosa = aire. Las filas cortas se rellenan con aire.
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
	"#......................................c.......................#.......#",
	"#.........#####.......................####.....................#.......#",
	"#..............................................................#.......#",
	"#..K...........................................#####...........#.......#",
	"#.....................c.............c..........#####.....c.....#.......#",
	"########################################################################",
]
const COLOR_BG := Color("141824")
const COLOR_BLOCK := Color("3a4258")
const COLOR_EDGE := Color("6b7896")

## Micropausa al acertar un golpe (segundos reales).
const HITSTOP := 0.05
const HITSTOP_SPECIAL := 0.10

var kira: Kira
var hud: Hud
var spawn := Vector2.ZERO
var size_px := Vector2.ZERO
var hitstop_enabled := true
var enemy_spawns: Array[Vector2] = []
var enemies: Array[Crawler] = []
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
	hud = Hud.new()
	add_child(hud)
	kira.health_changed.connect(hud.set_health)
	kira.notches_changed.connect(hud.set_notches)
	kira.hit_landed.connect(_on_hit_landed)
	kira.died.connect(reset_room)
	_spawn_enemies()


func _physics_process(_dt: float) -> void:
	if Input.is_action_just_pressed(Controls.RESET) or kira.position.y > size_px.y + 200:
		reset_room()


## Vuelve a empezar: Kira al inicio con toda la vida y los enemigos en su sitio.
func reset_room() -> void:
	kira.respawn(spawn)
	_spawn_enemies()


func _spawn_enemies() -> void:
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	for p in enemy_spawns:
		var e := Crawler.new()
		e.position = p
		e.died.connect(_on_enemy_died)
		add_child(e)
		enemies.append(e)


func _on_enemy_died(e: Crawler) -> void:
	var fx := Burst.new()
	fx.color = Crawler.COLOR
	fx.position = e.position + Vector2(0, -Crawler.SIZE.y / 2)
	add_child(fx)
	enemies.erase(e)


func _on_hit_landed(special: bool) -> void:
	if not hitstop_enabled:
		return
	Engine.time_scale = 0.05
	await get_tree().create_timer(HITSTOP_SPECIAL if special else HITSTOP, true, false, true).timeout
	Engine.time_scale = 1.0


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
			elif ch == "c":
				enemy_spawns.append(Vector2((x + 0.5) * TILE, (y + 1) * TILE))
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
