"""Prueba peinados de MakeHuman (CC0) sobre la cabeza de Kira y hace una vista de cada uno.

blender -b --factory-startup -P probar_pelos.py -- <kira_ranger.blend> <salida> <carpeta_peinado> [<carpeta_peinado> ...]

Cada carpeta trae un .obj (unidades de MakeHuman: decimetros, Y arriba) y su textura con transparencia.
El peinado se escala y se coloca segun la caja de la cabeza de Kira, y lo que quede dentro del craneo
se empuja hacia fuera. Se quita el pelo generado por codigo para ver solo el peinado probado.
"""
import glob
import math
import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
BLEND, OUT, FOLDERS = args[0], args[1], args[2:]
bpy.ops.wm.open_mainfile(filepath=BLEND)
scene = bpy.context.scene
body = bpy.data.objects["Kira_Cuerpo"]
for name in ("Kira_Pelo", "Kira_PeloBase", "Kira_PeloBase_Dobladillo", "Kira_Atadura"):
    if name in bpy.data.objects:
        bpy.data.objects[name].hide_render = True

mw = body.matrix_world
head = [mw @ v.co for v in body.data.vertices if (mw @ v.co).z > 1.56]
H_TOP = max(p.z for p in head)
H_X = max(abs(p.x) for p in head if p.z > 1.6)
H_FRONT = min(p.y for p in head if p.z > 1.6 and abs(p.x) < 0.03)
H_BACK = max(p.y for p in head if p.z > 1.6 and abs(p.x) < 0.03)
print("RESULT cabeza", H_TOP, H_X, H_FRONT, H_BACK, flush=True)


def select_only(ob):
    bpy.context.view_layer.objects.active = ob
    for o in bpy.context.view_layer.objects:
        o.select_set(o == ob)


def load_hair(folder):
    obj = sorted(glob.glob(os.path.join(folder, "*.obj")))[0]
    before = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=obj)
    new = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    select_only(new[0])
    for o in new:
        o.select_set(True)
    if len(new) > 1:
        bpy.ops.object.join()
    hair = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # Textura: la que indica el material de MakeHuman (.mhmat)
    pngs = []
    for mhmat in glob.glob(os.path.join(folder, "*.mhmat")):
        for line in open(mhmat, encoding="utf8", errors="ignore"):
            if line.startswith("diffuseTexture"):
                pngs.append(os.path.join(folder, line.split(None, 1)[1].strip()))
    m = bpy.data.materials.new("M_" + os.path.basename(folder))
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    if pngs and os.path.exists(pngs[0]):
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(pngs[0])
        # Verde de Kira: la luminosidad de la textura (normalizada a su media) recorre una rampa de verdes,
        # asi da igual que el pelo original sea rubio o negro.
        px = tex.image.pixels[:]
        lum = [0.3 * px[i] + 0.6 * px[i + 1] + 0.1 * px[i + 2] for i in range(0, len(px), 4 * 97) if px[i + 3] > 0.5]
        mean = sum(lum) / len(lum) if lum else 0.5
        bw = nt.nodes.new("ShaderNodeRGBToBW")
        ramp = nt.nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].position = mean * 0.35
        ramp.color_ramp.elements[0].color = (0.01, 0.09, 0.025, 1)
        ramp.color_ramp.elements[1].position = min(1.0, mean * 1.6)
        ramp.color_ramp.elements[1].color = (0.12, 0.55, 0.16, 1)
        nt.links.new(tex.outputs["Color"], bw.inputs["Color"])
        nt.links.new(bw.outputs["Val"], ramp.inputs["Fac"])
        nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
        nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    else:
        bsdf.inputs["Base Color"].default_value = (0.05, 0.32, 0.09, 1)
    bsdf.inputs["Roughness"].default_value = 0.5
    if hasattr(m, "surface_render_method"):
        m.surface_render_method = "DITHERED"
    hair.data.materials.clear()
    hair.data.materials.append(m)
    for p in hair.data.polygons:
        p.use_smooth = True
    return hair


def fit(hair):
    vs = [hair.matrix_world @ v.co for v in hair.data.vertices]
    top = max(v.z for v in vs)
    # anchura a la altura de las sienes del peinado (cerca de la parte alta), no la de la melena
    upper = [v for v in vs if v.z > top - 0.25 * (top - min(w.z for w in vs))] or vs
    width = max(v.x for v in upper) - min(v.x for v in upper)
    s = (2 * H_X + 0.035) / width
    hair.scale = (s, s, s)
    bpy.context.view_layer.update()
    vs = [hair.matrix_world @ v.co for v in hair.data.vertices]
    top = max(v.z for v in vs)
    upper = [v for v in vs if v.z > top - 0.06]
    cy = (max(v.y for v in upper) + min(v.y for v in upper)) / 2
    hair.location += Vector((0, (H_FRONT + H_BACK) / 2 + 0.005 - cy, H_TOP + 0.012 - top))
    select_only(hair)
    bpy.ops.object.transform_apply(location=True, scale=True)
    sw = hair.modifiers.new("fuera", "SHRINKWRAP")
    sw.target = body
    sw.wrap_method = "NEAREST_SURFACEPOINT"
    sw.wrap_mode = "OUTSIDE"
    sw.offset = 0.004
    bpy.ops.object.modifier_apply(modifier=sw.name)


cam = scene.camera
scene.render.resolution_x, scene.render.resolution_y = 500, 600
for folder in FOLDERS:
    name = os.path.basename(folder.rstrip("/\\"))
    hair = load_hair(folder)
    fit(hair)
    for view, ang in (("frente", 20), ("lado", 110)):
        a = math.radians(ang)
        cam.location = (6 * math.sin(a), -6 * math.cos(a), H_TOP - 0.2)
        cam.rotation_euler = (math.radians(90), 0, a)
        cam.data.ortho_scale = 0.75
        scene.render.filepath = os.path.join(OUT, "pelo_%s_%s.png" % (name, view))
        bpy.ops.render.render(write_still=True)
    print("RESULT peinado", name, len(hair.data.vertices), flush=True)
    bpy.data.objects.remove(hair)
