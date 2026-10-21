## Un mundo de la campaña: orden, presentación y sus huecos de misión.
## Los huecos se listan aunque la misión aún no exista: la campaña los muestra
## como «en construcción» hasta que su MissionDef está en content/missions/.
class_name WorldDef
extends Resource

@export var id: StringName
## Posición en la campaña (1 = primero).
@export var order := 1
@export var display_name := ""
## Una línea de ambientación.
@export var subtitle := ""
## Regla del mundo en una frase (se muestra en la campaña).
@export_multiline var rule_text := ""
## Color de acento (paleta del mundo en la interfaz).
@export var color := Color.WHITE
## Ids de misión en orden; el último es la misión del jefe.
@export var mission_slots := PackedStringArray()
## Nombres provisionales de los huecos aún no construidos.
@export var slot_names := PackedStringArray()
