"""Spawn animation for a textured familiar (T094): summoned in, not a pop (45 frames, one shot), Blender headless.

Run:  blender -b --factory-startup -P animate_spawn.py -- <textured_dir> <out_dir> <name> <bands 0|1>

Imports <textured_dir>/<name>.glb, builds the same starter armature and keys a 45-frame one-shot action called Spawn at 30 fps (1.5 s):
the figure starts tiny, sunk below the floor and turned 120 degrees, then rises and unwinds with an ease-out (frames 1 to 30, scale 0.04 to 1.07),
overshoots slightly (30), settles (38) and rests at the exact rest pose (45). On three-bone figures the head lags behind (tips back, then catches up).
Exports <name>_spawn.glb and <name>_spawn.fbx (baked), <name>_spawn_stats.json with the height ratio per frame, and four stills.
Pose-bone axes (measured): loc Y = up, rot Y = yaw, rot X positive = lean forward. Limits: no limbs, so the same motion for every familiar.
"""
import json
import math
import os
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
tex_dir, out_dir, name, bands = os.path.abspath(argv[0]), os.path.abspath(argv[1]), argv[2], argv[3] == "1"
os.makedirs(out_dir, exist_ok=True)
FRAMES = 30
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.fps = 30
scene.frame_start, scene.frame_end = 1, FRAMES

bpy.ops.import_scene.gltf(filepath=os.path.join(tex_dir, name + ".glb"))
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
zs = [v.co.z for v in mesh.data.vertices]
height = max(zs) - min(zs)

# --- armature (same layout as the cleanup step) ---
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
    vt = mesh.vertex_groups.new(name="Torso")
    vh = mesh.vertex_groups.new(name="Head")
    for v in mesh.data.vertices:
        t = max(0.0, min(1.0, (v.co.z / height - 0.58) / 0.14))
        w = t * t * (3 - 2 * t)
        if w < 1:
            vt.add([v.index], 1 - w, "REPLACE")
        if w > 0:
            vh.add([v.index], w, "REPLACE")
else:
    vr = mesh.vertex_groups.new(name="Root")
    vr.add([v.index for v in mesh.data.vertices], 1.0, "REPLACE")
mm = mesh.modifiers.new("Armature", "ARMATURE")
mm.object = arm

# --- keyframes ---
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="POSE")
for pb in arm.pose.bones:
    pb.rotation_mode = "XYZ"
arm.animation_data_create()
act = bpy.data.actions.new("Spawn")
arm.animation_data.action = act
d = math.radians
H = height


def key(bone, frame, rot=None, loc=None, scl=None):
    pb = arm.pose.bones[bone]
    if rot is not None:
        pb.rotation_euler = (d(rot[0]), d(rot[1]), d(rot[2]))
        pb.keyframe_insert("rotation_euler", frame=frame)
    if loc is not None:
        pb.location = loc
        pb.keyframe_insert("location", frame=frame)
    if scl is not None:
        pb.scale = scl
        pb.keyframe_insert("scale", frame=frame)


def pose(frame, **kw):
    """Key every bone at a frame; bones not mentioned stay at rest. kw: bone=(rot, loc, scl)."""
    for pb in arm.pose.bones:
        rot, loc, scl = kw.get(pb.name, ((0, 0, 0), (0, 0, 0), (1, 1, 1)))
        key(pb.name, frame, rot=rot, loc=loc, scl=scl)


ID = (1, 1, 1)
Z0 = (0, 0, 0)
bones = [b.name for b in arm.pose.bones]
S = lambda s: (s, s, s)
# frame: (yaw, up offset in heights, scale, head tip back in degrees)
SPAWN = ((1, 120, -0.18, 0.04, 0), (6, 84, -0.14, 0.2, 0), (12, 52, -0.09, 0.42, -6), (18, 26, -0.045, 0.7, -10),
         (24, 8, -0.01, 0.94, -6), (30, -4, 0.01, 1.07, 2), (38, 1, 0, 0.98, 0), (45, 0, 0, 1.0, 0))
for fr, yaw, up, sc, tip in SPAWN:
    kw = {"Root": ((0, yaw, 0), (0, H * up, 0), S(sc))}
    if "Head" in bones:
        kw["Head"] = ((tip, 0, 0), Z0, ID)
    pose(fr, **kw)
bpy.ops.object.mode_set(mode="OBJECT")
scene.frame_end = 45
for fc in act.fcurves if hasattr(act, "fcurves") else []:
    for kp in fc.keyframe_points:
        kp.interpolation = "BEZIER"
        kp.handle_left_type = kp.handle_right_type = "AUTO_CLAMPED"


# --- measure motion: evaluated vertex positions at chosen frames ---
def positions(frame):
    scene.frame_set(frame)
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg)
    m = ev.to_mesh()
    pts = [Vector(v.co) for v in m.vertices]
    ev.to_mesh_clear()
    return pts


FR = [1, 4, 6, 10, 12, 18, 24, 30, 38, 45]
bb = {}
for f in FR:
    pts = positions(f)
    bb[f] = max(p.z for p in pts) - min(p.z for p in pts)
scene.frame_set(45)
full = bb[45]
end_pts = positions(45)
scene.frame_set(1)
stats = {"name": name, "frames": 45, "fps": 30, "bones": [b.name for b in arm_data.bones], "height": round(height, 3),
         "height_ratio_by_frame": {str(k): round(v / full, 4) for k, v in bb.items()},
         "max_height_ratio": round(max(bb.values()) / full, 4)}
rest_pts = [Vector(v.co) for v in mesh.data.vertices]
stats["rest_error"] = round(max((p - r).length for p, r in zip(end_pts, rest_pts)), 6)
# restore the action pose (the animation data still holds the keys)
scene.frame_set(1)

# --- stills at four frames ---
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
for i, f in enumerate((1, 12, 24, 34)):
    scene.frame_set(f)
    a = math.radians(30)
    dd = height * 3.1
    cam.location = (math.sin(a) * dd, -math.cos(a) * dd, height * 0.55)
    cam.rotation_euler = (Vector((0, 0, height * 0.5)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(out_dir, f"{name}_spawn_f{f:03d}.png")
    bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
scene.frame_set(1)

# --- export ---
for o in scene.objects:
    o.select_set(o in (mesh, arm))
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + "_spawn.glb"), use_selection=True, export_format="GLB", export_animations=True,
                          export_frame_range=True)
bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, name + "_spawn.fbx"), use_selection=True, object_types={"ARMATURE", "MESH"}, add_leaf_bones=False,
                         bake_anim=True, bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False, path_mode="COPY", embed_textures=True)
with open(os.path.join(out_dir, name + "_spawn_stats.json"), "w") as f:
    json.dump(stats, f)
print("SPAWN_DONE", json.dumps(stats))
