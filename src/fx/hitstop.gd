## Micropausa al acertar un golpe: frena el juego un instante (en tiempo real).
class_name HitStop
extends RefCounted

const NORMAL := 0.05
const SPECIAL := 0.10


static func apply(tree: SceneTree, special: bool) -> void:
	Engine.time_scale = 0.05
	await tree.create_timer(SPECIAL if special else NORMAL, true, false, true).timeout
	Engine.time_scale = 1.0
