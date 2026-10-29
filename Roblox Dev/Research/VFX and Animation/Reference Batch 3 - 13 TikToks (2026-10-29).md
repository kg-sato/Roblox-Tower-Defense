# Reference Batch 3: 13 TikToks (2026-10-29)

Intake note. The user sent 13 links and flagged the aotishe one as having "a lot of the motion design ideas I want to implement". Earlier batches: [[Research/VFX and Animation/Reference Video Study 2 - Priority Links]], [[Research/VFX and Animation/Beam and Impact VFX Recipes]]. Applies to: [[Research/UI/Loading, Intro and UI References 2]], [[Planning/Immersion - Every Action a Cutscene]], [[Design/Cutscenes and Transitions]], [[Design/3D Assets]], [[Research/UI/bbstudios UI Reference]].

**Method and limits.** Videos downloaded with `watch.py` (yt-dlp + ffmpeg, route approved 2026-10-27, see [[Design/User Inputs]]), files kept outside the repo in the side-session-notes folder. aotishe: all 148 frames at 10 fps viewed (0.1 s steps). The other 12: 24 evenly spaced frames each (every 0.4 to 2 s), so effects shorter than that are not seen. No audio, no transcripts. Times are read from frame position (+-0.1 s for aotishe, coarser elsewhere). Colours are quantised from the sampled frames. Everything "why it works" is inference.

## 1. aotishe (the important one): kinetic motion-design reel, 14.9 s, 29.97 fps, 1300x1080
Not a game. A pure motion-graphics piece (Y2K / cyber-HUD collage). The ideas that carry over to our UI and cutscenes:

**Timeline (t from start, 10 fps readings)**
| t (s) | What happens |
|---|---|
| 0.0 to 0.4 | near-black (#010306), nothing |
| 0.4 to 1.0 | faint blue grid fades in, then a flat indigo logo shape builds from pieces; a thin curved line draws itself top right |
| 1.0 to 1.6 | a huge chrome triangle wipes in from the lower left in about 0.4 s (hard edge, gradient lit white to indigo); lens-flare crosses sit on its corners; small chrome sphere, white cards and bars pop in around it |
| 1.6 to 2.7 | hold with life: liquid chrome ribbons swirl and thin circles rotate, the triangle gradient scrolls (light band sweeps), so the frame is never static |
| 2.7 | one green-tinted chromatic flash frame, then a hard cut |
| 2.8 to 5.2 | HUD panel (window frame, radar web, text blocks, 3 dots) with a number counting 1000 to 0000. Readings every 0.1 s: 1000, 1000, 951, 778, 706, 640, 579, 523, 431, 374, 330, 289, 251, 180, 149, 120, 94, 70, 31, 17, 6, 0. Eases out: about 170 per step at the start, about 20 per step at the end; about 2.3 s in total. Bars of horizontal-line glitch tear across the panel at 0.4 and 0.5 s before the end |
| 5.2 to 7.6 | counter hands over to a huge chrome ring that enters from the right; glitch "barcode" blocks (black and white strips) stack beside it and shuffle; thin white arcs sweep |
| 7.2 to 7.8 | ring and bars flash to a rainbow gradient arc and white-out |
| 7.8 to 9.4 | cut to a small chrome sphere + liquid squiggle + indigo circuit-board card, held with slow drift and typed code text; this is the calm beat |
| 9.4 to 10.0 | the whole frame rotates and zooms into a nested square (white and black frames) |
| 10.0 to 11.4 | nested-square tunnel with diagonal stripes, small stars, pixel squares; the centre square blinks red twice |
| 11.4 to 12.0 | datamosh / block glitch, then white blocks, then a cut |
| 12.0 to 13.1 | final collage: new counter 1000 to 0426 (about 1.0 s, faster than the first), pale sky image in a small frame, a four-point star, vertical hairlines |
| 13.1 to 14.9 | white wipe from the right, then black |

77 scene cuts at threshold 0.25 in 14.9 s is mostly glitch and flash frames, not 77 separate shots. About 9 real beats. Average beat is 1.5 s; each beat has an entry (wipe, flash or cut), a hold that never fully stops, and an exit (flash or glitch).

**Measured palette (quantised, share of pixels):** near-black #010306 32%, deep navy #110e2b 15%, dark indigo #1f2139 13%, indigo #453b71 13%, grey-violet #76749d 14%, pale highlight #c2c7d7 11%. Second section: #605686, #a89aca, #e5deed. So: one hue family (indigo to violet) on black, with white-ish chrome highlights. Accents (green, rainbow, red) appear for 0.1 to 0.3 s only, as punctuation, never as a base colour.

**Techniques worth copying (all doable in Studio with UIGradient, UIStroke, frame tweens and ImageLabels; no video needed)**
1. **Hold is never still.** Every held frame has at least one slow independent loop (rotating thin circle, scrolling gradient, typing text, drifting ribbon). Matches our rule "no static frames" in [[Research/VFX and Animation/Effect Quality]].
2. **Hard wipe plus lens-flare cross** for big shapes (0.4 s), instead of fades.
3. **Number count-down with ease-out** (1000 to 0 in 2.3 s; our rolling counters could use the same curve). Ties to the rolling-counter work in [[Research/UI/Loading, Intro and UI References 2]].
4. **Glitch as a transition**: 2 to 3 frames of horizontal tear, barcode blocks, chromatic fringe, then cut. A cheap alternative to a fade for stage changes. Needs per-frame offsets in Lua (ImageLabel slices); not built yet.
5. **Collage layering**: many small cards (text blocks, circuit art, 3-dot indicators, thin hairlines) behind one hero element. Reads as "rich" because of small-scale density, not big shapes.
6. **Chrome liquid ribbons and spheres**: the single most "expensive" looking element. We can render these in Blender (matcap or glossy metal, cycles low samples) and use them as sprites; see [[Research/UI/UI Art Pipeline]]. Fits our metal theme only if recoloured gold-ink (the loading-eye chat's palette); the indigo here clashes with the etched look. UNVERIFIED which we want.
7. **Rotate-and-zoom into nested frames** as a screen transition (about 0.6 s): cheap with a Rotation tween plus Size tween on a stack of frames.

**Unclear:** whether the user wants this exact cyber look (indigo, glitch) or only the pacing and motion vocabulary. Our game is steampunk to cosmic, so the safe reading is "pacing and motion vocabulary, our palette". Ask.

## 2. Others, one paragraph each
Duration, resolution, what it shows, what applies.

- **guineainteractive** `7696568496024505614` (14.3 s, 1080x1920). "Roblox Titan Game, Opus 5.5 / Blender / Roblox Studio". Boss reveal: dark red arena, glowing floor cracks, camera dolly while a giant humanoid rises from a crouch (about 0.6 to 3 s), then a boss HP bar ("INFERNO TITAN, THE ASHEN KING", ornate frame, 100%) fades in at about 4 s, then he charges a fireball (orange ring, ember particles), throws it, and a shockwave smashes the player's blocky avatar. Palette measured red/black (#3d0803, #451207, #6f1606, #7a2912, #895139, #140401 base). Applies to: boss intro cutscene in [[Design/Cutscenes and Transitions]] (HP bar appears only after the reveal; embers as constant ambience; one hero attack per clip). Camera pushes and 2 to 3 s holds rather than cuts.
- **fxroxx** `7696579021093506337` (15 s). "POV: claude is just cooking for u". Studio screen recording of a cyan/blue crystal orb with orbiting ring trails, flower-like crystal "wings" that open and close, ripples on the floor, star sparkles; camera pushes into the orb at about 10 s. Palette: cyan, ice blue, soft violet on near-black. Applies to: summon / egg hatch and rarity reveal; ring trails (Trail or Beam) plus petals opening is a concrete recipe. Compare [[Research/VFX and Animation/Summon References]]. Not a measured analysis of the trails.
- **hyisno0b** `7700960602851790098` (51 s, 1080x1920). Minecraft (modded) Ender Dragon fight with a first-person ultimate: ability wheel (radial menu) opens, player picks "Spatial Path", camera stays first person, purple radial light-line web (spokes plus concentric circle) expands from the player's feet, the screen floods magenta, a one-frame inverted black/white "negative" flash, "I AM" text, a "Release your button" prompt on a black screen, then a vertical pillar of light and a pull-up to a top-down view with the line web on the ground. Palette measured: #25122d, #521a6b, #791ea3, #c98ad8, #864b8f. Applies directly to the user's stated idea "pressing ULTIMATE goes into first person" in [[Design/User Inputs]] and [[Planning/Immersion - Every Action a Cutscene]]: radial menu to line-web to flood to negative frame to text beat to release. Longest clip, only 24 samples, so exact timings not read.
- **sixervfx** `7701020761351261473` (9 s). "Work in progress, not proud of the end". Roblox Studio timeline recording of a boss summon cutscene: avatar with dark cubes, sharp violet-blue crystals, black-and-white speed frames, a four-point star slash, then a dragon face reveal with chromatic red lines and a white flash to cut. Mostly 0.3 to 0.5 s cuts, flash frames between. Palette: violet, blue, near-black. Applies to: Star Drake style reveal ([[Design/User Inputs]] 2026-10-27: STARFALL effects need work). The creator marks it unfinished; do not treat as a quality benchmark.
- **origin.o** `7692285528045112596` (32.6 s, 720p, blocky game). A character grows white feather wings and a halo ring, white and gold light rays burst out, a fiery greatsword in first person, sun glare in a desert; dark intro caption at 0 s. Concrete idea: halo ring plus radial ray burst plus feathers for a Celestial rarity reveal (Celestial is in [[Systems]] now). Low resolution; fine detail UNVERIFIED.
- **skaterstudios** `7685652372638436628` (18.2 s, 60 fps). "Day 1 learning scripting" crab boss fight: damage numbers (small white "-1", "-2", "-3" plus purple ones), ember hit sparks, black ground cracks that stay on the floor, boss body flashes colour (blue to purple to red) as a phase tell, caption overlay changes at 7 s and 13 s. Applies to: hit feedback and enemy phase tint in [[Research/UI/Enemy health and status readability]]. Cheap wins: tint shift per phase, persistent floor cracks, stacked small damage numbers.
- **gojodevs** `7699528523282877729` (23.9 s). "what me and my team made in 2 weeks": voxel-style steampunk set on a rail: galleon, ogre, whale, mech, brass cannon, steam train with cyan glowing lamps, balloon, spider-mech, turret firing with a muzzle flash. Palette: deep blue and gold with cyan emissive glow, over an orange to blue sky gradient. Very close to our steampunk theme (blue-brass-cyan). Applies to: enemy and boss colour design in [[Research/3D and Art/Backgrounds and Enemies - Mystic Victorian]]; the contrast rule (dark body, bright emissive accents) is the takeaway. One camera orbit per model, about 1 s each.
- **nhance.school** `7694774642132782358` (17.3 s). Tencent Hunyuan 3D (the model we use) generating a sword from a single image ("AI will replace 3D artists in gamedev"), then shown next to what a 3D artist does: clean mesh, colour base from baked maps, clean hand paint, final PBR. Relevant to our [[Design/3D Assets]] pipeline: the AI result is untextured grey geometry with noisy surface detail; the artist steps are retopo, bake, hand paint, PBR. Confirms our "shape only, colour in Studio" split. Gives a four-step checklist; not measured.
- **overlocked.hq** `7694726541980241172` (12 s). Two AI models each building a Rolex-inspired watch website with an exploded-view scroll animation (case, dial and movement separating as the page scrolls). Not Roblox. Idea: scroll- or button-driven "exploded view" for an upgrade or merge screen (parts separate, rotate, recombine). Interesting for the merge mechanic, UNVERIFIED how it would be built in Roblox (needs several MeshParts).
- **dev5s_** `7697032824104226061` (14.3 s). "Claude Design": Roblox game with a creature (wolf rig, 44 bones, 27k tris shown on screen), a themed "Portal Wall" teleport UI (purple, gold rainbow arches, glowing orbits). Applies to: stage-select UI idea (arches with glow, orbit lines). Text on screen only partly readable.
- **bbstudios4** `7700060539724074254` (39 s). "Ur Claude can build whole games": a bright water raft game recorded at 60 fps, HUD at the corners, caption above. Not UI-focused here; the account's UI work is in [[Research/UI/bbstudios UI Reference]]. Low relevance.
- **jackroberts____** `7685847969844808993` (28 s). A talking-head explainer on video understanding by AI models (Claude vs Gemini). Not game or art content. One idea only: a rich edit style (kinetic text captions, pop-in cards); no takeaway for the game. Skip.

## 3. What to do with it (suggestions, not done)
1. Loading-eye UI chat: aotishe items 1, 2, 3, 4 and 7 can be tried on the start menu and stage change with our gold-ink palette. Ask the user whether the indigo look is wanted.
2. Cutscene owner (Sonnet): hyisno0b ultimate flow and guineainteractive boss reveal as templates (HP bar after the reveal).
3. Familiar and enemy art: fxroxx ring-trail orb for the Celestial hatch; gojodevs dark body plus cyan emissive rule; origin.o halo ring.
4. Nothing was built or uploaded; no Studio, ComfyUI, GPU or Blender used.

## 4. Open questions for the user
- aotishe: copy the look (indigo, glitch) or only the pacing in our palette?
- Which of hyisno0b (ultimate) or guineainteractive (boss reveal) should be built first?

## 5. Decision (2026-10-29)
**Said:** "Pacing only": use aotishe's pacing and motion vocabulary (wipes, never-still holds, eased counters, glitch cuts, rotate-zoom) in our gold-ink palette, not the indigo look. Open question 1 closed; question 2 still open.
