## Dibuja la sala: fondo con paralaje, casillas, objetos, enemigos, Kira y efectos.
## Los brillos se apuntan en `glows` y los pinta GlowView con mezcla aditiva.
class_name WorldView
extends Node2D

const T := 32
const OUT := Paint.OUT
const SKIN := Color("f2d2c0")
const MAGENTA := Color("ff6fd8")
const GRAPHITE := Color("2c2433")
const SPARK := Color("ffe14d")
const HAIR := Color("b8338f")

var game: Game
var glows: Array = []
var _bg_cache := {}
var _cam := Vector2.ZERO
var _rim := Color.WHITE
var _pal: Dictionary


func glow(p: Vector2, r: float, col: Color, a: float) -> void:
	glows.append([p, r, Color(col, a)])


func _draw() -> void:
	glows.clear()
	if game == null:
		return
	var g := game
	_pal = Data.PALETTES[g.room.pal]
	_rim = _pal["rim"]
	var shake := Vector2.ZERO
	if g.shake > 0 and not g.reduced_motion:
		shake = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * g.shake * 0.6
	_cam = (g.cam - shake).round()
	_draw_bg()
	_draw_tiles()
	_draw_props()
	for e in g.enemies:
		_draw_enemy(e)
	_draw_pickups()
	if g.state != "dead":
		_draw_kira()
	_draw_slashes()
	_draw_projs()
	_draw_parts()
	_draw_nums()
	_draw_vignette()


func s(p: Vector2) -> Vector2:
	return p - _cam


# --- fondo ---
func _bg_for(r: Data.RoomDef) -> Dictionary:
	if _bg_cache.has(r.id):
		return _bg_cache[r.id]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(r.id)
	var layers := []
	for spec in [[0.3, _pal["far"]], [0.6, _pal["near"]]]:
		var p: float = spec[0]
		var span := (r.w * T - Game.VW) * p + Game.VW + 300
		var items := []
		var x := -120.0
		while x < span:
			var k := rng.randf()
			var kind := "tower" if k < 0.4 else ("arch" if k < 0.75 else "cube")
			var w := 150 + rng.randf() * 130 if kind == "arch" else (40 + rng.randf() * 50 if kind == "tower" else 18 + rng.randf() * 26)
			items.append({"kind": kind, "x": x, "w": w, "h": (160.0 if p < 0.5 else 110.0) + rng.randf() * 240, "s": rng.randf()})
			x += w + 50 + rng.randf() * 160
		layers.append({"p": p, "col": spec[1], "items": items})
	var rays := []
	for i in 3:
		rays.append({"x": rng.randf() * Game.VW, "w": 60 + rng.randf() * 110, "s": rng.randf() * 6})
	_bg_cache[r.id] = {"layers": layers, "rays": rays}
	return _bg_cache[r.id]


func _draw_bg() -> void:
	var g := game
	var bg := _bg_for(g.room)
	var top: Color = _pal["top"]
	var bot: Color = _pal["bot"]
	var bands := 24
	for i in bands:
		var y0 := Game.VH * i / bands
		draw_rect(Rect2(0, y0, Game.VW, Game.VH / bands + 1), top.lerp(bot, float(i) / bands))
	glow(Vector2(Game.VW * 0.5, Game.VH * 0.12), Game.VW * 0.65, _rim, 0.14)
	for ray in bg["rays"]:
		var sx := fposmod(ray["x"] + sin(g.time * 0.3 + ray["s"]) * 30 - g.cam.x * 0.1, Game.VW + 300) - 200
		var pts := PackedVector2Array([Vector2(sx, 0), Vector2(sx + ray["w"], 0), Vector2(sx + ray["w"] * 2 + 140, Game.VH), Vector2(sx + ray["w"] * 0.7 + 140, Game.VH)])
		var cols := PackedColorArray([Color(_rim, 0.07), Color(_rim, 0.07), Color(_rim, 0.0), Color(_rim, 0.0)])
		draw_polygon(pts, cols)
	var max_cy := maxf(0.0, g.room.h * T - Game.VH)
	for L in bg["layers"]:
		var ox: float = -g.cam.x * L["p"]
		var base: float = Game.VH + (max_cy - g.cam.y) * L["p"] * 0.5 + 20
		var col: Color = L["col"]
		for it in L["items"]:
			var x: float = it["x"] + ox
			if x > Game.VW + 300 or x + it["w"] < -300:
				continue
			var w: float = it["w"]
			var h: float = it["h"]
			match it["kind"]:
				"tower":
					draw_rect(Rect2(x, base - h, w, h), col)
					for m in range(0, int(w), 14):
						draw_rect(Rect2(x + m, base - h - 10, 8, 10), col)
					draw_rect(Rect2(x, base - h, 3, h), Color(_rim, 0.08))
					var wy := base - h + 30
					if fmod(it["s"] * 10.0, 2.0) < 1.0:
						glow(Vector2(x + w / 2, wy), 18, _rim, 0.18 + 0.08 * sin(g.time * 2 + it["s"] * 9))
						draw_rect(Rect2(x + w / 2 - 4, wy - 6, 8, 12), Color(_rim, 0.35))
				"arch":
					var pw := w * 0.14
					draw_rect(Rect2(x, base - h, pw, h), col)
					draw_rect(Rect2(x + w - pw, base - h, pw, h), col)
					draw_arc(Vector2(x + w / 2, base - h), w / 2 - pw / 2, PI, TAU, 24, col, pw * 0.9)
				"cube":
					var cy := base - h - 60 + sin(g.time * 0.8 + it["s"] * 20) * 8
					draw_rect(Rect2(x, cy, w, w), col)
					draw_rect(Rect2(x, cy, w, w), Color(_rim, 0.25), false, 1.5)
					if int(g.time * 2 + it["s"] * 7) % 7 == 0:
						draw_rect(Rect2(x + 3, cy + 3, w - 6, 3), Color(_rim, 0.4))
	var fog_pts := PackedVector2Array([Vector2(0, Game.VH * 0.55), Vector2(Game.VW, Game.VH * 0.55), Vector2(Game.VW, Game.VH), Vector2(0, Game.VH)])
	draw_polygon(fog_pts, PackedColorArray([Color(_rim, 0), Color(_rim, 0), Color(_rim, 0.08), Color(_rim, 0.08)]))
	for i in 50:
		var ex := fposmod(i * 197.0 + sin(g.time * 0.5 + i) * 20 - g.cam.x * 0.15, Game.VW)
		var ey := fposmod(i * 113.0 - g.time * (10 + i % 20), Game.VH)
		draw_rect(Rect2(ex, ey, 2, 2), Color(_rim, 0.25 + 0.25 * sin(g.time * 3 + i)))


# --- casillas ---
func _solid(x: int, y: int) -> bool:
	var r := game.room
	if x < 0 or y < 0 or x >= r.w or y >= r.h:
		return true
	return r.g[y][x] == "#"


func _draw_tiles() -> void:
	var r := game.room
	var stone: Color = _pal["stone"]
	var deep: Color = _pal["deep"]
	var x0 := maxi(0, floori(_cam.x / T) - 1)
	var y0 := maxi(0, floori(_cam.y / T) - 1)
	var x1 := mini(r.w - 1, floori((_cam.x + Game.VW) / T) + 1)
	var y1 := mini(r.h - 1, floori((_cam.y + Game.VH) / T) + 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var ch: String = r.g[y][x]
			var p := Vector2(x * T, y * T) - _cam
			if ch == "#":
				var inner := _solid(x - 1, y) and _solid(x + 1, y) and _solid(x, y - 1) and _solid(x, y + 1)
				draw_rect(Rect2(p, Vector2(T, T)), deep if inner else stone)
				if not inner:
					# Ladrillo del Reino: juntas alternas.
					var off := 0.0 if y % 2 == 0 else T / 2.0
					draw_rect(Rect2(p.x, p.y + T / 2.0 - 1, T, 2), deep)
					draw_rect(Rect2(p.x + fposmod(off + 8, T), p.y + 2, 2, T / 2.0 - 3), deep)
					draw_rect(Rect2(p.x + fposmod(off + 24, T), p.y + T / 2.0 + 1, 2, T / 2.0 - 3), deep)
				if not _solid(x, y - 1):
					draw_rect(Rect2(p, Vector2(T, 4)), OUT)
					draw_rect(Rect2(p.x, p.y + 4, T, 2), _rim)
					draw_rect(Rect2(p.x, p.y + 6, T, 5), Color(_rim, 0.18))
					glow(p + Vector2(T / 2.0, 5), 22, _rim, 0.10)
				if not _solid(x, y + 1):
					draw_rect(Rect2(p.x, p.y + T - 4, T, 4), OUT)
				if not _solid(x - 1, y):
					draw_rect(Rect2(p, Vector2(4, T)), OUT)
					draw_rect(Rect2(p.x + 4, p.y, 2, T), Color(_rim, 0.25))
				if not _solid(x + 1, y):
					draw_rect(Rect2(p.x + T - 4, p.y, 4, T), OUT)
			elif ch == "=":
				draw_rect(Rect2(p, Vector2(T, 10)), stone)
				draw_rect(Rect2(p, Vector2(T, 3)), OUT)
				draw_rect(Rect2(p.x, p.y + 10, T, 3), OUT)
				draw_rect(Rect2(p.x, p.y + 3, T, 2), _rim)
				if (x + y) % 3 == 0:
					draw_rect(Rect2(p.x + 13, p.y + 13, 5, 8), OUT)
			elif ch == "^":
				for i in 3:
					var sx := p.x + 2 + i * 10
					var tri := PackedVector2Array([Vector2(sx, p.y + T), Vector2(sx + 5, p.y + T * 0.42), Vector2(sx + 10, p.y + T)])
					Paint.outline_poly(self, tri, deep, 2)
					draw_colored_polygon(PackedVector2Array([Vector2(sx + 3.5, p.y + T * 0.62), Vector2(sx + 5, p.y + T * 0.42), Vector2(sx + 6.5, p.y + T * 0.62)]), _rim)


# --- objetos de las salas ---
func _draw_props() -> void:
	var g := game
	for o in g.props:
		var p := s(Vector2(o["x"], o["y"]))
		match o["type"]:
			"O":
				_draw_nexo(p)
				if g.new_talk():
					Paint.text(self, "!", p + Vector2(0, -78 + sin(g.time * 4) * 3), 28, SPARK, 1, 6, true)
			"M":
				# El anillo de Nexo: recibe fragmentos.
				Paint.outline_poly(self, PackedVector2Array([p + Vector2(-22, 0), p + Vector2(-14, -16), p + Vector2(14, -16), p + Vector2(22, 0)]), _pal["stone"])
				var c := p + Vector2(0, -44)
				draw_arc(c, 24, 0, TAU, 40, OUT, 9)
				draw_arc(c, 24, 0, TAU, 40, Color("6ff3ff"), 4)
				var a := g.time * 1.5
				for i in 4:
					var q := c + Vector2(cos(a + i * PI / 2), sin(a + i * PI / 2)) * 24
					draw_circle(q, 3, Color("e8fbff"))
				glow(c, 70, Color("6ff3ff"), 0.4)
			"H":
				# Marcador del Reino: la cuenta atrás del CONTINUE.
				var rr := Rect2(p + Vector2(-46, -92), Vector2(92, 56))
				draw_rect(Rect2(p + Vector2(-5, -36), Vector2(10, 36)), _pal["stone"])
				draw_rect(rr, Color("0b0e1a"))
				draw_rect(rr, OUT, false, 4)
				draw_rect(rr.grow(-4), Color(_rim, 0.5), false, 1.5)
				if g.meta["boss"]:
					Paint.text(self, "GAME", p + Vector2(0, -70), 18, Color("f2c14e"), 1, 0, true)
					Paint.text(self, "CLEAR", p + Vector2(0, -48), 18, Color("f2c14e"), 1, 0, true)
					glow(p + Vector2(0, -64), 90, Color("f2c14e"), 0.45)
				else:
					Paint.text(self, "CONTINUE?", p + Vector2(0, -72), 13, Color("e8384f"), 1, 0, true)
					Paint.text(self, str(9 - int(g.time) % 10), p + Vector2(0, -46), 22, Color("ffe14d"), 1, 0, true)
					glow(p + Vector2(0, -64), 60, Color("e8384f"), 0.3)
			"F":
				_draw_rift(p, o)
			"L":
				# Registro de Zerik: terminal pequeña.
				Paint.outline_poly(self, PackedVector2Array([p + Vector2(-16, 0), p + Vector2(-16, -40), p + Vector2(16, -40), p + Vector2(16, 0)]), Color("2a2a36"))
				draw_rect(Rect2(p + Vector2(-11, -35), Vector2(22, 16)), Color("10140c"))
				var blink := 0.55 + 0.25 * sin(g.time * 3)
				for i in 3:
					draw_rect(Rect2(p + Vector2(-8, -32 + i * 4), Vector2(16 - (i % 2) * 6, 2)), Color(Color("f2c14e"), blink))
				glow(p + Vector2(0, -27), 26, Color("f2c14e"), 0.25)
			"A":
				var c := p + Vector2(0, -30 + sin(g.time * 2) * 5)
				glow(c, 60, SPARK, 0.5)
				Paint.fill_ellipse(self, c, 13, 13, Color("fff5c0"), 0, 3)
				Paint.fill_ellipse(self, c, 6, 6, SPARK)
				if randf() < 0.2:
					g.part(o["x"] + randf_range(-20, 20), o["y"] - 30 + randf_range(-10, 10), randf_range(-10, 10), randf_range(-40, -10), 0.8, SPARK, 2, 0.0, true)
	if g.state == "play":
		var np = g.near_prop()
		if np != null:
			var pr := g.prompt_for(np)
			if pr != "":
				var txt := "E · " + pr
				var w := Paint.text_width(txt, 16) + 24
				var off: int = {"O": 100, "H": 112, "M": 86}.get(np["type"], 80)
				var p := s(Vector2(np["x"], np["y"] - off))
				var box := Rect2(p.x - w / 2, p.y - 19, w, 27)
				draw_rect(box, Color(0.04, 0.03, 0.08, 0.88))
				draw_rect(box, Color(_rim, 0.6), false, 1.5)
				Paint.text(self, txt, p, 16, Color("efe8f4"), 1)


func _draw_nexo(p: Vector2) -> void:
	var g := game
	# Capa asimétrica en espiral, cuerpo esbelto y el anillo-umbral orbitando a su espalda.
	var ring_c := p + Vector2(-6, -52)
	glow(ring_c, 60, Color("6ff3ff"), 0.35)
	draw_arc(ring_c, 26, 0, TAU, 40, OUT, 7)
	draw_arc(ring_c, 26, 0, TAU, 40, Color("6ff3ff"), 3)
	var cloak := PackedVector2Array([p + Vector2(-16, 0), p + Vector2(-10, -40), p + Vector2(-2, -50), p + Vector2(8, -48), p + Vector2(12, -30), p + Vector2(20, -6), p + Vector2(12, 0), p + Vector2(4, -6), p + Vector2(-4, 0)])
	Paint.outline_poly(self, cloak, Color("1d2b4f"))
	draw_polyline(PackedVector2Array([p + Vector2(-14, -4), p + Vector2(-9, -38), p + Vector2(-2, -48)]), Color("6ff3ff"), 1.8, true)
	Paint.fill_ellipse(self, p + Vector2(2, -58), 8, 9, Color("e8f4ff"), 0, 3)
	draw_rect(Rect2(p + Vector2(3, -60), Vector2(5, 2)), Color("1d2b4f"))
	var a := g.time * 2
	draw_circle(ring_c + Vector2(cos(a), sin(a)) * 26, 3, Color("ffffff"))


func _draw_rift(p: Vector2, o: Dictionary) -> void:
	var g := game
	var rf = g.run["rifts"].get(g.room.id)
	var live: bool = rf != null and not rf["taken"]
	var col: Color = Data.HEROES[rf["hero"]]["color"] if live else Color("4a4458")
	var c := p + Vector2(0, -40)
	var hgt := 38.0 + (sin(g.time * 3) * 3 if live else 0.0)
	# La grieta: un corte vertical dentado con luz del mundo del héroe.
	var pts := PackedVector2Array()
	var n := 9
	for i in n + 1:
		var t := float(i) / n
		pts.append(c + Vector2((7 if i % 2 == 0 else 2) + (sin(g.time * 5 + i) * 1.5 if live else 0.0), -hgt + t * hgt * 2))
	for i in range(n, -1, -1):
		var t := float(i) / n
		pts.append(c + Vector2(-(7 if i % 2 == 1 else 2), -hgt + t * hgt * 2))
	draw_colored_polygon(pts, OUT)
	var inner := PackedVector2Array()
	for q in pts:
		inner.append(c + (q - c) * Vector2(0.55, 0.92))
	draw_colored_polygon(inner, col if live else Color("2a2636"))
	if live:
		glow(c, 80, col, 0.55)
		if randf() < 0.3:
			g.part(o["x"] + randf_range(-6, 6), o["y"] - 40 + randf_range(-30, 30), randf_range(-30, 30), randf_range(-30, 30), 0.6, col, 2.5, 0.0, true)


# --- enemigos ---
func _draw_enemy(e: Game.Ent) -> void:
	var g := game
	var fl := e.flash > 0
	var cherry := Color("e8384f")
	match e.kind:
		"c":
			var p := s(Vector2(e.x + e.w / 2, e.y + e.h))
			draw_set_transform(p, 0, Vector2(e.face, 1))
			var st := sin(e.t * 10) * 3
			for lx in [-9, -3, 3, 9]:
				draw_line(Vector2(lx, -6), Vector2(lx + (st if lx % 2 != 0 else -st), 0), OUT, 3)
			var body := PackedVector2Array([Vector2(-14, -4)])
			body.append_array(Paint.bezier(Vector2(-14, -4), Vector2(-15, -20), Vector2(-8, -24), Vector2(1, -24)))
			body.append_array(Paint.bezier(Vector2(1, -24), Vector2(10, -24), Vector2(16, -18), Vector2(15, -5)))
			Paint.outline_poly(self, body, Color.WHITE if fl else Color("6a2232"))
			draw_polyline(PackedVector2Array([Vector2(-12, -8), Vector2(-12, -18), Vector2(-2, -22)]), _rim, 1.6, true)
			Paint.fill_ellipse(self, Vector2(9, -12), 6, 7, Color.WHITE if fl else Color("d9cfe0"), 0, 3)
			Paint.fill_ellipse(self, Vector2(10, -13), 2.2, 2.2, cherry)
			if e.revived:
				Paint.text(self, "2UP", Vector2(-10, -28), 10, cherry, 0, 3, true)
			draw_set_transform(Vector2.ZERO)
			glow(s(Vector2(e.x + e.w / 2 + e.face * 9, e.y + e.h - 13)), 10, cherry, 0.8)
		"f":
			var p := s(e.center())
			draw_set_transform(p, 0, Vector2(e.face, 1))
			var fp := absf(sin(e.t * 20))
			var wing := Color.WHITE if fl else Color(0.9, 0.82, 0.88, 0.92)
			Paint.fill_ellipse(self, Vector2(-6, -4), 14, 4 + fp * 8, wing, -0.5, 3)
			Paint.fill_ellipse(self, Vector2(-4, 4), 10, 3 + fp * 5, wing, 0.5, 3)
			Paint.fill_ellipse(self, Vector2(2, 0), 8, 6, Color.WHITE if fl else Color("3a1a2a"), 0, 3)
			Paint.fill_ellipse(self, Vector2(8, -2), 2.2, 2.2, cherry)
			draw_set_transform(Vector2.ZERO)
			glow(p, 22, cherry, 0.2)
		"s":
			var p := s(Vector2(e.x + e.w / 2, e.y + e.h))
			var pulse := 1.0 + sin(g.time * 30) * 0.06 if e.charging else 1.0
			draw_set_transform(p, 0, Vector2(e.face * pulse, 1.0 / pulse))
			var body := PackedVector2Array([Vector2(-17, 0)])
			body.append_array(Paint.bezier(Vector2(-17, 0), Vector2(-18, -22), Vector2(-8, -32), Vector2(0, -32)))
			body.append_array(Paint.bezier(Vector2(0, -32), Vector2(10, -32), Vector2(18, -20), Vector2(17, 0)))
			Paint.outline_poly(self, body, Color.WHITE if fl else Color("7a2a3a"))
			draw_rect(Rect2(-12, -14, 3, 10), Color("9a3a4e"))
			draw_polyline(PackedVector2Array([Vector2(-15, -4), Vector2(-14, -22), Vector2(-1, -30)]), _rim, 1.6, true)
			Paint.fill_ellipse(self, Vector2(8, -16), 5, 6.0 if e.charging else 3.0, OUT)
			draw_set_transform(Vector2.ZERO)
			if e.charging:
				glow(p + Vector2(e.face * 8, -16), 22, Color("ff9ab0"), 0.7)
		"core":
			var p := s(e.center())
			var blink := 0.5 + 0.5 * sin(g.time * (10 + (4 - e.t) * 6))
			Paint.fill_ellipse(self, p, 7, 7, Color.WHITE if fl else cherry, g.time, 3)
			Paint.text(self, str(ceili(e.t)), p + Vector2(0, -12), 12, Color("ffe14d"), 1, 3, true)
			glow(p, 26, cherry, 0.4 + blink * 0.4)
		"B":
			_draw_king(e)
	if e.kind in ["c", "f", "s"] and e.hp < e.max_hp:
		var w := 28.0
		var bp := s(Vector2(e.x + e.w / 2 - w / 2, e.y - 10))
		draw_rect(Rect2(bp - Vector2(1, 1), Vector2(w + 2, 5)), OUT)
		draw_rect(Rect2(bp, Vector2(w * maxf(0, e.hp) / e.max_hp, 3)), cherry)


func _draw_king(b: Game.Ent) -> void:
	var g := game
	var p := s(Vector2(b.x + b.w / 2, b.y + b.h))
	var gold := Color("f2c14e")
	var sy := 1.0
	if b.state == "slam_wind":
		sy = 0.88
	elif b.state == "air":
		sy = 1.08
	var alpha := clampf(b.t / 1.8, 0.2, 1.0) if b.state == "dying" else 1.0
	draw_set_transform(p, 0, Vector2(b.face / sy, sy))
	var fl := b.flash > 0
	var robe := PackedVector2Array([Vector2(-28, 0), Vector2(-18, -72), Vector2(18, -72), Vector2(28, 0), Vector2(18, -6), Vector2(10, 0), Vector2(0, -7), Vector2(-10, 0), Vector2(-19, -6)])
	Paint.outline_poly(self, robe, Color(Color.WHITE if fl else Color("3a0f1c"), alpha), 4)
	draw_polyline(PackedVector2Array([Vector2(-26, -4), Vector2(-17, -70)]), _rim, 2, true)
	# Cuello de armiño y cara de máscara de arcade.
	Paint.fill_ellipse(self, Vector2(0, -72), 22, 7, Color(Color("efe8f4"), alpha), 0, 3)
	Paint.fill_ellipse(self, Vector2(2, -86), 13, 13, Color(Color("1a0a10"), alpha), 0, 4)
	var eye := Color("ffe14d") if b.phase == 2 else gold
	Paint.fill_ellipse(self, Vector2(-2, -87), 2.5, 3, eye)
	Paint.fill_ellipse(self, Vector2(7, -87), 2.5, 3, eye)
	# Corona de cinco puntas.
	var crown := PackedVector2Array([Vector2(-14, -96), Vector2(-14, -110), Vector2(-8, -102), Vector2(-2, -114), Vector2(4, -102), Vector2(10, -112), Vector2(16, -100), Vector2(16, -96)])
	Paint.outline_poly(self, crown, Color(gold, alpha))
	# Cetro con un botón de CONTINUE en la punta.
	var lx := 34.0
	var ly := -100.0
	if b.state == "sweep_wind":
		lx = -20; ly = -96
	elif b.state == "sweep":
		lx = 50; ly = -48
	draw_line(Vector2(14, -56), Vector2(lx, ly - 4), OUT, 7)
	draw_line(Vector2(14, -56), Vector2(lx, ly - 4), gold, 3)
	Paint.fill_ellipse(self, Vector2(lx, ly - 8), 11, 11, Color("e8384f"), 0, 3)
	draw_set_transform(Vector2.ZERO)
	var wind := 0.9 if b.state in ["sweep_wind", "slam_wind"] else 0.5
	var ls := p + Vector2(lx * b.face / sy, (ly - 8) * sy)
	Paint.text(self, "C", ls + Vector2(0, 5), 12, Color("fff1c0"), 1, 0, true)
	glow(ls, 46, Color("e8384f"), wind)
	glow(p + Vector2(2.5 * b.face, -87 * sy), 16, eye, 0.8)


# --- Kira ---
func _draw_kira() -> void:
	var g := game
	var P := g.P
	for tr in P.trail:
		_kira_body(s(Vector2(tr["x"] + P.w / 2, tr["y"] + P.h)), tr["face"], tr["a"] * 0.6, true)
	var blink := P.inv > 0 and P.dash_t <= 0 and int(P.inv * 16) % 2 == 0
	_kira_body(s(Vector2(P.x + P.w / 2, P.y + P.h)), P.face, 0.35 if blink else 1.0, false)
	if P.crit_next:
		glow(s(P.center()), 30, Color("9b8cff"), 0.6)
	if P.heal_t > 0:
		glow(s(P.center()), 40 + P.heal_t * 30, MAGENTA, 0.45)


func _kira_body(p: Vector2, face: int, alpha: float, ghost: bool) -> void:
	var g := game
	var P := g.P
	var sq := P.squash * 0.18
	var running := P.on_ground and absf(P.vx) > 20
	var bob := -absf(sin(g.time * 16)) * 2 if running else 0.0
	var lean := 0.28 if P.dash_t > 0 else (0.07 if running else 0.0)
	draw_set_transform(p, lean * face, Vector2(face * (1 + sq), 1 - sq))
	if ghost:
		var sil := PackedVector2Array([Vector2(-8, -24), Vector2(10, -24), Vector2(12, 0), Vector2(-10, 0)])
		draw_colored_polygon(sil, Color(MAGENTA, alpha))
		Paint.fill_ellipse(self, Vector2(1, -32), 9, 9, Color(MAGENTA, alpha))
		draw_set_transform(Vector2.ZERO)
		return
	var a := alpha
	# Coleta larga: se queda atrás al correr y sube al caer.
	var sway := clampf(-P.vx * face / 300.0, -1.2, 1.2)
	var lift := clampf(P.vy / 600.0, -1.0, 1.0)
	var hair := PackedVector2Array([Vector2(-6, -36 + bob), Vector2(-14 + sway * 4, -34 - lift * 4 + bob), Vector2(-20 + sway * 6, -26 - lift * 8 + sin(g.time * 8) * 1.5), Vector2(-24 + sway * 8, -16 - lift * 10 + sin(g.time * 8 + 1) * 2.5)])
	draw_polyline(hair, Color(OUT, a), 8, true)
	draw_polyline(hair, Color(HAIR, a), 5, true)
	# Piernas.
	if running:
		var st := sin(g.time * 16) * 4
		Paint.fill_ellipse(self, Vector2(-3 + st, -1), 4, 2.5, Color(OUT, a))
		Paint.fill_ellipse(self, Vector2(4 - st, -1), 4, 2.5, Color(OUT, a))
	draw_rect(Rect2(-5, -10, 4, 9), Color(GRAPHITE, a))
	draw_rect(Rect2(2, -10, 4, 9), Color(GRAPHITE, a))
	# Torso: triángulo hacia delante (grafito con banda magenta).
	var torso := PackedVector2Array([Vector2(-8, -26 + bob), Vector2(9, -26 + bob), Vector2(12, -9), Vector2(-7, -9)])
	Paint.outline_poly(self, torso, Color(GRAPHITE, a))
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -20 + bob), Vector2(10, -20 + bob), Vector2(11, -15), Vector2(-6, -15)]), Color(MAGENTA, a))
	draw_polyline(PackedVector2Array([Vector2(-7, -10), Vector2(-8, -25 + bob)]), Color(_rim, a), 1.6, true)
	# Cabeza con flequillo en punta.
	Paint.fill_ellipse(self, Vector2(2, -33 + bob), 8, 8.5, Color(SKIN, a), 0, 3)
	var bangs := PackedVector2Array([Vector2(-7, -36 + bob), Vector2(-4, -43 + bob), Vector2(6, -43 + bob), Vector2(11, -36 + bob), Vector2(7, -38 + bob), Vector2(5, -33 + bob), Vector2(2, -37 + bob), Vector2(-3, -34 + bob)])
	Paint.outline_poly(self, bangs, Color(HAIR, a), 2.5)
	Paint.fill_ellipse(self, Vector2(6, -32 + bob), 1.4, 2.2, Color(OUT, a))
	# Espada de energía con 6 muescas: se encienden con el filo.
	if P.atk_t <= 0:
		var hand := Vector2(9, -16 + bob)
		var tip := hand + Vector2(-20, -18)
		draw_line(hand, tip, Color(OUT, a), 6)
		draw_line(hand, tip, Color(Color("fff5fb"), a), 3)
		for i in 6:
			var q := hand.lerp(tip, 0.18 + i * 0.13)
			draw_circle(q, 1.6, Color(SPARK if i < P.filo else Color("5a4a5a"), a))
	draw_set_transform(Vector2.ZERO)
	if P.filo >= Game.FILO_COST:
		glow(p + Vector2(-2 * face, -24), 22 + P.filo * 3, MAGENTA, 0.12 + P.filo * 0.03)


func _draw_slashes() -> void:
	var g := game
	var c := s(g.P.center()) + Vector2(0, -2)
	for sl in g.slashes:
		var a: float = 1.0 - sl["t"] / 0.14
		var rot := 0.0
		match sl["dir"]:
			"up": rot = -PI / 2
			"down": rot = PI / 2
			_: rot = 0.0 if sl["face"] > 0 else PI
		var R := 52.0 if sl["combo"] == 2 else 44.0
		var outer := PackedVector2Array()
		for i in 13:
			var t := -1.15 + 2.3 * i / 12.0
			outer.append(c + Vector2(cos(t), sin(t)).rotated(rot) * R)
		for i in range(12, -1, -1):
			var t := -1.0 + 2.0 * i / 12.0
			outer.append(c + (Vector2(10, 0) + Vector2(cos(t), sin(t)) * (R - 14)).rotated(rot))
		draw_colored_polygon(outer, Color(1, 0.96, 0.98, 0.9 * a))
		glow(c + Vector2(R * 0.7, 0).rotated(rot), R, MAGENTA, 0.6 * a)


func _draw_projs() -> void:
	var g := game
	for q in g.projs:
		var p := s(Vector2(q.x, q.y))
		match q.kind:
			"spark":
				glow(p, 28, MAGENTA, 0.8)
				Paint.fill_ellipse(self, p, 9, 4, Color("fff0fa"), 0)
				draw_line(p - Vector2(signf(q.vx) * 16, 0), p, Color(MAGENTA, 0.8), 3)
			"glob":
				Paint.fill_ellipse(self, p, q.r, q.r * 1.1, Color("ff9ab0"), 0, 3)
				Paint.fill_ellipse(self, p + Vector2(-2, -3), 2.5, 2.5, Color("ffe0ea"))
			"shock":
				var base := s(Vector2(q.x, q.y + q.h))
				var arc := PackedVector2Array([base])
				arc.append_array(Paint.bezier(base, base + Vector2(q.w * 0.3, -q.h - 8), base + Vector2(q.w * 0.7, -q.h - 8), base + Vector2(q.w, 0)))
				draw_colored_polygon(arc, Color("ffd27a"))
				glow(base + Vector2(q.w / 2, -8), 36, Color("f2c14e"), 0.6)
			"warn":
				var a := 0.4 + 0.4 * sin(g.time * 20)
				var fy := (g.room.h - 2) * T - _cam.y
				draw_rect(Rect2(p.x - 14, fy - 4, 28, 4), Color(Color("e8384f"), a))
				glow(Vector2(p.x, fy), 24, Color("e8384f"), a * 0.6)
			"fire":
				glow(p + Vector2(10, 12), 22, Color("22e4ff"), 0.5 * minf(1.0, q.life))


func _draw_pickups() -> void:
	for k in game.pickups:
		var p := s(Vector2(k.x, k.y))
		glow(p, 14, Color("6ff3ff"), 0.7)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(4, 0), p + Vector2(0, 5), p + Vector2(-4, 0)]), Color("e8fbff"))


func _draw_parts() -> void:
	for q in game.parts:
		var a: float = maxf(0.0, q["life"] / q["max"])
		var p := s(Vector2(q["x"], q["y"]))
		var sz: float = q["size"]
		if q["glow"]:
			glow(p, sz * 3, q["col"], a * 0.8)
		draw_rect(Rect2(p - Vector2(sz, sz) / 2, Vector2(sz, sz)), Color(q["col"], a))


func _draw_nums() -> void:
	for n in game.nums:
		var a: float = 1.0 - n["t"] / 0.9
		var p := s(Vector2(n["x"], n["y"] - n["t"] * 40))
		Paint.text(self, n["txt"], p, 28 if n["big"] else 20, Color(n["col"], a), 1, 6, true)


func _draw_vignette() -> void:
	# Viñeta: cuatro bandas que oscurecen los bordes.
	var d := Color(0, 0, 0, 0.55)
	var z := Color(0, 0, 0, 0)
	var W := Game.VW
	var H := Game.VH
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, 90), Vector2(0, 90)]), PackedColorArray([d, d, z, z]))
	draw_polygon(PackedVector2Array([Vector2(0, H - 110), Vector2(W, H - 110), Vector2(W, H), Vector2(0, H)]), PackedColorArray([z, z, d, d]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(140, 0), Vector2(140, H), Vector2(0, H)]), PackedColorArray([d, z, z, d]))
	draw_polygon(PackedVector2Array([Vector2(W - 140, 0), Vector2(W, 0), Vector2(W, H), Vector2(W - 140, H)]), PackedColorArray([z, d, d, z]))
