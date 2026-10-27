## Onda que recorre el suelo tras el salto aplastante del Guardián. Hace daño al
## tocarla (no se puede golpear) y desaparece al chocar con una pared.
class_name Shockwave
extends CharacterBody2D

const SIZE := Vector2(26, 22)
const COLOR := Color("ffb347")

var contact_damage := 1
var dir := 1
var speed := 360.0
var _t := 0.0


func _ready() -> void:
	collision_layer = Kira.LAYER_ENEMY
	collision_mask = Kira.LAYER_WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	shape.position = Vector2(0, -SIZE.y / 2)
	add_child(shape)


func _physics_process(dt: float) -> void:
	_t += dt
	velocity = Vector2(dir * speed, 0.0)
	move_and_slide()
	if is_on_wall() or _t > 4.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var flicker := 0.75 + 0.25 * sin(_t * 30.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-SIZE.x / 2, 0), Vector2(-dir * 4, -SIZE.y), Vector2(SIZE.x / 2, 0)]), Color(COLOR, flicker))
