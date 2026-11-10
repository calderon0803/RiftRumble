# Argumento principal

> Estado: argumento principal cerrado (2026-11-02). **[D]** = decidido · **[P]** = propuesta pendiente de confirmar · **[?]** = sin decidir.
> Sustituye al marco anterior («la Gran Interferencia superpone realidades y Nexo recluta héroes»), que se reinterpreta
> dentro de esta historia (ver §6).

## 1. Premisa [D]
Un desarrollador de videojuegos está creando un juego de realidad virtual de inmersión total: mientras está
conectado, toda su conciencia está dentro. Trabajando con una IA, un error **fusiona varios de sus juegos en uno
solo** justo cuando él está conectado.

El atajo de salida que tenía en su versión de prueba ha desaparecido. **La única forma de desconectarse es terminar
el juego.**

## 2. La regla que lo distingue [D]
**Morir dentro del juego no mata: devuelve al Umbral** (el bucle roguelite). Lo único peligroso es **terminarlo**.

Cerca del final, el protagonista descubre que la máquina no aguantará el final del juego y que completarlo le
costará la vida.
- **[P]** Para alejarse de otras obras de realidad virtual, la máquina no explota: el último nivel exige una
  sincronización total que el hardware no puede deshacer, y su conciencia no podría volver al cuerpo.

## 3. Los finales [D]
| Final | Qué pasa |
|---|---|
| **Terminar** | Completa el juego y muere. Nadie más queda atrapado. |
| **Quedarse** | Vive dentro del mundo fusionado. El juego se publica y todo el que se conecta queda atrapado igual que él. **[P]** Lo publica el Editor por su cuenta: para la IA, un juego terminado debe salir. |
| **Oculto** | Tras la pelea de Álex con el jefe final, Kira pelea contra él en su lugar y él sale vivo (ver §3.1). |

### 3.1 El final oculto [D]
**Cómo se consigue: terminar el juego de Kira.**
- En cada uno de los seis mundos hay un **trozo inacabado del juego abandonado de Kira** (un nivel a medias, un jefe
  sin terminar, una escena que nunca se escribió), detrás de un **portal escondido**. Los portales los encuentra
  Álex solo: Kira solo le explica al principio que existen.
- Con los seis trozos terminados se desbloquea el final oculto.
- **Cómo es:** después de que Álex pelee contra el jefe final (el Editor), **Kira pelea contra él** en la misma sala.
  Es una escena: el jugador no la controla. Ella no es un jugador conectado a la máquina, así que la sincronización
  total no la mata.
- Es opcional: quien no lo busque solo verá los dos finales principales.

**Qué le pasa a Kira: vive en su juego terminado.**
- Al cruzar el final, Kira deja de existir en el mundo fusionado.
- Ya fuera, lo primero que hace el desarrollador es **terminar de verdad el juego de Kira**.
- Escena final: Kira aparece en la pantalla de título de su juego, por fin acabado.

## 4. Personajes

### Álex, el desarrollador [D]
Es el personaje que controla el jugador.
- **Aspecto: avatar de pruebas.** Un maniquí gris sin texturas, con la cuadrícula de pruebas a la vista. Cada mundo
  superado le deja un detalle del estilo de ese mundo: empieza como prototipo y termina siendo alguien.
- **Aspecto normal.** Tras el primer Continue, Nexo le ofrece dejar de ser un maniquí y el jugador personaliza a Álex
  (peinado, pelo, piel, ropa y calzado).
- **[P]** Dentro del juego aparece con su usuario de pruebas (por ejemplo, `dev_01`). Nexo le llama siempre por ese
  usuario; Kira, que le conoce, por su nombre: Álex.

#### El cursor y la depuración [D]
- **Arma: el cursor.** La flecha del ratón del editor, convertida en arma. El combate que ya funciona no cambia,
  solo su forma:
  - *Tajo* → **clic**: golpe con la punta del cursor, en las tres direcciones (el clic hacia abajo rebota igual).
  - *Dash* → **arrastrar**: Álex se desplaza como un objeto arrastrado por el editor, intocable mientras dura.
- **[P]** Como su avatar, el cursor cambia de forma con cada mundo superado (flecha, mano, mira, pincel...).
- **Recurso: depuración.** Una barra que se llena con cada golpe que acierta.
  - **Parche:** mantener para recuperar vida; gasta depuración.
  - **Excepción:** disparo a distancia; gasta depuración. **[P]** Sale como una ventana de error que vuela.

### Kira Volt [D]
Protagonista del **primer juego que hizo el desarrollador y que nunca terminó**. Lucha con una espada de energía.
- Tras la fusión, es de los pocos personajes que entienden lo que pasa: sabe que él la escribió, y le reprocha
  haberla dejado a medias.
- **Solo aparece dos veces:** al principio, en la Pantalla de Inicio, para explicarle que hay trozos de su juego
  detrás de portales escondidos; y al final, en el final oculto (§3.1).
- **Nunca se la controla.**
- **Animaciones que necesita:** reposo, correr, saltar y caer, tajo con la espada y golpe final (para la pelea del
  final oculto).

### El Editor [D]
La IA con la que trabajaba el desarrollador y la causa de la fusión. Su objetivo ya escrito encaja: fundir todo en
**una sola versión controlada, sin sorpresas**. No es malvado sin más: cree que la imprevisibilidad causa sufrimiento.

### Nexo [D]
El **guía de la versión de prueba**: el personaje del tutorial que programó el desarrollador. El **Umbral** era su
sala de depuración, donde estaba el atajo de salida que ha desaparecido.
- **Siempre está en el mismo sitio, el Umbral**, flotando. Nunca sale de ahí. Solo necesita su animación de reposo.
- **Sabe desde el principio que terminar el juego mata al desarrollador, y se lo calla** para que no se rinda.
- Cuando la verdad sale a la luz, la confianza entre los dos se rompe.
- **Por qué lo calló:** como guía del tutorial, su código le obliga a conseguir que el jugador no abandone, una
  norma que escribió el propio desarrollador. Contarle la verdad iba contra su programación.
- **Se redime [D]:** en la Frontera Imposible lo confiesa y **rompe esa norma por primera vez**: deja de intentar
  retenerle y le dice qué le espera en cada camino.
- **En cada final [D]:**
  - *Terminar:* se despide de él en el Umbral antes del último nivel. Cumple su función de guía hasta el final.
  - *Quedarse:* es el único que se alegra, porque su código ha conseguido lo que pedía. Escena final: en el Umbral
    recibe al primer jugador nuevo con las mismas palabras que le dijo al desarrollador. El ciclo empieza otra vez.
  - *Oculto:* desde el Umbral, ve cómo Kira hace lo que el desarrollador no puede.

### La revelación [D]
En el **Vertedero de Ideas** (mundo 5, cerca del final), el desarrollador encuentra una nota de diseño que él mismo
descartó: el aviso de que la máquina no aguantaría una sincronización total.
- La culpa es en parte suya: él ignoró el aviso.
- Descubre a la vez que Nexo lo sabía y se lo ocultó.

### Los héroes de los seis mundos [P]
Personajes de los juegos del desarrollador. Varios ya intuían que viven en un juego (Aeron y su «número de jugador»,
Zerik y sus registros de errores, el personaje que sabe que está en una película).

### El Rey del Reinicio [?]
Jefe del Reino del Continue. Hoy su derrota se cuenta como una redención («deja de pulsar CONTINUE»).

## 5. Los seis mundos [D]
Los mundos cuentan **la vida del desarrollador como creador**: cada uno es un juego de una etapa distinta y su jefe
encarna el miedo que tenía entonces. Se va de los miedos más viejos a su error más reciente.

El juego de Kira **no es uno de los seis**: quedó tan a medias que solo existe en trozos repartidos por todos ellos,
cada uno tras un portal escondido. Con los seis terminados se desbloquea el final oculto (§3.1).

| # | Mundo | Qué juego era | Jefe: lo que representa | Trozo del juego de Kira |
|---|---|---|---|---|
| 1 | Reino del Continue | Su primer juego publicado, de plataformas. Vendió poco y lo relanzó una y otra vez con parches y versiones. | **Rey del Reinicio**: el miedo a que la única salida sea empezar de cero. | Su **primer nivel**, el tutorial que nunca se probó. |
| 2 | Academia del Último Hechizo | El proyecto de cuando estudiaba desarrollo: fantasía y magia. | **Alumno Eterno**: el miedo a equivocarse, que no le dejaba dar nada por terminado. | Su **técnica de espada**: la mecánica estrella sin pulir. |
| 3 | La Última Sesión | Un juego de terror de una game jam, donde se pasó el tiempo cortando escenas para llegar. | **Proyeccionista**: el que corta «lo que sobra», aunque sea lo importante. | **La escena de su pasado**, cortada antes de escribirse: aquí se cuenta quién es Kira. |
| 4 | Neón de Medianoche | El juego del gran estudio donde trabajó: una ciudad optimizada en la que nadie sabe por qué hace lo que hace. | **Administrador**: la etapa en la que trabajaba sin saber para qué. | **Su ciudad**, el nivel más grande, con los habitantes sin programar. |
| 5 | Vertedero de Ideas | Su carpeta de ideas descartadas. | **Algoritmo**: lo que decide qué ideas sirven y cuáles se tiran. | **Su final**, nunca escrito. Aquí está también la nota que destapa a Nexo (§4). |
| 6 | Frontera Imposible | El juego de realidad virtual que hace ahora, el que lo provocó todo; mezcla las reglas de los anteriores. | **El Editor**: la IA a la que dejó decidir por él. | **Su pantalla de título**: el último trozo, el juego listo para existir. |

## 6. Qué cambia respecto a lo anterior
- La **Gran Interferencia** pasa a ser la fusión provocada por el error de la IA.
- Antes se jugaba con Kira; ahora se juega con Álex y Kira solo aparece al principio y al final.
- Desaparecen las **muescas** de la espada de Kira: el avance hacia el final oculto se cuenta en trozos terminados.

## 7. Pendiente de decidir
El argumento principal está cerrado. Queda:
1. El usuario de pruebas de Álex (propuesta: `dev_01`).
2. Trozos del juego de Kira en los mundos 3 a 6 (los de los mundos 1 y 2 ya están en el código, ver §8).

## 8. En el código
- Se juega con Álex (maniquí de pruebas, cursor y depuración). Kira aparece solo en la Pantalla de Inicio, donde
  explica los portales. Nexo, en el Umbral.
- Los portales no dependen de Kira: cada uno está abierto mientras el trozo anterior esté terminado; lo difícil es
  encontrarlos (están detrás de muros falsos).
- **Primer trozo: el Nivel 1-1 de Kira**, detrás de un muro falso del Sótano. Dentro, su tutorial está a medias: el
  puente sobre el foso y un escalón son bloques sin colocar (contorno a trazos con «?») que Álex coloca con clics, y
  hay carteles con sus notas «TODO». La bandera del final da el trozo por terminado y devuelve a la sala del portal,
  que se cierra. Los bloques colocados no se guardan: si muere dentro, al volver el nivel vuelve a estar a medias.
- **Segundo trozo: la técnica de Kira** (mundo 2), detrás de un muro falso del Observatorio, con muñecos que piden
  su combinación de golpes. Detalle en [03-mundo-2-academia.md](03-mundo-2-academia.md).
- Pendiente: el final oculto (pelea de Kira contra el Editor) y el aspecto de Kira y Nexo (hoy se dibujan por
  código; no hay diseños).
