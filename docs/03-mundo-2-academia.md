# Mundo 2: Academia del Ãšltimo Hechizo

El proyecto de cuando Ãlex estudiaba: fantasÃ­a y magia, en violeta, dorado y azul noche. Su jefe, el Alumno
Eterno, es el miedo a equivocarse. Historia completa en [02-argumento.md](02-argumento.md).

## CÃ³mo se llega
Cada intento recorre el Reino del Continue: **el Rey del Reinicio vuelve en cada intento** y, al vencerle, se
abre la puerta derecha del trono hacia la Academia. La primera vez sale la pantalla de mundo superado (60
fragmentos); las siguientes, solo un rÃ³tulo (30).

## Salas
| Sala | QuÃ© tiene |
|---|---|
| Patio de la Academia | primer cristal de resonancia, una plataforma de cristal, una grieta en alto y un conjurador |
| Biblioteca Flotante | tres cristales y una subida por plataformas de cristal hasta la salida alta, grieta |
| Pasillo de las Runas | **Kira** y el portal a su tÃ©cnica; el **orbe de salto en pared** sobre un bloque alto |
| Torre del Examen | pozo de 4 casillas sin escalones: **solo se sube con salto en pared**; grieta abajo |
| Aula Magna | arena del **Alumno Eterno** |
| TÃ©cnica de Kira | segundo trozo del juego de Kira |

## MecÃ¡nicas nuevas
- **Resonancia** (regla del mundo): un clic a un cristal hace resonar a Ãlex 6 s. Mientras resuena, sus clics
  hacen +40% de daÃ±o y llegan mÃ¡s lejos, y las **plataformas de cristal** se pueden pisar.
- **Conjurador**: flota y carga un hechizo durante 2 s con barra visible. Un golpe lo interrumpe; si lo termina,
  cura 15 a todos los enemigos y les da un **escudo** que absorbe el siguiente golpe.
- **Salto en pared** (habilidad permanente): en el aire, empujando hacia una pared, Ãlex se desliza despacio;
  saltar le lanza hacia fuera y hacia arriba. Devuelve el dash y el salto doble.
- **Grietas**: ahora son 7 por intento (4 en el Reino y 3 en la Academia). Los cuatro hÃ©roes se reparten dos veces;
  en la segunda ofrecen los poderes que no se han cogido.

## El Alumno Eterno
600 de vida y tres fases (a 2/3 y 1/3 de vida). Ataques: rÃ¡faga de orbes hacia Ãlex (mÃ¡s orbes en cada fase),
desaparece y reaparece lejos, runas en el suelo que avisan y levantan columnas de luz, y en las fases 2 y 3
invoca conjuradores.

**Se adapta:** en cada cambio de fase pasa a resistir el ataque con el que mÃ¡s daÃ±o le han hecho en la fase anterior
(clic de frente, hacia arriba, hacia abajo o ExcepciÃ³n). Ese ataque solo le hace un 25% y el marcador lo indica.
Obliga a variar.

Vencerle da 80 fragmentos (40 las siguientes veces) y una bufanda violeta al avatar de Ãlex.

## TÃ©cnica de Kira (segundo trozo)
Kira se presenta en el Pasillo de las Runas y abre el portal 2-1. Dentro hay tres muÃ±ecos de entrenamiento, cada uno
con una combinaciÃ³n de golpes encima (X, â†‘X, â†“X). Hay que dar los golpes en ese orden; uno equivocado reinicia la
combinaciÃ³n. Con los tres aprendidos aparece la bandera, que enciende **la segunda muesca** de la espada de Kira.

Tests: `game_tests.gd` 57/57.
