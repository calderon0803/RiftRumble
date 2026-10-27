## Objeto que se recoge al tocarlo: el dash (orbe azul) o un corazón extra.
class_name Pickup
extends Node2D

const RADIUS := 14.0
const COLORS := {"dash": Color("6fd3ff"), "heart": Color("ff4fa0")}

var kind := "dash"
var id := ""
var _t := 0.0


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _draw() -> void:
	var col: Color = COLORS.get(kind, Color.WHITE)
	var bob := sin(_t * 3.0) * 3.0
	draw_circle(Vector2(0, bob), RADIUS + 6.0 + sin(_t * 5.0) * 2.0, Color(col, 0.18))
	if kind == "heart":
		draw_rect(Rect2(Vector2(-11, -10 + bob), Vector2(22, 20)), col)
		draw_rect(Rect2(Vector2(-7, -6 + bob), Vector2(14, 12)), col.lightened(0.4))
	else:
		draw_circle(Vector2(0, bob), RADIUS * 0.7, col)
		draw_circle(Vector2(-3, -3 + bob), RADIUS * 0.25, Color.WHITE)
