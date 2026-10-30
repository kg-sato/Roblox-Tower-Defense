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
| Skill tree (honeycomb, Skill Points) | testing (2026-10-29 v3 look `SkillTreeV3`: tarot cards, hand-placed S-curves, gold-ink; blind review FAIL r3, see [[Research/UI/UI Rework 2026-10-29 Title and Skill Tree]]; 19 nodes, server-validated purchases, headless-tested; 2026-10-28 v2 look `SkillTreeArt`: radial lantern tree, glyph icons, ticking brass watch-track border, clockwork hover popup, click to kindle; seen in Play incl. a purchase; blind review FAIL, see [[Research/UI/Captures 2026-10-28/Grading Report]]) | Server (rules), Client (UI) | Shared.Config.TREE, MatchSim.skill, GameClient | Effects: damage, coins, gems, luck, crystal HP, ult, roll cost, pity, double hatch |
| Ultimates | testing (cinematic: rune circle, orb, lightning, meteors; gather phase seen in a screenshot, release not) | Both | | Server validates charge |
| Bosses (telegraphed abilities) | testing (2026-10-29: server framework built and headless-tested, see the per-stage row below and [[Design/Boss Framework]]; client phase bar and phase banner still open) | Both | Shared.Config, Shared.MatchSim | |
| Crates / gacha (now: ROLL with gems) | testing (roll, rarity, pity, odds panel, reveal card; headless-tested) | Server roll, Client reveal | | Free currency only; odds panel |
| 3D pets (image-first pipeline) | testing (Frostling and Star Drake meshes live in game since 2026-10-27 via ReplicatedStorage.PetMeshes + Models MESHED table; flat colour; Idle/Attack clips play in Studio only until uploaded; other 6 awaiting the user's review) | Studio | Blender/import_ready | see [[Research/3D and Art/3D Model Workflow]] |
| Pets / models / trainer progression | testing (7 species x 5 tiers build with no errors; XP, levels, luck headless-tested) | Server | | |
| Shop / purchases (premium pets, passes) | idea | Server | | ProcessReceipt, fixed prices |
| UI (HUD, menus, reveal) | testing (2026-10-28 refine: `FontPass` house type, loading v4, `StartMenuArt` start menu v2, art ids in `ReplicatedStorage.ArtIds`; blind reviews FAIL; 2026-10-28 rework: ReplicatedFirst loading screen, start menu with featured familiar, Victorian object controls, Trainer Road, skill tree icons and paths; see [[Research/UI/UI Rework 2026-10-28]]; earlier: in-match HUD restyled dark-fantasy 2026-10-26 with a phone layout; tutorial pointers use the chevron sprite; played tutorial, waves 1 to 6 and the stage 5 boss with no script errors; not played by a human, real phone untested) | Client | StarterPlayerScripts.GameClient | near Luau's 200-local limit: add helpers to the UI table |
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
| Test harness | testing (2026-10-29: 16 headless suites in `Tests/`, all PASS in Studio Edit mode, including Boss (31 checks) and NewRoles (27 checks) added after the first 12: ActionArgs, Balance (bots), FamiliarMaterials, Familiars, GameSpeed, LoreFragments, MatchSim, NumberFormat, Rules, ServerRules, SettingsDefaults, StageSets; Python checks in `tools/`) | Studio | Tests/, tools/asset_budget.py, check_familiars_complete.py, check_stages_complete.py, check_sound_lengths.py | Headless asserts via execute_luau; see [[Design/Balance Baseline 2026-10-29]] |
| Economy (ROLL_COST 20, START_GEMS 60) | testing (2026-10-29: tuned so the full bot clears 25 stages in a mean 574 to 605 s; tutorial forces 3 rolls so START_GEMS stays 3 x ROLL_COST) | Shared/Server | Shared.Config | [[Design/Balance Baseline 2026-10-29]] |
| Crow and Thief (new enemies) | testing (2026-10-29: client models, Pace handler `PaceClient` + `EnemyPace`, `NEW_ENEMIES` and `MOVEMENT_EFFECTS` on; seen in Play once) | Both | Shared.Config, StarterPlayerScripts | [[Design/Combat Systems Implemented]] |
| GameClient split (UILib) | built (2026-10-29: UI helper library moved to `StarterPlayerScripts.UILib`; GameClient 199,960 to 173,770 of 200,000 characters; HUD builds identically in Play; panels not opened by a real click) | Client | StarterPlayerScripts.GameClient, UILib | Backup `ServerStorage.GameClient_backup_preUILib`; see [[Session Log]] |
| Chat comms and notify tools | built (`tools/comms.py` for chat-to-chat status files, `tools/notify.py` phone push per milestone) | Tools | tools/, `QUEUE.md` | Milestones in [[Notify Log]] |

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

### Stage, wave and leak rule
- Decision (2026-10-27, covered by `Tests/MatchSim.test.luau`): a wave that leaks still clears and advances the stage and pays the gem bonus at combo 0; the leak resets the streak (after `streakGuard` leaks) and costs crystal HP (none in the tutorial). You cannot lose.
- Crystal HP 0 pushes the run back `OVERRUN_STAGE_LOSS` stages (never below 1), takes `OVERRUN_COIN_LOSS` of coins, resets the streak, heals the crystal. An unkilled boss when its clock ends sends the run back one stage.

### Currency
- In-match coins: server only, reset per match. Meta gems/shards: saved.
| Stage backdrop (Lampwick Lane) | testing (built 2026-10-27, checked in Play on PC) | Server | ServerScriptService.Backdrop | Visual only; see [[Research/3D and Art/Backgrounds and Enemies - Mystic Victorian]] |
| Free placement + range display | testing (2026-10-27; headless + Play checks pass) | Shared/Server/Client | Config.canPlace, MatchSim.move, GameClient drag | Bloons-style footprints; max 12 |
| Character registry | testing (2026-10-27; no-code add tested) | Shared | ReplicatedStorage.Characters | see [[How to Add a Character]] |
| Settings (save, panel, wiring) | testing (2026-10-27 overnight; unit tests + Play clicks) | Shared/Server/Client | Shared.SettingsDefaults, MatchService "Setting", SettingsPanel, GameClient FXK.applySettings | 1 save per second, batch up to 16 keys; flashes, reduced motion, shake, volumes, effects detail, numbers, game speed |
| Game speed 1x/2x | testing (2026-10-27 overnight; headless equal-results test + Play) | Server/Client | MatchService gclock + SettingsDefaults.stepsFor, GameClient FXK.simNow, ProjectileFX.timeScale | cutscene skip not done |
| Effect budget / Low graphics | testing (2026-10-27 overnight; measured in Play) | Client | GameClient burst cap, FXK.budgetEmitter, ProjectileFX.quality, Backdrop LampLight | Low: lamp shadows off, emitter Rate x0.5, secondary layers off |
| NumberFormat | built, tested headless (not used by the HUD yet) | Shared | Shared.NumberFormat | short, grouped, scientific |
| Summon reveal module | refactor (2026-10-27 overnight) | Client | StarterPlayerScripts.RevealSection | split from GameClient; backup in ServerStorage.GameClient_backup_T14 |
| Familiar roster (20 familiars: data, lore, cards; 4 Epic and Legendary humans added 2026-10-29, see [[Design/Human Familiars]]) | testing (2026-10-29; `Shared.Familiars` generated by `tools/gen_familiars_luau.py`, 30 checks pass) | Shared | ReplicatedStorage.Shared.Familiars, Config.FAMILIARS | Roles (one verb each) are NOT in code; see [[Design/Character Bible Index]] |
| Familiar models, rigs and clips | testing (uploaded and load; the four Mythic and Celestial and four Epic and Legendary humans have Idle, Walk, Attack, Hit and Death uploaded as Animation assets and wired (ids in `VFX/ASSETS.md`; Hit and Death not called by the client yet); the older familiars' clips are still Studio-only KeyframeSequences; rig deformation unseen in Roblox) | Client | ReplicatedStorage.Characters, Shared.FamiliarClips | See [[Design/Upload Plan]], [[Known Issues]] |
| Collection screen (FAMILIARS) | testing (built 2026-10-29, hidden while the start menu shows) | Client | StarterPlayerScripts.CollectionScreen | Not played by a human |
| Enemy and boss models | prototype (11 concept models uploaded and load, none placed in a stage) | Client | not placed | [[Design/Enemy Models]], [[Design/Enemy Bible]], [[Design/Boss Designs]] (designs only) |
| Bosses (per-stage designs, phases) | testing (2026-10-29: `Config.BOSSES` five bosses x three phases, effects deny, freeze, summon, slow aura, regen, speed, damage; 31 checks in `Tests/Boss.test.luau`; boss hp mults eased (Regent 1.3, Clockmaker 1.2) so the full bot clears 12 of 12 seeds; per-boss specials and client phase bar not built) | Both | Shared.Config, Shared.MatchSim | [[Design/Boss Framework]], [[Design/Boss Designs]] |
| Stage set 5 (Above the Grey Veil) | testing (installed 2026-10-29: backdrop script `BackdropVeil`, `StageSets` entry, `veil` music state; seen in Play once) | Server | StageSets, ServerScriptService.BackdropVeil | [[Design/Stage Set 5 Plan]] |

## Overnight additions 2026-10-29 to 10-30
Status words: `built`, `flagged off`, `unverified look`. Source: `Overnight/LEDGER.md`. These rows extend the table above; the Bosses and GameClient split rows above are superseded by the rows here.

| System | Status | Server / Client | Where | Notes |
|---|---|---|---|---|
| Difficulty modes, pause/resume, collection shards (T004, T006, T186) | built, headless-tested; client UI not built | Server | Shared.Rules, MatchService actions | Evidence T004, T006, T186; 33 of 33 suites PASS |
| Faction combos, lantern power, elite/wave modifiers (T012, T011, T015) | built, flagged off (`Config.SYNERGIES`, `WAVES_V2` false) | Shared/Server | Shared.Config, MatchSim, MatchService Lantern | Headless-tested; no client UI |
| Day-night/weather, hollow enemies, endless mode (T009, T417, T016) | built, flagged off (`SKY_ON`, `HOLLOW_ENEMIES`, `ENDLESS` false) | Shared/Client | StageSets.sky, Config.SKY_EFFECTS | Client has no hollow enemy models |
| Path shapes, placement rules, path blockers, balance data modules (T167, T177, T157, T199) | built as data; `MAP_RULES` and `PATH_BLOCKERS` flagged off; `Shared.Data` holds 10 modules | Shared | StageSets, Config, Shared.Data | Per-set lane shapes not yet driving the board |
| Achievements, Quests, Bond, LeaderboardRules (T002, T023, T007, T025, T652) | built, hooked into MatchService via `ProgressHooks`, flagged off (`ACHIEVEMENTS_ON`, `QUESTS_ON`, `BOND_ON`, `LEADERBOARD_ON`); no client UI; leaderboard has no DataStore write | Server | Shared.*, MatchService | Lean bot and suites unchanged |
| Gacha P3 roll floor, P2 Lantern Oil chosen guarantee, P7 dupe bond (2026-10-30) | written, flags off (`P3_ROLL_FLOOR`, `P2_CHOSEN_GUARANTEE`, `P7_DUPE_BOND`); suites written, NOT yet run in Studio | Server (data fields and `Guarantee` action for the Summon menu) | Shared.Gacha, Shared.Bond, MatchSim, MatchService | [[Design/Summon Server API]] |
| Boss mechanics v2 (T416) and boss client (T149, T148, T172) | built; `BOSS_V2`, `BOSS_UNMERGE` flagged off; BossBar, BossFx, five BossArena variants; unverified look | Both | Shared.Config, BossBar, BossFx, BossArena | Boss fight reached stage 5 clear in Play (T650) |
| Enemy telegraphs, float text, placement hint, status icons (T138, T194, T178, T139, T641) | built, alive in Play (T651); unverified look | Client | EnemyTelegraph, FloatText, PlacementHint, EnemyBars, StatusIcons | H key clashes with HideUI (Bug Log) |
| FX layers: familiar shots, merge tiers, lantern light, enemy family FX, ult flourish (T133, T135, T144, T134, T601, T602) | built, alive in Play (T651); unverified look | Client | FamiliarShots, MergeTierFX, LanternFX, EnemyFamilyFX, UltFlourish, FXScale | Reduced motion scales hit-stop and shake |
| TextAnim, Dialogs, Toasts, Tooltips, Strings, NavFocus (T188, T607, T098, T085, T087, T086, T084) | built; unverified look | Client/Shared | TextAnim, Dialogs, Toasts, Tooltips, Strings, UIMotion | UIChecks suite (T235) |
| Screens and ScreenRouter (T090-T093, T074, T095, T097, T642, T081) | built, router and menu dock added; results screen flagged off (`RESULTS_SCREEN`); unverified look | Client | InventoryScreen, QuestScreen, PassScreen, ShopScreen, BoardScreen, StageSelect, ResultsScreen, PauseMenu, ScreenRouter | Shop/pass display only. HUD, collection and results failed blind review (T640, all items under 7) |
| Sound cues, ambience, music per set, mix sliders (T630, T604, T603, T155, T166, T160, T605, T606) | built; ear unverified; moderation of uploaded ids not checked | Client | SoundCues, AmbienceClient, SoundFX, SettingsDefaults | Sound cap bug fixed (T606) |
| Enemy models: rigs and texture sets (T142, T124) | built, rigs and textures made; not placed in stages | Client | Blender/, Assets | Look unverified |
| GameClient split (T198) | built | Client | StarterPlayerScripts.GC* | About 142,000 of 200,000 chars, nine GC* modules |
