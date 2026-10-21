## Representación provisional de un enemigo. El origen del nodo es su «pie»
## (contacto con el suelo), que es lo que usa el Y-sort para la profundidad.
extends Node2D

var _hp_ratio := 1.0


func set_hp_ratio(value: float) -> void:
	if not is_equal_approx(value, _hp_ratio):
		_hp_ratio = value
		queue_redraw()


func reset() -> void:
	_hp_ratio = 1.0
	queue_redraw()


func _draw() -> void:
	# Sombra
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	# Cuerpo
	draw_rect(Rect2(-7, -22, 14, 20), Color("e0565b"))
	draw_rect(Rect2(-7, -22, 14, 20), Color("5a1a24"), false, 2.0)
	draw_rect(Rect2(-3, -18, 6, 4), Color("ffe9a8"))
	# Barra de vida
	if _hp_ratio < 1.0:
		draw_rect(Rect2(-10, -30, 20, 3), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-10, -30, 20 * _hp_ratio, 3), Color("7dff8a"))
