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
	"trono": {"top": Color("4a0c18"), "bot": Color("0b0205"), "stone": Color("2c1018"), "deep": Color("18080c"), "rim": Color("e8384f"), "far": Color("2a0810"), "near": Color("170409")},
}


## Una sala: plano de casillas ("#" bloque, "=" plataforma que se atraviesa desde abajo, "^" pinchos),
## objetos, entradas (donde aparece Kira) y salidas por los bordes.
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
	var exits := {}

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

	func link(side: String, to: String, entry: String) -> RoomDef:
		exits[side] = [to, entry]
		return self


## Crea las salas (cada partida tiene su copia, porque la arena del jefe cambia el plano).
static func build_rooms() -> Dictionary:
	var list := [
		RoomDef.new("umbral", "Umbral de Nexo", "Donde se cruzan las grietas", 34, 17, "umbral").box()
			.fill(33, 12, 33, 14, ".").fill(9, 7, 14, 7, "=")
			.o("M", 3, 14).o("H", 9, 14).o("O", 21, 14)
			.o("L", 27, 14, "Registro de Zerik #001: el Umbral no aparece en ningún mapa del Reino. Conclusión: lo trajo Nexo consigo.")
			.e("P", 15, 14).e("1", 32, 14).link("right", "inicio", "1"),
		RoomDef.new("inicio", "Pantalla de Inicio", "Pulsa START. Otra vez.", 60, 17, "inicio").box()
			.fill(0, 12, 0, 14, ".").fill(59, 12, 59, 14, ".")
			.fill(18, 15, 20, 15, "^").fill(45, 15, 47, 15, "^")
			.fill(15, 10, 19, 10, "=").fill(24, 7, 28, 7, "=").fill(40, 10, 44, 10, "=").fill(30, 13, 34, 14, "#")
			.e("1", 1, 14).e("2", 58, 14)
			.o("L", 6, 14, "Registro de Zerik #014: los rastreros dejan un núcleo al caer. Si el núcleo sobrevive, el rastrero vuelve. Recomendación: romper el núcleo. Rápido.")
			.o("c", 12, 14).o("F", 26, 14).o("c", 32, 12).o("s", 39, 14).o("c", 53, 14)
			.link("left", "umbral", "1").link("right", "monedas", "1"),
		RoomDef.new("monedas", "Monedas Sueltas", "Lo que cae, se recoge", 50, 26, "monedas").box()
			.fill(0, 21, 0, 23, ".").fill(49, 8, 49, 10, ".")
			.fill(6, 21, 11, 21, "=").fill(13, 18, 18, 18, "=").fill(6, 15, 11, 15, "=").fill(1, 12, 5, 12, "=")
			.fill(20, 15, 25, 15, "=").fill(28, 12, 33, 12, "=").fill(37, 11, 48, 12, "#")
			.fill(26, 23, 29, 23, "^")
			.e("1", 1, 23).e("2", 47, 10)
			.o("A", 3, 11).o("F", 30, 11)
			.o("L", 44, 10, "Registro de Zerik #027: hay un orbe en lo más alto de esta sala. Demasiado alto para llegar sin querer. ¿Error de diseño o premio?")
			.o("c", 20, 23).o("c", 36, 23).o("f", 25, 8).o("f", 40, 18).o("f", 12, 6)
			.link("left", "inicio", "2").link("right", "bloque", "1"),
		RoomDef.new("bloque", "Bloque Sorpresa", "Todo vuelve a su sitio", 56, 17, "bloque").box()
			.fill(0, 8, 0, 10, ".").fill(1, 11, 8, 11, "#").fill(55, 12, 55, 14, ".")
			.fill(9, 13, 12, 13, "=").fill(20, 15, 23, 15, "^").fill(14, 10, 17, 10, "=").fill(24, 10, 28, 10, "=").fill(36, 8, 41, 8, "=")
			.e("1", 1, 10).e("2", 54, 14)
			.o("s", 13, 14).o("c", 30, 14).o("s", 38, 7).o("c", 46, 14).o("f", 33, 4).o("F", 26, 9)
			.o("L", 50, 14, "Registro de Zerik #033: aquí todo se rompe y luego vuelve. Todo. He tenido que crear una categoría nueva en el manual: «todo».")
			.link("left", "monedas", "2").link("right", "pantalla", "1"),
		RoomDef.new("pantalla", "Doble Pantalla", "Arriba hay más partida", 24, 40, "pantalla").box()
			.fill(0, 35, 0, 37, ".").fill(10, 0, 13, 0, ".")
			.fill(3, 33, 8, 33, "=").fill(12, 28, 17, 28, "=").fill(4, 23, 9, 23, "=").fill(13, 18, 18, 18, "=")
			.fill(5, 13, 10, 13, "=").fill(12, 8, 17, 8, "=").fill(9, 3, 14, 3, "=")
			.e("1", 1, 37).e("2", 11, 2)
			.o("L", 18, 37, "Registro de Zerik #041: plataformas a cinco casillas de altura. Con un salto normal, imposible. Con salto doble, probable.")
			.o("F", 15, 27).o("f", 6, 20).o("f", 16, 11).o("f", 11, 30)
			.link("left", "bloque", "2").link("up", "trono", "1"),
		RoomDef.new("trono", "Trono del Reinicio", "Donde el Rey pulsa CONTINUE", 40, 18, "trono").box()
			.fill(0, 13, 0, 15, ".").fill(8, 11, 12, 11, "=").fill(27, 11, 31, 11, "=")
			.e("1", 1, 15).o("B", 28, 15).link("left", "pantalla", "2"),
	]
	var rooms := {}
	for r in list:
		rooms[r.id] = r
	return rooms


## Salas con una grieta: en cada intento asoma un héroe distinto en cada una.
const RIFT_ROOMS := ["inicio", "monedas", "bloque", "pantalla"]

const HEROES := {
	"aeron": {"name": "Aeron", "title": "el que no tiene principio", "color": Color("9b8cff"),
		"quote": "No sé quién era. Sé lo que hago ahora. Toma."},
	"zerik": {"name": "Zerik", "title": "el que cataloga errores", "color": Color("f2c14e"),
		"quote": "Diagnóstico: te falta daño. Adjunto la solución."},
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
	{"id": "masdatos", "hero": "zerik", "name": "Más Datos", "desc": "Cada tajo que acierta llena dos muescas del filo."},
	{"id": "reforzado", "hero": "zerik", "name": "Disparo Reforzado", "desc": "Tu descarga de filo hace el doble de daño y estalla al impactar."},
	{"id": "sobrecarga", "hero": "voltra", "name": "Sobrecarga", "desc": "Tus golpes electrocutan: 12 de daño por segundo durante 3 s."},
	{"id": "farolas", "hero": "voltra", "name": "De Farola en Farola", "desc": "Tu dash deja una estela eléctrica que hiere a quien la toque."},
	{"id": "carrera", "hero": "voltra", "name": "Carrera", "desc": "Puedes usar el dash dos veces antes de tocar el suelo."},
	{"id": "apartar", "hero": "raiko", "name": "Apartar", "desc": "Al recibir daño, una onda hiere a todo lo cercano (40 de daño)."},
	{"id": "disciplina", "hero": "raiko", "name": "Disciplina", "desc": "El tajo hacia abajo hace el doble de daño y te devuelve el dash."},
	{"id": "combatejusto", "hero": "raiko", "name": "Combate Justo", "desc": "Corres un 15% más rápido y quedas intocable más tiempo al recibir daño."},
]

const UPGRADES := [
	{"id": "corazon", "name": "Corazón de Reserva", "desc": "+1 corazón máximo en cada intento.", "max": 3, "base": 25, "step": 25},
	{"id": "filo", "name": "Filo Templado", "desc": "+4 de daño en cada tajo.", "max": 3, "base": 30, "step": 30},
	{"id": "cargado", "name": "Filo Cargado", "desc": "Empiezas cada intento con las 6 muescas llenas.", "max": 1, "base": 45, "step": 0},
	{"id": "continue", "name": "Continue Extra", "desc": "Una vez por intento, al caer vuelves con media vida.", "max": 1, "base": 90, "step": 0},
]

const INTRO := [
	"La Gran Interferencia superpuso las realidades.",
	"El Editor quiere fundirlas en una sola versión, sin sorpresas.",
	"Al Reino del Continue lo convirtió en una partida que se reinicia sin fin.",
	"Kira Volt cruzó una grieta para romper el bucle.",
]

const NEXO_SEQ := [
	["Kira. Has cruzado la grieta... bien. Soy Nexo, guardián de este Umbral.",
		"Esto es el Reino del Continue. El Editor lo ha convertido en una partida que vuelve a empezar, una y otra vez.",
		"Al fondo, en su trono, el Rey del Reinicio cree que ganar es imposible. Demuéstrale lo contrario.",
		"Si caes, el Reino te devolverá aquí. Es su regla: continuar. Úsala a tu favor."],
	["Continue número dos. El Reino te ha devuelto, como te dije.",
		"Los fragmentos que traes no se pierden. Dámelos y el anillo te hará más fuerte."],
	["Las grietas no son solo heridas. Por ellas asoman otros héroes: Aeron, Zerik, Voltra, Raiko...",
		"No pueden cruzar del todo, pero te prestan su poder. Mientras dure el intento."],
	["El Rey no siempre fue así. Antes celebraba cada partida ganada.",
		"El Editor le convenció de que el final siempre es el mismo. Que solo queda volver a empezar."],
	["Zerik deja registros por todo el Reino. Léelos: cataloga errores que ni el Editor ha visto."],
	["Cada vez que vuelves, el bucle se resiente un poco.",
		"El Editor no cuenta con que alguien aprenda de sus derrotas."],
]
const NEXO_WINGS := ["¿Salto doble? Entonces la Doble Pantalla ya no te queda lejos.", "Sube, Kira. El trono está justo encima."]
const NEXO_IDLE := ["El Umbral aguanta. Ve cuando quieras.", "El anillo acepta fragmentos, si traes.", "Escucha a los héroes de las grietas. Pero el filo es tuyo."]
const NEXO_END := ["Lo has hecho. El Reino ya no se reinicia: sigue.",
	"El Rey ha dejado de pulsar CONTINUE. Por primera vez quiere ver qué pasa después.",
	"Al Editor no le va a gustar. Bien. Quedan cinco mundos por despertar."]
