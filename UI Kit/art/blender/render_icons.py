"""Renders glossy cartoon 3D icons with a dark outline, transparent background, into UI Kit/art/inbox/.

Run (Blender 5.3 beta, headless):
  blender.exe -b --factory-startup -P "UI Kit/art/blender/render_icons.py" -- [--only egg,gift] [--size 512]

Look: inverted-hull outline (a slightly larger copy with flipped normals and backface culling), glossy Principled
materials, a warm key light from the upper left, soft fill, orthographic 3/4 camera. Models are simple primitives
on purpose: they read well at 64 px and cost nothing. Output names match the sprite names (icon_*.png).
Afterwards: python "UI Kit/art/ingest_art.py" (trims/pads/resizes, registers) then build_art.py.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
INBOX = os.path.normpath(os.path.join(HERE, "..", "inbox"))
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
only = None
size = 512
if "--only" in argv:
    only = set(argv[argv.index("--only") + 1].split(","))
if "--size" in argv:
    size = int(argv[argv.index("--size") + 1])

OUTLINE = (0.07, 0.07, 0.125, 1)


def rgb(r, g, b, a=1.0):
    # sRGB 0-255 -> linear
    f = lambda c: ((c / 255 + 0.055) / 1.055) ** 2.4 if c / 255 > 0.04045 else c / 255 / 12.92
    return (f(r), f(g), f(b), a)


def new_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.film_transparent = True
    sc.render.resolution_x = sc.render.resolution_y = size
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "Standard"
    try:
        sc.eevee.taa_render_samples = 48
    except Exception:
        pass
    world = bpy.data.worlds.new("w")
    sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.9, 0.93, 1.0, 1)
    bg.inputs[1].default_value = 0.55
    return sc


def material(color, rough=0.28, metal=0.0, emit=None):
    m = bpy.data.materials.new("m")
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = color
    p.inputs["Roughness"].default_value = rough
    p.inputs["Metallic"].default_value = metal
    for k, v in (("Coat Weight", 0.3), ("Coat Roughness", 0.2)):
        if k in p.inputs:
            p.inputs[k].default_value = v
    if emit is not None:
        p.inputs["Emission Color"].default_value = emit
        p.inputs["Emission Strength"].default_value = 1.2
    else:
        # faint self-glow in the base colour keeps candy colours saturated under soft light
        p.inputs["Emission Color"].default_value = color
        p.inputs["Emission Strength"].default_value = 0.32
    return m


def outline_material():
    m = bpy.data.materials.new("outline")
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = OUTLINE
    em.inputs["Strength"].default_value = 1.0
    nt.links.new(em.outputs[0], out.inputs[0])
    m.use_backface_culling = True
    return m


OUTLINE_MAT = None
PARTS = []


def finish(obj, mat, outline=0.045, smooth=True):
    outline = outline * 2.2 if outline else outline
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    if smooth:
        for p in obj.data.polygons:
            p.use_smooth = True
    bpy.context.view_layer.update()
    if outline:
        o = obj.copy()
        o.data = obj.data.copy()
        o.data.materials.clear()
        o.data.materials.append(OUTLINE_MAT)
        mod = o.modifiers.new("hull", "SOLIDIFY")
        mod.thickness = outline
        mod.offset = 1
        mod.use_flip_normals = True
        bpy.context.scene.collection.objects.link(o)
    PARTS.append(obj)
    return obj


def sphere(loc, scale, mat, outline=0.045):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, location=loc)
    o = bpy.context.object
    o.scale = scale
    return finish(o, mat, outline)


def cube(loc, scale, mat, bevel=0.08, outline=0.04, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object
    o.scale = scale
    o.rotation_euler = rot
    b = o.modifiers.new("b", "BEVEL")
    b.width = bevel
    b.segments = 5
    b.limit_method = "ANGLE"
    bpy.ops.object.modifier_apply(modifier="b")
    return finish(o, mat, outline)


def cyl(loc, radius, depth, mat, verts=48, rot=(0, 0, 0), r2=None, outline=0.04, bevel=0.0):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=loc, rotation=rot)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=r2, depth=depth, location=loc, rotation=rot)
    o = bpy.context.object
    if bevel:
        b = o.modifiers.new("b", "BEVEL")
        b.width = bevel
        b.segments = 4
        bpy.ops.object.modifier_apply(modifier="b")
    return finish(o, mat, outline)


def torus(loc, major, minor, mat, rot=(0, 0, 0), outline=0.035):
    bpy.ops.mesh.primitive_torus_add(location=loc, rotation=rot, major_radius=major, minor_radius=minor, major_segments=48, minor_segments=20)
    return finish(bpy.context.object, mat, outline)


# ---------------------------------------------------------------- models
GOLD = lambda: material(rgb(255, 196, 40), 0.22, 0.6)
STEEL = lambda: material(rgb(190, 200, 215), 0.25, 0.7)


def m_egg():
    cream, pink, blue = material(rgb(255, 236, 205)), material(rgb(255, 130, 170)), material(rgb(90, 190, 255))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=64, ring_count=32, location=(0, 0, 0))
    o = bpy.context.object
    for v in o.data.vertices:
        z = v.co.z
        taper = 1 - 0.2 * max(0.0, z)
        v.co.x *= taper
        v.co.y *= taper
        v.co.z = z * 1.3
    finish(o, cream, 0.05)
    spots = [(0.55, -0.7, 0.55, 0.2, pink), (-0.5, -0.78, -0.2, 0.17, blue), (0.2, -0.9, -0.55, 0.15, pink), (-0.35, -0.7, 0.9, 0.12, blue), (0.62, -0.6, -0.15, 0.1, blue)]
    for x, y, z, r, m in spots:
        d = Vector((x, y, z))
        d.normalize()
        sphere((x, y, z * 1.05), (r, r * 0.5, r), m, outline=0)


def m_gift():
    box, lid, rib = material(rgb(160, 90, 255)), material(rgb(185, 120, 255)), GOLD()
    cube((0, 0, -0.25), (1.0, 1.0, 0.75), box, 0.1)
    cube((0, 0, 0.62), (1.1, 1.1, 0.3), lid, 0.1)
    cube((0, 0, -0.15), (0.2, 1.03, 0.78), rib, 0.04)
    cube((0, 0, -0.15), (1.03, 0.2, 0.78), rib, 0.04)
    cube((0, 0, 0.62), (0.22, 1.14, 0.32), rib, 0.04)
    cube((0, 0, 0.62), (1.14, 0.22, 0.32), rib, 0.04)
    torus((0.38, 0, 1.05), 0.38, 0.13, rib, rot=(math.radians(90), math.radians(20), 0))
    torus((-0.38, 0, 1.05), 0.38, 0.13, rib, rot=(math.radians(90), math.radians(-20), 0))
    sphere((0, 0, 0.98), (0.2, 0.2, 0.2), rib)


def m_chest():
    wood, band, dark = material(rgb(150, 90, 40), 0.4), GOLD(), material(rgb(90, 50, 25), 0.5)
    cube((0, 0, -0.3), (1.35, 0.9, 0.55), wood, 0.07)
    cyl((0, 0, 0.3), 0.9, 2.7, wood, rot=(0, math.radians(90), 0), outline=0.045)
    for x in (-0.95, 0.95):
        cube((x, 0, -0.3), (0.12, 0.95, 0.58), band, 0.03)
        cyl((x, 0, 0.3), 0.95, 0.24, band, rot=(0, math.radians(90), 0), outline=0.03)
    cube((0, -0.92, -0.05), (0.2, 0.08, 0.26), band, 0.03)
    sphere((0, -1.0, -0.05), (0.08, 0.05, 0.08), dark, 0)


def m_paw():
    brown, light = material(rgb(160, 95, 50)), material(rgb(205, 135, 80))
    sphere((0, 0, -0.35), (0.95, 0.55, 0.8), brown)
    for x, z, r in ((-0.85, 0.5, 0.33), (-0.3, 0.95, 0.36), (0.3, 0.95, 0.36), (0.85, 0.5, 0.33)):
        sphere((x, 0, z), (r, r * 0.55, r * 1.1), brown)
    sphere((0, -0.3, -0.3), (0.5, 0.2, 0.42), light, 0)


def m_gear():
    steel, dark = STEEL(), material(rgb(60, 66, 85), 0.5)
    cyl((0, 0, 0), 0.95, 0.5, steel, rot=(math.radians(90), 0, 0), bevel=0.05)
    for i in range(8):
        a = math.radians(i * 45)
        cube((math.cos(a) * 1.08, 0, math.sin(a) * 1.08), (0.3, 0.25, 0.3), steel, 0.05, rot=(0, -a, 0))
    cyl((0, -0.27, 0), 0.4, 0.2, dark, rot=(math.radians(90), 0, 0), outline=0.03)


def m_book():
    cover, pages, gold = material(rgb(50, 130, 235)), material(rgb(255, 246, 222), 0.6), GOLD()
    cube((0, 0, 0), (0.95, 0.38, 1.2), cover, 0.07)
    cube((0.06, -0.05, 0), (0.85, 0.36, 1.12), pages, 0.03, outline=0.02)
    cube((0, -0.4, 0), (0.92, 0.04, 1.17), cover, 0.04, outline=0)
    cube((-0.9, 0, 0), (0.08, 0.4, 1.2), cover, 0.04)
    sphere((0.05, -0.43, 0.15), (0.3, 0.05, 0.3), gold, 0.02)


def m_bag():
    red, handle = material(rgb(235, 70, 70)), material(rgb(255, 245, 235))
    cube((0, 0, -0.1), (0.95, 0.5, 1.05), red, 0.18)
    torus((0, 0, 0.9), 0.38, 0.07, handle, rot=(math.radians(90), 0, 0), outline=0.03)
    cube((0, -0.52, 0.0), (0.45, 0.04, 0.3), handle, 0.03, outline=0)


def m_trophy():
    g = GOLD()
    cyl((0, 0, 0.35), 0.95, 1.5, g, r2=0.55, rot=(math.radians(180), 0, 0), outline=0.05)
    cyl((0, 0, -0.55), 0.18, 0.8, g, outline=0.04)
    cyl((0, 0, -1.0), 0.65, 0.22, g, bevel=0.04)
    torus((-1.0, 0, 0.45), 0.35, 0.09, g, rot=(math.radians(90), 0, 0))
    torus((1.0, 0, 0.45), 0.35, 0.09, g, rot=(math.radians(90), 0, 0))
    sphere((0, -0.9, 0.45), (0.22, 0.05, 0.22), material(rgb(255, 240, 150), 0.2), 0)


def m_key():
    g = GOLD()
    torus((0, 0, 0.85), 0.55, 0.2, g, rot=(math.radians(90), 0, 0))
    cyl((0, 0, -0.35), 0.17, 1.9, g)
    cube((0.28, 0, -0.85), (0.3, 0.17, 0.12), g, 0.03)
    cube((0.24, 0, -0.45), (0.26, 0.17, 0.12), g, 0.03)


def m_shard():
    c, c2 = material(rgb(60, 210, 255), 0.12, emit=rgb(30, 160, 255)), material(rgb(130, 235, 255), 0.12, emit=rgb(70, 200, 255))
    for x, h, r, tilt, m in ((0, 2.0, 0.5, 0, c2), (-0.7, 1.4, 0.38, 22, c), (0.7, 1.2, 0.34, -22, c)):
        cyl((x, 0, -0.5 + h / 2), r, h, m, verts=6, r2=0.0, rot=(0, math.radians(tilt), 0), outline=0.04)


def m_potion():
    glass, liquid, cork = material(rgb(210, 235, 255), 0.05), material(rgb(170, 80, 255), 0.15, emit=rgb(120, 50, 220)), material(rgb(165, 105, 55), 0.5)
    sphere((0, 0, -0.2), (0.95, 0.95, 0.95), liquid)
    cyl((0, 0, 0.85), 0.28, 0.9, glass, outline=0.04)
    cyl((0, 0, 1.4), 0.34, 0.3, cork, bevel=0.04)
    sphere((-0.35, -0.75, 0.15), (0.2, 0.08, 0.28), material(rgb(255, 255, 255), 0.1), 0)


def m_crystal():
    c, c2 = material(rgb(110, 90, 255), 0.1, emit=rgb(80, 60, 230)), material(rgb(170, 150, 255), 0.1, emit=rgb(130, 110, 255))
    cyl((0, 0, 0.0), 0.7, 1.4, c, verts=6)
    cyl((0, 0, 1.2), 0.7, 1.0, c2, verts=6, r2=0.0)
    cyl((0, 0, -1.2), 0.7, 1.0, c, verts=6, r2=0.0, rot=(math.radians(180), 0, 0))



def m_apple():
    red, leaf, brown = material(rgb(235, 55, 60)), material(rgb(80, 200, 80)), material(rgb(120, 75, 40), 0.5)
    sphere((0, 0, 0), (1.0, 0.95, 0.92), red)
    sphere((-0.38, -0.55, 0.15), (0.2, 0.08, 0.3), material(rgb(255, 200, 200), 0.1), 0)
    cyl((0, 0, 0.98), 0.07, 0.45, brown, outline=0.03)
    sphere((0.32, 0, 1.05), (0.4, 0.07, 0.22), leaf, 0.03)


def m_candy():
    pink, white, wrap = material(rgb(255, 90, 160)), material(rgb(255, 245, 250)), material(rgb(255, 120, 190), 0.3)
    sphere((0, 0, 0), (0.85, 0.85, 0.85), pink)
    torus((0, -0.62, 0), 0.38, 0.07, white, rot=(math.radians(90), 0, 0), outline=0.02)
    torus((0, -0.7, 0), 0.2, 0.06, white, rot=(math.radians(90), 0, 0), outline=0.02)
    cyl((1.15, 0, 0), 0.5, 0.55, wrap, r2=0.12, rot=(0, math.radians(90), 0), outline=0.035)
    cyl((-1.15, 0, 0), 0.5, 0.55, wrap, r2=0.12, rot=(0, math.radians(-90), 0), outline=0.035)


def m_garlic():
    cream, shade_, brown = material(rgb(252, 244, 232), 0.35), material(rgb(225, 205, 235), 0.4), material(rgb(150, 110, 60), 0.5)
    sphere((0, 0, -0.1), (1.0, 0.9, 0.85), cream)
    sphere((-0.55, -0.15, -0.1), (0.5, 0.78, 0.8), shade_, 0)
    sphere((0.55, -0.15, -0.1), (0.5, 0.78, 0.8), shade_, 0)
    cyl((0, 0, 0.95), 0.2, 0.8, cream, r2=0.08, outline=0.04)
    sphere((0, 0, -0.92), (0.28, 0.28, 0.1), brown, 0.03)


def m_pickaxe():
    steel, wood = STEEL(), material(rgb(170, 105, 50), 0.45)
    cyl((0, 0, -0.1), 0.13, 2.4, wood, outline=0.04)
    cube((0, 0, 1.0), (0.18, 0.2, 0.2), steel, 0.04)
    for sgn in (-1, 1):
        cyl((sgn * 0.62, 0, 1.0), 0.19, 1.15, steel, r2=0.04, rot=(0, math.radians(90 * sgn), 0), outline=0.04)


def m_stopwatch():
    face, rim, red = material(rgb(250, 252, 255), 0.25), material(rgb(150, 160, 180), 0.25, 0.7), material(rgb(235, 60, 60))
    cyl((0, 0, 0), 1.0, 0.45, rim, rot=(math.radians(90), 0, 0), bevel=0.06)
    cyl((0, -0.24, 0), 0.82, 0.1, face, rot=(math.radians(90), 0, 0), outline=0.02)
    cube((0, -0.3, 0.3), (0.05, 0.03, 0.45), red, 0.01, outline=0)
    cube((0.22, -0.3, 0.0), (0.2, 0.03, 0.05), material(rgb(40, 40, 60)), 0.01, outline=0)
    cyl((0, 0, 1.2), 0.16, 0.4, rim, outline=0.04)
    cyl((0.8, 0, 0.9), 0.1, 0.3, rim, rot=(0, math.radians(45), 0), outline=0.03)


def m_trade():
    orange, blue = material(rgb(255, 150, 40)), material(rgb(50, 170, 255))
    for sgn, mat in ((1, orange), (-1, blue)):
        cube((0, 0, sgn * 0.55), (0.9, 0.18, 0.22), mat, 0.05)
        cyl((sgn * 1.0, 0, sgn * 0.55), 0.55, 0.5, mat, r2=0.0, rot=(math.radians(90), 0, math.radians(-90 * sgn)), verts=3, outline=0.04)
        cube((-sgn * 0.9, 0, sgn * 0.55), (0.16, 0.16, 0.16), mat, 0.04, outline=0)

MODELS = {
    "icon_egg": (m_egg, 3.1), "icon_gift": (m_gift, 3.4), "icon_chest": (m_chest, 3.6), "icon_paw": (m_paw, 3.0),
    "icon_gear": (m_gear, 3.0), "icon_index": (m_book, 3.4), "icon_shop": (m_bag, 3.2), "icon_trophy": (m_trophy, 3.6),
    "icon_key": (m_key, 3.4), "icon_apple": (m_apple, 3.2), "icon_candy": (m_candy, 3.9), "icon_garlic": (m_garlic, 3.2), "icon_pickaxe": (m_pickaxe, 3.8), "icon_stopwatch": (m_stopwatch, 3.4), "icon_shard": (m_shard, 3.2), "icon_potion": (m_potion, 3.3), "icon_crystal": (m_crystal, 4.0),
}


def render(name, builder, scale):
    global OUTLINE_MAT, PARTS
    sc = new_scene()
    OUTLINE_MAT = outline_material()
    PARTS = []
    builder()
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = scale
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    az, el, dist = math.radians(-24), math.radians(24), 12
    cam.location = Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el))) * dist
    cam.rotation_euler = (-cam.location).to_track_quat("-Z", "Y").to_euler()
    for nm, kind, energy, rot, col in (
        ("key", "SUN", 4.2, (math.radians(50), math.radians(10), math.radians(-35)), (1.0, 0.96, 0.9)),
        ("fill", "SUN", 1.0, (math.radians(70), 0, math.radians(140)), (0.8, 0.88, 1.0)),
    ):
        ld = bpy.data.lights.new(nm, kind)
        ld.energy = energy
        ld.color = col
        lo = bpy.data.objects.new(nm, ld)
        lo.rotation_euler = rot
        sc.collection.objects.link(lo)
    sc.render.filepath = os.path.join(INBOX, name + ".png")
    bpy.ops.render.render(write_still=True)
    print("RENDERED", name)


if __name__ == "__main__":
    os.makedirs(INBOX, exist_ok=True)
    for name, (fn, scale) in MODELS.items():
        short = name.replace("icon_", "")
        if only and short not in only and name not in only:
            continue
        render(name, fn, scale)
