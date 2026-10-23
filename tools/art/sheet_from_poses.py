"""Hoja de animación a partir de poses sueltas (imágenes de concepto de juego).

Recorta cada pose, quita el fondo gris liso y las sombras (el juego dibuja la
suya), la escala a la altura de la biblia visual y compone la hoja con el mismo
formato que las hojas SVG: celdas de 128 × 136 a 2×, pies en (64, 128), filas
reposo (4), andar (6) y ataque (6). Las animaciones son por poses: respiración,
rebote e inclinación sobre cada pose (biblia visual §12).

Uso: python tools/art/sheet_from_poses.py [hero_blade]
"""
import math
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
CELL_W, CELL_H = 128, 136
FEET = (64, 128)
COLS = 6
ROWS = 3
TARGET_H = 104  # alto del personaje de pie a 2× (≈ 52 px en pantalla)

# Por héroe: imagen de origen, recorte de cada pose (x0, y0, x1, y1) y alto del
# personaje de pie en la fila de esa pose (las filas de la imagen tienen escalas distintas).
HEROES = {
    "hero_blade": {
        "source": "art/concept/hero_blade/kira_juego_v1.webp",
        "poses": {
            "idle": ((150, 40, 560, 660), 610),
            "run": ((400, 700, 790, 1120), 470),
            "slash": ((820, 700, 1270, 1120), 470),
        },
    },
}


def cut_out(img):
    """Quita el fondo: gris neutro y claro conectado con los bordes (incluye sombras)."""
    img = img.convert("RGBA")
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
    # Fondo encerrado (entre brazo y cuerpo, dentro de la estela): manchas grises
    # grandes; las pequeñas (dientes, brillos) se conservan.
    seen = set()
    for y0 in range(h):
        for x0 in range(w):
            if (x0, y0) in seen or not is_bg(px[x0, y0]):
                continue
            comp, stack = [], [(x0, y0)]
            while stack:
                x, y = stack.pop()
                if (x, y) in seen or not (0 <= x < w and 0 <= y < h) or not is_bg(px[x, y]):
                    continue
                seen.add((x, y))
                comp.append((x, y))
                stack.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
            if len(comp) >= 40:
                for p in comp:
                    px[p] = (0, 0, 0, 0)
    return img


def feet_of(img):
    """Pies: fila opaca más baja y centro de los píxeles opacos no amarillos cerca del suelo."""
    w, h = img.size
    px = img.load()
    bottom = max(y for y in range(h) for x in range(0, w, 2) if px[x, y][3] > 200)
    xs = [x for y in range(bottom - 18, bottom + 1) for x in range(w)
          if px[x, y][3] > 200 and not (px[x, y][0] > 200 and px[x, y][1] > 180 and px[x, y][2] < 160)]
    return (sum(xs) / len(xs) if xs else w / 2, bottom)


def prepare(src, box, stand_h):
    img = cut_out(src.crop(box))
    s = TARGET_H / stand_h
    img = img.resize((max(1, round(img.width * s)), max(1, round(img.height * s))), Image.LANCZOS)
    return img, feet_of(img)


def place(sheet, pose, col, row, dy=0.0, sx=1.0, sy=1.0, angle=0.0, dx=0.0):
    """Pega una pose en una celda con escala desde los pies, giro y desplazamiento."""
    img, (fx, fy) = pose
    if sx != 1.0 or sy != 1.0:
        img = img.resize((max(1, round(img.width * sx)), max(1, round(img.height * sy))), Image.LANCZOS)
        fx, fy = fx * sx, fy * sy
    if angle:
        # Gira alrededor de los pies: se amplía el lienzo para no recortar.
        pad = max(img.size)
        big = Image.new("RGBA", (img.width + 2 * pad, img.height + 2 * pad))
        big.paste(img, (pad, pad))
        big = big.rotate(angle, resample=Image.BICUBIC, center=(fx + pad, fy + pad))
        img, fx, fy = big, fx + pad, fy + pad
    x = col * CELL_W + FEET[0] - fx + dx
    y = row * CELL_H + FEET[1] - fy + dy
    cell = Image.new("RGBA", sheet.size)
    cell.paste(img, (round(x), round(y)))
    # Recorta a la celda para no invadir las vecinas.
    mask = Image.new("L", sheet.size, 0)
    ImageDraw.Draw(mask).rectangle((col * CELL_W, row * CELL_H, (col + 1) * CELL_W - 1, (row + 1) * CELL_H - 1), 255)
    sheet.alpha_composite(Image.composite(cell, Image.new("RGBA", sheet.size), mask))


def build(hid):
    cfg = HEROES[hid]
    src = Image.open(os.path.join(ROOT, cfg["source"]))
    poses = {k: prepare(src, box, h) for k, (box, h) in cfg["poses"].items()}
    sheet = Image.new("RGBA", (CELL_W * COLS, CELL_H * ROWS))
    # Reposo: respiración (se encoge un poco desde los pies).
    for i, sy in enumerate([1.0, 0.985, 0.972, 0.985]):
        place(sheet, poses["idle"], i, 0, sx=1.0 + (1.0 - sy) * 0.5, sy=sy)
    # Andar: pose de carrera con rebote e inclinación.
    for i in range(6):
        t = 2 * math.pi * i / 6
        place(sheet, poses["run"], i, 1, dy=-abs(math.sin(t)) * 6, angle=-2 * math.sin(t))
    # Ataque: preparación (se echa atrás), tajo (dos fotogramas) y recuperación.
    place(sheet, poses["idle"], 0, 2, angle=4)
    place(sheet, poses["idle"], 1, 2, angle=7, dx=-2)
    place(sheet, poses["slash"], 2, 2, dx=4)
    place(sheet, poses["slash"], 3, 2, dx=6)
    place(sheet, poses["slash"], 4, 2, dx=4, angle=-2)
    place(sheet, poses["idle"], 5, 2, angle=-2)
    out = os.path.join(ROOT, "art", "heroes", hid, f"{hid}_sheet.png")
    sheet.save(out)
    print(out)


if __name__ == "__main__":
    for hid in sys.argv[1:] or HEROES:
        build(hid)
