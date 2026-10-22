# H · Valores base (generado)

> **Archivo generado** por `tools/hero_sheet.gd` a partir de la [matriz de C](C-matriz-estadisticas.md). No editar a mano: cambiar C y volver a generar.
> Fórmula de prueba de G-10 (prov.). Reglas de habilidades y cifras por héroe en [H · Ficha numérica](H-ficha-numerica.md).

```bash
godot --headless --path . --script res://tools/hero_sheet.gd
```

## Nivel 1

**Vida** = 10 × S · **DPS** = 0,5 × A · **Intervalo** = 1,6 − 0,1 × Ca · **Golpe** = DPS × intervalo · **Defensa** = 4 % × D · **Velocidad** = 1,5 + 0,2 × V casillas/s · **Alcance** por banda (B §0.2) · **Índice** = √(vida efectiva × DPS), donde vida efectiva = vida / (1 − defensa); sirve para comparar, no es una estadística del juego.

| # | Héroe | Rar. | Rol (+sec.) | Vida | DPS | Interv. (s) | Golpe | Def. | Vel. | Alcance | Bloq. | Índice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Aeron | C | Demoledor | 80 | 4 | 1,3 | 5,2 | 24 % | 2,3 | 1,4 (CaC) | 2 | 20,52 |
| 2 | Zerik | C | Puntero | 50 | 2,5 | 1 | 2,5 | 16 % | 2,7 | 3,1 (Largo) | 1 | 12,2 |
| 3 | Raiko | C | Demoledor (+Distorsionador) | 60 | 3 | 1 | 3 | 20 % | 2,9 | 1,5 (Corto) | 2 | 15 |
| 4 | Voltra | C | Catalizador | 40 | 2,5 | 0,8 | 2 | 12 % | 3,3 | 2,3 (Medio) | 1 | 10,66 |
| 5 | Sylka | C | Puntero | 50 | 3 | 1 | 3 | 16 % | 3,1 | 3 (Medio) | 1 | 13,36 |
| 6 | Mistral | C | Distorsionador | 40 | 2 | 1 | 2 | 16 % | 3,1 | 2,3 (Medio) | 1 | 9,76 |
| 7 | Rokka | C | Baluarte | 90 | 3,5 | 1,2 | 4,2 | 28 % | 2,3 | 1,2 (CaC) | 3 | 20,92 |
| 8 | Kagero | C | Demoledor | 60 | 3,5 | 1 | 3,5 | 20 % | 2,9 | 1,4 (CaC) | 2 | 16,2 |
| 9 | Kairo | PC | Ruptor | 70 | 3,5 | 1,1 | 3,85 | 20 % | 2,9 | 3 (Medio) | 1 | 17,5 |
| 10 | Nimue | PC | Catalizador (+Distorsionador) | 40 | 3,5 | 1,1 | 3,85 | 16 % | 2,5 | 3,55 (Largo) | 1 | 12,91 |
| 11 | Halvard | PC | Baluarte | 100 | 2,5 | 1,3 | 3,25 | 40 % | 1,9 | 1,5 (Corto) | 3 | 20,41 |
| 12 | Vesna | PC | Ruptor | 50 | 3,5 | 0,8 | 2,8 | 20 % | 3,3 | 1,4 (CaC) | 1 | 14,79 |
| 13 | Brannoc | PC | Demoledor (+Baluarte) | 90 | 4,5 | 1,2 | 5,4 | 28 % | 2,3 | 1,4 (CaC) | 3 | 23,72 |
| 14 | Bront | PC | Baluarte (+Puntero) | 80 | 3 | 1,1 | 3,3 | 32 % | 2,5 | 3 (Medio) | 3 | 18,79 |
| 15 | Eirwen | PC | Puntero (+Distorsionador) | 50 | 3,5 | 1 | 3,5 | 16 % | 2,7 | 3,55 (Largo) | 1 | 14,43 |
| 16 | Veyra | R | Puntero | 70 | 4 | 1,1 | 4,4 | 28 % | 2,5 | 3,55 (Largo) | 1 | 19,72 |
| 17 | Valdrin | R | Ruptor | 70 | 4 | 1 | 4 | 24 % | 3,1 | 1,5 (Corto) | 1 | 19,19 |
| 18 | Kazen | R | Ruptor | 60 | 4,5 | 0,9 | 4,05 | 20 % | 3,3 | 1,5 (Corto) | 1 | 18,37 |
| 19 | Ravena | R | Catalizador (+Distorsionador) | 50 | 4 | 0,9 | 3,6 | 16 % | 3,3 | 3,1 (Largo) | 1 | 15,43 |
| 20 | Drakar | R | Demoledor (+Ruptor) | 80 | 4,5 | 1,1 | 4,95 | 28 % | 2,9 | 2,3 (Medio) | 2 | 22,36 |
| 21 | Ophidia | R | Distorsionador | 50 | 3,5 | 1,1 | 3,85 | 20 % | 2,5 | 3,1 (Largo) | 1 | 14,79 |
| 22 | Aurenn | R | Distorsionador | 60 | 4 | 1,1 | 4,4 | 24 % | 2,5 | 3,55 (Largo) | 1 | 17,77 |
| 23 | Morrak | É | Catalizador (+Distorsionador) | 80 | 4,5 | 1,1 | 4,95 | 28 % | 2,5 | 3,1 (Largo) | 1 | 22,36 |
| 24 | Nyxara | É | Ruptor (+Demoledor) | 60 | 4,5 | 0,8 | 3,6 | 20 % | 3,5 | 2,3 (Medio) | 1 | 18,37 |
| 25 | Kaelith | É | Demoledor (+Puntero) | 70 | 5 | 1,1 | 5,5 | 24 % | 2,7 | 3 (Medio) | 2 | 21,46 |
| 26 | Astraion | É | Demoledor (+Baluarte) | 80 | 4 | 0,9 | 3,6 | 28 % | 3,1 | 2,3 (Medio) | 3 | 21,08 |
| 27 | Zeraph | É | Ruptor | 70 | 4,5 | 0,8 | 3,6 | 24 % | 3,3 | 2,2 (Corto) | 1 | 20,36 |
| 28 | Chronos | L | Distorsionador | 70 | 4 | 1 | 4 | 28 % | 3,1 | 3,1 (Largo) | 1 | 19,72 |
| 29 | Solenne | L | Catalizador (+Distorsionador) | 70 | 4,5 | 1 | 4,5 | 32 % | 2,7 | 3,55 (Largo) | 1 | 21,52 |
| 30 | Varkhan | L | Demoledor | 100 | 5 | 1,1 | 5,5 | 32 % | 2,5 | 2,3 (Medio) | 2 | 27,12 |
| 31 | Eclipse | L | Distorsionador | 80 | 4 | 0,9 | 3,6 | 32 % | 3,1 | 3,55 (Largo) | 1 | 21,69 |
| 32 | Omnion | M | Catalizador (+Distorsionador) | 80 | 4,5 | 0,9 | 4,05 | 32 % | 3,1 | 3 (Medio) | 1 | 23,01 |
| 33 | Voidra | M | Catalizador (+Distorsionador) | 80 | 5 | 0,9 | 4,5 | 28 % | 3,3 | 3,55 (Largo) | 1 | 23,57 |
| 34 | Uruvan | M | Demoledor (+Baluarte) | 100 | 5 | 1 | 5 | 36 % | 2,9 | 2,3 (Medio) | 3 | 27,95 |
| 35 | Aethern | T | Catalizador | 100 | 5 | 0,8 | 4 | 40 % | 3,3 | 4 (Largo) | 1 | 28,87 |

## Índice medio por rareza (nivel 1) frente a los protagonistas

| Rareza | Héroes | Índice medio | Mín. | Máx. |
|---|---|---|---|---|
| C | 8 | 14,83 | 9,76 | 20,92 |
| PC | 7 | 17,51 | 12,91 | 23,72 |
| R | 7 | 18,23 | 14,79 | 22,36 |
| É | 5 | 20,73 | 18,37 | 22,36 |
| L | 4 | 22,51 | 19,72 | 27,12 |
| M | 3 | 24,84 | 23,01 | 27,95 |
| T | 1 | 28,87 | 28,87 | 28,87 |
| *Kira Volt (actual)* | — | 12,85 | | |
| *Nexo (actual)* | — | 7,75 | | |

## Crecimiento: vida / DPS a los niveles 10, 40 y 60

Crecimiento por rol (G-10): Baluarte +3,5 % / +2 % por nivel · Ruptor +2,5 / +3,5 · Puntero y Catalizador +2 / +3,5 · Demoledor +3 / +3 · Distorsionador +3 / +2,5. La defensa, la velocidad, el alcance y la cadencia no crecen (E §1).

| # | Héroe | Nv. 10 | Nv. 40 (fin de campaña) | Nv. 60 |
|---|---|---|---|---|
| 1 | Aeron | 102 / 5,08 | 174 / 8,68 | 222 / 11,08 |
| 2 | Zerik | 59 / 3,29 | 89 / 5,91 | 109 / 7,66 |
| 3 | Raiko | 76 / 3,81 | 130 / 6,51 | 166 / 8,31 |
| 4 | Voltra | 47 / 3,29 | 71 / 5,91 | 87 / 7,66 |
| 5 | Sylka | 59 / 3,94 | 89 / 7,1 | 109 / 9,2 |
| 6 | Mistral | 51 / 2,45 | 87 / 3,95 | 111 / 4,95 |
| 7 | Rokka | 118 / 4,13 | 213 / 6,23 | 276 / 7,63 |
| 8 | Kagero | 76 / 4,45 | 130 / 7,59 | 166 / 9,7 |
| 9 | Kairo | 86 / 4,6 | 138 / 8,28 | 173 / 10,73 |
| 10 | Nimue | 47 / 4,6 | 71 / 8,28 | 87 / 10,73 |
| 11 | Halvard | 132 / 2,95 | 237 / 4,45 | 307 / 5,45 |
| 12 | Vesna | 61 / 4,6 | 99 / 8,28 | 124 / 10,73 |
| 13 | Brannoc | 114 / 5,71 | 195 / 9,77 | 249 / 12,47 |
| 14 | Bront | 105 / 3,54 | 189 / 5,34 | 245 / 6,54 |
| 15 | Eirwen | 59 / 4,6 | 89 / 8,28 | 109 / 10,73 |
| 16 | Veyra | 83 / 5,26 | 125 / 9,46 | 153 / 12,26 |
| 17 | Valdrin | 86 / 5,26 | 138 / 9,46 | 173 / 12,26 |
| 18 | Kazen | 74 / 5,92 | 119 / 10,64 | 149 / 13,79 |
| 19 | Ravena | 59 / 5,26 | 89 / 9,46 | 109 / 12,26 |
| 20 | Drakar | 102 / 5,71 | 174 / 9,77 | 222 / 12,47 |
| 21 | Ophidia | 64 / 4,29 | 109 / 6,91 | 139 / 8,66 |
| 22 | Aurenn | 76 / 4,9 | 130 / 7,9 | 166 / 9,9 |
| 23 | Morrak | 94 / 5,92 | 142 / 10,64 | 174 / 13,79 |
| 24 | Nyxara | 74 / 5,92 | 119 / 10,64 | 149 / 13,79 |
| 25 | Kaelith | 89 / 6,35 | 152 / 10,85 | 194 / 13,85 |
| 26 | Astraion | 102 / 5,08 | 174 / 8,68 | 222 / 11,08 |
| 27 | Zeraph | 86 / 5,92 | 138 / 10,64 | 173 / 13,79 |
| 28 | Chronos | 89 / 4,9 | 152 / 7,9 | 194 / 9,9 |
| 29 | Solenne | 83 / 5,92 | 125 / 10,64 | 153 / 13,79 |
| 30 | Varkhan | 127 / 6,35 | 217 / 10,85 | 277 / 13,85 |
| 31 | Eclipse | 102 / 4,9 | 174 / 7,9 | 222 / 9,9 |
| 32 | Omnion | 94 / 5,92 | 142 / 10,64 | 174 / 13,79 |
| 33 | Voidra | 94 / 6,57 | 142 / 11,83 | 174 / 15,33 |
| 34 | Uruvan | 127 / 6,35 | 217 / 10,85 | 277 / 13,85 |
| 35 | Aethern | 118 / 6,57 | 178 / 11,83 | 218 / 15,33 |
