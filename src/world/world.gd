## El mundo: salas colocadas en una cuadrícula común (ver Rooms). Al salir de una
## sala se entra en la que hay en ese punto. Gestiona pinchos (vuelta al último
## suelo seguro), bancos (descansar y guardar), muerte (vuelta al último banco),
## objetos (dash, corazón extra), jefes (puerta que se cierra durante el combate),
## el mapa y la partida guardada.
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
var enemies: Array[Node2D] = []
var collected := {}          # id de objeto → true
var bosses_defeated := {}    # id de sala → true
var boss: BossGuardian
var gate_closed := false
var _gate_body: Node2D
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
	for id in data.get("bosses", []):
		bosses_defeated[id] = true
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
	if boss and not gate_closed and current.gate.has_area() \
			and kira.position.x < current.gate.position.x - 2.0 * RoomLayout.TILE:
		_close_gate()


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
	boss = null
	gate_closed = false
	_gate_body = null
	hud.hide_boss()
	current = layouts[id]
	visited[id] = true
	_room_node = Node2D.new()
	_room_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_room_node)
	move_child(_room_node, 0)  # detrás de Kira
	var geo := RoomGeometry.new()
	_room_node.add_child(geo)
	geo.setup(current)
	for spawn in current.enemy_spawns:
		var e := Enemies.create(spawn.kind, spawn.pos, kira)
		e.died.connect(_on_enemy_died)
		_room_node.add_child(e)
		enemies.append(e)
	if current.boss_spawn != Vector2.INF and not bosses_defeated.has(id):
		boss = BossGuardian.new()
		boss.position = current.boss_spawn
		boss.target = kira
		boss.arena = current.rect
		boss.died.connect(_on_boss_died)
		boss.health_changed.connect(hud.set_boss_ratio)
		_room_node.add_child(boss)
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
		"bosses": bosses_defeated.keys(),
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
	bosses_defeated.clear()
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


## Empieza el combate: se cierra la puerta de la arena.
func _close_gate() -> void:
	gate_closed = true
	var body := StaticBody2D.new()
	body.collision_layer = Kira.LAYER_WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = current.gate.size
	shape.shape = rect
	shape.position = current.gate.get_center()
	body.add_child(shape)
	var bars := GateBars.new()
	bars.rect = current.gate
	body.add_child(bars)
	_room_node.add_child(body)
	_gate_body = body
	hud.show_boss(BossGuardian.DISPLAY_NAME)


func _on_boss_died(b: BossGuardian) -> void:
	bosses_defeated[current.id] = true
	for i in 5:
		var fx := Burst.new()
		fx.color = BossGuardian.COLOR.lightened(0.3)
		fx.position = b.position + Vector2(randf_range(-30, 30), -randf_range(10, 80))
		_room_node.add_child(fx)
	b.queue_free()
	boss = null
	if _gate_body:
		_gate_body.queue_free()
		_gate_body = null
	hud.hide_boss()
	kira.set_max_hp(kira.health.max_hp + HEART_BONUS)
	hud.toast("¡Has vencido al %s! Corazón extra: vida máxima %d" % [BossGuardian.DISPLAY_NAME, kira.health.max_hp])
	save()


func _check_pickups() -> void:
	var center := kira.position + Vector2(0, -Kira.SIZE.y / 2)
	for pk in pickups.duplicate():
		if center.distance_to(pk.position) < PICKUP_REACH:
			collect(pk)


func _on_enemy_died(e: Node2D) -> void:
	var fx := Burst.new()
	fx.color = e.color
	fx.position = Enemies.center_of(e)
	_room_node.add_child(fx)
	enemies.erase(e)


func _flash_fade() -> void:
	_fade.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 0.0, FADE_TIME)


## Barrotes de la puerta cerrada de la arena.
class GateBars extends Node2D:
	var rect := Rect2()

	func _draw() -> void:
		draw_rect(rect, Color(0.1, 0.1, 0.15, 0.6))
		var n := 4
		for i in n:
			var x := rect.position.x + (i + 0.5) * rect.size.x / n
			draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color("8a93ad"), 4.0)
