## Una misión: mapa, recursos iniciales, oleadas y torres disponibles.
class_name MissionDef
extends Resource

@export var id: StringName
@export var display_name := ""
@export_file("*.tscn") var map_scene := ""
@export var start_gold := 100
@export var base_hp := 20
@export var waves: Array[WaveDef] = []
## Ids de las torres que el jugador puede construir.
@export var towers := PackedStringArray()
## Ids de los héroes desplegados en la misión (uno por posición de inicio del mapa).
@export var heroes := PackedStringArray()
