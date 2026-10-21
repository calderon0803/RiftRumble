## Juega la misión con estrategias predefinidas y resume cada oleada.
## Uso: godot --headless --path . --script res://tools/balance.gd
extends SceneTree

const SimWorld := preload("res://src/sim/sim_world.gd")
const ContentDB := preload("res://src/content/content_db.gd")

## Cada estrategia: lista de acciones que se intentan en cada tick
## [&"build", posición, torre] o [&"upgrade", posición] (solo entre oleadas).
const STRATEGIES := {
	"sin torres": [],
	"solo pixeladora": [[&"build", 1, &"pixeladora"]],
	"pix+grim+reb": [[&"build", 1, &"pixeladora"], [&"build", 0, &"grimorio"], [&"build", 2, &"rebote"],
		[&"upgrade", 1], [&"upgrade", 2]],
	"3 rebotes": [[&"build", 1, &"rebote"], [&"build", 0, &"rebote"], [&"build", 2, &"rebote"]],
	"grim+pix (combo)": [[&"build", 1, &"grimorio"], [&"build", 0, &"pixeladora"], [&"build", 2, &"pixeladora"],
		[&"upgrade", 0], [&"upgrade", 2]],
}


func _init() -> void:
	var db = ContentDB.load_all()
	var mission: MissionDef = db.missions[&"continue_01"]
	var map: Node = load(mission.map_scene).instantiate()
	var map_def = map.build_def()
	map.free()
	for name in STRATEGIES:
		var w := SimWorld.new(map_def.routes, 99)
		w.setup_mission(db, mission, map_def)
		var log := []
		var leaks := 0
		var kills := 0
		for i in 30 * 60 * 10:
			for action in STRATEGIES[name]:
				if action[0] == &"build" and w.tower_at(action[1]).is_empty():
					w.build(action[1], action[2])
				elif action[0] == &"upgrade" and not w.wave_active:
					w.upgrade(action[1])
			if not w.wave_active and not w.is_over():
				w.start_next_wave()
			w.step()
			for ev in w.drain_events():
				match ev.type:
					&"enemy_leaked": leaks += 1
					&"enemy_killed": kills += 1
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
		print("\n== %s → %s (%.0f s)" % [name, SimWorld.Outcome.keys()[w.outcome], w.tick / 30.0])
		print("   torres: %s" % ", ".join(levels))
		for line in log:
			print("   " + line)
	quit()
