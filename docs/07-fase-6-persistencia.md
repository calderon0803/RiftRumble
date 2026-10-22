# RIFT RUMBLE — Fase 6: persistencia

Fecha: 2026-10-21 · Estado: **modo local activo; nube diseñada y preparada, sin activar** (decisión del proyecto: «por ahora en local»).

## Arquitectura

```
Partida (SimWorld) ──fin──▶ main._match_summary() ──▶ SaveService.submit_result()
                                                        │
                        sin config/backend.json ────────┼──▶ MODO LOCAL: recompensas calculadas
                                                        │    en el dispositivo (user://)
                        con config/backend.json ────────┴──▶ MODO NUBE: cola local + RPC
                                                             submit_match_result (Supabase)
```

| Pieza | Archivo | Responsabilidad |
|---|---|---|
| Servicio de guardado | `src/services/save_service.gd` | Progreso, fragmentos, sesión de invitado, cola y reintentos |
| Cliente HTTP | `src/services/supabase_client.gd` | Auth anónima, renovación de sesión y RPC; solo clave **pública** |
| Esquema del servidor | `supabase/migrations/20261021000001_init.sql` | Tablas, RLS, funciones validadas |
| Recompensas | `MissionDef` (`first_clear_reward`, `per_star_reward`, `replay_reward`) y tabla `missions` | Mismas reglas en local y en servidor |

### Qué se guarda
Por misión: mejores estrellas, mejor tiempo, victorias e intentos. Por jugador: **hilos** (antes «fragmentos»; clave `threads`, con migración desde `shards`), la moneda para desbloqueos futuros.

Recompensas:
- **Primera victoria:** 50 + 20 por estrella.
- **Mejorar el récord:** 20 por cada estrella nueva.
- **Repetir una victoria:** 5.
- **Derrota:** 0.

### Modo local (activo)
- Archivos en `user://` (IndexedDB en la web; no persiste en navegación privada).
- **Limitación conocida:** un archivo local puede editarse. **No protege datos frente a manipulación.** Es aceptable mientras no haya clasificaciones ni compras.

### Modo nube (preparado, sin activar)
Seguridad del esquema:
- **Sin escrituras directas:** no hay políticas INSERT/UPDATE/DELETE y se revocan los privilegios a `anon` y `authenticated`.
- **Lectura solo de lo propio** (RLS con `auth.uid()`).
- `submit_match_result` (SECURITY DEFINER, `search_path` vacío):
  - Valida la verosimilitud: misión existente, vida y oleadas en rango, duración mínima de victoria, coherencia entre victoria y derrota.
  - **Recalcula las estrellas** e ignora las del cliente.
  - Calcula la recompensa.
  - Es **idempotente** por `(user_id, client_nonce)`.
  - Limita los envíos a 60 por hora.
- Usuarios **anónimos** (invitados) con perfil y monedero creados por un trigger; se podrán vincular a un correo u OAuth más adelante.
- En el cliente: cola persistente, reintento con el **mismo nonce**, renovación del token caducado y descarte de resultados rechazados (sin bucles).

**Límite asumido:** la partida se simula en el cliente; el servidor valida verosimilitud, no autenticidad. Para clasificaciones competitivas, la simulación determinista permitirá **revalidar la partida en el servidor** con su semilla y sus comandos.

### Activar la nube (cuando se decida)
1. Crear el proyecto de Supabase y activar *Anonymous Sign-Ins*.
2. Ejecutar la migración en el SQL Editor.
3. Crear `config/backend.json` (ver `config/backend.example.json`) con la URL y la clave **publishable**. Nunca la *secret* ni la *service_role*.
4. Ejecutar `node tools/backend_check.mjs`: verifica idempotencia, estrellas recalculadas, rechazos, escrituras directas bloqueadas, aislamiento entre usuarios y acceso sin sesión.

## Criterios de aceptación

| Criterio | Verificación | Estado |
|---|---|---|
| El progreso se conserva correctamente | `tests/service_tests.gd` (reabrir el juego conserva fragmentos, estrellas, victorias, intentos y mejor tiempo) + prueba en el iPhone y el PC recargando | ✅ |
| Recompensas correctas, sin duplicados | Tests: reglas locales (70/40/5/0); en modo nube, el mismo nonce no duplica | ✅ |
| Funciona sin conexión | Tests: cola persistente entre sesiones, reintento, renovación de token, rechazos sin bloquear | ✅ |
| Un usuario no puede modificar datos protegidos | Diseñado en el esquema y con un script de verificación listo; **pendiente de ejecutar contra un proyecto real**. En modo local no es posible garantizarlo | ⏳ |

Tests: 172 (simulación) + 18 (servicio) + 5 (escena) comprobaciones, 0 fallos.

## Pendiente
- Activar y verificar la nube (`tools/backend_check.mjs`).
- Vincular cuentas (correo o Google) para no perder el progreso de invitado al cambiar de dispositivo.
- Usar los fragmentos: desbloqueos de héroes y mejoras (Fase 7).
