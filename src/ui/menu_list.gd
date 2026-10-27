## Lista de opciones para menús: ↑/↓ (o cruceta/stick) para elegir, saltar / Intro /
## botón A para aceptar. Funciona también con el juego en pausa.
class_name MenuList
extends VBoxContainer

signal chosen(id: String)

const COLOR_ON := Color("ffffff")
const COLOR_OFF := Color(1, 1, 1, 0.45)
const COLOR_DISABLED := Color(1, 1, 1, 0.18)

var selected := 0
var _items: Array[Dictionary] = []    # {id, label, enabled}
var _labels: Array[Label] = []


func _ready() -> void:
	Controls.ensure()
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_constant_override("separation", 10)


func set_items(items: Array) -> void:
	for l in _labels:
		l.queue_free()
	_labels.clear()
	_items.clear()
	for it in items:
		_items.append({"id": it[0], "label": it[1], "enabled": it[2] if it.size() > 2 else true})
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 28)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(l)
		_labels.append(l)
	selected = 0
	while selected < _items.size() and not _items[selected].enabled:
		selected += 1
	_refresh()


func set_label(id: String, text: String) -> void:
	for i in _items.size():
		if _items[i].id == id:
			_items[i].label = text
	_refresh()


func current_id() -> String:
	return _items[selected].id if selected < _items.size() else ""


func move(step: int) -> void:
	if _items.is_empty():
		return
	var i := selected
	for n in _items.size():
		i = posmod(i + step, _items.size())
		if _items[i].enabled:
			break
	selected = i
	_refresh()


func accept() -> void:
	if selected < _items.size() and _items[selected].enabled:
		chosen.emit(_items[selected].id)


func _process(_dt: float) -> void:
	if not is_visible_in_tree():
		return
	if Input.is_action_just_pressed(Controls.MOVE_UP) or Input.is_action_just_pressed(&"ui_up"):
		move(-1)
	elif Input.is_action_just_pressed(Controls.MOVE_DOWN) or Input.is_action_just_pressed(&"ui_down"):
		move(1)
	elif Input.is_action_just_pressed(Controls.JUMP) or Input.is_action_just_pressed(&"ui_accept"):
		accept()


func _refresh() -> void:
	for i in _labels.size():
		var it := _items[i]
		var on := i == selected
		_labels[i].text = ("›  %s  ‹" % it.label) if on else it.label
		_labels[i].add_theme_color_override("font_color",
				COLOR_DISABLED if not it.enabled else (COLOR_ON if on else COLOR_OFF))
