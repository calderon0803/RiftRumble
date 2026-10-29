## Animaciones de Kira por piezas, vista lateral (mirando a la derecha).
## Cada pista es una lista de [tiempo (s), valor]: grados para las articulaciones
## (sentido horario; para un miembro que cuelga, negativo = hacia delante, ±180 =
## hacia arriba) y Vector2 en píxeles de la hoja para «root» (desplazamiento de la
## cadera). Los valores se suman al giro de reposo de cada pieza. El pelo («hair»)
## es un objetivo: cutout_rig.gd le añade inercia. `trail` = deja estela la espada.
##
## Los tajos golpean en cuanto se pulsa (el combate no espera), así que empiezan
## ya con el brazo arriba y el corte ocurre en las primeras centésimas; la
## recuperación es más lenta.
extends RefCounted

## Velocidad en pantalla (px/s) para la que está pensada la carrera; Kira acelera
## o frena el ciclo según su velocidad real para que no resbale.
const RUN_REFERENCE_SPEED := 200.0

const ANIMS := {
	&"idle": {length = 1.8, loop = true, tracks = {
		root = [[0.0, Vector2.ZERO], [0.9, Vector2(1.5, -1.5)], [1.8, Vector2.ZERO]],
		torso = [[0.0, 1.0], [0.9, -2.0], [1.8, 1.0]],
		head = [[0.0, -1.0], [0.9, 2.5], [1.8, -1.0]],
		arm_r_up = [[0.0, 2.0], [0.9, -3.0], [1.8, 2.0]],
		arm_r_low = [[0.0, 0.0], [0.9, -4.0], [1.8, 0.0]],
		arm_l_up = [[0.0, -2.0], [0.9, 4.0], [1.8, -2.0]],
		arm_l_low = [[0.0, -6.0], [0.9, -10.0], [1.8, -6.0]],
		leg_r_up = [[0.0, -3.0], [0.9, -1.0], [1.8, -3.0]],
		leg_l_up = [[0.0, 3.0], [0.9, 5.0], [1.8, 3.0]],
		leg_l_low = [[0.0, 4.0], [0.9, 8.0], [1.8, 4.0]],
	}},
	&"run": {length = 0.48, loop = true, tracks = {
		root = [[0.0, Vector2(0, 0)], [0.06, Vector2(0, 4)], [0.12, Vector2(0, -2)], [0.18, Vector2(0, -6)],
			[0.24, Vector2(0, 0)], [0.30, Vector2(0, 4)], [0.36, Vector2(0, -2)], [0.42, Vector2(0, -6)], [0.48, Vector2(0, 0)]],
		hips = [[0.0, -2.0], [0.24, 2.0], [0.48, -2.0]],
		torso = [[0.0, 12.0], [0.06, 15.0], [0.18, 10.0], [0.24, 12.0], [0.30, 15.0], [0.42, 10.0], [0.48, 12.0]],
		head = [[0.0, -8.0], [0.06, -10.0], [0.18, -6.0], [0.24, -8.0], [0.30, -10.0], [0.42, -6.0], [0.48, -8.0]],
		leg_r_up = [[0.0, -42.0], [0.06, -26.0], [0.12, 4.0], [0.18, 30.0], [0.24, 32.0], [0.30, 18.0], [0.36, -20.0], [0.42, -46.0], [0.48, -42.0]],
		leg_r_low = [[0.0, 4.0], [0.06, 26.0], [0.12, 12.0], [0.18, 30.0], [0.24, 45.0], [0.30, 75.0], [0.36, 85.0], [0.42, 40.0], [0.48, 4.0]],
		leg_l_up = [[0.0, 32.0], [0.06, 18.0], [0.12, -20.0], [0.18, -46.0], [0.24, -42.0], [0.30, -26.0], [0.36, 4.0], [0.42, 30.0], [0.48, 32.0]],
		leg_l_low = [[0.0, 45.0], [0.06, 75.0], [0.12, 85.0], [0.18, 40.0], [0.24, 4.0], [0.30, 26.0], [0.36, 12.0], [0.42, 30.0], [0.48, 45.0]],
		# Brazo libre opuesto a las piernas; el de la espada la lleva atrás y se mueve poco.
		arm_l_up = [[0.0, -48.0], [0.24, 38.0], [0.48, -48.0]],
		arm_l_low = [[0.0, -70.0], [0.12, -55.0], [0.24, -40.0], [0.36, -55.0], [0.48, -70.0]],
		arm_r_up = [[0.0, 28.0], [0.24, 8.0], [0.48, 28.0]],
		arm_r_low = [[0.0, -35.0], [0.24, -25.0], [0.48, -35.0]],
		weapon = [[0.0, 20.0], [0.24, 12.0], [0.48, 20.0]],
	}},
	# Subiendo en el salto: rodilla delantera arriba, la otra recogida, brazo libre alto.
	&"jump": {length = 0.3, loop = false, tracks = {
		root = [[0.0, Vector2(0, 2)], [0.3, Vector2(0, -2)]],
		torso = [[0.0, 4.0], [0.3, 8.0]],
		head = [[0.0, -2.0], [0.3, -6.0]],
		leg_r_up = [[0.0, -30.0], [0.3, -62.0]],
		leg_r_low = [[0.0, 40.0], [0.3, 85.0]],
		leg_l_up = [[0.0, 10.0], [0.3, 18.0]],
		leg_l_low = [[0.0, 30.0], [0.3, 55.0]],
		arm_l_up = [[0.0, -40.0], [0.3, -125.0]],
		arm_l_low = [[0.0, -20.0], [0.3, -35.0]],
		arm_r_up = [[0.0, 10.0], [0.3, 30.0]],
		arm_r_low = [[0.0, -10.0], [0.3, -20.0]],
		weapon = [[0.0, 10.0], [0.3, 25.0]],
	}},
	# Cayendo: piernas que se estiran hacia el suelo, brazos abiertos para equilibrarse.
	&"fall": {length = 0.6, loop = true, tracks = {
		root = [[0.0, Vector2.ZERO], [0.3, Vector2(0, 1)], [0.6, Vector2.ZERO]],
		torso = [[0.0, -4.0], [0.3, -2.0], [0.6, -4.0]],
		head = [[0.0, 6.0], [0.3, 4.0], [0.6, 6.0]],
		leg_r_up = [[0.0, -24.0], [0.3, -20.0], [0.6, -24.0]],
		leg_r_low = [[0.0, 28.0], [0.3, 22.0], [0.6, 28.0]],
		leg_l_up = [[0.0, 18.0], [0.3, 22.0], [0.6, 18.0]],
		leg_l_low = [[0.0, 22.0], [0.3, 30.0], [0.6, 22.0]],
		arm_l_up = [[0.0, -95.0], [0.3, -105.0], [0.6, -95.0]],
		arm_l_low = [[0.0, -15.0], [0.3, -25.0], [0.6, -15.0]],
		arm_r_up = [[0.0, 45.0], [0.3, 52.0], [0.6, 45.0]],
		arm_r_low = [[0.0, -15.0], [0.3, -20.0], [0.6, -15.0]],
		weapon = [[0.0, 20.0], [0.3, 25.0], [0.6, 20.0]],
	}},
	# Tajo hacia delante: el brazo baja de arriba-atrás a delante en 0,07 s, se pasa
	# de largo y vuelve con calma.
	&"slash": {length = 0.3, loop = false, trail = true, tracks = {
		root = [[0.0, Vector2(-2, 0)], [0.07, Vector2(7, 1)], [0.12, Vector2(8, 1)], [0.3, Vector2.ZERO]],
		torso = [[0.0, -10.0], [0.07, 16.0], [0.12, 20.0], [0.3, 0.0]],
		head = [[0.0, -5.0], [0.07, 6.0], [0.3, 0.0]],
		arm_r_up = [[0.0, 140.0], [0.07, 280.0], [0.12, 300.0], [0.3, 360.0]],
		arm_r_low = [[0.0, -10.0], [0.07, 0.0], [0.12, 8.0], [0.3, 0.0]],
		weapon = [[0.0, 30.0], [0.07, -15.0], [0.12, -8.0], [0.3, 0.0]],
		arm_l_up = [[0.0, -30.0], [0.07, 40.0], [0.12, 46.0], [0.3, 0.0]],
		arm_l_low = [[0.0, -30.0], [0.07, -15.0], [0.3, 0.0]],
		leg_r_up = [[0.0, -6.0], [0.07, -26.0], [0.3, 0.0]],
		leg_r_low = [[0.0, 6.0], [0.07, 16.0], [0.3, 0.0]],
		leg_l_up = [[0.0, 6.0], [0.07, 22.0], [0.3, 0.0]],
		leg_l_low = [[0.0, 0.0], [0.07, 18.0], [0.3, 0.0]],
	}},
	# Tajo hacia arriba: de delante-abajo a arriba por encima de la cabeza.
	&"slash_up": {length = 0.3, loop = false, trail = true, tracks = {
		root = [[0.0, Vector2(0, 2)], [0.07, Vector2(0, -4)], [0.3, Vector2.ZERO]],
		torso = [[0.0, 6.0], [0.07, -12.0], [0.3, 0.0]],
		head = [[0.0, 4.0], [0.07, -16.0], [0.3, 0.0]],
		arm_r_up = [[0.0, -40.0], [0.07, -175.0], [0.12, -190.0], [0.3, 0.0]],
		arm_r_low = [[0.0, -20.0], [0.07, 0.0], [0.3, 0.0]],
		weapon = [[0.0, 20.0], [0.07, -10.0], [0.3, 0.0]],
		arm_l_up = [[0.0, 20.0], [0.07, 35.0], [0.3, 0.0]],
		leg_r_up = [[0.0, -10.0], [0.07, -4.0], [0.3, 0.0]],
		leg_l_up = [[0.0, 8.0], [0.07, 4.0], [0.3, 0.0]],
	}},
	# Tajo hacia abajo (en el aire): de arriba-delante hacia los pies, piernas recogidas.
	&"slash_down": {length = 0.3, loop = false, trail = true, tracks = {
		root = [[0.0, Vector2(0, -2)], [0.07, Vector2(0, 2)], [0.3, Vector2.ZERO]],
		torso = [[0.0, -6.0], [0.07, 24.0], [0.3, 8.0]],
		head = [[0.0, -4.0], [0.07, 14.0], [0.3, 4.0]],
		arm_r_up = [[0.0, -150.0], [0.07, -10.0], [0.12, 5.0], [0.3, 0.0]],
		arm_r_low = [[0.0, -10.0], [0.07, 0.0], [0.3, 0.0]],
		weapon = [[0.0, 15.0], [0.07, 40.0], [0.12, 45.0], [0.3, 20.0]],
		arm_l_up = [[0.0, -60.0], [0.07, 50.0], [0.3, 30.0]],
		leg_r_up = [[0.0, -40.0], [0.07, -55.0], [0.3, -40.0]],
		leg_r_low = [[0.0, 60.0], [0.07, 80.0], [0.3, 60.0]],
		leg_l_up = [[0.0, 10.0], [0.07, -10.0], [0.3, 10.0]],
		leg_l_low = [[0.0, 40.0], [0.07, 70.0], [0.3, 40.0]],
	}},
	# Tajo de filo: arco completo con un paso adelante y el cuerpo volcado.
	&"special": {length = 0.45, loop = false, trail = true, tracks = {
		root = [[0.0, Vector2(-4, 4)], [0.08, Vector2(12, 2)], [0.16, Vector2(16, 3)], [0.45, Vector2.ZERO]],
		torso = [[0.0, -16.0], [0.08, 22.0], [0.16, 28.0], [0.45, 0.0]],
		head = [[0.0, -8.0], [0.08, 8.0], [0.16, 10.0], [0.45, 0.0]],
		arm_r_up = [[0.0, 160.0], [0.08, 290.0], [0.16, 310.0], [0.45, 360.0]],
		arm_r_low = [[0.0, -15.0], [0.08, 0.0], [0.16, 10.0], [0.45, 0.0]],
		weapon = [[0.0, 35.0], [0.08, -15.0], [0.16, -5.0], [0.45, 0.0]],
		arm_l_up = [[0.0, -70.0], [0.08, 55.0], [0.16, 60.0], [0.45, 0.0]],
		arm_l_low = [[0.0, -40.0], [0.08, -20.0], [0.45, 0.0]],
		leg_r_up = [[0.0, -30.0], [0.08, -45.0], [0.16, -40.0], [0.45, 0.0]],
		leg_r_low = [[0.0, 45.0], [0.08, 20.0], [0.45, 0.0]],
		leg_l_up = [[0.0, 20.0], [0.08, 38.0], [0.16, 34.0], [0.45, 0.0]],
		leg_l_low = [[0.0, 40.0], [0.08, 30.0], [0.45, 0.0]],
	}},
	# Dash: cuerpo volcado hacia delante, brazos y piernas estirados hacia atrás.
	&"dash": {length = 0.2, loop = true, tracks = {
		root = [[0.0, Vector2(0, 4)], [0.2, Vector2(0, 4)]],
		torso = [[0.0, 30.0], [0.2, 30.0]],
		head = [[0.0, -16.0], [0.2, -16.0]],
		arm_r_up = [[0.0, 60.0], [0.2, 60.0]],
		arm_r_low = [[0.0, -10.0], [0.2, -10.0]],
		weapon = [[0.0, -35.0], [0.2, -35.0]],
		arm_l_up = [[0.0, 75.0], [0.2, 75.0]],
		arm_l_low = [[0.0, -20.0], [0.2, -20.0]],
		leg_r_up = [[0.0, -15.0], [0.2, -15.0]],
		leg_r_low = [[0.0, 50.0], [0.2, 50.0]],
		leg_l_up = [[0.0, 40.0], [0.2, 40.0]],
		leg_l_low = [[0.0, 60.0], [0.2, 60.0]],
	}},
	# Deslizándose por la pared (que queda a la espalda): mano atrás contra la pared,
	# piernas flexionadas.
	&"wall_slide": {length = 0.4, loop = true, tracks = {
		root = [[0.0, Vector2(-3, 0)], [0.2, Vector2(-3, 1)], [0.4, Vector2(-3, 0)]],
		torso = [[0.0, -8.0], [0.4, -8.0]],
		head = [[0.0, 4.0], [0.2, 2.0], [0.4, 4.0]],
		arm_l_up = [[0.0, 120.0], [0.2, 115.0], [0.4, 120.0]],
		arm_l_low = [[0.0, 20.0], [0.4, 20.0]],
		arm_r_up = [[0.0, -30.0], [0.4, -30.0]],
		arm_r_low = [[0.0, -25.0], [0.4, -25.0]],
		weapon = [[0.0, 15.0], [0.4, 15.0]],
		leg_r_up = [[0.0, -45.0], [0.4, -45.0]],
		leg_r_low = [[0.0, 70.0], [0.4, 70.0]],
		leg_l_up = [[0.0, -15.0], [0.4, -15.0]],
		leg_l_low = [[0.0, 55.0], [0.4, 55.0]],
	}},
	&"hit": {length = 0.32, loop = false, tracks = {
		root = [[0.0, Vector2.ZERO], [0.05, Vector2(-6, 1)], [0.16, Vector2(1, 0)], [0.32, Vector2.ZERO]],
		torso = [[0.0, 0.0], [0.05, -16.0], [0.16, 4.0], [0.32, 0.0]],
		head = [[0.0, 0.0], [0.05, -14.0], [0.16, 5.0], [0.32, 0.0]],
		arm_l_up = [[0.0, 0.0], [0.05, 30.0], [0.16, -5.0], [0.32, 0.0]],
		arm_r_up = [[0.0, 0.0], [0.05, 18.0], [0.32, 0.0]],
		leg_l_up = [[0.0, 0.0], [0.05, 10.0], [0.32, 0.0]],
	}},
}


## Valor de una pista en el instante `t`, con interpolación suave entre claves.
static func sample_track(keys: Array, t: float):
	if t <= keys[0][0]:
		return keys[0][1]
	for i in range(1, keys.size()):
		if t <= keys[i][0]:
			var t0: float = keys[i - 1][0]
			var w := smoothstep(0.0, 1.0, (t - t0) / maxf(keys[i][0] - t0, 0.0001))
			return lerp(keys[i - 1][1], keys[i][1], w)
	return keys[-1][1]


## Pose de una animación: {hueso: grados, root: Vector2}. Las que no se repiten
## se quedan en su última pose.
static func pose(anim: StringName, time: float) -> Dictionary:
	var a: Dictionary = ANIMS[anim]
	var t := fmod(time, a.length) if a.loop else minf(time, a.length)
	var out := {}
	for bone in a.tracks:
		out[bone] = sample_track(a.tracks[bone], t)
	return out


static func length(anim: StringName) -> float:
	return ANIMS[anim].length
