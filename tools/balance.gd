## Juega misiones con estrategias genéricas y resume cada oleada.
## Uso: godot --headless --path . --script res://tools/balance.gd -- [w1_m1 w1_m3 …]
## Sin argumentos juega todas las misiones del mundo 1.
##
## Ritmo: la primera oleada se lanza al empezar; las demás empiezan solas tras la
## cuenta atrás. Los héroes se quedan en su posición inicial (un jugador real los
## movería y usaría sus habilidades: estos resultados son un mínimo).
extends SceneTree

const SimWorld := preload("res://src/sim/sim_world.gd")
const ContentDB := preload("res://src/content/content_db.gd")
const SaveService := preload("res://src/services/save_service.gd")

const STRATEGIES := ["sin torres", "una torre", "equipo inicial sin mejorar", "equipo inicial + mejoras"]


func _init() -> void:
	var db = ContentDB.load_all()
	var ids := OS.get_cmdline_user_args()
	if ids.is_empty():
		ids = PackedStringArray(["w1_m1", "w1_m2", "w1_m3", "w1_m4", "w1_m5"])
	for id in ids:
		print("\n######## %s · %s" % [id, db.missions[StringName(id)].display_name])
		for strat in STRATEGIES:
			var r := play(db, StringName(id), strat)
			print("== %-28s → %s, %d★ (%.0f s) · fugas %d · KOs héroes %d" % [strat,
				SimWorld.Outcome.keys()[r.world.outcome], r.world.stars(), r.world.tick / 30.0,
				r.world.stats.leaks, r.world.stats.hero_kos])
			for line in r.log:
				print("     " + line)
	quit()


## Todas las asignaciones de torres del equipo a las posiciones (permutaciones
## del equipo, repetidas cíclicamente si hay más posiciones que torres).
static func orders(team_size: int) -> Array:
	var out := []
	_permute(range(team_size), 0, out)
	return out


static func _permute(arr: Array, k: int, out: Array) -> void:
	if k == arr.size():
		out.append(arr.duplicate())
		return
	for i in range(k, arr.size()):
		var tmp = arr[k]; arr[k] = arr[i]; arr[i] = tmp
		_permute(arr, k + 1, out)
		tmp = arr[k]; arr[k] = arr[i]; arr[i] = tmp


## Juega una misión con una estrategia genérica (también la usan los tests).
## `order`: torre del equipo para cada posición (índices); vacío = rotación simple.
## `hero_ids`: equipo de héroes (por defecto, los iniciales). Con `use_abilities`
## cada héroe lanza su habilidad al llenarse el medidor sobre el grupo más denso a
## su alcance (`tools/hero_check.gd`). El resultado incluye, por héroe, los usos y
## los segundos que tardó en llenar el medidor cada vez.
static func play(db, mission_id: StringName, strategy: String, order: Array = [],
		hero_ids := PackedStringArray(), use_abilities := false) -> Dictionary:
	var mission: MissionDef = db.missions[mission_id]
	var map: Node = load(mission.map_scene).instantiate()
	var map_def = map.build_def()
	map.free()
	# Equipo: torres iniciales permitidas por la misión.
	var team := PackedStringArray()
	for t in SaveService.STARTER_TOWERS:
		if mission.towers.is_empty() or t in mission.towers:
			team.append(t)
	var heroes := hero_ids
	if heroes.is_empty():
		for h in SaveService.STARTER_HEROES:
			if heroes.size() < mission.heroes.size():
				heroes.append(h)
	var w := SimWorld.new(map_def.routes, 99)
	w.setup_mission(db, mission, map_def, heroes, team)
	var casts := []
	var fill_secs := []
	var empty_since := []
	for h in heroes:
		casts.append(0)
		fill_secs.append([])
		empty_since.append(0)
	var log := []
	var leaks := 0
	var kills := 0
	w.start_next_wave()
	for i in 30 * 60 * 15:
		if strategy != "sin torres":
			var spots: int = 1 if strategy == "una torre" else w.build_spots.size()
			for s in spots:
				if w.tower_at(s).is_empty():
					var ti: int = order[s % order.size()] if not order.is_empty() else s
					w.build(s, StringName(team[ti % team.size()]))
			if strategy.ends_with("+ mejoras") and not w.wave_active:
				for s in spots:
					w.upgrade(s)
		if use_abilities:
			for hi in w.heroes.heroes.size():
				if _auto_cast(w, hi) == &"ok":
					casts[hi] += 1
					empty_since[hi] = w.tick
		w.step()
		for ev in w.drain_events():
			match ev.type:
				&"hero_ability_ready":
					fill_secs[ev.hero].append((w.tick - empty_since[ev.hero]) / float(SimWorld.TICK_RATE))
				&"enemy_leaked": leaks += 1
				&"enemy_killed": kills += 1
				&"wave_cleared", &"defeat":
					log.append("O%d: bajas %d, fugas %d, base %d, oro %d" % [
						w.wave_index + 1, kills, leaks, w.base_hp, w.gold])
					leaks = 0
					kills = 0
		if w.is_over():
			break
	return {world = w, log = log, casts = casts, fill_secs = fill_secs}


## Lanza la habilidad si está lista y hay al menos 2 enemigos donde caería.
static func _auto_cast(w: SimWorld, hi: int) -> StringName:
	var h: Dictionary = w.heroes.heroes[hi]
	if h.meter < 100.0 or h.dead_ticks > 0 or w.enemy_count == 0:
		return &"not_ready"
	var def: HeroDef = h.def
	if def.ability_kind == HeroDef.ABILITY_BURST_SELF:
		return w.cast_ability(hi, h.pos) if _count_near(w, h.pos, def.ability_radius) >= 2 else &"wait"
	# Grupo más denso dentro del alcance de la habilidad.
	var best := -1
	var best_n := 0
	for i in w.e_alive.size():
		if w.e_alive[i] == 1 and w.e_pos[i].distance_to(h.pos) <= def.ability_range:
			var n := _count_near(w, w.e_pos[i], 1.5)
			if n > best_n:
				best_n = n
				best = i
	if best < 0 or best_n < 2:
		return &"wait"
	return w.cast_ability(hi, w.e_pos[best])


static func _count_near(w: SimWorld, pos: Vector2, radius: float) -> int:
	var n := 0
	for i in w.e_alive.size():
		if w.e_alive[i] == 1 and w.e_pos[i].distance_to(pos) <= radius:
			n += 1
	return n
