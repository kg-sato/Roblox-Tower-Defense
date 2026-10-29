"""Remove small floating fragments from a cleaned model (Hunyuan3D leaves bits of props floating beside the figure). Blender headless.
Run:  blender -b --factory-startup -P remove_floaters.py -- <dir> <name> [min_fraction]
Imports <dir>/<name>.glb, splits it into loose parts, deletes every part whose largest bounding-box side is under min_fraction (default 0.18) of the whole model's height
(so a thin tall staff survives and a floating chip does not), and re-exports <dir>/<name>.glb and .fbx. Prints REMOVED n of m."""
import os
import sys

import bmesh
import bpy

d, name = os.path.abspath(sys.argv[sys.argv.index("--") + 1]), sys.argv[sys.argv.index("--") + 2]
frac = float(sys.argv[sys.argv.index("--") + 3]) if len(sys.argv) > sys.argv.index("--") + 3 else 0.18
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(d, name + ".glb"))
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
for o in bpy.context.scene.objects:
    o.select_set(o.type == "MESH")
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
obj = bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bm = bmesh.new()
bm.from_mesh(obj.data)
bm.verts.ensure_lookup_table()
seen, parts = set(), []
for v in bm.verts:
    if v.index in seen:
        continue
    stack, comp = [v], []
    seen.add(v.index)
    while stack:
        x = stack.pop()
        comp.append(x)
        for e in x.link_edges:
            o = e.other_vert(x)
            if o.index not in seen:
                seen.add(o.index)
                stack.append(o)
    parts.append(comp)
zs = [v.co.z for v in bm.verts]
height = max(zs) - min(zs)
kill = []
nparts_killed = 0
for comp in parts:
    xs, ys, zz = [v.co.x for v in comp], [v.co.y for v in comp], [v.co.z for v in comp]
    size = max(max(xs) - min(xs), max(ys) - min(ys), max(zz) - min(zz))
    if size < frac * height:
        kill.extend(comp)
        nparts_killed += 1
nkill = len(kill)
nparts_total = len(parts)
bmesh.ops.delete(bm, geom=kill, context="VERTS")
bm.to_mesh(obj.data)
bm.free()
print("REMOVED", nkill, "vertices in", nparts_killed, "of", nparts_total, "parts")
bpy.ops.object.select_all(action="DESELECT")
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.export_scene.gltf(filepath=os.path.join(d, name + ".glb"), use_selection=True, export_format="GLB")
bpy.ops.export_scene.fbx(filepath=os.path.join(d, name + ".fbx"), use_selection=True, path_mode="COPY")
