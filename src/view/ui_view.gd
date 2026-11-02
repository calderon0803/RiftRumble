## Marcador y pantallas: título, diálogos, grietas, anillo, Continue, final y pausa.
class_name UIView
extends Node2D

const OUT := Paint.OUT
const W := Game.VW
const H := Game.VH
const MAGENTA := Color("ff6fd8")
const SPARK := Color("ffe14d")
const CYAN := Color("6ff3ff")
const TEXT := Color("efe8f4")
const MUTED := Color("a89cb4")

var game: Game
var glows: Array = []


func glow(p: Vector2, r: float, col: Color, a: float) -> void:
	glows.append([p, r, Color(col, a)])


func _draw() -> void:
	glows.clear()
	if game == null:
		return
	var g := game
	if g.state != "title":
		_hud()
	if g.flash_a > 0:
		var a := g.flash_a * (1.0 if g.flash_col == Color.BLACK else 0.6)
		draw_rect(Rect2(0, 0, W, H), Color(g.flash_col, a))
	match g.state:
		"title": _title()
		"dialog": _dialog()
		"choice": _choice()
		"shop": _shop()
		"dead": _dead()
		"end": _end()
		"pause": _pause()
		"trans":
			var t: float = g.trans["t"]
			var a := t / 0.18 if t < 0.18 else 1.0 - (t - 0.18) / 0.18
			draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, clampf(a, 0, 1)))


func _panel(r: Rect2, col: Color) -> void:
	draw_rect(r, Color(0.04, 0.03, 0.08, 0.93))
	draw_rect(r, col, false, 2)
	draw_rect(r.grow(-6), Color(col, 0.35), false, 1)


func _heart(c: Vector2, size: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		var x := 16 * pow(sin(t), 3)
		var y := -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y) * size / 16.0)
	Paint.outline_poly(self, pts, col, 3)


# --- marcador ---
func _hud() -> void:
	var g := game
	var P := g.P
	var o := Vector2(24, 24)
	var mh := g.max_hp()
	for i in mh:
		var c := o + Vector2(12 + i * 26, 12)
		var on := i < P.hp
		_heart(c, 11, MAGENTA if on else Color("3a3044"))
		if on:
			glow(c, 16, MAGENTA, 0.35)
	# Filo: las 6 muescas de la espada.
	var fy := o.y + 40
	Paint.text(self, "FILO", Vector2(o.x, fy + 11), 12, MUTED, 0, 3, true)
	for i in Game.FILO_MAX:
		var r := Rect2(o.x + 42 + i * 18, fy, 13, 13)
		var lit := i < P.filo
		draw_rect(r.grow(2), OUT)
		draw_rect(r, SPARK if lit else Color("3a3044"))
		if lit:
			glow(r.get_center(), 12, SPARK, 0.5)
	# Fragmentos.
	var fc := Vector2(o.x + 8, fy + 34)
	var sc := 1.0 + g.frag_pulse
	var gem := PackedVector2Array([fc + Vector2(0, -7) * sc, fc + Vector2(6, 0) * sc, fc + Vector2(0, 7) * sc, fc + Vector2(-6, 0) * sc])
	Paint.outline_poly(self, gem, Color("e8fbff"), 2.5)
	glow(fc, 16, CYAN, 0.4)
	Paint.text(self, str(g.meta["frags"]), fc + Vector2(14, 6), 18, TEXT, 0, 4)
	if int(g.run["revive"]) > 0:
		Paint.text(self, "Continue extra listo", fc + Vector2(14 + Paint.text_width(str(g.meta["frags"]), 18) + 14, 6), 14, Color("f2c14e"), 0, 3)
	# Poderes de las grietas.
	var boons: Array = g.run["boons"]
	if not boons.is_empty():
		var x := 26.0
		var names := PackedStringArray()
		for id in boons:
			var b: Dictionary = Data.BOONS.filter(func(q): return q["id"] == id)[0]
			var col: Color = Data.HEROES[b["hero"]]["color"]
			var c := Vector2(x, H - 26)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -13), c + Vector2(13, 0), c + Vector2(0, 13), c + Vector2(-13, 0)]), OUT)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -9), c + Vector2(9, 0), c + Vector2(0, 9), c + Vector2(-9, 0)]), col)
			Paint.text(self, b["name"].substr(0, 1), c + Vector2(0, 5), 13, OUT, 1, 0, true)
			names.append(b["name"])
			x += 32
		Paint.text(self, " · ".join(names), Vector2(x + 4, H - 20), 14, MUTED, 0, 3)
	# Jefe.
	if g.boss != null and g.boss.state != "sleep":
		var bw := 520.0
		var bx := W / 2 - bw / 2
		var by := H - 40
		Paint.text(self, "El Rey del Reinicio", Vector2(W / 2, by - 10), 22, TEXT, 1, 5, true)
		draw_rect(Rect2(bx - 3, by - 3, bw + 6, 16), OUT)
		draw_rect(Rect2(bx, by, bw, 10), Color("3a1018"))
		draw_rect(Rect2(bx, by, bw * maxf(0, g.boss.hp) / g.boss.max_hp, 10), Color("e8384f"))
		draw_rect(Rect2(bx + bw / 2 - 1, by - 3, 2, 16), OUT)
	# Rótulo de sala o de poder.
	if not g.banner.is_empty():
		var t: float = g.banner["t"]
		var a := t / 0.4 if t < 0.4 else (maxf(0.0, (3.2 - t) / 0.6) if t > 2.6 else 1.0)
		var rim: Color = Data.PALETTES[g.room.pal]["rim"]
		Paint.text(self, g.banner["text"], Vector2(W / 2, 110), 38, Color(TEXT, a), 1, 8, true)
		var tw := Paint.text_width(g.banner["text"], 38, true)
		draw_line(Vector2(W / 2 - tw / 2 - 70, 98), Vector2(W / 2 - tw / 2 - 16, 98), Color(rim, a), 1.5)
		draw_line(Vector2(W / 2 + tw / 2 + 16, 98), Vector2(W / 2 + tw / 2 + 70, 98), Color(rim, a), 1.5)
		Paint.text(self, g.banner["sub"], Vector2(W / 2, 138), 18, Color(rim, a), 1, 4)


# --- pantallas ---
func _title() -> void:
	var g := game
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.01, 0.04, 0.62))
	glow(Vector2(W / 2, 160), 320, MAGENTA, 0.25)
	Paint.text(self, "RIFT RUMBLE", Vector2(W / 2, 170), 72, TEXT, 1, 10, true)
	Paint.text(self, "Defiende tu mundo. Rompe las reglas.", Vector2(W / 2, 208), 22, MAGENTA, 1, 4)
	var rows := [["← →", "moverse"], ["Espacio / Z", "saltar (dos veces con el orbe)"], ["X", "tajo · ↑ / ↓ + X para apuntar"],
		["Shift / C", "dash: intocable mientras dura"], ["Q", "descarga de filo (2 muescas)"], ["R mantenido", "concentrarse: +1 corazón (2 muescas)"],
		["E / ↑", "hablar, leer, asomarse a una grieta"]]
	for i in rows.size():
		Paint.text(self, rows[i][0], Vector2(W / 2 - 20, 264 + i * 28), 19, SPARK, 2, 3, true)
		Paint.text(self, rows[i][1], Vector2(W / 2, 264 + i * 28), 18, Color("d8cfe0"), 0, 3)
	var a := 0.6 + 0.4 * sin(g.time * 3)
	Paint.text(self, "Pulsa Enter para entrar en el Reino del Continue", Vector2(W / 2, 486), 22, Color(TEXT, a), 1, 4, true)
	if int(g.meta["deaths"]) > 0 or int(g.meta["frags"]) > 0:
		var info := "Continues: %d  ·  Fragmentos: %d" % [g.meta["deaths"], g.meta["frags"]]
		if g.meta["boss"]:
			info += "  ·  Bucle roto"
		Paint.text(self, info, Vector2(W / 2, 518), 15, MUTED, 1, 3)


func _dialog() -> void:
	var g := game
	var d := g.dialog
	var r := Rect2(110, H - 170, W - 220, 130)
	var col: Color = d["col"]
	_panel(r, col)
	if d["speaker"] != "":
		Paint.text(self, d["speaker"], r.position + Vector2(24, -10), 24, col, 0, 6, true)
	var full: String = d["lines"][d["i"]]
	var shown := full.substr(0, int(d["t"] * 55))
	var lines := Paint.wrap(shown, 20, r.size.x - 48)
	for i in lines.size():
		Paint.text(self, lines[i], r.position + Vector2(24, 38 + i * 27), 20, TEXT)
	if d["t"] * 55 >= full.length():
		Paint.text(self, "▸", r.end + Vector2(-26, -18 + sin(g.time * 5) * 2), 18, col, 1)


func _card_rect(i: int, n: int) -> Rect2:
	var cw := 270.0
	var gap := 24.0
	var tot := n * cw + (n - 1) * gap
	return Rect2(W / 2 - tot / 2 + i * (cw + gap), 178, cw, 230)


func _choice() -> void:
	var g := game
	var c := g.choice
	var hero: Dictionary = Data.HEROES[c["hero"]]
	var col: Color = hero["color"]
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.01, 0.04, 0.75))
	glow(Vector2(W / 2, 90), 320, col, 0.25)
	Paint.text(self, "%s, %s" % [hero["name"], hero["title"]], Vector2(W / 2, 82), 34, col, 1, 6, true)
	Paint.text(self, "«%s»" % hero["quote"], Vector2(W / 2, 120), 20, TEXT, 1, 4)
	var opts: Array = c["opts"]
	for i in opts.size():
		var b: Dictionary = opts[i]
		var sel: bool = i == c["sel"]
		var r := _card_rect(i, opts.size())
		if sel:
			r.position.y -= 8
			glow(r.get_center(), 180, col, 0.25)
		_panel(r, col if sel else Color("4a3a58"))
		var dc := r.position + Vector2(r.size.x / 2, 44)
		draw_colored_polygon(PackedVector2Array([dc + Vector2(0, -18), dc + Vector2(18, 0), dc + Vector2(0, 18), dc + Vector2(-18, 0)]), OUT)
		draw_colored_polygon(PackedVector2Array([dc + Vector2(0, -13), dc + Vector2(13, 0), dc + Vector2(0, 13), dc + Vector2(-13, 0)]), col)
		Paint.text(self, str(i + 1), dc + Vector2(0, 6), 16, OUT, 1, 0, true)
		Paint.text(self, b["name"], r.position + Vector2(r.size.x / 2, 100), 23, col if sel else TEXT, 1, 4, true)
		var lines := Paint.wrap(b["desc"], 17, r.size.x - 40)
		for j in lines.size():
			Paint.text(self, lines[j], r.position + Vector2(r.size.x / 2, 134 + j * 23), 17, Color("d8cfe0"), 1)
	Paint.text(self, "← → elegir  ·  E / Enter aceptar  ·  o pulsa 1, 2, 3", Vector2(W / 2, 460), 16, MUTED, 1, 3)


func _shop() -> void:
	var g := game
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.01, 0.04, 0.78))
	Paint.text(self, "El Anillo de Nexo", Vector2(W / 2, 80), 38, CYAN, 1, 6, true)
	Paint.text(self, "Entrega los fragmentos que traes. Lo que el anillo te da no se pierde con el Continue.", Vector2(W / 2, 112), 17, Color("d8cfe0"), 1, 3)
	Paint.text(self, "Fragmentos: %d" % g.meta["frags"], Vector2(W / 2, 146), 20, TEXT, 1, 3)
	for i in Data.UPGRADES.size():
		var u: Dictionary = Data.UPGRADES[i]
		var y := 172.0 + i * 72
		var sel: bool = i == g.shop["sel"]
		var lvl := int(g.meta["up"][u["id"]])
		var maxed := lvl >= int(u["max"])
		var r := Rect2(200, y, 560, 62)
		_panel(r, CYAN if sel else Color("4a3a58"))
		Paint.text(self, u["name"], Vector2(224, y + 27), 21, CYAN if sel else TEXT, 0, 4, true)
		Paint.text(self, u["desc"], Vector2(224, y + 50), 15, MUTED)
		for k in int(u["max"]):
			draw_circle(Vector2(560 + k * 16, y + 22), 5, CYAN if k < lvl else Color("3a3044"))
		var cost := g.upgrade_cost(u)
		var label := "Máximo" if maxed else "%d fragmentos" % cost
		var lc := Color("7be36b") if maxed else (TEXT if int(g.meta["frags"]) >= cost else Color("e8384f"))
		Paint.text(self, label, Vector2(736, y + 50), 16, lc, 2)
	if g.shop["msg_t"] > 0:
		Paint.text(self, g.shop["msg"], Vector2(W / 2, 480), 18, SPARK, 1, 3)
	Paint.text(self, "↑ ↓ elegir  ·  E / Enter entregar  ·  Esc salir", Vector2(W / 2, 515), 16, MUTED, 1, 3)


func _dead() -> void:
	var g := game
	var a := minf(1.0, g.dead_t / 0.8)
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.01, 0.04, 0.78 * a))
	Paint.text(self, "CONTINUE?", Vector2(W / 2, 220), 64, Color(Color("e8384f"), a), 1, 8, true)
	var count := maxi(0, 9 - int(g.dead_t * 4))
	Paint.text(self, str(count), Vector2(W / 2, 290), 48, Color(SPARK, a), 1, 6, true)
	Paint.text(self, "El Reino te devuelve al Umbral. Es su regla.", Vector2(W / 2, 330), 20, Color(MAGENTA, a), 1, 4)
	Paint.text(self, "Fragmentos de este intento: %d  ·  Los poderes de las grietas se pierden" % g.run["frags"], Vector2(W / 2, 362), 17, Color(MUTED, a), 1, 3)
	if g.dead_t > 1.6:
		Paint.text(self, "Pulsa Enter para continuar", Vector2(W / 2, 420), 20, Color(TEXT, a), 1, 4, true)


func _end() -> void:
	var g := game
	var a := minf(1.0, g.end_t / 1.2)
	draw_rect(Rect2(0, 0, W, H), Color(0.06, 0.03, 0.02, 0.82 * a))
	glow(Vector2(W / 2, 200), 320, Color("f2c14e"), 0.35 * a)
	Paint.text(self, "GAME CLEAR", Vector2(W / 2, 200), 64, Color(Color("f2c14e"), a), 1, 8, true)
	Paint.text(self, "Bucle roto", Vector2(W / 2, 256), 40, Color(TEXT, a), 1, 6, true)
	Paint.text(self, "El Rey del Reinicio deja de pulsar CONTINUE. El Reino sigue adelante, por fin.", Vector2(W / 2, 296), 19, Color(MAGENTA, a), 1, 4)
	Paint.text(self, "+60 fragmentos  ·  Fin del prototipo. Gracias por jugar.", Vector2(W / 2, 334), 17, Color(Color("d8cfe0"), a), 1, 3)
	if g.end_t > 2:
		Paint.text(self, "Pulsa Enter para volver al Umbral", Vector2(W / 2, 394), 20, Color(TEXT, a), 1, 4, true)


func _pause() -> void:
	var g := game
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.01, 0.04, 0.7))
	Paint.text(self, "Pausa", Vector2(W / 2, 200), 48, TEXT, 1, 6, true)
	Paint.text(self, "Esc o Enter para seguir  ·  F10 para salir", Vector2(W / 2, 250), 20, Color("d8cfe0"), 1, 3)
	var warn: bool = g.erase_arm > 0
	Paint.text(self, "Pulsa B otra vez para borrar todo el progreso" if warn else "B dos veces: borrar el progreso guardado", Vector2(W / 2, 320), 17, Color("ff6a7a") if warn else MUTED, 1, 3)
