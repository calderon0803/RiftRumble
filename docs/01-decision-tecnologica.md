# RIFT RUMBLE — Fase 1: decisión tecnológica

> Estado: **validada por la PoC (GO)**. Resultados en [02-resultados-poc.md](02-resultados-poc.md).
> Fecha: 2026-10-21. Versiones consultadas: Godot 4.7.2 (estable, 18-ago-2026), Phaser 4.x (v4.0.0 estable desde abril de 2026), Unity 6.x (6.3 LTS).

---

## 1. Análisis del concepto: retos principales

### Retos jugables
| Reto | Por qué es difícil | Consecuencia de diseño |
|---|---|---|
| Torres con identidad real (no variantes de DPS) | Cada torre introduce una regla distinta: estados acumulables, rebotes, fuerzas físicas, daño diferido | El combate necesita un **sistema de efectos de datos**, no lógica escrita en cada torre |
| Héroes activos en partidas de 3–6 min | El jugador gestiona economía + posicionamiento + habilidades a la vez; riesgo de saturación | Pocas acciones de héroe con tiempo de recarga claro; la pausa táctica es una posibilidad a considerar |
| Sinergias legibles | Si el jugador no ve por qué ocurre un combo, no lo aprende | Cada efecto necesita representación visual propia (iconos de estado, colores, números) |
| Aleatoriedad controlada (Gallinámbula) | «Divertido pero no una lotería» | RNG con semilla, varianza acotada y resultados medios garantizados |
| Escalada de daño (Cronoáncora, cadenas) | Combinaciones multiplicativas rompen el balance | Límites explícitos por efecto, profundidad máxima de cadena, sin recursión |
| Economía con decisiones | Construir / mejorar / ahorrar debe tener coste de oportunidad real | Curva de ingresos por oleada + interés o bonificación por adelantar oleadas (por evaluar) |

### Retos técnicos
1. **Isométrico 2.5D**: ordenación en profundidad de sprites altos (torres, jefes) sobre suelo en rombos; proyectiles con altura (arco) que deben dibujarse por encima o por debajo correctamente.
2. **Simulación separada de la presentación**: requisito explícito y clave para las pruebas, el rendimiento y una futura validación en servidor.
3. **Cantidad de entidades**: oleadas con 100–300 enemigos, cientos de proyectiles y partículas, todo ejecutándose también en navegadores de móvil.
4. **Sistema de efectos extensible**: acumulación, refresco, inmunidades, disparadores, propagación y protección frente a bucles.
5. **Navegador primero**: tamaño de descarga, tiempo de carga, audio con restricciones de reproducción automática, WebGL2 en Safari.
6. **Producción de arte**: el cuello de botella real del proyecto no es el código, sino producir pixel art isométrico detallado y animado.
7. **Desarrollo asistido por IA**: el agente debe poder editar escenas, datos y código como texto y **verificar** el resultado (tests headless, capturas).

---

## 2. Comparativa tecnológica

Puntuación de 1 a 5 con los criterios del encargo, en el orden de prioridad indicado.

| Criterio | **Godot 4.7** | **Phaser 4** | **Unity 6** | Defold (alternativa) |
|---|---|---|---|---|
| 1. Calidad 2.5D iso | 5 — TileMapLayer isométrico, Y-sort por nodo, luces 2D, shaders, partículas, AnimationPlayer/Tree | 4 — Renderer nuevo con filtros e iluminación; isométrico mediante Tiled y ordenación manual | 5 — Muy completo (Tilemap iso, URP 2D, iluminación) | 4 — Bueno, pero con menos herramientas de 2D avanzado |
| 2. Experiencia de producción (mapas, animaciones, contenido) | 5 — Editor integrado: escenas, tiles, animación, Resources como datos editables | 2 — Sin editor oficial gratuito (Phaser Editor es de pago); mapas con Tiled y todo lo demás en código | 5 — Editor muy maduro, pero pesado | 3 — Editor sencillo |
| 3. Sistemas jugables | 4 — Todo se escribe en GDScript; la estructura de nodos y señales encaja con TD | 4 — Todo en JS; libertad total | 5 — Ecosistema de assets enorme | 3 |
| 4. Rendimiento con muchas entidades | 4 — Nativo excelente; en web, renderer Compatibility (WebGL2) y GDScript interpretado sobre WASM. **Hay que medirlo (PoC)** | 4 — WebGL con batching muy eficiente; JS JIT rápido | 4 — Bueno; IL2CPP→WASM; arranque más lento en web | 5 — Muy ligero |
| 5. Plataformas (web → PWA → móvil) | 4 — Exportación web + opción PWA integrada; Android/iOS nativos. **C# no exporta a web**: obliga a GDScript | 5 — Web nativo; PWA trivial; móvil vía Capacitor (WebView) | 3 — Web en móvil soportado, pero builds pesados (>10–20 MB) y carga lenta | 5 — HTML5 muy pequeño |
| 6. Mantenibilidad / depuración / pruebas | 4 — Depurador, profiler, GUT/gdUnit4, ejecución headless | 4 — Ecosistema JS completo (Vitest, TS) | 4 — Test Framework; proyecto grande | 3 |
| 7. Desarrollo con agentes IA | 4 — Escenas `.tscn` y recursos `.tres` **en texto legible**; CLI headless para tests y exportación | 5 — Todo es código; validación en navegador | 2 — Escenas YAML con GUIDs, frágiles de editar sin el editor; meta-files | 3 — Formatos de texto, pero ecosistema pequeño |
| 8. Backend | 3 — Sin SDK oficial de Supabase; HTTPRequest a REST / Edge Functions (suficiente) | 5 — SDK oficial de Supabase JS | 4 — Unity Gaming Services, SDKs | 3 |
| 9. Costes y dependencias | 5 — MIT, sin royalties, sin cuenta | 5 — MIT | 3 — Personal gratis hasta un umbral de ingresos; Pro de pago; dependencia de las políticas de Unity (precedente del Runtime Fee) | 5 — Licencia libre |

### Inconvenientes reales de cada opción
- **Godot**: GDScript es un lenguaje nuevo para ti (aunque se parece a Python y se aprende rápido). En web: binario base de unos 25 MB sin comprimir (≈5–8 MB con Brotli) y arranque de 1–3 s, solo renderer Compatibility (WebGL2), Safari con problemas conocidos de WebGL2 y C# no disponible en web. Si queremos hilos en web, hacen falta cabeceras COOP/COEP; la exportación por defecto es de un solo hilo.
- **Phaser**: el editor que el proyecto necesita (mapas, animaciones, configuración visual de contenido) no existe gratis, así que tendríamos que construir herramientas o depender de Tiled más JSON a mano. Toda la escena isométrica (profundidad, capas, cámara) se programa a mano. Muy bueno para web, pero en móvil nativo depende de un WebView.
- **Unity**: es lo más potente, pero también lo peor para web ligera y para un flujo con agentes, que editan escenas YAML sin el editor abierto. Además añade riesgo de licencias y de dependencia comercial. Sobredimensionado para un TD 2D.
- **Defold**: excelente en tamaño y rendimiento web, pero con comunidad y herramientas 2D avanzadas más limitadas, y Lua sin ventaja frente a GDScript para ti.

---

## 3. Recomendación

### Motor principal: **Godot 4.7 con GDScript**

Motivos, por orden de los criterios:
1. **Calidad y producción**: es la única opción gratuita con editor completo para escenas isométricas, tiles, animación, partículas, shaders e interfaz. En un juego con 6 mundos, 8 héroes y jefes, el editor ahorra más tiempo que cualquier ventaja de lenguaje.
2. **Contenido como datos**: los `Resource` (`.tres`) permiten definir torres, enemigos, efectos y oleadas como archivos editables en el inspector *y* como texto que el agente puede modificar y validar.
3. **Plataformas**: web primero, con PWA opcional integrada, y después Android/iOS **nativos** (mejor rendimiento que un WebView).
4. **Agentes IA**: formatos de texto y `godot --headless` para ejecutar tests, simulaciones y exportaciones desde la línea de comandos o la CI.
5. **Coste**: MIT, sin royalties.

**Por qué GDScript y no C#**: C# no exporta a web en Godot 4, y la web es la plataforma inicial. No es una preferencia, es una restricción.

**Condición de salida**: si la PoC muestra en web un rendimiento o un tamaño inaceptables (ver §6), el plan B es **Phaser 4 + TypeScript + Tiled**, reutilizando el diseño de la simulación, que es independiente del motor.

### Tecnologías complementarias
| Necesidad | Elección | Justificación |
|---|---|---|
| Interfaz y menús | Nodos `Control` de Godot + `Theme` propio | No hace falta un framework web; el tema garantiza una estética coherente |
| Mapas y escenas | `TileMapLayer` isométrico + escenas `.tscn` por mapa | Editor integrado; las rutas y los puntos de construcción se definen como nodos marcadores |
| Pixel art | **Aseprite** (de pago, unos 20 USD, o compilación gratuita desde el código fuente) o **Pixelorama** (gratis, hecho en Godot) | Estándar para spritesheets; importación a Godot con el plugin *Aseprite Wizard* |
| Animación | `AnimatedSprite2D` / `AnimationPlayer` | Integrados |
| VFX | `GPUParticles2D` o `CPUParticles2D` + shaders | Integrados; en web conviene medir GPU frente a CPU |
| Audio | Buses de audio de Godot; SFX con jsfxr/ChipTone; música encargada o con licencia CC0/CC-BY | En web, el audio usa reproducción por *samples* (sin efectos de bus): hay que tenerlo en cuenta |
| Datos y configuración | `Resource` tipados (`TowerDef`, `EnemyDef`, `EffectDef`, `WaveDef`…) | Validación por tipos, edición en el inspector y diff legible |
| Tests | **GUT** o **gdUnit4** en headless + simulaciones deterministas sin ventana | La simulación pura se prueba sin renderizar |
| Build y CI | GitHub Actions con Godot headless (exportación web) | Reproducible |
| Despliegue web | itch.io para pruebas de jugadores + Cloudflare Pages o Netlify (cabeceras COOP/COEP si se activan los hilos) | Gratis |
| Backend (Fase 6) | **Supabase** (Auth + Postgres con RLS + Edge Functions/RPC) mediante `HTTPRequest` | Relacional encaja con progreso y desbloqueos; RLS protege por usuario; escrituras privilegiadas solo en el servidor. Alternativa evaluada: **Nakama** (servidor de juego open source con clasificaciones y lógica autoritativa), pero exige operar tu propio servidor. Revisar en la Fase 6 |
| Telemetría | Ninguna en el MVP. En la Fase 6, tabla de resultados de partida propia (oleada alcanzada, torres usadas) | Aporta datos de balance sin servicios externos |

---

## 4. Arquitectura propuesta

```
┌──────────────────────── Presentación (Nodos Godot) ────────────────────────┐
│ MapView (TileMapLayer iso)  EntityViews (pool de sprites)  VFX/Audio  HUD  │
│        ▲ lee estado (posiciones, HP) cada frame con interpolación          │
│        ▲ escucha eventos (hit, death, effect_applied, wave_started…)       │
└────────┼────────────────────────────────────────────────────────────────────┘
         │                                     │ comandos (build, upgrade,
         │                                     ▼ cast_ability, pause…)
┌────────┴──────────── Simulación (GDScript puro, RefCounted) ───────────────┐
│ SimWorld  — tick fijo (30 Hz), RNG con semilla, sin dependencias de Node   │
│  ├─ PathSystem      rutas en coordenadas lógicas (casillas, float)         │
│  ├─ WaveSystem      oleadas desde WaveDef                                  │
│  ├─ TargetingSystem consulta espacial (rejilla uniforme)                   │
│  ├─ CombatSystem    daño, tipos, resistencias                              │
│  ├─ ProjectileSystem pool, colisión lógica (no física)                     │
│  ├─ EffectSystem    estados, pilas, límites, disparadores, sinergias       │
│  ├─ HeroSystem      ataques y habilidades, recargas                        │
│  └─ EconomySystem   recursos, construcción, mejoras                        │
│ EventBus (cola de eventos por tick → la presentación los consume)          │
└──────────────────────────────▲─────────────────────────────────────────────┘
                               │ lee definiciones
┌──────────────────────────────┴──── Contenido (Resources .tres) ────────────┐
│ TowerDef · EnemyDef · HeroDef · AbilityDef · EffectDef · WaveDef · MapDef  │
└────────────────────────────────────────────────────────────────────────────┘
┌──────────── Servicios (autoloads) ────────────┐
│ SaveService (local → Supabase)  AudioService  SceneRouter  Settings        │
└───────────────────────────────────────────────┘
```

Decisiones clave:
- **Coordenadas lógicas** en casillas (x, y) cartesianas. Una sola función `Iso.to_screen()` proyecta al mundo isométrico; la simulación nunca conoce píxeles.
- **Profundidad**: Y-sort de Godot sobre la posición proyectada, con el origen de cada sprite en su «pie». Los proyectiles con arco tienen una altura `z` lógica que se suma solo en pantalla, sin cambiar su orden.
- **Tick fijo + interpolación**: la simulación avanza a 30 Hz con acumulador; la vista interpola entre estados. Pausa = no avanzar ticks. Reinicio = descartar `SimWorld` y crear uno nuevo, sin temporizadores huérfanos porque no hay `Timer` en la simulación.
- **Sin física de Godot** para el combate: distancias en una rejilla espacial. Es más barato, determinista y testeable.
- **Efectos como datos**: `EffectDef { id, duration, stacking: REFRESH|STACK|MAX, max_stacks, modifiers[], on_apply/on_threshold/on_expire triggers[], tags }`. Las sinergias son reglas (`if target has X and Y then …`) en el `EffectSystem`, con límite de profundidad de disparo y deduplicación por tick.
- **Determinismo**: misma semilla + mismos comandos = mismo resultado. Permite *replays*, tests de regresión y, en el futuro, validación de puntuaciones en servidor reejecutando la partida.
- **Añadir contenido**: un héroe, enemigo o torre nuevo se define con un `.tres` y, como mucho, un comportamiento nuevo registrado por id. Ningún sistema existente debe enumerar los tipos concretos.

---

## 5. Riesgos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Rendimiento de GDScript en web con cientos de entidades | Media | Alto | PoC de estrés; arrays empaquetados en la simulación; `MultiMeshInstance2D` o *pooling* de sprites; tick a 30 Hz; plan B en Phaser |
| Tamaño y arranque web (≈5–8 MB comprimidos + assets) | Alta | Medio | Brotli, plantilla de exportación reducida (sin 3D), pantalla de carga con estilo propio; aceptable para un juego (no para una landing page) |
| Safari/iOS con WebGL2 | Media | Medio | Exportación de un solo hilo; probar en iOS real en la PoC; app nativa iOS como alternativa |
| Ordenación isométrica de sprites grandes (jefes, torres altas) | Media | Medio | Origen en el pie, sprites altos divididos si hace falta, test visual con capturas |
| **Producción de pixel art de calidad** | **Alta** | **Alto** | Es el mayor riesgo del proyecto. Pipeline preparado para sustituir placeholders; guía de estilo temprana; plantear presupuesto o colaboración con artista; los assets temporales viven en `art/placeholder/` y fallan una comprobación de CI si se usan en una build de release |
| Complejidad de sinergias (bucles, explosión de daño) | Media | Alto | Límites por efecto, profundidad de cadena ≤ 3, dedupe por tick, tests de propiedades |
| Curva de aprendizaje de Godot/GDScript | Media | Medio | Arquitectura sencilla; el agente escribe código idiomático y documentado |
| Persistencia manipulable (cliente no confiable) | Alta | Medio (MVP) | RLS + escrituras solo por RPC/Edge Function; límites de plausibilidad; clasificaciones competitivas solo con replay validado en servidor |
| Coste de backend | Baja | Bajo | El plan gratuito de Supabase basta para pruebas; los proyectos inactivos se pausan, así que conviene un *keep-alive* o un plan Pro cuando haya jugadores |

---

## 6. Prueba de concepto (PoC)

**Objetivo**: validar los riesgos técnicos, no hacer el juego.

Alcance:
1. Proyecto Godot 4.7 con la separación **simulación pura ↔ vista**.
2. Mapa isométrico generado (rombos dibujados, sin arte) con una ruta en coordenadas lógicas.
3. Enemigos que recorren la ruta y restan vida a la base.
4. Una torre que apunta al enemigo más avanzado dentro de su alcance y dispara proyectiles que lo alcanzan, dañan y eliminan.
5. Y-sort correcto entre enemigos y torre.
6. **Modo estrés**: 500 enemigos + proyectiles; medir ms por tick de simulación y FPS.
7. Tests headless de la simulación (ruta, alcance, intervalo de ataque, daño).
8. Exportación web de un solo hilo: tamaño, tiempo de carga y FPS en Chrome y Firefox de escritorio y en Chrome Android (más iOS Safari si hay dispositivo).

**Criterios de paso (decisión go/no-go)**:
| Métrica | Umbral |
|---|---|
| Tests headless de simulación | 100 % en verde |
| Simulación, 300 enemigos + 200 proyectiles | ≤ 4 ms/tick en escritorio web |
| FPS web escritorio con 300 enemigos | ≥ 55 |
| FPS web en Android de gama media con 150 enemigos | ≥ 40 |
| Descarga inicial web (Brotli) | ≤ 12 MB |
| Arranque hasta el primer frame (escritorio, caché vacía, 50 Mbps) | ≤ 5 s |

Si falla el rendimiento: primero se optimiza (arrays empaquetados, MultiMesh). Si sigue fallando, se reevalúa con Phaser 4.

---

## 7. Plan de desarrollo

| Fase | Tareas principales | Criterios de aceptación verificables |
|---|---|---|
| **1. PoC** | Instalar Godot; estructura del proyecto; SimWorld mínimo; vista iso; torre básica; estrés; tests; exportación web | Umbrales de §6 medidos y documentados en `docs/02-resultados-poc.md` |
| **2. Mundo y rutas** | `MapDef`; mapa del Reino del Continue en TileMapLayer; marcadores de ruta y construcción leídos por la simulación; cámara (pan/zoom, táctil) | Test: un enemigo recorre la ruta en el tiempo esperado (±1 tick) y llega a la base; captura sin errores de profundidad |
| **3. Combate y economía** | Pixeladora, Grimorio, Rebote; enemigos ligero/acorazado/rápido; EconomySystem; construir/mejorar | Tests: alcance, intervalo, rebotes ≤ N, sellos 3 → inmovilización, no se puede gastar sin recursos; partida de una oleada ganable y perdible |
| **4. Héroes y efectos** | EffectSystem completo; Nexo (portal) y Kira Volt (corte cargado); sinergia *Error de sistema* | Tests de duración, pilas y límites; recargas respetadas; la sinergia usa efectos existentes (sin `if tower == "pixeladora"`) |
| **5. Misión completa** | 5 oleadas + Rey del Reinicio; balance; pausa, reinicio, victoria, derrota y resultados; feedback y SFX | Simulación headless de la partida completa con una estrategia scripted que gana, y otra que pierde; reinicio ×10 sin fugas (recuento de nodos estable) |
| **6. Persistencia** | Supabase: auth, perfil, progreso; RPC para recompensas; RLS | Tests: un usuario no puede leer ni escribir datos ajenos ni asignarse monedas; el envío duplicado de un resultado no duplica la recompensa |
| **7. Expansión** | Héroes 3–8, torres 4–6, mundos 2–6, retos diarios, clasificaciones | Cada pieza nueva = definiciones + comportamiento registrado; sin tocar sistemas no relacionados (revisión de diff) |
| **8. Pulido y publicación** | Arte final, audio, accesibilidad, móvil, optimización, despliegue | FPS objetivo en dispositivos de referencia; checklist de accesibilidad; builds web y Android |

---

## 8. Estimación orientativa

Suponiendo una persona a tiempo parcial (unas 10–15 h/semana) con asistencia de IA para el código, y **arte temporal** hasta la Fase 8:

| Fase | Duración | Depende de |
|---|---|---|
| 1. PoC | 1–2 semanas | — |
| 2. Mundo y rutas | 1–2 semanas | 1 |
| 3. Combate y economía | 2–3 semanas | 2 |
| 4. Héroes y efectos | 2–3 semanas | 3 |
| 5. Misión completa (MVP) | 2–4 semanas | 4 |
| **MVP jugable** | **≈ 2–3,5 meses** | |
| 6. Persistencia | 2–3 semanas | 5 (en paralelo con el arte) |
| 7. Expansión | Meses; en torno a 3–6 semanas por mundo | 5–6 |
| 8. Pulido | Variable; depende sobre todo del arte | Todo |

**Mayores incertidumbres**: (1) quién y cómo produce el arte final y a qué coste; (2) el rendimiento real en navegadores móviles; (3) cuánto ajuste de balance necesita la diversión (las iteraciones de diseño no se pueden estimar con precisión).

---

### Fuentes consultadas
- Godot — descargas (4.7.2 estable): https://godotengine.org/download/windows/
- Godot — Exporting for the Web (4.7): https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- Phaser 4 estable: https://phaser.io/download/stable · https://phaser.io/download/phaser4
- Unity Web en navegadores móviles: https://unity.com/en/blog/engine-platform/web-runtime-updates-enhance-browser-experience · https://docs.unity3d.com/ja/6000.0/Manual/webgl-browsercompatibility.html
- Tamaño de exportación web de Godot (mediciones de la comunidad): https://github.com/JohannesDeml/Godot-Web-LoadingTest
