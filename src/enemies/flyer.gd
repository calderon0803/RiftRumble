## Revoloteador (nombre provisional): flota en su sitio; si Kira se acerca, tiembla
## para avisar y se lanza en picado hacia ella, y luego vuelve. El origen está en
## su centro (no tiene pies).
class_name Flyer
extends CharacterBody2D

signal died(enemy: Node2D)

enum State { HOVER, WINDUP, DIVE, RETURN }

const SIZE := Vector2(26, 20)
const COLOR := Color("c58cff")
const COLOR_DARK := Color("3b1f5c")
const MAX_HP := 2
const SENSE_RANGE := 7.0 * 32.0
const WINDUP := 0.4
const DIVE_SPEED := 380.0
const DIVE_TIME := 0.9
const RETURN_SPEED := 120.0
const COOLDOWN := 1.0
const HOVER_AMPLITUDE := 10.0
const KNOCKBACK := 300.0
const KNOCKBACK_TIME := 0.15

var contact_damage := 1
var health := Health.new(MAX_HP)
var target: Node2D
var home := Vector2.ZERO
var state := State.HOVER
var color := COLOR
var _t := 0.0
var _cooldown := 0.0
var _dive_dir := Vector2.ZERO
var _knock := 0.0
var _flash := 0.0
var _clock := 0.0


func _ready() -> void:
	collision_layer = Kira.LAYER_ENEMY
	collision_mask = Kira.LAYER_WORLD
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	home = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	add_child(shape)


func center() -> Vector2:
	return position


func _physics_process(dt: float) -> void:
	_clock += dt
	_t -= dt
	_cooldown = maxf(_cooldown - dt, 0.0)
	_flash = maxf(_flash - dt, 0.0)
	if _knock > 0.0:
		_knock -= dt
		velocity = velocity.move_toward(Vector2.ZERO, 1800.0 * dt)
		move_and_slide()
		queue_redraw()
		return
	match state:
		State.HOVER:
			var bob := Vector2(0.0, sin(_clock * 2.0) * HOVER_AMPLITUDE)
			velocity = (home + bob - position) * 4.0
			if _cooldown <= 0.0 and _target_center().distance_to(position) < SENSE_RANGE:
				state = State.WINDUP
				_t = WINDUP
		State.WINDUP:
			velocity = Vector2.ZERO
			if _t <= 0.0:
				_dive_dir = (_target_center() - position).normalized()
				state = State.DIVE
				_t = DIVE_TIME
		State.DIVE:
			velocity = _dive_dir * DIVE_SPEED
		State.RETURN:
			var to_home := home - position
			velocity = to_home.normalized() * RETURN_SPEED if to_home.length() > 4.0 else Vector2.ZERO
			if to_home.length() <= 4.0:
				state = State.HOVER
				_cooldown = COOLDOWN
	move_and_slide()
	if state == State.DIVE and (_t <= 0.0 or get_slide_collision_count() > 0):
		state = State.RETURN
	queue_redraw()


func take_hit(damage: int, from: Vector2) -> bool:
	if health.is_dead():
		return false
	health.damage(damage)
	_flash = 0.1
	var away := (position - from)
	away = away.normalized() if away.length() > 0.1 else Vector2.UP
	velocity = away * KNOCKBACK
	_knock = KNOCKBACK_TIME
	if state == State.DIVE or state == State.WINDUP:
		state = State.RETURN
	if health.is_dead():
		died.emit(self)
		queue_free()
	return true


func _target_center() -> Vector2:
	if target == null:
		return Vector2.INF
	return target.global_position + Vector2(0, -22)


func _draw() -> void:
	var body := Color.WHITE if _flash > 0.0 else COLOR
	var shake := Vector2(sin(_clock * 80.0) * 2.0, 0.0) if state == State.WINDUP else Vector2.ZERO
	var flap := absf(sin(_clock * 14.0)) * 8.0
	draw_colored_polygon(PackedVector2Array([shake + Vector2(-4, -2), shake + Vector2(-18, -6 - flap), shake + Vector2(-10, 4)]), body.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([shake + Vector2(4, -2), shake + Vector2(18, -6 - flap), shake + Vector2(10, 4)]), body.darkened(0.2))
	draw_rect(Rect2(shake - SIZE / 2 + Vector2(5, 2), SIZE - Vector2(10, 4)), body)
	var eye := Color("ffe066") if state in [State.WINDUP, State.DIVE] else COLOR_DARK
	draw_rect(Rect2(shake + Vector2(-5, -3), Vector2(3, 3)), eye)
	draw_rect(Rect2(shake + Vector2(2, -3), Vector2(3, 3)), eye)
