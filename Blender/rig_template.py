"""Rig a textured familiar with its archetype template (T106), Blender headless.

Run:  blender -b --factory-startup -P rig_template.py -- <textured_dir> <out_dir> <name>
The archetype comes from rig_spec.ARCHETYPE[name]. Imports <textured_dir>/<name>.glb, joins the meshes, builds the armature from rig_spec (bone positions are fractions
of the model's bounding box), skins by distance to the nearest bone segments (inverse distance, power 4, at most 4 bones per vertex, weights sum to 1), and exports
<out_dir>/<name>_rigged.glb and .fbx plus <name>_rig_stats.json: bone list, weight checks, and a pose test (head turn, spine lean, one limb or tail bend) measured on the
evaluated mesh. No animation is exported: the clips of T092 to T095 are separate and use the core chain only.
Limits: automatic distance weights, not hand-painted: joints will tear a little on thin parts, and a template bone with no geometry near it owns few vertices."""
import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rig_spec

argv = sys.argv[sys.argv.index("--") + 1:]
src_dir, out_dir, name = argv[0], argv[1], argv[2]
src_dir, out_dir = os.path.abspath(src_dir), os.path.abspath(out_dir)
os.makedirs(out_dir, exist_ok=True)
arch = rig_spec.ARCHETYPE[name]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(src_dir, name + ".glb"))
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

co = np.array([v.co[:] for v in mesh.data.vertices], dtype=float)
mn, mx = co.min(axis=0), co.max(axis=0)
ctr, half = (mn + mx) / 2, (mx - mn) / 2
H = mx[2] - mn[2]


def pos(f):
    return Vector((ctr[0] + f[0] * half[0], ctr[1] + f[1] * half[1], mn[2] + f[2] * H))


bones = rig_spec.template(arch)
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

# weights: inverse distance to the bone segments, power 4, 4 nearest, normalised
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
    idx = np.where(W[:, i] > 1e-4)[0]
    for vi in idx:
        vg.add([int(vi)], float(W[vi, i]), "REPLACE")
mesh.parent = arm
mod = mesh.modifiers.new("Armature", "ARMATURE")
mod.object = arm

# --- stats and pose test ---
owned = {b[0]: int((W[:, i] >= 0.3).sum()) for i, b in enumerate(bones)}
infl = (W > 1e-4).sum(axis=1)
wsum = W.sum(axis=1)


def evaluated():
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg)
    m = ev.to_mesh()
    pts = np.array([v.co[:] for v in m.vertices])
    ev.to_mesh_clear()
    return pts


bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="POSE")
for pb in arm.pose.bones:
    pb.rotation_mode = "XYZ"
rest = evaluated()
limb = [b[0] for b in bones if b[0] not in rig_spec.CORE_NAMES and b[0].endswith(".L")][0]  # the first left limb bone (arm, leg or wing), not the tail
tests = {}
for label, bone, axis, deg in (("head_turn", "Head", 2, 30), ("spine_lean", "Spine", 0, 15), ("limb_bend", limb, 0, 40)):
    arm.pose.bones[bone].rotation_euler = (0, 0, 0)
    e = [0, 0, 0]
    e[axis] = math.radians(deg)
    arm.pose.bones[bone].rotation_euler = tuple(e)
    pts = evaluated()
    moved = np.linalg.norm(pts - rest, axis=1)
    tests[label] = {"bone": bone, "deg": deg, "vertices_moved": int((moved > 0.01 * H).sum()), "max_move_height_fraction": round(float(moved.max() / H), 4)}
    arm.pose.bones[bone].rotation_euler = (0, 0, 0)
bpy.ops.object.mode_set(mode="OBJECT")

stats = {"name": name, "archetype": arch, "bones": [b[0] for b in bones], "parents": {b[0]: b[1] for b in bones}, "vertices": int(len(co)), "height": round(float(H), 3),
         "max_influences": int(infl.max()), "weight_sum_min": round(float(wsum.min()), 5), "weight_sum_max": round(float(wsum.max()), 5),
         "owned_vertices_by_bone": owned, "pose_tests": tests}
for o in scene.objects:
    o.select_set(o in (mesh, arm))
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + "_rigged.glb"), use_selection=True, export_format="GLB", export_animations=False)
bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, name + "_rigged.fbx"), use_selection=True, object_types={"ARMATURE", "MESH"}, add_leaf_bones=False,
                         bake_anim=False, path_mode="COPY", embed_textures=True)
with open(os.path.join(out_dir, name + "_rig_stats.json"), "w") as f:
    json.dump(stats, f)
print("RIG_DONE", json.dumps({k: stats[k] for k in ("name", "archetype", "max_influences", "weight_sum_min", "weight_sum_max")}), json.dumps(owned))
