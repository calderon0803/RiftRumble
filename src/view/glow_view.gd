## Pinta con mezcla aditiva los brillos que apunta otra vista (`source.glows`: [posición, radio, color]).
class_name GlowView
extends Node2D

var source: Node


func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m


func _draw() -> void:
	if source == null:
		return
	var tex := Paint.glow_tex()
	for gl in source.glows:
		var p: Vector2 = gl[0]
		var r: float = gl[1]
		draw_texture_rect(tex, Rect2(p - Vector2(r, r), Vector2(r, r) * 2), false, gl[2])
