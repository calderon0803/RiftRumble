## Catálogo de contenido: carga todas las definiciones de res://content/.
## Añadir una torre o un enemigo nuevo = añadir su .tres a la carpeta; no hay
## que tocar este archivo ni los sistemas.
extends RefCounted

const ROOT := "res://content/"

var towers := {}   # StringName → TowerDef
var enemies := {}  # StringName → EnemyDef
var missions := {}  # StringName → MissionDef


static func load_all() -> RefCounted:
	var db = new()
	db.towers = _load_dir(ROOT + "towers/")
	db.enemies = _load_dir(ROOT + "enemies/")
	db.missions = _load_dir(ROOT + "missions/")
	return db


static func _load_dir(path: String) -> Dictionary:
	var out := {}
	# list_directory resuelve los nombres remapeados de las builds exportadas.
	for file in ResourceLoader.list_directory(path):
		if not (file.ends_with(".tres") or file.ends_with(".res")):
			continue
		var res: Resource = load(path + file)
		var id: StringName = res.get(&"id")
		assert(id != &"", "%s no tiene id" % (path + file))
		assert(not out.has(id), "id duplicado %s en %s" % [id, path])
		out[id] = res
	return out
