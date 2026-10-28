---
date: 2026-10-28
tags: [vfx, research, quality, flipbook, checklist, 1to1]
---
# Effect Quality: what makes the references look better, how to measure it, and per-effect checklists

**Trigger (user, 2026-10-28):** "Effects still aren't good enough. None of them have the same quality as the examples." Our 1:1 copies matched the references on coverage, brightness, colour and size ratios (all within about 10–25%), but they still looked worse. **Those ratios measure *how much* is on screen, not *how it is drawn*.**

Related: [[Effect Recreation 1to1 - Index]], [[Crafted Sheet Techniques]], [[Recreation - Splash Ring and Cooldown Ready]].

## 1. Research: how good flipbook effects are made
| Finding | Source | What we did wrong |
|---|---|---|
| Hand-made explosion flipbooks are painted as **greyscale** and coloured by a **gradient map** (temperature → colour). In Overwatch, a concept artist painted the flipbook in Photoshop, then it was converted to grey with a gradient map. Another artist lerps yellow to red by flipbook value in the material. | [Realtime VFX: Pharah rocket study](https://realtimevfx.com/t/overwatch-fx-pharah-rocket-study/758) | Each of our blobs had **one flat colour** plus a glow. The reference has a white heart, yellow body, orange then red edges *inside every mass*. |
| Simulated fire uses temperature for colour and density for alpha. If you key alpha from density, fire can look too transparent. The soft smoky low end of the ramp is trimmed. | [Realtime VFX: Bruno Afonseca sketch](https://realtimevfx.com/t/bruno-afonseca-sketch-48/19028/24), [SideFX forum](https://www.sidefx.com/forum/post/238220) | Our first splash lobes were see-through smoke puffs (0.47x brightness in the engine). |
| Dissipation is done by **alpha erosion**: a threshold on the shape's value rises over life. Thin and dim parts vanish first, so the shape breaks apart rather than fading. | [vfxdoc: alpha erosion](https://vfxdoc.readthedocs.io/en/latest/shaders/alpha-erosion/), [3dreference: erosion masks](https://3dreference.notion.site/Alpha-Erosion-Masks-9f2052268c4a4b24bbcd22430f0ca491), Realtime VFX Pharah thread (the ring is a static texture with alpha erosion) | Our lobes faded or turned red as whole balls. |
| Break up a round core with **spiky or curly secondary shapes** around it. Simplify shapes and reduce noise toward the end. Avoid symmetry. Snappy, non-linear timing. An initial bright flash. Use separate emitters for separate elements. | [Realtime VFX: Stylized UE4 explosion](https://realtimevfx.com/t/stylized-ue4-explosion/4557), [Realtime VFX: feedback on explosion](https://realtimevfx.com/t/looking-for-feedback-on-explosion-vfx/29528) | Our splash had nine equal balls placed evenly round the ring: symmetrical and readable as beads. |
| Anime-style effects hold frames (12–24 fps feel); the peak arrives a few frames after frame 1. | Realtime VFX Pharah thread; [Wikipedia: smear frame](https://en.wikipedia.org/wiki/Smear_frame) | Our noise re-randomised every 2–3 frames, so shapes "boiled" (motion 1.6x the reference). |
| League of Legends style guide (via VFX Apprentice): split primary shapes from secondary flavour, save the brightest value for the peak, put the impact in the first quarter, dissipate cleanly and keep effects short. | [VFX Apprentice: 10 League VFX tips](https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips) | (Applied already in [[Recreation - Tower Upgrade]].) |
| Gilland's *Elemental Magic* (former Disney effects animator) is the standard text for fire, smoke and explosions. Not read first-hand (paywalled), so it is listed as further reading only. | [O'Reilly: Elemental Magic Vol. II](https://oreilly.com/library/view/elemental-magic/9780240814797) | |

**Frame study (Seen, splash):** at every moment the reference is **one merged mass** whose hottest parts are where lobes overlap. Our v1 was a necklace of separate same-coloured balls. The reference's mass sits mainly on the **left and right ends of the ring** (perspective), with a cap on top that cools into dark smoke, and one lobe below. The middle clears to **dark textured smoke with ember streaks**. Late on, the masses **erode into fragments on the ring ends** and small bits drift up and down.

## 2. Metrics that would have caught the gap (`tools/fx_quality.py`)
`python -I tools/fx_quality.py <ref.png> <ours.png>` reports per-frame means, ratios and curve correlations:
- **ssim**: structural similarity of luminance, **only over the lit area** (the whole-frame version was inflated by empty background).
- **colhist**: overlap of the (hue, value) histogram, i.e. the colour ramp actually used.
- **core**: correlation of distance-from-edge with brightness. Hearts hotter than edges = the temperature look. **This is the metric that separates our flat balls from painted fire.**
- **heat**: correlation of brightness with warmth.
- **detail**: |Laplacian| inside the shapes.
- **blobs**: number of connected masses.
- **rough**: silhouette roughness (cauliflower edges vs discs).
- **soft**: share of feathered edge pixels.
- **lr**: composition (mass in the outer thirds).
- **motion**: frame-to-frame change and number of held frames (boil vs hold).

**Honest test of the metrics:** SSIM and colour overlap scored the old v1 *as well as* the rebuild (0.61 / 0.62 vs 0.61 / 0.57), even though v1 looks clearly worse. So they are not enough on their own. **core** and **heat** do separate them:

| Splash version | core (ref 0.19) | heat (ref −0.13) | rough (ref 3.04) | motion (ref 0.0068, 35 holds) |
|---|---|---|---|---|
| v1 (flat balls) | **−0.10** (edges as bright as hearts) | −0.41 (3.1x) | 2.36 | 0.0068, 31 holds |
| v2 (painted field) | **0.15** (0.79x) | −0.18 (1.35x) | 2.26 | 0.0085, 21 holds |

**Lesson:** always pair numbers with a **same-moment side-by-side at 2–3x zoom** (`1to1/*same_moments*.png`, `*_v1_v2_vs_ref.png`). No single number is "quality".

## 3. Quality checklist (use for every effect, before any metric)
1. **Layers named by role:** flash, primary shape (the message), secondary breakup, smoke, sparks, ground mark, glow. Each is drawn separately.
2. **Colour from a temperature/value ramp, per pixel:** a hot heart, a cooler edge, and the whole ramp sliding cooler over life. Never one flat colour per blob.
3. **One mass, not a necklace:** lobes merge (sum the fields), and overlaps are hottest. Composition is asymmetric, with the mass placed where perspective puts it.
4. **Silhouette:** cauliflower bumps (clusters of small puffs) on a few big shapes. Simplify toward the end.
5. **Dissipation by erosion:** thin parts break off first and cores go last. Fragments drift. Nothing fades as a whole.
6. **Timing:** flash, peak within the first quarter, hold, then a clean tail. Noise changes slowly (holds, not boil).
7. **Value control:** white only in the densest hearts. Keep bloom and glow light (heavy bloom turned our fire pastel). Smoke must be visible grey-brown with lit tops, not black.
8. **Engine check:** play side by side in Studio and compare the same moments. Sheet-only matches lied twice (splash transparency, frost needles).

## 4. Per-effect status against the checklist (2026-10-28)
| Effect | Lit SSIM | Colour overlap | core vs ref | Fails (most important first) |
|---|---|---|---|---|
| **Splash Damage Ring v3** | 0.63 | 0.54 | 0.20 vs 0.19 | top cap and smoke slightly redder than the reference's yellow hearts at f15; inside smoke a little bright in the engine (Seen) |
| **Tower Upgrade v2 (rebuilt)** | 0.31 (v1 0.39) | 0.48 | 0.15 vs 0.51 (v1 0.38) | *metrics got worse while the beats got closer* (see 6); arrows wider and flatter-lit than the reference's, the stack is three high too early, the star and its halo are weaker, fewer dripping sparks, the last arrow collapses messily |
| Cooldown Ready | 0.33 | 0.57 | 0.61 vs 0.65 | too many held frames (27 vs 4: the reference's border shimmers every frame); heat sign wrong (−0.25 vs −0.54: our label/border colours don't follow the reference's ramp) |
| **Frost Nova v2 (rebuilt)** | 0.43 (v1 0.32) | 0.69 (v1 0.65) | 0.36 vs 0.32 (v1 0.15) | crystals read as V-shaped twin claws, not the reference's single leaf-shaped blades; few separate pieces (rough 0.26x: the reference has many glints); the disc lacks the reference's swirl texture |
| Badge Pop | 0.44 | 0.64 | 0.80 vs 0.75 | fewer separate pieces (dust and sparkles, blobs 0.59x); motion 0.69x; red paler |

Next: Cooldown Ready and Badge Pop against the checklist; then fix the Tower Upgrade v2 gaps (section 6).

## 5. How the splash rebuild works (`tools/fx_craft.py splash_ring`; old version kept as `splash_ring_v1`)
- `fire_field()`: each lobe is a cluster of 8 small puffs (bumps), all summed into one density field with a slow domain warp. Heat is the density-weighted lobe heat and rises with density, so hearts are hottest. It also has painted noise.
- `paint_fire()`: colour = `ramp(T)` (dark red → red → orange → deep yellow → pale yellow → white; cold areas blend into grey-brown smoke). Alpha = erosion of density × noise against a rising threshold, then a light glow.
- Beats taken from a dense study of the reference (every frame f3–f38): dome and halo; split to the ring ends with inner bridges that burn away first; the top cap cools fast into smoke; one lobe below; embers in the cleared middle; torn-off bits; a smoke dome that holds.
- Evidence: `1to1/splash_ring_v1_v2_vs_ref.png` (reference / v1 / v2 at the same frames), `1to1/splash_ring_v2_engine_same_moments.png` (Studio, same moments: top = reference, bottom = ours), `1to1/splash_ring_v2_engine_curves.csv`. In Studio: brightness 1.11x, saturation 0.87x. Coverage is 1.36x and size 1.6x by 1.35x, because our early halo and the late smoke dome are larger.

Look and feel: **UNVERIFIED** until the user judges it. Not uploaded and not wired into the game.

## 6. Second round (2026-10-28): splash gaps closed, Frost Nova and Tower Upgrade rebuilt
Method each time: a dense frame study (every frame of the reference), a rebuild with value fields + ramps, `fx_quality.py`, sheet pairs at the same frames, then Studio at the same moments (`tools/fx_moments.py` finds the burst and cuts both halves at identical times).

| Effect | Studio (Measured): coverage / brightness / hue / saturation / size | Sheet metrics | Evidence in `1to1/` |
|---|---|---|---|
| Splash v3 (wider dome via shoulder lobes, split 2 frames later, darker painted patches, smoke fades out by f52) | 1.15x / 0.51x* / - / 0.75x / 1.08x by 1.00x | lit SSIM 0.63 (v2 0.61), core 0.20 vs ref 0.19 | `splash_ring_v3_sheet_pair.png`, `splash_ring_v3_engine_same_moments.png` |
| Frost Nova v2 (orb flattens into an ellipse; ripple rings; dark mist wider than the disc; crown of slender gradient-mapped blades (white spine -> cyan -> blue edge, ICE_RAMP); glints round the rim; crystals cool late and shatter one after another into tiny specks) | 1.05x / 1.04x / 1.00x / 1.02x / 1.03x by 0.95x | lit SSIM 0.43 (v1 0.32), colour 0.69, core 0.36 vs 0.32 (v1 0.15) | `frost_nova_v1_sheet_pair.png`, `frost_nova_v2_sheet_pair.png`, `frost_nova_v2_engine_same_moments.png` |
| Tower Upgrade v2 (arrows born at the bottom push the stack up; value-field arrows with UP_RAMP; cream double ring over an amber dish; soft flame pillar; star with a round halo; dripping streaks and glints; stack merges into one arrow, cools to orange) | 1.21x / 1.05x / 0.88x / 1.03x / 1.02x by 1.03x | lit SSIM 0.31 (v1 0.39), core 0.15 vs 0.51 (v1 0.38) | `tower_upgrade_v1_sheet_pair.png`, `tower_upgrade_v2_sheet_pair.png`, `tower_upgrade_v2_engine_same_moments.png` |

*Splash brightness in Studio varied between runs (1.11x, 0.51x) with the same settings: the reference's early white dome dominates the mean, and our burst's start can fall a frame earlier or later than the reference's within the 30 fps capture. Use the same-moment frames, not the mean, for this one.

**Lessons this round:**
1. **Tower Upgrade v2 scores worse than v1 on lit SSIM and core, but its beats now match** (bottom-up stacking, star with a halo, drips; v1 had none of those). The cause is that our arrows are lit almost evenly white-gold, while the reference's arrows are dimmer at the edges and have a bright core. So **a structural change can lower similarity until the shading is right.** Never accept or reject a version on one metric.
2. A recording crop that includes Roblox's top bar breaks burst detection ("no burst found"). Pass an explicit crop to `fx_compare.py record` (`x0,y0,x1,y1`).
3. Gradient-mapped value fields (fire: `FIRE_RAMP`, ice: `ICE_RAMP`, gold: `UP_RAMP`) are now the default way we colour every shape in `fx_craft.py`.

Look and feel of all three: **UNVERIFIED** until the user judges them. Not uploaded and not wired into the game. In this PC's Studio: `rbxasset://textures/vfx/splash_ring_v9.png`, `frost_nova_v4.png`, `tower_upgrade_v5.png`.

## 7. Third round (2026-10-28): Tower Upgrade metrics recovered, Cooldown Ready and Badge Pop rebuilt
| Effect | Lit SSIM (v1 -> now) | Colour overlap | core (ref) | Held frames (ref) | Studio, same moments (Measured): coverage / brightness / hue / saturation / size | Evidence in `1to1/` |
|---|---|---|---|---|---|---|
| Tower Upgrade v3 | 0.39 -> 0.33 (v2 was 0.30) | 0.48 | **0.43** (0.51; v1 0.38, v2 0.15) | 21 (20) | arrows and stacking now match; ring dimmer than the reference's | `tower_upgrade_v3_sheet_pair.png`, `tower_upgrade_v3_engine_same_moments.png` |
| Cooldown Ready v2 | 0.33 -> **0.38** | 0.52 | 0.59 (0.65) | **6** (4; v1 27) | 1.13x / 0.92x / 0.89x / 0.86x / 0.87x by 0.82x | `cooldown_ready_v1_sheet_pair.png`, `cooldown_ready_v2_sheet_pair.png`, `cooldown_ready_v2_engine_same_moments.png` |
| Badge Pop v2 | 0.44 -> **0.56** | 0.64 -> **0.76** | 0.79 (0.75) | 25 (10) | 1.06x / 1.03x / 0.97x / 0.88x / 1.06x by 1.07x | `badge_pop_v1_sheet_pair.png`, `badge_pop_v2_sheet_pair.png`, `badge_pop_v2_engine_same_moments.png` |

**What fixed Tower Upgrade's hot-middle score (0.15 -> 0.43):** a per-frame breakdown (`core` frame by frame) showed the drop was only in the ring phase, f2–20. Our bright ring *edge* was brighter than the dish's middle. The reference's amber dish is hottest in the middle. So the dish was made a hot spot (stronger, tighter falloff) and the ring dimmed. An arrow-position probe then showed our stack sat about 0.08 too high and 1.7x too wide early. The reference's arrows start small and grow as the stack builds, and its drips fall all the way to the ring. Structure recovered from 0.30 to 0.33 but is still under v1's 0.39. A brighter ring raised it again but dropped the hot-middle score, so the two pull against each other in the ring phase. Kept the hot-middle fix.

**Cooldown Ready v2 (dense study):**
- The comet is a sharp line segment, not a dot. It grows out of a point, turns corners as an L, and covers about 0.86 of a lap (it ends on the left edge).
- The tile is a light blue-grey, darkening over f27–33.
- The border is specks and short dashes that flicker every frame (the reference has only 4 held frames; v1 had 27). It is drawn over the tile.
- READY pops with a big overshoot and squashes into a line at the end.
- Bug found: the perimeter function didn't wrap, so points before the start were drawn as a long line from the corner.

**Badge Pop v2 (dense study):**
- f4 is a pure white disc. f5 overshoots to 1.2x, pale pink with a white ring inside the rim. f6 is red with the ring on the rim.
- f7–13: a thick dark halo with a pink glow opens and fades.
- Each later pop flashes pale while the old digit breaks up.
- The end shrinks the badge and bursts it into twinkling specks.
- **The single biggest gain was size:** a badge radius of 0.23 -> 0.26 (measured from the reference) took lit SSIM from 0.39 to 0.56. **Measure the reference's sizes before tuning anything else.**

**Remaining (Seen):**
- **Tower Upgrade:** the ring is dimmer, the star smaller, fewer drips.
- **Cooldown Ready:** the comet runs about a frame behind at 0.4 s, and the reference's lettering is blockier.
- **Badge Pop:** the reference's final burst still shows the "3" breaking apart; ours fades the badge.

All look and feel: **UNVERIFIED** until the user judges it. Not uploaded and not wired into the game.

## 8. The refined method (what changed from rounds 1 to 3)
1. **Measure the reference's geometry first** (sizes, positions, spacing per frame) before shading or timing. Badge Pop jumped from lit SSIM 0.39 to 0.56 on one size fix. Tower Upgrade's arrows were 0.08 too high and 1.7x too wide until a position probe showed it.
2. **Dense frame study** (every frame, zoomed) before writing a beat list. The sparse 8-frame strips hid key beats (Cooldown's L-shaped comet, Badge Pop's pale flash, Tower Upgrade's bottom-up stacking).
3. **Build shapes as value fields + a colour ramp**, never flat fills. Then check the `core` metric (hot middle, cooler edges).
4. **When a metric drops, break it down per frame** (`core` and SSIM per frame) to find the exact phase. Tower Upgrade's drop was only in the ring phase.
5. **Expect metrics to pull against each other** (ring brightness raises SSIM but lowers core). Decide with the same-moment frames and write down the trade-off.
6. **Always finish in Studio at the same moments** (`tools/fx_moments.py`, explicit crop, mouse moved out of the viewport, which once left a hand cursor in the reference half).
7. **Keep the old version as `<name>_v1`** in `fx_craft.py` so before/after can always be regenerated.

