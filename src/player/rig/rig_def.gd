## Esqueleto de un personaje animado por piezas.
## Todas las piezas están en una misma textura; cada una cuelga de su padre y las
## animaciones (src/player/rig/cutout_anims.gd) giran sus articulaciones.
class_name RigDef
extends Resource

## Hoja de piezas (fondo transparente).
@export var texture: Texture2D
## Cada pieza: {
##   name: StringName      — hueso estándar (hips, torso, head, hair, arm_r_up, arm_r_low,
##                           weapon, arm_l_up, arm_l_low, leg_r_up, leg_r_low, leg_l_up, leg_l_low)
##   region: Rect2         — recorte en la textura
##   pivot: Vector2        — articulación, en coordenadas de la región
##   parent: StringName    — pieza de la que cuelga (vacío = raíz, la cadera)
##   at: Vector2           — dónde va el pivote: en coordenadas de la región del padre,
##                           o respecto a los pies si es la raíz
##   rest: float           — giro de reposo en grados (sentido horario)
##   z: int                — orden de dibujo (mayor = delante)
## }
@export var parts: Array[Dictionary] = []
## Las piezas se dibujan a 2×: escala 0,5 en pantalla.
@export var scale := 0.5
## Familia de animaciones de ataque y habilidad: &"melee" o &"ranged".
@export var style: StringName = &"melee"
