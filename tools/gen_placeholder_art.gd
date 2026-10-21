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
	_save(_enemy_sheet(), "enemy_glitchling.png")
	_save(_tower(), "tower_basic.png")
	_save(_build_pad(), "build_pad.png")
	_save(_projectile(), "projectile_bit.png")
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
	# Emblema: estrella de «continue» en la cara izquierda.
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

## Hoja 4 frames × 32×32 de un «glitchling» que camina. Pie en (16, 30).
func _enemy_sheet() -> Image:
	var img := _img(128, 32)
	var body := Color("e2475a")
	var belly := Color("ff8f9c")
	for f in 4:
		var ox := f * 32
		var bob: int = [0, -1, 0, -1][f]
		var step: int = [0, 1, 0, -1][f]
		# Patas
		for leg in [-1, 1]:
			var lx: int = ox + 16 + leg * 4 + (step * leg)
			for y in range(26, 30):
				img.set_pixel(lx, y, OUTLINE)
				img.set_pixel(lx + 1, y, OUTLINE)
		# Cuerpo (gota redondeada)
		for y in range(8, 27):
			for x in range(ox + 6, ox + 26):
				var c := Vector2(ox + 16, 18 + bob)
				var e := Vector2((x - c.x) / 10.0, (y - c.y) / 9.0)
				if e.length() <= 1.0:
					img.set_pixel(x, y, belly if (e.y > 0.25 and absf(e.x) < 0.5) else body)
		# Antena con «píxel suelto» (glitch)
		img.set_pixel(ox + 16, 7 + bob, OUTLINE)
		img.set_pixel(ox + 16, 6 + bob, OUTLINE)
		img.set_pixel(ox + 17 + (f % 2), 4 + bob, Color("6ff3ff"))
		# Ojos
		for ex in [12, 19]:
			img.set_pixel(ox + ex, 15 + bob, Color.WHITE)
			img.set_pixel(ox + ex + 1, 15 + bob, Color.WHITE)
			img.set_pixel(ox + ex + 1, 16 + bob, OUTLINE)
			img.set_pixel(ox + ex, 16 + bob, Color.WHITE)
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
