# Familiar shape references (T089)

Twelve .glb files, one per familiar, made overnight 2026-10-28 from the design sheets in `Roblox Dev/Assets/Characters/Design Sheets/`. **Shape only, no textures, not cleaned up (T090 does that in Blender), not uploaded to Roblox.** Every file is 17,996 to 18,000 triangles, under the 20,000 limit (measured by `tools/glb_stats.py`, output in `Overnight/evidence/T089_glb_stats.txt`). The Tencent licence note in CLAUDE.md applies to the Hunyuan3D outputs (not to the EU, UK or South Korea).

| Model | Method | Triangles | Depth (z) vs height 1.97 | Quality note |
|---|---|---|---|---|
| Ember | Hunyuan3D from a shaded front image | 18000 | 0.62 | flame, lamp, sparks as one shape; usable massing |
| Brass Hound | Hunyuan3D | 18000 | 0.57 | usable massing |
| Sentinel | Hunyuan3D | 17999 | 0.37 | thin but volumetric; not watertight |
| Frostling | Hunyuan3D | 18000 | 0.89 | not watertight |
| Archivist | Hunyuan3D | 18000 | 0.77 | usable massing |
| Gargoyle | visual hull from the front and side silhouettes | 18000 | 1.59 | blocky; wings merged with the body |
| Ward | visual hull | 17998 | 1.11 | blocky; the lantern became a large box |
| Mourner | visual hull | 18000 | 0.81 | blocky column |
| Mirror Chorister | visual hull | 17996 | 0.91 | blocky; raised sleeves thickened |
| Moth-Lantern | visual hull | 18000 | 1.05 | blocky; wings thick |
| Star Drake | visual hull | 18000 | 1.30 | messy: the wings collapse into a bar |
| Grey Veil Wraith | visual hull | 18000 | 0.77 | blocky |

Why two methods: Hunyuan3D given the flat code-drawn front image first returned thin plates for all twelve (depth 0.01 to 0.15 against 1.97 tall; kept in `Familiars_flat_v0/`). Adding fake shading to the input (`tools/shade_inputs.py`) gave real depth for five (Ember, Brass Hound, Sentinel, Frostling, Archivist) and not for the other seven, even at stronger settings. For those seven I built volumes from the front and side silhouettes (`tools/visual_hull.py`), a different method that matches both drawings but gives crude, blocky forms.

These are reference massing only. Each needs a Blender pass (T090: scale, origin, smoothing, rebuild thin parts such as wings and the Star Drake from the sheets), not a direct use in the game.

## Cleaned versions (T090)
`clean/` holds the Blender-cleaned files for all twelve: `<Name>.glb`, `<Name>.fbx`, `<Name>_stats.json` and three preview renders. Produced by `Blender/cleanup_familiar.py` (Blender 5.3 beta, headless): joined and de-duplicated, normals fixed, silhouette-carved models smoothed (6 passes), decimated to 6,000 triangles, scaled to 4.0 units tall, origin at the feet centre, one armature (Root; plus Torso and Head with height-based weights for the nine humanoid-proportioned figures), flat grey material. The models are not yet posed or split into limbs; the rig-ready state means upright, centred, grounded, one clean mesh, and a starter skeleton. Verified by reopening the exported GLB files (`Overnight/evidence/T090_verify.txt`).

## Textured versions (T091)
`textured/` holds, for each familiar, `<Name>.glb` and `<Name>.fbx` with an embedded 1024 px base-colour map and a roughness map (also saved as `<Name>_BaseColor.png` and `<Name>_Roughness.png`) plus three preview renders. Made by `Blender/bake_familiar_textures.py` (Smart UV Project, then a Cycles bake of the design-sheet colours projected from the front, back and side views onto the cleaned 6,000-triangle models; roughness derived from the colour plus noise). The colours are projected from our code-drawn design sheets, not hand-painted in a paint program, so treat them as a first pass; 1024 px is more than a unit this small needs (the plan says 512 px, T123), so downsample before upload. Checked by `tools/verify_textured_models.py` (`Overnight/evidence/T091_verify.txt`).

## Idle animations (T092)
`idle/` holds `<Name>_idle.glb` and `<Name>_idle.fbx` (baked) for all twelve: a 121-frame (4.03 s) looping clip named Idle at 30 fps with two breaths and one signature motion that follows the card's gesture (Ember lifts its flame, the Gargoyle turns its head slowly, the Archivist turns its head almost all the way round, the Mourner bows, and so on). Made by `Blender/animate_idle.py` on the textured models with the starter armature (Root; plus Torso and Head for nine figures), so motions are limited to those bones: blocking-quality, not final animation. Checked by `tools/verify_idle_animations.py` (`Overnight/evidence/T092_verify.txt`); frame strip in `Overnight/captures/T092/idle_frames.png`.
