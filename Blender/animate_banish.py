"""Banish animation for a textured familiar (T095): dismissed, drawn down and away (36 frames, one shot), Blender headless.

Run:  blender -b --factory-startup -P animate_banish.py -- <textured_dir> <out_dir> <name> <bands 0|1>

Keys a 36-frame one-shot action called Banish at 30 fps (1.2 s): a small anticipation swell (frame 6, scale 1.05), then the figure turns away
(yaw to -140 degrees), sinks below the floor and shrinks to 2 percent (frame 36), accelerating (ease-in). It ends hidden, not at rest.
Three-bone figures bow the head as they go. Exports <name>_banish.glb and .fbx, <name>_banish_stats.json (height ratio per frame) and four stills.
Limits: no limbs; same curve for every familiar.
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
act = bpy.data.actions.new("Banish")
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
# frame: (yaw, up offset in heights, scale, head bow in degrees)
BANISH = ((1, 0, 0, 1.0, 0), (6, 6, 0.02, 1.05, -4), (12, -30, -0.01, 0.8, 8), (18, -62, -0.05, 0.55, 14),
          (24, -92, -0.1, 0.32, 16), (30, -120, -0.15, 0.12, 12), (36, -140, -0.18, 0.02, 0))
for fr, yaw, up, sc, tip in BANISH:
    kw = {"Root": ((0, yaw, 0), (0, H * up, 0), S(sc))}
    if "Head" in bones:
        kw["Head"] = ((tip, 0, 0), Z0, ID)
    pose(fr, **kw)
bpy.ops.object.mode_set(mode="OBJECT")
scene.frame_end = 36
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


FR = [1, 6, 12, 18, 24, 30, 36]
bb = {}
for f in FR:
    pts = positions(f)
    bb[f] = max(p.z for p in pts) - min(p.z for p in pts)
full = bb[1]
end_pts = positions(1)
scene.frame_set(1)
stats = {"name": name, "frames": 36, "fps": 30, "bones": [b.name for b in arm_data.bones], "height": round(height, 3),
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
    scene.render.filepath = os.path.join(out_dir, f"{name}_banish_f{f:03d}.png")
    bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
scene.frame_set(1)

# --- export ---
for o in scene.objects:
    o.select_set(o in (mesh, arm))
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + "_banish.glb"), use_selection=True, export_format="GLB", export_animations=True,
                          export_frame_range=True)
bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, name + "_banish.fbx"), use_selection=True, object_types={"ARMATURE", "MESH"}, add_leaf_bones=False,
                         bake_anim=True, bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False, path_mode="COPY", embed_textures=True)
with open(os.path.join(out_dir, name + "_banish_stats.json"), "w") as f:
    json.dump(stats, f)
print("BANISH_DONE", json.dumps(stats))
