"""Monta las animaciones de Kira a partir de las tiras del pack «Kira» de Sprite Kitchen
(spritekitchen.itch.io/kira-animated-pixel-art-swordswoman-pack). Las tiras originales no
se guardan en el repositorio (la licencia no permite redistribuirlas sueltas): se leen de
la carpeta donde se haya descomprimido el zip.

Uso: python tools/art/import_pack.py <carpeta_con_spr_kira_*.png>
Escribe art/kira/anims/<acción>/frame_N.png y art/kira/anims/anims.json.

Todos los fotogramas comparten lienzo (256×256, a 2×: el juego los dibuja a escala 0,5)
y punto de los pies, así que basta un desplazamiento para todas las acciones.
"""
import json
import os
import shutil
import sys

from PIL import Image

CELL = 256
FEET = (137, 201)  # pies en las tiras a escala 1 (todas menos «idle»)
# La tira de reposo está dibujada más grande y con los pies en otro sitio.
STRIP_FIT = {"idle": (132 / 191, (141.5, 225))}

# acción del juego: (tira, primer fotograma, último incluido, fps, bucle)
ANIMS = {
    "idle": ("idle", 0, 23, 25, True),
    "run": ("run", 0, 15, 25, True),
    "dash": ("run", 0, 15, 50, True),
    "jump": ("jump", 19, 30, 25, False),
    "fall": ("jump", 31, 54, 25, True),
    "wall_slide": ("jump", 57, 57, 1, True),
    "slash": ("hit", 3, 15, 43, False),
    "slash_up": ("hit", 16, 25, 33, False),
    "slash_down": ("hit", 35, 41, 23, False),
    "special": ("hit", 64, 77, 31, False),
    "hit": ("hurt", 3, 16, 44, False),
}
OUT = "art/kira/anims"


def strip_path(src, name):
    for f in os.listdir(src):
        if f.startswith("spr_kira_%s_strip" % name):
            return os.path.join(src, f)
    raise SystemExit("falta la tira " + name)


def fit(frame, strip):
    scale, feet = STRIP_FIT.get(strip, (1.0, FEET))
    if scale == 1.0 and feet == FEET:
        return frame
    w = round(CELL * scale)
    small = frame.resize((w, w), Image.LANCZOS)
    canvas = Image.new("RGBA", (CELL, CELL))
    canvas.alpha_composite(small, (round(FEET[0] - feet[0] * scale), round(FEET[1] - feet[1] * scale)))
    return canvas


def main():
    src = sys.argv[1]
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    meta = {"feet": list(FEET), "size": [CELL, CELL], "anims": {}}
    strips = {}
    for anim, (strip, first, last, fps, loop) in ANIMS.items():
        if strip not in strips:
            strips[strip] = Image.open(strip_path(src, strip)).convert("RGBA")
        sheet = strips[strip]
        d = os.path.join(OUT, anim)
        os.makedirs(d)
        for k, i in enumerate(range(first, last + 1)):
            frame = sheet.crop((i * CELL, 0, (i + 1) * CELL, CELL))
            fit(frame, strip).save(os.path.join(d, "frame_%d.png" % k))
        meta["anims"][anim] = {"count": last - first + 1, "fps": fps, "loop": loop}
    with open(os.path.join(OUT, "anims.json"), "w") as f:
        json.dump(meta, f, indent=1)
    print(len(ANIMS), "acciones en", OUT)


if __name__ == "__main__":
    main()
