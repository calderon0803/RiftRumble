# Fase 8 — Segunda habilidad: salto en pared

## Objetivo
Una segunda habilidad que abra camino en vertical y se combine con el dash.

## Cómo funciona
- **Deslizarse**: en el aire, empujando hacia una pared mientras cae, Kira se desliza despacio
  (140 px/s como máximo), mirando hacia fuera. Deslizarse devuelve el dash del aire.
- **Saltar desde la pared**: mientras se desliza (o hasta 0,1 s después de soltarse), saltar la lanza
  hacia fuera y hacia arriba (220 / 760 px/s), con 0,1 s sin control para que despegue. Volviendo a
  empujar hacia la misma pared se puede **trepar por una sola pared** (~4 casillas por salto), o ir de
  una pared a otra en un pasadizo. La altura depende de cuánto se mantenga el botón, como el salto normal.
- **Dónde se consigue**: orbe verde en la **Guarida**, que aparece **al vencer al Guardián**
  (si ya estaba vencido, está ahí al volver).
- **Qué abre**: un hueco de 6 casillas arriba a la derecha del **Pozo**, al que solo se llega trepando
  por la pared derecha. Lleva a la **Cumbre** (sala nueva), con un corazón en lo alto de un pasadizo
  estrecho (3 casillas) entre dos columnas, un revoloteador y un escupidor.
- Los objetos se recogen al **tocarlos con cualquier parte del cuerpo** (antes se medía desde el centro).

## Código
- `src/player/kira_motor.gd`: deslizarse y saltar desde la pared (sin nodos).
- `src/player/kira.gd`: detecta la pared pegada (`_wall_dir`) y dibuja el roce.
- `src/world/world.gd`: los objetos de la arena aparecen al vencer al jefe; recoger al tocar.
- `tools/gen_rooms.py`: orbe `W` en la Guarida, salida alta del Pozo y la Cumbre.

## Criterios de aceptación
- [x] Sin la habilidad no se desliza; con ella, empujando hacia la pared, cae despacio.
- [x] Saltar desde la pared la lanza hacia fuera y hacia arriba, con un instante sin control.
- [x] Deslizarse devuelve el dash; se puede saltar justo después de soltarse.
- [x] Sin la habilidad no se llega a lo alto de la pared derecha del Pozo; con ella se trepa hasta la Cumbre.
- [x] El orbe no está mientras vive el Guardián, aparece al vencerle, se coge y se guarda al momento.
- [x] El corazón de la Cumbre solo se alcanza subiendo por el pasadizo con salto en pared.

Tests: `run_tests.gd` 44/44, `scene_tests.gd` 30/30, `world_tests.gd` 51/51, `boss_tests.gd` 24/24 y `enemy_tests.gd` 19/19.
