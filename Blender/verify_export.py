"""Re-import an exported FBX/GLB and print what Roblox would receive: mesh count, triangles, size, bones, clips."""
import sys
import bpy
from mathutils import Vector

path = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
if path.lower().endswith(".fbx"):
    bpy.ops.import_scene.fbx(filepath=path)
else:
    bpy.ops.import_scene.gltf(filepath=path)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
arms = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
tris = 0
for m in meshes:
    m.data.calc_loop_triangles()
    tris += len(m.data.loop_triangles)
xs, ys, zs = [], [], []
for m in meshes:
    for c in m.bound_box:
        w = m.matrix_world @ Vector(c)
        xs.append(w.x); ys.append(w.y); zs.append(w.z)
print("VERIFY meshes", len(meshes), "triangles", tris, "armatures", len(arms))
print("VERIFY size", round(max(xs) - min(xs), 2), round(max(ys) - min(ys), 2), round(max(zs) - min(zs), 2))
for a in arms:
    print("VERIFY bones", [b.name for b in a.data.bones])
for act in bpy.data.actions:
    print("VERIFY action", act.name, "frames", tuple(round(v) for v in act.frame_range))
