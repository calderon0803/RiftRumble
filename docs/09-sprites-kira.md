# Fase 10 — Kira dibujada por piezas

## Objetivo
Sustituir el rectángulo provisional por Kira de verdad, en 2D y animada, sin 3D ni herramientas de pago.

## Cómo está hecha
- **Hoja de piezas**: `art/concept/hero_blade/kira_piezas_v1.webp` (generada antes, con el flequillo en
  punta y la espada de 6 muescas del diseño aprobado). Cabeza, coleta, torso, cadera, brazo y antebrazo
  con mano (×2), muslo y pierna con bota (×2) y espada.
- **Esqueleto**: `tools/art/cut_parts.py kira montar` recorta las piezas (quita el fondo gris), las
  escala con proporciones cabezonas (`art/kira/rig.json`, campo `size` por pieza) y escribe el atlas
  `art/kira/kira_parts.png` y el esqueleto `art/kira/kira_rig.tres` (13 piezas).
- **Animación** (`src/player/rig/`): cada pieza cuelga de su padre (cinemática directa); la coleta tiene
  inercia con un muelle; la espada deja estela en los tajos.

## Animaciones (`src/player/rig/cutout_anims.gd`)
| | |
|---|---|
| reposo | respiración y cambio de peso |
| carrera | ciclo de dos pasos; se acelera o frena con la velocidad real |
| salto / caída | rodilla arriba y brazo alto al subir; piernas hacia el suelo y brazos abiertos al caer |
| tajo, tajo arriba, tajo abajo | el corte ocurre en las primeras centésimas (el golpe es instantáneo), con estela |
| tajo de filo | arco completo con paso adelante |
| dash | cuerpo volcado hacia delante; deja una estela de copias de Kira que se desvanecen |
| pared | de espaldas a la pared, piernas flexionadas |
| golpe recibido | sacudida hacia atrás |

Prioridad: tajo o golpe en curso > dash > pared > aire > correr > reposo. El parpadeo de
invulnerabilidad se aplica al dibujo.

## Limitaciones conocidas
- La cara de la hoja está **de tres cuartos**, no de perfil puro: Kira corre de lado con la cara algo
  girada hacia la cámara. Cambiarlo pediría una hoja nueva de perfil.
- Las poses se ajustan a mano en `cutout_anims.gd`; `tools/rig_preview.gd` las dibuja todas en una imagen
  para revisarlas sin jugar.

## Criterios de aceptación
- [x] Kira se dibuja con sus 13 piezas y los pies apoyan en el suelo.
- [x] Cada acción pone su animación: reposo, carrera, salto, caída, tajos (3), tajo de filo, dash, golpe.
- [x] Un tajo no se corta por otra animación hasta que termina.
- [x] El dash deja una estela de copias de Kira.

Tests: `scene_tests.gd` 43/43 (más el resto de tests).
