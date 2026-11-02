# Roguelite en el Reino del Continue

> **Actualizado con el argumento de [02-argumento.md](02-argumento.md):** el personaje jugable es **ÃƒÂlex** (avatar de
> pruebas con el cursor como arma) y el recurso de combate es la **depuraciÃƒÂ³n** (Parche y ExcepciÃƒÂ³n). Kira Volt aparece
> en la Pantalla de Inicio como personaje, con las 6 muescas de su espada apagadas. Donde abajo dice Ã‚Â«KiraÃ‚Â», Ã‚Â«tajoÃ‚Â»,
> Ã‚Â«filoÃ‚Â» o Ã‚Â«muescasÃ‚Â» como jugador, lÃƒÂ©ase ÃƒÂlex, clic y depuraciÃƒÂ³n.

Se rehace RIFT RUMBLE a partir de un prototipo web (metroidvania con dones al estilo roguelite) y se
le pone la historia y el mundo que ya tenÃƒÂ­a el proyecto: la Gran Interferencia, Nexo, el Editor, Kira Volt
y el Reino del Continue. Todos los nombres siguen siendo provisionales y viven solo en `src/game/data.gd`.

## El bucle
- La regla del Reino es **continuar**: al caer, Kira vuelve al **Umbral de Nexo**.
- **Se conserva**: los fragmentos, lo comprado en el anillo, el orbe de salto doble y haber vencido al Rey.
- **Se pierde**: los poderes de las grietas y los corazones extra de *Sin Principio*.
- Nexo tiene una conversaciÃƒÂ³n nueva tras cada Continue (y otras al conseguir el orbe y al ganar).

## El mundo (6 salas)
| Sala | QuÃƒÂ© tiene |
|---|---|
| Umbral de Nexo | Nexo, el anillo (mejoras), el marcador del CONTINUE y un registro de Zerik |
| Pantalla de Inicio | pinchos, rastreros, escupidor y la primera grieta |
| Monedas Sueltas | sala alta con revoloteadores, grieta y el **orbe de salto doble** arriba del todo |
| Bloque Sorpresa | escupidores en alto, foso de pinchos y grieta |
| Doble Pantalla | subida vertical: las plataformas estÃƒÂ¡n a 5 casillas y **solo se sube con salto doble** |
| Trono del Reinicio | arena del **Rey del Reinicio**; la puerta se cierra hasta vencerle |

## Combate
- **Tajo** en tres direcciones; el tercero seguido hace Ãƒâ€”1,5. El tajo hacia abajo rebota en enemigos y pinchos.
- **Filo** (6 muescas, la espada de Kira): cada tajo que acierta llena una. Con 2 se puede lanzar una
  **descarga** o **concentrarse** para recuperar un corazÃƒÂ³n.
- **Dash** con invulnerabilidad mientras dura (como en los roguelites de acciÃƒÂ³n).
- **Regla del Reino (Ã‚Â«ContinÃƒÂºaÃ‚Â»)**: el rastrero deja un **nÃƒÂºcleo** al caer. Si no se rompe en 4 s,
  vuelve (una sola vez, marcado Ã‚Â«2UPÃ‚Â»).
- Enemigos: rastrero, revoloteador y escupidor; los tajos cortan sus proyectiles.

## Las grietas
En cada intento, cada una de las 4 grietas trae a un hÃƒÂ©roe distinto (orden al azar), que ofrece 3 poderes:
| HÃƒÂ©roe | Poderes |
|---|---|
| Aeron (Reino del Continue) | EspadÃƒÂ³n Ã‚Â· Golpe de Reinicio Ã‚Â· Sin Principio |
| Zerik (Reino del Continue) | DiagnÃƒÂ³stico Ã‚Â· MÃƒÂ¡s Datos Ã‚Â· Disparo Reforzado |
| Voltra (NeÃƒÂ³n de Medianoche) | Sobrecarga Ã‚Â· De Farola en Farola Ã‚Â· Carrera |
| Raiko (Academia del ÃƒÅ¡ltimo Hechizo) | Apartar Ã‚Â· Disciplina Ã‚Â· Combate Justo |

## El anillo de Nexo (mejoras permanentes)
CorazÃƒÂ³n de Reserva (+1 corazÃƒÂ³n, 3 niveles), Filo Templado (+4 de daÃƒÂ±o, 3 niveles), Filo Cargado
(empezar con el filo lleno) y Continue Extra (una vez por intento, volver con media vida).

## El Rey del Reinicio
Embestida con el cetro, salto aplastante con dos ondas por el suelo y, a media vida (Ã‚Â«Ã‚Â¡Continue!Ã‚Â»),
lluvia de proyectiles con aviso en el suelo y revoloteadores de refuerzo. Vencerle da 60 fragmentos,
abre la puerta y cambia el marcador del Umbral a GAME CLEAR.

## Pendiente
- Sonido.
- Arte final: todo se dibuja por cÃƒÂ³digo; el arte de Kira de `art/` no estÃƒÂ¡ conectado todavÃƒÂ­a.
- MÃƒÂ¡s mundos de la Trama (Academia, ÃƒÅ¡ltima SesiÃƒÂ³n, NeÃƒÂ³n, Vertedero, Frontera).

Tests: `game_tests.gd` 54/54 (con el mundo 2).
