"""Alex como avatar de pruebas: maniqui gris voxel con la cuadricula a la vista.

Se ejecuta dentro de fbx_a_glb.py (usa bpy y `arm`). Sustituye la malla por un
modelo propio, en pose T, con cada voxel unido a un hueso del esqueleto.
"""
V = 0.05  # lado del voxel en metros

COLORS = {
    "base": (0.72, 0.74, 0.78),
    "linea": (0.55, 0.58, 0.64),
    "junta": (0.24, 0.26, 0.32),
    "ojo": (0.10, 0.11, 0.15),
    "marca": (0.98, 0.70, 0.16),
}
NAMES = list(COLORS)

# hueso, x0, x1, y0, y1, z0, z1 (metros, de pie, mirando a -Y)
PARTS = [
    ("Head", -0.10, 0.10, -0.08, 0.12, 1.40, 1.65),
    ("Neck", -0.05, 0.05, -0.02, 0.08, 1.33, 1.42),
    ("Spine2", -0.17, 0.17, -0.05, 0.15, 1.10, 1.34),
    ("Spine1", -0.14, 0.14, -0.04, 0.14, 0.97, 1.12),
    ("Spine", -0.13, 0.13, -0.04, 0.14, 0.88, 0.99),
    ("Hips", -0.16, 0.16, -0.05, 0.15, 0.75, 0.90),
    ("LeftShoulder", 0.15, 0.20, 0.00, 0.10, 1.15, 1.25),
    ("RightShoulder", -0.20, -0.15, 0.00, 0.10, 1.15, 1.25),
    ("LeftArm", 0.17, 0.46, 0.00, 0.10, 1.15, 1.25),
    ("LeftForeArm", 0.45, 0.76, 0.00, 0.10, 1.15, 1.25),
    ("LeftHand", 0.75, 0.87, 0.00, 0.10, 1.15, 1.25),
    ("RightArm", -0.46, -0.17, 0.00, 0.10, 1.15, 1.25),
    ("RightForeArm", -0.76, -0.45, 0.00, 0.10, 1.15, 1.25),
    ("RightHand", -0.87, -0.75, 0.00, 0.10, 1.15, 1.25),
    ("LeftUpLeg", 0.03, 0.18, -0.08, 0.08, 0.39, 0.78),
    ("LeftLeg", 0.05, 0.16, -0.06, 0.07, 0.05, 0.41),
    ("LeftFoot", 0.05, 0.16, -0.06, 0.07, 0.00, 0.07),
    ("LeftToeBase", 0.05, 0.16, -0.16, -0.05, 0.00, 0.06),
    ("RightUpLeg", -0.18, -0.03, -0.08, 0.08, 0.39, 0.78),
    ("RightLeg", -0.16, -0.05, -0.06, 0.07, 0.05, 0.41),
    ("RightFoot", -0.16, -0.05, -0.06, 0.07, 0.00, 0.07),
    ("RightToeBase", -0.16, -0.05, -0.16, -0.05, 0.00, 0.06),
]
JOINTS = {"LeftForeArm", "RightForeArm", "LeftLeg", "RightLeg"}


def cell(a):
    return int(round(a / V))


def color_of(bone, i, j, k, z0_cell):
    if bone == "Head":
        if j == cell(-0.08) and k == cell(1.53) and i in (cell(-0.05), cell(0.05) - 1):
            return "ojo"
    if bone == "Spine2" and j == cell(-0.05) and k in (cell(1.20), cell(1.25)) and i in (cell(0.05), cell(0.05) + 1):
        return "marca"
    if bone in JOINTS and k == z0_cell + (0 if "Leg" in bone else 0) and "Arm" not in bone:
        return "junta"
    if bone in ("LeftForeArm", "RightForeArm") and i in (cell(0.45), cell(-0.46)):
        return "junta"
    if (i // 2 + j // 2 + k // 2) % 2 == 0:  # cuadros de prototipo
        return "linea"
    return "base"


voxels = {}
for bone, x0, x1, y0, y1, z0, z1 in PARTS:
    z0c = cell(z0)
    for i in range(cell(x0), cell(x1)):
        for j in range(cell(y0), cell(y1)):
            for k in range(z0c, cell(z1)):
                voxels[(bone, i, j, k)] = color_of(bone, i, j, k, z0c)

FACES = [((1, 0, 0), ((1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1))),
         ((-1, 0, 0), ((0, 1, 0), (0, 0, 0), (0, 0, 1), (0, 1, 1))),
         ((0, 1, 0), ((1, 1, 0), (0, 1, 0), (0, 1, 1), (1, 1, 1))),
         ((0, -1, 0), ((0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1))),
         ((0, 0, 1), ((0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1))),
         ((0, 0, -1), ((0, 1, 0), (1, 1, 0), (1, 0, 0), (0, 0, 0)))]

verts, faces, uvs, owners = [], [], [], []
for (bone, i, j, k), col in voxels.items():
    for n, quad in FACES:
        if (bone, i + n[0], j + n[1], k + n[2]) in voxels:
            continue
        idx = len(verts)
        for q in quad:
            verts.append(((i + q[0]) * V, (j + q[1]) * V, (k + q[2]) * V))
        faces.append((idx, idx + 1, idx + 2, idx + 3))
        uvs.append((NAMES.index(col) + 0.5) / len(NAMES))
        owners.append(bone)

mesh = bpy.data.meshes.new("dev")
mesh.from_pydata(verts, [], faces)
mesh.update()
uv = mesh.uv_layers.new(name="UV")
for poly, u in zip(mesh.polygons, uvs):
    for loop in poly.loop_indices:
        uv.data[loop].uv = (u, 0.5)

palette = bpy.data.images.new("paleta", len(NAMES), 1, alpha=False)
pixels = []
for n in NAMES:
    pixels += list(COLORS[n]) + [1.0]
palette.pixels = pixels
palette.pack()
new_mat = bpy.data.materials.new("dev")
new_mat.use_nodes = True
tree = new_mat.node_tree
shader = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
image_node = tree.nodes.new("ShaderNodeTexImage")
image_node.image = palette
image_node.interpolation = "Closest"
tree.links.new(image_node.outputs[0], shader.inputs["Base Color"])
mesh.materials.append(new_mat)

obj = bpy.data.objects.new("dev", mesh)
bpy.context.scene.collection.objects.link(obj)
for poly, bone in zip(mesh.polygons, owners):
    group = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
    group.add(list(poly.vertices), 1.0, "REPLACE")
obj.parent = arm
obj.matrix_parent_inverse = arm.matrix_world.inverted()
mod = obj.modifiers.new("esqueleto", "ARMATURE")
mod.object = arm
print("RESULT voxeles", len(voxels), "caras", len(faces), flush=True)
