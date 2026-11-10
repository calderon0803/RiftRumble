"""Exporta a Kira (kira_ranger.blend) a GLB para Godot, con las animaciones que pide Avatar3D.

blender -b --factory-startup -P exportar_kira.py -- <kira_ranger.blend> <UAL1_Standard.glb> <salida.glb>

Las animaciones vienen de la Universal Animation Library de Quaternius (CC0), hecha para este mismo
esqueleto: se usan tal cual, sin trasladarlas. Avatar3D necesita estos nombres (y pone en bucle Idle,
Run, Fall, Wall y Float); Kira no se agarra a paredes ni flota, asi que Wall y Float repiten el reposo.
Antes de exportar: altura maxima 1,76 m, y materiales que el formato glTF entiende (textura directa,
recorte de transparencia en pelo, tatuajes y runas, ojos verdes horneados en su textura).
"""
import os
import sys

import bpy
import numpy as np

BLEND, UAL, OUT = sys.argv[sys.argv.index("--") + 1:][:3]
bpy.ops.wm.open_mainfile(filepath=BLEND)
scene = bpy.context.scene
arm = next(o for o in scene.objects if o.type == "ARMATURE")

ANIMS = {"Idle": "Sword_Idle", "Run": "Jog_Fwd_Loop", "Jump": "Jump_Start", "Fall": "Jump_Loop",
         "Land": "Jump_Land", "Attack": "Sword_Attack", "Hit": "Hit_Chest", "Death": "Death01",
         "Wall": "Sword_Idle", "Float": "Sword_Idle"}
MAX_HEIGHT = 1.76

# ---------------------------------------------------------------- animaciones
before_obj, before_act = set(bpy.data.objects), set(bpy.data.actions)
bpy.ops.import_scene.gltf(filepath=UAL)
new_objs = [o for o in bpy.data.objects if o not in before_obj]
ual_actions = {a.name: a for a in bpy.data.actions if a not in before_act}


def find(name):
    for k, a in ual_actions.items():
        if k == name or k.startswith(name + "_") or k.split("|")[-1] == name:
            return a
    raise KeyError(name)


if arm.animation_data is None:
    arm.animation_data_create()
for track in list(arm.animation_data.nla_tracks):
    arm.animation_data.nla_tracks.remove(track)
arm.animation_data.action = None
for target, source in ANIMS.items():
    src = find(source)
    act = src.copy()
    act.name = target
    act.use_fake_user = True
    track = arm.animation_data.nla_tracks.new()
    track.name = target
    strip = track.strips.new(target, int(act.frame_range[0]), act)
    if act.slots:
        strip.action_slot = act.slots[0]
    print("RESULT animacion", target, "<-", src.name, int(act.frame_range[1] - act.frame_range[0]) + 1, "fotogramas", flush=True)
for o in new_objs:
    bpy.data.objects.remove(o)

# ---------------------------------------------------------------- altura
arm.data.pose_position = "REST"  # medir en pose de reposo, no en la animacion activa
bpy.context.view_layer.update()
deps = bpy.context.evaluated_depsgraph_get()
top = 0.0
for o in scene.objects:
    if o.type == "MESH" and not o.hide_render and (o.parent == arm):
        ev = o.evaluated_get(deps)
        me = ev.to_mesh()
        top = max([top] + [(o.matrix_world @ v.co).z for v in me.vertices])
        ev.to_mesh_clear()
arm.data.pose_position = "POSE"
if top > MAX_HEIGHT:
    f = MAX_HEIGHT / top
    arm.scale = (f, f, f)
    print("RESULT escala %.3f (de %.3f m a %.3f m)" % (f, top, MAX_HEIGHT), flush=True)

# ---------------------------------------------------------------- materiales para glTF


def hue_shift_image(img, shift, sat=1.3):
    out = img.copy()
    out.name = img.name + "_verde"
    px = np.array(out.pixels[:], dtype=np.float32).reshape(-1, 4)
    rgb = px[:, :3]
    mx, mn = rgb.max(1), rgb.min(1)
    d = mx - mn
    ds = np.where(d == 0, 1, d)
    r, g, b = rgb[:, 0], rgb[:, 1], rgb[:, 2]
    h = np.where(mx == r, ((g - b) / ds) % 6, np.where(mx == g, (b - r) / ds + 2, (r - g) / ds + 4)) / 6
    s = np.where(mx > 0, d / np.where(mx == 0, 1, mx), 0)
    h = (h + shift) % 1.0
    s = np.clip(s * sat, 0, 1)
    i = np.floor(h * 6).astype(int) % 6
    f = h * 6 - np.floor(h * 6)
    v = mx
    p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    for k, (a, bb, c) in enumerate([(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)]):
        m = i == k
        rgb[m, 0], rgb[m, 1], rgb[m, 2] = a[m], bb[m], c[m]
    px[:, :3] = rgb
    out.pixels.foreach_set(px.ravel())
    out.pack()
    return out


for m in bpy.data.materials:
    if not m.node_tree:
        continue
    nt = m.node_tree
    bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf is None:
        continue
    base = bsdf.inputs["Base Color"]
    if base.links:
        node = base.links[0].from_node
        # Mezcla con el color de vertice del pack: fuera, la textura va directa
        if node.type == "MIX" and any(l.from_node.type == "VERTEX_COLOR" for i in node.inputs for l in i.links):
            tex_link = next(l for i in node.inputs for l in i.links if l.from_node.type in ("TEX_IMAGE", "HUE_SAT"))
            src = tex_link.from_node
            if src.type == "HUE_SAT":  # ojos: el giro de tono se hornea en la textura
                tex = src.inputs["Color"].links[0].from_node
                tex.image = hue_shift_image(tex.image, src.inputs["Hue"].default_value - 0.5)
                src = tex
            nt.links.new(src.outputs["Color"], base)
        elif node.type == "MIX":  # cejas: textura por un verde fijo (glTF: factor de color)
            tex = next((l.from_node for i in node.inputs for l in i.links if l.from_node.type == "TEX_IMAGE"), None)
            if tex:
                node.blend_type = "MULTIPLY"
                node.inputs[0].default_value = 1.0
                for l in list(node.inputs[6].links) + list(node.inputs[7].links):
                    nt.links.remove(l)
                nt.links.new(tex.outputs["Color"], node.inputs[6])
                node.inputs[7].default_value = (0.03, 0.25, 0.06, 1)
    alpha = bsdf.inputs["Alpha"]
    if alpha.links and alpha.links[0].from_node.type == "TEX_IMAGE":
        # Recorte de transparencia (glTF alphaMode MASK): pelo, tatuajes y runas
        tex = alpha.links[0].from_node
        gt = nt.nodes.new("ShaderNodeMath")
        gt.operation = "GREATER_THAN"
        gt.inputs[1].default_value = 0.5
        nt.links.new(tex.outputs["Alpha"], gt.inputs[0])
        nt.links.new(gt.outputs[0], alpha)

# Texturas a 1024 px como mucho: en el juego Kira ocupa unos 113 px de alto
for img in bpy.data.images:
    if img.size[0] > 1024 and img.users:
        img.scale(1024, 1024 * img.size[1] // img.size[0])
        img.pack()
        print("RESULT textura reducida", img.name, flush=True)
print("RESULT altura sin escalar %.3f" % top, flush=True)

# ---------------------------------------------------------------- exportar
for o in bpy.context.view_layer.objects:
    o.select_set(o == arm or (o.parent == arm and o.type == "MESH" and not o.hide_render))
bpy.context.view_layer.objects.active = arm
print("RESULT objetos", sorted(o.name for o in bpy.context.selected_objects), flush=True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_animations=True,
                          export_animation_mode="NLA_TRACKS", export_apply=False, export_image_format="AUTO")
print("RESULT exportado", OUT, os.path.getsize(OUT) // 1024, "KB", flush=True)
