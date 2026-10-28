---
date: 2026-10-28
tags: [vfx, 1to1, flipbook, reveal, currency]
---
# Recreation - Egg Hatch and Coin Drop

References: ParticleFX Studio "Pet Egg Hatch" (8x8, 2.4 s) and "Enemy Defeat Coin Drop" (8x8, 1.3 s), already uploaded (`Overnight/asset_ids.json`). Ours: original art drawn by `tools/fx_craft.py` (v2) after `tools/fx_anim.py` (v1, flat shapes). Index: [[Effect Recreation 1to1 - Index]]; techniques: [[Crafted Sheet Techniques]].

## Egg hatch beats (Measured from the reference sheet, frame = 2.4/64 s = 37.5 ms)
| Frames | Time | What happens | Size (share of cell) |
|---|---|---|---|
| 0-12 | 0-0.45 s | cyan egg, thin gold rim, glint band sweeps across | 0.33 x 0.40 |
| 10-34 | 0.38-1.28 s | warm glow grows; gold fissures open with dark chipped edges; egg wobbles; speed lines flicker | width grows to 0.45 |
| 28-35 | 1.05-1.31 s | egg swells and turns white-gold | 0.5 to 0.6 |
| 36-44 | 1.35-1.65 s | gold starburst (about 20 uneven spikes) with overexposed core; crystal shards burst out | 0.75 |
| 40-50 | 1.5-1.9 s | starburst hollows from the centre into an amber ring; lens streak; gold dust | |
| 46-58 | 1.7-2.2 s | shards fall and fade, soft warm glow | |
| 59-63 | 2.2-2.4 s | empty | |
LightEmission 0, LightInfluence 0, Size 10, FacingCamera, one particle, `Emit(1)`.

## Coin drop beats (Measured)
| Frames | Time | What happens |
|---|---|---|
| 0-6 | 0-0.12 s | white spiky flash |
| 4-20 | 0.08-0.4 s | violet smoke puff grows, white-hot core, sparks shoot up, coins pop up out of it |
| 16-38 | 0.33-0.77 s | puff splits into two lobes, darkens, dissolves |
| 8-41 | | 5-6 coins arc up to about 0.15 of the cell height, spin, fall |
| 40-56 | 0.8-1.15 s | coins land at 0.75 of the cell height, small bounce, settle |
| 54-63 | 1.1-1.3 s | coins fade |

## Match (Measured, `tools/sheet_compare.py`, frame-by-frame correlation and mean ratio)
| Sheet | Version | Coverage corr / ratio | Brightness corr / ratio | Centre height corr | Box w / h ratio |
|---|---|---|---|---|---|
| Egg hatch | v1 flat (`fx_anim.py`) | 0.91 / 1.23 | 0.90 / 1.08 | 0.42 | 1.10 / 1.11 |
| Egg hatch | **v2 crafted** | 0.87 / 1.59 | 0.83 / 1.04 | | |
| Coin drop | v1 flat | 0.93 / 0.94 | 0.58 / 1.11 | 0.97 | 0.95 / 0.82 |
| Coin drop | **v2 crafted** | 0.93 / 0.98 | 0.52 / 1.34 | | |
The numbers barely move between v1 and v2 because they measure timing, size and position, which v1 already matched. What changed is the **craft** (the user's complaint): see `1to1/egg_hatch_v2_ref_vs_ours.png` and `1to1/coin_drop_v2_ref_vs_ours.png` (reference row above ours) against the v1 strips `1to1/egg_hatch_ref_vs_ours.png`, `1to1/coin_drop_ref_vs_ours.png`. In-engine (Play, both sheets on one particle each, `1to1/flipbooks_ingame_ref_vs_ours.jpg` for v1): v2 coverage 1.21x, brightness 1.09x, saturation 1.01x, box 1.07x.

## Still differs (Seen)
- Egg: our glow halo is larger (coverage 1.59x); our first cracks are whiter patches where the reference uses small gold flecks; the reference's star has a whiter, longer core flare.
- Coin: our puff sits about 0.05 lower and coins leave the puff in a tighter bunch; the reference's coins are drawn with a darker edge and more motion blur.
- Look and feel: **UNVERIFIED**.

## Recipe in code
`python -I tools/fx_craft.py egg_hatch VFX/flipbooks/egg_hatch_8x8.png` (and `coin_drop`). Uploaded v2 ids: egg 85571191205476, coin 113999797256109 (`VFX/textures/ids.json`). Not yet wired into the game (the game uses the ParticleFX originals today).
