"""Rig an enemy with an archetype template and describe its Walk, Hit and Death clips (T142), Blender headless.
Run:  blender -b --factory-startup -P rig_enemy.py -- <in_glb> <out_dir> <name> <archetype>
Reuses rig_spec.template (the familiar skeletons, core chain Root>Pelvis>Spine>Chest>Neck>Head) and the same automatic skinning as rig_template.py (inverse distance, power 4,
at most 4 bones per vertex, weights sum to 1). OVERRIDES moves bones for models whose shape does not fit the template (fractions of the bounding box, like rig_spec).
Writes <out_dir>/<name>_rigged.glb (mesh + armature + skin, no animation), <name>_clips.json (clip data from enemy_clips.py, Roblox mesh-space convention) and <name>_rig_stats.json
(bones, owned vertices, influence and weight checks, and a pose test per clip measured on the evaluated mesh: Walk at 0.25 s, Hit at 0.1 s, Death at 1.2 s).
Limits: automatic weights, not hand-painted; template bones with no geometry near them own few vertices; look UNVERIFIED."""
import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import enemy_clips
import rig_spec

in_glb, out_dir, name, arch = sys.argv[sys.argv.index("--") + 1:][:4]
in_glb, out_dir = os.path.abspath(in_glb), os.path.abspath(out_dir)
os.makedirs(out_dir, exist_ok=True)

# per-model bone overrides: name -> (head, tail) fractions; the wisp's tail runs backwards along +Y, not down
OVERRIDES = {
    "FogWisp": {"Trail1": ((0, 0.35, 0.30), (0, 0.70, 0.22)), "Trail2": ((0, 0.70, 0.22), (0, 1.0, 0.10))},
}

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=in_glb)
scene = bpy.context.scene
meshes = [o for o in scene.objects if o.type == "MESH"]
for o in scene.objects:
    o.select_set(o.type == "MESH")
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
mesh = bpy.context.view_layer.objects.active
mesh.name = name
for o in list(scene.objects):
    if o is not mesh:
        bpy.data.objects.remove(o, do_unlink=True)
mesh.parent = None
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
mesh.data.calc_loop_triangles()
tris = len(mesh.data.loop_triangles)

co = np.array([v.co[:] for v in mesh.data.vertices], dtype=float)
mn, mx = co.min(axis=0), co.max(axis=0)
ctr, half = (mn + mx) / 2, (mx - mn) / 2
H = mx[2] - mn[2]


def pos(f):
    return Vector((ctr[0] + f[0] * half[0], ctr[1] + f[1] * half[1], mn[2] + f[2] * H))


bones = []
for bname, parent, h, t in rig_spec.template(arch):
    ov = OVERRIDES.get(name, {})
    if bname in ov:
        h, t = ov[bname]
    elif bname.endswith(".R") and bname[:-2] + ".L" in ov:
        h, t = (tuple(-v if i == 0 else v for i, v in enumerate(p)) for p in ov[bname[:-2] + ".L"])
    bones.append((bname, parent, h, t))
arm_data = bpy.data.armatures.new(name + "_Rig")
arm = bpy.data.objects.new(name + "_Rig", arm_data)
scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
eb = {}
for bname, parent, h, t in bones:
    b = arm_data.edit_bones.new(bname)
    b.head, b.tail = pos(h), pos(t)
    if parent:
        b.parent = eb[parent]
    eb[bname] = b
bpy.ops.object.mode_set(mode="OBJECT")

heads = np.array([pos(h)[:] for _, _, h, _ in bones])
tails = np.array([pos(t)[:] for _, _, _, t in bones])
seg = tails - heads
seg2 = (seg * seg).sum(axis=1)
d = np.zeros((len(co), len(bones)))
for i in range(len(bones)):
    u = np.clip(((co - heads[i]) @ seg[i]) / seg2[i], 0, 1)
    d[:, i] = np.linalg.norm(co - (heads[i] + u[:, None] * seg[i]), axis=1)
w = 1.0 / (d + 0.03 * H) ** 4
order = np.argsort(-w, axis=1)[:, :4]
W = np.zeros_like(w)
rows = np.arange(len(co))[:, None]
W[rows, order] = w[rows, order]
W /= W.sum(axis=1, keepdims=True)
for i, (bname, _, _, _) in enumerate(bones):
    vg = mesh.vertex_groups.new(name=bname)
    for vi in np.where(W[:, i] > 1e-4)[0]:
        vg.add([int(vi)], float(W[vi, i]), "REPLACE")
mesh.parent = arm
mod = mesh.modifiers.new("Armature", "ARMATURE")
mod.object = arm

owned = {b[0]: int((W[:, i] >= 0.3).sum()) for i, b in enumerate(bones)}
infl = (W > 1e-4).sum(axis=1)
wsum = W.sum(axis=1)


def evaluated():
    bpy.context.view_layer.update()
    ev = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
    m = ev.to_mesh()
    pts = np.array([v.co[:] for v in m.vertices])
    ev.to_mesh_clear()
    return pts


# Roblox mesh space = (-x, z, y) of Blender space (model faces -Y in Blender, -Z in Roblox); the map is its own inverse
MR = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))


def apply_pose(pose):
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
    for bname, spec in pose.items():
        pb = arm.pose.bones.get(bname)
        if pb is None:
            continue
        s = list(spec) + [0] * (6 - len(spec))
        rr = Matrix.Rotation(math.radians(s[0]), 3, "X") @ Matrix.Rotation(math.radians(s[1]), 3, "Y") @ Matrix.Rotation(math.radians(s[2]), 3, "Z")
        rest = pb.bone.matrix_local.to_3x3()
        pb.rotation_quaternion = (rest.inverted() @ (MR @ rr @ MR) @ rest).to_quaternion()
        pb.location = rest.inverted() @ (MR @ Vector((s[3] * H, s[4] * H, s[5] * H)))


bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="POSE")
apply_pose({})
rest_pts = evaluated()
tests = {}
for clip, t in (("Walk", 0.25), ("Hit", 0.1), ("Death", 1.2)):
    apply_pose(enemy_clips.sample(arch, clip, t))
    pts = evaluated()
    moved = np.linalg.norm(pts - rest_pts, axis=1)
    tests[clip] = {"t": t, "vertices_moved": int((moved > 0.01 * H).sum()), "max_move_height_fraction": round(float(moved.max() / H), 4), "finite": bool(np.isfinite(pts).all())}
apply_pose({})
bpy.ops.object.mode_set(mode="OBJECT")

stats = {"name": name, "archetype": arch, "triangles": tris, "vertices": int(len(co)), "height": round(float(H), 3), "bones": [b[0] for b in bones], "max_influences": int(infl.max()),
         "weight_sum_min": round(float(wsum.min()), 5), "weight_sum_max": round(float(wsum.max()), 5), "owned_vertices_by_bone": owned, "pose_tests": tests, "overrides": sorted(OVERRIDES.get(name, {}))}
for o in scene.objects:
    o.select_set(o in (mesh, arm))
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + "_rigged.glb"), use_selection=True, export_format="GLB", export_animations=False)
with open(os.path.join(out_dir, name + "_rig_stats.json"), "w") as f:
    json.dump(stats, f, indent=1)
with open(os.path.join(out_dir, name + "_clips.json"), "w") as f:
    json.dump({"name": name, "archetype": arch, "convention": __doc__.split("\n")[0] and "rotation degrees about Roblox mesh-space axes (as Studio_Export/FamiliarClips.luau); translation in model heights; bones as in Blender/rig_spec.py",
               "model_height_blender_units": round(float(H), 3), "clips": enemy_clips.clip_data(arch)}, f)
print("RIG_DONE", name, arch, tris, json.dumps(tests), json.dumps(owned))
