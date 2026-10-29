"""Shared helpers for the procedural enemy and boss models (T118 onward), Blender headless.
Usage in a model script:
    import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from enemy_lib import Model
    m = Model("Name", out_dir, PAL)      # PAL: up to 16 (r, g, b) flat colours; every part's UVs sit in one cell of a 4 by 4 palette texture
    m.box(c, s, idx); m.blade(p0, p1, w0, w1, t, idx); m.cyl(c, r0, r1, h, idx, seg); m.finish()
finish() writes <Name>.glb and .fbx, <Name>_Palette.png, <Name>_stats.json and workbench stills (front, side, three_quarter) into out_dir."""
import json
import math
import os

import bmesh
import bpy
from mathutils import Vector

FACES = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]


class Model:
    def __init__(self, name, out_dir, pal, metallic=0.4, roughness=0.55):
        self.name, self.pal, self.metallic, self.roughness = name, pal, metallic, roughness
        self.out_dir = os.path.abspath(out_dir)
        os.makedirs(self.out_dir, exist_ok=True)
        bpy.ops.wm.read_factory_settings(use_empty=True)
        self.scene = bpy.context.scene
        self.bm = bmesh.new()
        self.uvl = self.bm.loops.layers.uv.new("UVMap")

    def _uv(self, idx):
        return ((idx % 4 + 0.5) / 4, 1 - ((idx // 4) + 0.5) / 4)

    def _face(self, verts, idx):
        f = self.bm.faces.new(verts)
        for loop in f.loops:
            loop[self.uvl].uv = self._uv(idx)

    def _prism(self, pts, idx):
        v = [self.bm.verts.new(p) for p in pts]
        for f in FACES:
            self._face([v[i] for i in f], idx)

    def box(self, c, s, idx):
        hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
        self._prism([(c[0] + sx * hx, c[1] + sy * hy, c[2] + z) for z in (-hz, hz) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))], idx)

    def blade(self, p0, p1, w0, w1, t, idx):
        """Flat prism from p0 to p1: horizontal width w0 at the base and w1 at the tip, vertical thickness t."""
        p0, p1 = Vector(p0), Vector(p1)
        d = Vector((p1.x - p0.x, p1.y - p0.y, 0))
        if d.length < 1e-6:
            d = Vector((1, 0, 0))
        d.normalize()
        side = Vector((-d.y, d.x, 0))
        pts = []
        for z in (-t / 2, t / 2):
            for p, w, sg in ((p0, w0, -1), (p0, w0, 1), (p1, w1, 1), (p1, w1, -1)):
                pts.append(p + side * (sg * w / 2) + Vector((0, 0, z)))
        self._prism(pts, idx)

    def cyl(self, c, r0, r1, h, idx, seg=8, ry=None):
        """Upright cylinder or cone from z = c[2] (radius r0) up by h (radius r1); ry scales the y radius."""
        ry = 1.0 if ry is None else ry
        ring = lambda r, z: [self.bm.verts.new((c[0] + r * math.cos(2 * math.pi * i / seg), c[1] + r * ry * math.sin(2 * math.pi * i / seg), z)) for i in range(seg)]
        bot, top = ring(r0, c[2]), ring(r1, c[2] + h)
        for i in range(seg):
            self._face((bot[i], bot[(i + 1) % seg], top[(i + 1) % seg], top[i]), idx)
        self._face(bot[::-1], idx)
        self._face(top, idx)

    def disc(self, c, r, thick, idx, seg=16, teeth=0.0):
        """Round plate facing -Y (axis along y) centred at c; teeth > 0 alternates the radius by r * teeth (a gear)."""
        def ring(y):
            return [self.bm.verts.new((c[0] + r * (1 + (teeth if i % 2 else 0)) * math.cos(2 * math.pi * i / seg), y, c[2] + r * (1 + (teeth if i % 2 else 0)) * math.sin(2 * math.pi * i / seg))) for i in range(seg)]
        fr, bk = ring(c[1] - thick / 2), ring(c[1] + thick / 2)
        for i in range(seg):
            self._face((fr[i], bk[i], bk[(i + 1) % seg], fr[(i + 1) % seg]), idx)
        self._face(fr[::-1], idx)
        self._face(bk, idx)

    def finish(self):
        name, scene, out_dir = self.name, self.scene, self.out_dir
        bmesh.ops.triangulate(self.bm, faces=self.bm.faces[:])
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
        mesh = bpy.data.meshes.new(name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        obj = bpy.data.objects.new(name, mesh)
        scene.collection.objects.link(obj)
        bpy.context.view_layer.objects.active = obj
        img = bpy.data.images.new(name + "_Palette", 64, 64, alpha=False)
        px = []
        for y in range(64):
            for x in range(64):
                i = (3 - y // 16) * 4 + x // 16
                c = self.pal[i] if i < len(self.pal) else (0, 0, 0)
                px += [c[0] / 255, c[1] / 255, c[2] / 255, 1.0]
        img.pixels = px
        img.filepath_raw = os.path.join(out_dir, name + "_Palette.png")
        img.file_format = "PNG"
        img.save()
        mat = bpy.data.materials.new(name)
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
        bsdf.inputs["Metallic"].default_value = self.metallic
        bsdf.inputs["Roughness"].default_value = self.roughness
        obj.data.materials.append(mat)
        mesh.calc_loop_triangles()
        co = [v.co.copy() for v in mesh.vertices]
        mn = Vector((min(c.x for c in co), min(c.y for c in co), min(c.z for c in co)))
        mx = Vector((max(c.x for c in co), max(c.y for c in co), max(c.z for c in co)))
        size = mx - mn
        stats = {"name": name, "triangles": len(mesh.loop_triangles), "vertices": len(co), "size": [round(size.x, 3), round(size.y, 3), round(size.z, 3)],
                 "min": [round(c, 3) for c in mn], "max": [round(c, 3) for c in mx], "width_over_height": round(size.x / size.z, 3), "materials": [m.name for m in mesh.materials]}
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.shading.light = "STUDIO"
        scene.display.shading.color_type = "TEXTURE"
        scene.render.resolution_x = scene.render.resolution_y = 384
        scene.world = bpy.data.worlds.new("W")
        scene.world.color = (0.2, 0.22, 0.3)
        cam_data = bpy.data.cameras.new("Cam")
        cam = bpy.data.objects.new("Cam", cam_data)
        scene.collection.objects.link(cam)
        scene.camera = cam
        cam_data.lens = 60
        centre = (mn + mx) / 2
        dist = max(size) * 2.4
        for view, ang in (("front", (0, -1, 0.15)), ("side", (1, 0, 0.1)), ("three_quarter", (0.7, -0.7, 0.2))):
            cam.location = centre + Vector(ang).normalized() * dist
            cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = os.path.join(out_dir, f"{name}_{view}.png")
            bpy.ops.render.render(write_still=True)
        bpy.data.objects.remove(cam, do_unlink=True)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + ".glb"), use_selection=True, export_format="GLB")
        bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, name + ".fbx"), use_selection=True, path_mode="COPY", embed_textures=True)
        with open(os.path.join(out_dir, name + "_stats.json"), "w") as f:
            json.dump(stats, f)
        print("MODEL_DONE", json.dumps(stats))
        return stats
