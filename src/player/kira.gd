## Kira en la sala: cuerpo físico, entrada, tajos, daño recibido y su dibujo
## por piezas (esqueleto animado, art/kira/). El origen está a sus pies.
class_name Kira
extends CharacterBody2D

signal health_changed(hp: int, max_hp: int)
signal notches_changed(notches: int)
signal hit_landed(special: bool, at: Vector2)
signal died
## Ha caído al suelo desde cierta velocidad (para temblor y polvo).
signal landed(fall_speed: float)

## Caída mínima para levantar polvo al aterrizar.
const DUST_FALL_SPEED := 420.0

const SIZE := Vector2(22, 44)
const RIG := preload("res://art/kira/kira_rig.tres")
const Anims := preload("res://src/player/rig/cutout_anims.gd")
## Animación de cada tajo.
const SLASH_ANIMS := {
	KiraCombat.Dir.FORWARD: &"slash", KiraCombat.Dir.UP: &"slash_up", KiraCombat.Dir.DOWN: &"slash_down",
}
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
var rig: CutoutRig
var _anim_clock := 0.0


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
	rig = CutoutRig.new()
	rig.setup(RIG)
	add_child(rig)
	_visual = Placeholder.new()
	_visual.draw_body = false
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
	var was_on_floor := is_on_floor()
	var fall_speed := velocity.y
	if motor.step(dt, inp.x, inp.jump_pressed, inp.jump_held, was_on_floor, inp.dash_pressed, _wall_dir()) and was_on_floor:
		_spawn_fx(Dust.new(), position)
	if motor.is_dashing() and Engine.get_physics_frames() % 3 == 0:
		_spawn_ghost()
	if motor.is_dashing():
		# Durante el dash no se ataca.
		inp.attack_pressed = false
		inp.special_pressed = false
	var notches_before := combat.notches
	var started := combat.step(dt, inp.attack_pressed, inp.special_pressed, inp.y, is_on_floor())
	if not started.is_empty():
		_hit_this_swing.clear()
		rig.play(&"special" if started.special else SLASH_ANIMS[started.dir], true)
	if combat.is_active():
		_resolve_swing()
	if combat.notches != notches_before:
		notches_changed.emit(combat.notches)
	velocity = motor.velocity
	move_and_slide()
	if is_on_floor() and not was_on_floor and fall_speed > DUST_FALL_SPEED:
		var dust := Dust.new()
		dust.amount = clampf(fall_speed / 700.0, 0.7, 1.6)
		_spawn_fx(dust, position)
		landed.emit(fall_speed)

	health.step(dt)
	_check_contact_damage()
	_update_rig(dt)
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


## Elige la animación según lo que está haciendo: tajo o golpe recibido en curso >
## dash > pared > aire (subiendo / cayendo) > correr > reposo.
func _update_rig(dt: float) -> void:
	_anim_clock += dt
	var cur := rig.current()
	var busy := (cur in [&"slash", &"slash_up", &"slash_down", &"special", &"hit"]) and not rig.finished()
	var speed := absf(velocity.x)
	var rate := 1.0
	if not busy:
		var anim := &"idle"
		if motor.is_dashing():
			anim = &"dash"
		elif motor.wall_sliding:
			anim = &"wall_slide"
		elif not is_on_floor():
			anim = &"jump" if velocity.y < 0.0 else &"fall"
		elif speed > 20.0:
			anim = &"run"
			rate = clampf(speed / Anims.RUN_REFERENCE_SPEED, 0.6, 1.5)
		rig.play(anim)
	rig.update(_anim_clock, motor.facing < 0, rate, speed)
	var blink := health.invulnerable > 0.0 and int(Time.get_ticks_msec() / 70) % 2 == 0
	rig.modulate.a = 0.35 if blink else 1.0


## Copia de Kira que se desvanece (estela del dash).
func _spawn_ghost() -> void:
	if get_parent() == null:
		return
	var g := CutoutRig.new()
	g.setup(RIG)
	g.copy_state(rig)
	g.update(_anim_clock, motor.facing < 0, 0.0, 0.0)
	g.modulate = Color(1.0, 0.55, 0.85, 0.5)
	g.position = position
	g.z_index = -1
	get_parent().add_child(g)
	var t := g.create_tween()
	t.tween_property(g, "modulate:a", 0.0, 0.22)
	t.tween_callback(g.queue_free)


## Efecto (polvo, chispas) en el mismo nivel que Kira, para que no la siga.
func _spawn_fx(fx: Node2D, at: Vector2) -> void:
	if get_parent() == null:
		return
	fx.position = at
	get_parent().add_child(fx)


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
		var at: Vector2 = enemy.center() if enemy.has_method("center") else enemy.global_position
		var sp := Sparks.new()
		if cur.special:
			sp.color = Color("f5e27a")
			sp.count = 12
		_spawn_fx(sp, at)
		hit_landed.emit(cur.special, at)
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
	rig.play(&"hit", true)
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


## Efectos de dibujo encima de Kira: roce en la pared (y el cuerpo provisional de
## rectángulo si `draw_body`, para pruebas sin esqueleto).
class Placeholder extends Node2D:
	var draw_body := true
	var blink := false
	var dashing := false
	var wall_sliding := false

	func _draw() -> void:
		var s := Kira.SIZE
		if draw_body:
			var alpha := 0.35 if blink and int(Time.get_ticks_msec() / 70) % 2 == 0 else 1.0
			draw_rect(Rect2(-s.x / 2, -s.y, s.x, s.y), Color(Kira.COLOR_BODY, alpha))
			draw_rect(Rect2(-s.x / 2, -s.y * 0.45, s.x, 6), Color(Kira.COLOR_DARK, alpha))
			draw_rect(Rect2(s.x / 2 - 8, -s.y + 9, 4, 5), Color(Kira.COLOR_DARK, alpha))
		if wall_sliding:
			# Rozando la pared (que queda a la espalda: mira hacia fuera).
			for i in 3:
				var y := -s.y + 8.0 + i * 12.0 + fmod(Time.get_ticks_msec() / 20.0, 12.0)
				draw_line(Vector2(-s.x / 2 - 2, y), Vector2(-s.x / 2 - 6, y + 4), Color(1, 1, 1, 0.5), 2.0)
