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
	"trono": {"top": Color("4a0c18"), "bot": Color("0b0205"), "stone": Color("2c1018"), "deep": Color("18080c"), "rim": Color("e8384f"), "far": Color("2a0810"), "near": Color("170409")},
}


## Una sala: plano de casillas ("#" bloque, "=" plataforma que se atraviesa desde abajo, "^" pinchos),
## objetos, entradas (donde aparece Álex) y salidas por los bordes.
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
			.e("1", 1, 14).e("2", 58, 14).e("K", 4, 14)
			.o("K", 9, 14).o("T", 4, 14)
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
]
## Al terminar un trozo de su juego, Kira habla (uno por cada muesca encendida).
const KIRA_FRAG := [
	["...Mi primer nivel. Lo has terminado.",
		"Has puesto el puente y el escalón que faltaban. Los que me prometiste hace años.",
		"Mira: una muesca encendida. La primera.",
		"Hay más trozos míos en tus otros juegos. Cuando llegues, te buscaré."],
]
const KIRA_IDLE :=["Sigue. Yo aparezco cuando haga falta.", "Ese Nexo te sonríe mucho, Álex. Demasiado.", "Mi primer nivel anda por aquí, en algún sitio. Nunca lo probaste."]
