## Datos lógicos de un mapa, independientes de la escena y de la proyección.
## La simulación solo conoce esto; la escena del mapa (editable en el editor)
## lo genera con `MapScene.build_def()`.
extends RefCounted

## Tamaño en casillas.
var size := Vector2i.ZERO
## Rutas enemigas en casillas (la primera es la principal). Preparado para
## rutas alternativas del Reino del Continue y mundos posteriores.
var routes: Array[PackedVector2Array] = []
## Centros de las posiciones de construcción, en casillas.
var build_spots := PackedVector2Array()


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
	var on_path := path_tiles()
	for s in build_spots:
		if not _inside(s, 0.0):
			problems.append("posición de construcción %s fuera del mapa" % s)
		if on_path.has(Vector2i(floori(s.x), floori(s.y))):
			problems.append("posición de construcción %s encima de la ruta" % s)
	return problems


## Casillas que pisa alguna ruta (segmentos muestreados).
func path_tiles() -> Dictionary:
	var tiles := {}
	for route in routes:
		for i in range(1, route.size()):
			var a := route[i - 1]
			var b := route[i]
			var steps := int(ceil(a.distance_to(b) * 4.0))
			for s in steps + 1:
				var p := a.lerp(b, float(s) / maxf(steps, 1))
				var t := Vector2i(floori(p.x), floori(p.y))
				if t.x >= 0 and t.y >= 0 and t.x < size.x and t.y < size.y:
					tiles[t] = true
	return tiles


func _inside(p: Vector2, margin: float) -> bool:
	return p.x >= -margin and p.y >= -margin and p.x <= size.x + margin and p.y <= size.y + margin
