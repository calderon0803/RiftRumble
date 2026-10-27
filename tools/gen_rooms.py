"""Genera src/world/rooms.gd: las salas del mundo como planos de texto.

Cada sala se describe con su origen en la cuadrícula del mundo (en casillas),
su tamaño, sus salidas (huecos en el borde) y lo que hay dentro. Así los huecos
de salas vecinas encajan por construcción; tests/world_tests.gd lo comprueba.

Uso: python tools/gen_rooms.py
Símbolos: # bloque, ^ pinchos, c rastrero, B banco, K inicio, D dash, H corazón extra,
G jefe, | puerta de la arena (abierta hasta que empieza el combate), . aire.
Reglas de diseño (para que todo sea alcanzable con el salto de Kira, ~5 casillas):
- entre plataformas, como mucho 4 casillas de subida y 2-3 de hueco;
- los fosos, como mucho 4 casillas de ancho (salvo los que piden dash: 7).
"""
from pathlib import Path


class Room:
    def __init__(self, rid, name, origin, w, h):
        self.id, self.name, self.origin, self.w, self.h = rid, name, origin, w, h
        self.g = [["." for _ in range(w)] for _ in range(h)]
        for x in range(w):
            self.g[0][x] = self.g[h - 1][x] = "#"
        for y in range(h):
            self.g[y][0] = self.g[y][w - 1] = "#"

    def exit(self, side, r0, r1):
        """Hueco en la pared izquierda/derecha entre las filas r0 y r1 (incluidas)."""
        x = 0 if side == "left" else self.w - 1
        for y in range(r0, r1 + 1):
            self.g[y][x] = "."

    def plat(self, row, c0, c1, ch="#"):
        for x in range(c0, c1 + 1):
            self.g[row][x] = ch

    def put(self, col, row, ch):
        assert self.g[row][col] == ".", (self.id, col, row, self.g[row][col])
        self.g[row][col] = ch

    def rows(self):
        return ["".join(r) for r in self.g]


rooms = []

# A — Inicio (una pantalla). Sale por la derecha; a la izquierda, un foso de
# pinchos de 7 casillas que solo se cruza con el dash lleva al Abismo.
a = Room("inicio", "Inicio", (0, 0), 40, 23)
a.exit("right", 18, 21)
a.exit("left", 18, 21)
a.plat(22, 6, 12, "^")           # 7 casillas: saltando se llega a ~6, con dash a ~9
a.plat(18, 17, 22)
a.plat(15, 26, 31)
a.put(24, 21, "K")
rooms.append(a)

# B — Pasillo (dos pantallas de ancho) con un foso de pinchos. Salidas a ambos lados.
b = Room("pasillo", "Pasillo", (40, 0), 80, 23)
b.exit("left", 18, 21)
b.exit("right", 18, 21)
b.plat(22, 30, 33, "^")          # foso de 4 casillas con pinchos en el fondo
b.plat(18, 20, 25)
b.plat(17, 44, 48)
b.plat(14, 52, 57)
b.put(15, 21, "c")
b.put(45, 21, "c")
b.put(66, 21, "c")
rooms.append(b)

# C — Pozo (dos pantallas de alto): se entra por abajo a la izquierda y se sale
# arriba a la izquierda subiendo por plataformas alternas.
c = Room("pozo", "Pozo", (120, -23), 30, 46)
c.exit("left", 41, 44)
c.exit("left", 6, 9)
c.plat(10, 1, 6)                 # repisa de la salida de arriba
left, right = (8, 15), (18, 25)
for i, row in enumerate([41, 37, 33, 29, 25, 21, 17, 13]):
    c0, c1 = right if i % 2 == 0 else left
    c.plat(row, c0, c1)
c.put(11, 28, "c")               # sobre la plataforma de la fila 29
rooms.append(c)

# D — Banco, encima del pasillo. Se entra por arriba a la derecha (desde el pozo)
# y sale abajo a la izquierda hacia el mirador.
d = Room("banco", "Banco", (90, -23), 30, 23)
d.exit("right", 6, 9)
d.exit("left", 18, 21)
d.plat(10, 22, 28)               # repisa de la entrada
d.plat(14, 12, 18)
d.plat(18, 20, 25)
d.put(8, 21, "B")
rooms.append(d)

# E — Mirador: sala sin salida con rastreros sobre plataformas.
e = Room("mirador", "Mirador", (60, -23), 30, 23)
e.exit("right", 18, 21)
e.plat(18, 6, 12)
e.plat(14, 14, 20)
e.plat(10, 4, 10)
e.put(9, 17, "c")
e.put(17, 13, "c")
e.put(20, 21, "c")
e.put(7, 9, "D")                 # el dash, en lo más alto
rooms.append(e)

# F — Abismo: al otro lado del foso del inicio (hace falta el dash). Corazón extra
# arriba y un banco antes de la guarida del jefe, a la izquierda.
f = Room("abismo", "Abismo", (-40, 0), 40, 23)
f.exit("right", 18, 21)
f.exit("left", 18, 21)
f.put(6, 21, "B")
f.plat(18, 26, 31)
f.plat(14, 18, 23)
f.plat(10, 10, 15)
f.put(20, 21, "c")
f.put(30, 21, "c")
f.put(12, 9, "H")
rooms.append(f)

# G — Guarida: arena del primer jefe. La puerta (columna 38) se cierra al entrar
# y se abre al vencerlo. El jefe mide ~2,6 casillas: pasa bajo las repisas.
g = Room("guarida", "Guarida", (-80, 0), 40, 23)
g.exit("right", 18, 21)
for row in range(18, 22):
    g.put(38, row, "|")
g.plat(18, 4, 8)
g.plat(18, 30, 34)
g.put(12, 21, "G")
rooms.append(g)

out = [
    "## Salas del mundo. GENERADO por tools/gen_rooms.py: edita el generador, no este archivo.",
    "## origin: posición de la esquina superior izquierda en casillas del mundo.",
    "## Símbolos: # bloque, ^ pinchos, c rastrero, B banco, K inicio, D dash, H corazón extra,",
    "## G jefe, | puerta de la arena, . aire.",
    "class_name Rooms",
    "extends RefCounted",
    "",
    'const START := "inicio"',
    "const DATA := {",
]
for r in rooms:
    out.append('\t"%s": {' % r.id)
    out.append('\t\t"name": "%s",' % r.name)
    out.append("\t\t\"origin\": Vector2i(%d, %d)," % r.origin)
    out.append('\t\t"layout": [')
    for row in r.rows():
        out.append('\t\t\t"%s",' % row)
    out.append("\t\t],")
    out.append("\t},")
out.append("}")
dest = Path(__file__).resolve().parent.parent / "src" / "world" / "rooms.gd"
dest.write_text("\n".join(out) + "\n", encoding="utf-8")
print("escrito", dest)
