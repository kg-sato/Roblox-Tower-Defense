# Overnight BOARD (draft, 2026-10-29, triage of `Overnight/TODO.md`; nothing armed)
Sources read: TODO.md (163 open lines), PROGRESS.md, REPORT.md, POLICY.md, denials.log, Backlog, Bug Log, Known Issues, Systems, Session Log (tail), QUEUE.md, Boss Framework, Human Familiars, Combat Systems Implemented, Next Night Plan, Pinterest Batch 1, User Inputs, `Roblox Dev/Planning/Overnight Task Log.md`, git log. Not read: `Overnight/archive/*` (UNVERIFIED that nothing there is still wanted).
**Id rule.** TODO line ids repeat (21 ids appear twice: T138-T142, T148, T149, T152, T153, T157, T159, T162-T166, T183, T187, T190, T193, T197) and also clash with finished ids in the Overnight Task Log (T002, T183, T187, T190, T193...). Board ids keep the TODO id; the SECOND occurrence in TODO.md gets a `b` suffix (effects/audio/text-animation blocks). Evidence files go to `Overnight/evidence/B-<id>.txt` (never `T###.txt`, those names are taken). Any board id below that equals a Task Log id means a different task. New ids: T400 up.
`needs: Studio` = the Studio MCP session; one holder at a time (QUEUE.md). Headless suites run in Studio Edit mode, so every test task also needs Studio unless it is a Python check.

# 1. Already done or obsolete (do NOT redo)
Format: `T### | reason | evidence`
- T187 | boss attacks as data exist (Config.BOSSES, 3 phases, effect vocabulary, 31 checks) | Design/Boss Framework.md, Tests/Boss.test.luau, Session Log 2026-10-29 (telegraph/feedback part moved to T149 and T138)
- T190 | economy checked over 25 stages by bots; "simulator tool" not needed | Tests/Balance.test.luau, Design/Balance Baseline 2026-10-29.md, Task Log T190/T191/T192
- T238 | 3 bot runs per set already logged (12 seeds, 25 stages, mean 570 s) | Design/Balance Baseline 2026-10-29.md, Session Log "full bot clears 12 of 12 seeds"
- T013 | armour and damage types implemented and tested | Design/Combat Systems Implemented.md, Tests/Combat.test.luau (Task Log T213)
- T028 | reveal pacing research exists | Task Log T016 (gacha pacing), T041 (Hearthstone reveal)
- T030 | skill-tree UX research exists; tree itself is OFF LIMITS | Task Log T018, Pinterest Batch 1 note
- T052 | loading/title research exists | Task Log T019, Pinterest Batch 1 note section 12 (title entity decided)
- T053 | monetisation research exists | Task Log T027, Design/Content Plans.md (battle pass), Progression Rules.md
- T054 | accessibility research exists | Task Log T024
- T082 | font pass shipped (Beyond Wonderland + Fondamento + Accanthis) | Session Log 2026-10-28 UI refine, Studio_Export/FontPass.luau (14 px floor is checked in T235)
- T083 | UI colour tokens exist, game is dark gold-ink only | Studio_Export/UITheme.luau, UI Kit README (light theme not wanted: UNVERIFIED, no user note either way)
- T192 | rolling coin/gem counters shipped | Session Log 2026-10-28 (cont.) "rolling coin/gem counters"; wave-number count-up not confirmed (UNVERIFIED)

## Merged duplicates (the task survives under the id on the right; nothing is dropped)
- T141,T140,T136,T147,T151,T152b,T153b -> T134 | T137 -> T148 | T100 -> T149 | T139b -> T139 | T146,T180,T181 -> T152
- T163,T165 -> T153 / T162 | T159,T170 -> T157 | T168,T169,T171,T179 -> T167 | T173-T176 -> T172 | T178 stays own task | T182 -> T177
- T193 -> T012 | T008 -> T007 | T010 -> T009 | T014 -> T015 | T125,T126 -> T124 | T061 -> T092 | T094 -> T093 | T096 -> T095
- T029,T055,T056 -> T027 | T077,T078 -> T076 | T088,T089,T099 -> T098 | T101,T102,T234 -> T235 | T103,T166b,T183b -> T162b | T196b -> T085
- T233 -> T087 | T189,T197b -> T188 | T191,T193b,T195 -> T190b | T201 -> T200 | T206 -> T205 | T141b,T154 -> T133 | T143 -> T140b
- T142b,T145,T148b,T149b,T150 -> T144 | T156,T159b -> T155 | T158,T184 -> T157b | T161 -> T160 | T164b -> T163b | T165b -> T166
OFF LIMITS (other chats, QUEUE.md; not on the board): T059, T079 (skill tree), T060, T080 (title screen), T197 (40-node skill tree), T003 (tutorial: IntroTour is owned by ui-rework), loading finale and clock.

# 2. Open board (actionable)
Verify types: `test:` = suite in Tests/ run via Tests/RunAll in Studio Edit; `py:` = python command; `studio:` = Play/Edit evidence file; `manual:` = evidence file only (look stays UNVERIFIED).

## Lane sim (sim-and-balance)
- [ ] T413 | Delete stale duplicate MatchSim and stray _GameSpeedTest folder | verify: studio: only one MatchSim in ReplicatedStorage.Shared, RunAll 16 of 16 PASS
  lane: docs-tooling | needs: Studio | depends: none | size: S | owner-files: ReplicatedStorage.Shared (delete only the stale 694-line MatchSim), ReplicatedStorage._GameSpeedTest
- [ ] T411 | Save bestStage and stage progress in profile with migration | verify: test: Tests/SaveMigration.test.luau (new cases)
  lane: sim | needs: Studio | depends: none | size: S | owner-files: Shared.Config, ServerScriptService.MatchService (profile), Tests/SaveMigration.test.luau
- [ ] T004 | Difficulty modes Normal and Hard, server-decided, labelled in data | verify: test: Tests/Rules.test.luau (new cases) and Balance still clears
  lane: sim | needs: Studio | depends: T411 | size: M | owner-files: Shared.Config, Shared.MatchSim, MatchService, Tests/Rules.test.luau
- [ ] T005 | Add 3x game speed, same results per sim second | verify: test: Tests/GameSpeed.test.luau
  lane: sim | needs: Studio | depends: none | size: S | owner-files: Shared.SettingsDefaults, MatchService gclock, Tests/GameSpeed.test.luau
- [ ] T006 | Pause and resume saved per run | verify: test: Tests/ServerRules.test.luau (new cases)
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.MatchSim, MatchService, Tests/ServerRules.test.luau
- [ ] T185 | Roster slot unlock rules (when a new slot opens) in data | verify: test: Tests/Rules.test.luau
  lane: sim | needs: Studio | depends: none | size: S | owner-files: Shared.Config, Tests/Rules.test.luau
- [ ] T186 | Collection schema: duplicates and shards, wired to the profile | verify: test: Tests/SaveMigration.test.luau
  lane: sim | needs: Studio | depends: T411 | size: M | owner-files: MatchService, Shared.Config, Tests/SaveMigration.test.luau
- [ ] T002 | Achievements: server unlock logic for the 30 designed ones | verify: test: Tests/Achievements.test.luau (new)
  lane: sim | needs: Studio | depends: T411 | size: M | owner-files: Shared.Achievements (new), MatchService, Tests/Achievements.test.luau
- [ ] T023 | Quests: server logic and data for the 20 designed quests | verify: test: Tests/Quests.test.luau (new)
  lane: sim | needs: Studio | depends: T411 | size: M | owner-files: Shared.Quests (new), MatchService, Tests/Quests.test.luau
- [ ] T007 | Familiar bond levels from use, plus mood state, as data | verify: test: Tests/Bond.test.luau (new)
  lane: sim | needs: Studio | depends: T186 | size: M | owner-files: Shared.Bond (new), MatchService, Tests/Bond.test.luau
- [ ] T012 | Faction adjacency combo driven by a synergy data table | verify: test: Tests/Combo.test.luau (new)
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.Synergies (new), Shared.MatchSim, Tests/Combo.test.luau
- [ ] T011 | Lantern power: player light buffs nearby familiars, cooldown | verify: test: Tests/Lantern.test.luau (new)
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.MatchSim, Shared.Config, Tests/Lantern.test.luau
- [ ] T015 | Elite enemies and ten wave modifiers as data | verify: test: Tests/Waves.test.luau (new)
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.Config, Shared.MatchSim, Tests/Waves.test.luau
- [ ] T009 | Per-set day/night window and weather events as data | verify: test: Tests/Env.test.luau (new)
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.StageSets (data fields only), Shared.MatchSim, Tests/Env.test.luau
- [ ] T016 | Endless mode after stage 25, tested to wave 100 | verify: test: Tests/Endless.test.luau (new)
  lane: sim | needs: Studio | depends: T015 | size: M | owner-files: Shared.MatchSim, Shared.Config, Tests/Endless.test.luau
- [ ] T019 | Sell and recycle refund percent per tier | verify: test: Tests/Rules.test.luau
  lane: sim | needs: Studio | depends: none | size: S | owner-files: Shared.Config, Shared.MatchSim, Tests/Rules.test.luau
- [ ] T025 | Weekly leaderboard server validation and anti-cheat checks | verify: test: Tests/Leaderboard.test.luau (new, pure validation; live OrderedDataStore UNVERIFIED in Studio)
  lane: sim | needs: Studio | depends: T411 | size: M | owner-files: Shared.LeaderboardRules (new), MatchService, Tests/Leaderboard.test.luau
- [ ] T416 | Remaining boss mechanics: Automaton lamp, Echo pushes, Regent candles, un-merge | verify: test: Tests/Boss.test.luau (new cases)
  lane: sim | needs: Studio | depends: none | size: L | owner-files: Shared.Config.BOSSES, Shared.MatchSim bossTick, Tests/Boss.test.luau
- [ ] T417 | Hollow Parishioner enemy and Fog Wisp lamp-eating in the sim | verify: test: Tests/Combat.test.luau (new cases), Balance still clears
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.Config enemies, Shared.MatchSim, Tests/Combat.test.luau
- [ ] T167 | Per-set path shapes as data with a curvature test | verify: test: Tests/StageSets.test.luau (new curvature cases), py: tools/check_stages_complete.py
  lane: sim | needs: Studio | depends: none | size: L | owner-files: Shared.Path, Shared.Config path data, Shared.StageSets (path field), Tests/StageSets.test.luau
- [ ] T157 | Path blockers and mid-path gates as data, tested in MatchSim | verify: test: Tests/MatchSim.test.luau (new cases)
  lane: sim | needs: Studio | depends: T167 | size: L | owner-files: Shared.MatchSim, Shared.Config, Tests/MatchSim.test.luau
- [ ] T177 | Placement rules per map, decorations never block, tested | verify: test: Tests/Rules.test.luau (placement cases)
  lane: sim | needs: Studio | depends: T167 | size: M | owner-files: Shared.Config canPlace, Tests/Rules.test.luau
- [ ] T199 | Move balance numbers into data modules, one table per system | verify: test: RunAll all suites PASS, outputs unchanged
  lane: sim | needs: Studio | depends: T004,T015,T016,T019 | size: L | owner-files: Shared.Config (split into Shared.Data.*), all Tests/*.test.luau requires

## Lane client-core (GameClient family; HELD by ui-rework per QUEUE.md: claim first, minimal hooks)
- [ ] T198 | Split GameClient below 150,000 characters into modules | verify: test: RunAll PASS plus studio: Play shows HUD identical, script size in evidence
  lane: client-core | needs: Studio | depends: QUEUE release of GameClient | size: L | owner-files: StarterPlayerScripts.GameClient, new modules next to UILib (OnClientEvent handler, killEnemy, sealButton/hideIcon, RenderStepped loop), Studio_Export/GameClient.luau
- [ ] T149 | Client boss phase bar, banner per phase, deny and freeze feedback | verify: studio: BossPhase and BossFx events drive bar ticks and banner in a Play run to stage 5 boss; console clean
  lane: client-core | needs: Studio | depends: T198 | size: M | owner-files: StarterPlayerScripts.BossBar (new), GameClient (one hook)
- [ ] T139 | Enemy health bars and status icons readable at the board camera | verify: studio: capture plus contrast numbers for burn, chill, stun, mark, hush
  lane: client-core | needs: Studio | depends: T198 | size: M | owner-files: GameClient enemy renderer or new EnemyBars module, Models.luau (bar only)
- [ ] T138 | Enemy telegraphs one second before Sentinel plant, Crow perch, Thief steal | verify: studio: telegraph fires 1 s before each special in a scripted wave
  lane: client-core | needs: Studio | depends: T198 | size: M | owner-files: new EnemyTelegraph module, GameClient (one hook), Shared.MatchSim events (read only)
- [ ] T194 | Damage float text with per-family colour, obeys damage setting | verify: studio: float text colours per family, setting off hides them
  lane: client-core | needs: Studio | depends: T198,T188 | size: S | owner-files: FeedbackFX, GameClient (one hook)
- [ ] T178 | Placement heat map hint toggle, good tiles per family | verify: studio: toggle shows tiles on stage 1, console clean
  lane: client-core | needs: Studio | depends: T177,T198 | size: S | owner-files: new PlacementHint module, GameClient (one hook)

## Lane client-ui (new standalone modules only; never the OFF LIMITS files)
- [ ] T188 | TextAnim module: typewriter, drop, wave, shake, reduced motion, off/subtle/full | verify: test: Tests/TextAnim.test.luau (new)
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: Shared.TextAnim (new), Shared.SettingsDefaults (new key), Tests/TextAnim.test.luau
- [ ] T190b | Apply TextAnim to captions, lore reveals, headings and boss name | verify: studio: captions typewrite in a Play cutscene, static when reduced motion is on
  lane: client-ui | needs: Studio | depends: T188 | size: M | owner-files: StageCaptions, CutsceneDirector (claim from cutscene owner), RevealSection
- [ ] T098 | Shared confirm dialog, toast queue, error and empty states | verify: studio: each state shown in Edit/Play with UIKit validator 0 problems
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: StarterPlayerScripts.Dialogs (new), Toasts (new)
- [ ] T085 | Tooltip system on every icon and stat, hover and long press | verify: studio: tooltip appears on hover and long press for 5 icons
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: StarterPlayerScripts.Tooltips (new)
- [ ] T084 | Button states idle, hover, pressed, disabled with motion | verify: studio: state screenshots from one button kit
  lane: client-ui | needs: Studio | depends: T162b | size: M | owner-files: UIMotion, UIKit button component (not the off-limits skins)
- [ ] T086 | Keyboard and gamepad focus for HUD and main screens | verify: studio: NextSelection path reaches every button in HUD and settings
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: NavFocus
- [ ] T087 | Strings table for items, enemies, familiars with coverage test | verify: test: Tests/Strings.test.luau (new, every id has a key)
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: Shared.Strings (new), Tests/Strings.test.luau
- [ ] T235 | UI checks: text at least 14 px at 844x390, contrast 4.5:1, labelled buttons | verify: test: Tests/UIChecks.test.luau (new, run in Play)
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: Tests/UIChecks.test.luau (read-only on UI)
- [ ] T074 | Results screen: wave, gold, lore line, next-step button | verify: studio: shown after a stage clear in Play, validator 0 problems
  lane: client-ui | needs: Studio | depends: T098 | size: M | owner-files: StarterPlayerScripts.ResultsScreen (new)
- [ ] T075 | Settings: add Controls group (keys, hide-UI) | verify: studio: group visible, values persist after rejoin
  lane: client-ui | needs: Studio | depends: none | size: S | owner-files: SettingsPanel, Shared.SettingsDefaults
- [ ] T057 | Reveal for Mythic and Celestial: own sigil and lore line | verify: studio: RevealFX.play for both, no TIER_ALIAS fallback, console clean
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: RevealSection, RevealFX (TIER_ALIAS), FXRecipes (ORDER/RAMP)
- [ ] T058 | Collection: faction filter, 20 cards reviewed, silhouettes for unowned | verify: studio: 20 cells, filter works in Play
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: CollectionScreen, FamiliarArt (claim from Sonnet)
- [ ] T095 | Familiar detail panel with lore, stats, bond, mood, evolve preview | verify: studio: panel opens for 3 familiars
  lane: client-ui | needs: Studio | depends: T007 | size: M | owner-files: StarterPlayerScripts.FamiliarPanel (new)
- [ ] T097 | Pause menu: resume, speed, settings, quit with confirm | verify: studio: pause then resume keeps run state
  lane: client-ui | needs: Studio | depends: T006,T098 | size: M | owner-files: StarterPlayerScripts.PauseMenu (new)
- [ ] T090 | Inventory screen: silhouette grid, tier stars, empty-slot lore | verify: studio: validator 0 problems, capture
  lane: client-ui | needs: Studio | depends: T185,T098 | size: M | owner-files: StarterPlayerScripts.InventoryScreen (new)
- [ ] T091 | Quest screen with one pinned tracker line in the HUD | verify: studio: tracker shows, collapses
  lane: client-ui | needs: Studio | depends: T023,T098 | size: M | owner-files: StarterPlayerScripts.QuestScreen (new)
- [ ] T092 | Battle pass and shop screens, cosmetic only, no live purchases | verify: studio: screens validate; no ProcessReceipt code path added
  lane: client-ui | needs: Studio | depends: T098 | size: M | owner-files: StarterPlayerScripts.PassScreen, ShopScreen (new)
- [ ] T093 | Leaderboard and stage-select screens | verify: studio: both open in Play with fake rows
  lane: client-ui | needs: Studio | depends: T025,T098 | size: M | owner-files: StarterPlayerScripts.BoardScreen, StageSelect (new)
- [ ] T081 | One-style icon set for status, currency, rarity, faction | verify: py: contact sheet in UI Kit/art/icons_set/, 40 files with alpha
  lane: client-ui | needs: ComfyUI | depends: none | size: M | owner-files: UI Kit/art/icons_set/ (new), VFX/ASSETS.md (append)
- [ ] T076 | Harsh Grading pass on HUD, reveal and collection | verify: manual: reviewer subagent scores 7 of 10 or fixes logged
  lane: client-ui | needs: Studio | depends: T057,T058,T074 | size: M | owner-files: Roblox Dev/Research/UI/Captures (notes only)

## Lane chars (characters-and-models)
- [ ] T142 | Rig and animate six enemy models: walk, hit, death; place in a stage | verify: py: tools/verify_enemy_model.py, studio: walk loop plays in Play
  lane: chars | needs: Blender | depends: none | size: L | owner-files: Blender/* enemy scripts, Blender/out/, Roblox Dev/Assets/3D/Enemies, Models.luau (enemy clips)
- [ ] T124 | 512 px texture sets for enemies, bosses and stage props | verify: py: tools/texture_maps.py report, tools/asset_budget.py PASS
  lane: chars | needs: Blender | depends: none | size: M | owner-files: tools/texture_maps.py, Roblox Dev/Assets/3D/Textures
- [ ] T409 | Wire 512 px maps into SurfaceAppearance, check in Play | verify: studio: maps load, capture of 3 familiars
  lane: chars | needs: Studio | depends: T124 | size: M | owner-files: ReplicatedStorage.Characters, FamiliarMaterials
- [ ] T407 | Clean blotchy first-pass textures on the 12 original familiars | verify: py: tools/verify_textured_models.py PASS plus contact sheet
  lane: chars | needs: Blender | depends: none | size: M | owner-files: Blender/tex_in, Blender/out, tools/prep_texture_inputs.py
- [ ] T404 | Idle, Hit, Death clips for the 12 original familiars | verify: studio: tracks load with correct lengths, Tests/Familiars.test.luau PASS
  lane: chars | needs: Studio | depends: none | size: M | owner-files: Shared.FamiliarClips, Characters/<id>/Animations
- [ ] T405 | Upload original familiars' clips as Animation assets and wire ids | verify: py: tools/uploads.json lists ids, studio: tracks load from ids
  lane: chars | needs: Studio | depends: T404 | size: M | owner-files: tools/upload_asset.py, tools/uploads.json, VFX/ASSETS.md (append), Characters/<id>/Animations
- [ ] T403 | Play Idle, Hit, Death clips of the human familiars on the board | verify: studio: Play capture frames show pose changes on hit and banish
  lane: chars | needs: Studio | depends: none | size: M | owner-files: Models.luau (playClip use), Shared.FamiliarClips
- [ ] T406 | Verify rig deformation visually in Roblox for all 20 familiars | verify: studio: screen_capture per archetype, bone data and capture saved
  lane: chars | needs: Studio | depends: none | size: M | owner-files: Overnight/captures only

## Lane world (world-and-stages)
- [ ] T153 | Play-verify stage sets 4 and 5: stages 16 and 21, edge rings, console clean | verify: studio: evidence with captures at stages 16 and 21, Bug Log #10 closed
  lane: world | needs: Studio | depends: none | size: M | owner-files: Backdrop*.luau, Shared.StageSets entries 4 and 5, BackdropFoundry, BackdropVeil
- [ ] T162 | Three distinct landmarks per set visible from the board camera | verify: studio: five captures, one per set, landmarks listed
  lane: world | needs: Studio | depends: T153 | size: M | owner-files: Backdrop*.luau, MapBuilder
- [ ] T164 | Weather and fog per set, tested for frame cost on Low | verify: studio: frame-time numbers Low vs Default per set
  lane: world | needs: Studio | depends: T153 | size: M | owner-files: Backdrop*.luau, Shared.StageSets lighting fields
- [ ] T152 | Spawn and exit gate per set with opening animation and enemy shadow | verify: studio: gate opens before spawn, capture per set
  lane: world | needs: Studio | depends: T153 | size: M | owner-files: MapBuilder gate parts, Backdrop*.luau
- [ ] T172 | Five boss arena variants of the board | verify: studio: each arena loads at its boss stage, path unchanged
  lane: world | needs: Studio | depends: T149,T167 | size: L | owner-files: StageSetClient (claim), Backdrop*.luau

## Lane fx-audio (effects-and-audio)
- [ ] T187b | Fix SoundFX cap so a lower priority never stops a higher | verify: test: Tests/SoundCap.test.luau (new, 8 voices at priority 3 then priority 2)
  lane: fx-audio | needs: Studio | depends: none | size: S | owner-files: SoundFX, Tests/SoundCap.test.luau
- [ ] T148 | Boss phase transition: visual change, sound and cut per phase | verify: studio: three phases of one boss captured with sound events logged
  lane: fx-audio | needs: Studio | depends: T149 | size: M | owner-files: CutsceneFX, BossFx module (new), SoundCatalog entries
- [ ] T134 | Hit and death reactions and effects per enemy family | verify: studio: six families, each hit and death captured, emitters under the burst cap
  lane: fx-audio | needs: Studio | depends: T142 | size: L | owner-files: ImpactFX, ProjectileFX hit part, VFX/*.luau (new recipes)
- [ ] T133 | Attack, trail and star effects per familiar (20) | verify: studio: contact sheet of all 20 attacks, burst cap respected
  lane: fx-audio | needs: Studio | depends: none | size: L | owner-files: ProjectileFX, FXRecipes
- [ ] T138b | Ultimate effect per familiar with a camera move | verify: studio: each ultimate runs to cleanup, no leftover parts
  lane: fx-audio | needs: Studio | depends: T133 | size: L | owner-files: UltFX, CutsceneFX
- [ ] T135 | Merge effect and look per tier 1 to 8, incl. morph cut | verify: studio: tier-up captured for 1 to 8
  lane: fx-audio | needs: Studio | depends: none | size: M | owner-files: FXRecipes (merge), TDFeedback, FamiliarMaterials (tier looks)
- [ ] T140b | Hit-stop, shake and camera nudge scaled, off with reduced motion | verify: test: Tests/FXScale.test.luau (new, setting off yields zero)
  lane: fx-audio | needs: Studio | depends: none | size: M | owner-files: FXRecipes, ImpactFX, Tests/FXScale.test.luau
- [ ] T144 | One lantern-light language: spawn sparkle, level column, clear ash, low-lantern vignette, decals | verify: studio: captures per effect, performance on Low
  lane: fx-audio | needs: Studio | depends: none | size: L | owner-files: FeedbackFX, FlipbookFX registry, VFX/flipbooks
- [ ] T155 | Familiar cues: placement, merge tiers 1 to 8, reveal per rarity | verify: py: tools/check_sound_lengths.py PASS, studio: cues logged in a Play run
  lane: fx-audio | needs: Studio | depends: T187b | size: M | owner-files: SoundCatalog, SoundFX call sites via SoundCues (new), VFX/sfx
- [ ] T157b | Enemy footsteps and hits, boss intro per boss, trainer footsteps | verify: py: tools/check_sound_lengths.py PASS, studio: cue log
  lane: fx-audio | needs: Studio | depends: T187b | size: M | owner-files: SoundCatalog, VFX/sfx
- [ ] T162b | UI sound set: click, hover, error, buy, quest, achievement, level-up | verify: py: tools/check_sound_lengths.py PASS
  lane: fx-audio | needs: Studio | depends: T187b | size: M | owner-files: SoundCatalog, VFX/sfx
- [ ] T163b | Sound mix sliders (master, music, effects, UI) and ducking | verify: test: Tests/SettingsDefaults.test.luau (new keys), studio: duck on reveal
  lane: fx-audio | needs: Studio | depends: T162b | size: M | owner-files: SoundFX, Shared.SettingsDefaults (claim from client-ui)
- [ ] T160 | Music per set (5, crossfade) plus tension layer by wave | verify: studio: states for sets 1 to 5 load, crossfade logged
  lane: fx-audio | needs: Studio | depends: none | size: M | owner-files: MusicFX, MusicCatalog, AudioIds
- [ ] T166 | Ambient loops per set and lobby, plus sounds for captions and set morph | verify: py: tools/check_sound_lengths.py PASS, studio: loops start per set
  lane: fx-audio | needs: Studio | depends: T153 | size: M | owner-files: MusicFX ambience states, SoundCatalog

## Lane docs-tooling (docs, vault, tooling, content)
- [ ] T232 | Stage completeness check passes for all 25 stages | verify: py: python tools/check_stages_complete.py
  lane: docs-tooling | needs: none | depends: none | size: S | owner-files: Studio_Export/StageCaptions.luau, tools/gen_stage_captions.py
- [ ] T422 | Lore, cards, voice lines complete for all 20 familiars | verify: py: python tools/check_familiars_complete.py
  lane: docs-tooling | needs: none | depends: none | size: S | owner-files: Roblox Dev/Lore/*, tools/voice_lines.py
- [ ] T414 | Confirm Bug #4 Ward MetalnessMap is fixed and fix the Bug Log row | verify: studio: Play console has no asset-type error; Bug Log updated
  lane: docs-tooling | needs: Studio | depends: none | size: S | owner-files: Roblox Dev/Bug Log.md
- [ ] T200 | Strict typing on pure modules and zero type errors on all modules | verify: test: type-check output saved, RunAll PASS (checker availability UNVERIFIED)
  lane: docs-tooling | needs: Studio | depends: T199 | size: L | owner-files: Shared.NumberFormat, SettingsDefaults, StageSets, MatchSim helpers
- [ ] T205 | Memory after 10 waves per set and frame-time probe Low/Default/High | verify: studio: numbers table in evidence
  lane: docs-tooling | needs: Studio | depends: T153 | size: M | owner-files: tools/perf_probe.luau (new)
- [ ] T027 | UI research boards for HUD, collection, results plus HUD wireframe | verify: manual: note in Research/UI with 5 cited sources per board
  lane: docs-tooling | needs: none | depends: none | size: M | owner-files: Roblox Dev/Research/UI/ (new notes)
- [ ] T424 | Refresh Systems.md, Backlog and Design Doc for bosses, 20 familiars, set 5 | verify: py: grep shows no "idea" for Bosses and Stage set 5 rows
  lane: docs-tooling | needs: none | depends: none | size: S | owner-files: Roblox Dev/Systems.md, Backlog.md, Design/Game Design Doc.md
- [ ] T246 | Write tonight's report: built, to judge, to delete | verify: manual: Overnight/REPORT.md updated with labels
  lane: docs-tooling | needs: none | depends: all lanes done | size: S | owner-files: Overnight/REPORT.md, Roblox Dev/Session Log.md (append)

# 3. Lanes (file ownership; two workers never share a file)
Shared append-only files (any lane, append lines only): VFX/ASSETS.md, Roblox Dev/Session Log.md, QUEUE.md own section.
- **sim** (sim-and-balance). Owns Shared.Config, Shared.MatchSim, Shared.Path, Shared.StageSets data fields, Shared.* new rule modules, MatchService, `Tests/*.test.luau`, `Studio_Export` mirrors of those. Note QUEUE.md lists Sonnet as owner of Config/MatchService/Familiars: CLAIM first. Order: T413, T411, T005, T185, T019, T004, T006, T186, T012, T011, T015, T009, T417, T416, T002, T023, T007, T025, T016, T167, T177, T157, T199.
- **client-core**. Owns GameClient and new modules hooked into it. GameClient is HELD by ui-rework (QUEUE.md): start only after release, one claim per task. Order: T198, T149, T139, T138, T194, T178.
- **client-ui** (new modules only). Owns new screens and shared UI modules (names above), NavFocus, SettingsPanel, RevealSection, CollectionScreen (claim from Sonnet). Order: T188, T098, T085, T087, T235, T075, T057, T058, T074, T086, T084, T190b, T095, T097, T090, T091, T092, T093, T081, T076.
- **chars** (characters-and-models). Owns Blender/*, Hunyuan3D/*, ReplicatedStorage.Characters, Shared.FamiliarClips, FamiliarMaterials, Models.luau, Roblox Dev/Assets/3D, tools/upload_asset.py. GPU and ComfyUI by QUEUE claim. Order: T403, T404, T406, T124, T142, T409, T407, T405.
- **world** (world-and-stages). Owns MapBuilder, Backdrop*.luau, StageSetClient, BackdropVeil, Shared.StageSets lighting fields (path data belongs to sim). Order: T153, T162, T164, T152, T172.
- **fx-audio**. Owns VFX/*, ProjectileFX, FXRecipes, ImpactFX, FeedbackFX, UltFX, CutsceneFX, SoundFX, SoundCatalog, MusicFX/MusicCatalog/AudioIds, VFX/sfx, VFX/flipbooks. Order: T187b, T162b, T155, T157b, T160, T140b, T133, T135, T148, T134, T138b, T144, T163b, T166.
- **docs-tooling**. Owns Roblox Dev/* notes (not Lore/*), tools/* (except upload_asset.py), Overnight/*, Studio hygiene. Order: T232, T422, T413, T414, T424, T027, T205, T200, T246.
OFF LIMITS (live chats in QUEUE.md, 2026-10-29): title page and skill tree (ui-rework-manager and its workers), loading finale and loading clock (loading-anim), LoadingScreen, StartMenuArt, FontPass, SkillTreeArt, SkillGrove, FrameArt, AbstractScreens/HUD/Layer, IntroTour, ArtIds, UI Kit/art menu/eye/lid/lash art. ComfyUI and GPU are HELD by the title-page worker (QUEUE.md): chars/client-ui GPU tasks wait for release.
**Parallel:** docs-tooling (no Studio) + chars Blender/Python tasks + fx-audio sound synthesis (Python) can run alongside one Studio holder. Studio-exclusive: sim, client-core, client-ui, world, fx-audio Play checks, T403/T404/T405/T406/T409. Rule: one lane holds Studio at a time, release between tasks; only the Studio holder starts or stops Play. Suggested Studio rotation: sim, then world, then fx-audio, then client-ui/client-core as the UI chats release.

# 4. Blocked by the old guardrails
Format: `id | what was blocked | one thing that unblocks | class`
- T153 | stage jumps via QAProfile did not switch set; stage-16/21 Play checks never run (PROGRESS T114, T127 PARTIAL) | use a Play-time debug jump on the server (local, reversible) | unblocked-by-relaxation
- T140b, T144, T133 | freeze-frame capture hook "not available", FXRecipes not wired (PROGRESS T101-T112 BLOCKED) | allow screen_capture/recording scripts and GameClient hook edits after claim | unblocked-by-relaxation (needs T198 for GameClient room)
- T235, T086 | HUD contrast fixes and layout sat in GameClient at its 200,000 limit (PROGRESS T120-T122) | T198 (now 173,770 after UILib split, Known Issues) | unblocked-by-relaxation
- T405 | upload route needs `ROBLOX_API_KEY`; denials.log 06:34 and 06:36 "secret access" | use tools/upload_asset.py with the existing env var, never print it; uploads pre-approved in CLAUDE.md. Whether the key is set is UNVERIFIED | unblocked-by-relaxation (judgement call, see report)
- T142, T407, T124 | Blender exe lives outside the project (denials.log path under Downloads); Hunyuan/ComfyUI not allowed overnight (POLICY) | allow the exe path from Research/3D and Art/Blender Cinematic Pipeline.md; claim GPU in QUEUE.md | unblocked-by-relaxation
- T200 | type checker not installed, "installing software" forbidden (POLICY); UNVERIFIED which checker Studio MCP exposes | download a pinned `luau-analyze` into tools/bin or use Studio script analysis | unblocked-by-relaxation (local, reversible)
- T413 | "recursive delete" denial (denials.log) | name the single instance and folder to delete | unblocked-by-relaxation
- T198, T149, T139, T138, T194, T178 | GameClient owned by ui-rework (QUEUE.md); PROGRESS T106 was blocked for the same reason | QUEUE release by ui-rework-manager | needs-user (coordination between chats; ask the chats, not the code)
- T183 | merge-factor vs rarity-cap flag: analysis done (Progression Rules), tier cap mismatch (5 vs 8) unresolved (Known Issues) | the user decides whether to raise the cap | needs-user
- T092 | live passes/products and prices | the user creates dev products in Creator Hub | needs-user
- T197, T059, T060, T079, T080, T003 | OFF LIMITS (live UI chats) | those chats finish and release | needs-user (ownership)
- Save `Claude.rbxl` (all Studio work of 2026-10-29 is unsaved: Known Issues) | POLICY forbids File > Download a Copy overnight; UNVERIFIED that the MCP can trigger it | the user saves the place | needs-user
- Commit, push, PR | checkpoint.py forced path (denials: "git writes go through checkpoint.py"); no `gh`, GitKraken signed out (QUEUE Sonnet section); user rule: no commit/push without OK | the user says commit | needs-user
- Publishing the game, Open Cloud key changes, purchases | POLICY "never overnight" | the user | needs-user
- Studio/Play stopping others' processes | denials "must not stop Studio, Claude or system processes" | QUEUE rule 4: stop only what you started | rule, not a blocker

# 5. Counts and first 15 tasks
Counts: TODO open lines 163. Section 1: 12 done/obsolete, about 60 ids merged into surviving tasks, 6 ids OFF LIMITS (exact line-by-line reconciliation UNVERIFIED; the board was built by walking all 163 lines). Section 2 actionable board: 84 tasks (sim 22, client-core 6, client-ui 20, chars 8, world 5, fx-audio 14, docs-tooling 9). Section 4: 15 entries (7 unblocked-by-relaxation, 7 needs-user, 1 rule).
New tasks (T400+): T403, T404, T405, T406, T407, T409, T411, T413, T414, T416, T417, T422, T424 (13).

First 15 to run, with reason:
1. T413 (Studio, S) remove the stale MatchSim trap before any sim edit.
2. T187b (Studio, S) known bug with a precise test, unblocks all audio.
3. T232 (Python, S) free check that exposes any stage 21-25 gaps; runs beside Studio work.
4. T422 (Python, S) same, for 20 familiars.
5. T153 (Studio Play) verifies set 4 and set 5, which exist only unsaved in Studio (Bug Log #10); everything world/FX depends on it.
6. T411 (Studio) profile fields first; achievements, quests, bond, leaderboard depend on it.
7. T005 (Studio, S) small sim win while Studio is held.
8. T004 (Studio) difficulty modes, uses T411.
9. T006 (Studio) pause/resume, needed by the pause menu.
10. T403 (Studio) humans already have clips; hooks make them visible on the board.
11. T404 (Studio) Idle/Hit/Death for the 12 originals, same pattern.
12. T142 (Blender, parallel to Studio) enemies have no rigs; biggest art gap (Known Issues).
13. T124 (Blender, parallel) textures feed T409.
14. T198 (Studio, gated on UI chats releasing GameClient) frees room for every client task.
15. T149 (Studio, after T198) the boss phase bar: server framework finished, client does not read it (Boss Framework "Open"); QUEUE note already asked the UI chat.

# Contradictions between sources
1. Task ids: TODO.md line ids duplicate (21 pairs) and clash with Overnight Task Log ids; Known Issues already notes it.
2. Bug #4 (Ward MetalnessMap): Session Log 2026-10-28 says fixed, Bug Log still lists it open and Known Issues repeats it.
3. Systems.md still says Bosses "idea" and Stage set 5 "idea"; Boss Framework.md, Session Log and BackdropVeil.luau show both built.
4. Tier cap: Config/Game Design Doc say 5, a task text says 8, Merge Evolution defines 3 looks (Known Issues).
5. Overnight loop: QUEUE.md lists "overnight loop" as active, but Overnight/ACTIVE was renamed `ACTIVE.ended-user-off-20261029` and PROGRESS says the loop was turned off.
6. Respec: Backlog marks the skill tree "respec, next-best hint" still open, the same file says server side done 2026-10-29; only the UI button is open (OFF LIMITS skill tree).
7. TODO intro says "T001 is first" and ids in priority order, but the file holds second-block ids and no T001-T073 lines; those were moved to the Task Log.
