# RIFT RUMBLE

> *Defiende tu mundo. Rompe las reglas.*

Metroidvania 2D lateral con bucle roguelite. **Álex**, un desarrollador, queda atrapado en su juego de realidad
virtual cuando su IA (el **Editor**) fusiona todos sus juegos en uno. Solo puede salir terminándolo. Empieza por el
**Reino del Continue**, cuyo jefe es el **Rey del Reinicio**. Morir dentro no duele: el juego le devuelve al
**Umbral de Nexo**, conservando los fragmentos y lo comprado en el anillo, pero no los poderes de las grietas.
Argumento completo: [docs/02-argumento.md](docs/02-argumento.md).

El código anterior (metroidvania por fases y, antes, tower defense) sigue en el historial de git y en la rama `main`.
Diseño: [mundo 1](docs/01-roguelite-reino-del-continue.md) · [argumento](docs/02-argumento.md) · [mundo 2](docs/03-mundo-2-academia.md) · [Reino ampliado](docs/04-reino-ampliado.md).

## Requisitos
- Godot **4.7.x** estable, versión estándar con GDScript (no la .NET).

## Estructura
```
src/main.gd, main.tscn  Escena principal: crea el juego y sus vistas, lee controles y avanza a 60 Hz
src/game/               Simulación sin nodos (Game), datos del mundo y textos (Data), guardado (SaveData)
src/view/               Dibujo: sala y personajes (WorldView), marcador y pantallas (UIView), brillos (GlowView)
src/core/               Controles de teclado y mando
tests/                  Tests headless de la simulación
tools/                  Capturas automáticas
art/                    Arte de Kira de versiones anteriores (no se usa todavía; Kira se dibuja por código)
```

## Comandos
Sustituye `godot` por la ruta de tu ejecutable si no está en el PATH.

Jugar:
```bash
godot --path .
```

Tests:
```bash
godot --headless --path . --script res://tests/game_tests.gd
```

Capturas de las pantallas principales:
```bash
godot --path . --script res://tools/screenshots.gd -- capturas
```

## Controles
| Acción | Teclado | Mando |
|---|---|---|
| Moverse | ← → / A D | Stick izquierdo / cruceta |
| Saltar (mantener = más alto; dos veces con el orbe) | Espacio / Z / K | A |
| Clic con el cursor (↑ arriba, ↓ en el aire abajo) | X / J | X |
| Arrastrar: dash, intocable mientras dura | Shift / C / L | RB |
| Salto en pared (con el orbe de la Academia) | empujar hacia la pared en el aire + saltar | |
| Excepción: disparo (2 de depuración) | Q / I | Y |
| Parche: +1 corazón (mantener, 2 de depuración) | R / U | LB |
| Hablar, leer, asomarse a una grieta | E / ↑ | B |
| Elegir poder | 1 2 3 / ← → + Enter | |
| Pausa | Esc / P | Start |
| Borrar el progreso (en pausa) | B dos veces | |
| Salir (en pausa) | F10 | |

Partida guardada: `user://partida.json` (en Windows, `%APPDATA%\Godot\app_userdata\RIFT RUMBLE\`).
