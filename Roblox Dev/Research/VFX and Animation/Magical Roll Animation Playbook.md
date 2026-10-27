# Magical Roll Animation Playbook

Researched 2026-10-24 from 24 screenshots of Sol's RNG (supplied by the user) plus Roblox docs. Related: [[Animation and Juice Playbook]], [[Low-End Device Playbook]], [[Screenshot Analysis]], [[Game Design Doc]] (crate reveal, settings), [[Systems]] (VFX row), [[Competitors and Policy]]

## Short answer: can AI make these animations?

**Partly, and it is worth being exact about which part.**

What the Sol's RNG effects actually are: not character animation (no skeleton keyframes). They are **VFX built from Roblox's effect objects**: particle emitters, beams, trails, glowing meshes, rings and runes lying on the ground, tweened parts, screen-wide post-processing, camera moves, a big text title with the rarity ("1 in 50,000,000"), and a music track. The aura viewer even credits teams per aura ("[CA] By @a, @b, @c", "[DA] By ..., Concept By ..."), so the best ones are made by several VFX artists. Note: that credit format is what the screenshots show. I could not find a developer write-up on how the game builds them.

| Part of the effect | Can AI do it? | How |
|---|---|---|
| Sequencing, timing, tweens, camera moves, text pop-ins, screen flash and fade, screen shake | **Yes, well.** This is code. | Claude writes Luau (TweenService, camera, UI) and runs it in Studio through the Studio MCP server |
| Particle emitters, beams, trails, lights, rings (tuning numbers and layering) | **Yes, as a first draft that needs iteration** | Claude creates the instances and sets the properties through MCP, plays it, and reads screenshots. Look is judged by you |
| Textures for particles (soft glow, star flare, rune circle, smoke, slash) | **Yes, with an image generator** | Generate on transparent or black background, upload to Roblox; additive blending (`LightEmission` = 1) lets black become invisible. Upload and moderation are yours |
| 3D props (crown, wings, sword, plane, sleigh) | **Partly** | Hunyuan3D (already installed here, shape only, under 3K triangles for props), or Roblox's Cube 3D mesh generation in Studio. Colour and glow added in Studio |
| Character body animation (R15) | **Partly** | Roblox's Animation Capture turns a short video (single person, under 15 s) into R15 keyframes (beta). Third-party tools exist that claim text-to-animation; I did not verify any |
| Music and sound | **Not by me** | Needs licensed or generated audio you upload; check licence |
| "Does it look and feel amazing" | **No** | Needs your eyes. Claude only sees still screenshots, not motion, so use captured frames at set times and tell Claude what feels off |
| Roblox's own text-to-animation or text-to-VFX in Studio | **I found no evidence it exists** | Search results mentioned Animation Capture (beta) and Cube 3D/4D news, nothing for text-to-animation. One third-party 2026 guide says there isn't one. Treat as unconfirmed; re-check release notes |

So: we do not get a "type a prompt, get an aura" button. We get **AI as the VFX programmer plus asset helper, with you as the art director**. That is how the cutscenes in these screenshots are built anyway (concept, then VFX, then code).

## What the screenshots show

Files are `sols-*` (the game) and `aura-view-*` (its aura collection viewer, which can replay each cutscene). All 1920x1080 desktop. Links go to the images in this folder.

### Roll flow
- [[sols-loading-screen.png]]: tiny loading screen (a logo, a thin bar, "Loading Complete. Welcome, Satocry.", one tip). Clean and cheap.
- [[sols-roll-result-crowned-1-in-20000.png]]: the result is **big title, odds line, rarity word**, with a golden crown and halo ring on the player. "1 in 20,000 / Crowned / Gilded [MUTATED]". Clear hierarchy: odds first, name second, modifier third.
- [[sols-roll-red-environment-takeover.png]], [[sols-roll-green-ruins-environment.png]]: for rare results **the whole world changes colour**: floor, sky, and nearby objects tinted red or green, with huge angular props and light streaks. The HUD stays in place.
- [[sols-roll-gargantua-black-hole.png]]: a black-hole disc above the player, light shafts in teal and white, ground glow, the aura name across the top. A **title card slides in for the biggest results** ("GARGANTUA").
- Controls stay simple: a big Roll button with a counter, Auto roll ON, Quick roll ON ([[sols-roll-result-crowned-1-in-20000.png]]). **"Quick roll" and a cutscene skip setting exist** (a guide says a "Cutscene Skip Rarity" setting stops long animations for low-tier results). That is the key to keeping a repeated roll bearable.
- HUD: ranked leaderboard by rolls, daily rewards claim ([[sols-daily-rewards-leaderboard.png]]), small notification cards at the bottom right, an item bar at the bottom right, and a day/night clock.

### The aura viewer (best reference)
The viewer lists auras on the left (locked ones are plain "Locked"), shows a **name styled in each aura's own font and colour**, a rarity tier label (MYTHIC, EXALTED, GLORIOUS), "Amplify Conditions: During Night/Windy/Snowy", a credits box, a lore paragraph, a music track with title and artist, **Replay Cutscene**, **Hide UI**, and **Default**. This is a model for our collection index.

Visual recipes seen (descriptions of the look, not how they were built):
- Ground **circle with rune ring and swirl**: [[aura-view-ethereal-rune-rings.png]], [[aura-view-hades-summoning-circle.png]], [[aura-view-twilight-ripple-rings.png]], [[aura-view-origin-blue-vortex.png]]
- **Tall light pillars and beams** of colour: [[aura-view-sirius-color-beams.png]], [[aura-view-galaxy-spiral.png]]
- **Floating geometric props** orbiting the player: cubes ([[aura-view-matrix-cubes.png]]), swords ([[aura-view-overseer-eye-swords.png]]), crystals ([[aura-view-starscourge-radiant-crystals.png]]), plane ([[aura-view-aviator-biplane.png]])
- **Single colour world** per aura (monochrome palette, one accent): red ([[aura-view-vital-blood-pool.png]], [[aura-view-starscourge-red-stars.png]]), purple ([[aura-view-nightmare-sky-chains-moon.png]]), blue ([[aura-view-moonflower.png]]), white ([[aura-view-chromatic-genesis-white-burst.png]])
- **Thin line art** (flowers, petals, lines): [[aura-view-twilight-iridescent-memory-lines.png]]
- **Theme scenes**: sleigh and glowing reindeer ([[aura-view-santa-frost-sleigh.png]]), snow globe ([[aura-view-wonderland-snowglobe.png]])
- Always a **name plate with odds** above the player in a themed font, with a gentle glow and sparkle.

## What makes them feel "high quality magical" (patterns)

1. **One palette per effect**: a dark base, one hero colour, one near-white highlight. No rainbow mush (except the intentional rainbow ones).
2. **Layering**: ground ring + core glow + rising particles + orbiting props + name text. Each layer is simple; the stack is rich.
3. **Additive glow on a dark scene**: bright things on dark backgrounds. The dark night skybox and dim world in the roll screenshots make the glow pop.
4. **Anticipation then release**: darken the screen, slow time or gather light, then the burst. (The Atlas aura is described by guides as going dark, showing an image, then fog lifting; that one I only know from guides, not screenshots.)
5. **Scale = rarity**: the more rare, the bigger the area, the more environment changes, the longer the cutscene, the bigger the title.
6. **Name and odds are part of the effect**, not a footnote.
7. **Music per rarity or per aura**, with the title shown.
8. **Skippable**: quick roll and a skip threshold keep the loop fast.

## Our plan: crate reveal for the merge tower defense

Our design today (see [[Game Design Doc]] "Gacha / crates"): "shake, flash, rarity-coloured burst, pet spins in, duplicate converts to shards". Upgrade it to **rarity tiers of effort** (cheap at the low end, rich at the top), since rolling is repeated and most results are Common.

| Tier | Effect budget | Length |
|---|---|---|
| Common | Pop-in card, small sparkle, sound. No screen change | under 1 s |
| Rare | Ground ring in blue, upward particles, short glow on the card | about 1.5 s |
| Epic | Ring plus beams, orbiting small props, slight screen tint, short title card | about 3 s |
| Legendary | Darken, gather light, burst, golden ring + pillar, large title with odds, camera push-in, special music sting | about 5 to 6 s |
| Skip | Quick roll toggle and "skip animations at or below rarity" setting | 0.3 s |

Also: **a Replay/Preview in the collection** (as the aura viewer does) so players can rewatch and we can test effects without rolling.

### Constraints that apply to us (from earlier notes)
- **Flashes setting**: the Sol's screenshots show full-screen red and green takeovers and bright white bursts. Ours must respect the Flashes and Reduced-motion settings in [[Game Design Doc]]. Each effect needs a **no-flash variant** (soft glow instead of white flash; no rapid flicker).
- **Mobile limits** (official [ParticleEmitter docs](https://create.roblox.com/docs/effects/particle-emitters)): emission rate is capped at 400 per second on desktop and 100 on mobile; particle lifetime max 20 s; large and overlapping translucent particles cost more (overdraw); flipbooks and custom textures use extra memory and may be disabled on low-memory phones. So: few particles, small textures, reuse textures, and honour the **Particles Low/Default/High** setting.
- **Test both quality levels**: the docs suggest setting Editor Quality Level to lowest and highest in Studio and checking the look.
- **Paid random items**: our crates use free currency only, so no odds-disclosure issue, but we show odds anyway. See [[Competitors and Policy]].
- **Audio**: licence and availability must be checked per asset.

## How we would build it with AI (workflow)

1. **Pick a style sheet for each rarity**: palette (3 colours), shape (ring, pillar, burst), props, music mood, and length. Write it in the vault.
2. **Claude builds a `RevealFX` module**: a function per tier that takes a spawn position and a settings table (flashes, particles level). It pools emitters, tweens, plays sounds, and cleans up. Everything client-side.
3. **Claude creates the instances through the Studio MCP server**, plays the reveal in Studio, takes **screenshots at fixed moments** (0.2 s, 1 s, 2 s, 4 s) and compares them to a reference image you give it.
4. **You judge**: "ring too small", "glow too white", "too long". Claude edits numbers and re-runs. Repeat 3 to 6 times per tier.
5. **Asset step**: image generator for 3 to 6 particle textures (soft glow, star, ring, rune circle, smoke wisp). Reuse across tiers.
6. **Replay in the collection** doubles as the test harness.
7. **Phone check**: run on a real low-end phone with Particles Low and Flashes Off; frame rate must hold.

Honest limits: Claude does not see motion; it sees screenshots. The loop needs your eyes on the moving result. Quality will come from iteration and good references, not from one prompt. Studio MCP tool names and exact capabilities come from Roblox's [MCP page](https://create.roblox.com/docs/studio/mcp) (scripts, running Luau in Edit/Client/Server, playtesting, console, screenshots, simulated input); I have not yet run an effect through it for this project.

## What we need from you
- 3 to 5 reference stills or clips per rarity you like (these screenshots count).
- A decision on the rarity tiers and names for our pets.
- Whether we may generate textures with your image tool, and where to store uploads (the textures must be uploaded to Roblox from your account).
- Music direction (we have no audio yet).

## Gaps
- Not verified: how Sol's RNG actually builds its effects (no write-up found).
- Not verified: any AI text-to-animation product. Roblox Assistant's current VFX abilities were not tested.
- Not read: Beam, Trail, post-processing (Bloom, ColorCorrection, DepthOfField, Blur), or camera docs in detail; Roblox's `effects.md` index page did not cover post-processing.
- Not tested: any of the Luau or effect values here in Studio.

## Built (2026-10-25): RevealFX prototype
First implementation of the plan above, in `VFX/RevealFX.luau` (README in `VFX/`). Stills at fixed moments: `Research/VFX Renders/` (legendary, epic, rare, ultimate). What worked: a lighting-based night shift for the anticipation (a UI dim layer also dimmed the glow, so effects looked flat; fixed), slim bright pillars and beams instead of wide translucent slabs, a serif gold title card with odds first, a gothic rose-window ground sigil. Ultimate "Dawnbreaker" (7.6 s): sigil opens and four gold pillars rise, a giant spectral sword materialises, light chains drop from it, it hangs, falls in 0.4 s, flash plus camera shake plus three shockwaves, ground cracks, a gold pillar, orbiting spectral swords, title card, then it dissolves. Not yet judged by you in motion; tell me what feels off. Flashes-on peak is 0.95 (rise 0.05 s) once per Ultimate; with Flashes off it becomes a slow 0.22 tint.
