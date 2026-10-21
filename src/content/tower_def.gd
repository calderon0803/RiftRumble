## Definición de una torre. Todas comparten el mismo comportamiento de ataque;
## la identidad táctica sale de estos datos: tipo de daño, efecto al impactar,
## rebotes y penetración de armadura. Los arrays tienen un valor por nivel
## (índice 0 = nivel 1).
class_name TowerDef
extends Resource

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""

@export_group("Combate")
## Tipo de daño: la armadura y la corrupción dependen de él.
@export var damage_type: StringName = &"kinetic"
@export var damage := PackedFloat32Array([1.0])
## Segundos entre disparos.
@export var interval := PackedFloat32Array([1.0])
## Alcance en casillas.
@export var range_tiles := PackedFloat32Array([3.0])
## Velocidad del proyectil en casillas por segundo.
@export var projectile_speed := 10.0
## Efecto aplicado a cada objetivo alcanzado (opcional).
@export var on_hit_effect: EffectDef
## Fracción de armadura ignorada (0–1) por nivel.
@export var armor_pierce := PackedFloat32Array([0.0])

@export_group("Rebote")
## Saltos adicionales tras el primer impacto (0 = sin rebote) por nivel.
@export var bounces := PackedInt32Array([0])
## Distancia máxima de cada salto, en casillas.
@export var bounce_range := 2.5
## Multiplicador de daño en cada salto.
@export var bounce_damage_mult := 0.8

@export_group("Economía")
## Coste de construir (índice 0) y de cada mejora (índices 1…).
@export var cost := PackedInt32Array([50])
## Fracción de lo invertido que se recupera al vender.
@export var sell_refund := 0.7

@export_group("Presentación")
@export var sprite: Texture2D
@export var sprite_offset := Vector2(0, -26)
@export var projectile_sprite: Texture2D
## Nombre de la mejora de cada nivel (índice 0 = nivel 1, normalmente vacío).
@export var level_names := PackedStringArray([""])


func max_level() -> int:
	return cost.size()


## Valor de un array por nivel (1..max); si falta, usa el último definido.
static func at_level(values, level: int):
	return values[clampi(level - 1, 0, values.size() - 1)]
