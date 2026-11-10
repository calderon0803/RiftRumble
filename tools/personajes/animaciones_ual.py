"""Animaciones de Álex para Avatar3D, sobre el esqueleto de Quaternius (UBC / UAL).

anadir_animaciones(arm, ual_glb, alex_viejo_glb): crea una pista NLA por animacion.
- La mayoria salen de la Universal Animation Library (CC0), hecha para este esqueleto: se usan tal cual.
- La pose de pared se traslada hueso a hueso, por direccion, desde el alex.glb antiguo (esqueleto tipo
  Mixamo), porque costo varios intentos dejarla bien.
"""
import bpy
from mathutils import Matrix, Vector

ALEX_ANIMS = {"Idle": "Idle_Loop", "Run": "Jog_Fwd_Loop", "Jump": "Jump_Start", "Fall": "Jump_Loop",
              "Land": "Jump_Land", "Attack": "Punch_Jab", "Hit": "Hit_Chest", "Death": "Death01", "Float": "Idle_Loop"}
MAP = {"pelvis": "Hips", "spine_01": "Spine", "spine_02": "Spine1", "spine_03": "Spine2", "neck_01": "Neck",
       "Head": "Head", "clavicle_l": "LeftShoulder", "upperarm_l": "LeftArm", "lowerarm_l": "LeftForeArm",
       "hand_l": "LeftHand", "clavicle_r": "RightShoulder", "upperarm_r": "RightArm", "lowerarm_r": "RightForeArm",
       "hand_r": "RightHand", "thigh_l": "LeftUpLeg", "calf_l": "LeftLeg", "foot_l": "LeftFoot", "ball_l": "LeftToeBase",
       "thigh_r": "RightUpLeg", "calf_r": "RightLeg", "foot_r": "RightFoot", "ball_r": "RightToeBase"}
AIM = {"upperarm_l": "lowerarm_l", "lowerarm_l": "hand_l", "upperarm_r": "lowerarm_r", "lowerarm_r": "hand_r",
       "thigh_l": "calf_l", "calf_l": "foot_l", "foot_l": "ball_l", "thigh_r": "calf_r", "calf_r": "foot_r", "foot_r": "ball_r"}


def _add_track(arm, name, action):
    action.name = name
    action.use_fake_user = True
    track = arm.animation_data.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, int(action.frame_range[0]), action)
    if action.slots:
        strip.action_slot = action.slots[0]


def anadir_animaciones(arm, ual_glb, old_glb, anims=ALEX_ANIMS):
    scene = bpy.context.scene
    if arm.animation_data is None:
        arm.animation_data_create()
    before_obj, before_act = set(bpy.data.objects), set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=ual_glb)
    ual_objs = [o for o in bpy.data.objects if o not in before_obj]
    ual_actions = [a for a in bpy.data.actions if a not in before_act]

    def find(name):
        for a in ual_actions:
            if a.name == name or a.name.startswith(name + "_") or a.name.split("|")[-1] == name:
                return a
        raise KeyError(name)

    for target, source in anims.items():
        _add_track(arm, target, find(source).copy())
    for o in ual_objs:
        bpy.data.objects.remove(o)

    # Pared, desde el alex.glb antiguo
    before_obj, before_act = set(bpy.data.objects), set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=old_glb)
    old_objs = [o for o in bpy.data.objects if o not in before_obj]
    src = next(o for o in old_objs if o.type == "ARMATURE")
    wall_src = next(a for a in bpy.data.actions if a not in before_act and a.name.startswith("Wall"))
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
            par = bone.parent.name if bone.parent else None
            if nme in AIM:
                d = (cur[AIM[nme]].translation - cur[nme].translation).normalized()
                d0 = (rest[AIM[nme]].translation - loc0).normalized()
                q = d0.rotation_difference(d) @ q0
            elif nme in MAP:
                q = cur[nme].to_quaternion() @ ref[nme].to_quaternion().inverted() @ q0
            elif par:
                q = pose_w[par].to_quaternion() @ rest[par].to_quaternion().inverted() @ q0
            else:
                q = q0
            if nme == "pelvis":
                loc = loc0 + (cur[nme].translation - ref[nme].translation) * ratio
            elif par:
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
    _add_track(arm, "Wall", wall)
    for o in old_objs:
        bpy.data.objects.remove(o)
    print("RESULT animaciones", [t.name for t in arm.animation_data.nla_tracks], flush=True)
