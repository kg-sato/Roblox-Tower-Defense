# Overnight TODO (night of 2026-10-28)

Task line format (the gate parses it, ids must start with T): `- [ ] T101 | title | verify: <command or studio: or manual:>`. `[ ]` open, `[x]` done, `[!]` blocked. Tasks run top to bottom. Last night's list and report: `Overnight/archive/`.

Sizing: last night finished 41 tasks in 1.8 h and stopped at loop 46 of 60, so this list is about three times larger and the tasks are bigger. **Arm with `--max-iter 220`** (the default 60 would stop the run after about 2 h). Sources: [[Backlog]], `Overnight/archive/REPORT-2026-10-27.md` (weak spots), [[Research/UI/UI Quality Bar]] gap list, the Game Design Doc. Not here on purpose (they need a decision from the user first): merge factor vs rarity cap, run-end and what carries over, roster size and revamp, layouts, collection schema, boss attacks, daily rewards, monetisation.

Order rule: a task never comes before one it needs. Studio rules from POLICY.md apply (mirror scripts to `Studio_Export/`, keep GameClient under the 200-local limit, look and feel is UNVERIFIED).

## A. Fix what last night's captures showed
- [ ] T101 | Starfall polish: the gold column no longer hides the drake (lower its brightness and width during the cut-in), the cut-in band leaves the drake's rise visible, falling stars are gold, impacts read as rings and sparks instead of flat white discs | verify: studio: evidence T101 (freeze frames at the same 5 phases as T11, before and after; console clean; look UNVERIFIED)
- [ ] T102 | Effects readable at the board camera: scale FXRecipes and TDFeedback sizes from the camera distance so a merge, a kill and a placement each cover at least 2 % of the screen (measure the changed-area share on freeze frames like T26) | verify: studio: evidence T102 (table of changed-area % per effect before and after; console clean)
- [ ] T103 | Winter's Hush crack: shards and a frost ring instead of soft white balls; Grand Arcana pillars keep the T10 kit | verify: studio: evidence T103 (freeze frame at the crack before and after; console clean)
- [ ] T104 | Harbour of Brass far ring inside the frame: bring one steamship and one crane into the top band of the default camera view | verify: studio: evidence T104 (capture at the default camera shows a ship hull and a crane; path still the lightest value)
- [ ] T105 | Silent Cathedral: stained-glass windows visible at the default camera (side-wall windows near the board) and the nearest covered statue in frame | verify: studio: evidence T105 (capture at stage 11 shows coloured glass and a statue)
- [ ] T106 | Skill tree legibility: node labels and the tooltip line at least 14 px at the 1333 x 777 capture size; locked nodes show which neighbour unlocks them | verify: studio: evidence T106 (measured TextBounds of every label in Play, smallest value, before and after captures)

## B. Wire the new kits into the game (built last night, not yet used)
- [ ] T107 | Hit-stop and screen shake from FXRecipes on merges, boss kills and the ultimate (once per impact, scaled by importance, off with reduced motion or shake off) | verify: studio: evidence T107 (Play: logged hit-stop frames and shake per event; reduced motion gives none; console clean)
- [ ] T108 | Generic ultimate for familiars without a signature uses the ported Hollow Purple and Arrow Rain recipes (by familiar colour) instead of the old meteor-only look | verify: studio: evidence T108 (Ult with an Ember and with a Gargoyle in Play, captures, console clean)
- [ ] T109 | Rarity frames (UIFlipbooks) on the reveal card and in the pet panel title; claim sparkle on upgrade buttons the player can afford | verify: studio: evidence T109 (Play: frames animate on a Rare and a Legendary reveal; sparkle only on affordable buttons; console clean)
- [ ] T110 | Level-up moment: when the trainer level goes up, the UIFlipbooks achievement burst plays over the level pill with a short banner and the next unlock named | verify: studio: evidence T110 (Play: force a level-up via QA, capture, console clean)
- [ ] T111 | Boss intro: when a boss spawns, a bracketed caption ("[ THE UNBOUND ]"), a TDFeedback splash ring at the portal and a short camera nudge (skipped with reduced motion) | verify: studio: evidence T111 (Play at stage 5, capture at the spawn, console clean)
- [ ] T112 | Sound cues for the new effects through SoundFX (merge column, coin drop, placement ring, splash, boss intro, cutscene skip), respecting the effects volume | verify: studio: evidence T112 (Play: each cue fires once per event, SoundFX group volume follows the setting; console clean)
- [ ] T113 | Loading screen: LoadingFX (built 2026-10-25, never wired) plays on join and hands off to the start screen; skippable after the first view | verify: studio: evidence T113 (Play: beats logged in order, start screen visible after, console clean)
- [ ] T114 | Music per stage set: MusicFX picks a track set per StageSets entry and crossfades on a set change | verify: studio: evidence T114 (Play: stage 1 -> 6 -> 11 logs the track change and crossfade; console clean)

## C. Settings, accessibility and comfort
- [ ] T115 | Backdrop Moving / Still setting wired: Still stops fog, dust, steam and drifting reveal fog | verify: studio: evidence T115 (Play: emitter counts in StageSets with Moving vs Still; console clean)
- [ ] T116 | Damage numbers On / Off setting (server-validated like the others) and the float texts obey it | verify: studio: evidence T116 (headless SettingsDefaults test extended and PASS; Play: no float text when Off)
- [ ] T117 | UI size setting (Small / Normal / Large) scaling the HUD UIScale, saved with the other settings | verify: studio: evidence T117 (Play: HUD AbsoluteSize at each size; settings test PASS)
- [ ] T118 | Hide-UI toggle for recording (keyboard H and a Settings toggle), restores on press | verify: studio: evidence T118 (Play: HUD hidden and restored by a real key press)
- [ ] T119 | Settings survive a rejoin: change three settings, stop Play, start Play, values come back from ProfileStore | verify: studio: evidence T119 (values read back after the second Play start)
- [ ] T120 | Contrast audit script: every visible TextLabel in the HUD and panels against its background, list ratios below 4.5:1 and fix them | verify: studio: evidence T120 (table before and after; no ratio below 4.5 except decorative text, which is listed)
- [ ] T121 | Gamepad and keyboard: HUD buttons and the Settings panel are reachable with arrow keys or a gamepad (Selectable, NextSelection) | verify: studio: evidence T121 (Play: real key presses move GuiService.SelectedObject through the main buttons)
- [ ] T122 | Phone-shape check: constrain the HUD root to 844:390 in Play and fix overlaps (buttons out of the thumbstick and jump corners, nothing under the top bar) | verify: studio: evidence T122 (captures at phone shape before and after, list of moved elements)

## D. Server safety and data
- [ ] T123 | Remote security audit with the roblox-dev:roblox-security skill on MatchService (every Action kind): type checks, rate limits, no client-trusted values; fix confirmed findings | verify: studio: evidence T123 (findings list, fixes, and a spam test: 200 Roll and 200 Setting calls in 2 s change state no faster than the limits)
- [ ] T124 | Profile data audit with the roblox-dev:roblox-datastores skill: template version bump path, Reconcile, sanitize on load for every field, BindToClose behaviour | verify: studio: evidence T124 (findings and fixes; MatchSim and SettingsDefaults tests still PASS)
- [ ] T125 | Headless test for MatchService helpers that can be pure (isSlot, isCoord, batch Setting handling) moved into a Shared module with tests | verify: studio: test output in Overnight/evidence/T125.txt, first line PASS
- [ ] T126 | One test runner: `Tests/RunAll` executes every Tests/*.test.luau in Studio and writes one summary line per suite | verify: studio: evidence T126 (summary with every suite PASS)

## E. Content
- [ ] T127 | Stage set 4 Clockwork Foundry (stages 16-20): furnaces, gears, rails, orange glow, sparks; edge ring visible at the board camera; StageSets data and test updated | verify: studio: evidence T127 (stage 16 shows it, test PASS, captures, console clean)
- [ ] T128 | Stage set 5 Above the Grey Veil (stages 21-25) per the Backgrounds note; StageSets data and test updated (cycle becomes 25 stages) | verify: studio: evidence T128 (stage 21 shows it, 26 wraps, test PASS, captures)
- [ ] T129 | Six more original flipbook sheets for status and UI use: burn, poison, shield, buff (up arrows), stun stars, level-up column; each with _mono | verify: Hunyuan3D\.venv\Scripts\python.exe -I tools\fx_sheet.py verify-all VFX\flipbooks
- [ ] T130 | Refresh `Overnight/captures/fx_contact.png` and add a short "how to use each sheet" table to `VFX/ASSETS.md` (grid, lifetime, LightEmission, use) | verify: manual: evidence T130 (table covers every sheet in VFX/flipbooks)
- [ ] T131 | Elite marker: a floating tarot card with an original symbol circles elite enemies (visual only, per the Game Design Doc enemy table); if the sim has no elites yet, show it on bosses only and note it | verify: studio: evidence T131 (Play capture, card follows the enemy and is removed with it; console clean)

## F. Code health
- [ ] T132 | Split the skill tree section out of GameClient into a module (same method as T14: backup, free_ids.py, ctx table, Play check) | verify: studio: evidence T132 (skill tree opens, buying a node works, console clean, GameClient smaller)
- [ ] T133 | Split the pet panel (upgrades and delete) out of GameClient the same way | verify: studio: evidence T133 (panel opens on a pet, upgrade and delete work in Play, console clean)
- [ ] T134 | Code review of last night's new modules with the roblox-dev:roblox-reviewer agent; fix confirmed findings only | verify: studio: evidence T134 (findings list with fixed / not a problem per item; all tests PASS)
- [ ] T135 | `--!strict` on the pure modules (NumberFormat, SettingsDefaults, StageSets, MatchSim helpers) with type errors fixed | verify: studio: evidence T135 (Script Analysis or a type-check pass shows no errors in those modules; tests PASS)
- [ ] T136 | Memory check: 10 waves with auto on and every effect kit active; instance counts in ClientVisuals, FlipbookFX, TDFeedback, FXRecipes and Cutscene return to baseline, and the Lua heap (gcinfo) does not climb wave over wave | verify: studio: evidence T136 (table per wave)
- [ ] T137 | Frame-time probe: average and worst frame time during a boss wave on Low, Default and High (RunService.Heartbeat deltas), recorded with the emitter counts | verify: studio: evidence T137 (table; note that PC numbers are not phone numbers)

## G. Measure and document
- [ ] T138 | Re-run the balance harness after last night's changes and compare with the T33 baseline (game speed must not change results per sim second) | verify: studio: evidence T138 (side-by-side table; differences explained)
- [ ] T139 | Re-capture every priority screen and update the gap list in [[Research/UI/UI Quality Bar]] (mark fixed, still open, UNKNOWN) | verify: manual: evidence T139 (note updated; each gap has a status and a capture)
- [ ] T140 | `VFX/README.md`: how the kits fit together (FlipbookFX, FXRecipes, TDFeedback, ParticleFXLib, UIFlipbooks, CutsceneFX), one example each, and what needs an upload | verify: manual: evidence T140 (README exists and every module named in Systems.md is covered)
- [ ] T141 | Vault upkeep: Systems.md statuses, Backlog ticks, Bug Log entries for anything found tonight, Session Log line | verify: manual: evidence T141 (list of changed lines)
- [ ] T142 | Repo hygiene check passes at the end of the run | verify: python tools/overnight/checks.py hygiene

## B. Needs you (the loop never does these)
- ( ) Save the place (File > Download a Copy over `Claude.rbxl`), then merge or keep `overnight/2026-10-27`.
- ( ) Arm: `python tools/overnight/arm.py --hours 8 --max-iter 220`, Studio open, PC awake.
- ( ) Morning: read `Overnight/REPORT.md`, `denials.log`, `git log`; judge the look of the captures.
- ( ) Decisions that unblock bigger work: merge factor vs rarity cap, run-end rewards, roster size, layouts, collection schema, boss attacks, daily rewards.
- ( ) Phone checks, a real second player, publishing and dev products.
- ( ) Delete `ServerStorage.GameClient_backup` and `GameClient_backup_T14` when happy.
