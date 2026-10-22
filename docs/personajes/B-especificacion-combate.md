# B · Especificación de combate

> **Estado:** las propuestas **[P]** de este documento quedan **aprobadas** (decisiones de [G](G-decisiones-pendientes.md), 2026-10-22). Se mantiene la marca [P] para distinguir lo nuevo de lo heredado del catálogo.
> Convenciones: **[E]** establecido, **[P]** propuesta (aprobada), **[?]** pregunta, **(prov.)** cifra de prueba. Ninguna cifra es definitiva; se validan con la simulación y `tools/balance.gd` (ver §0.12).
> Las estadísticas conceptuales están en [C](C-matriz-estadisticas.md), la historia en [A](A-biblia-narrativa.md) y la progresión en [E](E-progresion.md).

---

## 0 · Marco común

### 0.1 Contexto de partida [E]
- *Tower defense* isométrico. Los enemigos recorren rutas hacia la base; el jugador construye torres en plataformas fijas.
- **Equipo:** 2 héroes por misión, elegidos entre los protagonistas (Nexo y Kira Volt) y los coleccionables que se tengan.
- Los héroes **se colocan en el camino** (el jugador los mueve), **atacan solos** y **bloquean** enemigos. Los enemigos bloqueados se detienen y golpean al héroe cuerpo a cuerpo.
- Los héroes tienen vida, la regeneran fuera de combate, **caen** y **reaparecen** tras un tiempo.
- Hoy los enemigos solo atacan cuerpo a cuerpo a los héroes que los bloquean. No existen enemigos a distancia, voladores ni invisibles, ni ataques a las torres (ver G-6).

### 0.2 Alcance funcional [P]
La estadística **Alcance (1–10)** se traduce en una **banda**. Las distancias en casillas son solo una referencia de prueba frente a las torres actuales (3–3,6 casillas):

| Alcance | Banda | Referencia (prov.) |
|---|---|---|
| 1–3 | Cuerpo a cuerpo (CaC) | ≤ 1,4 casillas |
| 4–5 | Corto | 1,5–2,2 |
| 6–7 | Medio | 2,3–3,0 |
| 8–10 | Largo | 3,1–4,0 |

Las habilidades tienen su propio alcance de uso, indicado en cada ficha con las mismas bandas.

### 0.3 Capacidad de bloqueo por rol [P]
Determina cuántos enemigos detiene a la vez el héroe en su posición:

| Rol principal | Bloqueo (prov.) | Comentario |
|---|---|---|
| Baluarte | 3 | Su función |
| Demoledor | 2 | Frontal |
| Ruptor | 1 | Prefiere matar a sujetar |
| Puntero, Catalizador, Distorsionador | 1 | Están en el camino, pero sujetan poco |

Un **rol secundario Baluarte** suma +1. Algunas habilidades modifican el bloqueo de forma temporal.

### 0.4 Vocabulario de objetivos [P]
- **Bloqueado:** enemigo que el propio héroe está bloqueando. Prioridad por defecto de los cuerpo a cuerpo.
- **Más avanzado:** el más cercano a la base dentro del alcance. Prioridad por defecto de los ataques a distancia, como las torres.
- **Más cercano:** al héroe.
- **Élite:** enemigo acorazado, jefe o con mecánica especial (núcleo, invocación). Algunas fichas lo priorizan.
- **Marcado:** con una marca aplicada por el héroe.
- **Objetivo válido:** vivo y dentro del alcance. Cuando existan invisibles y voladores (G-6), además **visible**, y alcanzable por ataques a distancia en el caso de los voladores.

### 0.5 Tipos de daño [P] (alineados con el juego actual)
| Tipo mecánico | Equivalente actual | Armadura | Sabores temáticos que agrupa |
|---|---|---|---|
| **Físico** | cinético | La reduce por completo | cortes, golpes, balas, flechas |
| **Energético** | energía | **La reduce a la mitad** (decisión G-5; en el juego actual todavía la reduce por completo, pendiente de implementar) | eléctrico, láser, fuego, luz, vacío |
| **Arcano** | mágico | **La ignora** | hielo mágico, oscuro, espectral, temporal, estelar, onírico |

Los «sabores» son solo narrativos y visuales. La **perforación de armadura** (porcentaje que se ignora) es un rasgo de ataques concretos.

### 0.6 Medidor de habilidad [E + P]
**Decisión G-3:** Nexo y Kira Volt también usan el medidor (dejan el tiempo de recarga). La «carga» de Kira, que aumenta el daño de su corte, pasa a llamarse **filo** para no confundirla con el medidor.

**[E]** Cada héroe tiene un medidor propio. La habilidad se activa **manualmente al 100 %**. No se carga fuera de combate.

**Fuentes de carga [P]** (valores (prov.) para la primera prueba):

| Fuente | Regla | Valor de prueba |
|---|---|---|
| Golpear | Por **ataque**, no por objetivo; un ataque multiblanco suma un extra pequeño por objetivo adicional, con tope | 6 % por ataque (antes 4 %; ajustado con `tools/hero_check.gd`), +1 % por objetivo extra, máx. +2 % |
| Derribar | Por enemigo eliminado por el héroe | 8 % (antes 6 %) |
| Recibir daño | Proporcional a la vida perdida | 0,2 % por 1 % de vida perdida |
| Aplicar control | Por objetivo controlado, con enfriamiento interno por objetivo | 3 %; mismo objetivo cada 3 s como mucho |

**Límites [P]:**
- **Tope de carga por segundo:** 10 %/s (prov.).
- **Invocaciones, trampas, zonas y efectos periódicos** no cargan el medidor de su dueño. Solo cuentan los ataques automáticos y lo que el héroe recibe.
- **Mientras una habilidad está activa** el medidor no carga.
- **Fuera de combate** (sin dar ni recibir daño en los últimos 3 s, prov.) no carga.
- **Al caer** el héroe conserva el 50 % del medidor (prov.; G-4).
- **Al empezar la misión** el medidor está a 0 % (decisión G-4).

**Ritmos por rol [P]:** los Baluartes cargan sobre todo **recibiendo** daño y los Distorsionadores **controlando**. Así la carga refleja el rol sin tablas especiales por héroe.

### 0.7 Control: categorías, peso y resistencia [P]
**Categorías:**
- **Blando:** ralentización y debilitamiento (menos daño o menos cadencia del enemigo).
- **Duro:** aturdimiento, inmovilización, congelación, petrificación, suspensión e inversión del avance.
- **Desplazamiento:** empuje, atracción, derribo y retirada del camino.

**Peso del enemigo** (atributo nuevo de `EnemyDef`):

| Peso | Ejemplos actuales | Desplazamiento | Control duro | Ralentización |
|---|---|---|---|---|
| Ligero | glitchling, zumbador | Completo | Completo | Completa |
| Medio | — | Reducido a la mitad | Duración a la mitad | Completa |
| Pesado | acorazado | Ninguno | Solo «detener» breve | Completa |
| Jefe | Rey del Reinicio | **Inmune** | **Inmune** | Reducida a la mitad |

**Resistencia decreciente:**
- Cada control duro recibido en los últimos 6 s reduce a la mitad la duración del siguiente.
- Tras el tercero, el enemigo queda **inmune al control duro** 3 s.

Esta regla general amplía la inmunidad que ya tienen los sellos del Grimorio.

**Tope de ralentización:** −60 % de velocidad combinada (prov.).

### 0.8 Defensa: escudos, curación y reducción de daño [P]
- **Escudos:** absorben daño y duran como mucho 6 s (prov.). **No se acumulan del mismo origen**: uno nuevo sustituye al anterior si es mayor. Tope: 40 % de la vida máxima del protegido (prov.).
- **Curación:** nunca por encima del máximo; **nunca resucita**.
- **Reducción de daño:** se combina de forma multiplicativa con un **tope del 60 %** (prov.).
- **Intangibilidad e invisibilidad propias:** máximo 1,5 s (prov.). Durante ellas el héroe **no bloquea** y no puede ser objetivo.
- **Provocación:** obliga a los enemigos de un radio a atacar al héroe que la aplica en lugar de a otro héroe. No afecta a jefes.

### 0.9 Invocaciones, zonas y trampas [P]
- Como máximo **1 invocación permanente** y **1 zona o trampa** activas por héroe. Una nueva sustituye a la anterior.
- Las invocaciones **no bloquean** salvo que su ficha lo indique, no cargan el medidor y heredan una fracción de las estadísticas del dueño.

### 0.10 Criterio de rareza [P]
La rareza da **techo** (estadísticas, crecimiento) y **profundidad** (habilidades con más condiciones y combinaciones), **no multiplicadores ocultos**. Un Común bien elegido debe seguir siendo útil en su nicho al nivel 60 (ver F §2.3).

### 0.11 Interrupción [P]
Las habilidades **canalizadas** (indicado en cada ficha) se interrumpen si:
- el héroe **cae**;
- el jugador lo **mueve**;
- recibe un **control duro** enemigo (cuando exista; G-6).

Si se interrumpe en la primera mitad, se devuelve el 50 % del medidor (prov.).

### 0.12 Cómo validar las cifras de prueba
1. Implementar el medidor y las reglas comunes en la simulación.
2. Medir el tiempo medio hasta el 100 % por héroe en `w1_m1`–`w1_m5` (objetivo de prueba: 1 o 2 usos por oleada).
3. Comprobar con `tools/balance.gd` que ningún héroe hace ganable una misión sin torres.
4. Ajustar.

### 0.13 Plantilla de ficha
**Rol** · **Identidad mecánica** · **Ataque automático** (tipo, objetivo, alcance, multiblanco, daño, límites) · **Habilidad especial** (activación, alcance y área, duración, efectos, interrupción, inmunidades, contrajuego) · **Pasiva** (solo si aporta) · **Sinergias / contrapartidas** · **Cambios propuestos**.

---

## Comunes

### 1. Aeron · C · Demoledor · Reino del Continue
- **Rol:** Demoledor [E]. Sin secundario.
- **Identidad mecánica:** golpea lento y fuerte, y su habilidad **despeja** su propia posición cuando está desbordado. Es el Demoledor que mejor recupera una línea perdida.
- **Ataque automático — Tajo de ruptura:**
  - **Tipo:** corte frontal pesado.
  - **Objetivo:** bloqueado; si no hay, el más cercano.
  - **Alcance:** CaC.
  - **Multiblanco [P]:** alcanza al objetivo y a 1 enemigo adyacente en un cono frontal, con daño reducido.
  - **Daño:** Físico.
  - **Límites:** cadencia baja; sin efecto contra objetivos a distancia.
- **Habilidad especial — Impacto del umbral:**
  - **Activación:** instantánea, sobre sí mismo (sin apuntar).
  - **Área:** círculo corto alrededor.
  - **Efectos:** daño Físico y **empuje** hacia atrás en la ruta, completo a ligeros y reducido a medios. **Derriba** (aturdimiento breve) a ligeros.
  - **Inmunidades:** pesados y jefes no se desplazan.
  - **Contrajuego:** empujar puede sacar enemigos del alcance de las torres si Aeron está mal colocado.
- **Sinergias:** Baluartes que acumulan enemigos delante; Distorsionadores que ralentizan (más enemigos en el cono); torre de rebote.
- **Contrapartidas:** enjambres rápidos (cadencia baja), acorazados (Físico).

### 2. Zerik · C · Puntero · Reino del Continue
- **Rol:** Puntero [E].
- **Identidad mecánica:** el Puntero de las **filas**. Su habilidad gana fuerza por cada enemigo que atraviesa, así que premia colocarse al final de una recta. Es barato, preciso y de largo alcance.
- **Ataque automático — Pulso de precisión:**
  - **Tipo:** proyectil.
  - **Objetivo:** [E] el más cercano; [P] **el más avanzado**, coherente con la defensa de torres.
  - **Alcance:** largo. Monoobjetivo.
  - **Daño:** Energético.
  - **Límites:** sin perforación.
- **Habilidad especial — Sobrecarga (antes «Sobrecarga azul»):**
  - **Activación:** apuntar una dirección.
  - **Área:** línea larga desde Zerik.
  - **Efectos:** disparo que atraviesa a todos los enemigos alineados. **[P] Cada enemigo atravesado aumenta el daño a los siguientes** (+X % acumulativo, con tope).
  - **Interrupción:** instantánea.
  - **Contrajuego:** enemigos dispersos en carriles distintos; acorazados (Energético).
- **Sinergias:** Distorsionadores que agrupan en fila (ralentizar la cola); torres de sellos.
- **Contrapartidas:** salud baja si bloquea; mapas con muchas curvas.

### 3. Raiko · C · Demoledor · Academia del Último Hechizo
- **Rol:** Demoledor [E]. **Secundario [P]: Distorsionador** (empuja).
- **Identidad mecánica:** Demoledor **ágil** (Velocidad 7). Corre entre puntos calientes, y su habilidad no busca matar, sino **ganar tiempo** empujando una fila.
- **Ataque automático — Puño de corriente:**
  - **Tipo:** golpes cortos encadenados.
  - **Objetivo:** bloqueado o el más cercano.
  - **Alcance:** corto. Monoobjetivo.
  - **Daño:** Energético.
  - **Límites:** poco daño por golpe.
- **Habilidad especial — Onda del dragón** ([?] valorar otro nombre):
  - **Activación:** apuntar una dirección.
  - **Área:** línea media.
  - **Efectos:** daño Energético y **[P] empuje a lo largo de la línea**, completo a ligeros y reducido a medios. Se diferencia del resto de habilidades en línea porque su valor es el **retroceso**, no el daño.
  - **Inmunidades:** pesados y jefes no retroceden.
  - **Contrajuego:** empujar fuera del alcance de las torres.
- **Sinergias:** zonas persistentes (Prisión de escarcha, Sueño depredador), donde los enemigos vuelven a entrar.
- **Contrapartidas:** daño modesto; no sostiene un bloqueo largo.

### 4. Voltra · C · Catalizador · Neón de Medianoche
- **Rol:** Catalizador [E].
- **Identidad mecánica:** frágil y **muy rápida** (Velocidad 9, Cadencia 8). Se reposiciona a menudo y castiga los enjambres con rebotes y descargas centradas en sí misma.
- **Ataque automático — Chispa errante:**
  - **Tipo:** descarga.
  - **Objetivo:** el más avanzado.
  - **Alcance:** medio.
  - **Multiblanco:** **rebota a 1 enemigo cercano** con daño reducido [E].
  - **Daño:** Energético.
  - **Límites:** el rebote no repite objetivo.
- **Habilidad especial — Tormenta de voltaje:**
  - **Activación:** instantánea, sobre sí misma.
  - **Área:** círculo medio.
  - **Duración:** ralentización breve.
  - **Efectos:** daño Energético y ralentización.
  - **Contrajuego:** tiene que estar en medio del peligro (Salud 4, Defensa 3).
- **Sinergias:** activa **«Error de sistema»** (la corrupción se acumula más rápido en enemigos ralentizados) junto a la torre de corrupción.
- **Contrapartidas:** cae enseguida si bloquea a varios; acorazados.

### 5. Sylka · C · Puntero · Vertedero de Ideas (antes Frontera Imposible)
- **Rol:** Puntero [E].
- **Identidad mecánica:** Puntero **preparador**. Planifica emboscadas: su habilidad funciona mejor colocada **antes** de que llegue el grupo.
- **Ataque automático — Disparo de expedición:**
  - **Tipo:** proyectil preciso.
  - **Objetivo:** [P] **élite** si hay alguna en alcance; si no, el más avanzado.
  - **Alcance:** medio-largo. Monoobjetivo.
  - **Daño:** Físico.
  - **Límites:** sin efectos.
- **Habilidad especial — Trampa de reliquia:**
  - **Activación:** colocar en un punto del camino (alcance medio).
  - **Área:** círculo pequeño al activarse.
  - **Duración:** persiste hasta activarse o hasta 20 s (prov.).
  - **Efectos:** daño Físico en área y ralentización.
  - **[P] Activación selectiva:** la dispara el primer enemigo **no ligero**, de modo que no se gasta en un enjambre.
  - **Límites:** 1 trampa activa.
  - **Contrajuego:** voladores (futuros) no la activan; si solo pasan ligeros, no se dispara.
- **Sinergias:** misiones con élites predecibles; Distorsionadores que retienen sobre la trampa.
- **Contrapartidas:** oleadas solo de ligeros.

### 6. Mistral · C · Distorsionador · Vertedero de Ideas (antes Reino del Continue)
- **Rol:** Distorsionador [E] (apoyo táctico).
- **Identidad mecánica:** el **ingeniero** del equipo. Su habilidad potencia **torres**, un nicho que no cubre ningún otro héroe.
- **Ataque automático — Hélice cortante:**
  - **Tipo:** disco.
  - **Objetivo:** el más avanzado.
  - **Alcance:** medio.
  - **Multiblanco:** rebota **una vez** [E].
  - **Daño:** Físico.
  - **Límites:** poco daño.
- **Habilidad especial — Turbina de apoyo:**
  - **Activación:** instantánea, sobre sí mismo.
  - **Área:** círculo medio.
  - **Duración:** 6 s (prov.).
  - **Efectos:**
    - [E] Aumenta la velocidad de movimiento del héroe aliado.
    - **[P] Aumenta la cadencia de las torres** del área.
    - **[P] Ráfaga inicial** que empuja un poco a ligeros.
  - **Motivo del cambio:** en un equipo de 2 héroes, dar solo velocidad de movimiento aporta muy poco.
  - **Contrajuego:** inútil si no hay torres cerca; obliga a colocarse junto a ellas.
- **Sinergias:** cualquier torre, especialmente la de rebote y la de corrupción.
- **Contrapartidas:** daño propio bajo; débil en mapas de torres dispersas.

### 7. Rokka · C · Baluarte · Vertedero de Ideas
- **Rol:** Baluarte [E].
- **Identidad mecánica:** el único que crea **bloqueo fuera de su cuerpo**: levanta un obstáculo que los enemigos tienen que derribar.
- **Ataque automático — Puñetazo sísmico:**
  - **Tipo:** golpe pesado.
  - **Objetivo:** bloqueado.
  - **Alcance:** CaC. Monoobjetivo.
  - **Daño:** Físico.
  - **Límites:** cadencia baja.
- **Habilidad especial — Barrera de chatarra:**
  - **Activación:** colocar en el camino a corta distancia (delante de Rokka).
  - **Duración:** hasta que la destruyan o 10 s (prov.).
  - **Efectos:**
    - **[P] Obstáculo con vida** que **detiene a todos los enemigos no jefes** que llegan y que estos atacan para pasar.
    - Mientras exista, Rokka recibe **reducción de daño** [E].
    - Cumple el «protege a los aliados detrás» [E] en clave de este juego: todo lo que hay detrás del obstáculo, incluida la base, queda a salvo hasta que cae.
  - **Inmunidades:** los jefes lo destruyen de un golpe [P].
  - **Contrajuego:** acumula enemigos (bueno para el área, malo si se rompe con muchos detrás).
- **Sinergias:** Catalizadores de área, Aeron y la torre de rebote.
- **Contrapartidas:** Alcance 2 y Velocidad 4: mala reposición.

### 8. Kagero (antes Shinra) · C · Demoledor · Academia del Último Hechizo
- **Rol:** Demoledor [E].
- **Identidad mecánica:** Demoledor **antiélite** barato. Su habilidad atraviesa defensas y castiga al enemigo más duro del grupo.
- **Ataque automático — Cadena sombría:**
  - **Tipo:** combinación de 3 golpes: los dos primeros Físicos y el tercero Arcano (descarga oscura).
  - **Objetivo:** bloqueado.
  - **Alcance:** CaC. Monoobjetivo.
- **Habilidad especial — Ruptura interior:**
  - **Activación:** instantánea.
  - **Objetivo:** [P] el enemigo con **más vida** en CaC.
  - **Efectos:**
    - Daño alto al objetivo y reducido a los cercanos [E].
    - **[P] Perforación de armadura** elevada en el golpe principal.
  - **Contrajuego:** poco valor contra enjambres de ligeros.
- **Sinergias:** torres de rebote y Catalizadores (limpian lo que él no).
- **Contrapartidas:** grupos grandes sin élites.

---

## Poco comunes

### 9. Kairo · PC · Ruptor · Última Sesión
- **Rol:** Ruptor [E].
- **Identidad mecánica:** Ruptor de **larga persecución**. Marca a distancia y salta hasta sus marcas para rematar, a cambio de **abandonar su bloqueo**.
- **Ataque automático — Brasa marcadora [P]** (sustituye «Garfio ígneo», ver F §1.7):
  - **Tipo:** brasa lanzada.
  - **Objetivo:** el más avanzado.
  - **Alcance:** medio.
  - **Efecto:** daño Energético (fuego) y **marca** de deuda durante unos segundos (prov.). Los marcados no son atraídos.
  - **Límites:** máximo de marcas simultáneas (prov. 3).
- **Habilidad especial — Ascua vengadora:**
  - **Activación:** instantánea.
  - **Objetivo:** el marcado más avanzado dentro de alcance largo. **Sin marcas no se puede activar.**
  - **Efectos:** se desplaza hasta él y **explota** al llegar (círculo pequeño, Energético). Kairo **queda en el nuevo punto**.
  - **[P]** Si elimina al objetivo marcado, recupera el 20 % del medidor (prov.; una vez por activación).
  - **Contrajuego:** suelta a los enemigos que bloqueaba; puede acabar lejos del lugar donde se le necesita.
- **Sinergias:** un Baluarte que sostenga mientras él caza.
- **Contrapartidas:** Velocidad 6 (ver C); mapas con rutas cortas.

### 10. Nimue · PC · Catalizador · Academia del Último Hechizo
- **Rol:** Catalizador [E]. **Secundario [P]: Distorsionador.**
- **Identidad mecánica:** control a **gran distancia** (Alcance 9). Prepara **zonas de muerte** para las torres en lugar de pelear de cerca.
- **Ataque automático — Aguja glacial:**
  - **Tipo:** proyectil.
  - **Objetivo:** el más avanzado.
  - **Alcance:** largo. Monoobjetivo.
  - **Efecto:** **ralentización acumulable** leve (prov. 2 acumulaciones).
  - **Daño:** Arcano (hielo).
- **Habilidad especial — Prisión de escarcha:**
  - **Activación:** colocar en un punto (alcance largo).
  - **Área:** círculo medio.
  - **Duración:** 4 s (prov.).
  - **Efectos:** daño periódico. **[P] Al terminar, congela** (control duro) a ligeros y medios que sigan dentro. Los pesados solo se ralentizan; los jefes, ralentización reducida.
  - **Contrajuego:** los rápidos salen antes; resistencia decreciente al control.
- **Sinergias:** torre de corrupción («Error de sistema»), torre de rebote y Raiko (devuelve enemigos a la zona).
- **Contrapartidas:** Salud 4; si la alcanzan, cae.

### 11. Halvard (antes Bastion) · PC · Baluarte · Frontera Imposible
- **Rol:** Baluarte [E].
- **Identidad mecánica:** el **muro de un solo punto**. Casi inmóvil (Velocidad 2), absorbe y **atrae los golpes** dirigidos a su compañero.
- **Ataque automático — Martillo de asedio:**
  - **Tipo:** golpe frontal.
  - **Objetivo:** bloqueados.
  - **Alcance:** corto.
  - **Multiblanco:** cono que alcanza hasta 3 enemigos (prov.).
  - **Daño:** Físico.
  - **Límites:** cadencia baja.
- **Habilidad especial — Última muralla:**
  - **Activación:** instantánea. **Canalizada** (prov. 6 s).
  - **Efectos:**
    - Escudo que **absorbe** daño, con tope ligado a su vida máxima ([E] absorbe daño dirigido a aliados).
    - **[P] Provoca** a los enemigos de un radio corto: atacan a Halvard en lugar de al otro héroe.
    - **[P] +2 de bloqueo** mientras dura.
  - **Interrupción:** termina si el escudo se rompe o si lo mueven.
  - **Inmunidades:** los jefes no se ven afectados por la provocación.
  - **Contrajuego:** daño en área o a distancia (futuro).
- **Sinergias:** Catalizadores de área y Aeron.
- **Contrapartidas:** reposición lentísima; poco daño.

### 12. Vesna (antes Fiora) · PC · Ruptor · Academia del Último Hechizo
- **Rol:** Ruptor [E].
- **Identidad mecánica:** **duelista antiélite**. Brilla contra un enemigo duro aislado y sufre contra enjambres, porque el duelo la obliga a ignorar al resto.
- **Ataque automático — Estocada de duelo:**
  - **Tipo:** estocadas rápidas.
  - **Objetivo:** bloqueado o el más cercano.
  - **Alcance:** CaC.
  - **Efecto:** **[P] perforación parcial** de armadura («busca huecos» [E]).
  - **Daño:** Físico.
- **Habilidad especial — Duelo de honor [P]** (sustituye «Cuatro puntos débiles»):
  - **Activación:** elegir un enemigo dentro de alcance corto. Contra jefes, efectos reducidos.
  - **Duración:** prov. 6 s.
  - **Efectos:**
    - Solo ataca a ese enemigo y recibe **menos daño de él**.
    - **Contraataca** cada golpe suyo con una estocada adicional.
    - Si lo elimina durante el duelo, recupera vida y el 15 % del medidor (prov.).
  - **Interrupción:** si el objetivo sale del alcance (sigue la ruta) o si la mueven.
  - **Contrajuego:** enemigos rápidos que no se detienen; varios enemigos a la vez.
- **Sinergias:** Baluartes que sujetan al resto.
- **Contrapartidas:** enjambres; Alcance 3.

### 13. Brannoc (antes Garruk) · PC · Demoledor · Frontera Imposible
- **Rol:** Demoledor [E]. **Secundario [P]: Baluarte.**
- **Identidad mecánica:** Demoledor de **aguante** con una **ventana de poder que elige el jugador**, seguida de agotamiento.
- **Ataque automático — Hachazo ancestral:**
  - **Tipo:** golpe pesado.
  - **Objetivo:** bloqueado o el más próximo.
  - **Alcance:** CaC. Monoobjetivo.
  - **Daño:** Físico.
  - **Límites:** cadencia baja.
- **Habilidad especial — Cólera del exiliado:**
  - **Activación:** instantánea.
  - **Duración:** prov. 8 s.
  - **Efectos:** [E] más daño y más resistencia. **[P] +1 de bloqueo.**
  - **[P] Coste:** al terminar queda **agotado** unos segundos (menos cadencia). Esto lo diferencia de Uruvan: aquí el jugador decide el momento y paga después.
  - **Contrajuego:** usarla en el momento equivocado; el agotamiento.
- **Sinergias:** Distorsionadores que retienen; la curación de Aurenn o Solenne.
- **Contrapartidas:** enjambres rápidos; Alcance 3.

### 14. Bront · PC · Baluarte · Neón de Medianoche
- **Rol:** Baluarte [E]. **Secundario [P]: Puntero.**
- **Identidad mecánica:** Baluarte **a distancia** que protege por **interferencia**, no con el cuerpo. Sabotea la capacidad de atacar de los enemigos cercanos.
- **Ataque automático — Cañones gemelos:**
  - **Tipo:** ráfagas.
  - **Objetivo:** el más avanzado.
  - **Alcance:** medio-largo (Alcance 7 tras G-9). Monoobjetivo.
  - **Daño:** Energético.
- **Habilidad especial — Interceptor → [P] Cúpula de interferencia** (transformada, ver F §1.7):
  - **Activación:** instantánea, en su posición.
  - **Área:** círculo medio fijo.
  - **Duración:** prov. 6 s.
  - **Efectos:**
    - Los enemigos dentro **atacan más despacio** (debilitamiento).
    - Los héroes dentro reciben menos daño **en área y a distancia**.
    - **Dependencia (G-6):** cuando existan proyectiles enemigos, los que entren en la cúpula **se destruyen**.
  - **Contrajuego:** zona fija; enemigos que no atacan (pasan de largo).
- **Sinergias:** cualquier héroe cuerpo a cuerpo dentro de la cúpula.
- **Contrapartidas:** su valor completo depende de enemigos a distancia, aún inexistentes.

### 15. Eirwen · PC · Puntero · Última Sesión
- **Rol:** Puntero [E]. **Secundario [P]: Distorsionador.**
- **Identidad mecánica:** **artillería con utilidad**. Su lluvia **silencia** (interrumpe canalizaciones enemigas) y **revela**. Será clave contra los conjuradores del mundo 2 y los invisibles del mundo 3.
- **Ataque automático — Flecha del ocaso:**
  - **Tipo:** proyectil.
  - **Objetivo:** [P] élite (acorazados) si hay alguna; si no, el más avanzado.
  - **Alcance:** largo. Monoobjetivo.
  - **Efecto:** [E] perforación de armadura alta (prov. 50 %).
  - **Daño:** Físico.
- **Habilidad especial — Lluvia del silencio:**
  - **Activación:** colocar en un punto (alcance largo).
  - **Área:** círculo medio.
  - **Duración:** tras un retardo breve (prov. 1 s), lluvia durante 3 s (prov.).
  - **Efectos:**
    - Daño periódico Físico.
    - **[P] Silencio:** interrumpe canalizaciones enemigas.
    - **[P] Revela** invisibles.
  - **Contrajuego:** el retardo; los rápidos la atraviesan.
- **Sinergias:** torres de área.
- **Contrapartidas:** poco daño contra enjambres fuera de la lluvia.

---

## Raros

### 16. Veyra · R · Puntero · Neón de Medianoche
- **Rol:** Puntero [E].
- **Identidad mecánica:** la Puntero **pesada**. Su habilidad es un **haz canalizado que barre** un arco, mientras ella queda inmóvil: potencia a cambio de exposición.
- **Ataque automático — Cañón de fase:**
  - **Tipo:** ráfaga.
  - **Objetivo:** el más avanzado.
  - **Alcance:** largo. Monoobjetivo.
  - **Daño:** Energético.
- **Habilidad especial — Rayo de ruptura → [P] haz canalizado:**
  - **Activación:** apuntar una dirección. **Canalizada** (prov. 2,5 s).
  - **Área:** el haz barre un arco de 60° (prov.).
  - **Efectos:** daña todo lo que toca, con un daño que **aumenta con el tiempo** de canalización.
  - **Interrupción:** §0.11.
  - **Contrajuego:** mientras canaliza no ataca ni se mueve.
- **Sinergias:** Distorsionadores que agrupan delante (Voidra, Ophidia).
- **Contrapartidas:** enemigos que la alcanzan mientras canaliza.

### 17. Valdrin (antes Draeven) · R · Ruptor · Última Sesión
- **Rol:** Ruptor [E].
- **Identidad mecánica:** Ruptor de **supervivencia**. Se cura matando y su habilidad le **saca de un mal combate** golpeando a un objetivo grande. Kairo, en cambio, salta a donde ha preparado marcas.
- **Ataque automático — Hoja nocturna:**
  - **Tipo:** cortes veloces.
  - **Objetivo:** bloqueado o el más cercano.
  - **Alcance:** CaC.
  - **Daño:** Físico.
  - **Límites:** [E] **recupera vida al derrotar** enemigos, con tope por segundo (prov.).
- **Habilidad especial — Paso del eclipse:**
  - **Activación:** instantánea.
  - **Duración:** intangible prov. 1 s (no bloquea ni puede ser atacado).
  - **Efectos:** reaparece junto al **enemigo con más vida** en un radio medio y lo daña.
  - **Contrajuego:** suelta su bloqueo; los jefes pueden no ser buen destino (daño fijo).
- **Sinergias:** Baluarte que sujete.
- **Contrapartidas:** Alcance 4; el robo de vida exige derribos.

### 18. Kazen (antes Tenshi) · R · Ruptor · Frontera Imposible
- **Rol:** Ruptor [E].
- **Identidad mecánica:** Ruptor de **reposición ofensiva**. Su habilidad lo traslada por el camino dejando cortes que estallan: llega donde hace falta golpeando.
- **Ataque automático — Corte dimensional:**
  - **Tipo:** tajos rápidos.
  - **Objetivo:** bloqueado o el más cercano.
  - **Alcance:** CaC.
  - **Multiblanco:** alcanza al objetivo y a 1 adyacente.
  - **Daño:** Físico.
- **Habilidad especial — Línea del vacío → [P] Trazo del vacío** (diferenciada, ver F §2.2):
  - **Activación:** elegir un **destino en el camino** (distancia máxima prov.).
  - **Efectos:** se desplaza por la ruta hasta él dejando **cortes** cada cierta distancia. Tras un breve retardo, cada corte estalla y daña a los enemigos cercanos. **Termina en el destino.**
  - **Contrajuego:** abandona su posición; el retardo deja escapar a los rápidos.
- **Sinergias:** Baluarte compañero.
- **Contrapartidas:** Salud y Defensa 5.

### 19. Ravena · R · Catalizador · Última Sesión
- **Rol:** Catalizador [E]. **Secundario [P]: Distorsionador.**
- **Identidad mecánica:** Catalizadora de **desgaste protector**. Su zona daña poco a poco y **debilita**, así que protege a su compañero bajando el daño enemigo.
- **Ataque automático — Ala umbría:**
  - **Tipo:** cuchilla de energía.
  - **Objetivo:** el más avanzado.
  - **Alcance:** largo. Monoobjetivo.
  - **Daño:** Arcano (oscuro).
  - **[P]** Hace más daño a enemigos dentro de su zona.
- **Habilidad especial — Sueño depredador:**
  - **Activación:** colocar en un punto (alcance largo).
  - **Área:** círculo medio.
  - **Duración:** prov. 5 s.
  - **Efectos:** daño periódico Arcano y **reducción del ataque** de los enemigos dentro.
  - **Contrajuego:** los enemigos salen de la zona.
- **Sinergias:** Baluartes y Demoledores que sostienen dentro de la zona.
- **Contrapartidas:** Salud 5, Defensa 4.

### 20. Drakar · R · Demoledor · Frontera Imposible
- **Rol:** Demoledor [E]. **Secundario [P]: Ruptor.**
- **Identidad mecánica:** Demoledor de **asalto aéreo**. Salta sobre objetivos cercanos y su habilidad lo traslada a un punto lejano aterrizando con derribo.
- **Ataque automático — Garra desgarradora:**
  - **Tipo:** golpes pesados.
  - **Objetivo:** bloqueado.
  - **Alcance:** CaC.
  - **Daño:** Físico.
  - **[P]** Si no hay enemigos en CaC, **salta** sobre uno a distancia corta. Es lo que justifica su Alcance 6 (ver C).
- **Habilidad especial — Picado abisal:**
  - **Activación:** elegir un punto (alcance largo).
  - **Efectos:** se eleva (intocable y sin bloquear durante el ascenso) y cae. Daño en área y **derribo** a ligeros y medios. **Termina en el punto.**
  - **Contrajuego:** pesados y jefes no caen; abandona su bloqueo.
- **Sinergias:** zonas de control donde aterrizar.
- **Contrapartidas:** suma de estadísticas alta para su rareza (ver C).

### 21. Ophidia · R · Distorsionador · Academia del Último Hechizo
- **Rol:** Distorsionador [E].
- **Identidad mecánica:** **preparación de control**. Acumula petrificación con cada golpe y la convierte en un control fuerte que deja a los enemigos **frágiles al daño Físico**.
- **Ataque automático — Mirada pétrea:**
  - **Tipo:** descarga.
  - **Objetivo:** el más avanzado.
  - **Alcance:** largo. Monoobjetivo.
  - **Efecto:** **acumulaciones de petrificación** (ralentización leve por acumulación; prov. máx. 5).
  - **Daño:** Arcano.
- **Habilidad especial — Jardín de estatuas:**
  - **Activación:** apuntar una dirección.
  - **Área:** cono frontal.
  - **Efectos:**
    - Ralentiza a todos.
    - **Petrifica** (control duro, prov. 2 s) a los enemigos con suficientes acumulaciones.
    - **[P]** Los petrificados reciben **más daño Físico**.
  - **Inmunidades:** los jefes nunca se petrifican.
  - **Contrajuego:** la resistencia decreciente; necesita preparar las acumulaciones.
- **Sinergias:** Demoledores Físicos, torre de rebote y Zerik.
- **Contrapartidas:** suma de estadísticas baja (ver C); daño propio modesto.

### 22. Aurenn (antes Luneth) · R · Distorsionador · Frontera Imposible
- **Rol:** Distorsionador [E] (apoyo táctico).
- **Identidad mecánica:** **sostenimiento de grupo**. Es la principal curación del catálogo por debajo de Legendario, y ralentiza a los enemigos alrededor de su espíritu.
- **Ataque automático — Eco astral:**
  - **Tipo:** invocación menor que vuela hasta el objetivo y lo golpea [E].
  - **Objetivo:** el más avanzado.
  - **Alcance:** largo.
  - **Daño:** Arcano.
  - **Límites:** la invocación no bloquea ni carga el medidor.
- **Habilidad especial — Pacto de la aurora:**
  - **Activación:** colocar el espíritu en un punto cercano.
  - **Área:** círculo medio.
  - **Duración:** prov. 6 s.
  - **Efectos:**
    - [E] **Cura** de forma gradual a los héroes dentro y les da **resistencia** temporal.
    - **[P] Ralentiza** a los enemigos dentro.
  - **Límites:** §0.8.
  - **Contrajuego:** el daño en ráfaga supera la curación; zona fija.
- **Sinergias:** Baluartes y Demoledores cuerpo a cuerpo.
- **Contrapartidas:** poco daño.

---

## Épicos

### 23. Morrak · É · Catalizador · Frontera Imposible
- **Rol:** Catalizador [E]. **Secundario [P]: Distorsionador.**
- **Identidad mecánica:** **debilitador de masas**. Su onda instantánea, centrada en sí mismo y de gran radio, rebaja el poder ofensivo de todo un frente. Se diferencia de Ravena (zona colocada y persistente) en que es **inmediata y amplia, sin daño periódico**.
- **Ataque automático — Orbe tiránico:**
  - **Tipo:** esfera que **explota** al impactar (círculo pequeño).
  - **Objetivo:** [P] el enemigo con **más enemigos cerca** dentro de alcance.
  - **Alcance:** largo.
  - **Daño:** Arcano.
- **Habilidad especial — Dominio carmesí:**
  - **Activación:** instantánea, sobre sí mismo.
  - **Área:** círculo grande.
  - **Duración:** debilitamiento prov. 5 s.
  - **Efectos:**
    - Daño Arcano.
    - **Debilita**: menos daño y menos cadencia de los enemigos.
    - **[P]** Ralentiza un poco.
  - **Contrajuego:** se lanza desde su posición; necesita estar cerca del frente.
- **Sinergias:** héroes cuerpo a cuerpo que bloquean; Bront (interferencia que se suma, con tope).
- **Contrapartidas:** Velocidad 5.

### 24. Nyxara · É · Ruptor · Neón de Medianoche
- **Rol:** Ruptor [E]. **Secundario [P]: Demoledor.**
- **Identidad mecánica:** la Ruptora **de área**. Un Ruptor suele ir a por un objetivo; ella castiga **enjambres** con giros y suspensiones.
- **Ataque automático — Danza de obsidiana:**
  - **Tipo:** combinación veloz.
  - **Objetivo:** bloqueado o el más cercano.
  - **Alcance:** corto.
  - **Multiblanco:** **[P] cada cuarto ataque** es un **giro** que golpea alrededor (círculo pequeño).
  - **Daño:** Físico.
- **Habilidad especial — Último compás → [P] diferenciada:**
  - **Activación:** instantánea.
  - **Área:** círculo medio. 3 pulsos (prov.).
  - **Efectos:**
    - **Suspende** en el aire (control duro) a ligeros durante la secuencia.
    - Termina **ralentizando** a los supervivientes [E].
  - **Inmunidades:** jefes y pesados no se suspenden.
  - **Contrajuego:** la resistencia decreciente; las élites.
- **Sinergias:** torres de área y Voidra (agrupa).
- **Contrapartidas:** Salud 6, Defensa 5.

### 25. Kaelith · É · Demoledor · Última Sesión
- **Rol:** Demoledor [E]. **Secundario [P]: Puntero.**
- **Identidad mecánica:** Demoledor de **hoja larga y anticipación**. Golpea a distancia media, y su habilidad **marca la línea antes de cortar**: premia predecir el flujo de enemigos.
- **Ataque automático — Hoja del juicio:**
  - **Tipo:** tajo de gran alcance.
  - **Objetivo:** [P] el enemigo con **más vida** en alcance.
  - **Alcance:** medio. Monoobjetivo, daño concentrado.
  - **Daño:** Físico.
- **Habilidad especial — Horizonte partido → [P] corte diferido:**
  - **Activación:** apuntar una dirección.
  - **Duración:** la línea queda **marcada** prov. 1,5 s.
  - **Efectos:** al terminar, la línea entera estalla, incluidos los que hayan **entrado** durante el retardo, y una **onda** se expande en el extremo.
  - **Contrajuego:** los enemigos que salen de la línea antes del estallido.
- **Sinergias:** Distorsionadores que retienen dentro de la línea.
- **Contrapartidas:** cadencia 5; mal contra enjambres dispersos.

### 26. Astraion · É · Demoledor · Reino del Continue
- **Rol:** Demoledor [E]. **Secundario [P]: Baluarte** (mitiga la escasez de Baluartes de rareza alta).
- **Identidad mecánica:** el **pilar del equipo**. Golpea bien, y su habilidad **protege y refuerza el bloqueo** de los dos héroes.
- **Ataque automático — Golpe del farol** (antes «Llave luminosa»; arma: farol de umbrales):
  - **Tipo:** combinación que **alterna** golpes Físicos y Energéticos.
  - **Objetivo:** bloqueado.
  - **Alcance:** corto.
- **Habilidad especial — Portal de los aliados:**
  - **Activación:** instantánea, sobre sí mismo.
  - **Área:** círculo medio.
  - **Efectos:**
    - [E] Daño Energético y **escudo breve** a los héroes de la zona.
    - **[P] Mientras dure el escudo, cada héroe protegido bloquea un enemigo más.**
  - **Contrajuego:** el aliado debe estar cerca; escudos limitados (§0.8).
- **Sinergias:** cualquier compañero cuerpo a cuerpo.
- **Contrapartidas:** no tiene un pico de daño; su valor es de equipo.

### 27. Zeraph · É · Ruptor · Neón de Medianoche
- **Rol:** Ruptor [E].
- **Identidad mecánica:** Ruptor **versátil a cualquier distancia**. Cambia de arma solo y su habilidad es una **incursión de ida y vuelta**: golpea y regresa a su puesto. Kazen, en cambio, se queda en el destino.
- **Ataque automático — Arsenal cambiante:**
  - **Tipo:** espada (Físico) si el objetivo está en CaC; pistolas (Energético, alcance medio) si está más lejos [E].
  - **Objetivo:** bloqueado o el más avanzado.
- **Habilidad especial — Sinfonía del caos → [P] incursión:**
  - **Activación:** elegir una dirección del camino.
  - **Efectos:** recorre una distancia corta por la ruta golpeando a lo que encuentra y **vuelve**. Termina con un **disparo explosivo** al grupo más denso.
  - **Contrajuego:** no bloquea durante la incursión.
- **Sinergias:** Baluarte compañero.
- **Contrapartidas:** Defensa 6.

---

## Legendarios

### 28. Chronos · L · Distorsionador · Frontera Imposible
- **Rol:** Distorsionador [E].
- **Identidad mecánica:** **deshacer errores**. Su habilidad rebobina a **los dos héroes** del equipo: les devuelve la vida perdida recientemente y su posición anterior. Es la única forma de recuperar un mal combate sin curación directa.
- **Ataque automático — Fragmento temporal:**
  - **Tipo:** proyectil.
  - **Objetivo:** el más avanzado.
  - **Alcance:** largo.
  - **Efecto:** ralentización breve, no acumulable.
  - **Daño:** Arcano.
- **Habilidad especial — Rebobinado local:**
  - **Activación:** instantánea.
  - **Efectos:**
    - [E] Recupera la vida perdida en los últimos prov. 4 s y vuelve a la **posición** de entonces.
    - **[P] También al héroe aliado**, si está vivo.
  - **Límites:** [E] **no revive**; no deshace la vida perdida por la base ni el oro gastado.
  - **Contrajuego:** si se espera demasiado, no hay nada que rebobinar.
- **Sinergias:** héroes cuerpo a cuerpo que se arriesgan; Ruptores que abandonan su bloqueo.
- **Contrapartidas:** daño propio moderado.

### 29. Solenne · L · Catalizador · Frontera Imposible
- **Rol:** Catalizador [E]. **Secundario [P]: Distorsionador** (apoyo).
- **Identidad mecánica:** **guía de las torres**. Su campo daña, cura y además **aumenta el alcance de las torres** que cubre. Une a los héroes con la defensa.
- **Ataque automático — Estrella errante:**
  - **Tipo:** proyectil **teledirigido**.
  - **Objetivo:** el más avanzado.
  - **Alcance:** largo.
  - **Efecto:** **[P]** si el objetivo muere antes del impacto, busca otro.
  - **Daño:** Arcano.
- **Habilidad especial — Cuna cósmica:**
  - **Activación:** colocar en un punto (alcance largo).
  - **Área:** círculo grande.
  - **Duración:** prov. 6 s.
  - **Efectos:**
    - [E] Daño periódico a enemigos y curación gradual a héroes.
    - **[P] Las torres dentro ganan alcance.**
  - **Contrajuego:** zona fija.
- **Sinergias:** torres; héroes cuerpo a cuerpo.
- **Contrapartidas:** Velocidad 6.

### 30. Varkhan · L · Demoledor · Última Sesión
- **Rol:** Demoledor [E].
- **Identidad mecánica:** **abrelatas de acorazados**. Su cono destroza y deja a los enemigos **sin defensa** para las torres y el compañero.
- **Ataque automático — Descarga exterminadora → [P]:**
  - **Tipo:** disparo en **cono corto**, multiblanco, con daño que **cae con la distancia**. Así no repite el cambio de arma por distancia de Zeraph.
  - **Objetivo:** bloqueado o el más cercano.
  - **Daño:** Físico.
- **Habilidad especial — Protocolo de aniquilación:**
  - **Activación:** apuntar una dirección.
  - **Área:** cono grande.
  - **Efectos:** gran daño y **reducción de defensa** (armadura) prov. 6 s.
  - **[P] Recalentamiento:** tras usarla, no ataca durante prov. 2 s.
  - **Contrajuego:** el recalentamiento.
- **Sinergias:** torres de corrupción y rebote; Ophidia (petrificados que reciben más daño Físico).
- **Contrapartidas:** Velocidad 5; mal contra enemigos dispersos.

### 31. Eclipse · L · Distorsionador · Última Sesión
- **Rol:** Distorsionador [E].
- **Identidad mecánica:** **invierte el avance**. Los enemigos de su zona **caminan hacia atrás**, lo que regala tiempo a todo el sistema de torres. No atrae: así se distingue de Omnion y Voidra.
- **Ataque automático — Pulso invertido:**
  - **Tipo:** onda.
  - **Objetivo:** el más avanzado.
  - **Alcance:** largo.
  - **Multiblanco:** círculo pequeño alrededor del objetivo.
  - **Efecto:** ralentización [E].
  - **Daño:** Arcano.
- **Habilidad especial — Dominio del reverso → [P] inversión:**
  - **Activación:** colocar en un punto (alcance largo).
  - **Área:** círculo medio.
  - **Duración:** prov. 4 s.
  - **Efectos:**
    - Los enemigos dentro **retroceden** por la ruta a velocidad reducida. Los pesados solo se detienen; los jefes, ralentización reducida.
    - Daño periódico.
  - **Límites:** cuenta como control duro (§0.7).
  - **Contrajuego:** la resistencia decreciente.
- **Sinergias:** todas las torres y Nimue (los devuelve a la zona de congelación).
- **Contrapartidas:** suma de estadísticas alta para su rareza (ver C).

---

## Míticos

### 32. Omnion · M · Catalizador · Vertedero de Ideas (antes Reino del Continue)
- **Rol:** Catalizador [E]. **Secundario [P]: Distorsionador.**
- **Identidad mecánica:** **retira enemigos del flujo y los usa como munición**. No atrae para agrupar: **traga** y **escupe**.
- **Ataque automático — Esfera voraz:**
  - **Tipo:** absorbe energía del objetivo (daño Arcano) y la almacena.
  - **[P] Cada tercer ataque** lanza la energía acumulada como proyectil al enemigo más avanzado.
  - **Alcance:** medio.
- **Habilidad especial — Singularidad hambrienta → [P]:**
  - **Activación:** apuntar una dirección.
  - **Área:** círculo medio alrededor de Omnion.
  - **Efectos:**
    - **Traga** hasta N ligeros (prov. 5) del radio, que salen del camino unos segundos. Los medios son atraídos, pero no tragados.
    - Los **escupe** como proyectil explosivo en la dirección elegida: daño a los tragados y a los alcanzados.
    - Los tragados vuelven al camino **más atrás**, en el punto de impacto.
  - **Inmunidades:** pesados y jefes.
  - **Contrajuego:** el máximo de tragados; las élites.
- **Sinergias:** misiones de enjambres; torres de área en el punto de impacto.
- **Contrapartidas:** las élites no le temen.

### 33. Voidra · M · Catalizador · Neón de Medianoche
- **Rol:** Catalizador [E]. **Secundario [P]: Distorsionador.**
- **Identidad mecánica:** el **mejor agrupador** para las torres. Su núcleo atrae, y la explosión **crece con el número de atraídos**.
- **Ataque automático — Lanza de vacío:**
  - **Tipo:** descarga.
  - **Objetivo:** el más avanzado.
  - **Alcance:** largo. Monoobjetivo.
  - **Daño:** Arcano.
- **Habilidad especial — Colapso de antimateria:**
  - **Activación:** colocar en un punto (alcance largo).
  - **Duración:** prov. 2,5 s.
  - **Efectos:**
    - Núcleo que **atrae**: fuerte a ligeros, débil a medios; no afecta a pesados ni jefes.
    - Daña durante la duración y luego **estalla** con un daño que **escala con el número de enemigos atraídos** (con tope).
  - **Inmunidades:** [E] los inmunes al control no se desplazan.
  - **Contrajuego:** pocas víctimas = poca explosión.
- **Sinergias:** torre de rebote, Veyra, Nyxara y Varkhan.
- **Contrapartidas:** la suma de estadísticas más alta de su rareza (ver C).

### 34. Uruvan (antes Nexarion) · M · Demoledor · Frontera Imposible
- **Rol:** Demoledor [E]. **Secundario [P]: Baluarte.**
- **Identidad mecánica:** **se crece ante la adversidad**. Acumula «furia» cuando las cosas van mal, y esa furia decide la **duración** de su habilidad. A diferencia de Brannoc, no elige el momento: lo provoca la partida.
- **Ataque automático — Puño cataclísmico:**
  - **Tipo:** golpe.
  - **Objetivo:** bloqueado.
  - **Alcance:** CaC.
  - **Multiblanco:** **salpica** a enemigos próximos al objetivo [E].
  - **Daño:** Físico.
- **Pasiva [P] — Adversidad:** acumula furia al recibir daño, cuando cae su aliado o cuando la base pierde vida, con tope. **No aumenta su daño pasivo**, para no multiplicar el poder.
- **Habilidad especial — Furia de los mil impactos:**
  - **Activación:** instantánea.
  - **Área:** círculo corto.
  - **Duración:** **depende de la furia** (mín.–máx., prov.); consume la furia.
  - **Efectos:** secuencia de golpes que termina en un **impacto sísmico** que derriba a ligeros. Durante la secuencia **no se le desplaza** y **sigue bloqueando**.
  - **Contrajuego:** sin adversidad, la secuencia es corta.
- **Sinergias:** situaciones desesperadas; Chronos (rebobinar sin perder la furia: [?] por decidir).
- **Contrapartidas:** cuando todo va bien, rinde menos.

---

## Trascendente

### 35. Aethern · T · Catalizador · Frontera Imposible
- **Rol:** Catalizador [E]. Sin secundario: la falta de especialización es su rasgo.
- **Identidad mecánica:** **evita la derrota del equipo** una vez por activación. Su campo daña y **protege de caer**. Es poderoso, pero con un límite estricto, y no es un multiplicador de daño.
- **Ataque automático — Pulso primordial** (antes «Veredicto primordial»):
  - **Tipo:** haz.
  - **Objetivo:** el más avanzado.
  - **Alcance:** largo. Monoobjetivo.
  - **Daño:** Arcano.
- **Habilidad especial — Génesis del umbral:**
  - **Activación:** instantánea, en su posición.
  - **Área:** círculo grande.
  - **Duración:** prov. 5 s.
  - **Efectos:**
    - [E] Daño periódico a enemigos y **protección** de aliados.
    - **[P] Concretada:** los héroes dentro **no pueden bajar de 1 de vida**, una vez por activación y por héroe.
  - **Límites:** no resucita; no protege a la base.
  - **Contrajuego:** el daño en ráfaga **después** del campo.
- **Sinergias:** héroes cuerpo a cuerpo que se arriesgan.
- **Contrapartidas:** zona fija.
