# Roguelite en el Reino del Continue

Se rehace RIFT RUMBLE a partir de un prototipo web (metroidvania con dones al estilo roguelite) y se
le pone la historia y el mundo que ya tenía el proyecto: la Gran Interferencia, Nexo, el Editor, Kira Volt
y el Reino del Continue. Todos los nombres siguen siendo provisionales y viven solo en `src/game/data.gd`.

## El bucle
- La regla del Reino es **continuar**: al caer, Kira vuelve al **Umbral de Nexo**.
- **Se conserva**: los fragmentos, lo comprado en el anillo, el orbe de salto doble y haber vencido al Rey.
- **Se pierde**: los poderes de las grietas y los corazones extra de *Sin Principio*.
- Nexo tiene una conversación nueva tras cada Continue (y otras al conseguir el orbe y al ganar).

## El mundo (6 salas)
| Sala | Qué tiene |
|---|---|
| Umbral de Nexo | Nexo, el anillo (mejoras), el marcador del CONTINUE y un registro de Zerik |
| Pantalla de Inicio | pinchos, rastreros, escupidor y la primera grieta |
| Monedas Sueltas | sala alta con revoloteadores, grieta y el **orbe de salto doble** arriba del todo |
| Bloque Sorpresa | escupidores en alto, foso de pinchos y grieta |
| Doble Pantalla | subida vertical: las plataformas están a 5 casillas y **solo se sube con salto doble** |
| Trono del Reinicio | arena del **Rey del Reinicio**; la puerta se cierra hasta vencerle |

## Combate
- **Tajo** en tres direcciones; el tercero seguido hace ×1,5. El tajo hacia abajo rebota en enemigos y pinchos.
- **Filo** (6 muescas, la espada de Kira): cada tajo que acierta llena una. Con 2 se puede lanzar una
  **descarga** o **concentrarse** para recuperar un corazón.
- **Dash** con invulnerabilidad mientras dura (como en los roguelites de acción).
- **Regla del Reino («Continúa»)**: el rastrero deja un **núcleo** al caer. Si no se rompe en 4 s,
  vuelve (una sola vez, marcado «2UP»).
- Enemigos: rastrero, revoloteador y escupidor; los tajos cortan sus proyectiles.

## Las grietas
En cada intento, cada una de las 4 grietas trae a un héroe distinto (orden al azar), que ofrece 3 poderes:
| Héroe | Poderes |
|---|---|
| Aeron (Reino del Continue) | Espadón · Golpe de Reinicio · Sin Principio |
| Zerik (Reino del Continue) | Diagnóstico · Más Datos · Disparo Reforzado |
| Voltra (Neón de Medianoche) | Sobrecarga · De Farola en Farola · Carrera |
| Raiko (Academia del Último Hechizo) | Apartar · Disciplina · Combate Justo |

## El anillo de Nexo (mejoras permanentes)
Corazón de Reserva (+1 corazón, 3 niveles), Filo Templado (+4 de daño, 3 niveles), Filo Cargado
(empezar con el filo lleno) y Continue Extra (una vez por intento, volver con media vida).

## El Rey del Reinicio
Embestida con el cetro, salto aplastante con dos ondas por el suelo y, a media vida («¡Continue!»),
lluvia de proyectiles con aviso en el suelo y revoloteadores de refuerzo. Vencerle da 60 fragmentos,
abre la puerta y cambia el marcador del Umbral a GAME CLEAR.

## Pendiente
- Sonido.
- Arte final: todo se dibuja por código; el arte de Kira de `art/` no está conectado todavía.
- Más mundos de la Trama (Academia, Última Sesión, Neón, Vertedero, Frontera).

Tests: `game_tests.gd` 25/25.
