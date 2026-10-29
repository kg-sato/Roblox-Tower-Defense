"""Bake base colour and roughness maps for a cleaned familiar (T091). Blender headless, Cycles on the CPU.

Run:  blender -b --factory-startup -P bake_familiar_textures.py -- <clean_dir> <tex_in_dir> <out_dir> <name> [size]

Reads <clean_dir>/<name>.glb (from cleanup_familiar.py) and <tex_in_dir>/<name>_front|side|back.png (from tools/prep_texture_inputs.py).
Unwraps the model (Smart UV Project), projects the three design-sheet colour views onto it from the front, back and side (blended by the
surface normal) and bakes that into one base-colour map; the roughness map comes from the colour (more saturated, more metallic-looking
means lower roughness) with a little noise for a painted feel. Exports a textured GLB and FBX plus the two PNG maps.
The colours are painted by projection from our own design sheets, not hand-painted in a paint program: the maps are a first pass.
"""
import json
import math
import os
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
clean_dir, tex_in, out_dir, name = [os.path.abspath(a) if i < 3 else a for i, a in enumerate(argv[:4])]
size = int(argv[4]) if len(argv) > 4 else 1024
os.makedirs(out_dir, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 1
scene.cycles.use_denoising = False

bpy.ops.import_scene.gltf(filepath=os.path.join(clean_dir, name + ".glb"))
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

# bounding box in local space (Z up; the cleanup put the origin at the feet centre)
xs = [v.co.x for v in mesh.data.vertices]
ys = [v.co.y for v in mesh.data.vertices]
zs = [v.co.z for v in mesh.data.vertices]
minx, maxx, miny, maxy, minz, maxz = min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)
w, d, h = maxx - minx, maxy - miny, maxz - minz

# UV unwrap
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
bpy.ops.object.mode_set(mode="OBJECT")

img_color = bpy.data.images.new(name + "_BaseColor", size, size, alpha=False)
img_rough = bpy.data.images.new(name + "_Roughness", size, size, alpha=False)
img_rough.colorspace_settings.name = "Non-Color"


def load(label):
    im = bpy.data.images.load(os.path.join(tex_in, f"{name}_{label}.png"))
    im.colorspace_settings.name = "sRGB"
    return im


front_img, side_img, back_img = load("front"), load("side"), load("back")

mat = bpy.data.materials.new(name + "_Bake")
mat.use_nodes = True
nt = mat.node_tree
nt.nodes.clear()
N = nt.nodes.new
L = nt.links.new
out = N("ShaderNodeOutputMaterial")
emit = N("ShaderNodeEmission")
L(emit.outputs["Emission"], out.inputs["Surface"])

texcoord = N("ShaderNodeTexCoord")
sep = N("ShaderNodeSeparateXYZ")
L(texcoord.outputs["Object"], sep.inputs["Vector"])


def math_node(op, a=None, b=None, clamp=False):
    n = N("ShaderNodeMath")
    n.operation = op
    n.use_clamp = clamp
    if a is not None:
        if isinstance(a, (int, float)):
            n.inputs[0].default_value = a
        else:
            L(a, n.inputs[0])
    if b is not None:
        if isinstance(b, (int, float)):
            n.inputs[1].default_value = b
        else:
            L(b, n.inputs[1])
    return n.outputs[0]


# normalised object coordinates in 0..1
ux = math_node("DIVIDE", math_node("SUBTRACT", sep.outputs["X"], minx), w)
uy = math_node("DIVIDE", math_node("SUBTRACT", sep.outputs["Y"], miny), d)
uz = math_node("DIVIDE", math_node("SUBTRACT", sep.outputs["Z"], minz), h)


def image_at(img, u, v):
    comb = N("ShaderNodeCombineXYZ")
    L(u, comb.inputs["X"])
    L(v, comb.inputs["Y"])
    tex = N("ShaderNodeTexImage")
    tex.image = img
    tex.extension = "EXTEND"
    tex.interpolation = "Linear"
    L(comb.outputs["Vector"], tex.inputs["Vector"])
    return tex.outputs["Color"]


front = image_at(front_img, ux, uz)
back = image_at(back_img, math_node("SUBTRACT", 1.0, ux), uz)
side = image_at(side_img, math_node("SUBTRACT", 1.0, uy), uz)  # the side view faces right = -Y, viewed from -X

geo = N("ShaderNodeNewGeometry")
nsep = N("ShaderNodeSeparateXYZ")
L(geo.outputs["Normal"], nsep.inputs["Vector"])
ny = nsep.outputs["Y"]
nx = nsep.outputs["X"]
# front faces look towards -Y; back when the normal's Y is positive
is_back = math_node("GREATER_THAN", ny, 0.0)
mix_fb = N("ShaderNodeMix")
mix_fb.data_type = "RGBA"
L(is_back, mix_fb.inputs["Factor"])
L(front, mix_fb.inputs["A"])
L(back, mix_fb.inputs["B"])
# side blend: use the side view where |nx| dominates |ny|
side_w = math_node("ADD", math_node("MULTIPLY", math_node("SUBTRACT", math_node("ABSOLUTE", nx), math_node("ABSOLUTE", ny)), 4.0), 0.5, clamp=True)
mix_all = N("ShaderNodeMix")
mix_all.data_type = "RGBA"
L(side_w, mix_all.inputs["Factor"])
L(mix_fb.outputs["Result"], mix_all.inputs["A"])
L(side, mix_all.inputs["B"])
color_out = mix_all.outputs["Result"]

# roughness from the colour: saturated, brass-like colours are shinier; plus a little painted noise
hsv = N("ShaderNodeSeparateColor")
hsv.mode = "HSV"
L(color_out, hsv.inputs["Color"])
noise = N("ShaderNodeTexNoise")
noise.inputs["Scale"].default_value = 28.0
noise.inputs["Detail"].default_value = 4.0
L(texcoord.outputs["Object"], noise.inputs["Vector"])
# HSV mode: outputs are hue, saturation, value (the sockets keep their Red, Green, Blue names), so index 1 is the saturation
base_r = math_node("SUBTRACT", 0.82, math_node("MULTIPLY", hsv.outputs[1], 0.5))
jitter = math_node("MULTIPLY", math_node("SUBTRACT", noise.outputs["Fac"], 0.5), 0.22)
rough_out = math_node("ADD", base_r, jitter, clamp=True)
rough_rgb = N("ShaderNodeCombineColor")
for ch in ("Red", "Green", "Blue"):
    L(rough_out, rough_rgb.inputs[ch])

mesh.data.materials.clear()
mesh.data.materials.append(mat)
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)

# Bake colour: emission = projected colour; the active image node receives the bake
target = N("ShaderNodeTexImage")
nt.nodes.active = target


def bake(img, src_socket):
    target.image = img
    for lk in list(emit.inputs["Color"].links):
        nt.links.remove(lk)
    L(src_socket, emit.inputs["Color"])
    nt.nodes.active = target
    bpy.ops.object.bake(type="EMIT", margin=16, use_clear=True)


bake(img_color, color_out)
bake(img_rough, rough_rgb.outputs["Color"])

# clean-up (T407): a 5 by 5 median on the baked colour removes the speckle that the three-view projection leaves where a view's colour changes or a design-sheet texel is stray
# (specks under about 12 px across; painted lines 3 px wide or more survive). Set CLEAN_TEXTURE=0 to skip. The speckle share (pixels more than 24 levels from their 5 by 5 median) goes into the stats file.
import numpy as np


def med5(q):
    pad = np.pad(q, ((2, 2), (2, 2), (0, 0)), mode="edge")
    return np.median(np.stack([pad[y:y + size, x:x + size] for y in range(5) for x in range(5)]), axis=0).astype(np.uint8)


def speckle(q):
    painted = q.astype(int).sum(2) > 30
    return float(((np.abs(q.astype(int) - med5(q)).max(2) > 24) & painted).sum() / max(1, painted.sum()))


px = np.array(img_color.pixels[:], dtype=np.float32).reshape(size, size, 4)
q = (px[..., :3] * 255 + 0.5).astype(np.uint8)
speckle_before = speckle(q)
if os.environ.get("CLEAN_TEXTURE", "1") != "0":
    q = med5(q)
    px[..., :3] = q.astype(np.float32) / 255
    img_color.pixels = px.ravel().tolist()
speckle_after = speckle(q)

# save the maps
col_path = os.path.join(out_dir, name + "_BaseColor.png")
rough_path = os.path.join(out_dir, name + "_Roughness.png")
img_color.filepath_raw = col_path
img_color.file_format = "PNG"
img_color.save()
img_rough.filepath_raw = rough_path
img_rough.file_format = "PNG"
img_rough.save()

# final export material: Principled BSDF with the two maps
mat2 = bpy.data.materials.new(name + "_Mat")
mat2.use_nodes = True
nt2 = mat2.node_tree
bsdf = nt2.nodes.get("Principled BSDF")
tc = nt2.nodes.new("ShaderNodeTexImage")
tc.image = bpy.data.images.load(col_path)
tc.image.colorspace_settings.name = "sRGB"
tr = nt2.nodes.new("ShaderNodeTexImage")
tr.image = bpy.data.images.load(rough_path)
tr.image.colorspace_settings.name = "Non-Color"
nt2.links.new(tc.outputs["Color"], bsdf.inputs["Base Color"])
nt2.links.new(tr.outputs["Color"], bsdf.inputs["Roughness"])
bsdf.inputs["Metallic"].default_value = 0.0
mesh.data.materials.clear()
mesh.data.materials.append(mat2)

for o in scene.objects:
    o.select_set(o is mesh)
bpy.context.view_layer.objects.active = mesh
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + ".glb"), use_selection=True, export_format="GLB")
bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, name + ".fbx"), use_selection=True, path_mode="COPY", embed_textures=True)

# preview render (Workbench with texture colours)
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "TEXTURE"
scene.render.resolution_x = scene.render.resolution_y = 384
world = bpy.data.worlds.new("W")
scene.world = world
world.color = (0.2, 0.22, 0.3)
cam_data = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
cam_data.lens = 70
for label, angle in (("front", 0), ("three_quarter", 40), ("back", 180)):
    a = math.radians(angle)
    dd = h * 3.1
    cam.location = (math.sin(a) * dd, -math.cos(a) * dd, h * 0.55)
    cam.rotation_euler = (Vector((0, 0, h * 0.5)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(out_dir, f"{name}_tex_{label}.png")
    bpy.ops.render.render(write_still=True)

with open(os.path.join(out_dir, name + "_tex_stats.json"), "w") as f:
    json.dump({"name": name, "size": size, "uv_layers": [u.name for u in mesh.data.uv_layers], "triangles": len(mesh.data.polygons), "speckle_before": round(speckle_before, 4), "speckle_after": round(speckle_after, 4)}, f)
print("DONE", name)
