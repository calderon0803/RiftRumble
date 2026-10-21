## Escena de la PoC: conecta la simulación pura con la vista isométrica.
##
## Controles: S = alternar modo estrés · R = reiniciar · Espacio/P = pausa
##            Rueda = zoom · botón derecho/central arrastrando = mover cámara
## Argumento de usuario `--stress` (tras `--`) arranca directamente en modo estrés.
extends Node2D

const SimWorld := preload("res://src/sim/sim_world.gd")
const PocMap := preload("res://src/poc/poc_map.gd")
const Iso := preload("res://src/view/iso.gd")
const GroundView := preload("res://src/view/ground_view.gd")
const EnemyView := preload("res://src/view/enemy_view.gd")
const ProjectileView := preload("res://src/view/projectile_view.gd")
const TowerView := preload("res://src/view/tower_view.gd")

## Niveles del modo estrés; el botón/tecla recorre 150 → 300 → 500 → normal.
const STRESS_LEVELS := [150, 300, 500]
const NORMAL_SPAWN_EVERY_TICKS := 20

var world: SimWorld
var stress := false
var stress_enemies := 500
var paused := false

var _acc := 0.0
var _prev_e_pos := PackedVector2Array()
var _prev_p_pos := PackedVector2Array()
var _enemy_views: Array = []  # sin tipar: los nodos usan scripts de vista propios
var _projectile_views: Array = []
var _sim_ms_avg := 0.0
var _sim_ms_max := 0.0

var _entities: Node2D
var _camera: Camera2D
var _hud: Label
var _dragging := false


func _ready() -> void:
	stress = "--stress" in OS.get_cmdline_user_args()

	var ground := GroundView.new()
	ground.map_size = PocMap.SIZE
	ground.waypoints = PocMap.waypoints()
	add_child(ground)

	_entities = Node2D.new()
	_entities.name = "Entities"
	_entities.y_sort_enabled = true
	add_child(_entities)

	_camera = Camera2D.new()
	_camera.position = Iso.to_screen(Vector2(PocMap.SIZE) * 0.5)
	_camera.zoom = Vector2(1.2, 1.2)
	add_child(_camera)

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

	_restart()
	_maybe_capture_screenshot()


## `-- --screenshot=ruta.png [--frames=N]`: guarda una captura tras N frames y sale.
## Permite validar la vista de forma automática (agentes, CI).
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
	var next := STRESS_LEVELS.find(stress_enemies) + 1 if stress else 0
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

	world = SimWorld.new(PocMap.waypoints(), 1234)
	var spots: Array = PocMap.STRESS_TOWER_SPOTS if stress else [PocMap.TOWER_SPOT]
	for spot: Vector2 in spots:
		var range_tiles := 3.5
		world.add_tower(spot, range_tiles, 0.5, 1.0, 10.0)
		var tv := TowerView.new()
		tv.logical_pos = spot
		tv.range_tiles = range_tiles
		tv.show_range = not stress
		tv.position = Iso.to_screen(spot)
		_entities.add_child(tv)

	if stress:
		world.base_hp = 1_000_000_000
		for i in stress_enemies:
			world.spawn_enemy(40.0, 1.2, world.rng.randf_range(0.0, world.path.length * 0.95))
	_prev_e_pos = world.e_pos.duplicate()
	_prev_p_pos = world.p_pos.duplicate()


func _process(delta: float) -> void:
	if not paused and not world.is_lost():
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

	for ev in world.drain_events():
		match ev.type:
			&"enemy_spawned":
				_reset_prev(_prev_e_pos, world.e_pos, ev.slot)
				_ensure_pool(_enemy_views, EnemyView, ev.slot + 1)
				_enemy_views[ev.slot].reset()
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
		v.position = Iso.to_screen(_lerp_slot(_prev_e_pos, world.e_pos, i, alpha))
		v.set_hp_ratio(world.e_hp[i] / world.e_max_hp[i])

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
	_hud.text = "RIFT RUMBLE · PoC  [%s]\nFPS %d · sim %.2f ms/tick (máx %.2f)\nEnemigos %d · Proyectiles %d · Torres %d\nBase %s · Tick %d%s\nS estrés (150/300/500) · R reiniciar · Espacio pausa" % [
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
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_camera.zoom = (_camera.zoom * 1.1).clampf(0.4, 4.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				_camera.zoom = (_camera.zoom / 1.1).clampf(0.4, 4.0)
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		_camera.position -= event.relative / _camera.zoom
