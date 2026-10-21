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
var _debug: Label
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

	# --- Panel contextual (construir / mejorar) ---------------------------------
	# Contenedores a pantalla completa que colocan el panel abajo y centrado
	# (se adaptan solos a cualquier tamaño de pantalla).
	var dock := VBoxContainer.new()
	dock.set_anchors_preset(Control.PRESET_FULL_RECT)
	dock.offset_bottom = -10
	dock.alignment = BoxContainer.ALIGNMENT_END
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dock)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_child(center)
	_panel = PanelContainer.new()
	_panel.visible = false
	center.add_child(_panel)
	_panel_box = VBoxContainer.new()
	_panel_box.add_theme_constant_override("separation", 8)
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
	_button(ov, "Jugar otra vez", restart_requested.emit)

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


func select_spot(spot: int) -> void:
	selected_spot = spot
	_panel_signature = ""  # fuerza a reconstruir el panel


## Refresca textos y estados de botones. Barato: solo toca lo que cambia.
func refresh(paused: bool, debug_text: String) -> void:
	_gold.text = "Oro %d" % world.gold
	_lives.text = "Vida %d" % maxi(world.base_hp, 0)
	_wave.text = "Oleada %d/%d" % [world.wave_index + 1, world.waves_total()]
	_wave_button.disabled = world.wave_active or world.is_over() \
			or world.wave_index + 1 >= world.waves_total()
	_wave_button.text = "Oleada en curso" if world.wave_active else "Lanzar oleada"
	_pause_button.text = "Seguir" if paused else "Pausa"
	_debug.text = debug_text
	_refresh_panel()
	if world.is_over() and not _overlay.visible:
		_overlay.visible = true
		_panel.visible = false
		_overlay_label.text = "¡VICTORIA!\nVida restante: %d" % world.base_hp \
				if world.outcome == SimWorld.Outcome.VICTORY else "La base ha caído"


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


func _build_options() -> void:
	_title("Construir")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_panel_box.add_child(row)
	for id in world.mission.towers:
		var def: TowerDef = content.towers[StringName(id)]
		var b := _button(row, "%s\n%d oro" % [def.display_name, def.cost[0]],
				build_requested.emit.bind(selected_spot, def.id))
		b.custom_minimum_size = Vector2(150, 64)
		b.tooltip_text = def.description
		b.disabled = world.gold < def.cost[0]
	_button(_panel_box, "Cerrar", close_panel_requested.emit)


func _tower_options(t: Dictionary) -> void:
	var def: TowerDef = t.def
	_title("%s · nivel %d" % [def.display_name, t.level])
	var desc := Label.new()
	desc.text = def.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(420, 0)
	_panel_box.add_child(desc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_panel_box.add_child(row)
	var cost := world.upgrade_cost(selected_spot)
	if cost >= 0:
		var next_name: String = def.level_names[t.level] if t.level < def.level_names.size() else ""
		var label := "Mejorar: %s\n%d oro" % [next_name, cost] if next_name != "" else "Mejorar\n%d oro" % cost
		var up := _button(row, label, upgrade_requested.emit.bind(selected_spot))
		up.theme_type_variation = &"AccentButton"
		up.disabled = world.gold < cost
	else:
		_button(row, "Nivel máximo", func(): pass).disabled = true
	_button(row, "Vender\n+%d oro" % world.sell_value(selected_spot), sell_requested.emit.bind(selected_spot))
	_button(row, "Cerrar", close_panel_requested.emit)


func _title(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"HeaderLabel"
	_panel_box.add_child(l)


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
