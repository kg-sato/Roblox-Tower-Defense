"""Attack animation for a textured familiar (T093): windup, release, recover (30 frames, one shot), Blender headless.

Run:  blender -b --factory-startup -P animate_attack.py -- <textured_dir> <out_dir> <name> <bands 0|1>

Imports <textured_dir>/<name>.glb, builds the same starter armature as cleanup_familiar.py and keys a 30-frame one-shot action called Attack
at 30 fps: windup (frames 1 to 8), release (8 to 11, the fastest part), hold (11 to 13), recover (13 to 24 with a small overshoot), rest (24 to 30).
It follows the familiar's role. Exports <name>_attack.glb and <name>_attack.fbx (baked), writes <name>_attack_stats.json with measured motion and
four preview stills.
Pose-bone axes (measured in Blender 5.3): loc X = world +X, loc Y = up, loc Z = world -Y (forward, toward the camera), rot X positive = lean forward.
Limits: one-mesh models have no limbs, so attacks use the Root, Torso and Head bones only.
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
act = bpy.data.actions.new("Attack")
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
# Phases: 1 rest, 8 windup peak, 11 release peak, 13 hold end, 20 overshoot, 24 settle, 30 rest.
# Pose-bone axes (measured): loc Z = forward (world -Y), loc Y = up, rot X positive = lean forward.
R = {}
if name == "Ember":  # Scorch: gather and lean back, then flare forward and up
    R["wind"] = {"Root": ((-8, 0, 0), (0, -H * 0.02, -H * 0.06), (1.06, 0.9, 1.06))}
    R["rel"] = {"Root": ((16, 0, 0), (0, H * 0.04, H * 0.10), (0.92, 1.18, 0.92))}
    R["over"] = {"Root": ((-3, 0, 0), (0, 0, -H * 0.01), (1.02, 0.97, 1.02))}
elif name == "MothLantern":  # Reveal: raise the lantern, then point it forward
    R["wind"] = {"Torso": ((-6, 0, 0), Z0, ID), "Head": ((-18, 0, 0), Z0, ID)}
    R["rel"] = {"Torso": ((14, 0, 0), (0, 0, H * 0.04), ID), "Head": ((20, 0, 0), Z0, ID), "Root": (Z0, (0, 0, H * 0.04), ID)}
    R["over"] = {"Torso": ((-2, 0, 0), Z0, ID), "Head": ((-4, 0, 0), Z0, ID)}
elif name == "BrassHound":  # Harry: crouch, lunge and bite
    R["wind"] = {"Root": ((-6, 0, 0), (0, -H * 0.04, -H * 0.05), (1.06, 0.86, 1.06))}
    R["rel"] = {"Root": ((16, 0, 0), (0, H * 0.02, H * 0.16), (0.94, 1.1, 0.94))}
    R["over"] = {"Root": ((-3, 0, 0), (0, 0, H * 0.01), (1.02, 0.98, 1.02))}
elif name == "Sentinel":  # Breach: raise the halberd back, then thrust
    R["wind"] = {"Torso": ((-12, 0, 0), Z0, ID), "Head": ((-6, 0, 0), Z0, ID), "Root": (Z0, (0, 0, -H * 0.03), ID)}
    R["rel"] = {"Torso": ((18, 0, 0), Z0, ID), "Head": ((8, 0, 0), Z0, ID), "Root": (Z0, (0, 0, H * 0.10), ID)}
    R["over"] = {"Torso": ((-3, 0, 0), Z0, ID)}
elif name == "Frostling":  # Chill: breathe in, then blow
    R["wind"] = {"Torso": ((-10, 0, 0), Z0, (1.05, 1.0, 1.05)), "Head": ((-12, 0, 0), Z0, ID)}
    R["rel"] = {"Torso": ((9, 0, 0), Z0, (0.96, 1.0, 0.96)), "Head": ((22, 0, 0), Z0, ID), "Root": (Z0, (0, 0, H * 0.03), ID)}
    R["over"] = {"Head": ((-4, 0, 0), Z0, ID)}
elif name == "Gargoyle":  # Crush: rear up, then slam
    R["wind"] = {"Torso": ((-12, 0, 0), Z0, (1, 1.04, 1)), "Root": (Z0, (0, H * 0.03, 0), ID)}
    R["rel"] = {"Torso": ((24, 0, 0), Z0, (1, 0.94, 1)), "Root": (Z0, (0, -H * 0.03, H * 0.05), ID)}
    R["over"] = {"Torso": ((-3, 0, 0), Z0, ID)}
elif name == "Ward":  # Ward: lift the lantern high with a pulse
    R["wind"] = {"Torso": ((-6, 0, 0), Z0, ID), "Head": ((8, 0, 0), Z0, ID)}
    R["rel"] = {"Torso": ((8, 0, 6), Z0, (1, 1.04, 1)), "Head": ((-16, 0, 0), Z0, ID), "Root": (Z0, (0, H * 0.02, H * 0.03), ID)}
    R["over"] = {"Head": ((3, 0, 0), Z0, ID)}
elif name == "Archivist":  # Hasten: look away, then snap back with a stamp
    R["wind"] = {"Head": ((0, -40, 0), Z0, ID), "Torso": ((-6, 0, 0), Z0, ID)}
    R["rel"] = {"Head": ((10, 6, 0), Z0, ID), "Torso": ((12, 0, 0), Z0, ID), "Root": (Z0, (0, 0, H * 0.04), ID)}
    R["over"] = {"Head": ((-2, -4, 0), Z0, ID)}
elif name == "Mourner":  # Hush: raise the head, then bow and lift a finger
    R["wind"] = {"Head": ((-12, 0, 0), Z0, ID), "Torso": ((-5, 0, 0), Z0, ID)}
    R["rel"] = {"Head": ((26, 0, 0), Z0, ID), "Torso": ((9, 0, 0), Z0, ID), "Root": (Z0, (0, 0, H * 0.03), ID)}
    R["over"] = {"Head": ((-4, 0, 0), Z0, ID)}
elif name == "MirrorChorister":  # Echo: arms up, then forward and down
    R["wind"] = {"Torso": ((-9, 0, 0), Z0, (1, 1.05, 1)), "Head": ((-8, 0, 0), Z0, ID)}
    R["rel"] = {"Torso": ((15, 0, 0), Z0, (1, 0.96, 1)), "Head": ((8, 0, 0), Z0, ID), "Root": (Z0, (0, 0, H * 0.04), ID)}
    R["over"] = {"Torso": ((-3, 0, 0), Z0, ID)}
elif name == "StarDrake":  # Starfall: rear back, then dive
    R["wind"] = {"Root": ((-16, 0, 0), (0, H * 0.03, -H * 0.04), (0.95, 1.1, 0.95))}
    R["rel"] = {"Root": ((22, 0, 0), (0, -H * 0.04, H * 0.14), (1.04, 0.96, 1.04))}
    R["over"] = {"Root": ((-4, 0, 0), Z0, (1, 1.02, 1))}
elif name == "GreyVeilWraith":  # Drain: draw back, then reach forward
    R["wind"] = {"Torso": ((-12, 0, 0), Z0, ID), "Root": (Z0, (0, 0, -H * 0.04), ID)}
    R["rel"] = {"Torso": ((26, 0, 0), Z0, ID), "Root": (Z0, (0, 0, H * 0.14), ID)}
    R["over"] = {"Torso": ((-3, 0, 0), Z0, ID)}
else:
    raise SystemExit("no attack recipe for " + name)

bones = [b.name for b in arm.pose.bones]
for fr, label in ((1, None), (8, "wind"), (11, "rel"), (13, "hold"), (20, "over"), (24, None), (30, None)):
    kw = {}
    if label == "hold":  # hold: the release pose, eased a little
        kw = {k: ((v[0][0] * 0.9, v[0][1] * 0.9, v[0][2] * 0.9), (v[1][0], v[1][1], v[1][2] * 0.85), v[2]) for k, v in R["rel"].items() if k in bones}
    elif label:
        kw = {k: v for k, v in R[label].items() if k in bones}
    pose(fr, **kw)
bpy.ops.object.mode_set(mode="OBJECT")
scene.frame_end = 30
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
frames = [1, 4, 8, 10, 11, 13, 17, 20, 24, 30]
disp = {}
for f in frames:
    pts = positions(f)
    disp[f] = max((p - r).length for p, r in zip(pts, rest))
end_diff = disp[30]
cy = {}
for f in (1, 8, 11):
    pts = positions(f)
    cy[f] = sum(p.y for p in pts) / len(pts)
stats = {"name": name, "frames": 30, "fps": 30, "centroid_y_rest": round(cy[1], 4), "centroid_y_windup": round(cy[8], 4), "centroid_y_release": round(cy[11], 4), "bones": [b.name for b in arm_data.bones],
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
for i, f in enumerate((1, 8, 11, 20)):
    scene.frame_set(f)
    a = math.radians(30)
    dd = height * 3.1
    cam.location = (math.sin(a) * dd, -math.cos(a) * dd, height * 0.55)
    cam.rotation_euler = (Vector((0, 0, height * 0.5)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(out_dir, f"{name}_attack_f{f:03d}.png")
    bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)
scene.frame_set(1)

# --- export ---
for o in scene.objects:
    o.select_set(o in (mesh, arm))
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + "_attack.glb"), use_selection=True, export_format="GLB", export_animations=True,
                          export_frame_range=True)
bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, name + "_attack.fbx"), use_selection=True, object_types={"ARMATURE", "MESH"}, add_leaf_bones=False,
                         bake_anim=True, bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False, path_mode="COPY", embed_textures=True)
with open(os.path.join(out_dir, name + "_attack_stats.json"), "w") as f:
    json.dump(stats, f)
print("ATTACK_DONE", json.dumps(stats))
