# RIFT RUMBLE — Fase 4: héroes y efectos

Fecha: 2026-10-21 · Motor: Godot 4.7.2

> Todos los nombres de elementos son **provisionales**. En el código se usan ids neutros: `hero_portal` (Nexo), `hero_blade` (Kira Volt), `syn_corrupt_slowed` (Error de sistema), etc.

## Qué se ha construido

### Héroes (`HeroDef`, `src/sim/sim_heroes.gd`)
Los héroes **luchan en el camino**:
- Al ordenarles moverse, van al punto del camino más cercano al toque.
- **Bloquean** a los enemigos que les alcanzan (`block_count`). Los bloqueados se detienen y les golpean (`EnemyDef.melee_damage` y `melee_interval`).
- Tienen **vida**, que **regeneran** cuando no luchan. Si **caen**, sueltan a sus enemigos y **reaparecen** pasado `respawn_time`.
- Su **ataque básico** reutiliza la misma lógica de disparo que las torres: el héroe lleva un perfil `TowerDef` incrustado que se mueve con él.
- **Habilidad activa** (desde las decisiones de la biblia, G-3/G-4: por **medidor** al 100 % en lugar de recarga), elegida por `ability_kind`. Un héroe nuevo que reutilice un tipo de habilidad existente no necesita código:

| Héroe | Habilidad | Mecánica |
|---|---|---|
| `hero_portal` (Nexo) | `portal` (Umbral) | La entrada queda junto al héroe y la salida en el punto elegido (alcance 9). Durante 6 s, las torres a ≤ 3 casillas de la entrada **sin objetivo propio** disparan a través del portal contra enemigos junto a la salida, con **+25 %** de daño |
| `hero_blade` (Kira Volt) | `line_strike` (Corte prismático) | Cada golpe básico suma **carga** (máx. 6). El corte daña a **todos los enemigos alineados** en la dirección elegida (5,5 casillas); daño = 8 + 4 × carga, y consume la carga |

### Sinergia «Error de sistema» (`SynergyDef`, en el sistema de efectos)
- Si el objetivo tiene **cualquier** ralentización o inmovilización (bits de estado, no un efecto concreto), la corrupción suma **+1 pila**.
- Al **alcanzar** el máximo de pilas, se **propaga** con 2 pilas a los 3 enemigos más cercanos (radio 1,8).
- La propagación **no reactiva sinergias**, así que no hay cadenas. Tampoco se repite mientras el objetivo siga en el máximo.

Es una regla de datos: no hay código específico de torres ni de héroes. Las próximas sinergias del diseño (*Multibola*, *Embudo dimensional*…) se añadirán como nuevos `SynergyDef` o, si necesitan condiciones nuevas, ampliando ese tipo.

### Revisión tras las pruebas en el móvil
| Cambio | Detalle |
|---|---|
| **Camino más ancho** | 2 casillas (`MapScene.path_width`). El mapa pasa a 20×14 y la ruta va por la línea central |
| **Carriles** | Los enemigos de las oleadas eligen uno de 3 carriles (centro y ±¼ del ancho), calculados con esquinas a inglete para que no haya saltos |
| **Menú sobre el hueco** | Al tocar una plataforma se abre encima un menú compacto: iconos de las torres con su coste, o mejorar/vender/cerrar. Sigue a la cámara. Desaparece el panel inferior |
| **Deseleccionar héroes** | Dar la orden de moverse deselecciona al héroe; tocarlo otra vez (en el mapa o en su tarjeta) también |
| **Cámara** | El encuadre inicial ajusta el mapa a la pantalla |

### Correcciones
- **Vistas de torres y portales identificadas por `uid`.** Un `Dictionary` usado como clave se identifica por su contenido, que cambia en cada tick. Esto podía duplicar vistas o dejar una torre dibujada tras venderla.
- **Proyectil que cruza un portal cuando su objetivo ya ha muerto:** ahora se desvanece en la salida en lugar de volver a la entrada.

## Criterios de aceptación

| Criterio | Verificación | Estado |
|---|---|---|
| Nexo y Kira Volt implementados | Contenido en `content/heroes/`, jugados en el iPhone | ✅ |
| Habilidades activas con recarga | Test: recarga respetada, disponible al terminar; carga acumulada, limitada y consumida | ✅ |
| Las habilidades **cambian el combate** | Test `test_hero_abilities_change_the_outcome`: en la oleada 3 con una torre, usar el corte reduce las fugas | ✅ |
| Portal funcional y limitado | Test: sin portal la torre no alcanza; con portal sí (×1,25); al cerrarse deja de alcanzar; alcance máximo de la salida | ✅ |
| Héroes en el camino | Tests: el destino se ajusta al camino; bloquea hasta su capacidad; recibe daño; cae, suelta enemigos y reaparece; regenera | ✅ |
| Sinergia funcional sin duplicar lógica | Tests: pila extra solo con ralentización; propagación al alcanzar el máximo a 3 cercanos; sin cadenas ni repeticiones | ✅ |
| Balance coherente con héroes | `tools/balance.gd`: sin torres se pierde en la oleada 2; con una torre, en la 3; con tres composiciones distintas se gana | ✅ |

Tests: 37 tests, 139 comprobaciones, 0 fallos.

## Pendiente o riesgos
- **Vista previa al apuntar** (alcance, línea del corte, salida del portal antes de confirmar). Se ha probado sin ella y se entiende, pero mejoraría la precisión.
- **Enemigos que atacan a distancia o vuelan** (no bloqueables): previstos en el diseño, sin implementar.
- **Balance**: sigue siendo provisional; la Fase 5 ajustará 5 oleadas y el jefe.
- **Selección de héroes antes de la misión**: la misión despliega los dos héroes del MVP; el menú de selección llegará con la progresión.
