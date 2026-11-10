## Test de alcance de las salas (aproximado, sin física): calcula dónde puede ponerse Álex y a qué
## sitios llega andando, saltando y con dash, y comprueba que todas las salidas y objetos se alcanzan.
## Los bloques rompibles y las puertas de arena cuentan como aire; los bloques sin colocar y las
## plataformas de cristal, como plataformas. Las salas que piden salto en pared no se comprueban.
## godot --headless --path . --script res://tests/reach_tests.gd
extends SceneTree

var passed := 0
var failed := 0
var r: Data.RoomDef
var wings := true

## Sin salto doble: 3 casillas hacia arriba. Con él: 6. El dash añade 3 en horizontal.
const UP_SINGLE := 3
const UP_DOUBLE := 6
const DASH := 3


func check(cond: bool, name: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("  FAIL ", name)


func solid(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= r.w or y >= r.h:
		return false
	return r.g[y][x] == "#"


func floor_at(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= r.w or y >= r.h:
		return false
	return r.g[y][x] in ["#", "=", "p", "y"]


func hazard(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < r.w and y < r.h and r.g[y][x] == "^"


func standable(x: int, y: int) -> bool:
	if x < 0 or y < 1 or x >= r.w or y >= r.h - 1:
		return false
	return not solid(x, y) and not solid(x, y - 1) and floor_at(x, y + 1) and not hazard(x, y) and r.g[y + 1][x] != "^"


func clear_col(x: int, y0: int, y1: int) -> bool:
	for y in range(mini(y0, y1), maxi(y0, y1) + 1):
		if solid(x, y):
			return false
	return true


func clear_row(y: int, x0: int, x1: int) -> bool:
	for x in range(mini(x0, x1), maxi(x0, x1) + 1):
		if solid(x, y) or solid(x, y - 1):
			return false
	return true


## ¿Se puede ir saltando de s a d? Arco simplificado: subir en la columna de salida, cruzar por arriba y bajar.
func can_jump(s: Vector2i, d: Vector2i) -> bool:
	var up := s.y - d.y
	var dx := absi(d.x - s.x)
	var h := UP_DOUBLE if wings else UP_SINGLE
	if up > h:
		return false
	var reach: int
	if up >= 0:
		reach = (8 if wings else 5) - maxi(0, up - 1)
	else:
		reach = 5 + (-up) / 2 + (3 if wings else 0)
	if dx > reach + DASH:
		return false
	var apex := mini(s.y, d.y) - 1
	return clear_col(s.x, s.y - 1, apex) and clear_row(apex, s.x, d.x) and clear_col(d.x, apex, d.y - 1)


func reachable_from(start: Vector2i) -> Dictionary:
	var stands: Array = []
	for y in r.h:
		for x in r.w:
			if standable(x, y):
				stands.append(Vector2i(x, y))
	var s0 := start
	while s0.y < r.h - 1 and not standable(s0.x, s0.y):
		s0.y += 1
	var seen := {s0: true}
	var queue := [s0]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in stands:
			if seen.has(d):
				continue
			if absi(d.x - c.x) > 14 or d.y - c.y > 30 or c.y - d.y > UP_DOUBLE:
				continue
			var ok: bool = (d.y == c.y and absi(d.x - c.x) == 1) or can_jump(c, d)
			if not ok and d.y > c.y:
				# Dejarse caer desde el borde.
				ok = absi(d.x - c.x) <= 4 and clear_col(d.x, c.y - 1, d.y - 1) and clear_row(c.y, c.x, d.x)
			if ok:
				seen[d] = true
				queue.append(d)
	return seen


func near(seen: Dictionary, x: int, y: int, rx := 2, ry := 1) -> bool:
	for dy in range(-ry, ry + 1):
		for dx in range(-rx, rx + 1):
			if seen.has(Vector2i(x + dx, y + dy)):
				return true
	return false


func exit_reached(seen: Dictionary, ex: Dictionary) -> bool:
	var a: int = ex["a"]
	var b: int = ex["b"]
	var h := UP_DOUBLE if wings else UP_SINGLE
	match ex["side"]:
		"left", "right":
			var x := 1 if ex["side"] == "left" else r.w - 2
			if a < 0:
				a = 0; b = r.h - 1
			for y in range(a, b + 2):
				if seen.has(Vector2i(x, y)):
					return true
		"up":
			if a < 0:
				a = 0; b = r.w - 1
			for x in range(a, b + 1):
				for y in range(1, h + 1):
					if seen.has(Vector2i(x, y)) and clear_col(x, y - 1, 0):
						return true
		"down":
			if a < 0:
				a = 0; b = r.w - 1
			for x in range(a - 1, b + 2):
				for y in range(r.h - 4, r.h - 1):
					if seen.has(Vector2i(x, y)):
						return true
	return false


const OBJECTS := ["A", "W", "g", "h", "F", "L", "K", "T", "R", "M", "O", "H", "S", "G"]


func check_room(start_entry: String, label: String) -> void:
	var start: Vector2i = r.entries[start_entry]
	var seen := reachable_from(start)
	for ex in r.exits:
		check(exit_reached(seen, ex), "%s: %s llega a la salida %s → %s" % [r.id, label, ex["side"], ex["to"]])
	for o in r.objs:
		if o["type"] in OBJECTS:
			check(near(seen, o["tx"], o["ty"]), "%s: %s llega a %s en (%d,%d)" % [r.id, label, o["type"], o["tx"], o["ty"]])
	for k in r.entries:
		var en: Vector2i = r.entries[k]
		var s := en
		while s.y < r.h - 1 and not standable(s.x, s.y):
			s.y += 1
		check(seen.has(s), "%s: %s llega a la entrada %s" % [r.id, label, k])


## Recorridos que tienen que poder hacerse sin el salto doble (antes de conseguirlo): sala, entrada y lados.
const NO_WINGS := {
	"inicio": ["umbral", ["left", "right", "up"]], "pasarela": ["inicio", ["up", "right"]],
	"monedas": ["pasarela", ["right", "down"]], "azotea": ["monedas", ["left", "right"]],
	"mirador": ["azotea", ["left", "down"]], "chimenea": ["mirador", ["right", "down", "up"]],
	"puente": ["chimenea", ["right"]], "fuente": ["puente", ["left", "right", "down"]],
	"cruce": ["inicio", ["left", "right"]], "arena1": ["cruce", ["left", "right"]],
	"sotano": ["cruce", ["left", "right"]], "cripta": ["sotano", ["right"]], "pozo": ["cruce", ["left"]],
}
## Puertas que no se pueden alcanzar sin salto doble: sala, entrada y salida bloqueada (hacia esa sala).
const WINGS_GATES := [["umbral", "inicio", "chimenea"], ["bloque", "arena1", "fuente"], ["bloque", "arena1", "pantalla"],
	["pantalla", "bloque", "arena2"], ["pantalla", "fuente", "arena2"]]


func _init() -> void:
	var rooms := Data.build_rooms()
	for id in rooms:
		r = rooms[id]
		if "walljump" in r.needs:
			continue
		wings = true
		var first: String = "1" if r.entries.has("1") else r.entries.keys()[0]
		check_room(first, "con salto doble")
	wings = false
	for id in NO_WINGS:
		r = rooms[id]
		var seen := reachable_from(r.entries[NO_WINGS[id][0]])
		for ex in r.exits:
			if ex["side"] in NO_WINGS[id][1]:
				check(exit_reached(seen, ex), "%s: sin salto doble llega a la salida %s → %s" % [id, ex["side"], ex["to"]])
	for gate: Array in WINGS_GATES:
		r = rooms[gate[0]]
		var seen := reachable_from(r.entries[gate[1]])
		var ex: Dictionary = r.exits.filter(func(e): return e["to"] == gate[2])[0]
		check(not exit_reached(seen, ex), "%s: sin salto doble no se llega a %s" % [gate[0], gate[2]])
	r = rooms["monedas"]
	var orb: Dictionary = r.objs.filter(func(o): return o["type"] == "A")[0]
	check(near(reachable_from(r.entries["pasarela"]), orb["tx"], orb["ty"]), "monedas: sin salto doble se llega al orbe")
	print("
Alcance: %d ok, %d fallos" % [passed, failed])
	quit(1 if failed > 0 else 0)
