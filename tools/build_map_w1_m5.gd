## Genera el andamiaje del primer mapa del mundo 1 (misión 5, jefe).
## Uso (una vez; después el mapa se edita en el editor de Godot):
##   godot --headless --path . --script res://tools/build_map_w1_m5.gd
## ATENCIÓN: sobrescribe maps/w1/w1_m5.tscn y maps/w1/w1_ground.tres.
extends SceneTree

const Iso := preload("res://src/view/iso.gd")
const MapScene := preload("res://src/maps/map_scene.gd")

const SIZE := Vector2i(20, 14)
## Camino de 2 casillas: la ruta va por los bordes entre casillas (línea central).
const PATH_WIDTH := 2.0
const ROUTE := [
	Vector2(0.0, 3.0), Vector2(8.0, 3.0), Vector2(8.0, 10.0),
	Vector2(14.0, 10.0), Vector2(14.0, 4.0), Vector2(20.0, 4.0),
]
const BUILD_SPOTS := [Vector2(5.5, 5.5), Vector2(11.5, 6.5), Vector2(16.5, 7.5)]
## Posiciones iniciales de los héroes (sobre el camino).
const HERO_SPAWNS := [Vector2(8.0, 6.0), Vector2(17.0, 4.0)]
const BLOCKS := [Vector2(2.5, 6.5), Vector2(3.5, 6.5), Vector2(10.5, 1.5),
	Vector2(17.5, 10.5), Vector2(18.5, 10.5), Vector2(4.5, 11.5)]
const BUSHES := [Vector2(1.5, 0.5), Vector2(11.5, 12.5), Vector2(18.5, 1.5),
	Vector2(0.5, 8.5), Vector2(15.5, 12.5), Vector2(5.5, 0.5)]

## Coordenadas de atlas en ground_tiles.png.
const GRASS_A := Vector2i(0, 0)
const GRASS_B := Vector2i(1, 0)
const GRASS_FLOWERS := Vector2i(2, 0)
const PATH := Vector2i(3, 0)


func _init() -> void:
	var tileset := _make_tileset()
	ResourceSaver.save(tileset, "res://maps/w1/w1_ground.tres")
	tileset = load("res://maps/w1/w1_ground.tres")

	var root := Node2D.new()
	root.name = "W1M5"
	root.set_script(MapScene)
	root.size = SIZE
	root.path_width = PATH_WIDTH
	root.y_sort_enabled = true

	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tileset
	ground.z_index = -10
	# Godot centra la casilla (0,0) del rombo «diamond down» en (TILE_W/2, TILE_H/2);
	# nuestra proyección pone la esquina superior del mapa en (0,0). Se desplaza la capa
	# media casilla para que ambas coincidan (lo comprueba un test).
	ground.position = Vector2(-Iso.TILE_W * 0.5, 0.0)
	_add(root, ground, root)

	var props := Node2D.new()
	props.name = "Props"
	props.y_sort_enabled = true
	_add(root, props, root)

	var routes := Node2D.new()
	routes.name = "Routes"
	_add(root, routes, root)
	var path := Path2D.new()
	path.name = "Route0"
	path.curve = Curve2D.new()
	for p in ROUTE:
		path.curve.add_point(Iso.to_screen(p))
	_add(routes, path, root)

	var spots := Node2D.new()
	spots.name = "BuildSpots"
	_add(root, spots, root)
	for i in BUILD_SPOTS.size():
		var m := Marker2D.new()
		m.name = "Spot%d" % i
		m.position = Iso.to_screen(BUILD_SPOTS[i])
		_add(spots, m, root)

	var hero_spawns := Node2D.new()
	hero_spawns.name = "HeroSpawns"
	_add(root, hero_spawns, root)
	for i in HERO_SPAWNS.size():
		var m := Marker2D.new()
		m.name = "Hero%d" % i
		m.position = Iso.to_screen(HERO_SPAWNS[i])
		_add(hero_spawns, m, root)

	# El suelo se pinta a partir de los datos de la propia escena.
	var def = root.build_def()
	var path_tiles: Dictionary = def.path_tiles()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			var tile := PATH if path_tiles.has(cell) \
					else (GRASS_FLOWERS if rng.randf() < 0.1 else (GRASS_A if (x + y) % 2 == 0 else GRASS_B))
			ground.set_cell(cell, 0, tile)

	for p in BLOCKS:
		_add(props, _prop("res://art/placeholder/prop_block.png", p, Vector2(0, -16)), root)
	for p in BUSHES:
		_add(props, _prop("res://art/placeholder/prop_bush.png", p, Vector2(0, -12)), root)

	var problems: PackedStringArray = def.validate()
	if not problems.is_empty():
		push_error("Mapa inválido: %s" % ", ".join(problems))
		quit(1)
		return

	var scene := PackedScene.new()
	scene.pack(root)
	var err := ResourceSaver.save(scene, "res://maps/w1/w1_m5.tscn")
	print("w1_m5.tscn guardado (err=%d)" % err)
	root.free()
	quit(err)


func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = Vector2i(int(Iso.TILE_W), int(Iso.TILE_H))
	var src := TileSetAtlasSource.new()
	src.texture = load("res://art/placeholder/ground_tiles.png")
	src.texture_region_size = ts.tile_size
	for i in 4:
		src.create_tile(Vector2i(i, 0))
	ts.add_source(src, 0)
	return ts


func _prop(tex_path: String, logical: Vector2, offset: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = tex_path.get_file().get_basename().to_pascal_case()
	s.texture = load(tex_path)
	s.offset = offset  # el origen del nodo queda en el «pie» del sprite (Y-sort)
	s.position = Iso.to_screen(logical)
	return s


func _add(parent: Node, child: Node, owner_node: Node) -> void:
	parent.add_child(child, true)
	child.owner = owner_node
