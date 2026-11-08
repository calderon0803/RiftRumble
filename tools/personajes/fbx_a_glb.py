"""Une un personaje FBX y sus animaciones FBX en un solo GLB para Godot.

blender -b -P fbx_a_glb.py -- <personaje.fbx> <textura.png> <carpeta animaciones> <salida.glb>
"""
import os
import sys

import bpy
from math import degrees, radians

from mathutils import Matrix, Vector

char, tex, anim_dir, ual, run_name, out = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=char)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
meshes = [o for o in bpy.data.objects if o.type == "MESH"]

img = bpy.data.images.load(tex)
img.pack()
mat = bpy.data.materials.new("personaje")
mat.use_nodes = True
nt = mat.node_tree
bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
node = nt.nodes.new("ShaderNodeTexImage")
node.image = img
node.interpolation = "Closest"
nt.links.new(node.outputs[0], bsdf.inputs["Base Color"])
for m in meshes:
    m.data.materials.clear()
    m.data.materials.append(mat)

if arm.animation_data is None:
    arm.animation_data_create()
arm.animation_data.action = None
for track in list(arm.animation_data.nla_tracks):
    arm.animation_data.nla_tracks.remove(track)

# El esqueleto viene girado respecto al mundo: los ejes se expresan en su propio espacio.
_to_arm = arm.matrix_world.to_3x3().normalized().inverted()
AXES = {k: (_to_arm @ Vector(v)).normalized() for k, v in (("X", (1, 0, 0)), ("Y", (0, 1, 0)), ("Z", (0, 0, 1)))}
UP = AXES["Z"]

# Correccion de postura por animacion: hueso y grados hacia atras (espalda mas recta).
POSTURE = {}
FORWARD = None

scene = bpy.context.scene
order = [b.name for b in arm.data.bones]  # los padres van antes que los hijos
base = None

for name in ("Idle", "Attack", "Hit", "Death"):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(anim_dir, name + ".fbx"))
    new = [o for o in bpy.data.objects if o not in before]
    source = next(o for o in new if o.type == "ARMATURE")
    start, end = (int(round(v)) for v in source.animation_data.action.frame_range)
    target = bpy.data.actions.new(name)
    target.use_fake_user = True
    arm.animation_data.action = target
    to_arm = arm.matrix_world.inverted() @ source.matrix_world
    for frame in range(start, end + 1):
        scene.frame_set(frame)
        posed = {n: to_arm @ source.pose.bones[n].matrix for n in order}
        if name == "Idle" and frame == start:
            base = dict(posed)
        for bone_name, deg in POSTURE.get(name, {}).items():
            pivot = posed[bone_name].translation.copy()
            r = Matrix.Translation(pivot) @ Matrix.Rotation(radians(-deg), 4, AXES["X"]) @ Matrix.Translation(-pivot)
            for n in [bone_name] + [c.name for c in arm.data.bones[bone_name].children_recursive]:
                # brazos: la postura de la carrera se conserva con el tronco
                posed[n] = r @ posed[n]
        for bone_name in order:
            pb = arm.pose.bones[bone_name]
            parent = pb.parent
            extra = {"parent_matrix": posed[parent.name], "parent_matrix_local": parent.bone.matrix_local} if parent else {}
            pb.matrix_basis = pb.bone.convert_local_to_pose(posed[bone_name], pb.bone.matrix_local, invert=True, **extra)
            at = frame - start
            pb.keyframe_insert("rotation_quaternion", frame=at)
            if parent is None:
                pb.keyframe_insert("location", frame=at)
    slot = arm.animation_data.action_slot
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    track = arm.animation_data.nla_tracks.new()
    track.name = name
    nla = track.strips.new(name, 0, target)
    nla.action_slot = slot
    for o in new:
        bpy.data.objects.remove(o)
    print("RESULT", name, end - start + 1, "fotogramas", flush=True)

# Carrera de la Universal Animation Library (Quaternius, CC0), con otro esqueleto.
UAL = {"Hips": "pelvis", "Spine": "spine_01", "Spine1": "spine_02", "Spine2": "spine_03", "Neck": "neck_01",
       "Head": "Head", "LeftShoulder": "clavicle_l", "LeftArm": "upperarm_l", "LeftForeArm": "lowerarm_l",
       "LeftHand": "hand_l", "RightShoulder": "clavicle_r", "RightArm": "upperarm_r", "RightForeArm": "lowerarm_r",
       "RightHand": "hand_r", "LeftUpLeg": "thigh_l", "LeftLeg": "calf_l", "LeftFoot": "foot_l", "LeftToeBase": "ball_l",
       "RightUpLeg": "thigh_r", "RightLeg": "calf_r", "RightFoot": "foot_r", "RightToeBase": "ball_r"}
AIM = {"LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand", "RightArm": "RightForeArm", "RightForeArm": "RightHand",
       "LeftUpLeg": "LeftLeg", "LeftLeg": "LeftFoot", "LeftFoot": "LeftToeBase",
       "RightUpLeg": "RightLeg", "RightLeg": "RightFoot", "RightFoot": "RightToeBase"}


def add_ual(name, clip):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=ual)
    new = [o for o in bpy.data.objects if o not in before]
    src = next(o for o in new if o.type == "ARMATURE")
    if src.animation_data is None:
        src.animation_data_create()

    def play(action_name):
        action = next(a for a in bpy.data.actions if a.name == action_name or a.name.startswith(action_name + "_") and "Armature" in a.name)
        src.animation_data.action = action
        if src.animation_data.action_slot is None:
            src.animation_data.action_slot = action.slots[0]
        return action

    def sample():
        return {t: src.matrix_world @ src.pose.bones[u].matrix for t, u in UAL.items()}

    play("A_TPose")
    scene.frame_set(0)
    bpy.context.view_layer.update()
    ref = sample()
    action = play(clip)
    fa, fb = (int(round(v)) for v in action.frame_range)
    rest = {n: arm.matrix_world @ arm.data.bones[n].matrix_local for n in order}
    up = Vector((0, 0, 1))
    src_hip = ref["Hips"].translation.dot(up)
    tgt_hip = rest["Hips"].translation.dot(up)
    ratio = tgt_hip / src_hip
    target = bpy.data.actions.new(name)
    target.use_fake_user = True
    arm.animation_data.action = target
    to_local = arm.matrix_world.inverted()
    for frame in range(fa, fb + 1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        cur = sample()
        pose_w = {}
        for n in order:
            r0 = rest[n]
            loc0, q0, sc0 = r0.decompose()
            bone = arm.data.bones[n]
            if n in AIM:
                child = AIM[n]
                d = (cur[child].translation - cur[n].translation).normalized()
                d0 = (rest[child].translation - loc0).normalized()
                q = d0.rotation_difference(d) @ q0
            elif n in UAL:
                q = cur[n].to_quaternion() @ ref[n].to_quaternion().inverted() @ q0
            else:
                q = pose_w[bone.parent.name].to_quaternion() @ rest[bone.parent.name].to_quaternion().inverted() @ q0
            if bone.parent is None:
                loc = loc0 + (cur[n].translation - ref[n].translation) * ratio
            else:
                loc = (pose_w[bone.parent.name] @ rest[bone.parent.name].inverted()) @ loc0
            pose_w[n] = Matrix.LocRotScale(loc, q, sc0)
        posed = {n: to_local @ pose_w[n] for n in order}
        at = frame - fa
        for n in order:
            pb = arm.pose.bones[n]
            parent = pb.parent
            extra = {"parent_matrix": posed[parent.name], "parent_matrix_local": parent.bone.matrix_local} if parent else {}
            pb.matrix_basis = pb.bone.convert_local_to_pose(posed[n], pb.bone.matrix_local, invert=True, **extra)
            pb.keyframe_insert("rotation_quaternion", frame=at)
            if parent is None:
                pb.keyframe_insert("location", frame=at)
    slot = arm.animation_data.action_slot
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    track = arm.animation_data.nla_tracks.new()
    track.name = name
    nla = track.strips.new(name, 0, target)
    nla.action_slot = slot
    for o in new:
        bpy.data.objects.remove(o)
    print("RESULT", name, "desde", clip, fb - fa + 1, "fotogramas", flush=True)


add_ual("Run", run_name)

# Poses propias que el pack no trae. Cada entrada: hueso, eje del personaje y grados.
# Muslo hacia delante = X negativo; doblar la rodilla = X positivo; inclinar el tronco adelante = X positivo.
# Brazo izquierdo hacia fuera = Y negativo; brazo derecho hacia fuera = Y positivo.
FEET = ("LeftToe_End", "RightToe_End", "LeftToeBase", "RightToeBase", "LeftFoot", "RightFoot")


def build(spec, grounded):
    m = {k: v.copy() for k, v in base.items()}
    # las piernas parten rectas: el reposo del pack ya las tiene separadas
    chains = ("LeftUpLeg", "RightUpLeg") + (("LeftArm", "RightArm") if spec.get("_straight_arms") else ())
    for hip in chains:
        bone = arm.data.bones[hip]
        shift = Matrix.Translation(base[hip].translation - bone.matrix_local.translation)
        for n in [hip] + [c.name for c in bone.children_recursive]:
            m[n] = shift @ arm.data.bones[n].matrix_local
    for bone_name in order:
        for axis, deg in spec.get(bone_name, ()):
            pivot = m[bone_name].translation.copy()
            r = Matrix.Translation(pivot) @ Matrix.Rotation(radians(deg), 4, AXES[axis]) @ Matrix.Translation(-pivot)
            for n in [bone_name] + [c.name for c in arm.data.bones[bone_name].children_recursive]:
                m[n] = r @ m[n]
    if grounded:
        drop = min(base[n].translation.dot(UP) for n in FEET) - min(m[n].translation.dot(UP) for n in FEET)
        shift = Matrix.Translation(UP * drop)
        m = {k: shift @ v for k, v in m.items()}
    return m


def make_action(name, keys):
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    arm.animation_data.action = action
    for at, spec, grounded in keys:
        m = build(spec, grounded)
        for bone_name in order:
            pb = arm.pose.bones[bone_name]
            parent = pb.parent
            extra = {"parent_matrix": m[parent.name], "parent_matrix_local": parent.bone.matrix_local} if parent else {}
            pb.matrix_basis = pb.bone.convert_local_to_pose(m[bone_name], pb.bone.matrix_local, invert=True, **extra)
            pb.keyframe_insert("rotation_quaternion", frame=at)
            if parent is None:
                pb.keyframe_insert("location", frame=at)
    slot = arm.animation_data.action_slot
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    track = arm.animation_data.nla_tracks.new()
    track.name = name
    nla = track.strips.new(name, 0, action)
    nla.action_slot = slot
    print("RESULT", name, flush=True)


ARMS_BACK = {"LeftArm": [("Y", -22), ("X", 26)], "RightArm": [("Y", 22), ("X", 26)]}
ARMS_UP = {"_straight_arms": True, "LeftArm": [("Y", 72), ("X", -58)], "RightArm": [("Y", -72), ("X", 50)], "LeftForeArm": [("X", -10)], "RightForeArm": [("X", -10)]}
ARMS_LOW = {"LeftArm": [("Y", -30)], "RightArm": [("Y", 30)]}

CROUCH = dict(ARMS_BACK, Spine=[("X", 20)], LeftUpLeg=[("X", -62)], LeftLeg=[("X", 98)],
              RightUpLeg=[("X", -48)], RightLeg=[("X", 84)], LeftFoot=[("X", -30)], RightFoot=[("X", -30)])
TAKEOFF = dict(Spine=[("X", 8)], LeftUpLeg=[("X", -68)], LeftLeg=[("X", 86)], RightUpLeg=[("X", 18)],
               RightLeg=[("X", 22)], RightFoot=[("X", 40)], LeftArm=[("Y", -30), ("X", -30)], RightArm=[("Y", 30), ("X", 34)])
RISE = dict(Spine=[("X", 4)], LeftUpLeg=[("X", -74)], LeftLeg=[("X", 100)], RightUpLeg=[("X", -8)],
            RightLeg=[("X", 52)], RightFoot=[("X", 30)], LeftArm=[("Y", -42), ("X", -44)], RightArm=[("Y", 42), ("X", 28)])
FALL_A = dict(ARMS_UP, Spine=[("X", -6)], LeftUpLeg=[("X", -14)], LeftLeg=[("X", 20)], RightUpLeg=[("X", 4)],
              RightLeg=[("X", 16)], LeftFoot=[("X", 30)], RightFoot=[("X", 32)])
FALL_B = dict(ARMS_UP, Spine=[("X", -3)], LeftUpLeg=[("X", -20)], LeftLeg=[("X", 28)], RightUpLeg=[("X", 8)],
              RightLeg=[("X", 22)], LeftFoot=[("X", 34)], RightFoot=[("X", 36)])
FALL_B["LeftArm"] = [("Y", 72), ("X", -68)]
FALL_B["RightArm"] = [("Y", -72), ("X", 60)]
LAND_DEEP = dict(ARMS_LOW, Spine=[("X", 26)], LeftUpLeg=[("X", -72)], LeftLeg=[("X", 112)], RightUpLeg=[("X", -58)],
                 RightLeg=[("X", 100)], LeftFoot=[("X", -38)], RightFoot=[("X", -38)])

# De espaldas a la pared, mirando hacia fuera: una mano detras y los dos pies plantados en ella.
# Referencia: cuerpo pegado a la pared, un brazo arriba agarrando, una pierna recta y la otra rodilla fuera.
WALL_A = {"_straight_arms": True, "RightArm": [("Y", 88), ("X", -14)],
          "LeftArm": [("Y", 72), ("X", -32)], "LeftForeArm": [("X", -34)], "Spine": [("X", 6)],
          "RightUpLeg": [("X", 5)], "RightLeg": [("X", 8)], "RightFoot": [("X", 42)],
          "LeftUpLeg": [("X", -28)], "LeftLeg": [("X", 118)], "LeftFoot": [("X", 0)]}
WALL_B = dict(WALL_A, LeftArm=[("Y", 72), ("X", -36)], LeftUpLeg=[("X", -30)])
make_action("Wall", [(0, WALL_A, False), (10, WALL_B, False), (20, WALL_A, False)])
make_action("Jump", [(0, CROUCH, True), (3, TAKEOFF, False), (9, RISE, False)])
make_action("Fall", [(0, FALL_A, False), (8, FALL_B, False), (16, FALL_A, False)])
make_action("Land", [(0, LAND_DEEP, True), (5, LAND_DEEP, True), (12, {}, True)])

# Modelo propio: sustituye la malla importada.
design = os.environ.get("PERSONAJE")
if design:
    for m in meshes:
        bpy.data.objects.remove(m)
    exec(open(design, encoding="utf8").read(), globals())

bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_animations=True,
                          export_animation_mode="NLA_TRACKS", export_apply=False)
print("RESULT exportado", out)
