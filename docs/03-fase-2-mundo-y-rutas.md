# RIFT RUMBLE — Fase 2: mundo y rutas

Fecha: 2026-10-21 · Motor: Godot 4.7.2

## Qué se ha construido

| Pieza | Archivo | Notas |
|---|---|---|
| Datos lógicos del mapa | `src/content/map_def.gd` | Tamaño, rutas (lista, preparada para rutas alternativas), posiciones de construcción y `validate()` |
| Escena de mapa editable | `src/maps/map_scene.gd` + `maps/continue_01.tscn` | `Ground` (TileMapLayer isométrico), `Props` (Y-sort), `Routes/Route0` (Path2D) y `BuildSpots/*` (Marker2D). `build_def()` lo convierte a casillas lógicas |
| TileSet isométrico | `maps/tilesets/continue_ground.tres` | Casillas de 64×32 en rombo, del atlas `ground_tiles.png` |
| Andamiaje del mapa | `tools/build_continue_map.gd` | Generador de un solo uso: **sobrescribe** el mapa. A partir de ahora, el mapa se edita en el editor |
| Arte provisional | `tools/gen_placeholder_art.gd` → `art/placeholder/` | Suelo, bloque, arbusto, enemigo animado (4 frames), torre, plataforma de construcción y proyectil. **Todo es temporal** |
| Cámara | `src/view/camera_rig.gd` | Arrastre con ratón o un dedo, zoom con rueda, pellizco o trackpad hacia el punto señalado, y límites del mapa |
| Vista con sprites | `src/view/*_view.gd` | Textura compartida, animación desincronizada, orientación según la dirección y barra de vida solo si hay daño |

### Cómo editar el mapa
1. Abre `maps/continue_01.tscn` en el editor de Godot.
2. Para pintar el suelo, selecciona `Ground` y usa la pestaña TileMap.
3. Para cambiar la ruta, selecciona `Routes/Route0` y mueve sus puntos. Para añadir rutas alternativas, crea más `Path2D` dentro de `Routes`.
4. Para mover o añadir posiciones de construcción, mueve o añade `Marker2D` dentro de `BuildSpots`.
5. Ejecuta los tests: comprueban que el mapa es válido y que el camino pintado coincide con la ruta lógica.

> Las coordenadas se ajustan a medias casillas al leerlas, así que pequeñas imprecisiones al arrastrar en el editor no importan.

## Criterios de aceptación

| Criterio | Verificación | Estado |
|---|---|---|
| Los enemigos recorren la ruta correctamente | Test `test_enemy_traverses_real_map_route`: llega en el tick esperado (±1) | ✅ |
| Llegan a la base y le restan vida | Mismo test (`base_hp` 20 → 19) | ✅ |
| Movimiento visualmente coherente | Capturas: siguen el camino, animación y orientación correctas | ✅ |
| El suelo dibujado coincide con la simulación | Tests `test_tilemap_matches_iso_projection` y `test_ground_path_tiles_match_route` | ✅ (el test **detectó** un desfase de media casilla entre TileMapLayer y la proyección, ya corregido) |
| Profundidad (Y-sort) entre enemigos, torres y decorado | Capturas en modo normal y estrés | ✅ |
| Mapa con 3 posiciones de construcción | Test `test_map_def_is_valid` | ✅ |
| Cámara con arrastre, zoom y límites | Probada en el iPhone (sin incidencias reportadas) | ✅ |
| Rendimiento con sprites | iPhone 14 Pro: **60 FPS con 150, 300 y 500 enemigos** (antes 60/45/30). Nativo: 144 FPS (vsync) con 500 | ✅ |

Tests: 15 tests, 37 comprobaciones, 0 fallos. Benchmark sobre el mapa real: 500 enemigos con unos 380 proyectiles, 0,41 ms/tick de media.

## Pendiente o riesgos
- **Android de gama media**: sigue sin medir.
- **Tiempo de carga en un hosting real con Brotli**: sigue sin medir. Conviene hacerlo al publicar una primera build de pruebas (itch.io o Cloudflare Pages).
- El arte es provisional. La dirección artística definitiva (paleta del Reino del Continue, personajes y bloques con identidad propia) necesita una guía de estilo antes de producir arte final.
- Rutas alternativas: los datos ya las admiten (`routes` es una lista), pero la simulación usa solo la primera. Se activarán cuando una misión las necesite.
