## Tema provisional de la interfaz (paneles oscuros con borde cian).
## Se sustituirá por el tema definitivo de la dirección artística; todos los
## controles lo heredan, así que cambiarlo aquí cambia toda la UI.
extends RefCounted

const INK := Color("1e1830")
const ACCENT := Color("6ff3ff")
const GOLD := Color("ffe066")


static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 16

	var panel := _box(Color(INK, 0.92), ACCENT.darkened(0.3), 2, 8)
	panel.content_margin_left = 12
	panel.content_margin_right = 12
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	t.set_stylebox("panel", "PanelContainer", panel)

	t.set_stylebox("normal", "Button", _box(Color("2c2550"), Color("4a4380"), 2, 6))
	t.set_stylebox("hover", "Button", _box(Color("3a3270"), ACCENT, 2, 6))
	t.set_stylebox("pressed", "Button", _box(Color("17122b"), ACCENT, 2, 6))
	t.set_stylebox("disabled", "Button", _box(Color("221d38", 0.7), Color("332d55"), 2, 6))
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.35))

	t.set_type_variation(&"AccentButton", &"Button")
	t.set_stylebox("normal", "AccentButton", _box(Color("1f6f78"), ACCENT, 2, 6))
	t.set_stylebox("hover", "AccentButton", _box(Color("2a8a95"), Color.WHITE, 2, 6))

	t.set_type_variation(&"StatLabel", &"Label")
	t.set_font_size("font_size", "StatLabel", 20)
	t.set_color("font_color", "StatLabel", GOLD)

	t.set_type_variation(&"HeaderLabel", &"Label")
	t.set_font_size("font_size", "HeaderLabel", 20)
	t.set_color("font_color", "HeaderLabel", ACCENT)

	t.set_type_variation(&"TitleLabel", &"Label")
	t.set_font_size("font_size", "TitleLabel", 36)
	t.set_color("font_color", "TitleLabel", GOLD)

	t.set_type_variation(&"DebugLabel", &"Label")
	t.set_font_size("font_size", "DebugLabel", 12)
	t.set_color("font_color", "DebugLabel", Color(1, 1, 1, 0.6))
	return t


static func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s
