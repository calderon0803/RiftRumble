# RIFT RUMBLE

> *Defiende tu mundo. Rompe las reglas.*

Tower defense isométrico 2.5D con héroes. Estado actual: **Fase 1, prueba de concepto**.
Decisión tecnológica y plan: [docs/01-decision-tecnologica.md](docs/01-decision-tecnologica.md).

## Requisitos
- Godot **4.7.x** estable, versión estándar con GDScript (no la .NET).

## Estructura
```
src/sim/    Simulación pura (sin nodos, tick fijo, determinista)
src/view/   Presentación isométrica (lee el estado de la simulación)
src/poc/    Datos provisionales del mapa de la PoC
tests/      Tests headless de la simulación
tools/      Benchmarks y utilidades
docs/       Decisiones y resultados
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
