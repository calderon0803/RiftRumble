# Fase 3 — Combate

## Objetivo
Que golpear se sienta bien y que el filo de Kira (6 muescas) tenga uso desde el principio.
Todo sigue siendo provisional en lo visual: rectángulos y un arco para el tajo.

## Cómo funciona
- **Tajo** (X / J / botón X): golpea hacia delante. Con ↑, hacia arriba; con ↓ en el aire, hacia abajo.
  Cada tajo golpea una sola vez a cada enemigo. Golpe activo 0,10 s; recuperación 0,32 s.
- **Rebote**: acertar un tajo hacia abajo lanza a Kira hacia arriba (sirve para cruzar enemigos y huecos).
- **Retroceso**: al acertar hacia delante, Kira retrocede un poco; el enemigo sale despedido casi una casilla.
- **Micropausa** al acertar: 0,05 s (0,10 s con el tajo de filo).
- **Filo**: cada tajo normal que acierta llena una muesca (máx. 6).
  **Tajo de filo** (C / L / botón Y): con 3 muescas o más, corte amplio de 3 de daño que gasta 3.
- **Vida**: 5 corazones. Tocar a un enemigo quita uno, empuja a Kira hacia atrás, la deja sin control 0,22 s
  y la hace invulnerable 1 s (parpadea). Con 0 corazones, vuelve al inicio y la sala se reinicia.
- **Rastrero** (primer enemigo): 3 de vida, patrulla y se da la vuelta en paredes y bordes; hace daño al tocarlo.

## Código
- `src/combat/kira_combat.gd`: tajos y filo, sin nodos.
- `src/combat/health.gd`: vida e invulnerabilidad, sin nodos.
- `src/player/kira.gd`: zonas de golpe, daño por contacto, rebote, retroceso y dibujo del tajo.
- `src/enemies/crawler.gd`: el rastrero.
- `src/ui/hud.gd`: corazones y muescas. `src/fx/burst.gd`: estallido al morir un enemigo.
- Capas de física: 1 escenario, 2 Kira, 3 enemigos (Kira y los enemigos se atraviesan; el daño va por contacto).

## Criterios de aceptación
- [x] El tajo hacia delante quita 1 de vida, llena una muesca y empuja al enemigo; un tajo golpea una vez.
- [x] 3 tajos eliminan al rastrero y desaparece de la sala.
- [x] Tajo hacia arriba con ↑; hacia abajo solo en el aire; acertar hacia abajo hace rebotar sin recibir daño.
- [x] Tajo de filo: no sale con menos de 3 muescas; con 3 elimina al rastrero de un golpe y las gasta.
- [x] Tocar a un enemigo quita un corazón, empuja y da 1 s de invulnerabilidad; a 0, vuelta al inicio con toda la vida.
- [x] El rastrero no se cae de su plataforma y se da la vuelta en las paredes.

Tests: `run_tests.gd` 27/27 y `scene_tests.gd` 30/30.
