"""Álex, maniquí de pruebas 3D, sobre el cuerpo base masculino de Quaternius (CC0).

blender -b --factory-startup -P alex_maniqui.py -- <pack de cuerpos> <UAL1_Standard.glb> <alex.glb antiguo> <salida.glb> [vistas]

- Cuerpo «Superhero_Male» de Universal Base Characters, sin cejas: gris con la cuadricula de prototipo
  (horneada desde una cuadricula 3D, asi las casillas no se cortan en las costuras de la textura) y la
  marca naranja en el pecho, como el maniqui voxel.
- Animaciones de la Universal Animation Library (mismo esqueleto). Ataque: un directo rapido (Álex
  golpea con el cursor). La pose de pared se traslada tal cual desde el alex.glb antiguo, hueso a hueso
  por direccion, porque costo varios intentos dejarla bien.
- Altura 1,72 m. Mira a -Y (en Godot, +Z), pies en el suelo, pose en T.
"""
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

args = sys.argv[sys.argv.index("--") + 1:]
BODIES, UAL, OLD, OUT = args[:4]
VIEWS = args[4] if len(args) > 4 else None
HEIGHT = 1.72
ANIMS = {"Idle": "Idle_Loop", "Run": "Jog_Fwd_Loop", "Jump": "Jump_Start", "Fall": "Jump_Loop",
         "Land": "Jump_Land", "Attack": "Punch_Jab", "Hit": "Hit_Chest", "Death": "Death01", "Float": "Idle_Loop"}

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
bpy.ops.import_scene.gltf(filepath=os.path.join(BODIES, "Base Characters", "Godot - UE", "Superhero_Male_FullBody.gltf"))
for o in list(scene.objects):
    if o.name.startswith(("Icosphere", "Eyebrows")):
        bpy.data.objects.remove(o)
arm = next(o for o in scene.objects if o.type == "ARMATURE")
arm.name = "Alex"
body = next(o for o in scene.objects if o.type == "MESH" and o.name.lower().startswith("superhero"))
body.name = "Alex_Cuerpo"
eyes = next(o for o in scene.objects if o.type == "MESH" and o.name.startswith("Eyes"))
eyes.name = "Alex_Ojos"


def srgb(c):
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c) + (1.0,)


def flat_material(name, rgb):
    m = bpy.data.materials.new(name)
    m.diffuse_color = srgb(rgb)
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = srgb(rgb)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
    return m


def select_only(ob):
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)


# ---------------------------------------------------------------- cuadricula de prototipo horneada
GRIS, CUADRO = (0.72, 0.74, 0.78), (0.55, 0.58, 0.64)
img = bpy.data.images.new("T_Alex_Maniqui", 1024, 1024)
bake = bpy.data.materials.new("hornear")
nt = bake.node_tree
nt.nodes.remove(nt.nodes["Principled BSDF"])
coord = nt.nodes.new("ShaderNodeTexCoord")
checker = nt.nodes.new("ShaderNodeTexChecker")
checker.inputs["Scale"].default_value = 10.0  # casillas de 10 cm, como los cuadros del maniqui voxel
checker.inputs["Color1"].default_value = srgb(GRIS)
checker.inputs["Color2"].default_value = srgb(CUADRO)
emit = nt.nodes.new("ShaderNodeEmission")
target = nt.nodes.new("ShaderNodeTexImage")
target.image = img
nt.nodes.active = target
nt.links.new(coord.outputs["Object"], checker.inputs["Vector"])
nt.links.new(checker.outputs["Color"], emit.inputs["Color"])
nt.links.new(emit.outputs["Emission"], nt.nodes["Material Output"].inputs["Surface"])
body.data.materials.clear()
body.data.materials.append(bake)
scene.render.engine = "CYCLES"
scene.cycles.samples = 1
scene.cycles.device = "CPU"
select_only(body)
bpy.ops.object.bake(type="EMIT", margin=8)
img.filepath_raw = os.path.join(os.path.dirname(OUT), "fuentes", "texturas", "T_Alex_Maniqui.png")
os.makedirs(os.path.dirname(img.filepath_raw), exist_ok=True)
img.file_format = "PNG"
img.save()
img.pack()
skin = bpy.data.materials.new("M_Alex_Maniqui")
snt = skin.node_tree
tex = snt.nodes.new("ShaderNodeTexImage")
tex.image = img
snt.links.new(tex.outputs["Color"], snt.nodes["Principled BSDF"].inputs["Base Color"])
snt.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
body.data.materials.clear()
body.data.materials.append(skin)
eyes.data.materials.clear()
eyes.data.materials.append(flat_material("M_Alex_Ojos", (0.10, 0.11, 0.15)))
print("RESULT cuadricula horneada", flush=True)

# Marca naranja en el pecho (lado izquierdo de Álex), pegada a la superficie
deps = bpy.context.evaluated_depsgraph_get()
bvh = BVHTree.FromObject(body, deps)
inv = body.matrix_world.inverted()
zs = [(body.matrix_world @ v.co).z for v in body.data.vertices]
top = max(zs)
chest_z = top * 0.735
hit = bvh.ray_cast(inv @ Vector((0.075, -1.0, chest_z)), (inv.to_3x3() @ Vector((0, 1, 0))).normalized())
p = body.matrix_world @ hit[0]
n = (body.matrix_world.to_3x3() @ hit[1]).normalized()
side = Vector((0, 0, 1)).cross(n).normalized()
up = n.cross(side).normalized()
verts = [p + n * 0.003 + side * sx * 0.03 + up * sy * 0.04 for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
me = bpy.data.meshes.new("Alex_Marca")
me.from_pydata(verts, [], [(0, 1, 2, 3)])
mark = bpy.data.objects.new("Alex_Marca", me)
scene.collection.objects.link(mark)
me.materials.append(flat_material("M_Alex_Marca", (0.98, 0.70, 0.16)))
vg = mark.vertex_groups.new(name="spine_03")
vg.add([0, 1, 2, 3], 1.0, "REPLACE")
mark.parent = arm
mod = mark.modifiers.new("esqueleto", "ARMATURE")
mod.object = arm

# ---------------------------------------------------------------- animaciones de la UAL
before_obj, before_act = set(bpy.data.objects), set(bpy.data.actions)
bpy.ops.import_scene.gltf(filepath=UAL)
ual_objs = [o for o in bpy.data.objects if o not in before_obj]
ual_actions = [a for a in bpy.data.actions if a not in before_act]


def find(name):
    for a in ual_actions:
        if a.name == name or a.name.startswith(name + "_") or a.name.split("|")[-1] == name:
            return a
    raise KeyError(name)


arm.animation_data_create()


def add_track(name, action):
    action.name = name
    action.use_fake_user = True
    track = arm.animation_data.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, int(action.frame_range[0]), action)
    if action.slots:
        strip.action_slot = action.slots[0]


for target, source in ANIMS.items():
    add_track(target, find(source).copy())
    print("RESULT animacion", target, "<-", source, flush=True)
for o in ual_objs:
    bpy.data.objects.remove(o)

# ---------------------------------------------------------------- pared: traslado desde el alex.glb antiguo
MAP = {"pelvis": "Hips", "spine_01": "Spine", "spine_02": "Spine1", "spine_03": "Spine2", "neck_01": "Neck",
       "Head": "Head", "clavicle_l": "LeftShoulder", "upperarm_l": "LeftArm", "lowerarm_l": "LeftForeArm",
       "hand_l": "LeftHand", "clavicle_r": "RightShoulder", "upperarm_r": "RightArm", "lowerarm_r": "RightForeArm",
       "hand_r": "RightHand", "thigh_l": "LeftUpLeg", "calf_l": "LeftLeg", "foot_l": "LeftFoot", "ball_l": "LeftToeBase",
       "thigh_r": "RightUpLeg", "calf_r": "RightLeg", "foot_r": "RightFoot", "ball_r": "RightToeBase"}
AIM = {"upperarm_l": "lowerarm_l", "lowerarm_l": "hand_l", "upperarm_r": "lowerarm_r", "lowerarm_r": "hand_r",
       "thigh_l": "calf_l", "calf_l": "foot_l", "foot_l": "ball_l", "thigh_r": "calf_r", "calf_r": "foot_r", "foot_r": "ball_r"}
before_obj, before_act = set(bpy.data.objects), set(bpy.data.actions)
bpy.ops.import_scene.gltf(filepath=OLD)
old_objs = [o for o in bpy.data.objects if o not in before_obj]
src = next(o for o in old_objs if o.type == "ARMATURE")
wall_src = next(a for a in bpy.data.actions if a not in before_act and (a.name == "Wall" or a.name.startswith("Wall")))
order = [b.name for b in arm.data.bones]
rest = {n: arm.matrix_world @ arm.data.bones[n].matrix_local for n in order}
ref = {t: src.matrix_world @ src.data.bones[s].matrix_local for t, s in MAP.items()}
src.animation_data_create()
src.animation_data.action = wall_src
if wall_src.slots:
    src.animation_data.action_slot = wall_src.slots[0]
fa, fb = (int(round(v)) for v in wall_src.frame_range)
up = Vector((0, 0, 1))
ratio = rest["pelvis"].translation.dot(up) / ref["pelvis"].translation.dot(up)
wall = bpy.data.actions.new("Wall")
arm.animation_data.action = wall
for frame in range(fa, fb + 1):
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    cur = {t: src.matrix_world @ src.pose.bones[s].matrix for t, s in MAP.items()}
    pose_w = {}
    for nme in order:
        loc0, q0, sc0 = rest[nme].decompose()
        bone = arm.data.bones[nme]
        if nme in AIM:
            d = (cur[AIM[nme]].translation - cur[nme].translation).normalized()
            d0 = (rest[AIM[nme]].translation - loc0).normalized()
            q = d0.rotation_difference(d) @ q0
        elif nme in MAP:
            q = cur[nme].to_quaternion() @ ref[nme].to_quaternion().inverted() @ q0
        elif bone.parent is not None:
            par = bone.parent.name
            q = pose_w[par].to_quaternion() @ rest[par].to_quaternion().inverted() @ q0
        else:
            q = q0
        if nme == "pelvis":
            loc = loc0 + (cur[nme].translation - ref[nme].translation) * ratio
        elif bone.parent is not None:
            par = bone.parent.name
            loc = (pose_w[par] @ rest[par].inverted()) @ loc0
        else:
            loc = loc0
        pose_w[nme] = Matrix.LocRotScale(loc, q, sc0)
    posed = {k: arm.matrix_world.inverted() @ v for k, v in pose_w.items()}
    for nme in order:
        pb = arm.pose.bones[nme]
        parent = pb.parent
        extra = {"parent_matrix": posed[parent.name], "parent_matrix_local": parent.bone.matrix_local} if parent else {}
        pb.matrix_basis = pb.bone.convert_local_to_pose(posed[nme], pb.bone.matrix_local, invert=True, **extra)
        pb.keyframe_insert("rotation_quaternion", frame=frame - fa)
        pb.keyframe_insert("location", frame=frame - fa)
arm.animation_data.action = None
for pb in arm.pose.bones:
    pb.matrix_basis = Matrix.Identity(4)
add_track("Wall", wall)
for o in old_objs:
    bpy.data.objects.remove(o)
print("RESULT pared trasladada", fb - fa + 1, "fotogramas", flush=True)

# ---------------------------------------------------------------- altura y exportacion
f = HEIGHT / top
arm.scale = (f, f, f)
print("RESULT escala %.3f (de %.3f m a %.2f m)" % (f, top, HEIGHT), flush=True)
bpy.ops.object.select_all(action="DESELECT")
for o in scene.objects:
    if o == arm or (o.parent == arm and o.type == "MESH"):
        o.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_animations=True,
                          export_animation_mode="NLA_TRACKS", export_apply=False)
print("RESULT exportado", OUT, os.path.getsize(OUT) // 1024, "KB", flush=True)

# ---------------------------------------------------------------- vistas de comprobacion (opcional)
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
    cd.ortho_scale = 2.0
    cam = bpy.data.objects.new("cam", cd)
    scene.collection.objects.link(cam)
    scene.camera = cam
    scene.render.resolution_x, scene.render.resolution_y = 600, 700
    os.makedirs(VIEWS, exist_ok=True)
    for name, track_name, frame, ang in (("reposo", None, 0, 30), ("pared", "Wall", 5, 68), ("golpe", "Attack", 8, 68),
                                         ("frente", None, 0, 0)):
        for t in arm.animation_data.nla_tracks:
            t.mute = track_name is not None and t.name != track_name
            t.is_solo = False
        arm.data.pose_position = "REST" if track_name is None else "POSE"
        scene.frame_set(frame)
        a = math.radians(ang)
        cam.location = (6 * math.sin(a), -6 * math.cos(a), 0.88)
        cam.rotation_euler = (math.radians(90), 0, a)
        scene.render.filepath = os.path.join(VIEWS, "alex_%s.png" % name)
        bpy.ops.render.render(write_still=True)
