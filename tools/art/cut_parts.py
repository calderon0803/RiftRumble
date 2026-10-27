"""Convierte una hoja de piezas generada (fondo gris liso) en un esqueleto para Godot.

Pasos:
  1. python tools/art/cut_parts.py <id> detectar
     Quita el fondo, detecta las piezas sueltas y guarda una imagen numerada
     (art/<id>/piezas_detectadas.png) para identificarlas.
  2. Se escribe art/<id>/rig.json: qué pieza detectada es cada hueso,
     con su pivote, dónde se engancha en el padre, giro de reposo y orden.
  3. python tools/art/cut_parts.py <id> montar
     Escala las piezas, compone el atlas (art/<id>/<id>_parts.png) y escribe
     art/<id>/<id>_rig.tres.

rig.json:
  {
    "source": "art/concept/hero_blade/kira_piezas_v1.webp",
    "scale": 0.25,               # escala de la imagen generada al tamaño de trabajo (2×)
    "style": "melee",
    "parts": {
      "hips": {"piece": 3, "pivot": [x, y], "parent": "", "at": [0, -50], "rest": 0, "z": 5},
      ...
    }
  }
Los píxeles de "pivot" y "at" están en la imagen original recortada (se escalan solos);
"at" de la raíz es respecto a los pies, ya en tamaño de trabajo. "size" (opcional,
1 por defecto) agranda o encoge una pieza: así unas piezas de proporciones normales
dan un personaje cabezón (biblia visual §6).
"""
import json
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
MIN_AREA = 150  # componentes más pequeños se descartan (motas)


def cut_out(img):
    """Quita el fondo: gris neutro y claro conectado con los bordes (incluye sombras)."""
    img = img.convert("RGBA")
    original = img.copy()
    w, h = img.size
    px = img.load()

    def is_bg(c):
        r, g, b, a = c
        return a > 0 and max(r, g, b) - min(r, g, b) < 16 and (r + g + b) / 3 > 120

    stack = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    seen = set()
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        if not is_bg(px[x, y]):
            continue
        px[x, y] = (0, 0, 0, 0)
        stack.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    # Fondo encerrado (entre brazo y cuerpo, dentro de la estela): manchas grandes
    # del MISMO gris que el fondo; el blanco de los ojos o los dientes se conserva.
    bg = original.getpixel((0, 0))

    def is_enclosed_bg(c):
        return c[3] > 0 and all(abs(c[k] - bg[k]) <= 12 for k in range(3))

    seen = set()
    for y0 in range(h):
        for x0 in range(w):
            if (x0, y0) in seen or not is_enclosed_bg(px[x0, y0]):
                continue
            comp, stack = [], [(x0, y0)]
            while stack:
                x, y = stack.pop()
                if (x, y) in seen or not (0 <= x < w and 0 <= y < h) or not is_enclosed_bg(px[x, y]):
                    continue
                seen.add((x, y))
                comp.append((x, y))
                stack.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
            if len(comp) >= 40:
                for p in comp:
                    px[p] = (0, 0, 0, 0)
    return img


def pieces(img):
    """Componentes opacos conectados (8 vecinos), ordenados de arriba abajo y de izquierda a derecha."""
    w, h = img.size
    a = img.split()[3].load()
    seen = bytearray(w * h)
    found = []
    for y0 in range(h):
        for x0 in range(w):
            if seen[y0 * w + x0] or a[x0, y0] < 40:
                continue
            stack, xs, ys, n = [(x0, y0)], [], [], 0
            seen[y0 * w + x0] = 1
            while stack:
                x, y = stack.pop()
                xs.append(x)
                ys.append(y)
                n += 1
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and a[nx, ny] >= 40:
                            seen[ny * w + nx] = 1
                            stack.append((nx, ny))
            if n >= MIN_AREA:
                found.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1))
    found.sort(key=lambda b: (b[1] // 80, b[0]))
    return found


def detect(hid, cfg):
    src = cut_out(Image.open(os.path.join(ROOT, cfg["source"])))
    found = pieces(src)
    view = Image.new("RGBA", src.size, (95, 163, 90, 255))
    view.alpha_composite(src)
    d = ImageDraw.Draw(view)
    for i, b in enumerate(found):
        d.rectangle(b, outline=(255, 0, 0, 255), width=2)
        d.text((b[0] + 3, b[1] + 3), str(i), fill=(255, 255, 0, 255))
    out = os.path.join(ROOT, "art", hid, "piezas_detectadas.png")
    view.save(out)
    for i, b in enumerate(found):
        print(i, b)
    print(out)


def build(hid, cfg):
    src = cut_out(Image.open(os.path.join(ROOT, cfg["source"])))
    found = pieces(src)
    s = cfg["scale"]
    pad = 4
    crops = {}
    for name, p in cfg["parts"].items():
        b = found[p["piece"]]
        c = src.crop(b)
        ps = s * p.get("size", 1.0)
        crops[name] = (c.resize((max(1, round(c.width * ps)), max(1, round(c.height * ps))), Image.LANCZOS), b)
    w = sum(c.width + 2 * pad for c, _ in crops.values())
    h = max(c.height for c, _ in crops.values()) + 2 * pad
    atlas = Image.new("RGBA", (w, h))
    x = 0
    entries = []
    for name, (c, b) in crops.items():
        p = cfg["parts"][name]
        atlas.paste(c, (x + pad, pad))
        ps = s * p.get("size", 1.0)
        pivot = ((p["pivot"][0] - b[0]) * ps, (p["pivot"][1] - b[1]) * ps)
        parent = p.get("parent", "")
        if parent:
            pp = cfg["parts"][parent]
            pb = found[pp["piece"]]
            qs = s * pp.get("size", 1.0)
            at = ((p["at"][0] - pb[0]) * qs, (p["at"][1] - pb[1]) * qs)
        else:
            at = tuple(p["at"])
        entries.append(
            f'{{"name": &"{name}", "region": Rect2({x + pad}, {pad}, {c.width}, {c.height}), '
            f'"pivot": Vector2({pivot[0]:.1f}, {pivot[1]:.1f}), "parent": &"{parent}", '
            f'"at": Vector2({at[0]:.1f}, {at[1]:.1f}), "rest": {float(p.get("rest", 0))}, "z": {p.get("z", 0)}}}')
        x += c.width + 2 * pad
    d = os.path.join(ROOT, "art", hid)
    atlas.save(os.path.join(d, f"{hid}_parts.png"))
    tres = ('[gd_resource type="Resource" script_class="RigDef" load_steps=3 format=3]\n\n'
            '[ext_resource type="Script" path="res://src/player/rig/rig_def.gd" id="1_rig"]\n'
            f'[ext_resource type="Texture2D" path="res://art/{hid}/{hid}_parts.png" id="2_tex"]\n\n'
            '[resource]\nscript = ExtResource("1_rig")\ntexture = ExtResource("2_tex")\n'
            'parts = Array[Dictionary]([' + ", ".join(entries) + f'])\nstyle = &"{cfg.get("style", "melee")}"\n')
    with open(os.path.join(d, f"{hid}_rig.tres"), "w", encoding="utf-8") as f:
        f.write(tres)
    print(os.path.join(d, f"{hid}_rig.tres"))


def main():
    hid, step = sys.argv[1], sys.argv[2]
    with open(os.path.join(ROOT, "art", hid, "rig.json"), encoding="utf-8") as f:
        cfg = json.load(f)
    {"detectar": detect, "montar": build}[step](hid, cfg)


if __name__ == "__main__":
    main()
