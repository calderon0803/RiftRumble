## Partida guardada en el PC (JSON en user://). Solo local.
class_name SaveGame
extends RefCounted

const DEFAULT_PATH := "user://partida.json"
## Partida con la que trabajan el título y el mundo (los tests la cambian para no
## tocar la de verdad).
static var active_path := DEFAULT_PATH


static func load_from(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


static func save_to(path: String, data: Dictionary) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


static func erase(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
