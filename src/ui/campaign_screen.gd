## Pantalla de campaña («La Trama»): mundos, recorrido de misiones con estrellas
## y panel de preparación (elección de héroes) antes de jugar.
##
## Solo muestra y elige; el desbloqueo lo decide CampaignRules y el progreso lo
## da el guardado global (autoload Save). Al jugar, deja la elección en Session.
extends Control

const ContentDB := preload("res://src/content/content_db.gd")
const CampaignRules := preload("res://src/content/campaign_rules.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const StarRow := preload("res://src/ui/star_row.gd")
const GAME_SCENE := "res://src/view/main.tscn"

signal play_requested(mission_id: String, hero_ids: PackedStringArray)

var content
var selected_world := 0

var _worlds: Array = []
var _progress_label: Label
var _world_bar: HBoxContainer
var _world_title: Label
var _world_sub: Label
var _world_rule: Label
var _path: MissionPath
var _prep: PanelContainer
var _prep_box: VBoxContainer
var _prep_mission := ""
var _chosen := PackedStringArray()
var _chosen_towers := PackedStringArray()
var _play_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.build()
	content = ContentDB.load_all()
	_worlds = CampaignRules.worlds_in_order(content)
	Save.ensure_started()
	_build()
	# Abre el mundo más avanzado disponible.
	for i in _worlds.size():
		if CampaignRules.world_unlocked(content, i, _progress_of):
			selected_world = i
	_show_world(selected_world)


func _progress_of(mission_id: String) -> Dictionary:
	return Save.progress_of(mission_id)


# --- Construcción de la interfaz ------------------------------------------------

func _build() -> void:
	var bg := Background.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var header := HBoxContainer.new()
	col.add_child(header)
	var title := Label.new()
	title.text = "La Trama"
	title.theme_type_variation = &"TitleLabel"
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_progress_label = Label.new()
	_progress_label.theme_type_variation = &"StatLabel"
	header.add_child(_progress_label)

	_world_bar = HBoxContainer.new()
	_world_bar.add_theme_constant_override("separation", 6)
	col.add_child(_world_bar)
	for i in _worlds.size():
		var w: WorldDef = _worlds[i]
		var b := Button.new()
		b.text = "%d · %s" % [w.order, w.display_name]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.add_theme_color_override("font_color", w.color)
		b.pressed.connect(_show_world.bind(i))
		_world_bar.add_child(b)

	var info := VBoxContainer.new()
	col.add_child(info)
	_world_title = Label.new()
	_world_title.theme_type_variation = &"HeaderLabel"
	info.add_child(_world_title)
	_world_sub = Label.new()
	info.add_child(_world_sub)
	_world_rule = Label.new()
	_world_rule.add_theme_color_override("font_color", UiTheme.GOLD)
	info.add_child(_world_rule)

	_path = MissionPath.new()
	_path.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_path.mission_pressed.connect(_open_prep)
	col.add_child(_path)

	# Panel de preparación (centrado, encima de todo).
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_prep = PanelContainer.new()
	_prep.visible = false
	center.add_child(_prep)
	_prep_box = VBoxContainer.new()
	_prep_box.add_theme_constant_override("separation", 8)
	_prep_box.custom_minimum_size = Vector2(460, 0)
	_prep.add_child(_prep_box)


func _show_world(index: int) -> void:
	selected_world = index
	_prep.visible = false
	var w: WorldDef = _worlds[index]
	var unlocked := CampaignRules.world_unlocked(content, index, _progress_of)
	_world_title.text = w.display_name if unlocked else "%s · bloqueado" % w.display_name
	_world_title.add_theme_color_override("font_color", w.color)
	_world_sub.text = w.subtitle
	_world_rule.text = w.rule_text
	for i in _world_bar.get_child_count():
		var b: Button = _world_bar.get_child(i)
		var open := CampaignRules.world_unlocked(content, i, _progress_of)
		# Seleccionado: resaltado; bloqueado: atenuado (se puede consultar, no jugar).
		b.theme_type_variation = &"AccentButton" if i == index else &""
		b.modulate = Color.WHITE if open else Color(1, 1, 1, 0.4)
		b.tooltip_text = _worlds[i].display_name + ("" if open else " — se abre al completar el mundo anterior")
	var nodes := []
	for slot in w.mission_slots.size():
		var id := w.mission_slots[slot]
		var mission: MissionDef = content.missions.get(StringName(id))
		nodes.append({
			id = id, number = slot + 1, boss = slot == w.mission_slots.size() - 1,
			name = mission.display_name if mission else (w.slot_names[slot] if slot < w.slot_names.size() else "?"),
			state = CampaignRules.mission_state(content, index, slot, _progress_of),
			stars = int(_progress_of(id).get("best_stars", 0)),
		})
	_path.color = w.color
	_path.set_nodes(nodes)
	_update_header()


func _update_header() -> void:
	var total_stars := 0
	for w: WorldDef in _worlds:
		for id in w.mission_slots:
			total_stars += int(_progress_of(id).get("best_stars", 0))
	_progress_label.text = "%d ★ · %d fragmentos" % [total_stars, Save.shards()]


# --- Preparación de la misión ----------------------------------------------------

func _open_prep(mission_id: String) -> void:
	var mission: MissionDef = content.missions[StringName(mission_id)]
	_prep_mission = mission_id
	for c in _prep_box.get_children():
		c.queue_free()
	var w: WorldDef = _worlds[selected_world]
	_label(mission.display_name, &"HeaderLabel")
	_label("%s · %d oleadas" % [w.display_name, mission.waves.size()], &"")
	var p := _progress_of(mission_id)
	if p.get("victories", 0) > 0:
		var stars := StarRow.new()
		stars.radius = 12.0
		stars.custom_minimum_size = Vector2(90, 28)
		stars.set_stars(int(p.best_stars))
		_prep_box.add_child(stars)

	# Equipo de torres: las que tiene el jugador (y permite la misión), hasta max_towers.
	var available := PackedStringArray()
	for id in Save.owned_towers():
		if content.towers.has(StringName(id)) and (mission.towers.is_empty() or id in mission.towers):
			available.append(id)
	_label("Elige tus torres (hasta %d)" % mission.max_towers, &"MenuTitle")
	_chosen_towers = PackedStringArray()
	for id in Save.last_towers():
		if id in available and _chosen_towers.size() < mission.max_towers:
			_chosen_towers.append(id)
	for id in available:
		if _chosen_towers.size() < mission.max_towers and not id in _chosen_towers:
			_chosen_towers.append(id)
	var towers := HBoxContainer.new()
	towers.add_theme_constant_override("separation", 6)
	_prep_box.add_child(towers)
	for id in available:
		var def: TowerDef = content.towers[StringName(id)]
		var tb := Button.new()
		tb.toggle_mode = true
		tb.focus_mode = Control.FOCUS_NONE
		tb.icon = def.sprite
		tb.expand_icon = true
		tb.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tb.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		tb.text = def.display_name
		tb.clip_text = true
		tb.custom_minimum_size = Vector2(96, 92)
		tb.theme_type_variation = &"SpotButton"
		tb.button_pressed = id in _chosen_towers
		tb.tooltip_text = def.description
		tb.toggled.connect(_toggle_tower.bind(id, tb))
		towers.add_child(tb)

	var needed := mission.heroes.size()
	_label("Elige %d héroes" % needed, &"MenuTitle")
	var owned := Save.owned_heroes()
	_chosen = PackedStringArray()
	for id in Save.last_heroes():
		if id in owned and _chosen.size() < needed:
			_chosen.append(id)
	for id in owned:
		if _chosen.size() < needed and not id in _chosen:
			_chosen.append(id)
	var heroes := HBoxContainer.new()
	heroes.add_theme_constant_override("separation", 6)
	_prep_box.add_child(heroes)
	for id in owned:
		var def: HeroDef = content.heroes.get(StringName(id))
		if def == null:
			continue
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.icon = _first_frame(def.sprite, def.hframes)
		b.expand_icon = true
		b.text = "%s\n%s" % [def.display_name, def.title]
		b.custom_minimum_size = Vector2(220, 64)
		b.add_theme_color_override("font_color", def.color)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.button_pressed = id in _chosen
		b.tooltip_text = def.description
		b.toggled.connect(_toggle_hero.bind(id))
		heroes.add_child(b)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_prep_box.add_child(row)
	_play_button = Button.new()
	_play_button.text = "¡A jugar!"
	_play_button.theme_type_variation = &"AccentButton"
	_play_button.custom_minimum_size = Vector2(200, 52)
	_play_button.focus_mode = Control.FOCUS_NONE
	_play_button.pressed.connect(_play)
	row.add_child(_play_button)
	var close := Button.new()
	close.text = "Cerrar"
	close.custom_minimum_size = Vector2(120, 52)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func(): _prep.visible = false)
	row.add_child(close)
	_prep.visible = true
	_update_play()


func _toggle_hero(pressed: bool, id: String) -> void:
	var idx := _chosen.find(id)
	if pressed and idx < 0:
		_chosen.append(id)
	elif not pressed and idx >= 0:
		_chosen.remove_at(idx)
	_update_play()


func _toggle_tower(pressed: bool, id: String, button: Button) -> void:
	var max_towers: int = content.missions[StringName(_prep_mission)].max_towers
	var idx := _chosen_towers.find(id)
	if pressed and idx < 0:
		if _chosen_towers.size() >= max_towers:
			button.set_pressed_no_signal(false)  # equipo lleno
			return
		_chosen_towers.append(id)
	elif not pressed and idx >= 0:
		_chosen_towers.remove_at(idx)
	_update_play()


func _update_play() -> void:
	var needed: int = content.missions[StringName(_prep_mission)].heroes.size()
	var heroes_ok := _chosen.size() == needed
	var towers_ok := not _chosen_towers.is_empty()
	_play_button.disabled = not (heroes_ok and towers_ok)
	if not heroes_ok:
		_play_button.text = "Elige %d héroes (%d/%d)" % [needed, _chosen.size(), needed]
	elif not towers_ok:
		_play_button.text = "Elige al menos 1 torre"
	else:
		_play_button.text = "¡A jugar!"


func _play() -> void:
	Session.mission_id = _prep_mission
	Session.hero_ids = _chosen
	Session.tower_ids = _chosen_towers
	Save.set_last_heroes(_chosen)
	Save.set_last_towers(_chosen_towers)
	play_requested.emit(_prep_mission, _chosen)
	get_tree().change_scene_to_file(GAME_SCENE)


## Primer fotograma de una hoja de animación (para iconos).
static func _first_frame(sheet: Texture2D, hframes: int) -> Texture2D:
	if sheet == null or hframes <= 1:
		return sheet
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0, 0, sheet.get_width() / float(hframes), sheet.get_height())
	return atlas


func _label(text: String, variation: StringName) -> void:
	var l := Label.new()
	l.text = text
	if variation != &"":
		l.theme_type_variation = variation
	_prep_box.add_child(l)


# --- Componentes visuales -------------------------------------------------------

## Fondo: degradado oscuro con «hilos» de la Trama.
class Background extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("141022"))
		var cols := [Color("ffb840"), Color("a46bff"), Color("c0283c"), Color("ff3fd0"), Color("7dff8a"), Color("6ff3ff")]
		for i in 6:
			var pts := PackedVector2Array()
			for k in 33:
				var x := size.x * k / 32.0
				pts.append(Vector2(x, size.y * (0.25 + i * 0.12) + sin(k * 0.45 + i * 1.3) * 24.0))
			draw_polyline(pts, Color(cols[i], 0.10), 3.0, true)


## Recorrido de misiones de un mundo: nodos en zigzag unidos por un hilo.
class MissionPath extends Control:
	signal mission_pressed(mission_id: String)
	const StarRowScript := preload("res://src/ui/star_row.gd")
	var color := Color.WHITE
	var _nodes: Array = []
	var _widgets: Array = []

	func set_nodes(nodes: Array) -> void:
		_nodes = nodes
		for w in _widgets:
			w.queue_free()
		_widgets.clear()
		for n in nodes:
			var box := VBoxContainer.new()
			box.alignment = BoxContainer.ALIGNMENT_CENTER
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(76, 76)
			b.text = "JEFE" if n.boss else str(n.number)
			var locked: bool = n.state == CampaignRules.State.LOCKED or n.state == CampaignRules.State.PLANNED
			b.disabled = locked
			if not locked:
				b.pressed.connect(func(): mission_pressed.emit(n.id))
			if n.state == CampaignRules.State.AVAILABLE:
				b.theme_type_variation = &"AccentButton"
			elif locked:
				b.theme_type_variation = &"LockedNode"
			box.add_child(b)
			var name := Label.new()
			name.text = n.name if n.state != CampaignRules.State.PLANNED else "%s\n(en construcción)" % n.name
			name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name.custom_minimum_size = Vector2(150, 0)
			name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name.modulate = Color(1, 1, 1, 0.45) if locked else Color.WHITE
			box.add_child(name)
			var stars := StarRowScript.new()
			stars.radius = 9.0
			stars.custom_minimum_size = Vector2(66, 20)
			stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			stars.set_stars(n.stars)
			stars.visible = n.state == CampaignRules.State.COMPLETED
			box.add_child(stars)
			add_child(box)
			_widgets.append(box)
		_layout()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_layout()

	func _node_center(i: int) -> Vector2:
		var n := maxi(_nodes.size(), 1)
		var x := size.x * (i + 0.5) / n
		var y := size.y * (0.38 if i % 2 == 0 else 0.62)
		return Vector2(x, y)

	func _layout() -> void:
		for i in _widgets.size():
			var w: Control = _widgets[i]
			w.size = w.get_combined_minimum_size()
			w.position = _node_center(i) - Vector2(w.size.x * 0.5, 38)
		queue_redraw()

	func _draw() -> void:
		for i in range(1, _nodes.size()):
			var done: bool = _nodes[i - 1].state == CampaignRules.State.COMPLETED
			draw_line(_node_center(i - 1), _node_center(i), Color(color, 0.8 if done else 0.25), 4.0 if done else 2.0, true)
