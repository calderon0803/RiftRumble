## Kira en la sala: cuerpo físico, entrada y dibujo provisional (un rectángulo
## hasta que haya sprites). El origen está a sus pies.
class_name Kira
extends CharacterBody2D

const SIZE := Vector2(22, 44)
const COLOR_BODY := Color("ff4fa0")
const COLOR_DARK := Color("9c2a63")

var motor := KiraMotor.new()
## Para los tests: si no está vacío, se usa en lugar del teclado o el mando.
## Claves: "x" (float) y "jump" (bool, mantenido).
var scripted_input := {}
var _scripted_jump_was := false
var _visual: Node2D


func _ready() -> void:
	Controls.ensure()
	floor_snap_length = 6.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	shape.position = Vector2(0, -SIZE.y / 2)
	add_child(shape)
	_visual = Placeholder.new()
	add_child(_visual)


func _physics_process(dt: float) -> void:
	var move_x: float
	var jump_held: bool
	var jump_pressed: bool
	if scripted_input.is_empty():
		move_x = Input.get_axis(Controls.MOVE_LEFT, Controls.MOVE_RIGHT)
		jump_held = Input.is_action_pressed(Controls.JUMP)
		jump_pressed = Input.is_action_just_pressed(Controls.JUMP)
	else:
		move_x = scripted_input.get("x", 0.0)
		jump_held = scripted_input.get("jump", false)
		jump_pressed = jump_held and not _scripted_jump_was
		_scripted_jump_was = jump_held
	motor.velocity = velocity
	motor.step(dt, move_x, jump_pressed, jump_held, is_on_floor())
	velocity = motor.velocity
	move_and_slide()
	_visual.scale.x = motor.facing


func respawn(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	motor = KiraMotor.new()


## Dibujo provisional: cuerpo rosa, franja oscura y un ojo hacia donde mira.
class Placeholder extends Node2D:
	func _draw() -> void:
		var s := Kira.SIZE
		draw_rect(Rect2(-s.x / 2, -s.y, s.x, s.y), Kira.COLOR_BODY)
		draw_rect(Rect2(-s.x / 2, -s.y * 0.45, s.x, 6), Kira.COLOR_DARK)
		draw_rect(Rect2(s.x / 2 - 8, -s.y + 9, 4, 5), Kira.COLOR_DARK)
