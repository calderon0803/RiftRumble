# RIFT RUMBLE — Biblia de personajes

Especificación conceptual, narrativa y jugable de los **35 héroes coleccionables**. Sin gráficos, sin código y sin cifras definitivas.

> Todos los nombres son provisionales. En datos y código se usarán ids neutros (`hero_c01`… o equivalentes) cuando se implementen.

## Documentos

| Doc | Contenido | Qué NO contiene |
|---|---|---|
| [F · Auditoría de coherencia](F-auditoria-coherencia.md) | **Empieza aquí.** Auditoría del catálogo (problemas detectados antes de completar las fichas), conflictos con decisiones ya tomadas, propiedad intelectual y revisión global | Fichas |
| [A · Biblia narrativa](A-biblia-narrativa.md) | Identidad, motivación, rasgo, trasfondo, procedencia y coherencia narrativa de cada héroe | Mecánicas |
| [B · Especificación de combate](B-especificacion-combate.md) | Marco común (alcances, objetivos, medidor, control, escudos) y, por héroe: ataque automático, habilidad, identidad mecánica, sinergias y contrapartidas | Historia y estadísticas |
| [C · Matriz de estadísticas](C-matriz-estadisticas.md) | Las seis puntuaciones conceptuales (sin convertir) y observaciones de coherencia | Valores reales |
| [D · Roles y sinergias](D-roles-y-sinergias.md) | Distribución de roles por rareza y mundo, variedad interna, fortalezas y debilidades, sinergias entre héroes y con torres | — |
| [E · Matriz de progresión](E-progresion.md) | Qué escala con nivel y categoría, qué queda fijo, y las excepciones de cada héroe | Costes y fórmulas no aprobadas |
| [H · Ficha numérica](H-ficha-numerica.md) | Cifras de prueba de ataques, habilidades y mejoras de categoría de los 35 héroes, en múltiplos de P (DPS del héroe) | Validación en la simulación |
| [H · Valores base](H-valores-base.md) | **Generado** desde C con `tools/hero_sheet.gd`: vida, DPS, defensa, velocidad, alcance y bloqueo por nivel | — |
| [G · Registro de decisiones](G-decisiones-pendientes.md) | Las 19 decisiones **tomadas** (2026-10-22), con su motivo y lo que implican para la implementación | — |

Cada dato de un héroe vive en **un solo documento**: la historia en A, el combate en B, las estadísticas en C y la progresión en E. D y F solo analizan y enlazan.

## Convenciones

- **[E] Establecido:** viene del catálogo o de decisiones ya tomadas en el proyecto.
- **[P] Propuesta:** nueva respecto al catálogo; **aprobada** en G (se mantiene la marca para distinguirla).
- **[?] Pregunta:** decisión abierta.
- **«(prov.)»:** cualquier cifra es provisional y de prueba, nunca un valor final.
- **Rareza** abreviada: C (común), PC (poco común), R (raro), É (épico), L (legendario), M (mítico), T (trascendente).

## Registro de avance

| Bloque | A | B | C | E | Estado |
|---|---|---|---|---|---|
| Auditoría inicial | — | — | — | — | ✅ |
| Marco común de combate | — | ✅ | — | ✅ | ✅ |
| Comunes (1–8) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Poco comunes (9–15) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Raros (16–22) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Épicos (23–27) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Legendarios (28–31) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Míticos (32–34) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Trascendente (35) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Revisión global (F) y decisiones (G) | — | — | — | — | ✅ |
| Decisiones tomadas y aplicadas a A–E | ✅ | ✅ | ✅ | ✅ | ✅ |

Fuera de alcance de esta fase: arte, animación, paletas, sprites, código, cifras finales y costes de progresión.
