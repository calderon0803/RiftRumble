## Reglas de la campaña (puras, sin nodos): orden de mundos y desbloqueos.
##
## - Un hueco cuya misión no existe todavía está «en construcción» (PLANNED) y
##   no bloquea: se salta al calcular el orden.
## - Una misión está disponible si todas las misiones construidas anteriores de
##   su mundo están completadas (al menos una victoria).
## - Una misión ya completada sigue siempre disponible (aunque después se añadan
##   misiones nuevas antes que ella en su mundo).
## - Un mundo está abierto si es el primero o si todas las misiones construidas
##   del mundo anterior están completadas.
## `progress_of` es un Callable(mission_id) → Dictionary con `victories`.
extends RefCounted

enum State { LOCKED, AVAILABLE, COMPLETED, PLANNED }


static func worlds_in_order(content) -> Array:
	var worlds: Array = content.worlds.values()
	worlds.sort_custom(func(a, b): return a.order < b.order)
	return worlds


static func is_completed(mission_id: String, progress_of: Callable) -> bool:
	return int(progress_of.call(mission_id).get("victories", 0)) > 0


static func world_unlocked(content, world_index: int, progress_of: Callable) -> bool:
	if world_index <= 0:
		return true
	var prev: WorldDef = worlds_in_order(content)[world_index - 1]
	if not world_unlocked(content, world_index - 1, progress_of):
		return false
	var built := 0
	for id in prev.mission_slots:
		if content.missions.has(StringName(id)):
			built += 1
			if not is_completed(id, progress_of):
				return false
	return built > 0  # un mundo sin misiones construidas no abre el siguiente


static func mission_state(content, world_index: int, slot: int, progress_of: Callable) -> State:
	var world: WorldDef = worlds_in_order(content)[world_index]
	var id := world.mission_slots[slot]
	if not content.missions.has(StringName(id)):
		return State.PLANNED
	if is_completed(id, progress_of):
		return State.COMPLETED
	if not world_unlocked(content, world_index, progress_of):
		return State.LOCKED
	for i in slot:
		var prev_id := world.mission_slots[i]
		if content.missions.has(StringName(prev_id)) and not is_completed(prev_id, progress_of):
			return State.LOCKED
	return State.COMPLETED if is_completed(id, progress_of) else State.AVAILABLE
