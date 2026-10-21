## Una oleada: grupos de enemigos que aparecen con un ritmo y un retraso.
## Los arrays van en paralelo (un elemento por grupo).
class_name WaveDef
extends Resource

## Id del EnemyDef de cada grupo.
@export var enemies := PackedStringArray()
@export var counts := PackedInt32Array()
## Segundos entre enemigos del mismo grupo.
@export var spacing := PackedFloat32Array()
## Segundos desde el inicio de la oleada hasta el primer enemigo del grupo.
@export var start_delay := PackedFloat32Array()
## Índice de ruta de cada grupo (0 = principal).
@export var route := PackedInt32Array()
## Oro extra al terminar la oleada.
@export var clear_bonus := 20


func total_enemies() -> int:
	var n := 0
	for c in counts:
		n += c
	return n
