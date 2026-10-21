## Una misión: mapa, recursos iniciales, oleadas y torres disponibles.
class_name MissionDef
extends Resource

@export var id: StringName
@export var display_name := ""
@export_file("*.tscn") var map_scene := ""
@export var start_gold := 100
@export var base_hp := 20
@export var waves: Array[WaveDef] = []
## Restricción OPCIONAL de torres (historia o reto). Vacía = cualquiera de las
## que tenga el jugador. Las torres se obtienen por tiradas.
@export var towers := PackedStringArray()
## Máximo de torres distintas que se llevan a la misión.
@export var max_towers := 4
## Ids de los héroes desplegados en la misión (uno por posición de inicio del mapa).
@export var heroes := PackedStringArray()

@export_group("Recompensas (fragmentos)")
## Mismas reglas que la función del servidor (supabase/migrations): primera
## victoria = first_clear + per_star × estrellas; mejorar el récord =
## per_star × estrellas nuevas; repetir una victoria = replay.
@export var first_clear_reward := 50
@export var per_star_reward := 20
@export var replay_reward := 5
