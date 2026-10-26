"""Roblox rigs for Blender: exact R6 / R15 joint data, rig builder, Roblox <-> Blender maths.

Units are studs (1 Blender unit = 1 stud). Every bone's local axes are the character's own axes in
Roblox terms (X right, Y up, Z back), so a pose bone's rotation IS the Roblox joint rotation in the
parent's axes. That is the "pose language" shared with the Studio kit (roblox/AnimKit.luau).
"""
import math

import bpy
from mathutils import Matrix, Vector

# Roblox (X right, Y up, Z back, facing -Z)  <->  Blender (Z up, facing -Y). Its own inverse.
B2R = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
R2B = B2R


def cf(x, y, z, *r):
    """Roblox CFrame.new(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22) as a 4x4 Matrix."""
    if not r:
        r = (1, 0, 0, 0, 1, 0, 0, 0, 1)
    return Matrix(((r[0], r[1], r[2], x), (r[3], r[4], r[5], y), (r[6], r[7], r[8], z), (0, 0, 0, 1)))


def cf_components(m):
    """4x4 Matrix -> the 12 numbers of CFrame.new(...), rounded so files stay small."""
    out = [m[0][3], m[1][3], m[2][3], m[0][0], m[0][1], m[0][2], m[1][0], m[1][1], m[1][2], m[2][0], m[2][1], m[2][2]]
    return [0.0 if abs(v) < 1e-6 else round(v, 6) for v in out]


def angles(x=0.0, y=0.0, z=0.0):
    """Roblox CFrame.Angles(rad(x), rad(y), rad(z)) = Rx * Ry * Rz, degrees in."""
    return (Matrix.Rotation(math.radians(x), 4, "X") @ Matrix.Rotation(math.radians(y), 4, "Y")
            @ Matrix.Rotation(math.radians(z), 4, "Z"))


# Standard R6 rig (Rig Builder "Block Rig R6"). Part sizes in Roblox axes (X, Y, Z).
_R6_ROT_ROOT = (-1, 0, 0, 0, 0, 1, 0, 1, 0)
_R6_ROT_R = (0, 0, 1, 0, 1, 0, -1, 0, 0)
_R6_ROT_L = (0, 0, -1, 0, 1, 0, 1, 0, 0)

RIGS = {
    "R6": {
        "root": "HumanoidRootPart",
        "hip_height": 3.0,  # HumanoidRootPart centre above the ground at rest
        "parts": {
            "HumanoidRootPart": (2, 2, 1),
            "Torso": (2, 2, 1),
            "Head": (2, 1, 1),
            "Right Arm": (1, 2, 1),
            "Left Arm": (1, 2, 1),
            "Right Leg": (1, 2, 1),
            "Left Leg": (1, 2, 1),
        },
        # (motor name, Part0, Part1, C0, C1)
        "joints": [
            ("RootJoint", "HumanoidRootPart", "Torso", cf(0, 0, 0, *_R6_ROT_ROOT), cf(0, 0, 0, *_R6_ROT_ROOT)),
            ("Neck", "Torso", "Head", cf(0, 1, 0, *_R6_ROT_ROOT), cf(0, -0.5, 0, *_R6_ROT_ROOT)),
            ("Right Shoulder", "Torso", "Right Arm", cf(1, 0.5, 0, *_R6_ROT_R), cf(-0.5, 0.5, 0, *_R6_ROT_R)),
            ("Left Shoulder", "Torso", "Left Arm", cf(-1, 0.5, 0, *_R6_ROT_L), cf(0.5, 0.5, 0, *_R6_ROT_L)),
            ("Right Hip", "Torso", "Right Leg", cf(1, -1, 0, *_R6_ROT_R), cf(0.5, 1, 0, *_R6_ROT_R)),
            ("Left Hip", "Torso", "Left Leg", cf(-1, -1, 0, *_R6_ROT_L), cf(-0.5, 1, 0, *_R6_ROT_L)),
        ],
        "colors": {
            "HumanoidRootPart": (0.8, 0.8, 0.8),
            "Torso": (0.051, 0.412, 0.675),
            "Head": (0.961, 0.804, 0.188),
            "Right Arm": (0.961, 0.804, 0.188),
            "Left Arm": (0.961, 0.804, 0.188),
            "Right Leg": (0.643, 0.741, 0.278),
            "Left Leg": (0.643, 0.741, 0.278),
        },
        "feet": ["Right Leg", "Left Leg"],
        "body": ["Torso", "Head", "Right Leg", "Left Leg"],
        # part pairs that must not pass through each other
        "pairs": [("Right Arm", "Torso"), ("Left Arm", "Torso"), ("Right Arm", "Head"), ("Left Arm", "Head"),
                  ("Right Leg", "Left Leg"), ("Right Arm", "Right Leg"), ("Left Arm", "Left Leg")],
    },
}


def _r15():
    """Block R15 (HumanoidDescription with BodyTypeScale 0 and ProportionScale 0), measured in
    Studio from the rig attachments: C0 = Part0's RigAttachment, C1 = Part1's RigAttachment."""
    parts = {
        "HumanoidRootPart": (2, 2, 1), "LowerTorso": (2, 0.4, 1), "UpperTorso": (2, 1.6, 1),
        "Head": (1.2, 1.2, 1.2),
    }
    joints = [
        ("Root", "HumanoidRootPart", "LowerTorso", cf(0, -1, 0), cf(0, -0.2, 0)),
        ("Waist", "LowerTorso", "UpperTorso", cf(0, 0.2, 0), cf(0, -0.8, 0)),
        ("Neck", "UpperTorso", "Head", cf(0, 0.8, 0), cf(0, -0.586, 0)),
    ]
    colors = {"HumanoidRootPart": (0.8, 0.8, 0.8), "LowerTorso": (0.051, 0.412, 0.675),
              "UpperTorso": (0.051, 0.412, 0.675), "Head": (0.961, 0.804, 0.188)}
    for side, s in (("Right", 1), ("Left", -1)):
        parts.update({f"{side}UpperArm": (1, 1.169, 1), f"{side}LowerArm": (1, 1.052, 1), f"{side}Hand": (1, 0.3, 1),
                      f"{side}UpperLeg": (1, 1.217, 1), f"{side}LowerLeg": (1, 1.193, 1), f"{side}Foot": (1, 0.3, 1)})
        joints += [
            (f"{side}Shoulder", "UpperTorso", f"{side}UpperArm", cf(s, 0.563, 0), cf(-0.5 * s, 0.394, 0)),
            (f"{side}Elbow", f"{side}UpperArm", f"{side}LowerArm", cf(0, -0.334, 0), cf(0, 0.259, 0)),
            (f"{side}Wrist", f"{side}LowerArm", f"{side}Hand", cf(0, -0.501, 0), cf(0, 0.125, 0)),
            (f"{side}Hip", "LowerTorso", f"{side}UpperLeg", cf(0.5 * s, -0.2, 0), cf(0, 0.421, 0)),
            (f"{side}Knee", f"{side}UpperLeg", f"{side}LowerLeg", cf(0, -0.401, 0), cf(0, 0.379, 0)),
            (f"{side}Ankle", f"{side}LowerLeg", f"{side}Foot", cf(0, -0.547, 0), cf(0, 0.102, 0)),
        ]
        for p in ("UpperArm", "LowerArm", "Hand"):
            colors[f"{side}{p}"] = (0.961, 0.804, 0.188)
        for p in ("UpperLeg", "LowerLeg", "Foot"):
            colors[f"{side}{p}"] = (0.643, 0.741, 0.278)
    pairs = [("RightHand", "LeftHand"), ("RightLowerArm", "LeftLowerArm")]
    for s in ("Right", "Left"):
        pairs += [(f"{s}UpperArm", "Head")]
        for limb in (f"{s}LowerArm", f"{s}Hand"):
            pairs += [(limb, "UpperTorso"), (limb, "LowerTorso"), (limb, "Head")]
    pairs += [("RightLowerLeg", "LeftLowerLeg"), ("RightFoot", "LeftFoot"), ("RightUpperLeg", "LeftUpperLeg"),
              ("RightFoot", "LeftLowerLeg"), ("LeftFoot", "RightLowerLeg")]
    return {"root": "HumanoidRootPart", "hip_height": 3.0, "parts": parts, "joints": joints, "colors": colors,
            "feet": ["RightFoot", "LeftFoot"], "body": ["UpperTorso", "LowerTorso", "Head"], "pairs": pairs}


RIGS["R15"] = _r15()

# Props (weapons) hang off a part through an extra Motor6D. The prop part is named like the Pose
# Roblox will look for, so it must match the part name in the game ("Handle" for Tools). Every weapon's
# business end is its +Y and points forward when the arm hangs down; `grip` is how far below the
# part's centre the hand holds it. One weapon at a time (they all use the joint "Handle").
_HAND = {
    "R6": ("Right Arm", cf(0, -1, 0) @ angles(-90, 0, 0)),
    "R15": ("RightHand", cf(0, -0.15, 0) @ angles(-90, 0, 0)),
}


def _prop(size, grip, color):
    return {"part": "Handle", "size": size, "c1": cf(0, -grip, 0), "color": color, "attach": _HAND}


PROPS = {
    "Sword": _prop((0.3, 4.2, 0.3), 1.3, (0.75, 0.78, 0.82)),  # one-handed blade, 3 studs past the hand
    "Spear": _prop((0.3, 8.0, 0.3), 2.2, (0.55, 0.4, 0.25)),  # 6 studs in front of the hand, 2 behind
    "Dagger": _prop((0.2, 1.8, 0.2), 0.55, (0.75, 0.78, 0.82)),
    "Axe": _prop((0.3, 3.6, 0.3), 1.2, (0.5, 0.36, 0.22)),  # head on the end, blade toward the prop's -Z
}


def rest_frames(rig):
    """Rest CFrame of every part in character space (root at the origin)."""
    frames = {rig["root"]: Matrix.Identity(4)}
    pending = list(rig["joints"])
    while pending:
        for j in list(pending):
            name, p0, p1, c0, c1 = j
            if p0 in frames:
                frames[p1] = frames[p0] @ c0 @ c1.inverted()
                pending.remove(j)
    return frames


def joint_pivot(rig, part):
    """Rest pivot (joint position) of the part in character space; the root pivots at its centre."""
    for name, p0, p1, c0, c1 in rig["joints"]:
        if p1 == part:
            return (rest_frames(rig)[p0] @ c0).to_translation()
    return Vector((0, 0, 0))


def with_props(rig_type, props=()):
    """Copy of the rig definition with the requested props added as extra joints and parts."""
    base = RIGS[rig_type]
    rig = {k: (dict(v) if isinstance(v, dict) else list(v) if isinstance(v, list) else v) for k, v in base.items()}
    for prop_name in props:
        p = PROPS[prop_name]
        parent, c0 = p["attach"][rig_type]
        rig["parts"][p["part"]] = p["size"]
        rig["colors"][p["part"]] = p["color"]
        rig["joints"].append((p["part"], parent, p["part"], c0, p["c1"]))
        rig["pairs"] += [(p["part"], b) for b in rig["body"]]
    return rig


def _material(name, rgb):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, 1)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs[0].default_value = (*rgb, 1)
    bsdf.inputs["Roughness"].default_value = 0.6
    return mat


def _box(name, size_r, coll):
    """Box mesh with Roblox size (X, Y, Z), centred at its origin, in Blender axes."""
    import bmesh
    sx, sy, sz = size_r
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:  # Blender X, Y (depth = Roblox Z), Z (height = Roblox Y)
        v.co.x, v.co.y, v.co.z = v.co.x * sx, v.co.y * sz, v.co.z * sy
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    bev = obj.modifiers.new("Bevel", "BEVEL")
    bev.width = min(size_r) * 0.08
    bev.segments = 2
    return obj


def _head(name, coll, mat_skin):
    """Classic Roblox head (rounded cylinder) with a face on its front (-Z Roblox = -Y Blender)."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.62, depth=1.2)
    head = bpy.context.active_object
    head.name = name
    for c in head.users_collection:
        c.objects.unlink(head)
    coll.objects.link(head)
    bev = head.modifiers.new("Bevel", "BEVEL")
    bev.width = 0.18
    bev.segments = 4
    head.data.materials.append(mat_skin)
    black = _material("RbxFace", (0.02, 0.02, 0.02))
    face = []
    for sx in (-0.2, 0.2):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.075, location=(sx, -0.6, 0.12))
        face.append(bpy.context.active_object)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.22, minor_radius=0.03, location=(0, -0.6, -0.08),
                                     rotation=(math.radians(90), 0, 0))
    smile = bpy.context.active_object
    # keep only the lower half of the torus as a smile
    bm_mesh = smile.data
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(bm_mesh)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.y > -0.02], context="VERTS")
    bm.to_mesh(bm_mesh)
    bm.free()
    face.append(smile)
    for i, f in enumerate(face):
        f.name = f"{name}_Face{i}"
        f["rbx_deco"] = True  # lets live.clear_scene find it even after the head is gone
        for c in f.users_collection:
            c.objects.unlink(f)
        coll.objects.link(f)
        f.data.materials.append(black)
        f.parent = head
    return head


# Display meshes for the props: (centre z, size x, size y, size z, material) boxes along the prop's +Y
# (Blender +Z), the grip point at z = -grip. Roblox only sees the one Handle part; these are for looking.
_PROP_MESH = {
    "Sword": ([(-1.25, 0.22, 0.22, 0.9, 0), (-0.75, 1.0, 0.3, 0.16, 1), (0.6, 0.34, 0.08, 2.6, 2)], 1.85),
    "Spear": ([(-0.3, 0.16, 0.16, 7.0, 0), (3.35, 0.34, 0.08, 1.1, 2), (3.1, 0.5, 0.12, 0.12, 1)], 3.6),
    "Dagger": ([(-0.55, 0.16, 0.16, 0.5, 0), (-0.28, 0.5, 0.2, 0.1, 1), (0.35, 0.22, 0.06, 1.1, 2)], 0.75),
    "Axe": ([(-0.2, 0.18, 0.18, 3.4, 0), (1.3, 0.12, 1.2, 0.9, 2)], 99),
}
_PROP_MATS = (("Rbx_Grip", (0.32, 0.2, 0.1)), ("Rbx_Guard", (0.85, 0.65, 0.15)), ("Rbx_Blade", (0.8, 0.84, 0.9)))


def _prop_mesh(kind, name, coll):
    """Display mesh for a weapon prop (see _PROP_MESH); tips above `taper` get a point."""
    import bmesh
    pieces, taper = _PROP_MESH[kind]
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    for cz, sx, sy, sz, mi in pieces:
        geom = bmesh.ops.create_cube(bm, size=1.0)["verts"]
        for v in geom:
            v.co.x *= sx
            v.co.y *= sy
            v.co.z = v.co.z * sz + cz
        for f in {f for v in geom for f in v.link_faces}:
            f.material_index = mi
    for v in bm.verts:
        if v.co.z > taper:
            v.co.x *= 0.15
    if kind == "Axe":  # push the axe head out to the front of the shaft (Blender -Y = the prop's -Z)
        for v in bm.verts:
            if v.co.z > 0.8 and abs(v.co.y) > 0.1:
                v.co.y -= 0.5
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    for nm, rgb in _PROP_MATS:
        mesh.materials.append(_material(nm, rgb))
    return obj


def build(rig_type="R6", name=None, props=(), location=(0.0, 0.0, 0.0), show_root=False):
    """Create the rig in the current scene and return the armature object.

    The armature is named `name` (default `rig_type`), stands on z = 0 at `location` and faces -Y.
    Parts are rigid meshes parented to their bones, exactly like Roblox's Motor6D rigs.
    """
    rig = with_props(rig_type, props)
    name = name or rig_type
    frames = rest_frames(rig)
    hip = rig["hip_height"]

    coll = bpy.data.collections.get(name) or bpy.data.collections.new(name)
    if coll.name not in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.link(coll)

    arm_data = bpy.data.armatures.new(name)
    arm = bpy.data.objects.new(name, arm_data)
    coll.objects.link(arm)
    arm.location = Vector(location) + Vector((0, 0, hip))
    arm["rbx_rig"] = rig_type
    arm["rbx_props"] = ",".join(props)
    arm_data.display_type = "STICK"  # bones sit inside the parts; select them in the Outliner

    bpy.context.view_layer.objects.active = arm
    for o in bpy.context.selected_objects:
        o.select_set(False)
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    parent_of = {p1: p0 for _, p0, p1, _, _ in rig["joints"]}
    order = [rig["root"]] + [p1 for _, _, p1, _, _ in rig["joints"]]
    ebones = {}
    for part in order:
        eb = arm_data.edit_bones.new(part)
        pivot = joint_pivot(rig, part)
        eb.matrix = Matrix.Translation(R2B @ pivot) @ R2B  # bone axes = Roblox character axes
        eb.length = 0.35
        eb.matrix = Matrix.Translation(R2B @ pivot) @ R2B
        eb.use_deform = False
        if part in parent_of:
            eb.parent = ebones[parent_of[part]]
        ebones[part] = eb
    bpy.ops.object.mode_set(mode="POSE")
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
    bpy.ops.object.mode_set(mode="OBJECT")

    bpy.context.view_layer.update()
    for part, size in rig["parts"].items():
        if part == rig["root"] and not show_root:
            continue
        mat = _material(f"Rbx_{part}", rig["colors"][part])
        if part == "Head" and rig_type == "R6":
            obj = _head(f"{name}_Head", coll, mat)
        elif part == "Handle" and props and props[0] in _PROP_MESH:
            obj = _prop_mesh(props[0], f"{name}_{props[0]}", coll)
        else:
            obj = _box(f"{name}_{part.replace(' ', '')}", size, coll)
            obj.data.materials.append(mat)
        if part == rig["root"]:
            obj.display_type = "WIRE"
        obj.parent = arm
        obj.parent_type = "BONE"
        obj.parent_bone = part
        bpy.context.view_layer.update()
        obj.matrix_world = arm.matrix_world @ R2B @ frames[part] @ R2B
        obj["rbx_part"] = part
    bpy.context.view_layer.update()
    return arm


def part_frames(arm, rig):
    """Current CFrame of every part relative to the HumanoidRootPart, in Roblox axes."""
    frames = rest_frames(rig)
    world = {}
    for part in rig["parts"]:
        # bone-local coordinates are Roblox character coordinates, so only the armature side converts
        joint_r = B2R @ arm.pose.bones[part].matrix
        world[part] = joint_r @ Matrix.Translation(-joint_pivot(rig, part)) @ frames[part]
    root_inv = world[rig["root"]].inverted()
    return {p: root_inv @ m for p, m in world.items()}


def motor_transforms(arm, rig):
    """Motor6D.Transform of every joint for the current frame: (P0 * C0)^-1 * (P1 * C1)."""
    pf = part_frames(arm, rig)
    return {p1: (pf[p0] @ c0).inverted() @ (pf[p1] @ c1) for _, p0, p1, c0, c1 in rig["joints"]}
