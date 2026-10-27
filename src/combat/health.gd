## Vida con invulnerabilidad temporal tras recibir daño. Sin nodos.
class_name Health
extends RefCounted

var max_hp: int
var hp: int
var invulnerable := 0.0


func _init(max_value: int) -> void:
	max_hp = max_value
	hp = max_value


func step(dt: float) -> void:
	invulnerable = maxf(invulnerable - dt, 0.0)


## Aplica el daño si no está invulnerable ni muerto. Devuelve si lo ha recibido.
func damage(amount: int, invulnerable_time := 0.0) -> bool:
	if invulnerable > 0.0 or hp <= 0:
		return false
	hp = maxi(hp - amount, 0)
	invulnerable = invulnerable_time
	return true


func is_dead() -> bool:
	return hp <= 0


func reset() -> void:
	hp = max_hp
	invulnerable = 0.0
