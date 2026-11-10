## Personaje 3D en tiempo real: se dibuja en una imagen propia y esa imagen se coloca en el mundo 2D.
## La camara no tiene perspectiva y mira de lado, de modo que el juego sigue viendose en 2D.
class_name Avatar3D
extends SubViewport

const ALEX: PackedScene = preload("res://art/personajes3d/alex_v2.glb")
const KIRA: PackedScene = preload("res://art/personajes3d/kira_v2.glb")
const NEXO: PackedScene = preload("res://art/personajes3d/nexo.glb")
const NORMAL: PackedScene = preload("res://art/personajes3d/alex_normal_v2.glb")
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
## Cada pieza se llama como su fila y opcion ("arriba_2"); cada material, como el color que lo tine
## ("piel", "pelo", "ropa", "pantalon"): su textura va en gris y el color elegido la multiplica.
func set_look(look: Dictionary) -> void:
	_look = look
	if _model == null or look.is_empty() or look == _applied_look:
		return
	_applied_look = look.duplicate()
	var colors := Data.look_colors(look)
	for node: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		var piece := str(node.name).rsplit("_", true, 1)
		if piece.size() == 2 and look.has(piece[0]) and piece[1].is_valid_int():
			node.visible = int(look[piece[0]]) == int(piece[1])
		for i in node.mesh.get_surface_count():
			var mat := node.get_surface_override_material(i) as StandardMaterial3D
			var slot := mat.resource_name.get_slice(".", 0)  # Blender numera los repetidos: "pelo.001"
			if colors.has(slot):
				mat.albedo_color = colors[slot]


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
	_add_cape_physics()


## La capa de Kira cuelga de tres cadenas de huesos (capa_I/C/D_0..3): se mueven con inercia y gravedad
## y chocan con piernas y caderas, asi la tela reacciona a la animacion en vez de ir pegada a la espalda.
const CAPE_CHAINS := ["I", "C", "D"]
## Hueso del cuerpo: [hueso hijo hacia el que va la capsula, radio]. La capsula cubre el hueso entero.
const CAPE_COLLIDERS := {"pelvis": ["spine_01", 0.16], "spine_01": ["spine_02", 0.15],
	"thigh_l": ["calf_l", 0.095], "thigh_r": ["calf_r", 0.095], "calf_l": ["foot_l", 0.075], "calf_r": ["foot_r", 0.075]}


func _add_cape_physics() -> void:
	var skeletons := _model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty() or skeletons[0].find_bone("capa_C_0") < 0:
		return
	var skel: Skeleton3D = skeletons[0]
	var sim := SpringBoneSimulator3D.new()
	skel.add_child(sim)
	sim.setting_count = CAPE_CHAINS.size()
	for i in CAPE_CHAINS.size():
		sim.set_root_bone_name(i, "capa_%s_0" % CAPE_CHAINS[i])
		sim.set_end_bone_name(i, "capa_%s_3" % CAPE_CHAINS[i])
		sim.set_extend_end_bone(i, true)
		sim.set_end_bone_length(i, 0.08)
		sim.set_radius(i, 0.03)
		sim.set_stiffness(i, 2.0)  # tiende a volver a su caida natural, por detras
		sim.set_drag(i, 0.5)
		sim.set_gravity(i, 0.4)
		sim.set_enable_all_child_collisions(i, true)
	for bone_name: String in CAPE_COLLIDERS:
		var to_child := skel.get_bone_rest(skel.find_bone(CAPE_COLLIDERS[bone_name][0])).origin
		var c := SpringBoneCollisionCapsule3D.new()
		sim.add_child(c)
		c.bone_name = bone_name
		c.radius = CAPE_COLLIDERS[bone_name][1]
		c.height = to_child.length() + c.radius * 2.0
		c.position_offset = to_child * 0.5  # centrada en el hueso y alineada con el
		c.rotation_offset = Quaternion(Vector3.UP, to_child.normalized())


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
func pose(anim: String, speed: float, face: int, hold := -1.0, restart := false) -> void:
	if _player == null:
		return
	_fit_resolution()
	# Se gira el modelo, no la imagen: voltearla cambiaria de mano la espada y todo lo asimetrico
	_model.rotation.y = TURN if face >= 0 else -TURN
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
