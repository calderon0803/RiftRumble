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

@export_group("Mecánicas del mundo")
## Probabilidad (0–1) de que un enemigo suelte una moneda al morir.
@export_range(0.0, 1.0, 0.05) var coin_drop_chance := 0.0
@export var coin_value := 4
## Segundos que la moneda permanece antes de desaparecer.
@export var coin_lifetime := 8.0

@export_group("Tutorial")
## Pistas que se muestran la primera vez que ocurre un evento. Formato de cada
## línea: "evento|texto". Eventos: start, wave_started, tower_built,
## tower_upgraded, wave_cleared, coin_spawned, block_hit, block_broken,
## core_dropped, route_opened, hero_died.
@export var hints := PackedStringArray()
## Ids de los héroes desplegados en la misión (uno por posición de inicio del mapa).
@export var heroes := PackedStringArray()

@export_group("Recompensas (fragmentos)")
## Mismas reglas que la función del servidor (supabase/migrations): primera
## victoria = first_clear + per_star × estrellas; mejorar el récord =
## per_star × estrellas nuevas; repetir una victoria = replay.
@export var first_clear_reward := 50
@export var per_star_reward := 20
@export var replay_reward := 5
