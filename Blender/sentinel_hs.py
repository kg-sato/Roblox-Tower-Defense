"""Brass Sentinel v9, hard-surface rebuild (2026-10-28, the user chose "Hard-surface rebuild" after the Hunyuan paint
route scored 5/3/4/4/5: "clay golem", blotchy paint). Reference: UI Kit/art/comfy_out/ref_sentinel_s33.png.
    blender -b --factory-startup -P Blender/sentinel_hs.py -- <out.glb>
Gorilla-built steam automaton facing -Y: brass barrel torso with riveted chest plate, a glowing furnace grill in the
belly, a small helmet sunk between huge pauldrons with one red eye, a copper boiler and two chimneys on the back with
pipes to the shoulders, piston arms ending in clamp fists, short piston legs with big boots.
Flat colour zones (the user's "Flat colours"): brass, dark iron, copper; the eye and furnace are one object "Eye"
(Models.luau makes it Neon). The colour bake multiplies in ambient occlusion so seams read dark. Every material gets an
explicit metal map (Roblox's importer otherwise gives a white, fully metal one); metal stays <= 0.45 because higher
values mirror the blue night sky (v6). Colours are linear."""
import bpy, math, sys, os

out = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 32
scene.cycles.device = "CPU"
# v10 (user: "split + walk"): every piece goes into a body part, joined per part so Models.luau can swing the limbs.
# Parts: Body (torso, head, back, pauldrons), Arm{L,R}_{Upper,Lower}, Leg{L,R}_{Upper,Lower}, Eye (eye + furnace glow).
parts = {}
PART = ["Body"]
# flat zone colours (linear), metal, roughness
SPEC = {
    "brass": ((0.30, 0.105, 0.012), 0.3, 0.35),  # v9-v11 read lemon, then lime in the lantern's cyan light: orange-leaning gold, less sky reflection
    "ivory": ((0.62, 0.55, 0.40), 0.0, 0.45),
    "iron": ((0.03, 0.025, 0.022), 0.4, 0.5),  # warm near-black (v10 read navy)
    "copper": ((0.24, 0.055, 0.015), 0.35, 0.4),  # v11 pauldrons read peach
    "eye": ((1.0, 0.18, 0.03), 0.0, 0.3),
}
MATS = {}
for k, (col, met, rough) in SPEC.items():
    m = bpy.data.materials.new(k)
    m.use_nodes = True
    nt, b = m.node_tree, m.node_tree.nodes["Principled BSDF"]
    if k == "eye":
        b.inputs["Base Color"].default_value = (*col, 1)
    else:  # flat colour times ambient occlusion: dark seams, no noise
        ao = nt.nodes.new("ShaderNodeAmbientOcclusion")
        ao.inputs["Distance"].default_value = 0.35
        mr = nt.nodes.new("ShaderNodeMapRange")
        mr.inputs["To Min"].default_value, mr.inputs["To Max"].default_value = 0.45, 1.0
        nt.links.new(ao.outputs["AO"], mr.inputs["Value"])
        mul = nt.nodes.new("ShaderNodeMix")
        mul.data_type, mul.blend_type = "RGBA", "MULTIPLY"
        mul.inputs["Factor"].default_value = 1.0
        mul.inputs[6].default_value = (*col, 1)
        nt.links.new(mr.outputs[0], mul.inputs[7])
        nt.links.new(mul.outputs[2], b.inputs["Base Color"])
    b.inputs["Metallic"].default_value = met
    b.inputs["Roughness"].default_value = rough
    MATS[k] = m
X = math.pi / 2


def add(kind, o, bev=0.0, seg=3):
    if bev > 0:
        m = o.modifiers.new("b", "BEVEL")
        m.width, m.segments, m.limit_method = bev, seg, "ANGLE"
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier="b")
    o.data.materials.append(MATS[kind])
    parts.setdefault("Eye" if kind == "eye" else PART[0], []).append(o)
    return o


def box(kind, size, loc, rot=(0, 0, 0), bev=0.06, taper=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if taper:  # shrink the bottom face in X/Y by this factor (tapered forearms, shins)
        for v in o.data.vertices:
            if v.co.z < 0:
                v.co.x *= taper
                v.co.y *= taper
    return add(kind, o, bev)


def cyl(kind, r, d, loc, rot=(0, 0, 0), v=24, bev=0.03):
    bpy.ops.mesh.primitive_cylinder_add(vertices=v, radius=r, depth=d, location=loc, rotation=rot)
    return add(kind, bpy.context.active_object, bev, 2)


def ball(kind, r, loc, scale=(1, 1, 1), seg=20):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, radius=r, location=loc)
    o = bpy.context.active_object
    o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    return add(kind, o)


def ring(kind, R, r, loc, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=28, minor_segments=8, location=loc, rotation=rot)
    return add(kind, bpy.context.active_object)


def rivet(loc):
    return ball("iron", 0.05, loc, seg=8)


def pipe(kind, pts, r):
    cu = bpy.data.curves.new("p", "CURVE")
    cu.dimensions, cu.bevel_depth, cu.bevel_resolution = "3D", r, 3
    sp = cu.splines.new("BEZIER")
    sp.bezier_points.add(len(pts) - 1)
    for bp, p in zip(sp.bezier_points, pts):
        bp.co = p
        bp.handle_left_type = bp.handle_right_type = "AUTO"
    o = bpy.data.objects.new("p", cu)
    scene.collection.objects.link(o)
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.convert(target="MESH")
    return add(kind, bpy.context.active_object)


# ---- torso: brass barrel chest, riveted chest plate, iron belly with furnace grill, brass pelvis
box("brass", (2.5, 1.8, 1.7), (0, 0, 3.55), bev=0.16)  # v11: tighter bevels read as machined, not clay
box("brass", (1.5, 0.12, 0.95), (0, -0.92, 3.75), bev=0.05)                     # raised chest plate
for k in range(7):
    rivet((-0.66 + k * 0.22, -0.99, 4.17))
    rivet((-0.66 + k * 0.22, -0.99, 3.33))
# one pressure dial (ivory face, iron needle) and a vent grill: v9 had two round gauges that read as cartoon eyes
cyl("copper", 0.2, 0.08, (-0.4, -1.0, 3.75), (X, 0, 0))
cyl("ivory", 0.16, 0.04, (-0.4, -1.05, 3.75), (X, 0, 0), bev=0)
box("iron", (0.025, 0.02, 0.13), (-0.37, -1.075, 3.79), (0, math.radians(-35), 0), bev=0)
for k in range(4):
    box("iron", (0.5, 0.06, 0.06), (0.38, -1.0, 3.57 + k * 0.12), bev=0.02)
box("copper", (2.3, 1.7, 0.14), (0, 0, 2.7), bev=0.04)                          # belt band
box("iron", (1.9, 1.45, 0.75), (0, 0, 2.3), bev=0.15)                           # belly
box("iron", (1.15, 0.1, 0.55), (0, -0.75, 2.3), bev=0.03)                       # furnace frame
for k in range(4):                                                              # glowing slits between bars
    box("eye", (0.95, 0.06, 0.07), (0, -0.78, 2.12 + k * 0.12), bev=0.0)
box("brass", (2.0, 1.5, 0.45), (0, 0, 1.85), bev=0.08)                          # pelvis
# ---- head: iron collar, small brass helmet sunk between the shoulders, brow, single red eye in a copper bezel
cyl("iron", 0.55, 0.25, (0, -0.15, 4.42), v=28)
ball("brass", 0.66, (0, -0.25, 4.74), (1, 1, 0.82))
box("brass", (0.9, 0.3, 0.14), (0, -0.72, 4.92), (math.radians(-12), 0, 0), bev=0.05)   # brow ridge
cyl("iron", 0.27, 0.28, (0, -0.72, 4.68), (X, 0, 0))
ring("copper", 0.25, 0.05, (0, -0.86, 4.68), (X, 0, 0))
cyl("eye", 0.2, 0.06, (0, -0.86, 4.68), (X, 0, 0), bev=0)
cyl("copper", 0.07, 0.35, (0, -0.2, 5.25), v=12)                                # helmet valve
ball("copper", 0.1, (0, -0.2, 5.45), seg=12)
# ---- back: copper boiler with brass bands, two iron chimneys with brass caps, pipes to the shoulders
cyl("copper", 0.62, 1.7, (0, 1.05, 3.7), v=28)
for z in (3.05, 3.7, 4.35):
    ring("brass", 0.63, 0.05, (0, 1.05, z))
for s in (-1, 1):
    cyl("iron", 0.17, 1.2, (s * 0.32, 1.2, 4.95), v=16)
    cyl("brass", 0.23, 0.14, (s * 0.32, 1.2, 5.55), v=16)
    pipe("copper", [(s * 0.55, 1.1, 4.2), (s * 1.0, 0.9, 4.75), (s * 1.45, 0.35, 4.6)], 0.08)
# ---- arms: huge pauldrons, piston upper arm, brass elbow, tapered brass forearm, iron clamp fist
for s in (-1, 1):
    side = "L" if s > 0 else "R"
    PART[0] = "Body"
    # v11: square armoured pauldrons in copper (reviewer: "puffy balloon domes", copper only as thin trim)
    box("copper", (1.25, 1.35, 0.7), (s * 1.7, 0, 4.2), (0, s * math.radians(-12), 0), bev=0.1)
    box("iron", (1.3, 1.4, 0.12), (s * 1.7, 0, 3.85), (0, s * math.radians(-12), 0), bev=0.03)
    for a in (-0.5, 0, 0.5):
        rivet((s * 1.7 + math.sin(a) * 0.5, -0.69, 4.25))
    PART[0] = "Arm%s_Upper" % side
    cyl("iron", 0.24, 1.0, (s * 1.75, 0, 3.25), v=16)
    cyl("brass", 0.1, 0.9, (s * 1.75, -0.32, 3.25), v=12)                       # piston rod in front
    ball("brass", 0.3, (s * 1.75, 0, 2.7))
    PART[0] = "Arm%s_Lower" % side
    box("brass", (0.78, 0.8, 1.05), (s * 1.8, -0.05, 2.1), bev=0.14, taper=0.8)
    ring("copper", 0.4, 0.06, (s * 1.8, -0.05, 2.55))
    box("iron", (0.8, 0.75, 0.5), (s * 1.8, -0.1, 1.38), bev=0.12)               # fist
    for c in (-1, 0, 1):                                                        # three clamp fingers
        box("iron", (0.2, 0.25, 0.42), (s * 1.8 + c * 0.24, -0.38, 1.05), (math.radians(14), 0, 0), bev=0.06)
    box("brass", (0.82, 0.16, 0.2), (s * 1.8, -0.5, 1.5), bev=0.05)            # knuckle plate
# ---- legs: iron thigh, brass knee cap, tapered brass shin with a piston, iron boot with brass toe cap
for s in (-1, 1):
    side = "L" if s > 0 else "R"
    PART[0] = "Leg%s_Upper" % side
    cyl("iron", 0.36, 0.6, (s * 0.62, 0, 1.4), v=20)
    ball("brass", 0.3, (s * 0.62, -0.22, 1.08), (1, 0.8, 1))
    PART[0] = "Leg%s_Lower" % side
    box("brass", (0.8, 0.85, 0.75), (s * 0.62, 0, 0.72), bev=0.12, taper=0.85)
    cyl("iron", 0.08, 0.7, (s * 0.62, 0.45, 0.8), v=10)
    box("iron", (0.95, 1.3, 0.36), (s * 0.62, -0.18, 0.18), bev=0.1)
    box("brass", (0.9, 0.3, 0.26), (s * 0.62, -0.72, 0.22), bev=0.08)

PART[0] = "Body"


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = o.data.name = name  # glTF exports the mesh name; Models.luau finds parts by these names
    bpy.ops.object.shade_smooth()
    wn = o.modifiers.new("w", "WEIGHTED_NORMAL")  # hard-surface shading: flat faces stay flat, bevels catch light
    wn.keep_sharp = True
    bpy.ops.object.modifier_apply(modifier="w")
    return o


objs = {k: join(v, k) for k, v in parts.items()}


def image(name, size, data):
    img = bpy.data.images.new(name, size, size)
    if data:
        img.colorspace_settings.name = "Non-Color"
    return img


def bake_part(ob, size):
    """Bake every material slot of one part into a single colour, metal and roughness map, then give the part one
    material with those maps (one SurfaceAppearance per MeshPart in Roblox)."""
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.01)
    bpy.ops.object.mode_set(mode="OBJECT")
    scene.render.bake.margin = 8
    imgs = {"color": image(ob.name + "_color", size, False), "metal": image(ob.name + "_metal", size, True),
            "rough": image(ob.name + "_rough", size, True)}
    mats = [s.material for s in ob.material_slots]
    for kind, img in imgs.items():
        temp = []
        for m in mats:
            nt = m.node_tree
            b, outn = nt.nodes["Principled BSDF"], nt.nodes["Material Output"]
            node = nt.nodes.new("ShaderNodeTexImage")
            node.image = img
            nt.nodes.active = node
            temp.append((nt, node))
            if kind == "rough":
                continue
            em = nt.nodes.new("ShaderNodeEmission")  # emission bake: a DIFFUSE bake of a metal comes out black
            if kind == "color" and b.inputs["Base Color"].links:
                nt.links.new(b.inputs["Base Color"].links[0].from_socket, em.inputs["Color"])
            elif kind == "color":
                em.inputs["Color"].default_value = b.inputs["Base Color"].default_value
            else:
                v = b.inputs["Metallic"].default_value
                em.inputs["Color"].default_value = (v, v, v, 1)
            nt.links.new(em.outputs[0], outn.inputs["Surface"])
            temp.append((nt, em))
        bpy.ops.object.bake(type="ROUGHNESS" if kind == "rough" else "EMIT")
        for nt, nd in temp:
            nt.nodes.remove(nd)
            nt.links.new(nt.nodes["Principled BSDF"].outputs[0], nt.nodes["Material Output"].inputs["Surface"])
    m = bpy.data.materials.new(ob.name + "_mat")
    m.use_nodes = True
    nt, b = m.node_tree, m.node_tree.nodes["Principled BSDF"]
    for kind, sock in (("color", "Base Color"), ("metal", "Metallic"), ("rough", "Roughness")):
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = imgs[kind]
        nt.links.new(t.outputs["Color"], b.inputs[sock])
    ob.data.materials.clear()
    ob.data.materials.append(m)


SIZE = {"Body": 1024, "Eye": 32}
for k, o in objs.items():
    bake_part(o, SIZE.get(k, 512))
tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in scene.objects if o.type == "MESH")
assert tris < 20000, tris  # project rule: meshes under 20k triangles
assert set(objs) == {"Body", "Eye", "ArmL_Upper", "ArmL_Lower", "ArmR_Upper", "ArmR_Lower",
                     "LegL_Upper", "LegL_Lower", "LegR_Upper", "LegR_Lower"}, sorted(objs)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_apply=True)
print("EXPORTED", out, "tris", tris, "parts", sorted(objs), "bytes", os.path.getsize(out))
