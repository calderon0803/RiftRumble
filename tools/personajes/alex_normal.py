"""Álex personalizable en 3D: cuerpo de Quaternius + ropa, calzado y peinados de MakeHuman (todo CC0).

blender -b --factory-startup -P alex_normal.py -- <pack de cuerpos> <carpeta extraida de MakeHuman> <UAL1_Standard.glb>
                                               <alex.glb antiguo> <salida.glb> [vistas]

Una malla por opcion de la personalizacion, con el nombre que espera Avatar3D: «peinado_N», «arriba_N»,
«abajo_N», «calzado_N» (N = indice en Data.LOOK_OPTIONS). El cuerpo es «cuerpo» y los ojos «ojos».
Los materiales se llaman como el color que los tine en el juego («piel», «pelo», «ropa», «pantalon»):
sus texturas van en gris para que el color elegido las multiplique. El calzado conserva su color.

La ropa de MakeHuman esta hecha en postura en A y para otro cuerpo. Para cada prenda: el cuerpo de Álex se
pone en esa postura, un cuerpo de MakeHuman la lleva puesta y se ajusta a la forma de Álex (la prenda lo
sigue con «Surface Deform»), se separa unos milimetros de la piel, toma los pesos del cuerpo y se devuelve
a la postura en T deshaciendo el esqueleto vertice a vertice.
"""
import glob
import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from animaciones_ual import anadir_animaciones  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:]
BODIES, MH, UAL, OLD, OUT = args[:5]
VIEWS = args[5] if len(args) > 5 else None
HEIGHT = 1.72
TEX_DIR = os.path.join(os.path.dirname(OUT), "fuentes", "texturas")
os.makedirs(TEX_DIR, exist_ok=True)

# Opciones, en el orden de Data.LOOK_OPTIONS
PEINADOS = [("mh", "short02"), ("mh", "long01"), ("ubc", "Hair_Buzzed"), ("mh", "ponytail01"),
            ("mh", "short01"), ("mh", "afro01"), ("mh", "rehmanpolanski_hair_bun_brown")]
ARRIBA = [("male_casualsuit02", None), ("male_casualsuit06", None), ("male_casualsuit05", None),
          ("male_casualsuit06", "tirantes"), ("male_casualsuit03", None)]
ABAJO = [("male_casualsuit02", None), ("male_casualsuit02", "corto"), ("male_casualsuit04", "liso")]
CALZADO = ["shoes05", "shoes03", "shoes01"]

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def select_only(ob):
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)


def link(ob):
    for c in ob.users_collection:
        c.objects.unlink(ob)
    scene.collection.objects.link(ob)


# ---------------------------------------------------------------- cuerpo
bpy.ops.import_scene.gltf(filepath=os.path.join(BODIES, "Base Characters", "Godot - UE", "Superhero_Male_FullBody.gltf"))
for o in list(scene.objects):
    if o.name.startswith("Icosphere"):
        bpy.data.objects.remove(o)
arm = next(o for o in scene.objects if o.type == "ARMATURE")
arm.name = "Alex"
body = next(o for o in scene.objects if o.type == "MESH" and o.name.lower().startswith("superhero"))
body.name = "cuerpo"
eyes = next(o for o in scene.objects if o.name.startswith("Eyes"))
eyes.name = "ojos"
brows = next(o for o in scene.objects if o.name.startswith("Eyebrows"))
brows.name = "cejas"
BW = [body.matrix_world @ v.co for v in body.data.vertices]
BODY_TOP = max(p.z for p in BW)


def gray_texture(path, name, keep_alpha=True, flat=None):
    """Textura en gris (media 0,78) para que el color del juego la multiplique."""
    src = bpy.data.images.load(path)
    w, h = src.size
    px = np.array(src.pixels[:], dtype=np.float32).reshape(-1, 4)
    lum = px[:, 0] * 0.3 + px[:, 1] * 0.59 + px[:, 2] * 0.11
    mask = px[:, 3] > 0.5
    mean = float(lum[mask].mean()) if mask.any() else float(lum.mean())
    g = np.clip(lum / max(mean, 1e-3) * 0.78, 0, 1) if flat is None else np.full_like(lum, flat)
    px[:, 0] = px[:, 1] = px[:, 2] = g
    if not keep_alpha:
        px[:, 3] = 1.0
    out = bpy.data.images.new(name, w, h, alpha=True)
    out.pixels.foreach_set(px.ravel())
    if w > 1024:
        out.scale(1024, 1024 * h // w)
    out.filepath_raw = os.path.join(TEX_DIR, name + ".png")
    out.file_format = "PNG"
    out.save()
    out.pack()
    return out


def material(name, image=None, alpha_clip=False):
    m = bpy.data.materials.new(name)
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.8
    if image is not None:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = image
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        if alpha_clip:
            gt = nt.nodes.new("ShaderNodeMath")
            gt.operation = "GREATER_THAN"
            gt.inputs[1].default_value = 0.5
            nt.links.new(tex.outputs["Alpha"], gt.inputs[0])
            nt.links.new(gt.outputs[0], bsdf.inputs["Alpha"])
            if hasattr(m, "surface_render_method"):
                m.surface_render_method = "DITHERED"
    return m


def body_texture_path(kind):
    # la carpeta del pack lleva corchetes: hay que escaparla para glob
    for p in glob.glob(os.path.join(glob.escape(BODIES), "Base Characters", "**", "*.png"), recursive=True):
        if "Male" in p and kind in p and "Female" not in p:
            return p


skin = gray_texture(body_texture_path("Lig"), "T_Alex_Piel")
body.data.materials.clear()
body.data.materials.append(material("piel", skin))
brow_tex = next((n.image for n in bpy.data.materials["MI_Hair_1"].node_tree.nodes if n.type == "TEX_IMAGE" and "Base" in n.image.name), None)
brows.data.materials.clear()
brows.data.materials.append(material("pelo", gray_texture(bpy.path.abspath(brow_tex.filepath), "T_Alex_Cejas") if brow_tex and brow_tex.filepath else None,
                                     alpha_clip=True))
print("RESULT cuerpo", round(BODY_TOP, 3), flush=True)

# ---------------------------------------------------------------- cuerpo en postura en A (la de MakeHuman)
mh_body_obj = glob.glob(os.path.join(MH, "proxymeshes", "male_muscle_13290", "*.obj"))[0]
before = set(bpy.data.objects)
bpy.ops.wm.obj_import(filepath=mh_body_obj)
mh = next(o for o in bpy.data.objects if o not in before)
mh.name = "mh_cuerpo"
select_only(mh)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)  # el importador gira el objeto (Y arriba)
MV = [mh.matrix_world @ v.co for v in mh.data.vertices]
mh_bottom, mh_top = min(p.z for p in MV), max(p.z for p in MV)
S = BODY_TOP / (mh_top - mh_bottom)


def mh_to_alex(p):
    return Vector((p.x * S, p.y * S, (p.z - mh_bottom) * S))


T = Matrix.Translation((0, 0, -mh_bottom * S)) @ Matrix.Scale(S, 4)
mh.matrix_world = T
select_only(mh)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
MV = [v.co.copy() for v in mh.data.vertices]


def torso_center_y(points, height):
    band = [p.y for p in points if 0.55 * height < p.z < 0.75 * height and abs(p.x) < 0.12]
    return (min(band) + max(band)) / 2


DY = torso_center_y(BW, BODY_TOP) - torso_center_y(MV, BODY_TOP)  # el cuerpo de MakeHuman va algo adelantado
T = Matrix.Translation((0, DY, 0)) @ T
for v in mh.data.vertices:
    v.co.y += DY
MV = [v.co.copy() for v in mh.data.vertices]
print("RESULT desplazamiento en profundidad %.3f m" % DY, flush=True)
# Los brazos de MakeHuman bajan y van algo adelantados: el brazo de Álex se gira desde el hombro para
# que la punta de su mano apunte a la punta de la mano de MakeHuman.
for side, sign in (("l", 1), ("r", -1)):
    pb = arm.pose.bones["upperarm_" + side]
    head = arm.matrix_world @ pb.head
    tip_alex = max(BW, key=lambda p: sign * p.x)
    tip_mh = max(MV, key=lambda p: sign * p.x)
    q = (tip_alex - head).rotation_difference(tip_mh - head)
    rot = Matrix.Translation(head) @ q.to_matrix().to_4x4() @ Matrix.Translation(-head)
    pb.matrix = arm.matrix_world.inverted() @ rot @ arm.matrix_world @ pb.matrix
    print("RESULT brazo", side, "girado %.1f grados" % math.degrees(q.angle), flush=True)
bpy.context.view_layer.update()
deps = bpy.context.evaluated_depsgraph_get()
posed_me = bpy.data.meshes.new_from_object(body.evaluated_get(deps), preserve_all_data_layers=True, depsgraph=deps)
body_a = bpy.data.objects.new("cuerpo_A", posed_me)
scene.collection.objects.link(body_a)
for vg in body.vertex_groups:
    body_a.vertex_groups.new(name=vg.name)
body_a.matrix_world = body.matrix_world
SKIN_M = {pb.name: arm.matrix_world @ pb.matrix @ pb.bone.matrix_local.inverted() @ arm.matrix_world.inverted()
          for pb in arm.pose.bones}

# El cuerpo de MakeHuman se ajusta a la forma de Álex (en A): cada vertice va al punto mas cercano de la
# piel de Álex. Ese desplazamiento es el que luego siguen las prendas.
from mathutils.bvhtree import BVHTree  # noqa: E402
from mathutils.interpolate import poly_3d_calc  # noqa: E402

fit = mh.modifiers.new("ajuste", "SHRINKWRAP")
fit.target = body_a
fit.wrap_method = "NEAREST_SURFACEPOINT"
bpy.context.view_layer.update()
deps = bpy.context.evaluated_depsgraph_get()
fit_me = mh.evaluated_get(deps).to_mesh()
MH_FIT = [v.co.copy() for v in fit_me.vertices]
mh.evaluated_get(deps).to_mesh_clear()
mh.modifiers.remove(fit)
MH_POLYS = [tuple(p.vertices) for p in mh.data.polygons]
MH_BVH = BVHTree.FromPolygons(MV, MH_POLYS)
MH_DISP = [MH_FIT[i] - MV[i] for i in range(len(MV))]


def follow_body(piece):
    """Mueve cada vertice de la prenda lo mismo que se movio el punto mas cercano del cuerpo de MakeHuman."""
    for v in piece.data.vertices:
        loc, _n, idx, _d = MH_BVH.find_nearest(v.co)
        if idx is None:
            continue
        poly = MH_POLYS[idx]
        w = poly_3d_calc([MV[i] for i in poly], loc)
        v.co = v.co + sum((MH_DISP[i] * wi for i, wi in zip(poly, w)), Vector())


def import_mh_piece(folder):
    """Importa una prenda de MakeHuman ya colocada sobre Álex en postura en A. Devuelve el objeto."""
    obj = [p for p in glob.glob(os.path.join(folder, "*.obj"))][0]
    before = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=obj)
    new = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    piece = new[0]
    if len(new) > 1:
        select_only(piece)
        for o in new:
            o.select_set(True)
        bpy.ops.object.join()
    select_only(piece)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)  # giro del importador
    piece.matrix_world = T
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if os.environ.get("AJUSTE_CRUDO"):
        return piece
    follow_body(piece)
    sub = piece.modifiers.new("suave", "SUBSURF")  # mas vertices: la piel musculada no asoma entre ellos
    sub.levels = 1
    bpy.ops.object.modifier_apply(modifier=sub.name)
    out = piece.modifiers.new("fuera", "SHRINKWRAP")
    out.target = body_a
    out.wrap_method = "NEAREST_SURFACEPOINT"
    out.wrap_mode = "OUTSIDE"
    out.offset = 0.004
    bpy.ops.object.modifier_apply(modifier=out.name)
    return piece


def texture_of(folder):
    for mhmat in glob.glob(os.path.join(folder, "*.mhmat")):
        for line in open(mhmat, encoding="utf8", errors="ignore"):
            if line.startswith("diffuseTexture"):
                return os.path.join(folder, line.split(None, 1)[1].strip())


def to_t_pose(piece):
    """Pesos del cuerpo en A y vuelta a la postura en T (skinning inverso por vertice)."""
    select_only(piece)
    dt = piece.modifiers.new("pesos", "DATA_TRANSFER")
    dt.object = body_a
    dt.use_vert_data = True
    dt.data_types_verts = {"VGROUP_WEIGHTS"}
    dt.vert_mapping = "POLYINTERP_NEAREST"
    bpy.ops.object.datalayout_transfer(modifier=dt.name)
    bpy.ops.object.modifier_apply(modifier=dt.name)
    names = {g.index: g.name for g in piece.vertex_groups}
    for v in piece.data.vertices:
        M = Matrix(((0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0)))
        total = 0.0
        for g in v.groups:
            bone = names[g.group]
            if bone in SKIN_M and g.weight > 0:
                M = M + SKIN_M[bone] * g.weight
                total += g.weight
        if total > 0:
            v.co = (M * (1.0 / total)).inverted() @ (piece.matrix_world @ v.co)
    piece.parent = arm
    mod = piece.modifiers.new("esqueleto", "ARMATURE")
    mod.object = arm
    link(piece)


def islands(ob):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.verts.ensure_lookup_table()
    seen, groups = set(), []
    for v in bm.verts:
        if v.index in seen:
            continue
        stack, grp = [v], []
        while stack:
            x = stack.pop()
            if x.index in seen:
                continue
            seen.add(x.index)
            grp.append(x.index)
            stack.extend(e.other_vert(x) for e in x.link_edges)
        groups.append(grp)
    bm.free()
    return groups


def keep_only(ob, keep_verts=None, drop_face=None):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.verts.ensure_lookup_table()
    if keep_verts is not None:
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.index not in keep_verts], context="VERTS")
    if drop_face is not None:
        mw = ob.matrix_world
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if drop_face(mw @ f.calc_center_median())], context="FACES")
    bm.to_mesh(ob.data)
    bm.free()


TEXTURES = {}


def debug_render(objs, path):
    """Vista rapida (Workbench) de unos objetos, para comprobar el ajuste en postura en A."""
    hidden = {o: o.hide_render for o in scene.objects}
    for o in scene.objects:
        o.hide_render = o not in objs
    old = scene.render.engine
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "OBJECT"
    for k, o in enumerate(objs):
        o.color = ((0.8, 0.8, 0.8, 1), (0.9, 0.2, 0.2, 1), (0.2, 0.4, 0.9, 1))[min(k, 2)]
    cd = bpy.data.cameras.new("dep")
    cd.type = "ORTHO"
    cd.ortho_scale = 2.1
    cam = bpy.data.objects.new("dep", cd)
    scene.collection.objects.link(cam)
    scene.camera = cam
    for ang, suffix in ((0, "frente"), (90, "lado")):
        a = math.radians(ang)
        cam.location = (6 * math.sin(a), -6 * math.cos(a), 0.9)
        cam.rotation_euler = (math.radians(90), 0, a)
        scene.render.resolution_x = scene.render.resolution_y = 500
        scene.render.filepath = path + "_" + suffix + ".png"
        bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)
    for o, h in hidden.items():
        o.hide_render = h
    scene.render.engine = old


def suit_part(suit, part, name, slot, variant):
    folder = os.path.join(MH, "clothes", suit)
    piece = import_mh_piece(folder)
    if VIEWS and name == "arriba_0":
        os.makedirs(VIEWS, exist_ok=True)
        debug_render([body_a, piece], os.path.join(VIEWS, "ajuste_A"))
        if os.environ.get("SOLO_AJUSTE"):
            raise SystemExit
    groups = islands(piece)
    mw = piece.matrix_world
    zmean = [sum((mw @ piece.data.vertices[i].co).z for i in g) / len(g) for g in groups]
    big = sorted(range(len(groups)), key=lambda k: -len(groups[k]))[:2]
    top_i = max(big, key=lambda k: zmean[k])
    bot_i = min(big, key=lambda k: zmean[k])
    keep_only(piece, set(groups[top_i] if part == "arriba" else groups[bot_i]))
    to_t_pose(piece)
    if variant == "tirantes":  # sin mangas: se quita todo lo que pasa del hombro
        keep_only(piece, drop_face=lambda c: abs(c.x) > 0.165 and c.z > 1.1 * HEIGHT / 1.72)
    if variant == "corto":  # pantalon corto: por encima de la rodilla
        knee = (arm.matrix_world @ arm.data.bones["calf_l"].head_local).z
        keep_only(piece, drop_face=lambda c: c.z < knee + 0.06)
    key = (suit, variant == "liso")
    if key not in TEXTURES:
        TEXTURES[key] = gray_texture(texture_of(folder), "T_Alex_%s%s" % (suit, "_liso" if variant == "liso" else ""),
                                     keep_alpha=False, flat=0.8 if variant == "liso" else None)
    piece.data.materials.clear()
    piece.data.materials.append(material(slot, TEXTURES[key]))
    piece.name = name
    for p in piece.data.polygons:
        p.use_smooth = True
    print("RESULT pieza", name, suit, variant or "", len(piece.data.vertices), flush=True)


for i, (suit, variant) in enumerate(ARRIBA):
    suit_part(suit, "arriba", "arriba_%d" % i, "ropa", variant)
for i, (suit, variant) in enumerate(ABAJO):
    suit_part(suit, "abajo", "abajo_%d" % i, "pantalon", variant)
for i, shoe in enumerate(CALZADO):
    folder = os.path.join(MH, "clothes", shoe)
    piece = import_mh_piece(folder)
    to_t_pose(piece)
    img = bpy.data.images.load(texture_of(folder))
    if img.size[0] > 1024:
        img.scale(1024, 1024 * img.size[1] // img.size[0])
    img.pack()
    piece.data.materials.clear()
    piece.data.materials.append(material("calzado", img))
    piece.name = "calzado_%d" % i
    for p in piece.data.polygons:
        p.use_smooth = True
    print("RESULT pieza", piece.name, shoe, len(piece.data.vertices), flush=True)

# Piernas: con pantalon largo no se ven nunca, y la piel musculada asomaria entre la tela. Salen del cuerpo
# y la parte que queda a la vista bajo el pantalon corto pasa a formar parte de esa pieza (abajo_1).
# Los pies (siempre dentro del calzado) se quitan.
mwb = body.matrix_world
SPLIT = (arm.matrix_world @ arm.data.bones["thigh_l"].head_local).z + 0.03
KNEE = (arm.matrix_world @ arm.data.bones["calf_l"].head_local).z
FOOT_TOP = 0.09 * BODY_TOP / 1.81


def body_faces(cond):
    """Copia del cuerpo (con sus pesos) que solo conserva las caras cuyos vertices cumplen cond(z)."""
    ob = body.copy()
    ob.data = body.data.copy()
    scene.collection.objects.link(ob)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if not all(cond((mwb @ v.co).z) for v in f.verts)], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(ob.data)
    bm.free()
    return ob


legs = body_faces(lambda z: FOOT_TOP <= z < KNEE + 0.09)  # bajo el pantalon corto, con un poco de solape
shorts = bpy.data.objects["abajo_1"]
select_only(shorts)
legs.select_set(True)
bpy.ops.object.join()
bpy.ops.object.mode_set(mode="OBJECT")
bm = bmesh.new()
bm.from_mesh(body.data)
bmesh.ops.delete(bm, geom=[f for f in bm.faces if all((mwb @ v.co).z < SPLIT for v in f.verts)], context="FACES")
bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
bm.to_mesh(body.data)
bm.free()
print("RESULT piernas: fuera del cuerpo por debajo de %.2f m; piel de pierna en abajo_1" % SPLIT, flush=True)

# Torso y brazos: igual que las piernas, pero cada prenda de arriba deja ver una parte distinta (los tirantes,
# los brazos; la chaqueta abierta, el pecho). El cuerpo se queda con cabeza, cuello y manos, y cada prenda
# lleva dentro la piel que queda a la vista con ella puesta.
from mathutils.bvhtree import BVHTree as _BVH  # noqa: E402

NECK_Z = (arm.matrix_world @ arm.data.bones["neck_01"].head_local).z + 0.02
HAND_X = (arm.matrix_world @ arm.data.bones["hand_l"].head_local).x - 0.015


def upper_region(p):
    return SPLIT - 0.01 <= p.z < NECK_Z and abs(p.x) < HAND_X


bm = bmesh.new()
bm.from_mesh(body.data)
bm.verts.ensure_lookup_table()
bm.normal_update()
BVERTS = [(mwb @ v.co, (mwb.to_3x3() @ v.normal).normalized()) for v in bm.verts]
REGION_FACES = [f.index for f in bm.faces if all(upper_region(BVERTS[v.index][0]) for v in f.verts)]
FACE_VERTS = {f.index: [v.index for v in f.verts] for f in bm.faces}
VERT_FACES = {}
for fi, vs in FACE_VERTS.items():
    for vi in vs:
        VERT_FACES.setdefault(vi, []).append(fi)
bm.free()

for i in range(len(ARRIBA)):
    top = bpy.data.objects["arriba_%d" % i]
    tw = top.matrix_world
    tree = _BVH.FromPolygons([tw @ v.co for v in top.data.vertices], [tuple(p.vertices) for p in top.data.polygons])
    # Brazos: si la manga llega a esa altura del brazo (tramo de 1 cm a lo largo de x), la piel de ahi
    # se quita entera; si no, al doblar el codo la piel atravesaria la tela.
    sleeve = {(1 if w.x > 0 else -1, round(abs(w.x) / 0.01)) for w in (tw @ v.co for v in top.data.vertices) if abs(w.x) > 0.18}
    covered = set()
    for fi in REGION_FACES:
        for vi in FACE_VERTS[fi]:
            if vi in covered:
                continue
            p, n = BVERTS[vi]
            if abs(p.x) > 0.2:
                if (1 if p.x > 0 else -1, round(abs(p.x) / 0.01)) in sleeve:
                    covered.add(vi)
            elif tree.find_nearest(p, 0.035)[0] is not None or tree.ray_cast(p - n * 0.005, n, 0.10)[0] is not None:
                covered.add(vi)  # torso: la prenda pasa cerca, o justo delante aunque vaya holgada
    # Se queda la cara con algun vertice a la vista: las que quedan a medio tapar ya hacen de solape
    keep = {fi for fi in REGION_FACES if not all(vi in covered for vi in FACE_VERTS[fi])}
    if keep:
        skin_ob = body.copy()
        skin_ob.data = body.data.copy()
        scene.collection.objects.link(skin_ob)
        sbm = bmesh.new()
        sbm.from_mesh(skin_ob.data)
        sbm.faces.ensure_lookup_table()
        bmesh.ops.delete(sbm, geom=[f for f in sbm.faces if f.index not in keep], context="FACES")
        bmesh.ops.delete(sbm, geom=[v for v in sbm.verts if not v.link_faces], context="VERTS")
        sbm.to_mesh(skin_ob.data)
        sbm.free()
        select_only(top)
        skin_ob.select_set(True)
        bpy.ops.object.join()
    print("RESULT piel bajo arriba_%d: %d caras visibles" % (i, len(keep)), flush=True)

bm = bmesh.new()
bm.from_mesh(body.data)
bm.faces.ensure_lookup_table()
region = set(REGION_FACES)
bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index in region], context="FACES")
bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
bm.to_mesh(body.data)
bm.free()

# ---------------------------------------------------------------- peinados (en postura en T, sobre la cabeza)
head = [p for p in BW if p.z > BODY_TOP - 0.24]
H_X = max(abs(p.x) for p in head if p.z > BODY_TOP - 0.16)
H_FRONT = min(p.y for p in head if p.z > BODY_TOP - 0.16 and abs(p.x) < 0.03)
H_BACK = max(p.y for p in head if p.z > BODY_TOP - 0.16 and abs(p.x) < 0.03)
for i, (kind, name) in enumerate(PEINADOS):
    before = set(bpy.data.objects)
    if kind == "ubc":
        bpy.ops.import_scene.gltf(filepath=os.path.join(BODIES, "Hairstyles", "Origin at 0", "glTF (Godot)", name + ".gltf"))
        new = [o for o in bpy.data.objects if o not in before]
        hair = next(o for o in new if o.type == "MESH")
        for o in new:
            if o != hair:
                bpy.data.objects.remove(o)
        hair.parent = None
        tex_img = next((n.image for n in hair.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE" and "Base" in n.image.name), None)
        tex_path = bpy.path.abspath(tex_img.filepath) if tex_img else None
        select_only(hair)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    else:
        folder = os.path.join(MH, "hair", name)
        bpy.ops.wm.obj_import(filepath=glob.glob(os.path.join(folder, "*.obj"))[0])
        hair = next(o for o in bpy.data.objects if o not in before and o.type == "MESH")
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
        hair.location = Vector((0, (H_FRONT + H_BACK) / 2 + 0.005 - cy, BODY_TOP + 0.012 - top))
        bpy.ops.object.transform_apply(location=True)
        tex_path = texture_of(folder)
    sw = hair.modifiers.new("fuera", "SHRINKWRAP")
    sw.target = body
    sw.wrap_method = "NEAREST_SURFACEPOINT"
    sw.wrap_mode = "OUTSIDE"
    sw.offset = 0.004
    bpy.ops.object.modifier_apply(modifier=sw.name)
    hair.data.materials.clear()
    hair.data.materials.append(material("pelo", gray_texture(tex_path, "T_Alex_Pelo_%d" % i) if tex_path else None, alpha_clip=True))
    for vg in list(hair.vertex_groups):
        hair.vertex_groups.remove(vg)
    vg = hair.vertex_groups.new(name="Head")
    vg.add(list(range(len(hair.data.vertices))), 1.0, "REPLACE")
    hair.parent = arm
    mod = hair.modifiers.new("esqueleto", "ARMATURE")
    mod.object = arm
    hair.name = "peinado_%d" % i
    link(hair)
    for p in hair.data.polygons:
        p.use_smooth = True
    print("RESULT pieza", hair.name, name, len(hair.data.vertices), flush=True)

# ---------------------------------------------------------------- limpieza, animaciones y exportacion
for pb in arm.pose.bones:
    pb.matrix_basis = Matrix.Identity(4)
for o in (mh, body_a):
    bpy.data.objects.remove(o)
anadir_animaciones(arm, UAL, OLD)
f = HEIGHT / BODY_TOP
arm.scale = (f, f, f)
bpy.ops.object.select_all(action="DESELECT")
for o in scene.objects:
    if o == arm or (o.parent == arm and o.type == "MESH"):
        o.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_animations=True,
                          export_animation_mode="NLA_TRACKS", export_apply=False)
print("RESULT exportado", OUT, os.path.getsize(OUT) // 1024, "KB", flush=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.path.dirname(OUT), "fuentes", "alex_normal.blend"))

# ---------------------------------------------------------------- vistas: cada opcion de cada fila
if VIEWS:
    items = [i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in items else "BLENDER_EEVEE_NEXT"
    scene.world = bpy.data.worlds.new("fondo")
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.57, 0.6, 1)
    ld = bpy.data.lights.new("sol", "SUN")
    ld.energy = 3.0
    lo = bpy.data.objects.new("sol", ld)
    lo.rotation_euler = [math.radians(a) for a in (50, 10, -35)]
    scene.collection.objects.link(lo)
    scene.view_settings.view_transform = "Standard"
    cd = bpy.data.cameras.new("cam")
    cd.type = "ORTHO"
    cam = bpy.data.objects.new("cam", cd)
    scene.collection.objects.link(cam)
    scene.camera = cam
    scene.render.resolution_x, scene.render.resolution_y = 400, 500
    arm.data.pose_position = "REST"
    os.makedirs(VIEWS, exist_ok=True)
    rows = {"peinado": len(PEINADOS), "arriba": len(ARRIBA), "abajo": len(ABAJO), "calzado": len(CALZADO)}
    for row, count in rows.items():
        for k in range(count):
            look = {r: (k if r == row else 0) for r in rows}
            for o in scene.objects:
                if o.type == "MESH" and "_" in o.name:
                    r, idx = o.name.rsplit("_", 1)
                    if r in rows:
                        o.hide_render = look[r] != int(idx)
            a = math.radians(30)
            zoom = {"peinado": (0.55, 1.62), "arriba": (1.0, 1.25), "abajo": (1.1, 0.55), "calzado": (0.6, 0.2)}[row]
            cam.location = (6 * math.sin(a), -6 * math.cos(a), zoom[1])
            cam.rotation_euler = (math.radians(90), 0, a)
            cd.ortho_scale = zoom[0]
            scene.render.filepath = os.path.join(VIEWS, "alexn_%s_%d.png" % (row, k))
            bpy.ops.render.render(write_still=True)
    print("RESULT vistas", flush=True)
