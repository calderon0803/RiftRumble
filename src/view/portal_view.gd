## Portal activo: entrada y salida (anillos que giran), enlace entre ambos y
## radio de enlace con las torres. Plano sobre el suelo.
extends Node2D

const Iso := preload("res://src/view/iso.gd")

var portal: Dictionary
var color := Color("6ff3ff")
var _t := 0.0


func _ready() -> void:
	z_index = -4


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var entry := Iso.to_screen(portal.entry)
	var exit := Iso.to_screen(portal.exit)
	_ellipse(entry, portal.link_radius, Color(color, 0.18), 1.0)
	_ellipse(exit, portal.exit_radius, Color(color, 0.25), 1.0)
	for p in [entry, exit]:
		for k in 3:
			var r := 14.0 + k * 5.0 + sin(_t * 6.0 + k) * 2.0
			_ring(p, r, Color(color, 0.9 - k * 0.25))
	# Enlace punteado entre entrada y salida.
	var n := int(entry.distance_to(exit) / 14.0)
	for i in n:
		if (i + int(_t * 10.0)) % 2 == 0:
			draw_line(entry.lerp(exit, float(i) / n), entry.lerp(exit, float(i + 1) / n), Color(color, 0.5), 2.0)


func _ring(c: Vector2, r: float, col: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, col, 2.0)
	draw_set_transform(Vector2.ZERO)


## Círculo en casillas = elipse en pantalla.
func _ellipse(center: Vector2, radius_tiles: float, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	for i in 49:
		var a := TAU * i / 48.0
		pts.append(center + Iso.to_screen(Vector2(cos(a), sin(a)) * radius_tiles))
	draw_colored_polygon(pts, Color(col, col.a * 0.4))
	draw_polyline(pts, col, width)
