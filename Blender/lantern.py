"""Lampwick Lane's protected item: the steampunk ward lantern (2026-10-28). Reference: UI Kit/art/comfy_out/
ref_steamlantern_s22.png (FLUX concept). Headless:  blender -b --factory-startup -P Blender/lantern.py -- <out.glb>
Hexagonal stone pedestal with a brass band, a pressure gauge and two valve wheels; a brass hexagonal lantern with
corner posts, arched window frames, rivets and filigree; glass panes (own object "Glass", made translucent in Studio);
a ribbed brass dome with a finial; one faceted crystal inside. Procedural materials baked to PBR maps (linear colour
values, colour baked through Emission so metals do not bake black, a constant metal map)."""
import bpy, bmesh, math, sys, os
from mathutils import Vector, Matrix

out = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 16
scene.cycles.device = "CPU"
H6 = [i / 6 * math.tau + math.pi / 6 for i in range(6)]


def join(objs, name, smooth=False):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    ob = bpy.context.active_object
    ob.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if smooth:
        bpy.ops.object.shade_smooth()
    return ob


def bevel(ob, w=0.03, seg=2):
    m = ob.modifiers.new("b", "BEVEL")
    m.width, m.segments, m.limit_method = w, seg, "ANGLE"
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier="b")
    return ob


def cyl(r, d, z, verts=6, rot=0.0, loc=(0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=d, location=(loc[0], loc[1], z), rotation=(0, 0, rot))
    return bpy.context.active_object


def lathe(name, profile, segments=24, loc=(0, 0, 0)):
    bm = bmesh.new()
    rings = [[bm.verts.new((math.cos(i / segments * math.tau + math.pi / segments) * r, math.sin(i / segments * math.tau + math.pi / segments) * r, z)) for i in range(segments)] for (r, z) in profile]
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


def tube(name, pts, r, sides=8):
    """sweep a circle along a polyline: arches, ribs, pipes"""
    bm = bmesh.new()
    rings = []
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        a = t.orthogonal().normalized()
        b2 = t.cross(a)
        rings.append([bm.verts.new(p + (a * math.cos(k / sides * math.tau) + b2 * math.sin(k / sides * math.tau)) * r) for k in range(sides)])
    for ra, rb in zip(rings, rings[1:]):
        for k in range(sides):
            bm.faces.new((ra[k], ra[(k + 1) % sides], rb[(k + 1) % sides], rb[k]))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    scene.collection.objects.link(ob)
    return ob


# --- stone pedestal (hexagonal, slightly tapered, with a plinth step) ---
st = [bevel(cyl(1.35, 0.3, 0.15)), bevel(cyl(1.1, 2.0, 1.3)), bevel(cyl(1.25, 0.25, 2.42))]
st[1].scale = (1, 1, 1)
pedestal = join(st, "Pedestal")

# --- brass: band, gauge, valves, lantern frame, dome, finial ---
brass = []
brass.append(bevel(cyl(1.18, 0.12, 2.25)))                        # band under the lantern
brass.append(bevel(cyl(1.0, 0.16, 2.62)))                         # lantern floor plate
brass.append(bevel(cyl(1.12, 0.16, 5.15)))                        # lantern top plate
for k, a in enumerate(H6):                                        # corner posts
    p = Vector((math.cos(a) * 0.98, math.sin(a) * 0.98, 3.9))
    bpy.ops.mesh.primitive_cube_add(size=1, location=p, rotation=(0, 0, a))
    post = bpy.context.active_object
    post.scale = (0.11, 0.11, 2.45)
    brass.append(bevel(post, 0.02))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.09, location=(p.x, p.y, 2.72))
    brass.append(bpy.context.active_object)
for k in range(6):                                                # arched window frames: a half torus per face
    a = (H6[k] + H6[(k + 1) % 6]) / 2 + (math.pi if k == 5 else 0) * 0
    a = H6[k] + math.pi / 6
    c = Vector((math.cos(a) * 0.86, math.sin(a) * 0.86, 4.55))
    side = Vector((-math.sin(a), math.cos(a), 0))
    arch = [c + side * (0.38 * math.cos(t * math.pi)) + Vector((0, 0, 0.38 * math.sin(t * math.pi))) for t in [i / 16 for i in range(17)]]
    arch = [arch[0] - Vector((0, 0, 1.5))] + arch + [arch[-1] - Vector((0, 0, 1.5))]   # the arch's legs run down the pane
    brass.append(tube("arch%d" % k, arch, 0.035, 6))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.12, minor_radius=0.025, major_segments=12, minor_segments=6, location=(math.cos(a) * 0.9, math.sin(a) * 0.9, 3.0), rotation=(math.pi / 2, 0, a + math.pi / 2))
    brass.append(bpy.context.active_object)                       # filigree loop at the bottom of each pane
    for r in range(4):                                            # rivets on the band
        ra = a + (r - 1.5) * 0.18
        bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=0.035, location=(math.cos(ra) * 1.19, math.sin(ra) * 1.19, 2.25))
        brass.append(bpy.context.active_object)
# gauge on the front face of the pedestal, valve wheels on two sides
front = H6[0] + math.pi / 6
g = Vector((math.cos(front) * 1.06, math.sin(front) * 1.06, 1.45))
bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.32, depth=0.12, location=g, rotation=(math.pi / 2, 0, front + math.pi / 2))
brass.append(bevel(bpy.context.active_object, 0.02))
extra_faces = []
for side in (-1, 1):  # two smaller gauges on the neighbouring faces (reviewer: three raised brass gauges)
    a2 = front + side * math.pi / 3
    g2 = Vector((math.cos(a2) * 1.04, math.sin(a2) * 1.04, 1.85))
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.2, depth=0.12, location=g2, rotation=(math.pi / 2, 0, a2 + math.pi / 2))
    brass.append(bevel(bpy.context.active_object, 0.015))
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.16, depth=0.02, location=g2 + Vector((math.cos(a2), math.sin(a2), 0)) * 0.065, rotation=(math.pi / 2, 0, a2 + math.pi / 2))
    extra_faces.append(bpy.context.active_object)
for z in (0.42, 2.2):  # rivet bands round the stone
    for k in range(30):
        ra = k / 30 * math.tau
        bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=0.045, location=(math.cos(ra) * 1.13, math.sin(ra) * 1.13, z))
        brass.append(bpy.context.active_object)
bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.26, depth=0.02, location=g + Vector((math.cos(front), math.sin(front), 0)) * 0.065, rotation=(math.pi / 2, 0, front + math.pi / 2))
gauge_face = bpy.context.active_object
gauge_face.name = "GaugeFace"
if extra_faces:
    bpy.ops.object.select_all(action="DESELECT")
    for o in [gauge_face] + extra_faces:
        o.select_set(True)
    bpy.context.view_layer.objects.active = gauge_face
    bpy.ops.object.join()
    gauge_face = bpy.context.active_object
needle = tube("needle", [g + Vector((math.cos(front), math.sin(front), 0)) * 0.08, g + Vector((math.cos(front), math.sin(front), 0)) * 0.08 + Vector((-math.sin(front) * 0.15, math.cos(front) * 0.15, 0.12))], 0.015, 4)
brass.append(needle)
for side in (-2, 2):
    a = front + side * math.pi / 3
    v = Vector((math.cos(a) * 1.08, math.sin(a) * 1.08, 1.6))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.22, minor_radius=0.04, major_segments=20, minor_segments=6, location=v, rotation=(math.pi / 2, 0, a + math.pi / 2))
    brass.append(bpy.context.active_object)
    for sp in range(3):
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.025, depth=0.42, location=v, rotation=(math.pi / 2, sp * math.pi / 3, a + math.pi / 2))
        brass.append(bpy.context.active_object)
dome = lathe("domeb", [(1.25, 5.2), (1.3, 5.3), (1.15, 5.55), (0.95, 5.95), (0.7, 6.3), (0.4, 6.55), (0.22, 6.65), (0.22, 6.8), (0.3, 6.9), (0.12, 7.05), (0.16, 7.25), (0.1, 7.5), (0.0, 7.6)], 6)
brass.append(dome)
for a in H6:                                                      # dome ribs, following the dome's profile
    prof = [(1.3, 5.3), (1.15, 5.55), (0.95, 5.95), (0.7, 6.3), (0.4, 6.55), (0.22, 6.65)]
    pts = [Vector((math.cos(a) * (r + 0.04), math.sin(a) * (r + 0.04), z + 0.03)) for (r, z) in prof]
    brass.append(tube("rib", pts, 0.05, 6))
brass.append(bevel(cyl(1.42, 0.14, 5.22)))                       # canopy ledge under the dome (reviewer)
for k in range(24):                                               # rivets on the ledge
    ra = k / 24 * math.tau
    bpy.ops.mesh.primitive_uv_sphere_add(segments=6, ring_count=4, radius=0.04, location=(math.cos(ra) * 1.38, math.sin(ra) * 1.38, 5.3))
    brass.append(bpy.context.active_object)
bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=0.2, location=(0, 0, 7.75))
brass.append(bpy.context.active_object)                           # ball finial
hook = [Vector((0.0, 0.0, 7.9))] + [Vector((0.3 * math.sin(t * 4), 0, 7.9 + 0.35 * t + 0.2 * (1 - math.cos(t * 4)))) for t in [i / 12 for i in range(1, 13)]]
brass.append(tube("hook", hook, 0.035, 6))                        # curled hook on the finial
for k in range(6):                                                # filigree scrolls on each pane's lower half
    a = H6[k] + math.pi / 6
    c = Vector((math.cos(a) * 0.9, math.sin(a) * 0.9, 3.45))
    side = Vector((-math.sin(a), math.cos(a), 0))
    for sgn in (-1, 1):
        spiral = [c + side * sgn * (0.05 + 0.2 * t) * math.cos(t * 9) * 0.9 + Vector((0, 0, (0.05 + 0.2 * t) * math.sin(t * 9))) for t in [i / 24 for i in range(25)]]
        brass.append(tube("scroll", spiral, 0.02, 5))
gc = g + Vector((math.cos(front), math.sin(front), 0)) * 0.07     # rim around the gauge face
rim = [gc + Vector((-math.sin(front), math.cos(front), 0)) * 0.27 * math.cos(t * math.tau) + Vector((0, 0, 0.27 * math.sin(t * math.tau))) for t in [i / 24 for i in range(25)]]
brass.append(tube("rim", rim, 0.03, 6))
frame = join(brass, "Frame", smooth=True)

# --- glass panes (one hexagonal shell) and the crystal ---
glass = cyl(0.93, 2.35, 3.88)
glass.name = "Glass"
bm = bmesh.new()
pts = [bm.verts.new((0, 0, 2.95)), bm.verts.new((0, 0, 4.75))]
ring = [bm.verts.new((math.cos(i / 6 * math.tau) * 0.36, math.sin(i / 6 * math.tau) * 0.36, 3.75 + (0.08 if i % 2 else -0.06))) for i in range(6)]
for i in range(6):
    j = (i + 1) % 6
    bm.faces.new((pts[0], ring[j], ring[i]))
    bm.faces.new((pts[1], ring[i], ring[j]))
me = bpy.data.meshes.new("Crystal")
bm.to_mesh(me)
bm.free()
crystal = bpy.data.objects.new("Crystal", me)
scene.collection.objects.link(crystal)


def mat(name, build):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    build(m.node_tree, m.node_tree.nodes["Principled BSDF"])
    return m


def ramp_noise(nt, bsdf, scale, c0, c1, rough=None, metal=0.0, pos1=1.0):
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = scale
    noise.inputs["Detail"].default_value = 8
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = c0
    ramp.color_ramp.elements[1].color = c1
    ramp.color_ramp.elements[1].position = pos1
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    if rough:
        rr = nt.nodes.new("ShaderNodeMapRange")
        rr.inputs["To Min"].default_value, rr.inputs["To Max"].default_value = rough
        nt.links.new(noise.outputs["Fac"], rr.inputs["Value"])
        nt.links.new(rr.outputs[0], bsdf.inputs["Roughness"])
    bsdf.inputs["Metallic"].default_value = metal


def brass_mat(nt, bsdf):  # polished brass with darker tarnish in the noise (linear values: sRGB ~200,150,70)
    ramp_noise(nt, bsdf, 2.5, (0.06, 0.03, 0.008, 1), (0.32, 0.17, 0.04, 1), (0.5, 0.3), 0.85, 0.8)  # 0.85 metal: at 1.0 Roblox reflects the bright sky and brass reads white (v2, v5)  # reviewer: 'blotchy crumpled foil' -> broad soft variation, darker bronze


def stone_mat(nt, bsdf):  # dressed stone blocks: brick texture for mortar lines, noise for wear (reviewer: 'no texture')
    tc = nt.nodes.new("ShaderNodeTexCoord")
    br = nt.nodes.new("ShaderNodeTexBrick")
    br.inputs["Scale"].default_value = 4.0
    br.inputs["Mortar Size"].default_value = 0.015
    br.inputs["Color1"].default_value = (0.09, 0.09, 0.1, 1)
    br.inputs["Color2"].default_value = (0.06, 0.06, 0.07, 1)  # grey stone (reviewer: dark planks)
    br.inputs["Mortar"].default_value = (0.006, 0.006, 0.008, 1)
    nt.links.new(tc.outputs["Generated"], br.inputs["Vector"])
    n = nt.nodes.new("ShaderNodeTexNoise")
    n.inputs["Scale"].default_value = 25
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 0.5
    nt.links.new(br.outputs["Color"], mix.inputs["A"])
    nt.links.new(n.outputs["Color"], mix.inputs["B"])
    nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Metallic"].default_value = 0.0


def glass_mat(nt, bsdf):
    bsdf.inputs["Base Color"].default_value = (0.02, 0.35, 0.42, 1)  # deeper teal: v4 read cream
    bsdf.inputs["Roughness"].default_value = 0.05


def crystal_mat(nt, bsdf):  # cyan with a white core band
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Object"], sep.inputs[0])
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["From Min"].default_value, mr.inputs["From Max"].default_value = 2.95, 4.75
    nt.links.new(sep.outputs["Z"], mr.inputs["Value"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0.02, 0.25, 0.45, 1)
    ramp.color_ramp.elements[1].color = (0.02, 0.25, 0.45, 1)
    mid = ramp.color_ramp.elements.new(0.45)
    mid.color = (0.85, 0.98, 1.0, 1)
    nt.links.new(mr.outputs[0], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.05


def ivory_mat(nt, bsdf):
    bsdf.inputs["Base Color"].default_value = (0.75, 0.66, 0.48, 1)
    bsdf.inputs["Roughness"].default_value = 0.4


gauge_face.data.materials.append(mat("Ivory", ivory_mat))
for ob, f, n in ((pedestal, stone_mat, "Stone"), (frame, brass_mat, "Brass"), (glass, glass_mat, "GlassMat"), (crystal, crystal_mat, "CrystalMat")):
    ob.data.materials.append(mat(n, f))


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
            src = bsdf.inputs["Base Color"].links[0].from_socket if bsdf.inputs["Base Color"].links else None
            if src:
                nt.links.new(src, em.inputs["Color"])
            else:
                em.inputs["Color"].default_value = bsdf.inputs["Base Color"].default_value
            nt.links.new(em.outputs[0], outn.inputs["Surface"])
            bpy.ops.object.bake(type="EMIT")
            nt.links.new(bsdf.outputs[0], outn.inputs["Surface"])
            nt.nodes.remove(em)
        else:
            bpy.ops.object.bake(type="ROUGHNESS")
        made["Base Color" if kind == "color" else "Roughness"] = node
        img.filepath_raw = os.path.join(os.path.dirname(out), "lantern_" + img.name + ".png")
        img.file_format = "PNG"
        img.save()
    met = bsdf.inputs["Metallic"].default_value
    if True:  # every material gets an explicit metal map: without one, Roblox's importer gave stone AND brass a white (fully metal) map
        mimg = bpy.data.images.new("%s_metal" % ob.name, size, size)  # same size as roughness: glTF packs both into one image (16 px got dropped)
        mimg.colorspace_settings.name = "Non-Color"
        mimg.generated_color = (met, met, met, 1)
        mn = nt.nodes.new("ShaderNodeTexImage")
        mn.image = mimg
        nt.links.new(mn.outputs["Color"], bsdf.inputs["Metallic"])
    for socket, node in made.items():
        for l in list(bsdf.inputs[socket].links):
            nt.links.remove(l)
        nt.links.new(node.outputs["Color"], bsdf.inputs[socket])


for ob, size in ((pedestal, 1024), (frame, 1024), (glass, 128), (crystal, 256), (gauge_face, 64)):
    bake(ob, size)
faces = sum(len(o.data.polygons) for o in scene.objects if o.type == "MESH")
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_apply=True)
print("EXPORTED", out, "faces", faces, "bytes", os.path.getsize(out))
