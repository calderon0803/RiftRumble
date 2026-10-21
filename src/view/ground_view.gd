## Suelo isométrico provisional dibujado por código (sin arte todavía).
extends Node2D

const Iso := preload("res://src/view/iso.gd")

var map_size := Vector2i(16, 16)
var waypoints := PackedVector2Array()

const GRASS_A := Color("3d7a4a")
const GRASS_B := Color("468a52")
const PATH_COLOR := Color("c9a46b")
const EDGE := Color(0, 0, 0, 0.18)


func _draw() -> void:
	var path_tiles := _rasterize_path()
	for y in map_size.y:
		for x in map_size.x:
			var color := PATH_COLOR if path_tiles.has(Vector2i(x, y)) \
					else (GRASS_A if (x + y) % 2 == 0 else GRASS_B)
			var poly := _tile_polygon(x, y)
			draw_colored_polygon(poly, color)
			poly.append(poly[0])
			draw_polyline(poly, EDGE, 1.0)
	if waypoints.size() >= 2:
		_draw_marker(waypoints[0], Color("8a5cff"))   # portal de entrada
		_draw_marker(waypoints[waypoints.size() - 1], Color("ff5c7a"))  # base


func _tile_polygon(x: int, y: int) -> PackedVector2Array:
	return PackedVector2Array([
		Iso.to_screen(Vector2(x, y)), Iso.to_screen(Vector2(x + 1, y)),
		Iso.to_screen(Vector2(x + 1, y + 1)), Iso.to_screen(Vector2(x, y + 1)),
	])


func _draw_marker(logical: Vector2, color: Color) -> void:
	var c := Iso.to_screen(logical)
	draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 26.0, Color(color, 0.55))
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 32, color, 3.0)
	draw_set_transform(Vector2.ZERO)


## Casillas que toca la ruta (segmentos alineados con los ejes).
func _rasterize_path() -> Dictionary:
	var tiles := {}
	for i in range(1, waypoints.size()):
		var a := waypoints[i - 1]
		var b := waypoints[i]
		var steps := int(ceil(a.distance_to(b) * 4.0))
		for s in steps + 1:
			var p := a.lerp(b, float(s) / maxf(steps, 1))
			tiles[Vector2i(floori(p.x), floori(p.y))] = true
	return tiles
