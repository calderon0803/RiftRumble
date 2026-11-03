## Dibuja la sala: fondo con paralaje, casillas, objetos, enemigos, Álex y efectos.
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
		_draw_alex()
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
	# El muro falso cuenta como pared para los bordes: así no se delata.
	return r.g[y][x] == "#" or r.g[y][x] == "w" or (r.g[y][x] == "d" and game.arena_active)


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
			if ch == "#" or ch == "w":
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
				if ch == "w" and game.hits.has(Vector2i(x, y)):
					# Muro falso golpeado una vez: ahora sí se ven las grietas.
					draw_polyline(PackedVector2Array([p + Vector2(6, 4), p + Vector2(14, 14), p + Vector2(9, 22), p + Vector2(17, 29)]), OUT, 2.5)
					draw_polyline(PackedVector2Array([p + Vector2(26, 5), p + Vector2(19, 16), p + Vector2(27, 24)]), OUT, 2.5)
					glow(p + Vector2(16, 16), 20, Color("ff6fd8"), 0.3)
			elif ch == "=":
				draw_rect(Rect2(p, Vector2(T, 10)), stone)
				draw_rect(Rect2(p, Vector2(T, 3)), OUT)
				draw_rect(Rect2(p.x, p.y + 10, T, 3), OUT)
				draw_rect(Rect2(p.x, p.y + 3, T, 2), _rim)
				if (x + y) % 3 == 0:
					draw_rect(Rect2(p.x + 13, p.y + 13, 5, 8), OUT)
			elif ch == "b" or ch == "n":
				# Bloque rompible: ladrillo agrietado; el que guarda fragmentos brilla por las grietas.
				var cracked := game.hits.has(Vector2i(x, y))
				draw_rect(Rect2(p, Vector2(T, T)), stone.lightened(0.08))
				draw_rect(Rect2(p, Vector2(T, T)), OUT, false, 3)
				var crack := Color("f2c14e") if ch == "n" else deep
				draw_polyline(PackedVector2Array([p + Vector2(8, 4), p + Vector2(14, 13), p + Vector2(10, 20), p + Vector2(18, 28)]), crack, 2)
				draw_polyline(PackedVector2Array([p + Vector2(24, 6), p + Vector2(20, 15), p + Vector2(26, 22)]), crack, 2)
				if cracked:
					draw_polyline(PackedVector2Array([p + Vector2(3, 16), p + Vector2(16, 17), p + Vector2(29, 12)]), crack, 2.5)
				if ch == "n":
					glow(p + Vector2(16, 16), 22, Color("f2c14e"), 0.25 + 0.1 * sin(game.time * 3 + x))
			elif ch == "d":
				# Puerta de arena: abierta no se ve; cerrada son barrotes.
				if game.arena_active:
					draw_rect(Rect2(p, Vector2(T, T)), Color(0, 0, 0, 0.35))
					for i in 3:
						draw_rect(Rect2(p + Vector2(4 + i * 10, 0), Vector2(5, T)), OUT)
						draw_rect(Rect2(p + Vector2(5 + i * 10, 0), Vector2(3, T)), Color("e8384f"))
					glow(p + Vector2(16, 16), 26, Color("e8384f"), 0.3)
			elif ch == "y":
				# Plataforma de cristal: sólida y brillante mientras Álex resuena; si no, apenas un reflejo.
				if game.P.resonance > 0:
					var fade := clampf(game.P.resonance / 1.5, 0.35, 1.0)
					draw_rect(Rect2(p, Vector2(T, 10)), Color(Color("ffe9a8"), fade))
					draw_rect(Rect2(p, Vector2(T, 3)), Color(OUT, fade))
					draw_rect(Rect2(p.x, p.y + 10, T, 2), Color(OUT, fade))
					glow(p + Vector2(T / 2.0, 5), 26, Color("e0b84a"), 0.35 * fade)
				else:
					draw_rect(Rect2(p, Vector2(T, 10)), Color(Color("e0b84a"), 0.12), false, 1.0)
			elif ch == "p":
				# Bloque sin colocar: solo su contorno, a trazos, esperando un clic.
				var a := 0.45 + 0.25 * sin(game.time * 4 + x)
				var col := Color(Color("ff6fd8"), a)
				for i in 4:
					draw_line(p + Vector2(i * 8 + 1, 1), p + Vector2(i * 8 + 5, 1), col, 2)
					draw_line(p + Vector2(i * 8 + 1, 11), p + Vector2(i * 8 + 5, 11), col, 2)
				draw_line(p + Vector2(1, 1), p + Vector2(1, 11), col, 2)
				Paint.text(self, "?", p + Vector2(T / 2.0, 10), 10, col, 1, 0, true)
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
			"T":
				var n := int(o["text"])
				if g.portal_open(n):
					# Entrada a un trozo del juego de Kira: un marco de nivel con su número.
					var c := p + Vector2(0, -30)
					var pulse := 1.0 + sin(g.time * 3) * 0.05
					Paint.fill_ellipse(self, c, 18 * pulse, 30 * pulse, OUT)
					Paint.fill_ellipse(self, c, 14 * pulse, 26 * pulse, Color("3a1030"))
					draw_arc(c, 16, 0, TAU, 32, MAGENTA, 2)
					Paint.text(self, "%d-1" % n, c + Vector2(0, 5), 13, Color("ffd6f2"), 1, 3, true)
					glow(c, 70, MAGENTA, 0.45)
			"R":
				# Cristal de resonancia sobre su peana; vibra mientras Álex resuena.
				var on := g.P.resonance > 0
				var jit := Vector2(randf_range(-1, 1), 0) if on else Vector2.ZERO
				Paint.outline_poly(self, PackedVector2Array([p + Vector2(-12, 0), p + Vector2(-8, -8), p + Vector2(8, -8), p + Vector2(12, 0)]), _pal["stone"])
				var crystal := PackedVector2Array([p + jit + Vector2(0, -44), p + jit + Vector2(9, -26), p + jit + Vector2(0, -8), p + jit + Vector2(-9, -26)])
				Paint.outline_poly(self, crystal, Color("ffe9a8") if on else Color("c9a24a"), 2.5)
				draw_line(p + jit + Vector2(0, -42), p + jit + Vector2(0, -10), Color(1, 1, 1, 0.5), 1.5)
				glow(p + Vector2(0, -26), 70 if on else 34, Color("e0b84a"), 0.6 if on else 0.3)
			"W":
				var c := p + Vector2(0, -30 + sin(g.time * 2) * 5)
				glow(c, 60, Color("7be36b"), 0.5)
				Paint.fill_ellipse(self, c, 13, 13, Color("e0ffd8"), 0, 3)
				Paint.fill_ellipse(self, c, 6, 6, Color("7be36b"))
			"h":
				# Fuente: pila de piedra con agua del color del Umbral.
				Paint.outline_poly(self, PackedVector2Array([p + Vector2(-26, 0), p + Vector2(-22, -18), p + Vector2(22, -18), p + Vector2(26, 0)]), _pal["stone"])
				draw_rect(Rect2(p + Vector2(-4, -40), Vector2(8, 22)), _pal["stone"])
				draw_rect(Rect2(p + Vector2(-4, -40), Vector2(8, 22)), OUT, false, 2)
				draw_rect(Rect2(p + Vector2(-20, -20), Vector2(40, 5)), Color("6ff3ff"))
				for i in 3:
					var dy := fposmod(game.time * 40 + i * 12, 34)
					draw_rect(Rect2(p + Vector2(-1.5, -42 + dy * 0.6), Vector2(3, 5)), Color("b8faff"))
				glow(p + Vector2(0, -26), 60, Color("6ff3ff"), 0.4)
			"g":
				# Fragmentos escondidos: un montón brillante.
				var c := p + Vector2(0, -12 + sin(g.time * 3) * 2)
				for q in [Vector2(-6, 2), Vector2(6, 2), Vector2(0, -6)]:
					var gem := PackedVector2Array([c + q + Vector2(0, -6), c + q + Vector2(5, 0), c + q + Vector2(0, 6), c + q + Vector2(-5, 0)])
					Paint.outline_poly(self, gem, Color("e8fbff"), 2)
				glow(c, 34, Color("6ff3ff"), 0.6)
			"S":
				# Cartel de tutorial a medio hacer, con una nota de Álex.
				draw_rect(Rect2(p + Vector2(-2, -26), Vector2(4, 26)), Color("4a3a48"))
				var w := Paint.text_width(o["text"], 12) + 16
				var box := Rect2(p + Vector2(-w / 2, -48), Vector2(w, 22))
				draw_rect(box.grow(2), OUT)
				draw_rect(box, Color("efe2c8"))
				Paint.text(self, o["text"], p + Vector2(0, -32), 12, Color("3a2030"), 1)
			"G":
				# Bandera del final del nivel.
				draw_rect(Rect2(p + Vector2(-2, -76), Vector2(4, 76)), Color("d8cfe0"))
				var wave := sin(g.time * 5) * 3
				Paint.outline_poly(self, PackedVector2Array([p + Vector2(2, -74), p + Vector2(30, -66 + wave), p + Vector2(2, -56)]), MAGENTA, 2.5)
				glow(p + Vector2(14, -66), 50, MAGENTA, 0.4)
			"K":
				_draw_kira_npc(p)
				if g.new_kira_talk(int(o["text"])):
					Paint.text(self, "!", p + Vector2(0, -72 + sin(g.time * 4) * 3), 28, Color("5fe39a"), 1, 6, true)
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


## Sprites de los personajes (art/personajes, preparados con PhotoCraft a partir de los diseños).
var _tex := {}


func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = load("res://art/personajes/%s.png" % name)
	return _tex[name]


## Reposo de cada personaje: fotogramas en bucle (art/personajes/<nombre>_reposo_N.png). Los de Kira salen de
## un vídeo generado con Wan 2.2 en Hugging Face a partir de su diseño (fotograma inicial = final, así que el
## bucle cierra), con el fondo quitado en PhotoCraft. 0 fotogramas = imagen fija (<nombre>.png).
const IDLE := {"kira": [8, 0.25], "nexo": [0, 0.25]}


## Dibuja al personaje con los pies en `p`, mirando a `face`. `figure` es la altura de la figura en la imagen
## y `height` la altura en pantalla.
func _draw_idle(name: String, p: Vector2, face: int, height: float, figure: float, phase: float) -> void:
	var frames: int = IDLE[name][0]
	var t: Texture2D
	if frames > 0:
		t = tex("%s_reposo_%d" % [name, int(game.time / IDLE[name][1] + phase) % frames])
	else:
		t = tex(name)
	var k := height / figure
	draw_set_transform(p, 0, Vector2(face * k, k))
	var origin := Vector2(-t.get_width() / 2.0, -t.get_height())
	# Contorno oscuro (la silueta desplazada en cuatro direcciones) para que se lea sobre cualquier fondo.
	var o := 1.6 / k
	for d in [Vector2(o, 0), Vector2(-o, 0), Vector2(0, o), Vector2(0, -o)]:
		draw_texture(t, origin + d, Color(OUT, 0.9))
	draw_texture(t, origin)
	draw_set_transform(Vector2.ZERO)

## Hacia dónde mira cada personaje (por su posición en la sala). Solo se gira cuando Álex ha pasado
## claramente al otro lado, para que no cambie de lado mientras Álex sigue delante de él.
var _npc_face := {}


func npc_face(p: Vector2, margin := 8.0) -> int:
	var key := "%s:%d" % [game.room.id, int(p.x)]
	var face: int = _npc_face.get(key, 1 if game.P.center().x >= p.x else -1)
	var dx := game.P.center().x - p.x
	if dx > margin:
		face = 1
	elif dx < -margin:
		face = -1
	_npc_face[key] = face
	return face


## Runas que flotan alrededor de Nexo, como en su diseño: trazos sueltos en naranja y azul.
const RUNES := [
	[Vector2(-3, -4), Vector2(3, -4), Vector2(-3, 4), Vector2(3, 4)],
	[Vector2(-3, 4), Vector2(-3, -4), Vector2(2, 0), Vector2(-3, 0)],
	[Vector2(-3, 4), Vector2(0, -4), Vector2(3, 4)],
	[Vector2(-3, -4), Vector2(-3, 4), Vector2(3, 4)],
	[Vector2(3, -4), Vector2(-3, -1), Vector2(3, 1), Vector2(-3, 4)],
	[Vector2(-3, 4), Vector2(-3, -4), Vector2(3, -2), Vector2(-3, 0), Vector2(3, 4)],
]


func _draw_nexo(p: Vector2) -> void:
	var g := game
	var face := npc_face(p + _cam)
	glow(p + Vector2(0, -4), 46, Color("4fc3f7"), 0.12)
	_draw_idle("nexo", p, face, 76, 144, 0.0)
	draw_set_transform(Vector2.ZERO)
	for i in RUNES.size():
		var a := g.time * 0.6 + i * TAU / RUNES.size()
		var c := p + Vector2(cos(a) * 30, -38 + sin(a * 1.3) * 22)
		var col := Color("ff9a3a") if i % 2 == 0 else Color("4fc3f7")
		var alpha := 0.55 + 0.35 * sin(g.time * 3 + i)
		var pts := PackedVector2Array()
		for q in RUNES[i]:
			pts.append(c + q)
		draw_polyline(pts, Color(col, alpha), 1.5)
		glow(c, 10, col, 0.35 * alpha)


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
		"E":
			_draw_student(e)
		"k":
			# Conjurador: túnica de la Academia, libro abierto y barra del hechizo que carga.
			var p := s(Vector2(e.x + e.w / 2, e.y + e.h))
			draw_set_transform(p, 0, Vector2(e.face, 1))
			var robe := PackedVector2Array([Vector2(-12, 0), Vector2(-7, -24), Vector2(7, -24), Vector2(12, 0), Vector2(5, -4), Vector2(0, 0), Vector2(-5, -4)])
			Paint.outline_poly(self, robe, Color.WHITE if fl else Color("3a2a6a"))
			Paint.outline_poly(self, PackedVector2Array([Vector2(-9, -22), Vector2(0, -38), Vector2(9, -22)]), Color.WHITE if fl else Color("2a1f50"))
			Paint.fill_ellipse(self, Vector2(2, -26), 2, 2, Color("7be36b"))
			Paint.outline_poly(self, PackedVector2Array([Vector2(6, -16), Vector2(16, -18), Vector2(16, -10), Vector2(6, -8)]), Color("efe2c8"), 2)
			draw_set_transform(Vector2.ZERO)
			if e.charging:
				var bw := 30.0
				var bp := s(Vector2(e.x + e.w / 2 - bw / 2, e.y - 14))
				draw_rect(Rect2(bp - Vector2(1, 1), Vector2(bw + 2, 6)), OUT)
				draw_rect(Rect2(bp, Vector2(bw * clampf(e.cd / g.charge_time(e), 0, 1), 4)), Color("7be36b"))
				glow(p + Vector2(0, -20), 40, Color("7be36b"), 0.5)
		"dummy":
			# Muñeco de entrenamiento con la combinación que pide encima.
			var p := s(Vector2(e.x + e.w / 2, e.y + e.h))
			var done := e.idx >= e.seq.size()
			draw_rect(Rect2(p + Vector2(-2, -14), Vector2(4, 14)), Color("6a4a3a"))
			Paint.outline_poly(self, PackedVector2Array([p + Vector2(-11, -14), p + Vector2(-9, -34), p + Vector2(9, -34), p + Vector2(11, -14)]), Color.WHITE if fl else Color("c9a77a"))
			Paint.fill_ellipse(self, p + Vector2(0, -40), 7, 7, Color("c9a77a"), 0, 3)
			var icons := {"side": "X", "up": "↑X", "down": "↓X"}
			var x0 := p.x - (e.seq.size() - 1) * 15
			for i in e.seq.size():
				var col := MAGENTA if i < e.idx else Color("efe2c8")
				Paint.text(self, icons[e.seq[i]], Vector2(x0 + i * 30, p.y - 56), 13, col, 1, 4, true)
			if done:
				glow(p + Vector2(0, -26), 50, MAGENTA, 0.5)
	if e.elite:
		# Élite: corona dorada encima y un halo.
		var top := s(Vector2(e.x + e.w / 2, e.y - 4))
		Paint.outline_poly(self, PackedVector2Array([top + Vector2(-7, 0), top + Vector2(-7, -7), top + Vector2(-3, -3), top + Vector2(0, -9), top + Vector2(3, -3), top + Vector2(7, -7), top + Vector2(7, 0)]), Color("f2c14e"), 2)
		glow(s(e.center()), maxf(e.w, e.h) * 1.2, Color("f2c14e"), 0.25)
	if e.shield > 0:
		draw_arc(s(e.center()), maxf(e.w, e.h) * 0.7, 0, TAU, 32, Color(Color("7be36b"), 0.8), 2)
		glow(s(e.center()), maxf(e.w, e.h), Color("7be36b"), 0.2)
	if e.kind in ["c", "f", "s", "k"] and e.hp < e.max_hp:
		var w := 28.0
		var bp := s(Vector2(e.x + e.w / 2 - w / 2, e.y - 10))
		draw_rect(Rect2(bp - Vector2(1, 1), Vector2(w + 2, 5)), OUT)
		draw_rect(Rect2(bp, Vector2(w * maxf(0, e.hp) / e.max_hp, 3)), cherry)


## El Alumno Eterno: un estudiante con toga y birrete, rodeado de hojas de examen.
## Su escudo muestra el ataque que ha estudiado (el que resiste).
func _draw_student(b: Game.Ent) -> void:
	var g := game
	var p := s(Vector2(b.x + b.w / 2, b.y + b.h))
	var fl := b.flash > 0
	var gold := Color("e0b84a")
	var alpha := 1.0
	if b.state == "blink_out":
		alpha = clampf(b.t / 0.35, 0.0, 1.0)
	elif b.state == "blink_in":
		alpha = 1.0 - clampf(b.t / 0.25, 0.0, 1.0)
	elif b.state == "dying":
		alpha = clampf(b.t / 1.8, 0.2, 1.0)
	var bob := sin(g.time * 2) * 2
	draw_set_transform(p + Vector2(0, bob), 0, Vector2(b.face, 1))
	var robe := PackedVector2Array([Vector2(-20, 0), Vector2(-13, -50), Vector2(13, -50), Vector2(20, 0), Vector2(10, -6), Vector2(0, 0), Vector2(-10, -6)])
	Paint.outline_poly(self, robe, Color(Color.WHITE if fl else Color("231a44"), alpha), 3.5)
	draw_polyline(PackedVector2Array([Vector2(-18, -4), Vector2(-12, -48)]), Color(_rim, alpha), 2, true)
	Paint.fill_ellipse(self, Vector2(2, -58), 10, 11, Color(Color("d9cfe8"), alpha), 0, 3)
	Paint.fill_ellipse(self, Vector2(6, -58), 2, 3, Color(OUT, alpha))
	# Birrete.
	Paint.outline_poly(self, PackedVector2Array([Vector2(-14, -68), Vector2(2, -74), Vector2(18, -68), Vector2(2, -63)]), Color(Color("16122c"), alpha), 2.5)
	draw_line(Vector2(16, -68), Vector2(18, -56), Color(gold, alpha), 2)
	draw_set_transform(Vector2.ZERO)
	# Hojas de examen orbitando.
	for i in 3:
		var a := g.time * 1.5 + i * TAU / 3
		var q := p + Vector2(cos(a) * 34, -40 + sin(a) * 14)
		draw_rect(Rect2(q - Vector2(5, 7), Vector2(10, 14)), Color(Color("efe2c8"), alpha))
		draw_rect(Rect2(q - Vector2(5, 7), Vector2(10, 14)), Color(OUT, alpha), false, 1.5)
	if b.state in ["volley_wind", "runes"]:
		glow(p + Vector2(0, -40), 60, gold, 0.6)
	if b.resist != "":
		var icons := {"side": "X", "up": "↑X", "down": "↓X", "cast": "Q"}
		draw_arc(p + Vector2(0, -36), 46, 0, TAU, 40, Color(Color("8a8698"), 0.7 * alpha), 3)
		Paint.text(self, icons.get(b.resist, "?"), p + Vector2(0, -96), 14, Color("c9c2d6"), 1, 4, true)


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


# --- Álex ---
const MANNEQUIN := Color("b9bcc6")
const MANNEQUIN_DARK := Color("7d818e")
const GRID := Color("8f94a3")


func _draw_alex() -> void:
	var g := game
	var P := g.P
	# Arrastrar: copias que se quedan atrás, con el recuadro de selección del editor.
	for tr in P.trail:
		var tp := s(Vector2(tr["x"], tr["y"]))
		var a: float = tr["a"] * 0.6
		draw_rect(Rect2(tp - Vector2(4, 16), Vector2(P.w + 8, P.h + 16)), Color(Game.DEBUG_COL, a * 0.6), false, 1.0)
		_alex_body(s(Vector2(tr["x"] + P.w / 2, tr["y"] + P.h)), tr["face"], a, true)
	var blink := P.inv > 0 and P.dash_t <= 0 and int(P.inv * 16) % 2 == 0
	_alex_body(s(Vector2(P.x + P.w / 2, P.y + P.h)), P.face, 0.35 if blink else 1.0, false)
	if P.crit_next:
		glow(s(P.center()), 30, Color("9b8cff"), 0.6)
	if P.heal_t > 0:
		glow(s(P.center()), 40 + P.heal_t * 30, Game.DEBUG_COL, 0.45)
	if P.resonance > 0:
		glow(s(P.center()), 34, Color("e0b84a"), 0.25 + 0.15 * sin(g.time * 12))


## Avatar de pruebas: maniquí gris sin texturas, con la cuadrícula a la vista. Al vencer al Rey del Reinicio
## se queda con un detalle de su mundo (la corona dorada en el pecho).
func _alex_body(p: Vector2, face: int, alpha: float, ghost: bool) -> void:
	var g := game
	var P := g.P
	var sq := P.squash * 0.18
	var running := P.on_ground and absf(P.vx) > 20
	var bob := -absf(sin(g.time * 16)) * 2 if running else 0.0
	var lean := 0.28 if P.dash_t > 0 else (0.07 if running else 0.0)
	draw_set_transform(p, lean * face, Vector2(face * (1 + sq), 1 - sq))
	if ghost:
		draw_colored_polygon(PackedVector2Array([Vector2(-7, -26), Vector2(8, -26), Vector2(10, 0), Vector2(-8, 0)]), Color(MANNEQUIN, alpha))
		Paint.fill_ellipse(self, Vector2(1, -33), 7, 8, Color(MANNEQUIN, alpha))
		draw_set_transform(Vector2.ZERO)
		return
	var a := alpha
	var body := Color(MANNEQUIN, a)
	var dark := Color(MANNEQUIN_DARK, a)
	# Piernas.
	var st := sin(g.time * 16) * 4 if running else 0.0
	draw_line(Vector2(-3, -11), Vector2(-3 + st, 0), Color(OUT, a), 6)
	draw_line(Vector2(-3, -11), Vector2(-3 + st, 0), dark, 3.5)
	draw_line(Vector2(4, -11), Vector2(4 - st, 0), Color(OUT, a), 6)
	draw_line(Vector2(4, -11), Vector2(4 - st, 0), body, 3.5)
	# Torso con la cuadrícula de pruebas.
	var torso := PackedVector2Array([Vector2(-7, -26 + bob), Vector2(8, -26 + bob), Vector2(7, -10), Vector2(-6, -10)])
	Paint.outline_poly(self, torso, body)
	for gy in [-21, -16]:
		draw_line(Vector2(-6, gy + bob * 0.5), Vector2(7, gy + bob * 0.5), Color(GRID, a), 1)
	draw_line(Vector2(0.5, -25 + bob), Vector2(0.5, -11), Color(GRID, a), 1)
	draw_polyline(PackedVector2Array([Vector2(-6, -11), Vector2(-7, -25 + bob)]), Color(_rim, a), 1.6, true)
	if g.meta["boss"]:
		# Detalle del Reino del Continue: una pequeña corona dorada en el pecho.
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -18 + bob), Vector2(-2, -22 + bob), Vector2(0, -20 + bob), Vector2(2, -23 + bob), Vector2(4, -20 + bob), Vector2(5, -22 + bob), Vector2(5, -18 + bob)]), Color(Color("f2c14e"), a))
	if g.meta["boss2"]:
		# Detalle de la Academia: una bufanda violeta que ondea hacia atrás.
		var wave := sin(g.time * 6) * 2
		draw_polyline(PackedVector2Array([Vector2(-5, -25 + bob), Vector2(-12, -24 + wave), Vector2(-18, -21 + wave * 1.5)]), Color(OUT, a), 6, true)
		draw_polyline(PackedVector2Array([Vector2(-5, -25 + bob), Vector2(-12, -24 + wave), Vector2(-18, -21 + wave * 1.5)]), Color(Color("7a5ad6"), a), 3.5, true)
	# Cabeza lisa, sin rasgos: solo el corte de la malla.
	Paint.fill_ellipse(self, Vector2(1, -33 + bob), 7, 8, body, 0, 3)
	draw_arc(Vector2(1, -33 + bob), 7, -0.6, 0.6, 8, Color(GRID, a), 1)
	draw_line(Vector2(-6, -33 + bob), Vector2(8, -33 + bob), Color(GRID, a), 1)
	# Brazo con el cursor.
	if P.atk_t <= 0:
		var hand := Vector2(8, -17 + bob)
		draw_line(Vector2(4, -22 + bob), hand, Color(OUT, a), 5)
		draw_line(Vector2(4, -22 + bob), hand, body, 2.5)
		_cursor(hand + Vector2(3, -2), 0.6, a, 0.85)
	draw_set_transform(Vector2.ZERO)
	if P.debug >= Game.DEBUG_COST:
		glow(p + Vector2(8 * face, -20), 16 + P.debug * 3, Game.DEBUG_COL, 0.1 + P.debug * 0.03)


## La flecha del ratón del editor, con la punta en `tip`.
func _cursor(tip: Vector2, rot: float, a: float, k := 1.0) -> void:
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(0, 16), Vector2(4, 12), Vector2(7, 18), Vector2(10, 17), Vector2(7, 11), Vector2(12, 11)])
	var tr := PackedVector2Array()
	for q in pts:
		tr.append(tip + (q * k).rotated(rot))
	Paint.outline_poly(self, tr, Color(Color("ffffff"), a), 2.0)


func _draw_kira_npc(p: Vector2) -> void:
	# Kira de pie, mirando hacia Álex, tal como su diseño (sin espada por ahora).
	var g := game
	var face := npc_face(p + _cam)
	glow(p + Vector2(0, -4), 40, Color("5fe39a"), 0.12)
	_draw_idle("kira", p, face, 68, 128, 2.0)
	draw_set_transform(Vector2.ZERO)


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
		draw_colored_polygon(outer, Color(0.92, 1, 0.98, 0.75 * a))
		# Clic: el cursor golpea con la punta y deja dos ondas.
		var tip := c + Vector2(R - 6, 0).rotated(rot)
		var k: float = sl["t"] / 0.14
		draw_arc(tip, 6 + k * 18, 0, TAU, 20, Color(Game.DEBUG_COL, a), 2)
		draw_arc(tip, 2 + k * 10, 0, TAU, 16, Color(Color.WHITE, a), 1.5)
		_cursor(tip, rot - PI / 4 + PI / 2 * 0.0, a, 1.1)
		glow(tip, R * 0.8, Game.DEBUG_COL, 0.6 * a)


func _draw_projs() -> void:
	var g := game
	for q in g.projs:
		var p := s(Vector2(q.x, q.y))
		match q.kind:
			"spark":
				# Excepción: una ventana de error que vuela.
				var win := Rect2(p - Vector2(12, 9), Vector2(24, 18))
				glow(p, 30, Color("e8384f"), 0.6)
				draw_rect(win.grow(2), OUT)
				draw_rect(win, Color("f4f1e8"))
				draw_rect(Rect2(win.position, Vector2(24, 5)), Color("e8384f"))
				Paint.text(self, "!", p + Vector2(0, 8), 12, Color("e8384f"), 1, 0, true)
				draw_line(p - Vector2(signf(q.vx) * 26, 0), p - Vector2(signf(q.vx) * 14, 0), Color(Game.DEBUG_COL, 0.8), 2)
			"glob":
				Paint.fill_ellipse(self, p, q.r, q.r * 1.1, Color("ff9ab0"), 0, 3)
				Paint.fill_ellipse(self, p + Vector2(-2, -3), 2.5, 2.5, Color("ffe0ea"))
			"shock":
				var base := s(Vector2(q.x, q.y + q.h))
				var arc := PackedVector2Array([base])
				arc.append_array(Paint.bezier(base, base + Vector2(q.w * 0.3, -q.h - 8), base + Vector2(q.w * 0.7, -q.h - 8), base + Vector2(q.w, 0)))
				draw_colored_polygon(arc, Color("ffd27a"))
				glow(base + Vector2(q.w / 2, -8), 36, Color("f2c14e"), 0.6)
			"orb":
				glow(p, 22, Color("e0b84a"), 0.8)
				Paint.fill_ellipse(self, p, q.r, q.r, Color("fff1c0"), 0, 2.5)
			"rune":
				var fy := (g.room.h - 2) * T - _cam.y
				if q.t > 0:
					var a := 0.4 + 0.4 * sin(g.time * 18)
					draw_arc(Vector2(p.x, fy - 4), 14, PI, TAU, 16, Color(Color("e0b84a"), a), 3)
					glow(Vector2(p.x, fy), 26, Color("e0b84a"), a * 0.5)
				else:
					var k := clampf(q.life / 0.8, 0.0, 1.0)
					draw_rect(Rect2(p.x - 12, 0, 24, fy), Color(Color("fff1c0"), 0.75 * k))
					glow(Vector2(p.x, fy - 60), 60, Color("e0b84a"), 0.6 * k)
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
