## Escenario de una sala: colisiones de bloques y pinchos (los pinchos también
## son sólidos) y su dibujo provisional.
class_name RoomGeometry
extends Node2D

const COLOR_BLOCK := Color("3a4258")
const COLOR_EDGE := Color("6b7896")
const COLOR_SPIKE := Color("c9d2e8")
const COLOR_BENCH := Color("b08a5a")

var layout: RoomLayout


func setup(room: RoomLayout) -> void:
	layout = room
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


func _draw() -> void:
	for r in layout.solids:
		draw_rect(r, COLOR_BLOCK)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), COLOR_EDGE)
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
