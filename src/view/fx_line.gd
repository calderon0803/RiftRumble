## Destello de un ataque en línea (corte cargado): banda que se desvanece.
extends Node2D

const LIFETIME := 0.35

var from := Vector2.ZERO
var to := Vector2.ZERO
var width := 10.0
var color := Color("ff6fd8")
var _t := 0.0


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFETIME
	draw_line(from, to, Color(color, 0.8 * (1.0 - k)), width * (1.0 + k))
	draw_line(from, to, Color(1, 1, 1, 1.0 - k), width * 0.3)
