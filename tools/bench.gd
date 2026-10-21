## Benchmark headless de la simulación (sin render).
## Uso:  godot --headless --path . --script res://tools/bench.gd -- [enemigos] [ticks] [intervalo_s] [vel_proyectil]
## Un intervalo corto y proyectiles lentos (p. ej. 0.1 y 2) estresan el sistema de proyectiles.
extends SceneTree

const SimWorld := preload("res://src/sim/sim_world.gd")
const StressLayout := preload("res://src/poc/stress_layout.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var enemies := int(args[0]) if args.size() > 0 else 500
	var ticks := int(args[1]) if args.size() > 1 else 600
	var interval := float(args[2]) if args.size() > 2 else 0.5
	var proj_speed := float(args[3]) if args.size() > 3 else 10.0

	var map: Node = load("res://maps/w1/w1_m1.tscn").instantiate()
	var def = map.build_def()
	map.free()
	var w := SimWorld.new(def.routes[0], 1)
	w.base_hp = 1_000_000_000
	for spot in StressLayout.tower_spots(def, 12):
		w.add_tower(spot, 3.5, interval, 1.0, proj_speed)
	for i in enemies:
		w.spawn_enemy(40.0, 1.2, w.rng.randf_range(0.0, w.path.length * 0.95))

	var times := PackedFloat64Array()
	var max_proj := 0
	for t in ticks:
		while w.enemy_count < enemies:
			w.spawn_enemy(40.0, 1.2)
		var t0 := Time.get_ticks_usec()
		w.step()
		times.append((Time.get_ticks_usec() - t0) / 1000.0)
		w.drain_events()
		max_proj = maxi(max_proj, w.projectile_count)

	var sorted := times.duplicate()
	sorted.sort()
	var total := 0.0
	for x in times:
		total += x
	print("BENCH enemigos=%d torres=%d ticks=%d proyectiles_max=%d" % [enemies, w.towers.size(), ticks, max_proj])
	print("BENCH media=%.3f ms  p95=%.3f ms  max=%.3f ms  (presupuesto a 30 Hz: 33.3 ms)" % [
		total / ticks, sorted[int(ticks * 0.95)], sorted[ticks - 1]])
	quit()
