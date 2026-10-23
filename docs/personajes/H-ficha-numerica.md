# H · Ficha numérica

> **Estado:** valores de prueba **(prov.)** para los 35 héroes, con la fórmula de G-10. Todavía no se han validado en la simulación (§7).
> Valores de combate de nivel 1, bloqueo y crecimiento: [H · Valores base](H-valores-base.md), **generado** desde la matriz de C con `tools/hero_sheet.gd`. Este documento fija lo demás: ataques multiblanco, habilidades y mejoras de categoría.
> Reglas comunes (medidor, control, peso, escudos y topes): B §0. Progresión y economía: E y [`docs/10`](../10-economia.md).

## 1. Unidad de potencia: **P**

**P = DPS del héroe** a su nivel actual (0,5 × Ataque × crecimiento del rol). El daño de ataques y habilidades se expresa en **múltiplos de P**. Así escala solo con el Ataque, como exige E §1, y nunca dos veces.

*Ejemplo:* Aeron a nivel 1 tiene P = 4. Su Impacto del umbral (8 P) hace 32 de daño a cada enemigo del área. A nivel 40 (P = 8,7) hace 70.

*Calibración:* el Corte prismático de Kira con el filo lleno hace 32 de daño con P = 3, es decir, ≈ 10 P por enemigo alineado. Las plantillas de §2 se mueven en ese orden de magnitud.

## 2. Plantillas comunes

Cada habilidad parte de una plantilla. La rareza no cambia los coeficientes (B §0.10): se nota en el Ataque, que ya está en P, y en los efectos añadidos.

### Tamaños (casillas; el camino mide 2)
| Forma | Pequeño | Medio | Grande |
|---|---|---|---|
| Círculo (radio) | 1,2 | 1,8 | 2,6 |
| Línea (largo × ancho 1) | 3 | 4,5 | 6 |
| Cono | 2 / 60° | — | 3,5 / 90° |
| Alcance de uso | corto 3 | medio 5 | largo 8 |

### Daño
| Plantilla | Coeficiente |
|---|---|
| Ráfaga en área, línea o cono | **8 P** por enemigo |
| Golpe a un solo objetivo | **15 P** |
| Zona con daño periódico | **2 P/s** (menos si la zona también controla) |
| Objetivos secundarios de un ataque automático (cono, adyacente, salpicadura) | **50 %**; salpicadura **40 %** en radio 0,8 |
| Rebote del ataque automático | **60 %**, a ≤ 1,5 casillas, sin repetir objetivo |

### Control y apoyo
| Efecto | Valor base | Notas |
|---|---|---|
| Ralentización de habilidad | **35 %** durante 3 s | Tope combinado −60 % (B §0.7) |
| Ralentización de ataque | 10–20 % durante 1–2 s | |
| Control duro | **1,5 s** sobre ligeros | Medios ×0,5, pesados ×0,25, jefes inmunes; resistencia decreciente |
| Empuje | **1,5 casillas** (ligeros), 0,75 (medios) | Pesados y jefes, nada |
| Debilitamiento | **−30 %** de daño y −25 % de cadencia enemigos, 5 s | |
| Escudo | **25–30 %** de la vida máxima del protegido | Tope 40 %; dura ≤ 6 s; no se acumula del mismo origen |
| Curación | **3–4 %** de la vida máxima por segundo | Nunca resucita |
| Reducción de daño propia | 20–40 % | Tope combinado 60 % |

### Medidor
Igual para todos (B §0.6): 6 % por ataque (+1 % por objetivo extra, tope +2 %), 8 % por derribo, 0,2 % por cada 1 % de vida perdida, 3 % por aplicar control (cada objetivo, como mucho cada 3 s) y tope de 10 %/s. **Objetivo:** 1 o 2 usos por oleada.

## 3. Mejoras de categoría

Las mejoras de E §3 con cifras. **II** y **IV** cambian una cifra de la habilidad o del ataque; **VI** es la maestría. Ninguna suma un porcentaje plano de daño.

## 4. Fichas

Abreviaturas:
- **Fís.** = Físico, **Ene.** = Energético, **Arc.** = Arcano.
- **r** = radio.
- **lig./med.** = enemigos ligeros y medios.

### Comunes

| # | Héroe | Ataque automático | Habilidad | Cat. II | Cat. IV | Cat. VI |
|---|---|---|---|---|---|---|
| 1 | Aeron | Fís. Cono: +1 adyacente al 50 % | Sobre sí, r 1,2: 8 P, empuje y derribo 0,8 s a lig. | r 1,2 → 1,6 | Cono: +2 adyacentes | Derribo también a med. (0,4 s por peso) |
| 2 | Zerik | Ene. Al más avanzado, monoobjetivo | Línea 6: 8 P, +15 % por enemigo atravesado (tope +75 %) | Tope +75 → +120 % | Rastro 3 s: ralentiza 25 % | Rebota 1 vez al final (línea 3, 50 %) |
| 3 | Raiko | Ene. Monoobjetivo | Línea 4,5: 5 P y empuje de 2 casillas (lig.) / 1 (med.) | Línea 4,5 → 6 | Empuje completo a med. | La onda vuelve: 2.º paso al 50 % y empuje de 1 casilla |
| 4 | Voltra | Ene. Rebote a 1 (60 %) | Sobre sí, r 1,8: 8 P y ralentiza 35 % 2 s | r 1,8 → 2,3 | Rebote a 2 | Deja 4 chispas de 3 P que rebotan 1 vez |
| 5 | Sylka | Fís. Prioriza élites | Trampa (uso 5, dura 20 s; la dispara el primer no ligero), r 1,2: 12 P al que la dispara, 8 P al resto y ralentiza 40 % 3 s | r 1,2 → 1,6 | 2 trampas activas | Marca a la élite 6 s: +20 % de daño recibido |
| 6 | Mistral | Fís. Rebote a 1 (60 %) | Sobre sí, r 1,8, 6 s: torres +30 % de cadencia, aliado +30 % de velocidad; ráfaga que empuja 0,5 a lig. | 6 → 8 s | Rebote a 2 | Las torres de la zona ganan +0,5 casillas de alcance |
| 7 | Rokka | Fís. Monoobjetivo | Barrera (≤ 2 casillas delante, 10 s) con vida = 60 % de la de Rokka; Rokka recibe −25 % de daño mientras exista | Vida 60 → 90 % | Ocupa todo el ancho del camino | Al romperse aturde 1 s en r 1,8 |
| 8 | Kagero | Combinación Fís./Fís./Arc. (×0,8 / ×0,8 / ×1,4) | Al de más vida en CaC: 15 P con 60 % de perforación; r 1,2: 5 P | Perforación 60 → 80 % | El 3.er golpe salpica (40 %, r 0,8) | Ejecuta élites no jefe por debajo del 15 % de vida |

### Poco comunes

| # | Héroe | Ataque automático | Habilidad | Cat. II | Cat. IV | Cat. VI |
|---|---|---|---|---|---|---|
| 9 | Kairo | Ene. Marca 5 s (máx. 3) | Salta al marcado más avanzado (uso 8): 12 P al objetivo y 8 P en r 1,2; +20 % de medidor si lo mata | Máx. 3 → 4 marcas | La explosión ralentiza 35 % 2 s | Encadena a una 2.ª marca a ≤ 3 casillas (8 P) |
| 10 | Nimue | Arc. Ralentiza 10 % por acumulación (máx. 2), 2 s | Zona (uso 8), r 1,8, 4 s: 1,5 P/s; al acabar congela 1,5 s a lig./med. (pesados: ralentiza 35 %) | r 1,8 → 2,3 | La aguja acumula hasta 3 | Los congelados reciben +20 % de daño 3 s |
| 11 | Halvard | Fís. Cono a 3 (100/50/50 %) | **Canalizada 6 s:** escudo del 30 %, provocación en r 1,8 y +2 de bloqueo | Escudo 30 → 40 % (tope) | Provocación r 1,8 → 2,6 | Al terminar, onda del 50 % de lo absorbido en r 1,8 |
| 12 | Vesna | Fís. Perforación 25 % | Duelo (uso 3), 6 s: el rival le hace −40 % de daño (jefes −20 %); contraataca con el 50 % del golpe; si lo mata, +15 % de vida y +15 % de medidor | 6 → 8 s | El contraataque perfora 50 % | Encadena un 2.º duelo de 3 s con el más cercano |
| 13 | Brannoc | Fís. Monoobjetivo | 8 s: +40 % de daño, −25 % de daño recibido y +1 de bloqueo. Después, agotado 4 s (−40 % de cadencia) | Agotamiento 4 → 2,5 s | +1 de bloqueo más | El primer golpe derriba 1 s (r 1,2; lig./med.) |
| 14 | Bront | Ene. Ráfagas al más avanzado | Cúpula fija, r 1,8, 6 s: enemigos −35 % de cadencia de ataque; héroes −25 % de daño en área y a distancia | r 1,8 → 2,3 | −35 → −50 % | La cúpula sigue a Bront |
| 15 | Eirwen | Fís. Perforación 50 %; prioriza élites | Lluvia (uso 8), r 1,8, retardo 1 s y 3 s: 2,5 P/s, silencia y revela | El silencio dura 2 s más | r 1,8 → 2,3 | Los revelados reciben +15 % de daño 4 s |

### Raros

| # | Héroe | Ataque automático | Habilidad | Cat. II | Cat. IV | Cat. VI |
|---|---|---|---|---|---|---|
| 16 | Veyra | Ene. Monoobjetivo | **Canalizada 2,5 s:** haz de 6 casillas que barre 60°; de 4 P a 10 P por contacto según el tiempo de canalización | Arco 60 → 90° | Empieza en 6 P | Puede moverse al 30 % de velocidad |
| 17 | Valdrin | Fís. Recupera el 8 % de su vida por derribo (tope 15 %/s) | Intangible 1 s; reaparece junto al enemigo de más vida a ≤ 5 casillas: 15 P | Tope de robo 15 → 25 %/s | Intangible 1 → 1,5 s (tope B §0.8) | Reaparece con 2 golpes (15 P + 8 P) |
| 18 | Kazen | Fís. +1 adyacente al 50 % | Trazo por la ruta hasta ≤ 6 casillas, con un corte cada 1,5 (máx. 4); tras 0,6 s cada corte estalla: 6 P en r 1,0 | 6 → 8 casillas | Un corte por casilla (máx. 6) | Los cortes ralentizan 35 % 2 s |
| 19 | Ravena | Arc. +25 % de daño dentro de su zona | Zona (uso 8), r 1,8, 5 s: 1,5 P/s y −30 % de daño enemigo | r 1,8 → 2,3 | −30 → −40 % | La zona sigue al enemigo de más vida (1,5 casillas/s) |
| 20 | Drakar | Fís. Si no hay nadie en CaC, salta a ≤ 2,3 casillas (cada 4 s) | Picado (uso 8): 0,6 s intocable; caída en r 1,8: 10 P y derribo 1 s (lig.) / 0,5 s (med.) | r 1,8 → 2,3 | Salto automático 2,3 → 3,1 | Terreno roto 4 s en r 1,8: ralentiza 30 % |
| 21 | Ophidia | Arc. Petrificación: 5 % de ralentización por acumulación (máx. 5), 4 s | Cono 3,5/90°: ralentiza 35 % 3 s; petrifica 2 s con ≥ 3 acumulaciones; los petrificados reciben +25 % de daño Físico | Cono 3,5 → 4,5 | Petrifica desde 2 acumulaciones | Al terminar, metralla de 6 P en r 1,2 |
| 22 | Aurenn | Arc. Invocación menor (no bloquea ni carga) | Espíritu (uso 3), r 1,8, 6 s: cura 4 %/s, −20 % de daño recibido y ralentiza 25 % | Curación 4 → 5,5 %/s | El espíritu menor ralentiza 15 % 1,5 s | Escudo del 15 % al entrar (1 vez) |

### Épicos

| # | Héroe | Ataque automático | Habilidad | Cat. II | Cat. IV | Cat. VI |
|---|---|---|---|---|---|---|
| 23 | Morrak | Arc. Orbe que explota (r 1,0, 50 %) en el grupo más denso | Sobre sí, r 2,6: 8 P; debilita 5 s y ralentiza 20 % | r 2,6 → 3,2 | El orbe debilita (−10 %, 2 s) | Escudo del 50 % del daño evitado (tope 20 %) |
| 24 | Nyxara | Fís. Cada 4.º ataque, giro en r 1,2 | Sobre sí, r 1,8: 3 pulsos en 1,5 s, 4 P cada uno; suspende a lig.; al final ralentiza 35 % 3 s | 3 → 4 pulsos | Giro cada 3.er ataque | Los suspendidos reciben +20 % de daño |
| 25 | Kaelith | Fís. Al de más vida; monoobjetivo | Línea 6 marcada 1,5 s; luego estalla: 10 P (también a los que entren) y onda final de 6 P en r 1,2 | Línea 6 → 7,5 | Retardo 1,5 → 1,0 s (mínimo) | La onda final se repite 1 s después |
| 26 | Astraion | Alterna golpes Fís. y Ene. | Sobre sí, r 1,8: 6 P y escudo del 25 % a los héroes (6 s); cada protegido bloquea +1 mientras tenga escudo | Escudo 25 → 35 % | El +1 de bloqueo dura 3 s tras romperse el escudo | Si expira sin romperse, cura lo que quede |
| 27 | Zeraph | Fís. en CaC / Ene. hasta 2,3 casillas | Incursión de 4 casillas por la ruta, ida y vuelta (1,2 s): 5 P a cada uno; disparo explosivo al grupo más denso (≤ 5 casillas): 8 P en r 1,2 | 4 → 5,5 casillas | Explosión de 12 P en r 1,6 | Elige el arma: espada (incursión +50 %) o pistolas (2 disparos) |

### Legendarios

| # | Héroe | Ataque automático | Habilidad | Cat. II | Cat. IV | Cat. VI |
|---|---|---|---|---|---|---|
| 28 | Chronos | Arc. Ralentiza 20 % 1 s | Rebobina 4 s a los dos héroes vivos (vida perdida y posición); no revive | Ventana 4 → 5 s | Limpia estados negativos (G-6) | Al volver, ralentiza 35 % 2 s en r 1,8 |
| 29 | Solenne | Arc. Teledirigido (cambia de objetivo si muere) | Campo (uso 8), r 2,6, 6 s: 1,5 P/s, cura 3 %/s y torres +0,6 casillas de alcance | r 2,6 → 3,2 | Torres +0,6 → +1,0 | La estrella rebota 1 vez (60 %) |
| 30 | Varkhan | Fís. Cono 2/60°: 100 % hasta 1 casilla y 60 % al final | Cono 3,5/90°: 12 P y −50 % de armadura 6 s; después, 2 s sin atacar | Cono 3,5 → 4,5 | −50 → −70 % de armadura | Recalentamiento 2 → 0,8 s |
| 31 | Eclipse | Arc. r 1,0 alrededor del objetivo (50 %); ralentiza 20 % 1,5 s | Zona (uso 8), r 1,8, 4 s: retroceden al 50 % de su velocidad (control duro); pesados detenidos; 1 P/s | r 1,8 → 2,3 | Retroceso al 75 % | Al acabar, ralentiza 35 % 3 s |

### Míticos

| # | Héroe | Ataque automático | Habilidad | Cat. II | Cat. IV | Cat. VI |
|---|---|---|---|---|---|---|
| 32 | Omnion | Arc. Absorbe; cada 3.er ataque lanza un proyectil de ×2 al más avanzado | r 1,8: traga hasta 5 lig. 2 s (med. atraídos 1 casilla); los escupe en línea 6: 8 P en r 1,5 a tragados y alcanzados, que vuelven al punto de impacto | 5 → 7 tragados | Traga también med. (cuentan como 2) | El proyectil se divide en 3 (r 1,0, 50 %) |
| 33 | Voidra | Arc. Monoobjetivo | Núcleo (uso 8), 2,5 s: atrae en r 2,3 (lig. 1,5 casillas/s, med. 0,75); 1 P/s; estalla con 6 P + 1,5 P por atraído (tope 8) | Tope 8 → 12 | Med. con atracción completa | Zona de vacío 3 s en r 1,8: ralentiza 35 % |
| 34 | Uruvan | Fís. Salpica (40 %, r 0,8) | Furia (0–100, §5). Secuencia de 2 s + 4 s × furia/100: un golpe cada 0,4 s de 2 P en r 1,2; impacto final de 10 P y derribo 1 s a lig.; no se le desplaza y sigue bloqueando | Furia máx. 100 → 150 (hasta 8 s) | Salpicadura 40 → 60 % en r 1,2 | El impacto final derriba también a med. |

### Trascendente

| # | Héroe | Ataque automático | Habilidad | Cat. II | Cat. IV | Cat. VI |
|---|---|---|---|---|---|---|
| 35 | Aethern | Arc. Haz monoobjetivo | Sobre sí, r 2,6, 5 s: 2 P/s; héroes −20 % de daño recibido; no bajan de 1 de vida (una vez por activación y héroe) | r 2,6 → 3,2 | 2 → 3 P/s | −20 → −35 % de daño recibido |

## 5. Detalles que no caben en las tablas

- **Furia de Uruvan:**
  - gana 1 por cada 1 % de vida perdida;
  - gana 30 cuando cae su aliado y 10 por cada vida que pierde la base;
  - tope de 100; se vacía al usar la habilidad;
  - **no** da daño pasivo (G-18).
- **Canalizadas** (Halvard, Veyra): se interrumpen según B §0.11. Si se interrumpen en la primera mitad, se devuelve el 50 % del medidor.
- **Invocaciones y zonas** (Aurenn, Sylka, Nimue, Ravena, Solenne, Eclipse, Voidra): no cargan el medidor (B §0.9). Cada héroe tiene como máximo 1 zona o trampa; Sylka puede tener 2 desde la categoría IV.
- **Habilidad «activa»** a efectos del medidor (no carga mientras dura): canalizadas, zonas, la cúpula, el escudo, el duelo, la cólera y la secuencia de Uruvan.

## 6. Protagonistas (decisión E-1)

Nexo y Kira conservan sus valores actuales como base de nivel 1. Toman el **nivel de historia** del mundo con el crecimiento de un rol:
- **Kira:** Ruptor (+2,5 % de vida y +3,5 % de ataque por nivel).
- **Nexo:** Distorsionador (+3 % y +2,5 %).

No tienen categorías ni mejoras II, IV y VI: es lo que los coleccionables aportan además de sus estadísticas.

| Comparación a nivel 1 | Índice (H · Valores base) |
|---|---|
| Kira | 12,9 |
| Nexo | 7,8 (su valor es el portal) |
| Media de los comunes | 14,8 |
| Media de los épicos | 20,7 |
| Trascendente | 28,9 |

**Conclusión:** en estadísticas, todos los coleccionables salvo tres comunes de apoyo superan a Kira. Los tres que no la superan (Voltra, Mistral y Zerik) aportan su valor con la habilidad.

## 7. Validación pendiente (en la simulación)

1. **Tipos de habilidad que hay que implementar.** Las 35 habilidades se reparten en unos **12 tipos** reutilizables (`ability_kind`). Hoy existen `line_strike` y `portal`:

| Tipo | Héroes |
|---|---|
| `burst_self` (área sobre sí) | Aeron, Voltra, Morrak, Astraion, Nyxara, Aethern* |
| `line` (línea o haz) | Zerik, Raiko, Kaelith*, Veyra* |
| `cone` | Ophidia, Varkhan |
| `zone` (zona colocada) | Nimue, Eirwen, Ravena, Solenne, Eclipse, Voidra*, Aurenn |
| `trap` | Sylka |
| `aura_buff` (potencia aliados o torres) | Mistral, Bront, Brannoc |
| `barrier` | Rokka |
| `strike_target` (golpe a un objetivo elegido) | Kagero, Vesna*, Valdrin |
| `dash` (desplazamiento ofensivo) | Kairo, Kazen, Drakar, Zeraph |
| `channel_shield` | Halvard |
| `rewind` | Chronos |
| `swallow` | Omnion |
| `rage_sequence` | Uruvan |

\* Con un parámetro o efecto propio sobre la plantilla.

2. **Medidor:** medir por héroe el tiempo hasta el 100 % en `w1_m1`–`w1_m5`. Objetivo: 1 o 2 usos por oleada.
3. **Ningún héroe gana solo:** con `tools/balance.gd`, ninguna misión debe poder ganarse sin torres con un solo héroe de nivel esperado (B §0.12).
4. **Coleccionable frente a protagonista:** a igual nivel, en su nicho, un coleccionable debe mejorar el resultado del protagonista al que sustituye (E-1).
5. **Ajuste:** cambiar primero los coeficientes de la plantilla (§2) y solo después los de un héroe concreto.

## 8. Tanda 1: Aeron, Zerik, Nimue y Astraion (implementados)

- **Implementado en la simulación:**
  - nivel y crecimiento; los protagonistas toman el nivel de historia;
  - defensa;
  - golpe a adyacentes y tipo de daño alterno;
  - tipos de habilidad `burst_self` (con empuje por peso y escudo con +1 de bloqueo) y `zone` (daño periódico y efecto final);
  - `line_strike` con daño en P y rampa por objetivo atravesado;
  - medidor por objetivos extra y por aplicar control.
- **En el juego:** todavía no se pueden conseguir (faltan las tiradas). Son datos en `content/heroes/` con tests.
- **Validación:** `godot --headless --path . --script res://tools/hero_check.gd`. Juega el mundo 1 con cada héroe y Kira, lanzando la habilidad sobre el grupo más denso. Los héroes no se mueven de su posición inicial, así que es un mínimo.

| Equipo | w1_m3 | w1_m4 | w1_m5 (jefe) | Usos por oleada | Segundos hasta el 100 % |
|---|---|---|---|---|---|
| Nexo + Kira (actual) | 1★ | 3★ | pierde | 0,4–0,5 | 52–100 |
| Aeron + Kira | 3★ | 3★ | 1★ | 0,8–1,0 | 35–51 |
| Zerik + Kira | 3★ | 3★ | 1★ | 0,8–1,0 | 37–58 |
| Nimue + Kira | 3★ | 3★ | 1★ | 0,8–1,0 | 31–52 |
| Astraion + Kira | 3★ | 3★ | 1★ | 0,6–1,0 | 39–57 |

**Lectura:**
- **Coleccionable frente a protagonista (E-1):** cada coleccionable mejora el resultado de Nexo, sobre todo en el jefe, que Nexo + Kira no ganan con este orden de construcción.
- **Sin torres:** en las misiones 3 a 5 todos pierden, solos y acompañados de Kira.
  - En las de introducción (w1_m1 y w1_m2) algunos ganan, pero los protagonistas con 2 héroes también ganan la 1.
  - Los coleccionables llegan después del mundo 1, así que esto solo se nota al repetir.
- **Medidor:** subido a 6 % por ataque y 8 % por derribo. Los coleccionables llegan a unos **0,8–1 usos por oleada**.
  - Subir más la carga casi no cambia nada: el límite es el tiempo fuera de combate de un héroe quieto.
  - Un jugador que mueve a sus héroes cargará más.
  - Nexo sigue lento (su ataque es débil y de alcance corto) y se revisará con el resto de los protagonistas.
- **Pendiente:**
  - repetir la validación en el mundo 2 a nivel de historia 8, cuando exista;
  - valorar si los coleccionables comunes más fuertes (Aeron, Rokka) superan demasiado a Kira (índice 20,5 frente a 12,9).
