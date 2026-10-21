## Sistema de efectos de estado sobre enemigos.
##
## Interpreta EffectDef de forma genérica: pilas, duración, ralentización,
## inmovilización, daño recibido extra y efectos encadenados al llegar al máximo
## de pilas, con inmunidad posterior. Protecciones:
##  - profundidad máxima de encadenamiento (sin recursión infinita),
##  - todo efecto tiene duración finita (sin efectos permanentes accidentales),
##  - las pilas están acotadas por `max_stacks`,
##  - las sinergias (SynergyDef) se evalúan aquí; una propagación no vuelve a
##    activar sinergias, así que no hay cadenas de propagación.
extends RefCounted

const MAX_CHAIN_DEPTH := 3

## Por enemigo: lista de instancias { def: EffectDef, stacks: int, ticks: int }.
var instances: Array = []
## Por enemigo: { effect_id: tick hasta el que es inmune }.
var immunities: Array = []
## Estado derivado por enemigo (se recalcula al cambiar sus efectos).
var speed_mult := PackedFloat32Array()
var rooted := PackedByteArray()
var view_flags := PackedInt32Array()


## Prepara (o reinicia) el hueco de un enemigo recién creado o reutilizado.
func reset_slot(slot: int) -> void:
	while instances.size() <= slot:
		instances.append([])
		immunities.append({})
		speed_mult.append(1.0)
		rooted.append(0)
		view_flags.append(0)
	instances[slot] = []
	immunities[slot] = {}
	speed_mult[slot] = 1.0
	rooted[slot] = 0
	view_flags[slot] = 0


## Aplica un efecto. Devuelve true si se aplicó.
## `world` se pasa en cada llamada (no se guarda) para no crear una referencia
## circular mundo ↔ efectos que impediría liberar la partida al reiniciar.
func apply(world, slot: int, def: EffectDef, depth := 0, allow_synergies := true) -> bool:
	if def == null or depth > MAX_CHAIN_DEPTH:
		return false
	if immunities[slot].get(def.id, -1) > world.tick:
		return false
	var list: Array = instances[slot]
	var inst = null
	for e in list:
		if e.def == def:
			inst = e
			break
	if inst == null:
		inst = {def = def, stacks = 0, ticks = 0}
		list.append(inst)
	var cap := maxi(def.max_stacks, 1)
	var stacks_before: int = inst.stacks
	inst.stacks = mini(inst.stacks + 1, cap)
	inst.ticks = maxi(1, roundi(def.duration * world.TICK_RATE))

	# Sinergias: la condición se evalúa con el estado del objetivo ANTES de este efecto.
	var active: Array = []
	if allow_synergies:
		for syn: SynergyDef in world.synergies:
			if syn.trigger_effect == def and (view_flags[slot] & syn.requires_any_flags) != 0:
				active.append(syn)
				inst.stacks = mini(inst.stacks + syn.extra_stacks, cap)
				world.events.append({type = &"synergy_triggered", synergy = syn.id, slot = slot})
	world.events.append({type = &"effect_applied", slot = slot, effect = def.id, stacks = inst.stacks})

	# Propagación al ALCANZAR el máximo (no en cada golpe posterior).
	if stacks_before < cap and inst.stacks >= cap:
		for syn: SynergyDef in active:
			if syn.spread_radius > 0.0 and syn.spread_max_targets > 0:
				_spread(world, slot, def, syn, depth)

	if def.on_max_stacks and inst.stacks >= def.max_stacks:
		list.erase(inst)
		if def.immunity_after_trigger > 0.0:
			immunities[slot][def.id] = world.tick + roundi(def.immunity_after_trigger * world.TICK_RATE)
		world.events.append({type = &"effect_triggered", slot = slot, effect = def.id})
		apply(world, slot, def.on_max_stacks, depth + 1)
	_recompute(slot)
	return true


## Avanza un tick: descuenta duraciones y elimina los efectos agotados.
## Aplica `def` a los enemigos más cercanos a `slot` (sin volver a activar sinergias).
func _spread(world, slot: int, def: EffectDef, syn: SynergyDef, depth: int) -> void:
	var origin: Vector2 = world.e_pos[slot]
	var candidates := []
	var r2 := syn.spread_radius * syn.spread_radius
	for i in world.e_alive.size():
		if i != slot and world.e_alive[i] == 1:
			var d2 := origin.distance_squared_to(world.e_pos[i])
			if d2 <= r2:
				candidates.append([d2, i])
	candidates.sort_custom(func(a, b): return a[0] < b[0])
	var targets := []
	for c in candidates.slice(0, syn.spread_max_targets):
		targets.append(c[1])
		for k in syn.spread_stacks:
			apply(world, c[1], def, depth + 1, false)
	world.events.append({type = &"synergy_spread", synergy = syn.id, slot = slot, targets = targets})


func step(world) -> void:
	for slot in instances.size():
		var list: Array = instances[slot]
		if list.is_empty() or world.e_alive[slot] == 0:
			continue
		var changed := false
		for i in range(list.size() - 1, -1, -1):
			list[i].ticks -= 1
			if list[i].ticks <= 0:
				list.remove_at(i)
				changed = true
		if changed:
			_recompute(slot)


## Multiplicador de daño recibido para un tipo de daño (≥ 1).
func damage_taken_mult(slot: int, damage_type: StringName) -> float:
	var mult := 1.0
	for e in instances[slot]:
		var def: EffectDef = e.def
		if def.damage_taken_bonus_per_stack != 0.0 and def.bonus_excludes_damage_type != damage_type:
			mult += def.damage_taken_bonus_per_stack * e.stacks
	return mult


func stacks_of(slot: int, effect_id: StringName) -> int:
	for e in instances[slot]:
		if e.def.id == effect_id:
			return e.stacks
	return 0


func _recompute(slot: int) -> void:
	var speed := 1.0
	var root := false
	var flags := 0
	for e in instances[slot]:
		var def: EffectDef = e.def
		speed *= pow(def.speed_mult_per_stack, e.stacks)
		root = root or def.root
		flags |= def.view_flags
	speed_mult[slot] = speed
	rooted[slot] = 1 if root else 0
	view_flags[slot] = flags
