## Vista de un enemigo: Sprite2D con hoja de animación de su EnemyDef (todas
## las instancias de un tipo comparten textura, lo que agrupa el dibujado).
## El origen del nodo es su «pie», que es lo que usa el Y-sort.
extends Sprite2D

const DEFAULT_SHEET := preload("res://art/placeholder/enemy_light.png")
const FPS := 8.0
const FLASH_TIME := 0.08

## Tinte por estado (prioridad de arriba abajo). Usa los bits de EffectDef.ViewFlag.
const TINTS := [
	[2, Color(0.55, 0.95, 1.6)],  # inmovilizado
	[4, Color(1.5, 0.6, 1.5)],    # corrompido
	[1, Color(0.7, 0.8, 1.4)],    # ralentizado
]

var _hp_ratio := 1.0
var _bar: HealthBar
var _timer_ring: TimerRing
var _phase := 0.0
var _flash := 0.0
var _frames := 4


func _init() -> void:
	_bar = HealthBar.new()
	_bar.visible = false
	add_child(_bar)
	_timer_ring = TimerRing.new()
	_timer_ring.visible = false
	_timer_ring.z_index = -3
	add_child(_timer_ring)


func reset(slot: int, def: EnemyDef) -> void:
	if def and def.sprite:
		texture = def.sprite
		_frames = def.hframes
		offset = def.sprite_offset
		scale = Vector2.ONE * def.sprite_scale
	else:
		texture = DEFAULT_SHEET
		_frames = 4
		offset = Vector2(0, -14)
		scale = Vector2.ONE
	hframes = _frames
	_hp_ratio = 1.0
	_bar.visible = false
	_timer_ring.visible = false
	_flash = 0.0
	_phase = slot * 0.37  # desincroniza la animación entre enemigos


func flash() -> void:
	_flash = FLASH_TIME


func update_view(time: float, screen_dx: float, hp_ratio: float, flags: int) -> void:
	# Inmovilizado = animación congelada.
	if flags & 2 == 0:
		frame = int((time + _phase) * FPS) % _frames
	if absf(screen_dx) > 0.01:
		flip_h = screen_dx < 0.0
	var tint := Color.WHITE
	for t in TINTS:
		if flags & t[0]:
			tint = t[1]
			break
	if _flash > 0.0:
		_flash -= get_process_delta_time()
		tint = Color(2.2, 2.2, 2.2)
	modulate = tint
	if not is_equal_approx(hp_ratio, _hp_ratio):
		_hp_ratio = hp_ratio
		_bar.visible = hp_ratio < 1.0
		_bar.ratio = hp_ratio
		_bar.queue_redraw()


## Cuenta atrás visible (p. ej., núcleo de reaparición): `ratio` < 0 la oculta.
func set_timer(ratio: float) -> void:
	_timer_ring.visible = ratio >= 0.0
	if _timer_ring.visible and not is_equal_approx(ratio, _timer_ring.ratio):
		_timer_ring.ratio = ratio
		_timer_ring.queue_redraw()


## Anillo en el suelo que se vacía con el tiempo restante.
class TimerRing extends Node2D:
	var ratio := 1.0

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 40, Color(0, 0, 0, 0.45), 6.0)
		draw_arc(Vector2.ZERO, 26.0, -PI / 2, -PI / 2 + TAU * ratio, 40, Color("ff5fd2"), 5.0)
		draw_set_transform(Vector2.ZERO)


class HealthBar extends Node2D:
	var ratio := 1.0

	func _draw() -> void:
		draw_rect(Rect2(-10, -34, 20, 3), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-10, -34, 20 * ratio, 3), Color("7dff8a"))
