## Vista de un héroe: sprite animado, anillo de selección, alcance de su
## ataque básico al seleccionarlo y marcas de carga (si las usa).
extends Sprite2D

const Iso := preload("res://src/view/iso.gd")
const FPS := 5.0

var def: HeroDef
var _ring: SelectionRing
var _charge: ChargePips
var _hp_bar: HpBar
var _meter_bar: MeterBar
var _phase := 0.0


func setup(hero_def: HeroDef, index: int) -> void:
	def = hero_def
	texture = def.sprite
	hframes = def.hframes
	offset = def.sprite_offset
	_phase = index * 0.5
	_ring = SelectionRing.new()
	_ring.color = def.color
	_ring.range_tiles = TowerDef.at_level(def.attack.range_tiles, 1) if def.attack else 0.0
	_ring.z_index = -4
	add_child(_ring)
	_charge = ChargePips.new()
	_charge.max_charge = def.edge_max
	_charge.color = def.color
	add_child(_charge)
	_hp_bar = HpBar.new()
	add_child(_hp_bar)
	_meter_bar = MeterBar.new()
	_meter_bar.color = def.color
	add_child(_meter_bar)


func update_view(time: float, screen_dx: float, edge: int, selected: bool, meter_ratio: float,
		hp_ratio: float, dead: bool) -> void:
	var ability_ready := meter_ratio >= 1.0
	if not is_equal_approx(_meter_bar.ratio, meter_ratio):
		_meter_bar.ratio = meter_ratio
		_meter_bar.queue_redraw()
	_meter_bar.visible = not dead
	# Caído: translúcido y gris hasta reaparecer.
	modulate = Color(0.6, 0.6, 0.7, 0.35) if dead else Color.WHITE
	if not is_equal_approx(_hp_bar.ratio, hp_ratio):
		_hp_bar.ratio = hp_ratio
		_hp_bar.queue_redraw()
	_hp_bar.visible = not dead
	frame = int((time + _phase) * FPS) % hframes
	if absf(screen_dx) > 0.05:
		flip_h = screen_dx < 0.0
	_ring.selected = selected
	_ring.ability_ready = ability_ready
	_ring.queue_redraw()
	if _charge.charge != edge:
		_charge.charge = edge
		_charge.queue_redraw()


## Anillo bajo el héroe: visible siempre (más intenso si su habilidad está lista);
## al seleccionarlo muestra además el alcance de su ataque básico.
class SelectionRing extends Node2D:
	var color := Color.WHITE
	var range_tiles := 0.0
	var selected := false
	var ability_ready := false

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, Color(color, 0.9 if ability_ready else 0.35), 2.5 if selected else 1.5)
		draw_set_transform(Vector2.ZERO)
		if selected and range_tiles > 0.0:
			var pts := PackedVector2Array()
			for i in 49:
				var a := TAU * i / 48.0
				pts.append(Iso.to_screen(Vector2(cos(a), sin(a)) * range_tiles))
			draw_polyline(pts, Color(color, 0.5), 1.5)


class HpBar extends Node2D:
	var ratio := 1.0

	func _draw() -> void:
		draw_rect(Rect2(-12, -46, 24, 4), Color(0, 0, 0, 0.65))
		var col := Color("7dff8a") if ratio > 0.5 else (Color("ffd34d") if ratio > 0.25 else Color("ff5c7a"))
		draw_rect(Rect2(-12, -46, 24 * ratio, 4), col)


## Medidor de habilidad bajo la barra de vida (brilla al llegar al 100 %).
class MeterBar extends Node2D:
	var ratio := 0.0
	var color := Color.WHITE

	func _draw() -> void:
		draw_rect(Rect2(-12, -41, 24, 3), Color(0, 0, 0, 0.65))
		draw_rect(Rect2(-12, -41, 24 * ratio, 3), Color.WHITE if ratio >= 1.0 else color)


## Filo (carga propia de algunos héroes, p. ej., Kira).
class ChargePips extends Node2D:
	var charge := 0
	var max_charge := 0
	var color := Color.WHITE

	func _draw() -> void:
		for i in max_charge:
			var c := Vector2((i - (max_charge - 1) * 0.5) * 6.0, -52.0)
			draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), color if i < charge else Color(0, 0, 0, 0.5))
