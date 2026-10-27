## Pantalla de título: continuar (si hay partida), partida nueva (pide confirmar
## si ya hay una) y salir.
class_name TitleScreen
extends Control

const WORLD_SCENE := "res://src/world/world.tscn"
const COLOR_BG := Color("10131c")

var menu: MenuList
var _confirm_new := false
var _hint: Label


func _ready() -> void:
	Controls.ensure()
	RenderingServer.set_default_clear_color(COLOR_BG)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var title := Label.new()
	title.text = "RIFT RUMBLE"
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Color("ff4fa0"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 110)
	add_child(title)
	menu = MenuList.new()
	menu.position = Vector2(440, 340)
	menu.size = Vector2(400, 200)
	add_child(menu)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.position = Vector2(0, 600)
	_hint.size = Vector2(1280, 40)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	add_child(_hint)
	var has_save := not SaveGame.load_from(SaveGame.active_path).is_empty()
	menu.set_items([
		["continue", "Continuar", has_save],
		["new", "Partida nueva"],
		["quit", "Salir"],
	])
	menu.chosen.connect(_on_chosen)
	_hint.text = "↑ ↓ para elegir  ·  Espacio / Intro / A para aceptar"


func _on_chosen(id: String) -> void:
	match id:
		"continue":
			_start()
		"new":
			var has_save := not SaveGame.load_from(SaveGame.active_path).is_empty()
			if has_save and not _confirm_new:
				_confirm_new = true
				menu.set_label("new", "¿Borrar la partida? Pulsa otra vez")
				return
			SaveGame.erase(SaveGame.active_path)
			_start()
		"quit":
			get_tree().quit()
	if id != "new":
		_confirm_new = false


func _start() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(WORLD_SCENE)
