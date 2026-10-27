## Fondo de una sala: degradado y dos capas de siluetas (columnas y arcos) que se
## mueven más despacio que la cámara para dar profundidad. Las formas salen de una
## semilla por sala, así que cada sala es siempre igual.
class_name BackgroundView
extends Node2D

var layout: RoomLayout
var _pal: Dictionary
var _far: ParallaxShapes
var _near: ParallaxShapes


func setup(room: RoomLayout) -> void:
	layout = room
	_pal = Themes.palette(room.theme)
	z_index = -10
	_far = ParallaxShapes.new()
	_far.factor = 0.2
	_far.color = _pal.far
	_near = ParallaxShapes.new()
	_near.factor = 0.45
	_near.color = _pal.near
	for layer in [_far, _near]:
		layer.room = room.rect
		layer.build(hash(room.id) + (1 if layer == _near else 0), layer == _near)
		add_child(layer)
	queue_redraw()


func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null or layout == null:
		return
	var offset := cam.get_screen_center_position() - layout.rect.get_center()
	for layer in [_far, _near]:
		layer.position = offset * (1.0 - layer.factor)


func _draw() -> void:
	if layout == null:
		return
	var r := layout.rect
	var bands := 12
	for i in bands:
		var t := float(i) / (bands - 1)
		var band := Rect2(r.position.x, r.position.y + r.size.y * i / bands, r.size.x, r.size.y / bands + 1.0)
		draw_rect(band, _pal.bg_top.lerp(_pal.bg_bottom, t))


## Una capa de siluetas: columnas con remate y arcos entre ellas.
class ParallaxShapes extends Node2D:
	var factor := 0.3
	var color := Color.BLACK
	var room := Rect2()
	var _shapes: Array = []   # [PackedVector2Array]

	func build(seed_value: int, arches: bool) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var margin := room.size * 0.6
		var area := room.grow_individual(margin.x, margin.y, margin.x, margin.y)
		var x := area.position.x
		var bottom := area.end.y
		while x < area.end.x:
			var w := rng.randf_range(40, 90) * (1.6 if arches else 1.0)
			var h := rng.randf_range(0.35, 0.9) * room.size.y
			var top := bottom - h - margin.y
			var tip := rng.randf_range(10, 40)
			_shapes.append(PackedVector2Array([
				Vector2(x, bottom), Vector2(x, top), Vector2(x + w / 2, top - tip),
				Vector2(x + w, top), Vector2(x + w, bottom)]))
			if arches:
				var gap := rng.randf_range(80, 160)
				var arch_y := top + rng.randf_range(20, 60)
				var pts := PackedVector2Array([Vector2(x + w, arch_y - 26), Vector2(x + w, arch_y)])
				for i in 9:
					var a := PI + PI * i / 8.0
					pts.append(Vector2(x + w + gap / 2 + cos(a) * gap / 2, arch_y - 4 + sin(a) * -22.0 + 22.0))
				pts.append(Vector2(x + w + gap, arch_y))
				pts.append(Vector2(x + w + gap, arch_y - 26))
				_shapes.append(pts)
				x += w + gap
			else:
				x += w + rng.randf_range(30, 120)
		queue_redraw()

	func _draw() -> void:
		for s in _shapes:
			draw_colored_polygon(s, color)
