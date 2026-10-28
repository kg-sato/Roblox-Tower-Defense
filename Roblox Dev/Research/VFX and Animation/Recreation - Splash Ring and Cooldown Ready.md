---
date: 2026-10-28
tags: [vfx, 1to1, flipbook, aoe, ui-effect]
---
# Recreation - Splash Ring and Cooldown Ready

Two more ParticleFX 8x8 sheets recreated 1:1 with `tools/fx_craft.py` (credit for the references in `VFX/ASSETS.md`). Method: [[Effect Recreation 1to1 - Index]]. Chosen for the game. The splash suits area hits and boss kills, and Cooldown Ready suits "ULT charged".

## Splash Damage Ring (`fx_craft.py splash_ring` -> `VFX/flipbooks/splash_ring.png`)
Beats from the reference timeline:
- **f3:** a red double ground ring and a white lumpy fireball appear at once, with no wind-up because it is a hit.
- **f4–12:** the fireball swells and turns yellow.
- **f12–28:** its lobes are pushed out to the ring and cool to orange, then red. This uncovers a dark scorch with embers rising.
- **f28–50:** only the scorch and the ring remain.
- **f50–58:** they fade.

| Test | Coverage | Brightness | Colour | Size | Curve correlation |
|---|---|---|---|---|---|
| Sheet vs sheet | 0.87x | 1.16x | R 1.10x, G 1.06x, B 1.15x | w 0.97x, h 0.78x | coverage 0.97, brightness 0.97, colour 0.98 to 1.00 |
| In Studio, side by side (Measured) | 1.09x | 1.04x | saturation 0.89x (mean hue is not meaningful for reds, which wrap round 0/360) | w 1.10x, h 0.94x | |

How it got there:
1. **Pass 1:** the lobes were small, dull smoke puffs and the halo was huge.
2. **Pass 2:** the lobes glowed, but stayed yellow too long.
3. **Pass 3:** the lobes warmed faster and the glow was weaker.
4. **Pass 4:** some lobes fall and some float up, and the ring dims sooner.
5. **Pass 5 (after the first in-engine test):** the in-engine image was only 0.47x as bright, because the lobes were see-through smoke (`puff`). They became opaque fire lobes (new `fireball()` helper), and in-engine brightness went to 1.04x.

**Lesson:** an offline match in premultiplied alpha can still be too transparent in the engine. Always test in Studio.

Remaining gap (Seen): the reference throws more lobes above and below the ring (height 0.78x offline), and its lobes are more irregular than our rounder ones.

## Cooldown Ready (`fx_craft.py cooldown_ready` -> `VFX/flipbooks/cooldown_ready.png`)
Beats:
- **f0:** a faint dotted square.
- **f1–26:** a bright comet runs one lap clockwise from the top middle.
- **f27–33:** the slot flashes full, the dotted border lights up, sparks fly out and READY pops in with an overshoot.
- **f34–54:** the border and the label hold.
- **f55–56:** the label shrinks away, and the faint square stays.

| Test | Coverage | Brightness | Colour | Size | Curve correlation |
|---|---|---|---|---|---|
| Sheet vs sheet | 1.14x | 0.98x | 0.97x | w 0.95x, h 0.89x | coverage 0.96, brightness 0.75 |
| In Studio, side by side, size 10 (Measured) | 1.25x | 0.99x | hue 0.98x, saturation 1.03x | w 0.98x, h 0.90x | |

Remaining gap (Seen): our dotted border is denser (coverage 1.25x), and the reference's READY lettering is heavier and blurrier.

## Tower Upgrade update
The falling specks are now streaks, as in the reference. In Studio: coverage 0.98x, brightness 1.02x, width 1.02x, height 1.19x. See [[Recreation - Tower Upgrade]].

Evidence in `1to1/`: `splash_ring_sheet_compare.png`, `splash_ring_engine_sheet.jpg` + `_curves.csv`, `cooldown_ready_sheet_compare.png`, `cooldown_ready_engine_sheet.jpg` + `_curves.csv`, `tower_upgrade_*` (updated).

**Not wired into the game and not uploaded** (this run: no uploads). In Studio they load from this PC only, at `rbxasset://textures/vfx/<name>_v4/_v5.png`. Look and feel is **UNVERIFIED** until the user judges it.
