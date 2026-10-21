## Representación de la simulación: enemigos, torres, proyectiles y feedback.
## Lee el estado del mundo e interpreta sus eventos; nunca lo modifica.
extends Node2D

const SimWorld := preload("res://src/sim/sim_world.gd")
const Iso := preload("res://src/view/iso.gd")
const EnemyView := preload("res://src/view/enemy_view.gd")
const ProjectileView := preload("res://src/view/projectile_view.gd")
const TowerView := preload("res://src/view/tower_view.gd")
const FxPop := preload("res://src/view/fx_pop.gd")
const FxLine := preload("res://src/view/fx_line.gd")
const HeroView := preload("res://src/view/hero_view.gd")
const PortalView := preload("res://src/view/portal_view.gd")

var world: SimWorld
var selected_spot := -1
var selected_hero := -1

var _prev_e_pos := PackedVector2Array()
var _prev_p_pos := PackedVector2Array()
var _enemy_views: Array = []
var _projectile_views: Array = []
## Claves por uid: un Dictionary como clave se identifica por su contenido, que
## cambia en cada tick (recargas, duración), así que no sirve como identidad.
var _tower_views := {}  # uid de torre → TowerView
var _hero_views: Array = []
var _prev_hero_pos := PackedVector2Array()
var _portal_views := {}  # uid de portal → PortalView
var _time := 0.0


func _init() -> void:
	y_sort_enabled = true


func bind(new_world: SimWorld) -> void:
	for child in get_children():
		child.queue_free()
	_enemy_views.clear()
	_projectile_views.clear()
	_tower_views.clear()
	_hero_views.clear()
	_portal_views.clear()
	world = new_world
	_sync_towers()
	for i in world.heroes.heroes.size():
		var hv := HeroView.new()
		hv.setup(world.heroes.heroes[i].def, i)
		add_child(hv)
		_hero_views.append(hv)
	snapshot()


## Guarda las posiciones antes de un tick para interpolar entre ticks.
func snapshot() -> void:
	_prev_e_pos = world.e_pos.duplicate()
	_prev_p_pos = world.p_pos.duplicate()
	_prev_hero_pos.resize(world.heroes.heroes.size())
	for i in world.heroes.heroes.size():
		_prev_hero_pos[i] = world.heroes.heroes[i].pos


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
			&"line_strike":
				var fx := FxLine.new()
				var lift := Vector2(0, -16)  # a la altura del cuerpo, no del suelo
				fx.from = Iso.to_screen(ev.from) + lift
				fx.to = Iso.to_screen(ev.to) + lift
				fx.color = world.heroes.heroes[ev.hero].def.color
				add_child(fx)
			&"hero_died":
				_spawn_fx(world.heroes.heroes[ev.hero].pos, Color("ff5c7a"), "¡KO!")
			&"synergy_spread":
				_spawn_fx(world.e_pos[ev.slot], Color("ff5fd2"), _synergy_name(ev.synergy))


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
		var revives: EnemyDef = world.e_revive_into[i]
		v.set_timer(world.e_timer[i] / (revives.revive_delay * SimWorld.TICK_RATE) if revives else -1.0)
		v.position = new_pos

	for i in _hero_views.size():
		var h: Dictionary = world.heroes.heroes[i]
		var hv = _hero_views[i]
		var hero_pos := Iso.to_screen(_prev_hero_pos[i].lerp(h.pos, alpha))
		hv.update_view(_time, hero_pos.x - hv.position.x, h.charge, i == selected_hero, h.ability_cd == 0,
				h.hp / h.def.max_hp, h.dead_ticks > 0)
		hv.position = hero_pos

	_sync_portals()

	var m := world.p_alive.size()
	_ensure_pool(_projectile_views, ProjectileView, m)
	for i in m:
		var pv: Node2D = _projectile_views[i]
		pv.visible = world.p_alive[i] == 1
		if pv.visible:
			pv.position = Iso.to_screen(_lerp_slot(_prev_p_pos, world.p_pos, i, alpha))


func set_selected_spot(spot: int) -> void:
	selected_spot = spot
	for t in world.towers:
		if _tower_views.has(t.uid):
			_tower_views[t.uid].set_selected(t.spot == spot and spot >= 0)


func _sync_towers() -> void:
	var alive := {}
	for t in world.towers:
		alive[t.uid] = true
		if not _tower_views.has(t.uid):
			var tv := TowerView.new()
			add_child(tv)
			_tower_views[t.uid] = tv
		_tower_views[t.uid].show_tower(t)
	for uid in _tower_views.keys():
		if not alive.has(uid):
			_tower_views[uid].queue_free()
			_tower_views.erase(uid)
	set_selected_spot(selected_spot)


func _sync_portals() -> void:
	var alive := {}
	for p in world.heroes.portals:
		alive[p.uid] = true
		if not _portal_views.has(p.uid):
			var pv := PortalView.new()
			pv.portal = p
			pv.color = world.heroes.heroes[p.hero_index].def.color
			add_child(pv)
			_portal_views[p.uid] = pv
	for uid in _portal_views.keys():
		if not alive.has(uid):
			_portal_views[uid].queue_free()
			_portal_views.erase(uid)


func _synergy_name(id: StringName) -> String:
	for syn: SynergyDef in world.synergies:
		if syn.id == id:
			return syn.display_name
	return String(id)


## Posición en pantalla (interpolada) de un héroe, para la selección por toque.
func hero_screen_pos(index: int) -> Vector2:
	return _hero_views[index].position


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
