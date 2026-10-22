## Definición de un héroe: movimiento, ataque básico y habilidad activa.
## El ataque básico reutiliza el perfil de ataque de las torres (TowerDef).
## La habilidad se elige por `ability_kind`; sus parámetros son genéricos para
## que varios héroes puedan compartir un mismo tipo de habilidad.
class_name HeroDef
extends Resource

## Tipos de habilidad implementados en la simulación (sim_heroes.gd).
const ABILITY_PORTAL := &"portal"
const ABILITY_LINE_STRIKE := &"line_strike"

@export var id: StringName
@export var display_name := ""
@export var title := ""
@export_multiline var description := ""

@export_group("Combate en el camino")
## Los héroes se colocan en el camino y bloquean enemigos que luchan con ellos.
@export var max_hp := 60.0
## Vida recuperada por segundo mientras no lucha.
@export var regen_per_second := 3.0
## Segundos hasta reaparecer tras caer.
@export var respawn_time := 10.0
## Enemigos que puede bloquear a la vez.
@export var block_count := 2
## Distancia (casillas) a la que bloquea a un enemigo.
@export var engage_radius := 0.9

@export_group("Movimiento y ataque")
## Casillas por segundo.
@export var move_speed := 2.5
## Ataque automático (se usa el nivel 1 del perfil).
@export var attack: TowerDef
## «Filo»: carga propia de algunos héroes (p. ej., Kira) que gana cada golpe del
## ataque básico y que su habilidad consume para hacer más daño (0 = no usa filo).
## No confundir con el medidor de habilidad, común a todos (docs/personajes/B §0.6).
@export var edge_per_hit := 0
@export var edge_max := 0

@export_group("Habilidad")
@export var ability_kind: StringName
@export var ability_name := ""
@export_multiline var ability_description := ""
## Distancia máxima desde el héroe al punto elegido (casillas).
@export var ability_range := 8.0
## Duración de los efectos persistentes (p. ej., el portal), en segundos.
@export var ability_duration := 0.0
## Radios y medidas, en casillas.
@export var ability_radius := 3.0
@export var ability_length := 5.0
@export var ability_width := 0.9
## Portal: las torres a esta distancia de la entrada pueden disparar a través de él.
@export var ability_link_radius := 3.0
## Daño: base + por cada punto de filo consumido.
@export var ability_damage := 0.0
@export var ability_damage_per_edge := 0.0
@export var ability_damage_type: StringName = &"energy"
@export var ability_armor_pierce := 0.0
## Multiplicador aplicado a lo que la habilidad redirige (portal).
@export var ability_damage_mult := 1.0

@export_group("Presentación")
@export var sprite: Texture2D
@export var hframes := 4
@export var sprite_offset := Vector2(0, -20)
@export var color := Color.WHITE
