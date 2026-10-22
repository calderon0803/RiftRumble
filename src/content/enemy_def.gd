## Definición de un tipo de enemigo. La simulación usa las estadísticas;
## la vista usa los campos de presentación.
class_name EnemyDef
extends Resource

## Peso (docs/personajes/B §0.7): cuánto le afectan desplazamientos y control duro.
enum Weight { LIGHT, MEDIUM, HEAVY, BOSS }

@export var id: StringName
@export var display_name := ""

@export_group("Simulación")
@export var hp := 10.0
## Casillas por segundo.
@export var speed := 1.4
## Reducción de daño (0–0,9) para los tipos de daño afectados por armadura.
@export_range(0.0, 0.9, 0.05) var armor := 0.0
## Oro al eliminarlo.
@export var bounty := 5
## Ligero: control completo · Medio: control duro a la mitad · Pesado: control duro
## muy breve · Jefe: inmune al control duro y ralentización reducida a la mitad.
@export var weight: Weight = Weight.LIGHT
## Vida que quita a la base si llega.
@export var base_damage := 1
## Daño a un héroe que lo bloquea, y segundos entre golpes.
@export var melee_damage := 2.0
@export var melee_interval := 1.0

@export_group("Mecánicas especiales")
## Al morir deja este «núcleo» (enemigo inmóvil). Si el núcleo sobrevive
## `revive_delay` segundos, el enemigo reaparece con `revive_hp_ratio` de su
## vida. Solo una vez por enemigo.
@export var revive_core: EnemyDef
@export var revive_delay := 6.0
@export_range(0.05, 1.0, 0.05) var revive_hp_ratio := 0.5
## Invoca `summon_count` enemigos de este tipo cada `summon_interval` segundos.
@export var summon_enemy: EnemyDef
@export var summon_interval := 0.0
@export var summon_count := 0
## Jefe: la interfaz muestra su barra de vida.
@export var is_boss := false

@export_group("Presentación")
@export var sprite: Texture2D
@export var hframes := 4
## Desplazamiento del sprite para que el origen del nodo sea el pie.
@export var sprite_offset := Vector2(0, -14)
@export var sprite_scale := 1.0
