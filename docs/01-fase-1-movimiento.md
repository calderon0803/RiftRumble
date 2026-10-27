# Fase 1 — Movimiento de Kira

## Objetivo
Que correr y saltar se sientan bien antes de añadir nada más: en un metroidvania es lo que más se usa.
Kira es un rectángulo provisional hasta que haya sprites.

## Qué hay
- `KiraMotor` (`src/player/kira_motor.gd`): toda la lógica de movimiento, sin nodos ni física, para poder probarla sola.
- `Kira` (`src/player/kira.gd`): el cuerpo en la sala (`CharacterBody2D`), lee teclado/mando y aplica el motor.
- Sala de prueba (`src/world/test_room.gd`) construida a partir de un plano de texto (`#` bloque, `K` inicio), con cámara que sigue a Kira dentro de los límites de la sala.
- Controles registrados por código (`src/core/controls.gd`).

## Ajustes (en `kira_motor.gd`)
| Parámetro | Valor | Efecto |
|---|---|---|
| Velocidad de carrera | 280 px/s (8,75 casillas/s) | |
| Arranque / frenada en suelo | 6 / 5 fotogramas | respuesta inmediata |
| Salto máximo (manteniendo) | 5,3 casillas (≈5,1 real) | |
| Salto mínimo (toque) | 1,2 casillas (≈1,5 real) | altura variable al soltar |
| Tiempo hasta lo alto | 0,39 s | |
| Gravedad al caer | ×1,7 | cae más rápido de lo que sube |
| Velocidad máxima de caída | 960 px/s | |
| Margen tras salir de un borde | 0,10 s | |
| Margen al pulsar antes de aterrizar | 0,12 s | |

Una casilla son 32 px; la pantalla muestra 40 × 22,5 casillas.

## Criterios de aceptación
- [x] Se juega en PC con teclado y mando.
- [x] Correr: llega a tope y se para en pocos fotogramas; se gira al cambiar de dirección.
- [x] Salto con altura variable: un toque sube menos de la mitad que manteniendo.
- [x] Se puede saltar justo después de salir de un borde (0,07 s) pero no tarde (0,17 s).
- [x] Pulsar saltar justo antes de aterrizar salta al tocar el suelo; pulsarlo demasiado pronto no.
- [x] En la sala: se queda en el suelo, choca con paredes sin atravesarlas, sube a un bloque de 2 casillas y el techo la frena.
- [x] La cámara la sigue sin salirse de la sala.

Tests: `run_tests.gd` 12/12 y `scene_tests.gd` 10/10.
