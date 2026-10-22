## Controlador de la partida: carga la misión, crea la simulación y conecta
## la vista y la interfaz. Traduce las peticiones de la interfaz a comandos de la
## simulación (que los valida) y gestiona la selección en el mapa.
##
## Controles: clic/toque en una posición de construcción = construir/mejorar
##            toque en un héroe (o su tarjeta, o 1/2) = seleccionarlo; toque en el mapa = moverlo
##            botón de habilidad (o Q) y toque en el mapa = lanzar la habilidad
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
const AudioDirector := preload("res://src/audio/audio_director.gd")
const SaveService := preload("res://src/services/save_service.gd")
const CAMPAIGN_SCENE := "res://src/ui/campaign.tscn"

const STRESS_LEVELS := [150, 300, 500]
const STRESS_TOWERS := 12
## Radio (en casillas) para considerar que un toque selecciona una posición.
const SELECT_RADIUS := 0.9
## Movimiento máximo (px) para que una pulsación cuente como toque y no como arrastre.
const TAP_SLOP := 12.0
## Distancia (px de mundo) para que un toque seleccione a un héroe (su sprite es alto).
const HERO_PICK_RADIUS := 26.0

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
var _audio: AudioDirector
var _save: SaveService
var _press_pos := Vector2.ZERO
var _pressing := false
var _selected_hero := -1
var _targeting_hero := -1


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	stress = "--stress" in args
	autoplay = "--autoplay" in args
	for arg in args:
		if arg.begins_with("--select-hero="):
			_select_hero.call_deferred(int(arg.trim_prefix("--select-hero=")))
		if arg.begins_with("--speed="):  # acelera el tiempo (pruebas de flujo completas)
			Engine.time_scale = float(arg.trim_prefix("--speed="))

	content = ContentDB.load_all()
	# La misión y los héroes los elige la campaña (autoload Session); si la escena
	# se abre directamente (pruebas, capturas), se usa la misión por defecto.
	mission = content.missions[StringName(Session.mission_or_default())]

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
	_camera.setup(_map_bounds())

	_hud = Hud.new()
	add_child(_hud)
	_audio = AudioDirector.new()
	add_child(_audio)
	_hud.map_requested.connect(_go_to_campaign)
	# Guardado global (autoload): sus señales se conectan a métodos de nodos de
	# esta escena, que Godot desconecta solo al cambiar de pantalla.
	_save = Save
	_save.status_changed.connect(_hud.set_cloud_status)
	_save.result_processed.connect(_hud.show_reward)
	_save.result_processed.connect(_on_result_processed)
	_save.ensure_started()
	# Construir o vender cierra el menú; mejorar lo deja abierto (se puede seguir).
	_hud.build_requested.connect(func(spot, id): if _command(world.build(spot, id)): _select(-1))
	_hud.upgrade_requested.connect(func(spot): _command(world.upgrade(spot)))
	_hud.sell_requested.connect(func(spot): if _command(world.sell(spot)): _select(-1))
	_hud.start_wave_requested.connect(func(): _command(world.start_next_wave()))
	_hud.pause_toggled.connect(func(): paused = not paused)
	_hud.restart_requested.connect(_restart)
	_hud.close_panel_requested.connect(func(): _select(-1))
	_hud.hero_selected.connect(_toggle_hero)
	_hud.ability_requested.connect(_begin_targeting)

	_restart()
	_maybe_capture_screenshot()


func _restart() -> void:
	_acc = 0.0
	_sim_ms_avg = 0.0
	paused = false
	world = SimWorld.new(map_def.routes, 1234)
	world.setup_mission(content, mission, map_def, _chosen_heroes(), _chosen_towers())
	if stress:
		world.base_hp = 1_000_000_000
		# Torres de la misión en rotación (sin ids escritos a mano).
		var spots := StressLayout.tower_spots(map_def, STRESS_TOWERS)
		for i in spots.size():
			world.place_tower(content.towers[StringName(world.allowed_towers[i % world.allowed_towers.size()])], spots[i])
		for i in stress_enemies:
			world.spawn_enemy(40.0, 1.2, world.rng.randf_range(0.0, world.path.length * 0.95))
	_view.bind(world)
	_audio.world = world
	_hud.bind(world, content)
	_refresh_progress()
	_dispatch_events()
	_select(-1)
	_select_hero(-1)


## Resultado de un comando: la simulación ya lo validó; aquí solo se informa.
func _command(result: StringName) -> bool:
	if result != &"ok":
		print("Comando rechazado: %s" % result)
		if result in [&"no_gold", &"cooldown", &"out_of_range", &"dead"]:
			_audio.play("denied")
	_select(_view.selected_spot)  # refresca el menú abierto
	return result == &"ok"


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
		Engine.get_frames_per_second(), _sim_ms_avg, world.enemy_count, world.projectile_count],
		_selected_hero, _targeting_hero)


func _run_tick() -> void:
	_view.snapshot()
	if stress:
		for i in mini(stress_enemies - world.enemy_count, 5):
			world.spawn_enemy(40.0, 1.2)
	var t0 := Time.get_ticks_usec()
	world.step()
	_sim_ms_avg = lerpf(_sim_ms_avg, (Time.get_ticks_usec() - t0) / 1000.0, 0.05)
	_dispatch_events()


## Héroes elegidos en la campaña, si son válidos para esta misión.
func _chosen_heroes() -> PackedStringArray:
	var ids := Session.hero_ids
	if ids.size() != mission.heroes.size():
		return PackedStringArray()
	for id in ids:
		if not content.heroes.has(StringName(id)):
			return PackedStringArray()
	return ids


## Equipo de torres elegido en la campaña, si es válido para esta misión.
func _chosen_towers() -> PackedStringArray:
	var ids := Session.tower_ids
	if ids.is_empty() or ids.size() > mission.max_towers:
		return PackedStringArray()
	for id in ids:
		if not content.towers.has(StringName(id)):
			return PackedStringArray()
		if not mission.towers.is_empty() and not id in mission.towers:
			return PackedStringArray()
	return ids


func _on_result_processed(_response: Dictionary) -> void:
	_refresh_progress()


func _go_to_campaign() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(CAMPAIGN_SCENE)


func _refresh_progress() -> void:
	_hud.set_progress(_save.best_stars(String(mission.id)), _save.shards())


## Resumen de la partida para el servidor (que recalcula estrellas y recompensas).
func _match_summary() -> Dictionary:
	var won := world.outcome == SimWorld.Outcome.VICTORY
	return {
		mission_id = String(mission.id),
		outcome = "victory" if won else "defeat",
		base_hp = world.base_hp,
		waves_reached = world.waves_total() if won else world.wave_index + 1,
		duration_secs = world.tick / SimWorld.TICK_RATE,
		stars = world.stars(),
		stats = world.stats,
		rewards = {first_clear = mission.first_clear_reward, per_star = mission.per_star_reward,
			replay = mission.replay_reward},
	}


## Reparte los eventos del tick entre la vista, la interfaz y el audio.
func _dispatch_events() -> void:
	var events := world.drain_events()
	_view.handle_events(events)
	_hud.on_events(events)
	for ev in events:
		# Las partidas automáticas (pruebas, capturas) no cuentan como progreso.
		if (ev.type == &"victory" or ev.type == &"defeat") and not autoplay:
			_save.submit_result(_match_summary())
	if _audio:
		_audio.on_events(events)


# --- Selección en el mapa --------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_press_pos = event.position
		elif _pressing:
			_pressing = false
			if event.position.distance_to(_press_pos) <= TAP_SLOP:
				_on_map_tap(get_global_mouse_position())
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
				_select_hero(-1)
			KEY_1, KEY_2, KEY_3, KEY_4:
				_toggle_hero(event.keycode - KEY_1)
			KEY_Q:
				_begin_targeting(_selected_hero)


## Prioridad de un toque en el mapa: objetivo de habilidad > héroe > posición de
## construcción > mover al héroe seleccionado > deseleccionar.
func _on_map_tap(world_pos: Vector2) -> void:
	var logical := Iso.to_logical(world_pos)
	if _targeting_hero >= 0:
		var result := world.cast_ability(_targeting_hero, logical)
		_command(result)
		if result == &"ok" or result == &"cooldown":
			_targeting_hero = -1
		return
	var coin := _coin_at(logical)
	if coin >= 0:
		_command(world.collect_coin(coin))
		return
	var hero := _hero_at(world_pos)
	if hero >= 0:
		_toggle_hero(hero)
		return
	var spot := _spot_at(world_pos)
	if spot >= 0:
		_select_hero(-1)
		_select(spot)
		return
	if _selected_hero >= 0:
		# Mover es una acción completa: tras dar la orden, el héroe se deselecciona.
		_command(world.move_hero(_selected_hero, logical))
		_select_hero(-1)
		return
	_select(-1)


## Moneda bajo el toque (uid) o -1. Radio generoso: son pequeñas.
func _coin_at(logical: Vector2) -> int:
	for c in world.objects.coins:
		if c.pos.distance_to(logical) <= 0.7:
			return c.uid
	return -1


func _hero_at(world_pos: Vector2) -> int:
	for i in world.heroes.heroes.size():
		# El sprite es alto: se compara con el centro del cuerpo, no con el pie.
		var body := _view.hero_screen_pos(i) + Vector2(0, -20)
		if world_pos.distance_to(body) <= HERO_PICK_RADIUS:
			return i
	return -1


func _select_hero(index: int) -> void:
	_selected_hero = index if index < world.heroes.heroes.size() else -1
	_targeting_hero = -1
	_view.selected_hero = _selected_hero
	if _selected_hero >= 0:
		_select(-1)


## Tocar al héroe ya seleccionado (en el mapa o en su tarjeta) lo deselecciona.
func _toggle_hero(index: int) -> void:
	_select_hero(-1 if index == _selected_hero and _targeting_hero < 0 else index)


func _begin_targeting(index: int) -> void:
	if index < 0 or index >= world.heroes.heroes.size():
		return
	_select_hero(index)
	if world.heroes.heroes[index].ability_cd == 0:
		_targeting_hero = index


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
	_hud.select_spot(spot, Iso.to_screen(map_def.build_spots[spot]) if spot >= 0 else Vector2.ZERO)


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
	# Las plataformas las dibuja la vista del mundo (pueden moverse o estar cerradas).


func _map_bounds() -> Rect2:
	var s := Vector2(map_def.size)
	var r := Rect2(Iso.to_screen(Vector2.ZERO), Vector2.ZERO)
	for c in [Vector2(s.x, 0), s, Vector2(0, s.y)]:
		r = r.expand(Iso.to_screen(c))
	return r


## Estrategia automática para capturas y pruebas de humo.
func _autoplay_step() -> void:
	# Una torre de cada tipo disponible, en orden, en las posiciones libres.
	var team := world.allowed_towers
	for spot in map_def.build_spots.size():
		if world.tower_at(spot).is_empty():
			world.build(spot, StringName(team[spot % team.size()]))
	if not world.wave_active and not world.is_over():
		world.start_next_wave()
	# Héroes: cada uno lanza su habilidad cuando está lista y hay enemigos, apuntando
	# al tramo final de la ruta (detalles de prueba, no lógica del juego).
	var route := map_def.routes[0]
	var near_base := route[route.size() - 2].lerp(route[route.size() - 1], 0.5)
	for i in world.heroes.heroes.size():
		var h: Dictionary = world.heroes.heroes[i]
		if h.ability_cd > 0 or world.enemy_count == 0:
			continue
		var def: HeroDef = h.def
		var to := near_base
		if def.ability_kind == HeroDef.ABILITY_LINE_STRIKE:
			to = route[route.size() - 2]
		elif h.pos.distance_to(to) > def.ability_range:
			to = h.pos + (to - h.pos).normalized() * def.ability_range
		world.cast_ability(i, to)


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
	_audio.stop_all()
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
