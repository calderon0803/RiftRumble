# RIFT RUMBLE

> *Defiende tu mundo. Rompe las reglas.*

Tower defense isométrico 2.5D con héroes. Estado actual: **Fase 3 completada (combate y economía)**. Siguiente: Fase 4 (héroes y efectos).
Documentación: [decisión tecnológica](docs/01-decision-tecnologica.md) · [resultados de la PoC](docs/02-resultados-poc.md) · [Fase 2](docs/03-fase-2-mundo-y-rutas.md) · [Fase 3](docs/04-fase-3-combate-y-economia.md).

## Requisitos
- Godot **4.7.x** estable, versión estándar con GDScript (no la .NET).

## Estructura
```
src/sim/       Simulación pura (sin nodos, tick fijo, determinista)
src/content/   Tipos de contenido (TowerDef, EnemyDef, EffectDef, WaveDef, MissionDef, MapDef) y ContentDB
content/       Contenido del juego (.tres editables en el inspector)
src/ui/        Interfaz (HUD y tema)
src/maps/      Script de las escenas de mapa
src/view/      Presentación isométrica (lee el estado de la simulación)
src/poc/       Utilidades de pruebas de rendimiento
maps/          Escenas de mapa editables y TileSets
art/placeholder/  Arte PROVISIONAL generado (se sustituirá)
tests/         Tests headless
tools/         Generadores, benchmark y servidor web local
docs/          Decisiones y resultados por fase
```

## Comandos
Sustituye `godot` por la ruta de tu ejecutable si no está en el PATH.

```bash
godot --headless --path . --import
```

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

```bash
godot --headless --path . --script res://tools/bench.gd -- 500 600
```

```bash
godot --path .
```

Exportar a web y probar en red local (Godot exige HTTPS fuera de `localhost`):

```bash
godot --headless --path . --export-release "Web" build/web/index.html
```

```bash
node tools/serve_web.mjs build/web 8443 --https
```

El modo `--https` necesita `.tools/dev-cert.pem` y `.tools/dev-key.pem` (certificado autofirmado, no versionado).

Balance (juega la misión con varias estrategias):

```bash
godot --headless --path . --script res://tools/balance.gd
```

En el juego: toca una plataforma para construir, mejorar o vender; **N** lanza la oleada, **Espacio** pausa, **R** reinicia, la rueda o el pellizco hacen zoom y el botón derecho o un dedo arrastran la cámara. **S** recorre el modo estrés (depuración).

> Tras clonar, ejecuta primero `--import` una vez: registra las clases de contenido (`TowerDef`…) que usan los tests.
