## Juega la misión con estrategias predefinidas y resume cada oleada.
## Uso: godot --headless --path . --script res://tools/balance.gd
##
## Ritmo: la primera oleada se lanza al empezar; las demás empiezan solas tras
## la cuenta atrás, salvo en las estrategias «agresivas», que las adelantan y
## cobran el oro extra. Con `kira`, el héroe de la espada se coloca en la esquina
## (14, 4) y corta a lo largo de la columna cada vez que puede.
extends SceneTree

const SimWorld := preload("res://src/sim/sim_world.gd")
const ContentDB := preload("res://src/content/content_db.gd")

## actions: lista de [&"build", posición, torre] o [&"upgrade", posición]
## (las mejoras se intentan solo entre oleadas).
const STRATEGIES := {
	"sin torres": {actions = []},
	"solo corrupción": {actions = [[&"build", 1, &"tower_corrupt"]]},
	"una de cada, sin mejorar": {actions = [[&"build", 1, &"tower_corrupt"], [&"build", 0, &"tower_seal"],
		[&"build", 2, &"tower_bounce"]]},
	"una de cada + mejoras": {actions = [[&"build", 1, &"tower_corrupt"], [&"build", 0, &"tower_seal"],
		[&"build", 2, &"tower_bounce"], [&"upgrade", 1], [&"upgrade", 2], [&"upgrade", 0]]},
	"una de cada + mejoras + Kira": {kira = true, actions = [[&"build", 1, &"tower_corrupt"],
		[&"build", 0, &"tower_seal"], [&"build", 2, &"tower_bounce"], [&"upgrade", 1], [&"upgrade", 2],
		[&"upgrade", 0]]},
	"3× rebote + mejoras": {actions = [[&"build", 1, &"tower_bounce"], [&"build", 0, &"tower_bounce"],
		[&"build", 2, &"tower_bounce"], [&"upgrade", 1], [&"upgrade", 0], [&"upgrade", 2]]},
	"agresiva (adelanta oleadas)": {aggressive = true, actions = [[&"build", 1, &"tower_corrupt"],
		[&"build", 0, &"tower_seal"], [&"build", 2, &"tower_bounce"], [&"upgrade", 1], [&"upgrade", 2],
		[&"upgrade", 0]]},
}


func _init() -> void:
	var db = ContentDB.load_all()
	var mission: MissionDef = db.missions[&"w1_m1"]
	var map: Node = load(mission.map_scene).instantiate()
	var map_def = map.build_def()
	map.free()
	for name in STRATEGIES:
		var strat: Dictionary = STRATEGIES[name]
		var w := SimWorld.new(map_def.routes, 99)
		w.setup_mission(db, mission, map_def)
		var log := []
		var leaks := 0
		var kills := 0
		var revives := 0
		w.start_next_wave()
		if strat.get("kira", false):
			w.move_hero(1, Vector2(14, 4.5))
		for i in 30 * 60 * 15:
			for action in strat.actions:
				if action[0] == &"build" and w.tower_at(action[1]).is_empty():
					w.build(action[1], action[2])
				elif action[0] == &"upgrade" and not w.wave_active:
					w.upgrade(action[1])
			if strat.get("aggressive", false) and not w.wave_active and not w.is_over():
				w.start_next_wave()
			if strat.get("kira", false) and w.enemy_count > 0:
				w.cast_ability(1, Vector2(14, 10))
			w.step()
			for ev in w.drain_events():
				match ev.type:
					&"enemy_leaked": leaks += 1
					&"enemy_killed": kills += 1
					&"enemy_revived": revives += 1
					&"wave_cleared", &"defeat":
						log.append("O%d: bajas %d, fugas %d, base %d, oro %d" % [
							w.wave_index + 1, kills, leaks, w.base_hp, w.gold])
						leaks = 0
						kills = 0
			if w.is_over():
				break
		var levels := []
		for t in w.towers:
			levels.append("%s@%d L%d" % [t.def.id, t.spot, t.level])
		print("\n== %s → %s, %d★ (%.0f s)" % [name, SimWorld.Outcome.keys()[w.outcome], w.stars(), w.tick / 30.0])
		print("   torres: %s · KOs héroes %d · oro extra %d · el jefe reapareció: %s" % [
			", ".join(levels), w.stats.hero_kos, w.stats.early_bonus, "sí" if revives > 0 else "no"])
		for line in log:
			print("   " + line)
	quit()
