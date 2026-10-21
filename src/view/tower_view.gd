## Torre provisional: un pilar alto para comprobar la ordenación en profundidad
## con enemigos que pasan por delante y por detrás.
extends Node2D

const Iso := preload("res://src/view/iso.gd")

var logical_pos := Vector2.ZERO
var range_tiles := 3.0
var show_range := true


func _draw() -> void:
	if show_range:
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * i / 48.0
			var p := logical_pos + Vector2(cos(a), sin(a)) * range_tiles
			pts.append(Iso.to_screen(p) - Iso.to_screen(logical_pos))
		draw_polyline(pts, Color(1, 1, 1, 0.25), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, 0), Vector2(0, 6), Vector2(12, 0), Vector2(12, -48),
		Vector2(0, -42), Vector2(-12, -48)]), Color("4b5ea8"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 6), Vector2(12, 0), Vector2(12, -48), Vector2(0, -42)]), Color("34437d"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -48), Vector2(0, -54), Vector2(12, -48), Vector2(0, -42)]), Color("8fa2ff"))
	draw_circle(Vector2(0, -60), 5.0, Color("6ff3ff"))
