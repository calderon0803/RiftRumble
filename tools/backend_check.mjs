// Comprobaciones de seguridad y persistencia contra el proyecto de Supabase real.
// Uso: node tools/backend_check.mjs            (lee config/backend.json)
//
// Crea dos usuarios invitados de prueba y verifica que:
//   - los resultados válidos dan progreso y recompensa, y son idempotentes;
//   - el servidor recalcula las estrellas y rechaza resultados inverosímiles;
//   - un usuario no puede escribir directamente sus monedas o progreso;
//   - un usuario no puede leer los datos de otro;
//   - sin sesión no se puede enviar nada.
// Solo usa la clave PÚBLICA: exactamente lo que tiene cualquier jugador.
import { readFileSync } from "node:fs";
import { randomUUID } from "node:crypto";

const cfg = JSON.parse(readFileSync(new URL("../config/backend.json", import.meta.url), "utf8"));
const base = cfg.url.replace(/\/$/, "");
const key = cfg.publishable_key;

let failures = 0;
let checks = 0;
function check(cond, msg) {
  checks++;
  console.log(`${cond ? "  ✓" : "  ✗"} ${msg}`);
  if (!cond) failures++;
}

async function call(method, path, body, token) {
  const res = await fetch(base + path, {
    method,
    headers: {
      apikey: key,
      Authorization: `Bearer ${token ?? key}`,
      "Content-Type": "application/json",
      Prefer: "return=representation",
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let data = null;
  try { data = text ? JSON.parse(text) : null; } catch { data = text; }
  return { status: res.status, ok: res.ok, data };
}

async function guest() {
  const r = await call("POST", "/auth/v1/signup", { data: {} });
  if (!r.ok) throw new Error(`No se pudo crear un invitado (${r.status}): ${JSON.stringify(r.data)}.
¿Están activadas las «Anonymous Sign-Ins» en Authentication → Sign In / Providers?`);
  return { token: r.data.access_token, id: r.data.user.id };
}

const submit = (u, p) => call("POST", "/rest/v1/rpc/submit_match_result", {
  p_mission_id: "w1_m5", p_client_nonce: randomUUID(), p_outcome: "victory",
  p_base_hp: 20, p_waves_reached: 5, p_duration_secs: 240, p_stats: {}, ...p,
}, u?.token);

console.log(`Proyecto: ${base}\n`);
const a = await guest();
const b = await guest();
check(a.id !== b.id, "se crean dos invitados distintos");

console.log("\nResultados y recompensas");
const prof = await call("GET", `/rest/v1/profiles?select=display_name`, undefined, a.token);
check(prof.ok && prof.data.length === 1, `perfil creado automáticamente (${prof.data?.[0]?.display_name})`);
const nonce = randomUUID();
const r1 = await submit(a, { p_client_nonce: nonce, p_base_hp: 19 });
check(r1.ok && r1.data.stars === 3 && r1.data.first_clear === true, "victoria válida: 3★ y primera victoria");
check(r1.ok && r1.data.reward === 50 + 3 * 20, `recompensa de primera victoria (${r1.data?.reward})`);
const r2 = await submit(a, { p_client_nonce: nonce, p_base_hp: 19 });
check(r2.ok && r2.data.duplicate === true && r2.data.shards === r1.data.shards,
  "reenviar el mismo resultado no duplica la recompensa");
const r3 = await submit(a, { p_base_hp: 3 });
check(r3.ok && r3.data.stars === 1 && r3.data.reward === 5, "estrellas recalculadas por el servidor (1★) y recompensa de repetición");
const prog = await call("GET", "/rest/v1/campaign_progress?select=*", undefined, a.token);
check(prog.ok && prog.data[0]?.best_stars === 3 && prog.data[0]?.victories === 2, "el progreso guarda la mejor marca");

console.log("\nResultados inverosímiles");
check((await submit(a, { p_duration_secs: 20 })).status === 400, "victoria demasiado rápida: rechazada");
check((await submit(a, { p_base_hp: 99 })).status === 400, "vida de base imposible: rechazada");
check((await submit(a, { p_waves_reached: 2 })).status === 400, "victoria sin completar las oleadas: rechazada");
check((await submit(a, { p_mission_id: "no_existe" })).status === 400, "misión desconocida: rechazada");
check((await submit(a, { p_outcome: "defeat", p_base_hp: 10 })).status === 400, "derrota con vida en la base: rechazada");

console.log("\nEscrituras directas (deben fallar)");
const before = (await call("GET", "/rest/v1/wallets?select=shards", undefined, a.token)).data[0].shards;
const w1 = await call("PATCH", `/rest/v1/wallets?user_id=eq.${a.id}`, { shards: 999999 }, a.token);
const w2 = await call("POST", "/rest/v1/wallets", { user_id: a.id, shards: 999999 }, a.token);
const w3 = await call("POST", "/rest/v1/campaign_progress", { user_id: a.id, mission_id: "w1_m5", best_stars: 3 }, a.token);
const w4 = await call("POST", "/rest/v1/match_results", { user_id: a.id, mission_id: "w1_m5",
  client_nonce: randomUUID(), outcome: "victory", stars: 3, base_hp: 20, waves_reached: 5, duration_secs: 999, reward: 9999 }, a.token);
const after = (await call("GET", "/rest/v1/wallets?select=shards", undefined, a.token)).data[0].shards;
check(!w1.ok || (Array.isArray(w1.data) && w1.data.length === 0), `no se pueden modificar las monedas (HTTP ${w1.status})`);
check(!w2.ok && !w3.ok && !w4.ok, `no se pueden insertar monedas, progreso ni resultados (HTTP ${w2.status}/${w3.status}/${w4.status})`);
check(after === before, `las monedas no han cambiado (${before} → ${after})`);

console.log("\nAislamiento entre usuarios");
const spy1 = await call("GET", `/rest/v1/campaign_progress?user_id=eq.${a.id}`, undefined, b.token);
const spy2 = await call("GET", `/rest/v1/wallets?user_id=eq.${a.id}`, undefined, b.token);
const spy3 = await call("GET", `/rest/v1/match_results?user_id=eq.${a.id}`, undefined, b.token);
check(spy1.ok && spy1.data.length === 0 && spy2.data.length === 0 && spy3.data.length === 0,
  "un usuario no puede leer el progreso, monedas ni resultados de otro");
const nameB = await call("POST", "/rest/v1/rpc/set_display_name", { p_name: "Probador B" }, b.token);
const profA = await call("GET", "/rest/v1/profiles?select=display_name", undefined, a.token);
check(nameB.ok && profA.data[0].display_name !== "Probador B", "cambiar el nombre propio no afecta a otros");

console.log("\nSin sesión");
const anonSubmit = await submit(null, {});
check(!anonSubmit.ok, `sin sesión no se pueden enviar resultados (HTTP ${anonSubmit.status})`);
const anonRead = await call("GET", "/rest/v1/wallets?select=*");
check(!anonRead.ok || anonRead.data.length === 0, "sin sesión no se leen monedas");

console.log(`\n${checks} comprobaciones, ${failures} fallos`);
console.log("Nota: se han creado 2 usuarios invitados de prueba; puedes borrarlos en Authentication → Users.");
process.exit(failures > 0 ? 1 : 0);
