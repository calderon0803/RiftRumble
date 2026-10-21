## Genera efectos de sonido PROVISIONALES por síntesis en res://audio/placeholder/.
## Uso: godot --headless --path . --script res://tools/gen_placeholder_sfx.gd
##
## Ondas simples (cuadrada, seno, ruido) con barridos de frecuencia y envolventes.
## Sirven para validar el feedback sonoro; se sustituirán por audio definitivo
## sin tocar la lógica (el director de audio los busca por nombre).
extends SceneTree

const OUT := "res://audio/placeholder/"
const RATE := 22050

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 7
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# Disparos por tipo de daño
	_save("shot_digital", _seq([[1400, 900, 0.05, &"square", 0.35]]))
	_save("shot_magic", _seq([[600, 1200, 0.09, &"sine", 0.45]]))
	_save("shot_kinetic", _seq([[220, 120, 0.07, &"square", 0.3], [0, 0, 0.03, &"noise", 0.2]]))
	_save("shot_energy", _seq([[900, 500, 0.06, &"saw", 0.3]]))
	# Impactos y resultados
	_save("hit", _seq([[0, 0, 0.035, &"noise", 0.25]]))
	_save("kill", _seq([[700, 1100, 0.05, &"square", 0.3], [1100, 300, 0.08, &"square", 0.25]]))
	_save("leak", _seq([[180, 90, 0.35, &"saw", 0.4]]))
	# Economía
	_save("build", _seq([[440, 440, 0.07, &"square", 0.3], [660, 660, 0.1, &"square", 0.3]]))
	_save("upgrade", _seq([[523, 523, 0.06, &"square", 0.3], [659, 659, 0.06, &"square", 0.3],
		[784, 784, 0.12, &"square", 0.3]]))
	_save("sell", _seq([[988, 988, 0.05, &"square", 0.3], [1319, 1319, 0.12, &"sine", 0.35]]))
	_save("denied", _seq([[160, 140, 0.12, &"square", 0.25]]))
	# Oleadas y héroes
	_save("wave_start", _seq([[392, 392, 0.12, &"square", 0.3], [392, 392, 0.12, &"square", 0.3],
		[587, 587, 0.3, &"square", 0.32]]))
	_save("portal", _seq([[200, 900, 0.35, &"sine", 0.45], [900, 600, 0.15, &"sine", 0.3]]))
	_save("slash", _seq([[0, 0, 0.18, &"noise", 0.4], [1600, 400, 0.12, &"saw", 0.25]]))
	_save("hero_ko", _seq([[500, 120, 0.45, &"square", 0.35]]))
	_save("hero_respawn", _seq([[300, 900, 0.25, &"sine", 0.4]]))
	_save("synergy", _seq([[1800, 200, 0.05, &"square", 0.3], [200, 1500, 0.05, &"square", 0.3],
		[0, 0, 0.06, &"noise", 0.25], [1200, 1200, 0.08, &"square", 0.25]]))
	# Jefe
	_save("boss_summon", _seq([[90, 60, 0.4, &"saw", 0.45]]))
	_save("core", _seq([[300, 300, 0.08, &"sine", 0.4], [0, 0, 0.05, &"silence", 0.0],
		[300, 300, 0.08, &"sine", 0.4]]))
	_save("revive", _seq([[100, 400, 0.5, &"saw", 0.4]]))
	# Final
	_save("victory", _seq([[523, 523, 0.14, &"square", 0.3], [659, 659, 0.14, &"square", 0.3],
		[784, 784, 0.14, &"square", 0.3], [1047, 1047, 0.5, &"square", 0.32]]))
	_save("defeat", _seq([[392, 392, 0.2, &"square", 0.3], [311, 311, 0.2, &"square", 0.3],
		[262, 196, 0.7, &"square", 0.3]]))
	quit()


## Concatena tramos [frec_inicio, frec_fin, duración, onda, volumen].
func _seq(parts: Array) -> PackedByteArray:
	var data := PackedByteArray()
	for p in parts:
		data.append_array(_tone(p[0], p[1], p[2], p[3], p[4]))
	return data


func _tone(f0: float, f1: float, dur: float, wave: StringName, vol: float) -> PackedByteArray:
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t)
		phase = fmod(phase + f / RATE, 1.0)
		var v := 0.0
		match wave:
			&"square": v = 1.0 if phase < 0.5 else -1.0
			&"sine": v = sin(phase * TAU)
			&"saw": v = phase * 2.0 - 1.0
			&"noise": v = rng.randf_range(-1.0, 1.0)
			_: v = 0.0
		# Envolvente: ataque de 4 ms y caída lineal.
		var env := minf(1.0, i / (0.004 * RATE)) * (1.0 - t)
		data.encode_s16(i * 2, int(clampf(v * env * vol, -1.0, 1.0) * 32767))
	return data


func _save(name: String, pcm: PackedByteArray) -> void:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = pcm
	var err := s.save_to_wav(OUT + name + ".wav")
	print("%s %s" % ["OK " if err == OK else "ERR", name])
