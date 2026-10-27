# Reference Video Study 2: priority links (2026-10-27)

Method: each video downloaded with yt-dlp, 24 evenly spaced frames per video in one overview sheet (see [[User Inputs]]). Labels: **Seen** = visible in frames. **Inference** = my reading. No audio, no transcripts, no comments were read; fast effects between sampled frames can be missed (10 fps sheets exist for a closer look). Studied so far: the 3 UI links and the 6 benchmark links. The other 10 (tutorials, 3D/workflow) are NOT studied yet.

Related: [[Research/VFX and Animation/TikTok VFX Reference Study]], [[Research/UI/Loading and Reveal Spec]], [[Research/UI/UI Methods and Magic Effects]], [[Feature Pipeline]]

## UI (priority)
**gfxcomet 7695567752261586206 (OP-114 mission HUD, 69 s).**
- Seen: a dark sci-fi directive panel with a big title (OP-114), a phase number, a progress bar filling yellow-green, a 4-row objective list (A1 to A4) where the active row turns orange with an orange square marker and finished rows get checkboxes, and a countdown "14:37" with an ETA. Thin corner brackets and tiny technical labels fill the margins. The panel is tilted in 3D over the game view. A second layout (signal observatory, crosshair, audio waveform) appears. The last third advertises a UI pack.
- Inference: the quality comes from hierarchy (huge number, small caps labels), one accent colour for "active", and tiny decorative text. For us: a quest or objective list (daily tasks, stage goals) with an orange active row and a tilted panel would suit the HUD, restyled brass and Victorian instead of sci-fi.

**syuaey_ 7695927409681435926 (LUNAR JUDGMENT, 31 s).**
- Seen: a full cinematic ability with bracketed HUD captions in light cyan at the top ("[ LUNAR JUDGMENT ]", "[ CANNON CHARGING ]", "[ FIRE CONFIRMED ]", "[ IMPACT CONFIRMED ]", "[ WARNING: SECOND DETONATION ]"), small readouts at the bottom, thin corner brackets. Sequence: moon, satellite cannon charging with blue rings, white-out flash, beam, impact ring, debris and a white column, second detonation, blur settling on a glowing ring.
- Inference: text stages narrate the ability and give each phase a UI job. Directly relevant to STARFALL, GRAND ARCANA and WINTER'S HUSH: add bracketed stage captions and phase beats (charge, white-out, impact, aftershock).

**usaaa804 7701017387746839840 (rarity reveal, 24 s; caption "Opus 5.5 + Blender + VFX Studio").**
- Seen: one reveal screen per rarity (Epic purple, Divine gold, Ethereal teal, Transcendent green then pink): dark vignette, a glowing four-point star orb with a ring and rays, the rarity word below. The top rarity becomes a full cinematic: white-out, a gold ring opening with rays, petals, columns and clouds, a black character silhouette on a rayed blue backdrop, then a final card with name, title, odds "1 in 1,008x" and a tap-to-continue line.
- Inference: each rarity gets its own colour world, not only a bigger burst. Our Orrery summon and silhouette beat already echo this; worth adding per-rarity colour worlds and an odds line on the final card.

## Benchmark quality
**syuaey_ 7689557302894152963 (golden spear strike, 16 s).** Seen: a gold spear with rings charging in darkness, a white-screen flash, a white column, then a violet full-screen flash. Inference: hard colour flashes mark the strike; keep them under our Flashes setting.

**sixervfx 7698207431645564192 (Chisa-inspired character VFX, 11 s).** Seen: very fast cuts, hand-drawn-style slash ribbons (red, black, blue), screen-filling colour washes (red, pink, white), black silhouettes on bright backdrops, close-ups at odd angles. Inference: stylised 2D-looking slashes and colour floods, edited like anime; the camera and cuts do as much as the effects.

**blovica 7690294293059161357 (purple blade ultimate, 14 s).** Seen: a dark night sky, a violet character, tall violet energy pillars, butterflies, a pink ring, long speed-line streaks with zoom blur, a starburst, sparkles, then a fade to the sky. Inference: many small layered particles plus speed lines and a starburst read as premium; the dark scene makes glows readable (like our dusk Lampwick Lane).

**goodgood3d 7687326536504003872 (Blender tutorial, 92 s).** Seen: Blender Geometry Nodes and shader nodes building an animated dome shield: scene time, a float curve, noise texture, a Greater Than threshold giving black and white masks, an "age" attribute, then a glowing emissive shield and a red crescent. Inference: a time-driven noise mask on a sphere is the core trick; it could become a ward bubble or reveal dome. Blender 5.3 exists here; export to Roblox (baked mask or EditableImage) is unsolved.

**pr0_devv 7679364442194234646 (Bezier curves, 53 s).** Seen: a lerp function explained, a quadratic Bezier built from two lerps, a Luau code card, then white spark trails curving through a Roblox scene. Inference: Bezier arcs make projectiles feel alive; ProjectileFX could use them for Arcane Fox cards and Star Drake starbursts. The video says the code is in its comments, which we do not have.

**lambsx 7697543400899366175 (character reveal trailer, 18 s).** Seen: extreme close-ups with heavy depth-of-field blur, the title "MIZU" growing behind the character, a glassy water-spirit fish, a rival in red, very fast cuts, strong teal against warm skin, a caption on the first frames. Inference: a "meet the character" teaser format; could be a reveal intro for each familiar (portrait close-up with blur, big name behind, one signature effect).

## Suggested additions (my suggestions, not decisions)
1. Bracketed stage captions and phase beats inside the three cutscenes (Lunar Judgment pattern).
2. Per-rarity colour worlds and an odds line on the summon reveal (usaaa804).
3. Objective-list HUD panel with orange active row and a tilted perspective (gfxcomet), in brass for the Victorian theme.
4. Bezier-arc projectiles in ProjectileFX (pr0_devv).
5. Layered speed lines, starburst and particles on ultimates, inside the touch particle cap (blovica, syuaey_).
6. Stylised slash ribbons and colour-flood backgrounds for big hits (sixervfx).
7. Procedural ward-dome shader idea (goodgood3d), later.

## Not studied yet
Tutorials: remonbiz, smudger13030, lihfolk (897 s), ashenbot, vinallac, solodev_t, deadj.rodev 7698101726175350038. 3D and workflow: deadj.rodev 7701021888679808279, vos_studiostt (484 s), iag0d_. The user has not yet said what exactly is wrong with the Star Drake STARFALL effects; these notes give ideas only.
