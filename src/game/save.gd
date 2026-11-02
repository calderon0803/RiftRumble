## Progreso permanente (lo que sobrevive a cada Continue), en JSON local.
class_name SaveData
extends RefCounted

static var path := "user://partida.json"


static func defaults() -> Dictionary:
	return {"frags": 0, "deaths": 0, "wings": false, "boss": false,
		"up": {"corazon": 0, "filo": 0, "cargado": 0, "continue": 0},
		"talk": 0, "wing_talk": false, "end_talk": false, "seen_intro": false}


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
	return m


static func save_meta(m: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(m))


static func erase() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
