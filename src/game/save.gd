## Progreso permanente (lo que sobrevive a cada Continue), en JSON local.
class_name SaveData
extends RefCounted

static var path := "user://partida.json"


static func defaults() -> Dictionary:
	return {"frags": 0, "deaths": 0, "wings": false, "walljump": false, "boss": false, "boss2": false,
		"up": {"corazon": 0, "dano": 0, "precarga": 0, "continue": 0},
		"talk": 0, "kira_talk": 0, "kira_frags": 0, "wing_talk": false, "end_talk": false, "seen_intro": false,
		"look": {}, "seen_rooms": [], "shortcuts": []}


static func load_meta() -> Dictionary:
	var m := defaults()
	if not FileAccess.file_exists(path):
		return m
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return m
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return m
	for k in m:
		if data.has(k):
			m[k] = data[k]
	var up: Dictionary = defaults()["up"]
	if typeof(m["up"]) == TYPE_DICTIONARY:
		for k in up:
			up[k] = int(m["up"].get(k, 0))
	m["up"] = up
	m["frags"] = int(m["frags"])
	m["deaths"] = int(m["deaths"])
	m["talk"] = int(m["talk"])
	m["kira_talk"] = int(m["kira_talk"])
	m["kira_frags"] = int(m["kira_frags"])
	m["look"] = _valid_look(m["look"])
	m["seen_rooms"] = m["seen_rooms"].filter(func(id): return id is String) if m["seen_rooms"] is Array else []
	m["shortcuts"] = m["shortcuts"].filter(func(id): return id is String) if m["shortcuts"] is Array else []
	return m


## Un aspecto guardado fuera de rango se descarta: Nexo lo volverá a ofrecer.
static func _valid_look(data) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY or data.is_empty():
		return {}
	var look := {}
	for option: Dictionary in Data.LOOK_OPTIONS:
		var value = data.get(option["id"], 0)  # una fila nueva que la partida aun no tenia empieza en la primera opcion
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or int(value) < 0 or int(value) >= option["opts"].size():
			return {}
		look[option["id"]] = int(value)
	return look


static func save_meta(m: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(m))


static func erase() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
