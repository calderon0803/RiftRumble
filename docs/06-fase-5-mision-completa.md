# RIFT RUMBLE — Fase 5: misión completa

Fecha: 2026-10-21 · Motor: Godot 4.7.2

> Nombres provisionales. Ids: `enemy_boss_w1` (Rey del Reinicio), `enemy_core` (núcleo), `w1_m1`.

## Qué se ha construido

### Misión de 5 oleadas con jefe (`content/missions/w1_m1.tres`)
| Oleada | Composición | Bonificación |
|---|---|---|
| 1 | 10 ligeros | 20 |
| 2 | 10 ligeros + 8 rápidos | 25 |
| 3 | 14 ligeros + 6 acorazados + 12 rápidos | 30 |
| 4 | 16 ligeros + 8 acorazados + 14 rápidos | 40 |
| 5 | **Jefe** + 12 ligeros + 6 acorazados + 10 rápidos | — |

### Mecánicas genéricas de enemigos (`EnemyDef`, reutilizables)
- **Núcleo de reaparición** (`revive_core`, `revive_delay`, `revive_hp_ratio`). Al morir, el enemigo deja un núcleo inmóvil. Si sobrevive el tiempo indicado, el enemigo reaparece **una sola vez** con parte de su vida. Es la regla del mundo 1: «reaparece si su núcleo no ha sido destruido».
- **Invocación** (`summon_enemy`, `summon_interval`, `summon_count`).
- **Jefe** (`is_boss`): la interfaz muestra su barra de vida y la del núcleo, con su cuenta atrás.

**Jefe del mundo 1:** 420 de vida, armadura 0,35, lento, 10 de daño a la base. Invoca 2 ligeros cada 7 s. Su núcleo tiene 140 de vida y le deja 8 s; si el jefe reaparece, lo hace con el 50 % de su vida.

### Ritmo y economía
- **Cuenta atrás entre oleadas** de 20 s. Lanzar una oleada antes da **1 de oro por segundo adelantado**.
- **Estadísticas** de la partida en la simulación (`stats`): bajas, fugas, oro ganado y gastado, torres, habilidades, héroes caídos y oro por adelantar.
- **Estrellas**: 3 con ≥ 90 % de la vida de la base, 2 con ≥ 50 % y 1 con una victoria apurada.

### Interfaz y feedback
- Botón de oleada con la cuenta atrás y el oro por adelantarla.
- Carteles de oleada («OLEADA 3/5», «OLEADA FINAL», «¡Destruye el núcleo!», oro por adelantar).
- Barra del jefe (arriba a la derecha) y anillo de cuenta atrás alrededor del núcleo.
- **Pantalla de resultados** con estrellas dibujadas y 10 estadísticas.

### Audio (`src/audio/audio_director.gd`, `audio/placeholder/`)
- 22 efectos **provisionales** generados por síntesis (`tools/gen_placeholder_sfx.gd`): disparos por tipo de daño, impactos, bajas, fugas, economía, oleadas, héroes, sinergia, jefe, victoria y derrota.
- El director traduce eventos a sonidos con **intervalo mínimo por sonido**, 16 voces y variación de tono, para no saturar con cientos de enemigos.
- Sustituir el audio definitivo = reemplazar los `.wav` por nombre.

## Criterios de aceptación

| Criterio | Verificación | Estado |
|---|---|---|
| 5 oleadas y jefe | Test `test_full_mission_flow`: se juegan las 5 oleadas | ✅ |
| Partida de principio a fin sin bloqueos | Mismo test: con defensa razonable se gana, sin ella se pierde; jugada completa en el iPhone | ✅ |
| Duración de 3–6 min | El test lo comprueba; balance: unos 4,5–5 min | ✅ |
| Mecánicas del jefe | Tests: núcleo → reaparición única con el 50 %; núcleo destruido → no reaparece; invocación periódica | ✅ |
| Economía con decisiones | Tests de cuenta atrás y oro por adelantar; balance con estrategia agresiva | ✅ |
| Pausa y reinicio limpios | `tests/scene_tests.gd`: 10 reinicios sin acumular nodos (108 → 108) ni huérfanos; en pausa la simulación no avanza | ✅ |
| Pantalla de resultados | Estrellas y estadísticas (test de estrellas y estadísticas) | ✅ |
| Dificultad | Balance: sin torres → oleada 2; una torre → oleada 3; tres sin mejorar → oleada 4; tres mejoradas → 1★; + Kira → 2★. Prueba en el iPhone: **3★ mejorando las tres torres al máximo** | ✅ |

Tests: 44 tests de simulación (172 comprobaciones) + 5 comprobaciones de escena, 0 fallos. Build web: 7,0 MB con Brotli.

## Ajustes tras las pruebas
- El núcleo tenía 30 de vida y caía antes de que se viera: se sube a **140** con **8 s** de margen, se dibuja 1,6 veces más grande y se añade el **anillo de cuenta atrás**.

## Pendiente o riesgos
- **Oro sobrante al final**: con 3 posiciones, al llegar a nivel 3 ya no hay en qué gastar. Habrá que tenerlo en cuenta con más posiciones de construcción o mejoras de héroe.
- En las simulaciones automáticas el jefe suele escapar con vida (los héroes se quedan quietos). Un jugador activo puede derrotarlo, como confirmó la prueba.
- Aviso de «recurso en uso al salir» en las ejecuciones sin ventana: es un sonido que el servidor de audio retiene al cerrar el motor de forma inmediata, no una fuga durante el juego (el test de escena lo confirma).
- **Accesibilidad y ajustes** (volumen, silenciar, velocidad x2): pendientes para la Fase 8.
