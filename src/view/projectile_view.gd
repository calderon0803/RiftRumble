## Proyectil provisional. Se dibuja a una altura fija sobre su posición lógica,
## pero ordena la profundidad por su proyección en el suelo.
extends Node2D

const HEIGHT := 18.0


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 3.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-3, -HEIGHT - 3, 6, 6), Color("6ff3ff"))
	draw_rect(Rect2(-1, -HEIGHT - 1, 2, 2), Color.WHITE)
