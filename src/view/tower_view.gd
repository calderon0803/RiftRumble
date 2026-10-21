## Torre provisional (sprite alto) con anillo de alcance opcional.
extends Sprite2D

const Iso := preload("res://src/view/iso.gd")
const TEX := preload("res://art/placeholder/tower_basic.png")

var _ring: RangeRing


func _init() -> void:
	texture = TEX
	offset = Vector2(0, -26)  # pie en (16, 58) del sprite de 32×64


func setup(logical_pos: Vector2, range_tiles: float, show_range: bool) -> void:
	position = Iso.to_screen(logical_pos)
	if show_range:
		_ring = RangeRing.new()
		_ring.range_tiles = range_tiles
		_ring.z_index = -5  # sobre el suelo, por debajo de las entidades
		add_child(_ring)


## Alcance circular en casillas = elipse en pantalla.
class RangeRing extends Node2D:
	var range_tiles := 3.0

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 65:
			var a := TAU * i / 64.0
			pts.append(Iso.to_screen(Vector2(cos(a), sin(a)) * range_tiles))
		draw_polyline(pts, Color(1, 1, 1, 0.35), 1.5)
