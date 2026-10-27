## Crea enemigos por tipo (el que aparece en los planos de las salas).
class_name Enemies
extends RefCounted

## Símbolo del plano → tipo.
const KINDS := {"c": "crawler", "v": "flyer", "s": "spitter"}


## `pos`: pies (rastrero, escupidor) o centro (revoloteador).
static func create(kind: String, pos: Vector2, target: Node2D) -> Node2D:
	var e: Node2D
	match kind:
		"flyer":
			e = Flyer.new()
		"spitter":
			e = Spitter.new()
		_:
			e = Crawler.new()
	e.position = pos
	if "target" in e:
		e.target = target
	return e


## Centro del cuerpo (para efectos).
static func center_of(e: Node2D) -> Vector2:
	return e.center() if e.has_method("center") else e.position + Vector2(0, -16)
