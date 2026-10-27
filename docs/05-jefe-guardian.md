# Fase 6 — Primer jefe: el Guardián

Nombre provisional (id neutro en el código: `BossGuardian`, sala `guarida`).

## Objetivo
Un primer combate de verdad que ponga a prueba tajo, filo, salto y dash, con un patrón que se
pueda aprender y avisos claros antes de cada ataque.

## El combate
- **Vida**: 30 (tajo 1, tajo de filo 3). No retrocede al golpearle (es pesado).
- **Embestida**: parpadea en amarillo (0,6 s) y carga de pared a pared (520 px/s).
  Se esquiva **saltándola** en la zona abierta o **subiéndose a una repisa** (pasa por debajo);
  debajo de las repisas no hay altura para saltarla. Al chocar con la pared queda **aturdido** 0,9 s.
- **Salto aplastante**: parpadea (0,5 s), salta hacia Kira y al caer lanza **dos ondas** por el suelo,
  una a cada lado, que se saltan.
- **Fase 2** (a media vida): ojos amarillos, todo más rápido y **dos embestidas seguidas**.
- **Patrón**: fase 1 embestida → salto; fase 2 salto → embestida doble.

## La arena
- **Guarida**, a la izquierda del Abismo. Al entrar se **cierra la puerta** (barrotes) y no se abre
  hasta vencerle. Barra de vida del jefe arriba.
- **Banco nuevo en el Abismo**, al lado: si Kira muere, vuelve cerca.
- **Recompensa**: un corazón más. El jefe vencido queda guardado y no vuelve a aparecer.

## Código
- `src/enemies/boss_guardian.gd`: el jefe (máquina de estados).
- `src/enemies/shockwave.gd`: las ondas.
- `src/world/world.gd`: aparición, puerta, victoria, recompensa y guardado.
- `src/ui/hud.gd`: barra de vida del jefe.
- `tools/gen_rooms.py`: Guarida (`G` jefe, `|` puerta) y banco del Abismo.

## Criterios de aceptación
- [x] Al entrar en la guarida se cierra la puerta y no se puede salir.
- [x] La embestida avisa, se esquiva saltando sin daño y, al chocar, deja al jefe aturdido.
- [x] Subida a una repisa, la embestida pasa por debajo sin hacer daño.
- [x] Los tajos le quitan vida y no retrocede.
- [x] El salto aplastante va hacia Kira y lanza dos ondas, una a cada lado, que se saltan sin daño
      y desaparecen en las paredes.
- [x] A media vida pasa a la fase 2, más rápida.
- [x] Al vencerle se abre la puerta, da un corazón más y queda guardado; no reaparece y la puerta
      ya no se cierra.

Tests: `boss_tests.gd` 24/24 (más `run_tests.gd` 36/36, `scene_tests.gd` 30/30 y `world_tests.gd` 42/42).
