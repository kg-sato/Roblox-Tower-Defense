"""Brass Sentinel v3: Hunyuan3D shape + concept-painted texture (2026-10-28, the user: "utilize both at once").
    blender -b --factory-startup -P Blender/sentinel_hy.py -- <hunyuan.glb> <concept.png> <out.glb>
The Hunyuan3D mesh (made from the concept image) is centred and stood upright; the concept image is projected onto it
from the front (orthographic, X -> u, Z -> v, using the concept's foreground box) and baked to a 2048 px colour map;
roughness and metalness come from the painted colour (brass and iron shine, dark gaps rough). A small sphere is
added where the concept's red eye is, as its own object "Eye" (made Neon in Studio)."""
import bpy, bmesh, math, sys, os
from mathutils import Vector

A = sys.argv[sys.argv.index("--") + 1:]
src, concept, out = A[:3]
BOX = (0.1975, 0.8002, 0.0458, 0.9219)   # concept foreground u0, u1, v0, v1 (from the image, measured with OpenCV)
EYE = (0.4535, 0.2715)                    # concept eye centroid (u, v)
PAINT, EYENAME, EYESIZE, EYECOL = "sentinel_paint.png", "Eye", 0.035, (1.0, 0.1, 0.03, 1)
if len(A) > 3:  # generic use: paint.png box(u0,u1,v0,v1) eye(u,v) name size r,g,b  (the lantern uses this)
    PAINT = A[3]
    BOX = tuple(float(x) for x in A[4].split(","))
    EYE = tuple(float(x) for x in A[5].split(","))
    EYENAME, EYESIZE = A[6], float(A[7])
    EYECOL = tuple(float(x) for x in A[8].split(",")) + (1,)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 8
scene.cycles.device = "CPU"
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in scene.objects if o.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
body = bpy.context.active_object
body.name = "Body"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
for o in list(scene.objects):
    if o != body:
        bpy.data.objects.remove(o, do_unlink=True)
# measure, stand on z=0, centre x/y; glTF import makes Z up already
co = [body.matrix_world @ v.co for v in body.data.vertices]
mn = Vector((min(c.x for c in co), min(c.y for c in co), min(c.z for c in co)))
mx = Vector((max(c.x for c in co), max(c.y for c in co), max(c.z for c in co)))
for v in body.data.vertices:
    v.co -= Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
H = mx.z - mn.z
W = mx.x - mn.x
print("size", W, mx.y - mn.y, H)
bpy.ops.object.shade_smooth()

# projection material: u = x across the concept's box, v = z up the box (image v grows downward)
img = bpy.data.images.load(concept)
m = bpy.data.materials.new("Painted")
m.use_nodes = True
nt = m.node_tree
bsdf = nt.nodes["Principled BSDF"]
tc = nt.nodes.new("ShaderNodeTexCoord")
sep = nt.nodes.new("ShaderNodeSeparateXYZ")
nt.links.new(tc.outputs["Object"], sep.inputs[0])
u = nt.nodes.new("ShaderNodeMapRange")
u.inputs["From Min"].default_value, u.inputs["From Max"].default_value = -W / 2, W / 2
u.inputs["To Min"].default_value, u.inputs["To Max"].default_value = BOX[0], BOX[1]
nt.links.new(sep.outputs["X"], u.inputs["Value"])
v = nt.nodes.new("ShaderNodeMapRange")
v.inputs["From Min"].default_value, v.inputs["From Max"].default_value = 0, H
v.inputs["To Min"].default_value, v.inputs["To Max"].default_value = 1 - BOX[3], 1 - BOX[2]
nt.links.new(sep.outputs["Z"], v.inputs["Value"])
comb = nt.nodes.new("ShaderNodeCombineXYZ")
nt.links.new(u.outputs[0], comb.inputs["X"])
nt.links.new(v.outputs[0], comb.inputs["Y"])
tex = nt.nodes.new("ShaderNodeTexImage")
tex.image = img
tex.extension = "EXTEND"
nt.links.new(comb.outputs[0], tex.inputs["Vector"])
nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
body.data.materials.clear()
body.data.materials.append(m)

# eye: a small sphere at the concept eye, pushed out to the front surface (-Y)
ex = (EYE[0] - (BOX[0] + BOX[1]) / 2) / (BOX[1] - BOX[0]) * W
ez = (1 - EYE[1] - (1 - BOX[3])) / (BOX[3] - BOX[2]) * H
front = min((c.y for c in [body.matrix_world @ vv.co for vv in body.data.vertices] if abs(c.x - ex) < W * 0.06 and abs(c.z - ez) < H * 0.04), default=-0.3)
bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=H * EYESIZE, location=(ex, (front - H * 0.005) if EYENAME == "Eye" else 0.0, ez))
eye = bpy.context.active_object
eye.name = EYENAME
em = bpy.data.materials.new("EyeMat")
em.use_nodes = True
em.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = EYECOL
eye.data.materials.append(em)

# v3b: no baking. UVs ARE the front projection (x -> u, z -> v over the whole model), and the texture is the concept
# painting itself, cropped to the robot with its colours grown into the background (sentinel_paint.png). v3a's baked
# map was thousands of tiny islands that blurred to grey in Roblox.
uvl = body.data.uv_layers.new(name="Front")
for poly in body.data.polygons:
    for li in poly.loop_indices:
        co = body.data.vertices[body.data.loops[li].vertex_index].co
        uvl.data[li].uv = ((co.x + W / 2) / W, co.z / H)
body.data.uv_layers.active = uvl
for l in list(body.data.uv_layers):
    if l.name != "Front":
        body.data.uv_layers.remove(l)
paint = bpy.data.images.load(os.path.join(os.path.dirname(out), PAINT))
for nd in (tex, comb, u, v, sep, tc):
    nt.nodes.remove(nd)
pn = nt.nodes.new("ShaderNodeTexImage")
pn.image = paint
nt.links.new(pn.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 0.5  # v8 brass: some sheen; metal 0.6 mirrored the blue sky
for name, val, sock in (("Body_metal", 0.35, "Metallic"),):
    im2 = bpy.data.images.new(name, 16, 16)
    im2.colorspace_settings.name = "Non-Color"
    im2.generated_color = (val, val, val, 1)
    tn = nt.nodes.new("ShaderNodeTexImage")
    tn.image = im2
    nt.links.new(tn.outputs["Color"], bsdf.inputs[sock])
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_apply=True)
print("EXPORTED", out, "faces", sum(len(o.data.polygons) for o in scene.objects if o.type == "MESH"), "bytes", os.path.getsize(out))
