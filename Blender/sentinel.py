"""Brass Sentinel (Tank enemy) for Lampwick Lane, 2026-10-28. Reference: UI Kit/art/comfy_out/ref_sentinel_s33.png.
    blender -b --factory-startup -P Blender/sentinel.py -- <out.glb>
A hulking steam automaton: dark riveted iron torso with brass trim and three gauges, a domed helmet with one red eye
(own object "Eye", made Neon in Studio), a back chimney and pipe, round pauldrons, piston arms with clawed fists,
thick legs with knee plates and boots. Separate objects per material; baked PBR maps, explicit metal map on every
material (Roblox's importer otherwise gives a white, fully metal map), linear colour values."""
import bpy, bmesh, math, sys, os
from mathutils import Vector

out = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 16
scene.cycles.device = "CPU"
groups = {"iron": [], "brass": [], "ivory": [], "eye": []}


def add(kind, ob, bev=0.0):
    if bev > 0:
        m = ob.modifiers.new("b", "BEVEL")
        m.width, m.segments, m.limit_method = bev, 2, "ANGLE"
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.modifier_apply(modifier="b")
    groups[kind].append(ob)
    return ob


def box(kind, size, loc, rot=(0, 0, 0), bev=0.06):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return add(kind, o, bev)


def cyl(kind, r, d, loc, rot=(0, 0, 0), v=20, bev=0.02):
    bpy.ops.mesh.primitive_cylinder_add(vertices=v, radius=r, depth=d, location=loc, rotation=rot)
    return add(kind, bpy.context.active_object, bev)


def ball(kind, r, loc, scale=(1, 1, 1), seg=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, radius=r, location=loc)
    o = bpy.context.active_object
    o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    return add(kind, o)


X = math.pi / 2
# torso: barrel chest, belly plate, brass belt and collar
box("iron", (2.2, 1.5, 1.6), (0, 0, 3.4), bev=0.25)
box("iron", (1.9, 1.35, 0.8), (0, 0, 2.35), bev=0.18)
box("brass", (2.0, 1.45, 0.16), (0, 0, 2.75), bev=0.04)
box("brass", (1.3, 1.1, 0.14), (0, 0, 4.25), bev=0.04)
box("brass", (0.45, 0.12, 0.3), (0, -0.74, 2.75), bev=0.03)                  # belt buckle
for i, x in enumerate((-0.55, 0.0, 0.55)):                                   # three gauges on the chest
    cyl("brass", 0.24, 0.1, (x, -0.78, 3.55), (X, 0, 0), 24)
    cyl("ivory", 0.19, 0.02, (x, -0.835, 3.55), (X, 0, 0), 24, 0)
for row, z in enumerate((3.95, 3.0)):                                        # rivet rows
    for k in range(9):
        ball("brass", 0.045, (-0.95 + k * 0.2375, -0.76, z), seg=8)
# helmet head with a red eye
ball("iron", 0.55, (0, -0.1, 4.6), (1, 1, 0.85))
cyl("brass", 0.6, 0.12, (0, -0.1, 4.42), v=28)
cyl("iron", 0.26, 0.3, (0, -0.6, 4.62), (X, 0, 0), 24)
cyl("eye", 0.2, 0.08, (0, -0.76, 4.62), (X, 0, 0), 24, 0)
cyl("brass", 0.08, 0.5, (0, -0.1, 5.15), v=12)                               # top valve
# back chimney and a side pipe
cyl("iron", 0.22, 1.7, (0.45, 0.75, 4.6), v=16)
cyl("brass", 0.28, 0.12, (0.45, 0.75, 5.45), v=16)
cyl("brass", 0.1, 1.2, (-0.55, 0.78, 4.4), v=12)
# shoulders, arms, fists with claws
for s in (-1, 1):
    ball("brass", 0.55, (s * 1.35, 0, 4.05), (1, 1, 0.8))
    cyl("iron", 0.26, 1.0, (s * 1.45, 0, 3.4), v=16)
    ball("brass", 0.25, (s * 1.45, 0, 2.85), seg=12)
    cyl("iron", 0.34, 1.0, (s * 1.5, -0.1, 2.3), v=16)
    cyl("brass", 0.36, 0.1, (s * 1.5, -0.1, 2.75), v=16)
    box("iron", (0.6, 0.55, 0.45), (s * 1.5, -0.15, 1.6), bev=0.08)
    for c in (-1, 0, 1):
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.08, depth=0.45, location=(s * 1.5 + c * 0.18, -0.38, 1.28), rotation=(math.radians(-25), 0, 0))
        add("brass", bpy.context.active_object)
# legs, knee plates, boots
for s in (-1, 1):
    cyl("iron", 0.36, 0.9, (s * 0.55, 0, 1.6), v=16)
    cyl("brass", 0.3, 0.12, (s * 0.55, -0.32, 1.15), (X, 0, 0), 16)
    cyl("iron", 0.4, 0.9, (s * 0.55, 0, 0.75), v=16)
    box("iron", (0.75, 1.0, 0.35), (s * 0.55, -0.12, 0.18), bev=0.08)
    box("brass", (0.78, 0.2, 0.12), (s * 0.55, -0.62, 0.3), bev=0.03)


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = name
    bpy.ops.object.shade_smooth()
    return o


objs = {k: join(v, k.capitalize()) for k, v in groups.items()}


def mat(name, build):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    build(m.node_tree, m.node_tree.nodes["Principled BSDF"])
    return m


def noisy(nt, bsdf, scale, c0, c1, rough, metal, pos1=1.0):
    n = nt.nodes.new("ShaderNodeTexNoise")
    n.inputs["Scale"].default_value = scale
    n.inputs["Detail"].default_value = 10
    r = nt.nodes.new("ShaderNodeValToRGB")
    r.color_ramp.elements[0].color = c0
    r.color_ramp.elements[1].color = c1
    r.color_ramp.elements[1].position = pos1
    nt.links.new(n.outputs["Fac"], r.inputs["Fac"])
    nt.links.new(r.outputs["Color"], bsdf.inputs["Base Color"])
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["To Min"].default_value, mr.inputs["To Max"].default_value = rough
    nt.links.new(n.outputs["Fac"], mr.inputs["Value"])
    nt.links.new(mr.outputs[0], bsdf.inputs["Roughness"])
    bsdf.inputs["Metallic"].default_value = metal


builders = {
    "iron": lambda nt, b: noisy(nt, b, 9, (0.03, 0.033, 0.045, 1), (0.12, 0.125, 0.15, 1), (0.75, 0.5), 0.5, 0.8),  # gunmetal: v1 read near-black on the night street
    "brass": lambda nt, b: noisy(nt, b, 14, (0.03, 0.014, 0.003, 1), (0.42, 0.22, 0.045, 1), (0.7, 0.42), 0.8, 0.75),
    "ivory": lambda nt, b: noisy(nt, b, 30, (0.55, 0.48, 0.34, 1), (0.75, 0.66, 0.48, 1), (0.5, 0.4), 0.0),
    "eye": lambda nt, b: noisy(nt, b, 5, (0.6, 0.02, 0.01, 1), (1.0, 0.25, 0.05, 1), (0.3, 0.2), 0.0),
}
for k, o in objs.items():
    o.data.materials.append(mat(k, builders[k]))


def bake(ob, size):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    nt = ob.data.materials[0].node_tree
    bsdf = nt.nodes["Principled BSDF"]
    outn = nt.nodes["Material Output"]
    scene.render.bake.margin = 8
    made = {}
    for kind in ("color", "rough"):
        img = bpy.data.images.new("%s_%s" % (ob.name, kind), size, size)
        if kind == "rough":
            img.colorspace_settings.name = "Non-Color"
        node = nt.nodes.new("ShaderNodeTexImage")
        node.image = img
        nt.nodes.active = node
        if kind == "color":
            em = nt.nodes.new("ShaderNodeEmission")
            nt.links.new(bsdf.inputs["Base Color"].links[0].from_socket, em.inputs["Color"])
            nt.links.new(em.outputs[0], outn.inputs["Surface"])
            bpy.ops.object.bake(type="EMIT")
            nt.links.new(bsdf.outputs[0], outn.inputs["Surface"])
            nt.nodes.remove(em)
        else:
            bpy.ops.object.bake(type="ROUGHNESS")
        made["Base Color" if kind == "color" else "Roughness"] = node
    met = bsdf.inputs["Metallic"].default_value
    mimg = bpy.data.images.new("%s_metal" % ob.name, size, size)
    mimg.colorspace_settings.name = "Non-Color"
    mimg.generated_color = (met, met, met, 1)
    mn = nt.nodes.new("ShaderNodeTexImage")
    mn.image = mimg
    nt.links.new(mn.outputs["Color"], bsdf.inputs["Metallic"])
    for socket, node in made.items():
        for l in list(bsdf.inputs[socket].links):
            nt.links.remove(l)
        nt.links.new(node.outputs["Color"], bsdf.inputs[socket])


for k, o in objs.items():
    bake(o, {"iron": 1024, "brass": 1024, "ivory": 128, "eye": 64}[k])
faces = sum(len(o.data.polygons) for o in scene.objects if o.type == "MESH")
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_apply=True)
print("EXPORTED", out, "faces", faces, "bytes", os.path.getsize(out))
