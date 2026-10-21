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
| Simulación y FPS en **web** de escritorio | ≤ 4 ms · ≥ 55 FPS | Pendiente: requiere las plantillas de exportación | ⏳ |
| FPS en web Android de gama media | ≥ 40 con 150 enemigos | Pendiente | ⏳ |
| Descarga inicial web (Brotli) | ≤ 12 MB | Pendiente | ⏳ |
| Arranque web | ≤ 5 s | Pendiente | ⏳ |

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
