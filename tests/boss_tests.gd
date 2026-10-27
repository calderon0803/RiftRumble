## Tests del primer jefe (el Guardián) en su arena real.
## Uso: godot --headless --path . --script res://tests/boss_tests.gd
extends SceneTree

const SAVE := "user://test_jefe.json"
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


func _local_x(w: World, node: Node2D) -> float:
	return (node.position.x - w.current.rect.position.x) / T


func _waves(w: World) -> Array:
	return w._room_node.get_children().filter(func(n): return n is Shockwave and not n.is_queued_for_deletion())


func _run() -> void:
	SaveGame.erase(SAVE)
	var w: World = load("res://src/world/world.tscn").instantiate()
	w.save_path = SAVE
	w.hitstop_enabled = false
	root.add_child(w)
	await _physics(3)
	var kira := w.kira

	print("Arena")
	check(w.layouts["abismo"].bench != Vector2.INF, "hay un banco en el abismo, junto a la guarida")
	w.enter_room("guarida")
	check(w.boss != null, "en la guarida está el Guardián")
	check(not w.gate_closed, "la puerta está abierta al llegar")
	kira.place_at(w.current.rect.position + Vector2(34.5 * T, 22 * T))
	await _physics(3)
	check(w.gate_closed, "al entrar, la puerta se cierra")
	kira.scripted_input = {"x": 1.0}
	await _physics(60)
	check(_local_x(w, kira) < 38.0, "y no se puede salir")
	kira.scripted_input = {"x": 0.0}

	print("Embestida")
	var boss := w.boss
	# En la zona abierta (bajo las repisas no hay altura para saltarlo).
	kira.place_at(w.current.rect.position + Vector2(24.5 * T, 22 * T))
	boss.position = w.current.rect.position + Vector2(12 * T, 22 * T)
	boss._pattern_i = 0  # lo siguiente es una embestida
	boss._enter(BossGuardian.State.IDLE)
	kira.health.reset()
	var hp0 := kira.health.hp
	var jumped := false
	var charged := false
	for i in 240:
		await physics_frame
		if boss.state == BossGuardian.State.CHARGE:
			charged = true
			if not jumped and absf(boss.position.x - kira.position.x) < 100.0:
				kira.scripted_input = {"x": 0.0, "jump": true}
				jumped = true
		if boss.state == BossGuardian.State.STUNNED:
			break
	kira.scripted_input = {"x": 0.0}
	check(charged, "embiste hacia Kira tras avisar")
	check(kira.health.hp == hp0, "saltándola no se recibe daño")
	check(boss.state == BossGuardian.State.STUNNED, "al chocar con la pared queda aturdido")

	# Subida a una repisa también se está a salvo: el jefe pasa por debajo.
	kira.place_at(w.current.rect.position + Vector2(32.5 * T, 18 * T))
	boss.position = w.current.rect.position + Vector2(12 * T, 22 * T)
	boss._pattern_i = 0
	boss._enter(BossGuardian.State.IDLE)
	kira.health.reset()
	var passed_under := false
	for i in 240:
		await physics_frame
		if boss.state == BossGuardian.State.CHARGE and boss.position.x > kira.position.x:
			passed_under = true
		if boss.state == BossGuardian.State.STUNNED:
			break
	check(passed_under and kira.health.hp == kira.health.max_hp, "subida a una repisa pasa por debajo sin hacerle daño")

	print("Golpearle aturdido")
	await _physics(30)
	var stunned_at := boss.position
	kira.place_at(stunned_at + Vector2(-60, 0))
	kira.health.invulnerable = 1.0
	var boss_hp := boss.health.hp
	for i in 2:
		kira.scripted_input = {"x": 1.0, "attack": true}
		await _physics(1)
		kira.scripted_input = {"x": 0.0}
		await _physics(int(KiraCombat.COOLDOWN * 60) + 1)
	check(boss.health.hp < boss_hp, "los tajos le quitan vida (%d → %d)" % [boss_hp, boss.health.hp])
	check(boss.position.distance_to(stunned_at) < 2.0, "no retrocede al golpearle (es pesado)")

	print("Salto aplastante")
	kira.health.reset()
	kira.place_at(w.current.rect.position + Vector2(20.5 * T, 22 * T))
	var landed := false
	for i in 300:
		await physics_frame
		if boss.state == BossGuardian.State.SLAM_RECOVER:
			landed = true
			break
	check(landed, "salta hacia Kira")
	await _physics(1)
	var waves := _waves(w)
	check(waves.size() == 2, "al caer lanza dos ondas por el suelo")
	if waves.size() == 2:
		check(waves[0].dir != waves[1].dir, "una hacia cada lado")
	# Saltar una onda: Kira lejos, salta cuando la onda está cerca.
	kira.place_at(w.current.rect.position + Vector2(3.5 * T, 22 * T))
	kira.health.reset()
	kira.health.invulnerable = 0.0
	for e in _waves(w):
		e.queue_free()
	boss.position.x = w.current.rect.position.x + 20.0 * T
	await _physics(2)
	boss._land()
	var hp1 := kira.health.hp
	var wave_jumped := false
	for i in 180:
		await physics_frame
		for wv in _waves(w):
			if wv.dir < 0 and not wave_jumped and absf(wv.position.x - kira.position.x) < 70.0:
				kira.scripted_input = {"x": 0.0, "jump": true}
				wave_jumped = true
		if wave_jumped and kira.is_on_floor() and i > 30:
			break
	kira.scripted_input = {"x": 0.0}
	await _physics(5)
	check(wave_jumped and kira.health.hp == hp1, "las ondas se saltan sin recibir daño")
	await _physics(120)
	check(_waves(w).is_empty(), "y desaparecen al llegar a las paredes")

	print("Fase 2")
	boss.health.hp = BossGuardian.MAX_HP / 2 + 1
	boss.take_hit(1, kira.position)
	check(boss.phase == 1, "a media vida pasa a la fase 2")
	check(BossGuardian.CHARGE_SPEED[1] > BossGuardian.CHARGE_SPEED[0], "más rápido en la fase 2")

	print("Victoria")
	var max0 := kira.health.max_hp
	boss.health.hp = 1
	boss.take_hit(1, kira.position)
	await _physics(3)
	check(w.boss == null and w.bosses_defeated.has("guarida"), "con 0 de vida es vencido")
	check(w._gate_body == null, "la puerta se abre")
	check(kira.health.max_hp == max0 + 1, "recompensa: un corazón más (%d)" % kira.health.max_hp)
	var data := SaveGame.load_from(SAVE)
	check("guarida" in data.get("bosses", []), "y queda guardado")
	w.enter_room("guarida")
	await _physics(2)
	check(w.boss == null, "al volver a la guarida ya no está")
	kira.place_at(w.current.rect.position + Vector2(34.5 * T, 22 * T))
	await _physics(3)
	check(not w.gate_closed, "y la puerta ya no se cierra")

	w.queue_free()
	await _physics(2)
	SaveGame.erase(SAVE)
	print("\n%d/%d comprobaciones correctas" % [_checks - _failures, _checks])
	quit(1 if _failures > 0 else 0)
