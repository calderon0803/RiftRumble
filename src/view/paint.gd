## Utilidades de dibujo compartidas por las vistas: fuentes, texto con contorno, elipses, llamas y brillos.
class_name Paint
extends RefCounted

const OUT := Color("0a0610")

static var _display: Font
static var _body: Font
static var _glow_tex: Texture2D


static func display_font() -> Font:
	if _display == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
		f.font_weight = 700
		_display = f
	return _display


static func body_font() -> Font:
	if _body == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
		_body = f
	return _body


## Textura radial blanca que se desvanece; se tiñe al dibujarla.
static func glow_tex() -> Texture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.4))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 128
		t.height = 128
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_glow_tex = t
	return _glow_tex


## Texto; align: 0 izquierda, 1 centro, 2 derecha. outline en píxeles (0 = sin contorno).
static func text(ci: CanvasItem, s: String, pos: Vector2, size: int, col: Color, align := 0, outline := 0, display := false) -> void:
	var f := display_font() if display else body_font()
	var width := 1600.0
	var p := pos
	var ha := HORIZONTAL_ALIGNMENT_LEFT
	if align == 1:
		p.x -= width / 2; ha = HORIZONTAL_ALIGNMENT_CENTER
	elif align == 2:
		p.x -= width; ha = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		width = -1
	if outline > 0:
		ci.draw_string_outline(f, p, s, ha, width, size, outline, Color(OUT, col.a))
	ci.draw_string(f, p, s, ha, width, size, col)


static func text_width(s: String, size: int, display := false) -> float:
	return (display_font() if display else body_font()).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func wrap(s: String, size: int, max_w: float) -> Array:
	var lines: Array = []
	var line := ""
	for word in s.split(" "):
		var t := word if line == "" else line + " " + word
		if text_width(t, size) > max_w and line != "":
			lines.append(line)
			line = word
		else:
			line = t
	if line != "":
		lines.append(line)
	return lines


static func ellipse(c: Vector2, rx: float, ry: float, rot := 0.0, n := 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


static func fill_ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot := 0.0, outline := 0.0) -> void:
	var pts := ellipse(c, rx, ry, rot)
	ci.draw_colored_polygon(pts, col)
	if outline > 0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, OUT, outline, true)


static func outline_poly(ci: CanvasItem, pts: PackedVector2Array, col: Color, width := 3.0) -> void:
	ci.draw_colored_polygon(pts, col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, OUT, width, true)


static func bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, n := 8) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(1, n + 1):
		var t := float(i) / n
		var u := 1.0 - t
		pts.append(p0 * u * u * u + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t * t * t)
	return pts


## Llama en forma de gota con la base en (x, y), altura s y núcleo claro.
static func flame(ci: CanvasItem, base: Vector2, s: float, c1: Color, c2: Color, time: float) -> void:
	var f := 1.0 + sin(time * 13.0 + base.x * 0.1) * 0.12
	for layer in [[c1, 1.0], [c2, 0.55]]:
		var h: float = s * layer[1] * f
		var w: float = s * layer[1] * 0.5
		var top := base + Vector2(0, -h)
		var pts := PackedVector2Array([top])
		pts.append_array(bezier(top, base + Vector2(w, -h * 0.45), base + Vector2(w * 0.9, 0), base))
		var back := bezier(base, base + Vector2(-w * 0.9, 0), base + Vector2(-w, -h * 0.45), top)
		back.remove_at(back.size() - 1)
		pts.append_array(back)
		ci.draw_colored_polygon(pts, layer[0])
