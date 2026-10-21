## Proyectil: se dibuja a una altura fija sobre su posición lógica, pero ordena
## la profundidad por su proyección en el suelo (origen del nodo).
extends Sprite2D

const DEFAULT_TEX := preload("res://art/placeholder/projectile_bit.png")
const HEIGHT := 22.0


func _init() -> void:
	texture = DEFAULT_TEX
	offset = Vector2(0, -HEIGHT)


func set_source(def: TowerDef) -> void:
	texture = def.projectile_sprite if def and def.projectile_sprite else DEFAULT_TEX
