---
date: 2026-10-28
tags: [vfx, 1to1, buff]
---
# Recreation - Healing

Reference: Yuruzuu's Healing Effect (`VFX/third_party/yuruzuu_rbxl/Healing_Effect.rbxl`), rebuilt exactly. Index: [[Effect Recreation 1to1 - Index]].

## Layers (exact)
Emitter part 5 x 0.1 x 5 studs, Box shape, EmissionDirection Top, LightEmission 0, LightInfluence 0, colour 93,255,121, not LockedToPart.
| Layer | Rate | Lifetime | Size | Speed | Drag | Brightness | Other | Our texture |
|---|---|---|---|---|---|---|---|---|
| Shards | 8 | 0.55-0.80 | 0, 0.8 at 0.35, 0 | 10-18 | 2.5 | 5 | Squash 1.35 | `shard_v2` |
| Plus | 5 | 0.85-1.25 | 0, 0.4 at 0.25, 0 | 8-12.5 | 3 | 2 | | `plus_v2` |
| ShardsBigger | 5 | 0.50-0.75 | 0, 0.9 at 0.35, 0 | 12.5-20 | 5 | 5 | Squash 0.35 | `shard_v2` |
| Specs | 13.5 | 0.85-1.25 | 0, 0.5 at 0.25 (env 0.2), 0 | 8-12.5 | 3 | 5 | Rotation ±180, RotSpeed ±300, spread ±10, ZOffset -1 | `dot_corner` |
Transparency 0 throughout: particles fade by shrinking (size curve back to 0), not by alpha.

## Iterations (Measured)
| Version | Coverage | Brightness | Hue | Saturation | Width | Height |
|---|---|---|---|---|---|---|
| v1 (`shard`, `plus`) | 0.61x | 1.03x | 1.01x | 0.82x | 0.92x | 1.02x |
| v2 (shard width 0.07 to 0.12, plus arms 0.2 to 0.23) | **1.16x** | **1.00x** | **0.99x** | **1.01x** | 0.94x | 1.07x |
Frames: `1to1/healing_v1.jpg`, `1to1/healing_v2.jpg`; curves `1to1/healing_v2_curves.csv`.

## Still differs
Our shards are evenly lens-shaped; the reference's have a slightly brighter core line. Look: **UNVERIFIED**. `FXRecipes.healing` not yet switched to these textures.
