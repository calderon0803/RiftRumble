"""Junta varias imagenes en una hoja (rejilla) para compararlas.

blender -b --factory-startup -P hoja_contactos.py -- <salida.png> <columnas> <ancho celda> <img1> <img2> ...
"""
import sys

import bpy
import numpy as np

args = sys.argv[sys.argv.index("--") + 1:]
out, cols, cw = args[0], int(args[1]), int(args[2])
files = args[3:]
cells = []
for f in files:
    im = bpy.data.images.load(f)
    w, h = im.size
    ch = int(cw * h / w)
    im.scale(cw, ch)
    cells.append(np.array(im.pixels[:], dtype=np.float32).reshape(ch, cw, 4))
ch = cells[0].shape[0]
rows = (len(cells) + cols - 1) // cols
gap = 6
W, H = cols * cw + (cols + 1) * gap, rows * ch + (rows + 1) * gap
sheet = np.ones((H, W, 4), dtype=np.float32)
sheet[:, :, :3] = 0.15
for i, c in enumerate(cells):
    r, k = divmod(i, cols)
    y0 = H - (r + 1) * (ch + gap)  # las filas de pixeles de Blender van de abajo arriba
    x0 = gap + k * (cw + gap)
    sheet[y0:y0 + ch, x0:x0 + cw] = c
img = bpy.data.images.new("hoja", W, H, alpha=True)
img.pixels.foreach_set(sheet.ravel())
img.filepath_raw = out
img.file_format = "PNG"
img.save()
print("RESULT hoja", out, W, H)
