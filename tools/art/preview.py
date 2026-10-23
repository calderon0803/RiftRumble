"""Vista previa de las hojas SVG: hoja completa, animación a tamaño real (0,5)
y ampliada, prueba de silueta y prueba del gris, sobre el suelo del mundo 1.

Uso: python tools/art/preview.py [salida.html]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from hero_svgs import CELL_W, CELL_H, ROWS, HEROES  # noqa: E402

FPS = {"idle": 8, "walk": 12, "attack": 14}


def main():
    root = os.path.join(os.path.dirname(__file__), "..", "..")
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "art", "heroes", "preview.html")
    css, body = [], []
    for hid, (name, _) in HEROES.items():
        svg = open(os.path.join(root, "art", "heroes", hid, f"{hid}_sheet.svg"), encoding="utf-8").read()
        uri = "data:image/svg+xml;utf8," + svg.replace("#", "%23").replace("\n", "")
        rows = []
        for r, (anim, n) in enumerate(ROWS):
            cls = f"{hid}-{anim}"
            dur = n / FPS[anim]
            for scale, tag in ((0.5, "s1"), (1.0, "s2")):
                css.append(f".{cls}.{tag}{{width:{CELL_W * scale}px;height:{CELL_H * scale}px;"
                           f"background:url('{uri}') 0 {-r * CELL_H * scale}px/{CELL_W * 6 * scale}px {CELL_H * 3 * scale}px;"
                           f"animation:{cls}-{tag} {dur:.2f}s steps({n}) infinite}}"
                           f"@keyframes {cls}-{tag}{{to{{background-position-x:{-n * CELL_W * scale}px}}}}")
            rows.append(f'<div class="anim"><span>{anim}</span>'
                        f'<div class="row"><i class="{cls} s2"></i><i class="{cls} s1"></i>'
                        f'<i class="{cls} s1 sil"></i><i class="{cls} s1 gray"></i><i class="{cls} s1 flip"></i></div></div>')
        body.append(f'<section><h2>{name}</h2><div class="anims">{"".join(rows)}</div>'
                    f'<img class="sheet" src=\'{uri}\' alt="hoja de {name}"></section>')
    html = f"""<title>Pruebas de estilo</title>
<style>
body{{background:#2b3a55;color:#f4f1e8;font:14px system-ui;padding:16px}}
section{{background:#5fa35a;margin:0 0 16px;padding:12px;border-radius:6px}}
h2{{margin:0 0 8px;color:#1b2533}}
.anims{{display:flex;gap:16px;flex-wrap:wrap}}
.anim span{{display:block;color:#1b2533;font-weight:700;font-size:12px}}
.row{{display:flex;gap:10px;align-items:flex-end}}
.row i{{display:block;image-rendering:auto}}
.sil{{filter:brightness(0)}}
.gray{{filter:grayscale(1)}}
.flip{{transform:scaleX(-1)}}
.sheet{{display:block;margin-top:10px;background:#4e8a4a;max-width:100%}}
{''.join(css)}
</style>
<p>Por fila: ampliada (2×) · tamaño real · silueta · gris · reflejada</p>
{''.join(body)}"""
    with open(out, "w", encoding="utf-8") as f:
        f.write(html)
    print(out)


if __name__ == "__main__":
    main()
