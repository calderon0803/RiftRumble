## Polvo a los pies al saltar o al aterrizar: nubecillas que se abren hacia los lados.
class_name Dust
extends Node2D

const LIFE := 0.3
var amount := 1.0          # 1 = aterrizaje normal; más, más polvo
var _t := 0.0


func _process(dt: float) -> void:
	_t += dt
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var col := Color(0.8, 0.82, 0.9, 0.45 * (1.0 - k))
	for side: float in [-1.0, 1.0]:
		for i in 3:
			var x := side * (6.0 + i * 7.0 + 26.0 * k * amount)
			draw_circle(Vector2(x, -3.0 - i), (3.0 + i) * (1.0 - 0.5 * k), col)
