## Simulación del juego, sin nodos: salas, Álex, enemigos, jefe, dones de las grietas y el bucle
## del Continue. Las vistas solo leen este estado; los tests lo manejan directamente.
class_name Game
extends RefCounted

const T := 32
const VW := 960.0
const VH := 540.0
const GRAV := 2000.0
const MAXFALL := 900.0
const RUN := 250.0
const JUMP := 680.0
const DJUMP := 600.0
const DASH := 720.0
const POGO := 600.0
const DEBUG_MAX := 6
const DEBUG_COST := 2
## Color de la depuración y de los efectos de Álex.
const DEBUG_COL := Color("7be3c8")


## Cualquier cosa que no es Álex: enemigos, jefe, proyectiles, núcleos y recogibles.
class Ent extends RefCounted:
	var kind := ""
	var x := 0.0
	var y := 0.0
	var w := 0.0
	var h := 0.0
	var vx := 0.0
	var vy := 0.0
	var hp := 0.0
	var max_hp := 0.0
	var frags := 0
	var face := 1
	var flash := 0.0
	var burn := 0.0
	var burn_tick := 0.0
	var kb := 0.0
	var t := 0.0
	var cd := 0.0
	var on_ground := false
	var drop_t := 0.0
	var aggro := false
	var charging := false
	var dead := false
	var state := ""
	var phase := 1
	var air_t := 0.0
	var rained := false
	var summon_cd := 0.0
	var hit_wall := false
	var life := 0.0
	var r := 0.0
	var g := 0.0
	var dmg := 0.0
	var boom := false
	var hostile := false
	var tick := 0.0
	var revived := false
	var amt := 0
	var name := ""
	var shield := 0            # golpes que absorbe (lo da el conjurador)
	var resist := ""           # tipo de ataque que el Alumno Eterno resiste
	var dmg_by := {}           # daño recibido por tipo de ataque (para adaptarse)
	var seq: Array = []        # combinación pendiente de un muñeco de la técnica de Kira
	var idx := 0
	var home := Vector2.ZERO
	var elite := false         # versión de élite: más vida y un ataque extra

	func rect() -> Rect2:
		return Rect2(x, y, w, h)

	func center() -> Vector2:
		return Vector2(x + w / 2.0, y + h / 2.0)


## Color de Kira (verde).
const KIRA_COL := Color("5fe39a")

class Player extends RefCounted:
	var x := 0.0
	var y := 0.0
	var w := 18.0
	var h := 30.0
	var vx := 0.0
	var vy := 0.0
	var face := 1
	var on_ground := false
	var was_ground := false
	var drop_t := 0.0
	var coyote := 0.0
	var jump_buf := 0.0
	var air_jumps := 1
	var dash_t := 0.0
	var dash_cd := 0.0
	var dash_charges := 1
	var atk_t := 0.0
	var atk_cd := 0.0
	var atk_dir := "side"
	var combo := 0
	var combo_t := 0.0
	var atk_hits := {}
	var pogo_done := false
	var inv := 0.0
	var hp := 5
	var debug := 0
	var heal_t := 0.0
	var cast_cd := 0.0
	var squash := 0.0
	var crit_next := false
	var safe := Vector2.ZERO
	var trail: Array = []
	var fire_t := 0.0
	var resonance := 0.0       # segundos de resonancia tras golpear un cristal
	var wall_dir := 0          # pared contra la que se desliza (-1 izquierda, 1 derecha)
	var wall_coyote := 0.0
	var last_wall := 0
	var ctrl_lock := 0.0       # sin control horizontal justo después de saltar desde la pared

	func rect() -> Rect2:
		return Rect2(x, y, w, h)

	func center() -> Vector2:
		return Vector2(x + w / 2.0, y + h / 2.0)


# --- estado ---
var meta: Dictionary
var rooms: Dictionary
var room: Data.RoomDef
var run: Dictionary
var P := Player.new()
var enemies: Array = []
var projs: Array = []
var pickups: Array = []
var parts: Array = []
var nums: Array = []
var slashes: Array = []
var props: Array = []
var boss: Ent = null
var state := "title"   # title, play, trans, dialog, choice, shop, pause, dead, end
var time := 0.0
var cam := Vector2.ZERO
var shake := 0.0
var hitstop := 0.0
var flash_a := 0.0
var flash_col := Color.WHITE
var banner := {}
var dialog := {}
var choice := {}
var shop := {}
## Mientras se desarrolla el juego, el mapa enseña todas las salas. Poner a false para el juego final.
const DEV_FULL_MAP := true
var map_reveal_all := DEV_FULL_MAP
var map_pan := Vector2.ZERO  # casilla del mapa que está en el centro de la pantalla
const MAP_PAN_SPEED := 160.0  # casillas por segundo al mover el mapa
var look_edit := {}  # {"look": aspecto en edición, "sel": fila; la fila tras las opciones es "Listo"}
var trans := {}
var dead_t := 0.0
var end_t := 0.0
var erase_arm := 0.0
var frag_pulse := 0.0
var revive_fx := 0.0       # segundos que queda el aviso de Continue Extra en pantalla
var save_timer := 0.0
var dirty := false
## Arena de la sala actual: se cierra al entrar y lanza sus oleadas (Data.RoomDef.waves).
var arena_active := false
var arena_wave := 0
var arena_delay := 0.0
var arena_trigger := -1.0
var arena_spawns: Array = []
var hits := {}               # golpes recibidos por cada bloque rompible (Vector2i -> int)
var keys := {}
var pressed := {}
var quit_requested := false
var reduced_motion := false


func _init(fresh_meta := false) -> void:
	meta = SaveData.defaults() if fresh_meta else SaveData.load_meta()
	rooms = Data.build_rooms()
	new_run()
	load_room("umbral", "P")


# --- utilidades ---
func held(a: String) -> bool:
	return keys.get(a, false)


func hit(a: String) -> bool:
	return pressed.get(a, false)


func has(id: String) -> bool:
	return run["boons"].has(id)


func max_hp() -> int:
	return 5 + int(meta["up"]["corazon"]) + int(run["extra_hp"])


func save() -> void:
	SaveData.save_meta(meta)


func new_run() -> void:
	var heroes := []
	for k in 3:
		var round_ := ["aeron", "zerik", "voltra", "raiko"]
		round_.shuffle()
		heroes.append_array(round_)
	var rifts := {}
	for i in Data.RIFT_ROOMS.size():
		rifts[Data.RIFT_ROOMS[i]] = {"hero": heroes[i], "taken": false}
	# Los jefes vuelven en cada intento: "beaten" dice a cuáles se ha vencido en este.
	# Cada intento empieza con las salas como nuevas: bloques sin romper y arenas por superar.
	rooms = Data.build_rooms()
	run = {"boons": [], "extra_hp": 0, "revive": int(meta["up"]["continue"]), "frags": 0, "rifts": rifts, "beaten": {},
		"arenas": {}, "fountains": {}, "gems": {}}
	P.hp = max_hp()
	P.debug = DEBUG_MAX if int(meta["up"]["precarga"]) > 0 else 0
	P.inv = 0.0
	P.crit_next = false


# --- casillas ---
func tile_at(tx: int, ty: int) -> String:
	if room == null or ty < 0 or ty >= room.h or tx < 0 or tx >= room.w:
		return "."
	return room.g[ty][tx]


## Casillas que no se atraviesan: bloque, bloques rompibles y la puerta de una arena en combate.
func is_solid(c: String) -> bool:
	return c == "#" or c == "b" or c == "n" or c == "w" or c == "a" or (c == "d" and arena_active)


func solid_pt(px: float, py: float) -> bool:
	return is_solid(tile_at(floori(px / T), floori(py / T)))


func is_floor(tx: int, ty: int) -> bool:
	var c := tile_at(tx, ty)
	return is_solid(c) or c == "="


## Una casilla que se pisa desde arriba: plataforma, o plataforma de cristal mientras Álex resuena.
func one_way(c: String) -> bool:
	return c == "=" or (c == "y" and P.resonance > 0)


## Cierra o abre la puerta por la que se entra a una arena de jefe.
func set_arena(rid: String, locked: bool) -> void:
	var r: Data.RoomDef = rooms[rid]
	for ex: Dictionary in r.exits:
		if ex["to"] == Data.BOSS_DOORS.get(rid, ""):
			_set_door(r, ex, "#" if locked else ".")


## Rellena el hueco de una puerta (cerrarla o abrirla).
func _set_door(r: Data.RoomDef, ex: Dictionary, c: String) -> void:
	match ex["side"]:
		"left", "right":
			var x := 0 if ex["side"] == "left" else r.w - 1
			for y in range(ex["a"], ex["b"] + 1):
				r.g[y][x] = c
		"up":
			for x in range(ex["a"], ex["b"] + 1):
				r.g[0][x] = c
		"down":
			for x in range(ex["a"], ex["b"] + 1):
				r.g[r.h - 2][x] = c
				r.g[r.h - 1][x] = c


## La salida de una sala de jefe hacia el mundo siguiente solo se abre tras vencerle en el intento.
func set_boss_exit(rid: String, open: bool) -> void:
	var r: Data.RoomDef = rooms[rid]
	for ex: Dictionary in r.exits:
		if ex["to"] == Data.BOSS_GATES[rid][0]:
			_set_door(r, ex, "." if open else "#")


func move_x(e, dx: float) -> bool:
	e.x += dx
	var y0 := floori(e.y / T)
	var y1 := floori((e.y + e.h - 0.01) / T)
	if dx > 0:
		var tx := floori((e.x + e.w) / T)
		for ty in range(y0, y1 + 1):
			if is_solid(tile_at(tx, ty)):
				e.x = tx * T - e.w
				e.vx = 0.0
				return true
	elif dx < 0:
		var tx := floori(e.x / T)
		for ty in range(y0, y1 + 1):
			if is_solid(tile_at(tx, ty)):
				e.x = (tx + 1) * T
				e.vx = 0.0
				return true
	return false


func move_y(e, dy: float) -> bool:
	var prev_bot: float = e.y + e.h
	e.y += dy
	e.on_ground = false
	var x0 := floori(e.x / T)
	var x1 := floori((e.x + e.w - 0.01) / T)
	if dy > 0:
		var ty := floori((e.y + e.h) / T)
		for tx in range(x0, x1 + 1):
			var c := tile_at(tx, ty)
			if is_solid(c) or (one_way(c) and e.drop_t <= 0.0 and prev_bot <= ty * T + 0.5):
				e.y = ty * T - e.h
				e.vy = 0.0
				e.on_ground = true
				return true
	elif dy < 0:
		var ty := floori(e.y / T)
		for tx in range(x0, x1 + 1):
			if is_solid(tile_at(tx, ty)):
				e.y = (ty + 1) * T
				e.vy = 0.0
				return true
	return false


func touching_spikes(b: Rect2) -> bool:
	for ty in range(floori(b.position.y / T), floori(b.end.y / T) + 1):
		for tx in range(floori(b.position.x / T), floori(b.end.x / T) + 1):
			if tile_at(tx, ty) == "^" and b.intersects(Rect2(tx * T + 3, ty * T + T * 0.45, T - 6, T * 0.55)):
				return true
	return false


## ¿Hay un bloque justo al lado de Álex, hacia `dir`, a la altura de su cuerpo?
func wall_at(dir: int) -> bool:
	var px := P.x + P.w + 1 if dir > 0 else P.x - 1
	var tx := floori(px / T)
	for py in [P.y + 4, P.y + P.h - 4]:
		if is_solid(tile_at(tx, floori(py / T))):
			return true
	return false


func standing_on_one_way() -> bool:
	var ty := floori((P.y + P.h + 1) / T)
	var one := false
	for tx in range(floori(P.x / T), floori((P.x + P.w - 0.01) / T) + 1):
		var c := tile_at(tx, ty)
		if is_solid(c):
			return false
		if c == "=":
			one = true
	return one


func safe_ground() -> bool:
	var ty := floori((P.y + P.h + 1) / T)
	var x0 := floori(P.x / T) - 1
	var x1 := floori((P.x + P.w) / T) + 1
	for tx in range(x0, x1 + 1):
		if tile_at(tx, ty) == "^" or tile_at(tx, ty - 1) == "^":
			return false
	for tx in range(x0 + 1, x1):
		if not is_floor(tx, ty):
			return false
	return true


# --- cámara ---
func clamp_cam(v: float, size: float, view: float) -> float:
	return (size - view) / 2.0 if size <= view else clampf(v, 0.0, size - view)


func cam_target() -> Vector2:
	return Vector2(clamp_cam(P.x + P.w / 2 - VW / 2 + P.face * 60, room.w * T, VW),
		clamp_cam(P.y + P.h / 2 - VH / 2 - 30, room.h * T, VH))


# --- salas ---
func load_room(id: String, entry: String, carry := Vector2.ZERO) -> void:
	var prev := room
	if Data.ARENAS.has(id):
		set_arena(id, false)
	if Data.BOSS_GATES.has(id):
		set_boss_exit(id, run["beaten"].has(Data.BOSS_GATES[id][1]))
	if id == "kira1" or id == "kira2":
		# Los trozos de Kira no guardan lo hecho: cada visita vuelven a estar a medias.
		rooms[id] = Data.build_rooms()[id]
	room = rooms[id]
	if meta["shortcuts"].has(id):
		open_shortcut()
	for ex: Dictionary in room.exits:
		if ex.has("shortcut"):
			# Atajo de un solo sentido: cerrado hasta cruzarlo una vez desde el otro lado.
			_set_door(room, ex, "." if meta["shortcuts"].has(ex["shortcut"]) else "#")
	if not meta["seen_rooms"].has(id):
		meta["seen_rooms"].append(id)
		save()
	enemies.clear(); projs.clear(); pickups.clear(); slashes.clear(); props.clear()
	arena_active = false; arena_wave = 0; arena_delay = 0.0; arena_trigger = -1.0; arena_spawns.clear(); hits.clear()
	boss = null
	for o in room.objs:
		var px: float = o["tx"] * T + 16
		var py: float = (o["ty"] + 1) * T
		match o["type"]:
			"c", "f", "s", "k", "C", "V", "Z", "Q":
				# Una arena ya superada en este intento no vuelve a llenarse.
				enemies.append(mk_enemy(o["type"], px, py))
			"x":
				arena_trigger = px
			"z":
				arena_spawns.append(Vector2(px, py))
			"h":
				if not run["fountains"].has(room.id):
					props.append({"type": "h", "x": px, "y": py, "text": ""})
			"g":
				var key := "%s:%d:%d" % [room.id, o["tx"], o["ty"]]
				if not run["gems"].has(key):
					props.append({"type": "g", "x": px, "y": py, "text": key})
			"B", "E":
				if not run["beaten"].has(o["type"]):
					boss = mk_boss(o["type"], px, py)
					enemies.append(boss)
			"D":
				enemies.append(mk_dummy(px, py, o["text"]))
			"A":
				if not meta["wings"]:
					props.append({"type": "A", "x": px, "y": py, "text": ""})
			"W":
				if not meta["walljump"]:
					props.append({"type": "W", "x": px, "y": py, "text": ""})
			_:
				props.append({"type": o["type"], "x": px, "y": py, "text": o["text"]})
	var en: Vector2i = room.entries[entry]
	P.x = en.x * T + 16 - P.w / 2
	P.y = (en.y + 1) * T - P.h
	P.vx = carry.x
	P.vy = carry.y
	P.dash_t = 0.0
	P.atk_t = 0.0
	P.safe = Vector2(P.x, P.y)
	P.trail.clear()
	cam = cam_target()
	if prev == null or prev.id != room.id:
		banner = {"text": room.name, "sub": room.sub, "t": 0.0}
	dirty = true


## Sale por el tramo del borde en el que está Álex (una sala puede tener varias salidas por el mismo lado).
func start_trans(side: String) -> bool:
	var c := P.center()
	var along := floori(c.y / T) if side in ["left", "right"] else floori(c.x / T)
	var found = null
	for ex in room.exits:
		if ex["side"] != side:
			continue
		if ex["a"] < 0 or (along >= ex["a"] - 1 and along <= ex["b"] + 1):
			found = ex
			break
	if found == null:
		for ex in room.exits:
			if ex["side"] == side:
				found = ex
				break
	if found == null:
		return false
	if found.has("opens") and not meta["shortcuts"].has(found["opens"]):
		meta["shortcuts"].append(found["opens"])
		save()
	state = "trans"
	trans = {"t": 0.0, "to": found["to"], "entry": found["entry"], "loaded": false,
		"carry": Vector2(0.0 if side == "up" else P.vx, -300.0 if side == "up" else 0.0)}
	return true


# --- partículas y números ---
func part(px: float, py: float, pvx: float, pvy: float, life: float, col: Color, size: float, grav := 0.0, glow := false) -> void:
	if parts.size() > 700:
		return
	parts.append({"x": px, "y": py, "vx": pvx, "vy": pvy, "life": life, "max": life, "col": col, "size": size, "g": grav, "glow": glow})


func burst(c: Vector2, n: int, col: Color, spd: float, grav := 0.0, glow := false) -> void:
	for i in n:
		var a := randf() * TAU
		var s := randf_range(spd * 0.3, spd)
		part(c.x, c.y, cos(a) * s, sin(a) * s, randf_range(0.3, 0.8), col, randf_range(1.5, 4.0), grav, glow)


func num(px: float, py: float, txt: String, col: Color, big := false) -> void:
	nums.append({"x": px, "y": py, "txt": txt, "t": 0.0, "col": col, "big": big})


# --- enemigos ---
## Élites: "C" rastrero, "V" revoloteador, "Z" escupidor, "Q" conjurador.
const ELITES := {"C": "c", "V": "f", "Z": "s", "Q": "k"}


func mk_enemy(kind: String, px: float, py: float) -> Ent:
	var elite := ELITES.has(kind)
	if elite:
		kind = ELITES[kind]
	# ancho, alto, vida, fragmentos
	var d: Array = {"c": [26, 22, 30, 3], "f": [24, 20, 22, 2], "s": [30, 30, 45, 5], "k": [24, 32, 35, 4]}[kind]
	var e := Ent.new()
	e.kind = kind
	e.elite = elite
	e.w = d[0]; e.h = d[1]; e.hp = d[2]; e.max_hp = d[2]; e.frags = d[3]
	if elite:
		e.hp *= 2.2; e.max_hp = e.hp; e.frags *= 2
	e.x = px - e.w / 2; e.y = py - e.h
	e.home = Vector2(e.x, e.y)
	e.face = -1 if randf() < 0.5 else 1
	e.t = randf() * 3.0
	e.cd = 1.0 + randf()
	if kind == "k":
		e.cd = 2.0 + randf()
	return e


func mk_boss(kind: String, px: float, py: float) -> Ent:
	var b := Ent.new()
	b.kind = kind
	if kind == "B":
		b.w = 56; b.h = 96; b.hp = 500
	else:
		b.w = 40; b.h = 72; b.hp = 600
	b.max_hp = b.hp
	b.x = px - b.w / 2; b.y = py - b.h
	b.face = -1
	b.state = "sleep"
	b.name = Data.BOSS_NAMES[kind]
	return b


## Muñeco de entrenamiento de la técnica de Kira: no muere; pide una combinación de golpes.
func mk_dummy(px: float, py: float, combo: String) -> Ent:
	var e := Ent.new()
	e.kind = "dummy"
	e.w = 24; e.h = 40; e.hp = 1; e.max_hp = 1
	e.x = px - 12; e.y = py - 40
	e.seq = Array(combo.split(","))
	return e


func common_enemy(e: Ent, dt: float) -> void:
	if e.kind != "B" and e.kind != "E" and e.kind != "core":
		e.t += dt
	e.flash = maxf(0.0, e.flash - dt)
	if e.burn > 0:
		e.burn -= dt
		e.burn_tick += dt
		if randf() < 0.3:
			part(e.x + randf() * e.w, e.y + randf() * e.h, randf_range(-20, 20), randf_range(-80, -30), 0.5, Color("22e4ff"), 2.5, 0.0, true)
		if e.burn_tick >= 0.25:
			e.burn_tick = 0.0
			damage_enemy(e, 3, Color("8ff0ff"))


func upd_enemy(e: Ent, dt: float) -> void:
	common_enemy(e, dt)
	if e.dead:
		return
	var pc := P.center()
	var ec := e.center()
	match e.kind:
		"c":
			e.vy = minf(e.vy + GRAV * dt, MAXFALL)
			var vx := e.face * (85.0 if e.elite else 55.0) + e.kb
			e.kb = move_toward(e.kb, 0.0, 900 * dt)
			if move_x(e, vx * dt) and absf(e.kb) < 1:
				e.face *= -1
			move_y(e, e.vy * dt)
			if touching_spikes(e.rect()):
				# Empujado a los pinchos: muere sin dejar núcleo (dentro del foso no se podría romper).
				e.revived = true
				e.flash = 0.09
				num(e.center().x, e.y - 6, "¡Pinchos!", Color("fff3c4"))
				kill_enemy(e)
				return
			if e.on_ground and absf(e.kb) < 1:
				var fx := e.x + e.w + 2 if e.face > 0 else e.x - 2
				var ftx := floori(fx / T)
				if not is_floor(ftx, floori((e.y + e.h + 4) / T)) or tile_at(ftx, floori((e.y + e.h - 4) / T)) == "^":
					e.face *= -1
		"f":
			var d := pc - ec
			var dist := maxf(d.length(), 1.0)
			if dist < 330 or e.aggro:
				e.aggro = true
				e.vx = move_toward(e.vx, d.x / dist * 150, 300 * dt)
				e.vy = move_toward(e.vy, d.y / dist * 150, 300 * dt)
			else:
				e.vx = move_toward(e.vx, 0.0, 100 * dt)
				e.vy = sin(e.t * 2) * 30
			e.x = clampf(e.x + e.vx * dt, T, room.w * T - T - e.w)
			e.y = clampf(e.y + e.vy * dt, T, room.h * T - 2 * T - e.h)
			if absf(d.x) > 4:
				e.face = signi(int(d.x))
			if e.elite and e.aggro:
				# El revoloteador de élite dispara un orbe hacia Álex cada 2,5 s.
				e.cd -= dt
				if e.cd <= 0:
					e.cd = 2.5
					var q := Ent.new()
					q.kind = "orb"; q.hostile = true; q.x = ec.x; q.y = ec.y
					q.vx = d.x / dist * 260; q.vy = d.y / dist * 260; q.r = 7; q.life = 3
					projs.append(q)
		"s":
			var dx := pc.x - ec.x
			var dy := pc.y - e.y
			e.face = 1 if dx >= 0 else -1
			e.cd -= dt
			if e.cd <= 0.55 and not e.charging and absf(dx) < 540 and absf(dy) < 320:
				e.charging = true
			if e.cd <= 0:
				if e.charging:
					var tt := 0.85
					# El escupidor de élite lanza tres a la vez, abiertos en abanico.
					for spread in ([-90.0, 0.0, 90.0] if e.elite else [0.0]):
						var q := Ent.new()
						q.kind = "glob"; q.hostile = true; q.x = ec.x; q.y = e.y + 6
						q.vx = clampf((dx + spread) / tt, -520, 520); q.vy = (dy - 0.5 * 1200 * tt * tt) / tt
						q.g = 1200; q.r = 7; q.life = 4
						projs.append(q)
					burst(Vector2(ec.x, e.y + 6), 8, Color("ff9ab0"), 160, 600)
				e.cd = 2.2
				e.charging = false
		"core":
			e.t -= dt
			e.vy = minf(e.vy + GRAV * dt, MAXFALL)
			move_y(e, e.vy * dt)
			if e.t <= 0:
				# El núcleo sobrevivió: el rastrero continúa.
				e.dead = true
				var c := mk_enemy("c", ec.x, e.y + e.h)
				c.revived = true
				enemies.append(c)
				burst(ec, 20, Color("e8384f"), 260, 0.0, true)
				num(ec.x, e.y - 10, "CONTINUE", Color("e8384f"))
		"k":
			# Conjurador: flota en su sitio y carga un hechizo (2 s, barra visible). Un golpe lo
			# interrumpe; si lo termina, cura 15 a todos los enemigos y les da un escudo.
			e.y = e.home.y + sin(e.t * 2) * 6
			e.face = 1 if pc.x >= ec.x else -1
			if e.charging:
				e.cd += dt
				if randf() < 0.5:
					part(ec.x + randf_range(-14, 14), ec.y + randf_range(-16, 16), 0, -40, 0.5, Color("7be36b"), 2.5, 0.0, true)
				if e.cd >= charge_time(e):
					e.charging = false
					e.cd = 3.0
					for o in enemies:
						if not o.dead and o.kind in ["c", "f", "s", "k", "B", "E"]:
							o.hp = minf(o.max_hp, o.hp + (25 if e.elite else 15))
							o.shield = 1
					burst(ec, 30, Color("7be36b"), 300, 0.0, true)
					num(ec.x, e.y - 10, "¡Hechizo!", Color("7be36b"))
			else:
				e.cd -= dt
				if e.cd <= 0 and ec.distance_to(pc) < 600:
					e.charging = true
					e.cd = 0.0


## El conjurador de élite carga más rápido.
func charge_time(e: Ent) -> float:
	return 1.4 if e.elite else 2.0


## El golpe interrumpe al conjurador si estaba cargando.
func interrupt(e: Ent) -> void:
	if e.kind == "k" and e.charging:
		e.charging = false
		e.cd = 2.5
		num(e.center().x, e.y - 10, "Interrumpido", Color("fff3c4"))


func lantern_box(b: Ent) -> Rect2:
	return Rect2(b.x + b.w - 4 if b.face > 0 else b.x - 44, b.y + 30, 48, 44)


## El Alumno Eterno: aparece y desaparece, lanza orbes y runas, y en cada fase se vuelve
## resistente al ataque con el que más daño le han hecho (el miedo a equivocarse dos veces).
func upd_student(b: Ent, dt: float) -> void:
	common_enemy(b, dt)
	var pc := P.center()
	var bc := b.center()
	b.vy = minf(b.vy + GRAV * dt, MAXFALL)
	b.summon_cd -= dt
	var ratio := b.hp / b.max_hp
	var want_phase := 1 if ratio > 0.66 else (2 if ratio > 0.33 else 3)
	if want_phase > b.phase and b.state != "dying":
		b.phase = want_phase
		var best := ""
		for k in b.dmg_by:
			if best == "" or b.dmg_by[k] > b.dmg_by[best]:
				best = k
		b.resist = best
		b.dmg_by = {}
		shake = 12; flash_a = 0.4; flash_col = Color("e0b84a")
		if best != "":
			banner = {"text": "Ha estudiado tu ataque", "sub": "Ahora resiste " + Data.ATTACK_NAMES.get(best, best), "t": 0.0}
	match b.state:
		"sleep":
			if pc.x > 7 * T:
				b.state = "roar"; b.t = 1.4
				set_arena(room.id, true)
				shake = 10
				banner = {"text": b.name, "sub": Data.BOSS_SUBS[b.kind], "t": 0.0}
		"roar":
			b.t -= dt
			if randf() < 0.6:
				part(bc.x + randf_range(-30, 30), b.y + 10, randf_range(-40, 40), randf_range(-160, -60), 0.8, Color("e0b84a"), 3, 0.0, true)
			if b.t <= 0:
				b.state = "idle"; b.t = 0.6
		"idle":
			b.face = 1 if pc.x >= bc.x else -1
			b.t -= dt
			if b.t <= 0:
				var opts: Array = ["volley", "volley", "blink", "runes"]
				if b.phase >= 2 and b.summon_cd <= 0:
					opts.append("summon")
				match opts.pick_random():
					"volley":
						b.state = "volley_wind"; b.t = 0.5
					"blink":
						b.state = "blink_out"; b.t = 0.35
					"runes":
						b.state = "runes"; b.t = 1.2; b.rained = false
					"summon":
						b.state = "summon"; b.t = 0.8; b.summon_cd = 14
		"volley_wind":
			b.t -= dt
			if b.t <= 0:
				var n := 3 + b.phase
				var base := (pc - bc).angle()
				for i in n:
					var a := base + (i - (n - 1) / 2.0) * 0.22
					var q := Ent.new()
					q.kind = "orb"; q.hostile = true; q.x = bc.x; q.y = bc.y - 10
					q.vx = cos(a) * 330; q.vy = sin(a) * 330; q.r = 8; q.life = 3
					projs.append(q)
				b.state = "idle"; b.t = 0.9 if b.phase == 1 else 0.6
		"blink_out":
			b.t -= dt
			if b.t <= 0:
				# Reaparece lejos de Álex, en el suelo del aula.
				var nx := pc.x + (260.0 if randf() < 0.5 else -260.0)
				if nx < 3 * T or nx > (room.w - 3) * T:
					nx = pc.x - (nx - pc.x)
				b.x = clampf(nx, 2 * T, (room.w - 2) * T - b.w) - b.w / 2
				burst(b.center(), 24, Color("e0b84a"), 260, 0.0, true)
				b.state = "blink_in"; b.t = 0.25
		"blink_in":
			b.t -= dt
			if b.t <= 0:
				b.state = "idle"; b.t = 0.4
		"runes":
			b.t -= dt
			if not b.rained and b.t < 0.9:
				b.rained = true
				for i in 2 + b.phase * 2:
					var q := Ent.new()
					q.kind = "rune"; q.hostile = true
					q.x = clampf(pc.x + randf_range(-300, 300), 2 * T, (room.w - 2) * T)
					q.t = 0.8; q.life = 1.6
					projs.append(q)
			if b.t <= 0:
				b.state = "idle"; b.t = 0.5
		"summon":
			b.t -= dt
			if b.t <= 0:
				var k := mk_enemy("k", bc.x + randf_range(-120, 120), b.y - 40)
				k.cd = 1.0
				enemies.append(k)
				burst(k.center(), 20, Color("7be36b"), 240, 0.0, true)
				b.state = "idle"; b.t = 0.6
		"dying":
			b.t -= dt
			if randf() < 0.9:
				burst(bc + Vector2(randf_range(-20, 20), randf_range(-30, 30)), 3, Color("e0b84a"), 260, 0.0, true)
			shake = maxf(shake, 5)
			if b.t <= 0:
				b.dead = true
				burst(bc, 80, Color("e0b84a"), 520, 0.0, true)
				boss_defeated(b)
	move_y(b, b.vy * dt)


func upd_boss(b: Ent, dt: float) -> void:
	common_enemy(b, dt)
	var pcx := P.center().x
	var bcx := b.center().x
	b.vy = minf(b.vy + GRAV * dt, MAXFALL)
	b.summon_cd -= dt
	if b.phase == 1 and b.hp <= b.max_hp / 2 and b.state != "dying":
		b.phase = 2
		shake = 14; flash_a = 0.4; flash_col = Color("e8384f")
		banner = {"text": "¡Continue!", "sub": "El Rey se niega a perder", "t": 0.0}
	match b.state:
		"sleep":
			b.vx = 0
			if pcx > 7 * T:
				b.state = "roar"; b.t = 1.4
				set_arena(room.id, true)
				shake = 12
				banner = {"text": b.name, "sub": Data.BOSS_SUBS[b.kind], "t": 0.0}
		"roar":
			b.t -= dt
			if randf() < 0.6:
				part(bcx + randf_range(-30, 30), b.y + 20, randf_range(-60, 60), randf_range(-200, -80), 0.8, Color("f2c14e"), 3, 0.0, true)
			if b.t <= 0:
				b.state = "idle"; b.t = 0.5
		"idle":
			b.vx = move_toward(b.vx, 0.0, 1400 * dt)
			b.face = 1 if pcx >= bcx else -1
			b.t -= dt
			if b.t <= 0:
				choose_boss_move(b)
		"walk":
			b.face = 1 if pcx >= bcx else -1
			b.vx = b.face * (160.0 if b.phase == 2 else 115.0)
			b.t -= dt
			if b.t <= 0 or absf(pcx - bcx) < 80:
				b.state = "idle"; b.t = 0.2
		"slam_wind":
			b.vx = 0
			b.t -= dt
			if b.t <= 0:
				b.vy = -900
				b.vx = clampf((pcx - bcx) / 0.95, -460, 460)
				b.state = "air"; b.air_t = 0.0; b.on_ground = false
		"air":
			b.air_t += dt
			if b.air_t > 0.12 and b.on_ground:
				var fy := b.y + b.h
				for s in [-1, 1]:
					var q := Ent.new()
					q.kind = "shock"; q.hostile = true; q.x = bcx - 14; q.y = fy - 26; q.w = 28; q.h = 26
					q.vx = s * (470.0 if b.phase == 2 else 400.0); q.life = 2.4
					projs.append(q)
				shake = maxf(shake, 16)
				burst(Vector2(bcx, fy), 26, Color("f2c14e"), 300, 900)
				b.vx = 0; b.state = "idle"; b.t = 0.5 if b.phase == 2 else 0.8
		"sweep_wind":
			b.vx = 0
			b.face = 1 if pcx >= bcx else -1
			b.t -= dt
			if b.t <= 0:
				b.state = "sweep"; b.t = 0.6
		"sweep":
			b.vx = b.face * 640
			b.t -= dt
			if randf() < 0.8:
				var lc := lantern_box(b).get_center()
				part(lc.x, lc.y, randf_range(-40, 40), randf_range(-60, 20), 0.4, Color("f2c14e"), 3, 0.0, true)
			if b.t <= 0 or b.hit_wall:
				if b.hit_wall:
					shake = maxf(shake, 8)
				b.state = "idle"; b.t = 0.7; b.vx = 0
		"rain":
			b.vx = 0
			b.t -= dt
			if not b.rained and b.t < 0.6:
				b.rained = true
				for i in 6:
					var q := Ent.new()
					q.kind = "warn"; q.hostile = true
					q.x = clampf(pcx + randf_range(-280, 280), 2 * T, room.w * T - 2 * T)
					q.t = 0.75 + i * 0.08; q.life = 3
					projs.append(q)
			if b.t <= 0:
				b.state = "idle"; b.t = 0.5
		"summon":
			b.vx = 0
			b.t -= dt
			if b.t <= 0:
				for s in [-1, 1]:
					var f := mk_enemy("f", bcx + s * 60, b.y)
					f.aggro = true
					enemies.append(f)
					burst(Vector2(bcx + s * 60, b.y), 14, Color("e8384f"), 200)
				b.state = "idle"; b.t = 0.6
		"dying":
			b.vx = 0
			b.t -= dt
			if randf() < 0.9:
				burst(Vector2(bcx + randf_range(-30, 30), b.y + randf_range(10, 90)), 3, Color("f2c14e") if randf() < 0.5 else Color("fff1c0"), 260, 0.0, true)
			shake = maxf(shake, 5)
			if b.t <= 0:
				b.dead = true
				burst(b.center(), 80, Color("f2c14e"), 520, 0.0, true)
				boss_defeated(b)
	b.hit_wall = move_x(b, b.vx * dt)
	move_y(b, b.vy * dt)


func choose_boss_move(b: Ent) -> void:
	var opts: Array = ["walk", "slam", "slam", "sweep"] if absf(P.x - b.x) > 220 else ["slam", "sweep", "sweep"]
	if b.phase == 2:
		opts.append_array(["rain", "rain"])
		if b.summon_cd <= 0:
			opts.append("summon")
	match opts.pick_random():
		"walk":
			b.state = "walk"; b.t = 1.0
		"slam":
			b.state = "slam_wind"; b.t = 0.45
		"sweep":
			b.state = "sweep_wind"; b.t = 0.45 if b.phase == 2 else 0.65
		"rain":
			b.state = "rain"; b.t = 1.1; b.rained = false
		"summon":
			b.state = "summon"; b.t = 0.8; b.summon_cd = 12


## `how`: con qué se ha hecho el daño ("side", "up", "down", "cast" u "other"), para el Alumno Eterno.
func damage_enemy(e: Ent, d: int, col := Color("fff3c4"), crit := false, how := "other") -> void:
	if e.dead or e.state == "dying" or e.kind == "dummy" or (e.kind in ["B", "E"] and e.state == "sleep"):
		return
	interrupt(e)
	if e.shield > 0:
		e.shield -= 1
		e.flash = 0.09
		num(e.center().x, e.y - 6, "Escudo", Color("7be36b"))
		return
	if e.kind == "E" and how != "other":
		if how == e.resist:
			d = maxi(1, roundi(d * 0.25))
			col = Color("8a8698")
		e.dmg_by[how] = e.dmg_by.get(how, 0) + d
	e.hp -= d
	e.flash = 0.09
	num(e.center().x + randf_range(-8, 8), e.y - 6, str(d), Color("ff5a7a") if crit else col, crit)
	if e.hp <= 0:
		kill_enemy(e)


func kill_enemy(e: Ent) -> void:
	if e.kind == "B" or e.kind == "E":
		if e.state != "dying":
			e.state = "dying"; e.t = 1.8; e.hp = 0; e.vx = 0
			for o in enemies:
				if o != e and not o.dead:
					o.dead = true
					burst(o.center(), 14, Color("e8384f"), 220, 600)
			projs = projs.filter(func(q): return not q.hostile)
		return
	e.dead = true
	var c := e.center()
	burst(c, 20, Color("e8e2f4"), 260, 900)
	burst(c, 10, room_rim(), 200, 0.0, true)
	if e.kind == "core":
		num(c.x, e.y - 10, "Núcleo roto", Color("f2c14e"))
		return
	for i in e.frags:
		var k := Ent.new()
		k.kind = "frag"; k.x = c.x; k.y = c.y; k.vx = randf_range(-160, 160); k.vy = randf_range(-380, -160); k.amt = 1
		pickups.append(k)
	# Regla del Reino del Continue: el rastrero deja un núcleo; si sobrevive, vuelve.
	if e.kind == "c" and not e.revived:
		var core := Ent.new()
		core.kind = "core"; core.w = 14; core.h = 14; core.x = c.x - 7; core.y = c.y - 7
		core.hp = 1; core.max_hp = 1; core.t = 4.0; core.vy = -200
		enemies.append(core)
		P.atk_hits[core] = true  # el tajo que lo derriba no rompe también su núcleo


## Vencer a un jefe vale para este intento (en el siguiente vuelve). La primera vez sale la
## pantalla de mundo superado; las siguientes, solo un rótulo.
var end_world := 1


func boss_defeated(b: Ent) -> void:
	run["beaten"][b.kind] = true
	boss = null
	set_arena(room.id, false)
	flash_a = 1.0; flash_col = Color("fff4d0")
	var key := "boss" if b.kind == "B" else "boss2"
	var first: bool = not meta[key]
	meta[key] = true
	var reward := 60 if b.kind == "B" else 80
	if not first:
		reward /= 2
	meta["frags"] = int(meta["frags"]) + reward
	save()
	if Data.BOSS_GATES.has(room.id):
		set_boss_exit(room.id, true)
	end_world = 1 if b.kind == "B" else 2
	if first:
		state = "end"; end_t = 0.0
	else:
		banner = {"text": b.name + " vencido", "sub": "+%d fragmentos" % reward, "t": 0.0}


func room_rim() -> Color:
	return Data.PALETTES[room.pal]["rim"]


# --- Álex ---
func hurt_player(src_x = null) -> bool:
	if P.inv > 0 or state != "play":
		return false
	P.hp -= 1
	P.inv = 1.7 if has("combatejusto") else 1.1
	P.heal_t = 0.0
	P.dash_t = 0.0
	var dir := -P.face if src_x == null else (1 if P.center().x >= float(src_x) else -1)
	P.vx = dir * 320.0
	P.vy = -380.0
	hitstop = 0.14
	shake = maxf(shake, 11)
	flash_a = 0.35; flash_col = Color("ff2a4a")
	burst(P.center(), 16, DEBUG_COL, 260, 900)
	if has("apartar"):
		for e in enemies:
			if not e.dead and e.center().distance_to(P.center()) < 120:
				damage_enemy(e, 40, Color("ffb070"))
		burst(P.center(), 24, Color("ff9a3a"), 340)
	if P.hp <= 0:
		if int(run["revive"]) > 0:
			run["revive"] = int(run["revive"]) - 1
			P.hp = ceili(max_hp() / 2.0)
			P.inv = 2.0
			# Que se note: pausa larga, destello dorado y aviso grande en el centro (lo pinta UIView).
			revive_fx = 2.2
			hitstop = 0.45
			shake = maxf(shake, 14)
			flash_col = Color("f2c14e"); flash_a = 0.9
			burst(P.center(), 60, Color("f2c14e"), 420, 0.0, true)
		else:
			die()
	return true


func die() -> void:
	state = "dead"
	dead_t = 0.0
	revive_fx = 0.0
	meta["deaths"] = int(meta["deaths"]) + 1
	save()
	burst(P.center(), 60, DEBUG_COL, 420, 700)
	burst(Vector2(P.center().x, P.y), 20, Color("ffe14d"), 200, 0.0, true)


func atk_box() -> Rect2:
	var cx := P.center().x
	var r := 16.0 if P.resonance > 0 else 0.0  # la resonancia alarga el alcance del clic
	match P.atk_dir:
		"up":
			return Rect2(cx - 26, P.y - 50 - r, 52, 52 + r)
		"down":
			return Rect2(cx - 26, P.y + P.h - 6, 52, 52 + r)
	return Rect2(P.x + P.w - 2 if P.face > 0 else P.x - 50 - r, P.y - 10, 52 + r, 46)


func resolve_attack() -> void:
	var b := atk_box()
	var pogo := false
	for e in enemies:
		if e.dead or P.atk_hits.has(e) or e.state == "dying":
			continue
		if b.intersects(e.rect()):
			P.atk_hits[e] = true
			if P.atk_dir == "down":
				pogo = true
			if e.kind == "dummy":
				dummy_hit(e)
				continue
			hit_enemy_melee(e, b)
	# Cristales de la Academia: un clic los hace resonar.
	for o in props:
		if o["type"] == "R" and not P.atk_hits.has(o) and b.intersects(Rect2(o["x"] - 12, o["y"] - 40, 24, 40)):
			P.atk_hits[o] = true
			P.resonance = 6.0
			flash_a = 0.25; flash_col = Color("e0b84a")
			burst(Vector2(o["x"], o["y"] - 20), 24, Color("e0b84a"), 280, 0.0, true)
			num(o["x"], o["y"] - 48, "Resonancia", Color("e0b84a"))
	# El tajo corta los proyectiles del escupidor.
	for q in projs:
		if q.kind == "glob" and not q.dead and b.has_point(Vector2(q.x, q.y)):
			q.dead = true
			burst(Vector2(q.x, q.y), 8, Color("ff9ab0"), 180)
	if P.atk_dir == "down" and not pogo and touching_spikes(b):
		pogo = true
	place_blocks(b)
	if break_blocks(b) and P.atk_dir == "down":
		pogo = true
	if pogo and not P.pogo_done:
		P.pogo_done = true
		P.vy = -POGO
		P.air_jumps = 1
		if has("disciplina"):
			P.dash_charges = 2 if has("carrera") else 1


## Bloques rompibles ("b", "n", "w"): dos clics los rompen. Los "n" sueltan fragmentos; los "w" son muros
## falsos que se ven como una pared normal hasta el primer clic.
## Devuelve si el clic ha dado en alguno (para rebotar con el clic hacia abajo).
func break_blocks(b: Rect2) -> bool:
	var any := false
	for ty in range(floori(b.position.y / T), floori(b.end.y / T) + 1):
		for tx in range(floori(b.position.x / T), floori(b.end.x / T) + 1):
			var c := tile_at(tx, ty)
			if not c in ["b", "n", "w", "a"] or not b.intersects(Rect2(tx * T, ty * T, T, T)):
				continue
			if c == "a" and not shortcut_side_ok(tx):
				continue
			var key := Vector2i(tx, ty)
			if P.atk_hits.has(key):
				continue
			P.atk_hits[key] = true
			any = true
			hits[key] = hits.get(key, 0) + 1
			var center := Vector2(tx * T + 16, ty * T + 16)
			burst(center, 8, Data.PALETTES[room.pal]["stone"].lightened(0.4), 200, 900)
			if hits[key] >= 2 and c == "a":
				hits.erase(key)
				open_shortcut()
				meta["shortcuts"].append(room.id)
				save()
				burst(center, 30, room_rim(), 320, 900)
				shake = maxf(shake, 8)
				num(center.x, center.y - 10, "¡Atajo abierto!", Color("6ff3ff"), true)
			elif hits[key] >= 2:
				room.g[ty][tx] = "."
				hits.erase(key)
				burst(center, 16, room_rim(), 260, 900)
				shake = maxf(shake, 4)
				if c == "n":
					num(center.x, center.y - 10, "¡Sorpresa!", Color("f2c14e"))
					for i in 4:
						var k := Ent.new()
						k.kind = "frag"; k.x = center.x; k.y = center.y; k.vx = randf_range(-160, 160); k.vy = randf_range(-380, -160); k.amt = 1
						pickups.append(k)
	return any


## Un atajo solo se rompe desde su lado: Álex tiene que estar en la parte de la sala de la que sale.
func shortcut_side_ok(tx: int) -> bool:
	var px := P.center().x
	return px > tx * T + 16 if room.shortcut_from == "right" else px < tx * T + 16


## Quita el muro del atajo de la sala actual.
func open_shortcut() -> void:
	for y in room.h:
		for x in room.w:
			if room.g[y][x] == "a":
				room.g[y][x] = "."


## Arena: al entrar se cierran las puertas ("d") y salen las oleadas por los puntos "z". Al vaciar
## la última se abren, cura 2 corazones y suelta 10 fragmentos. Solo una vez por intento.
func upd_arena(dt: float) -> void:
	if room.waves.is_empty() or run["arenas"].has(room.id):
		return
	if not arena_active:
		var cx := P.center().x
		if arena_trigger >= 0 and cx > 4 * T and cx < (room.w - 4) * T:
			arena_active = true
			arena_wave = 0
			arena_delay = 0.8
			shake = maxf(shake, 8)
			banner = {"text": "¡Arena!", "sub": "Sobrevive a %d oleadas" % room.waves.size(), "t": 0.0}
		return
	if not enemies.is_empty():
		return
	arena_delay -= dt
	if arena_delay > 0:
		return
	if arena_wave < room.waves.size():
		var wave: Array = room.waves[arena_wave]
		for i in wave.size():
			var sp: Vector2 = arena_spawns[(i + arena_wave) % arena_spawns.size()] if not arena_spawns.is_empty() else Vector2(room.w * T / 2.0, 3 * T)
			var e := mk_enemy(wave[i], sp.x, sp.y)
			e.aggro = true
			enemies.append(e)
			burst(e.center(), 14, Color("e8384f"), 200, 0.0, true)
		arena_wave += 1
		arena_delay = 1.0
		return
	# Arena superada.
	arena_active = false
	run["arenas"][room.id] = true
	P.hp = mini(max_hp(), P.hp + 2)
	flash_a = 0.4; flash_col = Color("f2c14e")
	banner = {"text": "Arena superada", "sub": "+2 corazones · +10 fragmentos", "t": 0.0}
	for i in 10:
		var k := Ent.new()
		k.kind = "frag"; k.x = P.center().x; k.y = P.y - 20; k.vx = randf_range(-200, 200); k.vy = randf_range(-420, -200); k.amt = 1
		pickups.append(k)


## Un clic sobre un bloque sin colocar ("p") lo coloca: pasa a ser una plataforma que se pisa.
func place_blocks(b: Rect2) -> void:
	for ty in range(floori(b.position.y / T), floori(b.end.y / T) + 1):
		for tx in range(floori(b.position.x / T), floori(b.end.x / T) + 1):
			if tile_at(tx, ty) == "p" and b.intersects(Rect2(tx * T, ty * T, T, T)):
				room.g[ty][tx] = "="
				burst(Vector2(tx * T + 16, ty * T + 6), 8, KIRA_COL, 160, 0.0, true)
				num(tx * T + 16, ty * T - 4, "Colocado", KIRA_COL)


## Golpe a un muñeco de la técnica de Kira: tiene que llegar en el orden que pide.
func dummy_hit(e: Ent) -> void:
	if e.idx >= e.seq.size():
		return
	if P.atk_dir == e.seq[e.idx]:
		e.idx += 1
		e.flash = 0.09
		burst(e.center(), 10, KIRA_COL, 200, 0.0, true)
		if e.idx >= e.seq.size():
			num(e.center().x, e.y - 12, "¡Aprendido!", KIRA_COL, true)
			if enemies.all(func(o): return o.kind != "dummy" or o.idx >= o.seq.size()):
				# Toda la técnica aprendida: aparece la bandera.
				props.append({"type": "G", "x": (room.w - 4) * T + 16.0, "y": (room.h - 2) * T + 0.0, "text": ""})
				banner = {"text": "Técnica completa", "sub": "Ve a la bandera", "t": 0.0}
	else:
		e.idx = 0
		e.flash = 0.09
		num(e.center().x, e.y - 12, "Otra vez", Color("ff5a7a"))


func hit_enemy_melee(e: Ent, b: Rect2) -> void:
	var d := 10.0 + 4 * int(meta["up"]["dano"])
	if P.combo == 2:
		d *= 1.5
	if P.resonance > 0:
		d *= 1.4
	if has("espadon"):
		d *= 1.3
	if P.atk_dir == "down" and has("disciplina"):
		d *= 2
	var crit := false
	if P.crit_next:
		d *= 3; P.crit_next = false; crit = true
	elif has("diagnostico") and randf() < 0.2:
		d *= 2.5; crit = true
	damage_enemy(e, roundi(d), Color("fff3c4"), crit, P.atk_dir)
	if has("sobrecarga"):
		e.burn = 3.0
	if not e.kind in ["B", "E", "core"]:
		var kb := 400.0 if has("espadon") else 220.0
		var dir := P.face if P.atk_dir == "side" else (1 if e.x >= P.x else -1)
		if e.kind == "f":
			e.vx = dir * kb * 1.2
			e.vy = -kb if P.atk_dir == "up" else (kb if P.atk_dir == "down" else -60.0)
		elif e.kind == "c":
			e.kb = dir * kb
	if e.kind != "core":
		P.debug = mini(DEBUG_MAX, P.debug + (2 if has("masdatos") else 1))
	hitstop = maxf(hitstop, 0.08 if crit else 0.05)
	shake = maxf(shake, 7.0 if crit else 4.0)
	if P.atk_dir == "side":
		P.vx -= P.face * 90
	var hp := Vector2(clampf(e.center().x, b.position.x, b.end.x), clampf(e.center().y, b.position.y, b.end.y))
	burst(hp, 10, Color("fff3c4"), 320)
	burst(hp, 6, Color("ff5a7a") if crit else DEBUG_COL, 240, 0.0, true)


func update_player(dt: float) -> void:
	P.inv = maxf(0.0, P.inv - dt)
	P.dash_cd = maxf(0.0, P.dash_cd - dt)
	P.atk_cd = maxf(0.0, P.atk_cd - dt)
	P.combo_t = maxf(0.0, P.combo_t - dt)
	P.jump_buf = maxf(0.0, P.jump_buf - dt)
	P.drop_t = maxf(0.0, P.drop_t - dt)
	P.squash = move_toward(P.squash, 0.0, dt * 5)
	P.cast_cd = maxf(0.0, P.cast_cd - dt)
	P.resonance = maxf(0.0, P.resonance - dt)
	P.ctrl_lock = maxf(0.0, P.ctrl_lock - dt)
	P.wall_coyote = maxf(0.0, P.wall_coyote - dt)
	var ix := (1 if held("right") else 0) - (1 if held("left") else 0)
	# Salto en pared: en el aire, empujando hacia una pared mientras cae, se desliza despacio.
	P.wall_dir = 0
	if meta["walljump"] and not P.on_ground and ix != 0 and wall_at(ix):
		P.wall_dir = ix
		P.last_wall = ix
		P.wall_coyote = 0.1
		P.dash_charges = 2 if has("carrera") else 1
		if P.vy > 140:
			P.vy = 140
			if randf() < 0.4:
				part(P.center().x + ix * 10, P.y + P.h - 4, -ix * 30, -20, 0.3, Color("c9c2d6"), 2)
	# Parche: con 2 puntos de depuración, mantener para recuperar un corazón.
	if held("heal") and P.on_ground and P.debug >= DEBUG_COST and P.hp < max_hp() and P.dash_t <= 0:
		P.heal_t += dt
		if randf() < 0.6:
			part(P.x + randf_range(-6, P.w + 6), P.y + P.h, randf_range(-10, 10), randf_range(-140, -60), 0.6, DEBUG_COL, 2.5, 0.0, true)
		if P.heal_t >= 0.8:
			P.hp += 1; P.debug -= DEBUG_COST; P.heal_t = 0.0
			flash_a = 0.25; flash_col = DEBUG_COL
			num(P.center().x, P.y - 10, "Parche: +1", DEBUG_COL)
	else:
		P.heal_t = 0.0
	var healing := P.heal_t > 0
	if hit("jump"):
		P.jump_buf = 0.12
	if hit("dash") and P.dash_cd <= 0 and P.dash_charges > 0 and not healing:
		if ix != 0:
			P.face = ix
		P.dash_t = 0.16; P.dash_cd = 0.38; P.dash_charges -= 1
		P.inv = maxf(P.inv, 0.2); P.vy = 0.0
		if has("reinicio"):
			P.crit_next = true
		burst(P.center(), 10, DEBUG_COL, 180, 0.0, true)
	if P.dash_t > 0:
		P.dash_t -= dt
		P.vx = P.face * DASH
		P.vy = 0.0
		P.trail.append({"x": P.x, "y": P.y, "face": P.face, "a": 0.45})
		if has("farolas"):
			P.fire_t -= dt
			if P.fire_t <= 0:
				P.fire_t = 0.035
				var q := Ent.new()
				q.kind = "fire"; q.x = P.center().x - 10; q.y = P.y + P.h - 20; q.w = 20; q.h = 20; q.life = 1.1
				projs.append(q)
	else:
		var sp := RUN * (1.15 if has("combatejusto") else 1.0) * (0.0 if healing else 1.0)
		if P.ctrl_lock <= 0:
			P.vx = move_toward(P.vx, ix * sp, (2600.0 if P.on_ground else 1800.0) * dt)
			if ix != 0 and not healing:
				P.face = ix
		if P.wall_dir != 0:
			P.face = -P.wall_dir
		var g := GRAV
		if P.vy < 0 and not held("jump"):
			g *= 2.2
		P.vy = minf(P.vy + g * dt, MAXFALL)
		if P.wall_dir != 0:
			P.vy = minf(P.vy, 140)
	if P.jump_buf > 0 and not healing:
		if held("down") and P.on_ground and standing_on_one_way():
			P.drop_t = 0.22; P.jump_buf = 0.0; P.on_ground = false
		elif P.coyote > 0:
			P.vy = -JUMP; P.coyote = 0.0; P.jump_buf = 0.0; P.on_ground = false; P.dash_t = 0.0
			burst(Vector2(P.center().x, P.y + P.h), 6, Color("c9c2d6"), 120)
		elif P.wall_coyote > 0 and P.last_wall != 0:
			# Saltar desde la pared: hacia fuera y hacia arriba, con un instante sin control.
			P.vy = -JUMP * 0.95; P.vx = -P.last_wall * 260.0; P.face = -P.last_wall
			P.ctrl_lock = 0.12; P.wall_coyote = 0.0; P.jump_buf = 0.0; P.dash_t = 0.0; P.air_jumps = 1
			burst(Vector2(P.center().x + P.last_wall * 10, P.center().y), 8, Color("c9c2d6"), 140)
		elif meta["wings"] and P.air_jumps > 0:
			P.vy = -DJUMP; P.air_jumps -= 1; P.jump_buf = 0.0; P.dash_t = 0.0
			for i in 14:
				part(P.center().x + randf_range(-14, 14), P.y + P.h, randf_range(-120, 120), randf_range(20, 120), 0.5, Color("ffe14d"), 2.5, 0.0, true)
	if hit("attack") and P.atk_cd <= 0 and not healing:
		P.atk_dir = "up" if held("up") else ("down" if held("down") and not P.on_ground else "side")
		P.combo = (P.combo + 1) % 3 if P.combo_t > 0 else 0
		P.combo_t = 0.6; P.atk_t = 0.11; P.atk_cd = 0.28
		P.atk_hits = {}; P.pogo_done = false
		slashes.append({"dir": P.atk_dir, "face": P.face, "t": 0.0, "combo": P.combo})
	# Excepción: gasta 2 puntos de depuración y lanza una ventana de error.
	if hit("cast") and not healing and P.debug >= DEBUG_COST and P.cast_cd <= 0:
		P.debug -= DEBUG_COST; P.cast_cd = 0.35
		var boom := has("reforzado")
		var q := Ent.new()
		q.kind = "spark"; q.x = P.center().x + P.face * 14; q.y = P.y + 12; q.vx = P.face * 760; q.r = 8
		q.dmg = 50 if boom else 25; q.life = 1.2; q.boom = boom
		projs.append(q)
		P.vx -= P.face * 120
	move_x(P, P.vx * dt)
	move_y(P, P.vy * dt)
	if P.on_ground:
		if not P.was_ground:
			P.squash = 1.0
			burst(Vector2(P.center().x, P.y + P.h), 5, Color("c9c2d6"), 90)
		P.coyote = 0.1; P.air_jumps = 1; P.dash_charges = 2 if has("carrera") else 1
		if safe_ground():
			P.safe = Vector2(P.x, P.y)
	else:
		P.coyote = maxf(0.0, P.coyote - dt)
	P.was_ground = P.on_ground
	if P.atk_t > 0:
		P.atk_t -= dt
		resolve_attack()
	for tr in P.trail:
		tr["a"] -= dt * 2.2
	P.trail = P.trail.filter(func(tr): return tr["a"] > 0)
	if touching_spikes(P.rect()):
		hurt_player()
		if state == "play":
			P.x = P.safe.x; P.y = P.safe.y; P.vx = 0.0; P.vy = 0.0; P.dash_t = 0.0
			flash_a = maxf(flash_a, 0.5); flash_col = Color.BLACK
		return
	var c := P.center()
	var side := ""
	if c.x < 0:
		side = "left"
	elif c.x > room.w * T:
		side = "right"
	elif c.y < 0:
		side = "up"
	elif c.y > room.h * T:
		side = "down"
	if side != "" and not start_trans(side):
		P.x = clampf(P.x, 0, room.w * T - P.w)
		P.y = clampf(P.y, 0, room.h * T - P.h)


# --- proyectiles y recogibles ---
func circle_rect(c: Ent, rr: Rect2) -> bool:
	var n := Vector2(clampf(c.x, rr.position.x, rr.end.x), clampf(c.y, rr.position.y, rr.end.y))
	return n.distance_to(Vector2(c.x, c.y)) < c.r


func impact(q: Ent) -> void:
	q.dead = true
	if q.boom:
		for e in enemies:
			if not e.dead and e.center().distance_to(Vector2(q.x, q.y)) < 85:
				damage_enemy(e, roundi(q.dmg * 0.6), Color("ffe14d"))
		burst(Vector2(q.x, q.y), 30, DEBUG_COL, 380, 0.0, true)
		shake = maxf(shake, 6)
	else:
		burst(Vector2(q.x, q.y), 12, Color("ffe14d"), 220, 0.0, true)


func upd_projs(dt: float) -> void:
	var i := 0
	while i < projs.size():
		var q: Ent = projs[i]
		i += 1
		q.life -= dt
		if q.life <= 0:
			q.dead = true
			continue
		match q.kind:
			"spark":
				q.x += q.vx * dt
				part(q.x, q.y, randf_range(-30, 30), randf_range(-30, 30), 0.3, DEBUG_COL, 2.5, 0.0, true)
				if solid_pt(q.x, q.y):
					impact(q)
					continue
				for e in enemies:
					if not e.dead and e.state != "dying" and circle_rect(q, e.rect()):
						damage_enemy(e, roundi(q.dmg), Color("ffe14d"), false, "cast")
						if has("sobrecarga"):
							e.burn = 3.0
						impact(q)
						break
			"glob":
				q.vy += q.g * dt
				q.x += q.vx * dt
				q.y += q.vy * dt
				if solid_pt(q.x, q.y + q.r * 0.5):
					q.dead = true
					burst(Vector2(q.x, q.y), 10, Color("ff9ab0"), 180, 700)
				elif state == "play" and circle_rect(q, P.rect()):
					if hurt_player(q.x):
						q.dead = true
			"shock":
				q.x += q.vx * dt
				var tx := floori((q.x + q.w if q.vx > 0 else q.x) / T)
				if is_solid(tile_at(tx, floori((q.y + q.h / 2) / T))):
					q.dead = true
					continue
				if randf() < 0.7:
					part(q.x + q.w / 2, q.y + q.h, randf_range(-30, 30), randf_range(-220, -80), 0.4, Color("f2c14e"), 3, 0.0, true)
				if q.rect().intersects(P.rect()):
					hurt_player(q.x + q.w / 2)
			"orb":
				q.x += q.vx * dt
				q.y += q.vy * dt
				if randf() < 0.5:
					part(q.x, q.y, 0, 0, 0.3, Color("e0b84a"), 2.5, 0.0, true)
				if solid_pt(q.x, q.y):
					q.dead = true
					burst(Vector2(q.x, q.y), 8, Color("e0b84a"), 160, 0.0, true)
				elif state == "play" and circle_rect(q, P.rect()):
					if hurt_player(q.x):
						q.dead = true
			"rune":
				# Runa en el suelo: avisa 0,8 s y luego levanta una columna de luz.
				q.t -= dt
				if q.t <= 0 and q.t > -dt * 1.5:
					shake = maxf(shake, 4)
					burst(Vector2(q.x, (room.h - 2) * T), 14, Color("e0b84a"), 260, 0.0, true)
				if q.t <= 0 and P.rect().intersects(Rect2(q.x - 14, 0, 28, (room.h - 2) * T)):
					hurt_player(q.x)
			"warn":
				q.t -= dt
				if q.t <= 0:
					q.dead = true
					var gl := Ent.new()
					gl.kind = "glob"; gl.hostile = true; gl.x = q.x; gl.y = T * 1.3; gl.vy = 200; gl.g = 1600; gl.r = 9; gl.life = 3
					projs.append(gl)
			"fire":
				q.tick -= dt
				if randf() < 0.4:
					part(q.x + randf() * q.w, q.y + q.h, randf_range(-10, 10), randf_range(-90, -40), 0.4, Color("22e4ff"), 2.5, 0.0, true)
				if q.tick <= 0:
					q.tick = 0.25
					for e in enemies:
						if not e.dead and q.rect().intersects(e.rect()):
							damage_enemy(e, 5, Color("8ff0ff"))
	projs = projs.filter(func(q): return not q.dead)


func upd_pickups(dt: float) -> void:
	for k in pickups:
		k.t += dt
		if k.t < 0.45:
			k.vy += 1400 * dt
			k.x += k.vx * dt
			k.y += k.vy * dt
			if solid_pt(k.x, k.y + 4):
				k.vy *= -0.4; k.y -= 3; k.vx *= 0.7
		else:
			var d := P.center() - Vector2(k.x, k.y)
			var dist := maxf(d.length(), 1.0)
			var s := minf(950.0, 220.0 + k.t * 800.0)
			k.x += d.x / dist * s * dt
			k.y += d.y / dist * s * dt
			if dist < 16:
				k.dead = true
				meta["frags"] = int(meta["frags"]) + k.amt
				run["frags"] = int(run["frags"]) + k.amt
				frag_pulse = 0.3
				dirty = true
	pickups = pickups.filter(func(k): return not k.dead)


# --- interacción ---
## Salas que enseña el mapa. Lo descubierto se sigue guardando aparte aunque se vea todo.
func map_seen_rooms() -> Array:
	return rooms.keys() if map_reveal_all else meta["seen_rooms"]


## Tras el primer Continue (y después de la bienvenida), Nexo ofrece un aspecto normal hasta que se elija.
func look_offer_pending() -> bool:
	return int(meta["deaths"]) >= 1 and int(meta["talk"]) >= 1 and meta["look"].is_empty()


func open_look_editor() -> void:
	look_edit = {"look": Data.default_look(), "sel": 0}
	state = "look"


func new_talk() -> bool:
	if look_offer_pending():
		return true
	if meta["boss"]:
		return not meta["end_talk"]
	return (meta["wings"] and not meta["wing_talk"]) or (int(meta["talk"]) <= int(meta["deaths"]) and int(meta["talk"]) < Data.NEXO_SEQ.size())


func nexo_lines() -> Array:
	if meta["boss"]:
		meta["end_talk"] = true
		return Data.NEXO_END
	if meta["wings"] and not meta["wing_talk"]:
		meta["wing_talk"] = true
		return Data.NEXO_WINGS
	var talk := int(meta["talk"])
	if talk <= int(meta["deaths"]) and talk < Data.NEXO_SEQ.size():
		meta["talk"] = talk + 1
		return Data.NEXO_SEQ[talk]
	return [Data.NEXO_IDLE.pick_random()]


## Kira solo aparece al principio, en la Pantalla de Inicio (`n` = 1): la primera vez se presenta y explica
## los portales; después repite frases cortas.
func kira_lines(n: int) -> Array:
	if new_kira_talk(n):
		meta["kira_talk"] = n
		return Data.KIRA_SEQ[n - 1]
	return [Data.KIRA_IDLE.pick_random()]


func new_kira_talk(n: int) -> bool:
	return int(meta["kira_talk"]) == n - 1 and n - 1 < Data.KIRA_SEQ.size()


## Los portales no dependen de Kira: el del trozo `n` está abierto mientras el anterior esté terminado y
## este no. Lo que cuesta es encontrarlos (están detrás de muros falsos).
func portal_open(n: int) -> bool:
	return int(meta["kira_frags"]) == n - 1


## Tocar la bandera de un trozo de Kira lo da por terminado (con los seis se desbloquea el final oculto) y
## devuelve a la sala del portal. Kira no está: solo aparece al principio y al final.
func complete_kira_fragment() -> void:
	var n := int(meta["kira_frags"])
	meta["kira_frags"] = n + 1
	save()
	var info: Dictionary = Data.KIRA_FRAG_INFO[mini(n, Data.KIRA_FRAG_INFO.size() - 1)]
	flash_a = 0.7; flash_col = KIRA_COL
	burst(P.center(), 60, KIRA_COL, 420, 0.0, true)
	banner = {"text": info["name"], "sub": info["sub"], "t": 0.0}
	var back: Array = info["back"]
	state = "trans"
	trans = {"t": 0.0, "to": back[0], "entry": back[1], "loaded": false, "carry": Vector2.ZERO}


func open_dialog(speaker: String, col: Color, lines: Array, on_end := Callable()) -> void:
	dialog = {"speaker": speaker, "col": col, "lines": lines, "i": 0, "t": 0.0, "on_end": on_end}
	state = "dialog"


func near_prop():
	var cx := P.center().x
	var fy := P.y + P.h
	for o in props:
		if o["type"] == "A":
			continue
		if absf(o["x"] - cx) < 36 and absf(o["y"] - fy) < 44:
			return o
	return null


func prompt_for(o: Dictionary) -> String:
	match o["type"]:
		"O": return "Hablar con Nexo"
		"K": return "Hablar con Kira"
		"T":
			var n := int(o["text"])
			if portal_open(n):
				return "Entrar en: " + Data.KIRA_FRAG_INFO[n - 1]["name"]
		"L": return "Leer el registro"
		"h": return "Beber de la fuente"
		"M": return "Entregar fragmentos al anillo"
		"H": return "Mirar el marcador"
		"F":
			var rf = run["rifts"].get(room.id)
			if rf and not rf["taken"]:
				return "Asomarse a la grieta de " + Data.HEROES[rf["hero"]]["name"]
	return ""


func interact(o: Dictionary) -> void:
	match o["type"]:
		"O":
			if look_offer_pending():
				open_dialog("Nexo, Guardián del Umbral", Color("6ff3ff"), Data.NEXO_LOOK, open_look_editor)
				return
			var l := nexo_lines()
			save()
			open_dialog("Nexo, Guardián del Umbral", Color("6ff3ff"), l)
		"K":
			open_dialog("Kira Volt", KIRA_COL, kira_lines(int(o["text"])))
			save()
		"T":
			var n := int(o["text"])
			if portal_open(n):
				state = "trans"
				trans = {"t": 0.0, "to": Data.KIRA_FRAG_INFO[n - 1]["room"], "entry": "1", "loaded": false, "carry": Vector2.ZERO}
		"L":
			open_dialog("Registro de Zerik", Color("f2c14e"), [o["text"]])
		"h":
			# La fuente cura por completo, una vez por intento.
			props.erase(o)
			run["fountains"][room.id] = true
			P.hp = max_hp()
			P.debug = DEBUG_MAX
			flash_a = 0.5; flash_col = Color("6ff3ff")
			burst(Vector2(o["x"], o["y"] - 20), 40, Color("6ff3ff"), 300, 0.0, true)
			banner = {"text": "Vida y depuración al máximo", "sub": "La fuente se seca hasta el próximo intento", "t": 0.0}
		"H":
			open_dialog("Marcador del Reino", Color("ffe14d"), ["GAME CLEAR. El marcador ya no cuenta hacia atrás." if meta["boss"] else "CONTINUE? 9... 8... 7... La cuenta atrás nunca llega a cero. Siempre vuelve a empezar."])
		"M":
			shop = {"sel": 0, "msg": "", "msg_t": 0.0}
			state = "shop"
		"F":
			var rf = run["rifts"].get(room.id)
			if rf == null or rf["taken"]:
				return
			var opts: Array = Data.BOONS.filter(func(b): return b["hero"] == rf["hero"] and not has(b["id"]))
			if opts.is_empty():
				rf["taken"] = true
				return
			choice = {"hero": rf["hero"], "opts": opts.slice(0, 3), "sel": 0, "t": 0.0}
			state = "choice"


func pick_boon(b: Dictionary) -> void:
	run["boons"].append(b["id"])
	if b["id"] == "sinprincipio":
		run["extra_hp"] = int(run["extra_hp"]) + 2
		P.hp = max_hp()
	run["rifts"][room.id]["taken"] = true
	state = "play"
	var col: Color = Data.HEROES[choice["hero"]]["color"]
	flash_a = 0.35; flash_col = col
	burst(P.center(), 40, col, 380, 0.0, true)
	banner = {"text": b["name"], "sub": "Poder de " + Data.HEROES[choice["hero"]]["name"], "t": 0.0}
	choice = {}


func upgrade_cost(u: Dictionary) -> int:
	return int(u["base"]) + int(u["step"]) * int(meta["up"][u["id"]])


func buy(u: Dictionary) -> void:
	var lvl := int(meta["up"][u["id"]])
	if lvl >= int(u["max"]):
		shop["msg"] = "Ya está al máximo."; shop["msg_t"] = 1.5
		return
	var c := upgrade_cost(u)
	if int(meta["frags"]) < c:
		shop["msg"] = "Te faltan fragmentos: necesitas %d." % c; shop["msg_t"] = 1.5
		return
	meta["frags"] = int(meta["frags"]) - c
	meta["up"][u["id"]] = lvl + 1
	save()
	match u["id"]:
		"corazon": P.hp += 1
		"continue": run["revive"] = int(run["revive"]) + 1
		"precarga": P.debug = DEBUG_MAX
	shop["msg"] = u["name"] + ": hecho."; shop["msg_t"] = 1.5
	flash_a = 0.3; flash_col = Color("6ff3ff")


# --- bucle principal ---
func update(dt: float) -> void:
	time += dt
	for q in parts:
		q["life"] -= dt
		q["vy"] += q["g"] * dt
		q["x"] += q["vx"] * dt
		q["y"] += q["vy"] * dt
	parts = parts.filter(func(q): return q["life"] > 0)
	for n in nums:
		n["t"] += dt
	nums = nums.filter(func(n): return n["t"] < 0.9)
	for s in slashes:
		s["t"] += dt
	slashes = slashes.filter(func(s): return s["t"] < 0.14)
	if not banner.is_empty():
		banner["t"] += dt
		if banner["t"] > 3.2:
			banner = {}
	flash_a = maxf(0.0, flash_a - dt * 2.2)
	shake = maxf(0.0, shake - dt * 40)
	frag_pulse = maxf(0.0, frag_pulse - dt)
	revive_fx = maxf(0.0, revive_fx - dt)
	erase_arm = maxf(0.0, erase_arm - dt)
	save_timer += dt
	if dirty and save_timer > 2:
		save(); dirty = false; save_timer = 0.0

	match state:
		"title":
			if hit("confirm") or hit("jump"):
				state = "play"
				if not meta["seen_intro"]:
					open_dialog("", Color("6ff3ff"), Data.INTRO, func(): meta["seen_intro"] = true; save())
			elif hit("pause"):
				quit_requested = true
			return
		"trans":
			trans["t"] += dt
			if not trans["loaded"] and trans["t"] >= 0.18:
				load_room(trans["to"], trans["entry"], trans["carry"])
				trans["loaded"] = true
			if trans["t"] >= 0.36:
				state = "play"; trans = {}
			return
		"dialog":
			dialog["t"] += dt
			var line: String = dialog["lines"][dialog["i"]]
			if hit("confirm") or hit("interact") or hit("jump") or hit("attack"):
				if dialog["t"] * 55 < line.length():
					dialog["t"] = line.length() / 55.0 + 0.01
				else:
					dialog["i"] += 1
					dialog["t"] = 0.0
					if dialog["i"] >= dialog["lines"].size():
						var cb: Callable = dialog["on_end"]
						dialog = {}
						state = "play"
						if cb.is_valid():
							cb.call()
			return
		"choice":
			choice["t"] += dt
			var n: int = choice["opts"].size()
			if hit("left"):
				choice["sel"] = (choice["sel"] + n - 1) % n
			if hit("right"):
				choice["sel"] = (choice["sel"] + 1) % n
			if choice["t"] > 0.35:
				for k in 3:
					if hit("c%d" % (k + 1)) and k < n:
						pick_boon(choice["opts"][k])
						return
				if hit("confirm") or hit("interact") or hit("attack"):
					pick_boon(choice["opts"][choice["sel"]])
			return
		"map":
			if hit("map") or hit("pause") or hit("dash"):
				state = "play"
				return
			var dir := Vector2(int(keys.get("right", false)) - int(keys.get("left", false)), int(keys.get("down", false)) - int(keys.get("up", false)))
			var b: Rect2 = Data.MAP_BOUNDS
			map_pan = (map_pan + dir * MAP_PAN_SPEED * dt).clamp(b.position, b.end)
			return
		"look":
			var rows: int = Data.LOOK_OPTIONS.size() + 1
			if hit("up"):
				look_edit["sel"] = (look_edit["sel"] + rows - 1) % rows
			if hit("down"):
				look_edit["sel"] = (look_edit["sel"] + 1) % rows
			if look_edit["sel"] == rows - 1:
				if hit("confirm") or hit("interact") or hit("attack"):
					meta["look"] = look_edit["look"]
					look_edit = {}
					state = "play"; flash_a = 0.6; flash_col = Color("6ff3ff")
					save()
				return
			var option: Dictionary = Data.LOOK_OPTIONS[look_edit["sel"]]
			var count: int = option["opts"].size()
			var step_dir := int(hit("right")) - int(hit("left"))
			look_edit["look"][option["id"]] = (int(look_edit["look"][option["id"]]) + step_dir + count) % count
			return
		"shop":
			shop["msg_t"] = maxf(0.0, shop["msg_t"] - dt)
			var n := Data.UPGRADES.size()
			if hit("up"):
				shop["sel"] = (shop["sel"] + n - 1) % n
			if hit("down"):
				shop["sel"] = (shop["sel"] + 1) % n
			if hit("confirm") or hit("interact") or hit("attack"):
				buy(Data.UPGRADES[shop["sel"]])
			if hit("pause") or hit("dash"):
				state = "play"; shop = {}; save()
			return
		"pause":
			if hit("erase"):
				if erase_arm > 0:
					meta = SaveData.defaults(); save()
					rooms = Data.build_rooms(); room = null
					new_run(); load_room("umbral", "P")
					state = "title"; erase_arm = 0.0
					return
				erase_arm = 2.5
			if hit("quit"):
				quit_requested = true
			if hit("pause") or hit("confirm"):
				state = "play"
			return
		"dead":
			dead_t += dt
			if dead_t > 1.6 and (hit("confirm") or hit("jump") or hit("attack") or dead_t > 5):
				new_run(); load_room("umbral", "P")
				state = "play"; P.inv = 1.0; flash_a = 0.6; flash_col = Color("6ff3ff")
			return
		"end":
			end_t += dt
			if end_t > 2 and (hit("confirm") or hit("jump")):
				P.hp = max_hp()
				state = "play"
				if end_world == 1:
					# Tras el Rey se sigue: la puerta del trono ya lleva a la Academia.
					banner = {"text": "La puerta se abre", "sub": "Al otro lado, la Academia del Último Hechizo", "t": 0.0}
				else:
					load_room("umbral", "P")
			return

	# --- jugando ---
	if hit("pause"):
		state = "pause"
		return
	if hit("map"):
		# El mapa se abre centrado en Álex.
		map_pan = Data.MAP_BOUNDS.get_center()
		if Data.MAP_ROOMS.has(room.id):
			map_pan = Vector2(Data.MAP_ROOMS[room.id]) + P.center() / T
		state = "map"
		return
	if hitstop > 0:
		hitstop -= dt
		return
	update_player(dt)
	if state != "play":
		return
	var i := 0
	while i < enemies.size():
		var e: Ent = enemies[i]
		i += 1
		if e.kind == "B":
			upd_boss(e, dt)
		elif e.kind == "E":
			upd_student(e, dt)
		elif e.kind != "dummy":
			upd_enemy(e, dt)
		if state != "play":
			return
		var harmless := e.kind in ["core", "dummy"] or (e.kind in ["B", "E"] and e.state in ["sleep", "dying", "blink_out"])
		if not e.dead and not harmless:
			if P.rect().intersects(e.rect()):
				hurt_player(e.center().x)
			if e.kind == "B" and e.state == "sweep" and P.rect().intersects(lantern_box(e)):
				hurt_player(e.center().x)
	enemies = enemies.filter(func(e): return not e.dead)
	upd_arena(dt)
	upd_projs(dt)
	upd_pickups(dt)
	for o in props:
		if o["type"] == "g" and absf(o["x"] - P.center().x) < 22 and absf(o["y"] - 12 - P.center().y) < 30:
			# Fragmentos escondidos: 8 de golpe, una vez por intento.
			props.erase(o)
			run["gems"][o["text"]] = true
			burst(Vector2(o["x"], o["y"] - 12), 24, Color("6ff3ff"), 260, 0.0, true)
			num(o["x"], o["y"] - 30, "+8 fragmentos", Color("6ff3ff"), true)
			meta["frags"] = int(meta["frags"]) + 8
			run["frags"] = int(run["frags"]) + 8
			frag_pulse = 0.3
			dirty = true
			break
	for o in props:
		if o["type"] == "A" and absf(o["x"] - P.center().x) < 26 and absf(o["y"] - 30 - P.center().y) < 40:
			props.erase(o)
			meta["wings"] = true
			save()
			flash_a = 0.6; flash_col = Color("ffe14d")
			burst(Vector2(o["x"], o["y"] - 30), 50, Color("ffe14d"), 360, 0.0, true)
			open_dialog("Orbe de Salto Doble", Color("ffe14d"), ["El orbe se rompe y su chispa se queda en las botas del avatar de Álex.",
				"Pulsa SALTAR en el aire para dar un segundo salto. Este poder no se pierde con el Continue."])
			return
		if o["type"] == "W" and absf(o["x"] - P.center().x) < 26 and absf(o["y"] - 30 - P.center().y) < 40:
			props.erase(o)
			meta["walljump"] = true
			save()
			flash_a = 0.6; flash_col = Color("7be36b")
			burst(Vector2(o["x"], o["y"] - 30), 50, Color("7be36b"), 360, 0.0, true)
			open_dialog("Orbe de Salto en Pared", Color("7be36b"), ["Era un apunte de clase: «el personaje debería poder agarrarse a las paredes». Nunca lo programaste.",
				"Empuja hacia una pared en el aire para deslizarte, y salta para rebotar. Este poder no se pierde con el Continue."])
			return
	for o in props:
		if o["type"] == "G" and absf(o["x"] - P.center().x) < 22 and P.y + P.h > o["y"] - 70:
			props.erase(o)
			complete_kira_fragment()
			return
	var np = near_prop()
	if np != null and prompt_for(np) != "" and (hit("interact") or hit("up")):
		interact(np)
	var t := cam_target()
	cam += (t - cam) * minf(1.0, dt * 6)
