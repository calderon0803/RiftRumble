## Lee el plano de texto de una sala (sin nodos): bloques, pinchos, enemigos,
## banco e inicio, ya en píxeles del mundo.
## «#» bloque, «^» pinchos, «c» rastrero, «B» banco, «K» inicio, «D» dash,
## «H» corazón extra; lo demás, aire.
## Las filas cortas se rellenan con aire.
class_name RoomLayout
extends RefCounted

const TILE := 32

var id := ""
var name := ""
var rows: Array = []
var rect := Rect2()             # en píxeles del mundo
var solids: Array[Rect2] = []   # tramos horizontales de bloques
var spikes: Array[Rect2] = []
var enemy_spawns: Array[Vector2] = []   # pies
var bench := Vector2.INF                # pies; INF si no hay
var start := Vector2.INF                # pies; INF si no hay
## Objetos que se recogen: {kind: "dash"|"heart", pos: centro, id: "sala:col:fila"}.
var pickups: Array[Dictionary] = []

const PICKUP_KINDS := {"D": "dash", "H": "heart"}


static func parse(layout: Array, origin_tiles := Vector2i.ZERO, room_id := "", room_name := "") -> RoomLayout:
	var r := RoomLayout.new()
	r.id = room_id
	r.name = room_name
	r.rows = layout
	var o := Vector2(origin_tiles) * TILE
	var width := 0
	for row in layout:
		width = maxi(width, row.length())
	r.rect = Rect2(o, Vector2(width, layout.size()) * TILE)
	for y in layout.size():
		var row: String = layout[y]
		var x := 0
		while x < row.length():
			var ch := row[x]
			var feet := o + Vector2((x + 0.5) * TILE, (y + 1) * TILE)
			match ch:
				"K":
					r.start = feet
				"c":
					r.enemy_spawns.append(feet)
				"B":
					r.bench = feet
			if PICKUP_KINDS.has(ch):
				r.pickups.append({
					"kind": PICKUP_KINDS[ch],
					"pos": o + Vector2((x + 0.5) * TILE, (y + 0.5) * TILE),
					"id": "%s:%d:%d" % [room_id, x, y],
				})
			if ch != "#" and ch != "^":
				x += 1
				continue
			var x0 := x
			while x < row.length() and row[x] == ch:
				x += 1
			var span := Rect2(o + Vector2(x0, y) * TILE, Vector2(x - x0, 1) * TILE)
			if ch == "#":
				r.solids.append(span)
			else:
				r.spikes.append(span)
	return r


## ¿Es aire la casilla (columna, fila) local? Fuera del plano cuenta como bloque.
func is_open(col: int, row: int) -> bool:
	if row < 0 or row >= rows.size():
		return false
	var s: String = rows[row]
	var w := int(rect.size.x / TILE)
	if col < 0 or col >= w:
		return false
	return col >= s.length() or not (s[col] in ["#", "^"])
