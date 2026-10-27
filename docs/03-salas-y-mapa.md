# Fase 4 — Salas, banco y mapa

## Objetivo
Pasar de una sala suelta a un mundo: salas conectadas, peligros del escenario, un sitio donde descansar
y guardar, y un mapa para orientarse.

## Cómo funciona
- **Mundo en cuadrícula**: cada sala tiene su posición en una cuadrícula común (en casillas). Al salir
  de una sala por un hueco del borde, Kira entra en la sala que hay en ese punto, sin saltos de posición;
  la cámara se ajusta a los límites de cada sala y hay un fundido breve.
- **Salas** (generadas por `tools/gen_rooms.py` → `src/world/rooms.gd`):
  | Sala | Tamaño | Qué tiene |
  |---|---|---|
  | Inicio | 1 pantalla | punto de partida, dos plataformas |
  | Pasillo | 2 pantallas de ancho | foso de pinchos de 4 casillas, 3 rastreros |
  | Pozo | 2 pantallas de alto | se sube por plataformas alternas, 1 rastrero |
  | Banco | 1 pantalla (encima del pasillo) | el banco |
  | Mirador | 1 pantalla | sala sin salida con 3 rastreros en plataformas |
- **Pinchos**: tocarlos quita un corazón y devuelve a Kira al último suelo seguro (no al banco).
  Caerse fuera del mundo cuenta igual.
- **Banco**: de pie sobre él, ↑ para descansar: recupera toda la vida y guarda la partida.
- **Muerte**: vuelve al último banco (o al inicio si no hay ninguno) con toda la vida; la sala se reinicia.
- **Enemigos**: reaparecen cada vez que se entra en una sala.
- **Mapa** (M / Tab / Select): salas visitadas en su sitio, la actual resaltada, Kira y el banco.
  Mientras está abierto, el juego se pausa.
- **Partida guardada**: `user://partida.json` (en Windows, `%APPDATA%\Godot\app_userdata\RIFT RUMBLE\`).
  Guarda el último banco y las salas visitadas. Al abrir el juego se empieza en el último banco.
  R vuelve al último banco; F5 empieza una partida nueva (borra el guardado).

## Código
- `src/world/world.gd` (+ `world.tscn`, escena principal): salas, transiciones, pinchos, banco, muerte, guardado.
- `src/world/room_layout.gd`: lee el plano de texto de una sala (sin nodos).
- `src/world/room_geometry.gd`: colisiones y dibujo de una sala.
- `src/world/test_room.gd`: sala suelta para los tests de movimiento y combate.
- `src/core/save_game.gd`: leer y escribir la partida (JSON local).
- `src/ui/map_view.gd`: el mapa.
- `tools/gen_rooms.py`: genera las salas; los huecos de salas vecinas encajan por construcción.

## Criterios de aceptación
- [x] Las salas no se solapan y cada hueco del borde lleva a aire en la sala vecina (32 casillas de salida).
- [x] Inicio ↔ pasillo, pasillo → pozo, pozo → banco y banco → mirador funcionan andando, sin saltos de posición.
- [x] La cámara se ajusta a cada sala (también a la de dos pantallas de alto).
- [x] Pinchos: quitan un corazón y devuelven al borde del foso; saltando se cruza sin daño.
- [x] Banco: devuelve toda la vida y guarda el banco y las salas visitadas.
- [x] Al morir se vuelve al último banco con toda la vida.
- [x] Al abrir el juego se empieza en el último banco y el mapa recuerda las salas visitadas.
- [x] Partida nueva: borra el guardado y vuelve al inicio.
- [x] Todas las plataformas de inicio, pozo, banco y mirador se alcanzan saltando con la física real.

Tests: `world_tests.gd` 28/28 (antes del dash).
