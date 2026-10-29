"""The Ward's crystal (2026-10-28 3D art replacement, pilot). Headless:
    blender -b --factory-startup -P Blender/crystal.py -- <out.glb>
A cluster of faceted crystals (tall centre, six smaller ones leaning out) on a brass Victorian base with rivets and a
filigree ring. Procedural materials are baked to 1024 px PBR maps (colour, roughness, metal, normal) so they survive
the Roblox importer, which does not read procedural nodes. Glow is added in Studio (Neon core + light + bloom), since
imported SurfaceAppearance has no emissive."""
import bpy, bmesh, math, random, sys, os
from mathutils import Vector, Matrix

out = sys.argv[sys.argv.index("--") + 1]
random.seed(7)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 16
scene.cycles.device = "CPU"


def crystal(name, height, radius, tilt, yaw, base_z=0.0, sides=6):
    """a hexagonal crystal: prism with a pointed, slightly off-centre tip; facets kept flat"""
    bm = bmesh.new()
    ring_lo, ring_hi = [], []
    for i in range(sides):
        a = i / sides * math.tau
        r = radius * random.uniform(0.85, 1.1)
        ring_lo.append(bm.verts.new((math.cos(a) * r * 0.9, math.sin(a) * r * 0.9, 0)))
        ring_hi.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, height * 0.72)))
    tip = bm.verts.new((radius * 0.12, -radius * 0.08, height))
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new((ring_lo[i], ring_lo[j], ring_hi[j], ring_hi[i]))
        bm.faces.new((ring_hi[i], ring_hi[j], tip))
    bm.faces.new(list(reversed(ring_lo)))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    scene.collection.objects.link(ob)
    ob.matrix_world = Matrix.Translation((0, 0, base_z)) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(tilt, 4, "Y")
    return ob


parts = [crystal("c0", 3.2, 0.55, 0.0, 0.0, 0.55)]
for k in range(6):
    yaw = k / 6 * math.tau + random.uniform(-0.2, 0.2)
    h = random.uniform(1.2, 2.1)
    ob = crystal("c%d" % (k + 1), h, random.uniform(0.25, 0.38), random.uniform(0.35, 0.6), yaw, 0.5)
    ob.location += Vector((math.cos(yaw) * 0.45, math.sin(yaw) * 0.45, 0))
    parts.append(ob)
bpy.ops.object.select_all(action="DESELECT")
for p in parts:
    p.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
cry = bpy.context.active_object
cry.name = "Crystal"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# brass base: a stepped round plinth, a filigree ring of small loops, and rivets
bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=1.25, depth=0.3, location=(0, 0, 0.15))
b1 = bpy.context.active_object
bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=1.0, depth=0.25, location=(0, 0, 0.42))
b2 = bpy.context.active_object
bpy.ops.mesh.primitive_torus_add(major_radius=1.12, minor_radius=0.05, major_segments=64, minor_segments=8, location=(0, 0, 0.32))
b3 = bpy.context.active_object
extra = []
for k in range(12):
    a = k / 12 * math.tau
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.06, location=(math.cos(a) * 1.18, math.sin(a) * 1.18, 0.3))
    extra.append(bpy.context.active_object)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.12, minor_radius=0.025, major_segments=16, minor_segments=6, location=(math.cos(a + 0.26) * 1.02, math.sin(a + 0.26) * 1.02, 0.55), rotation=(math.pi / 2, 0, a + 0.26 + math.pi / 2))
    extra.append(bpy.context.active_object)
bpy.ops.object.select_all(action="DESELECT")
for o in [b1, b2, b3] + extra:
    o.select_set(True)
bpy.context.view_layer.objects.active = b1
bpy.ops.object.join()
base = bpy.context.active_object
base.name = "Base"
bpy.ops.object.shade_smooth()


# the lantern around it (the Ward): stone plinth, four turned brass posts, an upper ring, a domed iron roof with a
# finial. Replaces MapBuilder's primitive parts. Units: Blender metres = Roblox studs here (scaled in Studio anyway).
def lathe(name, profile, segments=24, loc=(0, 0, 0)):
    """spin a (radius, z) profile around Z: turned posts, domes, finials"""
    bm = bmesh.new()
    rings = []
    for (r, z) in profile:
        ring = [bm.verts.new((math.cos(i / segments * math.tau) * r, math.sin(i / segments * math.tau) * r, z)) for i in range(segments)]
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            bm.faces.new((a[i], a[j], b[j], b[i]))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    scene.collection.objects.link(ob)
    ob.location = loc
    return ob

POST = [(0.16, 0), (0.2, 0.08), (0.2, 0.22), (0.12, 0.3), (0.1, 0.9), (0.14, 1.0), (0.09, 1.1), (0.08, 3.3), (0.13, 3.4), (0.09, 3.5), (0.09, 4.1), (0.15, 4.2), (0.15, 4.3), (0.0, 4.32)]
posts = [lathe("post%d" % k, POST, 16, (math.cos(a) * 1.55, math.sin(a) * 1.55, 0.55)) for k, a in enumerate([math.pi / 4 + i * math.pi / 2 for i in range(4)])]
ring = lathe("ring", [(1.85, 4.75), (1.95, 4.8), (1.95, 4.95), (1.8, 5.0), (1.7, 4.95), (1.7, 4.8), (1.85, 4.75)], 48)
dome = lathe("dome", [(2.15, 4.95), (2.2, 5.05), (2.0, 5.3), (1.6, 5.75), (1.0, 6.15), (0.45, 6.4), (0.3, 6.5), (0.18, 6.75), (0.28, 6.9), (0.2, 7.05), (0.0, 7.1)], 32)
finial = lathe("finial", [(0.12, 7.0), (0.22, 7.2), (0.16, 7.45), (0.05, 7.8), (0.0, 7.95)], 16)
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.0))
plinth = bpy.context.active_object
plinth.scale = (3.6, 3.6, 0.6)
bpy.ops.object.transform_apply(scale=True)
bev = plinth.modifiers.new("bev", "BEVEL")
bev.width, bev.segments = 0.08, 2
bpy.ops.object.modifier_apply(modifier="bev")
bpy.ops.object.select_all(action="DESELECT")
for o in posts + [ring, finial]:
    o.select_set(True)
bpy.context.view_layer.objects.active = posts[0]
bpy.ops.object.join()
frame = bpy.context.active_object
frame.name = "Frame"
bpy.ops.object.shade_smooth()
dome.name = "Roof"
for o in (dome,):
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.shade_smooth()
plinth.name = "Plinth"
base.location.z += 0.3   # the brass base now sits on the stone plinth
cry.location.z += 0.3

def mat(name, build):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    build(nt, bsdf)
    return m


def crystal_mat(nt, bsdf):
    """reviewer v4: 'flat pale white-blue, no facets, no inner colour, no accent'. Now: deep blue roots to cyan to
    white tips, violet-pink veins from noise, and bright facet edges from the geometry's pointiness (linear values)."""
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Object"], sep.inputs[0])
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["From Min"].default_value, mr.inputs["From Max"].default_value = 0.4, 3.8
    nt.links.new(sep.outputs["Z"], mr.inputs["Value"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0.004, 0.012, 0.08, 1)
    ramp.color_ramp.elements[1].color = (0.6, 0.85, 1.0, 1)
    mid = ramp.color_ramp.elements.new(0.45)
    mid.color = (0.01, 0.22, 0.45, 1)
    nt.links.new(mr.outputs[0], ramp.inputs["Fac"])
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 3.5
    noise.inputs["Detail"].default_value = 8
    veins = nt.nodes.new("ShaderNodeValToRGB")  # thin bands where noise crosses 0.5 = veins
    veins.color_ramp.elements[0].position = 0.47
    veins.color_ramp.elements[1].position = 0.5
    veins.color_ramp.elements[0].color = (0, 0, 0, 1)
    veins.color_ramp.elements[1].color = (1, 1, 1, 1)
    v2 = veins.color_ramp.elements.new(0.53)
    v2.color = (0, 0, 0, 1)
    nt.links.new(noise.outputs["Fac"], veins.inputs["Fac"])
    mixv = nt.nodes.new("ShaderNodeMix")
    mixv.data_type = "RGBA"
    mixv.inputs["B"].default_value = (0.55, 0.12, 0.6, 1)  # violet-pink accent
    nt.links.new(veins.outputs["Color"], mixv.inputs["Factor"])
    nt.links.new(ramp.outputs["Color"], mixv.inputs["A"])
    geo = nt.nodes.new("ShaderNodeNewGeometry")  # lighter on facets that face up (pointiness turned it all white)
    nsep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Normal"], nsep.inputs[0])
    edge = nt.nodes.new("ShaderNodeMapRange")
    edge.inputs["From Min"].default_value, edge.inputs["From Max"].default_value = 0.35, 1.0
    edge.inputs["To Max"].default_value = 0.45
    nt.links.new(nsep.outputs["Z"], edge.inputs["Value"])
    mixe = nt.nodes.new("ShaderNodeMix")
    mixe.data_type = "RGBA"
    mixe.inputs["B"].default_value = (0.9, 0.97, 1.0, 1)
    nt.links.new(edge.outputs[0], mixe.inputs["Factor"])
    nt.links.new(mixv.outputs["Result"], mixe.inputs["A"])
    nt.links.new(mixe.outputs["Result"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.08
    bsdf.inputs["Metallic"].default_value = 0.0


def brass_mat(nt, bsdf):
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 18
    ramp = nt.nodes.new("ShaderNodeValToRGB")  # worn brass: darker in the grime, bright on the wear
    ramp.color_ramp.elements[0].color = (0.04, 0.018, 0.004, 1)
    ramp.color_ramp.elements[1].color = (0.34, 0.17, 0.035, 1)  # linear values (sRGB ~150,105,45): v2/v3 read as cream
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    rr = nt.nodes.new("ShaderNodeMapRange")
    rr.inputs["To Min"].default_value, rr.inputs["To Max"].default_value = 0.55, 0.25
    nt.links.new(noise.outputs["Fac"], rr.inputs["Value"])
    nt.links.new(rr.outputs[0], bsdf.inputs["Roughness"])
    bsdf.inputs["Metallic"].default_value = 1.0


def iron_mat(nt, bsdf):
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 9
    ramp = nt.nodes.new("ShaderNodeValToRGB")  # dark iron with green-blue patina in the noise
    ramp.color_ramp.elements[0].color = (0.006, 0.007, 0.01, 1)
    ramp.color_ramp.elements[1].color = (0.018, 0.045, 0.04, 1)
    ramp.color_ramp.elements[1].position = 0.9  # quieter patina
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.45
    bsdf.inputs["Metallic"].default_value = 0.8


def stone_mat(nt, bsdf):
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 3
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 30
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "FLOAT"
    mix.inputs[0].default_value = 0.4
    nt.links.new(vor.outputs["Distance"], mix.inputs[2])
    nt.links.new(noise.outputs["Fac"], mix.inputs[3])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0.012, 0.011, 0.014, 1)
    ramp.color_ramp.elements[1].color = (0.07, 0.065, 0.078, 1)
    nt.links.new(mix.outputs[0], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.85


cry.data.materials.append(mat("CrystalMat", crystal_mat))
base.data.materials.append(mat("BrassMat", brass_mat))
frame.data.materials.append(mat("FrameBrass", brass_mat))
dome.data.materials.append(mat("RoofIron", iron_mat))
plinth.data.materials.append(mat("PlinthStone", stone_mat))


def bake(ob, size=1024):
    """smart-UV the object, bake base colour and roughness from the procedural nodes into images, rewire to them"""
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    m = ob.data.materials[0]
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    results = {}
    for kind, socket in (("color", "Base Color"), ("rough", "Roughness")):
        img = bpy.data.images.new("%s_%s" % (ob.name, kind), size, size)
        if kind == "rough":
            img.colorspace_settings.name = "Non-Color"
        node = nt.nodes.new("ShaderNodeTexImage")
        node.image = img
        nt.nodes.active = node
        scene.render.bake.margin = 8
        if kind == "color": # emission trick: a metal has no diffuse colour, so DIFFUSE baked the brass black
            out_node = nt.nodes["Material Output"]
            src = bsdf.inputs["Base Color"].links[0].from_socket if bsdf.inputs["Base Color"].links else None
            em = nt.nodes.new("ShaderNodeEmission")
            if src:
                nt.links.new(src, em.inputs["Color"])
            else:
                em.inputs["Color"].default_value = bsdf.inputs["Base Color"].default_value
            nt.links.new(em.outputs[0], out_node.inputs["Surface"])
            bpy.ops.object.bake(type="EMIT")
            nt.links.new(bsdf.outputs[0], out_node.inputs["Surface"])
            nt.nodes.remove(em)
        else:
            bpy.ops.object.bake(type="ROUGHNESS")
        results[socket] = node
    met = bsdf.inputs["Metallic"].default_value
    if met > 0: # a constant metal map: the importer ignored the bare metallic factor, so brass looked painted
        mimg = bpy.data.images.new("%s_metal" % ob.name, 16, 16)
        mimg.colorspace_settings.name = "Non-Color"
        mimg.generated_color = (met, met, met, 1)
        mnode = nt.nodes.new("ShaderNodeTexImage")
        mnode.image = mimg
        nt.links.new(mnode.outputs["Color"], bsdf.inputs["Metallic"])
    for socket, node in results.items():
        for l in list(bsdf.inputs[socket].links):
            nt.links.remove(l)
        nt.links.new(node.outputs["Color"], bsdf.inputs[socket])


for o in (cry, base, frame, dome, plinth):
    bake(o, 1024 if o in (cry, frame) else 512)
bpy.ops.object.select_all(action="SELECT")
tris = sum(len(o.data.polygons) for o in scene.objects if o.type == "MESH")
for img in bpy.data.images: # keep the baked maps next to the export for checking
    if img.name.startswith(("Crystal_", "Base_", "Frame_", "Roof_", "Plinth_")):
        img.filepath_raw = os.path.join(os.path.dirname(out), img.name + ".png")
        img.file_format = "PNG"
        img.save()
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_image_format="AUTO", export_apply=True)
print("EXPORTED", out, "faces", tris, "bytes", os.path.getsize(out))
