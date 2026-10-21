## Datos del mapa de la PoC (en casillas lógicas).
## En la Fase 2 se sustituirá por un MapDef editable en el editor.
extends RefCounted

const SIZE := Vector2i(16, 16)

const WAYPOINTS := [
	Vector2(0.5, 2.5), Vector2(11.5, 2.5), Vector2(11.5, 7.5),
	Vector2(3.5, 7.5), Vector2(3.5, 12.5), Vector2(15.5, 12.5),
]

## Torre única del modo normal (junto al primer codo de la ruta).
const TOWER_SPOT := Vector2(9.5, 5.0)

## Torres adicionales del modo estrés.
const STRESS_TOWER_SPOTS := [
	Vector2(2.5, 4.5), Vector2(6.5, 4.5), Vector2(9.5, 5.0), Vector2(13.5, 4.5),
	Vector2(6.5, 9.5), Vector2(1.5, 9.5), Vector2(9.5, 10.0), Vector2(6.5, 14.5),
	Vector2(10.5, 14.5), Vector2(14.5, 10.0), Vector2(13.5, 0.5), Vector2(1.5, 14.5),
]


static func waypoints() -> PackedVector2Array:
	return PackedVector2Array(WAYPOINTS)
