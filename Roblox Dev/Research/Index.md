# Research Index

Every research note, grouped by area. Add new notes to the right folder and list them here. Related: [[Home]], [[Backlog]]

## UI
- [[Research/UI/Creative Fix Method|Creative Fix Method]]: the loop for turning anything generic into a themed object or cutscene, the metaphor table, pitfalls and a log of every fix; run it with /make-creative (2026-10-28)
- [[Research/UI/Abstract UI|Abstract UI]]: Hilma af Klint, Kandinsky, Bauhaus, Mini Metro and Persona research turned into seven rules; the HUD's abstract layer (2026-10-28)
- [[Research/UI/Start Menu - Sol's RNG and Tutorials|Start Menu - Sol's RNG and Tutorials]]: how Sol's title flow works, the common menu techniques (scene camera, clamped parallax, blur, flash), Claude + Studio MCP workflow, what we applied (2026-10-28)
- [[Research/UI/UI Rework 2026-10-28|UI Rework 2026-10-28]]: loading screen, start menu, Victorian object controls, Trainer Road, skill tree paths (2026-10-28)
Screens, kits, art pipeline, and what other games' UI does.

- [[Research/UI/Community UI Approaches|Community UI Approaches]]: how other Roblox developers build and animate UI (Fusion, Sculpt, springs) compared with our FrameArt and UI Kit (2026-10-27)
- [[Research/UI/bbstudios UI Reference|bbstudios UI Reference]]: frame-level study of the bbstudios4 TikTok UI (scroll and glass look) and how to copy it
- [[Research/UI/GUI Maker Tools Review|GUI Maker Tools Review]]: RobloxGUIMaker, ForgeGUI and open-source alternatives; Obsidian Excalidraw design plan
- [[Research/UI/Loading and Reveal Spec|Loading and Reveal Spec]]: combined Rivals + Sols loading and reveal design with acceptance checks
- [[Research/UI/Screenshot Analysis|Screenshot Analysis]]: what 7 popular games' UIs do, the qualities worth copying, and the mistakes to avoid
- [[Research/UI/UI Art Pipeline|UI Art Pipeline]]: why our UI felt flat (artwork vs frames) and the free sprite, Blender and Kimi pipeline we built
- [[Research/UI/UI Design Playbook|UI Design Playbook]]: modern, mobile-first Roblox UI rules, layout, animation, onboarding
- [[Research/UI/UI Direction - Welcoming|UI Direction - Welcoming]]: the HUD stays tiny and the world is the UI; welcoming, low-pressure tone: level and money bottom-left, a two-slot hotbar bottom-centre, one timer top-centre, two round buttons top-right. Everything el
- [[Research/UI/UI Generator Method|UI Generator Method]]: how the paid UI generator sites likely work, and the free UI Kit we built to match (untested)
- [[Research/UI/UI Methods and Magic Effects|UI Methods and Magic Effects]]: general UI methods for non-rigid, magical UI (unroll, glass, stagger, glow)
- [[Research/UI/UI Recreation Coverage|UI Recreation Coverage]]: which screenshot UIs are built and the suggested build order

## VFX and Animation
- [[Research/VFX and Animation/Summon References|Summon References]]: how FGO, Hearthstone, Honkai Star Rail and Anime Vanguards stage summons (frame study) and our tarot-table reveal The Reading (2026-10-28)
- [[Research/VFX and Animation/Cinematic Cutscenes|Cinematic Cutscenes]]: how high-quality Roblox cutscenes are made (reference-part cameras, splines, first-person from Blender, impact frames, speed lines) and our first-person ultimate (2026-10-28)
- [[Research/VFX and Animation/Effect Recreation 1to1 - Index|Effect Recreation 1to1 - Index]]: measured 1:1 recreation pipeline (in-engine reference rebuild, side-by-side capture, per-layer test, texture painter, sheet and UI comparison) and results for Hollow Purple, Healing, Egg Hatch, Coin Drop, Sol's roll screen (2026-10-28)
- [[Research/VFX and Animation/Crafted Sheet Techniques|Crafted Sheet Techniques]]: cracks, erosion, shaded shards, bloom: how hand-made sheets get their craft, implemented in tools/fx_craft.py (2026-10-28)
Rolls, cutscenes, beams, blur, juice, and the reference videos behind them.

- [[Research/VFX and Animation/Free VFX Sources and Paid-Quality Build Plan|Free VFX Sources and Paid-Quality Build Plan]]: CC0 free sources, what paid packs include, a measurable quality bar, and the first procedural flipbooks (2026-10-27)
- [[Research/VFX and Animation/ParticleFX Studio and Flipbook VFX|ParticleFX Studio and Flipbook VFX]]: one-particle flipbook effects, exact emitter recipe, tower-defense and UI effect sets, six DevForum threads (2026-10-27)
- [[Research/VFX and Animation/Community VFX Techniques|Community VFX Techniques]]: Roblox and other-engine effect methods (mesh slashes, flipbooks, Sine VFX) mapped to our kit (2026-10-27)
- [[Research/VFX and Animation/Animation and Juice Playbook|Animation and Juice Playbook]]: how UI supports animation, easing and timing, Luau recipes
- [[Research/VFX and Animation/Beam and Impact VFX Recipes|Beam and Impact VFX Recipes]]: layered beams, impact sets and captions for STARFALL and the other cutscenes (STARFALL beams were plain cylinders) the beams are plain cylinders (`VFX/CutsceneFX.luau` line 357 `column`, 576 `pillar`) with no effects. This note turn
- [[Research/VFX and Animation/Magical Roll Animation Playbook|Magical Roll Animation Playbook]]: how Sol's RNG style effects are built, what AI can and cannot do, rarity-tier reveal plan
- [[Research/VFX and Animation/Reference Video Study 2 - Priority Links|Reference Video Study 2 - Priority Links]]: the 19 priority reference videos, frame-sampled, with suggested additions with yt-dlp, 24 evenly spaced frames per video in one overview sheet (see User Inputs). Labels: **Seen** = visible in frames. **Inference** 
- [[Research/VFX and Animation/Skill Tree, Effects and Characters|Skill Tree, Effects and Characters]]: honeycomb skill tree, roll effects and character presentation, from the screenshots in this folder. Related: Screenshot Analysis, Magical Roll Animation Playbook, Animation and Juice Playbook, Game Design Doc, S
- [[Research/VFX and Animation/Smooth Motion and Blur Playbook|Smooth Motion and Blur Playbook]]: smooth, elegant motion; blur effects (transition, focus pull, camera-speed); blur loading screen; code recipes (untested)
- [[Research/VFX and Animation/TikTok VFX Reference Study|TikTok VFX Reference Study]]: the 11 supplied TikToks played in full with comments read, plus a search for high-engagement Roblox animation ranked by likes and saves (2026-10-26)
- [[Research/VFX and Animation/VFX Verification Report|VFX Verification Report]]: machine checks of effects and sound (run 2026-10-25) because nobody could review the effects by eye or ear. Method: checks the machine can run (numbers, comparisons against known values, frame measurements, 
- [[Research/VFX and Animation/Video Reference Analysis|Video Reference Analysis]]: frame-level analysis of the 10 Rivals / Sols RNG / vibe-game videos (sheets in Research/Video Frames)

## 3D and Art
Models, Blender, animation, image generation, backgrounds and enemies.

- [[Research/3D and Art/Community 3D Pipelines|Community 3D Pipelines]]: AI 3D generators, VRAM and licence numbers, Roblox GenerationService change (2026-10-27)
- [[Research/3D and Art/3D Model Workflow|3D Model Workflow]]: the simple loop for every model: 2D reference -> Hunyuan3D -> Blender -> the user approves -> game; quality bar for distinct, detailed models
- [[Research/3D and Art/Animation Kit Review|Animation Kit Review]]: fwjelaa's R6/R15 animation pack: what it does, what it does not do for us, what was installed
- [[Research/3D and Art/Asset and Animation Workflow|Asset and Animation Workflow]]: full stage table, import bugs and fixes, animation coverage
- [[Research/3D and Art/Backgrounds and Enemies - Mystic Victorian|Backgrounds and Enemies - Mystic Victorian]]: date: 2026-10-27
- [[Research/3D and Art/Blender Cinematic Pipeline|Blender Cinematic Pipeline]]: - The old install folder `C:\Program Files\Blender Foundation\Blender 4.3\` has no `blender.exe`; ignore it.
- [[Research/3D and Art/Image Generation Workflow|Image Generation Workflow]]: Two sources, one hand-off folder. Kimi is retired (Claude could not drive it, and it was a manual download step).

## Game Design and Market
Genre playbooks, competitors, monetization rules, retention, low-end devices.

- [[Research/Game Design and Market/Competitors and Policy|Competitors and Policy]]: live competitor numbers, UI patterns to copy, and Roblox's paid-random-item rules
- [[Research/Game Design and Market/Engagement Loop Playbook|Engagement Loop Playbook]]: what makes simple games sticky, plus a one-month build plan
- [[Research/Game Design and Market/Layouts, Placement and Summoning|Layouts, Placement and Summoning]]: date: 2026-10-27
- [[Research/Game Design and Market/Low-End Device Playbook|Low-End Device Playbook]]: making the game run and feel good on phones and tablets
- [[Research/Game Design and Market/Merge Tower Defense Playbook|Merge Tower Defense Playbook]]: tower defense and merge design, Roblox TD engineering, gacha/monetization resolution
- [[Research/Game Design and Market/Mid-Size Game Patterns|Mid-Size Game Patterns]]: what the 5K to 30K player games have in common, with live chart data and ages
- [[Research/Game Design and Market/Payments and Robux|Payments and Robux]]: Researched 2026-10-24 from the official pages [Developer products](https://create.roblox.com/docs/production/monetization/developer-products) and [Game passes](https://cr
- [[Research/Game Design and Market/Roblox Success Sources|Roblox Success Sources]]: vetted official docs on discovery, retention, security, monetization, and tooling

## Process and Tools
How we build and test, and tools or skills that speed us up.

- [[Research/Process and Tools/Community Vaults and Workflows|Community Vaults and Workflows]]: Karpathy LLM-wiki pattern, RbxSync harness, Studio MCP servers, and what our vault adopted (2026-10-27)
- [[Research/Process and Tools/Dev Process Playbook|Dev Process Playbook]]: how we build, test and ship (applies to any game)
- [[Research/Process and Tools/Workflow Gaps and Game Feel|Workflow Gaps and Game Feel]]: Open Cloud uploads, phone testing, window recorder, game-feel research and what was built from it (2026-10-26)
- [[Research/Process and Tools/Workflow Tools and Skills|Workflow Tools and Skills]]: ranked tools, skills and connectors that could speed us up (ffmpeg already installed; nothing new installed yet) (2026-10-27)

## Media (not notes)
- `Research/Reference Screens/`: 67 screenshots of other games (Sols RNG, Duel, fishing, pet and fruit games). Embedded by name from the UI and VFX notes.
- `Research/UI Kit Renders/`, `Research/VFX Renders/`, `Research/Video Frames/`: our own Studio renders and extracted video frames (scripts write here, so the paths stay).
- `Research/Reference Videos/`: the downloaded reference clips (git-ignored, large).
