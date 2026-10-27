## Rastrero: patrulla por el suelo y se da la vuelta en paredes y bordes.
## Hace daño al tocarlo. El origen está a sus pies.
class_name Crawler
extends CharacterBody2D

signal died(enemy: Node2D)

const SIZE := Vector2(30, 22)
const SPEED := 60.0
const MAX_HP := 3
const GRAVITY := 1800.0
const MAX_FALL := 900.0
const KNOCKBACK := 320.0
const KNOCKBACK_TIME := 0.15
const COLOR := Color("6fdc8c")
const COLOR_DARK := Color("1f4a2e")

var contact_damage := 1
var color := COLOR
var health := Health.new(MAX_HP)
var dir := -1
var _knock := 0.0
var _flash := 0.0


func _ready() -> void:
	collision_layer = Kira.LAYER_ENEMY
	collision_mask = Kira.LAYER_WORLD
	floor_snap_length = 6.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	shape.position = Vector2(0, -SIZE.y / 2)
	add_child(shape)


func _physics_process(dt: float) -> void:
	_flash = maxf(_flash - dt, 0.0)
	if _knock > 0.0:
		_knock -= dt
		velocity.x = move_toward(velocity.x, 0.0, 1600.0 * dt)
	else:
		if is_on_wall():
			dir = 1 if get_wall_normal().x > 0.0 else -1
		elif is_on_floor() and not _ground_ahead():
			dir = -dir
		velocity.x = dir * SPEED
	velocity.y = minf(velocity.y + GRAVITY * dt, MAX_FALL)
	move_and_slide()
	queue_redraw()


func center() -> Vector2:
	return position + Vector2(0, -SIZE.y / 2)


## Recibe un tajo desde `from` (posición de quien golpea). Devuelve si le ha dado.
func take_hit(damage: int, from: Vector2) -> bool:
	if health.is_dead():
		return false
	health.damage(damage)
	_flash = 0.1
	var away := 1.0 if position.x >= from.x else -1.0
	velocity.x = away * KNOCKBACK
	_knock = KNOCKBACK_TIME
	if health.is_dead():
		died.emit(self)
		queue_free()
	return true


## ¿Hay suelo justo delante? (si no, está en un borde)
func _ground_ahead() -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = position + Vector2(dir * (SIZE.x / 2 + 2), 6)
	q.collision_mask = Kira.LAYER_WORLD
	return not get_world_2d().direct_space_state.intersect_point(q, 1).is_empty()


func _draw() -> void:
	var body := Color.WHITE if _flash > 0.0 else COLOR
	draw_rect(Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, SIZE.y), body)
	draw_rect(Rect2(dir * (SIZE.x / 2 - 7) - 2, -SIZE.y + 6, 4, 4), COLOR_DARK)
