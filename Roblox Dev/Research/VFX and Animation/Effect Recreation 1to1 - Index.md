---
date: 2026-10-28
tags: [research, vfx, ui, 1to1, method]
---
# Effect Recreation 1:1 - Index

How we recreate a reference effect or screen in Roblox and prove how close it is. Built and used 2026-10-28. Evidence images are in `1to1/` next to this note. Labels: **Measured** = numbers from our capture tools; **Seen** = judged from frames by Claude; **UNVERIFIED** = look and feel not yet judged by the user.

## Results
| Reference | Type | Our recipe | Match (measured) | Verdict | Note |
|---|---|---|---|---|---|
| Yuruzuu Hollow Purple (orb ultimate) | 10 emitters, world | same numbers + 9 of our textures | coverage 0.83x, brightness 1.07x, hue 1.01x, saturation 1.01x, size 0.82x | close; ring less jagged, faint planes missing | [[Recreation - Hollow Purple]] |
| Yuruzuu Healing (buff) | 4 emitters, world | same numbers + 3 of our textures | coverage 1.16x, brightness 1.00x, hue 0.99x, saturation 1.01x, size 0.94-1.07x | close | [[Recreation - Healing]] |
| ParticleFX Pet Egg Hatch (rarity reveal) | 8x8 flipbook, 2.4 s | `tools/fx_craft.py egg_hatch` | frame correlation: coverage 0.87, brightness 0.83; in-engine coverage 1.21x | same beats and craft class; ours brighter and slightly larger | [[Recreation - Egg Hatch and Coin Drop]] |
| ParticleFX Enemy Defeat Coin Drop (currency pop) | 8x8 flipbook, 1.3 s | `tools/fx_craft.py coin_drop` | frame correlation: coverage 0.93, centre height 0.96; coverage 0.98x | close; puff sits a little low, coins rise in a tighter cluster | [[Recreation - Egg Hatch and Coin Drop]] |
| ParticleFX Tower Upgrade (level-up on a tower) | 8x8 flipbook | `tools/fx_craft.py tower_upgrade` | sheet: coverage corr 0.98, brightness corr 0.95; in Studio: coverage 0.98x, brightness 1.02x, size 1.02x/1.19x | close; streak sparks added; ring less white | [[Recreation - Tower Upgrade]] |
| ParticleFX Splash Damage Ring (area hit) | 8x8 flipbook | `tools/fx_craft.py splash_ring` | sheet: curves corr 0.97+; in Studio: coverage 1.09x, brightness 1.04x, size 1.10x/0.94x | close; fewer lobes thrown up and down | [[Recreation - Splash Ring and Cooldown Ready]] |
| ParticleFX Cooldown Ready (ability charged) | 8x8 flipbook | `tools/fx_craft.py cooldown_ready` | sheet: coverage corr 0.96; in Studio: coverage 1.25x, brightness 0.99x, size 0.98x/0.90x | close; border denser, label thinner | [[Recreation - Splash Ring and Cooldown Ready]] |
| ParticleFX Frost Nova (ice burst) | 8x8 flipbook | `tools/fx_craft.py frost_nova` | in Studio: coverage 0.92x, brightness 1.04x, hue 1.03x, saturation 0.95x, size 0.99x/0.86x | close; needles slightly fewer, haze lower | [[Recreation - Frost Nova and Badge Pop]] |
| ParticleFX Notification Badge Pop (counter 1-2-3) | 8x8 flipbook | `tools/fx_craft.py badge_pop` | in Studio: coverage 0.87x, brightness 1.03x, hue 0.96x, saturation 0.86x, size 0.94x/0.95x | close; our red a little paler | [[Recreation - Frost Nova and Badge Pop]] |
| Sol's RNG roll result "1 in 20,000 Crowned" | UI screen | existing UIKit `AuraRoll` (not yet reworked) | edge F1 0.07, Delta E 29 | **not a match yet**: baseline for the UI rework | [[Recreation - UI Screens]] |

Look and feel of every row: **UNVERIFIED** until the user judges it.

**2026-10-28, user: "none of them have the same quality as the examples".** The ratio columns above measure *how much* is on screen, not *how it is drawn*. See [[Effect Quality]] for the research, the new quality metrics (`tools/fx_quality.py`: lit-area SSIM, colour-ramp overlap, core gradient, heat, roughness, holds) and a checklist per effect. Splash Damage Ring has been rebuilt as v2 (painted temperature field, erosion). The others are listed there with what they still fail.

## The pipeline (reusable)
1. **Get the reference in the same engine when you can.** A `.rbxl` effect: `tools/rbxl_tree.py <file> --spec <Name>` dumps the whole subtree (all classes, CFrames, Beam attachment links); `VFX/FXSpecBuild.luau` rebuilds it in Studio. A flipbook sheet: play it on one particle. A screen: the screenshot itself.
2. **Stage:** `workspace._FXCompare_TEMP` (temporary): black backdrop high above the map, reference on the left, ours on the right, fixed camera, HUD hidden. Record in **Play mode** (Edit mode only redraws while Studio is the active window; `record_window.py --front` exists for that case).
3. **Record and measure:** `tools/fx_compare.py record <dir> <s> [fps] [x0,y0,x1,y1]` then `measure <dir>`: per half (left = reference, right = ours) coverage, lit brightness, hue, saturation, box size, per-frame curves (`curves.csv`) and a contact sheet.
4. **Find the guilty layer:** show one emitter at a time on both sides on a shared wall-clock start (`DateTime.now()` in Luau, `time.time()` in Python), split the clip into 2 s windows, compare per layer. This is how Hollow Purple's gap was traced to 6 specific textures.
5. **Textures:** look at the reference textures on a SurfaceGui in the stage, paint ours with `tools/fx_tex.py` (16 shapes, `score` command), upload with Studio MCP `upload_image` from a local http server (owner approved uploads of our own textures on 2026-10-28). Ids: `VFX/textures/ids.json`.
6. **Flipbooks:** `tools/sheet_compare.py analyze|compare` gives the per-frame timeline (coverage, colour, centre, box) of any sheet; write the animation in `tools/fx_craft.py` beat by beat from that timeline; compare offline, then play both in Studio.
7. **UI:** build the screen inside a 16:9 `Stage` frame with four 6 px magenta corner markers; `tools/ui_compare.py capture` finds the markers and saves the stage at 1920x1080; `compare` prints edge F1 (outline alignment, 3 px tolerance) and colour Delta E, and writes side-by-side, blend and edge-overlay images.

## Facts found on the way
- Studio MCP `screen_capture` does not draw particles or BillboardGuis, so effect reviews must use window recording (`record_window.py`). This plus the Edit-mode redraw rule explains the identical frames of 2026-10-27.
- A 4x4 or 8x8 `FlipbookLayout` is ignored unless the texture is exactly 1024x1024; the reference Hollow Purple shows its full textures as squares because of this, and our copy reproduces it.
- Another creator's public image ids load in our place (Yuruzuu textures rendered fine), but we ship our own textures.
- The old `YuruzuuPorts` lost `Brightness` (4 to 5), the 4x4 flipbooks and `Orientation` VelocityPerpendicular; numbers alone are not enough, the texture and those flags carry most of the look.

## Techniques for crafted sheets
See [[Crafted Sheet Techniques]] (cracks, erosion, shaded shards, bloom), written after the user's feedback that our sheets looked like "a low-effort triangle".
