---
date: 2026-10-28
tags: [vfx, flipbook, technique, research]
---
# Crafted Sheet Techniques

Why: on 2026-10-28 the user said our sheets were not close to the references: "real ones have well-crafted shock and cracking animations, ours is a low-effort triangle". This note lists what hand-made sheets do, where it comes from, and where it lives in `tools/fx_craft.py`. Related: [[Effect Recreation 1to1 - Index]], [[Recreation - Egg Hatch and Coin Drop]], [[ParticleFX Studio and Flipbook VFX]].

## What the reference sheets do (Seen, zoomed frames of ParticleFX Pet Egg Hatch)
1. **Cracks are regions, not lines:** the shell breaks into irregular patches; light shines through each opening, and the edges show dark brown chips.
2. **Anticipation:** short radial speed lines flicker around the egg while it shakes; the egg warms to white before it pops.
3. **Burst:** an uneven starburst (spikes of different lengths) with an overexposed white core and a wide soft glow.
4. **Burst decay by erosion:** the starburst hollows from the inside into a hot amber ring, then breaks up; it does not just fade.
5. **Debris has volume:** crystal shards are two-tone prisms (light face and dark face, bright edge) that tumble and fall under gravity.
6. **Secondary detail:** twinkling dust specks, a diagonal lens streak, a lingering warm glow.

## Techniques (sources)
- **Erosion / dissolve:** noise compared with a rising threshold, pixels below it removed, so a shape breaks up instead of fading evenly ([sparks-and-sprites VFX cheatsheet](https://github.com/esorhizome/sparks-and-sprites/blob/main/cheatsheets/vfx.md); [VFX Apprentice: textures, meshes, shaders](https://www.vfxapprentice.com/blog/textures-meshes-shaders-vfx-basics)). In `fx_craft.py`: `fbm()` + `smooth()` in the starburst hollow and in `puff()`.
- **Distort before dissolve, two texture layers, hand-painted cracks with light through them:** [80.lv, stylized combat VFX in the Zelda style](https://80.lv/articles/creating-stylized-combat-vfx-in-the-zelda-style) (light beams through cracks painted over the sphere; flow-map distortion before the dissolve; timing "breathing room" with charge-up and aftermath). In ours: `voronoi()` cracks with light (`add`) in the holes and dark rims.
- **Shockwave:** a ring that scales up about 3x while it fades (cheatsheet above); a bright first flash catches the eye ([Real Time VFX, stylized UE4 explosion critique](https://realtimevfx.com/t/stylized-ue4-explosion/4557)).
- **Glow:** bloom = bright pixels blurred and added back (cheatsheet). In ours: `Frame.bloom()` on every frame (two blur radii, 2% and 6% of the frame).
- **Gradient maps and channel-packed masks** are how studio sheets get colour from one greyscale simulation (Real Time VFX thread above); our `tools/fx_ingest.py` already gradient-maps the Unity Labs sheets.
- **Heavier tools, not used yet:** Blender (installed, 5.3 beta) can render sheets with real 3D shards, Eevee bloom and geometry-node shockwaves ([shockwave in geometry nodes](https://3dart.it/shockwave-simulation-in-blender-tutorial), [Pierrick Picaut's Eevee 2D-plane explosion series](https://superhivemarket.com/products/explosion-generator-eevee-and-cycles) listing only). Effekseer (free) exports PNG frames from its editor, but no documented command line was found, so it would be a manual step.

## Our implementation (`tools/fx_craft.py`)
2x supersampling (256 px drawn, 128 px stored), antialiased polygons with `cv2.fillPoly`, premultiplied colour so light layers add correctly, overexposed values pushed toward white. Building blocks: `Frame.over/add/bloom`, `mask_poly`, `mask_line`, `gauss`, `fbm`, `voronoi`, `starburst`, `shard`, `puff`, `coin`. New effects are a function of the frame number that stacks these.

## Before and after (evidence)
- v1 flat shapes: `1to1/egg_hatch_ref_vs_ours.png`, `1to1/coin_drop_ref_vs_ours.png`.
- v2 crafted: `1to1/egg_hatch_v2_ref_vs_ours.png`, `1to1/coin_drop_v2_ref_vs_ours.png` (reference row on top).
Look and feel: **UNVERIFIED** until the user judges it.

## Next
Apply the same building blocks to the game's own weak effects (merge burst, hit spark, Starfall impact), each against a reference clip with `fx_compare.py`; try the Blender route for 3D debris if 2D shards still read flat.
