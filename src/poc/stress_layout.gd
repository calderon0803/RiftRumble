## Colocación de torres para el modo estrés y el benchmark: reparte posiciones
## a ambos lados de la ruta principal, fuera del camino y dentro del mapa.
extends RefCounted

const MapDef := preload("res://src/content/map_def.gd")
const SimPath := preload("res://src/sim/sim_path.gd")


static func tower_spots(def: MapDef, count: int, side_offset := 1.5) -> PackedVector2Array:
	var path := SimPath.new(def.routes[0])
	var on_path := def.path_tiles()
	var taken := {}
	var out := PackedVector2Array()
	var step := path.length / float(count + 1)
	var i := 0
	var d := step * 0.5
	while out.size() < count and d < path.length:
		var p := path.sample(d)
		var dir := (path.sample(d + 0.1) - p).normalized()
		var normal := Vector2(-dir.y, dir.x) * (1.0 if i % 2 == 0 else -1.0)
		var spot := ((p + normal * side_offset) * 2.0).round() / 2.0
		var tile := Vector2i(floori(spot.x), floori(spot.y))
		var inside := tile.x >= 0 and tile.y >= 0 and tile.x < def.size.x and tile.y < def.size.y
		i += 1
		if inside and not on_path.has(tile) and not taken.has(tile):
			taken[tile] = true
			out.append(Vector2(tile) + Vector2(0.5, 0.5))
			d += step
		else:
			d += step * 0.25  # posición no válida: reintenta un poco más adelante
	return out
