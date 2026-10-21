## Ruta en coordenadas lógicas (casillas). No conoce la proyección isométrica.
extends RefCounted

var points: PackedVector2Array
var _cumulative := PackedFloat32Array()
var length := 0.0


func _init(waypoints: PackedVector2Array) -> void:
	assert(waypoints.size() >= 2, "Una ruta necesita al menos dos puntos")
	points = waypoints
	_cumulative.append(0.0)
	for i in range(1, points.size()):
		length += points[i - 1].distance_to(points[i])
		_cumulative.append(length)


## Polilínea desplazada lateralmente `offset` casillas (positivo = a la izquierda
## del sentido de avance), con esquinas a inglete para que no haya saltos.
static func offset_points(pts: PackedVector2Array, offset: float) -> PackedVector2Array:
	if is_zero_approx(offset):
		return pts
	var out := PackedVector2Array()
	for i in pts.size():
		var n_in := Vector2.ZERO
		var n_out := Vector2.ZERO
		if i > 0:
			var d := (pts[i] - pts[i - 1]).normalized()
			n_in = Vector2(-d.y, d.x)
		if i < pts.size() - 1:
			var d := (pts[i + 1] - pts[i]).normalized()
			n_out = Vector2(-d.y, d.x)
		var n := n_in if n_out == Vector2.ZERO else n_out
		var miter := n
		if n_in != Vector2.ZERO and n_out != Vector2.ZERO:
			miter = (n_in + n_out).normalized()
			n = n_out
		out.append(pts[i] + miter * (offset / maxf(miter.dot(n), 0.3)))
	return out


## Posición a una distancia `d` desde el inicio, limitada a [0, length].
func sample(d: float) -> Vector2:
	if d <= 0.0:
		return points[0]
	if d >= length:
		return points[points.size() - 1]
	# Búsqueda binaria del segmento que contiene d.
	var seg := _cumulative.bsearch(d, true) - 1
	seg = clampi(seg, 0, points.size() - 2)
	var seg_len := _cumulative[seg + 1] - _cumulative[seg]
	var t := (d - _cumulative[seg]) / seg_len if seg_len > 0.0 else 0.0
	return points[seg].lerp(points[seg + 1], t)
