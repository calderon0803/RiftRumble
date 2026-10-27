## Tests del mundo: salas conectadas, pinchos, banco, guardado y muerte.
## Uso: godot --headless --path . --script res://tests/world_tests.gd
extends SceneTree

const SAVE := "user://test_partida.json"
const T := RoomLayout.TILE
var _failures := 0
var _checks := 0


func check(cond: bool, msg: String) -> void:
	_checks += 1
	print(("  ✓ " if cond else "  ✗ ") + msg)
	if not cond:
		_failures += 1


func _initialize() -> void:
	_run.call_deferred()


func _physics(n: int) -> void:
	for i in n:
		await physics_frame


func _new_world() -> World:
	var w: World = load("res://src/world/world.tscn").instantiate()
	w.save_path = SAVE
	w.hitstop_enabled = false
	root.add_child(w)
	return w


func _clear_enemies(w: World) -> void:
	for e in w.enemies:
		if is_instance_valid(e):
			e.queue_free()
	w.enemies.clear()


## Pone a Kira en la casilla (col, fila) local de una sala, de pie sobre lo que haya debajo.
func _place(w: World, room: String, col: float, row: float) -> void:
	var l: RoomLayout = w.layouts[room]
	if w.current.id != room:
		w.enter_room(room)
	w.kira.place_at(l.rect.position + Vector2(col * T, row * T))
	_clear_enemies(w)


func _run() -> void:
	SaveGame.erase(SAVE)
	_check_data()

	var w := _new_world()
	var kira := w.kira
	await _physics(5)
	check(w.current.id == Rooms.START, "empieza en la sala de inicio")

	print("Paso entre salas")
	_clear_enemies(w)
	kira.scripted_input = {"x": 1.0}
	for i in 400:
		await physics_frame
		if w.current.id != Rooms.START:
			break
	check(w.current.id == "pasillo", "saliendo por la derecha entra en el pasillo")
	check(absf(kira.position.x - 40.0 * T) < 2.0 * T, "sin saltos de posición (x %.0f)" % kira.position.x)
	check(w.cam.limit_left == int(w.current.rect.position.x) and w.cam.limit_right == int(w.current.rect.end.x),
			"la cámara se ajusta a la nueva sala")
	_clear_enemies(w)
	kira.scripted_input = {"x": -1.0}
	for i in 200:
		await physics_frame
		if w.current.id != "pasillo":
			break
	check(w.current.id == Rooms.START, "y volviendo a la izquierda regresa al inicio")

	print("Pinchos")
	_place(w, "pasillo", 26.5, 22.0)
	kira.scripted_input = {"x": 0.0}
	await _physics(10)
	var hp0 := kira.health.hp
	var safe := w.last_safe
	kira.scripted_input = {"x": 1.0}
	for i in 120:
		await physics_frame
		if kira.health.hp < hp0:
			break
	kira.scripted_input = {"x": 0.0}
	await _physics(2)
	check(kira.health.hp == hp0 - 1, "pisar pinchos quita un corazón")
	var local_x := (kira.position.x - w.current.rect.position.x) / T
	check(local_x > 26.0 and local_x < 30.0 and absf(kira.position.y - safe.y) < 1.0,
			"y vuelve al último suelo seguro, al borde del foso (casilla %.1f)" % local_x)
	await _physics(20)  # pasa el aturdimiento
	kira.health.invulnerable = 0.0
	kira.scripted_input = {"x": 1.0, "jump": true}
	for i in 60:
		await physics_frame
	kira.scripted_input = {"x": 1.0}
	await _physics(20)
	check(kira.position.x > w.current.rect.position.x + 35.0 * T and kira.health.hp == hp0 - 1,
			"saltando se cruza el foso sin daño")

	print("Pozo")
	_place(w, "pasillo", 76.5, 22.0)
	kira.scripted_input = {"x": 1.0}
	for i in 120:
		await physics_frame
		if w.current.id != "pasillo":
			break
	check(w.current.id == "pozo", "por la derecha del pasillo se entra al pozo")
	check(w.cam.limit_bottom - w.cam.limit_top == 46 * T, "la cámara cubre las dos pantallas de alto del pozo")
	kira.scripted_input = {"x": 0.0}
	_place(w, "pozo", 3.5, 10.0)
	kira.scripted_input = {"x": -1.0}
	for i in 120:
		await physics_frame
		if w.current.id != "pozo":
			break
	check(w.current.id == "banco", "por arriba a la izquierda del pozo se llega al banco")
	kira.scripted_input = {"x": 0.0}

	print("Banco y guardado")
	var bench: Vector2 = w.current.bench
	kira.place_at(bench)
	await _physics(10)
	kira.health.hp = 2
	kira.scripted_input = {"x": 0.0, "y": -1.0}
	await _physics(2)
	kira.scripted_input = {"x": 0.0}
	await _physics(1)
	check(kira.health.hp == kira.health.max_hp, "sentarse en el banco devuelve toda la vida")
	var data := SaveGame.load_from(SAVE)
	check(data.get("bench_room", "") == "banco", "y guarda la partida en el banco")
	check("pasillo" in data.get("visited", []) and "pozo" in data.get("visited", []), "con las salas visitadas")

	print("Muerte")
	_place(w, "banco", 26.0, 10.0)
	await _physics(5)
	kira.died.emit()
	await _physics(3)
	check(w.current.id == "banco" and kira.position.distance_to(bench) < 4.0, "al morir vuelve al último banco")
	check(kira.health.hp == kira.health.max_hp, "con toda la vida")

	print("Mirador")
	_place(w, "banco", 2.5, 22.0)
	kira.scripted_input = {"x": -1.0}
	for i in 120:
		await physics_frame
		if w.current.id != "banco":
			break
	check(w.current.id == "mirador", "por la izquierda del banco se llega al mirador")
	check(w.enemies.size() == 3, "con sus 3 rastreros")
	kira.scripted_input = {"x": 0.0}

	print("Cargar partida")
	w.queue_free()
	await _physics(2)
	var w2 := _new_world()
	await _physics(3)
	check(w2.current.id == "banco", "al abrir el juego empieza en el último banco")
	check(w2.visited.has("pozo") and w2.visited.has("pasillo"), "y recuerda las salas visitadas para el mapa")
	w2.new_game()
	await _physics(2)
	check(w2.current.id == Rooms.START and not FileAccess.file_exists(SAVE), "partida nueva: borra el guardado y vuelve al inicio")
	w2.queue_free()
	await _physics(2)

	await _check_climbs()
	SaveGame.erase(SAVE)
	print("\n%d/%d comprobaciones correctas" % [_checks - _failures, _checks])
	quit(1 if _failures > 0 else 0)


## Los datos de las salas: sin solaparse y con cada hueco del borde llevando a otra sala.
func _check_data() -> void:
	print("Salas")
	var layouts := {}
	for id in Rooms.DATA:
		var d: Dictionary = Rooms.DATA[id]
		layouts[id] = RoomLayout.parse(d.layout, d.origin, id, d.name)
	var overlap := false
	var ids := layouts.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			if layouts[ids[i]].rect.intersects(layouts[ids[j]].rect):
				overlap = true
	check(not overlap, "las %d salas no se solapan" % ids.size())
	check((layouts[Rooms.START] as RoomLayout).start != Vector2.INF, "la sala de inicio tiene punto de inicio")
	var bad := []
	var exits := 0
	for id in layouts:
		var l: RoomLayout = layouts[id]
		var w := int(l.rect.size.x / T)
		var h := int(l.rect.size.y / T)
		for row in h:
			for col in [0, w - 1]:
				if not l.is_open(col, row):
					continue
				exits += 1
				var outside := l.rect.position + Vector2((col + (-0.5 if col == 0 else 1.5)) * T, (row + 0.5) * T)
				var other := ""
				for oid in layouts:
					if oid != id and layouts[oid].rect.has_point(outside):
						other = oid
				var ok := false
				if other != "":
					var ol: RoomLayout = layouts[other]
					var local := ((outside - ol.rect.position) / T).floor()
					ok = ol.is_open(int(local.x), int(local.y))
				if not ok:
					bad.append("%s fila %d" % [id, row])
	check(bad.is_empty(), "las %d casillas de salida llevan a aire en la sala vecina %s" % [exits, str(bad)])


## Salta desde el borde de una plataforma (o del suelo) hacia otra más alta.
## Plataformas como [fila, col_inicio, col_fin] en casillas locales.
func _hop(w: World, room: String, from: Array, to: Array) -> bool:
	var dir := 1.0 if (to[1] + to[2]) > (from[1] + from[2]) else -1.0
	var col: float = (from[2] + 0.5) if dir > 0.0 else (from[1] + 0.5)
	_place(w, room, col, from[0])
	var kira := w.kira
	kira.scripted_input = {"x": 0.0}
	await _physics(20)
	var target_y: float = w.current.rect.position.y + to[0] * T
	kira.scripted_input = {"x": dir, "jump": true}
	var left_ground := false
	for i in 90:
		await physics_frame
		var local_x := (kira.position.x - w.current.rect.position.x) / T
		# Suelta la dirección al estar sobre la plataforma de destino.
		if local_x > to[1] + 0.8 and local_x < to[2] + 0.2:
			kira.scripted_input = {"x": 0.0, "jump": true}
		if not kira.is_on_floor():
			left_ground = true
		elif left_ground:
			break
	kira.scripted_input = {"x": 0.0}
	await _physics(3)
	return kira.is_on_floor() and absf(kira.position.y - target_y) < 1.0


func _check_climbs() -> void:
	print("Plataformas alcanzables")
	SaveGame.erase(SAVE)
	var w := _new_world()
	await _physics(3)
	var routes := {
		"inicio": [[22, 6, 9], [18, 12, 17], [15, 21, 26]],
		"pozo": [[45, 12, 15], [41, 18, 25], [37, 8, 15], [33, 18, 25], [29, 8, 15], [25, 18, 25],
				[21, 8, 15], [17, 18, 25], [13, 8, 15], [10, 1, 6]],
		"banco": [[22, 15, 17], [18, 20, 25], [14, 12, 18], [10, 22, 28]],
		"mirador": [[22, 15, 17], [18, 6, 12], [14, 14, 20], [10, 4, 10]],
	}
	for room in routes:
		var steps: Array = routes[room]
		var failed := []
		for i in steps.size() - 1:
			var ok: bool = await _hop(w, room, steps[i], steps[i + 1])
			if not ok:
				failed.append("fila %d → %d" % [steps[i][0], steps[i + 1][0]])
		check(failed.is_empty(), "%s: se sube saltando por todas las plataformas %s" % [room, str(failed)])
	w.queue_free()
	await _physics(2)
	SaveGame.erase(SAVE)
