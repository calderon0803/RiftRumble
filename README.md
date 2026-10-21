# RIFT RUMBLE

> *Defiende tu mundo. Rompe las reglas.*

Tower defense isométrico 2.5D con héroes. Estado actual: **Fase 2 completada (mundo y rutas)**. Siguiente: Fase 3 (combate y economía).
Documentación: [decisión tecnológica](docs/01-decision-tecnologica.md) · [resultados de la PoC](docs/02-resultados-poc.md) · [Fase 2](docs/03-fase-2-mundo-y-rutas.md).

## Requisitos
- Godot **4.7.x** estable, versión estándar con GDScript (no la .NET).

## Estructura
```
src/sim/       Simulación pura (sin nodos, tick fijo, determinista)
src/content/   Definiciones de datos (MapDef…)
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

En el juego: **S** o el botón *Estrés* recorre 150/300/500 enemigos con 12 torres, **R** reinicia, **Espacio** pausa, la rueda hace zoom y el botón derecho arrastra la cámara.
