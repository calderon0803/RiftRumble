## Genera el andamiaje de los mapas w1_m1…w1_m4 del mundo 1.
## Uso (una vez por mapa; después se editan en el editor de Godot):
##   godot --headless --path . --script res://tools/build_maps_w1.gd -- [w1_m1 w1_m3 …]
## Sin argumentos genera los cuatro. ATENCIÓN: sobrescribe esos .tscn.
## (w1_m5 tiene su propio generador y no se toca aquí.)
extends SceneTree

const Iso := preload("res://src/view/iso.gd")
const MapScene := preload("res://src/maps/map_scene.gd")

## Cada mapa: tamaño, ancho del camino, rutas (casillas, por la línea central),
## posiciones de construcción, inicio de héroes y elementos interactivos.
const SPECS := {
	"w1_m1": {
		size = Vector2i(16, 10), width = 2.0,
		routes = [[Vector2(0, 3), Vector2(10, 3), Vector2(10, 8), Vector2(16, 8)]],
		spots = [Vector2(6.5, 5.5), Vector2(12.5, 5.5)],
		heroes = [Vector2(10, 5)],
		objects = [],
		decor = 8,
	},
	"w1_m2": {
		size = Vector2i(18, 12), width = 2.0,
		routes = [[Vector2(0, 6), Vector2(6, 6), Vector2(6, 2), Vector2(12, 2), Vector2(12, 9), Vector2(18, 9)]],
		spots = [Vector2(3.5, 3.5), Vector2(9.5, 4.5), Vector2(15.5, 6.5)],
		heroes = [Vector2(6, 4), Vector2(12, 6)],
		objects = [],
		decor = 10,
	},
	"w1_m3": {
		size = Vector2i(20, 14), width = 2.0,
		routes = [
			[Vector2(0, 3), Vector2(16, 3), Vector2(16, 11), Vector2(4, 11), Vector2(4, 14)],
			# Atajo: baja antes por x = 8 (cerrado por el bloque «Atajo»).
			[Vector2(0, 3), Vector2(8, 3), Vector2(8, 11), Vector2(4, 11), Vector2(4, 14)],
		],
		spots = [Vector2(12.5, 6.5), Vector2(4.5, 6.5), Vector2(18.5, 7.5), Vector2(10.5, 7.5)],
		heroes = [Vector2(12, 3), Vector2(16, 7)],
		objects = [
			{name = "Atajo", kind = "block", pos = Vector2(8, 7),
				meta = {hp = 30.0, reward_gold = 0, opens_route = 1, opens_spot = 3}},
			{name = "Sorpresa1", kind = "block", pos = Vector2(12.5, 4.5), meta = {hp = 15.0, reward_gold = 30}},
			{name = "Sorpresa2", kind = "block", pos = Vector2(17.5, 11.5), meta = {hp = 15.0, reward_gold = 30}},
		],
		decor = 10,
	},
	"w1_m4": {
		size = Vector2i(20, 14), width = 2.0,
		routes = [
			[Vector2(0, 3), Vector2(10, 3), Vector2(10, 9), Vector2(20, 9)],
			[Vector2(14, 0), Vector2(14, 6), Vector2(10, 6), Vector2(10, 9), Vector2(20, 9)],
		],
		spots = [Vector2(4.5, 5.5), Vector2(12.5, 3.5), Vector2(6.5, 6.5), Vector2(15.5, 11.5)],
		heroes = [Vector2(10, 7), Vector2(16, 9)],
		objects = [
			{name = "Plataforma", kind = "platform", pos = Vector2(6.5, 6.5),
				meta = {spot = 2, to = Vector2(17.5, 5.5), period = 16.0}},
		],
		decor = 10,
	},
}

const GRASS_A := Vector2i(0, 0)
const GRASS_B := Vector2i(1, 0)
const GRASS_FLOWERS := Vector2i(2, 0)
const PATH := Vector2i(3, 0)


func _init() -> void:
	var wanted := OS.get_cmdline_user_args()
	if wanted.is_empty():
		wanted = PackedStringArray(SPECS.keys())
	var tileset: TileSet = load("res://maps/w1/w1_ground.tres")
	var failed := false
	for id in wanted:
		if not SPECS.has(id):
			push_error("Mapa desconocido: %s" % id)
			failed = true
			continue
		failed = not _build(id, SPECS[id], tileset) or failed
	quit(1 if failed else 0)


func _build(id: String, spec: Dictionary, tileset: TileSet) -> bool:
	var root := Node2D.new()
	root.name = id.to_upper().replace("_", "")
	root.set_script(MapScene)
	root.size = spec.size
	root.path_width = spec.width
	root.y_sort_enabled = true

	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tileset
	ground.z_index = -10
	ground.position = Vector2(-Iso.TILE_W * 0.5, 0.0)  # alinea la rejilla de Godot con Iso
	_add(root, ground, root)

	var props := Node2D.new()
	props.name = "Props"
	props.y_sort_enabled = true
	_add(root, props, root)

	var routes := _group(root, "Routes")
	for r in spec.routes.size():
		var path := Path2D.new()
		path.name = "Route%d" % r
		path.curve = Curve2D.new()
		for p in spec.routes[r]:
			path.curve.add_point(Iso.to_screen(p))
		_add(routes, path, root)

	var spots := _group(root, "BuildSpots")
	for i in spec.spots.size():
		_add(spots, _marker("Spot%d" % i, spec.spots[i]), root)
	var heroes := _group(root, "HeroSpawns")
	for i in spec.heroes.size():
		_add(heroes, _marker("Hero%d" % i, spec.heroes[i]), root)
	var objects := _group(root, "Objects")
	for o in spec.objects:
		var m := _marker(o.name, o.pos)
		m.set_meta(&"kind", o.kind)
		for k in o.meta:
			m.set_meta(StringName(k), o.meta[k])
		_add(objects, m, root)

	var def = root.build_def()
	var path_tiles: Dictionary = def.path_tiles()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	for y in spec.size.y:
		for x in spec.size.x:
			var cell := Vector2i(x, y)
			var tile := PATH if path_tiles.has(cell) \
					else (GRASS_FLOWERS if rng.randf() < 0.1 else (GRASS_A if (x + y) % 2 == 0 else GRASS_B))
			ground.set_cell(cell, 0, tile)

	# Decorado: casillas libres, lejos de rutas, plataformas, héroes y elementos.
	var busy: Array = []
	busy.append_array(spec.spots)
	busy.append_array(spec.heroes)
	for o in spec.objects:
		busy.append(o.pos)
		if o.meta.has("to"):
			busy.append(o.meta.to)
	var placed := 0
	var tries := 0
	while placed < spec.decor and tries < 500:
		tries += 1
		var cell := Vector2i(rng.randi_range(0, spec.size.x - 1), rng.randi_range(0, spec.size.y - 1))
		var c := Vector2(cell) + Vector2(0.5, 0.5)
		if path_tiles.has(cell) or _near_any(c, busy, 1.6) or _near_any(c, _all_route_points(def), 1.4):
			continue
		busy.append(c)
		var block := rng.randf() < 0.4
		_add(props, _prop("res://art/placeholder/prop_block.png" if block else "res://art/placeholder/prop_bush.png",
				c, Vector2(0, -16) if block else Vector2(0, -12)), root)
		placed += 1

	var problems: PackedStringArray = def.validate()
	if not problems.is_empty():
		push_error("%s inválido: %s" % [id, ", ".join(problems)])
		root.free()
		return false
	var scene := PackedScene.new()
	scene.pack(root)
	var err := ResourceSaver.save(scene, "res://maps/w1/%s.tscn" % id)
	print("%s.tscn guardado (err=%d)" % [id, err])
	root.free()
	return err == OK


func _all_route_points(def) -> Array:
	var pts := []
	for r in def.routes:
		for i in range(1, r.size()):
			var n := int(r[i - 1].distance_to(r[i]) * 2.0)
			for k in n + 1:
				pts.append(r[i - 1].lerp(r[i], float(k) / maxf(n, 1)))
	return pts


static func _near_any(p: Vector2, pts: Array, radius: float) -> bool:
	for q in pts:
		if p.distance_to(q) < radius:
			return true
	return false


func _group(root: Node, name: String) -> Node2D:
	var n := Node2D.new()
	n.name = name
	_add(root, n, root)
	return n


func _marker(name: String, logical: Vector2) -> Marker2D:
	var m := Marker2D.new()
	m.name = name
	m.position = Iso.to_screen(logical)
	return m


func _prop(tex_path: String, logical: Vector2, offset: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = tex_path.get_file().get_basename().to_pascal_case()
	s.texture = load(tex_path)
	s.offset = offset
	s.position = Iso.to_screen(logical)
	return s


func _add(parent: Node, child: Node, owner_node: Node) -> void:
	parent.add_child(child, true)
	child.owner = owner_node
