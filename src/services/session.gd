## Datos de la partida elegida en la campaña, compartidos entre pantallas
## (autoload «Session»). La escena de juego los lee al empezar.
extends Node

## Misión por defecto si se abre la escena de juego directamente (pruebas).
const DEFAULT_MISSION := "w1_m5"

var mission_id := ""
var hero_ids := PackedStringArray()
var tower_ids := PackedStringArray()


func mission_or_default() -> String:
	return mission_id if mission_id != "" else DEFAULT_MISSION
