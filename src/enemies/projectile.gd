## Proyectil del escupidor: vuela en línea recta, hace daño al tocar a Kira y
## desaparece al chocar con algo. El tajo lo corta (sin llenar muescas).
class_name Projectile
extends CharacterBody2D

const SIZE := Vector2(12, 12)
const COLOR := Color("ffd166")
const LIFE := 4.0

var contact_damage := 1
var direction := Vector2.RIGHT
var speed := 300.0
var _t := 0.0


func _ready() -> void:
	collision_layer = Kira.LAYER_ENEMY
	collision_mask = Kira.LAYER_WORLD
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	add_child(shape)


func _physics_process(dt: float) -> void:
	_t += dt
	velocity = direction * speed
	move_and_slide()
	if get_slide_collision_count() > 0 or _t > LIFE:
		queue_free()
	queue_redraw()


## El tajo lo corta: desaparece pero no cuenta como acierto.
func take_hit(_damage: int, _from: Vector2) -> bool:
	queue_free()
	return false


## Ha alcanzado a Kira.
func on_hit_kira() -> void:
	queue_free()


func _draw() -> void:
	var pulse := 1.0 + 0.2 * sin(_t * 25.0)
	draw_circle(Vector2.ZERO, SIZE.x * 0.75 * pulse, Color(COLOR, 0.3))
	draw_circle(Vector2.ZERO, SIZE.x * 0.5, COLOR)
