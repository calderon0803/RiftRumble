## Vista de un enemigo: Sprite2D con hoja de animación compartida (todas las
## instancias usan la misma textura, lo que permite agrupar el dibujado).
## El origen del nodo es su «pie», que es lo que usa el Y-sort.
extends Sprite2D

const SHEET := preload("res://art/placeholder/enemy_glitchling.png")
const FRAMES := 4
const FPS := 8.0

var _hp_ratio := 1.0
var _bar: Node2D
var _phase := 0.0


func _init() -> void:
	texture = SHEET
	hframes = FRAMES
	offset = Vector2(0, -14)  # pie en (16, 30) de cada frame de 32×32
	_bar = HealthBar.new()
	_bar.visible = false
	add_child(_bar)


func reset(slot: int) -> void:
	_hp_ratio = 1.0
	_bar.visible = false
	_phase = slot * 0.37  # desincroniza la animación entre enemigos


func update_view(time: float, screen_dx: float, hp_ratio: float) -> void:
	frame = int((time + _phase) * FPS) % FRAMES
	if absf(screen_dx) > 0.01:
		flip_h = screen_dx < 0.0
	if not is_equal_approx(hp_ratio, _hp_ratio):
		_hp_ratio = hp_ratio
		_bar.visible = hp_ratio < 1.0
		_bar.ratio = hp_ratio
		_bar.queue_redraw()


class HealthBar extends Node2D:
	var ratio := 1.0

	func _draw() -> void:
		draw_rect(Rect2(-10, -34, 20, 3), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-10, -34, 20 * ratio, 3), Color("7dff8a"))
