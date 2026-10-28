---
date: 2026-10-28
tags: [vfx, 1to1, flipbook, upgrade]
---
# Recreation - Tower Upgrade

Reference: ParticleFX "tower upgrade" 8x8 sheet (`VFX/third_party/particlefx/tower-upgrade-roblox-8x8.png`, credit in `VFX/ASSETS.md`). It fits our game's Upgrade event (a familiar levels up). Ours: `tools/fx_craft.py tower_upgrade` writes `VFX/flipbooks/tower_upgrade.png`. Index: [[Effect Recreation 1to1 - Index]].

## Beats (from `tools/sheet_compare.py analyze` on the reference)
| Frames | Reference | Ours |
|---|---|---|
| 0-1 | empty | empty |
| 2-9 | a flat ground ring opens wide over an amber pool; a thin light pillar; three arrowheads pop in one by one (f3, f5, f7) | same, wedge arrowheads with overshoot pop |
| 9-21 | the ring fades, the pool stays; the arrows turn from white to yellow | same |
| 16-24 | a four-point star caps the stack | same |
| 20-36 | the stack rises | same |
| 30-45 | it cools to orange and fades | same |
| 45-52 | last specks | same |

## Match
| Test | Coverage | Brightness | Colour | Size | Shape of the curves |
|---|---|---|---|---|---|
| Sheet vs sheet (offline, per frame) | 0.76x | 1.09x | R 0.94x, G 0.90x, B 0.96x | w 0.89x, h 1.03x | correlation: coverage 0.98, brightness 0.95, height 0.98 |
| In Studio, side by side, same emitter settings (Measured, 5 s at 30 fps) | 0.91x | 1.00x | hue 0.88x (a little more orange), saturation 1.06x | w 1.02x, h 1.13x | |

Evidence: `1to1/tower_upgrade_sheet_compare.png` (top = reference, bottom = ours), `1to1/tower_upgrade_engine_sheet.jpg` (left = reference, right = ours), `1to1/tower_upgrade_engine_curves.csv`.

**Verdict (Seen):** close in timing, size and brightness. Remaining gaps: the reference's sparks are falling streaks (ours are dots), its early ring is a whiter double ring, and its ground pool is larger and yellower. Look and feel: **UNVERIFIED** until the user judges it.

## How it was tuned (4 passes)
1. First pass: right beats, but too wide (1.34x) and too low; ring and pool too big.
2. Smaller ring and pool, but arrows outlined and merged into a blob; too bright and white (1.44x).
3. Solid wedge arrowheads (the reference fills them), warmer whites, less bloom: brightness 0.97x but arrows too small (coverage 0.66x).
4. Bigger arrows and wider glow: final numbers above.

## Effect craft rules used (research 2026-10-28)
From the League of Legends VFX style guide as summarised by [VFX Apprentice](https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips) (Riot's own PDF link now redirects, so not read first-hand): split primary shapes (the arrows: they carry the message "up") from secondary flavour (specks, pool); save the brightest value for the peak (the star); peak in the first quarter of the life, then a clean, short fade; hard shapes for the message, soft glow only around them; keep it short so it does not clutter the board.

## In the game
Not wired in yet. The sheet is not uploaded (this run's instruction was no uploads), so it only plays in this PC's Studio from `rbxasset://textures/vfx/tower_upgrade_v3.png`. To use it: upload `VFX/flipbooks/tower_upgrade.png` (owner's OK), then play it on the familiar in the `Upgrade` event in GameClient.
