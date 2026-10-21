## Definición de un efecto de estado (ralentización, corrupción, sellos…).
## Un solo sistema interpreta estos datos; ningún arma o torre programa su
## propio efecto.
class_name EffectDef
extends Resource

## Bits para que la vista represente estados sin conocer los efectos concretos.
enum ViewFlag { NONE = 0, SLOWED = 1, ROOTED = 2, CORRUPTED = 4, SEALED = 8 }

@export var id: StringName
## Duración en segundos. Cada nueva aplicación la renueva.
@export var duration := 2.0
## Pilas máximas (1 = no acumulable).
@export var max_stacks := 1
## Multiplicador de velocidad por pila (0.8 = −20 % por pila).
@export var speed_mult_per_stack := 1.0
## Inmoviliza al objetivo mientras dure.
@export var root := false
## Daño adicional recibido por pila (0.15 = +15 %).
@export var damage_taken_bonus_per_stack := 0.0
## El daño de este tipo NO se amplifica (p. ej. la corrupción no potencia a la
## propia torre de corrupción: prepara al objetivo para *otros* tipos).
@export var bonus_excludes_damage_type: StringName
## Al llegar a `max_stacks`: aplica este efecto y elimina las pilas propias.
@export var on_max_stacks: EffectDef
## Tras dispararse `on_max_stacks`, este efecto no puede reaplicarse durante
## este tiempo (evita inmovilizaciones permanentes).
@export var immunity_after_trigger := 0.0
@export_flags("Ralentizado", "Inmovilizado", "Corrompido", "Sellado") var view_flags := 0
