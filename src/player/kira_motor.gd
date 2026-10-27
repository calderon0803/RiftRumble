## Movimiento de Kira sin nodos: recibe la entrada y si está en el suelo y
## calcula la velocidad. Así se puede probar a mano y en tests sin física.
##
## Unidades: píxeles y segundos; +Y hacia abajo. Una casilla son 32 px.
class_name KiraMotor
extends RefCounted

const TILE := 32.0

## Carrera
const RUN_SPEED := 280.0
const GROUND_ACCEL := 3000.0
const GROUND_DECEL := 3600.0      # al soltar o al darse la vuelta: frena rápido
const AIR_ACCEL := 2200.0
const AIR_DECEL := 1200.0

## Salto: altura máxima (manteniendo), mínima (toque) y tiempo hasta lo alto.
const JUMP_HEIGHT := 5.3 * TILE
const JUMP_MIN_HEIGHT := 1.2 * TILE
const TIME_TO_APEX := 0.39
const FALL_GRAVITY_MULT := 1.7    # cae más rápido de lo que sube
const MAX_FALL_SPEED := 960.0

## Ayudas: saltar justo después de salir de un borde y pulsar un poco antes de aterrizar.
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12

var gravity := 2.0 * JUMP_HEIGHT / (TIME_TO_APEX * TIME_TO_APEX)
var jump_speed := 2.0 * JUMP_HEIGHT / TIME_TO_APEX
var jump_cut_speed := sqrt(2.0 * gravity * JUMP_MIN_HEIGHT)

var velocity := Vector2.ZERO
var facing := 1                   # 1 derecha, -1 izquierda
var _coyote := 0.0
var _buffer := 0.0
var _rising_jump := false


## Un paso. `move_x` en [-1, 1]; `jump_pressed` solo el fotograma en que se pulsa.
## Devuelve true si en este paso ha empezado un salto.
func step(dt: float, move_x: float, jump_pressed: bool, jump_held: bool, on_floor: bool) -> bool:
	# Horizontal
	var target := move_x * RUN_SPEED
	var accel: float
	if on_floor:
		var turning := move_x != 0.0 and signf(move_x) != signf(velocity.x) and velocity.x != 0.0
		accel = GROUND_DECEL if (move_x == 0.0 or turning) else GROUND_ACCEL
	else:
		accel = AIR_DECEL if move_x == 0.0 else AIR_ACCEL
	velocity.x = move_toward(velocity.x, target, accel * dt)
	if move_x != 0.0:
		facing = 1 if move_x > 0.0 else -1

	# Ayudas al salto
	if on_floor and velocity.y >= 0.0:
		_coyote = COYOTE_TIME
		_rising_jump = false
	else:
		_coyote -= dt
	_buffer = JUMP_BUFFER if jump_pressed else _buffer - dt

	var jumped := false
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = -jump_speed
		_buffer = 0.0
		_coyote = 0.0
		_rising_jump = true
		jumped = true

	# Soltar el botón mientras sube corta el salto (altura variable).
	if _rising_jump and not jump_held and velocity.y < 0.0:
		velocity.y = maxf(velocity.y, -jump_cut_speed)
		_rising_jump = false

	# Gravedad
	if not (on_floor and velocity.y >= 0.0):
		var g := gravity * (FALL_GRAVITY_MULT if velocity.y > 0.0 else 1.0)
		velocity.y = minf(velocity.y + g * dt, MAX_FALL_SPEED)
	elif not jumped:
		velocity.y = gravity * dt  # un empujoncito contra el suelo para seguir pegada
	return jumped
