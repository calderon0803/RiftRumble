## Director de audio: traduce eventos de la simulación a efectos de sonido.
##
## - Los sonidos se buscan por nombre en SFX_DIR: sustituir el audio provisional
##   por el definitivo no requiere tocar código.
## - Evita saturar: cada sonido tiene un intervalo mínimo entre reproducciones y
##   un máximo de voces simultáneas (con 300 enemigos no suenan 300 disparos).
extends Node

const SFX_DIR := "res://audio/placeholder/"
const VOICES := 16
## Segundos mínimos entre dos reproducciones del mismo sonido.
const MIN_GAP := {shot_digital = 0.07, shot_magic = 0.07, shot_kinetic = 0.07, shot_energy = 0.07,
	hit = 0.05, kill = 0.04}
const DEFAULT_GAP := 0.03
## Volumen por sonido (dB); los frecuentes, más bajos.
const VOLUME := {shot_digital = -16.0, shot_magic = -15.0, shot_kinetic = -15.0, shot_energy = -16.0,
	hit = -18.0, kill = -10.0}
const DEFAULT_VOLUME := -6.0

var world  # SimWorld (para saber el tipo de daño de cada disparo)
var muted := false

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played := {}


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(name: String) -> void:
	if muted:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(name, -1.0) < MIN_GAP.get(name, DEFAULT_GAP):
		return
	var stream := _stream(name)
	if stream == null:
		return
	_last_played[name] = now
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = VOLUME.get(name, DEFAULT_VOLUME)
	p.pitch_scale = randf_range(0.95, 1.05)  # variación para que no suene mecánico
	p.play()


func _exit_tree() -> void:
	stop_all()


## Detiene todo y suelta los sonidos (al salir, para no dejar reproducciones vivas).
func stop_all() -> void:
	for p in _players:
		p.stop()
		p.stream = null
	_streams.clear()


func on_events(events: Array[Dictionary]) -> void:
	for ev in events:
		match ev.type:
			&"projectile_fired":
				var def: TowerDef = world.p_tower_def[ev.slot] if world else null
				play("shot_%s" % (def.damage_type if def else "kinetic"))
			&"enemy_hit": play("hit")
			&"enemy_killed": play("kill")
			&"enemy_leaked": play("leak")
			&"tower_built": play("build")
			&"tower_upgraded": play("upgrade")
			&"tower_sold": play("sell")
			&"wave_started": play("wave_start")
			&"portal_opened": play("portal")
			&"line_strike": play("slash")
			&"hero_died": play("hero_ko")
			&"hero_respawned": play("hero_respawn")
			&"synergy_spread": play("synergy")
			&"enemy_summoned": play("boss_summon")
			&"core_dropped": play("core")
			&"enemy_revived": play("revive")
			&"victory": play("victory")
			&"defeat": play("defeat")


func _stream(name: String) -> AudioStream:
	if not _streams.has(name):
		var path := SFX_DIR + name + ".wav"
		_streams[name] = load(path) if ResourceLoader.exists(path) else null
	return _streams[name]
