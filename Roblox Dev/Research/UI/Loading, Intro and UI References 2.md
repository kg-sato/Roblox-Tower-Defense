---
date: 2026-10-28
tags: [ui, loading-screen, intro, tutorial, vfx, models, references]
---
# Loading, intro and UI references (set 2)

User (2026-10-28) sent 9 screen recordings (`C:\Users\kgsat\Videos\Screen Recordings\`), 7 TikToks and gfxcomet.com ("just look at designs ... take what they're doing and try to recreate it"). They also said: "The cutscenes also need some more as most of them aren't high quality in terms of how pristine they are. The bone / structure is good but the effects and models are lacking." Skill-tree reference photos are still coming.

Method: frame sheets (16 frames per clip, `tools/video_sheets.py`), TikToks fetched with `yt-dlp`, gfxcomet's 24 product preview images pulled into contact sheets. **Seen** = visible in frames; anything else is labelled.

## Loading screens and menus
| Reference | What it does (Seen) | Take for us |
|---|---|---|
| **Bit Tensei** ("Magical loading Screen") | a sacred-geometry seal: two squares rotating against each other inside rings, points on the ring, a glowing centre; warm diagonal light shafts across a dark amber field; a thin glowing progress bar that **turns into the START button**; then framed panels with corner ornaments | the seal and the light shafts (fits our abstract set); the bar becoming the next step |
| **Prehistoric Farm** | big title on a starfield, tiny "loading" text bottom-left, a rotating **Tip** line; then a dim camera shot of the world with a minimal text menu on the left (PLAY / SETTINGS / CODES / UPDATES, a small diamond marks hover), small windows pop over it; arrival in game with sparkles and an area banner | tips; minimal left menu (ours already is); arrival title |
| **Fishing Master** | key art behind, rotating tips, a themed progress bar whose head is a **fish icon**; then an NPC guide dialogue box | a themed bar head: our moth point flies along the line |
| **Upgrade X** ("Insanely cool") | the menu lives **in the 3D world**: the camera flies between spots; PLAY / CREDITS are tilted boards, JOIN / PRIVATE / PUBLIC are big round icons placed in the scene; day turns to night | later: menu pages as camera moves |
| **Twenty One** ("Eerie") | 60 s of near-black: centred disclaimer text, a photosensitivity line, red glitch images, glitched logo, a version-notes card | minimal centred text on black; a version card |
| **Loading Screen 2** | "Waiting for server" centred; a HEALTH AND SAFETY notice with "HOLD ANY BUTTON TO CONTINUE" | we show "Contains flashing lights" on the menu already |
| **Descend** ("Intro Video") | "click anywhere to play" over an aerial shot; then a **guided camera tour**: each beat is a slow shot of one place with a caption title and a smaller line under it (WELCOME TO DESCEND, THE SEA FLOOR IS FULL OF LOST RELICS, SELL THEM AT THE WELL FOR COINS, PUT YOUR COINS INTO BETTER GEAR), a SKIP button, ending on an NPC dialogue | **a first-time camera tour of our board with captions** |
| **Dao Cultivation** ("Good Intro or Tutorial") | ink-wash art loading screen with a bar and a tip; black; a soft-focus first-person walk through a forest; a centred **quest title card** ("The Elder Awaits", then "First Harvest"); an NPC with a "!" marker; fireflies | quest title cards; fireflies |
| **"Good UI"** (purple lobby game) | translucent panels in the same violet as the world; tab list on the left; item grids; achievement tiles | panels take the world's palette (ours: ink pools) |

## TikToks
| Video | Seen | Take |
|---|---|---|
| [fxroxx](https://www.tiktok.com/@fxroxx/video/7696579021093506337) (5,960 likes) | a crystal "core" object: blue sphere with crystal spikes, several tilted orbit rings, shards and confetti drifting | a hero object with layered tilted orbits |
| [bbstudios4](https://www.tiktok.com/@bbstudios4/video/7700060539724074254) | a boat racing game built with Claude: bright water, speed lines | - |
| [neildegracce](https://www.tiktok.com/@neildegracce/video/7696876445888466198) (19,300 likes) | motion design: squash and stretch, an easing curve, a morphing toggle, **kinetic type with motion blur**, **rolling digits blurred vertically** ("900 frames"), depth-of-field blur, a warm glow at the bottom | kinetic title letters with echoes; rolling counters with vertical smear |
| [deadj.rodev](https://www.tiktok.com/@deadj.rodev/video/7699200640383192342) (6,254 likes) | "quality models in 10 min": a concept image of the creature from several angles, then a part-built model with glowing cracks (lava crab) via a plugin called forgeGUI | concept sheet first, then build from parts with emissive cracks |
| [chunkydevpug](https://www.tiktok.com/@chunkydevpug/video/7700653137362750742) (3,767 likes) | dense voxel-built eggs / towers, each with neon trims, orbit rings and particles | denser part models with glowing trims |
| [corektvfx](https://www.tiktok.com/@corektvfx/video/7695085027662630166) | a star slams down as a **diagonal beam** of pink-white bands, a sparkle burst, a star trail streaking along the ground | a layered beam for STARFALL |
| [smudger13030](https://www.tiktok.com/@smudger13030/video/7699123611696860418) | Figma + BloxFig: a button made of a gradient, a texture overlay (stripes, dot gradient), a **light sweep** on hover, sparkles; exported to Studio | light sweep across key buttons |

## gfxcomet.com (designs only; nothing bought)
- **Icons:** chunky 3D-looking icons with a thick dark outline and a glossy highlight; every icon comes in **tier variants** (plain, gold, rainbow).
- **Radial weapon wheels:** a dark **ink-brush ring** split into segments; the chosen segment turns red; text in the middle.
- **Health UI:** a diamond with a brush-stroke bar; a portrait ringed by a red brush arc with the level beside it.
- **Popups / shops / settings:** clean dark or bright panels, big round key hints (E / R / T).
- Their code pitch: logic separate from the look, "tag and play", event-driven updates.

## Plan (built in this order)
1. **Loading screen v2:** the seal (rotating squares inside rings, with ghost copies for glare), warm light shafts, kinetic title letters with echoes, the moth point flying along the progress line, tips; when loading ends the seal ignites (rings fly outward) instead of a plain fade.
2. **First-time intro tour:** a captioned camera tour of the board with letterbox bars and SKIP (Descend), ending on the tutorial.
3. **Rolling counters:** coins and gems roll with a vertical smear (neildegracce).
4. **Cutscenes:** STARFALL's plain cylinder beams -> layered diagonal beams with ghosts, a sparkle burst and a ground streak (corektvfx); models built denser with glowing trims (chunkydevpug, deadj).

Results are logged in the "Built" section below.

## Built (2026-10-28, each checked in Play)
| Piece | What | Checked |
|---|---|---|
| Loading screen v2 (`Studio_Export/LoadingScreen.luau`) | the seal (two squares turning against each other in three rings, eight points, breathing core; every line has a ghost copy for glow); two warm light shafts; title letters drop in one by one with two echo copies; the moth flies along the progress line as its head; tips; at the end the seal ignites (rings fly outward) | recorded at Play start: seal, shafts, letter drop, moth head and ignite all seen. Then the letters were tightened and the seal enlarged (not re-recorded) |
| Intro tour (`Studio_Export/IntroTour.luau`, called from GameClient once when the tutorial is active, after the opening crane) | letterbox bars; four captioned shots with cuts through black: WELCOME TO LAMPWICK LANE, THE NIGHT COMES THROUGH THE GATE, SUMMON AND MERGE FAMILIARS, KEEP THE CRYSTAL LIT; SKIP; ends on the tutorial note | Play with a reset profile: all four beats, bars, captions, SKIP and the hand-off to the tutorial seen. The third shot was empty ground and was reframed to a low dolly over the grid (not re-recorded) |
| Rolling counters (`Motion.rollSmear`, used by AbstractHUD for coins and gems) | while a number counts, its two previous values trail above it and fade | test: ghosts visible during a count, hidden 0.12 s after; still capture mid-count reads as rolling |
| Cutscene effects (`CutsceneFX.luau` kit: `K.glint`, `K.slam`, `K.core`; `K.impact` updated; first-person ultimate uses them) | the ultimate's orb is now a crystal core (white centre, two glow shells, three tilted rings of points, six circling shards) that grows while charging and leaves echo copies on its ride; impacts get star glints, glowing shards (were grey slate cubes), motes (were a grey dust ball), a fainter glow; the first four targets get diagonal light slams with a ground streak | two Play runs of the real ULT (Frostling): core, glints, shards, slams and streaks seen |

Not done yet: the big flat shockwave disc on impact still reads flat; the menu-in-the-3D-world idea (Upgrade X); gfxcomet-style tiered icons; denser part-built models for enemies and bosses (chunkydevpug / deadj method); the other action cutscenes (merge, boss, level) did not get the new kit pieces yet. Skill tree waits for the user's references.

Images: `Research/UI/References 2/` (reference sheets `ref_*.jpg`, gfxcomet sheets, and ours: `ours_loading_v2_sheet.jpg`, `ours_intro_tour.jpg`, `ours_rolling_counter.png`, `ours_ult_core_slam.jpg`).
