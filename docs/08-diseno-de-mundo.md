# RIFT RUMBLE — Diseño de mundo y campaña (propuesta)

> Estado: **revisada con decisiones del 2026-10-21** (ver §10). Todos los nombres son provisionales; en datos y código se usarán ids neutros (`w1`…`w6`, `w1_m1`…).

## 1. Principios

1. **Cada mundo rompe una regla distinta.** Además de su estética, cada mundo trae 1 o 2 mecánicas propias del mapa y un tipo de enemigo que obliga a cambiar de táctica. El lema «Rompe las reglas» se aplica a la jugabilidad, no solo a la narrativa.
2. **Una mecánica nueva cada vez.** Cada misión presenta como mucho una idea nueva y la combina con las anteriores. El jefe del mundo es el examen de todas ellas.
3. **Partidas cortas, campaña larga.** Misiones de 3 a 6 min. Unos 5 por mundo dan unos 25 min de campaña por mundo, más la rejugabilidad por estrellas.
4. **Héroes y torres por tiradas.** Ambos se consiguen con **tiradas** (estilo gacha) pagadas con **hilos** ganados jugando (ver §5). Antes de cada misión se elige un **equipo**: 2 héroes y hasta 4 torres de las que se tengan.
6. **Ganable con lo inicial.** Toda misión debe poder ganarse con los héroes y torres **iniciales** y buen juego. Lo obtenido por tiradas amplía estrategias y sinergias, pero nunca es obligatorio.
5. **La lectura táctica manda.** Ninguna mecánica de mundo puede tapar rutas, proyectiles o enemigos importantes sin dar una forma clara de contrarrestarla.

## 2. Estructura de la campaña

```
La Trama (mapa de campaña)
 ├─ Mundo 1 · Reino del Continue      5 misiones (4 + jefe)
 ├─ Mundo 2 · Academia del Último Hechizo   5
 ├─ Mundo 3 · La Última Sesión        5
 ├─ Mundo 4 · Neón de Medianoche      5
 ├─ Mundo 5 · Vertedero de Ideas      5
 └─ Mundo 6 · Frontera Imposible      5 (jefe final: el Editor)
```

- **Desbloqueo:** completar una misión abre la siguiente; vencer al jefe abre el mundo siguiente. Las estrellas no bloquean el avance.
- **Rejugabilidad:**
  - **3 estrellas** en cada misión.
  - **Modo «Rompe las reglas»:** se desbloquea al vencer al jefe y aplica a cada misión 1 o 2 modificadores del mundo (§6), con recompensas mayores.
  - **Retos diarios:** más adelante; una misión ya jugada con modificadores aleatorios fijados por semilla. Encaja con la simulación determinista.
- **Mapa de campaña:** la Trama como tapiz de hilos que conecta islas-mundo. Cada misión es un nodo con su récord de estrellas. Entre mundos hay escenas breves de diálogo, 3 o 4 líneas como máximo.

## 3. Temática por mundo (referencia; héroes y torres se obtienen por tiradas)

> **Decisión (2026-10-21):** héroes **y torres** se obtienen por tiradas, así que **no van ligados a ningún mundo**. Esta tabla queda como **referencia temática**: qué personajes, torres y sinergias encajan con la estética y las mecánicas de cada mundo (útil para «destacados» de tiradas o recomendaciones en la preparación). La lista de héroes sigue pendiente de definir.

| Mundo | Héroes nuevos | Torre nueva | Sinergia que se presenta |
|---|---|---|---|
| 1 · Reino del Continue | Nexo, Kira Volt *(ya hechos)* | Pixeladora, Grimorio, Rebote *(ya hechas)* | Error de sistema *(hecha)* |
| 2 · Academia del Último Hechizo | Madame Segundero | Cronoáncora | Tiempo prestado (Cronoáncora + Segundero) |
| 3 · La Última Sesión | Tramoya, Don Remache | — (la revelación la aportan héroes y mejoras) | Fuera de guion (Martillo + Pincel) |
| 4 · Neón de Medianoche | Bit | Polarizadora | Embudo dimensional (Polarizadora + Nexo), Combo infinito (Zapper + Pixeladora + Bit) |
| 5 · Vertedero de Ideas | Bric, Miga | Gallinámbula | Multibola (Rebote + Miga) |
| 6 · Frontera Imposible | — (todo el reparto) | — | Todas, combinadas |

- **Héroes por misión:** se eligen **2** de los que el jugador tenga antes de cada misión. Se empieza con dos héroes iniciales (hoy, Nexo y Kira Volt) para que el tutorial y el mundo 1 sean jugables sin tiradas.
- **Torres por misión:** se eligen **hasta 4** de las que tenga el jugador. Las tres torres iniciales (corrupción, sellos y rebote) están disponibles desde el principio. Una misión puede **restringir** torres de forma opcional (`MissionDef.towers`, por historia o como reto); vacía = cualquiera.

## 4. Los seis mundos

### Mundo 1 · Reino del Continue
- **Inspiración:** arcade y plataformas clásicos. **Paleta:** cielo cian, verde intenso, ladrillo cálido y oro.
- **Regla del mundo: «Continúa».** Algunos enemigos llevan un **núcleo**: al morir dejan el núcleo y, si no lo destruyes a tiempo, reaparecen una vez. *(Mecánica ya hecha para el jefe.)*
- **Elementos de mapa:**
  - **Monedas sueltas:** aparecen al eliminar enemigos o en puntos fijos. Las recoge el héroe que pasa por encima, o un toque, y dan oro. Premian mover a los héroes.
  - **Bloques interactivos:** se rompen con daño. Al romperse, sueltan una recompensa (oro, una mejora temporal de torre) o **abren un atajo**. Riesgo y recompensa: el atajo acorta el camino de los enemigos, pero da acceso a una plataforma extra.
  - **Plataformas móviles:** una posición de construcción que se desplaza entre dos tramos de la ruta cada N segundos. La torre cubre zonas distintas según el momento.
  - **Rutas alternativas:** bifurcaciones. Cada grupo de una oleada elige ruta, y la previa de la oleada lo muestra.
- **Enemigo de mundo:** «ligero con continue» (lleva núcleo).
- **Jefe:** Rey del Reinicio *(hecho)*. Mejora prevista: «Reinicio de nivel», que una vez por combate devuelve los bloques rotos a su estado inicial.
- **Narrativa:** el Editor convierte el reino en una partida que se reinicia sin fin. El Rey cree que ganar es imposible y que solo cabe volver a empezar.

### Mundo 2 · Academia del Último Hechizo
- **Inspiración:** fantasía mágica y academias. **Paleta:** violeta, dorado y azul noche.
- **Regla del mundo: «Resonancia».** **Cristales**: las torres cercanas a un cristal ganan alcance y daño. Algunos cristales flotan y cambian de isla.
- **Elementos de mapa:** islas flotantes unidas por puentes que se activan y desactivan, de modo que la ruta cambia entre oleadas; también runas en el suelo que potencian efectos.
- **Enemigo de mundo:** **conjuradores** que **cargan un hechizo** (barra visible). Si no se **interrumpen** con aturdimiento, empuje o inmovilización, curan, protegen o aceleran a los demás. Da protagonismo al control (sellos, martillo).
- **Nuevo:** Madame Segundero + **Cronoáncora**, con la sinergia **Tiempo prestado**.
- **Jefe:** **Alumno Eterno.** Se **adapta al tipo de daño** que más recibe y gana resistencia a él por fases. Obliga a diversificar torres.
- **Narrativa:** el Editor ofrece a los alumnos «la respuesta correcta a todo». El Alumno Eterno nunca se gradúa porque teme equivocarse.

### Mundo 3 · La Última Sesión
- **Inspiración:** cine de terror y cines abandonados. **Paleta:** negro, rojo granate y verde fósforo.
- **Regla del mundo: «Fuera de plano».** **Niebla y oscuridad**: hay zonas donde los enemigos son **invisibles** para las torres hasta que se **revelan** (luz de proyector, habilidades, mejoras de detección).
- **Elementos de mapa:** proyectores que hay que activar para iluminar tramos; **señuelos** (enemigos falsos que atraen disparos); butacas que bloquean posiciones hasta despejarlas.
- **Enemigos de mundo:** acechadores invisibles y señuelos.
- **Nuevos:** Tramoya (Pincel de Realidad: pinta zonas y altera rutas) + Don Remache (defensa, barrera), con la sinergia **Fuera de guion**.
- **Jefe:** **Proyeccionista.** **Cambia de escena** por fases: rueda la película hacia atrás (los enemigos retroceden y se curan), apaga luces, invierte el orden de la ruta.
- **Narrativa:** el Editor quiere un final que no sorprenda a nadie; el Proyeccionista corta las escenas «que sobran».

### Mundo 4 · Neón de Medianoche
- **Inspiración:** ciudades futuristas. **Paleta:** magenta, cian y negro azulado.
- **Regla del mundo: «Red».** **Generadores**: cada torre necesita estar en la zona de un generador encendido. Los enemigos «saboteadores» los apagan y el jugador los vuelve a encender.
- **Elementos de mapa:** **trenes** que cruzan la ruta y hacen daño a quien pille en las vías, enemigos o héroes; **zonas de velocidad** que aceleran a los enemigos; rutas alternativas por niveles.
- **Enemigos de mundo:** saboteadores y motoristas rápidos.
- **Nuevos:** Bit (Zapper: marca y encadena) + **Polarizadora**, con **Embudo dimensional** y **Combo infinito**.
- **Jefe:** **Administrador.** **Toma el control** de una torre durante unos segundos, que pasa a disparar a tus héroes, y pide «permisos» (núcleos que hay que destruir).
- **Narrativa:** una ciudad optimizada en la que nadie sabe por qué hace lo que hace.

### Mundo 5 · Vertedero de Ideas
- **Inspiración:** cultura de Internet, surrealismo y humor absurdo. **Paleta:** colores saturados en conflicto, a propósito.
- **Regla del mundo: «Tendencia».** **Modificadores de oleada** que cambian cada oleada y se anuncian antes: «los enemigos pequeños son enormes», «las torres cuestan la mitad pero disparan al azar», «todo rebota».
- **Elementos de mapa:** objetos cotidianos gigantes como obstáculos y plataformas; **interactivos de riesgo y recompensa** (un botón «no pulsar» que da oro o suelta una oleada sorpresa).
- **Enemigos de mundo:** **virales**, que se **multiplican si se ignoran** (se dividen si pasan N segundos sin recibir daño). Castigan descuidar un tramo de la ruta.
- **Nuevos:** Bric (Gallinámbula) + Miga (Aspiraversos) + **Gallinámbula**, con **Multibola**.
- **Jefe:** **Algoritmo.** **Reescribe los modificadores activos** en mitad del combate, con un aviso previo para que sea legible.
- **Narrativa:** ideas desechadas de todos los mundos; el Editor quiere borrarlas por inútiles.

### Mundo 6 · Frontera Imposible
- **Inspiración:** fantasía épica y mundos paralelos. **Paleta:** piedra antigua con vetas de la paleta de cada mundo.
- **Regla del mundo: «Mezcla».** Cada misión **combina dos reglas de mundos anteriores** (cristales y niebla, generadores y tendencias…).
- **Elementos de mapa:** portales que conectan tramos de ruta y maquinaria colosal.
- **Enemigos de mundo:** **híbridos**, versiones de enemigos anteriores con dos mecánicas.
- **Jefe final:** **el Editor.** **Altera las reglas del combate** por fases: desactiva un tipo de torre, invierte la ruta, copia una habilidad de tus héroes. Cada fase se anuncia y tiene respuesta. El combate final se gana usando lo aprendido en los cinco mundos.
- **Narrativa:** el Editor no es malvado sin más: cree que la imprevisibilidad causa sufrimiento. El desenlace celebra que la diferencia y el caos también crean.

## 5. Progresión, hilos y tiradas de héroes

**Fuentes de hilos:** las recompensas por misión actuales (primera victoria, estrellas nuevas, repetición), con más en el modo «Rompe las reglas» y en los retos.

### Tiradas (gacha) de héroes y torres
- **Coste:** hilos ganados jugando. **Sin dinero real** en el alcance actual.
- **Rarezas:** **7** (común, poco común, rara, épica, legendaria, mítica y trascendente), definidas en la [biblia de personajes](personajes/README.md); tasas y garantías de prueba en su [G-16](personajes/G-decisiones-pendientes.md). Las **probabilidades se muestran** siempre en la pantalla de tiradas.
- **Garantía («pity»):** al cabo de N tiradas sin un héroe de la rareza más alta, la siguiente lo garantiza. El contador se guarda y se muestra.
- **Repetidos:** los de **héroes** se convierten en **fragmentos del héroe**, que permiten ascender de categoría (I–VI, niveles 1–60; ver la biblia de personajes). Los de **torres** se convierten en **ecos**, que desbloquean sus **ramas de nivel 3**. Nunca son una tirada perdida.
- **Moneda general:** se llama **hilos** (G-2 de la biblia; antes «fragmentos»), para no confundirla con los fragmentos del héroe.
- **Iniciales:** dos héroes y tres torres gratuitos desde el principio. Con ellos toda misión es ganable.
- **Por decidir:** un único banner con héroes y torres o banners separados; tasas y tamaño de la garantía.
- **Determinismo y seguridad:**
  - En **local** la tirada se resuelve en el dispositivo y, como el resto del progreso local, es manipulable.
  - Con la **nube** activa, la tirada la resolverá **el servidor** (función SQL con su propio generador aleatorio). El cliente nunca decide el resultado.
- **Riesgo regulatorio (si algún día hay dinero real):** las cajas de botín de pago están reguladas o prohibidas en algunos países (p. ej., Bélgica), y las tiendas de aplicaciones exigen publicar las probabilidades. Habría que revisarlo antes de monetizar.

### Otros usos de los hilos
- **Ramas de mejora de torres:** el nivel 3 pasa a ser una elección entre dos especializaciones del diseño original (p. ej., Pixeladora: *Desfragmentación* frente a *Cadena de errores*). Se desbloquean con **ecos** de la torre (repetidos de tiradas).
- Más adelante, aspectos cosméticos y mejoras de la base, con límite.

## 6. Tipos de misión y modificadores

- **Objetivos:** defender la base (el actual); **sobrevivir** N oleadas con recursos limitados; **proteger** un objeto que avanza por el mapa; **contrarreloj** (resistir hasta que algo se active).
- **Modificadores** (datos `RuleDef`, combinables): velocidad de los enemigos, coste de las torres, recargas de habilidades, oleadas aceleradas, solo ciertas torres, enemigos con núcleo… Se usan en los mundos 5 y 6, en el modo «Rompe las reglas» y en los retos.

## 7. Mundo 1 en detalle (primera entrega)

| Misión | Nombre provisional | Mecánica nueva | Notas |
|---|---|---|---|
| `w1_m1` | Pantalla de inicio | — (tutorial) | 3 oleadas, 2 plataformas, solo torre de corrupción y Kira. Enseña construir, mejorar y mover al héroe. |
| `w1_m2` | Monedas sueltas | Monedas | Se suma la torre de sellos y Nexo. Las monedas premian mover a los héroes. |
| `w1_m3` | Bloque sorpresa | Bloques interactivos + enemigos con núcleo | Se suma la torre de rebote. Un bloque abre un atajo con una plataforma extra. |
| `w1_m4` | Doble pantalla | Rutas alternativas + plataforma móvil | Dos entradas que se unen, y una plataforma que alterna entre ambas. |
| `w1_m5` | El Rey del Reinicio | Jefe | La misión actual, reubicada como final del mundo, con bloques que el Rey reinicia. |

Con esto, la misión que ya existe pasa a ser la **5.ª**, y las cuatro anteriores la preparan.

## 8. Consecuencias para la arquitectura

Todo encaja en la estructura actual de **datos + sistemas genéricos**:

| Necesidad | Solución | Estado |
|---|---|---|
| Mundos y campaña | `WorldDef` (misiones, paleta, regla del mundo, historia) y `CampaignDef` | Nuevo |
| Elementos de mapa (monedas, bloques, plataformas, cristales, generadores, proyectores, trenes…) | `MapObjectDef` + **comportamientos registrados por tipo** (como las habilidades). Se colocan como nodos en la escena del mapa | Nuevo |
| Rutas alternativas | `MapDef.routes` ya es una lista; falta asignar la ruta en `WaveDef.route` y la previa visual | Casi hecho |
| Enemigos nuevos (conjurador, invisible, señuelo, saboteador, viral, híbrido) | Más campos en `EnemyDef` y comportamientos genéricos, como el núcleo o la invocación | Ampliación |
| Visibilidad y revelado | Bit de estado «oculto» que la búsqueda de objetivos de las torres respeta | Nuevo |
| Modificadores | `RuleDef` aplicado al crear la partida (y dinámicamente por jefes) | Nuevo |
| Objetivos de misión | `MissionDef.objective` + condiciones de victoria y derrota por tipo | Ampliación |
| Selección de héroes y misión | Escenas de mapa de campaña y preparación; la persistencia ya guarda el progreso | Nuevo |
| Ramas de mejora | `TowerDef` con niveles alternativos y desbloqueos guardados | Ampliación |

## 9. Plan de entrega propuesto

1. **7.1 · Campaña mínima:** `WorldDef`/`CampaignDef`, mapa de campaña con nodos, selección de misión y de 2 héroes, desbloqueo secuencial guardado.
2. **7.2 · Mundo 1 completo:** monedas, bloques, plataforma móvil, rutas alternativas, enemigo con núcleo y las 4 misiones nuevas.
3. **7.3 · Hilos útiles:** ramas de nivel 3 de las torres actuales y primeras mejoras de héroe.
4. **7.4 · Mundo 2:** cristales, conjuradores interrumpibles, Madame Segundero, Cronoáncora, Tiempo prestado y Alumno Eterno.
5. Siguientes mundos con el mismo esquema. Los retos diarios y las clasificaciones, cuando el núcleo esté estable y la nube activa.

Cada entrega tendrá criterios verificables, como hasta ahora: tests de simulación de cada mecánica nueva, balance con la herramienta y prueba en el iPhone.

## 10. Decisiones

| Tema | Decisión (2026-10-21) |
|---|---|
| Misiones por mundo | **5** (4 + jefe) |
| Obtención de héroes | **Tiradas estilo gacha** con hilos (§5) |
| Obtención de torres | **También por tiradas**; equipo de hasta 4 torres por misión; misiones ganables con las iniciales |
| Reparto de héroes | **Por definir**: sesión de diseño de personajes pendiente |
| Torres y sinergias por mundo | La tabla §3 queda como referencia temática (no reparto) |
| Primera entrega | **7.1 · Campaña mínima** |
| Misión actual | Pasa a ser la 5.ª del mundo 1 (`w1_m5`) |

Abiertas: cantidad de narrativa (propuesta: diálogos breves), tasas y tamaño de la garantía de las tiradas, rarezas y lista de héroes.
