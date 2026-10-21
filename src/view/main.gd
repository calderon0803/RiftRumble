## Controlador de la partida: carga la misión, crea la simulación y conecta
## la vista y la interfaz. Traduce las peticiones de la interfaz a comandos de la
## simulación (que los valida) y gestiona la selección en el mapa.
##
## Controles: clic/toque en una posición de construcción = construir/mejorar
##            Rueda o pellizco = zoom · arrastrar (botón derecho/central o un dedo) = cámara
##            Espacio/P = pausa · R = reiniciar · N = lanzar oleada · S = modo estrés (depuración)
## Argumentos de usuario (tras `--`): `--stress`, `--screenshot=ruta.png`, `--frames=N`,
##            `--autoplay` (construye una defensa y lanza oleadas solo, para capturas),
##            `--speed=N` (multiplica la velocidad del tiempo), `--select=N` (selecciona una posición).
extends Node2D

const SimWorld := preload("res://src/sim/sim_world.gd")
const MapDef := preload("res://src/content/map_def.gd")
const ContentDB := preload("res://src/content/content_db.gd")
const StressLayout := preload("res://src/poc/stress_layout.gd")
const Iso := preload("res://src/view/iso.gd")
const CameraRig := preload("res://src/view/camera_rig.gd")
const WorldView := preload("res://src/view/world_view.gd")
const Hud := preload("res://src/ui/hud.gd")
const BUILD_PAD := preload("res://art/placeholder/build_pad.png")

## Misión que se carga (más adelante la elegirá el menú de selección).
const MISSION_ID := &"w1_m1"
const STRESS_LEVELS := [150, 300, 500]
const STRESS_TOWERS := 12
## Radio (en casillas) para considerar que un toque selecciona una posición.
const SELECT_RADIUS := 0.9
## Movimiento máximo (px) para que una pulsación cuente como toque y no como arrastre.
const TAP_SLOP := 12.0

var content
var mission: MissionDef
var map_def: MapDef
var world: SimWorld
var paused := false
var stress := false
var stress_enemies := 500
var autoplay := false

var _acc := 0.0
var _sim_ms_avg := 0.0
var _world_root: Node2D
var _view: WorldView
var _camera: CameraRig
var _hud: Hud
var _press_pos := Vector2.ZERO
var _pressing := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	stress = "--stress" in args
	autoplay = "--autoplay" in args
	for arg in args:
		if arg.begins_with("--speed="):  # acelera el tiempo (pruebas de flujo completas)
			Engine.time_scale = float(arg.trim_prefix("--speed="))

	content = ContentDB.load_all()
	mission = content.missions[MISSION_ID]

	# Mapa y entidades comparten un antecesor con Y-sort para ordenarse entre sí.
	_world_root = Node2D.new()
	_world_root.name = "World"
	_world_root.y_sort_enabled = true
	add_child(_world_root)
	var map: Node2D = load(mission.map_scene).instantiate()
	_world_root.add_child(map)
	map_def = map.build_def()
	var problems := map_def.validate()
	assert(problems.is_empty(), "Mapa inválido: %s" % ", ".join(problems))
	_add_map_markers()

	_view = WorldView.new()
	_view.name = "Entities"
	_world_root.add_child(_view)

	_camera = CameraRig.new()
	add_child(_camera)
	_camera.setup(_map_bounds(), 1.3)

	_hud = Hud.new()
	add_child(_hud)
	_hud.build_requested.connect(func(spot, id): _command(world.build(spot, id)))
	_hud.upgrade_requested.connect(func(spot): _command(world.upgrade(spot)))
	_hud.sell_requested.connect(func(spot): _command(world.sell(spot)))
	_hud.start_wave_requested.connect(func(): _command(world.start_next_wave()))
	_hud.pause_toggled.connect(func(): paused = not paused)
	_hud.restart_requested.connect(_restart)
	_hud.close_panel_requested.connect(func(): _select(-1))

	_restart()
	_maybe_capture_screenshot()


func _restart() -> void:
	_acc = 0.0
	_sim_ms_avg = 0.0
	paused = false
	world = SimWorld.new(map_def.routes, 1234)
	world.setup_mission(content, mission, map_def)
	if stress:
		world.base_hp = 1_000_000_000
		# Torres de la misión en rotación (sin ids escritos a mano).
		var spots := StressLayout.tower_spots(map_def, STRESS_TOWERS)
		for i in spots.size():
			world.place_tower(content.towers[StringName(mission.towers[i % mission.towers.size()])], spots[i])
		for i in stress_enemies:
			world.spawn_enemy(40.0, 1.2, world.rng.randf_range(0.0, world.path.length * 0.95))
	_view.bind(world)
	_view.handle_events(world.drain_events())
	_hud.bind(world, content)
	_select(-1)


## Resultado de un comando: la simulación ya lo validó; aquí solo se informa.
func _command(result: StringName) -> void:
	if result != &"ok":
		print("Comando rechazado: %s" % result)
	_hud.select_spot(_view.selected_spot)


func _process(delta: float) -> void:
	if autoplay:
		_autoplay_step()
	if not paused and not world.is_over():
		_acc += minf(delta, 0.25 * Engine.time_scale)  # evita la «espiral de la muerte» tras un tirón
		while _acc >= SimWorld.DT:
			_acc -= SimWorld.DT
			_run_tick()
	_view.sync(_acc / SimWorld.DT)
	_hud.refresh(paused, "FPS %d · sim %.2f ms · enemigos %d · proyectiles %d" % [
		Engine.get_frames_per_second(), _sim_ms_avg, world.enemy_count, world.projectile_count])


func _run_tick() -> void:
	_view.snapshot()
	if stress:
		for i in mini(stress_enemies - world.enemy_count, 5):
			world.spawn_enemy(40.0, 1.2)
	var t0 := Time.get_ticks_usec()
	world.step()
	_sim_ms_avg = lerpf(_sim_ms_avg, (Time.get_ticks_usec() - t0) / 1000.0, 0.05)
	_view.handle_events(world.drain_events())


# --- Selección en el mapa --------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_press_pos = event.position
		elif _pressing:
			_pressing = false
			if event.position.distance_to(_press_pos) <= TAP_SLOP:
				_select(_spot_at(get_global_mouse_position()))
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE, KEY_P:
				paused = not paused
			KEY_R:
				_restart()
			KEY_N:
				_command(world.start_next_wave())
			KEY_S:
				_toggle_stress()
			KEY_ESCAPE:
				_select(-1)


func _spot_at(world_pos: Vector2) -> int:
	var logical := Iso.to_logical(world_pos)
	var best := -1
	var best_d := SELECT_RADIUS
	for i in map_def.build_spots.size():
		var d := logical.distance_to(map_def.build_spots[i])
		if d <= best_d:
			best_d = d
			best = i
	return best


func _select(spot: int) -> void:
	_view.set_selected_spot(spot)
	_hud.select_spot(spot)


func _toggle_stress() -> void:
	var next: int = STRESS_LEVELS.find(stress_enemies) + 1 if stress else 0
	stress = next < STRESS_LEVELS.size()
	if stress:
		stress_enemies = STRESS_LEVELS[next]
	_restart()


# --- Escenario y utilidades ---------------------------------------------------------

## Portal de entrada, base y plataformas de construcción (planos, sobre el suelo).
func _add_map_markers() -> void:
	var markers := MapMarkers.new()
	for route in map_def.routes:
		markers.spawns.append(Iso.to_screen(route[0]))
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


## Estrategia automática para capturas y pruebas de humo.
func _autoplay_step() -> void:
	# Una torre de cada tipo disponible, en orden, en las posiciones libres.
	for spot in map_def.build_spots.size():
		if world.tower_at(spot).is_empty():
			world.build(spot, StringName(mission.towers[spot % mission.towers.size()]))
	if not world.wave_active and not world.is_over():
		world.start_next_wave()


## `--screenshot=ruta.png [--frames=N]`: guarda una captura tras N frames y sale.
func _maybe_capture_screenshot() -> void:
	var out := ""
	var frames := 180
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			out = arg.trim_prefix("--screenshot=")
		elif arg.begins_with("--frames="):
			frames = int(arg.trim_prefix("--frames="))
		elif arg.begins_with("--select="):
			_select(int(arg.trim_prefix("--select=")))
	if out.is_empty():
		return
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var err := get_viewport().get_texture().get_image().save_png(out)
	print("SCREENSHOT %s (err=%d) fps=%d sim_ms=%.3f enemigos=%d oro=%d vida=%d oleada=%d resultado=%s" % [
		out, err, Engine.get_frames_per_second(), _sim_ms_avg, world.enemy_count, world.gold,
		world.base_hp, world.wave_index + 1, SimWorld.Outcome.keys()[world.outcome]])
	get_tree().quit()


## Marcas provisionales de los portales de entrada y de la base.
class MapMarkers extends Node2D:
	var spawns: Array[Vector2] = []
	var base := Vector2.ZERO

	func _draw() -> void:
		for s in spawns:
			_ring(s, Color("8a5cff"))
		_ring(base, Color("ff5c7a"))

	func _ring(c: Vector2, color: Color) -> void:
		draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 26.0, Color(color, 0.55))
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 32, color, 3.0)
		draw_set_transform(Vector2.ZERO)
