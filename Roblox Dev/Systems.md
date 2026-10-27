# Systems

Every game system, where it lives, and its status.
Status: `idea` → `building` → `testing` → `done`
Design: [[Game Design Doc]]. Patterns: [[Merge Tower Defense Playbook]].

| System | Status | Server / Client | Where in Studio | Notes |
|---|---|---|---|---|
| Config (pets, enemies, waves, crates) | testing (pets, enemies, waves done; crates not) | Shared | ReplicatedStorage.Shared.Config | Data tables feed gameplay and UI |
| Player data saving (ProfileStore) | built | Server | ServerScriptService.MatchService + ProfileStore | Saves level, xp, sp, gems, tree; Studio Play-to-Play reload verified; live-server rejoin not checked |
| Match service (state, grid, economy) | testing (`MatchSim` headless-tested; `MatchService` ran in Play) | Server | ServerScriptService | Pure logic modules, tested headless |
| Merge logic | testing | Server (logic), Client (animation) | Shared.Logic | 3 same -> next tier |
| Enemy sim (data, path distance) | testing | Server | ServerScriptService | No Humanoids; 10 Hz |
| Enemy renderer | testing (4 procedural models, move verified in Play) | Client | StarterPlayerScripts | Interpolates from spawn time and speed |
| Targeting + damage + projectiles | idea | Server (logic), Client (visuals) | | Pooled |
| Skill tree (honeycomb, Skill Points) | testing (19 nodes, server-validated purchases, headless-tested; UI seen in a screenshot) | Server (rules), Client (UI) | Shared.Config.TREE, MatchSim.skill, GameClient | Effects: damage, coins, gems, luck, crystal HP, ult, roll cost, pity, double hatch |
| Ultimates | testing (cinematic: rune circle, orb, lightning, meteors; gather phase seen in a screenshot, release not) | Both | | Server validates charge |
| Bosses (telegraphed abilities) | idea | Both | | |
| Crates / gacha (now: ROLL with gems) | testing (roll, rarity, pity, odds panel, reveal card; headless-tested) | Server roll, Client reveal | | Free currency only; odds panel |
| 3D pets (image-first pipeline) | testing (Frostling and Star Drake meshes live in game since 2026-10-27 via ReplicatedStorage.PetMeshes + Models MESHED table; flat colour; Idle/Attack clips play in Studio only until uploaded; other 6 awaiting the user's review) | Studio | Blender/import_ready | see [[Research/3D and Art/3D Model Workflow]] |
| Pets / models / trainer progression | testing (7 species x 5 tiers build with no errors; XP, levels, luck headless-tested) | Server | | |
| Shop / purchases (premium pets, passes) | idea | Server | | ProcessReceipt, fixed prices |
| UI (HUD, menus, reveal) | testing (in-match HUD restyled dark-fantasy 2026-10-26 with a phone layout; tutorial pointers use the chevron sprite; played tutorial, waves 1 to 6 and the stage 5 boss with no script errors; not played by a human, real phone untested) | Client | StarterPlayerScripts.GameClient | near Luau's 200-local limit: add helpers to the UI table |
| UI Kit (free UI generator: tokens, components, screens, validator) | testing (13 UIScreens2 screens plus the first set, all validated and screenshot-checked in the dark-fantasy Sols skin on 2026-10-26; Lobby HUD has a phone layout, emulated only; art loads from local files, not uploaded) | Client | ReplicatedStorage.UIKit | K.skin = "Sols" forces the theme; sprites in textures/uikit_v5 (bump the folder to bust Studio's texture cache); never run make_chrome.py or build_art.py (they overwrite the dark chrome and ComfyUI icons) |
| Settings (display, accessibility, sound) | idea | Client (apply), Server (validate and save) | StarterPlayerScripts, ReplicatedStorage.Shared | Launch: Music, SFX, Flashes, Particles, Backdrop, Number format. See [[Game Design Doc]] "Display and accessibility settings" |
| Number format (`NumberFormat`) | idea | Shared | ReplicatedStorage.Shared | One function for every number shown; headless test cases listed in the Game Design Doc |
| Animation pass (HUD, enemies, world) | testing (coverage table in [[Research/3D and Art/Asset and Animation Workflow|Asset and Animation Workflow]]) | Client | GameClient | In-engine tweens; Blender clips exist only for the pilot pet |
| Audio (music, sfx) | prototype (uploaded 2026-10-25; Now Playing popup built 2026-10-26) | Client | | Asset licence/availability to verify |
| Merge core and roster | prototype logic (rules tested, difficulty simulated, not wired in) | Shared | `VFX/MergeCore.luau`, `VFX/Roster.luau`, [[Game Redesign - Merge Academy]] | Proposal awaiting the user's answers (section 12) |
| Music | prototype (5 CC0 tracks uploaded 2026-10-25, ids in `VFX/AudioIds.luau`, load and length checked in Edit mode, never listened to) | Client | `Audio/CREDITS.md`, `VFX/MusicFX.luau` | Needs playtest check of `VFXVerify.music()` and moderation status |
| VFX | prototype (standalone, not wired in; loading, reveal ideas, feedback baseline, 23 synthesized sound effects and camera motion blur added and machine-verified 2026-10-25; see VFX Verification Report) | Client | `VFX/RevealFX.luau`, `Research/VFX Renders/` | Reveal tiers Common to Legendary plus a medieval-magic Ultimate; Flashes, Particles and Reduced-motion settings honoured; headless audit passes; needs sound, uploaded textures, your judgement of the motion. 2026-10-26: `AbilityFX` (Verdant Rend) wired to tier 3+ crits; `ImpactFX` (impact frame, scorch, telegraph, smooth shake) wired to ult, boss kill and boss escape |
| Tutorial / onboarding | testing (5 highlighted steps, scripted run reached stage 2; not played by a human) | Client | | |
| Analytics events | idea | Server | | Funnel events |
| Test harness | idea | Studio | | Headless asserts via execute_luau |

## Security rules (apply to every system)
- Never trust the client for currency, rewards, purchases, inventory or cooldowns.
- RemoteEvents: check type, range and rate of every argument on the server.
- Review AI-written Luau before shipping.
- Crate roll, merge, summon, ultimate cast, wave start: all server-decided.

## Details
### Player data saving
- ProfileStore with session locking. Schema: gems, shards, pets {id -> level, owned}, equipped, worldsCleared, dailyState, settings, version.

### Settings
- `settings` table in the profile: musicVolume, sfxVolume, flashes (bool), particles ("low" | "default" | "high"), backdrop ("moving" | "still"), numberFormat ("short" | "grouped" | "scientific"). Allowed values and defaults live in one shared `SettingsDefaults` module used by client UI and server validation.
- Client applies changes immediately and saves debounced through one RemoteEvent. Server checks each key against the allowed values, clamps or rejects anything else, and rate-limits the event.
- Systems that read settings: VFX pool (particle cap), `UIAnimator` (flashes, later reduced motion), `NumberFormat`, lobby backdrop, audio groups.

### Currency
- In-match coins: server only, reset per match. Meta gems/shards: saved.
| Stage backdrop (Lampwick Lane) | testing (built 2026-10-27, checked in Play on PC) | Server | ServerScriptService.Backdrop | Visual only; see [[Research/3D and Art/Backgrounds and Enemies - Mystic Victorian]] |
| Free placement + range display | testing (2026-10-27; headless + Play checks pass) | Shared/Server/Client | Config.canPlace, MatchSim.move, GameClient drag | Bloons-style footprints; max 12 |
| Character registry | testing (2026-10-27; no-code add tested) | Shared | ReplicatedStorage.Characters | see [[How to Add a Character]] |
