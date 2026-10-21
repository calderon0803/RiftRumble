@tool
## Raíz de una escena de mapa. Se edita visualmente en el editor:
##   Ground (TileMapLayer iso)  → suelo
##   Props (Node2D, Y-sort)     → decorado alto (bloques, plataformas…)
##   Routes/RouteN (Path2D)     → rutas enemigas, en orden de recorrido
##   BuildSpots/* (Marker2D)    → posiciones de construcción
## `build_def()` convierte todo a coordenadas lógicas para la simulación.
extends Node2D

const MapDef := preload("res://src/content/map_def.gd")
const Iso := preload("res://src/view/iso.gd")

## Tamaño del mapa en casillas.
@export var size := Vector2i(18, 12)
## Las rutas solo se dibujan en el editor (en juego las representa el suelo).
@export var show_routes_in_game := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		$Routes.visible = show_routes_in_game


func build_def() -> MapDef:
	var def := MapDef.new()
	def.size = size
	for route in $Routes.get_children():
		if route is Path2D and route.curve:
			var pts := PackedVector2Array()
			for i in route.curve.point_count:
				var screen: Vector2 = route.position + route.curve.get_point_position(i)
				pts.append(_snap(Iso.to_logical(screen)))
			def.routes.append(pts)
	for spot in $BuildSpots.get_children():
		if spot is Marker2D:
			def.build_spots.append(_snap(Iso.to_logical(spot.position)))
	return def


## Ajusta a la rejilla de medias casillas para absorber imprecisiones del editor.
static func _snap(p: Vector2) -> Vector2:
	return (p * 2.0).round() / 2.0
