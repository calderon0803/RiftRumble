## Valida héroes en las misiones del mundo 1 (docs/personajes/H §7):
## - medidor: segundos hasta llenarlo y usos por oleada (objetivo: 1–2);
## - con torres: resultado del equipo [héroe + Kira] frente a los protagonistas;
## - sin torres: ningún héroe gana solo (ni acompañado de Kira).
## Uso: godot --headless --path . --script res://tools/hero_check.gd -- [hero_aeron …]
extends SceneTree

const SimWorld := preload("res://src/sim/sim_world.gd")
const ContentDB := preload("res://src/content/content_db.gd")
const Balance := preload("res://tools/balance.gd")

const MISSIONS := [&"w1_m1", &"w1_m2", &"w1_m3", &"w1_m4", &"w1_m5"]
const DEFAULT_HEROES := ["hero_aeron", "hero_zerik", "hero_nimue", "hero_astraion"]
const PARTNER := "hero_blade"
const BASELINE := ["hero_portal", "hero_blade"]
## Misiones de introducción: los coleccionables llegan al completar el mundo 1
## (tirada ×10 gratuita, docs/10), así que aquí solo se avisa.
const INTRO := [&"w1_m1", &"w1_m2"]


func _init() -> void:
	var db = ContentDB.load_all()
	var ids := OS.get_cmdline_user_args()
	if ids.is_empty():
		ids = PackedStringArray(DEFAULT_HEROES)
	var problems := []
	var notes := []
	print("Equipo | misión | resultado (con torres) | fugas | usos/oleada | s hasta 100 % | sin torres (solo / con Kira)")
	for team in [BASELINE] + Array(ids).map(func(id): return [id, PARTNER]):
		for m in MISSIONS:
			var r: Dictionary = Balance.play(db, m, "equipo inicial + mejoras", [], PackedStringArray(team), true)
			var w: SimWorld = r.world
			var waves := float(maxi(w.wave_index + 1, 1))
			var fills: Array = r.fill_secs[0]
			var mean_fill: float = fills.reduce(func(a, b): return a + b, 0.0) / maxf(fills.size(), 1.0)
			var alone := ""
			if team != BASELINE:
				var solo: Dictionary = Balance.play(db, m, "sin torres", [], PackedStringArray([team[0]]), true)
				var duo: Dictionary = Balance.play(db, m, "sin torres", [], PackedStringArray(team), true)
				alone = "%s / %s" % [_short(solo.world), _short(duo.world)]
				if solo.world.outcome == SimWorld.Outcome.VICTORY or duo.world.outcome == SimWorld.Outcome.VICTORY:
					(notes if m in INTRO else problems).append("%s gana %s sin torres" % [team[0], m])
			print("%-28s | %s | %s %d★ | %2d | %.1f | %s | %s" % [", ".join(team), m,
				_short(w), w.stars(), w.stats.leaks, r.casts[0] / waves,
				"%.0f" % mean_fill if fills.size() > 0 else "—", alone])
	if not notes.is_empty():
		print("\nAvisos (misiones de introducción):\n  " + "\n  ".join(notes))
	print("\n" + ("Sin problemas." if problems.is_empty() else "PROBLEMAS:\n  " + "\n  ".join(problems)))
	quit()


static func _short(w: SimWorld) -> String:
	return "gana" if w.outcome == SimWorld.Outcome.VICTORY else "pierde"
