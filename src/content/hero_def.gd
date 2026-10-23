## Definición de un héroe: movimiento, ataque básico y habilidad activa.
## El ataque básico reutiliza el perfil de ataque de las torres (TowerDef).
## La habilidad se elige por `ability_kind`; sus parámetros son genéricos para
## que varios héroes puedan compartir un mismo tipo de habilidad.
class_name HeroDef
extends Resource

## Tipos de habilidad implementados en la simulación (sim_heroes.gd).
const ABILITY_PORTAL := &"portal"
const ABILITY_LINE_STRIKE := &"line_strike"
## Área instantánea alrededor del héroe (daño, efecto, empuje y escudo opcionales).
const ABILITY_BURST_SELF := &"burst_self"
## Zona colocada con daño periódico y un efecto al terminar.
const ABILITY_ZONE := &"zone"

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
## Reducción del daño recibido (0,04 × Defensa; tope 0,4; docs/personajes/H).
@export_range(0.0, 0.6, 0.01) var defense := 0.0

@export_group("Crecimiento por nivel")
## Fracción que ganan la vida y el ataque por cada nivel por encima del 1
## (G-10: según el rol). La defensa, la velocidad y el alcance no crecen.
@export var growth_hp := 0.0
@export var growth_attack := 0.0

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
## Golpe en cono o a adyacentes: enemigos extra (a ≤ `cleave_radius` del objetivo)
## que reciben `cleave_mult` del daño.
@export var cleave_targets := 0
@export var cleave_radius := 1.0
@export var cleave_mult := 0.5
## Si no está vacío, los golpes alternan entre el tipo del ataque y este.
@export var alt_damage_type: StringName

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
## Daño en múltiplos de P (el DPS del héroe a su nivel; docs/personajes/H §1).
## Si es > 0 sustituye a `ability_damage` y al filo.
@export var ability_power := 0.0
## Línea: cada enemigo atravesado suma este extra a los siguientes, con tope.
@export var ability_ramp_per_target := 0.0
@export var ability_ramp_max := 0.0
## Efecto aplicado a cada enemigo alcanzado (ralentización, derribo…).
@export var ability_effect: EffectDef
## Empuje hacia atrás en la ruta (casillas; ligeros completo, medios la mitad).
@export var ability_push := 0.0
## Zona: daño por segundo en múltiplos de P y efecto al terminar sobre los que sigan dentro.
@export var ability_zone_power := 0.0
@export var ability_end_effect: EffectDef
## Escudo a los héroes del área (fracción de su vida máxima; tope 0,4) durante
## `ability_duration`; mientras lo tengan, bloquean `ability_shield_block_bonus` más.
@export_range(0.0, 0.4, 0.01) var ability_shield := 0.0
@export var ability_shield_block_bonus := 0

@export_group("Presentación")
## Sprite simple de un fila (marcadores de posición); se ignora si hay `anim_sheet`.
@export var sprite: Texture2D
## Hoja de animación (docs/arte/01-biblia-visual.md §7): una fila por animación
## (reposo, andar, ataque), celdas iguales, pies en el centro inferior.
@export var anim_sheet: Texture2D
@export var anim_frames := PackedInt32Array([4, 6, 6])
@export var anim_fps := PackedFloat32Array([8.0, 12.0, 14.0])
@export var anim_columns := 6
## Se dibuja a 2×: escala 0,5 en pantalla.
@export var anim_scale := 0.5
## Desplazamiento (en píxeles de la hoja) para que los pies queden en el origen.
@export var anim_offset := Vector2(0, -60)
@export var hframes := 4
@export var sprite_offset := Vector2(0, -20)
@export var color := Color.WHITE
