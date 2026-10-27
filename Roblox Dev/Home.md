# Home

Start here. Claude reads this vault at the start of every session. Layout: root = the live game notes; `Planning/` = early plans; `Research/` = notes by area (see [[Research/Index]]); `Assets/` = models and character art.

## Game (live notes)
- [[Game Design Doc]]: what the game is and why it's fun
- [[Systems]]: every game system and its status
- [[Backlog]]: what to build next, in order
- [[Bug Log]]: open and fixed bugs
- [[User Inputs]]: feedback, playtest notes and decisions from the user
- [[Feature Pipeline]]: how a new feature goes from idea to verified
- [[How to Add a Character]]: data-driven recipe for a new familiar
- [[3D Assets]]: Hunyuan3D models and their status
- [[Analytics/Analytics Log|Analytics Log]]: weekly numbers and what changed
- [[Session Log]]: one line per work session (full history)

## Planning (early, mostly done)
- [[Planning/Master Plan|Master Plan]]: the 4-week plan, who does what, risks
- [[Planning/Concept Pitches|Concept Pitches]]: the three original pitches (the user chose a merge tower defense instead)
- [[Planning/Game Redesign - Merge Academy|Game Redesign - Merge Academy]]: the proposal to make the roster one merge chain

## Research (by area; full list in [[Research/Index]])
- **UI** (10): Screens, kits, art pipeline, and what other games' UI does. [[bbstudios UI Reference]], [[GUI Maker Tools Review]], [[Loading and Reveal Spec]], [[Screenshot Analysis]], ...
- **VFX and Animation** (9): Rolls, cutscenes, beams, blur, juice, and the reference videos behind them. [[Animation and Juice Playbook]], [[Beam and Impact VFX Recipes]], [[Magical Roll Animation Playbook]], [[Reference Video Study 2 - Priority Links]], ...
- **3D and Art** (6): Models, Blender, animation, image generation, backgrounds and enemies. [[3D Model Workflow]], [[Animation Kit Review]], [[Asset and Animation Workflow]], [[Backgrounds and Enemies - Mystic Victorian]], ...
- **Game Design and Market** (8): Genre playbooks, competitors, monetization rules, retention, low-end devices. [[Competitors and Policy]], [[Engagement Loop Playbook]], [[Layouts, Placement and Summoning]], [[Low-End Device Playbook]], ...
- **Process and Tools** (3): How we build and test, and tools or skills that speed us up. [[Dev Process Playbook]], [[Workflow Gaps and Game Feel]], [[Workflow Tools and Skills]]
- **Outside examples** (what other developers do, found 2026-10-27): [[Research/UI/Community UI Approaches|UI]], [[Research/VFX and Animation/Community VFX Techniques|VFX]], [[Research/3D and Art/Community 3D Pipelines|3D]], [[Research/Process and Tools/Community Vaults and Workflows|vaults and LLM workflows]]

## Current focus
- Phase: **Polish and content.** Core loop, free placement, familiars, Lampwick Lane, signature cutscenes and ProfileStore saving are built.
- Next: see "Next up" in [[Backlog]] (stage sets 2 to 5, settings panel, more signature cutscenes).

## Recent sessions (older ones in [[Session Log]])
- 2026-10-27 (tools session): Installed 6 third-party skills in .claude/skills plus agent-browser CLI and its Chrome (user approved); ponytail left for the user's /plugin commands. See [[Research/Process and Tools/Workflow Tools and Skills|Workflow Tools and Skills]].
- 2026-10-27 (codex session): Built Roblox Dev/Codex Handoff (7 adapted skills, AGENTS.md snippet, dry-run install-for-codex.ps1, video_scenes.py). Static checks pass; nothing run in Codex, nothing installed. See [[Codex Handoff/README|Codex Handoff]].
- 2026-10-27 (inputs session): Studied the 9 priority reference videos from sampled frames; note [[Research/VFX and Animation/Reference Video Study 2 - Priority Links]] with seven suggested additions. Other 10 videos not studied.
- 2026-10-27 (inputs session): Studied all 19 reference videos and wrote [[Research/VFX and Animation/Beam and Impact VFX Recipes]] (layered beams, impact set, captions); forwarded to the main session.
- 2026-10-27: Audit fixes (ponytail audit): empty rarity now steps down (`MatchSim.pickPet`) + load warnings in Config; cutscene errors restore HUD/stage/grade; `SkipTutorial` throttled per player (1/s); Config fallback table warns when used; removed dead code (pad helpers, adjacency, 7 shape builders, egg alias: about -100 lines); saved server tests `Tests/MatchSim.test.luau` (12 checks, PASS); reference videos untracked (`.gitignore`, staged, not committed); STARFALL rebuilt with layered Beam strikes, a full impact set (ring, shockwave, light column, debris, dust, glow, second detonation) and bracketed captions, checked with a static demo. Not done: saving (needs ProfileStore, awaiting OK), GameClient split, duplicate audio.
- 2026-10-27: Saving added (official ProfileStore, vetted copy in `Vendor/`; 16 headless tests in `Tests/`). Old generic ultimate split out of GameClient into `UltFX`; sigil now paints on first reveal; `record_window.py` keeps JPEG frames (low RAM); duplicate music copy removed from `Audio/Upload/`; skills and Codex hand-off git-ignored. Backup of the pre-split GameClient: `ServerStorage.GameClient_backup` (delete once happy).
