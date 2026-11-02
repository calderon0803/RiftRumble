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
	"kira": {"top": Color("3a1030"), "bot": Color("0c040c"), "stone": Color("2c1a30"), "deep": Color("180c1c"), "rim": Color("ff6fd8"), "far": Color("2a0e26"), "near": Color("1a0818")},
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


## Crea las salas (cada partida tiene su copia, porque la arena del jefe cambia el plano).
static func build_rooms() -> Dictionary:
	var list := [
		# --- Mundo 1: Reino del Continue ---
		# Recorrido principal: Inicio → Pasarela → Cruce → Arena de los Rastreros → Bloque Sorpresa →
		# Doble Pantalla (pide salto doble) → Fuente → Arena de Élites → Trono.
		# Desvíos: Torre de las Monedas (orbe de salto doble) → Azotea Dorada (atajo hasta el Bloque), y el Sótano.
		RoomDef.new("umbral", "Umbral de Nexo", "Donde se cruzan las grietas", 34, 17, "umbral").box()
			.door("right", 12, 14, "inicio", "1").fill(9, 7, 14, 7, "=")
			.o("M", 3, 14).o("H", 9, 14).o("O", 21, 14)
			.o("L", 27, 14, "Registro de Zerik #001: el Umbral no aparece en ningún mapa del Reino. Conclusión: lo trajo Nexo consigo.")
			.e("P", 15, 14).e("1", 32, 14),
		# Tutorial: saltar fosos, rastreros con núcleo, un escupidor, la primera grieta y el primer muro rompible.
		RoomDef.new("inicio", "Pantalla de Inicio", "Pulsa START. Otra vez.", 64, 17, "inicio").box()
			.door("left", 12, 14, "umbral", "1").door("right", 12, 14, "pasarela", "1")
			.fill(18, 15, 20, 15, "^").fill(45, 15, 47, 15, "^")
			.fill(30, 13, 34, 14, "#").fill(36, 11, 40, 11, "=")
			.fill(50, 12, 50, 12, "n").fill(57, 12, 57, 14, "b")
			.e("1", 1, 14).e("2", 62, 14).e("K", 4, 14)
			.o("K", 9, 14, "1").o("T", 4, 14, "1")
			.o("L", 6, 14, "Registro de Zerik #014: los rastreros dejan un núcleo al caer. Si el núcleo sobrevive, el rastrero vuelve. Recomendación: romper el núcleo. Rápido.")
			.o("L", 55, 14, "Registro de Zerik #015: este muro está agrietado. Diagnóstico: dos clics. Algunos bloques guardan fragmentos dentro.")
			.o("c", 12, 14).o("F", 38, 10).o("c", 32, 12).o("s", 42, 14).o("c", 53, 14),
		# Plataformas sobre un suelo de pinchos, con dos escupidores en alto y revoloteadores.
		RoomDef.new("pasarela", "Pasarela de los Escupidores", "No mires abajo", 72, 20, "inicio").box()
			.door("left", 15, 17, "inicio", "2").door("right", 15, 17, "cruce", "1")
			.fill(9, 18, 63, 18, "^")
			.fill(11, 15, 14, 15, "=").fill(19, 15, 22, 15, "=").fill(27, 15, 30, 15, "=").fill(35, 15, 38, 15, "=")
			.fill(43, 15, 46, 15, "=").fill(51, 15, 54, 15, "=").fill(59, 15, 62, 15, "=")
			.fill(31, 7, 33, 8, "#").fill(47, 7, 49, 8, "#")
			.fill(2, 12, 7, 12, "=").fill(21, 11, 21, 11, "n")
			.e("1", 1, 17).e("2", 70, 17)
			.o("s", 32, 6).o("s", 48, 6).o("f", 40, 5).o("f", 56, 6).o("c", 5, 17).o("g", 4, 11)
			.o("L", 66, 17, "Registro de Zerik #016: los escupidores apuntan a donde estás, no a donde vas. Diagnóstico: no te quedes quieto."),
		# Cruce vertical con cuatro salidas: la arena (derecha), la torre (arriba) y el sótano (abajo).
		RoomDef.new("cruce", "Cruce del Reino", "Cuatro caminos, una partida", 40, 34, "monedas").box()
			.door("left", 29, 31, "pasarela", "2").door("right", 29, 31, "arena1", "1")
			.door("up", 17, 22, "monedas", "1").door("down", 30, 33, "sotano", "1")
			.fill(3, 29, 8, 29, "=").fill(11, 26, 16, 26, "=").fill(3, 23, 8, 23, "=").fill(11, 20, 16, 20, "=")
			.fill(19, 17, 24, 17, "=").fill(27, 14, 32, 14, "=").fill(19, 11, 24, 11, "=").fill(11, 8, 16, 8, "=")
			.fill(18, 5, 23, 5, "=").fill(17, 2, 22, 2, "=")
			.e("1", 1, 31).e("2", 38, 31).e("3", 19, 1).e("4", 28, 31)
			.o("c", 10, 31).o("f", 8, 15).o("f", 30, 8).o("s", 29, 13)
			.o("L", 36, 31, "Registro de Zerik #019: este cruce tiene cuatro salidas. Arriba, a la derecha, abajo... y por donde has venido. Todas llevan a algún sitio. Casi seguro."),
		# Torre con el orbe de salto doble arriba del todo. Arriba a la derecha sigue la Azotea.
		RoomDef.new("monedas", "Torre de las Monedas", "Lo que cae, se recoge", 30, 40, "monedas").box()
			.door("down", 13, 16, "cruce", "3").door("right", 2, 4, "azotea", "1")
			.fill(3, 35, 8, 35, "=").fill(11, 32, 16, 32, "=").fill(19, 29, 24, 29, "=").fill(11, 26, 16, 26, "=")
			.fill(3, 23, 8, 23, "=").fill(11, 20, 16, 20, "=").fill(19, 17, 24, 17, "=").fill(25, 14, 28, 14, "=")
			.fill(17, 11, 22, 11, "=").fill(9, 8, 14, 8, "=").fill(16, 6, 19, 6, "=").fill(20, 5, 28, 5, "#")
			.fill(2, 5, 7, 5, "=").fill(26, 30, 26, 30, "n")
			.e("1", 11, 37).e("2", 27, 4)
			.o("A", 4, 4).o("c", 22, 37).o("f", 20, 34).o("f", 6, 15).o("f", 22, 8).o("s", 21, 16)
			.o("L", 26, 37, "Registro de Zerik #027: hay un orbe en lo más alto de esta torre. Demasiado alto para llegar sin querer. ¿Error de diseño o premio?"),
		# Camino alternativo por encima: fragmentos escondidos, el primer rastrero de élite y bajada al Bloque.
		RoomDef.new("azotea", "Azotea Dorada", "Por encima del Reino", 44, 17, "monedas").box()
			.door("left", 12, 14, "monedas", "2").door("right", 12, 14, "bloque", "3")
			.fill(10, 15, 13, 15, "^").fill(26, 15, 29, 15, "^")
			.fill(16, 9, 21, 9, "=").fill(33, 12, 33, 12, "n")
			.e("1", 1, 14).e("2", 42, 14)
			.o("g", 18, 8).o("C", 22, 14).o("f", 34, 6).o("F", 37, 14)
			.o("L", 4, 14, "Registro de Zerik #022: desde aquí arriba se ve el Bloque Sorpresa. Atajo detectado. No se lo digas al Rey."),
		# Primera arena: tres oleadas de rastreros y revoloteadores.
		RoomDef.new("arena1", "Arena de los Rastreros", "Nadie sale hasta que acabe", 36, 17, "inicio").box()
			.door("left", 12, 14, "cruce", "2").door("right", 12, 14, "bloque", "1")
			.fill(1, 12, 1, 14, "d").fill(34, 12, 34, 14, "d")
			.fill(8, 11, 12, 11, "=").fill(23, 11, 27, 11, "=")
			.e("1", 2, 14).e("2", 33, 14)
			.o("x", 18, 14).o("z", 6, 13).o("z", 18, 9).o("z", 30, 13).o("z", 10, 10).o("z", 25, 10)
			.arena([["c", "c", "c"], ["c", "f", "f", "s"], ["C", "c", "f", "f"]]),
		# Muros rompibles, bloques con fragmentos y núcleos. Arriba a la izquierda llega el atajo de la Azotea.
		RoomDef.new("bloque", "Bloque Sorpresa", "Todo vuelve a su sitio", 64, 20, "bloque").box()
			.door("left", 15, 17, "arena1", "2").door("left", 6, 8, "azotea", "2").door("right", 15, 17, "pantalla", "1")
			.fill(1, 9, 10, 9, "#").fill(11, 12, 14, 12, "=")
			.fill(20, 15, 20, 17, "b").fill(26, 18, 29, 18, "^")
			.fill(33, 14, 37, 14, "=").fill(41, 11, 46, 11, "=").fill(36, 10, 36, 10, "n")
			.fill(52, 10, 52, 14, "#").fill(52, 15, 52, 17, "b")
			.e("1", 1, 17).e("2", 62, 17).e("3", 2, 8)
			.o("c", 15, 17).o("c", 24, 17).o("c", 34, 17).o("s", 43, 10).o("f", 30, 8).o("f", 57, 6).o("F", 46, 17)
			.o("L", 58, 17, "Registro de Zerik #033: aquí todo se rompe y luego vuelve. Todo. He tenido que crear una categoría nueva en el manual: «todo»."),
		RoomDef.new("pantalla", "Doble Pantalla", "Arriba hay más partida", 24, 40, "pantalla").box()
			.door("left", 35, 37, "bloque", "2").door("up", 10, 13, "fuente", "1")
			.fill(3, 33, 8, 33, "=").fill(12, 28, 17, 28, "=").fill(4, 23, 9, 23, "=").fill(13, 18, 18, 18, "=")
			.fill(5, 13, 10, 13, "=").fill(12, 8, 17, 8, "=").fill(9, 3, 14, 3, "=").fill(20, 24, 20, 24, "n")
			.e("1", 1, 37).e("2", 11, 2)
			.o("L", 18, 37, "Registro de Zerik #041: plataformas a cinco casillas de altura. Con un salto normal, imposible. Con salto doble, probable.")
			.o("f", 6, 20).o("f", 16, 11).o("f", 11, 30).o("s", 15, 17).o("V", 7, 6)
			.need("wings"),
		# Descanso antes del final: la fuente cura una vez por intento.
		RoomDef.new("fuente", "Fuente del Guardado", "Un respiro antes del final", 32, 17, "monedas").box()
			.door("left", 12, 14, "pantalla", "2").door("right", 12, 14, "arena2", "1")
			.e("1", 3, 14).e("2", 30, 14)
			.o("h", 16, 14).o("F", 9, 14)
			.o("L", 24, 14, "Registro de Zerik #045: una fuente que restaura. No sé quién la programó. Diagnóstico: alguien quería que llegaras al final."),
		# Última arena antes del trono: élites.
		RoomDef.new("arena2", "Arena de Élites", "Los mejores del Reino", 40, 17, "trono").box()
			.door("left", 12, 14, "fuente", "2").door("right", 12, 14, "trono", "1")
			.fill(1, 12, 1, 14, "d").fill(38, 12, 38, 14, "d")
			.fill(6, 11, 10, 11, "=").fill(16, 8, 23, 8, "=").fill(29, 11, 33, 11, "=")
			.e("1", 2, 14).e("2", 37, 14)
			.o("x", 20, 14).o("z", 8, 10).o("z", 20, 7).o("z", 31, 10).o("z", 5, 13).o("z", 34, 13)
			.arena([["C", "f", "s"], ["V", "c", "c", "Z"], ["C", "C", "V", "f"]]),
		# Opcional: cuevas bajo el Cruce con fragmentos escondidos, una grieta y un élite.
		RoomDef.new("sotano", "Sótano de las Partidas", "Donde se guardan las que nadie terminó", 56, 20, "bloque").box()
			.door("up", 2, 5, "cruce", "4")
			.fill(2, 3, 6, 3, "=").fill(1, 6, 5, 6, "=").fill(7, 9, 11, 9, "=").fill(1, 12, 5, 12, "=").fill(7, 15, 11, 15, "=")
			.fill(16, 18, 19, 18, "^").fill(34, 18, 37, 18, "^")
			.fill(24, 15, 28, 15, "=").fill(40, 13, 44, 13, "=").fill(46, 9, 52, 9, "=")
			.fill(30, 12, 30, 12, "n").fill(51, 15, 51, 17, "b")
			.e("1", 3, 2)
			.o("F", 26, 14).o("g", 49, 8).o("g", 53, 17)
			.o("C", 22, 17).o("c", 40, 17).o("f", 30, 6).o("f", 45, 4).o("s", 42, 12)
			.o("L", 13, 17, "Registro de Zerik #037: partidas guardadas a medias. Cientos. Todas con el mismo nombre de usuario: dev_01."),
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
			.link("left", "inicio", "K"),
		# La puerta derecha (columna 39, filas 13-15) se abre al vencer al Rey en el intento.
		RoomDef.new("trono", "Trono del Reinicio", "Donde el Rey pulsa CONTINUE", 40, 18, "trono").box()
			.fill(0, 13, 0, 15, ".").fill(8, 11, 12, 11, "=").fill(27, 11, 31, 11, "=")
			.e("1", 1, 15).e("2", 38, 15).o("B", 28, 15)
			.link("left", "arena2", "2").link("right", "patio", "1"),

		# --- Mundo 2: Academia del Último Hechizo ---
		# "R" cristal que resuena al golpearlo; "y" plataforma de cristal: solo se pisa mientras Álex resuena.
		# Recorrido principal: Patio → Vestíbulo → Biblioteca → Pasillo de las Runas (orbe de salto en pared) →
		# Laboratorio (arena) → Galería de Retratos (pide salto en pared) → Torre del Examen → Antesala (fuente) →
		# Claustro (arena de élites) → Aula Magna. Desvíos desde el Vestíbulo: Observatorio (arriba) y Archivo (abajo).
		RoomDef.new("patio", "Patio de la Academia", "Donde nadie se gradúa", 56, 17, "academia").box()
			.door("left", 12, 14, "trono", "2").door("right", 12, 14, "vestibulo", "1")
			.fill(16, 12, 18, 12, "y").fill(20, 9, 26, 9, "#").fill(50, 12, 50, 14, "b")
			.e("1", 1, 14).e("2", 54, 14)
			.o("L", 6, 14, "Registro de Zerik #052: los cristales vibran al golpearlos. Mientras vibran, algunas plataformas existen. Mi manual no tiene una categoría para «existir a ratos».")
			.o("R", 13, 14).o("F", 23, 8).o("c", 30, 14).o("k", 36, 11).o("c", 44, 14),
		# Vestíbulo vertical: dos tramos de la subida son de cristal (hay que golpear un cristal antes).
		RoomDef.new("vestibulo", "Vestíbulo de los Ecos", "Cada paso suena dos veces", 40, 34, "academia").box()
			.door("left", 29, 31, "patio", "2").door("right", 29, 31, "biblioteca", "1")
			.door("up", 17, 22, "observatorio", "1").door("down", 30, 33, "archivo", "1")
			.fill(3, 29, 8, 29, "=").fill(11, 26, 16, 26, "=").fill(3, 23, 8, 23, "=").fill(11, 20, 16, 20, "=")
			.fill(19, 17, 24, 17, "y").fill(27, 14, 32, 14, "=").fill(19, 11, 24, 11, "y").fill(11, 8, 16, 8, "=")
			.fill(18, 5, 23, 5, "=").fill(17, 2, 22, 2, "=")
			.e("1", 1, 31).e("2", 38, 31).e("3", 19, 1).e("4", 28, 31)
			.o("R", 14, 19).o("R", 29, 13)
			.o("c", 10, 31).o("k", 8, 15).o("f", 30, 8).o("s", 31, 13)
			.o("L", 36, 31, "Registro de Zerik #055: el Vestíbulo repite cada sonido. También los errores. Sobre todo los errores."),
		# Opcional, arriba: plataformas de cristal hasta unos fragmentos escondidos; conjurador de élite.
		RoomDef.new("observatorio", "Observatorio", "Donde se miraban las notas", 44, 17, "academia").box()
			.door("down", 2, 5, "vestibulo", "3")
			.fill(15, 12, 18, 12, "y").fill(20, 9, 23, 9, "y").fill(26, 6, 31, 6, "=").fill(34, 10, 34, 10, "n")
			.e("1", 8, 14)
			.o("R", 12, 14).o("g", 28, 5).o("F", 38, 14).o("Q", 30, 11).o("f", 20, 4)
			.o("L", 41, 14, "Registro de Zerik #060: un telescopio que apunta hacia dentro. Desde aquí se ve todo el Reino del Continue. Parece pequeño."),
		# Opcional, abajo: puentes de cristal sobre fosos de pinchos, fragmentos y un escupidor de élite.
		RoomDef.new("archivo", "Archivo Prohibido", "Exámenes que nadie corrigió", 56, 20, "academia").box()
			.door("up", 2, 5, "vestibulo", "4")
			.fill(2, 3, 6, 3, "=").fill(1, 6, 5, 6, "=").fill(7, 9, 11, 9, "=").fill(1, 12, 5, 12, "=").fill(7, 15, 11, 15, "=")
			.fill(16, 18, 25, 18, "^").fill(16, 15, 25, 15, "y")
			.fill(34, 18, 41, 18, "^").fill(36, 15, 39, 15, "=").fill(49, 15, 49, 17, "b")
			.e("1", 3, 2)
			.o("R", 13, 17).o("g", 30, 17).o("g", 52, 17)
			.o("Z", 45, 17).o("k", 28, 12).o("f", 38, 6)
			.o("L", 9, 17, "Registro de Zerik #066: exámenes de dev_01. Todos con la misma nota en rojo: «Bien, pero sin terminar»."),
		RoomDef.new("biblioteca", "Biblioteca Flotante", "Libros que nadie terminó de leer", 56, 24, "academia").box()
			.door("left", 19, 21, "vestibulo", "2").door("right", 4, 6, "pasillo", "1")
			.fill(11, 19, 14, 19, "y").fill(17, 16, 21, 16, "=").fill(24, 13, 27, 13, "y")
			.fill(30, 10, 34, 10, "=").fill(38, 10, 41, 10, "y").fill(43, 7, 54, 7, "#").fill(48, 17, 48, 17, "n")
			.e("1", 1, 21).e("2", 53, 6)
			.o("L", 4, 21, "Registro de Zerik #058: la Biblioteca flota porque nadie terminó de diseñar el suelo. Hipótesis: aquí estudiaba dev_01.")
			.o("R", 8, 21).o("R", 19, 15).o("R", 34, 9).o("F", 31, 9)
			.o("k", 21, 12).o("f", 28, 5).o("s", 47, 6).o("c", 30, 21).o("C", 44, 21),
		RoomDef.new("pasillo", "Pasillo de las Runas", "Aquí se suspendía", 60, 17, "academia").box()
			.door("left", 4, 6, "biblioteca", "2").door("right", 12, 14, "laboratorio", "1")
			.fill(1, 7, 8, 7, "#").fill(4, 11, 7, 11, "=").fill(46, 11, 52, 14, "#")
			.e("1", 1, 6).e("2", 58, 14).e("K", 11, 14)
			.o("K", 14, 14, "2").o("T", 11, 14, "2").o("W", 49, 10)
			.o("L", 56, 14, "Registro de Zerik #063: hay marcas en las paredes de la Galería. Alguien subía rebotando de pared en pared.")
			.o("c", 24, 14).o("k", 30, 11).o("s", 38, 14).o("f", 44, 5),
		# Primera arena de la Academia: conjuradores que curan a los demás si no se les interrumpe.
		RoomDef.new("laboratorio", "Laboratorio de Alquimia", "Mezclas que no salieron bien", 40, 17, "academia").box()
			.door("left", 12, 14, "pasillo", "2").door("right", 12, 14, "galeria", "1")
			.fill(1, 12, 1, 14, "d").fill(38, 12, 38, 14, "d")
			.fill(6, 11, 10, 11, "=").fill(16, 8, 23, 8, "y").fill(29, 11, 33, 11, "=")
			.e("1", 2, 14).e("2", 37, 14)
			.o("R", 20, 14).o("x", 20, 14).o("z", 8, 10).o("z", 20, 6).o("z", 31, 10).o("z", 5, 13).o("z", 34, 13)
			.arena([["k", "c", "c"], ["k", "k", "f", "s"], ["Q", "C", "f", "f"]]),
		# Enseña el salto en pared: una chimenea de 3 casillas entre dos muros es la única forma de pasar.
		RoomDef.new("galeria", "Galería de Retratos", "Todos te miran subir", 60, 24, "academia").box()
			.door("left", 19, 21, "laboratorio", "2").door("right", 19, 21, "torre", "1")
			.fill(26, 3, 26, 18, "#").fill(30, 3, 31, 21, "#")
			.fill(36, 22, 47, 22, "^").fill(38, 19, 41, 19, "y").fill(44, 16, 47, 16, "y").fill(50, 13, 50, 13, "n")
			.e("1", 1, 21).e("2", 58, 21)
			.o("R", 34, 21).o("Q", 44, 12).o("c", 14, 21).o("f", 10, 8).o("V", 53, 8)
			.o("L", 22, 21, "Registro de Zerik #068: retratos de todos los alumnos que suspendieron. El último es un maniquí gris.")
			.need("walljump"),
		# Torre: un pozo de 4 casillas sin escalones. Solo se sube con salto en pared.
		RoomDef.new("torre", "Torre del Examen", "Arriba está la nota", 14, 44, "academia").box()
			.door("left", 39, 41, "galeria", "2").door("up", 5, 8, "antesala", "1")
			.fill(1, 1, 4, 30, "#").fill(9, 1, 12, 30, "#")
			.fill(2, 38, 5, 38, "=").fill(8, 35, 11, 35, "=").fill(4, 32, 9, 32, "=")
			.e("1", 1, 41).e("2", 7, 2)
			.o("L", 11, 41, "Registro de Zerik #070: la Torre del Examen no tiene escaleras. Diagnóstico: el examen es subir.")
			.o("f", 10, 36).o("f", 6, 15).o("V", 7, 8)
			.need("walljump"),
		# Descanso antes del final: fuente y grieta.
		RoomDef.new("antesala", "Antesala del Examen", "Repasa por última vez", 32, 17, "academia").box()
			.door("left", 12, 14, "torre", "2").door("right", 12, 14, "claustro", "1")
			.e("1", 3, 14).e("2", 30, 14)
			.o("h", 16, 14).o("F", 9, 14)
			.o("L", 24, 14, "Registro de Zerik #072: alguien dejó apuntes en la mesa. Letra de dev_01. Dicen: «Esta vez sí lo termino»."),
		# Última arena: élites de la Academia.
		RoomDef.new("claustro", "Claustro de los Repetidores", "Los que nunca pasaron de curso", 40, 17, "academia").box()
			.door("left", 12, 14, "antesala", "2").door("right", 12, 14, "aula", "1")
			.fill(1, 12, 1, 14, "d").fill(38, 12, 38, 14, "d")
			.fill(6, 11, 10, 11, "=").fill(16, 8, 23, 8, "=").fill(29, 11, 33, 11, "=")
			.e("1", 2, 14).e("2", 37, 14)
			.o("x", 20, 14).o("z", 8, 10).o("z", 20, 7).o("z", 31, 10).o("z", 5, 13).o("z", 34, 13)
			.arena([["Q", "C", "f"], ["V", "k", "Z", "c"], ["Q", "Q", "V", "C"]]),
		RoomDef.new("aula", "Aula Magna", "El examen final", 40, 18, "academia").box()
			.fill(0, 13, 0, 15, ".").fill(8, 11, 12, 11, "=").fill(27, 11, 31, 11, "=")
			.e("1", 2, 15).o("E", 28, 15).link("left", "claustro", "2"),
		# Segundo trozo del juego de Kira: su técnica de espada, a medio enseñar.
		RoomDef.new("kira2", "Técnica de Kira", "La combinación sin pulir", 32, 17, "kira").box()
			.fill(0, 12, 0, 14, ".")
			.e("1", 1, 14)
			.o("S", 4, 14, "TÉCNICA DE KIRA")
			.o("D", 11, 14, "side,up,side").o("D", 17, 14, "up,side,down").o("D", 23, 14, "down,up,side")
			.link("left", "pasillo", "K"),
	]
	var rooms := {}
	for r in list:
		rooms[r.id] = r
	return rooms


## Salas con una grieta. En cada intento los cuatro héroes se reparten por ellas al azar
## (en la Academia repiten y ofrecen los poderes que aún no se han cogido).
const RIFT_ROOMS := ["inicio", "azotea", "bloque", "sotano", "fuente", "patio", "biblioteca", "observatorio", "antesala"]

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
const NEXO_WINGS := ["¿Salto doble? Dejaste ese orbe en el editor hace años. Me alegra que lo hayas encontrado.", "Sube, dev_01. El trono está justo encima."]
const NEXO_IDLE := ["El Umbral aguanta. Ve cuando quieras.", "El anillo acepta fragmentos, si traes.", "Escucha a tus personajes de las grietas. Pero el cursor es tuyo."]
const NEXO_END := ["Has vencido al Rey. El Reino ya no se reinicia: sigue adelante.",
	"Un mundo menos, dev_01. Quedan cinco.",
	"...Lo estás haciendo muy bien. Sigue jugando."]

## Kira, la protagonista del primer juego que Álex dejó a medias. Solo aparece en momentos puntuales.
const KIRA_SEQ := [
	["¿Álex? ...Eres tú. Con esa pinta de maniquí, pero eres tú.",
		"Soy Kira. La protagonista de tu primer juego. El que dejaste a medias, ¿te acuerdas?",
		"Tu IA se ha tragado todos tus juegos, y el mío con ellos. Está roto en trozos por todas partes.",
		"Mira mi espada: seis muescas, todas apagadas. Era tu mecánica estrella y nunca la terminaste.",
		"No te pido nada. Solo que esta vez no dejes las cosas a medias."],
	["Álex. Esta es tu Academia... la recuerdo. Aquí me diste la espada.",
		"Mi técnica: una combinación de golpes por cada muesca. Solo escribiste la primera.",
		"Hay una sala de entrenamiento a medias aquí al lado. Si la terminas, quizá recuerde el resto."],
]
## Al terminar un trozo de su juego, Kira habla (uno por cada muesca encendida).
const KIRA_FRAG := [
	["...Mi primer nivel. Lo has terminado.",
		"Has puesto el puente y el escalón que faltaban. Los que me prometiste hace años.",
		"Mira: una muesca encendida. La primera.",
		"Hay más trozos míos en tus otros juegos. Cuando llegues, te buscaré."],
	["De frente, arriba, abajo... así era. Ya me acuerdo.",
		"Segunda muesca. Mi espada empieza a parecerse a lo que prometiste.",
		"El Alumno Eterno te espera arriba, en el aula. No dejes que te convenza de que no estás listo."],
]
## Rótulo, subtítulo y sala de vuelta de cada trozo de Kira.
const KIRA_FRAG_INFO := [
	{"name": "Nivel 1-1 de Kira", "sub": "Primera muesca encendida", "back": ["inicio", "K"], "room": "kira1"},
	{"name": "Técnica de Kira", "sub": "Segunda muesca encendida", "back": ["pasillo", "K"], "room": "kira2"},
]
const KIRA_IDLE :=["Sigue. Yo aparezco cuando haga falta.", "Ese Nexo te sonríe mucho, Álex. Demasiado.", "Mi primer nivel anda por aquí, en algún sitio. Nunca lo probaste."]
