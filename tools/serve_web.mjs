// Servidor estático mínimo para probar la exportación web en local.
// Uso: node tools/serve_web.mjs [carpeta=build/web] [puerto=8060] [--https]
//
// Godot 4 exige un contexto seguro: `http://localhost` vale en este PC, pero
// para abrirlo desde otro dispositivo (móvil en la misma red) hace falta HTTPS.
// Con --https usa .tools/dev-cert.pem y .tools/dev-key.pem (autofirmados; el
// navegador mostrará un aviso que hay que aceptar una vez).
// Envía el MIME correcto para .wasm y las cabeceras COOP/COEP (necesarias solo
// si algún día se activa la exportación con hilos; no estorban sin ellos).
import { createServer as createHttp } from "node:http";
import { createServer as createHttps } from "node:https";
import { readFile } from "node:fs/promises";
import { readFileSync } from "node:fs";
import { extname, join, normalize, resolve } from "node:path";

const args = process.argv.slice(2);
const https = args.includes("--https");
const [dir = "build/web", portArg] = args.filter((a) => !a.startsWith("--"));
const root = resolve(dir);
const port = Number(portArg ?? (https ? 8443 : 8060));
const types = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript", ".wasm": "application/wasm",
  ".pck": "application/octet-stream", ".png": "image/png", ".svg": "image/svg+xml",
  ".json": "application/json", ".ico": "image/x-icon",
};

async function handler(req, res) {
  const urlPath = decodeURIComponent(new URL(req.url, "http://x").pathname);
  const file = normalize(join(root, urlPath === "/" ? "index.html" : urlPath));
  console.log(`${new Date().toISOString()} ${req.socket.remoteAddress} ${req.method} ${urlPath}`);
  if (!file.startsWith(root)) { res.writeHead(403).end(); return; }
  try {
    const body = await readFile(file);
    res.writeHead(200, {
      "Content-Type": types[extname(file)] ?? "application/octet-stream",
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
      "Cache-Control": "no-store",
    });
    res.end(body);
  } catch {
    res.writeHead(404).end("No encontrado");
  }
}

const server = https
  ? createHttps({ cert: readFileSync(".tools/dev-cert.pem"), key: readFileSync(".tools/dev-key.pem") }, handler)
  : createHttp(handler);
server.listen(port, () =>
  console.log(`Sirviendo ${root} en ${https ? "https" : "http"}://localhost:${port}`));
