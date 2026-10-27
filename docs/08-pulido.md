# Fase 9 — Pulido

## Objetivo
Que lo que ya hay se sienta como un juego: entrar y salir de él, pausar, notar los golpes y un
escenario con algo de ambiente. Sin sonido por ahora.

## Qué hay
- **Pantalla de título** (escena principal): Continuar (solo si hay partida), Partida nueva (si ya hay
  partida, pide pulsar otra vez para confirmar y borrarla) y Salir. ↑/↓ y Espacio / Intro / A.
- **Pausa** (Esc / P / Start): Continuar, Controles (lista completa), Volver al título y Salir.
  Mientras está abierta, el juego se detiene. La línea de controles de la parte de arriba desaparece:
  queda solo un recordatorio pequeño («Esc: pausa y controles · M: mapa»).
- **Sensación de golpe**:
  - temblor de cámara: fuerte al recibir daño (9 px, 0,3 s), suave al acertar (3 px), algo más con el
    tajo de filo (6 px), al aterrizar el Guardián (7 px) y al caer desde muy alto (2,5 px);
  - destello rojo en los bordes de la pantalla al recibir daño;
  - chispas en el punto del golpe (doradas y más con el tajo de filo);
  - polvo a los pies al saltar desde el suelo y al aterrizar desde cierta altura.
- **Escenario**: cada zona tiene su paleta (piedra azulada, agua, cálido, morado, rojo); fondo en
  degradado con dos capas de siluetas (columnas y arcos) que se mueven más despacio que la cámara;
  bloques con sombra, juntas entre casillas y borde claro solo donde se pisa.
- **F5 ya no borra la partida** (era fácil pulsarla sin querer): la partida nueva está en el título.

## Código
- `src/ui/title_screen.gd` (+ `title.tscn`), `src/ui/pause_menu.gd`, `src/ui/menu_list.gd`.
- `src/fx/camera_shake.gd`, `src/fx/sparks.gd`, `src/fx/dust.gd`.
- `src/world/themes.gd` (paletas), `src/world/background_view.gd` (fondo y paralaje).
- `src/core/save_game.gd`: `active_path` (los tests usan otro archivo para no tocar la partida real).

## Criterios de aceptación
- [x] El juego arranca en el título; sin partida, «Continuar» está apagado.
- [x] «Partida nueva» empieza en el inicio; con partida guardada pide confirmar y luego la borra.
- [x] Esc pausa (Kira no se mueve), enseña los controles, vuelve y reanuda; «Volver al título» funciona.
- [x] Daño: temblor fuerte y destello rojo que se calman; acierto: chispas y temblor suave.
- [x] Polvo al aterrizar desde lo alto.
- [x] Zonas con paletas distintas y fondo con paralaje.

Tests: `ui_tests.gd` 22/22 (más `run_tests.gd` 44/44, `scene_tests.gd` 30/30, `world_tests.gd` 51/51,
`boss_tests.gd` 24/24 y `enemy_tests.gd` 19/19).
