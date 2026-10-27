## Escenario de una sala: colisiones de bloques y pinchos (los pinchos también
## son sólidos) y su dibujo provisional, con los colores de la zona.
class_name RoomGeometry
extends Node2D

const COLOR_SPIKE := Color("c9d2e8")
const COLOR_BENCH := Color("b08a5a")

var layout: RoomLayout
var _pal: Dictionary


func setup(room: RoomLayout) -> void:
	layout = room
	_pal = Themes.palette(room.theme)
	var body := StaticBody2D.new()
	body.collision_layer = Kira.LAYER_WORLD
	add_child(body)
	for r in room.solids + room.spikes:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		shape.shape = rect
		shape.position = r.get_center()
		body.add_child(shape)
	queue_redraw()


## ¿Hay aire encima de algún tramo del bloque? (para el borde claro)
func _open_above(r: Rect2) -> bool:
	var o := layout.rect.position
	var row := int((r.position.y - o.y) / RoomLayout.TILE) - 1
	var c0 := int((r.position.x - o.x) / RoomLayout.TILE)
	for c in range(c0, c0 + int(r.size.x / RoomLayout.TILE)):
		if layout.is_open(c, row):
			return true
	return false


func _draw() -> void:
	var tile := float(RoomLayout.TILE)
	for r in layout.solids:
		draw_rect(r, _pal.block)
		# Sombra abajo, juntas entre casillas y borde de arriba solo si es superficie pisable.
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 6), Vector2(r.size.x, 6)), _pal.block_shadow)
		var n := int(r.size.x / tile)
		for i in range(1, n):
			var x := r.position.x + i * tile
			draw_line(Vector2(x, r.position.y + 4), Vector2(x, r.end.y - 6), Color(_pal.block_shadow, 0.6), 1.0)
		if _open_above(r):
			draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), _pal.block_top)
	for r in layout.spikes:
		var n := int(r.size.x / 16)
		for i in n:
			var x := r.position.x + i * 16
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, r.end.y), Vector2(x + 8, r.position.y + 4), Vector2(x + 16, r.end.y)]), COLOR_SPIKE)
	if layout.bench != Vector2.INF:
		var p := layout.bench
		draw_rect(Rect2(p + Vector2(-26, -14), Vector2(52, 6)), COLOR_BENCH)
		draw_rect(Rect2(p + Vector2(-22, -8), Vector2(5, 8)), COLOR_BENCH)
		draw_rect(Rect2(p + Vector2(17, -8), Vector2(5, 8)), COLOR_BENCH)
