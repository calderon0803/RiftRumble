"""Kira con la ropa «Ranger» de Quaternius (Modular Character Outfits - Fantasy, CC0).

blender -b --factory-startup -P kira_ranger.py -- <kira.blend> <pack de ropa> <pack de cuerpos> <salida> <carpeta hair de MakeHuman>

Parte de kira.blend (lo que genera kira_modelo.py): quita la ropa hecha por codigo, vuelve a poner el
cuerpo entero, monta encima las piezas del Ranger (sin capucha ni mangas: la coleta y los tatuajes
quedan a la vista), las ajusta al cuerpo y borra la piel que queda tapada.
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

BLEND, OUTFITS, BODIES, OUT, HAIRS = sys.argv[sys.argv.index("--") + 1:][:5]
bpy.ops.wm.open_mainfile(filepath=BLEND)
scene = bpy.context.scene
arm = next(o for o in scene.objects if o.type == "ARMATURE")
body = bpy.data.objects["Kira_Cuerpo"]
KIRA = bpy.data.collections["KIRA_Malla"]

# ---------------------------------------------------------------- quitar la ropa hecha por codigo
MINE = ("Kira_Corpino", "Kira_Camiseta", "Kira_Pantalon", "Kira_Medias", "Kira_Brazal", "Kira_Guante",
        "Kira_Botas", "Kira_BotaPie", "Kira_BotaHebilla", "Kira_Rodilleras", "Kira_Espinilleras",
        "Kira_Cinturon", "Kira_Falda", "Kira_Bufanda")
for o in list(scene.objects):
    if o.name.startswith(MINE):
        bpy.data.objects.remove(o)


def select_only(ob):
    bpy.context.view_layer.objects.active = ob
    for o in bpy.context.view_layer.objects:
        o.select_set(o == ob)


# ---------------------------------------------------------------- cuerpo entero otra vez
before = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=os.path.join(BODIES, "Base Characters", "Godot - UE", "Superhero_Female_FullBody.gltf"))
new = [o for o in bpy.data.objects if o not in before]
fresh = next(o for o in new if o.name.startswith("Superhero_Female"))
old_mats = list(body.data.materials)
body.data = fresh.data
body.data.materials.clear()
for m in old_mats:
    body.data.materials.append(m)
for o in new:
    bpy.data.objects.remove(o)

# ---------------------------------------------------------------- ropa Ranger
before = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=os.path.join(OUTFITS, "Exports", "glTF (Godot-Unreal)", "Outfits", "Female_Ranger.gltf"))
new = [o for o in bpy.data.objects if o not in before]
ranger_arm = next(o for o in new if o.type == "ARMATURE")
# Diferencia de esqueleto entre el cuerpo Regular (para el que esta hecha la ropa) y el nuestro
diff = max((ranger_arm.data.bones[b.name].head_local - b.head_local).length for b in arm.data.bones if b.name in ranger_arm.data.bones)
print("RESULT diferencia maxima de huesos %.4f m" % diff, flush=True)
DROP = ("Female_Ranger_Head_Hood", "Female_Ranger_Arms")
pieces = []
for o in new:
    if o.type != "MESH" or o.name.startswith("Icosphere") or o.name in DROP:
        continue
    mw = o.matrix_world.copy()
    o.parent = arm
    o.matrix_world = mw
    for mod in o.modifiers:
        if mod.type == "ARMATURE":
            mod.object = arm
    for c in o.users_collection:
        c.objects.unlink(o)
    KIRA.objects.link(o)
    o.name = o.name.replace("Female_Ranger", "Kira_Ranger")
    pieces.append(o)
for o in new:
    if o.name in bpy.data.objects and o not in pieces:
        bpy.data.objects.remove(o)

# ---------------------------------------------------------------- colores de Kira
# La textura del Ranger se recolorea por tono: cuero marron -> negro, metal plateado -> bronce,
# verde amarillento -> el verde de Kira. Los cinturones conservan el cuero; el pantalon pasa a negro.
import numpy as np

TEX_DIR = os.path.join(OUT, "texturas")
os.makedirs(TEX_DIR, exist_ok=True)
src_mat = pieces[0].data.materials[0]
src_img = next(n.image for n in src_mat.node_tree.nodes if n.type == "TEX_IMAGE" and "BaseColor" in n.image.name)


def rgb_to_hsv(rgb):
    mx, mn = rgb.max(1), rgb.min(1)
    d = mx - mn
    ds = np.where(d == 0, 1, d)
    r, g, b = rgb[:, 0], rgb[:, 1], rgb[:, 2]
    h = np.where(mx == r, ((g - b) / ds) % 6, np.where(mx == g, (b - r) / ds + 2, (r - g) / ds + 4)) / 6
    h = np.where(d == 0, 0, h)
    s_ = np.where(mx > 0, d / np.where(mx == 0, 1, mx), 0)
    return h, s_, mx


def hsv_to_rgb(h, s_, v):
    i = np.floor(h * 6).astype(int) % 6
    f = h * 6 - np.floor(h * 6)
    p_, q, t = v * (1 - s_), v * (1 - f * s_), v * (1 - (1 - f) * s_)
    choices = [(v, t, p_), (q, v, p_), (p_, v, t), (p_, q, v), (t, p_, v), (v, p_, q)]
    out = np.zeros((len(h), 3), dtype=np.float32)
    for k, (a, b, c) in enumerate(choices):
        m = i == k
        out[m, 0], out[m, 1], out[m, 2] = a[m], b[m], c[m]
    return out


def recolor(name, keep_leather=False, dark_green_black=False):
    img = src_img.copy()
    img.name = name
    img.scale(2048, 2048)
    px = np.array(img.pixels[:], dtype=np.float32).reshape(-1, 4)
    h, s_, v = rgb_to_hsv(px[:, :3])
    brown = (h > 0.0) & (h < 0.13) & (s_ > 0.25)
    metal = (s_ < 0.2) & (v > 0.45)
    green = (h > 0.18) & (h < 0.5) & (s_ > 0.2)
    if not keep_leather:
        h = np.where(brown, 0.62, h)
        s_ = np.where(brown, 0.12, s_)
        v = np.where(brown, v * 0.32, v)
    h = np.where(metal, 0.105, h)
    s_ = np.where(metal, 0.55, s_)
    v = np.where(metal, v * 0.8, v)
    h = np.where(green, 0.37, h)
    if dark_green_black:
        dark = green & (v < 0.25)
        s_ = np.where(dark, 0.1, s_)
        v = np.where(dark, v * 0.7, v)
    px[:, :3] = hsv_to_rgb(h, s_, v)
    img.pixels.foreach_set(px.ravel())
    img.filepath_raw = os.path.join(TEX_DIR, name + ".png")
    img.file_format = "PNG"
    img.save()
    # La copia hereda la textura original empaquetada y su ruta: se sustituyen por el PNG nuevo
    path = img.filepath_raw
    img.unpack(method="REMOVE") if img.packed_file else None
    img.filepath = path
    img.reload()
    print("RESULT ruta", img.filepath, bool(img.packed_file), flush=True)
    m = src_mat.copy()
    m.name = "M_" + name
    for n in m.node_tree.nodes:
        if n.type == "TEX_IMAGE" and n.image == src_img:
            n.image = img
    print("RESULT textura", name, flush=True)
    return m


VARIANTS = {"main": recolor("T_Kira_Ropa"), "belt": recolor("T_Kira_Cuero", keep_leather=True),
            "legs": recolor("T_Kira_Pantalon", dark_green_black=True)}
for o in pieces:
    key = "belt" if "Belt" in o.name else ("legs" if o.name.endswith("Legs") else "main")
    for i, m in enumerate(o.data.materials):
        if m == src_mat:
            o.data.materials[i] = VARIANTS[key]

# Del cuerpo solo quedan cabeza, cuello, brazos y manos: el resto lo cubre la ropa, hecha para
# otro cuerpo mas delgado (el pack lo indica: con su ropa, del cuerpo base solo se usa la cabeza).
mw = body.matrix_world


def visible_skin(p):
    return p.z > 1.44 or (abs(p.x) > 0.15 and p.z > 1.30)


bm = bmesh.new()
bm.from_mesh(body.data)
bm.verts.ensure_lookup_table()
dead = [f for f in bm.faces if not any(visible_skin(mw @ v.co) for v in f.verts)]
bmesh.ops.delete(bm, geom=dead, context="FACES")
bm.to_mesh(body.data)
bm.free()
print("RESULT caras de piel quitadas", len(dead), flush=True)

# Brazaletes y hombrera se ajustan a los brazos de este cuerpo, que son mas gruesos
for o in pieces:
    if "Bracer" in o.name or "Pauldron" in o.name:
        sw = o.modifiers.new("ajuste", "SHRINKWRAP")
        sw.target = body
        sw.wrap_method = "NEAREST_SURFACEPOINT"
        sw.wrap_mode = "OUTSIDE"
        sw.offset = 0.004
        select_only(o)
        bpy.ops.object.modifier_apply(modifier=sw.name)
    print("RESULT pieza", o.name, len(o.data.vertices), flush=True)

# ---------------------------------------------------------------- pelo: coleta de MakeHuman (CC0)
# «ponytail01» de los recursos del sistema de MakeHuman. Sustituye al pelo generado por codigo.
# Se escala y coloca segun la caja de la cabeza; lo que quede dentro del craneo sale hacia fuera.
# La textura se pasa al verde de Kira conservando el brillo de los mechones y la transparencia.
for name in ("Kira_Pelo", "Kira_PeloBase", "Kira_PeloBase_Dobladillo", "Kira_Atadura"):
    if name in bpy.data.objects:
        bpy.data.objects.remove(bpy.data.objects[name])
HAIR_DIR = os.path.join(HAIRS, "ponytail01")
mwb = body.matrix_world
head = [mwb @ v.co for v in body.data.vertices if (mwb @ v.co).z > 1.56]
H_TOP = max(p.z for p in head)
H_X = max(abs(p.x) for p in head if p.z > 1.6)
H_FRONT = min(p.y for p in head if p.z > 1.6 and abs(p.x) < 0.03)
H_BACK = max(p.y for p in head if p.z > 1.6 and abs(p.x) < 0.03)

before = set(bpy.data.objects)
bpy.ops.wm.obj_import(filepath=os.path.join(HAIR_DIR, "ponytail01.obj"))
hair = next(o for o in bpy.data.objects if o not in before and o.type == "MESH")
hair.name = "Kira_Pelo"
select_only(hair)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
vs = [v.co for v in hair.data.vertices]
top = max(v.z for v in vs)
upper = [v for v in vs if v.z > top - 0.25 * (top - min(w.z for w in vs))]
s = (2 * H_X + 0.035) / (max(v.x for v in upper) - min(v.x for v in upper))
hair.scale = (s, s, s)
bpy.ops.object.transform_apply(scale=True)
vs = [v.co for v in hair.data.vertices]
top = max(v.z for v in vs)
upper = [v for v in vs if v.z > top - 0.06]
cy = (max(v.y for v in upper) + min(v.y for v in upper)) / 2
hair.location = Vector((0, (H_FRONT + H_BACK) / 2 + 0.005 - cy, H_TOP + 0.012 - top))
bpy.ops.object.transform_apply(location=True)
sw = hair.modifiers.new("fuera", "SHRINKWRAP")
sw.target = body
sw.wrap_method = "NEAREST_SURFACEPOINT"
sw.wrap_mode = "OUTSIDE"
sw.offset = 0.004
bpy.ops.object.modifier_apply(modifier=sw.name)

src = bpy.data.images.load(os.path.join(HAIR_DIR, "ponytail01_diffuse.png"))
px = np.array(src.pixels[:], dtype=np.float32).reshape(-1, 4)
lum = px[:, 0] * 0.3 + px[:, 1] * 0.6 + px[:, 2] * 0.1
mean = float(lum[px[:, 3] > 0.5].mean())
t = np.clip((lum - mean * 0.35) / (mean * 1.6 - mean * 0.35), 0, 1)[:, None]
dark, light = np.array([0.03, 0.30, 0.09]), np.array([0.37, 0.77, 0.42])  # verdes en sRGB
px[:, :3] = dark + (light - dark) * t
hair_img = bpy.data.images.new("T_Kira_Pelo", src.size[0], src.size[1], alpha=True)
hair_img.pixels.foreach_set(px.ravel())
hair_img.filepath_raw = os.path.join(TEX_DIR, "T_Kira_Pelo.png")
hair_img.file_format = "PNG"
hair_img.save()
hair_img.source = "FILE"
hair_img.filepath = hair_img.filepath_raw
hair_img.reload()
m = bpy.data.materials.new("M_Kira_Pelo")
nt = m.node_tree
bsdf = nt.nodes["Principled BSDF"]
tex = nt.nodes.new("ShaderNodeTexImage")
tex.image = hair_img
nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
bsdf.inputs["Roughness"].default_value = 0.5
if hasattr(m, "surface_render_method"):
    m.surface_render_method = "DITHERED"
hair.data.materials.clear()
hair.data.materials.append(m)
for p in hair.data.polygons:
    p.use_smooth = True
# Rigida con la cabeza
vg = hair.vertex_groups.new(name="Head")
vg.add(list(range(len(hair.data.vertices))), 1.0, "REPLACE")
mw_h = hair.matrix_world.copy()
hair.parent = arm
hair.matrix_world = mw_h
mod = hair.modifiers.new("esqueleto", "ARMATURE")
mod.object = arm
for c in hair.users_collection:
    c.objects.unlink(hair)
KIRA.objects.link(hair)

# Atadura de bronce donde nace la coleta: la parte mas alta del pelo que queda detras del craneo
tail = [v.co for v in hair.data.vertices if v.co.y > H_BACK + 0.012 and abs(v.co.x) < 0.05]
root_z = max(v.z for v in tail)
root = [v for v in tail if v.z > root_z - 0.03]
c = sum(root, Vector()) / len(root)
r = max(0.016, max(abs(v.x - c.x) for v in root) * 0.8)
tie_v, tie_f = [], []
for i in range(24):
    a = 2 * math.pi * i / 24
    for dz in (-0.01, 0.01):
        tie_v.append(c + Vector((math.cos(a) * r, math.sin(a) * r * 0.9, dz)))
for i in range(24):
    j = (i + 1) % 24
    tie_f.append((2 * i, 2 * j, 2 * j + 1, 2 * i + 1))
me = bpy.data.meshes.new("Kira_Atadura")
me.from_pydata(tie_v, [], tie_f)
tie = bpy.data.objects.new("Kira_Atadura", me)
KIRA.objects.link(tie)
bronze = next((mm for mm in bpy.data.materials if mm.name == "M_Kira_Bronce"), None)
if bronze:
    me.materials.append(bronze)
sol = tie.modifiers.new("grosor", "SOLIDIFY")
sol.thickness = 0.006
select_only(tie)
bpy.ops.object.modifier_apply(modifier=sol.name)
for p in me.polygons:
    p.use_smooth = True
tvg = tie.vertex_groups.new(name="Head")
tvg.add(list(range(len(me.vertices))), 1.0, "REPLACE")
tie.parent = arm
tmod = tie.modifiers.new("esqueleto", "ARMATURE")
tmod.object = arm
print("RESULT coleta", len(hair.data.vertices), "raiz", tuple(round(x, 3) for x in c), flush=True)

# ---------------------------------------------------------------- huesos de la capa
# Tres cadenas de 4 huesos (I = izquierda de Kira, C = centro, D = derecha) que cuelgan de spine_03
# siguiendo la tela. En Godot, Avatar3D las mueve con SpringBoneSimulator3D (inercia, gravedad y
# choque con las piernas). La capa, su dobladillo y las runas pasan a depender de estos huesos.
CAPE_CHAINS = (("I", 0.13), ("C", 0.0), ("D", -0.13))
CAPE_JOINTS = (1.40, 1.15, 0.90, 0.66, 0.47)
cape = bpy.data.objects["Kira_Capa"]
deps = bpy.context.evaluated_depsgraph_get()
cape_bvh = BVHTree.FromObject(cape, deps)
inv = cape.matrix_world.inverted()
chain_points = {}
for side, x in CAPE_CHAINS:
    pts = []
    for z in CAPE_JOINTS:
        hit = cape_bvh.ray_cast(inv @ Vector((x, 2.0, z)), (inv.to_3x3() @ Vector((0, -1, 0))).normalized())
        if hit[0] is None:  # fuera de la tela (p. ej. un diente del borde): el punto de la capa mas cercano
            hit = cape_bvh.find_nearest(inv @ Vector((x, 0.4, z)))
        p = cape.matrix_world @ hit[0]
        pts.append(Vector((x, p.y - 0.006, z)))
    chain_points[side] = pts

bpy.context.view_layer.objects.active = arm
for o in bpy.context.view_layer.objects:
    o.select_set(o == arm)
bpy.ops.object.mode_set(mode="EDIT")
to_arm = arm.matrix_world.inverted()
eb = arm.data.edit_bones
for side, pts in chain_points.items():
    parent = eb["spine_03"]
    for k in range(len(pts) - 1):
        b = eb.new("capa_%s_%d" % (side, k))
        b.head = to_arm @ pts[k]
        b.tail = to_arm @ pts[k + 1]
        b.roll = 0.0
        b.parent = parent
        b.use_connect = k > 0
        parent = b
bpy.ops.object.mode_set(mode="OBJECT")

N_SEG = len(CAPE_JOINTS) - 1


def cape_weights(p):
    """Pesos de un punto de la capa: mezcla horizontal entre cadenas y vertical entre huesos."""
    xs = [x for _, x in CAPE_CHAINS]  # de +x a -x
    wh = {}
    if p.x >= xs[0]:
        wh = {CAPE_CHAINS[0][0]: 1.0}
    elif p.x <= xs[-1]:
        wh = {CAPE_CHAINS[-1][0]: 1.0}
    else:
        for i in range(len(xs) - 1):
            if xs[i] >= p.x >= xs[i + 1]:
                t = (xs[i] - p.x) / (xs[i] - xs[i + 1])
                wh = {CAPE_CHAINS[i][0]: 1 - t, CAPE_CHAINS[i + 1][0]: t}
    # u: 0 en la primera articulacion, N_SEG en la ultima
    zs = CAPE_JOINTS
    if p.z >= zs[0]:
        u = -(p.z - zs[0]) / (zs[0] - zs[1])
    else:
        u = N_SEG
        for k in range(N_SEG):
            if zs[k] >= p.z >= zs[k + 1]:
                u = k + (zs[k] - p.z) / (zs[k] - zs[k + 1])
                break
    out = {"spine_03": max(0.0, 1 - u * 2)}
    for k in range(N_SEG):
        wv = max(0.0, 1 - abs(u - (k + 0.5)))
        if k == N_SEG - 1 and u > N_SEG - 0.5:
            wv = 1.0
        for side, w in wh.items():
            out["capa_%s_%d" % (side, k)] = out.get("capa_%s_%d" % (side, k), 0.0) + wv * w
    total = sum(out.values()) or 1.0
    return {k: v / total for k, v in out.items() if v > 1e-4}


for name in ("Kira_Capa", "Kira_Capa_Dobladillo", "Kira_Runas"):
    ob = bpy.data.objects.get(name)
    if ob is None:
        continue
    for vg in list(ob.vertex_groups):
        ob.vertex_groups.remove(vg)
    mw = ob.matrix_world
    groups = {}
    for v in ob.data.vertices:
        for bone, w in cape_weights(mw @ v.co).items():
            g = groups.get(bone) or ob.vertex_groups.new(name=bone)
            groups[bone] = g
            g.add([v.index], w, "REPLACE")
print("RESULT huesos de la capa", sum(len(p) - 1 for p in chain_points.values()), flush=True)

# ---------------------------------------------------------------- guardar y vistas
items = [i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in items else "BLENDER_EEVEE_NEXT"
scene.world = bpy.data.worlds.new("fondo")
bg = scene.world.node_tree.nodes["Background"]
bg.inputs["Color"].default_value = (0.55, 0.57, 0.6, 1)
bg.inputs["Strength"].default_value = 0.9
for name, rot, energy in (("sol", (50, 10, -35), 3.0), ("relleno", (60, 0, 140), 1.2)):
    ld = bpy.data.lights.new(name, "SUN")
    ld.energy = energy
    lo = bpy.data.objects.new(name, ld)
    lo.rotation_euler = [math.radians(a) for a in rot]
    scene.collection.objects.link(lo)
scene.view_settings.view_transform = "Standard"
cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
scene.render.resolution_x, scene.render.resolution_y = 700, 800
HEAD_TOP = 1.767
VIEWS = (("frente", 0, 2.0, 0.89), ("tres_cuartos", 40, 2.0, 0.89), ("perfil", 90, 2.0, 0.89),
         ("espalda", 180, 2.0, 0.89), ("cara", 25, 0.5, HEAD_TOP - 0.12), ("detalle", 35, 0.75, 1.13),
         ("piernas", 30, 0.8, 0.45))
for view, ang, scale, z in VIEWS:
    a = math.radians(ang)
    cam.location = (6 * math.sin(a), -6 * math.cos(a), z)
    cam.rotation_euler = (math.radians(90), 0, a)
    cam_data.ortho_scale = scale
    scene.render.filepath = os.path.join(OUT, "capturas", "ranger_%s.png" % view)
    bpy.ops.render.render(write_still=True)
    print("RESULT vista", view, flush=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "kira_ranger.blend"))
