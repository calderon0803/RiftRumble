## Personaje 3D en tiempo real: se dibuja en una imagen propia y esa imagen se coloca en el mundo 2D.
## La camara no tiene perspectiva y mira de lado, de modo que el juego sigue viendose en 2D.
class_name Avatar3D
extends SubViewport

const MODEL: PackedScene = preload("res://art/personajes3d/dev.glb")
const QUALITY := 2  # se renderiza al doble para que se vea nitido
const SIDE := 128 * QUALITY
const PX_PER_M := 40.0 * QUALITY
const FEET := Vector2(SIDE / 2.0, SIDE - 6.0 * QUALITY) / QUALITY
const DRAW_SIZE := Vector2(SIDE, SIDE) / QUALITY
const TURN := deg_to_rad(68.0)  # no del todo de perfil: asi se ve el volumen
const BLEND := 0.08

var _model: Node3D
var _player: AnimationPlayer
var _current := ""


func _ready() -> void:
	size = Vector2i(SIDE, SIDE)
	transparent_bg = true
	own_world_3d = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = SIDE / PX_PER_M
	cam.position = Vector3(0, (SIDE / 2.0 - 6.0 * QUALITY) / PX_PER_M, 10)
	add_child(cam)
	_model = MODEL.instantiate()
	add_child(_model)
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		_flatten(node)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0]
	for loop_name in ["Idle", "Run", "Fall", "Wall"]:
		_player.get_animation(loop_name).loop_mode = Animation.LOOP_LINEAR


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
	_model.rotation.y = TURN  # siempre a la derecha; al mirar a la izquierda se voltea la imagen
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
