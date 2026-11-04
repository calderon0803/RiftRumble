# Mundo 2: Academia del Último Hechizo

El proyecto de cuando Álex estudiaba: fantasía y magia, en violeta, dorado y azul noche. Su jefe, el Alumno
Eterno, es el miedo a equivocarse. Historia completa en [02-argumento.md](02-argumento.md).

## Cómo se llega
Cada intento recorre el Reino del Continue: **el Rey del Reinicio vuelve en cada intento** y, al vencerle, se
abre la puerta derecha del trono hacia la Academia. La primera vez sale la pantalla de mundo superado (60
fragmentos); las siguientes, solo un rótulo (30).

## El mapa (12 salas + Técnica de Kira)
Ampliada igual que el Reino ([04-reino-ampliado.md](04-reino-ampliado.md)): mapa fijo, desvíos opcionales,
arenas y élites, pensada para 10-15 minutos por intento.
```
Trono ─ Patio ─ Vestíbulo ─ Biblioteca ─ Pasillo ─ Laboratorio ─ Galería ─ Torre ─ Antesala ─ Claustro ─ Aula Magna
                   │
                   ├─ arriba: Observatorio (opcional)
                   └─ abajo: Archivo Prohibido (opcional)
```
| Sala | Qué enseña o exige |
|---|---|
| Patio de la Academia | primer cristal de resonancia, una plataforma de cristal, grieta en alto, conjurador, muro agrietado |
| Vestíbulo de los Ecos | sala vertical con cuatro salidas; dos tramos de la subida son de cristal |
| Observatorio | opcional: subida por cristal hasta fragmentos escondidos, grieta, **conjurador de élite** |
| Archivo Prohibido | opcional: puentes de cristal sobre pinchos, fragmentos escondidos, escupidor de élite |
| Biblioteca Flotante | tres cristales y una subida por plataformas de cristal hasta la salida alta, grieta, bloque sorpresa |
| Pasillo de las Runas | el **orbe de salto en pared** sobre un bloque alto |
| Laboratorio de Alquimia | **arena** de conjuradores, con un cristal en el centro para pelear resonando |
| Galería de Retratos | **pide salto en pared**: el muro solo se pasa subiendo por una chimenea; luego cristal sobre pinchos |
| Torre del Examen | pozo sin escalones, solo con salto en pared |
| Antesala del Examen | **fuente** y grieta |
| Claustro de los Repetidores | **arena** de élites |
| Aula Magna | el **Alumno Eterno** |
| Técnica de Kira | segundo trozo del juego de Kira |

## Mecánicas nuevas
- **Resonancia** (regla del mundo): un clic a un cristal hace resonar a Álex 6 s. Mientras resuena, sus clics
  hacen +40% de daño y llegan más lejos, y las **plataformas de cristal** se pueden pisar.
- **Conjurador**: flota y carga un hechizo durante 2 s con barra visible. Un golpe lo interrumpe; si lo termina,
  cura 15 a todos los enemigos y les da un **escudo** que absorbe el siguiente golpe.
- **Salto en pared** (habilidad permanente): en el aire, empujando hacia una pared, Álex se desliza despacio;
  saltar le lanza hacia fuera y hacia arriba. Devuelve el dash y el salto doble.
- **Conjurador de élite** (con corona): carga en 1,4 s y cura 25.
- **Grietas**: 9 por intento (5 en el Reino y 4 en la Academia). Los cuatro héroes se reparten varias veces y
  cada vez ofrecen los poderes que aún no se han cogido.

## El Alumno Eterno
600 de vida y tres fases (a 2/3 y 1/3 de vida). Ataques: ráfaga de orbes hacia Álex (más orbes en cada fase),
desaparece y reaparece lejos, runas en el suelo que avisan y levantan columnas de luz, y en las fases 2 y 3
invoca conjuradores.

**Se adapta:** en cada cambio de fase pasa a resistir el ataque con el que más daño le han hecho en la fase anterior
(clic de frente, hacia arriba, hacia abajo o Excepción). Ese ataque solo le hace un 25% y el marcador lo indica.
Obliga a variar.

Vencerle da 80 fragmentos (40 las siguientes veces) y una bufanda violeta al avatar de Álex.

## Técnica de Kira (segundo trozo)
Su portal (2-1) está escondido al fondo del Observatorio, detrás de un muro falso; se abre con el primer trozo
terminado. Dentro hay tres muñecos de entrenamiento, cada uno con una combinación de golpes encima (X, ↑X, ↓X).
Hay que dar los golpes en ese orden; uno equivocado reinicia la combinación. Con los tres aprendidos aparece la
bandera, que da el trozo por terminado (2 de 6).

Tests: `game_tests.gd` 72/72 · `reach_tests.gd` 169/169.
