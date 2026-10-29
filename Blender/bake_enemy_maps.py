"""Unwrap an enemy/boss GLB and bake its palette colour + ambient occlusion into 512 px images (T124), Blender headless, CPU.
Run:  blender -b --factory-startup -P bake_enemy_maps.py -- <glb> <out_dir> <name>
Writes <out_dir>/<name>_bake_color.png, <name>_bake_ao.png (512 px, new smart-projected UV layer) and <out_dir>/<name>_uv.glb (the same mesh with ONE UV layer
and the baked colour as base colour). tools/texture_maps.py turns these into the per-stage-set Color/Roughness/Normal/Emissive sets.
Limit: smart UV project gives blocky islands and uniform texel density per island, not hand-laid UVs; alpha (FogWisp mist fade) is not baked."""
import os
import sys

import bpy

glb, out_dir, name = [os.path.abspath(a) if i < 2 else a for i, a in enumerate(sys.argv[sys.argv.index("--") + 1:][:3])]
os.makedirs(out_dir, exist_ok=True)
S = 512
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
scene = bpy.context.scene
meshes = [o for o in scene.objects if o.type == "MESH"]
for o in scene.objects:
    o.select_set(o.type == "MESH")
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active
ob.parent = None
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
me = ob.data
src_uv = me.uv_layers[0].name
new = me.uv_layers.new(name="BakeUV")
me.uv_layers.active = new
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.004)
bpy.ops.object.mode_set(mode="OBJECT")

mats = [sl.material for sl in ob.material_slots]
targets = []  # one bake-target node per material (models with several materials, e.g. the Fog Wisp eyes, bake into the same image)
for mat in mats:
    nt = mat.node_tree
    tex = next((n for n in nt.nodes if n.type == "TEX_IMAGE"), None)
    if tex is not None:
        uvn = nt.nodes.new("ShaderNodeUVMap")
        uvn.uv_map = src_uv
        nt.links.new(uvn.outputs["UV"], tex.inputs["Vector"])
    targets.append(nt.nodes.new("ShaderNodeTexImage"))

scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.render.bake.margin = 8
scene.render.bake.use_pass_direct = False
scene.render.bake.use_pass_indirect = False
scene.render.bake.use_pass_color = True


def bake(kind, samples, suffix):
    img = bpy.data.images.new(f"{name}_{suffix}", S, S)
    for mat, target in zip(mats, targets):
        target.image = img
        for n in mat.node_tree.nodes:
            n.select = n.name == target.name
        mat.node_tree.nodes.active = target
    scene.cycles.samples = samples
    bpy.ops.object.bake(type=kind)
    img.filepath_raw = os.path.join(out_dir, f"{name}_bake_{suffix}.png")
    img.file_format = "PNG"
    img.save()
    return img


color = bake("DIFFUSE", 4, "color")
bake("AO", 48, "ao")

# final material: baked colour only, one UV layer (the new one), then export
me.uv_layers.remove(me.uv_layers[src_uv])
for p in me.polygons:
    p.material_index = 0
while len(ob.material_slots) > 1:
    ob.active_material_index = len(ob.material_slots) - 1
    bpy.ops.object.material_slot_remove()
mat = ob.material_slots[0].material
nt = mat.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
out = nt.nodes.new("ShaderNodeOutputMaterial")
bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
t2 = nt.nodes.new("ShaderNodeTexImage")
t2.image = color
nt.links.new(t2.outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
bsdf.inputs["Roughness"].default_value = 0.55
color.pack()
bpy.ops.object.select_all(action="DESELECT")
ob.select_set(True)
bpy.context.view_layer.objects.active = ob
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, f"{name}_uv.glb"), use_selection=True, export_format="GLB")
print("BAKE_DONE", name, len(me.polygons))
