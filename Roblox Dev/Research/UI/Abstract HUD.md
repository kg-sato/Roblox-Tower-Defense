---
date: 2026-10-28
tags: [ui, abstract, hud, checklist, metrics]
---
# Abstract HUD (every control its own form)

User (2026-10-28): "compared to the beginning it's better but the UI still isn't up to par. Try to make everything abstract, without UI that looks similar." Asked and answered: **replace the brass/tarot objects too**, and start with **the main HUD**. Earlier research: [[Research/UI/Abstract UI]]. Code: `Studio_Export/AbstractHUD.luau` (StarterPlayerScripts), called from GameClient right after `AbstractLayer`. Old art is hidden, not deleted.

## Research added this round
- **Mizuguchi on Rez:** it looks simple and abstract, but it isn't really simple ([Game Developer interview](https://www.gamedeveloper.com/design/expressing-the-future-tetsuya-mizuguchi)). Its less-is-more look shaped later games like Tetris Effect ([feedme.design](https://feedme.design/rez-a-cultural-and-design-revolution-in-gaming)).
- **Minimalist games** have small rule sets and abstract audio-visual forms, with depth still allowed ([Nealen et al. 2011 via unpaywall](https://unpaywall.org/10.1145%2F2159365.2159371)). A 2024 study says the claim that HUDs are getting more minimal was mostly anecdotal ([Uni Bonn](https://bonndoc.ulb.uni-bonn.de/xmlui/handle/20.500.11811/14207?show=full)).
- **Saul Bass:** simple geometric shapes carrying a symbol, drawn by hand so they feel casual; colour shifts with mood (West Side Story's bars) ([BFI](https://www.bfi.org.uk/news-opinion/news-bfi/lists/saul-bass-10-essential-title-sequences), [Atomic Ranch](https://www.atomic-ranch.com/modernist-index/saul-bass-mid-century-in-motion/)).
- **Diegetic vs non-diegetic:** most games mix both, and too many in-world elements make information harder to read ([Stony Brook lecture](https://www3.cs.stonybrook.edu/~tony/ui/lectures/game_design/gameUI.pdf), [Wayline](https://www.wayline.io/blog/diegetic-interfaces-game-design)). Hence: abstract forms, but every number stays plain text.
- No source found on circle vs triangle meaning in game HUDs. We use Kandinsky's (circle calm, triangle hot/active), already cited in [[Research/UI/Abstract UI]].

## UI quality checklist (use for every screen)
1. **No stock shapes:** no rectangle or pill buttons, no plain bars, no framed boxes. Every control is a point, line, circle, triangle, spiral, arc or a figure built from them.
2. **No two controls alike:** each has its own form *and* colour role. Same-kind pairs (coins/gems) differ in shape.
3. **The form shows the state:** AUTO's point orbits when on; START WAVE's triangle goes hollow while a wave runs; ULT's ring of points fills; HP is a moon that wanes. No text-only state.
4. **Numbers stay plain text** (Merriweather bold, ink outline), next to the form, never inside decoration.
5. **Hierarchy by size:** ROLL is the one big form, START WAVE second; everything else is small.
6. **Motion budget:** only ROLL's spiral turns slowly and AUTO's point orbits when on; ULT breathes only when full. Nothing moves with Reduced Motion.
7. **Palette roles:** violet = summon/skills, amber/gold = action/progress/coins, cyan = power/gems/settings, pale = crystal, red = boss/low HP, grey = off.
8. **Check in Play** with captures in each state (idle; AUTO and QUICK on; wave running; ULT charging; HP low).

## Metrics (`tools/ui_quality.py`)
`python -I tools/ui_quality.py <hud_on.png> <hud_off.png> <controls.json> [out]`: diff of HUD-on vs HUD-off captures, cut per control rect.
- **boxy**: the silhouette is an axis-aligned rectangle or pill.
- **lookalike pairs**: same outline (Hu moments, or outline IoU > 0.85, or appearance correlation > 0.7) *and* the same dominant colour *and* a similar size.

Known limits: a badge drawn over a control hides it from the outline match (the old Skill Tree seal was missed), and a decor shape that fills a control's rect counts as boxy.

| | Boxy controls | Lookalike pairs | Notes |
|---|---|---|---|
| Before (brass objects + abstract layer) | **7 of 14** | 2 found (Progression~Settings seals; Level~Stage plates), +1 missed (Skill Tree seal under its badge) | `Creative Fixes/hud_abstract2_before.png` |
| After | **1 of 14** (Level: before the corner field was removed) -> **1** (the Level rect still holds the old fade field behind the vesica) | **0** | `hud_abstract2_after.png`, `hud_abstract2_states.png`, `hud_abstract2_pair.jpg` |

## The forms (all built from Frames, UICorner, UIStroke, rotation and the already-uploaded spiral/vesica/eye art; nothing new uploaded)
| Control | Form | State shown by |
|---|---|---|
| ROLL | af Klint spiral turning in a violet disc | the spiral spins up when pressed |
| AUTO | thin ring with one point | the point orbits and turns amber when on |
| QUICK | three slanted speed lines | longer and amber when on |
| ODDS | the eye | - |
| START WAVE | solid amber triangle, "BEGIN / THE WAVE" | hollow outline + "RUNNING" during a wave |
| ULT | ring of 24 points around a core | points light with charge (Measured: 40% -> 9 of 24); core fills and breathes when full |
| Coins / Gems | amber point / cyan diamond | - |
| Level | vesica with the number; XP = ten points | points fill with XP |
| Stage | big numeral in a thin circle | ring and a point turn red on boss stages |
| Crystal HP | a pale moon | it wanes into a crescent as HP falls, red under 30% |
| Skill Tree / Progression / Settings | a branch of points / three points climbing / two rings and a point | the skill-point badge stays |

**Bug found and fixed:** the state hooks first read the button's `Txt` copy. Another handler updates that copy after ours, so the forms showed the *previous* state. They now read `Text`. Note: Studio's signals are deferred, so a test that sets a value must `task.wait()` before checking.

## Round 2: start menu, streak, boss plate, panels (`Studio_Export/AbstractScreens.luau`)
| Screen | Forms | Checked |
|---|---|---|
| Start menu | crown -> a sun point on a line; LIGHT THE LAMP -> a half sun rising over a horizon line (rises on hover); gazette -> no parchment, a violet line beside the text; flashes -> a line with a sliding point | Play; flash switch toggled by a real click (Flashes on -> off). Metric: boxy 4 of 4 -> 1 of 4 (the remaining one is the crown's rect, filled by the faint vesica decor) |
| Streak | a column of embers, one per perfect stage, swaying like a flame, with the multiplier | Play at x4 |
| Boss plate | no plate or chains; a red point before the boss's name; life = a red comet (a tapered line with a diamond head that slides back as the boss is hit); the wick timer kept | Play on stage 5: 319 / 1,452 shown, escape timer counting |
| All panels | no glass frame: a soft round ink pool keeps text readable; dividers -> thin gold lines; close -> two crossing lines | Play, all four open |
| Odds | each rarity a circle whose **area is its chance** (51 / 32 / 14 / 3.4%) inside a thin ring | Play |
| Familiar | buy -> a plus of two lines + price; Delete -> RELEASE: a red point struck through by a line; level pips stay (they are already points) | Play (no familiar selected, so prices were empty) |
| Settings | volume rails -> thin lines with the point knob; candles -> a point (amber on) / hollow ring (grey off), ON/OFF; choice capsule removed, the diamond pointer stays; reset seal -> a red triangle | Play |
| Progression | XP bar -> a gold line with a point at its end (plus the constellation road from before) | Play |

Images: `Creative Fixes/start_abstract2_before.png` / `_after.png`, `boss_streak_abstract2.png`, `panels_abstract2_before.jpg` / `panels_abstract2_after.jpg`.

## Round 3: tutorial, banners, skill tree, loading, Now Playing, reveal
| Screen | Forms | Checked |
|---|---|---|
| Tutorial note | no parchment, seal or plaque: a breathing violet guide point with a line down from it, pale text, gold signature, Skip as underlined text | Play |
| Banners | the words plus a line drawn out from the middle with a point at each end, in the banner's colour (Saul Bass bars); fades with the text | Play (shared-summon banner) |
| Toasts | a small red point before the text | code only (the toast faded before capture) |
| Skill tree | hex tokens -> concentric circles (outer one a ring) that copy each hex's live colour, so locked / buyable / owned still read; object icons replaced by the node's short word; info box -> violet line at its left; BUY -> an upward chevron of two lines; Close -> crossing lines | Play |
| Loading screen | the crown art -> a breathing amber point in the orbits; SKIP -> underlined text (the rest was already rings, points and a line) | recorded at start of Play |
| Now Playing | no card box; the note in a thin violet ring; progress = a thin line | Play. **Bug found and fixed:** its stroke uses ScaledSize, so Thickness 2 meant twice the bubble's size (a huge violet disc over the HUD) |
| Reveal ("The Reading") | no tablecloth, no candles (two small points of light instead); the card's back is the af Klint spiral in gold, its face the vesica tinted by rarity; rim colours, flip and shatter unchanged | Play (Epic). **Bug found and fixed:** the new decals showed blank until preloaded like the old tarot art |

Images: `Creative Fixes/tutorial_banner_abstract.png`, `skilltree_abstract_pair.jpg`, `loading_abstract.png`, `nowplaying_abstract.png`, `reveal_before_sheet.jpg` / `reveal_abstract_sheet.jpg`.

## Round 4: the 3D walk-up scenes and the Legendary moth
User: make the 3D scenes and the cinematic art abstract too; then, mid-round: "try duplicating objects and slightly moving them so the animations have more glare / blur" and "the skill tree does not have any good backdrop / main focal point. I want a really majestic main tree."

| Scene | Forms | Checked |
|---|---|---|
| Skill grove (`SkillGrove.luau`) | **Main tree:** a trunk of seven strands of light that rise from spread gold roots and braid into one at the crown; a fractal canopy of five limbs, each splitting four times, with gold points at the tips. **Backdrop:** a stepped halo sun (four stacked faint circles), the three af Klint rings, a gold horizon line, four smaller violet line-trees on either side. Path = one gold line with points; lamps = amber points on faint lines; courtyard wall = a ring of violet points. Skill lanterns = a point in a faint circle; skill branches turn the skill's colour when owned. | Play, same arrival frame before / after; grow recorded at 15 fps (roots, trunk braids up, canopy spreads); buy flare called without errors. 1,159 parts, opens in the same 3.3 s |
| Trainer road (`TrainerRoad.luau`) | road = one gold line over dark ground; each milestone = its numeral in a thin ring that takes the state colour (violet passed, gold next, grey later), reward text below, a point of light on a faint line beside it | Play, same arrival frame |
| Legendary cinematic (`RevealSection.luau`) | the moth art -> an ink point with two line wings that beat (flat -> V); three fading echo copies trail it | Play (Legendary via `DebugReveal`), recorded at 15 fps |

**Glare by duplication (the user's idea):** every decor line in the grove has two ghost copies, 2.6x and 5x thicker, much fainter, nudged a few centimetres off. Together they bloom like a long exposure. The moth's echoes replay where it was 2, 4 and 6 frames ago (a chronophotograph-style smear).

**Bugs found and fixed:**
- Big canopy circles made from Cylinder parts showed facets at 24 studs; they are now SurfaceGui circles on clear parts.
- The new ground z-fought with the Baseplate (slate tiles showed through); the ground now sits 3 cm higher.
- The moth's heading tilt made the line-wing V look lopsided; removed.
- First majestic pass: the white trunk and canopy drowned the coloured skill lanterns; the canopy is now violet-to-gold and fainter, and the ghosts are fainter.

Images: `Creative Fixes/grove_abstract_pair.jpg`, `grove_grow_sheet.jpg`, `road_abstract_pair.jpg`, `moth_echo_after.jpg` (before of the moth: `Research/VFX and Animation/Summon References/ours_legendary_manga_v1.jpg`).

## Still to do
- **Not converted yet:** cutscene captions.
- **Look and feel:** **UNVERIFIED** until the user judges it.
- **Phone layout:** not checked with the new forms.
