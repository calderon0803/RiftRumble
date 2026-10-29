## Escupidor (nombre provisional): fijo en el suelo. Si Kira está a tiro, se
## ilumina para avisar y le dispara un proyectil; luego recarga. El origen está a sus pies.
class_name Spitter
extends CharacterBody2D

signal died(enemy: Node2D)

enum State { IDLE, WINDUP }

const SIZE := Vector2(28, 30)
const COLOR := Color("e0b04a")
const COLOR_DARK := Color("4a3510")
const COLOR_WARN := Color("fff1a8")
const MAX_HP := 3
const RANGE := 10.0 * 32.0
const MAX_HEIGHT_DIFF := 9.0 * 32.0
const WINDUP := 0.5
const COOLDOWN := 2.0
const SHOT_SPEED := 300.0
const GRAVITY := 1800.0

var contact_damage := 1
var health := Health.new(MAX_HP)
var target: Node2D
var state := State.IDLE
var facing := -1
var color := COLOR
var shots_fired := 0
var _t := 0.0
var _cooldown := 0.6
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


func center() -> Vector2:
	return position + Vector2(0, -SIZE.y / 2)


func _physics_process(dt: float) -> void:
	_flash = maxf(_flash - dt, 0.0)
	_cooldown = maxf(_cooldown - dt, 0.0)
	_t -= dt
	var aim := _target_center()
	var in_range := aim != Vector2.INF and absf(aim.x - position.x) < RANGE and absf(aim.y - center().y) < MAX_HEIGHT_DIFF
	if aim != Vector2.INF:
		facing = 1 if aim.x > position.x else -1
	match state:
		State.IDLE:
			if in_range and _cooldown <= 0.0:
				state = State.WINDUP
				_t = WINDUP
		State.WINDUP:
			if _t <= 0.0:
				if in_range:
					_shoot(aim)
				state = State.IDLE
				_cooldown = COOLDOWN
	velocity = Vector2(0.0, minf(velocity.y + GRAVITY * dt, 900.0))
	move_and_slide()
	queue_redraw()


func take_hit(damage: int, _from: Vector2) -> bool:
	if health.is_dead():
		return false
	health.damage(damage)
	_flash = 0.1
	if health.is_dead():
		died.emit(self)
		queue_free()
	return true


func _shoot(aim: Vector2) -> void:
	var p := Projectile.new()
	p.position = center() + Vector2(facing * (SIZE.x / 2 + 6), -4)
	p.direction = (aim - p.position).normalized()
	p.speed = SHOT_SPEED
	get_parent().add_child(p)
	shots_fired += 1


func _target_center() -> Vector2:
	if target == null:
		return Vector2.INF
	return target.global_position + Vector2(0, -Kira.SIZE.y / 2)


func _draw() -> void:
	var body := Color.WHITE if _flash > 0.0 else COLOR
	if state == State.WINDUP and int(_t * 14.0) % 2 == 0:
		body = COLOR_WARN
	draw_rect(Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, SIZE.y), body)
	draw_rect(Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, 6), COLOR_DARK)
	draw_rect(Rect2(facing * (SIZE.x / 2) - 4, -SIZE.y * 0.62, 8, 8), COLOR_DARK)
