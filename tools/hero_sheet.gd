## Genera docs/personajes/H-valores-base.md: los valores de combate de los 35
## héroes a partir de la matriz de C (única fuente de las puntuaciones 1–10),
## con la fórmula de prueba de G-10, el crecimiento por rol y el bloqueo de G-12.
## Uso: godot --headless --path . --script res://tools/hero_sheet.gd
extends SceneTree

const MATRIX := "res://docs/personajes/C-matriz-estadisticas.md"
const COMBAT := "res://docs/personajes/B-especificacion-combate.md"
const OUT := "res://docs/personajes/H-valores-base.md"

## Crecimiento por nivel (G-10): [salud, ataque] por cada nivel por encima del 1.
const GROWTH := {
	"Baluarte": [0.035, 0.020], "Ruptor": [0.025, 0.035], "Puntero": [0.020, 0.035],
	"Catalizador": [0.020, 0.035], "Demoledor": [0.030, 0.030], "Distorsionador": [0.030, 0.025],
}
## Bloqueo por rol (G-12); un secundario Baluarte suma 1.
const BLOCK := {"Baluarte": 3, "Demoledor": 2}
## Alcance en casillas por puntuación (B §0.2, lineal dentro de cada banda).
const RANGE := [0.0, 1.0, 1.2, 1.4, 1.5, 2.2, 2.3, 3.0, 3.1, 3.55, 4.0]
const BANDS := ["", "CaC", "CaC", "CaC", "Corto", "Corto", "Medio", "Medio", "Largo", "Largo", "Largo"]
## Protagonistas (valores actuales del juego) para comparar.
const PROTAGONISTS := [
	{name = "Kira Volt", hp = 55.0, dps = 1.8 / 0.6, def = 0.0},
	{name = "Nexo", hp = 45.0, dps = 1.2 / 0.9, def = 0.0},
]


func _init() -> void:
	var heroes := parse_matrix(FileAccess.get_file_as_string(MATRIX))
	var secondary := parse_secondary(FileAccess.get_file_as_string(COMBAT))
	assert(heroes.size() == 35, "la matriz debe tener 35 héroes (%d)" % heroes.size())
	var lines := PackedStringArray()
	lines.append("# H · Valores base (generado)")
	lines.append("")
	lines.append("> **Archivo generado** por `tools/hero_sheet.gd` a partir de la [matriz de C](C-matriz-estadisticas.md). No editar a mano: cambiar C y volver a generar.")
	lines.append("> Fórmula de prueba de G-10 (prov.). Reglas de habilidades y cifras por héroe en [H · Ficha numérica](H-ficha-numerica.md).")
	lines.append("")
	lines.append("```bash")
	lines.append("godot --headless --path . --script res://tools/hero_sheet.gd")
	lines.append("```")
	lines.append("")
	lines.append("## Nivel 1")
	lines.append("")
	lines.append("**Vida** = 10 × S · **DPS** = 0,5 × A · **Intervalo** = 1,6 − 0,1 × Ca · **Golpe** = DPS × intervalo · **Defensa** = 4 % × D · **Velocidad** = 1,5 + 0,2 × V casillas/s · **Alcance** por banda (B §0.2) · **Índice** = √(vida efectiva × DPS), donde vida efectiva = vida / (1 − defensa); sirve para comparar, no es una estadística del juego.")
	lines.append("")
	lines.append("| # | Héroe | Rar. | Rol (+sec.) | Vida | DPS | Interv. (s) | Golpe | Def. | Vel. | Alcance | Bloq. | Índice |")
	lines.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|")
	var by_rarity := {}
	for h in heroes:
		var sec: String = secondary.get(h.name, "")
		var v := values(h, sec, 1)
		var role: String = h.role + (" (+%s)" % sec if sec != "" else "")
		lines.append("| %d | %s | %s | %s | %d | %s | %s | %s | %d %% | %s | %s (%s) | %d | %s |" % [h.num, h.name, h.rarity, role,
			v.hp, _f(v.dps), _f(v.interval), _f(v.hit), roundi(v.def * 100), _f(v.speed), _f(v.range), BANDS[h.Al],
			v.block, _f(v.index)])
		by_rarity[h.rarity] = by_rarity.get(h.rarity, []) + [v.index]
	lines.append("")
	lines.append("## Índice medio por rareza (nivel 1) frente a los protagonistas")
	lines.append("")
	lines.append("| Rareza | Héroes | Índice medio | Mín. | Máx. |")
	lines.append("|---|---|---|---|---|")
	for r in ["C", "PC", "R", "É", "L", "M", "T"]:
		var xs: Array = by_rarity[r]
		var mean: float = xs.reduce(func(a, b): return a + b) / xs.size()
		lines.append("| %s | %d | %s | %s | %s |" % [r, xs.size(), _f(mean), _f(xs.min()), _f(xs.max())])
	for p in PROTAGONISTS:
		lines.append("| *%s (actual)* | — | %s | | |" % [p.name, _f(sqrt(p.hp / (1.0 - p.def) * p.dps))])
	lines.append("")
	lines.append("## Crecimiento: vida / DPS a los niveles 10, 40 y 60")
	lines.append("")
	lines.append("Crecimiento por rol (G-10): Baluarte +3,5 % / +2 % por nivel · Ruptor +2,5 / +3,5 · Puntero y Catalizador +2 / +3,5 · Demoledor +3 / +3 · Distorsionador +3 / +2,5. La defensa, la velocidad, el alcance y la cadencia no crecen (E §1).")
	lines.append("")
	lines.append("| # | Héroe | Nv. 10 | Nv. 40 (fin de campaña) | Nv. 60 |")
	lines.append("|---|---|---|---|---|")
	for h in heroes:
		var sec: String = secondary.get(h.name, "")
		var cells := []
		for lvl in [10, 40, 60]:
			var v := values(h, sec, lvl)
			cells.append("%d / %s" % [v.hp, _f(v.dps)])
		lines.append("| %d | %s | %s | %s | %s |" % [h.num, h.name, cells[0], cells[1], cells[2]])
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("Escrito %s (%d héroes)" % [OUT, heroes.size()])
	quit()


## Valores de combate de un héroe a un nivel.
static func values(h: Dictionary, secondary: String, level: int) -> Dictionary:
	var g: Array = GROWTH[h.role]
	var hp: float = 10.0 * h.S * (1.0 + g[0] * (level - 1))
	var dps: float = 0.5 * h.A * (1.0 + g[1] * (level - 1))
	var interval: float = 1.6 - 0.1 * h.Ca
	var def: float = minf(0.04 * h.D, 0.4)
	var block: int = BLOCK.get(h.role, 1) + (1 if secondary == "Baluarte" else 0)
	return {hp = roundi(hp), dps = dps, interval = interval, hit = dps * interval, def = def,
		speed = 1.5 + 0.2 * h.V, range = RANGE[h.Al], block = block, index = sqrt(hp / (1.0 - def) * dps)}


## Filas de la matriz: | # | Héroe | Rar. | Rol | S | A | D | V | Al | Ca | Σ | …
## Los ajustes «**7→6**» toman el valor nuevo. Comprueba la suma Σ.
static func parse_matrix(text: String) -> Array:
	var out := []
	for line in text.split("\n"):
		var cells := line.split("|")
		if cells.size() < 13 or not cells[1].strip_edges().is_valid_int():
			continue
		var h := {num = int(cells[1]), name = cells[2].strip_edges(), rarity = cells[3].strip_edges(),
			role = cells[4].strip_edges()}
		var keys := ["S", "A", "D", "V", "Al", "Ca"]
		var total := 0
		for i in keys.size():
			var v := _score(cells[5 + i])
			h[keys[i]] = v
			total += v
		assert(total == _score(cells[11]), "Σ de %s no cuadra (%d)" % [h.name, total])
		out.append(h)
	return out


static func _score(cell: String) -> int:
	var s := cell.replace("*", "").strip_edges()
	if "→" in s:
		s = s.split("→")[1]
	return int(s)


## Rol secundario de cada héroe según los encabezados y la línea «Secundario» de B.
static func parse_secondary(text: String) -> Dictionary:
	var out := {}
	var current := ""
	var header := RegEx.create_from_string("^### \\d+\\. (\\S+)")
	var sec := RegEx.create_from_string("Secundario \\[P\\]: (\\w+)")
	for line in text.split("\n"):
		var m := header.search(line)
		if m:
			current = m.get_string(1)
			continue
		var s := sec.search(line)
		if s and current != "" and line.begins_with("- **Rol:**"):
			out[current] = s.get_string(1)
	return out


static func _f(x: float) -> String:
	return ("%.2f" % x).rstrip("0").rstrip(".").replace(".", ",")
