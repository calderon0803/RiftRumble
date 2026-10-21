## Genera el arte PROVISIONAL de la Fase 2 en res://art/placeholder/.
## Uso: godot --headless --path . --script res://tools/gen_placeholder_art.gd
##
## Todo lo que hay en art/placeholder/ es temporal: sirve para validar mecánicas,
## escala, profundidad y rendimiento con sprites reales (textura compartida),
## y se sustituirá por arte definitivo sin tocar la lógica.
extends SceneTree

const OUT := "res://art/placeholder/"
const TW := 64  # ancho de casilla
const TH := 32  # alto de casilla

const OUTLINE := Color("1e1830")
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 2026
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save(_ground_atlas(), "ground_tiles.png")
	_save(_block(), "prop_block.png")
	_save(_bush(), "prop_bush.png")
	_save(_enemy_sheet(Color("e2475a"), Color("ff8f9c"), &"light"), "enemy_light.png")
	_save(_enemy_sheet(Color("7d8aa6"), Color("b9c3d8"), &"armored"), "enemy_armored.png")
	_save(_enemy_sheet(Color("ffcc33"), Color("fff0a0"), &"fast"), "enemy_fast.png")
	_save(_tower(), "tower_basic.png")
	_save(_tower_corrupt(), "tower_corrupt.png")
	_save(_tower_seal(), "tower_seal.png")
	_save(_tower_bounce(), "tower_bounce.png")
	_save(_build_pad(), "build_pad.png")
	_save(_projectile(), "projectile_bit.png")
	_save(_proj_pixel(), "proj_pixel.png")
	_save(_proj_seal(), "proj_seal.png")
	_save(_proj_ball(), "proj_ball.png")
	_save(_hero_portal(), "hero_portal.png")
	_save(_hero_blade(), "hero_blade.png")
	_save(_boss_w1(), "enemy_boss_w1.png")
	_save(_boss_core(), "enemy_core.png")
	quit()


func _save(img: Image, name: String) -> void:
	var err := img.save_png(OUT + name)
	print("%s %s" % ["OK " if err == OK else "ERR", OUT + name])


func _img(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


## ¿Está el píxel (x, y) dentro del rombo de una casilla con origen (ox, oy)?
static func _in_diamond(x: int, y: int, ox: int, oy: int) -> bool:
	var dx := absf(x - ox - (TW - 1) * 0.5) / (TW * 0.5)
	var dy := absf(y - oy - (TH - 1) * 0.5) / (TH * 0.5)
	return dx + dy <= 1.0


static func _on_diamond_edge(x: int, y: int, ox: int, oy: int) -> bool:
	if not _in_diamond(x, y, ox, oy):
		return false
	return not (_in_diamond(x - 1, y, ox, oy) and _in_diamond(x + 1, y, ox, oy)
			and _in_diamond(x, y - 1, ox, oy) and _in_diamond(x, y + 1, ox, oy))


# --- Suelo -------------------------------------------------------------------------

## Atlas 4×1: césped A, césped B, césped con flores, camino de baldosas.
func _ground_atlas() -> Image:
	var img := _img(TW * 4, TH)
	_grass_tile(img, 0, Color("58c35a"), false)
	_grass_tile(img, TW, Color("4fb150"), false)
	_grass_tile(img, TW * 2, Color("58c35a"), true)
	_path_tile(img, TW * 3)
	return img


func _grass_tile(img: Image, ox: int, base: Color, flowers: bool) -> void:
	for y in TH:
		for x in range(ox, ox + TW):
			if not _in_diamond(x, y, ox, 0):
				continue
			var c := base
			var n := rng.randf()
			if n < 0.10:
				c = base.lightened(0.18)
			elif n < 0.18:
				c = base.darkened(0.15)
			# Luz arriba-izquierda, sombra abajo-derecha.
			if y < TH * 0.5 and x < ox + TW * 0.5 and _on_diamond_edge(x, y, ox, 0):
				c = base.lightened(0.3)
			elif _on_diamond_edge(x, y, ox, 0):
				c = base.darkened(0.3)
			img.set_pixel(x, y, c)
	if flowers:
		for i in 6:
			var fx := ox + rng.randi_range(18, 45)
			var fy := rng.randi_range(9, 22)
			if _in_diamond(fx, fy, ox, 0):
				var fc: Color = [Color("ffe066"), Color("ff7eb6"), Color.WHITE][i % 3]
				img.set_pixel(fx, fy, fc)
				img.set_pixel(fx, fy + 1, Color("2f7a33"))


func _path_tile(img: Image, ox: int) -> void:
	var brick := Color("e7b765")
	var mortar := Color("a8743a")
	for y in TH:
		for x in range(ox, ox + TW):
			if not _in_diamond(x, y, ox, 0):
				continue
			# Baldosas en coordenadas isométricas locales (u, v).
			var lx := x - ox - TW * 0.5
			var u := (lx / (TW * 0.5) + y / (TH * 0.5)) * 2.0
			var v := (y / (TH * 0.5) - lx / (TW * 0.5)) * 2.0
			var c := brick
			if fposmod(u, 1.0) < 0.12 or fposmod(v + (0.5 if int(floor(u)) % 2 == 0 else 0.0), 1.0) < 0.12:
				c = mortar
			elif rng.randf() < 0.08:
				c = brick.lightened(0.15)
			if _on_diamond_edge(x, y, ox, 0):
				c = mortar.darkened(0.2)
			img.set_pixel(x, y, c)


# --- Decorado --------------------------------------------------------------------

## Cubo isométrico 64×64. El «pie» (centro del rombo de la base) está en (32, 48).
func _block() -> Image:
	var img := _img(64, 64)
	var top := Color("ffb840")
	var left := Color("e08a1e")
	var right := Color("b5650f")
	for x in 64:
		# Borde inferior del rombo superior en esta columna; las caras bajan 32 px.
		var yt := 16.0 + (x if x < 32 else 63 - x) * 0.5
		for y in 64:
			if _in_diamond(x, y, 0, 0):  # cara superior (rombo en y 0..31)
				img.set_pixel(x, y, top)
			elif y >= yt and y < yt + 32.0:
				img.set_pixel(x, y, left if x < 32 else right)
	# Contorno de las caras laterales.
	for y in 64:
		for x in 64:
			var c := img.get_pixel(x, y)
			if c.a > 0 and c != OUTLINE:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = Vector2i(x, y) + d
					if n.x < 0 or n.y < 0 or n.x >= 64 or n.y >= 64 or img.get_pixelv(n).a == 0:
						img.set_pixel(x, y, OUTLINE)
						break
	# Emblema: estrella en la cara izquierda.
	for p in [Vector2i(15, 34), Vector2i(16, 33), Vector2i(16, 34), Vector2i(16, 35), Vector2i(17, 34),
			Vector2i(14, 34), Vector2i(18, 34), Vector2i(16, 32), Vector2i(16, 36)]:
		img.set_pixelv(p, Color("fff4c2"))
	return img


## Arbusto 40×32, pie en (20, 28).
func _bush() -> Image:
	var img := _img(40, 32)
	var greens := [Color("2f8f3a"), Color("3fae48"), Color("6fd66a")]
	for blob in [Vector3(14, 18, 10), Vector3(26, 17, 10), Vector3(20, 11, 10)]:
		for y in 32:
			for x in 40:
				var d := Vector2(x, y).distance_to(Vector2(blob.x, blob.y))
				if d <= blob.z:
					var shade: int = 2 if (y < blob.y - 3 and x < blob.x) else (0 if y > blob.y + 4 else 1)
					img.set_pixel(x, y, greens[shade])
	_outline(img)
	return img


# --- Entidades -------------------------------------------------------------------

## Hoja 4 frames × 32×32 de un enemigo que camina. Pie en (16, 30).
## kind: &"light" (gota), &"armored" (más ancho, con placas), &"fast" (pequeño, con alas).
func _enemy_sheet(body: Color, belly: Color, kind: StringName) -> Image:
	var img := _img(128, 32)
	var rx := 10.0
	var ry := 9.0
	var cy := 18
	if kind == &"armored":
		rx = 12.0
		ry = 10.0
		cy = 17
	elif kind == &"fast":
		rx = 7.0
		ry = 6.0
		cy = 21
	for f in 4:
		var ox := f * 32
		var bob: int = [0, -1, 0, -1][f]
		var step: int = [0, 1, 0, -1][f] * (2 if kind == &"fast" else 1)
		# Patas
		for leg in [-1, 1]:
			var lx: int = ox + 16 + leg * (5 if kind == &"armored" else 4) + (step * leg)
			for y in range(26, 30):
				img.set_pixel(lx, y, OUTLINE)
				img.set_pixel(lx + 1, y, OUTLINE)
		# Alas del rápido (aleteo alterno)
		if kind == &"fast":
			var wy := 14 + bob - (2 if f % 2 == 0 else 0)
			for wx in range(3, 8):
				for side in [ox + 16 - 6 - wx, ox + 16 + 5 + wx]:
					img.set_pixel(side, wy + wx / 3, Color("e8fbff"))
					img.set_pixel(side, wy + wx / 3 + 1, Color("bfefff"))
		# Cuerpo
		var c := Vector2(ox + 16, cy + bob)
		for y in range(0, 30):
			for x in range(ox + 2, ox + 30):
				var e := Vector2((x - c.x) / rx, (y - c.y) / ry)
				if e.length() <= 1.0:
					var col := belly if (e.y > 0.25 and absf(e.x) < 0.5) else body
					if kind == &"armored" and e.y < 0.1 and int(x + y) % 6 == 0:
						col = body.darkened(0.35)  # remaches de las placas
					if kind == &"armored" and e.y < -0.55:
						col = body.lightened(0.25)  # casco
					img.set_pixel(x, y, col)
		# Antena con «píxel suelto» (glitch)
		var top := int(c.y - ry)
		img.set_pixel(ox + 16, top - 1, OUTLINE)
		img.set_pixel(ox + 16, top - 2, OUTLINE)
		img.set_pixel(ox + 17 + (f % 2), top - 4, Color("6ff3ff"))
		# Ojos
		var eye_y := int(c.y) - (2 if kind == &"fast" else 3)
		var eye_dx := 3 if kind == &"fast" else 4
		for ex in [16 - eye_dx, 16 + eye_dx - 1]:
			img.set_pixel(ox + ex, eye_y, Color.WHITE)
			img.set_pixel(ox + ex + 1, eye_y, Color.WHITE)
			img.set_pixel(ox + ex + 1, eye_y + 1, OUTLINE)
			img.set_pixel(ox + ex, eye_y + 1, Color.WHITE)
		if kind == &"armored":  # visera
			for x in range(ox + 10, ox + 23):
				img.set_pixel(x, eye_y - 2, OUTLINE)
	_outline(img)
	return img


## Torre provisional 32×64, pie en (16, 58).
func _tower() -> Image:
	var img := _img(32, 64)
	for y in range(12, 58):
		for x in range(7, 25):
			img.set_pixel(x, y, Color("5b6fd0") if x < 16 else Color("3e4fa3"))
	for y in range(6, 14):
		for x in range(4, 28):
			img.set_pixel(x, y, Color("8fa2ff") if y < 10 else Color("6b7fe0"))
	for y in range(0, 6):
		for x in range(12, 20):
			if Vector2(x, y).distance_to(Vector2(15.5, 3)) < 3.5:
				img.set_pixel(x, y, Color("6ff3ff"))
	for y in range(20, 50, 8):
		for x in range(9, 23):
			img.set_pixel(x, y, Color("2c3a80"))
	_outline(img)
	return img


## Plataforma de construcción 64×32 (anillo en rombo).
func _build_pad() -> Image:
	var img := _img(64, 32)
	for y in 32:
		for x in 64:
			if _in_diamond(x, y, 0, 0):
				var dx := absf(x - 31.5) / 32.0
				var dy := absf(y - 15.5) / 16.0
				var r := dx + dy
				if r > 0.72:
					img.set_pixel(x, y, Color("cfd6ff") if r < 0.86 else Color("5b6fd0"))
				elif r > 0.6:
					img.set_pixel(x, y, Color(1, 1, 1, 0.25))
	return img


func _projectile() -> Image:
	var img := _img(8, 8)
	for y in 8:
		for x in 8:
			var d := Vector2(x, y).distance_to(Vector2(3.5, 3.5))
			if d < 3.6:
				img.set_pixel(x, y, Color.WHITE if d < 1.6 else Color("6ff3ff"))
	return img


## Base de piedra común a las torres (32×64, pie en (16, 58)): zócalo en rombo.
func _tower_base(img: Image, top_y: int, a: Color, b: Color) -> void:
	for y in range(top_y, 58):
		for x in range(6, 26):
			img.set_pixel(x, y, a if x < 16 else b)
	for y in range(52, 60):
		for x in range(3, 29):
			if absf(x - 15.5) / 13.0 + absf(y - 55.5) / 4.5 <= 1.0:
				img.set_pixel(x, y, Color("8a8fa8") if x < 16 else Color("6a6f88"))


## Torre de corrupción: columna magenta coronada por un cubo de píxeles flotante.
func _tower_corrupt() -> Image:
	var img := _img(32, 64)
	_tower_base(img, 22, Color("c03a9a"), Color("8e2273"))
	for y in range(26, 50, 6):
		for x in range(8, 24, 4):
			img.set_pixel(x, y, Color("ff8be0"))
	var pal := [Color("ff5fd2"), Color("6ff3ff"), Color("ffe066"), Color("b18cff")]
	for by in 3:
		for bx in 3:
			var col: Color = pal[(bx + by * 2) % pal.size()]
			for y in 4:
				for x in 4:
					img.set_pixel(10 + bx * 4 + x, 4 + by * 4 + y, col)
	_outline(img)
	return img


## Torre de sellos: atril violeta con un libro abierto y runa dorada.
func _tower_seal() -> Image:
	var img := _img(32, 64)
	_tower_base(img, 30, Color("6a4bc4"), Color("4b3296"))
	for y in range(20, 30):
		for x in range(4, 28):
			var page := Color("fff4dc") if x != 15 and x != 16 else Color("b48a5a")
			if y > 20 + absf(x - 15.5) * 0.25:
				img.set_pixel(x, y, page)
	for x in range(6, 26):
		img.set_pixel(x, 29, Color("5a2d82"))
	for y in range(6, 16):
		for x in range(10, 22):
			var d := Vector2(x, y).distance_to(Vector2(15.5, 10.5))
			if d < 5.5 and d > 3.5:
				img.set_pixel(x, y, Color("ffd34d"))
	img.set_pixel(15, 10, Color("ffd34d"))
	img.set_pixel(16, 11, Color("ffd34d"))
	_outline(img)
	return img


## Torre de rebote: torre turquesa con muelle y bola elástica arriba.
func _tower_bounce() -> Image:
	var img := _img(32, 64)
	_tower_base(img, 34, Color("2bb5a8"), Color("1d867c"))
	for y in range(18, 34):
		var x0 := 11 if (y / 2) % 2 == 0 else 13
		for x in range(x0, x0 + 8):
			img.set_pixel(x, y, Color("cfd6e6"))
	for y in range(2, 18):
		for x in range(8, 24):
			var d := Vector2(x, y).distance_to(Vector2(15.5, 10))
			if d < 7.5:
				img.set_pixel(x, y, Color("ff7a45") if d > 2.5 or y > 10 else Color("ffd0b0"))
	_outline(img)
	return img


func _proj_pixel() -> Image:
	var img := _img(8, 8)
	for y in range(1, 7):
		for x in range(1, 7):
			img.set_pixel(x, y, Color("ff5fd2") if (x + y) % 3 else Color.WHITE)
	_outline(img)
	return img


func _proj_seal() -> Image:
	var img := _img(10, 10)
	for y in 10:
		for x in 10:
			var d := Vector2(x, y).distance_to(Vector2(4.5, 4.5))
			if d < 4.6 and d > 2.4:
				img.set_pixel(x, y, Color("ffd34d"))
			elif d <= 1.2:
				img.set_pixel(x, y, Color("fff4c2"))
	return img


func _proj_ball() -> Image:
	var img := _img(9, 9)
	for y in 9:
		for x in 9:
			var d := Vector2(x, y).distance_to(Vector2(4, 4))
			if d < 4.2:
				img.set_pixel(x, y, Color("ffd0b0") if (x < 4 and y < 4) else Color("ff7a45"))
	_outline(img)
	return img


## Cuerpo base de héroe (hoja 4 × 32×48, pie en (16, 46)): piernas, torso y cabeza.
func _hero_body(img: Image, ox: int, bob: int, coat: Color, coat_dark: Color, skin: Color) -> void:
	for leg in [-1, 1]:  # piernas
		for y in range(36, 46):
			for x in range(ox + 16 + leg * 3 - 1, ox + 16 + leg * 3 + 2):
				img.set_pixel(x, y, Color("2a2440"))
	for y in range(20 + bob, 38):  # torso / abrigo
		var half := 6 + (y - 20) / 5
		for x in range(ox + 16 - half, ox + 16 + half):
			img.set_pixel(x, y, coat if x < ox + 16 else coat_dark)
	for y in range(10 + bob, 20 + bob):  # cabeza
		for x in range(ox + 11, ox + 21):
			if Vector2(x, y).distance_to(Vector2(ox + 15.5, 14.5 + bob)) < 5.2:
				img.set_pixel(x, y, skin)


## Héroe del portal (Nexo, provisional): capucha violeta y guantelete brillante.
func _hero_portal() -> Image:
	var img := _img(128, 48)
	for f in 4:
		var ox := f * 32
		var bob: int = [0, 0, -1, -1][f]
		_hero_body(img, ox, bob, Color("4b3a9e"), Color("33287a"), Color("f2c9a0"))
		for y in range(7 + bob, 15 + bob):  # capucha
			for x in range(ox + 9, ox + 23):
				if Vector2(x, y).distance_to(Vector2(ox + 15.5, 14 + bob)) < 7.0 and 						not Vector2(x, y).distance_to(Vector2(ox + 15.5, 16 + bob)) < 4.6:
					img.set_pixel(x, y, Color("6a56d0"))
		for ex in [13, 18]:  # ojos
			img.set_pixel(ox + ex, 15 + bob, Color("6ff3ff"))
		var glow := Color("6ff3ff") if f % 2 == 0 else Color("b8fbff")
		for y in range(25 + bob, 33 + bob):  # guantelete grande
			for x in range(ox + 22, ox + 29):
				img.set_pixel(x, y, Color("2bb5a8") if (x + y) % 3 else glow)
	_outline(img)
	return img


## Héroe de la espada (Kira Volt, provisional): pelo de punta y hoja de energía.
func _hero_blade() -> Image:
	var img := _img(128, 48)
	for f in 4:
		var ox := f * 32
		var bob: int = [0, 0, -1, -1][f]
		_hero_body(img, ox, bob, Color("d8344f"), Color("a3223a"), Color("f6d2b0"))
		for i in 5:  # pelo blanco en punta
			for y in range(6 + bob - (i % 2) * 2, 12 + bob):
				img.set_pixel(ox + 11 + i * 2, y, Color("f4f4ff"))
				img.set_pixel(ox + 12 + i * 2, y, Color("d9dcff"))
		for ex in [13, 18]:
			img.set_pixel(ox + ex, 15 + bob, Color("1e1830"))
		var blade := Color("ff6fd8") if f % 2 == 0 else Color("ffd0f4")
		for i in 18:  # espada diagonal
			var x := ox + 6 - i / 3
			var y := 34 + bob - i
			if x >= ox and y >= 0:
				img.set_pixel(x + 8, y, blade)
				img.set_pixel(x + 9, y, Color("6ff3ff"))
	_outline(img)
	return img


## Jefe del mundo 1 (provisional): gran gota real con corona, capa y cetro.
## Hoja 4 × 64×64, pie en (32, 60).
func _boss_w1() -> Image:
	var img := _img(256, 64)
	var body := Color("8a3fd1")
	var belly := Color("c79bff")
	var cape := Color("c0283c")
	var gold := Color("ffd34d")
	for f in 4:
		var ox := f * 64
		var bob: int = [0, -1, -2, -1][f]
		var step: int = [0, 2, 0, -2][f]
		for leg in [-1, 1]:  # patas
			for y in range(52, 60):
				for x in range(ox + 32 + leg * 9 + step * leg - 2, ox + 32 + leg * 9 + step * leg + 3):
					img.set_pixel(x, y, OUTLINE)
		for y in range(20, 58):  # capa detrás
			var half := 8 + (y - 20) / 2
			for x in range(ox + 32 - half, ox + 32 + half):
				if y > 30:
					img.set_pixel(x, y, cape if (x + y) % 9 else cape.darkened(0.2))
		var c := Vector2(ox + 32, 36 + bob)
		for y in range(12, 58):  # cuerpo
			for x in range(ox + 8, ox + 56):
				var e := Vector2((x - c.x) / 19.0, (y - c.y) / 17.0)
				if e.length() <= 1.0:
					img.set_pixel(x, y, belly if (e.y > 0.3 and absf(e.x) < 0.45) else body)
		var top := int(c.y - 17)
		for i in 5:  # corona de 5 puntas
			var px := ox + 20 + i * 6
			for y in range(top - 8 + (i % 2) * 3, top + 2):
				for x in range(px, px + 4):
					img.set_pixel(x, y, gold)
			img.set_pixel(px + 1, top - 3, Color("ff5fd2"))
		for x in range(ox + 18, ox + 47):  # banda de la corona
			img.set_pixel(x, top + 1, gold.darkened(0.25))
			img.set_pixel(x, top + 2, gold.darkened(0.25))
		for ex in [25, 37]:  # ojos con ceño
			for y in range(int(c.y) - 6, int(c.y) - 2):
				for x in range(ox + ex, ox + ex + 3):
					img.set_pixel(x, y, Color.WHITE)
			img.set_pixel(ox + ex + 1, int(c.y) - 4, OUTLINE)
			img.set_pixel(ox + ex + 2, int(c.y) - 4, OUTLINE)
		for x in range(ox + 24, ox + 41):
			img.set_pixel(x, int(c.y) - 8 + (1 if x < ox + 32 else 0), OUTLINE)
		for y in range(16 + bob, 50 + bob):  # cetro con moneda de «continue»
			img.set_pixel(ox + 54, y, gold.darkened(0.3))
			img.set_pixel(ox + 55, y, gold.darkened(0.3))
		for y in range(9 + bob, 17 + bob):
			for x in range(ox + 50, ox + 60):
				if Vector2(x, y).distance_to(Vector2(ox + 54.5, 13 + bob)) < 4.6:
					img.set_pixel(x, y, gold if f % 2 == 0 else Color("fff4c2"))
	_outline(img)
	return img


## Núcleo de reaparición (provisional): gema que late. Hoja 4 × 24×24, pie en (12, 22).
func _boss_core() -> Image:
	var img := _img(96, 24)
	for f in 4:
		var ox := f * 24
		var r: float = [6.0, 7.0, 8.0, 7.0][f]
		var glow: Color = [Color("ff5fd2"), Color("ff8be0"), Color("ffd0f4"), Color("ff8be0")][f]
		for y in 24:
			for x in range(ox, ox + 24):
				var d := absf(x - ox - 11.5) / r + absf(y - 13.0) / (r + 2.0)
				if d <= 1.0:
					img.set_pixel(x, y, glow if d > 0.55 else Color("7a1f6a"))
	_outline(img)
	return img


## Contorno de 1 px alrededor de los píxeles opacos.
func _outline(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := img.duplicate()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and src.get_pixelv(n).a > 0 \
						and src.get_pixelv(n) != OUTLINE:
					img.set_pixel(x, y, OUTLINE)
					break
