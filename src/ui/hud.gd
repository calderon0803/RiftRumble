## Interfaz de la partida. Muestra el estado y emite peticiones; NUNCA modifica
## la simulación (el controlador traduce las señales a comandos validados).
extends CanvasLayer

const SimWorld := preload("res://src/sim/sim_world.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

signal build_requested(spot: int, tower_id: StringName)
signal upgrade_requested(spot: int)
signal sell_requested(spot: int)
signal start_wave_requested
signal pause_toggled
signal restart_requested
signal close_panel_requested
signal hero_selected(index: int)
signal ability_requested(index: int)

var world: SimWorld
var content
var selected_spot := -1

var _gold: Label
var _lives: Label
var _wave: Label
var _wave_button: Button
var _pause_button: Button
var _panel: PanelContainer
var _panel_box: VBoxContainer
var _overlay: PanelContainer
var _overlay_label: Label
var _overlay_stars: StarRow
var _overlay_stats: GridContainer
var _boss_panel: PanelContainer
var _boss_name: Label
var _boss_bar: ProgressBar
var _boss_note: Label
var _banner: Label
var _cloud_label: Label
var _cloud_status := ""
var _reward_text := ""
var _banner_t := 0.0
var _debug: Label
var _hint: Label
var _hero_box: VBoxContainer
var _hero_cards: Array = []  # [{name: Button, ability: Button, panel: PanelContainer}]
var _panel_signature := ""


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.build()
	add_child(root)

	# --- Barra superior -------------------------------------------------------
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 8
	top.offset_right = -8
	top.offset_top = 8
	root.add_child(top)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 18)
	top.add_child(bar)
	_gold = _stat(bar, "ui_gold")
	_lives = _stat(bar, "ui_lives")
	_wave = _stat(bar, "ui_wave")
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_wave_button = _button(bar, "Lanzar oleada", start_wave_requested.emit)
	_wave_button.theme_type_variation = &"AccentButton"
	_pause_button = _button(bar, "Pausa", pause_toggled.emit)
	_button(bar, "Reiniciar", restart_requested.emit)

	# --- Menú contextual sobre la plataforma (construir / mejorar / vender) ----------
	# Se coloca cada frame encima de la posición seleccionada (sigue a la cámara).
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"SpotMenu"
	_panel.visible = false
	root.add_child(_panel)
	_panel_box = VBoxContainer.new()
	_panel_box.add_theme_constant_override("separation", 4)
	_panel.add_child(_panel_box)

	# --- Resultado -----------------------------------------------------------
	var overlay_center := CenterContainer.new()
	overlay_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay_center)
	_overlay = PanelContainer.new()
	_overlay.visible = false
	overlay_center.add_child(_overlay)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 12)
	_overlay.add_child(ov)
	_overlay_label = Label.new()
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_label.theme_type_variation = &"TitleLabel"
	ov.add_child(_overlay_label)
	_overlay_stars = StarRow.new()
	_overlay_stars.custom_minimum_size = Vector2(180, 52)
	_overlay_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ov.add_child(_overlay_stars)
	_overlay_stats = GridContainer.new()
	_overlay_stats.columns = 2
	_overlay_stats.add_theme_constant_override("h_separation", 24)
	ov.add_child(_overlay_stats)
	_cloud_label = Label.new()
	_cloud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cloud_label.add_theme_color_override("font_color", Color("6ff3ff"))
	_cloud_label.add_theme_font_size_override("font_size", 13)
	ov.add_child(_cloud_label)
	_button(ov, "Jugar otra vez", restart_requested.emit)

	# --- Barra del jefe (arriba, centrada) ---------------------------------------
	# A la derecha, bajo la barra superior: no tapa la entrada de los enemigos.
	_boss_panel = PanelContainer.new()
	_boss_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_boss_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_boss_panel.offset_right = -8
	_boss_panel.offset_top = 80
	_boss_panel.visible = false
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_boss_panel)
	var bb := VBoxContainer.new()
	_boss_panel.add_child(bb)
	_boss_name = Label.new()
	_boss_name.theme_type_variation = &"HeaderLabel"
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bb.add_child(_boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(260, 14)
	_boss_bar.show_percentage = false
	bb.add_child(_boss_bar)
	_boss_note = Label.new()
	_boss_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_note.add_theme_color_override("font_color", Color("ff8be0"))
	bb.add_child(_boss_note)

	# --- Cartel de oleada --------------------------------------------------------
	_banner = Label.new()
	_banner.theme_type_variation = &"TitleLabel"
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	root.add_child(_banner)

	# --- Indicación de objetivo (habilidades) -----------------------------------
	_hint = Label.new()
	_hint.theme_type_variation = &"HeaderLabel"
	_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.offset_top = 84
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hint)

	# --- Tarjetas de héroe (abajo a la izquierda) ---------------------------------
	_hero_box = VBoxContainer.new()
	_hero_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hero_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hero_box.offset_left = 8
	_hero_box.offset_bottom = -26
	_hero_box.add_theme_constant_override("separation", 6)
	root.add_child(_hero_box)

	# --- Depuración (FPS, simulación) -------------------------------------------
	_debug = Label.new()
	_debug.theme_type_variation = &"DebugLabel"
	_debug.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_debug.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_debug.offset_left = 10
	_debug.offset_bottom = -6
	_debug.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_debug)


func bind(new_world: SimWorld, content_db) -> void:
	world = new_world
	content = content_db
	selected_spot = -1
	_panel_signature = ""
	_panel.visible = false
	_overlay.visible = false
	_banner.visible = false
	_boss_panel.visible = false
	_reward_text = ""
	_update_cloud_label()
	_build_hero_cards()


## Estado del guardado (servicio de persistencia).
func set_cloud_status(text: String) -> void:
	_cloud_status = text
	_update_cloud_label()


## Respuesta del servidor a un resultado: recompensa en fragmentos.
func show_reward(response: Dictionary) -> void:
	if response.get("rejected", false):
		_reward_text = "El servidor no aceptó el resultado"
	elif response.get("duplicate", false):
		_reward_text = ""
	elif int(response.get("reward", 0)) > 0:
		_reward_text = "+%d fragmentos%s · total %d" % [response.reward,
			" (¡primera victoria!)" if response.get("first_clear", false) else "", response.get("shards", 0)]
	_update_cloud_label()


func _update_cloud_label() -> void:
	if _cloud_label:
		_cloud_label.text = "
".join([_reward_text, _cloud_status].filter(func(t): return t != ""))


## Eventos de la simulación relevantes para la interfaz (carteles).
func on_events(events: Array[Dictionary]) -> void:
	for ev in events:
		match ev.type:
			&"wave_started":
				var last: bool = ev.index + 1 == world.waves_total()
				_show_banner("OLEADA FINAL" if last else "OLEADA %d/%d" % [ev.index + 1, world.waves_total()])
			&"early_call_bonus":
				_show_banner("+%d oro por adelantarte" % ev.gold)
			&"core_dropped":
				_show_banner("¡Destruye el núcleo!")


func _show_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = true
	_banner_t = 2.2


func _process(delta: float) -> void:
	if _banner_t > 0.0:
		_banner_t -= delta
		_banner.modulate.a = clampf(_banner_t / 0.6, 0.0, 1.0)
		_banner.visible = _banner_t > 0.0


func _build_hero_cards() -> void:
	for c in _hero_box.get_children():
		c.queue_free()
	_hero_cards.clear()
	for i in world.heroes.heroes.size():
		var def: HeroDef = world.heroes.heroes[i].def
		var panel := PanelContainer.new()
		_hero_box.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		panel.add_child(row)
		var name_btn := _button(row, "%d · %s" % [i + 1, def.display_name], hero_selected.emit.bind(i))
		name_btn.custom_minimum_size = Vector2(130, 48)
		name_btn.add_theme_color_override("font_color", def.color)
		name_btn.tooltip_text = "%s — %s" % [def.title, def.description]
		var ability := _button(row, def.ability_name, ability_requested.emit.bind(i))
		ability.custom_minimum_size = Vector2(170, 48)
		ability.theme_type_variation = &"AccentButton"
		ability.tooltip_text = def.ability_description
		_hero_cards.append({name = name_btn, ability = ability, panel = panel})


## Posición del menú: encima de este punto del mundo (pie de la plataforma).
var _spot_world_pos := Vector2.ZERO


func select_spot(spot: int, world_pos := Vector2.ZERO) -> void:
	if spot >= 0:
		_spot_world_pos = world_pos
	selected_spot = spot
	_panel_signature = ""  # fuerza a reconstruir el panel


## Refresca textos y estados de botones. Barato: solo toca lo que cambia.
func refresh(paused: bool, debug_text: String, selected_hero := -1, targeting_hero := -1) -> void:
	_refresh_heroes(selected_hero, targeting_hero)
	_gold.text = "Oro %d" % world.gold
	_lives.text = "Vida %d" % maxi(world.base_hp, 0)
	_wave.text = "Oleada %d/%d" % [world.wave_index + 1, world.waves_total()]
	_wave_button.disabled = world.wave_active or world.is_over() \
			or world.wave_index + 1 >= world.waves_total()
	if world.wave_active:
		_wave_button.text = "Oleada en curso"
	elif world.next_wave_ticks > 0:
		var secs := ceili(world.next_wave_ticks / float(SimWorld.TICK_RATE))
		_wave_button.text = "Siguiente en %d s (+%d oro)" % [secs, ceili(secs * SimWorld.EARLY_CALL_GOLD_PER_SECOND)]
	else:
		_wave_button.text = "Lanzar oleada"
	_refresh_boss()
	_pause_button.text = "Seguir" if paused else "Pausa"
	_debug.text = debug_text
	_refresh_panel()
	_place_spot_menu()
	if world.is_over() and not _overlay.visible:
		_show_results()


func _show_results() -> void:
	_overlay.visible = true
	_panel.visible = false
	_boss_panel.visible = false
	var won := world.outcome == SimWorld.Outcome.VICTORY
	_overlay_label.text = "¡VICTORIA!" if won else "La base ha caído"
	_overlay_stars.stars = world.stars()
	_overlay_stars.queue_redraw()
	for c in _overlay_stats.get_children():
		c.queue_free()
	var st: Dictionary = world.stats
	var secs := world.tick / SimWorld.TICK_RATE
	var rows := [
		["Oleadas", "%d/%d" % [world.wave_index + 1 if won else world.wave_index, world.waves_total()]],
		["Vida de la base", "%d/%d" % [world.base_hp, world.mission.base_hp]],
		["Tiempo", "%d:%02d" % [secs / 60, secs % 60]],
		["Enemigos eliminados", str(st.kills)],
		["Enemigos que llegaron", str(st.leaks)],
		["Torres construidas", str(st.towers_built)],
		["Oro ganado / gastado", "%d / %d" % [st.gold_earned, st.gold_spent]],
		["Oro por adelantar oleadas", str(st.early_bonus)],
		["Habilidades usadas", str(st.abilities_used)],
		["Héroes caídos", str(st.hero_kos)],
	]
	for r in rows:
		for k in 2:
			var l := Label.new()
			l.text = r[k]
			if k == 1:
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				l.add_theme_color_override("font_color", UiTheme.GOLD)
			_overlay_stats.add_child(l)


## Barra del jefe: visible mientras haya un jefe (o su núcleo) en el mapa.
func _refresh_boss() -> void:
	var boss := -1
	var core := -1
	for i in world.e_alive.size():
		if world.e_alive[i] == 0:
			continue
		var def: EnemyDef = world.e_def[i]
		if def and def.is_boss:
			boss = i
		elif world.e_revive_into[i] != null and world.e_revive_into[i].is_boss:
			core = i
	_boss_panel.visible = (boss >= 0 or core >= 0) and not world.is_over()
	if boss >= 0:
		var def: EnemyDef = world.e_def[boss]
		_boss_name.text = def.display_name
		_boss_bar.max_value = def.hp
		_boss_bar.value = world.e_hp[boss]
		_boss_note.text = "" if world.e_can_revive[boss] == 1 else "Sin núcleo: ¡último aliento!"
		_boss_note.visible = _boss_note.text != ""
	elif core >= 0:
		var def: EnemyDef = world.e_revive_into[core]
		_boss_name.text = "%s · núcleo" % def.display_name
		_boss_bar.max_value = world.e_max_hp[core]
		_boss_bar.value = world.e_hp[core]
		_boss_note.text = "Destrúyelo antes de %d s o volverá" % ceili(world.e_timer[core] / float(SimWorld.TICK_RATE))
		_boss_note.visible = true


func _refresh_heroes(selected_hero: int, targeting_hero: int) -> void:
	for i in _hero_cards.size():
		var h: Dictionary = world.heroes.heroes[i]
		var def: HeroDef = h.def
		var card: Dictionary = _hero_cards[i]
		var cd_s := ceili(h.ability_cd / float(SimWorld.TICK_RATE))
		var dead: bool = h.dead_ticks > 0
		var text := def.ability_name if cd_s == 0 else "%s (%d s)" % [def.ability_name, cd_s]
		if def.charge_max > 0:
			text += " · carga %d/%d" % [h.charge, def.charge_max]
		if dead:
			text = "Caído · vuelve en %d s" % ceili(h.dead_ticks / float(SimWorld.TICK_RATE))
		if card.ability.text != text:
			card.ability.text = text
		card.ability.disabled = cd_s > 0 or dead or world.is_over()
		card.panel.modulate = Color(1.25, 1.25, 1.25) if i == selected_hero else Color.WHITE
	if targeting_hero >= 0:
		var def: HeroDef = world.heroes.heroes[targeting_hero].def
		var what := "la salida del portal" if def.ability_kind == HeroDef.ABILITY_PORTAL else "la dirección del ataque"
		_hint.text = "%s: toca %s (alcance %d)" % [def.ability_name, what, roundi(def.ability_range)]
	elif selected_hero >= 0:
		_hint.text = "Toca el camino para mover a %s · tócalo de nuevo para soltarlo" % 				world.heroes.heroes[selected_hero].def.display_name
	else:
		_hint.text = ""


func _refresh_panel() -> void:
	if selected_spot < 0 or world.is_over():
		_panel.visible = false
		return
	var t := world.tower_at(selected_spot)
	# Firma del contenido: solo se reconstruye si cambia algo relevante (qué se
	# puede pagar, no el oro exacto: si no, cada baja reconstruiría los botones).
	var affordable := ""
	if t.is_empty():
		for id in world.mission.towers:
			affordable += "1" if world.gold >= content.towers[StringName(id)].cost[0] else "0"
	else:
		affordable = str(world.gold >= world.upgrade_cost(selected_spot))
	var sig := "%d|%s|%d|%s" % [selected_spot, t.get("level", 0), t.size(), affordable]
	if sig == _panel_signature:
		return
	_panel_signature = sig
	for c in _panel_box.get_children():
		c.queue_free()
	_panel.visible = true
	if t.is_empty():
		_build_options()
	else:
		_tower_options(t)


## Coloca el menú centrado encima de la plataforma, sin salirse de la pantalla.
func _place_spot_menu() -> void:
	if not _panel.visible:
		return
	var screen := get_viewport().get_canvas_transform() * _spot_world_pos
	var menu_size := _panel.get_combined_minimum_size()
	_panel.size = menu_size
	var pos := screen - Vector2(menu_size.x * 0.5, menu_size.y + 22.0)
	var vp := get_viewport().get_visible_rect().size
	pos.x = clampf(pos.x, 6.0, vp.x - menu_size.x - 6.0)
	pos.y = clampf(pos.y, 80.0, vp.y - menu_size.y - 6.0)
	_panel.position = pos


## Menú de construir: un icono por torre con su coste debajo.
func _build_options() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_panel_box.add_child(row)
	for id in world.mission.towers:
		var def: TowerDef = content.towers[StringName(id)]
		var b := _icon_button(row, def.sprite, str(def.cost[0]), build_requested.emit.bind(selected_spot, def.id))
		b.tooltip_text = "%s — %s" % [def.display_name, def.description]
		b.disabled = world.gold < def.cost[0]
	_close_button(row)


## Menú de una torre construida: nombre y nivel, mejorar y vender.
func _tower_options(t: Dictionary) -> void:
	var def: TowerDef = t.def
	_title("%s · Nv %d" % [def.display_name, t.level])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_panel_box.add_child(row)
	var cost := world.upgrade_cost(selected_spot)
	if cost >= 0:
		var next_name: String = def.level_names[t.level] if t.level < def.level_names.size() else ""
		var up := _small_button(row, "Mejorar\n%d" % cost, upgrade_requested.emit.bind(selected_spot))
		up.theme_type_variation = &"AccentButton"
		up.tooltip_text = "Nivel %d%s" % [t.level + 1, (": " + next_name) if next_name != "" else ""]
		up.disabled = world.gold < cost
	else:
		_small_button(row, "Nivel\nmáx.", func(): pass).disabled = true
	_small_button(row, "Vender\n+%d" % world.sell_value(selected_spot), sell_requested.emit.bind(selected_spot))
	_close_button(row)


func _icon_button(parent: Node, icon: Texture2D, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.icon = icon
	b.text = text
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(54, 80)
	b.theme_type_variation = &"SpotButton"
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


func _small_button(parent: Node, text: String, callback: Callable) -> Button:
	var b := _button(parent, text, callback)
	b.custom_minimum_size = Vector2(64, 48)
	b.theme_type_variation = &"SpotButton"
	return b


func _close_button(parent: Node) -> void:
	var b := _button(parent, "X", close_panel_requested.emit)
	b.custom_minimum_size = Vector2(32, 32)
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	b.theme_type_variation = &"SpotButton"


func _title(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"MenuTitle"
	_panel_box.add_child(l)


## Tres estrellas dibujadas (no dependen de que la fuente tenga el glifo ★).
class StarRow extends Control:
	var stars := 0

	func _draw() -> void:
		for i in 3:
			var c := Vector2(size.x * (i + 0.5) / 3.0, size.y * 0.5)
			var pts := PackedVector2Array()
			for k in 10:
				var r := 22.0 if k % 2 == 0 else 9.0
				var a := -PI / 2 + k * PI / 5
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, Color("ffd34d") if i < stars else Color(1, 1, 1, 0.15))
			pts.append(pts[0])
			draw_polyline(pts, Color("1e1830"), 2.0)


func _stat(parent: Node, _name: String) -> Label:
	var l := Label.new()
	l.theme_type_variation = &"StatLabel"
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 48)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b
