# Reino del Continue ampliado

Los mundos se quedaban cortos (unos 3-4 minutos) y cada sala hacía una sola cosa. Decisiones:
**mapa fijo grande** al estilo Hollow Knight (siempre igual, con desvíos, atajos y secretos) y **10-15 minutos
por mundo** en un intento. Este documento cubre el mundo 1; la Academia se ampliará después igual.

## El mapa (12 salas + Umbral, Nivel 1-1 de Kira y Trono)
```
Umbral ─ Inicio ─ Pasarela ─ Cruce ─ Arena de los Rastreros ─ Bloque Sorpresa ─ Doble Pantalla ─ Fuente ─ Arena de Élites ─ Trono
                               │                                   │
                               ├─ arriba: Torre de las Monedas ─ Azotea Dorada ┘ (atajo al Bloque, por arriba)
                               └─ abajo: Sótano de las Partidas (opcional)
```
| Sala | Qué enseña o exige |
|---|---|
| Pantalla de Inicio | saltar fosos, núcleos, primer escupidor, primera grieta, **muro agrietado** que hay que romper |
| Pasarela de los Escupidores | plataformas sobre un suelo de pinchos con escupidores en alto; fragmentos escondidos (con salto doble) |
| Cruce del Reino | sala vertical con cuatro salidas y un foso hacia el Sótano |
| Torre de las Monedas | subida larga hasta el **orbe de salto doble** |
| Azotea Dorada | camino alternativo: fragmentos escondidos, primer **élite**, grieta y bajada directa al Bloque |
| Arena de los Rastreros | **arena**: 3 oleadas |
| Bloque Sorpresa | dos muros rompibles, bloques con fragmentos, foso y la llegada del atajo |
| Doble Pantalla | subida que **pide salto doble** (si no se tiene, toca volver a la Torre) |
| Fuente del Guardado | **fuente**: vida y depuración al máximo, una vez por intento; grieta |
| Arena de Élites | **arena**: 3 oleadas con élites |
| Sótano de las Partidas | opcional: dos montones de fragmentos, grieta, élite |

## Mecánicas nuevas
- **Varias salidas por lado**: cada salida es un tramo del borde (`RoomDef.door`).
- **Bloques rompibles** («b»): dos clics. Los **bloques sorpresa** («n», con grietas doradas) sueltan 4 fragmentos.
  El clic hacia abajo rebota en ellos.
- **Arenas**: al entrar se cierran las puertas y salen las oleadas por puntos fijos. Al vaciar la última: +2
  corazones y 10 fragmentos. Una vez por intento.
- **Élites** (con corona dorada): ×2,2 de vida y doble de fragmentos. El rastrero es más rápido, el revoloteador
  dispara orbes y el escupidor lanza tres a la vez.
- **Fuente**: cura vida y depuración, una vez por intento.
- **Fragmentos escondidos**: 8 de golpe, una vez por intento.
- **Cada intento empieza con el mapa como nuevo**: bloques sin romper, arenas por superar y fuentes llenas.
- Las grietas pasan a 8 por intento (5 en el Reino y 3 en la Academia).

## Test de alcance
`tests/reach_tests.gd` calcula, sin física, dónde puede ponerse Álex y a dónde llega andando, saltando y con dash.
Comprueba que se alcanzan todas las salidas, objetos y entradas de cada sala (con salto doble), que el camino
principal hasta la Doble Pantalla se puede hacer sin él y que la Doble Pantalla no se sube sin él. Las salas que
piden salto en pared no se comprueban.

Tests: `game_tests.gd` 70/70 · `reach_tests.gd` 130/130.
