## Vista de un enemigo: Sprite2D con hoja de animación de su EnemyDef (todas
## las instancias de un tipo comparten textura, lo que agrupa el dibujado).
## El origen del nodo es su «pie», que es lo que usa el Y-sort.
extends Sprite2D

const DEFAULT_SHEET := preload("res://art/placeholder/enemy_glitchling.png")
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
var _phase := 0.0
var _flash := 0.0
var _frames := 4


func _init() -> void:
	_bar = HealthBar.new()
	_bar.visible = false
	add_child(_bar)


func reset(slot: int, def: EnemyDef) -> void:
	if def and def.sprite:
		texture = def.sprite
		_frames = def.hframes
		offset = def.sprite_offset
	else:
		texture = DEFAULT_SHEET
		_frames = 4
		offset = Vector2(0, -14)
	hframes = _frames
	_hp_ratio = 1.0
	_bar.visible = false
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


class HealthBar extends Node2D:
	var ratio := 1.0

	func _draw() -> void:
		draw_rect(Rect2(-10, -34, 20, 3), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-10, -34, 20 * ratio, 3), Color("7dff8a"))
