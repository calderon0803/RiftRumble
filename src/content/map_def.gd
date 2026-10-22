## Datos lógicos de un mapa, independientes de la escena y de la proyección.
## La simulación solo conoce esto; la escena del mapa (editable en el editor)
## lo genera con `MapScene.build_def()`.
extends RefCounted

## Tamaño en casillas.
var size := Vector2i.ZERO
## Rutas enemigas en casillas (la primera es la principal). Preparado para
## rutas alternativas del mundo 1 y posteriores.
var routes: Array[PackedVector2Array] = []
## Ancho del camino en casillas (la ruta es su línea central).
var path_width := 1.0
## Centros de las posiciones de construcción, en casillas.
var build_spots := PackedVector2Array()
## Posiciones iniciales de los héroes, en casillas.
var hero_spawns := PackedVector2Array()
## Elementos interactivos: [{ id: String, kind: StringName, pos: Vector2, props: Dictionary }].
## Tipos actuales: &"block" (rompible: hp, reward_gold, opens_route, opens_spot)
## y &"platform" (mueve una posición de construcción: spot, to, period).
var objects: Array = []


## Lista de problemas del mapa (vacía si es válido).
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if size.x <= 0 or size.y <= 0:
		problems.append("tamaño inválido %s" % size)
	if routes.is_empty():
		problems.append("no hay rutas")
	for r in routes.size():
		if routes[r].size() < 2:
			problems.append("la ruta %d tiene menos de 2 puntos" % r)
		for p in routes[r]:
			if not _inside(p, 0.51):  # se permite empezar/terminar en el borde
				problems.append("punto %s de la ruta %d fuera del mapa" % [p, r])
	for o in objects:
		if not _inside(o.pos, 0.0):
			problems.append("elemento %s fuera del mapa" % o.id)
		var p: Dictionary = o.props
		if p.get("opens_route", -1) >= routes.size():
			problems.append("el bloque %s abre una ruta inexistente" % o.id)
		if p.get("opens_spot", -1) >= build_spots.size() or (o.kind == &"platform" and p.get("spot", -1) >= build_spots.size()):
			problems.append("el elemento %s apunta a una posición inexistente" % o.id)
	var on_path := path_tiles()
	for s in build_spots:
		if not _inside(s, 0.0):
			problems.append("posición de construcción %s fuera del mapa" % s)
		if on_path.has(Vector2i(floori(s.x), floori(s.y))):
			problems.append("posición de construcción %s encima de la ruta" % s)
	return problems


## Casillas del camino: aquellas cuyo centro está a ≤ path_width/2 de la línea
## central de alguna ruta.
func path_tiles() -> Dictionary:
	var tiles := {}
	var half := path_width * 0.5 + 0.01
	for y in size.y:
		for x in size.x:
			var c := Vector2(x + 0.5, y + 0.5)
			for route in routes:
				if distance_to_route(c, route) <= half:
					tiles[Vector2i(x, y)] = true
					break
	return tiles


## Punto de la ruta más cercano a `p` (para colocar héroes en el camino).
static func closest_point_on_route(p: Vector2, route: PackedVector2Array) -> Vector2:
	var best := route[0]
	var best_d := INF
	for i in range(1, route.size()):
		var q := Geometry2D.get_closest_point_to_segment(p, route[i - 1], route[i])
		var d := q.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = q
	return best


static func distance_to_route(p: Vector2, route: PackedVector2Array) -> float:
	return closest_point_on_route(p, route).distance_to(p)


func _inside(p: Vector2, margin: float) -> bool:
	return p.x >= -margin and p.y >= -margin and p.x <= size.x + margin and p.y <= size.y + margin
