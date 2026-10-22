## Tests del servicio de guardado con un servidor simulado en memoria.
## Uso: godot --headless --path . --script res://tests/service_tests.gd
extends SceneTree

const SaveService := preload("res://src/services/save_service.gd")
const DIR := "user://test_save/"

var _failures := 0
var _checks := 0


## Servidor de mentira: sesiones, idempotencia por nonce, recompensa fija y
## fallos de red a voluntad.
class FakeServer extends RefCounted:
	var offline := false
	var signups := 0
	var refreshes := 0
	var calls := 0
	var results := {}  # nonce → respuesta
	var threads := 0
	var expire_next := false

	func sign_up_anonymous() -> Dictionary:
		if offline:
			return {ok = false, status = 0, data = null, error = "network"}
		signups += 1
		return {ok = true, status = 200, data = {access_token = "a%d" % signups,
			refresh_token = "r%d" % signups, user = {id = "u1"}}, error = ""}

	func refresh(token: String) -> Dictionary:
		if offline:
			return {ok = false, status = 0, data = null, error = "network"}
		refreshes += 1
		return {ok = true, status = 200, data = {access_token = "a-ref", refresh_token = token,
			user = {id = "u1"}}, error = ""}

	func rpc_call(_fn: String, p: Dictionary, _token: String) -> Dictionary:
		if offline:
			return {ok = false, status = 0, data = null, error = "network"}
		if expire_next:
			expire_next = false
			return {ok = false, status = 401, data = null, error = "JWT expired"}
		calls += 1
		if results.has(p.p_client_nonce):
			var prev: Dictionary = results[p.p_client_nonce].duplicate()
			prev.duplicate = true
			return {ok = true, status = 200, data = prev, error = ""}
		if p.p_outcome == "victory" and p.p_duration_secs < 150:
			return {ok = false, status = 400, data = null, error = "implausible_victory"}
		var reward := 50 if p.p_outcome == "victory" else 0
		threads += reward
		var res := {duplicate = false, stars = 3 if p.p_outcome == "victory" else 0, reward = reward, threads = threads}
		results[p.p_client_nonce] = res
		return {ok = true, status = 200, data = res, error = ""}


func check(cond: bool, msg: String) -> void:
	_checks += 1
	print(("  ✓ " if cond else "  ✗ ") + msg)
	if not cond:
		_failures += 1


func _initialize() -> void:
	_run.call_deferred()


func _service(server) -> SaveService:
	var s := SaveService.new()
	s.storage_dir = DIR
	s.transport = server
	root.add_child(s)
	return s


func _victory(duration := 240) -> Dictionary:
	return {mission_id = "w1_m5", outcome = "victory", base_hp = 20, waves_reached = 5,
		duration_secs = duration, stars = 3, stats = {kills = 100}}


func _clean() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR.path_join(f)))


func _run() -> void:
	_clean()
	var server := FakeServer.new()

	# 1. Sin conexión: el resultado queda en cola y el progreso local se actualiza.
	server.offline = true
	var s := _service(server)
	await s.start()
	await s.submit_result(_victory())
	check(s.pending_count() == 1, "sin conexión el resultado queda en cola")
	check(s.best_stars("w1_m5") == 3, "el progreso local se actualiza igualmente")
	s.queue_free()

	# 2. La cola sobrevive a reiniciar el juego y se envía al recuperar la conexión.
	server.offline = false
	s = _service(server)
	check(s.pending_count() == 1, "la cola se conserva entre sesiones")
	await s.start()
	check(server.signups == 1, "crea un usuario invitado una sola vez")
	check(s.pending_count() == 0 and server.calls == 1, "al conectar envía lo pendiente")
	check(s.threads() == 50, "guarda las monedas que devuelve el servidor")
	s.queue_free()

	# 3. Siguiente sesión: renueva el token en vez de crear otro usuario.
	s = _service(server)
	await s.start()
	check(server.signups == 1 and server.refreshes == 1, "reutiliza la sesión guardada (refresh)")

	# 4. Token caducado durante el envío: se renueva y se reintenta.
	server.expire_next = true
	await s.submit_result(_victory())
	check(s.pending_count() == 0 and server.refreshes == 2, "token caducado: renueva y reenvía")

	# 5. Fallo de red a mitad: el reintento usa el MISMO nonce (sin recompensas dobles).
	server.offline = true
	await s.submit_result(_victory())
	var nonce: String = s._pending[0].client_nonce
	server.offline = false
	await s.flush()
	check(server.results.has(nonce), "el reintento usa el mismo identificador de partida")
	var threads_before := server.threads
	var dup: Dictionary = await server.rpc_call("submit_match_result", {p_client_nonce = nonce,
		p_outcome = "victory", p_duration_secs = 240}, "")
	check(dup.data.duplicate and server.threads == threads_before, "reenviar el mismo resultado no da más monedas")

	# 6. Rechazo del servidor (inverosímil): no se queda reintentando para siempre.
	await s.submit_result(_victory(30))
	check(s.pending_count() == 0, "un resultado rechazado no bloquea la cola")

	s.queue_free()

	# 7. Modo local (sin servidor): recompensas con las mismas reglas que el SQL.
	_clean()
	s = _service(null)
	await s.start()
	var got := []
	s.result_processed.connect(func(r): got.append(r))
	var v1 := _victory()
	v1.stars = 1
	await s.submit_result(v1)
	check(got[-1].reward == 50 + 1 * 20 and got[-1].first_clear, "local: primera victoria (1★) = 70")
	await s.submit_result(_victory())
	check(got[-1].reward == 2 * 20, "local: mejorar de 1★ a 3★ = 40")
	await s.submit_result(_victory())
	check(got[-1].reward == 5, "local: repetir victoria = 5")
	await s.submit_result({mission_id = "w1_m5", outcome = "defeat", base_hp = 0, waves_reached = 3,
		duration_secs = 120, stars = 0})
	check(got[-1].reward == 0, "local: derrota sin recompensa")
	check(s.pending_count() == 0, "local: no acumula envíos pendientes")
	s.queue_free()

	# 8. El progreso local se conserva al «reabrir el juego».
	s = _service(null)
	var p := s.progress_of("w1_m5")
	check(s.threads() == 115 and s.best_stars("w1_m5") == 3, "se conservan los hilos (115) y mejores estrellas")
	check(p.victories == 3 and p.attempts == 4 and p.best_time_secs == 240, "se conservan victorias, intentos y mejor tiempo")
	s.queue_free()

	# 9. Migración: el progreso guardado con el id antiguo (w1_m1) pasa a w1_m5.
	_clean()
	var f := FileAccess.open(DIR.path_join("rift_progress.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({w1_m1 = {best_stars = 2, victories = 1}, shards = 30}))
	f.close()
	s = _service(null)
	check(s.best_stars("w1_m5") == 2 and s.best_stars("w1_m1") == 0, "migra el progreso de w1_m1 a w1_m5")
	check(s.threads() == 30, "conserva los hilos al migrar (antes «shards»)")
	check(Array(s.owned_heroes()) == SaveService.STARTER_HEROES, "un jugador empieza con los héroes iniciales")
	check(Array(s.owned_towers()) == SaveService.STARTER_TOWERS, "y con las torres iniciales")
	s.set_last_heroes(PackedStringArray(["hero_blade", "hero_portal"]))
	s.queue_free()
	s = _service(null)
	check(Array(s.last_heroes()) == ["hero_blade", "hero_portal"], "recuerda los últimos héroes elegidos")
	s.queue_free()
	_clean()
	print("\n%d comprobaciones, %d fallos" % [_checks, _failures])
	await process_frame
	quit(1 if _failures > 0 else 0)
