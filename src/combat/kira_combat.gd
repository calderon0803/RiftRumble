## Ataques de Kira sin nodos: cuándo empieza un tajo, hacia dónde, cuánto dura
## su golpe y el filo (6 muescas que se llenan al acertar y se gastan en el tajo de filo).
class_name KiraCombat
extends RefCounted

enum Dir { FORWARD, UP, DOWN }

const COOLDOWN := 0.32        # entre tajos
const ACTIVE := 0.10          # tiempo en que el tajo golpea
const DAMAGE := 1
const NOTCHES_MAX := 6
const SPECIAL_COST := 3
const SPECIAL_DAMAGE := 3
const SPECIAL_COOLDOWN := 0.45

var notches := 0
## Ataque en curso (vacío si no hay): dir, special, damage, id.
var current := {}
var _cooldown := 0.0
var _active := 0.0
var _next_id := 0


## Un paso. `move_y`: -1 arriba, 1 abajo. Devuelve el ataque si empieza uno en este paso.
func step(dt: float, attack_pressed: bool, special_pressed: bool, move_y: float, on_floor: bool) -> Dictionary:
	_cooldown = maxf(_cooldown - dt, 0.0)
	_active = maxf(_active - dt, 0.0)
	if _active <= 0.0:
		current = {}
	if _cooldown > 0.0:
		return {}
	if special_pressed and notches >= SPECIAL_COST:
		notches -= SPECIAL_COST
		return _start(Dir.FORWARD, true, SPECIAL_DAMAGE, SPECIAL_COOLDOWN)
	if attack_pressed:
		var dir := Dir.FORWARD
		if move_y < -0.5:
			dir = Dir.UP
		elif move_y > 0.5 and not on_floor:
			dir = Dir.DOWN
		return _start(dir, false, DAMAGE, COOLDOWN)
	return {}


func is_active() -> bool:
	return _active > 0.0


## El tajo en curso ha alcanzado a un enemigo: el tajo normal llena una muesca.
func on_hit() -> void:
	if not current.is_empty() and not current.special:
		notches = mini(notches + 1, NOTCHES_MAX)


func reset() -> void:
	notches = 0
	current = {}
	_cooldown = 0.0
	_active = 0.0


func _start(dir: Dir, special: bool, damage: int, cooldown: float) -> Dictionary:
	_next_id += 1
	current = {"dir": dir, "special": special, "damage": damage, "id": _next_id}
	_cooldown = cooldown
	_active = ACTIVE
	return current
