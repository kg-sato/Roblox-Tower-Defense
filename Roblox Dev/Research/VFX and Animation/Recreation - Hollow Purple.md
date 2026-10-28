---
date: 2026-10-28
tags: [vfx, 1to1, ultimate]
---
# Recreation - Hollow Purple

Reference: Yuruzuu's open-source Hollow Purple (`VFX/third_party/yuruzuu_rbxl/Hollow_Purple.rbxl`, credit in `VFX/ASSETS.md`), rebuilt exactly in Studio from the file. Ours: the same instance tree with our textures. Index: [[Effect Recreation 1to1 - Index]].

## Layers (exact, from the file)
One 1-stud part, one Attachment, 10 ParticleEmitters (all LockedToPart, LightInfluence 0) and a PointLight (Brightness 2, Range 15, colour 231,142,255).
| Layer | Rate | Lifetime | Size curve | Transp. curve | Brightness | LightEm. | Flipbook | Orientation | Other | Our texture |
|---|---|---|---|---|---|---|---|---|---|---|
| Lightning (ring) | 25 | 0.10-0.15 | 5.8 to 6.0 | 0 to 0 at 0.49, 1 at end | 4 | 0 | none | camera | Rotation -360..3603 | `lightning_ring_v3` |
| Lightning1 (bolts) | 7.5 | 0.45-0.60 | 6 to 7 (env 1) | 0 to 0.86, then 1 | 4 | 1 | 4x4 loop | camera | | `bolts_4x4_v3` |
| Middle (dot) | 50 | 0.35-0.45 | 0, 5.5 at 0.1 (env 1), 0 | as above | 4 | 0.85 | 4x4 loop | camera | Speed 11, Drag 4, spread 360 | `dot_v3` |
| Specs | 27.5 | 0.75-0.90 | 0, 1.5 at 0.2, 0 | as above | 4 | 1 | 4x4 loop | camera | Speed 30-40, Drag 7, RotSpeed ±360 | `dot_4x4_v3` |
| Smoke | 25 | 0.5 | 0 to 13 ease-out | 1, 0.93 at 0.2, 1 | 4 | 1 | none (loop) | camera | colour 232,196,255 | `wisps_v3` |
| Main (dark core) | 15 | 0.15 | 5 | 0 | 1 | 0 | none | camera | colour 32,19,38, ZOffset -1 | `disc` |
| Shockwave | 25 | 0.25-0.35 | 0 to 12 ease-out (env 2) | 1, 0.88 at 0.2, 1 | 4.5 | 1 | 4x4 loop | **VelocityPerpendicular** | ZOffset 4 | `ray_burst_v3` |
| Lightning1 (big) | 0.75 | 0.5 | 11 | 0 to 0.86, 1 | 4 | 1 | 4x4 loop | camera | | `bolts_4x4_v3` |
| Crescents (black) | 25 | 0.25-0.35 | 0 to 12 ease-out (env 2) | 1, 0.75 at 0.2, 1 | 1 | 0 | 4x4 loop | VelocityPerpendicular | RotSpeed ±360 | `swirl` |
| Crescents1 | 55 | 0.25-0.35 | 2.4 to 0 | 0 to 0.86, 1 | 5 | 1 | 4x4 loop | VelocityPerpendicular | Drag 7 | `crescent` |
Colour for the violet layers: 187,92,255. Timing: a steady loop (no beats); Rate drives everything.

## Iterations (Measured, `fx_compare.py`, left reference / right ours, Play mode, 20 fps)
| Version | Coverage | Brightness | Hue | Saturation | Size | What changed |
|---|---|---|---|---|---|---|
| v0 old port (built-in textures, no Brightness/flipbook/orientation) | 0.78x | 1.01x | 0.95x | 0.89x | 0.8x | see `1to1/hollow_purple_v0_port.jpg`: a plain bloom, no ring, no dark core |
| v1 our textures + all flags | 1.60x | 1.03x | 0.98x | 0.85x | 1.18x | structure right; ring halo too wide |
| v3 six textures fixed after the per-layer test | **0.83x** | **1.07x** | **1.01x** | **1.01x** | 0.82x | `1to1/hollow_purple_v3.jpg` |
Per-layer test (v2): reference Smoke, Shockwave and Specs barely show (Specs only on flipbook frame 1), ours were 13x to 150x too dense; our bolts were 0.3x, ring 0.6x. Fixed in v3.

## What still differs
- Ring: ours is a smoother wavy line; the reference ring is spikier with uneven thickness.
- The reference's faint sheared planes (Shockwave and Crescents drawn as full squares because their textures are not 1024 px) are fainter in ours.
- Look and feel: **UNVERIFIED**.

## Recipe in code
- Reference rebuild: `tools/rbxl_tree.py VFX/third_party/yuruzuu_rbxl/Hollow_Purple.rbxl --spec "Hollow Purple"` then `VFX/FXSpecBuild.luau`.
- Ours = that tree with textures swapped by `VFX/textures/ids.json` (map above). Not yet wired into `FXRecipes.hollowPurple` (it still uses the old port data).
