## Vistas de los elementos interactivos del mapa (bloques, monedas, plataformas).
## Solo representan el estado de SimObjects; no lo modifican.
extends RefCounted

const Iso := preload("res://src/view/iso.gd")


## Bloque rompible: sprite (dorado con premio o muro gris si cierra algo) y barra de vida.
class BlockView extends Sprite2D:
	const REWARD_TEX := preload("res://art/placeholder/prop_reward.png")
	const WALL_TEX := preload("res://art/placeholder/prop_wall.png")
	var _bar: Bar
	var _shake := 0.0
	var _glow := false
	var _t := 0.0

	func setup(block: Dictionary) -> void:
		var is_wall: bool = block.opens_route >= 0 or block.opens_spot >= 0
		texture = WALL_TEX if is_wall else REWARD_TEX
		_glow = not is_wall  # los bloques con premio laten para distinguirse del decorado
		offset = Vector2(0, -16)
		position = Iso.to_screen(block.pos)
		_bar = Bar.new()
		_bar.visible = false
		add_child(_bar)

	func hit(hp_ratio: float) -> void:
		_bar.visible = true
		_bar.ratio = hp_ratio
		_bar.queue_redraw()
		_shake = 0.12

	func _process(delta: float) -> void:
		_t += delta
		if _glow:
			var k := 1.0 + 0.25 * (0.5 + 0.5 * sin(_t * 4.0))
			modulate = Color(k, k, k)
		if _shake > 0.0:
			_shake -= delta
			offset = Vector2(randf_range(-1.5, 1.5), -16)
		elif offset.x != 0.0:
			offset = Vector2(0, -16)

	class Bar extends Node2D:
		var ratio := 1.0

		func _draw() -> void:
			draw_rect(Rect2(-16, -52, 32, 4), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(-16, -52, 32 * ratio, 4), Color("ffd34d"))


## Moneda: gira, flota y parpadea cuando está a punto de desaparecer.
class CoinView extends Sprite2D:
	const TEX := preload("res://art/placeholder/coin.png")
	var _t := 0.0
	var ticks_left := 999

	func _init() -> void:
		texture = TEX
		hframes = 4
		offset = Vector2(0, -10)
		scale = Vector2(1.5, 1.5)  # más grande: se toca con el dedo
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta
		frame = int(_t * 10.0) % 4
		offset.y = -10 - absf(sin(_t * 4.0)) * 3.0
		visible = ticks_left > 60 or int(_t * 8.0) % 2 == 0  # parpadeo en los 2 últimos segundos


## Plataforma de construcción (fija o móvil); atenuada y con candado si está cerrada.
class PadView extends Sprite2D:
	const TEX := preload("res://art/placeholder/build_pad.png")
	var locked := false

	func _init() -> void:
		texture = TEX
		z_index = -5

	func set_locked(value: bool) -> void:
		if value != locked:
			locked = value
			modulate = Color(1, 1, 1, 0.35) if locked else Color.WHITE
			queue_redraw()

	func _draw() -> void:
		if locked:  # candado sencillo
			draw_rect(Rect2(-6, -6, 12, 9), Color("ffd34d"))
			draw_arc(Vector2(0, -6), 4.0, PI, TAU, 10, Color("ffd34d"), 2.0)
