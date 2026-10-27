## Marcador: corazones arriba a la izquierda, las 6 muescas del filo debajo y
## los controles abajo.
class_name Hud
extends CanvasLayer

const HEART := Color("ff4fa0")
const EMPTY := Color(1, 1, 1, 0.15)
const NOTCH := Color("f5e27a")

var hp := 5
var max_hp := 5
var notches := 0
var _panel: Control


func _ready() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.draw.connect(_draw_panel)
	add_child(_panel)
	var label := Label.new()
	label.text = "Moverse: ← → / A D  ·  Saltar: Espacio / Z  ·  Tajo: X / J (con ↑ arriba, con ↓ en el aire abajo)  ·  Tajo de filo: C / L (3 muescas)  ·  R: reiniciar"
	label.position = Vector2(190, 20)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	add_child(label)


func set_health(value: int, maximum: int) -> void:
	hp = value
	max_hp = maximum
	_panel.queue_redraw()


func set_notches(value: int) -> void:
	notches = value
	_panel.queue_redraw()


func _draw_panel() -> void:
	for i in max_hp:
		var p := Vector2(20 + i * 30, 18)
		_panel.draw_rect(Rect2(p, Vector2(22, 20)), HEART if i < hp else EMPTY)
	for i in KiraCombat.NOTCHES_MAX:
		var p := Vector2(20 + i * 18, 48)
		var ready := notches >= KiraCombat.SPECIAL_COST
		var col := NOTCH if i < notches else EMPTY
		if i < notches and ready:
			col = col.lightened(0.3)
		_panel.draw_rect(Rect2(p, Vector2(12, 12)), col)
