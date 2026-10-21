## Sinergia: regla que modifica un efecto cuando el objetivo cumple una condición.
## Se evalúa en el sistema de efectos, sin código específico de torres o héroes:
## por ejemplo, «Error de sistema» = la corrupción acumula más rápido en enemigos
## ralentizados y, al llegar al máximo, se propaga a los cercanos.
class_name SynergyDef
extends Resource

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""

## Efecto que activa la sinergia al aplicarse.
@export var trigger_effect: EffectDef
## Bits de EffectDef.ViewFlag que el objetivo debe tener (cualquiera de ellos).
## Así, cualquier ralentización futura (no solo los sellos) participa.
@export_flags("Ralentizado", "Inmovilizado", "Corrompido", "Sellado") var requires_any_flags := 0

## Pilas extra del efecto disparador cuando se cumple la condición.
@export var extra_stacks := 0

## Al llegar el efecto a su máximo de pilas: se propaga a otros enemigos.
@export var spread_radius := 0.0
@export var spread_max_targets := 0
## Pilas que recibe cada enemigo alcanzado por la propagación.
@export var spread_stacks := 1
