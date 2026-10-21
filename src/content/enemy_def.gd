## Definición de un tipo de enemigo. La simulación usa las estadísticas;
## la vista usa los campos de presentación.
class_name EnemyDef
extends Resource

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
## Vida que quita a la base si llega.
@export var base_damage := 1
## Daño a un héroe que lo bloquea, y segundos entre golpes.
@export var melee_damage := 2.0
@export var melee_interval := 1.0

@export_group("Presentación")
@export var sprite: Texture2D
@export var hframes := 4
## Desplazamiento del sprite para que el origen del nodo sea el pie.
@export var sprite_offset := Vector2(0, -14)
