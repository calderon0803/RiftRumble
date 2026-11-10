"""Personajes voxel propios: Alex, Kira y Nexo, sobre el mismo esqueleto.

Se ejecuta dentro de fbx_a_glb.py (usa bpy y `arm`); la variable NOMBRE elige el personaje.
Las cajas se dan en voxeles enteros (i0, i1, j0, j1, k0, k1), de pie y mirando a -Y; una caja
posterior repinta a las anteriores. Estilo: bloques grandes, colores planos y acentos brillantes.
"""
V = 0.05


class Model:
    def __init__(self):
        self.vox = {}

    def box(self, bone, color, i0, i1, j0, j1, k0, k1):
        for i in range(i0, i1):
            for j in range(j0, j1):
                for k in range(k0, k1):
                    self.vox[(bone, i, j, k)] = color

    def sym(self, bone, color, i0, i1, j0, j1, k0, k1):
        """Caja en el lado izquierdo y su reflejo en el derecho."""
        self.box("Left" + bone, color, i0, i1, j0, j1, k0, k1)
        self.box("Right" + bone, color, -i1, -i0, j0, j1, k0, k1)


def body(m, top, belly, hips, sleeve, cuff, hand, thigh, shin, boot, sole):
    """Cuerpo humano comun: 33 voxeles de alto, cabeza de 5."""
    m.box("Spine2", top, -3, 3, -1, 3, 22, 27)
    m.box("Neck", hand, -1, 1, 0, 2, 26, 29)
    m.box("Spine1", belly, -3, 3, 0, 3, 19, 23)
    m.box("Spine", belly, -3, 3, 0, 3, 17, 20)
    m.box("Hips", hips, -3, 3, -1, 3, 15, 18)
    m.sym("Shoulder", sleeve, 3, 4, 0, 2, 25, 27)
    # El codo gira en i=9: cada pieza entra un voxel en la otra para que no se abra un hueco al doblarlo.
    m.sym("Arm", sleeve, 3, 10, 0, 2, 25, 27)
    m.sym("ForeArm", sleeve, 8, 14, 0, 2, 25, 27)
    m.sym("ForeArm", cuff, 12, 14, 0, 2, 25, 27)
    m.sym("Hand", hand, 14, 16, 0, 2, 25, 27)
    m.sym("UpLeg", thigh, 0, 3, -1, 2, 8, 16)
    m.sym("Leg", shin, 1, 3, -1, 1, 1, 9)
    m.sym("Leg", boot, 1, 3, -1, 1, 1, 5)
    m.sym("Foot", boot, 1, 3, -1, 1, 0, 2)
    m.sym("ToeBase", sole, 1, 3, -3, -1, 0, 1)
    m.sym("ToeBase", boot, 1, 3, -3, -1, 1, 2)


def alex():
    m = Model()
    body(m, "gris", "gris", "gris", "gris", "gris", "gris", "gris", "gris", "gris", "junta")
    m.box("Head", "gris", -2, 2, -2, 3, 28, 33)
    for (bone, i, j, k) in list(m.vox):
        if m.vox[(bone, i, j, k)] == "gris" and (i // 2 + j // 2 + k // 2) % 2 == 0:
            m.vox[(bone, i, j, k)] = "cuadro"
    m.box("Head", "ojo", -2, -1, -2, -1, 30, 31)
    m.box("Head", "ojo", 1, 2, -2, -1, 30, 31)
    m.box("Spine2", "marca", 1, 2, -1, 0, 24, 26)
    m.sym("Leg", "junta", 1, 3, -1, 1, 8, 9)
    m.sym("ToeBase", "junta", 1, 3, -3, -1, 0, 1)
    colors = {"gris": (0.72, 0.74, 0.78), "cuadro": (0.55, 0.58, 0.64), "junta": (0.24, 0.26, 0.32),
              "ojo": (0.10, 0.11, 0.15), "marca": (0.98, 0.70, 0.16)}
    return m, colors


def hair_part(style):
    m = Model()
    m.box("Head", "pelo", -2, 2, -2, 3, 32, 33)
    m.box("Head", "pelo", -2, 2, 2, 3, 30, 32)
    if style in ("corto", "largo", "coleta", "mono"):
        m.box("Head", "pelo", -2, 2, -2, -1, 31, 32)
        m.box("Head", "pelo", -2, -1, -1, 3, 30, 32)
        m.box("Head", "pelo", 1, 2, -1, 3, 30, 32)
        m.box("Head", "pelo", -2, 2, -1, 3, 32, 34)
    if style == "largo":
        m.box("Head", "pelo", -3, 3, 0, 4, 26, 34)
        m.box("Head", "pelo", -3, -2, -2, 0, 28, 33)
        m.box("Head", "pelo", 2, 3, -2, 0, 28, 33)
    if style == "coleta":
        m.box("Head", "pelo", -1, 1, 3, 5, 30, 33)
        m.box("Head", "pelo", -1, 1, 4, 5, 23, 30)
    if style == "cresta":
        m.box("Head", "pelo", -1, 1, -2, 4, 33, 36)
    if style == "afro":
        m.box("Head", "pelo", -3, 3, -2, 4, 31, 36)
        m.box("Head", "pelo", -4, 4, -1, 3, 32, 35)
        m.box("Head", "pelo", -2, 2, -1, 3, 36, 37)
        m.box("Head", "pelo", -3, -2, -1, 4, 29, 31)
        m.box("Head", "pelo", 2, 3, -1, 4, 29, 31)
        m.box("Head", "pelo", -3, 3, 2, 4, 29, 31)
    if style == "mono":
        m.box("Head", "pelo", -1, 1, 0, 2, 34, 37)
    return m


def torso(m):
    m.box("Spine2", "ropa", -3, 3, -1, 3, 22, 27)
    m.box("Spine1", "ropa", -3, 3, 0, 3, 19, 23)
    m.box("Spine", "ropa", -3, 3, 0, 3, 17, 20)
    m.box("Hips", "ropa", -3, 3, -1, 3, 17, 18)


def sleeves(m, arm_end, fore_end=0, cuff=False):
    m.sym("Shoulder", "ropa", 3, 4, 0, 2, 25, 27)
    m.sym("Arm", "ropa", 3, arm_end, 0, 2, 25, 27)
    if fore_end:
        m.sym("ForeArm", "ropa", 8, fore_end, 0, 2, 25, 27)
    if cuff:
        m.sym("ForeArm", "ropa2", fore_end - 2, fore_end, 0, 2, 25, 27)


def top_part(kind):
    m = Model()
    torso(m)
    if kind == "tirantes":
        for key in [k for k in m.vox if k[0] == "Spine2" and k[3] >= 25 and -2 <= k[1] < 2]:
            del m.vox[key]
    if kind == "sudadera":
        sleeves(m, 10, 14, True)
        m.box("Spine2", "ropa2", 0, 1, -1, 0, 22, 27)
        m.box("Spine1", "ropa2", 0, 1, 0, 1, 19, 23)
        m.box("Hips", "ropa2", -3, 3, -1, 3, 17, 18)
        m.box("Spine2", "ropa2", -2, 2, 2, 4, 26, 28)
    if kind == "camiseta":
        sleeves(m, 7)
        m.box("Spine2", "ropa2", -1, 1, -1, 0, 26, 27)
    if kind == "chaqueta":
        sleeves(m, 10, 14, True)
        m.box("Spine2", "interior", -1, 1, -1, 0, 22, 27)
        m.box("Spine1", "interior", -1, 1, 0, 1, 19, 23)
        m.box("Spine", "interior", -1, 1, 0, 1, 17, 20)
        m.box("Hips", "ropa", -3, -1, -1, 3, 15, 18)
        m.box("Hips", "ropa", 1, 3, -1, 3, 15, 18)
        m.box("Hips", "ropa", -3, 3, 1, 3, 15, 18)
        m.box("Spine2", "ropa2", -2, -1, -1, 0, 25, 28)
        m.box("Spine2", "ropa2", 1, 2, -1, 0, 25, 28)
    if kind == "camisa":
        sleeves(m, 10, 10)
        m.box("Spine2", "ropa2", 0, 1, -1, 0, 22, 27)
        m.box("Spine2", "interior", -2, 2, -1, 0, 26, 27)
    return m


def bottom_part(kind):
    m = Model()
    m.box("Hips", "pantalon", -3, 3, -1, 3, 15, 18)
    if kind in ("pantalon", "chandal"):
        m.sym("UpLeg", "pantalon", 0, 3, -1, 2, 8, 16)
        m.sym("Leg", "pantalon", 1, 3, -1, 1, 2, 9)
    if kind == "chandal":
        m.sym("UpLeg", "pantalon2", 2, 3, 0, 1, 8, 16)
        m.sym("Leg", "pantalon2", 2, 3, 0, 1, 2, 9)
    if kind == "corto":
        m.sym("UpLeg", "pantalon", 0, 3, -1, 2, 11, 16)
    return m


def shoe_part(kind):
    m = Model()
    if kind == "sandalias":
        m.sym("Foot", "suela", 1, 3, -1, 1, 0, 1)
        m.sym("ToeBase", "suela", 1, 3, -3, -1, 0, 1)
        m.sym("ToeBase", "zapato", 1, 3, -2, -1, 1, 2)
        return m
    upper = "bota" if kind == "botas" else "zapato"
    m.sym("Foot", upper, 1, 3, -1, 1, 1, 3)
    m.sym("Foot", "suela", 1, 3, -1, 1, 0, 1)
    m.sym("ToeBase", upper, 1, 3, -3, -1, 1, 2)
    m.sym("ToeBase", "suela", 1, 3, -3, -1, 0, 1)
    if kind == "botas":
        m.sym("Leg", "bota", 1, 3, -1, 1, 1, 6)
    return m


def alex_normal():
    """Piel de base y una malla por opcion, nombrada como la fila y el indice de Data.LOOK_OPTIONS.

    El orden de los colores es el de Avatar3D.LOOK_SLOTS. Cada capa sobresale unos milimetros de la anterior.
    """
    base = Model()
    body(base, "piel", "piel", "piel", "piel", "piel", "piel", "piel", "piel", "piel", "piel")
    base.box("Head", "piel", -2, 2, -2, 3, 28, 33)
    base.box("Head", "ojo", -2, -1, -2, -1, 30, 31)
    base.box("Head", "ojo", 1, 2, -2, -1, 30, 31)
    parts = [("base", base, 0.0)]
    groups = [("peinado", hair_part, ["corto", "largo", "rapado", "coleta", "cresta", "afro", "mono"], 0.006),
              ("abajo", bottom_part, ["pantalon", "corto", "chandal"], 0.006),
              ("arriba", top_part, ["sudadera", "camiseta", "chaqueta", "tirantes", "camisa"], 0.012),
              ("calzado", shoe_part, ["zapatillas", "botas", "sandalias"], 0.018)]
    for group, make, kinds, inflate in groups:
        for i, kind in enumerate(kinds):
            parts.append(("%s_%d" % (group, i), make(kind), inflate))
    colors = {"piel": (0.93, 0.74, 0.60), "pelo": (0.18, 0.12, 0.09), "ropa": (0.20, 0.36, 0.62),
              "ropa2": (0.13, 0.24, 0.43), "pantalon": (0.20, 0.21, 0.27), "pantalon2": (0.8, 0.8, 0.8),
              "zapato": (0.86, 0.86, 0.82), "bota": (0.23, 0.16, 0.12), "ojo": (0.08, 0.08, 0.11),
              "suela": (0.32, 0.32, 0.36), "interior": (0.9, 0.9, 0.88)}
    return parts, colors


def kira():
    m = Model()
    body(m, "ropa", "ropa2", "ropa", "ropa", "verde", "piel", "ropa2", "ropa2", "bota", "verde")
    m.box("Spine2", "verde", -1, 1, -1, 0, 22, 27)
    m.box("Hips", "verde", -3, 3, -1, 0, 15, 16)
    # Cabeza
    m.box("Head", "piel", -2, 2, -2, 2, 28, 32)
    m.box("Head", "pelo", -2, 2, -1, 3, 30, 34)
    m.box("Head", "pelo", -3, 3, 0, 3, 29, 33)
    m.box("Head", "pelo", -2, 2, -2, -1, 32, 33)
    m.box("Head", "pelo2", -2, 0, -2, -1, 31, 32)
    m.box("Head", "pelo", -3, -2, -2, 1, 29, 32)
    m.box("Head", "pelo", 2, 3, -2, 1, 29, 32)
    m.box("Head", "ojo", -2, -1, -2, -1, 30, 31)
    m.box("Head", "ojo", 1, 2, -2, -1, 30, 31)
    # Coleta
    m.box("Head", "cinta", -1, 1, 3, 4, 31, 33)
    m.box("Head", "pelo", -1, 1, 4, 6, 30, 33)
    m.box("Head", "pelo2", -1, 1, 5, 7, 26, 30)
    m.box("Head", "pelo", -1, 1, 5, 6, 23, 26)
    # Espada de energia en la mano derecha, apuntando adelante
    m.box("RightHand", "metal", -16, -14, -2, 0, 25, 27)
    m.box("RightHand", "metal", -17, -13, -3, -2, 25, 27)
    m.box("RightHand", "hoja", -15, -14, -17, -3, 25, 27)
    m.box("RightHand", "hoja2", -15, -14, -17, -3, 26, 27)
    colors = {"piel": (0.93, 0.74, 0.60), "ropa": (0.17, 0.14, 0.20), "ropa2": (0.27, 0.24, 0.31),
              "verde": (0.37, 0.89, 0.60), "bota": (0.10, 0.09, 0.13), "pelo": (0.18, 0.62, 0.42),
              "pelo2": (0.28, 0.76, 0.52), "cinta": (0.93, 0.93, 0.85), "ojo": (0.07, 0.12, 0.12),
              "metal": (0.55, 0.57, 0.63), "hoja": (0.37, 0.89, 0.60), "hoja2": (0.78, 1.0, 0.86)}
    return m, colors


def nexo():
    m = Model()
    body(m, "capa", "capa", "capa", "capa", "cian", "palido", "capa", "capa", "capa", "capa")
    # Tunica rigida: no hay pies, flota
    for key in [k for k in m.vox if "Leg" in k[0] or "Foot" in k[0] or "Toe" in k[0]]:
        del m.vox[key]
    m.box("Hips", "capa", -4, 4, -2, 4, 4, 18)
    m.box("Hips", "capa2", -3, 3, -3, -2, 4, 18)
    m.box("Hips", "cian", -4, 4, -2, 4, 4, 5)
    m.box("Hips", "cian", 0, 1, -3, -2, 4, 18)
    m.box("Spine2", "cian", 0, 1, -2, -1, 22, 27)
    m.box("Spine2", "capa", -3, 3, -2, -1, 22, 27)
    m.box("Spine2", "cian", 0, 1, -2, -1, 22, 27)
    # Capa asimetrica sobre un hombro
    m.box("Spine2", "capa2", -5, -3, -1, 4, 20, 28)
    m.box("Spine2", "cian", -5, -4, -1, 4, 20, 21)
    m.box("Spine2", "capa2", -3, 4, 3, 5, 16, 28)
    # Cabeza
    m.box("Head", "palido", -2, 2, -2, 3, 28, 33)
    m.box("Head", "capa", -2, 2, -2, -1, 30, 31)
    m.box("Head", "cian", -1, 1, -2, -1, 30, 31)
    m.box("Head", "palido2", -2, 2, 2, 3, 28, 33)
    # Anillo-umbral a su espalda
    ring = [(-5, 0), (-4, 3), (-3, 4), (0, 5), (3, 4), (4, 3), (5, 0), (4, -3), (3, -4), (0, -5), (-3, -4), (-4, -3)]
    full = set()
    for a in range(len(ring)):
        x0, z0 = ring[a]
        x1, z1 = ring[(a + 1) % len(ring)]
        for t in range(9):
            full.add((round(x0 + (x1 - x0) * t / 8), round(z0 + (z1 - z0) * t / 8)))
    for x, z in full:
        m.box("Spine2", "aro", x, x + 1, 6, 7, 29 + z, 30 + z)
    colors = {"capa": (0.11, 0.17, 0.31), "capa2": (0.17, 0.25, 0.43), "cian": (0.44, 0.95, 1.0),
              "palido": (0.91, 0.96, 1.0), "palido2": (0.68, 0.76, 0.86), "aro": (0.44, 0.95, 1.0)}
    return m, colors


def human_arms():
    """Proporciones humanas: hombros arriba del torso y dedos a media muslo. Solo traslada huesos: las animaciones valen."""
    from mathutils import Vector
    to_arm = arm.matrix_world.inverted().to_3x3()

    def shift(name, dx, dz):
        bone = arm.data.edit_bones[name]
        delta = to_arm @ Vector((dx * V, 0, dz * V))
        bone.use_connect = False
        for b in [bone] + list(bone.children_recursive):
            b.head += delta
            b.tail += delta

    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for side, sign in (("Left", 1), ("Right", -1)):
        shift(side + "Arm", 0, 2)
        shift(side + "Hand", -sign, 0)
    bpy.ops.object.mode_set(mode="OBJECT")


human_arms()
name = os.environ["NOMBRE"]
if name == "alex_normal":
    PARTS, COLORS = alex_normal()
else:
    model, COLORS = {"alex": alex, "kira": kira, "nexo": nexo}[name]()
    PARTS = [(name, model, 0.0)]
NAMES = list(COLORS)
FACES = [((1, 0, 0), ((1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1))),
         ((-1, 0, 0), ((0, 1, 0), (0, 0, 0), (0, 0, 1), (0, 1, 1))),
         ((0, 1, 0), ((1, 1, 0), (0, 1, 0), (0, 1, 1), (1, 1, 1))),
         ((0, -1, 0), ((0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1))),
         ((0, 0, 1), ((0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1))),
         ((0, 0, -1), ((0, 1, 0), (1, 1, 0), (1, 0, 0), (0, 0, 0)))]

palette = bpy.data.images.new("paleta_" + name, len(NAMES), 1, alpha=False)
pixels = []
for n in NAMES:
    pixels += list(COLORS[n]) + [1.0]
palette.pixels = pixels
palette.pack()
new_mat = bpy.data.materials.new(name)
new_mat.use_nodes = True
tree = new_mat.node_tree
shader = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
image_node = tree.nodes.new("ShaderNodeTexImage")
image_node.image = palette
image_node.interpolation = "Closest"
tree.links.new(image_node.outputs[0], shader.inputs["Base Color"])


def add_mesh(part_name, voxels, inflate):
    verts, faces, uvs, owners = [], [], [], []

    # Dentro de una prenda, cada hueso sobresale un poco distinto: sin caras coplanarias no hay dientes de sierra.
    bone_order = list(dict.fromkeys(key[0] for key in voxels))

    def corner(cell, q, bone):
        extra = inflate + bone_order.index(bone) * 0.0004 if inflate else 0.0
        return (cell + q) * V + (2 * q - 1) * extra

    for (bone, i, j, k), col in voxels.items():
        for n, quad in FACES:
            if (bone, i + n[0], j + n[1], k + n[2]) in voxels:
                continue
            idx = len(verts)
            for q in quad:
                verts.append((corner(i, q[0], bone), corner(j, q[1], bone), corner(k, q[2], bone)))
            faces.append((idx, idx + 1, idx + 2, idx + 3))
            uvs.append((NAMES.index(col) + 0.5) / len(NAMES))
            owners.append(bone)
    mesh = bpy.data.meshes.new(part_name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    uv = mesh.uv_layers.new(name="UV")
    for poly, u in zip(mesh.polygons, uvs):
        for loop in poly.loop_indices:
            uv.data[loop].uv = (u, 0.5)
    mesh.materials.append(new_mat)
    obj = bpy.data.objects.new(part_name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for poly, bone in zip(mesh.polygons, owners):
        group = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
        group.add(list(poly.vertices), 1.0, "REPLACE")
    obj.parent = arm
    obj.matrix_parent_inverse = arm.matrix_world.inverted()
    mod = obj.modifiers.new("esqueleto", "ARMATURE")
    mod.object = arm
    print("RESULT malla", part_name, "voxeles", len(voxels), flush=True)


for part_name, part, inflate in PARTS:
    add_mesh(part_name, part.vox, inflate)


def preview(path):
    """Vista de comprobacion: pose de reposo, colores planos."""
    tree.links.new(image_node.outputs[0], shader.inputs["Emission Color"])
    shader.inputs["Emission Strength"].default_value = 1.0
    shader.inputs["Base Color"].default_value = (0, 0, 0, 1)
    for link in list(tree.links):
        if link.to_socket == shader.inputs["Base Color"]:
            tree.links.remove(link)
    for track in arm.animation_data.nla_tracks:
        track.mute = True
    action = bpy.data.actions["Float" if os.environ["NOMBRE"] == "nexo" else "Idle"]
    arm.animation_data.action = action
    arm.animation_data.action_slot = action.slots[0]
    sc = bpy.context.scene
    sc.frame_set(10)
    items = [i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in items else items[0]
    sc.render.resolution_x, sc.render.resolution_y = 500, 700
    sc.render.film_transparent = False
    sc.world = bpy.data.worlds.new("w")
    sc.world.color = (0.03, 0.06, 0.07)
    cd = bpy.data.cameras.new("c")
    cd.type = "ORTHO"
    cd.ortho_scale = 2.5
    cam = bpy.data.objects.new("c", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    import math
    ang = math.radians(35)
    cam.location = (8 * math.sin(ang), -8 * math.cos(ang), 0.95)
    cam.rotation_euler = (math.radians(90), 0, ang)
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
