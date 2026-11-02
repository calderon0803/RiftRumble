# RIFT RUMBLE

> *Defiende tu mundo. Rompe las reglas.*

Metroidvania 2D lateral con bucle roguelite. **Kira Volt** entra en el **Reino del Continue**, que el **Editor**
ha convertido en una partida que se reinicia sin fin, para romper el bucle venciendo al **Rey del Reinicio**.
Cada vez que cae, el Reino la devuelve al **Umbral de Nexo**: conserva los fragmentos y lo comprado en el anillo,
pero pierde los poderes que le prestaron los héroes de las grietas.

El código anterior (metroidvania por fases y, antes, tower defense) sigue en el historial de git y en la rama `main`.
Diseño de esta versión: [docs/01-roguelite-reino-del-continue.md](docs/01-roguelite-reino-del-continue.md).

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
art/                    Arte de Kira de versiones anteriores (no se usa todavía)
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
| Tajo (↑ arriba, ↓ en el aire abajo) | X / J | X |
| Dash (intocable mientras dura) | Shift / C / L | RB |
| Descarga de filo (2 muescas) | Q / I | Y |
| Concentrarse: +1 corazón (mantener, 2 muescas) | R / U | LB |
| Hablar, leer, asomarse a una grieta | E / ↑ | B |
| Elegir poder | 1 2 3 / ← → + Enter | |
| Pausa | Esc / P | Start |
| Borrar el progreso (en pausa) | B dos veces | |
| Salir (en pausa) | F10 | |

Partida guardada: `user://partida.json` (en Windows, `%APPDATA%\Godot\app_userdata\RIFT RUMBLE\`).
