# RIFT RUMBLE — Fase 3: combate y economía

Fecha: 2026-10-21 · Motor: Godot 4.7.2

## Diseño

### El contenido son datos (`content/`)
| Tipo | Script | Archivos |
|---|---|---|
| Efectos | `EffectDef` | `content/effects/` — corrupción, sello, inmovilización por sellos |
| Enemigos | `EnemyDef` | `content/enemies/` — Glitchling (ligero), Cascarón (acorazado), Zumbador (rápido) |
| Torres | `TowerDef` | `content/towers/` — Pixeladora, Grimorio de Guardia, Rebote Supremo |
| Misiones y oleadas | `MissionDef` + `WaveDef` | `content/missions/continue_01.tres` (3 oleadas de prueba) |

`ContentDB` carga todas las definiciones de cada carpeta. **Añadir una torre o un enemigo es añadir un `.tres`**: no hay que tocar ningún sistema. Los valores se editan en el inspector de Godot.

### Una sola lógica de ataque; la identidad sale de los datos
| Torre | Tipo de daño | Mecánica propia (por datos) |
|---|---|---|
| Pixeladora | digital | Aplica **corrupción**: +15 % de daño recibido por pila (máx. 3) de *otros* tipos. Nivel 3 (*Desfragmentación*): ignora el 60 % de la armadura |
| Grimorio de Guardia | mágico (ignora armadura) | Aplica **sellos**: −20 % de velocidad por pila; al 3.º sello, **inmoviliza** 1,2 s y da 3 s de inmunidad a sellos |
| Rebote Supremo | cinético | **Rebota** 2/3/5 veces a enemigos distintos (×0,85 de daño por salto). Contra un objetivo aislado no rebota |

### Sistema de efectos (`src/sim/sim_effects.gd`)
Es genérico: pilas acotadas, duración renovable, ralentización multiplicativa, inmovilización, daño recibido según el tipo y un efecto encadenado al llegar al máximo de pilas, con inmunidad posterior. Protecciones: profundidad máxima de encadenamiento de 3, todos los efectos con duración finita e inmunidad para evitar bloqueos permanentes. La vista recibe solo bits de estado (ralentizado, inmovilizado, corrompido) y no conoce los efectos concretos.

### Economía y comandos
La simulación valida construir, mejorar, vender y lanzar una oleada, y devuelve el motivo si rechaza el comando (`no_gold`, `occupied`, `max_level`…). La interfaz solo emite peticiones, así que no puede gastar oro inexistente ni saltarse reglas.

### Interfaz (`src/ui/`)
Barra superior con oro, vida y oleada, el botón para lanzar la oleada, pausa y reinicio. Un panel contextual sirve para construir o para mejorar y vender, y hay una pantalla de victoria o derrota. El tema es provisional y está centralizado en `ui_theme.gd`.

## Criterios de aceptación

| Criterio | Verificación | Estado |
|---|---|---|
| Cada torre tiene su mecánica propia | Tests: corrupción (pilas, solo otros tipos, expiración), 3 sellos → inmovilización + inmunidad, rebote a objetivos distintos y sin rebote contra uno solo | ✅ |
| Alcance e intervalos | Tests heredados de la PoC (alcance, intervalo, objetivo «primero») | ✅ |
| Armadura según el tipo de daño | Test: cinético reducido, mágico la ignora, penetración parcial | ✅ |
| No se puede gastar oro inexistente | Test de economía: sin oro no se construye ni se mejora, y el oro no cambia | ✅ |
| Construir, mejorar y vender | Test: costes, nivel máximo, reembolso del 70 %, posición ocupada o inexistente | ✅ |
| Recompensas y fugas | Test: botín al eliminar, `base_damage` al llegar | ✅ |
| Oleadas | Test: aparecen todos los enemigos y no se solapan oleadas | ✅ |
| Victoria y derrota | Tests: sin torres se pierde; con una defensa razonable se gana. Partida completa en la build (autojuego acelerado) hasta la pantalla de victoria | ✅ |
| **El jugador completa oleadas tomando decisiones reales** | `tools/balance.gd`: sin torres o con una sola se pierde; con tres composiciones distintas se gana con fugas en la oleada 3. Jugado en el iPhone sin incidencias | ✅ |

Tests: 26 tests, 97 comprobaciones, 0 fallos.

## Herramientas nuevas
- `tools/balance.gd`: juega la misión con estrategias predefinidas y resume cada oleada (bajas, fugas, vida y oro). Base para el balance de la Fase 5.
- Argumentos de la escena: `--autoplay`, `--speed=N` y `--select=N` (además de `--screenshot` y `--stress`).

## Pendiente o riesgos
- **Balance**: provisional. Al jugador le sobra oro con estrategias pasivas; la Fase 5 ajustará la economía de las 5 oleadas y el jefe.
- **Mejoras con ramas**: las mejoras con nombre del diseño (*Cadena de errores*, etc.) son por ahora niveles lineales. La propagación de la corrupción entra con la sinergia de la Fase 4.
- **Interfaz en vertical en el móvil**: el panel de construir, de unos 500 px de ancho, está pensado para horizontal.
- La búsqueda de objetivos sigue siendo por fuerza bruta. Basta para el MVP (0,57 ms/tick con 500 enemigos y 12 torres de rebote).
