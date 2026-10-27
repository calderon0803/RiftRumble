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
var _toast: Label
var _toast_t := 0.0
var _hurt_t := 0.0
const HURT_FLASH := 0.35
var _boss_name := ""
var _boss_ratio := 1.0


func _ready() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.draw.connect(_draw_panel)
	add_child(_panel)
	var hint := Label.new()
	hint.text = "Esc: pausa y controles  ·  M: mapa"
	hint.position = Vector2(1060, 14)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	add_child(hint)
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 600)
	_toast.size = Vector2(1280, 40)
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.modulate.a = 0.0
	add_child(_toast)


## Mensaje breve en el centro de la parte de abajo.
func toast(text: String) -> void:
	_toast.text = text
	_toast_t = 2.0


## Destello rojo en los bordes al recibir daño.
func flash_damage() -> void:
	_hurt_t = HURT_FLASH
	_panel.queue_redraw()


func hurt_flash() -> float:
	return _hurt_t


func _process(dt: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= dt
		_toast.modulate.a = clampf(_toast_t / 0.5, 0.0, 1.0)
	if _hurt_t > 0.0:
		_hurt_t = maxf(_hurt_t - dt, 0.0)
		_panel.queue_redraw()


func show_boss(display_name: String) -> void:
	_boss_name = display_name
	_boss_ratio = 1.0
	_panel.queue_redraw()


func set_boss_ratio(ratio: float) -> void:
	_boss_ratio = ratio
	_panel.queue_redraw()


func hide_boss() -> void:
	_boss_name = ""
	if _panel:
		_panel.queue_redraw()


func set_health(value: int, maximum: int) -> void:
	hp = value
	max_hp = maximum
	_panel.queue_redraw()


func set_notches(value: int) -> void:
	notches = value
	_panel.queue_redraw()


func _draw_panel() -> void:
	if _hurt_t > 0.0:
		var a := 0.45 * _hurt_t / HURT_FLASH
		var col := Color(0.9, 0.1, 0.2, a)
		for i in 6:
			var w := 10.0 + i * 10.0
			var c := Color(col, a * (1.0 - i / 6.0))
			_panel.draw_rect(Rect2(0, 0, 1280, w), c)
			_panel.draw_rect(Rect2(0, 720 - w, 1280, w), c)
			_panel.draw_rect(Rect2(0, 0, w, 720), c)
			_panel.draw_rect(Rect2(1280 - w, 0, w, 720), c)
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
	if _boss_name != "":
		var bar := Rect2(340, 72, 600, 12)
		_panel.draw_string(ThemeDB.fallback_font, bar.position + Vector2(0, -8), _boss_name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.85))
		_panel.draw_rect(bar, Color(0, 0, 0, 0.6))
		_panel.draw_rect(Rect2(bar.position, Vector2(bar.size.x * _boss_ratio, bar.size.y)), Color("c0395f"))
		_panel.draw_rect(bar, Color(1, 1, 1, 0.4), false, 1.0)
