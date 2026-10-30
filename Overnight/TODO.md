# Overnight TODO (promoted from the board 2026-10-29; the user said go)

Task line format (the gate parses it, ids start with T): `- [ ] T### | title | verify: <command, studio: or manual:>`. `[ ]` open, `[x]` done, `[!]` blocked. Tasks run top to bottom. Indented lines under a task are the lane details (ignored by the gate). Board with merge map, lanes and blocked list: `Overnight/BOARD.draft.md`. Old list: `Overnight/archive/TODO-before-board.md`.
Ids that had a `b` suffix on the board are numbered T601 upward here (T138b->T601, T140b->T602, T157b->T603, T162b->T604, T163b->T605, T187b->T606, T190b->T607). Evidence files: `Overnight/evidence/<id>.txt` (first line PASS, then real output) for `studio:` and `manual:` tasks. `studio:`-verified tasks that are suites run as `test:` on the board are checked through Tests/RunAll in Studio Edit mode.
Rules: one commit per finished task via checkpoint.py with --task and a three-word --desc; one lane per worker; claim Studio and the GPU in QUEUE.md; silent mode; off-limits areas (title page, skill tree, loading) belong to other chats. Studio-held-by-others means do a non-Studio task first or wait via `tools/comms.py read`.


## Lane: sim (sim-and-balance)
- [x] T413 | Delete stale duplicate MatchSim and stray _GameSpeedTest folder | verify: studio: only one MatchSim in ReplicatedStorage.Shared, RunAll 16 of 16 PASS
  lane: docs-tooling | needs: Studio | depends: none | size: S | owner-files: ReplicatedStorage.Shared (delete only the stale 694-line MatchSim), ReplicatedStorage._GameSpeedTest
- [x] T606 | Fix SoundFX cap so a lower priority never stops a higher | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/SoundCap.test.luau (new, 8 voices at priority 3 then priority 2))
  lane: fx-audio | needs: Studio | depends: none | size: S | owner-files: SoundFX, Tests/SoundCap.test.luau
- [x] T232 | Stage completeness check passes for all 25 stages | verify: python tools/check_stages_complete.py
  lane: docs-tooling | needs: none | depends: none | size: S | owner-files: Studio_Export/StageCaptions.luau, tools/gen_stage_captions.py
- [x] T422 | Lore, cards, voice lines complete for all 20 familiars | verify: python tools/check_familiars_complete.py
  lane: docs-tooling | needs: none | depends: none | size: S | owner-files: Roblox Dev/Lore/*, tools/voice_lines.py
- [x] T153 | Play-verify stage sets 4 and 5: stages 16 and 21, edge rings, console clean | verify: studio: evidence with captures at stages 16 and 21, Bug Log #10 closed
  lane: world | needs: Studio | depends: none | size: M | owner-files: Backdrop*.luau, Shared.StageSets entries 4 and 5, BackdropFoundry, BackdropVeil
- [x] T411 | Save bestStage and stage progress in profile with migration | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/SaveMigration.test.luau (new cases))
  lane: sim | needs: Studio | depends: none | size: S | owner-files: Shared.Config, ServerScriptService.MatchService (profile), Tests/SaveMigration.test.luau
- [x] T005 | Add 3x game speed, same results per sim second | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/GameSpeed.test.luau)
  lane: sim | needs: Studio | depends: none | size: S | owner-files: Shared.SettingsDefaults, MatchService gclock, Tests/GameSpeed.test.luau
- [x] T004 | Difficulty modes Normal and Hard, server-decided, labelled in data | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Rules.test.luau (new cases) and Balance still clears)
  lane: sim | needs: Studio | depends: T411 | size: M | owner-files: Shared.Config, Shared.MatchSim, MatchService, Tests/Rules.test.luau
- [x] T006 | Pause and resume saved per run | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/ServerRules.test.luau (new cases))
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.MatchSim, MatchService, Tests/ServerRules.test.luau
- [x] T403 | Play Idle, Hit, Death clips of the human familiars on the board | verify: studio: Play capture frames show pose changes on hit and banish
  lane: chars | needs: Studio | depends: none | size: M | owner-files: Models.luau (playClip use), Shared.FamiliarClips
- [x] T404 | Idle, Hit, Death clips for the 12 original familiars | verify: studio: tracks load with correct lengths, Tests/Familiars.test.luau PASS
  lane: chars | needs: Studio | depends: none | size: M | owner-files: Shared.FamiliarClips, Characters/<id>/Animations
- [x] T142 | Rig and animate six enemy models: walk, hit, death; place in a stage | verify: manual: tools/verify_enemy_model.py, studio: walk loop plays in Play
  lane: chars | needs: Blender | depends: none | size: L | owner-files: Blender/* enemy scripts, Blender/out/, Roblox Dev/Assets/3D/Enemies, Models.luau (enemy clips)
- [x] T124 | 512 px texture sets for enemies, bosses and stage props | verify: manual: tools/texture_maps.py report, tools/asset_budget.py PASS
  lane: chars | needs: Blender | depends: none | size: M | owner-files: tools/texture_maps.py, Roblox Dev/Assets/3D/Textures
- [x] T198 | Split GameClient below 150,000 characters into modules | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (RunAll PASS plus studio: Play shows HUD identical, script size in evidence)
  lane: client-core | needs: Studio | depends: QUEUE release of GameClient | size: L | owner-files: StarterPlayerScripts.GameClient, new modules next to UILib (OnClientEvent handler, killEnemy, sealButton/hideIcon, RenderStepped loop), Studio_Export/GameClient.luau
- [x] T149 | Client boss phase bar, banner per phase, deny and freeze feedback | verify: studio: BossPhase and BossFx events drive bar ticks and banner in a Play run to stage 5 boss; console clean
  lane: client-core | needs: Studio | depends: T198 | size: M | owner-files: StarterPlayerScripts.BossBar (new), GameClient (one hook)
- [x] T185 | Roster slot unlock rules (when a new slot opens) in data | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Rules.test.luau)
  lane: sim | needs: Studio | depends: none | size: S | owner-files: Shared.Config, Tests/Rules.test.luau
- [x] T186 | Collection schema: duplicates and shards, wired to the profile | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/SaveMigration.test.luau)
  lane: sim | needs: Studio | depends: T411 | size: M | owner-files: MatchService, Shared.Config, Tests/SaveMigration.test.luau
- [x] T002 | Achievements: server unlock logic for the 30 designed ones | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Achievements.test.luau (new))
  lane: sim | needs: Studio | depends: T411 | size: M | owner-files: Shared.Achievements (new), MatchService, Tests/Achievements.test.luau
- [x] T023 | Quests: server logic and data for the 20 designed quests | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Quests.test.luau (new))
  lane: sim | needs: Studio | depends: T411 | size: M | owner-files: Shared.Quests (new), MatchService, Tests/Quests.test.luau
- [x] T007 | Familiar bond levels from use, plus mood state, as data | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Bond.test.luau (new))
  lane: sim | needs: Studio | depends: T186 | size: M | owner-files: Shared.Bond (new), MatchService, Tests/Bond.test.luau
- [x] T012 | Faction adjacency combo driven by a synergy data table | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Combo.test.luau (new))
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.Synergies (new), Shared.MatchSim, Tests/Combo.test.luau
- [x] T011 | Lantern power: player light buffs nearby familiars, cooldown | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Lantern.test.luau (new))
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.MatchSim, Shared.Config, Tests/Lantern.test.luau
- [x] T015 | Elite enemies and ten wave modifiers as data | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Waves.test.luau (new))
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.Config, Shared.MatchSim, Tests/Waves.test.luau
- [x] T009 | Per-set day/night window and weather events as data | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Env.test.luau (new))
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.StageSets (data fields only), Shared.MatchSim, Tests/Env.test.luau
- [x] T016 | Endless mode after stage 25, tested to wave 100 | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Endless.test.luau (new))
  lane: sim | needs: Studio | depends: T015 | size: M | owner-files: Shared.MatchSim, Shared.Config, Tests/Endless.test.luau
- [x] T019 | Sell and recycle refund percent per tier | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Rules.test.luau)
  lane: sim | needs: Studio | depends: none | size: S | owner-files: Shared.Config, Shared.MatchSim, Tests/Rules.test.luau
- [x] T025 | Weekly leaderboard server validation and anti-cheat checks | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Leaderboard.test.luau (new, pure validation; live OrderedDataStore UNVERIFIED in Studio))
  lane: sim | needs: Studio | depends: T411 | size: M | owner-files: Shared.LeaderboardRules (new), MatchService, Tests/Leaderboard.test.luau
- [x] T416 | Remaining boss mechanics: Automaton lamp, Echo pushes, Regent candles, un-merge | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Boss.test.luau (new cases))
  lane: sim | needs: Studio | depends: none | size: L | owner-files: Shared.Config.BOSSES, Shared.MatchSim bossTick, Tests/Boss.test.luau
- [x] T417 | Hollow Parishioner enemy and Fog Wisp lamp-eating in the sim | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Combat.test.luau (new cases), Balance still clears)
  lane: sim | needs: Studio | depends: none | size: M | owner-files: Shared.Config enemies, Shared.MatchSim, Tests/Combat.test.luau
- [x] T167 | Per-set path shapes as data with a curvature test | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/StageSets.test.luau (new curvature cases), py: tools/check_stages_complete.py)
  lane: sim | needs: Studio | depends: none | size: L | owner-files: Shared.Path, Shared.Config path data, Shared.StageSets (path field), Tests/StageSets.test.luau
- [x] T157 | Path blockers and mid-path gates as data, tested in MatchSim | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/MatchSim.test.luau (new cases))
  lane: sim | needs: Studio | depends: T167 | size: L | owner-files: Shared.MatchSim, Shared.Config, Tests/MatchSim.test.luau
- [x] T177 | Placement rules per map, decorations never block, tested | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Rules.test.luau (placement cases))
  lane: sim | needs: Studio | depends: T167 | size: M | owner-files: Shared.Config canPlace, Tests/Rules.test.luau
- [x] T199 | Move balance numbers into data modules, one table per system | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (RunAll all suites PASS, outputs unchanged)
  lane: sim | needs: Studio | depends: T004,T015,T016,T019 | size: L | owner-files: Shared.Config (split into Shared.Data.*), all Tests/*.test.luau requires

## Lane: client-core (GameClient family; HELD by ui-rework per QUEUE.md: claim first, minimal hooks)
- [x] T139 | Enemy health bars and status icons readable at the board camera | verify: studio: capture plus contrast numbers for burn, chill, stun, mark, hush
  lane: client-core | needs: Studio | depends: T198 | size: M | owner-files: GameClient enemy renderer or new EnemyBars module, Models.luau (bar only)
- [x] T138 | Enemy telegraphs one second before Sentinel plant, Crow perch, Thief steal | verify: studio: telegraph fires 1 s before each special in a scripted wave
  lane: client-core | needs: Studio | depends: T198 | size: M | owner-files: new EnemyTelegraph module, GameClient (one hook), Shared.MatchSim events (read only)
- [x] T194 | Damage float text with per-family colour, obeys damage setting | verify: studio: float text colours per family, setting off hides them
  lane: client-core | needs: Studio | depends: T198,T188 | size: S | owner-files: FeedbackFX, GameClient (one hook)
- [x] T178 | Placement heat map hint toggle, good tiles per family | verify: studio: toggle shows tiles on stage 1, console clean
  lane: client-core | needs: Studio | depends: T177,T198 | size: S | owner-files: new PlacementHint module, GameClient (one hook)

## Lane: client-ui (new standalone modules only; never the OFF LIMITS files)
- [x] T188 | TextAnim module: typewriter, drop, wave, shake, reduced motion, off/subtle/full | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/TextAnim.test.luau (new))
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: Shared.TextAnim (new), Shared.SettingsDefaults (new key), Tests/TextAnim.test.luau
- [x] T607 | Apply TextAnim to captions, lore reveals, headings and boss name | verify: studio: captions typewrite in a Play cutscene, static when reduced motion is on
  lane: client-ui | needs: Studio | depends: T188 | size: M | owner-files: StageCaptions, CutsceneDirector (claim from cutscene owner), RevealSection
- [x] T098 | Shared confirm dialog, toast queue, error and empty states | verify: studio: each state shown in Edit/Play with UIKit validator 0 problems
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: StarterPlayerScripts.Dialogs (new), Toasts (new)
- [x] T085 | Tooltip system on every icon and stat, hover and long press | verify: studio: tooltip appears on hover and long press for 5 icons
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: StarterPlayerScripts.Tooltips (new)
- [x] T084 | Button states idle, hover, pressed, disabled with motion | verify: studio: state screenshots from one button kit
  lane: client-ui | needs: Studio | depends: T604 | size: M | owner-files: UIMotion, UIKit button component (not the off-limits skins)
- [x] T086 | Keyboard and gamepad focus for HUD and main screens | verify: studio: NextSelection path reaches every button in HUD and settings
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: NavFocus
- [x] T087 | Strings table for items, enemies, familiars with coverage test | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/Strings.test.luau (new, every id has a key))
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: Shared.Strings (new), Tests/Strings.test.luau
- [x] T235 | UI checks: text at least 14 px at 844x390, contrast 4.5:1, labelled buttons | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/UIChecks.test.luau (new, run in Play))
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: Tests/UIChecks.test.luau (read-only on UI)
- [x] T074 | Results screen: wave, gold, lore line, next-step button | verify: studio: shown after a stage clear in Play, validator 0 problems
  lane: client-ui | needs: Studio | depends: T098 | size: M | owner-files: StarterPlayerScripts.ResultsScreen (new)
- [x] T075 | Settings: add Controls group (keys, hide-UI) | verify: studio: group visible, values persist after rejoin
  lane: client-ui | needs: Studio | depends: none | size: S | owner-files: SettingsPanel, Shared.SettingsDefaults
- [x] T057 | Reveal for Mythic and Celestial: own sigil and lore line | verify: studio: RevealFX.play for both, no TIER_ALIAS fallback, console clean
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: RevealSection, RevealFX (TIER_ALIAS), FXRecipes (ORDER/RAMP)
- [x] T058 | Collection: faction filter, 20 cards reviewed, silhouettes for unowned | verify: studio: 20 cells, filter works in Play
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: CollectionScreen, FamiliarArt (claim from Sonnet)
- [x] T095 | Familiar detail panel with lore, stats, bond, mood, evolve preview | verify: studio: panel opens for 3 familiars
  lane: client-ui | needs: Studio | depends: T007 | size: M | owner-files: StarterPlayerScripts.FamiliarPanel (new)
- [x] T097 | Pause menu: resume, speed, settings, quit with confirm | verify: studio: pause then resume keeps run state
  lane: client-ui | needs: Studio | depends: T006,T098 | size: M | owner-files: StarterPlayerScripts.PauseMenu (new)
- [x] T090 | Inventory screen: silhouette grid, tier stars, empty-slot lore | verify: studio: validator 0 problems, capture
  lane: client-ui | needs: Studio | depends: T185,T098 | size: M | owner-files: StarterPlayerScripts.InventoryScreen (new)
- [x] T091 | Quest screen with one pinned tracker line in the HUD | verify: studio: tracker shows, collapses
  lane: client-ui | needs: Studio | depends: T023,T098 | size: M | owner-files: StarterPlayerScripts.QuestScreen (new)
- [x] T092 | Battle pass and shop screens, cosmetic only, no live purchases | verify: studio: screens validate; no ProcessReceipt code path added
  lane: client-ui | needs: Studio | depends: T098 | size: M | owner-files: StarterPlayerScripts.PassScreen, ShopScreen (new)
- [x] T093 | Leaderboard and stage-select screens | verify: studio: both open in Play with fake rows
  lane: client-ui | needs: Studio | depends: T025,T098 | size: M | owner-files: StarterPlayerScripts.BoardScreen, StageSelect (new)
- [x] T081 | One-style icon set for status, currency, rarity, faction | verify: manual: contact sheet in UI Kit/art/icons_set/, 40 files with alpha
  lane: client-ui | needs: ComfyUI | depends: none | size: M | owner-files: UI Kit/art/icons_set/ (new), VFX/ASSETS.md (append)
- [!] T076 | Harsh Grading pass on HUD, reveal and collection | verify: manual: reviewer subagent scores 7 of 10 or fixes logged
  lane: client-ui | needs: Studio | depends: T057,T058,T074 | size: M | owner-files: Roblox Dev/Research/UI/Captures (notes only)

## Lane: chars (characters-and-models)
- [x] T409 | Wire 512 px maps into SurfaceAppearance, check in Play | verify: studio: maps load, capture of 3 familiars
  lane: chars | needs: Studio | depends: T124 | size: M | owner-files: ReplicatedStorage.Characters, FamiliarMaterials
- [x] T407 | Clean blotchy first-pass textures on the 12 original familiars | verify: manual: tools/verify_textured_models.py PASS plus contact sheet
  lane: chars | needs: Blender | depends: none | size: M | owner-files: Blender/tex_in, Blender/out, tools/prep_texture_inputs.py
- [x] T405 | Upload original familiars' clips as Animation assets and wire ids | verify: manual: tools/uploads.json lists ids, studio: tracks load from ids
  lane: chars | needs: Studio | depends: T404 | size: M | owner-files: tools/upload_asset.py, tools/uploads.json, VFX/ASSETS.md (append), Characters/<id>/Animations
- [x] T406 | Verify rig deformation visually in Roblox for all 20 familiars | verify: studio: screen_capture per archetype, bone data and capture saved
  lane: chars | needs: Studio | depends: none | size: M | owner-files: Overnight/captures only

## Lane: world (world-and-stages)
- [x] T162 | Three distinct landmarks per set visible from the board camera | verify: studio: five captures, one per set, landmarks listed
  lane: world | needs: Studio | depends: T153 | size: M | owner-files: Backdrop*.luau, MapBuilder
- [x] T164 | Weather and fog per set, tested for frame cost on Low | verify: studio: frame-time numbers Low vs Default per set
  lane: world | needs: Studio | depends: T153 | size: M | owner-files: Backdrop*.luau, Shared.StageSets lighting fields
- [x] T152 | Spawn and exit gate per set with opening animation and enemy shadow | verify: studio: gate opens before spawn, capture per set
  lane: world | needs: Studio | depends: T153 | size: M | owner-files: MapBuilder gate parts, Backdrop*.luau
- [x] T172 | Five boss arena variants of the board | verify: studio: each arena loads at its boss stage, path unchanged
  lane: world | needs: Studio | depends: T149,T167 | size: L | owner-files: StageSetClient (claim), Backdrop*.luau

## Lane: fx-audio (effects-and-audio)
- [x] T148 | Boss phase transition: visual change, sound and cut per phase | verify: studio: three phases of one boss captured with sound events logged
  lane: fx-audio | needs: Studio | depends: T149 | size: M | owner-files: CutsceneFX, BossFx module (new), SoundCatalog entries
- [x] T134 | Hit and death reactions and effects per enemy family | verify: studio: six families, each hit and death captured, emitters under the burst cap
  lane: fx-audio | needs: Studio | depends: T142 | size: L | owner-files: ImpactFX, ProjectileFX hit part, VFX/*.luau (new recipes)
- [x] T133 | Attack, trail and star effects per familiar (20) | verify: studio: contact sheet of all 20 attacks, burst cap respected
  lane: fx-audio | needs: Studio | depends: none | size: L | owner-files: ProjectileFX, FXRecipes
- [x] T601 | Ultimate effect per familiar with a camera move | verify: studio: each ultimate runs to cleanup, no leftover parts
  lane: fx-audio | needs: Studio | depends: T133 | size: L | owner-files: UltFX, CutsceneFX
- [x] T135 | Merge effect and look per tier 1 to 8, incl. morph cut | verify: studio: tier-up captured for 1 to 8
  lane: fx-audio | needs: Studio | depends: none | size: M | owner-files: FXRecipes (merge), TDFeedback, FamiliarMaterials (tier looks)
- [x] T602 | Hit-stop, shake and camera nudge scaled, off with reduced motion | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/FXScale.test.luau (new, setting off yields zero))
  lane: fx-audio | needs: Studio | depends: none | size: M | owner-files: FXRecipes, ImpactFX, Tests/FXScale.test.luau
- [x] T144 | One lantern-light language: spawn sparkle, level column, clear ash, low-lantern vignette, decals | verify: studio: captures per effect, performance on Low
  lane: fx-audio | needs: Studio | depends: none | size: L | owner-files: FeedbackFX, FlipbookFX registry, VFX/flipbooks
- [x] T155 | Familiar cues: placement, merge tiers 1 to 8, reveal per rarity | verify: manual: tools/check_sound_lengths.py PASS, studio: cues logged in a Play run
  lane: fx-audio | needs: Studio | depends: T606 | size: M | owner-files: SoundCatalog, SoundFX call sites via SoundCues (new), VFX/sfx
- [x] T603 | Enemy footsteps and hits, boss intro per boss, trainer footsteps | verify: manual: tools/check_sound_lengths.py PASS, studio: cue log
  lane: fx-audio | needs: Studio | depends: T606 | size: M | owner-files: SoundCatalog, VFX/sfx
- [x] T604 | UI sound set: click, hover, error, buy, quest, achievement, level-up | verify: manual: tools/check_sound_lengths.py PASS
  lane: fx-audio | needs: Studio | depends: T606 | size: M | owner-files: SoundCatalog, VFX/sfx
- [x] T605 | Sound mix sliders (master, music, effects, UI) and ducking | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (Tests/SettingsDefaults.test.luau (new keys), studio: duck on reveal)
  lane: fx-audio | needs: Studio | depends: T604 | size: M | owner-files: SoundFX, Shared.SettingsDefaults (claim from client-ui)
- [x] T160 | Music per set (5, crossfade) plus tension layer by wave | verify: studio: states for sets 1 to 5 load, crossfade logged
  lane: fx-audio | needs: Studio | depends: none | size: M | owner-files: MusicFX, MusicCatalog, AudioIds
- [x] T166 | Ambient loops per set and lobby, plus sounds for captions and set morph | verify: manual: tools/check_sound_lengths.py PASS, studio: loops start per set
  lane: fx-audio | needs: Studio | depends: T153 | size: M | owner-files: MusicFX ambience states, SoundCatalog

## Lane: docs-tooling (docs, vault, tooling, content)
- [x] T414 | Confirm Bug #4 Ward MetalnessMap is fixed and fix the Bug Log row | verify: studio: Play console has no asset-type error; Bug Log updated
  lane: docs-tooling | needs: Studio | depends: none | size: S | owner-files: Roblox Dev/Bug Log.md
- [!] T200 | Strict typing on pure modules and zero type errors on all modules | verify: studio: run Tests via RunAll in Studio Edit; evidence file must hold PASS and the output (type-check output saved, RunAll PASS (checker availability UNVERIFIED))
  lane: docs-tooling | needs: Studio | depends: T199 | size: L | owner-files: Shared.NumberFormat, SettingsDefaults, StageSets, MatchSim helpers
- [x] T205 | Memory after 10 waves per set and frame-time probe Low/Default/High | verify: studio: numbers table in evidence
  lane: docs-tooling | needs: Studio | depends: T153 | size: M | owner-files: tools/perf_probe.luau (new)
- [x] T027 | UI research boards for HUD, collection, results plus HUD wireframe | verify: manual: note in Research/UI with 5 cited sources per board
  lane: docs-tooling | needs: none | depends: none | size: M | owner-files: Roblox Dev/Research/UI/ (new notes)
- [x] T424 | Refresh Systems.md, Backlog and Design Doc for bosses, 20 familiars, set 5 | verify: manual: grep shows no "idea" for Bosses and Stage set 5 rows
  lane: docs-tooling | needs: none | depends: none | size: S | owner-files: Roblox Dev/Systems.md, Backlog.md, Design/Game Design Doc.md
- [ ] T246 | Write tonight's report: built, to judge, to delete | verify: manual: Overnight/REPORT.md updated with labels
  lane: docs-tooling | needs: none | depends: all lanes done | size: S | owner-files: Overnight/REPORT.md, Roblox Dev/Session Log.md (append)

## Lane: fx-audio (added by the controller during the run)
- [x] T630 | Wire the new sound sets (UI, enemy, boss, familiar cues, uploaded ids in VFX/ASSETS.md) into SoundCatalog and call sites | verify: studio: cue log of a Play run shows ui click, enemy hit, boss intro, reveal per rarity, placement and merge cues fired
  lane: fx-audio | needs: Studio | depends: none | size: M | owner-files: SoundCatalog, SoundCues (new), AudioIds, SoundFX call sites (no GameClient edits)

## Lane: follow-ups (added by the controller during the run)
- [x] T650 | Final regression pass: all suites, lean bot, Play run to the stage 5 boss with a wave, console scan, script sizes, compile | verify: studio: evidence file with RunAll counts, bot clears, Play console errors (none new), sizes
  lane: docs-tooling | needs: Studio | depends: none | size: M | owner-files: Overnight/evidence, Overnight/captures
- [x] T642 | Make the new screens reachable: a ScreenRouter module with a menu dock button (one-line hook) opening inventory, quests, pass and shop, leaderboard, stage select, familiar panel, results after a clear and pause on Esc | verify: studio: in a Play run every screen is created in PlayerGui when opened and closes cleanly, console clean, HUD counts otherwise unchanged
  lane: client-ui | needs: Studio | depends: none | size: M | owner-files: StarterPlayerScripts.ScreenRouter (new), one-line hook in GameClient
- [!] T640 | Raise HUD, reveal, collection and results screens to 7 of 10 or better on a blind review (up to three fix rounds) | verify: studio: reviewer scores per item in evidence, every item at 7 or better or the honest scores and what blocked
  lane: client-ui | needs: Studio | depends: T642 | size: L | owner-files: new UI modules only (not the title page, skill tree or loading files)
- [x] T641 | Upload the 40-icon set (images, pre-approved) and wire the ids into status, rarity and faction displays | verify: studio: icons visible on enemy status display and rarity chips in a Play capture, ids in VFX/ASSETS.md
  lane: client-ui | needs: Studio | depends: T081 | size: M | owner-files: new modules, VFX/ASSETS.md (append)
- [x] T651 | Wiring audit: for every module and script added tonight (see the ledger), prove it runs in Play (required by a running script or creating instances/events) and list orphans; wire the cheap ones | verify: studio: evidence table module -> how it was proven alive (log line, instance, event) and the orphan list with fixes or reasons
  lane: docs-tooling | needs: Studio | depends: T642 | size: M | owner-files: Overnight/evidence, new hooks only where an orphan is trivially wirable
- [x] T652 | Hook Achievements, Quests, Bond and LeaderboardRules into the server: profile fields with migration, events from the sim, results saved and clamped, all behind Config flags default OFF | verify: studio: new and extended suites (SaveMigration, ServerRules, Achievements, Quests, Bond) pass and RunAll all green, lean bot unchanged with flags off
  lane: sim | needs: Studio | depends: none | size: L | owner-files: ServerScriptService.MatchService (profile and hooks), Shared.Config flags, Shared.MatchSim events, Tests/*.test.luau
