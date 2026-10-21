## Escena de prueba de la Fase 2: carga el mapa del Reino del Continue,
## crea la simulación a partir de sus datos y la representa con sprites.
##
## Controles: S = recorrer modo estrés (150/300/500) · R = reiniciar · Espacio/P = pausa
##            Rueda o pellizco = zoom · arrastrar (botón derecho/central o un dedo) = cámara
## Argumentos de usuario (tras `--`): `--stress`, `--screenshot=ruta.png`, `--frames=N`.
extends Node2D

const SimWorld := preload("res://src/sim/sim_world.gd")
const MapDef := preload("res://src/content/map_def.gd")
const StressLayout := preload("res://src/poc/stress_layout.gd")
const Iso := preload("res://src/view/iso.gd")
const CameraRig := preload("res://src/view/camera_rig.gd")
const EnemyView := preload("res://src/view/enemy_view.gd")
const ProjectileView := preload("res://src/view/projectile_view.gd")
const TowerView := preload("res://src/view/tower_view.gd")
const BUILD_PAD := preload("res://art/placeholder/build_pad.png")

const MAP_SCENE := "res://maps/continue_01.tscn"
## Niveles del modo estrés; el botón/tecla recorre 150 → 300 → 500 → normal.
const STRESS_LEVELS := [150, 300, 500]
const STRESS_TOWERS := 12
const NORMAL_SPAWN_EVERY_TICKS := 20
const TOWER_RANGE := 3.5

var world: SimWorld
var map_def: MapDef
var stress := false
var stress_enemies := 500
var paused := false

var _acc := 0.0
var _time := 0.0
var _prev_e_pos := PackedVector2Array()
var _prev_p_pos := PackedVector2Array()
var _enemy_views: Array = []
var _projectile_views: Array = []
var _sim_ms_avg := 0.0
var _sim_ms_max := 0.0

var _world_root: Node2D
var _entities: Node2D
var _camera: CameraRig
var _hud: Label


func _ready() -> void:
	var user_args := OS.get_cmdline_user_args()
	if "--stress" in user_args:
		stress = true

	# Mapa y entidades comparten un antecesor con Y-sort para ordenarse entre sí.
	_world_root = Node2D.new()
	_world_root.name = "World"
	_world_root.y_sort_enabled = true
	add_child(_world_root)

	var map: Node2D = load(MAP_SCENE).instantiate()
	_world_root.add_child(map)
	map_def = map.build_def()
	var problems := map_def.validate()
	assert(problems.is_empty(), "Mapa inválido: %s" % ", ".join(problems))

	_add_map_markers()

	_entities = Node2D.new()
	_entities.name = "Entities"
	_entities.y_sort_enabled = true
	_world_root.add_child(_entities)

	_camera = CameraRig.new()
	add_child(_camera)
	_camera.setup(_map_bounds(), 1.3)

	_build_hud()
	_restart()
	_maybe_capture_screenshot()


## Portal de entrada, base y plataformas de construcción (planos, sobre el suelo).
func _add_map_markers() -> void:
	var route := map_def.routes[0]
	var markers := MapMarkers.new()
	markers.spawn = Iso.to_screen(route[0])
	markers.base = Iso.to_screen(route[route.size() - 1])
	markers.z_index = -5
	_world_root.add_child(markers)
	for spot in map_def.build_spots:
		var pad := Sprite2D.new()
		pad.texture = BUILD_PAD
		pad.position = Iso.to_screen(spot)
		pad.z_index = -5
		_world_root.add_child(pad)


func _map_bounds() -> Rect2:
	var s := Vector2(map_def.size)
	var r := Rect2(Iso.to_screen(Vector2.ZERO), Vector2.ZERO)
	for c in [Vector2(s.x, 0), s, Vector2(0, s.y)]:
		r = r.expand(Iso.to_screen(c))
	return r


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(12, 8)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 4)
	layer.add_child(_hud)
	# Botones táctiles (equivalen a S y R) para probar en móvil.
	var buttons := HBoxContainer.new()
	buttons.position = Vector2(12, 150)
	layer.add_child(buttons)
	for spec in [["Estrés", _toggle_stress], ["Reiniciar", _restart]]:
		var b := Button.new()
		b.text = spec[0]
		b.custom_minimum_size = Vector2(120, 48)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(spec[1])
		buttons.add_child(b)


## `--screenshot=ruta.png [--frames=N]`: guarda una captura tras N frames y sale.
func _maybe_capture_screenshot() -> void:
	var out := ""
	var frames := 180
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			out = arg.trim_prefix("--screenshot=")
		elif arg.begins_with("--frames="):
			frames = int(arg.trim_prefix("--frames="))
	if out.is_empty():
		return
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var err := get_viewport().get_texture().get_image().save_png(out)
	print("SCREENSHOT %s (err=%d) fps=%d sim_ms=%.3f enemigos=%d proyectiles=%d" % [
		out, err, Engine.get_frames_per_second(), _sim_ms_avg, world.enemy_count, world.projectile_count])
	get_tree().quit()


func _toggle_stress() -> void:
	var next: int = STRESS_LEVELS.find(stress_enemies) + 1 if stress else 0
	stress = next < STRESS_LEVELS.size()
	if stress:
		stress_enemies = STRESS_LEVELS[next]
	_restart()


func _restart() -> void:
	for child in _entities.get_children():
		child.queue_free()
	_enemy_views.clear()
	_projectile_views.clear()
	_acc = 0.0
	_sim_ms_avg = 0.0
	_sim_ms_max = 0.0

	world = SimWorld.new(map_def.routes[0], 1234)
	var spots := StressLayout.tower_spots(map_def, STRESS_TOWERS) if stress \
			else PackedVector2Array([map_def.build_spots[1]])
	for spot in spots:
		world.add_tower(spot, TOWER_RANGE, 0.5, 1.0, 10.0)
		var tv := TowerView.new()
		tv.setup(spot, TOWER_RANGE, not stress)
		_entities.add_child(tv)

	if stress:
		world.base_hp = 1_000_000_000
		for i in stress_enemies:
			world.spawn_enemy(40.0, 1.2, world.rng.randf_range(0.0, world.path.length * 0.95))
	_handle_events()
	_prev_e_pos = world.e_pos.duplicate()
	_prev_p_pos = world.p_pos.duplicate()


func _process(delta: float) -> void:
	if not paused and not world.is_lost():
		_time += delta
		_acc += minf(delta, 0.25)  # evita la «espiral de la muerte» tras un tirón
		while _acc >= SimWorld.DT:
			_acc -= SimWorld.DT
			_run_tick()
	_sync_views(_acc / SimWorld.DT)
	_update_hud()


func _run_tick() -> void:
	_prev_e_pos = world.e_pos.duplicate()
	_prev_p_pos = world.p_pos.duplicate()

	if stress:
		var to_spawn := mini(stress_enemies - world.enemy_count, 5)
		for i in to_spawn:
			world.spawn_enemy(40.0, 1.2)
	elif world.tick % NORMAL_SPAWN_EVERY_TICKS == 0:
		world.spawn_enemy(6.0, 1.6)

	var t0 := Time.get_ticks_usec()
	world.step()
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	_sim_ms_avg = lerpf(_sim_ms_avg, ms, 0.05)
	_sim_ms_max = maxf(_sim_ms_max * 0.995, ms)
	_handle_events()


func _handle_events() -> void:
	for ev in world.drain_events():
		match ev.type:
			&"enemy_spawned":
				_reset_prev(_prev_e_pos, world.e_pos, ev.slot)
				_ensure_pool(_enemy_views, EnemyView, ev.slot + 1)
				_enemy_views[ev.slot].reset(ev.slot)
			&"projectile_fired":
				_reset_prev(_prev_p_pos, world.p_pos, ev.slot)


## Un hueco reutilizado no debe interpolar desde la posición de su ocupante anterior.
func _reset_prev(prev: PackedVector2Array, cur: PackedVector2Array, slot: int) -> void:
	if slot < prev.size():
		prev[slot] = cur[slot]


func _ensure_pool(pool: Array, script: GDScript, size: int) -> void:
	while pool.size() < size:
		var v: Node2D = script.new()
		v.visible = false
		_entities.add_child(v)
		pool.append(v)


func _sync_views(alpha: float) -> void:
	var n := world.e_alive.size()
	_ensure_pool(_enemy_views, EnemyView, n)
	for i in n:
		var v = _enemy_views[i]
		if world.e_alive[i] == 0:
			v.visible = false
			continue
		v.visible = true
		var new_pos := Iso.to_screen(_lerp_slot(_prev_e_pos, world.e_pos, i, alpha))
		v.update_view(_time, new_pos.x - v.position.x, world.e_hp[i] / world.e_max_hp[i])
		v.position = new_pos

	var m := world.p_alive.size()
	_ensure_pool(_projectile_views, ProjectileView, m)
	for i in m:
		var pv: Node2D = _projectile_views[i]
		pv.visible = world.p_alive[i] == 1
		if pv.visible:
			pv.position = Iso.to_screen(_lerp_slot(_prev_p_pos, world.p_pos, i, alpha))


func _lerp_slot(prev: PackedVector2Array, cur: PackedVector2Array, i: int, alpha: float) -> Vector2:
	return prev[i].lerp(cur[i], alpha) if i < prev.size() else cur[i]


func _update_hud() -> void:
	var status := ""
	if world.is_lost():
		status = "\nBASE DESTRUIDA — R para reiniciar"
	elif paused:
		status = "\nPAUSA"
	_hud.text = "RIFT RUMBLE · Reino del Continue  [%s]\nFPS %d · sim %.2f ms/tick (máx %.2f)\nEnemigos %d · Proyectiles %d · Torres %d\nBase %s · Tick %d%s\nS estrés (150/300/500) · R reiniciar · Espacio pausa" % [
		"ESTRÉS %d" % stress_enemies if stress else "NORMAL",
		Engine.get_frames_per_second(), _sim_ms_avg, _sim_ms_max,
		world.enemy_count, world.projectile_count, world.towers.size(),
		"∞" if stress else str(world.base_hp), world.tick, status,
	]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_S:
				_toggle_stress()
			KEY_R:
				_restart()
			KEY_SPACE, KEY_P:
				paused = not paused


## Marcas provisionales del portal de entrada y de la base.
class MapMarkers extends Node2D:
	var spawn := Vector2.ZERO
	var base := Vector2.ZERO

	func _draw() -> void:
		_ring(spawn, Color("8a5cff"))
		_ring(base, Color("ff5c7a"))

	func _ring(c: Vector2, color: Color) -> void:
		draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 26.0, Color(color, 0.55))
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 32, color, 3.0)
		draw_set_transform(Vector2.ZERO)
