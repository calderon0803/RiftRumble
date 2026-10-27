# Fase 7 — Más enemigos

Nombres provisionales (ids en el código: `Flyer`, `Spitter`, `Projectile`).

## Objetivo
Que el combate no sea siempre igual: un enemigo que ataca desde el aire y otro a distancia,
los dos con aviso antes de atacar.

## Enemigos
| | Revoloteador (`v`) | Escupidor (`s`) |
|---|---|---|
| Vida | 2 | 3 |
| Movimiento | flota en su sitio | fijo en el suelo |
| Ataque | al acercarse Kira (7 casillas) tiembla 0,4 s y se lanza en picado (380 px/s); luego vuelve | a tiro (10 casillas en horizontal, 9 en vertical) se ilumina 0,5 s y dispara hacia Kira (300 px/s); recarga 2 s |
| Notas | se puede rebotar sobre él con el tajo hacia abajo; no atraviesa paredes | el tajo corta los proyectiles (sin llenar muescas); los proyectiles desaparecen al chocar |

El rastrero sigue igual (3 de vida, patrulla y se gira en paredes y bordes).

## Dónde están
- **Pasillo**: un escupidor en la plataforma alta.
- **Pozo**: dos revoloteadores en el hueco por el que se sube.
- **Mirador**: un revoloteador.
- **Abismo**: un escupidor vigilando el corazón extra.
- **Sala del banco**: sin enemigos.

## Código
- `src/enemies/flyer.gd`, `src/enemies/spitter.gd`, `src/enemies/projectile.gd`.
- `src/enemies/enemies.gd`: crea enemigos por tipo (símbolo del plano → tipo).
- `src/player/kira.gd`: los proyectiles desaparecen al alcanzarla (`on_hit_kira`).

## Criterios de aceptación
- [x] Revoloteador: flota lejos de Kira; avisa y se lanza en picado al acercarse; vuelve a su sitio.
- [x] Revoloteador: 2 tajos lo eliminan; se puede rebotar sobre él; no atraviesa paredes.
- [x] Escupidor: no dispara con Kira lejos; avisa y dispara a tiro; el proyectil quita un corazón y desaparece.
- [x] Escupidor: recarga ~2 s; 3 tajos lo eliminan.
- [x] El tajo corta los proyectiles sin daño y sin llenar muescas; chocan y desaparecen en los bloques.
- [x] Repartidos por las salas; la del banco, sin enemigos.

Tests: `enemy_tests.gd` 19/19 (más `run_tests.gd` 36/36, `scene_tests.gd` 30/30, `world_tests.gd` 42/42 y `boss_tests.gd` 24/24).
