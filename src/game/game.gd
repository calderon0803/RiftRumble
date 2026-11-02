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

	func rect() -> Rect2:
		return Rect2(x, y, w, h)

	func center() -> Vector2:
		return Vector2(x + w / 2.0, y + h / 2.0)


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
var trans := {}
var dead_t := 0.0
var end_t := 0.0
var erase_arm := 0.0
var frag_pulse := 0.0
var save_timer := 0.0
var dirty := false
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
	var heroes := ["aeron", "zerik", "voltra", "raiko"]
	heroes.shuffle()
	var rifts := {}
	for i in Data.RIFT_ROOMS.size():
		rifts[Data.RIFT_ROOMS[i]] = {"hero": heroes[i], "taken": false}
	run = {"boons": [], "extra_hp": 0, "revive": int(meta["up"]["continue"]), "frags": 0, "rifts": rifts}
	P.hp = max_hp()
	P.debug = DEBUG_MAX if int(meta["up"]["precarga"]) > 0 else 0
	P.inv = 0.0
	P.crit_next = false


# --- casillas ---
func tile_at(tx: int, ty: int) -> String:
	if room == null or ty < 0 or ty >= room.h or tx < 0 or tx >= room.w:
		return "."
	return room.g[ty][tx]


func solid_pt(px: float, py: float) -> bool:
	return tile_at(floori(px / T), floori(py / T)) == "#"


func is_floor(tx: int, ty: int) -> bool:
	var c := tile_at(tx, ty)
	return c == "#" or c == "="


func set_arena(locked: bool) -> void:
	var r: Data.RoomDef = rooms["trono"]
	for y in range(13, 16):
		r.g[y][0] = "#" if locked else "."


func move_x(e, dx: float) -> bool:
	e.x += dx
	var y0 := floori(e.y / T)
	var y1 := floori((e.y + e.h - 0.01) / T)
	if dx > 0:
		var tx := floori((e.x + e.w) / T)
		for ty in range(y0, y1 + 1):
			if tile_at(tx, ty) == "#":
				e.x = tx * T - e.w
				e.vx = 0.0
				return true
	elif dx < 0:
		var tx := floori(e.x / T)
		for ty in range(y0, y1 + 1):
			if tile_at(tx, ty) == "#":
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
			if c == "#" or (c == "=" and e.drop_t <= 0.0 and prev_bot <= ty * T + 0.5):
				e.y = ty * T - e.h
				e.vy = 0.0
				e.on_ground = true
				return true
	elif dy < 0:
		var ty := floori(e.y / T)
		for tx in range(x0, x1 + 1):
			if tile_at(tx, ty) == "#":
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


func standing_on_one_way() -> bool:
	var ty := floori((P.y + P.h + 1) / T)
	var one := false
	for tx in range(floori(P.x / T), floori((P.x + P.w - 0.01) / T) + 1):
		var c := tile_at(tx, ty)
		if c == "#":
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
	if id == "trono":
		set_arena(false)
	if id == "kira1":
		# Los bloques colocados no se guardan: cada visita el nivel vuelve a estar a medias.
		rooms[id] = Data.build_rooms()[id]
	room = rooms[id]
	enemies.clear(); projs.clear(); pickups.clear(); slashes.clear(); props.clear()
	boss = null
	for o in room.objs:
		var px: float = o["tx"] * T + 16
		var py: float = (o["ty"] + 1) * T
		match o["type"]:
			"c", "f", "s":
				enemies.append(mk_enemy(o["type"], px, py))
			"B":
				if not meta["boss"]:
					boss = mk_boss(px, py)
					enemies.append(boss)
			"A":
				if not meta["wings"]:
					props.append({"type": "A", "x": px, "y": py, "text": ""})
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


func start_trans(side: String) -> bool:
	if not room.exits.has(side):
		return false
	var ex: Array = room.exits[side]
	state = "trans"
	trans = {"t": 0.0, "to": ex[0], "entry": ex[1], "loaded": false,
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
func mk_enemy(kind: String, px: float, py: float) -> Ent:
	var d: Array = {"c": [26, 22, 30, 3], "f": [24, 20, 22, 2], "s": [30, 30, 45, 5]}[kind]
	var e := Ent.new()
	e.kind = kind
	e.w = d[0]; e.h = d[1]; e.hp = d[2]; e.max_hp = d[2]; e.frags = d[3]
	e.x = px - e.w / 2; e.y = py - e.h
	e.face = -1 if randf() < 0.5 else 1
	e.t = randf() * 3.0
	e.cd = 1.0 + randf()
	return e


func mk_boss(px: float, py: float) -> Ent:
	var b := Ent.new()
	b.kind = "B"
	b.w = 56; b.h = 96; b.hp = 500; b.max_hp = 500
	b.x = px - 28; b.y = py - 96
	b.face = -1
	b.state = "sleep"
	return b


func common_enemy(e: Ent, dt: float) -> void:
	if e.kind != "B" and e.kind != "core":
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
			var vx := e.face * 55.0 + e.kb
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
					var q := Ent.new()
					q.kind = "glob"; q.hostile = true; q.x = ec.x; q.y = e.y + 6
					q.vx = clampf(dx / tt, -520, 520); q.vy = (dy - 0.5 * 1200 * tt * tt) / tt
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


func lantern_box(b: Ent) -> Rect2:
	return Rect2(b.x + b.w - 4 if b.face > 0 else b.x - 44, b.y + 30, 48, 44)


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
				set_arena(true)
				shake = 12
				banner = {"text": "El Rey del Reinicio", "sub": "Señor del Reino del Continue", "t": 0.0}
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
				boss_defeated()
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


func damage_enemy(e: Ent, d: int, col := Color("fff3c4"), crit := false) -> void:
	if e.dead or e.state == "dying" or (e.kind == "B" and e.state == "sleep"):
		return
	e.hp -= d
	e.flash = 0.09
	num(e.center().x + randf_range(-8, 8), e.y - 6, str(d), Color("ff5a7a") if crit else col, crit)
	if e.hp <= 0:
		kill_enemy(e)


func kill_enemy(e: Ent) -> void:
	if e.kind == "B":
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


func boss_defeated() -> void:
	meta["boss"] = true
	meta["frags"] = int(meta["frags"]) + 60
	save()
	set_arena(false)
	boss = null
	flash_a = 1.0; flash_col = Color("fff4d0")
	state = "end"; end_t = 0.0


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
			banner = {"text": "Continue Extra", "sub": "El Reino te da otra moneda", "t": 0.0}
			flash_col = Color("f2c14e"); flash_a = 0.6
		else:
			die()
	return true


func die() -> void:
	state = "dead"
	dead_t = 0.0
	meta["deaths"] = int(meta["deaths"]) + 1
	save()
	burst(P.center(), 60, DEBUG_COL, 420, 700)
	burst(Vector2(P.center().x, P.y), 20, Color("ffe14d"), 200, 0.0, true)


func atk_box() -> Rect2:
	var cx := P.center().x
	match P.atk_dir:
		"up":
			return Rect2(cx - 26, P.y - 50, 52, 52)
		"down":
			return Rect2(cx - 26, P.y + P.h - 6, 52, 52)
	return Rect2(P.x + P.w - 2 if P.face > 0 else P.x - 50, P.y - 10, 52, 46)


func resolve_attack() -> void:
	var b := atk_box()
	var pogo := false
	for e in enemies:
		if e.dead or P.atk_hits.has(e) or e.state == "dying":
			continue
		if b.intersects(e.rect()):
			P.atk_hits[e] = true
			hit_enemy_melee(e, b)
			if P.atk_dir == "down":
				pogo = true
	# El tajo corta los proyectiles del escupidor.
	for q in projs:
		if q.kind == "glob" and not q.dead and b.has_point(Vector2(q.x, q.y)):
			q.dead = true
			burst(Vector2(q.x, q.y), 8, Color("ff9ab0"), 180)
	if P.atk_dir == "down" and not pogo and touching_spikes(b):
		pogo = true
	place_blocks(b)
	if pogo and not P.pogo_done:
		P.pogo_done = true
		P.vy = -POGO
		P.air_jumps = 1
		if has("disciplina"):
			P.dash_charges = 2 if has("carrera") else 1


## Un clic sobre un bloque sin colocar ("p") lo coloca: pasa a ser una plataforma que se pisa.
func place_blocks(b: Rect2) -> void:
	for ty in range(floori(b.position.y / T), floori(b.end.y / T) + 1):
		for tx in range(floori(b.position.x / T), floori(b.end.x / T) + 1):
			if tile_at(tx, ty) == "p" and b.intersects(Rect2(tx * T, ty * T, T, T)):
				room.g[ty][tx] = "="
				burst(Vector2(tx * T + 16, ty * T + 6), 8, Color("ff6fd8"), 160, 0.0, true)
				num(tx * T + 16, ty * T - 4, "Colocado", Color("ff6fd8"))


func hit_enemy_melee(e: Ent, b: Rect2) -> void:
	var d := 10.0 + 4 * int(meta["up"]["dano"])
	if P.combo == 2:
		d *= 1.5
	if has("espadon"):
		d *= 1.3
	if P.atk_dir == "down" and has("disciplina"):
		d *= 2
	var crit := false
	if P.crit_next:
		d *= 3; P.crit_next = false; crit = true
	elif has("diagnostico") and randf() < 0.2:
		d *= 2.5; crit = true
	damage_enemy(e, roundi(d), Color("fff3c4"), crit)
	if has("sobrecarga"):
		e.burn = 3.0
	if e.kind != "B" and e.kind != "core":
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
	var ix := (1 if held("right") else 0) - (1 if held("left") else 0)
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
		P.vx = move_toward(P.vx, ix * sp, (2600.0 if P.on_ground else 1800.0) * dt)
		if ix != 0 and not healing:
			P.face = ix
		var g := GRAV
		if P.vy < 0 and not held("jump"):
			g *= 2.2
		P.vy = minf(P.vy + g * dt, MAXFALL)
	if P.jump_buf > 0 and not healing:
		if held("down") and P.on_ground and standing_on_one_way():
			P.drop_t = 0.22; P.jump_buf = 0.0; P.on_ground = false
		elif P.coyote > 0:
			P.vy = -JUMP; P.coyote = 0.0; P.jump_buf = 0.0; P.on_ground = false; P.dash_t = 0.0
			burst(Vector2(P.center().x, P.y + P.h), 6, Color("c9c2d6"), 120)
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
						damage_enemy(e, roundi(q.dmg), Color("ffe14d"))
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
				if tile_at(tx, floori((q.y + q.h / 2) / T)) == "#":
					q.dead = true
					continue
				if randf() < 0.7:
					part(q.x + q.w / 2, q.y + q.h, randf_range(-30, 30), randf_range(-220, -80), 0.4, Color("f2c14e"), 3, 0.0, true)
				if q.rect().intersects(P.rect()):
					hurt_player(q.x + q.w / 2)
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
func new_talk() -> bool:
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


## Kira solo aparece en momentos puntuales: primero se presenta y luego repite frases cortas.
func kira_lines() -> Array:
	var talk := int(meta["kira_talk"])
	if talk < Data.KIRA_SEQ.size():
		meta["kira_talk"] = talk + 1
		return Data.KIRA_SEQ[talk]
	return [Data.KIRA_IDLE.pick_random()]


func new_kira_talk() -> bool:
	return int(meta["kira_talk"]) < Data.KIRA_SEQ.size()


## El nivel de Kira se abre cuando ella se ha presentado, y se cierra al terminarlo.
func portal_open() -> bool:
	return int(meta["kira_talk"]) >= 1 and int(meta["kira_frags"]) < 1


## Tocar la bandera del nivel de Kira enciende una muesca de su espada.
func complete_kira_fragment() -> void:
	var n := int(meta["kira_frags"])
	meta["kira_frags"] = n + 1
	save()
	flash_a = 0.7; flash_col = Color("ff6fd8")
	burst(P.center(), 60, Color("ff6fd8"), 420, 0.0, true)
	banner = {"text": "Nivel 1-1 de Kira", "sub": "Primera muesca encendida", "t": 0.0}
	open_dialog("Kira Volt", Color("ff6fd8"), Data.KIRA_FRAG[mini(n, Data.KIRA_FRAG.size() - 1)],
		func(): state = "trans"; trans = {"t": 0.0, "to": "inicio", "entry": "K", "loaded": false, "carry": Vector2.ZERO})


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
			if portal_open():
				return "Entrar en el Nivel 1-1 de Kira"
		"L": return "Leer el registro"
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
			var l := nexo_lines()
			save()
			open_dialog("Nexo, Guardián del Umbral", Color("6ff3ff"), l)
		"K":
			open_dialog("Kira Volt", Color("ff6fd8"), kira_lines())
			save()
		"T":
			if portal_open():
				state = "trans"
				trans = {"t": 0.0, "to": "kira1", "entry": "1", "loaded": false, "carry": Vector2.ZERO}
		"L":
			open_dialog("Registro de Zerik", Color("f2c14e"), [o["text"]])
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
				load_room("umbral", "P")
				P.hp = max_hp()
				state = "play"
			return

	# --- jugando ---
	if hit("pause"):
		state = "pause"
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
		else:
			upd_enemy(e, dt)
		if state != "play":
			return
		if not e.dead and e.kind != "core" and not (e.kind == "B" and (e.state == "sleep" or e.state == "dying")):
			if P.rect().intersects(e.rect()):
				hurt_player(e.center().x)
			if e.kind == "B" and e.state == "sweep" and P.rect().intersects(lantern_box(e)):
				hurt_player(e.center().x)
	enemies = enemies.filter(func(e): return not e.dead)
	upd_projs(dt)
	upd_pickups(dt)
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
