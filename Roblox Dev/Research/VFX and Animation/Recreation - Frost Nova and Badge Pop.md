---
date: 2026-10-28
tags: [vfx, 1to1, flipbook, ice, ui-effect]
---
# Recreation - Frost Nova and Badge Pop

Two more ParticleFX 8x8 sheets recreated 1:1 with `tools/fx_craft.py` (reference credit in `VFX/ASSETS.md`). Method: [[Effect Recreation 1to1 - Index]]. Why these two: Frost Nova suits an ice familiar's area attack. Badge Pop is the animated twin of our skill-point badge on the Skill Tree seal.

## Frost Nova (`fx_craft.py frost_nova` -> `VFX/flipbooks/frost_nova.png`)
Beats:
- **f0:** a white spark.
- **f2–8:** a flat frost disc opens, with two white rings racing out.
- **f4–9:** a crown of ice needles shoots up round the rim. Front needles are taller (perspective), each has a smaller leaning shard beside it, and the spines are white-hot.
- **f9–36:** everything holds while the frost swirls under a tall dark-blue haze.
- **f37–52:** the needles shatter into small shards that scatter and fall.
- **f38–52:** the frost erodes away with noise, and specks drift up.

| Test | Coverage | Brightness | Colour | Size |
|---|---|---|---|---|
| In Studio, side by side (Measured) | 0.92x | 1.04x | hue 1.03x, saturation 0.95x | w 0.99x, h 0.86x |

How it got there:
1. **Passes 1–3 (offline):** too dark, then too bright and flat, with a comb of short spikes and a smoke blob under the disc.
2. **First in-engine test:** brightness 0.78x, saturation 0.71x, height 0.63x. Our spikes were fat "petals" against the reference's thin white-tipped needles, and the reference has a tall blue haze.
3. **Fix:** thin needles with a white spine, a tall dark-blue haze, smaller shatter pieces, and a faster erode with no leftover chunk. The engine numbers above are after this fix.

**Lesson (again):** the per-pixel brightness of a sheet says little until it is shown in the engine. Thin bright shapes and a soft dark haze read very differently there.

## Notification Badge Pop (`fx_craft.py badge_pop` -> `VFX/flipbooks/badge_pop.png`)
Beats:
- **f0–3:** dust gathers.
- **f4–5:** a full-size white disc flashes.
- **f6:** the red badge with "1" overshoots in, with a thick dark halo, a soft pink glow and a white rim.
- **f17 and f30:** it pops again (flash, overshoot, halo) to "2" and "3".
- **Hold**, then **f54–57:** it shrinks and bursts back into dust.

| Test | Coverage | Brightness | Colour | Size |
|---|---|---|---|---|
| In Studio, side by side, size 10 (Measured) | 0.87x | 1.03x | hue 0.96x, saturation 0.86x | w 0.94x, h 0.95x |

First pass: the opening white flash was missing, because it was drawn at the badge's size while the badge was still at zero. The reference also uses a thick dark halo with a soft glow, not a thin expanding ring. Remaining gap (Seen): our red is a little paler and pinker.

Evidence in `1to1/`: `frost_nova_sheet_compare.png`, `frost_nova_engine_sheet.jpg` + `_curves.csv`, `badge_pop_sheet_compare.png`, `badge_pop_engine_sheet.jpg` + `_curves.csv`.

**Not wired into the game and not uploaded.** In Studio they load from this PC only (`rbxasset://textures/vfx/frost_nova_v2.png`, `badge_pop_v1.png`). Look and feel is **UNVERIFIED** until the user judges it.
