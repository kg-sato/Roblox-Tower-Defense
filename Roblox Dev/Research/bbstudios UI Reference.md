---
date: 2026-10-27
tags: [research, ui, reference]
---
# bbstudios UI Reference

Channel: [@bbstudios4](https://www.tiktok.com/@bbstudios4) (Roblox dev, 350 followers, 28.8K likes as of 2026-10-27). 9 own videos; the user pointed at [7700685121522912542](https://www.tiktok.com/@bbstudios4/video/7700685121522912542).

## Sources looked at (2026-10-27)
| Video | Views (profile grid) | Topic | How viewed |
|---|---|---|---|
| 7700685121522912542 | 94.9K | "U rid ur Claude of slop ui": dark Commands panel | about 35 s of 48 s at normal speed, muted |
| 7699684173606292766 | 84.2K | "Claude makes better ui than any designer": Christmas shop | about 45 s of 47.7 s, plus the open (6.3 to 9.4 s) at 0.1x speed |
| 7700060539724074254 | 48.9K | "Claude can build whole games": raft game | about 40 s of 39.4 s at normal speed |
| 7699264512590957837 | 66.7K | cutscene (speed lines) | one frame |
| 7698164685895470349 | 40.3K | dark editor-style UI with crimson panels | one frame |
| 7698097573940219166 | 51.9K | "Endless Pets" upcoming game | one frame |
| 7699636994086931726, 7698457991313362206, 7697861335148727582 | 3.5K, 4.1K, 3.7K | not opened | - |

Comments not read. Audio not heard (muted).

## What makes their UI read as "high quality" (seen, not creator claims)
- **The silhouette is not a box.** Props and emblems break out of the frame: candy canes, ornaments and a gift on the shop's corners; a large emblem overlapping the Commands panel's top-left corner.
- **Soft edges.** The Commands panel is dark and translucent with no hard border; the edges fade.
- **Type hierarchy.** A big serif title with a small spaced subtitle under it; thin caps tabs; list rows split by faint lines; one accent colour (crimson).
- **Illustrated content.** Shop cards and the banner are painted art, not flat colour (we have no art uploaded yet).
- **Layered opening, frame by frame (shop, 0.1x):** tap -> world dims to deep blue with a horizontal light streak, a big glowing icon pops in the centre (about 1 s) -> a warm glow ring flashes and the panel fades in see-through -> 0.1 s later solid, with a big scene banner -> 0.4 s the banner tucks away and the item row fills left to right -> 0.6 s buttons -> 0.9 s lower cards -> props pop in on the edges. About 1 s of staggered build.

## What we built (2026-10-27)
"Arcane scroll" frames in `GameClient` (`UI.scroll`, `UI.unroll`, `UI.notches`, `UI.fadeStroke`, `UI.diamond`):
- Panels (Pet, Roll Odds, Trainer Progression), the start card and the tutorial card (sideways scroll) have gold rods with gem knobs that overhang the sheet, an indigo-to-dark sheet with a faint accent glow, a thin inner margin, side vignette, and an outline that fades along the sides.
- Panel header: diamond sigil, accent-tinted title, divider fading at both ends with a centre diamond, round gem close button.
- Open: the sheet unrolls from the centre (measured 0 to 391 px in about 0.4 s, Quint out) with a glow ring flash; close rolls up (about 0.12 s).
- Buttons: soft top shine and diamond notches on the sides instead of corner brackets. HUD pills: fading outline and a hairline shine.

## Gaps
- Their best-looking parts are painted art (banners, card art, props). We have none uploaded; real art needs uploads (user's OK).
- Pass 2 (same day) added the staggered rows, the dim + sigil intro and fixed the tutorial overlap. The Skill Tree detail card is still the old flat style.
- Not seen on a phone; motion checked by measurement and stills, not by a person.
