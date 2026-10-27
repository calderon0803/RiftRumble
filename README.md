# RIFT RUMBLE

Metroidvania 2D lateral para PC. Protagonista: **Kira**, espadachina con el filo de 6 muescas.
El proyecto empezó como tower defense; ese código queda en el historial de git (hasta el commit `e3a39a8`).

Estado: **movimiento** ([fase 1](docs/01-fase-1-movimiento.md)), **combate** ([fase 3](docs/02-combate.md)) y **un mundo de 7 salas con bancos, guardado y mapa** ([fase 4](docs/03-salas-y-mapa.md)) **el dash**, la primera habilidad que abre camino ([fase 5](docs/04-dash.md)), y **el primer jefe**, el Guardián ([fase 6](docs/05-jefe-guardian.md)). Kira, los enemigos y el escenario son formas provisionales.

## Requisitos
- Godot **4.7.x** estable, versión estándar con GDScript (no la .NET).

## Estructura
```
src/core/     Utilidades comunes (controles, partida guardada)
src/player/   Kira: movimiento sin nodos (KiraMotor) y cuerpo en la sala (Kira)
src/combat/   Tajos y filo (KiraCombat) y vida (Health), sin nodos
src/enemies/  Enemigos
src/ui/       Marcador y mapa
src/fx/       Efectos
src/world/    Mundo y salas (rooms.gd lo genera tools/gen_rooms.py)
tools/        Generadores
tests/        Tests headless
art/concept/  Diseño de los personajes
docs/         Decisiones y resultados por fase
```

## Comandos
Sustituye `godot` por la ruta de tu ejecutable si no está en el PATH.

Jugar:
```bash
godot --path .
```

Tests del movimiento (sin física):
```bash
godot --headless --path . --script res://tests/run_tests.gd
```

Tests en la sala (con física):
```bash
godot --headless --path . --script res://tests/scene_tests.gd
```

Tests del mundo (salas, pinchos, banco, guardado y plataformas alcanzables):
```bash
godot --headless --path . --script res://tests/world_tests.gd
```

Tests del jefe:
```bash
godot --headless --path . --script res://tests/boss_tests.gd
```

Regenerar las salas tras editar `tools/gen_rooms.py`:
```bash
python tools/gen_rooms.py
```

## Controles
| Acción | Teclado | Mando |
|---|---|---|
| Moverse | ← → / A D | Stick izquierdo / cruceta |
| Saltar (mantener = más alto) | Espacio / Z / K | A |
| Tajo (↑ arriba, ↓ en el aire abajo) | X / J | X |
| Tajo de filo (3 muescas) | C / L | Y |
| Dash (cuando se consigue) | Shift / V | RB |
| Descansar en un banco (guarda) | ↑ / W | Arriba |
| Mapa | M / Tab | Select / Back |
| Volver al último banco | R | |
| Partida nueva | F5 | |
