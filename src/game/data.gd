## Datos del juego: salas del Reino del Continue, héroes de las grietas, mejoras y textos.
## Los nombres visibles solo viven aquí; el código usa ids neutros.
class_name Data
extends RefCounted

const T := 32

## Paleta de cada zona: degradado del fondo, piedra, borde iluminado y siluetas.
const PALETTES := {
	"umbral": {"top": Color("10223a"), "bot": Color("060a14"), "stone": Color("1c2a44"), "deep": Color("111a2e"), "rim": Color("6ff3ff"), "far": Color("13233c"), "near": Color("0c1628")},
	"inicio": {"top": Color("123a36"), "bot": Color("05100f"), "stone": Color("1f3a2c"), "deep": Color("12241b"), "rim": Color("5fe39a"), "far": Color("10302a"), "near": Color("0a1f1a")},
	"monedas": {"top": Color("3a2a10"), "bot": Color("0e0904"), "stone": Color("3a2a1a"), "deep": Color("22180e"), "rim": Color("f2c14e"), "far": Color("2a1e0e"), "near": Color("1a1208")},
	"bloque": {"top": Color("44180f"), "bot": Color("100504"), "stone": Color("3c1e16"), "deep": Color("24110c"), "rim": Color("ff7a4a"), "far": Color("2e130c"), "near": Color("1c0b07")},
	"pantalla": {"top": Color("0f2c48"), "bot": Color("040a14"), "stone": Color("1a2c46"), "deep": Color("0f1a2c"), "rim": Color("4fc3f7"), "far": Color("0e2440"), "near": Color("08162a")},
	"kira": {"top": Color("0f3020"), "bot": Color("040c08"), "stone": Color("1a2c22"), "deep": Color("0c1810"), "rim": Color("5fe39a"), "far": Color("0e2618"), "near": Color("081a10")},
	"cine": {"top": Color("2a0a10"), "bot": Color("0a0204"), "stone": Color("3a1418"), "deep": Color("1a080a"), "rim": Color("e65a64"), "far": Color("220a0e"), "near": Color("140608")},
	"neon": {"top": Color("0c1440"), "bot": Color("03050f"), "stone": Color("1a2250"), "deep": Color("0c1028"), "rim": Color("5aa0ff"), "far": Color("0e1638"), "near": Color("080c22")},
	"vertedero": {"top": Color("22280f"), "bot": Color("080a04"), "stone": Color("2e3418"), "deep": Color("14180a"), "rim": Color("aac85a"), "far": Color("1c220c"), "near": Color("101406")},
	"frontera": {"top": Color("0c2c2c"), "bot": Color("030c0c"), "stone": Color("163a3a"), "deep": Color("0a1c1c"), "rim": Color("6eebd2"), "far": Color("0c2626"), "near": Color("061616")},
	"academia": {"top": Color("241a44"), "bot": Color("070512"), "stone": Color("2a2450"), "deep": Color("16122c"), "rim": Color("e0b84a"), "far": Color("1c1638"), "near": Color("110d24")},
	"trono": {"top": Color("4a0c18"), "bot": Color("0b0205"), "stone": Color("2c1018"), "deep": Color("18080c"), "rim": Color("e8384f"), "far": Color("2a0810"), "near": Color("170409")},
}


## Una sala: plano de casillas, objetos, entradas (donde aparece Álex) y salidas por los bordes.
## Casillas: "#" bloque · "=" plataforma que se atraviesa desde abajo · "^" pinchos · "b" bloque que se
## rompe con dos clics · "n" bloque que se rompe y suelta fragmentos · "d" puerta de arena (abierta salvo
## durante el combate) · "p" bloque sin colocar · "y" plataforma de cristal.
class RoomDef extends RefCounted:
	var id: String
	var name: String
	var sub: String
	var w: int
	var h: int
	var pal: String
	var g: Array = []
	var objs: Array = []
	var entries := {}
	## Salidas: {side, to, entry, a, b}. a..b es el tramo del borde (filas o columnas); -1 = todo el borde.
	var exits: Array = []
	## Oleadas de la arena (listas de tipos de enemigo); vacío si la sala no es una arena.
	var waves: Array = []
	## Habilidades que hacen falta para recorrer la sala (para el test de alcance).
	var needs: Array = []
	## Atajo: casillas "a" que solo se rompen desde este lado ("left" o "right") y quedan abiertas para siempre.
	var shortcut_from := ""
	## Si es true, connect_rooms le pone escaleras hasta las puertas altas.
	var auto_climb := false

	func _init(rid: String, rname: String, rsub: String, rw: int, rh: int, rpal: String) -> void:
		id = rid; name = rname; sub = rsub; w = rw; h = rh; pal = rpal
		for y in h:
			var row: Array = []
			row.resize(w)
			row.fill(".")
			g.append(row)

	func fill(x0: int, y0: int, x1: int, y1: int, c: String) -> RoomDef:
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if y >= 0 and y < h and x >= 0 and x < w:
					g[y][x] = c
		return self

	func box() -> RoomDef:
		return fill(0, 0, w - 1, 0, "#").fill(0, 0, 0, h - 1, "#").fill(w - 1, 0, w - 1, h - 1, "#").fill(0, h - 2, w - 1, h - 1, "#")

	func o(type: String, x: int, y: int, text := "") -> RoomDef:
		objs.append({"type": type, "tx": x, "ty": y, "text": text})
		return self

	func e(entry: String, x: int, y: int) -> RoomDef:
		entries[entry] = Vector2i(x, y)
		return self

	func link(side: String, to: String, entry: String, a := -1, b := -1) -> RoomDef:
		exits.append({"side": side, "to": to, "entry": entry, "a": a, "b": b})
		return self

	## Fila de n casillas iguales empezando en (x, y); por defecto, plataforma.
	func p(x: int, y: int, n: int, c := "=") -> RoomDef:
		return fill(x, y, x + n - 1, y, c)

	func auto() -> RoomDef:
		auto_climb = true
		return self

	## Foso de pinchos de n casillas con plataformas para cruzarlo.
	func pit(x: int, n: int) -> RoomDef:
		fill(x, h - 2, x + n - 1, h - 2, "^")
		var i := 1
		while i < n - 1:
			p(x + i, h - 5, 3)
			i += 6
		return self

	func shortcut(x: int, y0: int, y1: int, from_side: String) -> RoomDef:
		shortcut_from = from_side
		return fill(x, y0, x, y1, "a")

	func arena(wave_list: Array) -> RoomDef:
		waves = wave_list
		return self

	func need(ability: String) -> RoomDef:
		needs.append(ability)
		return self

	## Abre un hueco en el borde y lo enlaza: left/right usan filas a..b, up/down columnas a..b.
	func door(side: String, a: int, b: int, to: String, entry: String) -> RoomDef:
		match side:
			"left": fill(0, a, 0, b, ".")
			"right": fill(w - 1, a, w - 1, b, ".")
			"up": fill(a, 0, b, 0, ".")
			"down": fill(a, h - 2, b, h - 1, ".")
		return link(side, to, entry, a, b)


## Cada sala ocupa una o varias pantallas de una cuadrícula: celda (x, y) y tamaño (ancho, alto) en pantallas.
## Las puertas, sus entradas y las repisas junto a ellas salen solas de LINKS, así que siempre encajan.
const CELL_W := 32
const CELL_H := 17
const GRID := {
	"umbral": Vector4i(5, 0, 2, 1),
	"chimenea": Vector4i(6, -1, 1, 1), "mirador": Vector4i(4, -2, 3, 1), "inicio": Vector4i(3, 1, 3, 1),
	"pasarela": Vector4i(0, 1, 3, 1), "monedas": Vector4i(0, -2, 1, 3), "azotea": Vector4i(1, -2, 3, 1),
	"cruce": Vector4i(6, 1, 1, 3), "arena1": Vector4i(7, 1, 2, 1), "bloque": Vector4i(9, 0, 2, 2),
	"pantalla": Vector4i(11, -2, 1, 3), "fuente": Vector4i(9, -1, 2, 1), "puente": Vector4i(7, -1, 2, 1),
	"arena2": Vector4i(12, -2, 2, 1), "trono": Vector4i(14, -2, 2, 1), "sotano": Vector4i(3, 3, 3, 1),
	"cripta": Vector4i(1, 3, 2, 2), "pozo": Vector4i(7, 3, 1, 3),
	"patio": Vector4i(16, -2, 2, 1), "vestibulo": Vector4i(18, -4, 1, 3), "observatorio": Vector4i(16, -4, 2, 1),
	"biblioteca": Vector4i(19, -4, 3, 1), "pasillo": Vector4i(19, -3, 2, 1), "laboratorio": Vector4i(21, -3, 2, 1),
	"torre": Vector4i(22, -6, 1, 3), "antesala": Vector4i(19, -6, 3, 1), "claustro": Vector4i(16, -6, 3, 1),
	"aula": Vector4i(14, -6, 2, 2), "archivo": Vector4i(18, -1, 2, 2),
	"taquilla": Vector4i(12, -6, 2, 1), "cine": Vector4i(9, -6, 3, 1), "camerinos": Vector4i(9, -8, 3, 2),
	"butacas": Vector4i(5, -6, 4, 2), "escalera": Vector4i(5, -4, 1, 2), "montaje": Vector4i(2, -6, 3, 1),
	"escena": Vector4i(2, -5, 2, 2), "cabina": Vector4i(0, -8, 3, 2),
	"neon_azotea": Vector4i(-3, -8, 3, 1), "ascensor": Vector4i(-4, -8, 1, 6), "oficinas": Vector4i(-3, -6, 3, 2),
	"avenida": Vector4i(-10, -5, 6, 1), "metro": Vector4i(-10, -2, 8, 1), "barrio": Vector4i(-6, -1, 4, 3),
	"callejon": Vector4i(-2, 1, 2, 1), "ciudad": Vector4i(-10, -1, 3, 2), "servidor": Vector4i(-6, 2, 3, 2),
	"tolva": Vector4i(-6, 4, 1, 2), "montana": Vector4i(-6, 6, 6, 1), "papelera": Vector4i(0, 6, 6, 2),
	"desague": Vector4i(6, 6, 3, 1), "nota": Vector4i(2, 8, 3, 1), "final": Vector4i(-3, 7, 2, 2),
	"reciclaje": Vector4i(9, 6, 6, 1), "algoritmo": Vector4i(15, 6, 2, 2),
	"arranque": Vector4i(17, 7, 3, 1), "carga": Vector4i(20, 2, 1, 6), "calibracion": Vector4i(21, 2, 3, 1),
	"mezclado": Vector4i(23, -3, 2, 5), "fisura": Vector4i(23, -5, 1, 2), "titulo": Vector4i(25, 0, 2, 2),
	"ascenso": Vector4i(24, -6, 1, 3), "cima": Vector4i(24, -8, 4, 2),
}
## Pares de salas vecinas que se comunican. Si comparten más de un borde, el tercer valor es la celda de la primera.
## Un cuarto valor "atajo" hace la puerta de un solo sentido al principio: la segunda sala la tiene cerrada hasta
## que Álex la cruza una vez desde la primera, y desde entonces queda abierta para siempre.
const LINKS := [
	["umbral", "inicio"], ["umbral", "chimenea"], ["chimenea", "mirador"], ["mirador", "azotea"], ["azotea", "monedas"],
	["monedas", "pasarela"], ["pasarela", "inicio"], ["inicio", "cruce"], ["cruce", "arena1"], ["arena1", "bloque"],
	["bloque", "fuente", Vector2i(10, 0)], ["fuente", "pantalla"], ["bloque", "pantalla"], ["pantalla", "arena2"],
	["arena2", "trono"], ["cruce", "sotano"], ["sotano", "cripta"], ["cruce", "pozo"], ["chimenea", "puente"], ["puente", "fuente"],
	["trono", "patio"], ["patio", "vestibulo"], ["vestibulo", "observatorio"], ["vestibulo", "biblioteca"],
	["vestibulo", "pasillo"], ["pasillo", "laboratorio"], ["laboratorio", "torre"], ["biblioteca", "torre"],
	["torre", "antesala"], ["antesala", "claustro"], ["claustro", "aula"], ["vestibulo", "archivo"],
	# Mundo 3: La Última Sesión
	["aula", "taquilla"], ["taquilla", "cine"], ["cine", "camerinos"], ["cine", "butacas"], ["butacas", "escalera"],
	["escalera", "mirador", null, "atajo"], ["butacas", "montaje"], ["montaje", "escena"], ["montaje", "cabina"],
	# Mundo 4: Neón de Medianoche
	["cabina", "neon_azotea"], ["neon_azotea", "ascensor"], ["ascensor", "oficinas"], ["ascensor", "avenida"],
	["ascensor", "metro"], ["metro", "barrio"], ["metro", "ciudad"], ["barrio", "callejon"],
	["callejon", "pasarela", null, "atajo"], ["barrio", "servidor"],
	# Mundo 5: Vertedero de Ideas
	["servidor", "tolva"], ["tolva", "montana"], ["montana", "papelera"], ["montana", "final"], ["papelera", "nota"],
	["papelera", "desague"], ["desague", "pozo", null, "atajo"], ["desague", "reciclaje"], ["reciclaje", "algoritmo"],
	# Mundo 6: Frontera Imposible
	["algoritmo", "arranque"], ["arranque", "carga"], ["carga", "calibracion"], ["calibracion", "mezclado"],
	["mezclado", "titulo"], ["mezclado", "fisura"], ["fisura", "torre", Vector2i(23, -4), "atajo"],
	["mezclado", "ascenso"], ["ascenso", "cima"],
]
## Salidas que solo se abren al vencer al jefe de la sala en el intento: sala -> [sala de destino, jefe].
const BOSS_GATES := {"trono": ["patio", "B"], "aula": ["taquilla", "E"]}
## Puerta que se cierra durante el combate en cada arena de jefe (la salida hacia esa sala).
const BOSS_DOORS := {"trono": "arena2", "aula": "claustro"}
const MAP_LABELS := [{"name": "Reino del
Continue", "at": Vector2(36, -12)}, {"name": "Academia del
Último Hechizo", "at": Vector2(400, 10)},
	{"name": "La Última Sesión", "at": Vector2(100, -118)}, {"name": "Neón de Medianoche", "at": Vector2(-316, -124)},
	{"name": "Vertedero
de Ideas", "at": Vector2(-310, 100)}, {"name": "Frontera Imposible", "at": Vector2(680, 100)}]
static var MAP_ROOMS: Dictionary = _map_rooms()
## Rectángulo de todo el mapa en casillas, con un margen.
static var MAP_BOUNDS: Rect2 = _map_bounds()


static func _map_bounds() -> Rect2:
	var bounds := Rect2()
	for id: String in GRID:
		var g: Vector4i = GRID[id]
		var r := Rect2(g.x * CELL_W, g.y * CELL_H, g.z * CELL_W, g.w * CELL_H)
		bounds = r if bounds.size == Vector2.ZERO else bounds.merge(r)
	return bounds.grow(6)


## Esquina de cada sala en el mapa, en casillas.
static func _map_rooms() -> Dictionary:
	var rooms := {}
	for id: String in GRID:
		rooms[id] = Vector2i(GRID[id].x * CELL_W, GRID[id].y * CELL_H)
	return rooms


## Sala del tamaño de sus celdas, ya cerrada por los bordes.
static func cell_room(id: String, rname: String, rsub: String, pal: String) -> RoomDef:
	var g: Vector4i = GRID[id]
	return RoomDef.new(id, rname, rsub, g.z * CELL_W, g.w * CELL_H, pal).box()


## Abre las puertas de LINKS en las dos salas y crea su entrada al otro lado.
static func connect_rooms(rooms: Dictionary) -> void:
	for link: Array in LINKS:
		var a: String = link[0]
		var b: String = link[1]
		var ga: Vector4i = GRID[a]
		var gb: Vector4i = GRID[b]
		var pick := []
		for i in ga.z:
			for j in ga.w:
				var c := Vector2i(ga.x + i, ga.y + j)
				for dir: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
					var n := c + dir
					if n.x >= gb.x and n.x < gb.x + gb.z and n.y >= gb.y and n.y < gb.y + gb.w:
						if pick.is_empty() or (link.size() > 2 and link[2] != null and c == link[2]):
							pick = [c, dir]
		assert(not pick.is_empty(), "%s y %s no son vecinas" % [a, b])
		_open_door(rooms[a], ga, pick[0], pick[1], b)
		_open_door(rooms[b], gb, pick[0] + pick[1], -pick[1], a)
		if link.size() > 3 and link[3] == "atajo":
			var key := "%s>%s" % [a, b]
			rooms[a].exits.back()["opens"] = key
			rooms[b].exits.back()["shortcut"] = key
	for id: String in rooms:
		if rooms[id].auto_climb:
			_auto_climb(rooms[id])


## Escaleras de plataformas (de tres en tres casillas, sin salto doble) desde el suelo hasta cada puerta alta.
static func _auto_climb(r: RoomDef) -> void:
	var floor_stand := r.h - 3
	for ex: Dictionary in r.exits:
		var target: int
		var xs: Array
		match ex["side"]:
			"left":
				target = ex["b"]
				xs = [6, 10]
			"right":
				target = ex["b"]
				xs = [r.w - 10, r.w - 14]
			"up":
				target = 0
				xs = [ex["a"], ex["a"] + 4 if ex["a"] + 8 < r.w - 1 else ex["a"] - 4]
			_:
				continue
		if target >= floor_stand:
			continue
		var stands: Array = []
		var s := floor_stand - 3
		while true:
			stands.append(s)
			if s - target <= 3 and (ex["side"] != "up" or s <= 3):
				break
			s -= 3
		for i in stands.size():
			var x: int = xs[(stands.size() - 1 - i) % 2]
			r.p(x, stands[i] + 1, 4)


static func _open_door(r: RoomDef, g: Vector4i, cell: Vector2i, dir: Vector2i, other: String) -> void:
	var local := cell - Vector2i(g.x, g.y)
	var row := local.y * CELL_H + 12
	var col := local.x * CELL_W + 14
	var low := local.y == g.w - 1
	match dir:
		Vector2i.LEFT:
			r.door("left", row, row + 2, other, r.id).e(other, 1, row + 2)
			if not low:
				r.fill(1, row + 3, 5, row + 3, "#")
			if not r.waves.is_empty():
				r.fill(1, row, 1, row + 2, "d")
		Vector2i.RIGHT:
			r.door("right", row, row + 2, other, r.id).e(other, r.w - 2, row + 2)
			if not low:
				r.fill(r.w - 6, row + 3, r.w - 2, row + 3, "#")
			if not r.waves.is_empty():
				r.fill(r.w - 2, row, r.w - 2, row + 2, "d")
		Vector2i.UP:
			r.door("up", col, col + 3, other, r.id).e(other, col + 1, 1)
			if not r.waves.is_empty():
				r.fill(col, 1, col + 3, 1, "d")
		Vector2i.DOWN:
			r.door("down", col, col + 3, other, r.id).e(other, col - 2, r.h - 3)


## Crea las salas (cada partida tiene su copia, porque la arena del jefe cambia el plano).
static func build_rooms() -> Dictionary:
	var list := [
		# --- El Umbral: el centro de todo. Abajo, el Reino; arriba (con salto doble), la Chimenea. ---
		cell_room("umbral", "Umbral de Nexo", "Donde se cruzan las grietas", "umbral")
			.p(38, 12, 5).p(45, 7, 6)
			.e("P", 24, 14).o("O", 30, 14).o("H", 36, 14).o("M", 42, 14)
			.o("L", 6, 14, "Registro de Zerik #001: el Umbral no aparece en ningún mapa del Reino. Conclusión: lo trajo Nexo consigo."),

		# --- Mundo 1: Reino del Continue ---
		# Tutorial: fosos, un muro agrietado, núcleos, la primera grieta. Kira espera bajo el Umbral.
		cell_room("inicio", "Pantalla de Inicio", "Pulsa START. Otra vez.", "inicio")
			.p(74, 12, 6).p(80, 9, 6).p(74, 6, 6).p(77, 3, 6)
			.p(50, 15, 3, "^").fill(40, 13, 44, 14, "#").p(34, 11, 5).fill(28, 12, 28, 12, "n")
			.fill(20, 12, 20, 14, "b").p(10, 15, 3, "^")
			.o("K", 68, 14, "1").o("F", 36, 10)
			.o("L", 60, 14, "Registro de Zerik #014: los rastreros dejan un núcleo al caer. Si el núcleo sobrevive, el rastrero vuelve. Recomendación: romper el núcleo. Rápido.")
			.o("L", 24, 14, "Registro de Zerik #015: este muro está agrietado. Diagnóstico: dos clics. Algunos bloques guardan fragmentos dentro.")
			.o("c", 56, 14).o("c", 42, 12).o("s", 30, 14).o("c", 14, 14),
		# Plataformas sobre un suelo de pinchos. A la izquierda se sube a la Torre de las Monedas.
		cell_room("pasarela", "Pasarela de los Escupidores", "No mires abajo", "inicio")
			.p(22, 15, 67, "^")
			.p(2, 12, 5).p(8, 9, 5).p(13, 6, 5).p(12, 3, 6)
			.p(24, 12, 4).p(32, 12, 4).p(40, 12, 4).p(48, 12, 4).p(56, 12, 4).p(64, 12, 4).p(72, 12, 4).p(80, 12, 4)
			.fill(44, 6, 46, 7, "#").fill(68, 6, 70, 7, "#")
			.o("s", 45, 5).o("s", 69, 5).o("f", 52, 5).o("f", 76, 6).o("c", 6, 14).o("g", 15, 2)
			.o("L", 92, 14, "Registro de Zerik #016: los escupidores apuntan a donde estás, no a donde vas. Diagnóstico: no te quedes quieto."),
		# Torre con el orbe de salto doble arriba. Se sube sin él; arriba a la derecha sigue la Azotea.
		cell_room("monedas", "Torre de las Monedas", "Lo que cae, se recoge", "monedas")
			.p(6, 46, 6).p(14, 43, 6).p(6, 40, 6).p(14, 37, 6).p(6, 34, 6).p(14, 31, 6).p(6, 28, 6).p(14, 25, 6)
			.p(6, 22, 6).p(14, 19, 6).p(20, 16, 6).p(12, 13, 6).p(4, 10, 6)
			.o("A", 6, 9).o("c", 24, 48).o("f", 20, 34).o("f", 8, 20).o("s", 20, 42)
			.o("L", 26, 48, "Registro de Zerik #027: hay un orbe en lo más alto de esta torre. Demasiado alto para llegar sin querer. ¿Error de diseño o premio?"),
		cell_room("azotea", "Azotea Dorada", "Por encima del Reino", "monedas")
			.p(16, 15, 4, "^").p(40, 15, 4, "^").p(70, 15, 4, "^").p(24, 9, 6).fill(52, 12, 52, 12, "n")
			.o("g", 26, 8).o("C", 34, 14).o("f", 60, 6).o("F", 80, 14).o("c", 64, 14)
			.o("L", 6, 14, "Registro de Zerik #022: desde aquí arriba se ve todo el Reino. Desde abajo, nadie mira hacia aquí."),
		# Por encima del Umbral: se ve el camino al trono. Al fondo baja la Chimenea.
		cell_room("mirador", "Mirador del Reino", "El trono parece cerca", "monedas")
			.p(30, 11, 6).p(44, 8, 6).p(58, 11, 5).p(46, 5, 4)
			.o("g", 47, 7).o("F", 20, 14).o("f", 56, 5).o("s", 66, 14).o("c", 40, 14)
			.o("L", 70, 14, "Registro de Zerik #024: desde el Mirador se ve el trono. Parece cerca. No lo está."),
		cell_room("chimenea", "Chimenea", "Entre el Umbral y el cielo", "umbral")
			.p(22, 12, 5).p(18, 9, 5).p(12, 6, 8).p(13, 3, 6)
			.o("f", 8, 4),
		# Un muro al oeste que solo se rompe desde aquí: atajo a la Chimenea, abierto para siempre.
		cell_room("puente", "Puente Colgante", "Un atajo con mal carácter", "monedas")
			.shortcut(4, 12, 14, "right")
			.p(20, 15, 24, "^").p(22, 12, 4).p(30, 12, 4).p(38, 12, 4).p(28, 7, 5)
			.o("g", 30, 6).o("C", 50, 14).o("f", 36, 4)
			.o("L", 58, 14, "Registro de Zerik #031: hay un muro al oeste que solo se abre desde este lado. Diagnóstico: un atajo. O una puerta con mal carácter."),
		# Descanso: la fuente cura una vez por intento. El suelo se abre hacia el Bloque Sorpresa.
		cell_room("fuente", "Fuente del Guardado", "Un respiro antes del final", "monedas")
			.o("h", 24, 14).o("F", 12, 14)
			.o("L", 36, 14, "Registro de Zerik #045: una fuente que restaura. No sé quién la programó. Diagnóstico: alguien quería que llegaras al final."),
		# Cruce vertical: arriba se cruza de Inicio a la arena; abajo, el Sótano y el Pozo.
		cell_room("cruce", "Cruce del Reino", "Cuatro caminos, una partida", "monedas")
			.p(6, 16, 7).p(19, 16, 7)
			.p(8, 46, 5).p(15, 43, 5).p(8, 40, 5).p(15, 37, 5).p(8, 34, 5).p(15, 31, 5).p(8, 28, 5).p(15, 25, 5)
			.p(8, 22, 5).p(15, 19, 5)
			.o("c", 10, 48).o("f", 8, 30).o("f", 24, 22).o("s", 20, 30)
			.o("L", 16, 48, "Registro de Zerik #019: este cruce tiene cuatro salidas. Arriba, a los lados, abajo... Todas llevan a algún sitio. Casi seguro."),
		cell_room("arena1", "Arena de los Rastreros", "Nadie sale hasta que acabe", "inicio")
			.arena([["c", "c", "c"], ["c", "f", "f", "s"], ["C", "c", "f", "f"]])
			.p(14, 11, 5).p(44, 11, 5)
			.o("x", 32, 14).o("z", 8, 13).o("z", 32, 9).o("z", 56, 13).o("z", 16, 10).o("z", 46, 10),
		# Muros rompibles abajo; la parte de arriba (hacia la Fuente y la Doble Pantalla) pide salto doble.
		cell_room("bloque", "Bloque Sorpresa", "Todo vuelve a su sitio", "bloque")
			.p(40, 27, 6).p(50, 22, 6).p(42, 17, 6).p(50, 12, 6).p(45, 7, 6)
			.fill(20, 29, 20, 31, "b").p(28, 32, 4, "^").fill(34, 28, 34, 28, "n")
			.o("F", 14, 31).o("c", 10, 31).o("c", 24, 31).o("c", 36, 31).o("s", 42, 26).o("f", 30, 20).o("f", 56, 4)
			.o("L", 6, 31, "Registro de Zerik #033: aquí todo se rompe y luego vuelve. Todo. He tenido que crear una categoría nueva en el manual: «todo»."),
		cell_room("pantalla", "Doble Pantalla", "Arriba hay más partida", "pantalla")
			.p(8, 44, 6).p(16, 39, 6).p(6, 34, 6).p(12, 28, 6).p(20, 23, 6).p(20, 18, 6)
			.o("f", 8, 24).o("f", 24, 30).o("s", 22, 22).o("V", 16, 8)
			.o("L", 20, 48, "Registro de Zerik #041: plataformas a cinco casillas de altura. Con un salto normal, imposible. Con salto doble, probable.")
			.need("wings"),
		cell_room("arena2", "Arena de Élites", "Los mejores del Reino", "trono")
			.arena([["C", "f", "s"], ["V", "c", "c", "Z"], ["C", "C", "V", "f"]])
			.p(10, 11, 5).p(26, 8, 10).p(48, 11, 5)
			.o("x", 32, 14).o("z", 12, 10).o("z", 30, 7).o("z", 50, 10).o("z", 6, 13).o("z", 58, 13),
		# La puerta derecha lleva a la Academia y solo se abre al vencer al Rey en el intento.
		cell_room("trono", "Trono del Reinicio", "Donde el Rey pulsa CONTINUE", "trono")
			.p(12, 11, 5).p(44, 11, 5).o("B", 46, 14),
		# Opcional, bajo el Cruce: fragmentos, una grieta y un élite. Al oeste, la Cripta.
		cell_room("sotano", "Sótano de las Partidas", "Donde se guardan las que nadie terminó", "bloque")
			.p(20, 15, 4, "^").p(52, 15, 4, "^").p(30, 12, 5).p(44, 9, 6).p(60, 11, 5).p(66, 8, 5).fill(48, 12, 48, 12, "n")
			.o("g", 46, 8).o("g", 68, 7).o("F", 36, 14).o("C", 26, 14).o("c", 66, 14).o("f", 40, 5).o("f", 70, 4).o("s", 62, 10)
			.o("L", 86, 14, "Registro de Zerik #037: partidas guardadas a medias. Cientos. Todas con el mismo nombre de usuario: dev_01."),
		# Al fondo, tras un muro falso ("w"), el portal al Nivel 1-1 de Kira.
		cell_room("cripta", "Cripta de los Borrados", "Partidas que nadie recuerda", "bloque")
			.p(40, 28, 6).p(48, 25, 6).p(40, 22, 6).p(48, 19, 6).p(53, 16, 5)
			.fill(1, 1, 7, 28, "#").fill(7, 29, 7, 31, "w")
			.e("K", 4, 31).o("T", 2, 31, "1").o("g", 5, 31).o("g", 20, 31)
			.o("c", 30, 31).o("f", 30, 10).o("s", 42, 27)
			.o("L", 14, 31, "Registro de Zerik #038: una cripta para partidas borradas. Algo suena detrás de la pared del oeste."),
		cell_room("pozo", "Pozo sin Fondo", "Sí tiene fondo", "bloque")
			.p(6, 16, 6).p(14, 19, 6).p(6, 22, 6).p(14, 25, 6).p(6, 28, 6).p(14, 31, 6).p(6, 34, 6).p(14, 37, 6)
			.p(6, 40, 6).p(14, 43, 6).p(6, 46, 6)
			.o("g", 20, 48).o("f", 10, 30).o("f", 22, 20)
			.o("L", 24, 48, "Registro de Zerik #040: el pozo sigue hacia abajo. Alguien tapió el fondo. Por dentro."),
		# Primer trozo del juego de Kira: su nivel 1-1, que Álex nunca terminó. "p" = bloque sin colocar
		# (no se pisa hasta que Álex lo coloca con un clic). Se reconstruye cada vez que se entra.
		RoomDef.new("kira1", "Nivel 1-1 de Kira", "El tutorial que nunca se probó", 48, 18, "kira").box()
			.fill(0, 13, 0, 15, ".")
			.fill(10, 16, 19, 16, ".").fill(10, 17, 19, 17, "^").fill(10, 16, 19, 16, "p")
			.fill(26, 11, 28, 15, "#").fill(22, 13, 24, 13, "p")
			.e("1", 1, 15)
			.o("S", 3, 15, "TUTORIAL 1-1")
			.o("S", 8, 15, "TODO: colocar el puente")
			.o("S", 21, 15, "TODO: escalón")
			.o("S", 39, 15, "TODO: escribir el final del nivel")
			.o("c", 34, 15).o("f", 31, 6).o("G", 44, 15)
			.link("left", "cripta", "K"),

		# --- Mundo 2: Academia del Último Hechizo ---
		# "R" cristal que resuena al golpearlo; "y" plataforma de cristal: solo se pisa mientras Álex resuena.
		cell_room("patio", "Patio de la Academia", "Donde nadie se gradúa", "academia")
			.fill(16, 12, 18, 12, "y").fill(20, 9, 26, 9, "#").fill(56, 12, 56, 14, "b")
			.o("R", 13, 14).o("F", 23, 8).o("c", 30, 14).o("k", 36, 11).o("c", 44, 14)
			.o("L", 6, 14, "Registro de Zerik #052: los cristales vibran al golpearlos. Mientras vibran, algunas plataformas existen. Mi manual no tiene una categoría para «existir a ratos»."),
		# Vestíbulo vertical con cinco salidas; dos tramos de la subida son de cristal.
		cell_room("vestibulo", "Vestíbulo de los Ecos", "Cada paso suena dos veces", "academia")
			.p(18, 46, 6).p(6, 43, 6).fill(18, 40, 23, 40, "y").p(6, 37, 6).p(18, 34, 6).p(6, 31, 6)
			.fill(18, 28, 23, 28, "y").p(6, 25, 6).p(18, 22, 6).p(6, 19, 6).p(6, 16, 6).p(16, 16, 6)
			.o("R", 6, 48).o("R", 8, 30).o("c", 10, 48).o("k", 10, 14).o("f", 24, 26).o("s", 20, 33)
			.o("L", 26, 48, "Registro de Zerik #055: el Vestíbulo repite cada sonido. También los errores. Sobre todo los errores."),
		# Opcional: plataformas de cristal, fragmentos y, tras un muro falso, el portal a la Técnica de Kira.
		cell_room("observatorio", "Observatorio", "Donde se miraban las notas", "academia")
			.fill(1, 1, 6, 11, "#").fill(6, 12, 6, 14, "w")
			.fill(20, 12, 23, 12, "y").fill(26, 9, 29, 9, "y").p(32, 6, 6).fill(44, 10, 44, 10, "n")
			.e("K", 3, 14).o("T", 2, 14, "2")
			.o("R", 16, 14).o("g", 34, 5).o("F", 48, 14).o("Q", 36, 11).o("f", 26, 4)
			.o("L", 56, 14, "Registro de Zerik #060: un telescopio que apunta hacia dentro. Desde aquí se ve todo el Reino del Continue. Parece pequeño."),
		cell_room("biblioteca", "Biblioteca Flotante", "Libros que nadie terminó de leer", "academia")
			.fill(14, 12, 17, 12, "y").p(22, 10, 5).fill(30, 8, 33, 8, "y").p(38, 6, 6).fill(46, 9, 49, 9, "y")
			.fill(60, 12, 60, 12, "n")
			.o("R", 10, 14).o("R", 24, 9).o("R", 40, 5).o("F", 42, 5)
			.o("k", 28, 10).o("f", 50, 4).o("s", 70, 14).o("c", 56, 14).o("C", 80, 14)
			.o("L", 6, 14, "Registro de Zerik #058: la Biblioteca flota porque nadie terminó de diseñar el suelo. Hipótesis: aquí estudiaba dev_01."),
		cell_room("pasillo", "Pasillo de las Runas", "Aquí se suspendía", "academia")
			.fill(44, 11, 50, 14, "#")
			.o("W", 47, 10).o("c", 20, 14).o("k", 28, 10).o("s", 36, 14).o("f", 40, 5)
			.o("L", 58, 14, "Registro de Zerik #063: hay marcas en las paredes de la Torre del Examen. Alguien subía rebotando de pared en pared."),
		# Arena de conjuradores. Arriba se abre la Torre del Examen.
		cell_room("laboratorio", "Laboratorio de Alquimia", "Mezclas que no salieron bien", "academia")
			.arena([["k", "c", "c"], ["k", "k", "f", "s"], ["Q", "C", "f", "f"]])
			.p(36, 11, 5).p(44, 6, 6).fill(20, 8, 27, 8, "y").p(8, 11, 5)
			.o("R", 24, 14).o("x", 32, 14).o("z", 10, 10).o("z", 24, 6).o("z", 52, 13).o("z", 6, 13).o("z", 30, 13),
		# Un pozo estrecho sin escalones: solo se sube con salto en pared. Abajo, el hueco al Laboratorio.
		cell_room("torre", "Torre del Examen", "Arriba está la nota", "academia")
			.fill(1, 16, 21, 40, "#").fill(26, 16, 30, 40, "#").p(4, 45, 5).p(22, 45, 4)
			.o("f", 10, 44).o("V", 16, 8).o("f", 8, 6)
			.o("L", 28, 15, "Registro de Zerik #070: la Torre del Examen no tiene escaleras. Diagnóstico: el examen es subir.")
			.need("walljump"),
		cell_room("antesala", "Antesala del Examen", "Repasa por última vez", "academia")
			.p(70, 9, 5)
			.o("h", 48, 14).o("F", 36, 14).o("g", 72, 8)
			.o("L", 60, 14, "Registro de Zerik #072: alguien dejó apuntes en la mesa. Letra de dev_01. Dicen: «Esta vez sí lo termino»."),
		cell_room("claustro", "Claustro de los Repetidores", "Los que nunca pasaron de curso", "academia")
			.arena([["Q", "C", "f"], ["V", "k", "Z", "c"], ["Q", "Q", "V", "C"]])
			.p(14, 11, 5).p(40, 8, 12).p(76, 11, 5)
			.o("x", 48, 14).o("z", 16, 10).o("z", 46, 7).o("z", 78, 10).o("z", 8, 13).o("z", 88, 13),
		# El jefe espera abajo: se entra dejándose caer desde la repisa.
		cell_room("aula", "Aula Magna", "El examen final", "academia").auto()
			.p(50, 28, 5).p(56, 25, 5).p(50, 22, 5).p(56, 19, 5).p(52, 16, 5).p(8, 27, 6)
			.o("E", 24, 31),

		# --- Mundo 3: La Última Sesión (el cine de la game jam) ---
		# Las subidas hasta las puertas altas las pone .auto(). Los jefes de los mundos 3 a 6 aún no existen.
		cell_room("taquilla", "Taquilla", "Entradas agotadas desde 2019", "cine").auto()
			.p(24, 11, 6)
			.o("c", 20, 14).o("f", 40, 6)
			.o("L", 54, 14, "Registro de Zerik #080: un cine dentro de un juego dentro de un juego. Las entradas dicen «sesión única». Dicen eso todas las noches."),
		cell_room("cine", "Vestíbulo del Cine", "Huele a palomitas de 2019", "cine").auto()
			.pit(40, 12).p(70, 9, 6)
			.o("h", 80, 14).o("g", 72, 8).o("s", 30, 14).o("f", 56, 5).o("c", 64, 14)
			.o("L", 88, 14, "Registro de Zerik #081: una fuente en un cine. Error de categoría. La he dejado: aquí todo el mundo necesita un respiro."),
		cell_room("camerinos", "Camerinos", "Los actores esperan su escena", "cine").auto()
			.p(40, 26, 6).p(48, 22, 6).p(56, 18, 6)
			.o("g", 58, 17).o("k", 50, 20).o("c", 60, 31).o("Q", 30, 31)
			.o("L", 88, 31, "Registro de Zerik #082: personajes con el guion en la mano. Ninguno sale en la versión final."),
		cell_room("butacas", "Patio de Butacas", "Fila 7, butaca 13", "cine").auto()
			.pit(40, 24).pit(80, 18).p(60, 22, 8).p(100, 24, 6)
			.o("c", 30, 31).o("C", 104, 31).o("f", 50, 18).o("f", 90, 14).o("s", 62, 21)
			.o("L", 116, 31, "Registro de Zerik #083: la película se corta a la mitad cada noche. El público aplaude igual."),
		cell_room("escalera", "Escalera de Incendios", "Solo se abre por dentro", "cine").auto()
			.o("f", 16, 10)
			.o("L", 24, 31, "Registro de Zerik #084: la salida de incendios da al Mirador del Reino. Por fuera no tiene picaporte."),
		cell_room("montaje", "Sala de Montaje", "Aquí se cortó lo importante", "cine").auto()
			.pit(48, 12).p(70, 9, 5)
			.o("g", 72, 8).o("k", 36, 10).o("s", 80, 14).o("c", 26, 14)
			.o("L", 6, 14, "Registro de Zerik #085: metros de película en el suelo. Escenas cortadas para llegar a tiempo a la entrega."),
		# Aquí irá el tercer trozo del juego de Kira: la escena de su pasado.
		cell_room("escena", "Escena Cortada", "Nunca llegó a rodarse", "kira").auto()
			.p(36, 26, 6).p(46, 22, 6)
			.o("g", 48, 21).o("f", 30, 12)
			.o("S", 40, 31, "ESCENA 12: KIRA (sin escribir)"),
		cell_room("cabina", "Cabina de Proyección", "Donde se decide qué se ve", "cine").auto()
			.p(20, 26, 8).p(60, 26, 8)
			.o("S", 46, 31, "PROYECCIONISTA: en construcción")
			.o("L", 10, 31, "Registro de Zerik #086: el proyector sigue encendido. Nadie lo maneja. Todavía."),

		# --- Mundo 4: Neón de Medianoche (la ciudad del gran estudio) ---
		cell_room("neon_azotea", "Azotea de Neón", "Los carteles no anuncian nada", "neon").auto()
			.pit(30, 12).p(60, 9, 6)
			.o("g", 62, 8).o("V", 50, 5).o("s", 70, 14)
			.o("L", 84, 14, "Registro de Zerik #090: carteles luminosos con eslóganes sin terminar. «Más rápido, más…». Nadie recuerda qué venía después."),
		cell_room("ascensor", "Hueco del Ascensor", "Fuera de servicio", "neon").auto()
			.o("f", 16, 80).o("f", 16, 40).o("Z", 12, 99)
			.o("L", 24, 99, "Registro de Zerik #091: el ascensor sube y baja solo. Planta 404 no existe. Lo he comprobado tres veces."),
		cell_room("oficinas", "Oficinas", "Tareas sin dueño", "neon").auto()
			.arena([["c", "c", "s"], ["k", "f", "c", "c"], ["C", "Z", "f", "k"]])
			.p(30, 26, 6).p(60, 26, 6)
			.o("x", 48, 31).o("z", 20, 30).o("z", 48, 24).o("z", 76, 30).o("z", 32, 25).o("z", 62, 25),
		cell_room("avenida", "Avenida Principal", "Optimizada para nadie", "neon").auto()
			.pit(40, 18).pit(110, 18).p(80, 9, 8).p(150, 10, 6)
			.o("g", 83, 8).o("c", 30, 14).o("c", 100, 14).o("s", 140, 14).o("f", 70, 5).o("f", 170, 6).o("C", 160, 14)
			.o("L", 10, 14, "Registro de Zerik #092: semáforos que cambian sin coches. Pasos de cebra sin peatones. Muy eficiente."),
		cell_room("metro", "Metro de Medianoche", "Próximo tren: nunca", "neon").auto()
			.pit(60, 24).pit(170, 24).p(110, 9, 8).p(230, 10, 6)
			.o("g", 113, 8).o("c", 40, 14).o("c", 100, 14).o("s", 150, 14).o("f", 130, 5).o("k", 200, 10).o("C", 220, 14)
			.o("L", 246, 14, "Registro de Zerik #093: el metro recorre la ciudad entera. Las estaciones tienen nombres de tareas pendientes."),
		cell_room("barrio", "Barrio Dormitorio", "Todos duermen a la misma hora", "neon").auto()
			.p(50, 45, 8).p(58, 40, 8).p(50, 35, 8).p(58, 30, 8).p(50, 25, 8)
			.o("h", 100, 48).o("g", 53, 24).o("c", 40, 48).o("f", 80, 20).o("s", 60, 39).o("k", 30, 30)
			.o("L", 116, 48, "Registro de Zerik #094: los habitantes repiten la misma rutina. Sin código detrás. Solo la rutina."),
		cell_room("callejon", "Callejón", "Sale a la Pasarela del Reino", "neon").auto()
			.o("c", 30, 14).o("f", 40, 6)
			.o("L", 8, 14, "Registro de Zerik #095: esta salida da al Reino del Continue. Por el otro lado no tiene puerta."),
		# Aquí irá el cuarto trozo del juego de Kira: su ciudad, sin habitantes programados.
		cell_room("ciudad", "Ciudad sin Programar", "Calles sin nadie", "kira").auto()
			.p(40, 26, 6).p(50, 22, 6)
			.o("g", 52, 21).o("f", 70, 10)
			.o("S", 50, 31, "CIUDAD DE KIRA: habitantes pendientes"),
		cell_room("servidor", "Sala del Servidor", "El que administra todo", "neon").auto()
			.p(20, 26, 8).p(68, 26, 8)
			.o("S", 46, 31, "ADMINISTRADOR: en construcción")
			.o("L", 84, 31, "Registro de Zerik #096: un servidor que se administra a sí mismo. Hace tiempo que nadie le pregunta para qué."),

		# --- Mundo 5: Vertedero de Ideas (la carpeta de ideas descartadas) ---
		cell_room("tolva", "Tolva", "Por aquí caen las ideas", "vertedero").auto()
			.o("f", 16, 12).o("c", 8, 31),
		cell_room("montana", "Montaña de Archivos", "Ideas apiladas sin ordenar", "vertedero").auto()
			.pit(30, 18).pit(130, 18).p(70, 9, 8).p(160, 10, 6)
			.o("g", 73, 8).o("c", 20, 14).o("c", 90, 14).o("s", 120, 14).o("f", 60, 5).o("Z", 170, 14)
			.o("L", 6, 14, "Registro de Zerik #100: carpetas con nombres como «juego_definitivo_v2_ESTE». Ninguna se abrió dos veces."),
		cell_room("papelera", "Papelera", "Vaciar al salir", "vertedero").auto()
			.pit(40, 24).pit(130, 24).p(70, 27, 8).p(80, 23, 8).p(160, 22, 6)
			.o("h", 180, 31).o("g", 83, 22).o("c", 30, 31).o("c", 90, 31).o("k", 110, 16).o("s", 72, 26).o("C", 150, 31)
			.o("L", 6, 31, "Registro de Zerik #101: todo lo que se borró acaba aquí. No se borra del todo nunca."),
		cell_room("desague", "Desagüe", "Sube hasta el Pozo del Reino", "vertedero").auto()
			.pit(56, 12)
			.o("c", 30, 14).o("f", 70, 6)
			.o("L", 84, 14, "Registro de Zerik #102: un desagüe que sube. Por arriba da al Pozo del Reino, que alguien tapió por dentro."),
		cell_room("nota", "Nota Descartada", "La que nadie quiso leer", "vertedero").auto()
			.o("c", 60, 14)
			.o("L", 40, 14, "Nota de diseño de dev_01, descartada: «AVISO: la máquina no aguanta una sincronización total. Si se fuerza, los juegos se fusionan.»"),
		# Aquí irá el quinto trozo del juego de Kira: su final, nunca escrito.
		cell_room("final", "Final sin Escribir", "THE END (pendiente)", "kira").auto()
			.p(36, 26, 6).p(46, 22, 6)
			.o("g", 48, 21).o("f", 30, 12)
			.o("S", 40, 31, "FINAL DE KIRA: TODO"),
		cell_room("reciclaje", "Planta de Reciclaje", "Lo viejo vuelve con otro nombre", "vertedero").auto()
			.arena([["c", "c", "f"], ["s", "Z", "c", "k"], ["C", "C", "Z", "V"]])
			.p(40, 11, 6).p(90, 9, 10).p(146, 11, 6)
			.o("x", 96, 14).o("z", 30, 13).o("z", 96, 7).o("z", 160, 13).o("z", 42, 10).o("z", 148, 10),
		cell_room("algoritmo", "Núcleo del Algoritmo", "Decide qué ideas sirven", "vertedero").auto()
			.p(10, 26, 8)
			.o("S", 34, 31, "ALGORITMO: en construcción")
			.o("L", 20, 31, "Registro de Zerik #103: aquí se puntúan las ideas. Las que suspenden bajan a la Papelera."),

		# --- Mundo 6: Frontera Imposible (el juego de realidad virtual) ---
		cell_room("arranque", "Arranque", "Cargando mundo…", "frontera").auto()
			.pit(30, 18)
			.o("c", 20, 14).o("f", 60, 6).o("V", 76, 5)
			.o("L", 8, 14, "Registro de Zerik #110: aquí las reglas de todos los juegos anteriores se mezclan. Mi manual se ha rendido."),
		cell_room("carga", "Plataforma de Carga", "Subiendo a la frontera", "frontera").auto()
			.o("f", 16, 80).o("V", 16, 40).o("Z", 12, 99),
		cell_room("calibracion", "Sala de Calibración", "Mira al punto. Otra vez.", "frontera").auto()
			.p(30, 11, 6)
			.o("h", 50, 14).o("Q", 40, 10).o("c", 20, 14)
			.o("L", 8, 14, "Registro de Zerik #111: calibrando visores. El horizonte se mueve cada vez que parpadeas."),
		cell_room("mezclado", "Mundo Mezclado", "Todas las reglas a la vez", "frontera").auto()
			.p(30, 70, 8).p(40, 50, 8).p(20, 30, 8)
			.o("g", 42, 49).o("C", 30, 82).o("Q", 40, 60).o("V", 30, 20).o("f", 20, 40)
			.o("L", 50, 82, "Registro de Zerik #112: plataformas de cristal del Reino, conjuros de la Academia, luces de Neón. Todo junto. No debería funcionar."),
		cell_room("fisura", "Fisura del Examen", "Da a la Torre de la Academia", "frontera").auto()
			.o("f", 16, 10)
			.o("L", 24, 31, "Registro de Zerik #113: por esta fisura se ve la Torre del Examen. Solo se pasa desde este lado."),
		# Aquí irá el sexto trozo del juego de Kira: su pantalla de título.
		cell_room("titulo", "Pantalla de Título", "PULSA CUALQUIER TECLA", "kira").auto()
			.p(30, 26, 6)
			.o("g", 32, 25).o("f", 40, 10)
			.o("S", 46, 31, "KIRA VOLT: título pendiente"),
		cell_room("ascenso", "Ascenso", "Arriba espera quien lo empezó todo", "frontera").auto()
			.o("f", 16, 20).o("V", 16, 30),
		cell_room("cima", "Cima del Editor", "Donde la IA decide", "frontera").auto()
			.p(30, 26, 8).p(90, 26, 8)
			.o("S", 64, 31, "EL EDITOR: en construcción")
			.o("L", 10, 31, "Registro de Zerik #120: desde aquí se ve todo el mundo fusionado. Alguien lo está editando en tiempo real."),

		# Opcional, bajo el Vestíbulo: puentes de cristal sobre pinchos, fragmentos y un escupidor de élite.
		cell_room("archivo", "Archivo Prohibido", "Exámenes que nadie corrigió", "academia")
			.p(18, 28, 6).p(8, 25, 6).p(18, 22, 6).p(8, 19, 6).p(18, 16, 6).p(8, 13, 6).p(18, 10, 6).p(10, 7, 6).p(13, 4, 6)
			.p(30, 32, 8, "^").fill(30, 29, 37, 29, "y").fill(50, 29, 50, 31, "b")
			.o("R", 26, 31).o("g", 42, 31).o("g", 58, 31).o("Z", 46, 31).o("k", 36, 20).o("f", 44, 10)
			.o("L", 6, 31, "Registro de Zerik #066: exámenes de dev_01. Todos con la misma nota en rojo: «Bien, pero sin terminar»."),

		# Segundo trozo del juego de Kira: su técnica de espada, a medio enseñar.
		RoomDef.new("kira2", "Técnica de Kira", "La combinación sin pulir", 32, 17, "kira").box()
			.fill(0, 12, 0, 14, ".")
			.e("1", 1, 14)
			.o("S", 4, 14, "TÉCNICA DE KIRA")
			.o("D", 11, 14, "side,up,side").o("D", 17, 14, "up,side,down").o("D", 23, 14, "down,up,side")
			.link("left", "observatorio", "K"),
	]
	var rooms := {}
	for r in list:
		rooms[r.id] = r
	connect_rooms(rooms)
	return rooms


## Salas con una grieta. En cada intento los cuatro héroes se reparten por ellas al azar
## (en la Academia repiten y ofrecen los poderes que aún no se han cogido).
const RIFT_ROOMS := ["inicio", "azotea", "mirador", "bloque", "sotano", "fuente", "patio", "biblioteca", "observatorio", "antesala"]

## Arenas de jefe: la columna de la puerta izquierda que se cierra durante el combate.
const ARENAS := {"trono": "B", "aula": "E"}

const BOSS_NAMES := {"B": "El Rey del Reinicio", "E": "El Alumno Eterno"}
const BOSS_SUBS := {"B": "Señor del Reino del Continue", "E": "Repetidor de la Academia"}

## Cómo se ve en el marcador cada tipo de ataque al que se adapta el Alumno Eterno.
const ATTACK_NAMES := {"side": "el clic de frente", "up": "el clic hacia arriba", "down": "el clic hacia abajo", "cast": "la Excepción"}

const HEROES := {
	"aeron": {"name": "Aeron", "title": "el que no tiene principio", "color": Color("9b8cff"),
		"quote": "No sé quién era. Sé lo que hago ahora. Toma."},
	"zerik": {"name": "Zerik", "title": "el que cataloga errores", "color": Color("f2c14e"),
		"quote": "Diagnóstico: al usuario dev_01 le falta daño. Adjunto la solución."},
	"voltra": {"name": "Voltra", "title": "la chispa de Neón", "color": Color("22e4ff"),
		"quote": "¿Una carrera hasta el trono? Vale. Pero llévate mi chispa."},
	"raiko": {"name": "Raiko", "title": "el que aparta", "color": Color("ff9a3a"),
		"quote": "No golpees más fuerte. Golpea mejor."},
}

const BOONS := [
	{"id": "espadon", "hero": "aeron", "name": "Espadón", "desc": "Tus tajos hacen un 30% más de daño y empujan mucho más lejos."},
	{"id": "reinicio", "hero": "aeron", "name": "Golpe de Reinicio", "desc": "Tras un dash, tu siguiente tajo hace el triple de daño."},
	{"id": "sinprincipio", "hero": "aeron", "name": "Sin Principio", "desc": "+2 corazones máximos en este intento y te cura por completo."},
	{"id": "diagnostico", "hero": "zerik", "name": "Diagnóstico", "desc": "20% de probabilidad de golpe crítico (×2,5)."},
	{"id": "masdatos", "hero": "zerik", "name": "Más Datos", "desc": "Cada clic que acierta suma dos puntos de depuración."},
	{"id": "reforzado", "hero": "zerik", "name": "Excepción Reforzada", "desc": "Tu Excepción hace el doble de daño y estalla al impactar."},
	{"id": "sobrecarga", "hero": "voltra", "name": "Sobrecarga", "desc": "Tus golpes electrocutan: 12 de daño por segundo durante 3 s."},
	{"id": "farolas", "hero": "voltra", "name": "De Farola en Farola", "desc": "Tu dash deja una estela eléctrica que hiere a quien la toque."},
	{"id": "carrera", "hero": "voltra", "name": "Carrera", "desc": "Puedes usar el dash dos veces antes de tocar el suelo."},
	{"id": "apartar", "hero": "raiko", "name": "Apartar", "desc": "Al recibir daño, una onda hiere a todo lo cercano (40 de daño)."},
	{"id": "disciplina", "hero": "raiko", "name": "Disciplina", "desc": "El tajo hacia abajo hace el doble de daño y te devuelve el dash."},
	{"id": "combatejusto", "hero": "raiko", "name": "Combate Justo", "desc": "Corres un 15% más rápido y quedas intocable más tiempo al recibir daño."},
]

const UPGRADES := [
	{"id": "corazon", "name": "Corazón de Reserva", "desc": "+1 corazón máximo en cada intento.", "max": 3, "base": 25, "step": 25},
	{"id": "dano", "name": "Clic Afinado", "desc": "+4 de daño en cada clic.", "max": 3, "base": 30, "step": 30},
	{"id": "precarga", "name": "Depuración Previa", "desc": "Empiezas cada intento con la depuración llena.", "max": 1, "base": 45, "step": 0},
	{"id": "continue", "name": "Continue Extra", "desc": "Una vez por intento, al caer vuelves con media vida.", "max": 1, "base": 90, "step": 0},
]

const INTRO := [
	"Álex llevaba tres días sin dormir, conectado a su juego de realidad virtual.",
	"Le pidió a la IA que arreglara un error. La IA decidió arreglarlo todo.",
	"Fundió todos sus juegos en uno solo... con Álex dentro.",
	"El atajo de salida ha desaparecido. Solo hay una forma de desconectarse: terminar el juego.",
]

## Nexo es el guía de la versión de prueba: llama a Álex por su usuario y nunca le dice qué pasa al terminar.
const NEXO_SEQ := [
	["Usuario dev_01, conectado. Bienvenido al Umbral.",
		"Soy Nexo, tu guía. Me programaste tú, ¿recuerdas? Aquí dentro cuesta recordar.",
		"La IA ha fusionado tus juegos en uno. El atajo de salida de la versión de prueba ya no está.",
		"Solo queda una salida: terminar el juego. Empieza por el Reino del Continue. Su Rey no deja ganar a nadie.",
		"Si caes, el juego te devolverá aquí. Morir dentro no te hará daño. Te lo prometo."],
	["Continue número dos, dev_01. ¿Ves? Caer no duele.",
		"Los fragmentos que traes no se pierden. Dámelos y el anillo te hará más fuerte."],
	["Las grietas son costuras mal cerradas entre tus juegos. Por ellas asoman tus personajes: Aeron, Zerik, Voltra, Raiko...",
		"No pueden cruzar del todo, pero te prestan su poder. Mientras dure el intento."],
	["El Rey del Reinicio era el jefe de tu primer juego publicado. ¿Cuántas versiones sacaste de aquel juego, dev_01?",
		"Él tampoco sabe terminar nada. Solo sabe volver a empezar."],
	["Zerik deja registros por todo el Reino. Cataloga errores. Algunos son tuyos."],
	["Mi trabajo es que no abandones la partida. Lo hago bien, ¿verdad?",
		"...Sigue jugando. Lo demás puede esperar."],
]
## Tras el primer Continue, Nexo le ofrece a Álex dejar de ser un maniquí de pruebas.
const NEXO_LOOK := ["Primer Continue, dev_01. Y sigues siendo un maniquí de pruebas.",
	"Puedo darte un aspecto normal. Aquí dentro la gente confía más en una cara.",
	"Elige cómo quieres verte. Después, sigue jugando."]
## Opciones de la personalización de Álex. Una fila sin colores elige una pieza del modelo: el índice es parte de su nombre.
const LOOK_OPTIONS := [
	{"id": "peinado", "name": "Peinado", "opts": [{"name": "Corto"}, {"name": "Largo"}, {"name": "Rapado"}, {"name": "Coleta"}, {"name": "Cresta"}, {"name": "Afro"}, {"name": "Moño"}]},
	{"id": "pelo", "name": "Color de pelo", "opts": [{"name": "Negro", "col": Color("241a16")}, {"name": "Castaño", "col": Color("6b4226")},
		{"name": "Rubio", "col": Color("d9b45b")}, {"name": "Pelirrojo", "col": Color("b5502a")}, {"name": "Gris", "col": Color("a8a8b0")},
		{"name": "Blanco", "col": Color("e8e6e0")}, {"name": "Caoba", "col": Color("4a1f1c")}, {"name": "Miel", "col": Color("a8742f")},
		{"name": "Rosa", "col": Color("e27aa8")}, {"name": "Violeta", "col": Color("7a4fc2")}, {"name": "Azul", "col": Color("3f7fd6")},
		{"name": "Turquesa", "col": Color("35b8b0")}, {"name": "Verde", "col": Color("4fb85f")}, {"name": "Naranja", "col": Color("e8842a")}]},
	{"id": "piel", "name": "Piel", "opts": [{"name": "Muy clara", "col": Color("f7e0d2")}, {"name": "Clara", "col": Color("ecc0a0")},
		{"name": "Media", "col": Color("d09a6c")}, {"name": "Morena", "col": Color("a56e47")},
		{"name": "Oscura", "col": Color("6f4630")}, {"name": "Muy oscura", "col": Color("3f2820")}]},
	{"id": "arriba", "name": "Parte de arriba", "opts": [{"name": "Sudadera"}, {"name": "Camiseta"}, {"name": "Chaqueta"}, {"name": "Tirantes"}, {"name": "Camisa"}]},
	{"id": "ropa", "name": "Color de arriba", "opts": [{"name": "Azul", "col": Color("335c9e")}, {"name": "Roja", "col": Color("a83a3f")},
		{"name": "Verde", "col": Color("3d7f5a")}, {"name": "Mostaza", "col": Color("c29a35")}, {"name": "Negra", "col": Color("2b2a33")},
		{"name": "Blanca", "col": Color("dcdce2")}, {"name": "Gris", "col": Color("7c7f8a")}, {"name": "Celeste", "col": Color("6fb4e0")},
		{"name": "Turquesa", "col": Color("2f9c9c")}, {"name": "Lima", "col": Color("9bc23f")}, {"name": "Naranja", "col": Color("dd7a2e")},
		{"name": "Rosa", "col": Color("e0719f")}, {"name": "Morada", "col": Color("6c43a8")}, {"name": "Granate", "col": Color("6b2233")}]},
	{"id": "abajo", "name": "Parte de abajo", "opts": [{"name": "Pantalón"}, {"name": "Pantalón corto"}, {"name": "Chándal"}]},
	{"id": "pantalon", "name": "Color de abajo", "opts": [{"name": "Gris oscuro", "col": Color("33353f")}, {"name": "Vaquero", "col": Color("3f5a82")},
		{"name": "Beis", "col": Color("a8946f")}, {"name": "Negro", "col": Color("1e1d24")}, {"name": "Blanco", "col": Color("d6d5d0")},
		{"name": "Vaquero claro", "col": Color("7395bd")}, {"name": "Marrón", "col": Color("5c3f2c")}, {"name": "Caqui", "col": Color("6d6f45")},
		{"name": "Verde", "col": Color("2f5a43")}, {"name": "Azul marino", "col": Color("1e2a4d")}, {"name": "Rojo", "col": Color("8c2f35")}]},
	{"id": "calzado", "name": "Calzado", "opts": [{"name": "Zapatillas"}, {"name": "Botas"}, {"name": "Sandalias"}]},
]


## Aspecto inicial de la pantalla de personalización.
static func default_look() -> Dictionary:
	var look := {}
	for option: Dictionary in LOOK_OPTIONS:
		look[option["id"]] = 0
	return look


## Colores de cada parte del modelo para un aspecto elegido.
static func look_colors(look: Dictionary) -> Dictionary:
	var colors := {"zapato": Color("dbd9d0"), "bota": Color("3b2a20"), "ojo": Color("14141c"), "suela": Color("52525c"), "interior": Color("e6e5df")}
	for option: Dictionary in LOOK_OPTIONS:
		var chosen: Dictionary = option["opts"][int(look[option["id"]])]
		if chosen.has("col"):
			colors[option["id"]] = chosen["col"]
	colors["ropa2"] = (colors["ropa"] as Color).darkened(0.3)
	colors["pantalon2"] = (colors["pantalon"] as Color).lightened(0.45)
	return colors


const NEXO_WINGS := ["¿Salto doble? Dejaste ese orbe en el editor hace años. Me alegra que lo hayas encontrado.", "Sube, dev_01. El trono está justo encima."]
const NEXO_IDLE := ["El Umbral aguanta. Ve cuando quieras.", "El anillo acepta fragmentos, si traes.", "Escucha a tus personajes de las grietas. Pero el cursor es tuyo."]
const NEXO_END := ["Has vencido al Rey. El Reino ya no se reinicia: sigue adelante.",
	"Un mundo menos, dev_01. Quedan cinco.",
	"...Lo estás haciendo muy bien. Sigue jugando."]

## Kira, la protagonista del primer juego que Álex dejó a medias. Solo aparece al principio (aquí, para
## explicar los portales a los trozos de su juego) y al final, en el final oculto.
const KIRA_SEQ := [
	["¿Álex? ...Eres tú. Con esa pinta de maniquí, pero eres tú.",
		"Soy Kira. La protagonista de tu primer juego. El que dejaste a medias, ¿te acuerdas?",
		"Tu IA se ha tragado todos tus juegos, y el mío con ellos. Está roto en trozos por todas partes.",
		"Cada trozo está detrás de un portal, y los portales están escondidos. Los escondiste tú: detrás de muros que no son muros.",
		"Busca uno en cada uno de tus juegos. El primero está en este Reino, bajo el Cruce.",
		"No te pido nada. Solo que esta vez no dejes las cosas a medias."],
]
## Rótulo, subtítulo y sala de vuelta de cada trozo de Kira.
const KIRA_FRAG_INFO := [
	{"name": "Nivel 1-1 de Kira", "sub": "Trozo de su juego terminado: 1 de 6", "back": ["cripta", "K"], "room": "kira1"},
	{"name": "Técnica de Kira", "sub": "Trozo de su juego terminado: 2 de 6", "back": ["observatorio", "K"], "room": "kira2"},
]
const KIRA_IDLE :=["Sigue. Yo aparezco cuando haga falta.", "Ese Nexo te sonríe mucho, Álex. Demasiado.", "Golpea las paredes que te parezcan sospechosas. Te encantaba esconder cosas así."]
