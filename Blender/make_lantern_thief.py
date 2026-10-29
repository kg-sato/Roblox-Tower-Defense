"""Lantern Thief enemy model (T117), Blender headless, procedural.
Run:  blender -b --factory-startup -P make_lantern_thief.py -- <out_dir>
Design (TODO T137): a hunched hooded thief who goes for the path's lamps and drops a stolen light: pointed hood with two pale eyes, long thin arms, a big sack on its back, a stolen lantern glowing in one hand.
Built from boxes, prisms and one cone, flat colours from a 4 by 4 palette texture (LanternThief_Palette.png). Faces -Y. Exports LanternThief.glb and .fbx, LanternThief_stats.json and workbench stills."""
import bmesh
import json
import math
import os
import sys

import bpy
from mathutils import Vector

out_dir = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
os.makedirs(out_dir, exist_ok=True)
pal_path = os.path.join(out_dir, "LanternThief_Palette.png")

# palette cells (index = row * 4 + col): 0 dark coat, 1 patch cloth, 2 hood dark, 3 pale eye, 4 lantern glow gold, 5 black, 6 leather brown, 7 sack tan
PAL = [(44, 36, 52), (104, 74, 118), (24, 20, 30), (240, 236, 200), (255, 196, 80), (16, 14, 18), (100, 66, 40), (156, 124, 84)]

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
bm = bmesh.new()
uvl = bm.loops.layers.uv.new("UVMap")
FACES = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]


def cell_uv(idx):
    return ((idx % 4 + 0.5) / 4, 1 - ((idx // 4) + 0.5) / 4)


def add_pts(pts, idx):
    for f in FACES:
        face = bm.faces.new([pts[i] for i in f])
        for loop in face.loops:
            loop[uvl].uv = cell_uv(idx)


def add_box(c, s, idx):
    hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
    pts = [bm.verts.new((c[0] + sx * hx, c[1] + sy * hy, c[2] + z)) for z in (-hz, hz) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    add_pts(pts, idx)


def add_blade(p0, p1, w0, w1, t, idx):
    """Flat prism from p0 to p1: width w0 at the base, w1 at the tip (horizontal, perpendicular to the blade), thickness t (vertical)."""
    p0, p1 = Vector(p0), Vector(p1)
    d = Vector((p1.x - p0.x, p1.y - p0.y, 0))
    d.normalize()
    side = Vector((-d.y, d.x, 0))
    pts = []
    for z in (-t / 2, t / 2):
        pts.append(bm.verts.new(p0 + side * (-w0 / 2) + Vector((0, 0, z))))
        pts.append(bm.verts.new(p0 + side * (w0 / 2) + Vector((0, 0, z))))
        pts.append(bm.verts.new(p1 + side * (w1 / 2) + Vector((0, 0, z))))
        pts.append(bm.verts.new(p1 + side * (-w1 / 2) + Vector((0, 0, z))))
    add_pts(pts, idx)


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


# crouched stance: wide-set bent legs, low hunched coat, hood thrust forward, arms flung wide, lantern held high
for sx in (-1, 1):
    add_blade((sx * 0.35, 0.1, 1.0), (sx * 0.95, -0.4, 0.4), 0.3, 0.26, 0.3, 5)
    add_box((sx * 1.0, -0.45, 0.1), (0.4, 0.7, 0.2), 6)
add_box((0, 0.05, 1.15), (1.3, 1.0, 0.5), 0)
add_box((0, -0.25, 1.6), (1.0, 0.8, 0.8), 0)
add_box((0, -0.65, 1.55), (0.55, 0.06, 0.45), 1)
add_box((0, -0.75, 2.05), (0.8, 0.8, 0.6), 2)
add_cyl((0, -0.75, 2.35), 0.48, 0.04, 0.55, 2, seg=4)
for sx in (-1, 1):
    add_box((sx * 0.18, -1.17, 2.05), (0.12, 0.05, 0.1), 3)
# right arm flung up holding the stolen lantern high, left arm flung out and down trailing a grabbing hand
add_blade((0.55, -0.3, 1.8), (1.9, -0.6, 2.9), 0.24, 0.2, 0.22, 0)
add_box((1.95, -0.62, 2.95), (0.2, 0.2, 0.2), 6)
add_box((1.95, -0.62, 3.3), (0.6, 0.6, 0.6), 4)
add_box((1.95, -0.62, 3.65), (0.7, 0.7, 0.1), 6)
add_box((1.95, -0.62, 2.98), (0.7, 0.7, 0.1), 6)
add_box((1.95, -0.62, 3.85), (0.05, 0.05, 0.3), 5)
add_blade((-0.55, -0.3, 1.8), (-1.9, -0.9, 1.1), 0.24, 0.2, 0.22, 0)
add_box((-2.0, -0.95, 1.0), (0.3, 0.4, 0.22), 6)
# sack on the back with a knot
add_box((0, 0.8, 1.55), (1.2, 0.9, 1.1), 7)
add_box((0, 0.8, 2.16), (0.3, 0.3, 0.2), 6)
add_box((0, 0.8, 2.34), (0.14, 0.14, 0.2), 6)
bmesh.ops.triangulate(bm, faces=bm.faces[:])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
mesh = bpy.data.meshes.new("LanternThief")
bm.to_mesh(mesh)
bm.free()
obj = bpy.data.objects.new("LanternThief", mesh)
scene.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj

# palette texture (4 x 4 cells, 16 px each, written with Blender's own image API)
img = bpy.data.images.new("LanternThief_Palette", 64, 64, alpha=False)
px = []
for y in range(64):
    for x in range(64):
        cx, cy = x // 16, 3 - y // 16
        i = cy * 4 + cx
        c = PAL[i] if i < len(PAL) else (0, 0, 0)
        px += [c[0] / 255, c[1] / 255, c[2] / 255, 1.0]
img.pixels = px
img.filepath_raw = pal_path
img.file_format = "PNG"
img.save()
mat = bpy.data.materials.new("LanternThief")
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
bsdf.inputs["Metallic"].default_value = 0.65
bsdf.inputs["Roughness"].default_value = 0.45
obj.data.materials.append(mat)

# stats
mesh.calc_loop_triangles()
co = [v.co.copy() for v in mesh.vertices]
mn = Vector((min(c.x for c in co), min(c.y for c in co), min(c.z for c in co)))
mx = Vector((max(c.x for c in co), max(c.y for c in co), max(c.z for c in co)))
size = mx - mn
stats = {"name": "LanternThief", "triangles": len(mesh.loop_triangles), "vertices": len(co), "size": [round(size.x, 3), round(size.y, 3), round(size.z, 3)],
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
    scene.render.filepath = os.path.join(out_dir, f"LanternThief_{name}.png")
    bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)

bpy.ops.object.select_all(action="DESELECT")
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, "LanternThief.glb"), use_selection=True, export_format="GLB")
bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, "LanternThief.fbx"), use_selection=True, path_mode="COPY", embed_textures=True)
with open(os.path.join(out_dir, "LanternThief_stats.json"), "w") as f:
    json.dump(stats, f)
print("THIEF_DONE", json.dumps(stats))
