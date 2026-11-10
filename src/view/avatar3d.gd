## Personaje 3D en tiempo real: se dibuja en una imagen propia y esa imagen se coloca en el mundo 2D.
## La camara no tiene perspectiva y mira de lado, de modo que el juego sigue viendose en 2D.
class_name Avatar3D
extends SubViewport

const ALEX: PackedScene = preload("res://art/personajes3d/alex.glb")
const KIRA: PackedScene = preload("res://art/personajes3d/kira.glb")
const NEXO: PackedScene = preload("res://art/personajes3d/nexo.glb")
const NORMAL: PackedScene = preload("res://art/personajes3d/alex_normal.glb")
## Colores de la paleta de los modelos de Alex normal, en su orden.
const LOOK_SLOTS := ["piel", "pelo", "ropa", "ropa2", "pantalon", "pantalon2", "zapato", "bota", "ojo", "suela", "interior"]
const QUALITY := 2  # se renderiza al doble para que se vea nitido
const SIDE := 128 * QUALITY
const PX_PER_M := 40.0 * QUALITY
const FEET := Vector2(SIDE / 2.0, SIDE - 6.0 * QUALITY) / QUALITY
const DRAW_SIZE := Vector2(SIDE, SIDE) / QUALITY
const TURN := deg_to_rad(68.0)  # no del todo de perfil: asi se ve el volumen
const BLEND := 0.08

var _scene: PackedScene
var _look := {}
var _applied_look := {}
var zoom := 1.0  # veces que se amplia al dibujarlo; la imagen se renderiza a ese tamano real
var _model: Node3D
var _player: AnimationPlayer
var _current := ""


func _init(scene: PackedScene = ALEX) -> void:
	_scene = scene


## Alex tal como lo ha personalizado el jugador; sin personalizar es el maniqui de pruebas.
static func of_look(look: Dictionary) -> Avatar3D:
	if look.is_empty():
		return Avatar3D.new()
	var avatar := Avatar3D.new(NORMAL)
	avatar._look = look
	return avatar


## Cambia colores y piezas visibles al momento, sin volver a cargar el modelo.
func set_look(look: Dictionary) -> void:
	_look = look
	if _model == null or look.is_empty() or look == _applied_look:
		return
	_applied_look = look.duplicate()
	var image := Image.create(LOOK_SLOTS.size(), 1, false, Image.FORMAT_RGB8)
	var colors := Data.look_colors(look)
	for i in LOOK_SLOTS.size():
		image.set_pixel(i, 0, colors[LOOK_SLOTS[i]])
	var texture := ImageTexture.create_from_image(image)
	for node: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		var piece := str(node.name).rsplit("_", true, 1)  # "arriba_2": fila y opcion; "base" no tiene
		if piece.size() == 2:
			node.visible = int(look[piece[0]]) == int(piece[1])
		for i in node.mesh.get_surface_count():
			(node.get_surface_override_material(i) as StandardMaterial3D).albedo_texture = texture


func _ready() -> void:
	_fit_resolution()
	transparent_bg = true
	own_world_3d = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = SIDE / PX_PER_M
	cam.position = Vector3(0, (SIDE / 2.0 - 6.0 * QUALITY) / PX_PER_M, 10)
	add_child(cam)
	_model = _scene.instantiate()
	add_child(_model)
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		_flatten(node)
	set_look(_look)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0]
	for loop_name in ["Idle", "Run", "Fall", "Wall", "Float"]:
		_player.get_animation(loop_name).loop_mode = Animation.LOOP_LINEAR


## Un pixel de la imagen por cada pixel de la ventana: asi se ve nitido a cualquier tamano.
func _fit_resolution() -> void:
	var window := get_window()
	var screen_scale := minf(window.size.x / Game.VW, window.size.y / Game.VH)
	var side := maxi(128, roundi(DRAW_SIZE.x * screen_scale * zoom))
	if size.x != side:
		size = Vector2i(side, side)


## Colores planos y pixel nitido, como el resto del juego.
func _flatten(mesh_node: MeshInstance3D) -> void:
	for i in mesh_node.mesh.get_surface_count():
		var mat := mesh_node.mesh.surface_get_material(i).duplicate() as StandardMaterial3D
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mesh_node.set_surface_override_material(i, mat)


## Cambia de animacion suavemente; hold >= 0 deja la pose quieta en ese instante.
func pose(anim: String, speed: float, _face: int, hold := -1.0, restart := false) -> void:
	if _player == null:
		return
	_fit_resolution()
	_model.rotation.y = TURN # siempre a la derecha; al mirar a la izquierda se voltea la imagen
	if anim != _current or restart:
		_player.play(anim, 0.0 if restart else BLEND)
		_current = anim
	if hold >= 0.0:
		_player.seek(hold, true)
		_player.speed_scale = 0.0
	else:
		_player.speed_scale = speed


func anim_length(anim: String) -> float:
	return _player.get_animation(anim).length if _player != null else 1.0
