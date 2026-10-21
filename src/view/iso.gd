## Única conversión entre coordenadas lógicas (casillas) y pantalla isométrica.
extends RefCounted

const TILE_W := 64.0
const TILE_H := 32.0


static func to_screen(logical: Vector2) -> Vector2:
	return Vector2((logical.x - logical.y) * TILE_W * 0.5, (logical.x + logical.y) * TILE_H * 0.5)


static func to_logical(screen: Vector2) -> Vector2:
	var a := screen.x / (TILE_W * 0.5)
	var b := screen.y / (TILE_H * 0.5)
	return Vector2((a + b) * 0.5, (b - a) * 0.5)
