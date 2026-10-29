"""Clockwork Crow enemy model (T116), Blender headless, procedural.
Run:  blender -b --factory-startup -P make_clockwork_crow.py -- <out_dir>
Design (TODO T136): a fast flyer, a wind-up crow of dark steel with a brass beak and rivets, red eye points, a wind-up key on its back, geared shoulder joints.
Built from beveled-free prisms (feather blades fan out from each shoulder, raised in a flap pose; three tail blades) and flat colours from a 4 by 4 palette texture
(ClockworkCrow_Palette.png; every part's UVs sit in one palette cell). Faces -Y, wings up and spread: about 6.3 wide, 3.9 long, 2.9 high. Exports ClockworkCrow.glb and .fbx,
ClockworkCrow_stats.json and workbench stills (front, side, three_quarter)."""
import bmesh
import json
import math
import os
import sys

import bpy
from mathutils import Vector

out_dir = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
os.makedirs(out_dir, exist_ok=True)
pal_path = os.path.join(out_dir, "ClockworkCrow_Palette.png")

# palette cells (index = row * 4 + col): 0 dark steel, 1 brass, 2 worn dark, 3 red eye, 4 gold rivet, 5 black seam, 6 grey steel, 7 copper
PAL = [(52, 56, 66), (170, 128, 52), (34, 36, 44), (230, 44, 40), (222, 184, 90), (16, 16, 20), (110, 116, 128), (150, 88, 52)]

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


# body, chest plate, head, beak, eyes
add_box((0, 0, 1.6), (1.0, 1.7, 0.85), 0)
add_box((0, -0.88, 1.55), (0.7, 0.08, 0.5), 1)
add_box((0, -0.3, 1.18), (0.8, 1.2, 0.18), 2)
add_box((0, -1.15, 2.0), (0.62, 0.62, 0.6), 0)
add_blade((0, -1.4, 1.98), (0, -2.1, 1.82), 0.34, 0.03, 0.22, 1)
add_blade((0, -1.4, 1.84), (0, -1.95, 1.8), 0.28, 0.03, 0.1, 7)
for sx in (-1, 1):
    add_box((sx * 0.33, -1.3, 2.08), (0.06, 0.16, 0.16), 3)
# wings: five feather blades from each geared shoulder, raised in a flap pose
for sx in (-1, 1):
    shoulder = Vector((sx * 0.5, -0.15, 1.85))
    add_cyl((sx * 0.5, -0.15, 1.9), 0.26, 0.26, 0.16, 4, seg=10)
    for k in range(5):
        a = math.radians(-38 + 22 * k)  # from forward-sweep to back-sweep
        ln = 2.5 - 0.18 * k
        tip = shoulder + Vector((sx * math.cos(a) * ln, math.sin(a) * ln, 0.9 + 0.12 * (4 - k)))
        add_blade(shoulder, tip, 0.5, 0.26, 0.09, 0 if k % 2 == 0 else 6)
# tail fan, legs and talons
for k in range(3):
    a = math.radians(-24 + 24 * k)
    root = Vector((0, 0.85, 1.55))
    add_blade(root, root + Vector((math.sin(a) * 1.4, math.cos(a) * 1.4, -0.35)), 0.34, 0.2, 0.08, 0 if k == 1 else 6)
for sx in (-1, 1):
    add_box((sx * 0.28, -0.1, 0.95), (0.12, 0.12, 0.55), 6)
    add_box((sx * 0.28, -0.3, 0.64), (0.22, 0.6, 0.1), 1)
# wind-up key on the back
add_cyl((0, 0.15, 2.0), 0.07, 0.07, 0.55, 1, seg=6)
add_box((0, 0.15, 2.62), (0.8, 0.1, 0.26), 1)
add_box((0, 0.15, 2.62), (0.14, 0.14, 0.34), 4)
bmesh.ops.triangulate(bm, faces=bm.faces[:])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
mesh = bpy.data.meshes.new("ClockworkCrow")
bm.to_mesh(mesh)
bm.free()
obj = bpy.data.objects.new("ClockworkCrow", mesh)
scene.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj

# palette texture (4 x 4 cells, 16 px each, written with Blender's own image API)
img = bpy.data.images.new("ClockworkCrow_Palette", 64, 64, alpha=False)
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
mat = bpy.data.materials.new("ClockworkCrow")
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
stats = {"name": "ClockworkCrow", "triangles": len(mesh.loop_triangles), "vertices": len(co), "size": [round(size.x, 3), round(size.y, 3), round(size.z, 3)],
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
    scene.render.filepath = os.path.join(out_dir, f"ClockworkCrow_{name}.png")
    bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)

bpy.ops.object.select_all(action="DESELECT")
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, "ClockworkCrow.glb"), use_selection=True, export_format="GLB")
bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, "ClockworkCrow.fbx"), use_selection=True, path_mode="COPY", embed_textures=True)
with open(os.path.join(out_dir, "ClockworkCrow_stats.json"), "w") as f:
    json.dump(stats, f)
print("CROW_DONE", json.dumps(stats))
