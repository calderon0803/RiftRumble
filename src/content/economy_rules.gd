## Reglas de la economía (puras, sin nodos): hilos, experiencia, categorías,
## fragmentos del héroe y tiradas. Todas las cifras son de prueba (prov.); el
## diseño y su validación están en docs/10-economia.md (tools/economy.gd).
extends RefCounted

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC, TRANSCENDENT }

# --- Hilos por misión ---------------------------------------------------------------

## Multiplicador de recompensas del mundo `w` (1–6): +25 % por mundo.
static func world_mult(w: int) -> float:
	return 1.0 + 0.25 * (w - 1)

const FIRST_CLEAR := 80
const PER_STAR := 25
## Repetición: por cada estrella obtenida en la partida (3★ en el mundo 1 = 18).
const REPLAY_PER_STAR := 6
## La misión del jefe paga más la primera vez.
const BOSS_FIRST_CLEAR_MULT := 1.5
## Una sola vez, al completar el mundo 1: la primera tirada ×10 gratuita.
const FREE_PULLS_AFTER_W1 := 10


## Hilos de una victoria. `new_stars` = estrellas por encima del récord anterior.
static func mission_threads(w: int, boss: bool, first_clear: bool, stars: int, new_stars: int) -> int:
	var m := world_mult(w)
	if first_clear:
		var first := FIRST_CLEAR * (BOSS_FIRST_CLEAR_MULT if boss else 1.0)
		return roundi((first + PER_STAR * stars) * m)
	if new_stars > 0:
		return roundi(PER_STAR * new_stars * m)
	return roundi(REPLAY_PER_STAR * stars * m)

# --- Experiencia y niveles ----------------------------------------------------------

const MAX_LEVEL := 60
const LEVELS_PER_CATEGORY := 10
## Nivel esperado del equipo al EMPEZAR cada mundo (índice 1–6) y al acabar la
## campaña (índice 7). La dificultad de cada mundo se ajusta a este nivel, y los
## protagonistas (Nexo y Kira) lo reciben automáticamente («nivel de historia»).
const EXPECTED_LEVEL := [0, 1, 8, 15, 22, 29, 36, 40]


## Experiencia para pasar del nivel `level` al siguiente.
static func xp_to_next(level: int) -> int:
	return 30 + 10 * level


## Experiencia acumulada desde el nivel 1 hasta `level`.
static func xp_total(level: int) -> int:
	var total := 0
	for l in range(1, level):
		total += xp_to_next(l)
	return total


## Experiencia que gana cada héroe del equipo por partida en el mundo `w`.
static func mission_xp(w: int, victory: bool) -> int:
	var xp := 45 * w
	return xp if victory else xp / 4


## Recuperación: un héroe más de 2 niveles por debajo del nivel de historia del
## mundo (EXPECTED_LEVEL) gana ×3; así un héroe recién conseguido se pone al día.
const CATCH_UP_GAP := 2
const CATCH_UP_MULT := 3


static func level_cap(category: int) -> int:
	return category * LEVELS_PER_CATEGORY

# --- Ascenso de categoría ----------------------------------------------------------

## Coste de ascender A la categoría indicada (2–6): fragmentos del héroe + hilos.
const ASCEND_FRAGMENTS := [0, 0, 3, 6, 12, 25, 40]
const ASCEND_THREADS := [0, 0, 100, 200, 400, 800, 1500]
## Taller: comprar fragmentos de un héroe que ya se tiene.
const WORKSHOP_FRAGMENT_PRICE := 25

## Fragmentos por repetido según la rareza: aproximadamente inversos a la
## probabilidad de que salga ESE héroe, para que todos asciendan a un ritmo
## parecido (la rareza se nota en las estadísticas base y en la habilidad).
const DUPLICATE_FRAGMENTS := [5, 6, 10, 14, 22, 36, 50]

# --- Tiradas -------------------------------------------------------------------------

const PULL_COST := 100
const TEN_PULL_COST := 900
## Probabilidad base por rareza (suma 1).
const RATES := [0.40, 0.27, 0.17, 0.09, 0.045, 0.02, 0.005]
## Héroes coleccionables por rareza (biblia de personajes).
const HEROES_PER_RARITY := [8, 7, 7, 5, 4, 3, 1]
## Garantías: [rareza mínima, tiradas]. Al llegar a N tiradas sin esa rareza o
## superior, la siguiente la garantiza. Se comprueban de la más alta a la más baja.
const PITY := [[Rarity.TRANSCENDENT, 300], [Rarity.MYTHIC, 150], [Rarity.LEGENDARY, 60], [Rarity.EPIC, 10]]


static func new_pity() -> Dictionary:
	var p := {}
	for rule in PITY:
		p[rule[0]] = 0
	return p


## Rareza de una tirada; actualiza los contadores de garantía `pity`.
static func roll_rarity(rng: RandomNumberGenerator, pity: Dictionary) -> int:
	var floor_rarity := Rarity.COMMON
	for rule in PITY:
		if pity[rule[0]] + 1 >= rule[1]:
			floor_rarity = rule[0]
			break
	var rarity := _weighted(rng, floor_rarity)
	for r in pity:
		pity[r] = 0 if rarity >= r else pity[r] + 1
	return rarity


## Elige una rareza >= `min_rarity` con las probabilidades base renormalizadas.
static func _weighted(rng: RandomNumberGenerator, min_rarity: int) -> int:
	var total := 0.0
	for r in range(min_rarity, RATES.size()):
		total += RATES[r]
	var x := rng.randf() * total
	for r in range(min_rarity, RATES.size()):
		x -= RATES[r]
		if x < 0.0:
			return r
	return RATES.size() - 1
