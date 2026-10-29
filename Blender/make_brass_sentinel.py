"""Brass Sentinel enemy model (T115), Blender headless, procedural.
Run:  blender -b --factory-startup -P make_brass_sentinel.py -- <out_dir>
Design (Roblox Dev/Research/3D and Art/Backgrounds and Enemies - Mystic Victorian.md): "steam automaton, boxy torso, chimney on its back; square shoulders plus a back chimney; dark brass, red eye slit";
the heavy tank of the roster. Built from beveled boxes and one tapered chimney, flat colours from a 4 by 4 palette texture (BrassSentinel_Palette.png; every part's UVs sit in one palette cell).
Faces -Y, squat and wide: about 4.4 high with the chimney, 4.4 wide at the shoulders, 3 deep with the boiler. Exports BrassSentinel.glb and .fbx, BrassSentinel_stats.json and workbench stills (front, side, three_quarter)."""
import bmesh
import json
import math
import os
import sys

import bpy
from mathutils import Vector

out_dir = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
os.makedirs(out_dir, exist_ok=True)
pal_path = os.path.join(out_dir, "BrassSentinel_Palette.png")

# palette cells (index = row * 4 + col): 0 dark brass, 1 brass, 2 worn dark, 3 red eye, 4 chimney iron, 5 rivet gold, 6 black seam, 7 soot grey
PAL = [(92, 66, 26), (150, 112, 48), (58, 42, 20), (214, 40, 36), (60, 58, 62), (214, 176, 84), (22, 20, 22), (110, 106, 104)]

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
bm = bmesh.new()
uvl = bm.loops.layers.uv.new("UVMap")


def cell_uv(idx):
    return ((idx % 4 + 0.5) / 4, 1 - ((idx // 4) + 0.5) / 4)


def add_box(c, s, idx, taper=1.0):
    """Box centred at c with size s; taper scales the top face in x and y."""
    hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
    pts = []
    for z, k in ((-hz, 1.0), (hz, taper)):
        for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            pts.append(bm.verts.new((c[0] + sx * hx * k, c[1] + sy * hy * k, c[2] + z)))
    faces = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    for f in faces:
        face = bm.faces.new([pts[i] for i in f])
        for loop in face.loops:
            loop[uvl].uv = cell_uv(idx)


def add_cyl(c, r0, r1, h, idx, seg=8):
    bot = [bm.verts.new((c[0] + r0 * math.cos(2 * math.pi * i / seg), c[1] + r0 * math.sin(2 * math.pi * i / seg), c[2])) for i in range(seg)]
    top = [bm.verts.new((c[0] + r1 * math.cos(2 * math.pi * i / seg), c[1] + r1 * math.sin(2 * math.pi * i / seg), c[2] + h)) for i in range(seg)]
    for i in range(seg):
        f = bm.faces.new((bot[i], bot[(i + 1) % seg], top[(i + 1) % seg], top[i]))
        for loop in f.loops:
            loop[uvl].uv = cell_uv(idx)
    for ring, rev in ((bot, True), (top, False)):
        f = bm.faces.new(ring[::-1] if rev else ring)
        for loop in f.loops:
            loop[uvl].uv = cell_uv(idx)


# squat tank proportions so the side view is wide (deep boiler, long arms) and cannot be mistaken for the slim familiar Sentinel
# legs and feet
for sx in (-1, 1):
    add_box((sx * 0.7, 0.0, 0.42), (0.8, 0.8, 0.84), 0)
    add_box((sx * 0.7, -0.2, 0.1), (1.0, 1.4, 0.2), 2)
# pelvis and torso (boxy, deep), chest plate with rivets
add_box((0, 0, 1.0), (2.2, 1.3, 0.34), 2)
add_box((0, 0, 1.75), (2.7, 1.6, 1.2), 0)
add_box((0, -0.85, 1.75), (1.6, 0.1, 0.8), 1)
for sx in (-1, 1):
    for sz in (-1, 1):
        add_box((sx * 0.62, -0.92, 1.75 + sz * 0.27), (0.1, 0.06, 0.1), 5)
add_box((0, -0.88, 1.32), (1.9, 0.06, 0.06), 6)
# huge square shoulders
for sx in (-1, 1):
    add_box((sx * 1.7, 0, 2.3), (1.1, 1.5, 0.6), 1)
    add_box((sx * 1.7, 0, 1.92), (0.6, 0.7, 0.2), 6)
# long thick arms ending in big fists near the ground, swung slightly forward
for sx in (-1, 1):
    add_box((sx * 1.85, -0.2, 1.3), (0.62, 0.62, 1.5), 2)
    add_box((sx * 1.85, -0.3, 0.45), (0.9, 0.9, 0.7), 0)
# small head sunk between the shoulders, red eye slit
add_box((0, -0.2, 2.65), (1.0, 0.8, 0.55), 0)
add_box((0, -0.62, 2.68), (0.76, 0.05, 0.12), 3)
# big boiler on the back (deep) and two chimneys
add_box((0, 1.25, 1.85), (1.9, 1.0, 1.5), 2)
add_box((0, 1.77, 1.85), (1.5, 0.06, 1.0), 4)
add_cyl((0.55, 1.25, 2.6), 0.34, 0.26, 1.7, 4)
add_box((0.55, 1.25, 4.34), (0.7, 0.7, 0.14), 7)
add_cyl((-0.5, 1.25, 2.6), 0.26, 0.2, 1.1, 4)
add_box((-0.5, 1.25, 3.74), (0.5, 0.5, 0.12), 7)
bmesh.ops.triangulate(bm, faces=bm.faces[:])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
mesh = bpy.data.meshes.new("BrassSentinel")
bm.to_mesh(mesh)
bm.free()
obj = bpy.data.objects.new("BrassSentinel", mesh)
scene.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj

# palette texture (4 x 4 cells, 16 px each, written with Blender's own image API)
img = bpy.data.images.new("BrassSentinel_Palette", 64, 64, alpha=False)
px = []
for y in range(64):
    for x in range(64):
        cx, cy = x // 16, 3 - y // 16  # row 0 at the top
        i = cy * 4 + cx
        c = PAL[i] if i < len(PAL) else (0, 0, 0)
        px += [c[0] / 255, c[1] / 255, c[2] / 255, 1.0]
img.pixels = px
img.filepath_raw = pal_path
img.file_format = "PNG"
img.save()
mat = bpy.data.materials.new("BrassSentinel")
mat.use_nodes = True
nt = mat.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
out = nt.nodes.new("ShaderNodeOutputMaterial")
bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
tex = nt.nodes.new("ShaderNodeTexImage")
tex.image = img
tex.interpolation = "Closest"
nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
bsdf.inputs["Metallic"].default_value = 0.6
bsdf.inputs["Roughness"].default_value = 0.5
obj.data.materials.append(mat)

# stats
mesh.calc_loop_triangles()
co = [v.co.copy() for v in mesh.vertices]
mn = Vector((min(c.x for c in co), min(c.y for c in co), min(c.z for c in co)))
mx = Vector((max(c.x for c in co), max(c.y for c in co), max(c.z for c in co)))
size = mx - mn
stats = {"name": "BrassSentinel", "triangles": len(mesh.loop_triangles), "vertices": len(co), "size": [round(size.x, 3), round(size.y, 3), round(size.z, 3)],
         "min": [round(c, 3) for c in mn], "max": [round(c, 3) for c in mx], "width_over_height": round(size.x / size.z, 3), "materials": [m.name for m in mesh.materials]}

# stills
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
cam_data.lens = 60
centre = Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, (mn.z + mx.z) / 2))
dist = max(size) * 2.4
for name, ang in (("front", (0, -1, 0.15)), ("side", (1, 0, 0.1)), ("three_quarter", (0.7, -0.7, 0.2))):
    d = Vector(ang).normalized()
    cam.location = centre + d * dist
    cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(out_dir, f"BrassSentinel_{name}.png")
    bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)

bpy.ops.object.select_all(action="DESELECT")
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, "BrassSentinel.glb"), use_selection=True, export_format="GLB")
bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, "BrassSentinel.fbx"), use_selection=True, path_mode="COPY", embed_textures=True)
with open(os.path.join(out_dir, "BrassSentinel_stats.json"), "w") as f:
    json.dump(stats, f)
print("SENT_DONE", json.dumps(stats))
