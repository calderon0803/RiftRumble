## Vista de una torre: sprite de su TowerDef, marcas de nivel y anillo de
## alcance cuando está seleccionada.
extends Sprite2D

const Iso := preload("res://src/view/iso.gd")
const DEFAULT_TEX := preload("res://art/placeholder/tower_basic.png")

var _ring: RangeRing
var _pips: LevelPips


func _init() -> void:
	_ring = RangeRing.new()
	_ring.z_index = -5  # sobre el suelo, por debajo de las entidades
	_ring.visible = false
	add_child(_ring)
	_pips = LevelPips.new()
	add_child(_pips)


func show_tower(t: Dictionary) -> void:
	var def: TowerDef = t.def
	texture = def.sprite if def.sprite else DEFAULT_TEX
	offset = def.sprite_offset
	position = Iso.to_screen(t.pos)
	_ring.range_tiles = TowerDef.at_level(def.range_tiles, t.level)
	_ring.queue_redraw()
	_pips.level = t.level
	_pips.max_level = def.max_level()
	_pips.queue_redraw()


func set_selected(selected: bool) -> void:
	_ring.visible = selected


## Alcance circular en casillas = elipse en pantalla.
class RangeRing extends Node2D:
	var range_tiles := 3.0

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 65:
			var a := TAU * i / 64.0
			pts.append(Iso.to_screen(Vector2(cos(a), sin(a)) * range_tiles))
		draw_colored_polygon(pts, Color(0.43, 0.95, 1.0, 0.10))
		draw_polyline(pts, Color(0.43, 0.95, 1.0, 0.7), 2.0)


## Rombos de nivel bajo la torre.
class LevelPips extends Node2D:
	var level := 1
	var max_level := 3

	func _draw() -> void:
		for i in max_level:
			var c := Vector2((i - (max_level - 1) * 0.5) * 9.0, 8.0)
			var pts := PackedVector2Array([c + Vector2(0, -3), c + Vector2(4, 0), c + Vector2(0, 3), c + Vector2(-4, 0)])
			draw_colored_polygon(pts, Color("ffe066") if i < level else Color(0, 0, 0, 0.45))
