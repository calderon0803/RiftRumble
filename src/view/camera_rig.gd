## Cámara del mapa: arrastre (ratón o un dedo), zoom (rueda o pellizco)
## y límites para no perder el mapa de vista.
extends Camera2D

const ZOOM_MIN := 0.6
const ZOOM_MAX := 3.0
## Distancia mínima (px) para que una pulsación se considere arrastre.
const DRAG_THRESHOLD := 8.0

## Rectángulo del mapa en coordenadas de mundo (pantalla isométrica).
var bounds := Rect2()

var _mouse_drag := false
var _touches := {}  # índice → posición
var _pinch_start_dist := 0.0
var _pinch_start_zoom := 1.0


func setup(map_bounds: Rect2, initial_zoom: float) -> void:
	bounds = map_bounds
	position = bounds.get_center()
	zoom = Vector2.ONE * initial_zoom
	_clamp()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom_at(1.1, event.position)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_at(1.0 / 1.1, event.position)
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				_mouse_drag = event.pressed
	elif event is InputEventMouseMotion and _mouse_drag:
		_pan(event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		if _touches.size() == 2:
			var p: Array = _touches.values()
			_pinch_start_dist = p[0].distance_to(p[1])
			_pinch_start_zoom = zoom.x
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			_pan(event.relative)
		elif _touches.size() == 2 and _pinch_start_dist > 0.0:
			var p: Array = _touches.values()
			var factor: float = p[0].distance_to(p[1]) / _pinch_start_dist
			_set_zoom_around(_pinch_start_zoom * factor, (p[0] + p[1]) * 0.5)
	elif event is InputEventMagnifyGesture:  # trackpad
		_zoom_at(event.factor, event.position)


func _pan(screen_delta: Vector2) -> void:
	position -= screen_delta / zoom
	_clamp()


func _zoom_at(factor: float, screen_point: Vector2) -> void:
	_set_zoom_around(zoom.x * factor, screen_point)


## Cambia el zoom manteniendo fijo el punto del mundo bajo `screen_point`.
func _set_zoom_around(new_zoom: float, screen_point: Vector2) -> void:
	new_zoom = clampf(new_zoom, ZOOM_MIN, ZOOM_MAX)
	var before := get_canvas_transform().affine_inverse() * screen_point
	zoom = Vector2.ONE * new_zoom
	force_update_scroll()
	var after := get_canvas_transform().affine_inverse() * screen_point
	position += before - after
	_clamp()


## El centro de la cámara no puede salir del rectángulo del mapa.
func _clamp() -> void:
	if bounds.size == Vector2.ZERO:
		return
	position = position.clamp(bounds.position, bounds.end)
