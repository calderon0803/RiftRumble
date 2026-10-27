## Cámara con temblor: `shake(fuerza, duración)` desplaza la vista al azar y se
## va calmando. Si llegan varios temblores, manda el más fuerte.
class_name CameraShake
extends Camera2D

var strength := 0.0
var _time := 0.0
var _duration := 0.0
var _rng := RandomNumberGenerator.new()


func shake(amount: float, duration: float) -> void:
	if amount < current():
		return
	strength = amount
	_duration = duration
	_time = duration


## Fuerza actual del temblor (0 si está quieta).
func current() -> float:
	return strength * _time / _duration if _time > 0.0 else 0.0


func _process(dt: float) -> void:
	if _time <= 0.0:
		offset = Vector2.ZERO
		return
	_time = maxf(_time - dt, 0.0)
	var k := _time / _duration
	offset = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * strength * k
	if _time <= 0.0:
		strength = 0.0
