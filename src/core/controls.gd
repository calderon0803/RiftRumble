## Acciones de control (teclado y mando). Se registran por código para que estén
## igual en el juego y en los tests, sin depender del mapa de entrada del editor.
class_name Controls
extends RefCounted

const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const JUMP := &"jump"
const RESET := &"reset"


static func ensure() -> void:
	if InputMap.has_action(JUMP):
		return
	_add(MOVE_LEFT, [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_add(MOVE_RIGHT, [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_add(JUMP, [KEY_SPACE, KEY_Z, KEY_K], [JOY_BUTTON_A])
	_add(RESET, [KEY_R], [JOY_BUTTON_BACK])


static func _add(action: StringName, keys: Array, buttons: Array, axis := -1, axis_dir := 0.0) -> void:
	InputMap.add_action(action, 0.25)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(action, jb)
	if axis >= 0:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axis
		jm.axis_value = axis_dir
		InputMap.action_add_event(action, jm)
