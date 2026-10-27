## Kira en la sala: cuerpo físico, entrada, tajos, daño recibido y dibujo
## provisional (un rectángulo hasta que haya sprites). El origen está a sus pies.
class_name Kira
extends CharacterBody2D

signal health_changed(hp: int, max_hp: int)
signal notches_changed(notches: int)
signal hit_landed(special: bool)
signal died

const SIZE := Vector2(22, 44)
const COLOR_BODY := Color("ff4fa0")
const COLOR_DARK := Color("9c2a63")
const MAX_HP := 5

## Capas de física: 1 escenario, 2 Kira, 3 enemigos.
const LAYER_WORLD := 1
const LAYER_KIRA := 2
const LAYER_ENEMY := 4

## Zonas de golpe (centro y tamaño, respecto a los pies, mirando a la derecha).
const HITBOX := {
	KiraCombat.Dir.FORWARD: [Vector2(34, -24), Vector2(52, 38)],
	KiraCombat.Dir.UP: [Vector2(0, -62), Vector2(40, 44)],
	KiraCombat.Dir.DOWN: [Vector2(0, 20), Vector2(40, 46)],
}
const SPECIAL_HITBOX := [Vector2(52, -26), Vector2(96, 54)]

## Sensación de golpe
const POGO_SPEED := 620.0          # rebote al acertar un tajo hacia abajo
const RECOIL_SPEED := 140.0        # retroceso al acertar un tajo hacia delante
const HURT_KNOCKBACK := Vector2(240, -320)
const HURT_INVULNERABLE := 1.0
const HURT_STUN := 0.22            # sin control tras recibir un golpe

var motor := KiraMotor.new()
var combat := KiraCombat.new()
var health := Health.new(MAX_HP)
## Para los tests: si no está vacío, se usa en lugar del teclado o el mando.
## Claves: "x" y "y" (float), "jump", "attack", "special" y "dash" (bool, mantenidos).
var scripted_input := {}
var _scripted_was := {}
var _stun := 0.0
## Entrada del último paso (la usa el mundo, p. ej. ↑ para sentarse en un banco).
var last_input := {}
var _hit_this_swing := {}
var _visual: Placeholder


func _ready() -> void:
	Controls.ensure()
	collision_layer = LAYER_KIRA
	collision_mask = LAYER_WORLD
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
	var inp := _read_input()
	last_input = inp
	_stun = maxf(_stun - dt, 0.0)
	if _stun > 0.0:
		inp.x = 0.0
		inp.jump_pressed = false
		inp.attack_pressed = false
		inp.special_pressed = false
		inp.dash_pressed = false

	motor.velocity = velocity
	var was_dashing := motor.is_dashing()
	motor.step(dt, inp.x, inp.jump_pressed, inp.jump_held, is_on_floor(), inp.dash_pressed, _wall_dir())
	if motor.is_dashing() and not was_dashing:
		_visual.dash_started()
	if motor.is_dashing():
		# Durante el dash no se ataca.
		inp.attack_pressed = false
		inp.special_pressed = false
	var notches_before := combat.notches
	var started := combat.step(dt, inp.attack_pressed, inp.special_pressed, inp.y, is_on_floor())
	if not started.is_empty():
		_hit_this_swing.clear()
		_visual.slash(started, motor.facing)
	if combat.is_active():
		_resolve_swing()
	if combat.notches != notches_before:
		notches_changed.emit(combat.notches)
	velocity = motor.velocity
	move_and_slide()

	health.step(dt)
	_check_contact_damage()
	_visual.scale.x = motor.facing
	_visual.dashing = motor.is_dashing()
	_visual.wall_sliding = motor.wall_sliding
	_visual.blink = health.invulnerable > 0.0
	_visual.queue_redraw()


## La coloca en un sitio sin cambiar su vida ni su filo (p. ej., tras pisar pinchos).
func place_at(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	_new_motor()
	_stun = HURT_STUN


func respawn(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	_new_motor()
	combat.reset()
	health.reset()
	_stun = 0.0
	health_changed.emit(health.hp, health.max_hp)
	notches_changed.emit(combat.notches)


## Habilidades conseguidas (se conservan al reaparecer).
var abilities := {}


func grant(ability: String) -> void:
	abilities[ability] = true
	_apply_abilities()


func _apply_abilities() -> void:
	motor.can_dash = abilities.has("dash")
	motor.can_wall_jump = abilities.has("wall_jump")


## 1 si hay pared pegada a la derecha, -1 a la izquierda, 0 si no (o en el suelo).
func _wall_dir() -> int:
	if is_on_floor():
		return 0
	if test_move(global_transform, Vector2(2, 0)):
		return 1
	if test_move(global_transform, Vector2(-2, 0)):
		return -1
	return 0


func clear_abilities() -> void:
	abilities.clear()
	_apply_abilities()


func set_max_hp(value: int) -> void:
	health.max_hp = value
	health.hp = value
	health_changed.emit(health.hp, health.max_hp)


func _new_motor() -> void:
	motor = KiraMotor.new()
	_apply_abilities()


## Enemigos que toca el tajo en curso (cada uno, una vez por tajo).
func _resolve_swing() -> void:
	var cur := combat.current
	var box: Array = SPECIAL_HITBOX if cur.special else HITBOX[cur.dir]
	var center: Vector2 = box[0]
	center.x *= motor.facing
	for enemy in _overlapping_enemies(position + center, box[1]):
		if _hit_this_swing.has(enemy) or not enemy.has_method("take_hit"):
			continue
		_hit_this_swing[enemy] = true
		if not enemy.take_hit(cur.damage, position):
			continue
		combat.on_hit()
		hit_landed.emit(cur.special)
		if cur.dir == KiraCombat.Dir.DOWN:
			motor.velocity.y = -POGO_SPEED
			motor.refresh_air_dash()
		elif cur.dir == KiraCombat.Dir.FORWARD:
			motor.velocity.x = -motor.facing * RECOIL_SPEED


func _check_contact_damage() -> void:
	if health.invulnerable > 0.0 or health.is_dead():
		return
	var hits := _overlapping_enemies(position + Vector2(0, -SIZE.y / 2), SIZE - Vector2(4, 4))
	if hits.is_empty():
		return
	var enemy: Node2D = hits[0]
	var dmg: int = enemy.contact_damage if "contact_damage" in enemy else 1
	if not health.damage(dmg, HURT_INVULNERABLE):
		return
	if enemy.has_method("on_hit_kira"):
		enemy.on_hit_kira()
	var away := -1.0 if enemy.global_position.x > global_position.x else 1.0
	velocity = Vector2(HURT_KNOCKBACK.x * away, HURT_KNOCKBACK.y)
	_stun = HURT_STUN
	health_changed.emit(health.hp, health.max_hp)
	if health.is_dead():
		died.emit()


func _overlapping_enemies(center: Vector2, size: Vector2) -> Array:
	var rect := RectangleShape2D.new()
	rect.size = size
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = rect
	q.transform = Transform2D(0.0, center)
	q.collision_mask = LAYER_ENEMY
	q.collide_with_bodies = true
	var out := []
	for r in get_world_2d().direct_space_state.intersect_shape(q, 16):
		if not out.has(r.collider):
			out.append(r.collider)
	return out


func _read_input() -> Dictionary:
	var inp := {}
	if scripted_input.is_empty():
		inp.x = Input.get_axis(Controls.MOVE_LEFT, Controls.MOVE_RIGHT)
		inp.y = Input.get_axis(Controls.MOVE_UP, Controls.MOVE_DOWN)
		inp.jump_held = Input.is_action_pressed(Controls.JUMP)
		inp.jump_pressed = Input.is_action_just_pressed(Controls.JUMP)
		inp.attack_pressed = Input.is_action_just_pressed(Controls.ATTACK)
		inp.special_pressed = Input.is_action_just_pressed(Controls.SPECIAL)
		inp.up_pressed = Input.is_action_just_pressed(Controls.MOVE_UP)
		inp.dash_pressed = Input.is_action_just_pressed(Controls.DASH)
		return inp
	inp.x = scripted_input.get("x", 0.0)
	inp.y = scripted_input.get("y", 0.0)
	for key in ["jump", "attack", "special", "dash"]:
		var held: bool = scripted_input.get(key, false)
		inp[key + "_held"] = held
		inp[key + "_pressed"] = held and not _scripted_was.get(key, false)
		_scripted_was[key] = held
	var up: bool = inp.y < -0.5
	inp.up_pressed = up and not _scripted_was.get("up", false)
	_scripted_was["up"] = up
	return inp


## Dibujo provisional: cuerpo rosa con franja y ojo hacia donde mira, y el tajo
## como un arco claro que se desvanece.
class Placeholder extends Node2D:
	const SLASH_TIME := 0.16
	const TRAIL_TIME := 0.2
	var blink := false
	var dashing := false
	var wall_sliding := false
	var _trail_t := 0.0
	var _slash := {}
	var _slash_t := 0.0

	func slash(attack: Dictionary, _facing: int) -> void:
		_slash = attack
		_slash_t = SLASH_TIME

	func dash_started() -> void:
		_trail_t = TRAIL_TIME

	func _process(dt: float) -> void:
		if _slash_t > 0.0:
			_slash_t -= dt
			queue_redraw()
		if _trail_t > 0.0:
			_trail_t -= dt
			queue_redraw()

	func _draw() -> void:
		var s := Kira.SIZE
		var alpha := 0.35 if blink and int(Time.get_ticks_msec() / 70) % 2 == 0 else 1.0
		if _trail_t > 0.0:
			# Estela del dash: copias que se desvanecen detrás.
			var k := _trail_t / TRAIL_TIME
			for i in 3:
				var back := -(i + 1) * 14.0
				draw_rect(Rect2(back - s.x / 2, -s.y, s.x, s.y), Color(Kira.COLOR_BODY, 0.35 * k / (i + 1)))
		draw_rect(Rect2(-s.x / 2, -s.y, s.x, s.y), Color(Kira.COLOR_BODY, alpha))
		draw_rect(Rect2(-s.x / 2, -s.y * 0.45, s.x, 6), Color(Kira.COLOR_DARK, alpha))
		draw_rect(Rect2(s.x / 2 - 8, -s.y + 9, 4, 5), Color(Kira.COLOR_DARK, alpha))
		if wall_sliding:
			# Rozando la pared (que queda a la espalda: mira hacia fuera).
			for i in 3:
				var y := -s.y + 8.0 + i * 12.0 + fmod(Time.get_ticks_msec() / 20.0, 12.0)
				draw_line(Vector2(-s.x / 2 - 2, y), Vector2(-s.x / 2 - 6, y + 4), Color(1, 1, 1, 0.5), 2.0)
		if _slash_t <= 0.0 or _slash.is_empty():
			return
		var k := _slash_t / SLASH_TIME
		var col := Color(1.0, 0.95, 0.7, k) if _slash.special else Color(1, 1, 1, k * 0.9)
		var box: Array = Kira.SPECIAL_HITBOX if _slash.special else Kira.HITBOX[_slash.dir]
		var c: Vector2 = box[0]
		var r: float = maxf(box[1].x, box[1].y) * 0.55
		var from := -PI * 0.45
		match _slash.dir:
			KiraCombat.Dir.UP:
				from = PI * 1.05
			KiraCombat.Dir.DOWN:
				from = PI * 0.05
		var pivot := c - Vector2(r * 0.5, 0) if _slash.dir == KiraCombat.Dir.FORWARD else Vector2(0, -22)
		draw_arc(pivot, r, from, from + PI * 0.9, 16, col, 6.0 if _slash.special else 4.0)
