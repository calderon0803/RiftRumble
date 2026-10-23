# Arte · 01 · Biblia visual

> **Estado:** propuesta (2026-10-23). Fija las reglas que debe cumplir cualquier estilo final: tamaños, lectura, color, lenguaje de formas y formato de entrega. El **estilo de acabado** (vectorial, pixel art o 3D renderizado) se decidirá con las **pruebas de estilo** (§12). Todos los nombres siguen siendo provisionales.
> **Fuentes:** mundos en [`docs/08`](../08-diseno-de-mundo.md) §4; personajes en la [biblia de personajes](../personajes/README.md): A (identidad), B y H (mecánicas) y F (propiedad intelectual).

## 1. Principios

1. **La lectura táctica manda.** En una pantalla de móvil, el jugador debe distinguir en menos de un segundo:
   - héroe o enemigo;
   - qué héroe es;
   - qué enemigo es y cuánto pesa;
   - qué torre es;
   - qué estado tiene cada uno (ralentizado, inmovilizado, corrupto).

   Si un detalle bonito estorba la lectura, se quita.
2. **Silueta, luego color, luego detalle.** Cada personaje se reconoce rellenado de negro. El color confirma y el detalle solo se ve con zoom.
3. **Un juego, seis mundos.** Cada mundo tiene su paleta. Héroes, interfaz y efectos comparten reglas comunes, para que un héroe de Neón no parezca de otro juego en el Reino del Continue.
4. **Identidad propia.** Ningún diseño reproduce una silueta, un arma, un traje o una paleta reconocibles de su obra de inspiración (§11).
5. **Menos es más en movimiento.** Pocos colores por personaje, animaciones de pocos fotogramas bien elegidos y efectos que duran lo justo.

## 2. Restricciones técnicas

| Dato | Valor | Origen |
|---|---|---|
| Casilla isométrica | 64 × 32 px | `src/view/iso.gd` |
| Resolución lógica | 1280 × 720, `canvas_items`, `expand` | `project.godot` |
| Tamaño en el iPhone 14 Pro | Con el mapa entero en pantalla, 1 px lógico ≈ 0,55 pt | cámara inicial |
| Héroe actual | Fotograma de 32 × 48 px (≈ 27 pt en el móvil) | `art/placeholder/` |
| Ruta | 2 casillas de ancho, 3 carriles | `docs/03` |

### Tamaños objetivo (alto visible del personaje, en px lógicos, sin sombra)

| Elemento | Alto | Ancho máximo | Notas |
|---|---|---|---|
| Héroe | **44–52** | 40 | Más grande que cualquier enemigo no jefe |
| Enemigo ligero | 22–28 | 24 | Caben 3 en el ancho del camino |
| Enemigo medio | 30–36 | 32 | |
| Enemigo pesado | 38–44 | 44 | Más **ancho** que alto: el peso se lee por la anchura |
| Jefe | 80–110 | 120 | Ocupa todo el ancho del camino |
| Torre | 56–72 | 48 | La base encaja en la plataforma de 64 × 32 |
| Proyectil | 6–12 | — | Siempre con un núcleo claro y un borde oscuro |

**Resolución de trabajo:** se dibuja a **2×** (un héroe ocupa 88–104 px de alto en el original) y se muestra a escala 0,5. Así se ve nítido en pantallas de alta densidad, y el zoom de la cámara (hasta ×2) no pixela. Si el estilo final es pixel art, se dibuja a 1× y se escala con `nearest`.

## 3. Reglas de lectura

1. **Contorno:**
   - personajes y torres llevan un contorno oscuro de **2 px a 1×** (4 px a 2×);
   - el suelo y los objetos decorativos **no** llevan contorno;
   - así lo jugable se separa del fondo.
2. **Valor y saturación:**
   - los suelos son de **saturación media-baja** y valor medio;
   - personajes, enemigos y efectos, de **saturación alta**;
   - nada importante tiene el mismo valor que el suelo de su mundo.
3. **Sombra:** cada personaje tiene una **elipse de sombra** separada, al 35 % de opacidad. Indica dónde está en el suelo, aunque salte o vuele.
4. **Héroe frente a enemigo:**
   - los **héroes** tienen el contorno **oscuro cálido** (`#2A1A2E`) y un **anillo de suelo** de su color cuando están seleccionados;
   - los **enemigos** tienen el contorno **oscuro frío** (`#14121F`) y una **marca de error del Editor**: una franja desplazada o un píxel roto, en el color de acento de enemigos de cada mundo.
5. **Estados** (ya existen como `EffectDef.ViewFlag`): se muestran con un **icono pequeño sobre la cabeza** y un **tinte**, nunca solo con el tinte.

   | Estado | Tinte | Icono |
   |---|---|---|
   | Ralentizado | azul `#5EC8FF` | caracol o reloj |
   | Inmovilizado (control duro) | blanco con anillo | candado o cadena |
   | Corrompido | magenta `#FF3EA5` | píxel roto |
   | Sellado | dorado `#F2C14E` | runa |

6. **Barras:**
   - vida **verde → rojo** encima del personaje;
   - medidor de habilidad debajo, del **color del héroe**, que se vuelve **blanco** al llenarse (ya implementado);
   - las barras de los enemigos solo aparecen cuando han recibido daño.

## 4. Color

### 4.1 Paletas de mundo (suelo, decorado y enemigos)

| Mundo | Base del suelo | Decorado | Luz / acento | Sombra | Acento de enemigos |
|---|---|---|---|---|---|
| 1 · Reino del Continue | verde `#5FA35A` | ladrillo `#C8643C` | oro `#F2C14E`, cielo `#4FC3F7` | `#2B3A55` | rojo cereza `#E8384F` |
| 2 · Academia del Último Hechizo | piedra violeta `#5B4A7A` | pergamino `#EFE3C2` | dorado `#E0B84A` | azul noche `#1E2A5A` | verde veneno `#7BE36B` |
| 3 · La Última Sesión | moqueta `#3A2A2E` | granate `#7A1E2C` | fósforo `#7CFF6B`, sepia `#C9A46A` | `#121014` | blanco proyector `#F4F1E8` |
| 4 · Neón de Medianoche | asfalto `#1A2238` | metal `#3C4A66` | magenta `#FF3EA5`, cian `#22E4FF` | `#0D1328` | amarillo señal `#FFE14D` |
| 5 · Vertedero de Ideas | cartón `#9B8F7A` | choque deliberado: `#FF6B35`, `#7BFF00`, `#00B3FF` | rosa `#FF4FD8` | `#3A3530` | naranja aviso `#FF8A00` |
| 6 · Frontera Imposible | piedra `#6E6A64` | piedra clara `#B8B0A2`, musgo `#5C7A4A` | vetas de los mundos 1–5 | `#2E2B28` | el color del mundo de origen del enemigo |

### 4.2 Colores con significado (iguales en todos los mundos)

| Uso | Color | Notas |
|---|---|---|
| Daño Físico | acero `#E6E9EF` | números y destellos de impacto |
| Daño Energético | cian eléctrico `#3FE0FF` | |
| Daño Arcano | violeta `#B07CFF` | |
| Curación | verde `#5BE38A` | |
| Escudo | dorado pálido `#FFF1A8` | ya se usa al recibir escudo |
| Oro y monedas | `#FFD34D` | |
| Pérdida de vida de la base | `#FF5C7A` | |

### 4.3 Rareza

Solo en la **interfaz** (marcos de cartas, tiradas, ficha) y en un **brillo sutil del anillo de suelo**. **Nunca** cambia el tamaño ni la silueta del héroe en combate.

| Común | Poco común | Raro | Épico | Legendario | Mítico | Trascendente |
|---|---|---|---|---|---|---|
| `#9AA3AE` | `#5BC77A` | `#4C9BFF` | `#A35BFF` | `#F2B233` | `#FF4F5E` | iridiscente (degradado `#7FFFE0` → `#C69BFF` → `#FFE38A`) |

## 5. Lenguaje de formas por rol

La forma dominante de la silueta anuncia el rol. El color del héroe es libre, pero el rol se lee por la forma.

| Rol | Forma dominante | Postura | Arma o elemento | Ejemplo de lectura |
|---|---|---|---|---|
| **Baluarte** | **Cuadrado** ancho, base pesada | Plantado, piernas abiertas | Escudo, muro, armadura | «No pasa nadie» |
| **Demoledor** | **Trapecio invertido** (hombros enormes) | Inclinado sobre el arma | Arma más grande que el cuerpo | «Golpe pesado» |
| **Ruptor** | **Triángulo** agudo, apuntando hacia delante | Echado hacia delante, en carrera | Hojas cortas, garras | «Rápido y letal» |
| **Puntero** | **Vertical** fino con una línea larga | Erguido, de perfil | Arma larga (rifle, arco, cañón) | «Dispara lejos» |
| **Catalizador** | **Círculo** y aura | Flotando o con los pies separados del suelo | Orbe, energía en las manos | «Poder en área» |
| **Distorsionador** | **Espiral** asimétrica, capas | Ladeado, ropa o partes que ondean | Elemento que gira u orbita | «Altera el espacio» |

Un rol secundario se nota en **un** rasgo. Por ejemplo, Astraion (Demoledor + Baluarte) lleva hombros de Demoledor y un farol que hace de escudo.

## 6. Proporciones y construcción de personajes

- **Proporción «chibi» de 2,5–3 cabezas.** Cabeza grande para la expresión, cuerpo corto y manos y pies grandes para la lectura de la acción.
  - Los **colosos** (Rokka, Halvard, Brannoc, Uruvan, Varkhan) llegan a 3,5 cabezas, con el cuerpo ancho, pero sin pasar de la altura máxima del héroe.
  - Los **no humanoides** (Voltra, Omnion, Voidra, Aethern, Eclipse) siguen la forma de su rol y la altura del héroe.
- **Regla de los 3 rasgos:** cada héroe se identifica por **una silueta**, **un par de colores** y **un objeto**. Si se tapa uno de los tres, los otros dos bastan.
- **Paleta por héroe:** 1 color principal (≈ 60 %), 1 secundario (≈ 30 %) y 1 acento (≈ 10 %), más el contorno y la piel o material. **Máximo 5 colores** visibles a 1×.
- **Arma o elemento exagerado:** del 40 al 100 % de la altura del cuerpo. Es lo que más se ve en movimiento.
- **Rareza = densidad de detalle y efectos**, no tamaño. Un Común lleva formas simples y un efecto de habilidad limpio. Un Mítico o el Trascendente llevan capas, partículas en reposo y animaciones de habilidad más largas, dentro de la misma altura.

## 7. Animación

| Animación | Fotogramas | FPS | Notas |
|---|---|---|---|
| Reposo | 4 | 8 | Respiración o flotación; nunca quieto del todo |
| Andar | 6 | 12 | |
| Ataque | 4–6 | 12–15 | El **fotograma de impacto** coincide con el disparo o el golpe de la simulación |
| Habilidad | 6–10 | 12–15 | Más largo en rarezas altas; la simulación no espera a la animación |
| Recibir golpe | 2 | 12 | Destello blanco + retroceso de 1–2 px |
| Caer (KO) | 4 | 10 | Termina en un estado «fuera de juego» (translúcido) |
| Victoria | 4–6 | 10 | Opcional, para la pantalla de resultados |

- **Direcciones:** se dibujan **2** (diagonal de frente y diagonal de espaldas) y se **reflejan** para obtener las 4 diagonales isométricas. Las armas se dibujan pensando en el reflejo: nada de texto ni asimetrías que importen.
- **Punto de apoyo:** el centro de los pies, en la misma posición en todos los fotogramas.
- **Enemigos:** reposo 2, andar 4, ataque 3 y muerte 4. **Jefes:** como los héroes, más 1–2 animaciones de fase.

## 8. Fichas visuales de los personajes

> Silueta, colores (principal / secundario / acento) y objeto. Son la base para las pruebas de estilo y los encargos. «Alejamiento» indica qué evitar respecto a la inspiración (F, G-19).

### Protagonistas

| Personaje | Silueta | Colores | Objeto | Notas |
|---|---|---|---|---|
| **Nexo** | Distorsionador: capa asimétrica en espiral, cuerpo esbelto | cian `#6FF3FF` / azul tinta `#1D2B4F` / blanco | Anillo-umbral que orbita a su espalda | Guardián: calma, gestos amplios; el portal repite la forma del anillo |
| **Kira Volt** ✅ | Ruptor: triángulo hacia delante, coleta larga | magenta `#FF6FD8` / grafito `#2C2433` / amarillo chispa `#FFE14D` | Espada de energía recta, de un filo y punta en ángulo, con 6 muescas que se iluminan (el filo, 0–6) | **Diseño aprobado** (2026-10-23): [`art/concept/hero_blade/kira_concepto_v2.webp`](../../art/concept/hero_blade/kira_concepto_v2.webp). Chaqueta corta con top corto (decisión del usuario), mallas grafito con paneles rosas, guantes sin dedos y botas con suela rosa |

### Comunes

| # | Héroe | Silueta | Colores | Objeto | Alejamiento / notas |
|---|---|---|---|---|---|
| 1 | Aeron | Trapecio, espadón apoyado en el hombro | acero `#8E9BB0` / rojo óxido `#9C3B2E` / oro `#F2C14E` | Espadón con un número de jugador grabado | Nada de pelo de punta ni hoja ancha tipo «buster»: espadón recto, de mandoble, y casco abollado |
| 2 | Zerik | Vertical, antena-visor, cañón en el brazo | blanco esmalte `#EDEFF2` / azul `#3D7BFF` / naranja `#FF8A3D` | Visor de diagnóstico con texto de error | Robot explorador cuadrado, no humanoide de armadura azul |
| 3 | Raiko | Postura de guardia baja y baja estatura | blanco kimono `#F3EEE4` / azul celeste `#5EC8FF` / negro | Vendas que se iluminan al empujar | Sin pelo de punta ni aura dorada |
| 4 | Voltra | Esfera de energía con «patas» de chispa; flota | amarillo `#FFE14D` / azul neón `#22E4FF` / negro | Enchufe o farola en miniatura como «cola» | **No animal**: nada de orejas largas ni mejillas eléctricas; ser de cables y tensión urbana |
| 5 | Sylka | Vertical, mochila enorme de reliquias | caqui `#B59A6A` / verde `#4E7A4A` / rojo `#D94B3A` | Ballesta y trampas colgando de la mochila | Exploradora, no aventurera de pantalón corto y dos pistolas |
| 6 | Mistral | Alas de hélice, cuerpo pequeño | azul cielo `#8FD3FF` / cobre `#C07A3E` / blanco | Turbina dorsal | Inventor-pájaro, alas mecánicas |
| 7 | Rokka | Cuadrado enorme de chatarra | gris chatarra `#7C7F86` / óxido `#B5651D` / verde musgo `#6E9B4A` | Placas de señales de tráfico como armadura | Coloso amable: ojos grandes |
| 8 | Kagero | Trapecio, un brazo oscuro y más grande | negro `#1E1B24` / violeta `#7A4DFF` / blanco | Sello en el brazo que brilla en el 3.er golpe | Sin llamas en la mano ni uniforme de bombero |

### Poco comunes

| # | Héroe | Silueta | Colores | Objeto | Alejamiento / notas |
|---|---|---|---|---|---|
| 9 | Kairo | Triángulo, capucha y rostro cubierto | ceniza `#4A4448` / brasa `#FF6A2B` / ámbar | Cadena de brasas (marca de deuda) | Sin garfio ni cráneo en llamas |
| 10 | Nimue | Vertical, túnica larga que ondea como una marea | azul hielo `#A8E6FF` / azul profundo `#1F4E8C` / plata | Aguja-varita de cristal | |
| 11 | Halvard | Cuadrado total, armadura de muralla | piedra `#8A8578` / azul acero `#3E5C8A` / oro viejo | Martillo de asedio y hombreras-almena | Nada de torreta transformable |
| 12 | Vesna | Triángulo fino, estoque largo | blanco `#F5F2EC` / azul real `#2D4FA8` / oro | Estoque y capa corta | Sin parche de duelista |
| 13 | Brannoc | Trapecio ancho, piel de animal | marrón `#6B4A32` / verde bosque `#3E5A36` / hueso | Hacha de una hoja enorme | Sin rasgos de bestia ni cuernos de planeswalker |
| 14 | Bront | Cuadrado: exotraje con cañones gemelos | naranja industrial `#FF8A3D` / grafito / cian | Cañones a los hombros, piloto pequeño visible | Exotraje de obra, no mecha rosa con conejo |
| 15 | Eirwen | Vertical, arco largo, cuerpo translúcido | gris espectral `#B7C2CC` / azul noche / rojo ocaso `#D9534F` | Arco de hueso | |

### Raros

| # | Héroe | Silueta | Colores | Objeto | Alejamiento / notas |
|---|---|---|---|---|---|
| 16 | Veyra | Vertical, cañón de brazo muy largo | negro mate / verde fase `#5CFFB0` / blanco | Cañón de fase con disipadores | **Sin armadura esférica naranja ni casco de visor verde**; cazadora con abrigo largo |
| 17 | Valdrin | Triángulo elegante, abrigo largo | negro `#1A1420` / burdeos `#7A1E3A` / plata | Dagas curvas y gemelos de luna | Sin vampiro de capa con cuello alto |
| 18 | Kazen | Triángulo, coleta y una sola espada | blanco `#F1EFEA` / añil `#2B3A8C` / rojo `#C8323C` | Katana con la vaina a la espalda | Sin alas ni halo |
| 19 | Ravena | Espiral, alas de humo | violeta oscuro `#3A1F4D` / rosa niebla `#D88CC8` / oro | Alas que se deshacen en plumas | |
| 20 | Drakar | Trapecio con alas plegadas | rojo sangre `#8C1F2A` / negro / ámbar `#FFB13D` | Garras y alas membranosas | **Sin dragón espacial ni pico**; bípedo con cuernos hacia atrás |
| 21 | Ophidia | Espiral, cabello en mechones serpenteantes | verde jade `#3E9C7A` / piedra `#A39E93` / dorado | Ojos que brillan y velo | Sin serpientes vivas en el pelo |
| 22 | Aurenn | Círculo, espíritu acompañante | blanco cálido `#FFF4E0` / dorado `#E0B84A` / azul alba `#8FC6FF` | Espíritu-zorro de luz | |

### Épicos

| # | Héroe | Silueta | Colores | Objeto | Alejamiento / notas |
|---|---|---|---|---|---|
| 23 | Morrak | Círculo con capa y corona rota | carmesí `#A0182E` / negro / oro | Orbe tiránico flotando sobre la mano | Espejo del Editor: guiños de «tijeras y regla» del villano, en rojo |
| 24 | Nyxara | Triángulo, falda o abrigo que gira | obsidiana `#1B1A22` / magenta `#FF3EA5` / plata | Abanicos-cuchilla | |
| 25 | Kaelith | Trapecio alto, espada muy larga | gris acero / azul medianoche `#1C2A4A` / blanco | Espada larga con la línea marcada en la hoja | **Sin pelo plateado largo ni ala negra única ni gabardina negra**; armadura de comandante |
| 26 | Astraion | Trapecio, farol de umbrales grande | azul cielo `#4FC3F7` / blanco / oro `#F2C14E` | **Farol de umbrales** (no llave) que proyecta el escudo | **Sin llave-espada ni coronas o cadenas** |
| 27 | Zeraph | Triángulo, espada y pistola cruzadas | rojo `#D63A3A` / negro / amarillo | Espada a la espalda y dos pistolas | Sin gabardina roja larga ni pelo blanco |

### Legendarios, míticos y trascendente

| # | Héroe | Silueta | Colores | Objeto | Alejamiento / notas |
|---|---|---|---|---|---|
| 28 | Chronos | Espiral, abrigo de viaje y reloj de arena | marrón cuero `#7A5235` / bronce `#C69C4A` / azul tiempo `#6FB8FF` | Reloj de arena que gira al revés | |
| 29 | Solenne | Círculo, manto de estrellas | azul noche `#1E2A5A` / blanco estelar / oro | Estrella errante sobre la mano | |
| 30 | Varkhan | Trapecio, arma de cono a dos manos | gris militar `#4A5048` / naranja alerta `#FF7A1A` / negro | Rejilla de recalentamiento que brilla | Sin máscara de calavera |
| 31 | Eclipse | Espiral, cuerpo «en negativo» | negro / blanco invertido / violeta `#8A4DFF` | Halo partido que gira al revés | **Sin «mundo al revés» de otra cosmología**: reverso como **negativo fotográfico** (ligado al mundo 3) |
| 32 | Omnion | Círculo: criatura redonda con boca grande | verde lima `#9BE564` / violeta `#6B3FA0` / blanco | Barriga-portal en espiral | **Sin bola rosa que inhala** ni copia de habilidades; criatura de chatarra y cables del Vertedero |
| 33 | Voidra | Espiral, cuerpo de partículas | negro violáceo `#1C1030` / cian `#22E4FF` / blanco | Núcleo de antimateria en el pecho | **Sin «parásito» ni materia corrupta azul de esa obra**: corrupción como **ruido de señal** |
| 34 | Uruvan | Trapecio colosal | piedra roja `#8A3A2A` / bronce / lava `#FF8A3D` | Puños-roca con grietas que brillan con la furia | La furia se lee en las grietas (0–100) |
| 35 | Aethern | Círculo perfecto, sin rasgos humanos | blanco `#F8F6F0` / iridiscente / oro | Anillos concéntricos que giran despacio | Sin «juez divino» con balanza |

## 9. Enemigos y jefes

- **Concepto común:** son **«errores» del Editor**, versiones simplificadas o corruptas de los habitantes de cada mundo. Llevan la marca de error (§3.4) y el acento de enemigos de su mundo.
- **Peso → forma:**
  - **ligero**, pequeño y redondo;
  - **medio**, más alto;
  - **pesado**, **ancho** con placas;
  - **jefe**, ocupa el camino.
  - El jugador debe saber de un vistazo si un empuje funcionará.
- **Mecánicas visibles:**
  - el **núcleo** del «continue» se ve dentro del enemigo antes de soltarlo;
  - los **conjuradores** del mundo 2 muestran su barra de canalización;
  - los **invisibles** del mundo 3 se ven como un contorno distorsionado cuando están revelados a medias.

## 10. Torres, efectos e interfaz

- **Torres:**
  - **base común** (pie que encaja en la plataforma) con **cabeza por tipo**;
  - el **nivel 1 → 3** añade volumen y detalle a la cabeza, no altura;
  - el **color de la cabeza** = tipo de daño principal (§4.2), con el acento del tipo de torre:
    - corrupción en magenta;
    - sellos en dorado;
    - rebote en cian.
- **Efectos de habilidad:**
  - en el **color del héroe** y con la **forma del área real** (círculo, línea, cono o zona) dibujada en el suelo durante 0,2–0,4 s;
  - el jugador aprende el alcance viéndolo;
  - como máximo, unas 30 partículas por habilidad en móvil.
- **Números de daño:** solo críticos, derribos y efectos especiales; el resto se lee por el destello de impacto.
- **Interfaz:**
  - marcos simples de esquinas cortadas, en referencia al **hilo** y la **Trama**;
  - texto en una fuente redondeada y legible;
  - iconos de rol con la forma de §5;
  - la rareza solo en marcos (§4.3).

## 11. Propiedad intelectual: lista de comprobación

Antes de aprobar un diseño:
1. ¿La silueta rellena de negro recuerda a un personaje conocido? Si es así, cambiar la proporción, el arma o el peinado.
2. ¿La combinación de colores es la «firma» de un personaje conocido (p. ej., armadura naranja con visor verde)? Si es así, cambiar al menos 2 de los 3 colores.
3. ¿El arma u objeto es emblemático de otra obra (llave-espada, espada «buster»)? Si es así, sustituirlo (ya hecho en G-1 con el farol de Astraion).
4. ¿El nombre de un movimiento o de un objeto coincide con otra obra? Si es así, renombrarlo.
5. Los héroes marcados en G-19 (Voltra, Omnion, Astraion, Kaelith/Aeron, Veyra/Voidra/Drakar) se revisan dos veces.
6. **Material generado por IA:** si se usa, solo como boceto o referencia interna. El arte final debe ser original y revisarse con esta lista. **No** se usan nombres de obras ni de artistas en las indicaciones.

## 12. Formato de entrega y siguientes pasos

### Proceso de diseño (decidido el 2026-10-23)
1. **Concepto:** hoja de personaje generada con IA (ChatGPT o la API de imágenes de OpenAI) a partir de un encargo escrito desde esta biblia. Se revisa contra la silueta, la paleta, el objeto y la lista de §11, y se corrige sobre la misma imagen hasta aprobarla.
2. **Versión de juego:** el mismo personaje, cabezón (≈ 3 cabezas) y en vista isométrica, para comprobar la lectura a ≈ 50 px.
3. **Animación por piezas:** hoja con el personaje separado en piezas (cabeza, pelo, torso, brazos, piernas y arma), animadas en Godot por transformaciones. Generar cada fotograma por separado no sirve, porque el personaje cambia de uno a otro.
4. Las imágenes aprobadas se guardan en `art/concept/<id>/` como referencia.

### Carpetas y nombres
```
art/
  heroes/<id>/            hero_blade/, hero_aeron/…
    <id>_idle.png         hojas por animación, en una fila
    <id>_walk.png
    <id>_attack.png
    <id>_ability.png
    <id>_hit.png
    <id>_ko.png
    <id>_portrait.png     retrato para la interfaz (256 × 256)
  enemies/<id>/
  towers/<id>/            base y cabeza por nivel
  fx/
  ui/
  worlds/w1/              suelo, decorado
```
- **Hojas:** fotogramas del mismo tamaño en una fila, con el punto de apoyo en el centro inferior y 2 px de margen transparente.
- **Importación en Godot:**
  - filtro **lineal** y mipmaps desactivados si el estilo es vectorial o 3D;
  - **nearest** si es pixel art.
- **Código:** hoy cada héroe usa un único `sprite` con `hframes`. Para varias animaciones se pasará a `SpriteFrames` (`AnimatedSprite2D`), con un recurso por héroe y la vista eligiendo la animación por estado. Es un cambio pequeño en `hero_view.gd`.

### Pruebas de estilo (siguiente paso)
1. **Kira, Nexo y Aeron**, a tamaño real, en el mapa del mundo 1, en el iPhone: reposo, andar y ataque.
2. Comprobar con la **prueba de silueta** (rellenos de negro) y la **prueba del gris** (sin color) que los tres se distinguen entre sí y de los enemigos.
3. Elegir el estilo de acabado: **vectorial**, **pixel art** o **3D renderizado** (`docs/arte` recogerá la decisión).
4. Con el estilo aprobado: interfaz de tiradas y retratos, luego héroes por tandas, luego enemigos y mundos.
