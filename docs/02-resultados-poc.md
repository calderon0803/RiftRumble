# RIFT RUMBLE — Resultados de la prueba de concepto

Motor: Godot 4.7.2.stable.official (Windows x64, renderer Compatibility). Fecha: 2026-10-21.

## Estado de los criterios (§6 de `01-decision-tecnologica.md`)

| Criterio | Umbral | Resultado | Estado |
|---|---|---|---|
| Tests headless de simulación | 100 % | 11 tests, 26 comprobaciones, 0 fallos | ✅ |
| Simulación con 300 enemigos y unos 200 proyectiles (nativo) | ≤ 4 ms/tick | 0,28 ms de media, 0,68 ms de máximo (406 proyectiles) | ✅ en nativo |
| Simulación con 500 enemigos y unos 400 proyectiles (nativo) | — | 0,46 ms de media, 0,96 ms de máximo | ✅ |
| Simulación con 1000 enemigos (nativo) | — | 0,48 ms de media, 1,56 ms de máximo | ✅ |
| Render nativo, modo estrés (500 enemigos, 12 torres) | — | 111 FPS en ventana, sim 0,26 ms | ✅ |
| Ordenación en profundidad (Y-sort) | Sin errores visibles | Correcta en las capturas | ✅ |
| Simulación en **web** de escritorio (Chromium 152, un solo hilo), 500 enemigos + 12 torres | ≤ 4 ms/tick | 0,36 ms de media, 1,45 ms de máximo | ✅ |
| FPS en web de escritorio | ≥ 55 | Modo normal: 72 FPS (límite de refresco del panel). Estrés en escritorio no medido con el panel visible; el iPhone, más limitado, ya supera el umbral | ✅ (por inferencia) |
| **iOS Safari** (iPhone 14 Pro, HTTPS en red local) | Arranca y funciona | ✅ Carga y se ejecuta (era un riesgo conocido de WebGL2 en Safari) | ✅ |
| FPS en iPhone 14 Pro, modo normal | — | 60 FPS (límite de Safari) | ✅ |
| FPS en iPhone 14 Pro, 500 enemigos + 12 torres | — | 30–32 FPS, sim 0,27 ms/tick → **el cuello de botella es el render, no la simulación** | ⚠️ |
| FPS en iPhone 14 Pro con **150** enemigos + 12 torres | ≥ 40 | **60 FPS** (límite de Safari) | ✅ |
| FPS en iPhone 14 Pro con 300 enemigos + 12 torres | — | 45 FPS | ✅ |
| FPS en Android de gama media | ≥ 40 con 150 enemigos | Sin dispositivo disponible: **riesgo abierto**, medir al inicio de la Fase 2 con sprites reales | ⏳ |
| Descarga inicial web | ≤ 12 MB | **6,88 MB con Brotli** (9,81 con gzip; 38 MB sin comprimir, de los que 37,7 MB son el `.wasm` del motor) | ✅ |
| Arranque web (local, caché vacía) | ≤ 5 s | `.wasm` descargado en 0,26 s en local. En red real dominará la descarga: unos 1,1 s a 50 Mbps con Brotli | ✅ (estimado; medir en un hosting real) |

### Exportación web
- Plantilla `web_nothreads_release` (un solo hilo, sin cabeceras COOP/COEP).
- `export_presets.cfg` excluye `tests/`, `tools/` y `docs/`. El `.pck` del juego ocupa unos 46 KB; casi todo el tamaño es el motor.
- Margen de reducción si hace falta: plantilla personalizada sin 3D ni módulos no usados (las mediciones de la comunidad indican un 20–40 % menos).
- Servidor local: `node tools/serve_web.mjs build/web 8060`.

### Lectura
- La simulación usa menos del 5 % del presupuesto de un tick a 30 Hz incluso con 1000 enemigos en nativo. En web, GDScript sobre WASM suele ser entre 2 y 5 veces más lento: incluso en el peor caso queda margen de sobra frente al umbral de 4 ms.
- La búsqueda de objetivos es fuerza bruta (torres × enemigos). Con 12 torres no importa; con 30 o más torres y efectos de área convendrá una rejilla espacial (prevista en la arquitectura).
- La vista usa un nodo con `_draw()` por entidad y redibuja solo cuando cambia la vida. Con sprites reales el coste cambiará: hay que repetir la medición en la Fase 2 con spritesheets.

## Reproducir
```bash
godot --headless --path . --script res://tests/run_tests.gd
```

```bash
godot --headless --path . --script res://tools/bench.gd -- 300 600 0.1 2
```

```bash
godot --path . -- --stress --screenshot=stress.png --frames=300
```

## Decisión (go/no-go)

**GO con Godot 4.7 + GDScript.** Todos los criterios medibles se cumplen con margen:
- La simulación usa menos del 1 % del presupuesto incluso en el móvil.
- Se descargan 6,9 MB con Brotli.
- iOS/Safari funciona y da 60 FPS con 150 enemigos.

Cuestiones que pasan a la Fase 2:
1. Medir en un Android de gama media en cuanto haya dispositivo.
2. El render es el cuello de botella con más de 300 entidades. Hay que repetir la medición con sprites reales (textura compartida, que se dibuja de forma más eficiente) y, si hace falta, usar `MultiMeshInstance2D` para enemigos comunes.
3. El arranque web se ha medido en una red local sin compresión (unos 9,5 s con 38 MB). Hay que medirlo en un hosting real con Brotli.
4. Godot web exige un contexto seguro (HTTPS): para pruebas en red local, `node tools/serve_web.mjs build/web 8443 --https` (certificado autofirmado en `.tools/`).
