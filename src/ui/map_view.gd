## Mapa (M / Tab): las salas visitadas en su sitio, la sala actual resaltada,
## dónde está Kira y el último banco. Mientras está abierto, el juego se pausa.
class_name MapView
extends CanvasLayer

const AREA := Rect2(90, 80, 1100, 560)
const COLOR_ROOM := Color("2b3550")
const COLOR_EDGE := Color("6b7896")
const COLOR_CURRENT := Color("ffffff")
const COLOR_KIRA := Color("ff4fa0")
const COLOR_BENCH := Color("f5e27a")

var world: World
var _canvas: Control


func _ready() -> void:
	layer = 5
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_map)
	add_child(_canvas)


func queue_redraw() -> void:
	if _canvas:
		_canvas.queue_redraw()


func _draw_map() -> void:
	_canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0, 0, 0, 0.82))
	var font := ThemeDB.fallback_font
	_canvas.draw_string(font, Vector2(AREA.position.x, 50), "MAPA  ·  M / Tab para cerrar", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
	if world == null or world.layouts.is_empty():
		return
	# Escala fija con todas las salas (también las no visitadas) para que el mapa no baile.
	var bounds: Rect2 = world.layouts.values()[0].rect
	for l in world.layouts.values():
		bounds = bounds.merge(l.rect)
	var k := minf(AREA.size.x / bounds.size.x, AREA.size.y / bounds.size.y)
	var off := AREA.position + (AREA.size - bounds.size * k) / 2.0
	var to_map := func(p: Vector2) -> Vector2: return off + (p - bounds.position) * k
	for id in world.visited:
		var l: RoomLayout = world.layouts[id]
		var r := Rect2(to_map.call(l.rect.position), l.rect.size * k)
		_canvas.draw_rect(r, COLOR_ROOM)
		var is_current: bool = world.current != null and id == world.current.id
		_canvas.draw_rect(r, COLOR_CURRENT if is_current else COLOR_EDGE, false, 3.0 if is_current else 1.5)
		_canvas.draw_string(font, r.position + Vector2(6, 18), l.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.6))
		if l.bench != Vector2.INF:
			var b: Vector2 = to_map.call(l.bench)
			_canvas.draw_rect(Rect2(b - Vector2(6, 6), Vector2(12, 6)), COLOR_BENCH)
	if world.kira:
		var kp: Vector2 = to_map.call(world.kira.position + Vector2(0, -Kira.SIZE.y / 2))
		_canvas.draw_circle(kp, 6.0, COLOR_KIRA)
