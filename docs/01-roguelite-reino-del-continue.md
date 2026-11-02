# Roguelite en el Reino del Continue

> **Actualizado con el argumento de [02-argumento.md](02-argumento.md):** el personaje jugable es **Ãlex** (avatar de
> pruebas con el cursor como arma) y el recurso de combate es la **depuraciÃ³n** (Parche y ExcepciÃ³n). Kira Volt aparece
> en la Pantalla de Inicio como personaje, con las 6 muescas de su espada apagadas. Donde abajo dice Â«KiraÂ», Â«tajoÂ»,
> Â«filoÂ» o Â«muescasÂ» como jugador, lÃ©ase Ãlex, clic y depuraciÃ³n.

Se rehace RIFT RUMBLE a partir de un prototipo web (metroidvania con dones al estilo roguelite) y se
le pone la historia y el mundo que ya tenÃ­a el proyecto: la Gran Interferencia, Nexo, el Editor, Kira Volt
y el Reino del Continue. Todos los nombres siguen siendo provisionales y viven solo en `src/game/data.gd`.

## El bucle
- La regla del Reino es **continuar**: al caer, Kira vuelve al **Umbral de Nexo**.
- **Se conserva**: los fragmentos, lo comprado en el anillo, el orbe de salto doble y haber vencido al Rey.
- **Se pierde**: los poderes de las grietas y los corazones extra de *Sin Principio*.
- Nexo tiene una conversaciÃ³n nueva tras cada Continue (y otras al conseguir el orbe y al ganar).

## El mundo (6 salas)
| Sala | QuÃ© tiene |
|---|---|
| Umbral de Nexo | Nexo, el anillo (mejoras), el marcador del CONTINUE y un registro de Zerik |
| Pantalla de Inicio | pinchos, rastreros, escupidor y la primera grieta |
| Monedas Sueltas | sala alta con revoloteadores, grieta y el **orbe de salto doble** arriba del todo |
| Bloque Sorpresa | escupidores en alto, foso de pinchos y grieta |
| Doble Pantalla | subida vertical: las plataformas estÃ¡n a 5 casillas y **solo se sube con salto doble** |
| Trono del Reinicio | arena del **Rey del Reinicio**; la puerta se cierra hasta vencerle |

## Combate
- **Tajo** en tres direcciones; el tercero seguido hace Ã—1,5. El tajo hacia abajo rebota en enemigos y pinchos.
- **Filo** (6 muescas, la espada de Kira): cada tajo que acierta llena una. Con 2 se puede lanzar una
  **descarga** o **concentrarse** para recuperar un corazÃ³n.
- **Dash** con invulnerabilidad mientras dura (como en los roguelites de acciÃ³n).
- **Regla del Reino (Â«ContinÃºaÂ»)**: el rastrero deja un **nÃºcleo** al caer. Si no se rompe en 4 s,
  vuelve (una sola vez, marcado Â«2UPÂ»).
- Enemigos: rastrero, revoloteador y escupidor; los tajos cortan sus proyectiles.

## Las grietas
En cada intento, cada una de las 4 grietas trae a un hÃ©roe distinto (orden al azar), que ofrece 3 poderes:
| HÃ©roe | Poderes |
|---|---|
| Aeron (Reino del Continue) | EspadÃ³n Â· Golpe de Reinicio Â· Sin Principio |
| Zerik (Reino del Continue) | DiagnÃ³stico Â· MÃ¡s Datos Â· Disparo Reforzado |
| Voltra (NeÃ³n de Medianoche) | Sobrecarga Â· De Farola en Farola Â· Carrera |
| Raiko (Academia del Ãšltimo Hechizo) | Apartar Â· Disciplina Â· Combate Justo |

## El anillo de Nexo (mejoras permanentes)
CorazÃ³n de Reserva (+1 corazÃ³n, 3 niveles), Filo Templado (+4 de daÃ±o, 3 niveles), Filo Cargado
(empezar con el filo lleno) y Continue Extra (una vez por intento, volver con media vida).

## El Rey del Reinicio
Embestida con el cetro, salto aplastante con dos ondas por el suelo y, a media vida (Â«Â¡Continue!Â»),
lluvia de proyectiles con aviso en el suelo y revoloteadores de refuerzo. Vencerle da 60 fragmentos,
abre la puerta y cambia el marcador del Umbral a GAME CLEAR.

## Pendiente
- Sonido.
- Arte final: todo se dibuja por cÃ³digo; el arte de Kira de `art/` no estÃ¡ conectado todavÃ­a.
- MÃ¡s mundos de la Trama (Academia, Ãšltima SesiÃ³n, NeÃ³n, Vertedero, Frontera).

Tests: `game_tests.gd` 34/34.
