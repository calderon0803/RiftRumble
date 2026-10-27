## Chispas en el punto de un golpe: rayas cortas que salen en abanico y se apagan.
class_name Sparks
extends Node2D

const LIFE := 0.16
var color := Color(1.0, 0.95, 0.75)
var count := 7
var _t := 0.0
var _dirs: Array[Vector2] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(position)
	for i in count:
		_dirs.append(Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(0.6, 1.0))


func _process(dt: float) -> void:
	_t += dt
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	for d in _dirs:
		draw_line(d * (4.0 + 22.0 * k), d * (10.0 + 30.0 * k), Color(color, 1.0 - k), 2.5)
