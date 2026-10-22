## Simula jugadores que recorren la campaña con las reglas de economía
## (src/content/economy_rules.gd) y resume, por mundo, hilos, tiradas, héroes
## distintos, niveles del equipo y dinero gastado en el taller.
## Uso: godot --headless --path . --script res://tools/economy.gd -- [jugadores=2000] [repeticiones_por_mundo=5]
##
## Modelo de jugador (deliberadamente sencillo):
## - por mundo: 5 misiones; la primera victoria con 2★, una repetición para la 3.ª
##   estrella, 1 derrota y N repeticiones extra con 3★ («farmeo»);
## - equipo: los 2 héroes coleccionables de rareza más alta (a igualdad, más nivel);
##   sin coleccionables, juega con Nexo y Kira (nivel de historia);
## - tras cada partida asciende al equipo si está en el tope de nivel (fragmentos
##   de repetidos y, si faltan, del taller) y gasta el resto en tiradas (×10 si llega).
extends SceneTree

const Eco := preload("res://src/content/economy_rules.gd")
const MINUTES_PER_PLAY := 4.5
const RARITY_NAMES := ["común", "poco común", "rara", "épica", "legendaria", "mítica", "trascendente"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var players := int(args[0]) if args.size() > 0 else 2000
	var farm := int(args[1]) if args.size() > 1 else 5
	var rows := []
	for w in 7:
		rows.append({threads = 0.0, pulls = 0.0, distinct = 0.0, level = 0.0, category = 0.0,
			on_level = 0.0, workshop = 0.0, minutes = 0.0, top_rarity = PackedFloat64Array([0, 0, 0, 0, 0, 0, 0])})
	for i in players:
		_play_campaign(i, farm, rows)
	print("Economía · %d jugadores · %d repeticiones extra por mundo\n" % [players, farm])
	print("Mundo | horas | hilos ganados | tiradas | héroes | nivel equipo (esperado) | cat. | equipo al nivel | hilos en taller")
	for w in range(1, 7):
		var r: Dictionary = rows[w]
		var n := float(players)
		print("  %d   | %4.1f  | %13.0f | %7.1f | %6.1f | %5.1f (%2d)              | %4.1f | %14.0f %% | %15.0f" % [w,
			r.minutes / n / 60.0, r.threads / n, r.pulls / n, r.distinct / n, r.level / n, Eco.EXPECTED_LEVEL[w + 1],
			r.category / n, 100.0 * r.on_level / n, r.workshop / n])
	print("\nRareza máxima del equipo al acabar la campaña:")
	var top: PackedFloat64Array = rows[6].top_rarity
	for r in top.size():
		if top[r] > 0:
			print("  %-13s %5.1f %%" % [RARITY_NAMES[r], 100.0 * top[r] / players])
	quit()


func _play_campaign(seed_i: int, farm: int, rows: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + seed_i
	var p := {threads = 0, pulls = 0, pity = Eco.new_pity(), heroes = {}, workshop = 0, minutes = 0.0, earned = 0}
	for w in range(1, 7):
		for m in 5:
			var boss := m == 4
			_after_play(p, w, Eco.mission_threads(w, boss, true, 2, 2), true, rng)
			_after_play(p, w, Eco.mission_threads(w, boss, false, 3, 1), true, rng)
		_after_play(p, w, 0, false, rng)  # una derrota
		for f in farm:
			_after_play(p, w, Eco.mission_threads(w, false, false, 3, 0), true, rng)
		if w == 1:
			for k in Eco.FREE_PULLS_AFTER_W1:
				_pull(p, rng)
		_spend(p, w, rng)
		var row: Dictionary = rows[w]
		var team := _team(p)
		row.threads += p.earned
		row.pulls += p.pulls
		row.distinct += p.heroes.size()
		row.workshop += p.workshop
		row.minutes += p.minutes
		var lvl := 0.0
		var cat := 0.0
		var ok := true
		for h in team:
			lvl += h.level
			cat += h.category
			ok = ok and h.level >= Eco.EXPECTED_LEVEL[w + 1]
		if team.is_empty():
			lvl = Eco.EXPECTED_LEVEL[w + 1] * 2  # protagonistas: nivel de historia
			cat = 2
		row.level += lvl / 2.0
		row.category += cat / 2.0
		row.on_level += 1 if ok else 0
		if w == 6:
			var best := -1
			for h in team:
				best = maxi(best, h.rarity)
			if best >= 0:
				row.top_rarity[best] += 1


func _after_play(p: Dictionary, w: int, threads: int, victory: bool, rng: RandomNumberGenerator) -> void:
	p.threads += threads
	p.earned += threads
	p.minutes += MINUTES_PER_PLAY
	var team := _team(p)
	for h in team:
		var xp := Eco.mission_xp(w, victory)
		if h.level < Eco.EXPECTED_LEVEL[w] - Eco.CATCH_UP_GAP:
			xp *= Eco.CATCH_UP_MULT
		_gain_xp(h, xp)
	_spend(p, w, rng)


func _gain_xp(h: Dictionary, xp: int) -> void:
	h.xp += xp
	while h.level < Eco.level_cap(h.category) and h.xp >= Eco.xp_to_next(h.level):
		h.xp -= Eco.xp_to_next(h.level)
		h.level += 1
	if h.level >= Eco.level_cap(h.category):
		h.xp = mini(h.xp, Eco.xp_to_next(h.level))  # la experiencia sobrante no se pierde del todo


## Asciende al equipo si lo necesita y gasta el resto en tiradas.
func _spend(p: Dictionary, w: int, rng: RandomNumberGenerator) -> void:
	for h in _team(p):
		while h.category < 6 and h.level >= Eco.level_cap(h.category) \
				and h.level < Eco.EXPECTED_LEVEL[mini(w + 1, 7)] + 5:
			var next: int = h.category + 1
			var missing := maxi(0, Eco.ASCEND_FRAGMENTS[next] - h.fragments)
			var cost: int = Eco.ASCEND_THREADS[next] + missing * Eco.WORKSHOP_FRAGMENT_PRICE
			if p.threads < cost:
				return  # ahorra para ascender antes de tirar
			p.threads -= cost
			p.workshop += missing * Eco.WORKSHOP_FRAGMENT_PRICE
			h.fragments += missing - Eco.ASCEND_FRAGMENTS[next]
			h.category = next
			_gain_xp(h, 0)
	while p.threads >= Eco.TEN_PULL_COST:
		p.threads -= Eco.TEN_PULL_COST
		for k in 10:
			_pull(p, rng)
	while p.threads >= Eco.PULL_COST and p.threads < Eco.TEN_PULL_COST and _team(p).size() < 2:
		p.threads -= Eco.PULL_COST
		_pull(p, rng)


func _pull(p: Dictionary, rng: RandomNumberGenerator) -> void:
	p.pulls += 1
	var rarity := Eco.roll_rarity(rng, p.pity)
	var id := "%d_%d" % [rarity, rng.randi_range(0, Eco.HEROES_PER_RARITY[rarity] - 1)]
	if p.heroes.has(id):
		p.heroes[id].fragments += Eco.DUPLICATE_FRAGMENTS[rarity]
	else:
		p.heroes[id] = {rarity = rarity, level = 1, xp = 0, category = 1, fragments = 0}


func _team(p: Dictionary) -> Array:
	var all: Array = p.heroes.values()
	all.sort_custom(func(a, b): return a.rarity > b.rarity or (a.rarity == b.rarity and a.level > b.level))
	return all.slice(0, 2)
