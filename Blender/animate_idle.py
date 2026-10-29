"""Idle animation for a textured familiar (T092): breathing plus one signature motion, Blender headless.

Run:  blender -b --factory-startup -P animate_idle.py -- <textured_dir> <out_dir> <name> <bands 0|1>

Imports <textured_dir>/<name>.glb (the textured, grounded model from bake_familiar_textures.py), builds the same starter armature as
cleanup_familiar.py (Root; plus Torso and Head when bands=1, weighted by height), and keys a 120-frame looping action called Idle at 30 fps:
two breaths (a slow squash and stretch) and one signature motion between frames 36 and 96 that follows the familiar's card gesture.
Exports <name>_idle.glb and <name>_idle.fbx (baked), writes <name>_idle_stats.json with measured vertex motion, and four preview stills.
Limits: one-mesh models have no limbs, so motions use the Root, Torso and Head bones only; they are blocking-quality, not final animation.
Bone axes: bones point up, so local Y is the vertical axis (turn), local X is world X (nod), local Z is world -Y (tilt).
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
FRAMES = 120
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
act = bpy.data.actions.new("Idle")
arm.animation_data.action = act
d = math.radians


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


def reset(frame):
    for pb in arm.pose.bones:
        key(pb.name, frame, rot=(0, 0, 0), loc=(0, 0, 0), scl=(1, 1, 1))


# breathing: two breaths on the Torso (or Root) - squash and stretch along the vertical axis (local Y)
b = "Torso" if bands else "Root"
amp = 0.03
for f, s in ((1, 1.0), (15, 1 + amp), (30, 1.0), (45, 1 - amp * 0.5), (60, 1.0), (75, 1 + amp), (90, 1.0), (105, 1 - amp * 0.5), (121, 1.0)):
    key(b, f, scl=(1 - (s - 1) * 0.4, s, 1 - (s - 1) * 0.4))
if bands:
    for f in (1, 30, 60, 90, 121):
        key("Root", f, rot=(0, 0, 0), loc=(0, 0, 0), scl=(1, 1, 1))
        key("Head", f, rot=(0, 0, 0), loc=(0, 0, 0), scl=(1, 1, 1))
else:
    for f in (1, 121):
        key("Root", f, rot=(0, 0, 0), loc=(0, 0, 0))

SIGNATURE = name
H = height


def sig(bone, frames_values, kind="rot"):
    for f, v in frames_values:
        if kind == "rot":
            key(bone, f, rot=v)
        elif kind == "loc":
            key(bone, f, loc=v)
        else:
            key(bone, f, scl=v)


# Signature motions follow each card's gesture. Frames 36 to 96; start and end at rest so the clip loops.
if name == "Ember":          # lifts its flame: stretch up and lean toward the lantern
    sig("Root", [(30, (0, 0, 0)), (48, (0, 0, -7)), (66, (0, 0, -7)), (84, (0, 0, 0))])
    sig("Root", [(30, (1, 1, 1)), (48, (0.95, 1.12, 0.95)), (66, (0.95, 1.12, 0.95)), (84, (1, 1, 1))], "scl")
    sig("Root", [(30, (0, 0, 0)), (48, (0, H * 0.04, 0)), (66, (0, H * 0.04, 0)), (84, (0, 0, 0))], "loc")
elif name == "MothLantern":  # flutters once (quick side-to-side width pulses), then holds the lantern high
    for f, sx in ((36, 1.0), (40, 1.1), (44, 0.94), (48, 1.1), (52, 0.94), (56, 1.0)):
        key("Torso", f, scl=(sx, 1, 1))
    sig("Head", [(56, (0, 0, 0)), (70, (-14, 0, 0)), (86, (-14, 0, 0)), (100, (0, 0, 0))])
elif name == "BrassHound":   # thumps its tail: quick body wag side to side with a small bounce
    for f, r in ((36, 0), (42, 16), (48, -16), (54, 16), (60, -16), (66, 16), (72, -16), (78, 0)):
        key("Root", f, rot=(0, r, 0))
    sig("Root", [(36, (0, 0, 0)), (42, (0, H * 0.05, 0)), (48, (0, 0, 0)), (54, (0, H * 0.05, 0)), (60, (0, 0, 0)), (66, (0, H * 0.05, 0)), (72, (0, 0, 0))], "loc")
elif name == "Sentinel":     # tips its helmet (head nod and a tip), then lowers the halberd (lean)
    sig("Head", [(36, (0, 0, 0)), (48, (0, 0, 14)), (58, (16, 0, 14)), (66, (0, 0, 8)), (90, (0, 0, 0))])
    sig("Torso", [(66, (0, 0, 0)), (80, (7, 0, 0)), (96, (0, 0, 0))])
elif name == "Frostling":    # blows on its mittens: head forward, then holds them out
    sig("Head", [(36, (0, 0, 0)), (50, (22, 0, 0)), (62, (22, 0, 0)), (76, (-6, 0, 0)), (96, (0, 0, 0))])
    sig("Torso", [(50, (0, 0, 0)), (62, (6, 0, 0)), (76, (-5, 0, 0)), (96, (0, 0, 0))])
elif name == "Gargoyle":     # turns its head very slowly
    sig("Head", [(30, (0, 0, 0)), (66, (0, 38, 0)), (84, (0, 38, 0)), (115, (0, 0, 0))])
elif name == "Ward":         # raises the lantern toward the water: lean and chin up
    sig("Torso", [(36, (0, 0, 0)), (60, (0, 0, 8)), (84, (0, 0, 8)), (100, (0, 0, 0))])
    sig("Head", [(36, (0, 0, 0)), (60, (-14, 0, 0)), (84, (-14, 0, 0)), (100, (0, 0, 0))])
elif name == "Archivist":    # turns its head almost all the way round, then back
    sig("Head", [(36, (0, 0, 0)), (60, (0, 165, 0)), (78, (0, 165, 0)), (96, (0, 0, 0))])
elif name == "Mourner":      # bows its head and holds it
    sig("Head", [(36, (0, 0, 0)), (60, (24, 0, 0)), (84, (24, 0, 0)), (100, (0, 0, 0))])
    sig("Torso", [(36, (0, 0, 0)), (60, (6, 0, 0)), (84, (6, 0, 0)), (100, (0, 0, 0))])
elif name == "MirrorChorister":  # tilts its head and holds out an open palm (a lean the other way)
    sig("Head", [(36, (0, 0, 0)), (56, (0, 0, 16)), (84, (0, 0, 16)), (100, (0, 0, 0))])
    sig("Torso", [(36, (0, 0, 0)), (56, (0, 0, -6)), (84, (0, 0, -6)), (100, (0, 0, 0))])
elif name == "StarDrake":    # sings one long note: the chest swells and the whole body sways
    sig("Root", [(24, (0, 0, 0)), (48, (0, 8, 0)), (72, (0, -8, 0)), (96, (0, 8, 0)), (115, (0, 0, 0))])
    sig("Root", [(24, (1, 1, 1)), (60, (1.04, 1.1, 1.04)), (96, (1.04, 1.1, 1.04)), (115, (1, 1, 1))], "scl")
elif name == "GreyVeilWraith":  # reaches out one long arm: lean forward and to one side, hovering a little
    sig("Torso", [(36, (0, 0, 0)), (64, (10, 0, 8)), (84, (10, 0, 8)), (100, (0, 0, 0))])
    sig("Root", [(30, (0, 0, 0)), (60, (0, H * 0.03, 0)), (90, (0, 0, 0))], "loc")
reset(121) if False else None
for f in (1, 121):  # make the loop closed on every bone
    for pb in arm.pose.bones:
        key(pb.name, f, rot=(0, 0, 0), loc=(0, 0, 0), scl=(1, 1, 1))
bpy.ops.object.mode_set(mode="OBJECT")
scene.frame_end = 121
# smooth in/out everywhere
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


rest = positions(1)
frames = [1, 15, 30, 48, 60, 72, 84, 96, 108, 121]
disp = {}
for f in frames:
    pts = positions(f)
    disp[f] = max((p - r).length for p, r in zip(pts, rest))
end_diff = disp[121]
stats = {"name": name, "frames": 121, "fps": 30, "bones": [b.name for b in arm_data.bones],
         "max_vertex_motion_by_frame": {str(k): round(v, 4) for k, v in disp.items()},
         "max_motion": round(max(disp.values()), 4), "loop_closure_error": round(end_diff, 6), "height": round(height, 3)}

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
for i, f in enumerate((1, 15, 60, 84)):
    scene.frame_set(f)
    a = math.radians(30)
    dd = height * 3.1
    cam.location = (math.sin(a) * dd, -math.cos(a) * dd, height * 0.55)
    cam.rotation_euler = (Vector((0, 0, height * 0.5)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(out_dir, f"{name}_idle_f{f:03d}.png")
    bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
scene.frame_set(1)

# --- export ---
for o in scene.objects:
    o.select_set(o in (mesh, arm))
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + "_idle.glb"), use_selection=True, export_format="GLB", export_animations=True,
                          export_frame_range=True)
bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, name + "_idle.fbx"), use_selection=True, object_types={"ARMATURE", "MESH"}, add_leaf_bones=False,
                         bake_anim=True, bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False, path_mode="COPY", embed_textures=True)
with open(os.path.join(out_dir, name + "_idle_stats.json"), "w") as f:
    json.dump(stats, f)
print("IDLE_DONE", json.dumps(stats))
