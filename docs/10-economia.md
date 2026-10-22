# 10 · Pasada de economía

> **Estado:** diseño con **valores de prueba (prov.)**, validados con una simulación de jugadores. Todavía **no** está conectado al juego (ver §9).
> Las reglas viven en `src/content/economy_rules.gd`. La simulación es `tools/economy.gd` y los tests, la sección «Economía» de `tests/run_tests.gd`.
> Parte de las decisiones de la [biblia de personajes](personajes/G-decisiones-pendientes.md) (G-2, G-10, G-11, G-16) y de la progresión de [E](personajes/E-progresion.md).

```bash
godot --headless --path . --script res://tools/economy.gd -- 2000 5   # jugadores, repeticiones extra por mundo
```

## 1. Objetivos

1. **Ninguna misión exige suerte:** toda misión se gana con el equipo inicial (regla vigente). Los héroes coleccionables hacen más fácil sacar 3★, pero no son obligatorios.
2. **Un jugador «normal» tiene el equipo al nivel esperado de cada mundo** sin repetir misiones en exceso.
3. **Colección:** al acabar la campaña se tienen unos **dos tercios** de los 35 héroes. El resto, y la maestría (categoría VI), son objetivos a largo plazo.
4. **Sin dinero real** en el alcance actual (`docs/08` §5).
5. **Pocas monedas:** solo **hilos** (generales), **fragmentos del héroe** (de cada héroe) y **ecos** (de cada torre).

## 2. Hilos: ingresos

Recompensa por victoria. Multiplicador del mundo: **×(1 + 0,25 × (mundo − 1))**, es decir, ×1 en el mundo 1 y ×2,25 en el 6.

| Concepto | Base (mundo 1) | Notas |
|---|---|---|
| Primera victoria | **80** | La misión del jefe paga ×1,5 (**120**) |
| Por estrella (primera victoria o estrellas nuevas) | **25** | |
| Repetición | **6 por estrella** de la partida | 3★ = **18** |
| Al completar el mundo 1 | **Tirada ×10 gratuita** | Una sola vez; presenta las tiradas |

Por mundo con todas las misiones a 3★: **815 × multiplicador**, es decir, 815 en el mundo 1 y 1.834 en el 6. La campaña completa da **≈ 7.950 hilos** sin repetir.

**Repetir** da entre 240 hilos/h (mundo 1) y 540 hilos/h (mundo 6), de 2,4 a 5,4 tiradas por hora. Es un complemento y no la vía principal.

*Antes:* 50 + 20 por estrella + 5 por repetición, igual en todos los mundos.

## 3. Experiencia y niveles

- **Experiencia para subir del nivel L al siguiente:** 30 + 10 × L. Llegar al 10 cuesta 720; al 40, 8.970; y al 60, ≈ 19.500.
- **Experiencia por partida** para cada héroe del equipo: **45 × mundo**. Una derrota da la cuarta parte.
- **Recuperación:** un héroe que esté más de 2 niveles por debajo del **nivel de historia** del mundo gana **×3**. Así un héroe recién conseguido se pone al día en pocas partidas.

**Nivel de historia** (nivel esperado al **empezar** cada mundo):

| Mundo | 1 | 2 | 3 | 4 | 5 | 6 | Fin |
|---|---|---|---|---|---|---|---|
| Nivel | 1 | 8 | 15 | 22 | 29 | 36 | 40 |
| Categoría necesaria | I | I | II | III | III | IV | IV |

### Decisión E-1 · Nexo y Kira usan el nivel de historia
Los protagonistas están fuera de la colección (E). Por eso **toman automáticamente el nivel de historia del mundo**, con el crecimiento de su rol.

- **Motivo:** la dificultad de cada mundo se ajusta a ese nivel. Así la regla «ganable con el equipo inicial» sigue siendo cierta en el mundo 6, y un jugador sin suerte en las tiradas nunca se atasca.
- **Consecuencia:** un coleccionable al mismo nivel debe ser **algo mejor** que un protagonista en su nicho. Si no lo es, la colección no tiene sentido. Esto se comprobará en la especificación numérica por héroe.

La campaña termina a nivel **40, categoría IV**. Las categorías V y VI (nivel 41–60) son contenido posterior: «Rompe las reglas», los retos y la maestría.

## 4. Ascenso de categoría

Para ascender hay que estar en el nivel máximo de la categoría. Se conserva el nivel y sube el límite (E).

| Ascenso a | II | III | IV | V | VI | Total |
|---|---|---|---|---|---|---|
| Fragmentos del héroe | 3 | 6 | 12 | 25 | 40 | 86 |
| Hilos | 100 | 200 | 400 | 800 | 1.500 | 3.000 |

Durante la campaña (hasta la IV), cada héroe necesita **21 fragmentos y 700 hilos**.

### Fragmentos por repetido
Su cantidad es aproximadamente **inversa a la probabilidad de que salga ese héroe concreto**. Así todos ascienden a un ritmo parecido, y la rareza se nota en las estadísticas base y en la habilidad (G-11), no en lo difícil que es ascenderlo.

| Rareza | Común | Poco común | Raro | Épico | Legendario | Mítico | Trascendente |
|---|---|---|---|---|---|---|---|
| Probabilidad de **ese** héroe por tirada | 5,0 % | 3,9 % | 2,4 % | 1,8 % | 1,1 % | 0,7 % | 0,5 % |
| Fragmentos por repetido | 5 | 6 | 10 | 14 | 22 | 36 | 50 |

### Decisión E-2 · Taller de fragmentos
Se pueden comprar fragmentos de un héroe **que ya se tiene** a **25 hilos** cada uno, sin límite.

- **Motivo:** sin taller, un héroe raro que gusta no podría ascenderse, porque sus repetidos son escasos.
- **Coste de oportunidad:** cada fragmento comprado es un cuarto de tirada. El jugador decide entre ampliar la colección y subir a su favorito.
- En la simulación, el taller se lleva entre el 13 y el 22 % de los hilos de la campaña.

## 5. Tiradas

Valores de G-16:
- **Coste:** 100 hilos por tirada y 900 por 10 tiradas.
- **Probabilidades:** 40 / 27 / 17 / 9 / 4,5 / 2 / 0,5 %.
- **Garantías:**
  - épico o superior cada 10 tiradas;
  - legendario o superior a las 60;
  - mítico o superior a las 150;
  - trascendente a las 300.

Cada garantía cuenta las tiradas **sin esa rareza o superior**, y una tirada alta reinicia también los contadores inferiores. Los tests comprueban las cuatro garantías en 30.000 tiradas.

**Banner de torres:** mismo coste y garantías. Cada repetido de una torre da **1 eco**, y cada rama de nivel 3 cuesta **2 ecos**. Sus rarezas y tasas se fijarán cuando haya más torres; hoy solo existen las 3 iniciales. Los hilos que se gasten en torres salen de los mismos ingresos: hay que **revisar esta pasada** cuando exista ese banner.

## 6. Resultado de la simulación

1.000 jugadores por perfil. El equipo son los 2 coleccionables de rareza más alta. Se mide al acabar cada mundo frente al nivel esperado del siguiente. «Repeticiones» son las partidas extra por mundo, con 3★.

| Mundo | Horas (0 / 5 / 15 rep.) | Tiradas | Héroes distintos | Nivel del equipo (esperado) |
|---|---|---|---|---|
| 1 | 0,8 / 1,2 / 2,0 | 12 / 12 / 12 | 10 / 10 / 10 | 2 / 3 / 4 (8)\* |
| 2 | 1,6 / 2,4 / 3,9 | 22 / 22 / 22 | 16 / 16 / 16 | 13 / 15 / 19 (15) |
| 3 | 2,5 / 3,6 / 5,8 | 32 / 32 / 33 | 20 / 20 / 20 | 19 / 23 / 28 (22) |
| 4 | 3,3 / 4,8 / 7,8 | 42 / 42 / 42 | 23 / 23 / 23 | 25 / 30 / 35 (29) |
| 5 | 4,1 / 6,0 / 9,8 | 48 / 51 / 43 | 24 / 25 / 23 | 32 / 37 / 44 (36) |
| 6 | 5,0 / 7,2 / 11,7 | 60 / 52 / 57 | 27 / 25 / 26 | 38 / 43 / 47 (40) |

\* Al acabar el mundo 1 llega la tirada ×10 gratuita y el equipo pasa a ser de héroes nuevos de nivel 1. La recuperación ×3 los sube durante el mundo 2.

**Lectura:**
- El jugador con **5 repeticiones por mundo** sigue el nivel esperado con un margen de 0 a 3 niveles.
- El que **no repite** va unos 3 niveles por detrás. Gana igualmente con Nexo y Kira (E-1), aunque sacar 3★ le costará más.
- El que **repite mucho** va por delante y gasta más en el taller. Las tiradas se estabilizan porque los hilos van a los ascensos.
- **Colección al final:** ≈ 25 de 35 héroes (70 %). El mejor del equipo es mítico o trascendente en el 80 % de los casos.
- **Tiempo:** de 5 a 12 horas de campaña, a unos 4,5 minutos por partida.

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| Los coleccionables a nivel alto trivializan el mundo 1 al repetirlo | Las repeticiones pagan poco. Si hace falta, «Rompe las reglas» con nivel fijo |
| Un coleccionable no supera a un protagonista del mismo nivel | Validarlo en la especificación numérica por héroe (E-1) |
| Un jugador malgasta hilos en tiradas y no puede ascender | Ningún ascenso es obligatorio: los protagonistas siguen el nivel de historia |
| Un banner de torres reparte los mismos hilos | Revisar esta pasada al crearlo (§5) |
| Manipulación del progreso local | Igual que hoy. Con la nube, recompensas y tiradas en el servidor (`docs/07`, `docs/08` §5) |

## 8. Decisiones de esta pasada

| Id | Decisión |
|---|---|
| E-1 | Nexo y Kira toman el **nivel de historia** del mundo, que es también el nivel con el que se ajusta la dificultad |
| E-2 | **Taller de fragmentos:** 25 hilos por fragmento de un héroe que se tiene |
| E-3 | **Fragmentos por repetido** inversos a la probabilidad del héroe (5 a 50) |
| E-4 | **Tirada ×10 gratuita** al completar el mundo 1 |
| E-5 | Recompensas que **crecen un 25 % por mundo**; repetición por estrella |
| E-6 | La **campaña acaba a nivel 40 y categoría IV**; V y VI son contenido posterior |
| E-7 | **Recuperación ×3** de experiencia por debajo del nivel de historia |

## 9. Para conectarlo al juego (siguientes fases)

1. **Recompensas:**
   - `SaveService._apply_local_rewards` debe usar `EconomyRules.mission_threads` (con el mundo y si es la misión del jefe) en lugar de los campos de `MissionDef`;
   - esos campos quedan como ajuste opcional por misión;
   - también la función SQL de la nube.
2. **Guardado:**
   - héroes que se tienen, con nivel, experiencia, categoría y fragmentos;
   - contadores de garantía;
   - ecos de las torres;
   - si ya se recibió la tirada gratuita.
3. **Simulación:** escalar con el nivel la vida y el daño de los héroes (G-10) y la dificultad de los enemigos por mundo según el nivel de historia.
4. **Interfaz:** pantalla de tiradas con las probabilidades visibles, ficha del héroe (nivel, ascenso, taller) y experiencia en los resultados.
