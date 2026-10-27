## El mundo: salas colocadas en una cuadrícula común (ver Rooms). Al salir de una
## sala se entra en la que hay en ese punto. Gestiona pinchos (vuelta al último
## suelo seguro), bancos (descansar y guardar), muerte (vuelta al último banco),
## objetos (dash, corazón extra), el mapa y la partida guardada.
class_name World
extends Node2D

const COLOR_BG := Color("141824")
const FADE_TIME := 0.18
const BENCH_REACH := 30.0
const PICKUP_REACH := 30.0
const HEART_BONUS := 1

## Dónde se guarda la partida (los tests usan otro archivo).
var save_path := SaveGame.DEFAULT_PATH
var hitstop_enabled := true

var layouts := {}            # id → RoomLayout
var current: RoomLayout
var kira: Kira
var hud: Hud
var map_view: MapView
var cam: Camera2D
var visited := {}            # id → true
var bench_room := ""         # último banco ("" = ninguno: se vuelve al inicio)
var bench_pos := Vector2.INF
var enemies: Array[Crawler] = []
var collected := {}          # id de objeto → true
var pickups: Array[Pickup] = []
var last_safe := Vector2.ZERO
var _room_node: Node2D
var _fade: ColorRect


func _ready() -> void:
	RenderingServer.set_default_clear_color(COLOR_BG)
	Controls.ensure()
	process_mode = Node.PROCESS_MODE_ALWAYS  # para abrir y cerrar el mapa en pausa
	for id in Rooms.DATA:
		var d: Dictionary = Rooms.DATA[id]
		layouts[id] = RoomLayout.parse(d.layout, d.origin, id, d.name)

	kira = Kira.new()
	kira.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(kira)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	kira.add_child(cam)
	hud = Hud.new()
	add_child(hud)
	map_view = MapView.new()
	map_view.world = self
	add_child(map_view)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 10
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.size = Vector2(1280, 720)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)
	add_child(fade_layer)

	kira.health_changed.connect(hud.set_health)
	kira.notches_changed.connect(hud.set_notches)
	kira.hit_landed.connect(func(special: bool):
		if hitstop_enabled:
			HitStop.apply(get_tree(), special))
	kira.died.connect(func(): respawn_at_checkpoint.call_deferred())

	var data := SaveGame.load_from(save_path)
	if data.get("bench_room", "") in layouts:
		bench_room = data.bench_room
		bench_pos = Vector2(data.bench[0], data.bench[1])
	for id in data.get("visited", []):
		visited[id] = true
	for id in data.get("collected", []):
		collected[id] = true
	for a in data.get("abilities", []):
		kira.grant(a)
	if data.has("max_hp"):
		kira.set_max_hp(int(data.max_hp))
	respawn_at_checkpoint()


func _physics_process(_dt: float) -> void:
	if Input.is_action_just_pressed(Controls.MAP):
		map_view.visible = not map_view.visible
		get_tree().paused = map_view.visible
		map_view.queue_redraw()
	if get_tree().paused:
		return
	if Input.is_action_just_pressed(Controls.NEW_GAME):
		new_game()
		return
	if Input.is_action_just_pressed(Controls.RESET):
		respawn_at_checkpoint()
		return

	var center := kira.position + Vector2(0, -Kira.SIZE.y / 2)
	if not current.rect.has_point(center):
		var next := room_at(center)
		if next == "":
			_hazard()  # fuera del mundo: como unos pinchos
		else:
			enter_room(next)
		return
	if _touching_spikes():
		_hazard()
		return
	if kira.is_on_floor() and not _near_spikes(kira.position):
		last_safe = kira.position
	_check_bench()
	_check_pickups()


## Sala que contiene un punto del mundo ("" si ninguna).
func room_at(p: Vector2) -> String:
	for id in layouts:
		if layouts[id].rect.has_point(p):
			return id
	return ""


func enter_room(id: String) -> void:
	if _room_node:
		_room_node.queue_free()
	enemies.clear()
	pickups.clear()
	current = layouts[id]
	visited[id] = true
	_room_node = Node2D.new()
	_room_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_room_node)
	move_child(_room_node, 0)  # detrás de Kira
	var geo := RoomGeometry.new()
	_room_node.add_child(geo)
	geo.setup(current)
	for p in current.enemy_spawns:
		var e := Crawler.new()
		e.position = p
		e.died.connect(_on_enemy_died)
		_room_node.add_child(e)
		enemies.append(e)
	for item in current.pickups:
		if collected.has(item.id):
			continue
		var pk := Pickup.new()
		pk.kind = item.kind
		pk.id = item.id
		pk.position = item.pos
		_room_node.add_child(pk)
		pickups.append(pk)
	cam.limit_left = int(current.rect.position.x)
	cam.limit_top = int(current.rect.position.y)
	cam.limit_right = int(current.rect.end.x)
	cam.limit_bottom = int(current.rect.end.y)
	cam.reset_smoothing()
	_flash_fade()
	map_view.queue_redraw()


## Vuelve al último banco (o al inicio) con toda la vida; la sala se reinicia.
func respawn_at_checkpoint() -> void:
	var id := bench_room if bench_room != "" else Rooms.START
	var at := bench_pos if bench_room != "" else (layouts[Rooms.START] as RoomLayout).start
	kira.respawn(at)
	last_safe = at
	enter_room(id)


func rest_at_bench() -> void:
	kira.health.reset()
	kira.health_changed.emit(kira.health.hp, kira.health.max_hp)
	bench_room = current.id
	bench_pos = current.bench
	save()
	hud.toast("Descansas en el banco · partida guardada")


func save() -> void:
	SaveGame.save_to(save_path, {
		"bench_room": bench_room,
		"bench": [bench_pos.x, bench_pos.y] if bench_room != "" else [],
		"visited": visited.keys(),
		"collected": collected.keys(),
		"abilities": kira.abilities.keys(),
		"max_hp": kira.health.max_hp,
	})


## Recoge un objeto: lo aplica y guarda en el momento (no vuelve a aparecer).
func collect(pk: Pickup) -> void:
	collected[pk.id] = true
	pickups.erase(pk)
	pk.queue_free()
	match pk.kind:
		"dash":
			kira.grant("dash")
			hud.toast("¡Dash! Shift / V / RB: impulso rápido, también en el aire")
		"heart":
			kira.set_max_hp(kira.health.max_hp + HEART_BONUS)
			hud.toast("¡Corazón extra! Vida máxima: %d" % kira.health.max_hp)
	save()


func new_game() -> void:
	SaveGame.erase(save_path)
	bench_room = ""
	bench_pos = Vector2.INF
	visited.clear()
	collected.clear()
	kira.clear_abilities()
	kira.set_max_hp(Kira.MAX_HP)
	respawn_at_checkpoint()
	hud.toast("Partida nueva")


## Pinchos o caída: pierde un corazón y vuelve al último suelo seguro.
func _hazard() -> void:
	if kira.health.damage(1, Kira.HURT_INVULNERABLE):
		kira.health_changed.emit(kira.health.hp, kira.health.max_hp)
	if kira.health.is_dead():
		respawn_at_checkpoint()
		return
	var id := room_at(last_safe + Vector2(0, -4))
	kira.place_at(last_safe)
	if id != "" and id != current.id:
		enter_room(id)
	else:
		_flash_fade()


func _touching_spikes() -> bool:
	var body := Rect2(kira.position - Vector2(Kira.SIZE.x / 2, Kira.SIZE.y), Kira.SIZE).grow(1.0)
	for s in current.spikes:
		if body.intersects(s):
			return true
	return false


func _near_spikes(feet: Vector2) -> bool:
	var probe := Rect2(feet + Vector2(-Kira.SIZE.x, -4), Vector2(Kira.SIZE.x * 2, 12))
	for s in current.spikes:
		if probe.intersects(s):
			return true
	return false


func _check_bench() -> void:
	if current.bench == Vector2.INF or not kira.is_on_floor():
		return
	var near := absf(kira.position.x - current.bench.x) < BENCH_REACH and absf(kira.position.y - current.bench.y) < 4.0
	if near and kira.last_input.get("up_pressed", false):
		rest_at_bench()


func _check_pickups() -> void:
	var center := kira.position + Vector2(0, -Kira.SIZE.y / 2)
	for pk in pickups.duplicate():
		if center.distance_to(pk.position) < PICKUP_REACH:
			collect(pk)


func _on_enemy_died(e: Crawler) -> void:
	var fx := Burst.new()
	fx.color = Crawler.COLOR
	fx.position = e.position + Vector2(0, -Crawler.SIZE.y / 2)
	_room_node.add_child(fx)
	enemies.erase(e)


func _flash_fade() -> void:
	_fade.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 0.0, FADE_TIME)
