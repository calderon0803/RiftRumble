# G · Decisiones pendientes

> Ordenadas por prioridad: las primeras **bloquean** la especificación numérica; las últimas pueden esperar a la producción gráfica. Cada una indica la recomendación y dónde se desarrolla.

## Prioridad 1 · Bloquean la especificación numérica

| Id | Decisión | Opciones | Recomendación | Dónde |
|---|---|---|---|---|
| **G-10** | **Fórmula de conversión 1–10 → valores reales**, crecimiento por nivel y significado del **Alcance** | (a) Alcance = radio de ataque efectivo, que incluye saltos, cortes amplios y conos; (b) Alcance = distancia exacta del golpe | (a) y una tabla de bandas como B §0.2 | C (O4), B §0.2 |
| **G-11** | **¿Afecta la rareza al crecimiento por nivel?** | A: mismo crecimiento por rol; B: multiplicador pequeño por rareza | A | E §2 |
| **G-3** | **Medidor para Nexo y Kira** (hoy tienen tiempo de recarga) | Pasan al medidor / mantienen recarga | Medidor, por coherencia. La «carga» de Kira se renombra («filo») o se integra en el medidor | F C3–C4 |
| **G-4** | **Reglas del medidor**: fuentes, topes, inicio de misión y conservación al caer | Valores de prueba de B §0.6 | Aprobar el modelo (por ataque, no por objetivo; tope por segundo; las invocaciones no cargan; conservar el 50 % al caer; empezar a 0 %) y validarlo en simulación | B §0.6 |
| **G-12** | **Capacidad de bloqueo por rol** | Baluarte 3, Demoledor 2 y el resto 1; secundario Baluarte +1 | Aprobar como valores de prueba | B §0.3 |
| **G-5** | **Tipos de daño**: 3 mecánicos (Físico, Energético, Arcano). ¿La armadura reduce el Energético a la mitad? | Completa (como hoy) / a la mitad | A la mitad: da al Energético un papel propio entre el Físico y el Arcano | B §0.5 |
| **G-13** | **Reglas comunes de control y defensa**: peso del enemigo, resistencia decreciente, topes de ralentización y reducción de daño, escudos e intangibilidad | Valores de prueba de B §0.7–0.9 | Aprobar el modelo | B §0.7–0.9 |

## Prioridad 2 · Afectan al catálogo

| Id | Decisión | Recomendación | Dónde |
|---|---|---|---|
| **G-1** | **Nombres y conceptos con riesgo de propiedad intelectual** | Cambiar los de severidad alta: Fiora, Bastion, Luneth y Garruk. Valorar Shinra, Tenshi y Draeven. Renombrar Nexarion para que no se confunda con Nexo. Las propuestas de nombre son orientativas | F §1.7 |
| **G-14** | **Habilidades transformadas**: aceptar o ajustar | Kairo (marca en lugar de garfio), Fiora (duelo), Bront (cúpula de interferencia), Rokka (obstáculo con vida), Mistral (potencia torres), Veyra (haz que barre), Tenshi (trazo), Kaelith (corte diferido), Eclipse (inversión), Omnion (tragar y escupir), Aethern (impide caer). Más los cambios de ataque automático: Zerik, Varkhan y Nyxara | B |
| **G-7** | **Baluarte de rareza alta** | Aceptar los secundarios Baluarte (Garruk, Astraion, Nexarion). Opcional: Astraion pasa a Baluarte como rol principal | D §1 |
| **G-9** | **Estadísticas atípicas**: Sylka 37 (C), Bront 41 (PC), Drakar 43 (R), Ophidia 35 (R), Eclipse 49 (L), Kairo V 6 (Ruptor) | Definir un presupuesto por rareza (media ± 3) y ajustar Bront, Drakar y Eclipse. Aceptar Ophidia si su control escala | C |
| **G-8** | **Reparto por mundos**: Vertedero tiene 1 héroe y Frontera 11 | Mover Omnion, Mistral y Sylka al Vertedero de Ideas | A, F §1.2 |
| **G-15** | **Narrativa**: cambios de tema y espejos del Editor | Aceptar: Kaelith (obediencia), Nimue (tiempo congelado), Bastion (custodia algo que existe), Kairo (deuda), Garruk (exilio tras una guerra) y Morrak y Voidra como espejos | A, F §2.10 |

## Prioridad 3 · Sistemas del juego que hay que construir

| Id | Decisión | Por qué | Recomendación |
|---|---|---|---|
| **G-6** | **Nuevos tipos de enemigo**: a distancia (proyectiles), voladores, invisibles, canalizadores y con peso (ligero/medio/pesado/jefe) | Bront, Eirwen, Sylka y otros los necesitan para mostrar todo su valor; los mundos 2–4 los traen | Añadir el **peso** al implementar los héroes; el resto, con los mundos 2–4 |
| **G-2** | **Nombre de los «fragmentos del héroe»**, que choca con la moneda general «fragmentos» | Confusión para el jugador y en el código | Renombrar la **moneda general** (p. ej., «hilos de la Trama») y reservar «fragmentos» para los del héroe, o al revés |
| **G-16** | **Tiradas**: tasas por rareza, garantía, banners separados para héroes y torres o uno combinado | Diseñado en `docs/08` §5, pero con 3 rarezas; ahora son 7 | Definir tras G-2 y G-11 |

## Prioridad 4 · Pueden esperar
- **G-17:** cantidad de diálogo por héroe (frases de combate, presentación).
- **G-18:** ¿pasivas para más héroes? Hoy solo Nexarion tiene una, porque aporta una mecánica que no cubren su ataque ni su habilidad.
- **G-19:** dirección artística de cada héroe. Fuera de esta fase. Ya hay notas para alejar el diseño de su inspiración: Voltra, Omnion y Astraion.

## Ya establecido (no requiere decisión)
35 héroes; 7 rarezas con su reparto; 6 roles; 6 estadísticas conceptuales; 6 mundos; niveles 1–60 con categorías I–VI; fragmentos del héroe para ascender; Nexo y Kira fuera de la colección; habilidad manual al 100 % del medidor; el medidor no carga fuera de combate.
