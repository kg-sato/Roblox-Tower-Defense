"""Familiar shape cleanup for the game (T090): scale, origin and a rig-ready base pose. Blender headless.

Run:  blender -b --factory-startup -P cleanup_familiar.py -- <in.glb> <out_dir> <name> <smooth_iters> <bands 0|1> [target_tris] [height]

Steps: import, merge, remove doubles, recalculate normals, optional Laplacian-style smoothing (to soften the stair-steps of the silhouette-carved
models), decimate to the triangle budget, smooth shading, scale to a fixed height, put the origin at the feet centre (Z up in Blender),
a neutral upright pose, a small armature (Root, plus Torso and Head when bands=1, with height-based weights), preview renders, export GLB and FBX,
and write <name>_stats.json with the measured numbers.
This is a base for rigging, not a finished rig: limbs are not separate and not weighted (a one-mesh model from Hunyuan3D has none).
"""
import json
import math
import os
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, out_dir, name = os.path.abspath(argv[0]), os.path.abspath(argv[1]), argv[2]  # absolute: Blender resolves relative render paths against the drive root
smooth_iters = int(argv[3])
bands = argv[4] == "1"
target_tris = int(argv[5]) if len(argv) > 5 else 6000
height = float(argv[6]) if len(argv) > 6 else 4.0
os.makedirs(out_dir, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in scene.objects if o.type == "MESH"]
if not meshes:
    raise SystemExit("no mesh in " + src)
for o in scene.objects:
    o.select_set(o.type == "MESH")
bpy.context.view_layer.objects.active = meshes[0]
bpy.ops.object.join()
mesh = bpy.context.view_layer.objects.active
mesh.name = name
for o in list(scene.objects):
    if o is not mesh:
        bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode="OBJECT")


def tri_count(obj):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    m = ev.to_mesh()
    m.calc_loop_triangles()
    n = len(m.loop_triangles)
    ev.to_mesh_clear()
    return n


before = tri_count(mesh)
if smooth_iters > 0:
    sm = mesh.modifiers.new("Smooth", "SMOOTH")
    sm.factor = 0.7
    sm.iterations = smooth_iters
    bpy.ops.object.modifier_apply(modifier=sm.name)
if before > target_tris:
    mod = mesh.modifiers.new("Decimate", "DECIMATE")
    mod.ratio = target_tris / before
    bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.ops.object.shade_smooth()
after = tri_count(mesh)


def bounds(obj):
    cs = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    return (Vector((min(c.x for c in cs), min(c.y for c in cs), min(c.z for c in cs))),
            Vector((max(c.x for c in cs), max(c.y for c in cs), max(c.z for c in cs))))


mn, mx = bounds(mesh)
s = height / (mx.z - mn.z)
mesh.scale = (s, s, s)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
mn, mx = bounds(mesh)
mesh.location = (-(mn.x + mx.x) / 2, -(mn.y + mx.y) / 2, -mn.z)
bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
mn, mx = bounds(mesh)

mat = bpy.data.materials.new(name + "_Mat")
mat.diffuse_color = (0.72, 0.72, 0.76, 1.0)
mat.use_nodes = True
bsdf = mat.node_tree.nodes.get("Principled BSDF")
if bsdf:
    bsdf.inputs["Base Color"].default_value = (0.72, 0.72, 0.76, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.6
mesh.data.materials.clear()
mesh.data.materials.append(mat)

# --- armature: Root, and Torso/Head for humanoid-proportioned figures; weights by height ---
arm_data = bpy.data.armatures.new(name + "_Rig")
arm = bpy.data.objects.new(name + "_Rig", arm_data)
scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
root = arm_data.edit_bones.new("Root")
root.head, root.tail = (0, 0, 0), (0, 0, height * 0.2)
if bands:
    torso = arm_data.edit_bones.new("Torso")
    torso.head, torso.tail = (0, 0, height * 0.2), (0, 0, height * 0.62)
    torso.parent = root
    head = arm_data.edit_bones.new("Head")
    head.head, head.tail = (0, 0, height * 0.62), (0, 0, height * 0.95)
    head.parent = torso
bpy.ops.object.mode_set(mode="OBJECT")
mesh.parent = arm
if bands:
    vg_torso = mesh.vertex_groups.new(name="Torso")
    vg_head = mesh.vertex_groups.new(name="Head")
    for v in mesh.data.vertices:
        t = max(0.0, min(1.0, (v.co.z / height - 0.58) / 0.14))
        w = t * t * (3 - 2 * t)  # smoothstep between 58% and 72% of the height
        if w < 1:
            vg_torso.add([v.index], 1 - w, "REPLACE")
        if w > 0:
            vg_head.add([v.index], w, "REPLACE")
else:
    vg_root = mesh.vertex_groups.new(name="Root")
    vg_root.add([v.index for v in mesh.data.vertices], 1.0, "REPLACE")
mm = mesh.modifiers.new("Armature", "ARMATURE")
mm.object = arm

# --- preview stills ---
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "MATERIAL"
scene.render.resolution_x = scene.render.resolution_y = 384
world = bpy.data.worlds.new("W")
scene.world = world
world.color = (0.2, 0.22, 0.3)
cam_data = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
cam_data.lens = 70
for label, angle in (("front", 0), ("three_quarter", 40), ("side", 90)):
    a = math.radians(angle)
    d = height * 3.1
    cam.location = (math.sin(a) * d, -math.cos(a) * d, height * 0.55)
    cam.rotation_euler = (Vector((0, 0, height * 0.5)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(out_dir, f"{name}_{label}.png")
    bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)

for o in scene.objects:
    o.select_set(o in (mesh, arm))
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, name + ".fbx"), use_selection=True, object_types={"ARMATURE", "MESH"},
                         add_leaf_bones=False, apply_scale_options="FBX_SCALE_ALL", bake_anim=False)
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + ".glb"), use_selection=True, export_format="GLB")

mn, mx = bounds(mesh)
stats = {"name": name, "triangles_before": before, "triangles_after": after, "height": round(mx.z - mn.z, 4),
         "min_z": round(mn.z, 5), "centre_x": round((mn.x + mx.x) / 2, 5), "centre_y": round((mn.y + mx.y) / 2, 5),
         "width_x": round(mx.x - mn.x, 3), "depth_y": round(mx.y - mn.y, 3), "bones": [b.name for b in arm_data.bones],
         "vertex_groups": [g.name for g in mesh.vertex_groups], "smooth_iters": smooth_iters}
with open(os.path.join(out_dir, name + "_stats.json"), "w") as f:
    json.dump(stats, f)
print("STATS", json.dumps(stats))
