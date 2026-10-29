## Personaje animado por piezas: una Sprite2D por pieza, hermanas y ordenadas
## por `z`; cada fotograma se calculan sus transformaciones encadenando las del
## padre (cinemática directa) con la pose de cutout_anims.gd.
##
## Además de la pose:
## - el pelo (hueso «hair») tiene inercia: un muelle amortiguado lo hace quedarse
##   atrás al correr y seguir oscilando al pararse o al girar la cabeza;
## - la punta del arma deja una estela durante ataques y habilidades.
class_name CutoutRig
extends Node2D

const Anims := preload("res://src/player/rig/cutout_anims.gd")

## Muelle del pelo: rigidez, amortiguación y cuánto se queda atrás por velocidad.
const HAIR_STIFFNESS := 140.0
const HAIR_DAMPING := 11.0
const HAIR_DRAG := 0.22          # grados por píxel/s de avance
const HAIR_MAX_DRAG := 40.0
## Estela del arma: segundos que dura cada punto.
const TRAIL_LIFE := 0.12

var rig: RigDef
var _sprites := {}   # nombre → Sprite2D
var _by_name := {}   # nombre → pieza
var _order: Array = []  # piezas con el padre antes que el hijo
var _anim: StringName = &"idle"
var _anim_time := 0.0
var _last_time := -1.0
# Pelo: ángulo «en el mundo» (respecto a la cabeza en reposo) y su velocidad.
var _hair_angle := 0.0
var _hair_vel := 0.0
var _hair_ready := false
var _trail: Trail


func setup(rig_def: RigDef) -> void:
	rig = rig_def
	scale = Vector2.ONE * rig.scale
	for p in rig.parts:
		_by_name[p.name] = p
	# Orden de cálculo: padres primero.
	var done := {}
	while _order.size() < rig.parts.size():
		for p in rig.parts:
			if not done.has(p.name) and (p.get("parent", &"") == &"" or done.has(p.parent)):
				_order.append(p)
				done[p.name] = true
	var sorted := rig.parts.duplicate()
	sorted.sort_custom(func(a, b): return a.get("z", 0) < b.get("z", 0))
	for p in sorted:
		var s := Sprite2D.new()
		s.texture = rig.texture
		s.region_enabled = true
		s.region_rect = p.region
		s.centered = false
		s.offset = -p.pivot
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(s)
		_sprites[p.name] = s
	_trail = Trail.new()
	add_child(_trail)  # por delante de las piezas
	apply_pose(Anims.pose(&"idle", 0.0))


## Cambia de animación (no reinicia si ya está en ella, salvo `restart`).
func play(anim: StringName, restart := false) -> void:
	if anim != _anim or restart:
		_anim = anim
		_anim_time = 0.0


func current() -> StringName:
	return _anim


## Continúa la animación de otra vista del mismo personaje (al darse la vuelta).
func copy_state(other) -> void:
	_anim = other._anim
	_anim_time = other._anim_time
	_last_time = other._last_time


## ¿Ha terminado la animación actual? (las que se repiten nunca terminan)
func finished() -> bool:
	var a: Dictionary = Anims.ANIMS[_anim]
	return not a.loop and _anim_time >= a.length


## Avanza la animación hasta `time`. `rate` acelera o frena el reloj (p. ej., la
## carrera según la velocidad real) y `forward_speed` (px/s hacia donde mira)
## arrastra el pelo.
func update(time: float, facing_left: bool, rate := 1.0, forward_speed := 0.0) -> void:
	var dt := 0.0 if _last_time < 0.0 else clampf(time - _last_time, 0.0, 0.1)
	_last_time = time
	var prev_anim_time := _anim_time
	_anim_time += dt * rate
	scale.x = -absf(scale.x) if facing_left else absf(scale.x)
	var pose := Anims.pose(_anim, _anim_time)
	_step_hair(pose, dt, forward_speed)
	apply_pose(pose)
	_step_trail(time, dt, prev_anim_time)


## Muelle del pelo: su ángulo en el mundo persigue al de la cabeza más el arrastre.
func _step_hair(pose: Dictionary, dt: float, forward_speed: float) -> void:
	if not _by_name.has(&"hair"):
		return
	var head_world := _chain_angle(&"head", pose)
	var target := head_world + float(pose.get(&"hair", 0.0)) + clampf(forward_speed * HAIR_DRAG, -HAIR_MAX_DRAG, HAIR_MAX_DRAG)
	if not _hair_ready:
		_hair_angle = target
		_hair_ready = true
	var steps := maxi(1, ceili(dt / (1.0 / 120.0)))
	var h := dt / steps
	for i in steps:
		var acc := (target - _hair_angle) * HAIR_STIFFNESS - _hair_vel * HAIR_DAMPING
		_hair_vel += acc * h
		_hair_angle += _hair_vel * h
	pose[&"hair"] = _hair_angle - head_world


## Suma de giros (reposo + pose) desde la raíz hasta `bone`, incluido.
func _chain_angle(bone: StringName, pose: Dictionary) -> float:
	var total := 0.0
	var b := bone
	while b != &"":
		var p: Dictionary = _by_name[b]
		total += p.get("rest", 0.0) + float(pose.get(b, 0.0))
		b = p.get("parent", &"")
	return total


## La estela guarda también puntos intermedios entre fotogramas: el golpe es tan
## rápido que con un punto por fotograma saldría una línea quebrada.
const TRAIL_SUBSTEPS := 6


func _step_trail(time: float, dt: float, prev_anim_time: float) -> void:
	var active: bool = Anims.ANIMS[_anim].get("trail", false)
	if active and _sprites.has(&"weapon"):
		for i in range(1, TRAIL_SUBSTEPS + 1):
			var f := float(i) / TRAIL_SUBSTEPS
			var t_anim := lerpf(prev_anim_time, _anim_time, f)
			_trail.points.append([time - dt * (1.0 - f), _tip_for(Anims.pose(_anim, t_anim))])
	while not _trail.points.is_empty() and time - _trail.points[0][0] > TRAIL_LIFE:
		_trail.points.pop_front()
	_trail.now = time
	_trail.queue_redraw()


## Punta del arma en coordenadas del personaje para una pose (sin mover las piezas).
func _tip_for(pose: Dictionary) -> Vector2:
	var p: Dictionary = _by_name[&"weapon"]
	var tip: Vector2 = p.get("tip", Vector2(p.region.size.x * 0.5, p.region.size.y))
	return _bone_transform(&"weapon", pose) * (tip - p.pivot)


func _bone_transform(bone: StringName, pose: Dictionary) -> Transform2D:
	var p: Dictionary = _by_name[bone]
	var angle := deg_to_rad(p.get("rest", 0.0) + float(pose.get(bone, 0.0)))
	var parent: StringName = p.get("parent", &"")
	if parent == &"":
		return Transform2D(angle, p.at + pose.get(&"root", Vector2.ZERO))
	return _bone_transform(parent, pose) * Transform2D(angle, p.at - _by_name[parent].pivot)


func apply_pose(pose: Dictionary) -> void:
	var globals := {}
	for p in _order:
		var angle := deg_to_rad(p.get("rest", 0.0) + float(pose.get(p.name, 0.0)))
		var parent: StringName = p.get("parent", &"")
		var local: Transform2D
		if parent == &"":
			var root_offset: Vector2 = pose.get(&"root", Vector2.ZERO)
			local = Transform2D(angle, p.at + root_offset)
		else:
			# El pivote del padre es su origen local.
			local = Transform2D(angle, p.at - _by_name[parent].pivot)
		var g: Transform2D = globals[parent] * local if parent != &"" else local
		globals[p.name] = g
		_sprites[p.name].transform = g


## Estela de la punta del arma: tira que se estrecha y se desvanece.
class Trail extends Node2D:
	var points: Array = []  # [tiempo, posición]
	var now := 0.0
	var color := Color(1.0, 0.97, 0.75)

	func _draw() -> void:
		if points.size() < 2:
			return
		# Tira continua: un cuadrilátero por tramo, más ancho y opaco cuanto más reciente.
		for i in range(1, points.size()):
			var a0 := clampf(1.0 - (now - points[i - 1][0]) / TRAIL_LIFE, 0.0, 1.0)
			var a1 := clampf(1.0 - (now - points[i][0]) / TRAIL_LIFE, 0.0, 1.0)
			var p0: Vector2 = points[i - 1][1]
			var p1: Vector2 = points[i][1]
			var n := (p1 - p0).orthogonal().normalized()
			if n == Vector2.ZERO:
				continue
			var w0 := 6.0 * a0 + 1.0
			var w1 := 6.0 * a1 + 1.0
			draw_polygon(PackedVector2Array([p0 + n * w0, p1 + n * w1, p1 - n * w1, p0 - n * w0]),
				PackedColorArray([Color(color, a0 * 0.8), Color(color, a1 * 0.8), Color(color, a1 * 0.8), Color(color, a0 * 0.8)]))
