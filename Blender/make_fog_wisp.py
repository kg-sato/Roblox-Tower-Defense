"""Fog Wisp enemy model (T114), Blender headless, procedural.
Run:  blender -b --factory-startup -P make_fog_wisp.py -- <out_dir>
Design (Roblox Dev/Research/3D and Art/Backgrounds and Enemies - Mystic Victorian.md): "torn cloak with no body, glides low, trails mist; long trailing tail, no legs; pale cold blue".
A flattened hooded cloak swept along a gentle S-curve: domed hood at the front with a dark recess and two pale eye points, the cloak tapering into a long ragged tail, plus three thin mist strands.
The model faces -Y, tail toward +Y, floats about 0.5 above the ground plane (z = 0), 3.4 long, 1.7 high. UVs: u around the cloak, v along it (head 0, tail tip 1) for the gradient texture
FogWisp_BaseColor.png (alpha fades toward the tail: use AlphaMode Transparency). Exports FogWisp.glb and .fbx, FogWisp_stats.json (triangles, bounding box, vertices near the ground)
and workbench stills FogWisp_front/side/three_quarter.png."""
import bmesh
import json
import math
import os
import random
import sys

import bpy
from mathutils import Vector

out_dir = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
os.makedirs(out_dir, exist_ok=True)
tex_path = os.path.join(out_dir, "FogWisp_BaseColor.png")
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
random.seed(7)

L = 3.4          # length along +Y
SEG = 18         # verts around each ring
RINGS = 26       # rings along the cloak


def spine(t):
    y = -1.0 + L * t
    z = 1.05 - 0.55 * t + 0.22 * math.sin(2 * math.pi * 1.1 * t)
    x = 0.12 * math.sin(2 * math.pi * 0.9 * t) * t
    return Vector((x, y, z))


def radii(t):
    rx = 0.62 * (1 - t) ** 0.8 + 0.02          # width
    rz = 0.55 * (1 - t) ** 1.4 + 0.015         # thickness: thick hood, thin tail
    return rx, rz


bm = bmesh.new()
uv_layer = bm.loops.layers.uv.new("UVMap")
rings = []
# dome cap in front of ring 0 (hood): 5 rings from the front point backwards, an ellipsoid with depth 0.45
for k in range(5, 0, -1):
    phi = k / 5.0 * math.pi / 2
    f = max(math.cos(phi), 0.04)
    rx, rz = radii(0)
    c = spine(0) + Vector((0, -0.45 * math.sin(phi), 0))
    rings.append((c, rx * f, rz * f, 0.0))
for i in range(RINGS):
    t = i / (RINGS - 1)
    rx, rz = radii(t)
    rings.append((spine(t), rx, rz, t))
verts = []
for ri, (c, rx, rz, t) in enumerate(rings):
    row = []
    tt = max(t, 0.0)
    for j in range(SEG):
        a = 2 * math.pi * j / SEG
        jag = 1.0
        if tt > 0.5:
            jag = 1.0 + 0.55 * (tt - 0.5) * random.uniform(-1, 1) * (1.0 if math.cos(a) < 0.3 else 0.4)  # ragged tears at the sides of the tail
        x = c.x + math.cos(a) * rx * jag
        z = c.z + math.sin(a) * rz
        v = bm.verts.new((x, c.y, z))
        row.append(v)
    verts.append(row)
for ri in range(len(verts) - 1):
    for j in range(SEG):
        a, b = verts[ri][j], verts[ri][(j + 1) % SEG]
        c2, d2 = verts[ri + 1][(j + 1) % SEG], verts[ri + 1][j]
        f = bm.faces.new((a, b, c2, d2))
        for loop, (u, vv) in zip(f.loops, ((j / SEG, ri), ((j + 1) / SEG, ri), ((j + 1) / SEG, ri + 1), (j / SEG, ri + 1))):
            loop[uv_layer].uv = (u, vv / (len(verts) - 1))
bmesh.ops.triangulate(bm, faces=bm.faces[:])
# mist strands: three thin ribbons from the mid cloak
for k, (dx, dz, ln) in enumerate(((-0.22, 0.0, 1.5), (0.0, 0.12, 1.9), (0.22, -0.05, 1.3))):
    t0 = 0.34
    base = spine(t0)
    prev = None
    for m in range(14):
        s = m / 13
        w = 0.07 * (1 - s)
        pt = base + Vector((dx + 0.18 * math.sin(s * 5 + k), ln * s + 0.4 * s * s, dz - 0.35 * s + 0.12 * math.sin(s * 7 + k)))
        a = bm.verts.new(pt + Vector((-w, 0, 0)))
        b = bm.verts.new(pt + Vector((w, 0, 0)))
        if prev:
            f = bm.faces.new((prev[0], prev[1], b, a))
            for loop, uv in zip(f.loops, ((0.0, 0.5 + 0.5 * (m - 1) / 13), (1.0, 0.5 + 0.5 * (m - 1) / 13), (1.0, 0.5 + 0.5 * m / 13), (0.0, 0.5 + 0.5 * m / 13))):
                loop[uv_layer].uv = uv
        prev = (a, b)
# torn hem: seven ragged tatters hanging from the sides of the cloak and trailing back (cloth, not legs: they point backwards and down, never forward)
for k in range(7):
    t = 0.14 + 0.075 * k
    side = -1 if k % 2 == 0 else 1
    rx, rz = radii(t)
    base = spine(t) + Vector((side * rx * 0.85, 0, -rz * 0.5))
    w = 0.09 + 0.02 * (k % 3)
    tipv = bm.verts.new(base + Vector((side * 0.10, 0.55 + 0.08 * k, -0.42 - 0.04 * (k % 3))))
    a = bm.verts.new(base + Vector((0, -w, 0)))
    b = bm.verts.new(base + Vector((0, w, 0)))
    f = bm.faces.new((a, b, tipv))
    for loop, uv in zip(f.loops, ((0.0, t), (1.0, t), (0.5, min(1.0, t + 0.2)))):
        loop[uv_layer].uv = uv
bmesh.ops.triangulate(bm, faces=bm.faces[:])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
mesh_data = bpy.data.meshes.new("FogWisp")
bm.to_mesh(mesh_data)
bm.free()
obj = bpy.data.objects.new("FogWisp", mesh_data)
scene.collection.objects.link(obj)
# dark recess in the hood and two pale eye points (separate small meshes joined later)
def sphere(name, loc, r, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=r, location=loc)
    o = bpy.context.object
    o.name = name
    o.data.materials.append(mat)
    return o

mat = bpy.data.materials.new("FogWisp_Cloak")
mat.use_nodes = True
nt = mat.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
out = nt.nodes.new("ShaderNodeOutputMaterial")
bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
tex = nt.nodes.new("ShaderNodeTexImage")
tex.image = bpy.data.images.load(tex_path)
nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
bsdf.inputs["Roughness"].default_value = 0.9
mat.blend_method = "BLEND" if hasattr(mat, "blend_method") else None
obj.data.materials.append(mat)
mat_dark = bpy.data.materials.new("FogWisp_Recess")
mat_dark.diffuse_color = (0.03, 0.04, 0.07, 1)
mat_eye = bpy.data.materials.new("FogWisp_Eye")
mat_eye.diffuse_color = (0.92, 0.97, 1.0, 1)
h = spine(0)
recess = sphere("Recess", (h.x, h.y - 0.36, h.z + 0.03), 0.34, mat_dark)
recess.scale = (0.85, 0.30, 0.85)
eyes = [sphere("EyeL", (h.x - 0.16, h.y - 0.43, h.z + 0.06), 0.065, mat_eye), sphere("EyeR", (h.x + 0.16, h.y - 0.43, h.z + 0.06), 0.065, mat_eye)]
bpy.ops.object.select_all(action="DESELECT")
for o in (obj, recess, *eyes):
    o.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.object.join()
wisp = bpy.context.view_layer.objects.active
wisp.name = "FogWisp"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# --- stats ---
mesh = wisp.data
mesh.calc_loop_triangles()
tris = len(mesh.loop_triangles)
co = [v.co.copy() for v in mesh.vertices]
mn = Vector((min(c.x for c in co), min(c.y for c in co), min(c.z for c in co)))
mx = Vector((max(c.x for c in co), max(c.y for c in co), max(c.z for c in co)))
size = mx - mn
low = sum(1 for c in co if c.z < mn.z + 0.12 * size.z) / len(co)
stats = {"name": "FogWisp", "triangles": tris, "vertices": len(co), "size": [round(size.x, 3), round(size.y, 3), round(size.z, 3)], "min": [round(c, 3) for c in mn], "max": [round(c, 3) for c in mx],
         "length_over_height": round(size.y / size.z, 3), "fraction_vertices_in_lowest_12_percent": round(low, 4), "materials": [m.name for m in mesh.materials]}

# --- stills ---
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "TEXTURE"
scene.render.film_transparent = False
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
    scene.render.filepath = os.path.join(out_dir, f"FogWisp_{name}.png")
    bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(cam, do_unlink=True)

bpy.ops.object.select_all(action="DESELECT")
wisp.select_set(True)
bpy.context.view_layer.objects.active = wisp
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, "FogWisp.glb"), use_selection=True, export_format="GLB")
bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, "FogWisp.fbx"), use_selection=True, path_mode="COPY", embed_textures=True)
with open(os.path.join(out_dir, "FogWisp_stats.json"), "w") as f:
    json.dump(stats, f)
print("WISP_DONE", json.dumps(stats))
