# RIFT RUMBLE — Fase 7.1 y 7.2: campaña y mundo 1 completo

Fecha: 2026-10-22 · Diseño de referencia: [08-diseno-de-mundo.md](08-diseno-de-mundo.md)

> Nombres provisionales; ids neutros (`w1_m1`…`w1_m5`, `enemy_light_continue`, etc.).

## 7.1 · Campaña mínima

| Pieza | Archivo | Qué hace |
|---|---|---|
| Mundos | `WorldDef` + `content/worlds/w1…w6.tres` | Orden, nombre, ambientación, regla del mundo, color y 5 huecos de misión (los que aún no existen salen «en construcción») |
| Reglas de campaña | `src/content/campaign_rules.gd` | Desbloqueo secuencial. Los huecos sin misión no bloquean. Las misiones completadas siempre siguen disponibles. Un mundo se abre al completar el anterior |
| Pantalla «La Trama» | `src/ui/campaign_screen.gd`, `campaign.tscn` (escena principal) | Mundos, recorrido de misiones con estrellas y panel de **preparación**: 2 héroes y **hasta 4 torres** de las que se tienen |
| Sesión | autoload `Session` | Misión, héroes y torres elegidos para la partida |
| Guardado global | autoload `Save` | Progreso, héroes y torres que se tienen (iniciales: 2 y 3), últimos equipos elegidos y migración de `w1_m1` → `w1_m5` |
| Navegación | botones «Mapa» y «Volver al mapa» | Campaña → partida → resultados → campaña |

**Decisiones de diseño aplicadas:** héroes **y torres** por tiradas (aún sin implementar); equipo por misión; `MissionDef.towers` pasa a ser una restricción opcional.

## 7.2 · Mundo 1 completo

### Elementos de mapa (`src/sim/sim_objects.gd`)
Se colocan como `Marker2D` en el nodo `Objects` de la escena del mapa, con **metadatos** editables en el inspector:

| Tipo | Metadatos | Comportamiento |
|---|---|---|
| `block` | `hp`, `reward_gold`, `opens_route`, `opens_spot` | Lo golpean los héroes vivos y libres que estén cerca. Al romperse da oro y/o **abre un atajo** (ruta) y/o **una plataforma**. Los cerrados se ven como muro gris; los de premio, dorados y con pulso de luz |
| `platform` | `spot`, `to`, `period` | Mueve una posición de construcción, **con su torre**, en ida y vuelta suave |

**Monedas:** las sueltan los enemigos (`MissionDef.coin_drop_chance`, `coin_value`, `coin_lifetime`). Las recoge un héroe al pasar por encima o un toque, y parpadean antes de caducar.

**Atajos:** los grupos de una oleada asignados a una ruta cerrada entran por la principal hasta que se rompe el bloque.

### Misiones

| Id | Nombre | Novedad | Equipo |
|---|---|---|---|
| `w1_m1` | Pantalla de inicio | Tutorial con **pistas por evento** | Solo torre de corrupción, 1 héroe (Kira recomendada) |
| `w1_m2` | Monedas sueltas | Monedas | Libre |
| `w1_m3` | Bloque sorpresa | Bloques con premio, muro que abre atajo y plataforma, enemigo «con continue» | Libre |
| `w1_m4` | Doble pantalla | Dos entradas y plataforma móvil | Libre |
| `w1_m5` | El Rey del Reinicio | Jefe (de la Fase 5) | Libre |

**Contenido nuevo:**
- `enemy_light_continue`: deja un núcleo pequeño (`enemy_core_small`, 12 de vida, 5 s). Si sobrevive, el enemigo vuelve con toda su vida.
- Arte provisional: moneda, muro, bloque con premio y enemigo naranja con gema.

**Pistas** (`MissionDef.hints`, formato `evento|texto`): se muestran una sola vez cuando ocurre el evento (`start`, `tower_built`, `wave_started`, `coin_spawned`, `block_broken`, `route_opened`, `core_dropped`…).

### Herramientas
- `tools/build_maps_w1.gd`: generador común de los mapas `w1_m1`…`w1_m4`. Valida cada mapa y coloca el decorado lejos de rutas y elementos.
- `tools/balance.gd`: juega **cualquier misión** con estrategias genéricas (sin torres, una torre, equipo inicial con y sin mejoras) y con todas las colocaciones del equipo.

## Criterios de aceptación

| Criterio | Verificación | Estado |
|---|---|---|
| Campaña con desbloqueo guardado | Tests de reglas (en construcción, bloqueo, mundo siguiente, completadas disponibles) y migración | ✅ |
| Elegir equipo y jugar con él | Test de escena: la partida usa la misión, los héroes en orden y **solo** las torres del equipo | ✅ |
| Mecánicas del mundo 1 | Tests: monedas (soltar, recoger por toque o héroe, caducar), bloques (romper, oro, atajo, plataforma), plataforma móvil con torre | ✅ |
| **Toda misión ganable con lo inicial** | Test `test_world1_missions_winnable_with_starters`: cada misión tiene una colocación del equipo inicial que gana con los héroes quietos, y se pierde sin torres | ✅ |
| Contenido reutilizando sistemas | Las 4 misiones nuevas son datos, mapas generados y 2 sistemas genéricos (objetos y pistas) | ✅ |
| Prueba en dispositivo | Jugado en el iPhone; «todo bien por ahora» | ✅ |

Tests: 225 (simulación) + 23 (guardado) + 13 (escena) comprobaciones, 0 fallos.

## Pendiente
- **Tiradas** de héroes y torres (sistema, probabilidades, garantía, ecos).
- **Definir el reparto de héroes** (sesión de diseño con el usuario).
- Ramas de nivel 3 desbloqueadas por ecos.
- Mundo 2 (cristales, conjuradores interrumpibles, Alumno Eterno).
- Indicar en la vista previa por qué entrada llega cada grupo (misión 4).
