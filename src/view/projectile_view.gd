## Proyectil: se dibuja a una altura fija sobre su posición lógica, pero ordena
## la profundidad por su proyección en el suelo (origen del nodo).
extends Sprite2D

const TEX := preload("res://art/placeholder/projectile_bit.png")
const HEIGHT := 22.0


func _init() -> void:
	texture = TEX
	offset = Vector2(0, -HEIGHT)
