"""Hunyuan3D .glb -> game-ready pet with animation clips (Blender, headless).

Run:  blender -b --factory-startup -P process_pet.py -- <in.glb> <out_dir> <name> [target_tris] [height]

Steps: import, merge, clean, decimate, ground the model, give it one flat colour, add a one-bone
rig, key three clips (Idle, Attack, Spawn), render preview stills, export FBX and GLB.
Shape only: Hunyuan3D here gives no textures; colour is applied again in Studio.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, out_dir, name = argv[0], argv[1], argv[2]
target_tris = int(argv[3]) if len(argv) > 3 else 2800
height = float(argv[4]) if len(argv) > 4 else 4.0
os.makedirs(out_dir, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.fps = 30

# --- import and merge ---
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

# --- clean + decimate to the triangle budget ---
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
if before > target_tris:
    mod = mesh.modifiers.new("Decimate", "DECIMATE")
    mod.ratio = target_tris / before
    bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.ops.object.shade_smooth()
after = tri_count(mesh)

# --- ground and scale: feet on z=0, centred, fixed height ---
corners = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
mn = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
mx = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
scale = height / (mx.z - mn.z)
mesh.scale = (scale, scale, scale)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
corners = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
cx = (min(c.x for c in corners) + max(c.x for c in corners)) / 2
cy = (min(c.y for c in corners) + max(c.y for c in corners)) / 2
mesh.location = (-cx, -cy, -min(c.z for c in corners))
bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)

# --- one flat material (colour is re-applied in Studio) ---
mat = bpy.data.materials.new(name + "_Mat")
mat.diffuse_color = (1.0, 0.72, 0.25, 1.0)
mat.use_nodes = True
bsdf = mat.node_tree.nodes.get("Principled BSDF")
if bsdf:
    bsdf.inputs["Base Color"].default_value = (1.0, 0.72, 0.25, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.5
mesh.data.materials.clear()
mesh.data.materials.append(mat)

# --- one-bone rig: every vertex follows the root bone ---
arm_data = bpy.data.armatures.new(name + "_Rig")
arm = bpy.data.objects.new(name + "_Rig", arm_data)
scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
bone = arm_data.edit_bones.new("Root")
bone.head = (0, 0, 0)
bone.tail = (0, 0, height * 0.35)
bpy.ops.object.mode_set(mode="OBJECT")
vg = mesh.vertex_groups.new(name="Root")
vg.add([v.index for v in mesh.data.vertices], 1.0, "REPLACE")
mesh.parent = arm
mm = mesh.modifiers.new("Armature", "ARMATURE")
mm.object = arm

# --- animation clips on the root bone ---
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="POSE")
pb = arm.pose.bones["Root"]
pb.rotation_mode = "XYZ"
arm.animation_data_create()


def key(frame, loc=(0, 0, 0), rot=(0, 0, 0), scl=(1, 1, 1)):
    pb.location = loc
    pb.rotation_euler = rot
    pb.scale = scl
    pb.keyframe_insert("location", frame=frame)
    pb.keyframe_insert("rotation_euler", frame=frame)
    pb.keyframe_insert("scale", frame=frame)


def clip(clip_name, frames, build):
    act = bpy.data.actions.new(clip_name)
    arm.animation_data.action = act
    build()
    act.use_fake_user = True
    track = arm.animation_data.nla_tracks.new()
    track.name = clip_name
    track.strips.new(clip_name, frames[0], act)
    arm.animation_data.action = None


h = height
# Idle: gentle bob and breathing squash, loops in 36 frames
clip("Idle", (1, 36), lambda: [
    key(1), key(10, (0, 0, h * 0.04), (0, 0, 0), (0.98, 0.98, 1.04)),
    key(19), key(28, (0, 0, h * 0.03), (0, 0, 0), (1.02, 1.02, 0.97)), key(36),
])
# Attack: wind-up squash, lunge forward, recover (18 frames)
clip("Attack", (1, 18), lambda: [
    key(1), key(5, (0, h * 0.04, -h * 0.03), (math.radians(-12), 0, 0), (1.06, 1.06, 0.88)),
    key(9, (0, -h * 0.25, h * 0.05), (math.radians(14), 0, 0), (0.94, 0.94, 1.12)), key(18),
])
# Spawn: pop in with overshoot (24 frames)
clip("Spawn", (1, 24), lambda: [
    key(1, scl=(0.05, 0.05, 0.05)), key(10, scl=(1.18, 1.18, 0.85)),
    key(16, scl=(0.94, 0.94, 1.08)), key(24),
])
bpy.ops.object.mode_set(mode="OBJECT")

# --- preview stills (Workbench: robust, no GPU settings needed) ---
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "MATERIAL"
scene.render.resolution_x = scene.render.resolution_y = 512
scene.render.film_transparent = False
world = bpy.data.worlds.new("W")
scene.world = world
world.color = (0.18, 0.2, 0.28)
cam_data = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
cam_data.lens = 70
scene.frame_set(100)  # past every clip: all tracks hold their neutral end pose
for label, angle in (("front", 0), ("three_quarter", 40), ("side", 90), ("back", 180)):
    a = math.radians(angle)
    d = height * 3.1
    cam.location = (math.sin(a) * d, -math.cos(a) * d, height * 0.55)
    direction = Vector((0, 0, height * 0.5)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(out_dir, f"{name}_{label}.png")
    bpy.ops.render.render(write_still=True)

# Attack frames (contact sheet source): play the Attack clip alone
for t in arm.animation_data.nla_tracks:
    t.mute = t.name != "Attack"
for i, f in enumerate((1, 5, 9, 14)):
    scene.frame_set(f)
    a = math.radians(40)
    d = height * 3.1
    cam.location = (math.sin(a) * d, -math.cos(a) * d, height * 0.55)
    direction = Vector((0, 0, height * 0.5)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(out_dir, f"{name}_attack_{i}.png")
    bpy.ops.render.render(write_still=True)
for t in arm.animation_data.nla_tracks:
    t.mute = False
scene.frame_set(100)

# --- export ---
bpy.data.objects.remove(cam, do_unlink=True)
for o in scene.objects:
    o.select_set(o in (mesh, arm))
bpy.context.view_layer.objects.active = arm
fbx = os.path.join(out_dir, name + ".fbx")
bpy.ops.export_scene.fbx(
    filepath=fbx, use_selection=True, add_leaf_bones=False, bake_anim=True,
    bake_anim_use_all_actions=False, bake_anim_use_nla_strips=True, bake_anim_use_all_bones=True,
    object_types={"ARMATURE", "MESH"}, apply_scale_options="FBX_SCALE_ALL",
    axis_forward="-Z", axis_up="Y", bake_space_transform=True,  # fixes the 90-degree tilt seen after the first Roblox import
)
glb = os.path.join(out_dir, name + ".glb")
bpy.ops.export_scene.gltf(filepath=glb, use_selection=True, export_format="GLB", export_animations=True,
                          export_animation_mode="NLA_TRACKS")
print(f"RESULT {name}: triangles {before} -> {after}, height {height}, clips Idle/Attack/Spawn")
print("OUTPUT", fbx, glb)
