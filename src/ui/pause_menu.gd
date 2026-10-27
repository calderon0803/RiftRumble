## Menú de pausa (Esc / Start): continuar, ver controles, volver al título o salir.
class_name PauseMenu
extends CanvasLayer

signal resume_requested
signal title_requested

const CONTROLS_TEXT := """Moverse: ← → / A D / stick
Saltar: Espacio / Z (mantén para saltar más)
Tajo: X / J  (con ↑ hacia arriba, con ↓ en el aire hacia abajo)
Tajo de filo: C / L  (gasta 3 muescas)
Dash: Shift / V / RB
Salto en pared: en el aire, empuja hacia la pared y salta
Descansar en un banco: ↑
Mapa: M / Tab / Select
Volver al último banco: R
Pausa: Esc / Start"""

var menu: MenuList
var _controls: Label
var _showing_controls := false


func _ready() -> void:
	layer = 6
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.size = Vector2(1280, 720)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := Label.new()
	title.text = "PAUSA"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 60)
	add_child(title)
	menu = MenuList.new()
	menu.position = Vector2(440, 280)
	menu.size = Vector2(400, 220)
	add_child(menu)
	menu.set_items([
		["resume", "Continuar"],
		["controls", "Controles"],
		["title", "Volver al título"],
		["quit", "Salir del juego"],
	])
	menu.chosen.connect(_on_chosen)
	_controls = Label.new()
	_controls.text = CONTROLS_TEXT + "\n\n(Esc / Start para volver)"
	_controls.add_theme_font_size_override("font_size", 20)
	_controls.position = Vector2(340, 240)
	_controls.size = Vector2(600, 400)
	_controls.visible = false
	add_child(_controls)


func open() -> void:
	visible = true
	_show_controls(false)
	menu.selected = 0
	menu.move(0)


func close() -> void:
	visible = false


## Esc / Start dentro del menú: si se ven los controles, vuelve al menú; si no, cierra.
func back() -> void:
	if _showing_controls:
		_show_controls(false)
	else:
		resume_requested.emit()


func _on_chosen(id: String) -> void:
	match id:
		"resume":
			resume_requested.emit()
		"controls":
			_show_controls(true)
		"title":
			title_requested.emit()
		"quit":
			get_tree().quit()


func _show_controls(on: bool) -> void:
	_showing_controls = on
	_controls.visible = on
	menu.visible = not on
