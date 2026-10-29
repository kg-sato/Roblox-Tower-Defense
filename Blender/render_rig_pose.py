"""Render pose tests of a rigged familiar (T106): rest, head turn plus first-limb bend, spine lean. Blender headless.
Run:  blender -b --factory-startup -P render_rig_pose.py -- <rigged_dir> <out_dir> <name>
Imports <rigged_dir>/<name>_rigged.glb, poses the template bones, renders three 320 px workbench stills <out_dir>/<name>_rigpose_<k>.png."""
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rig_spec

argv = sys.argv[sys.argv.index("--") + 1:]
rig_dir, out_dir, name = os.path.abspath(argv[0]), os.path.abspath(argv[1]), argv[2]
os.makedirs(out_dir, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(rig_dir, name + "_rigged.glb"))
scene = bpy.context.scene
arm = next(o for o in scene.objects if o.type == "ARMATURE")
mesh = next(o for o in scene.objects if o.type == "MESH")
pts = [mesh.matrix_world @ v.co for v in mesh.data.vertices]
zs = [p.z for p in pts]
height = max(zs) - min(zs)
zmin = min(zs)
limb = [b[0] for b in rig_spec.template(rig_spec.ARCHETYPE[name]) if b[0] not in rig_spec.CORE_NAMES and b[0].endswith(".L")][0]
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "TEXTURE"
scene.render.resolution_x = scene.render.resolution_y = 320
world = bpy.data.worlds.new("W")
scene.world = world
world.color = (0.2, 0.22, 0.3)
cam_data = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
cam_data.lens = 70
a = math.radians(25)
dd = height * 3.1
cam.location = (math.sin(a) * dd, -math.cos(a) * dd, zmin + height * 0.55)
cam.rotation_euler = (Vector((0, 0, zmin + height * 0.5)) - cam.location).to_track_quat("-Z", "Y").to_euler()

bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="POSE")
for pb in arm.pose.bones:
    pb.rotation_mode = "XYZ"
poses = {
    "0rest": {},
    "1limb_head": {"Head": (0, 0, 35), limb: (0, 0, 55)},
    "2lean": {"Spine": (25, 0, 0), "Head": (-15, 0, 0)},
}
for k, bones in poses.items():
    for pb in arm.pose.bones:
        pb.rotation_euler = (0, 0, 0)
    for b, e in bones.items():
        arm.pose.bones[b].rotation_euler = tuple(math.radians(v) for v in e)
    bpy.context.view_layer.update()
    scene.render.filepath = os.path.join(out_dir, f"{name}_rigpose_{k}.png")
    bpy.ops.render.render(write_still=True)
print("RIGPOSE_DONE", name, limb)
