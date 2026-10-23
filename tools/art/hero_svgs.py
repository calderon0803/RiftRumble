"""Genera las hojas de animación vectoriales (SVG) de las pruebas de estilo.

Uso: python tools/art/hero_svgs.py
Escribe art/heroes/<id>/<id>_sheet.svg y art/heroes/preview.html (vista previa
con animación, prueba de silueta y prueba del gris).

Reglas (docs/arte/01-biblia-visual.md):
- celda de 128 × 136 a 2× (se muestra a escala 0,5); pies en (64, 128): cada
  figura se dibuja en un lienzo de 96 × 120 con pies en (48, 112) y se desplaza
  (16, 16) para dejar margen a armas y efectos;
- filas: 0 reposo (4), 1 andar (6), 2 ataque (6); mira a la derecha (se refleja);
- contorno de héroe #2A1A2E de 4 px a 2×; máximo 5 colores por personaje.
"""
import math
import os

CELL_W, CELL_H = 128, 136
MARGIN = (16, 16)
FEET = (48 + MARGIN[0], 112 + MARGIN[1])
COLS = 6
ROWS = [("idle", 4), ("walk", 6), ("attack", 6)]
OUT = "#2A1A2E"
SW = 4  # grosor del contorno a 2×
SKIN = "#F6D7C3"


def rot(deg, cx, cy):
    return f'rotate({deg:.1f} {cx:.1f} {cy:.1f})'


def limb(x, y, length, width, angle, fill, stroke=OUT):
    """Extremidad: cápsula que cuelga desde (x, y) girada `angle` grados (0 = hacia abajo)."""
    return (f'<rect x="{x - width / 2:.1f}" y="{y:.1f}" width="{width}" height="{length}" rx="{width / 2:.1f}" '
            f'fill="{fill}" stroke="{stroke}" stroke-width="{SW}" transform="{rot(angle, x, y)}"/>')


def ellipse(cx, cy, rx, ry, fill, stroke=OUT, sw=SW, extra=""):
    return f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" {extra}/>'


def path(d, fill, stroke=OUT, sw=SW, extra=""):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round" {extra}/>'


def walk_angle(i, n=6, amp=26.0):
    return amp * math.sin(2 * math.pi * i / n)


# ---------------------------------------------------------------- Kira Volt
# Ruptor: triángulo hacia delante, coleta larga, espada de energía con 6 muescas.
K_PINK, K_DARK, K_YELLOW, K_CORE = "#FF6FD8", "#2C2433", "#FFE14D", "#FFF7C2"


def kira(anim, i):
    bob, lean = 0.0, 6.0
    legs = (8.0, -8.0)
    arm_back = 20.0
    sword = 130.0      # 0 = hacia arriba, sentido horario
    sway = 0.0
    trail = None
    if anim == "idle":
        bob = [0, -1, -2, -1][i]
        sway = [0, 4, 7, 4][i]
    elif anim == "walk":
        a = walk_angle(i)
        legs = (a, -a)
        arm_back = -a * 0.8
        bob = -abs(math.sin(2 * math.pi * i / 6)) * 3
        sway = 6 + a * 0.2
        lean = 10
    else:  # ataque: preparación, golpe, seguimiento, recuperación
        sword = [100, -40, -70, 60, 150, 130][i]
        lean = [6, 2, 0, 16, 14, 8][i]
        legs = [(8, -8), (4, -14), (2, -18), (24, -20), (22, -16), (12, -10)][i]
        sway = [0, -6, -8, 10, 12, 6][i]
        if i in (3, 4):
            trail = i
    hip_y = 80 + bob
    sh = (52, 54 + bob)  # hombro delantero
    g = []
    # coleta (detrás de todo)
    px, py = 38, 26 + bob
    g.append(path(f"M{px} {py} q{-22 - sway} {6} {-26 - sway * 1.4} {30} q{6 + sway * 0.5} {-6} {16 + sway * 0.3} {-10} q-2 -12 10 -20 z", K_PINK))
    # pierna trasera y brazo trasero
    g.append(limb(44, hip_y, 30, 11, legs[1] + 4, "#3E3346"))
    g.append(limb(40, 58 + bob, 22, 9, arm_back + 20, "#3E3346"))
    # torso inclinado (triángulo hacia delante)
    g.append(f'<g transform="{rot(lean, 47, hip_y)}">' +
             path(f"M36 {hip_y + 4} L60 {hip_y + 4} L62 {54 + bob} Q48 {46 + bob} 34 {56 + bob} Z", K_DARK) +
             path(f"M40 {hip_y} L58 {56 + bob}", "none", K_PINK, 4) + '</g>')
    # pierna delantera
    g.append(limb(52, hip_y, 30, 11, legs[0], K_DARK))
    # cabeza, flequillo y ojo
    hx, hy = 50 + lean * 0.4, 34 + bob
    g.append(ellipse(hx, hy, 19, 19, SKIN))
    g.append(path(f"M{hx - 20} {hy + 2} Q{hx - 18} {hy - 24} {hx + 4} {hy - 20} Q{hx + 22} {hy - 16} {hx + 19} {hy - 2} "
                  f"L{hx + 10} {hy - 8} L{hx + 6} {hy - 2} L{hx} {hy - 10} L{hx - 8} {hy + 4} Z", K_PINK))
    g.append(ellipse(hx + 9, hy + 3, 3, 4.5, OUT, OUT, 0))
    g.append(ellipse(hx + 10, hy + 1.5, 1.2, 1.2, K_YELLOW, K_YELLOW, 0))
    # brazo delantero y espada (en la mano)
    hand = (sh[0] + 10 * math.sin(math.radians(sword * 0.35 + 20)), sh[1] + 16)
    g.append(f'<line x1="{sh[0]}" y1="{sh[1]}" x2="{hand[0]:.1f}" y2="{hand[1]:.1f}" stroke="{OUT}" stroke-width="13" stroke-linecap="round"/>'
             f'<line x1="{sh[0]}" y1="{sh[1]}" x2="{hand[0]:.1f}" y2="{hand[1]:.1f}" stroke="{K_DARK}" stroke-width="6" stroke-linecap="round"/>')
    blade = (f'<g transform="translate({hand[0]:.1f} {hand[1]:.1f}) rotate({sword:.1f})">'
             f'<rect x="-3" y="-4" width="6" height="12" rx="2" fill="{K_DARK}" stroke="{OUT}" stroke-width="3"/>'
             f'<rect x="-8" y="-7" width="16" height="5" rx="2" fill="{K_PINK}" stroke="{OUT}" stroke-width="3"/>'
             f'<path d="M-5 -8 L-5 -48 L0 -56 L5 -48 L5 -8 Z" fill="{K_YELLOW}" stroke="{OUT}" stroke-width="3" stroke-linejoin="round"/>'
             f'<path d="M-1.5 -10 L-1.5 -46 L1.5 -46 L1.5 -10 Z" fill="{K_CORE}"/>'
             + "".join(f'<rect x="3" y="{-14 - k * 6}" width="2.5" height="2.5" fill="{OUT}"/>' for k in range(6)) +
             '</g>')
    g.append(blade)
    if trail is not None:
        alpha = 0.85 if trail == 3 else 0.4
        g.append(f'<path d="M58 2 Q108 8 100 84" fill="none" stroke="{K_CORE}" stroke-width="7" stroke-linecap="round" opacity="{alpha}"/>'
                 f'<path d="M58 2 Q108 8 100 84" fill="none" stroke="{K_PINK}" stroke-width="2.5" stroke-linecap="round" opacity="{alpha}"/>')
    return "".join(g)


# ---------------------------------------------------------------- Nexo
# Distorsionador: capa asimétrica en espiral, anillo-umbral que orbita a su espalda.
N_CYAN, N_INK, N_WHITE = "#6FF3FF", "#1D2B4F", "#F4F1E8"


def nexo(anim, i):
    bob, flutter, ring_phase = 0.0, 0.0, 0.0
    arm = 20.0
    orb = 0.0
    step = (0.0, 0.0)
    if anim == "idle":
        bob = [0, -1.5, -2.5, -1.5][i]
        flutter = [0, 2, 4, 2][i]
        ring_phase = i / 4
    elif anim == "walk":
        bob = -abs(math.sin(2 * math.pi * i / 6)) * 3
        flutter = 4 + 3 * math.sin(2 * math.pi * i / 6)
        ring_phase = i / 6
        s = 4 * math.sin(2 * math.pi * i / 6)
        step = (s, -s)
    else:
        arm = [20, -20, -70, -85, -60, 0][i]
        orb = [0, 4, 9, 13, 6, 0][i]
        flutter = [0, 3, 6, 8, 5, 2][i]
        ring_phase = [0, .1, .25, .4, .5, .55][i]
        bob = [0, -1, -2, -2, -1, 0][i]
    g = []
    # anillo-umbral detrás (giro simulado con la escala horizontal)
    sx = 0.35 + 0.65 * abs(math.cos(math.pi * ring_phase))
    glow = 0.9 if anim == "attack" and i in (2, 3) else 0.7
    g.append(f'<g transform="translate(44 {52 + bob}) scale({sx:.2f} 1)">'
             f'<ellipse cx="0" cy="0" rx="34" ry="34" fill="none" stroke="{OUT}" stroke-width="11"/>'
             f'<ellipse cx="0" cy="0" rx="34" ry="34" fill="none" stroke="{N_CYAN}" stroke-width="5" opacity="{glow}"/></g>')
    # botas
    g.append(ellipse(42 + step[1], 110, 7, 4, N_INK))
    g.append(ellipse(54 + step[0], 110, 7, 4, N_INK))
    # abrigo largo y esbelto
    g.append(path(f"M38 {56 + bob} L58 {56 + bob} L64 {106} Q48 {110} 32 {106} Z", N_INK))
    # capa asimétrica en espiral (cian)
    f = flutter
    g.append(path(f"M58 {56 + bob} Q{30 - f} {66 + bob} {28 - f * 1.5} {98} Q{34 - f} {106} {44} {104} "
                  f"Q{36} {88} {52} {74 + bob} Q{60} {66 + bob} {58} {56 + bob} Z", N_CYAN))
    # cabeza: pelo blanco, ojos cian
    hx, hy = 49, 36 + bob
    g.append(ellipse(hx, hy, 17, 17, SKIN))
    g.append(path(f"M{hx - 18} {hy + 6} Q{hx - 20} {hy - 22} {hx + 2} {hy - 19} Q{hx + 20} {hy - 16} {hx + 17} {hy} "
                  f"L{hx + 9} {hy - 7} L{hx + 3} {hy - 1} L{hx - 4} {hy - 9} L{hx - 10} {hy + 8} Z", N_WHITE))
    g.append(ellipse(hx + 8, hy + 2, 2.6, 4, N_CYAN, OUT, 1.5))
    # brazo delantero
    sh = (55, 60 + bob)
    hand = (sh[0] + 18 * math.sin(math.radians(90 - arm)), sh[1] + 18 * math.cos(math.radians(90 - arm)))
    g.append(f'<line x1="{sh[0]}" y1="{sh[1]}" x2="{hand[0]:.1f}" y2="{hand[1]:.1f}" stroke="{OUT}" stroke-width="12" stroke-linecap="round"/>'
             f'<line x1="{sh[0]}" y1="{sh[1]}" x2="{hand[0]:.1f}" y2="{hand[1]:.1f}" stroke="{N_INK}" stroke-width="5" stroke-linecap="round"/>')
    g.append(ellipse(hand[0], hand[1], 4.5, 4.5, SKIN, OUT, 3))
    if orb > 0:
        g.append(ellipse(hand[0] + 8, hand[1] - 4, orb, orb, N_CYAN, OUT, 3, 'opacity="0.95"'))
        g.append(ellipse(hand[0] + 8, hand[1] - 4, orb * 0.45, orb * 0.45, N_WHITE, N_WHITE, 0))
    return "".join(g)


# ---------------------------------------------------------------- Aeron
# Demoledor: trapecio invertido, espadón recto apoyado en el hombro.
A_STEEL, A_RUST, A_GOLD, A_BLADE, A_DARK = "#8E9BB0", "#9C3B2E", "#F2C14E", "#DCE2EA", "#4A4F5C"


def aeron(anim, i):
    bob = 0.0
    legs = (6.0, -6.0)
    sword = -60.0    # 0 = hacia arriba; -60 = apoyado sobre el hombro hacia atrás
    lean = 0.0
    dust = False
    if anim == "idle":
        bob = [0, -1, -1.5, -1][i]
    elif anim == "walk":
        a = walk_angle(i, amp=18)
        legs = (a, -a)
        bob = -abs(math.sin(2 * math.pi * i / 6)) * 2.5
        sword = -60 + a * 0.15
    else:
        sword = [-60, -20, 10, 120, 125, -30][i]
        lean = [0, -6, -8, 14, 14, 4][i]
        bob = [0, -2, -3, 3, 3, 0][i]
        legs = [(6, -6), (2, -10), (0, -12), (18, -14), (18, -14), (8, -8)][i]
        dust = i in (3, 4)
    hip_y = 82 + bob
    g = []
    # piernas gruesas con botas
    g.append(limb(42, hip_y, 26, 14, legs[1], A_DARK))
    g.append(limb(54, hip_y, 26, 14, legs[0], A_STEEL))
    # torso: trapecio invertido (hombros anchos) + tabardo
    t = f'<g transform="{rot(lean, 48, hip_y)}">'
    t += path(f"M26 {52 + bob} L70 {52 + bob} L62 {hip_y + 2} L36 {hip_y + 2} Z", A_STEEL)
    t += path(f"M40 {64 + bob} L58 {64 + bob} L60 {hip_y + 16} L48 {hip_y + 12} L38 {hip_y + 16} Z", A_RUST)
    t += path(f"M26 {52 + bob} L70 {52 + bob}", "none", A_GOLD, 4)
    t += ellipse(26, 54 + bob, 10, 9, A_STEEL)  # hombrera trasera
    t += '</g>'
    g.append(t)
    # casco abollado con visera
    hx, hy = 50 + lean * 0.3, 36 + bob
    g.append(path(f"M{hx - 17} {hy + 10} Q{hx - 19} {hy - 18} {hx} {hy - 19} Q{hx + 19} {hy - 18} {hx + 17} {hy + 10} Z", A_STEEL))
    g.append(path(f"M{hx - 2} {hy - 2} L{hx + 17} {hy - 2}", "none", OUT, 5))      # visera
    g.append(path(f"M{hx - 4} {hy - 19} L{hx} {hy - 26} L{hx + 4} {hy - 19}", A_GOLD, OUT, 3))  # cresta
    g.append(path(f"M{hx - 13} {hy - 10} l4 3 l-3 3", "none", A_DARK, 2))          # abolladura
    # espadón (detrás del brazo delantero) y brazo
    hand = (60 + lean * 0.4, 64 + bob)
    g.append(f'<g transform="translate({hand[0]:.1f} {hand[1]:.1f}) rotate({sword:.1f})">'
             f'<rect x="-3.5" y="-2" width="7" height="16" rx="2" fill="#6B4A32" stroke="{OUT}" stroke-width="3"/>'
             f'<rect x="-12" y="-7" width="24" height="6" rx="2" fill="{A_GOLD}" stroke="{OUT}" stroke-width="3"/>'
             f'<path d="M-7 -8 L-7 -66 L0 -76 L7 -66 L7 -8 Z" fill="{A_BLADE}" stroke="{OUT}" stroke-width="3.5" stroke-linejoin="round"/>'
             f'<path d="M0 -12 L0 -64" stroke="#AEB8C6" stroke-width="2"/>'
             f'<text x="-3" y="-30" font-size="7" font-family="monospace" fill="{A_DARK}" transform="rotate(90 0 -30)">01</text>'
             '</g>')
    sh = (64, 56 + bob)
    g.append(ellipse(sh[0], sh[1], 11, 10, A_STEEL))  # hombrera delantera
    g.append(f'<line x1="{sh[0]}" y1="{sh[1] + 4}" x2="{hand[0]:.1f}" y2="{hand[1]:.1f}" stroke="{OUT}" stroke-width="14" stroke-linecap="round"/>'
             f'<line x1="{sh[0]}" y1="{sh[1] + 4}" x2="{hand[0]:.1f}" y2="{hand[1]:.1f}" stroke="{A_STEEL}" stroke-width="7" stroke-linecap="round"/>')
    if dust:
        op = 0.8 if i == 3 else 0.35
        g.append(f'<g opacity="{op}" stroke="{A_GOLD}" stroke-width="3" stroke-linecap="round">'
                 '<line x1="82" y1="108" x2="92" y2="100"/><line x1="76" y1="112" x2="92" y2="112"/><line x1="70" y1="104" x2="78" y2="94"/></g>')
    return "".join(g)


HEROES = {
    "hero_blade": ("Kira Volt", kira),
    "hero_portal": ("Nexo", nexo),
    "hero_aeron": ("Aeron", aeron),
}


def sheet(draw):
    w, h = CELL_W * COLS, CELL_H * len(ROWS)
    cells = []
    for r, (anim, n) in enumerate(ROWS):
        for i in range(n):
            cells.append(f'<g transform="translate({i * CELL_W + MARGIN[0]} {r * CELL_H + MARGIN[1]})">{draw(anim, i)}</g>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            + "".join(cells) + "</svg>\n")


def main():
    root = os.path.join(os.path.dirname(__file__), "..", "..")
    for hid, (_, draw) in HEROES.items():
        d = os.path.join(root, "art", "heroes", hid)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, f"{hid}_sheet.svg"), "w", encoding="utf-8") as f:
            f.write(sheet(draw))
    print("ok")


if __name__ == "__main__":
    main()
