## Fila de 3 estrellas dibujadas (no depende de que la fuente tenga el glifo ★).
extends Control

var stars := 0
## Radio exterior de cada estrella (px).
var radius := 22.0


func set_stars(value: int) -> void:
	stars = value
	queue_redraw()


func _draw() -> void:
	for i in 3:
		var c := Vector2(size.x * (i + 0.5) / 3.0, size.y * 0.5)
		var pts := PackedVector2Array()
		for k in 10:
			var r := radius if k % 2 == 0 else radius * 0.41
			var a := -PI / 2 + k * PI / 5
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, Color("ffd34d") if i < stars else Color(1, 1, 1, 0.15))
		pts.append(pts[0])
		draw_polyline(pts, Color("1e1830"), maxf(radius / 11.0, 1.0))
