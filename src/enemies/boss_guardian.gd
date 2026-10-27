## El Guardián (nombre provisional): primer jefe. Patrón fijo que se puede aprender:
## - Embestida: aviso, carga de pared a pared (se esquiva saltando); al chocar queda
##   aturdido (momento para golpearle).
## - Salto aplastante: aviso, salta hacia Kira y al caer lanza dos ondas por el suelo.
## A media vida (fase 2) va más rápido y embiste dos veces seguidas.
## El origen está a sus pies.
class_name BossGuardian
extends CharacterBody2D

signal died(boss: BossGuardian)
signal health_changed(ratio: float)
## Ha aterrizado del salto aplastante (para el temblor de cámara).
signal slammed

enum State { IDLE, CHARGE_WINDUP, CHARGE, STUNNED, SLAM_WINDUP, SLAM_AIR, SLAM_RECOVER, DEAD }

const DISPLAY_NAME := "Guardián"
const SIZE := Vector2(60, 84)
const MAX_HP := 30
const GRAVITY := 2200.0
const COLOR := Color("8e3b5c")
const COLOR_DARK := Color("2a1020")
const COLOR_WARN := Color("ffe066")

## Fase 1 / fase 2
const IDLE_TIME := [0.9, 0.55]
const CHARGE_WINDUP := [0.6, 0.45]
const CHARGE_SPEED := [520.0, 640.0]
const STUN_TIME := [0.9, 0.7]
const SLAM_WINDUP := [0.5, 0.4]
const SLAM_AIR_TIME := 0.8
const SLAM_HEIGHT := 4.0 * 32.0
const SLAM_RECOVER := [0.6, 0.45]
const WAVE_SPEED := [360.0, 440.0]
## Orden de ataques: se repite.
const PATTERN := [["charge", "slam"], ["slam", "charge"]]

var contact_damage := 1
var health := Health.new(MAX_HP)
var target: Node2D
## Dónde puede aterrizar (para que el salto no se salga de la arena), en píxeles.
var arena := Rect2()
var state := State.IDLE
var facing := -1
var phase := 0
var _t := 0.0
var _pattern_i := 0
var _charges_left := 0
var _flash := 0.0
var _slam_g := 0.0


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
	_enter(State.IDLE)


func _physics_process(dt: float) -> void:
	_flash = maxf(_flash - dt, 0.0)
	_t -= dt
	match state:
		State.IDLE:
			_face_target()
			velocity.x = 0.0
			if _t <= 0.0:
				_next_attack()
		State.CHARGE_WINDUP, State.SLAM_WINDUP, State.STUNNED, State.SLAM_RECOVER:
			velocity.x = 0.0
			if _t <= 0.0:
				match state:
					State.CHARGE_WINDUP:
						_enter(State.CHARGE)
					State.SLAM_WINDUP:
						_start_slam()
					State.STUNNED, State.SLAM_RECOVER:
						_enter(State.IDLE)
		State.CHARGE:
			velocity.x = facing * CHARGE_SPEED[phase]
		State.DEAD:
			velocity.x = 0.0
	var g := _slam_g if state == State.SLAM_AIR else GRAVITY
	velocity.y = minf(velocity.y + g * dt, 1200.0)
	move_and_slide()

	if state == State.CHARGE and is_on_wall():
		_charges_left -= 1
		if _charges_left > 0:
			facing = -facing
			_enter(State.CHARGE_WINDUP, 0.25)
		else:
			_enter(State.STUNNED)
	elif state == State.SLAM_AIR and is_on_floor() and velocity.y >= 0.0 and _t < SLAM_AIR_TIME - 0.1:
		_land()
	queue_redraw()


## Recibe un tajo. No retrocede (es pesado), solo parpadea.
func take_hit(damage: int, _from: Vector2) -> bool:
	if state == State.DEAD:
		return false
	health.damage(damage)
	_flash = 0.08
	health_changed.emit(float(health.hp) / health.max_hp)
	if phase == 0 and health.hp <= health.max_hp / 2:
		phase = 1
	if health.is_dead():
		_enter(State.DEAD)
		died.emit(self)
	return true


func _enter(s: State, time := -1.0) -> void:
	state = s
	match s:
		State.IDLE:
			_t = IDLE_TIME[phase]
		State.CHARGE_WINDUP:
			_t = CHARGE_WINDUP[phase] if time < 0.0 else time
		State.STUNNED:
			_t = STUN_TIME[phase]
		State.SLAM_WINDUP:
			_t = SLAM_WINDUP[phase]
		State.SLAM_RECOVER:
			_t = SLAM_RECOVER[phase]
		State.SLAM_AIR:
			_t = SLAM_AIR_TIME
		_:
			_t = time


func _next_attack() -> void:
	var seq: Array = PATTERN[phase]
	var attack: String = seq[_pattern_i % seq.size()]
	_pattern_i += 1
	_face_target()
	if attack == "charge":
		_charges_left = 2 if phase == 1 else 1
		_enter(State.CHARGE_WINDUP)
	else:
		_enter(State.SLAM_WINDUP)


## Salto en arco hacia donde está Kira, aterrizando en SLAM_AIR_TIME segundos.
func _start_slam() -> void:
	var to_x := target.global_position.x if target else position.x
	if arena.has_area():
		to_x = clampf(to_x, arena.position.x + SIZE.x, arena.end.x - SIZE.x)
	var half := SLAM_AIR_TIME / 2.0
	_slam_g = 2.0 * SLAM_HEIGHT / (half * half)
	velocity = Vector2((to_x - position.x) / SLAM_AIR_TIME, -_slam_g * half)
	_enter(State.SLAM_AIR)


func _land() -> void:
	velocity.x = 0.0
	slammed.emit()
	for d in [-1, 1]:
		var w := Shockwave.new()
		w.dir = d
		w.speed = WAVE_SPEED[phase]
		w.position = position + Vector2(d * (SIZE.x / 2 + 16), 0)
		get_parent().add_child(w)
	_enter(State.SLAM_RECOVER)


func _face_target() -> void:
	if target:
		facing = 1 if target.global_position.x > position.x else -1


func _draw() -> void:
	if state == State.DEAD:
		return
	var body := COLOR.lightened(0.25) if phase == 1 else COLOR
	var crouch := 0.0
	if state in [State.CHARGE_WINDUP, State.SLAM_WINDUP]:
		crouch = 10.0
		if int(_t * 12.0) % 2 == 0:
			body = COLOR_WARN  # aviso: parpadea en amarillo
	if state == State.STUNNED:
		body = body.darkened(0.35)
	if _flash > 0.0:
		body = Color.WHITE
	var h := SIZE.y - crouch
	draw_rect(Rect2(-SIZE.x / 2, -h, SIZE.x, h), body)
	draw_rect(Rect2(-SIZE.x / 2, -h + 22, SIZE.x, 8), COLOR_DARK)
	var eye_x := facing * (SIZE.x / 2 - 14)
	draw_rect(Rect2(eye_x - 5, -h + 10, 10, 8), COLOR_WARN if phase == 1 else Color.WHITE)
	if state == State.STUNNED:
		for i in 3:
			var a := Time.get_ticks_msec() / 200.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 22.0, -h - 12 + sin(a) * 6.0), 4.0, COLOR_WARN)
