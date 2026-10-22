# G · Registro de decisiones

> **Estado:** las 19 decisiones están **tomadas** (2026-10-22, por delegación del usuario: «toma las decisiones que consideres»). Cada una indica el motivo y las consecuencias para la implementación.
> **Implementado** (rama `sistemas/medidor-peso-hilos`): medidor de habilidad para Nexo y Kira (G-3/G-4, filo), peso de los enemigos y control duro decreciente (G-6), Energético con la mitad de armadura (G-5) y moneda «hilos» con migración del guardado (G-2).
> Toda cifra marcada **(prov.)** es un **valor de prueba**: se valida en la simulación y con `tools/balance.gd` antes de considerarse estable.

## Resumen

| Id | Tema | Decisión |
|---|---|---|
| G-1 | Nombres con riesgo de propiedad intelectual | Renombrados 8 héroes y 3 ataques |
| G-2 | «Fragmentos» duplicado | La moneda general pasa a llamarse **hilos**; «fragmentos» queda para los del héroe |
| G-3 | Medidor de Nexo y Kira | **Medidor** también para ellos; la carga de Kira pasa a llamarse **filo** |
| G-4 | Reglas del medidor | Se aprueba el modelo de B §0.6 |
| G-5 | Armadura y daño Energético | La armadura reduce el Energético **a la mitad** |
| G-6 | Enemigos nuevos | **Peso** del enemigo con los héroes; el resto, con los mundos 2–4 |
| G-7 | Baluarte de rareza alta | Secundarios Baluarte: Brannoc, Astraion y Uruvan. Sin cambiar roles principales |
| G-8 | Reparto por mundos | Omnion, Mistral y Sylka pasan al **Vertedero de Ideas** |
| G-9 | Estadísticas atípicas | Presupuesto por rareza (media ± 3) y 5 ajustes de 1 punto |
| G-10 | Conversión de estadísticas | Fórmula de prueba (§G-10) y **Alcance = radio de ataque efectivo** |
| G-11 | Rareza y crecimiento | **Mismo crecimiento por rol** para todas las rarezas |
| G-12 | Bloqueo por rol | Baluarte 3, Demoledor 2, resto 1; secundario Baluarte +1 |
| G-13 | Control y defensa | Se aprueban las reglas de B §0.7–0.9 |
| G-14 | Habilidades transformadas | Aceptadas todas |
| G-15 | Narrativa | Aceptados los cambios de tema y los espejos del Editor |
| G-16 | Tiradas | Banners separados; tasas y garantías de prueba (§G-16) |
| G-17 | Diálogo | 1 presentación y 3 frases de combate por héroe, en la fase de producción |
| G-18 | Pasivas | Ninguna nueva por ahora (solo Uruvan) |
| G-19 | Arte | Fuera de esta fase; se conservan las notas de alejamiento de la inspiración |

---

## Prioridad 1 · Base de la especificación numérica

### G-10 · Conversión de estadísticas y Alcance
**Decisión:** el **Alcance** es el **radio de ataque efectivo**: incluye saltos, cortes amplios y conos (resuelve la observación O4 de C).

**Fórmula de prueba** (prov.). Calibrada para que una estadística de 5 dé valores parecidos a los de los héroes actuales (Nexo y Kira: 45–55 de vida, unos 2–3 de daño por segundo, velocidad 2,5–3):

| Estadística | Nivel 1 | Escala con el nivel |
|---|---|---|
| Salud | Vida = **10 × S** | Sí, según el crecimiento del rol |
| Ataque | Daño por segundo base = **0,5 × A**. Daño por golpe = DPS × intervalo | Sí, según el crecimiento del rol |
| Defensa | Reducción del daño recibido = **4 % × D** (máx. 40 %, dentro del tope combinado del 60 %) | No |
| Velocidad | Casillas/s = **1,5 + 0,2 × V** | No |
| Alcance | Banda de B §0.2; dentro de la banda, lineal (Al 1 = 1,0 … Al 10 = 4,0 casillas) | No |
| Cadencia | Intervalo entre ataques (s) = **1,6 − 0,1 × Ca** | No |

**Crecimiento por nivel** (prov., por cada nivel por encima del 1, sobre el valor de nivel 1):

| Rol | Salud | Ataque |
|---|---|---|
| Baluarte | +3,5 % | +2,0 % |
| Ruptor | +2,5 % | +3,5 % |
| Puntero | +2,0 % | +3,5 % |
| Catalizador | +2,0 % | +3,5 % |
| Demoledor | +3,0 % | +3,0 % |
| Distorsionador | +3,0 % | +2,5 % |

Con +3 %/nivel, un héroe a nivel 60 tiene unas 2,8 veces el valor de nivel 1. **Consecuencia:** la dificultad de las misiones deberá asumir un **rango de nivel esperado** por mundo. Es un riesgo de economía que se resolverá al diseñar la progresión del jugador.

### G-11 · Rareza y crecimiento
**Decisión: opción A**, el mismo crecimiento por rol para todas las rarezas. **Motivo:** así un Común al 60 sigue siendo útil en su nicho (F §2.3). La rareza se nota en las estadísticas base y en la profundidad de la habilidad.

### G-3 · Medidor para los protagonistas
**Decisión:** Nexo y Kira Volt pasan al **medidor** y dejan el tiempo de recarga. La carga de Kira se llama **filo**. **Implementación:** cambiar `HeroDef` y `sim_heroes` (habilidad por medidor), las tarjetas de la interfaz y los tests de habilidades.

### G-4 · Reglas del medidor
**Decisión:** se aprueba el modelo de B §0.6:
- carga por ataque y no por objetivo;
- tope de carga por segundo;
- invocaciones, trampas y zonas no cargan;
- no carga fuera de combate;
- conserva el 50 % al caer;
- empieza la misión a 0 %.

**Objetivo de validación:** 1 o 2 usos por oleada.

### G-12 · Bloqueo por rol
**Decisión:** Baluarte 3, Demoledor 2 y el resto 1; el secundario Baluarte suma +1 (valores de prueba).

### G-5 · Tipos de daño
**Decisión:** 3 tipos mecánicos, y la armadura reduce el **Energético a la mitad**. **Motivo:** así el Energético tiene un papel propio entre el Físico (armadura completa) y el Arcano (la ignora). **Implementación:** cambiar `damage_enemy` en `sim_world.gd` y revisar el balance de las misiones del mundo 1, porque Nexo y Kira usan daño `energy`.

### G-13 · Control y defensa
**Decisión:** se aprueban las reglas de B §0.7–0.9:
- peso del enemigo;
- resistencia decreciente al control, con 3 controles duros cada 6 s seguidos de inmunidad;
- tope de ralentización del −60 %;
- tope de reducción de daño del 60 %;
- escudos limitados y sin acumulación del mismo origen;
- intangibilidad de 1,5 s como máximo.

---

## Prioridad 2 · Catálogo

### G-1 · Nombres
**Decisión:** se renombran 8 héroes y 3 ataques o armas. Los nuevos nombres son tan provisionales como el resto.

| Antes | Ahora | Motivo |
|---|---|---|
| Fiora | **Vesna** | Personaje de *League of Legends* |
| Bastion | **Halvard** | Héroe de *Overwatch* |
| Luneth | **Aurenn** | Protagonista de *Final Fantasy III* |
| Garruk | **Brannoc** | Personaje de *Magic: The Gathering* |
| Shinra | **Kagero** | Corporación de *Final Fantasy VII* |
| Nexarion | **Uruvan** | Se confundía con Nexo |
| Tenshi | **Kazen** | Personaje de *Touhou* |
| Draeven | **Valdrin** | Demasiado cercano a «Draven» |
| Sobrecarga azul | **Sobrecarga** | Evocaba el disparo cargado de la obra de inspiración |
| Veredicto primordial | **Pulso primordial** | Evocaba el movimiento característico de la obra de inspiración |
| Llave luminosa | **Golpe del farol** (arma: farol de umbrales) | Arma emblemática de la obra de inspiración |

Las mecánicas transformadas se recogen en G-14.

### G-14 · Habilidades transformadas
**Decisión:** se aceptan todas:
- Kairo: marca y salto, sin garfio.
- Vesna: duelo.
- Bront: cúpula de interferencia.
- Rokka: obstáculo con vida.
- Mistral: potencia torres.
- Veyra: haz que barre.
- Kazen: trazo.
- Kaelith: corte diferido.
- Eclipse: inversión del avance.
- Omnion: tragar y escupir.
- Aethern: impide caer.
- Cambios de ataque automático de Zerik, Varkhan y Nyxara.

### G-7 · Baluarte de rareza alta
**Decisión:** secundarios Baluarte para Brannoc, Astraion y Uruvan, **sin** cambiar el rol principal de Astraion. **Motivo:** cubre el hueco con el mínimo cambio sobre el catálogo.

### G-9 · Estadísticas
**Decisión:** presupuesto por rareza = media v1 ± 3 (guía) y 5 ajustes de un punto: Sylka Ca 7→6, Kairo V 6→7, Bront A 7→6 y Al 8→7, Drakar S 9→8, Eclipse A 9→8. Ophidia queda como excepción. Detalle en [C](C-matriz-estadisticas.md).

### G-8 · Mundos
**Decisión:** Omnion, Mistral y Sylka pasan al **Vertedero de Ideas**.

| Mundo | Héroes |
|---|---|
| Reino del Continue | 3 |
| Academia del Último Hechizo | 5 |
| Última Sesión | 7 |
| Neón de Medianoche | 6 |
| Vertedero de Ideas | 4 |
| Frontera Imposible | 10 |

### G-15 · Narrativa
**Decisión:** se aceptan los cambios de A:
- Kaelith: obediencia.
- Nimue: tiempo congelado.
- Halvard: custodia algo que aún existe.
- Kairo: deuda.
- Brannoc: exilio tras una guerra.
- Kagero: sello impuesto.
- Morrak y Voidra: espejos del Editor.
- Eclipse: reverso de la pantalla.

---

## Prioridad 3 · Sistemas del juego

### G-2 · Monedas
**Decisión:** la moneda general pasa a llamarse **hilos** («hilos de la Trama»). **Fragmentos** queda reservado para los fragmentos de cada héroe.

**Implementación:**
- textos de la interfaz (campaña, resultados, barra superior);
- `docs/07` a `docs/09`;
- en el guardado, la clave interna `shards` se renombra con migración, como se hizo con `w1_m1`.

### G-6 · Enemigos
**Decisión:** el **peso** (ligero, medio, pesado, jefe) se añade a `EnemyDef` al implementar los héroes. Los enemigos a distancia, voladores, invisibles y canalizadores llegan con los mundos 2–4 (`docs/08`).

Peso de los enemigos actuales:

| Peso | Enemigos |
|---|---|
| Ligero | glitchling, zumbador, glitchling con continue |
| Pesado | acorazado |
| Jefe | Rey del Reinicio |
| (no se desplazan) | núcleos |

### G-16 · Tiradas
**Decisión:** banners **separados** para héroes y torres. Las probabilidades se muestran siempre. Valores de prueba para el **banner de héroes**:

| Rareza | Probabilidad (prov.) |
|---|---|
| Común | 40 % |
| Poco común | 27 % |
| Raro | 17 % |
| Épico | 9 % |
| Legendario | 4,5 % |
| Mítico | 2 % |
| Trascendente | 0,5 % |

**Garantías (prov.):**
- **Épico o superior** cada 10 tiradas.
- **Legendario o superior** a las 60 tiradas sin uno.
- **Mítico o superior** a las 150.
- **Trascendente** a las 300.

Los contadores se guardan y se muestran.

**Coste (prov.):** 100 hilos por tirada; 900 por 10 tiradas.

**Repetidos:** se convierten en **fragmentos del héroe**. La cantidad por rareza y los costes de ascenso están **pendientes de la pasada de economía**.

**Banner de torres:** mismo esquema. Las rarezas de las torres están por definir cuando haya más torres; hoy solo existen las 3 iniciales.

**Riesgo regulatorio:** como en `docs/08` §5, si algún día hubiera dinero real.

---

## Prioridad 4

- **G-17 · Diálogo:** 1 presentación y 3 frases de combate por héroe, en la fase de producción. Sin bocadillos que tapen el combate.
- **G-18 · Pasivas:** ninguna nueva. Solo Uruvan (Adversidad), porque aporta una mecánica que no cubren su ataque ni su habilidad.
- **G-19 · Arte:** fuera de esta fase. Se conservan las notas para alejar el diseño de su inspiración: Voltra, Omnion, Astraion, Kaelith/Aeron y Veyra/Voidra/Drakar.

## Lo que sigue pendiente (no son decisiones de diseño, sino trabajo)
1. ~~**Pasada de economía**~~: hecha en [`docs/10-economia.md`](../10-economia.md) (valores de prueba validados por simulación).
2. ~~**Especificación numérica por héroe**~~: hecha en [H](H-ficha-numerica.md) y [H · Valores base](H-valores-base.md); falta validarla en la simulación.
3. **Implementación:** medidor, peso, Energético a la mitad e hilos ya están hechos; faltan las mecánicas de cada héroe coleccionable.
