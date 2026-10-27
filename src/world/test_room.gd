## Sala de prueba (para los tests y para probar mecánicas sueltas): una sola sala
## a partir de un plano de texto (ver RoomLayout), con Kira, cámara y marcador.
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

var kira: Kira
var hud: Hud
var spawn := Vector2.ZERO
var size_px := Vector2.ZERO
var hitstop_enabled := true
var enemy_spawns: Array[Dictionary] = []
var enemies: Array[Node2D] = []
var layout: RoomLayout


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
	for spawn in enemy_spawns:
		var e := Enemies.create(spawn.kind, spawn.pos, kira)
		e.died.connect(_on_enemy_died)
		add_child(e)
		enemies.append(e)


func _on_enemy_died(e: Node2D) -> void:
	var fx := Burst.new()
	fx.color = e.color
	fx.position = Enemies.center_of(e)
	add_child(fx)
	enemies.erase(e)


func _on_hit_landed(special: bool) -> void:
	if hitstop_enabled:
		HitStop.apply(get_tree(), special)


func _build() -> void:
	layout = RoomLayout.parse(LAYOUT)
	size_px = layout.rect.size
	spawn = layout.start
	enemy_spawns = layout.enemy_spawns.duplicate()
	var geo := RoomGeometry.new()
	add_child(geo)
	geo.setup(layout)
