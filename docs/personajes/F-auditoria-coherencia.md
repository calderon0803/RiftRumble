# F · Auditoría de coherencia

> **Estado (2026-10-22):** todas las decisiones de esta auditoría están **tomadas** (ver [G](G-decisiones-pendientes.md)). Los nombres originales que aparecen aquí son el registro histórico; en A–E ya figuran los nuevos («(antes X)»).

> Primera parte: **auditoría inicial** del catálogo recibido, hecha antes de completar las fichas. Segunda parte: **revisión global** del conjunto ya completado. Las propuestas se marcan **[P]** y se resumen en [G](G-decisiones-pendientes.md).

---

## Parte 1 · Auditoría inicial

### 1.1 Conflictos con decisiones ya tomadas en el proyecto

| # | Decisión vigente | Qué dice el catálogo | Tratamiento |
|---|---|---|---|
| C1 | `docs/08` §5: rarezas provisionales común, rara y épica | **7 rarezas** (C, PC, R, É, L, M, T) | El catálogo **sustituye** la propuesta provisional. Hay que actualizar `docs/08` |
| C2 | `docs/08` §5: los repetidos se convierten en **ecos** que mejoran al héroe | Los repetidos se convierten en **fragmentos específicos del héroe** para ascender de categoría | El catálogo sustituye a los ecos **para héroes**. **Choque de nombre:** «fragmentos» ya es la **moneda general** del juego (recompensas de misión). [?] G-2 |
| C3 | Juego actual: las habilidades de Nexo y Kira usan **tiempo de recarga** | La habilidad se activa manualmente cuando el **medidor llega al 100 %** | El catálogo define el sistema para coleccionables. [?] G-3: ¿Nexo y Kira pasan al medidor? Recomendación: sí, por coherencia |
| C4 | Juego actual: Kira tiene «carga» que aumenta el daño de su corte | El medidor es otra «carga» | Hay riesgo de confusión. [P] Renombrar la carga de Kira como «filo» o integrarla en el medidor (G-3) |
| C5 | Los héroes **luchan en el camino** y **bloquean** enemigos (decisión del usuario, Fase 4) | Roles a distancia (Puntero, Catalizador) | Compatible si cada rol tiene una **capacidad de bloqueo** distinta. [P] B §0.3 |
| C6 | Hoy los enemigos solo atacan **cuerpo a cuerpo** a los héroes; no hay enemigos a distancia, proyectiles enemigos, voladores, invisibles ni torres atacables | Varias habilidades dependen de **proyectiles enemigos** (Bront), **aliados detrás** (Rokka), **daño dirigido a aliados** (Bastion), **enemigos visibles** (Sylka, Aethern) | Esas habilidades necesitan **sistemas de enemigos que aún no existen**. Se reformulan para funcionar ya y se anotan las dependencias (G-6) |
| C7 | Tipos de daño del juego: cinético, digital, mágico (ignora armadura) y energía | Daño «energético», «oscuro», «espectral», «eléctrico», «de hielo»… | [P] Las variantes temáticas son **sabores**; mecánicamente se agrupan en 3 tipos (B §0.5). G-5 |
| C8 | Equipo de **2 héroes** por misión | El catálogo habla de «aliados» en plural | En partida un héroe tiene como mucho **1 héroe aliado** y las **torres**. Los efectos «a aliados» se definen para héroes y, donde se indica, para torres |
| C9 | Nexo y Kira son protagonistas | Fuera de la colección | Respetado: no figuran entre los 35 |

### 1.2 Distribución del catálogo

**Por rol y rareza:**

| Rol | C | PC | R | É | L | M | T | Total |
|---|---|---|---|---|---|---|---|---|
| Baluarte | 1 | 2 | – | – | – | – | – | **3** |
| Ruptor | – | 2 | 2 | 2 | – | – | – | **6** |
| Puntero | 2 | 1 | 1 | – | – | – | – | **4** |
| Catalizador | 1 | 1 | 1 | 1 | 1 | 2 | 1 | **8** |
| Demoledor | 3 | 1 | 1 | 2 | 1 | 1 | – | **9** |
| Distorsionador | 1 | – | 2 | – | 2 | – | – | **5** |

**Hallazgos:**
1. **Baluarte infrarrepresentado y solo en rarezas bajas** (3 héroes, ninguno por encima de PC). En este juego **bloquear el camino es central**: un jugador con suerte en las tiradas se encontrará casi sin Baluartes de alto nivel. [P] Dar rol secundario Baluarte a 2 o 3 héroes de rareza alta (ver Parte 2) y valorar un cambio de rol principal (G-7).
2. **Puntero sin nada por encima de Raro.** [P] Valorar secundarios Puntero en rarezas altas.
3. **Las rarezas altas se concentran en Catalizador y Demoledor** (de 13 héroes É–T, 9 son de daño). Riesgo explícito del encargo: «rareza alta = más daño». Se mitiga con identidades de utilidad (Parte 2) y con el criterio de diseño de B §0.10.

**Por mundo:**

| Mundo | Héroes | Nº |
|---|---|---|
| Reino del Continue | Aeron, Zerik, Mistral, Astraion, Omnion | 5 |
| Academia del Último Hechizo | Raiko, Shinra, Nimue, Fiora, Ophidia | 5 |
| Última Sesión | Kairo, Eirwen, Draeven, Ravena, Kaelith, Varkhan, Eclipse | 7 |
| Neón de Medianoche | Voltra, Bront, Veyra, Nyxara, Zeraph, Voidra | 6 |
| Vertedero de Ideas | Rokka | **1** |
| Frontera Imposible | Sylka, Bastion, Garruk, Tenshi, Drakar, Luneth, Morrak, Chronos, Solenne, Nexarion, Aethern | **11** |

4. **Vertedero de Ideas casi vacío (1)** y **Frontera Imposible sobrecargada (11)**, usada como cajón de sastre «multiverso». No hace falta repartir por igual, pero el mundo del humor merece representación. [P] Mover 2 o 3 héroes donde su historia encaja mejor (G-8): **Omnion** (absorbe residuos → vertedero de ideas desechadas), **Mistral** (inventor de cachivaches) y **Sylka** (arqueóloga de reliquias olvidadas).

### 1.3 Estadísticas: suma conceptual por rareza

Suma de las seis puntuaciones (no es poder real, pero orienta):

| Rareza | Rango de suma | Valores atípicos |
|---|---|---|
| C | 32–37 | Sylka 37 (alta para C) |
| PC | 34–41 | **Bront 41** (por encima de casi todos los Raros) |
| R | 35–43 | **Ophidia 35** (la más baja de su rareza), **Drakar 43** (por encima de dos Épicos) |
| É | 41–44 | — |
| L | 44–49 | **Eclipse 49** (por encima de Omnion, Mítico, con 47) |
| M | 47–50 | — |
| T | 57 | — |

Los atípicos no son necesariamente errores (un Distorsionador puede valer más por su control que por sus números), pero deben justificarse o corregirse cuando se defina el presupuesto de estadísticas por rareza. Ver [C](C-matriz-estadisticas.md) y G-9.

### 1.4 Coherencia entre estadísticas y rol

- **Kairo** (Ruptor) tiene Velocidad 6: baja para un rol de «movilidad elevada».
- **Bront** (Baluarte) tiene Alcance 8. Coherente con un exotraje con cañones, pero es un Baluarte a distancia: hay que decidir si bloquea (B §0.3).
- **Eclipse** (Distorsionador) tiene Ataque 9 y la mayor suma de su rareza: perfil de daño más que de control.
- **Ophidia** (Distorsionador, R) tiene la suma más baja de su rareza: coherente si su control es su valor; requiere que el control escale (E).

### 1.5 Mecánicas repetidas o demasiado parecidas

| Patrón | Héroes | Riesgo |
|---|---|---|
| **Ataque en línea que atraviesa** | Zerik, Raiko, Veyra, Kaelith, Tenshi (+ **Kira**, protagonista) | Seis variantes de «línea recta». **Alto** |
| **Atraer + dañar + explotar** | Omnion, Voidra, Eclipse | Tres agujeros negros. **Alto** |
| **Secuencia de golpes que termina con algo** | Fiora, Nyxara, Zeraph, Nexarion | Cuatro «combos con final». **Medio** |
| **Barrera o reducción de daño para aliados** | Rokka, Bastion, Bront, Astraion, Aethern | Cinco protectores. **Medio** |
| **Zona que ralentiza o congela** | Voltra, Nimue, Ophidia, Nyxara (final), Sylka (trampa) | Medio (distinguible por forma y condición) |
| **Desplazarse hasta el objetivo** | Kairo, Draeven, Tenshi | Medio |
| **Autopotenciación temporal** | Garruk, Nexarion | Medio |
| **Curación de aliados** | Luneth, Solenne (y Draeven, Chronos para sí mismos) | Bajo |

Las fichas de B proponen cómo diferenciar cada grupo (marcado **[P]**).

### 1.6 Narrativa: temas repetidos

- **Memoria** (4): Aeron (recuerdos perdidos), Nimue (hechizo que congela recuerdos), Kaelith (recuerdos fabricados) y Chronos (recuerda líneas temporales inexistentes). Además Aeron y Kaelith vienen de la misma obra de inspiración, con la misma dinámica. **Alto.**
- **Hogar o ciudad perdidos** (2): Eirwen y Bastion.
- **Poder oscuro heredado o maldición** (3): Shinra, Draeven y Kairo.
- **Unificar o reescribir la realidad** (2): **Morrak** («el caos necesita un dueño») y **Voidra** («reescribir los patrones de la vida»). Es el **mismo objetivo que el Editor**, el antagonista. Puede ser una gran baza narrativa (héroes tentados por la idea del villano) o una contradicción si no se trata. [P] Convertirlo en tema explícito (A).

### 1.7 Propiedad intelectual

Las inspiraciones son válidas como **arquetipo**. Estos puntos necesitan transformación porque copian un **nombre protegido**, una **mecánica emblemática** o una **historia reconocible**:

| Héroe | Problema | Severidad | Propuesta |
|---|---|---|---|
| **Fiora** | Mismo nombre que un personaje de *League of Legends*; «Cuatro puntos débiles» calca su mecánica de puntos vitales | **Alta** | Cambiar nombre y habilidad (ver B) |
| **Bastion** | Nombre de un héroe de *Overwatch* (y su diseño se inspira en otro de *Overwatch*) | **Alta** | Cambiar nombre |
| **Luneth** | Nombre del protagonista de *Final Fantasy III* (DS) | **Alta** | Cambiar nombre |
| **Garruk** | Nombre de un planeswalker de *Magic: The Gathering*; historia «cazador de dioses que renuncia a la venganza» = arco de la obra de inspiración | **Alta** | Cambiar nombre y transformar historia |
| **Shinra** | Nombre de la corporación de *Final Fantasy VII* (y de un personaje de *Fire Force*); «fuerza oscura heredada» = gen de la obra de inspiración | **Media** | Cambiar nombre y matizar historia |
| **Kairo** | «Garfio ígneo» que atrae + venganza desde un inframundo de fuego = mecánica e historia emblemáticas | **Media** | Transformar mecánica (marca y salto entre ascuas, sin arrastrar con cadena) |
| **Aeron + Kaelith** | Pareja espadón y amnesia frente a espada larga y memoria fabricada = la relación central de la obra de inspiración | **Media** | Romper el paralelismo: cambiar el tema de memoria de uno de los dos |
| **Zeraph + Tenshi** | Los dos de *Devil May Cry*, ambos Ruptor espadachines; «Línea del vacío» ≈ técnica emblemática | **Media** | Diferenciar estilos y evitar cualquier relación de hermanos |
| **Veyra + Voidra + Drakar** | Tres héroes de *Metroid*, con «materia corrupta» parecida a la de la obra | **Media** | Voidra: otro origen de la corrupción. Que no compartan historia |
| **Bront** | «Interceptor» ≈ matriz defensiva de la obra de inspiración (bloquea proyectiles) | **Media** | Transformar (ver B) |
| **Astraion** | «Llave luminosa» = arma emblemática de la obra de inspiración | **Media** | Cambiar el arma (p. ej., brújula o farol de umbrales) |
| **Aethern** | «Veredicto primordial» ≈ el movimiento característico de la obra de inspiración | **Baja-media** | Renombrar el ataque |
| **Eclipse** | «Plano invertido» = concepto central de la obra de inspiración | **Baja-media** | Mantener la idea de reverso con otra cosmología |
| **Tenshi** | Nombre de un personaje de *Touhou* (palabra común en japonés) | **Baja** | Valorar renombrar |
| **Draeven** | Muy cercano a «Draven» (*League of Legends*) | **Baja** | Valorar renombrar |
| **Nexarion** | Se confunde con **Nexo**, el protagonista | **Media (claridad)** | Renombrar |
| **Raiko** | «Onda del dragón» y personalidad de viajero en busca del combate justo = arquetipo muy reconocible | **Baja** | Matizar personalidad |

Nombres alternativos propuestos (solo orientativos): Fiora → **Vesna**; Bastion → **Halvard**; Luneth → **Aurenn**; Garruk → **Brannoc**; Shinra → **Kagero**; Nexarion → **Uruvan**; Tenshi → **Kazen**; Draeven → **Valdrin**. La decisión es del usuario (G-1).

---

## Parte 2 · Revisión global (tras completar las fichas)

### 2.1 Variedad dentro de cada rol
Ver el análisis completo en [D](D-roles-y-sinergias.md). Resumen:
- **Demoledor (9):** el más numeroso. Se diferencia por **forma de daño** (cono, círculo, objetivo + salpicadura, carga), **ritmo** (golpes lentos y pesados frente a rápidos) y **utilidad** (derribo, reducción de defensa, autopotenciación con condición). Riesgo residual: Garruk y Nexarion siguen siendo los dos «se fortalecen». Se separan por **condición**: Garruk elige cuándo y Nexarion depende de la adversidad.
- **Catalizador (8):** se diferencia por **geometría** (rebote, zona persistente, proyectil que persigue, absorción) y **efecto secundario** (ralentizar, debilitar, curar, controlar).
- **Ruptor (6):** se diferencia por **cómo** llega al objetivo (salto entre marcas, intangibilidad, cortes en trayectoria, duelo, danza, cambio de arma).
- **Distorsionador (5), Puntero (4) y Baluarte (3):** pocos, pero muy diferenciados.

### 2.2 Habilidades especiales casi idénticas: resueltas
- **Líneas (6 con Kira):**
  - **Zerik:** disparo que atraviesa y se fortalece por enemigo atravesado.
  - **Raiko:** onda que **empuja**.
  - **Veyra:** **haz canalizado que barre** un arco.
  - **Kaelith:** **corte diferido** que marca la línea y estalla después.
  - **Tenshi:** **cortes en puntos de una trayectoria** que el héroe recorre.
  - **Kira:** corte instantáneo cargado.
- **Agujeros negros (3):**
  - **Omnion** **absorbe** enemigos pequeños y los **escupe** como proyectil.
  - **Voidra** crea un núcleo que **escala con lo atraído**.
  - **Eclipse** **invierte el avance** de los enemigos de la zona (caminan hacia atrás). Eclipse ya no atrae.
- **Combos con final (4):**
  - **Fiora** pasa a ser un **duelo**: desafía a un enemigo y contraataca.
  - **Nyxara:** **ráfaga en área que suspende** a los enemigos ligeros.
  - **Zeraph:** **cambio de estilo** (espada o pistolas según la distancia), que termina en explosión.
  - **Nexarion:** su **contador de adversidad** determina la duración de la secuencia.
- **Protectores (5):**
  - **Rokka:** **obstáculo con vida** en el camino.
  - **Bastion:** **atrae los golpes** y absorbe daño.
  - **Bront:** **zona antiproyectiles y antiárea** (pendiente de enemigos a distancia).
  - **Astraion:** **escudo breve al aliado y portal de reposición**.
  - **Aethern:** **santuario** que impide morir durante un instante, con límite estricto.

### 2.3 Rarezas bajas útiles
Cada Común tiene un **nicho que no cubre ninguna rareza superior**:
- **Rokka:** obstáculo físico.
- **Mistral:** potencia torres.
- **Sylka:** trampas en el camino.
- **Zerik:** daño a distancia contra filas.
- **Voltra:** rebote barato contra enjambres.
- **Raiko:** empujar.
- **Aeron:** derribo en área.
- **Shinra:** limpiar élites.

Su techo de estadísticas es menor, pero su **función** no queda obsoleta.

### 2.4 Rareza alta ≠ solo más daño
De los 13 héroes É–T, la mayoría aporta **utilidad distintiva**:
- **Astraion:** protege y recoloca.
- **Chronos:** deshace daño.
- **Solenne:** sostiene.
- **Eclipse:** invierte el avance.
- **Omnion:** retira enemigos del camino.
- **Aethern:** evita una muerte.
- **Voidra:** agrupa para las torres.
- **Morrak:** debilita.

Los de puro daño (Kaelith, Zeraph, Varkhan, Nexarion) tienen **contrapartidas claras** (ver B).

### 2.5 Control abusivo: límites
- Hay **resistencia decreciente al control** por objetivo (B §0.7), con los **jefes inmunes al control duro y a los desplazamientos**. Así ninguna combinación de 2 héroes y las torres de sellos puede inmovilizar indefinidamente. Esta regla general **amplía** la inmunidad que ya tienen los sellos del Grimorio (3 s).
- Los efectos de **desplazamiento** solo afectan por completo a enemigos **ligeros** (B §0.7).

### 2.6 Curación, escudos, atracción, desplazamientos, invisibilidad y estados
Todos se rigen por las reglas comunes de B §0.7–0.9:
- **Escudos:** no se acumulan del mismo origen y tienen tope.
- **Curación:** sin resurrección.
- **Reducción de daño:** tope combinado.
- **Intangibilidad:** máximo 1,5 s (prov.) y durante ella el héroe no bloquea.
- **Invocaciones:** límite y sin carga del medidor.

Excepción vigilada: **Aethern** (impide morir), con límite de una vez por activación y por héroe.

### 2.7 Carga del medidor con ataques multiblanco
La carga se calcula **por ataque**, no por objetivo alcanzado, con un pequeño extra por objetivo adicional y tope (B §0.6). Los héroes con **rebote o área** (Voltra, Mistral, Bastion, Aeron, Nexarion, Morrak) no cargan más rápido por enfrentarse a enjambres. Las **invocaciones** (Luneth) no cargan el medidor de su invocador.

### 2.8 Coherencia entre estadísticas y patrones
Ver [C](C-matriz-estadisticas.md). Quedan **6 observaciones** que requieren decisión (G-9), sin modificar los valores.

### 2.9 Progresión sin multiplicar el mismo poder
Ver [E](E-progresion.md). Para no multiplicar el mismo poder, el nivel escala las **estadísticas** y la categoría desbloquea **mejoras cualitativas** de la habilidad. El mismo multiplicador nunca se aplica dos veces.

### 2.10 Personalidades y trasfondos
- **Tras los cambios propuestos:**
  - **Memoria:** Aeron (memoria perdida) y Chronos (memoria de lo que no ocurrió). Nimue pasa a otro tema: un hechizo que congela el **tiempo de una ciudad**. Kaelith deja la memoria fabricada: su conflicto es una **orden** que obedeció sin cuestionarla.
  - **Hogar perdido:** Eirwen. Bastion pasa a **custodiar algo que aún existe**.
  - **Poder oscuro:** Shinra (lo controla), Draeven (lo quiere romper) y Kairo (no hay maldición: es una deuda).
- **Morrak y Voidra** quedan como **espejos del Editor**: dos héroes que comparten parte de su idea y la rechazan a su manera. El recurso aporta profundidad, no contradicción.
