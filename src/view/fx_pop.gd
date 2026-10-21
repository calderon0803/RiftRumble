## Efecto breve: anillo que se expande y texto flotante (+oro, −vida).
## Se autodestruye; no depende de la simulación.
extends Node2D

const LIFETIME := 0.6

var color := Color.WHITE
var text := ""
var _t := 0.0


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFETIME
	draw_set_transform(Vector2(0, -10), 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, 6.0 + 18.0 * k, 0.0, TAU, 20, Color(color, 1.0 - k), 2.0)
	draw_set_transform(Vector2.ZERO)
	if not text.is_empty():
		var font := ThemeDB.fallback_font
		var pos := Vector2(-10, -30 - 20 * k)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0, 0, 0, 1.0 - k))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(color, 1.0 - k))
