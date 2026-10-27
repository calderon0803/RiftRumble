## Tests del movimiento de Kira sin física (KiraMotor con un suelo plano en y = 0).
## Uso: godot --headless --path . --script res://tests/run_tests.gd
extends SceneTree

const DT := 1.0 / 60.0
var _failures := 0
var _checks := 0


func check(cond: bool, msg: String) -> void:
	_checks += 1
	print(("  ✓ " if cond else "  ✗ ") + msg)
	if not cond:
		_failures += 1


## Simula hasta `frames` pasos sobre un suelo plano. `inputs(frame)` devuelve
## [move_x, jump_held]; `floor_until` permite quitar el suelo (borde) en un fotograma.
## Devuelve la trayectoria (posiciones) y los fotogramas en que empezó un salto.
func simulate(frames: int, inputs: Callable, floor_until := 1 << 30) -> Dictionary:
	var m := KiraMotor.new()
	var p := Vector2.ZERO
	var held_was := false
	var path: Array[Vector2] = []
	var jumps: Array[int] = []
	var on_floor := true
	for f in frames:
		var inp: Array = inputs.call(f)
		var held: bool = inp[1]
		if m.step(DT, inp[0], held and not held_was, held, on_floor):
			jumps.append(f)
		held_was = held
		p += m.velocity * DT
		var has_floor := f < floor_until
		on_floor = has_floor and p.y >= 0.0
		if on_floor:
			p.y = 0.0
			m.velocity.y = 0.0
		path.append(p)
	return {"path": path, "jumps": jumps, "motor": m}


func apex(path: Array[Vector2]) -> float:
	var top := 0.0
	for p in path:
		top = minf(top, p.y)
	return -top


func _initialize() -> void:
	var tile := KiraMotor.TILE
	print("Salto")
	var full := simulate(90, func(f): return [0.0, f >= 2])
	var h_full := apex(full.path)
	check(absf(h_full - KiraMotor.JUMP_HEIGHT) < 0.05 * KiraMotor.JUMP_HEIGHT,
			"manteniendo el botón sube %.1f casillas (objetivo %.1f)" % [h_full / tile, KiraMotor.JUMP_HEIGHT / tile])
	var tap := simulate(90, func(f): return [0.0, f == 2])
	var h_tap := apex(tap.path)
	check(h_tap < 0.5 * h_full and h_tap > KiraMotor.JUMP_MIN_HEIGHT * 0.8,
			"con un toque sube %.1f casillas (menos de la mitad)" % (h_tap / tile))
	var mid := simulate(90, func(f): return [0.0, f >= 2 and f < 8])
	var h_mid := apex(mid.path)
	check(h_mid > h_tap and h_mid < h_full, "soltando a medias queda entre ambos (%.1f casillas)" % (h_mid / tile))
	var land := -1
	for i in range(3, full.path.size()):
		if full.path[i].y >= 0.0:
			land = i
			break
	var air_time := (land - 2) * DT
	check(air_time > 0.6 and air_time < 0.8, "salto completo en el aire %.2f s (cae más rápido de lo que sube)" % air_time)

	print("Carrera")
	var run := simulate(60, func(_f): return [1.0, false])
	var m: KiraMotor = run.motor
	check(is_equal_approx(m.velocity.x, KiraMotor.RUN_SPEED), "alcanza la velocidad máxima (%.0f px/s)" % m.velocity.x)
	var reach := 0
	var r2 := KiraMotor.new()
	while r2.velocity.x < KiraMotor.RUN_SPEED and reach < 60:
		r2.step(DT, 1.0, false, false, true)
		reach += 1
	check(reach <= 8, "llega a tope en %d fotogramas (respuesta rápida)" % reach)
	var stop := 0
	while r2.velocity.x > 0.0 and stop < 60:
		r2.step(DT, 0.0, false, false, true)
		stop += 1
	check(stop <= 6, "se para en %d fotogramas al soltar" % stop)
	r2.step(DT, -1.0, false, false, true)
	check(r2.facing == -1, "se gira hacia donde se mueve")

	print("Ayudas")
	# Sale del borde en el fotograma 10 y pulsa saltar 4 fotogramas después (0,07 s).
	var coyote_ok := simulate(40, func(f): return [1.0, f >= 14], 10)
	check(coyote_ok.jumps.size() == 1, "puede saltar 0,07 s después de salir de un borde")
	var coyote_late := simulate(40, func(f): return [1.0, f >= 20], 10)
	check(coyote_late.jumps.is_empty(), "0,17 s después ya no")
	# Salto y, mientras cae, pulsa de nuevo justo antes de aterrizar.
	var first := simulate(120, func(f): return [0.0, f >= 2 and f < 4])
	var landing := -1
	for i in range(5, first.path.size()):
		if first.path[i].y >= 0.0:
			landing = i
			break
	var buffered := simulate(120, func(f): return [0.0, (f >= 2 and f < 4) or f >= landing - 5])
	check(buffered.jumps.size() == 2 and buffered.jumps[1] <= landing + 1,
			"pulsar 0,08 s antes de aterrizar vuelve a saltar al tocar el suelo")
	var too_early := simulate(120, func(f): return [0.0, (f >= 2 and f < 4) or (f >= landing - 14 and f < landing - 12)])
	check(too_early.jumps.size() == 1, "pulsar demasiado pronto no cuenta")

	print("\n%d/%d comprobaciones correctas" % [_checks - _failures, _checks])
	quit(1 if _failures > 0 else 0)
