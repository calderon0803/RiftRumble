## Estallido provisional: cuadraditos que salen disparados y se desvanecen.
class_name Burst
extends Node2D

const LIFE := 0.45
var color := Color.WHITE
var _t := 0.0
var _parts: Array = []  # [posición, velocidad, tamaño]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(position)
	for i in 10:
		var a := rng.randf_range(-PI, 0.0)
		_parts.append([Vector2.ZERO, Vector2.from_angle(a) * rng.randf_range(90, 260), rng.randf_range(3, 7)])


func _process(dt: float) -> void:
	_t += dt
	if _t >= LIFE:
		queue_free()
		return
	for p in _parts:
		p[1].y += 700.0 * dt
		p[0] += p[1] * dt
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _t / LIFE
	for p in _parts:
		draw_rect(Rect2(p[0] - Vector2.ONE * p[2] / 2, Vector2.ONE * p[2]), Color(color, k))
