# Fase 5 — Primera habilidad: el dash

## Objetivo
La primera habilidad que abre camino: hasta tenerla, hay una zona del mundo a la vista pero inalcanzable.

## Cómo funciona
- **Dash** (Shift / V / RB): impulso horizontal de ~5 casillas (900 px/s durante 0,18 s) sin caer.
  Va hacia donde se pulsa (o hacia donde mira). En el aire, uno hasta volver al suelo; rebotar sobre
  un enemigo con el tajo hacia abajo lo devuelve. Entre dashes en el suelo hay 0,35 s de espera.
  Saltar corta el dash. Durante el dash no se ataca.
- **Dónde se consigue**: orbe azul en lo más alto del **Mirador** (antes era una sala sin nada).
- **Qué abre**: a la izquierda del **Inicio**, un foso de pinchos de 7 casillas. Saltando con carrerilla
  se cruzan ~6; con salto + dash, ~9. Al otro lado, el **Abismo**, con un **corazón extra** (vida máxima 6).
- **Objetos**: se guardan en el momento de recogerlos (habilidades, vida máxima y qué se ha recogido)
  y no vuelven a aparecer. Se conservan al morir y al volver a abrir el juego; la partida nueva los quita.

## Código
- `src/player/kira_motor.gd`: el dash (sin nodos).
- `src/player/kira.gd`: habilidades (`grant`), vida máxima (`set_max_hp`), estela del dash.
- `src/world/pickup.gd`: orbe y corazón. `src/world/world.gd`: recoger, aplicar y guardar.
- `tools/gen_rooms.py`: nueva sala Abismo, foso en el Inicio y el orbe en el Mirador.

## Criterios de aceptación
- [x] Sin la habilidad no hay dash; con ella recorre ~5 casillas sin caer.
- [x] Un dash en el aire hasta tocar el suelo; el rebote sobre un enemigo lo devuelve.
- [x] Saltando con carrerilla se cruzan ~6 casillas: el foso de 7 no se puede cruzar sin dash.
- [x] Con salto + dash se cruza y se llega al Abismo.
- [x] El orbe da el dash, se guarda al momento y no reaparece; el corazón sube la vida máxima a 6.
- [x] Al volver a abrir el juego y al morir se conservan; la partida nueva los quita.
- [x] Todas las plataformas del Abismo se alcanzan saltando.

Tests: `run_tests.gd` 36/36, `scene_tests.gd` 30/30 y `world_tests.gd` 42/42.
