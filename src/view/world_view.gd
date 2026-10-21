## Representación de la simulación: enemigos, torres, proyectiles y feedback.
## Lee el estado del mundo e interpreta sus eventos; nunca lo modifica.
extends Node2D

const SimWorld := preload("res://src/sim/sim_world.gd")
const Iso := preload("res://src/view/iso.gd")
const EnemyView := preload("res://src/view/enemy_view.gd")
const ProjectileView := preload("res://src/view/projectile_view.gd")
const TowerView := preload("res://src/view/tower_view.gd")
const FxPop := preload("res://src/view/fx_pop.gd")

var world: SimWorld
var selected_spot := -1

var _prev_e_pos := PackedVector2Array()
var _prev_p_pos := PackedVector2Array()
var _enemy_views: Array = []
var _projectile_views: Array = []
var _tower_views := {}  # torre (Dictionary) → TowerView
var _time := 0.0


func _init() -> void:
	y_sort_enabled = true


func bind(new_world: SimWorld) -> void:
	for child in get_children():
		child.queue_free()
	_enemy_views.clear()
	_projectile_views.clear()
	_tower_views.clear()
	world = new_world
	_sync_towers()
	snapshot()


## Guarda las posiciones antes de un tick para interpolar entre ticks.
func snapshot() -> void:
	_prev_e_pos = world.e_pos.duplicate()
	_prev_p_pos = world.p_pos.duplicate()


func handle_events(events: Array[Dictionary]) -> void:
	for ev in events:
		match ev.type:
			&"enemy_spawned":
				_reset_prev(_prev_e_pos, world.e_pos, ev.slot)
				_ensure_pool(_enemy_views, EnemyView, ev.slot + 1)
				_enemy_views[ev.slot].reset(ev.slot, world.e_def[ev.slot])
			&"projectile_fired":
				_reset_prev(_prev_p_pos, world.p_pos, ev.slot)
				_ensure_pool(_projectile_views, ProjectileView, ev.slot + 1)
				_projectile_views[ev.slot].set_source(world.p_tower_def[ev.slot])
			&"enemy_hit":
				if ev.slot < _enemy_views.size():
					_enemy_views[ev.slot].flash()
			&"enemy_killed":
				_spawn_fx(world.e_pos[ev.slot], Color("ffe066"), "+%d" % ev.bounty if ev.bounty > 0 else "")
			&"enemy_leaked":
				_spawn_fx(world.e_pos[ev.slot], Color("ff5c7a"), "-%d" % ev.damage)
			&"tower_built", &"tower_upgraded", &"tower_sold":
				_sync_towers()


func _process(delta: float) -> void:
	_time += delta


## Coloca las vistas según el estado actual; `alpha` interpola entre ticks.
func sync(alpha: float) -> void:
	var n := world.e_alive.size()
	_ensure_pool(_enemy_views, EnemyView, n)
	for i in n:
		var v = _enemy_views[i]
		if world.e_alive[i] == 0:
			v.visible = false
			continue
		v.visible = true
		var new_pos := Iso.to_screen(_lerp_slot(_prev_e_pos, world.e_pos, i, alpha))
		v.update_view(_time, new_pos.x - v.position.x, world.e_hp[i] / world.e_max_hp[i],
				world.effects.view_flags[i])
		v.position = new_pos

	var m := world.p_alive.size()
	_ensure_pool(_projectile_views, ProjectileView, m)
	for i in m:
		var pv: Node2D = _projectile_views[i]
		pv.visible = world.p_alive[i] == 1
		if pv.visible:
			pv.position = Iso.to_screen(_lerp_slot(_prev_p_pos, world.p_pos, i, alpha))


func set_selected_spot(spot: int) -> void:
	selected_spot = spot
	for t in _tower_views:
		_tower_views[t].set_selected(t.spot == spot and spot >= 0)


func _sync_towers() -> void:
	var alive := {}
	for t in world.towers:
		alive[t] = true
		if not _tower_views.has(t):
			var tv := TowerView.new()
			add_child(tv)
			_tower_views[t] = tv
		_tower_views[t].show_tower(t)
	for t in _tower_views.keys():
		if not alive.has(t):
			_tower_views[t].queue_free()
			_tower_views.erase(t)
	set_selected_spot(selected_spot)


func _spawn_fx(logical: Vector2, color: Color, text: String) -> void:
	var fx := FxPop.new()
	fx.color = color
	fx.text = text
	fx.position = Iso.to_screen(logical)
	add_child(fx)


## Un hueco reutilizado no debe interpolar desde la posición de su ocupante anterior.
func _reset_prev(prev: PackedVector2Array, cur: PackedVector2Array, slot: int) -> void:
	if slot < prev.size():
		prev[slot] = cur[slot]


func _ensure_pool(pool: Array, script: GDScript, size: int) -> void:
	while pool.size() < size:
		var v: Node2D = script.new()
		v.visible = false
		add_child(v)
		pool.append(v)


func _lerp_slot(prev: PackedVector2Array, cur: PackedVector2Array, i: int, alpha: float) -> Vector2:
	return prev[i].lerp(cur[i], alpha) if i < prev.size() else cur[i]
