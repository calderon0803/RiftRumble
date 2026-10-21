## Servicio de guardado: progreso del jugador, en local o en la nube.
##
## - MODO LOCAL (sin config/backend.json): el progreso y los fragmentos se
##   calculan y guardan en el dispositivo con las mismas reglas que el servidor.
##   Limitación: un archivo local puede editarse; no protege datos (ver docs/07).
## - MODO NUBE (con config/backend.json): los resultados quedan en cola (user://)
##   hasta que el servidor los acepta.
## - Cada resultado lleva un `client_nonce` único y se reenvía con el MISMO nonce
##   tras un fallo: el servidor no duplica recompensas.
## - El servidor es la fuente de verdad de estrellas y monedas; lo local es una
##   copia para mostrar progreso sin conexión.
##
## `transport` es el cliente de Supabase (o un doble en los tests).
extends Node

const SupabaseClient := preload("res://src/services/supabase_client.gd")

signal status_changed(text: String)
signal result_processed(response: Dictionary)

## Héroes y torres con los que empieza cualquier jugador (el resto, por tiradas).
const STARTER_HEROES := ["hero_portal", "hero_blade"]
const STARTER_TOWERS := ["tower_corrupt", "tower_seal", "tower_bounce"]
## Ids de misión renombrados (migración de partidas guardadas antiguas).
const RENAMED_MISSIONS := {"w1_m1": "w1_m5"}

## Máximo de resultados en cola (si nunca hay conexión, se descartan los más antiguos).
const MAX_PENDING := 50

## Carpeta de los archivos locales (los tests usan otra).
var storage_dir := "user://"
var transport  # SupabaseClient o doble de pruebas
var online := false

var _session := {}       # access_token, refresh_token, user_id
var _pending: Array = [] # resultados por enviar
var _progress := {}      # mission_id → {best_stars, victories}, shards
var _flushing := false
var _started := false


func _ready() -> void:
	_load()


## Configura el transporte real a partir de res://config/backend.json (si existe).
func configure_from_file(path := "res://config/backend.json") -> void:
	if transport != null or not FileAccess.file_exists(path):
		return
	var cfg = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (cfg is Dictionary) or cfg.get("url", "") == "" or cfg.get("publishable_key", "") == "":
		return
	var client := SupabaseClient.new()
	client.url = cfg.url
	client.api_key = cfg.publishable_key
	add_child(client)
	transport = client


## Configura y arranca una sola vez (lo llaman las pantallas que lo usan).
func ensure_started() -> void:
	if _started:
		return
	_started = true
	configure_from_file()
	await start()


## Inicia sesión (o la renueva) y envía lo pendiente.
func start() -> void:
	if transport == null:
		_set_status("Progreso guardado en este dispositivo")
		return
	var ok := await _ensure_session()
	online = ok
	_set_status("Conectado como invitado" if ok else "Sin conexión: se guardará más tarde")
	if ok:
		await flush()


## Registra el resultado de una partida y lo intenta enviar.
func submit_result(summary: Dictionary) -> void:
	if transport == null:
		var res := _apply_local_rewards(summary)
		_save()
		result_processed.emit(res)
		return
	var entry := summary.duplicate()
	entry.client_nonce = _uuid_v4()
	_pending.append(entry)
	while _pending.size() > MAX_PENDING:
		_pending.pop_front()
	_apply_local(entry)
	_save()
	await flush()


## Envía los resultados pendientes en orden; se detiene ante el primer fallo de red.
func flush() -> void:
	if _flushing or transport == null or _pending.is_empty():
		return
	_flushing = true
	if _session.is_empty() and not await _ensure_session():
		_flushing = false
		_set_status("Sin conexión: %d resultado(s) pendiente(s)" % _pending.size())
		return
	while not _pending.is_empty():
		var entry: Dictionary = _pending[0]
		var res: Dictionary = await transport.rpc_call("submit_match_result", {
			p_mission_id = entry.mission_id, p_client_nonce = entry.client_nonce,
			p_outcome = entry.outcome, p_base_hp = entry.base_hp,
			p_waves_reached = entry.waves_reached, p_duration_secs = entry.duration_secs,
			p_stats = entry.get("stats", {}),
		}, _session.get("access_token", ""))
		if res.ok:
			_pending.pop_front()
			_apply_server(entry.mission_id, res.data)
			_save()
			result_processed.emit(res.data)
		elif res.status == 401 and await _refresh_session():
			continue  # token caducado: se reintenta el mismo envío
		elif res.status >= 400 and res.status < 500:
			# El servidor lo rechaza (inverosímil, misión desconocida…): no se reintenta.
			push_warning("Resultado rechazado por el servidor: %s" % res.error)
			_pending.pop_front()
			_save()
			result_processed.emit({rejected = true, error = res.error})
		else:
			_set_status("Sin conexión: %d resultado(s) pendiente(s)" % _pending.size())
			break
	_flushing = false
	if _pending.is_empty():
		_set_status("Progreso guardado en la nube")


func pending_count() -> int:
	return _pending.size()


## Héroes que posee el jugador (ids).
func owned_heroes() -> PackedStringArray:
	return PackedStringArray(_progress.get("heroes", STARTER_HEROES))


## Torres que posee el jugador (ids).
func owned_towers() -> PackedStringArray:
	return PackedStringArray(_progress.get("towers", STARTER_TOWERS))


func last_towers() -> PackedStringArray:
	return PackedStringArray(_progress.get("last_towers", []))


func set_last_towers(ids: PackedStringArray) -> void:
	_progress.last_towers = Array(ids)
	_save()


## Últimos héroes elegidos para jugar (para preseleccionarlos).
func last_heroes() -> PackedStringArray:
	return PackedStringArray(_progress.get("last_heroes", []))


func set_last_heroes(ids: PackedStringArray) -> void:
	_progress.last_heroes = Array(ids)
	_save()


func progress_of(mission_id: String) -> Dictionary:
	return _progress.get(mission_id, {})


func best_stars(mission_id: String) -> int:
	return _progress.get(mission_id, {}).get("best_stars", 0)


func shards() -> int:
	return _progress.get("shards", 0)


# --- Sesión -------------------------------------------------------------------

func _ensure_session() -> bool:
	if not _session.is_empty():
		return true
	if _session_file_token() != "" and await _refresh_session():
		return true
	var res: Dictionary = await transport.sign_up_anonymous()
	if not res.ok:
		return false
	_store_session(res.data)
	return true


func _refresh_session() -> bool:
	var token: String = _session.get("refresh_token", _session_file_token())
	if token == "":
		return false
	var res: Dictionary = await transport.refresh(token)
	if not res.ok:
		_session = {}
		return false
	_store_session(res.data)
	return true


func _store_session(data) -> void:
	if not (data is Dictionary) or not data.has("access_token"):
		return
	_session = {access_token = data.access_token, refresh_token = data.get("refresh_token", ""),
		user_id = data.get("user", {}).get("id", "")}
	_write_json("rift_session.json", {refresh_token = _session.refresh_token, user_id = _session.user_id})


func _session_file_token() -> String:
	return _read_json("rift_session.json").get("refresh_token", "")


# --- Progreso -----------------------------------------------------------------

## Modo local: misma lógica de recompensas que `submit_match_result` en SQL.
## `summary.rewards` = {first_clear, per_star, replay} (de MissionDef).
func _apply_local_rewards(summary: Dictionary) -> Dictionary:
	var id: String = summary.mission_id
	var p: Dictionary = _progress.get(id, {best_stars = 0, victories = 0, attempts = 0, best_time_secs = -1})
	var rw: Dictionary = summary.get("rewards", {first_clear = 50, per_star = 20, replay = 5})
	var won: bool = summary.outcome == "victory"
	var stars: int = summary.get("stars", 0) if won else 0
	var reward := 0
	var first := false
	if won:
		if p.get("victories", 0) == 0:
			first = true
			reward = rw.first_clear + stars * rw.per_star
		elif stars > p.best_stars:
			reward = (stars - p.best_stars) * rw.per_star
		else:
			reward = rw.replay
		p.victories = p.get("victories", 0) + 1
		var t: int = summary.get("duration_secs", 0)
		p.best_time_secs = t if p.get("best_time_secs", -1) < 0 else mini(p.best_time_secs, t)
	p.attempts = p.get("attempts", 0) + 1
	p.best_stars = maxi(p.get("best_stars", 0), stars)
	_progress[id] = p
	_progress.shards = _progress.get("shards", 0) + reward
	return {duplicate = false, stars = stars, reward = reward, first_clear = first,
		shards = _progress.shards, best_stars = p.best_stars, local = true}


## Copia local optimista (las estrellas se calculan igual que en el servidor).
func _apply_local(entry: Dictionary) -> void:
	var p: Dictionary = _progress.get(entry.mission_id, {best_stars = 0, victories = 0})
	if entry.outcome == "victory":
		p.victories += 1
		p.best_stars = maxi(p.best_stars, entry.get("stars", 0))
	_progress[entry.mission_id] = p


func _apply_server(mission_id: String, data) -> void:
	if not (data is Dictionary):
		return
	var p: Dictionary = _progress.get(mission_id, {best_stars = 0, victories = 0})
	p.best_stars = maxi(p.best_stars, int(data.get("stars", 0)))
	_progress[mission_id] = p
	if data.has("shards") and data.shards != null:
		_progress.shards = int(data.shards)


# --- Archivos -----------------------------------------------------------------

func _load() -> void:
	_pending = _read_json("rift_pending.json").get("pending", [])
	_progress = _read_json("rift_progress.json")
	for old in RENAMED_MISSIONS:
		if _progress.has(old) and not _progress.has(RENAMED_MISSIONS[old]):
			_progress[RENAMED_MISSIONS[old]] = _progress[old]
			_progress.erase(old)
	for entry in _pending:
		entry.mission_id = RENAMED_MISSIONS.get(entry.mission_id, entry.mission_id)


func _save() -> void:
	_write_json("rift_pending.json", {pending = _pending})
	_write_json("rift_progress.json", _progress)


func _read_json(file: String) -> Dictionary:
	var path := storage_dir.path_join(file)
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


func _write_json(file: String, data: Dictionary) -> void:
	var f := FileAccess.open(storage_dir.path_join(file), FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar %s (%s)" % [file, FileAccess.get_open_error()])
		return
	f.store_string(JSON.stringify(data))


func _set_status(text: String) -> void:
	status_changed.emit(text)


## UUID v4 con aleatoriedad criptográfica.
static func _uuid_v4() -> String:
	var b := Crypto.new().generate_random_bytes(16)
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	var h := b.hex_encode()
	return "%s-%s-%s-%s-%s" % [h.substr(0, 8), h.substr(8, 4), h.substr(12, 4), h.substr(16, 4), h.substr(20, 12)]
