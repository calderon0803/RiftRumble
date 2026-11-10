"""Vista de comprobacion de un cuerpo base glTF: medidas, huesos y cuatro vistas con su textura.

blender -b --factory-startup -P ver_base.py -- <modelo.gltf> <prefijo de salida> [pelo.gltf ...]
"""
import math
import sys

import bpy

args = sys.argv[sys.argv.index("--") + 1:]
model, out, extras = args[0], args[1], args[2:]
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
for path in [model] + extras:
    bpy.ops.import_scene.gltf(filepath=path)

arm = next((o for o in scene.objects if o.type == "ARMATURE"), None)
meshes = []
for o in scene.objects:
    if o.type != "MESH":
        continue
    if o.name.startswith("Icosphere"):  # ayudas del esqueleto que trae el pack
        o.hide_render = True
        continue
    meshes.append(o)
# Textura de piel alternativa del mismo pack (PIEL=<ruta png>)
import os
if os.environ.get("PIEL"):
    skin = bpy.data.images.load(os.environ["PIEL"])
    for o in meshes:
        for m in o.data.materials:
            for n in m.node_tree.nodes if m and m.node_tree else []:
                if n.type == "TEX_IMAGE" and n.image and "Superhero_Female" in n.image.name and "BaseColor" in n.image.name:
                    n.image = skin
# La vista Workbench muestra la textura del nodo activo: que sea la de color.
for m in bpy.data.materials:
    for n in m.node_tree.nodes if m.node_tree else []:
        if n.type == "TEX_IMAGE" and n.image and ("BaseColor" in n.image.name or "Eye_Brown" in n.image.name):
            m.node_tree.nodes.active = n
bpy.context.view_layer.update()
zs, xs = [], []
for o in meshes:
    for v in o.data.vertices:
        w = o.matrix_world @ v.co
        zs.append(w.z); xs.append(w.x)
print("RESULT altura %.3f..%.3f ancho %.3f..%.3f" % (min(zs), max(zs), min(xs), max(xs)))
for o in meshes:
    print("RESULT malla", o.name, len(o.data.vertices), "vertices", sum(len(p.vertices) - 2 for p in o.data.polygons), "tri",
          [m.name for m in o.data.materials])
if arm:
    print("RESULT huesos", len(arm.data.bones), [b.name for b in arm.data.bones])

scene.render.engine = "BLENDER_WORKBENCH"
shading = scene.display.shading
shading.light = "STUDIO"
shading.color_type = "TEXTURE"
scene.world = bpy.data.worlds.new("fondo")
scene.world.color = (0.8, 0.8, 0.8)
scene.render.resolution_x, scene.render.resolution_y = 600, 700
cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = 2.1
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
mid = (min(zs) + max(zs)) / 2
for view, ang in (("frente", 0), ("tres_cuartos", 40), ("perfil", 90), ("cara", 20)):
    a = math.radians(ang)
    cam.location = (6 * math.sin(a), -6 * math.cos(a), mid)
    cam.rotation_euler = (math.radians(90), 0, a)
    cam_data.ortho_scale = 2.1
    if view == "cara":
        cam.location.z = max(zs) - 0.13
        cam_data.ortho_scale = 0.45
    scene.render.filepath = "%s_%s.png" % (out, view)
    bpy.ops.render.render(write_still=True)
