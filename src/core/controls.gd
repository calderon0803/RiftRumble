## Controles registrados por código (teclado y mando), para no depender del mapa de entrada del editor.
class_name Controls
extends RefCounted

const KEYS := {
	"left": [KEY_LEFT, KEY_A],
	"right": [KEY_RIGHT, KEY_D],
	"up": [KEY_UP, KEY_W],
	"down": [KEY_DOWN, KEY_S],
	"jump": [KEY_SPACE, KEY_Z, KEY_K],
	"attack": [KEY_X, KEY_J],
	"dash": [KEY_SHIFT, KEY_C, KEY_L],
	"cast": [KEY_Q, KEY_I],
	"heal": [KEY_R, KEY_U],
	"interact": [KEY_E],
	"confirm": [KEY_ENTER, KEY_KP_ENTER],
	"pause": [KEY_ESCAPE, KEY_P],
	"c1": [KEY_1], "c2": [KEY_2], "c3": [KEY_3],
	"erase": [KEY_B],
	"quit": [KEY_F10],
}

const PAD := {
	"jump": [JOY_BUTTON_A],
	"attack": [JOY_BUTTON_X],
	"dash": [JOY_BUTTON_RIGHT_SHOULDER],
	"cast": [JOY_BUTTON_Y],
	"heal": [JOY_BUTTON_LEFT_SHOULDER],
	"interact": [JOY_BUTTON_B],
	"confirm": [JOY_BUTTON_A],
	"pause": [JOY_BUTTON_START],
	"left": [JOY_BUTTON_DPAD_LEFT],
	"right": [JOY_BUTTON_DPAD_RIGHT],
	"up": [JOY_BUTTON_DPAD_UP],
	"down": [JOY_BUTTON_DPAD_DOWN],
}

const ACTIONS := ["left", "right", "up", "down", "jump", "attack", "dash", "cast", "heal", "interact", "confirm", "pause", "c1", "c2", "c3", "erase", "quit"]


static func register() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			continue
		InputMap.add_action(a, 0.4)
		for k in KEYS.get(a, []):
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(a, ev)
		for b in PAD.get(a, []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = b
			InputMap.action_add_event(a, jb)
	var axes := {"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0], "up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0]}
	for a in axes:
		var m := InputEventJoypadMotion.new()
		m.axis = axes[a][0]
		m.axis_value = axes[a][1]
		InputMap.action_add_event(a, m)


## Copia el estado de las acciones en los diccionarios que lee el juego.
static func read(keys: Dictionary, pressed: Dictionary) -> void:
	for a in ACTIONS:
		keys[a] = Input.is_action_pressed(a)
		pressed[a] = Input.is_action_just_pressed(a)
