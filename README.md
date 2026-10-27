# RIFT RUMBLE

Metroidvania 2D lateral para PC. Protagonista: **Kira**, espadachina con el filo de 6 muescas.
El proyecto empezó como tower defense; ese código queda en el historial de git (hasta el commit `e3a39a8`).

Estado: **fase 1, movimiento** (correr y saltar en una sala de prueba). Ver [docs/01-fase-1-movimiento.md](docs/01-fase-1-movimiento.md).

## Requisitos
- Godot **4.7.x** estable, versión estándar con GDScript (no la .NET).

## Estructura
```
src/core/     Utilidades comunes (controles)
src/player/   Kira: movimiento sin nodos (KiraMotor) y cuerpo en la sala (Kira)
src/world/    Salas
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

## Controles
| Acción | Teclado | Mando |
|---|---|---|
| Moverse | ← → / A D | Stick izquierdo / cruceta |
| Saltar (mantener = más alto) | Espacio / Z / K | A |
| Volver al inicio | R | Select / Back |
