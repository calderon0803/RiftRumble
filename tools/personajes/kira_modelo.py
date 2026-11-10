"""Kira estilizada sobre el cuerpo base de Quaternius (Universal Base Characters, CC0).

blender -b --factory-startup -P kira_modelo.py -- <carpeta del pack Standard> <carpeta de salida>

El cuerpo ya trae esqueleto (65 huesos) y pesos. Casi toda la ropa se saca del propio cuerpo:
se copia una zona de la malla, se separa unos milimetros por la normal y se le da grosor, asi
sigue la anatomia y hereda los pesos. Falda y capa se cuelgan con simulacion de tela. El pelo
son mechones generados alrededor de la cabeza. La espada (opcion B) va colgada de hand_r.
Pose en T, mirando a -Y (en Godot, +Z), unidades en metros. Guarda kira.blend y las vistas.
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

PACK, OUT = sys.argv[sys.argv.index("--") + 1:][:2]
BASE = os.path.join(PACK, "Base Characters")
random.seed(7)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---------------------------------------------------------------- cuerpo base
bpy.ops.import_scene.gltf(filepath=os.path.join(BASE, "Godot - UE", "Superhero_Female_FullBody.gltf"))
for o in list(scene.objects):
    if o.name.startswith("Icosphere"):
        bpy.data.objects.remove(o)
arm = next(o for o in scene.objects if o.type == "ARMATURE")
body = bpy.data.objects["Superhero_Female"]
body.name = "Kira_Cuerpo"
bpy.data.objects["Eyes"].name = "Kira_Ojos"
bpy.data.objects["Eyebrows"].name = "Kira_Cejas"
TO_W = body.matrix_world.copy()
TO_L = TO_W.inverted()


def srgb(hexcol):
    c = [int(hexcol[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c) + (1.0,)


MATS = {}


def mat(name, hexcol, rough=0.8, metal=0.0):
    m = bpy.data.materials.new("M_Kira_" + name)
    m.diffuse_color = srgb(hexcol)
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = srgb(hexcol)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    MATS[name] = m
    return m


mat("Negro", "#1d1e24", 0.7)
mat("NegroTela", "#2a2b33", 0.9)
mat("Gris", "#8d8f96", 0.8)
mat("Verde", "#24753a", 0.85)
mat("VerdeOscuro", "#174f27", 0.85)
mat("Forro", "#d9d6cc", 0.9)
mat("Pelo", "#2f8f3e", 0.6)
mat("Cuero", "#7a5532", 0.7)
mat("Bronce", "#b08a45", 0.4, 0.8)
mat("Metal", "#3d424b", 0.45, 0.7)
mat("Energia", "#5fe39a", 0.3)
MATS["Energia"].node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = srgb("#5fe39a")
MATS["Energia"].node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 1.5


def color_input(mix):
    return [i for i in mix.inputs if i.name == "B" and i.type == "RGBA"][0]


# Piel clara del mismo pack
skin_img = bpy.data.images.load(os.path.join(BASE, "Textures", "T_Superhero_Female_Light_BaseColor.png"))
for n in body.data.materials[0].node_tree.nodes:
    if n.type == "TEX_IMAGE" and n.image and "BaseColor" in n.image.name:
        n.image = skin_img
        print("RESULT piel clara aplicada", flush=True)
# Ojos verdes: giro de tono sobre la textura del iris
eye_mat = bpy.data.objects["Kira_Ojos"].data.materials[0]
nt = eye_mat.node_tree
tex = next(n for n in nt.nodes if n.type == "TEX_IMAGE" and "Normal" not in n.image.name)
hue = nt.nodes.new("ShaderNodeHueSaturation")
hue.inputs["Hue"].default_value = 0.78
hue.inputs["Saturation"].default_value = 1.4
for link in list(nt.links):
    if link.from_node == tex and link.from_socket.name == "Color":
        to = link.to_socket
        nt.links.remove(link)
        nt.links.new(tex.outputs["Color"], hue.inputs["Color"])
        nt.links.new(hue.outputs["Color"], to)
# Cejas verdes
brow = bpy.data.objects["Kira_Cejas"].data.materials[0].node_tree
for n in brow.nodes:
    if n.type == "MIX":
        sock = color_input(n)
        for link in list(sock.links):
            brow.links.remove(link)
        sock.default_value = srgb("#1e5e2a")

# Datos del cuerpo en espacio de mundo
BV = [TO_W @ v.co for v in body.data.vertices]
BN = [(TO_W.to_3x3() @ v.normal).normalized() for v in body.data.vertices]


def band(z0, z1, cond=lambda p: True):
    return [p for p in BV if z0 <= p.z <= z1 and cond(p)]


head_pts = band(1.56, 2.0)
HEAD_TOP = max(p.z for p in head_pts)
HEAD_FRONT = min(p.y for p in band(1.58, 1.68, lambda p: abs(p.x) < 0.03))
HEAD_BACK = max(p.y for p in band(1.58, 1.68, lambda p: abs(p.x) < 0.03))
HEAD_HALF_X = max(abs(p.x) for p in band(1.60, 1.66))
HC = Vector((0, (HEAD_FRONT + HEAD_BACK) / 2, HEAD_TOP - 0.1))
HR = Vector((HEAD_HALF_X, (HEAD_BACK - HEAD_FRONT) / 2, 0.11))
print("RESULT cabeza arriba %.3f delante %.3f detras %.3f ancho %.3f" % (HEAD_TOP, HEAD_FRONT, HEAD_BACK, HEAD_HALF_X))


def section(z, cond=lambda p: True, dz=0.012):
    pts = band(z - dz, z + dz, cond)
    return (min(p.x for p in pts), max(p.x for p in pts), min(p.y for p in pts), max(p.y for p in pts))


# ---------------------------------------------------------------- utilidades
KIRA = bpy.data.collections.new("KIRA_Malla")
scene.collection.children.link(KIRA)
SWORD = bpy.data.collections.new("KIRA_Espada")
scene.collection.children.link(SWORD)


def link(ob, coll=KIRA):
    for c in ob.users_collection:
        c.objects.unlink(ob)
    coll.objects.link(ob)


link(body)
link(bpy.data.objects["Kira_Ojos"])
link(bpy.data.objects["Kira_Cejas"])


def select_only(ob):
    bpy.context.view_layer.objects.active = ob
    for o in bpy.context.view_layer.objects:
        o.select_set(o == ob)


def apply_modifiers(ob, keep=("ARMATURE",)):
    select_only(ob)
    for mod in list(ob.modifiers):
        if mod.type not in keep:
            bpy.ops.object.modifier_apply(modifier=mod.name)


def add_armature(ob):
    mod = ob.modifiers.new("esqueleto", "ARMATURE")
    mod.object = arm
    if ob.parent != arm:
        ob.parent = arm
        ob.matrix_parent_inverse = arm.matrix_world.inverted()


def set_materials(ob, names, chooser=None):
    ob.data.materials.clear()
    for n in names:
        ob.data.materials.append(MATS[n])
    if chooser:
        mw = ob.matrix_world
        for p in ob.data.polygons:
            p.material_index = names.index(chooser(mw @ p.center, (mw.to_3x3() @ p.normal).normalized()))


def garment(name, keep, offset, materials, chooser=None, thick=0.0, flat=False, rim=None):
    """Prenda copiada del cuerpo: vertices que cumplen keep(p), separados `offset` por la normal."""
    me = body.data.copy()
    me.name = name
    ob = bpy.data.objects.new(name, me)
    KIRA.objects.link(ob)
    ob.matrix_world = body.matrix_world
    ob.parent = arm
    ob.matrix_parent_inverse = body.matrix_parent_inverse.copy()
    ob.matrix_world = body.matrix_world
    if me.shape_keys:
        select_only(ob)
        ob.shape_key_clear()
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    normals = [v.normal.copy() for v in bm.verts]
    drop = [v for v in bm.verts if not keep(BV[v.index], BN[v.index])]
    for v in bm.verts:
        v.co += normals[v.index] * offset
    bmesh.ops.delete(bm, geom=drop, context="VERTS")
    bm.to_mesh(me)
    bm.free()
    set_materials(ob, materials, chooser)
    if thick:
        sol = ob.modifiers.new("grosor", "SOLIDIFY")
        sol.thickness = thick
        sol.offset = 1.0
        if rim:
            sol.material_offset_rim = materials.index(rim)
    if flat:
        bev = ob.modifiers.new("bisel", "BEVEL")
        bev.width = 0.002
        bev.segments = 1
    apply_modifiers(ob, keep=())
    for p in ob.data.polygons:
        p.use_smooth = not flat
    add_armature(ob)
    return ob


def weight_all(ob, groups):
    """Pesos fijos: groups es una lista de (hueso, funcion(p) -> peso)."""
    mw = ob.matrix_world
    for bone, fn in groups:
        vg = ob.vertex_groups.get(bone) or ob.vertex_groups.new(name=bone)
        for v in ob.data.vertices:
            w = fn(mw @ v.co)
            if w > 0:
                vg.add([v.index], w, "REPLACE")


def transfer_weights(ob):
    """Pesos del cuerpo por la cara mas cercana (para telas que siguen a las piernas)."""
    select_only(ob)
    dt = ob.modifiers.new("pesos", "DATA_TRANSFER")
    dt.object = body
    dt.use_vert_data = True
    dt.data_types_verts = {"VGROUP_WEIGHTS"}
    dt.vert_mapping = "POLYINTERP_NEAREST"
    bpy.ops.object.datalayout_transfer(modifier=dt.name)
    bpy.ops.object.modifier_apply(modifier=dt.name)


def mesh_obj(name, verts, faces, materials, coll=KIRA):
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.validate()
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    for n in materials:
        me.materials.append(MATS[n])
    return ob


# ---------------------------------------------------------------- telas simuladas
def simulate(ob, frames, bending=0.5, pin="pin"):
    col = body.modifiers.get("colision") or body.modifiers.new("colision", "COLLISION")
    body.collision.thickness_outer = 0.006
    cl = ob.modifiers.new("tela", "CLOTH")
    s = cl.settings
    s.quality = 8
    s.mass = 0.25
    s.bending_stiffness = bending
    s.vertex_group_mass = pin
    s.air_damping = 2.0
    cl.collision_settings.distance_min = 0.006
    cl.point_cache.frame_start = 1
    cl.point_cache.frame_end = frames
    scene.frame_start, scene.frame_end = 1, frames
    for f in range(1, frames + 1):
        scene.frame_set(f)
    select_only(ob)
    bpy.ops.object.modifier_apply(modifier=cl.name)
    scene.frame_set(1)
    print("RESULT tela", ob.name, flush=True)


def grid_sheet(name, rows, cols, point, pin_rows=2):
    verts = [point(i / cols, j / rows, i, j) for j in range(rows + 1) for i in range(cols + 1)]
    faces = []
    for j in range(rows):
        for i in range(cols):
            a = j * (cols + 1) + i
            faces.append((a, a + 1, a + cols + 2, a + cols + 1))
    ob = mesh_obj(name, verts, faces, [])
    vg = ob.vertex_groups.new(name="pin")
    vg.add([j * (cols + 1) + i for j in range(pin_rows) for i in range(cols + 1)], 1.0, "REPLACE")
    return ob


def ragged(i, cols, depth):
    """Borde roto: dientes irregulares."""
    k = i % 4
    base = (0.0, 0.55, 1.0, 0.45)[k]
    return depth * base * (0.6 + 0.8 * ((i * 37) % 11) / 10)


# Falda de paneles abierta por delante, de la cintura (bajo los cinturones) a la rodilla
from mathutils.bvhtree import BVHTree
BODY_BVH = BVHTree.FromPolygons(BV, [tuple(p.vertices) for p in body.data.polygons])
wx0, wx1, wy0, wy1 = section(0.975)
cy_w = (wy0 + wy1) / 2
SK_TOP, SK_LEN = 0.972, 0.47
SK_COLS, SK_ROWS = 64, 26


def surface_radius(z, a, cy):
    d = Vector((-math.sin(a), -math.cos(a), 0))
    c = Vector((0, cy, z))
    hit = BODY_BVH.ray_cast(c + d, -d)
    return (hit[0] - c).length if hit[0] is not None else 0.16


def skirt_point(u, v, i, j):
    a = math.radians(38 + u * 284)  # 0 grados = delante; hueco delante de 76 grados
    r = surface_radius(SK_TOP, a, cy_w) + 0.008 + v * 0.12
    z = SK_TOP - v * SK_LEN
    if j == SK_ROWS:
        z += ragged(i, SK_COLS, 0.07)
    elif j == SK_ROWS - 1:
        z += ragged(i, SK_COLS, 0.07) * 0.4
    return (-math.sin(a) * r, cy_w - math.cos(a) * r, z)


skirt = grid_sheet("Kira_Falda", SK_ROWS, SK_COLS, skirt_point)
# Cortes a los lados de atras: la falda queda en cuatro paneles que caen cada uno a su aire
bm = bmesh.new()
bm.from_mesh(skirt.data)
dead = []
for f in bm.faces:
    c = f.calc_center_median()
    ang = math.degrees(math.atan2(-c.x, -(c.y - cy_w))) % 360
    if c.z < SK_TOP - 0.15 and min(abs(ang - 128), abs(ang - 232), abs(ang - 180)) < 2.3:
        dead.append(f)
bmesh.ops.delete(bm, geom=dead, context="FACES")
bm.to_mesh(skirt.data)
bm.free()
simulate(skirt, 45, bending=1.0)

# Capa: cae desde los hombros por detras
CP_ROWS, CP_COLS = 40, 30
back = {}
for p in band(1.40, 1.47, lambda p: abs(p.x) < 0.2 and p.y > 0):
    key = round(p.x / 0.02)
    back[key] = max(back.get(key, -1), p.y)


def back_y(x):
    key = round(x / 0.02)
    near = [back[k] for k in (key - 1, key, key + 1) if k in back]
    return max(near) if near else 0.1


def cape_point(u, v, i, j):
    w = 0.17 + v * 0.17
    x = (u * 2 - 1) * w
    k = (u * 2 - 1)
    ztop = 1.465 - 0.05 * k * k
    if j == 0:
        return (x, back_y(x) + 0.03, ztop)
    z = ztop - v * 1.0
    y = back_y(min(max(x, -0.18), 0.18)) + 0.035 + v * 0.06
    if j == CP_ROWS:
        z += ragged(i, CP_COLS, 0.10)
    elif j == CP_ROWS - 1:
        z += ragged(i, CP_COLS, 0.10) * 0.4
    return (x, y, z)


cape = grid_sheet("Kira_Capa", CP_ROWS, CP_COLS, cape_point, pin_rows=1)
simulate(cape, 50, bending=3.0)
body.modifiers.remove(body.modifiers["colision"])

# ---------------------------------------------------------------- sastreria
# Prendas cortadas del cuerpo con planos: bordes limpios en vez de seguir los triangulos.
# Cada prenda lleva dobladillo con grosor, costuras hundidas con vivo y pliegues donde la tela se arruga.
from mathutils.bvhtree import BVHTree


def leg(p):
    return p.z < 0.98 and abs(p.x) > 0.02 and abs(p.x) < 0.25


def smoothstep(e0, e1, x):
    t = min(1.0, max(0.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def boundary_loops(bm):
    """Cadenas de aristas de borde: lista de listas de vertices."""
    nb = {}
    for e in bm.edges:
        if e.is_boundary:
            a, b = e.verts
            nb.setdefault(a, []).append(b)
            nb.setdefault(b, []).append(a)
    seen, loops = set(), []
    for start in nb:
        if start in seen:
            continue
        loop, prev, cur = [start], None, start
        seen.add(start)
        while True:
            nxt = [v for v in nb[cur] if v is not prev and v not in seen]
            if not nxt:
                break
            prev, cur = cur, nxt[0]
            loop.append(cur)
            seen.add(cur)
        if len(loop) > 4:
            loops.append(loop)
    return loops


def tube_mesh(name, paths, radius, material, closed=True, sides=8, shift=0.7, weights=None):
    """Tubos a lo largo de caminos [(punto, normal de la superficie)]: dobladillos, vivos, correas finas."""
    verts, faces = [], []
    for path in paths:
        n = len(path)
        if n < 3:
            continue
        start = len(verts)
        for i, (p, nrm) in enumerate(path):
            a = path[(i - 1) % n][0] if (closed or i > 0) else p
            b = path[(i + 1) % n][0] if (closed or i < n - 1) else p
            t = (b - a).normalized()
            out = (nrm - t * nrm.dot(t)).normalized()
            side = t.cross(out)
            c = p + out * radius * shift
            for k in range(sides):
                ang = 2 * math.pi * k / sides
                verts.append(c + side * math.cos(ang) * radius + out * math.sin(ang) * radius * 0.8)
        rng = range(n) if closed else range(n - 1)
        for i in rng:
            j = (i + 1) % n
            for k in range(sides):
                k2 = (k + 1) % sides
                faces.append((start + i * sides + k, start + j * sides + k, start + j * sides + k2, start + i * sides + k2))
    ob = mesh_obj(name, verts, faces, [material])
    for p in ob.data.polygons:
        p.use_smooth = True
    if weights:
        weight_all(ob, weights)
    else:
        transfer_weights(ob)
    add_armature(ob)
    return ob


def relax_boundary(bm, iters=3):
    loops = boundary_loops(bm)
    for _ in range(iters):
        for loop in loops:
            n = len(loop)
            new = [(loop[i - 1].co + loop[(i + 1) % n].co) * 0.5 for i in range(n)]
            for v, c in zip(loop, new):
                v.co = v.co * 0.5 + c * 0.5


def tailor(name, planes, seeds, offset, materials, thick=0.004, folds=None, cut=None, chooser=None,
           hem=None, hem_material=None, seams=(), seam_material=None, flat=False, smooth=0):
    """planes: [(punto, normal)]: se quita lo que queda hacia la normal. seeds: puntos de las islas que se quedan.
    folds(p, n): desplazamiento extra por la normal (pliegues, costuras hundidas).
    hem: radio del dobladillo en todos los bordes. seams: [(x, z0, z1, lado)] vivos verticales (lado 1 delante)."""
    me = body.data.copy()
    me.name = name
    ob = bpy.data.objects.new(name, me)
    KIRA.objects.link(ob)
    ob.parent = arm
    ob.matrix_parent_inverse = body.matrix_parent_inverse.copy()
    ob.matrix_world = body.matrix_world
    if me.shape_keys:
        select_only(ob)
        ob.shape_key_clear()
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.transform(TO_W)
    # El glTF trae la malla partida en las costuras de textura: se vuelve a coser
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    for co, no in planes:
        bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], dist=1e-5,
                               plane_co=Vector(co), plane_no=Vector(no).normalized(), clear_outer=True)
    if cut:
        cut(bm)
    keep = set()
    for s in seeds:
        seed = min(bm.verts, key=lambda v: (v.co - Vector(s)).length)
        stack = [seed]
        while stack:
            v = stack.pop()
            if v in keep:
                continue
            keep.add(v)
            stack.extend(e.other_vert(v) for e in v.link_edges if e.other_vert(v) not in keep)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v not in keep], context="VERTS")
    relax_boundary(bm)
    bm.normal_update()
    normals = {v: v.normal.copy() for v in bm.verts}
    for v in bm.verts:
        v.co += normals[v] * (offset + (folds(v.co, normals[v]) if folds else 0.0))
    if smooth:  # piezas rigidas (cinturones): sin ondas
        inner = [v for v in bm.verts if not v.is_boundary]
        for _ in range(smooth):
            bmesh.ops.smooth_vert(bm, verts=inner, factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
        relax_boundary(bm, 4)
    bm.normal_update()
    hem_paths = [[(v.co.copy(), v.normal.copy()) for v in loop] for loop in boundary_loops(bm)] if hem else []
    tree = BVHTree.FromBMesh(bm)
    seam_paths = []
    for x, z0, z1, side in seams:
        path = []
        for k in range(40):
            z = z0 + (z1 - z0) * k / 39
            hit = tree.ray_cast(Vector((x, -side * 1.0, z)), Vector((0, side, 0)))
            if hit[0] is not None:
                path.append((hit[0].copy(), hit[1].copy()))
        seam_paths.append(path)
    bm.transform(TO_L)
    bm.to_mesh(me)
    bm.free()
    set_materials(ob, materials, chooser)
    sol = ob.modifiers.new("grosor", "SOLIDIFY")
    sol.thickness = thick
    sol.offset = 1.0
    if flat:
        bev = ob.modifiers.new("bisel", "BEVEL")
        bev.width = 0.0015
    apply_modifiers(ob, keep=())
    for p in ob.data.polygons:
        p.use_smooth = not flat
    add_armature(ob)
    if hem:
        tube_mesh(name + "_Dobladillo", [[(p + n * thick, n) for p, n in path] for path in hem_paths],
                  hem, hem_material or materials[0])
    if seams:
        tube_mesh(name + "_Vivo", [[(p + n * thick, n) for p, n in path] for path in seam_paths if len(path) > 3],
                  0.0018, seam_material or materials[0], closed=False, sides=6)
    return ob


def groove(p, x0, width, depth, side):
    """Costura hundida: linea vertical en |x| = x0, por delante (side=-1) o por detras (side=1)."""
    if p.y * side < 0:
        return 0.0
    d = abs(abs(p.x) - x0)
    return -depth * max(0.0, 1 - d / width) ** 2


def corset_folds(p, n):
    f = groove(p, 0.07, 0.008, 0.0025, -1) + groove(p, 0.06, 0.008, 0.0025, 1)
    side = smoothstep(0.06, 0.11, abs(p.x))
    f += 0.0022 * math.sin(p.z * 170 + p.x * 20) * side * max(0.0, 1 - abs(p.z - 1.09) / 0.07)
    if p.y < 0 and abs(p.x) < 0.05 and 1.22 < p.z < 1.36:  # la tela no se mete entre los pechos
        f += 0.012 * (1 - abs(p.x) / 0.05) * max(0.0, 1 - abs(p.z - 1.29) / 0.07)
    return f


def v_neck(bm):
    """Escote en V delantero, cortado por dos planos (solo por delante)."""
    for s in (1, -1):
        bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], dist=1e-5,
                               plane_co=Vector((0, 0, 1.27)), plane_no=Vector((s * 0.20, 0, -0.09)).normalized())
    dead = []
    for f in bm.faces:
        c = f.calc_center_median()
        if c.y < -0.02 and c.z > 1.27 and abs(c.x) < (c.z - 1.27) * 0.45:
            dead.append(f)
    bmesh.ops.delete(bm, geom=dead, context="FACES")


tailor("Kira_Corpino",
       [((0, 0, 0.955), (0, 0, -1)), ((0, 0, 1.47), (0, 0, 1)),
        ((0.125, 0, 1.39), (1, 0, 0.6)), ((-0.125, 0, 1.39), (-1, 0, 0.6))],
       [(0, -0.12, 1.1)], 0.008, ["Negro"], thick=0.005, folds=corset_folds, cut=v_neck,
       hem=0.0042, hem_material="Verde",
       seams=[(0.07, 0.96, 1.24, 1), (-0.07, 0.96, 1.24, 1), (0.06, 0.96, 1.40, -1), (-0.06, 0.96, 1.40, -1)],
       seam_material="VerdeOscuro")
tailor("Kira_Camiseta", [((0, 0, 1.24), (0, 0, -1)), ((0, 0, 1.475), (0, 0, 1)),
                         ((0.12, 0, 0), (1, 0, 0)), ((-0.12, 0, 0), (-1, 0, 0)), ((0, 0.0, 0), (0, 1, 0))],
       [(0, -0.12, 1.38)], 0.004, ["Gris"], thick=0.002)


def shorts_folds(p, n):
    s = 1 if p.x > 0 else -1
    ang = math.atan2(p.y - 0.03, p.x - s * 0.11)
    cuff = max(0.0, 1 - (p.z - 0.80) / 0.06)
    f = 0.0022 * math.sin(ang * 7 + s) * cuff
    if p.y < 0 and 0.82 < p.z < 0.92:  # pliegues de la ingle hacia la cadera
        f += 0.0018 * math.sin((p.z - abs(p.x) * 0.8) * 140) * smoothstep(0.03, 0.08, abs(p.x)) * (1 - smoothstep(0.12, 0.17, abs(p.x)))
    return f


tailor("Kira_Pantalon", [((0, 0, 0.995), (0, 0, 1)), ((0, 0, 0.80), (0.0, 0.15, -1))],
       [(0, 0.0, 0.9)], 0.006, ["NegroTela"], thick=0.004, folds=shorts_folds, hem=0.0045)


def stocking_folds(p, n):
    f = 0.0014 * math.sin(p.z * 260) * max(0.0, 1 - abs(p.z - 0.13) / 0.06)
    if p.y > 0:
        f += 0.0016 * math.sin(p.z * 220) * max(0.0, 1 - abs(p.z - 0.54) / 0.04)
    return f


tailor("Kira_Medias", [((0, 0, 0.685), (0, 0, 1)), ((0, 0, 0.06), (0, 0, -1))],
       [(0.11, 0, 0.4), (-0.11, 0, 0.4)], 0.003, ["NegroTela"], thick=0.002, folds=stocking_folds,
       hem=0.0065, hem_material="Negro")

for s in (1, -1):
    sx = "I" if s > 0 else "D"
    tailor("Kira_Brazal" + sx, [((s * 0.47, 0, 0), (-s, 0, 0)), ((s * 0.63, 0, 0), (s, 0, 0))],
           [(s * 0.55, 0.05, 1.418)], 0.012, ["Negro"], thick=0.005, hem=0.005, hem_material="Verde")
    for k, x in enumerate((0.515, 0.585)):
        tailor("Kira_BrazalCorrea" + sx + str(k), [((s * (x - 0.007), 0, 0), (-s, 0, 0)), ((s * (x + 0.007), 0, 0), (s, 0, 0))],
               [(s * x, 0.05, 1.418)], 0.019, ["Cuero"], thick=0.003, hem=0.0018, hem_material="Cuero")
    tailor("Kira_Guante" + sx, [((s * 0.615, 0, 0), (-s, 0, 0)), ((s * 0.735, 0, 0), (s, 0, 0))],
           [(s * 0.67, 0.05, 1.418)], 0.003, ["Negro"], thick=0.002, hem=0.003)


def boot_color(p, n):
    if p.z < 0.022:
        return "Cuero"  # suela
    if p.y < -0.085 and p.z < 0.09:
        return "Verde"  # puntera
    return "Negro"


BOOT_SEEDS = [(0.11, 0.0, 0.2), (-0.11, 0.0, 0.2)]
tailor("Kira_Botas", [((0, 0, 0.30), (0, 0, 1)), ((0, 0, 0.07), (0, 0, -1))], BOOT_SEEDS, 0.009, ["Negro"], thick=0.005,
       hem=0.004, seams=[(0.111, 0.08, 0.29, 1), (-0.111, 0.08, 0.29, 1)], seam_material="VerdeOscuro")
# Pie de la bota: envolvente del pie (sin dedos marcados), redondeada
for side in (1, -1):
    pts = [p for p in BV if p.z < 0.12 and side * p.x > 0.02 and abs(p.x) < 0.25]
    cen = sum(pts, Vector()) / len(pts)
    bm = bmesh.new()
    for p in pts:
        q = p + (p - cen) * 0.12
        bm.verts.new((q.x, q.y, max(q.z, -0.012)))
    bmesh.ops.convex_hull(bm, input=bm.verts)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.004)
    me = bpy.data.meshes.new("Kira_BotaPie")
    bm.to_mesh(me)
    bm.free()
    foot = bpy.data.objects.new("Kira_BotaPie", me)
    KIRA.objects.link(foot)
    sub = foot.modifiers.new("suave", "SUBSURF")
    sub.levels = 2
    apply_modifiers(foot, keep=())
    set_materials(foot, ["Negro", "Verde", "Cuero"], boot_color)
    for p in foot.data.polygons:
        p.use_smooth = True
    transfer_weights(foot)
    add_armature(foot)
tailor("Kira_BotasPuno", [((0, 0, 0.322), (0, 0, 1)), ((0, 0, 0.262), (0, 0, -1))],
       [(0.11, 0.0, 0.29), (-0.11, 0.0, 0.29)], 0.02, ["Verde"], thick=0.006,
       folds=lambda p, n: 0.005 * math.sin((p.z - 0.262) / 0.06 * math.pi), hem=0.004, hem_material="VerdeOscuro")
tailor("Kira_BotasCorrea", [((0, 0, 0.125), (0, 0, 1)), ((0, 0, 0.105), (0, 0, -1))],
       [(0.11, 0.0, 0.115), (-0.11, 0.0, 0.115)], 0.017, ["Cuero"], thick=0.003, hem=0.0016, hem_material="Cuero", smooth=6)


# Armadura: placas delante de rodilla y espinilla, con borde de bronce
def plate_shape(lo, hi):
    """Placa abombada en el centro y con el borde algo levantado."""
    mid = (lo + hi) / 2
    return lambda p, n: 0.006 * max(0.0, 1 - abs(p.z - mid) / ((hi - lo) / 2)) * max(0.0, -n.y)


# Rodilleras y espinilleras: placas lisas de metal con ribete de bronce, solo por delante
tailor("Kira_Rodilleras", [((0, 0, 0.465), (0, 0, -1)), ((0, 0, 0.62), (0, 0, 1)), ((0, 0.035, 0), (0, 1, 0))],
       [(0.11, -0.1, 0.54), (-0.11, -0.1, 0.54)], 0.02, ["Metal"], thick=0.006, folds=plate_shape(0.465, 0.62),
       hem=0.004, hem_material="Bronce")
tailor("Kira_Espinilleras", [((0, 0, 0.15), (0, 0, -1)), ((0, 0, 0.43), (0, 0, 1)), ((0, 0.06, 0), (0, 1, 0))],
       [(0.11, -0.1, 0.3), (-0.11, -0.1, 0.3)], 0.024, ["Metal"], thick=0.005, folds=plate_shape(0.15, 0.43),
       hem=0.004, hem_material="Bronce")

# Cinturones: tiras de cuero con canto cosido, uno recto y otro cruzado hacia la cadera derecha
TILT = Vector((0.10, 0, 1)).normalized()
for name, planes, seed, off in (
        ("Kira_Cinturon", [((0, 0, 0.958), (0, 0, -1)), ((0, 0, 0.99), (0, 0, 1)), ((0, 0.05, 0), (0, 1, 0))],
         (0, -0.12, 0.975), 0.02),
        ("Kira_Cinturon2", [((0, 0, 0.925), -TILT), ((0, 0, 0.951), TILT), ((0, 0.05, 0), (0, 1, 0))],
         (0, -0.12, 0.938), 0.03)):
    tailor(name, planes, [seed], off, ["Cuero"], thick=0.005, hem=0.0022, hem_material="Cuero", smooth=14)


def buckle(name, center, normal, w=0.042, h=0.034, bar=0.0055):
    """Hebilla: marco de bronce con pasador, orientada a la superficie."""
    out = normal.normalized()
    side = Vector((0, 0, 1)).cross(out).normalized()
    up = out.cross(side).normalized()
    bm = bmesh.new()
    for cx, cy, sx_, sy_ in ((0, h / 2, w, bar), (0, -h / 2, w, bar), (w / 2, 0, bar, h), (-w / 2, 0, bar, h),
                             (0, 0, bar * 0.6, h * 0.9)):
        res = bmesh.ops.create_cube(bm, size=1.0)
        for v in res["verts"]:
            local = Vector((v.co.x * sx_, v.co.y * sy_, v.co.z * bar))
            v.co = center + side * (cx + local.x) + up * (cy + local.y) + out * (local.z + bar * 0.6)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    KIRA.objects.link(ob)
    me.materials.append(MATS["Bronce"])
    b = ob.modifiers.new("bisel", "BEVEL")
    b.width = 0.001
    b.segments = 2
    apply_modifiers(ob, keep=())
    transfer_weights(ob)
    add_armature(ob)


deps = bpy.context.evaluated_depsgraph_get()
for belt_name, x, z in (("Kira_Cinturon", 0.0, 0.974), ("Kira_Cinturon2", -0.09, 0.938 + 0.10 * 0.09)):
    bo = bpy.data.objects[belt_name]
    bvh = BVHTree.FromObject(bo, deps)
    inv = bo.matrix_world.inverted()
    hit = bvh.ray_cast(inv @ Vector((x, -1.0, z)), (inv.to_3x3() @ Vector((0, 1, 0))).normalized())
    if hit[0] is not None:
        buckle(belt_name + "_Hebilla", bo.matrix_world @ hit[0], (bo.matrix_world.to_3x3() @ hit[1]).normalized())
        print("RESULT hebilla", belt_name, flush=True)

# ---------------------------------------------------------------- bufanda
nx0, nx1, ny0, ny1 = section(1.49, lambda p: abs(p.x) < 0.1)
ncx, ncy = (nx1 + nx0) / 2, (ny0 + ny1) / 2
RX, RY = (nx1 - nx0) / 2 + 0.03, (ny1 - ny0) / 2 + 0.03
TURNS, N, RING = 1.75, 180, 14
scarf_verts, scarf_faces = [], []
UP = Vector((0, 0, 1))
for i in range(N + 1):
    t = i / N
    a = 2 * math.pi * TURNS * t + 0.5
    grow = 1 + 0.3 * t  # la vuelta de fuera es mas holgada
    z = 1.425 + 0.05 * t + 0.006 * math.sin(a * 3)
    c = Vector((math.sin(a) * RX * grow + ncx, -math.cos(a) * RY * grow + ncy, z))
    out = Vector((math.sin(a), -math.cos(a), 0))
    e = min(1.0, t * 7, (1 - t) * 7)
    w = 0.062 * (0.3 + 0.7 * e) * (1 + 0.12 * math.sin(a * 5 + 1))
    h = 0.02 * (0.4 + 0.6 * e)
    tw = 0.18 * math.sin(a * 2.5) + 0.22  # rollo grueso de tela, algo vencido hacia fuera, con pliegues
    da = UP * math.cos(tw) + out * math.sin(tw)
    db = out * math.cos(tw) - UP * math.sin(tw)
    for k in range(RING):
        b = 2 * math.pi * k / RING
        scarf_verts.append(c + da * math.cos(b) * w + db * (math.sin(b) * h + 0.004 * math.sin(b * 2)))
for i in range(N):
    for k in range(RING):
        k2 = (k + 1) % RING
        scarf_faces.append((i * RING + k, (i + 1) * RING + k, (i + 1) * RING + k2, i * RING + k2))
scarf_faces.append(tuple(range(RING - 1, -1, -1)))
scarf_faces.append(tuple(range(N * RING, N * RING + RING)))
scarf = mesh_obj("Kira_Bufanda", scarf_verts, scarf_faces, ["Verde"])
sub = scarf.modifiers.new("suave", "SUBSURF")
sub.levels = 1
apply_modifiers(scarf, keep=())
for p in scarf.data.polygons:
    p.use_smooth = True
weight_all(scarf, [("neck_01", lambda p: 0.5), ("spine_03", lambda p: 0.5)])
add_armature(scarf)

# ---------------------------------------------------------------- pelo
# Mechones con seccion de lente (anchos, finos en los bordes y curvados hacia la cabeza), que nacen
# finos, se ensanchan y acaban en punta. Los del craneo siguen la superficie de la cabeza hasta la coleta.
mat("PeloOscuro", "#1f6a2c", 0.55)
MATS["Pelo"].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.45


def catmull(points, steps=6):
    pts = [points[0]] + points + [points[-1]]
    out = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for s in range(steps):
            t = s / steps
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                              + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t))
    out.append(points[-1])
    return out


HAIR_V, HAIR_F, HAIR_M = [], [], []


def lock(ctrl, width, thick, out_fn, dark=False, curl=0.35, root=0.3, sides=10, steps=6, power=0.9):
    """Mechon: seccion de lente que se curva hacia la cabeza (curl); nace con `root` del ancho y acaba en punta."""
    path = catmull([Vector(c) for c in ctrl], steps)
    n = len(path)
    start = len(HAIR_V)
    for i, p in enumerate(path):
        t = (path[min(i + 1, n - 1)] - path[max(i - 1, 0)]).normalized()
        out = out_fn(p)
        out = (out - t * out.dot(t)).normalized()
        side = t.cross(out).normalized()
        f = i / (n - 1)
        shape = min(1.0, root + f * 5) * (1 - f) ** power
        w, th = width * shape, thick * max(shape, 0.15)
        for k in range(sides):
            b = 2 * math.pi * k / sides
            cx = math.cos(b)
            HAIR_V.append(p + side * cx * w + out * (math.sin(b) * th - curl * cx * cx * w * 0.35))
    for i in range(n - 1):
        for k in range(sides):
            a0 = start + i * sides + k
            a1 = start + i * sides + (k + 1) % sides
            HAIR_F.append((a0, a0 + sides, a1 + sides, a1))
            HAIR_M.append(1 if dark else 0)
    HAIR_F.append(tuple(range(start + sides - 1, start - 1, -1)))
    HAIR_M.append(1 if dark else 0)


def head_point(d, lift):
    d = d.normalized()
    return Vector((HC.x + d.x * (HR.x + lift), HC.y + d.y * (HR.y + lift), HC.z + d.z * (HR.z + lift)))


def head_dir(theta, phi):
    """theta = giro desde delante (rad), phi = altura desde el ecuador (rad)."""
    return Vector((math.sin(theta) * math.cos(phi), -math.cos(theta) * math.cos(phi), math.sin(phi)))


def on_head(theta, phi, lift=0.012):
    return head_point(head_dir(theta, phi), lift)


def from_head(p):
    return Vector(((p.x - HC.x) / HR.x, (p.y - HC.y) / HR.y, (p.z - HC.z) / HR.z)).normalized()


def slerp(a, b, t):
    a, b = a.normalized(), b.normalized()
    ang = math.acos(max(-1.0, min(1.0, a.dot(b))))
    if ang < 1e-4:
        return a
    return (a * math.sin((1 - t) * ang) + b * math.sin(t * ang)) / math.sin(ang)


# Gorro de pelo: el craneo copiado, liso, debajo de todos los mechones
def scalp(p, n):
    if p.z < 1.53:
        return False
    # linea del pelo: alta en la frente, baja por las sienes y la nuca
    line = 1.718 - 0.07 * min(1.0, abs(p.x) / 0.07) - 0.6 * max(0.0, p.y - HEAD_FRONT - 0.03)
    return p.z > line


# Corte limpio con un plano inclinado: alto en la frente y bajando hacia la nuca
cap = tailor("Kira_PeloBase", [((0, HEAD_FRONT, 1.738), (0, -0.75, -1)), ((0, 0, 1.53), (0, 0, -1))],
             [(0, HC.y, HEAD_TOP)], 0.007, ["Pelo"], thick=0.003)
TIE_DIR = head_dir(math.pi, 0.8)
TIE = head_point(TIE_DIR, 0.0) + Vector((0, 0.015, 0.0))

# Craneo: mechones anchos y planos que van de la linea del pelo a la coleta pegados a la cabeza
for i in range(34):
    th = -math.pi * 0.92 + i * (2 * math.pi * 0.92 / 33)
    ph0 = 0.85 if abs(th) < 0.6 else (0.55 if abs(th) < 0.9 else (0.1 if abs(th) < 2.0 else -0.3))
    d0 = head_dir(th, ph0)
    pts = []
    for k in range(9):
        t = k / 8
        lift = 0.010 + 0.008 * math.sin(math.pi * t)
        pts.append(head_point(slerp(d0, TIE_DIR, t * 0.92), lift))
    lock(pts, 0.05, 0.006, from_head, curl=0.6, root=0.6, steps=3, power=0.5)

# Sin flequillo: la frente queda despejada y todo el pelo va peinado hacia la coleta.

# Mechones junto a la cara: bajan por delante de la oreja y se curvan hacia dentro en la punta
for s in (1, -1):
    for k, (low, wid) in enumerate(((1.47, 0.03), (1.52, 0.026))):
        pts = [on_head(s * (0.9 + 0.25 * k), 0.75, 0.012),
               on_head(s * (1.05 + 0.25 * k), 0.25, 0.02),
               Vector((s * (HR.x + 0.02), HC.y - 0.035 + 0.03 * k, 1.60)),
               Vector((s * (HR.x + 0.012), HC.y - 0.05 + 0.03 * k, (1.60 + low) / 2)),
               Vector((s * (HR.x - 0.005), HC.y - 0.06 + 0.03 * k, low))]
        lock(pts, wid, 0.009, lambda p, s=s: Vector((s, -0.35, 0)), curl=0.4, root=0.5)

# Coleta: un haz que sube un poco, se abre y cae por la espalda; capa interior mas oscura
AXIS_Y = TIE.y + 0.17
for layer, (count, rad, wid, dark) in enumerate(((10, 0.6, 0.06, False), (16, 1.0, 0.055, False))):
    for i in range(count):
        ang = 2 * math.pi * (i + 0.5 * layer) / count + random.uniform(-0.12, 0.12)
        c, s_ = math.cos(ang), math.sin(ang)
        r = random.random()
        wave = 0.025 * math.sin(i * 1.9 + layer)
        k_ = rad * (1 + 0.4 * r)
        pts = [TIE + Vector((c * 0.018, 0.0, s_ * 0.014)),
               TIE + Vector((c * 0.03, 0.035, 0.03 + s_ * 0.014)),
               Vector((c * 0.05 * k_, TIE.y + 0.11, TIE.z + 0.025 + s_ * 0.022)),
               Vector((c * 0.075 * k_, TIE.y + 0.19 + 0.05 * s_ * rad, 1.55)),
               Vector((c * 0.085 * k_ + wave, TIE.y + 0.22 + 0.06 * s_ * rad, 1.30)),
               Vector((c * 0.065 * k_ - wave, TIE.y + 0.20 + 0.05 * s_ * rad, 1.08 - 0.08 * r)),
               Vector((c * 0.05 * k_ + wave * 1.6, TIE.y + 0.17 + 0.05 * s_ * rad, 0.90 - 0.12 * r))]
        lock(pts, wid, 0.012, lambda p: Vector((p.x, p.y - AXIS_Y, 0.15)), dark=dark, curl=0.3, root=0.6, power=0.6)

hair = mesh_obj("Kira_Pelo", HAIR_V, HAIR_F, ["Pelo", "PeloOscuro"])
for poly, m in zip(hair.data.polygons, HAIR_M):
    poly.material_index = m
for p in hair.data.polygons:
    p.use_smooth = True
weight_all(hair, [("Head", lambda p: 1.0)])
add_armature(hair)

# Atadura de la coleta
tie_v, tie_f = [], []
for i in range(24):
    a = 2 * math.pi * i / 24
    for k, (dy, rr) in enumerate(((-0.012, 0.028), (0.014, 0.026))):
        tie_v.append(TIE + Vector((math.cos(a) * rr, dy, math.sin(a) * rr * 0.8)))
for i in range(24):
    j = (i + 1) % 24
    tie_f.append((2 * i, 2 * j, 2 * j + 1, 2 * i + 1))
tie = mesh_obj("Kira_Atadura", tie_v, tie_f, ["Bronce"])
sol = tie.modifiers.new("grosor", "SOLIDIFY")
sol.thickness = 0.006
apply_modifiers(tie, keep=())
weight_all(tie, [("Head", lambda p: 1.0)])
add_armature(tie)

# ---------------------------------------------------------------- tatuaje en ambos hombros
TAT = 64
img = bpy.data.images.new("T_Kira_Tatuaje", TAT, TAT, alpha=True)
px = [0.0] * (TAT * TAT * 4)
green = srgb("#3fbf5f")


def dot(x, y):
    if 0 <= x < TAT and 0 <= y < TAT:
        i = (y * TAT + x) * 4
        px[i:i + 4] = [green[0], green[1], green[2], 1.0]


def line(a, b):
    steps = int(max(abs(b[0] - a[0]), abs(b[1] - a[1]))) + 1
    for s in range(steps + 1):
        x = round(a[0] + (b[0] - a[0]) * s / steps)
        y = round(a[1] + (b[1] - a[1]) * s / steps)
        for dx in (0, 1):
            for dy in (0, 1):
                dot(x + dx, y + dy)


# Rombo con un rombo inscrito y trazos que bajan: dibujo geometrico propio
for a, b in (((32, 58), (54, 36)), ((54, 36), (32, 14)), ((32, 14), (10, 36)), ((10, 36), (32, 58)),
             ((32, 48), (44, 36)), ((44, 36), (32, 24)), ((32, 24), (20, 36)), ((20, 36), (32, 48)),
             ((32, 14), (32, 4)), ((24, 8), (40, 8)), ((10, 36), (4, 36)), ((54, 36), (60, 36))):
    line(a, b)
img.pixels = px
img.pack()
tm = bpy.data.materials.new("M_Kira_Tatuaje")
tm.diffuse_color = green
tn = tm.node_tree
tb = tn.nodes["Principled BSDF"]
ti = tn.nodes.new("ShaderNodeTexImage")
ti.image = img
ti.interpolation = "Closest"
tn.links.new(ti.outputs["Color"], tb.inputs["Base Color"])
tn.links.new(ti.outputs["Alpha"], tb.inputs["Alpha"])
if hasattr(tm, "surface_render_method"):
    tm.surface_render_method = "DITHERED"
MATS["Tatuaje"] = tm
tat = garment("Kira_Tatuajes", lambda p, n: 0.17 <= abs(p.x) <= 0.31 and 1.36 <= p.z <= 1.50 and n.z > -0.3 and n.y > -0.6, 0.0012, ["Tatuaje"])
uv = tat.data.uv_layers.active
mw = tat.matrix_world
for poly in tat.data.polygons:
    for li in poly.loop_indices:
        p = mw @ tat.data.vertices[tat.data.loops[li].vertex_index].co
        uv.data[li].uv = ((abs(p.x) - 0.17) / 0.12, (p.z - 1.37) / 0.12)

# ---------------------------------------------------------------- acabado de falda y capa
CAPE_W = [("spine_03", lambda p: min(1, max(0, (p.z - 1.0) / 0.4))),
          ("spine_01", lambda p: 1 - min(1, max(0, (p.z - 1.0) / 0.4)))]


def cloth_finish(ob, outer, inner, thick, hem_r, hem_mat, weights=None):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.transform(ob.matrix_world)
    bm.normal_update()
    paths = [[(v.co.copy(), v.normal.copy()) for v in loop] for loop in boundary_loops(bm)]
    bm.free()
    set_materials(ob, [outer, inner])
    sol = ob.modifiers.new("grosor", "SOLIDIFY")
    sol.thickness = thick
    sol.offset = 0.0
    sol.material_offset = 1
    sub = ob.modifiers.new("suave", "SUBSURF")
    sub.levels = 1
    apply_modifiers(ob, keep=())
    for p in ob.data.polygons:
        p.use_smooth = True
    ob.vertex_groups.remove(ob.vertex_groups["pin"])
    if weights:
        weight_all(ob, weights)
    else:
        transfer_weights(ob)
    add_armature(ob)
    tube_mesh(ob.name + "_Dobladillo", paths, hem_r, hem_mat, shift=0.0, weights=weights)


cloth_finish(skirt, "Verde", "Forro", 0.006, 0.0035, "VerdeOscuro")
cloth_finish(cape, "Verde", "VerdeOscuro", 0.008, 0.0045, "VerdeOscuro", CAPE_W)

# Runas verde claro en la capa, en columna, como en la referencia
rune = bpy.data.materials.new("M_Kira_Runa")
rune.diffuse_color = srgb("#9fe07c")
rn = rune.node_tree
rb = rn.nodes["Principled BSDF"]
rb.inputs["Base Color"].default_value = srgb("#9fe07c")
ri = rn.nodes.new("ShaderNodeTexImage")
ri.image = img
ri.interpolation = "Closest"
rn.links.new(ri.outputs["Alpha"], rb.inputs["Alpha"])
if hasattr(rune, "surface_render_method"):
    rune.surface_render_method = "DITHERED"
MATS["Runa"] = rune
deps = bpy.context.evaluated_depsgraph_get()
cape_bvh = BVHTree.FromObject(cape, deps)
rv, rf, ruv = [], [], []
for k, (x, z) in enumerate(((0.17, 0.98), (0.16, 0.82), (0.15, 0.66))):
    hit = cape_bvh.ray_cast(Vector((x, 2.0, z)), Vector((0, -1, 0)))
    if hit[0] is None:
        continue
    pnt, nrm = hit[0], hit[1] if hit[1].y > 0 else -hit[1]
    side = UP.cross(nrm).normalized()
    up = nrm.cross(side).normalized()
    base = len(rv)
    for cu, cv in ((0, 0), (1, 0), (1, 1), (0, 1)):
        rv.append(pnt + nrm * 0.006 + side * (cu - 0.5) * 0.1 + up * (cv - 0.5) * 0.1)
        ruv.append((1 - cu, cv))
    rf.append((base, base + 1, base + 2, base + 3))
runes = mesh_obj("Kira_Runas", rv, rf, ["Runa"])
uvl = runes.data.uv_layers.new(name="UV")
for poly in runes.data.polygons:
    for li in poly.loop_indices:
        uvl.data[li].uv = ruv[runes.data.loops[li].vertex_index]
weight_all(runes, CAPE_W)
add_armature(runes)

# Hebillas de las correas de las botas, por fuera
for s in (1, -1):
    strap = bpy.data.objects["Kira_BotasCorrea"]
    bvh = BVHTree.FromObject(strap, deps)
    hit = bvh.ray_cast(Vector((s * 1.0, 0.0, 0.115)), Vector((-s, 0, 0)))
    if hit[0] is not None:
        buckle("Kira_BotaHebilla", hit[0], hit[1], w=0.024, h=0.02, bar=0.0035)

# ---------------------------------------------------------------- borrar piel tapada
# La piel bajo la ropa se quita: asi no asoma al doblar articulaciones.
def covered(p):
    if 0.97 <= p.z <= 1.44 and abs(p.x) < 0.11 and not (p.y < -0.02 and p.z > 1.30):
        return True
    if leg(p) and 0.14 <= p.z <= 0.94:
        return not (0.70 < p.z < 0.82)
    if leg(p) and p.z < 0.29:
        return True
    if 0.49 <= abs(p.x) <= 0.70 and p.z > 1.3:
        return True
    return False


bm = bmesh.new()
bm.from_mesh(body.data)
bm.verts.ensure_lookup_table()
dead = [f for f in bm.faces if all(covered(BV[v.index]) for v in f.verts)]
bmesh.ops.delete(bm, geom=dead, context="FACES")
bm.to_mesh(body.data)
bm.free()
print("RESULT caras de piel quitadas", len(dead), flush=True)

# ---------------------------------------------------------------- espada (opcion B)
def prism(name, outline, half, material, bevel=0.0015):
    n = len(outline)
    verts = [(-half, y, z) for y, z in outline] + [(half, y, z) for y, z in outline]
    faces = [tuple(range(n))[::-1], tuple(range(n, 2 * n))] + [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
    ob = mesh_obj(name, verts, faces, [material], SWORD)
    if bevel:
        b = ob.modifiers.new("bisel", "BEVEL")
        b.width = bevel
        b.segments = 2
        apply_modifiers(ob, keep=())
    return ob


parts = [
    prism("Espada_Filo", [(-0.09, -0.032), (-0.79, -0.032), (-0.87, 0.0), (-0.79, 0.032), (-0.09, 0.032)], 0.005, "Energia"),
    prism("Espada_Hoja", [(-0.09, -0.021), (-0.78, -0.021), (-0.825, 0.0), (-0.78, 0.021), (-0.09, 0.021)], 0.008, "Metal"),
    prism("Espada_Linea", [(-0.17, -0.003), (-0.72, -0.003), (-0.72, 0.003), (-0.17, 0.003)], 0.0088, "Bronce", 0.0),
    prism("Espada_Rombo", [(-0.115, 0.0), (-0.13, -0.012), (-0.145, 0.0), (-0.13, 0.012)], 0.009, "Energia", 0.0),
    prism("Espada_Guarda", [(-0.075, -0.075), (-0.097, -0.05), (-0.097, 0.05), (-0.075, 0.075), (-0.066, 0.0)], 0.017, "Metal"),
    prism("Espada_GuardaBorde", [(-0.073, -0.079), (-0.077, -0.079), (-0.068, 0.0), (-0.077, 0.079), (-0.073, 0.079), (-0.064, 0.0)], 0.018, "Bronce", 0.0),
]
grip_v, grip_f = [], []
for k in range(14):
    y = -0.066 + k * 0.01
    r = 0.0145 + 0.0015 * (k % 2)
    for i in range(12):
        a = 2 * math.pi * i / 12
        grip_v.append((math.cos(a) * r, y, math.sin(a) * r))
for k in range(13):
    for i in range(12):
        j = (i + 1) % 12
        grip_f.append((k * 12 + i, k * 12 + j, (k + 1) * 12 + j, (k + 1) * 12 + i))
parts.append(mesh_obj("Espada_Puno", grip_v, grip_f, ["Cuero"], SWORD))
bm = bmesh.new()
bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=0.021)
for v in bm.verts:
    v.co.y += 0.085
me = bpy.data.meshes.new("Espada_Pomo")
bm.to_mesh(me)
bm.free()
pommel = bpy.data.objects.new("Espada_Pomo", me)
SWORD.objects.link(pommel)
me.materials.append(MATS["Bronce"])
parts.append(pommel)
for ob in parts:
    for p in ob.data.polygons:
        p.use_smooth = ob.name in ("Espada_Puno", "Espada_Pomo")
select_only(parts[0])
for ob in parts:
    ob.select_set(True)
bpy.ops.object.join()
sword = bpy.context.view_layer.objects.active
sword.name = "Kira_Espada"
# Empunadura en la palma derecha, hoja hacia delante; colgada del hueso de la mano
hand = arm.data.bones["hand_r"]
grip_at = arm.matrix_world @ (hand.head_local + (hand.tail_local - hand.head_local) * 2.2) + Vector((0, -0.005, -0.012))
sword.location = grip_at
sword.parent = arm
sword.parent_type = "BONE"
sword.parent_bone = "hand_r"
sword.matrix_world = Matrix.Translation(grip_at)

# ---------------------------------------------------------------- medidas, guardado y vistas
bpy.context.view_layer.update()
deps = bpy.context.evaluated_depsgraph_get()
zs, xs, tris = [], [], 0
for ob in KIRA.objects:
    ev = ob.evaluated_get(deps)
    me = ev.to_mesh()
    for v in me.vertices:
        w = ob.matrix_world @ v.co
        zs.append(w.z)
        xs.append(w.x)
    tris += sum(len(p.vertices) - 2 for p in me.polygons)
    ev.to_mesh_clear()
print("RESULT medidas z %.3f..%.3f x %.3f..%.3f triangulos %d" % (min(zs), max(zs), min(xs), max(xs), tris), flush=True)
os.makedirs(os.path.join(OUT, "capturas"), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "kira.blend"))

items = [i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in items else "BLENDER_EEVEE_NEXT"
scene.world = bpy.data.worlds.new("fondo")
scene.world.use_nodes = True
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
scene.render.resolution_x, scene.render.resolution_y = 700, 800
cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
VIEWS = (("frente", 0, 2.0, 0.89), ("tres_cuartos", 40, 2.0, 0.89), ("perfil", 90, 2.0, 0.89),
         ("espalda", 180, 2.0, 0.89), ("cara", 25, 0.5, HEAD_TOP - 0.12), ("detalle", 35, 0.75, 1.13),
         ("piernas", 30, 0.8, 0.45))
for view, ang, scale, z in VIEWS:
    a = math.radians(ang)
    cam.location = (6 * math.sin(a), -6 * math.cos(a), z)
    cam.rotation_euler = (math.radians(90), 0, a)
    cam_data.ortho_scale = scale
    scene.render.filepath = os.path.join(OUT, "capturas", "kira_%s.png" % view)
    bpy.ops.render.render(write_still=True)
    print("RESULT vista", view, flush=True)
# Tamano real en el juego (unos 113 px de alto), girada como en Avatar3D (68 grados)
scene.render.resolution_x, scene.render.resolution_y = 130, 150
a = math.radians(68)
cam.location = (6 * math.sin(a), -6 * math.cos(a), 0.89)
cam.rotation_euler = (math.radians(90), 0, a)
cam_data.ortho_scale = 2.0
scene.render.filepath = os.path.join(OUT, "capturas", "kira_juego.png")
bpy.ops.render.render(write_still=True)
