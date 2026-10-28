# Overnight report, 2026-10-27 (branch overnight/2026-10-27)

Run: armed 19:53, ended about 21:40 (1.8 h of 8 h, 46 of 60 loops). All 41 tasks done (36 planned + T37-T43 added when the list finished early, as the user asked). Nothing blocked. Labels: **gate-verified** = the gate ran the check itself; **attested** = I ran it in Studio and saved the output in `Overnight/evidence/Txx.txt`; **UNVERIFIED** = no human has judged it (all look and feel).

## Read this first
1. **No commits were made.** `tools/overnight/checkpoint.py` fails at its staging step on git 2.54: its `:(exclude)` patterns name paths that `.gitignore` already ignores (`Overnight/ACTIVE*`, `Overnight/state.json`, `Overnight/captures/*`, `Roblox Dev/Codex Handoff/*`), and git exits with code 1. The script is a protected control file, so I did not edit it; raw git writes are denied by the guard. All work is on disk (and staged from the first attempt). **Fix:** delete those four excludes from `EXCLUDE` (they are ignored anyway), then run the checkpoint or commit by hand.
2. **Save the place** (File > Download a Copy over `Claude.rbxl`). Every Studio change tonight exists only in the open place; `Studio_Export/` mirrors the scripts as text.
3. **Look at** `Overnight/captures/fx_contact.png` (all 30 effect sheets) and the per-task captures in `Overnight/captures/`.

## Features implemented
| Task | What | Label |
|---|---|---|
| T01 | Every Studio script mirrored to `Studio_Export/` (local receiver `tools/export_receiver.py`, re-run after each change) | gate-verified |
| T32 | Audit: one map shared by all players; per-run layouts would need Path as an instance (`evidence/T32.txt`) | attested |
| T33 | Balance baseline harness `Tests/Balance.test.luau` (4 bot strategies, 3 seeds) | attested |
| T35 | `Roblox Dev/Research/UI/UI Quality Bar.md` with captures and a 10-item gap list | attested |
| T03 | `Shared.NumberFormat` (short, grouped, scientific) | attested |
| T04 | Settings schema in the profile, server validation, 1 save per second, batches | attested |
| T05 | Settings wired: flashes, reduced motion, shake, volumes, effects detail | attested |
| T06 | Settings panel (glass, UIKit validator 0 problems on content) | attested (look UNVERIFIED) |
| T07 | Low setting turns lamp shadows off | attested |
| T22 | Effect budget: burst cap 10/20/32, Rate x0.5 on Low, secondary layers off | attested |
| T34 | Game speed 1x/2x (same results, half the time) | attested |
| T14 | Summon reveal split into `RevealSection` module (backup `ServerStorage.GameClient_backup_T14`) | attested |
| T18 | Spike: EditableImage cannot texture ParticleEmitters or Beams (works in UI) | attested |
| T16 | `FlipbookFX` kit (world and UI players, emit attributes, resize, recolor, registry) | attested |
| T24, T27, T28 | 30 flipbook sheets: 14 ours, 13 Unity Labs CC0 repacks, 3 composites; recolor test; contact sheet | gate-verified (look UNVERIFIED) |
| T25, T26 | `FXRecipes` (6 recipes, 3 beats, hit-stop and shake) + quality gate table | attested (look UNVERIFIED) |
| T19 | `TDFeedback`: placement, upgrade column + chevrons, range and splash rings, coin drop | attested (look UNVERIFIED) |
| T20 | Rarity accents (loot beam, aura, Legendary sigil) + shared Legendary banner | attested (second player untested) |
| T21 | Slash-arc projectile style (combo, heavy hits, ink) | attested |
| T36 | Quality pass: HUD below the top bar, icon fallback, reveal text clear of ROLL, board feedback wired | attested (look UNVERIFIED) |
| T30 | `rbxl_emitters.py --full` decodes emitter numbers; Hollow Purple, Healing, Arrow Rain ported (our textures) | gate-verified |
| T29, T23 | ParticleFX catalogue registry (44 effects, your 38 ids) + sheets on merges and kills with fallbacks | attested |
| T08, T39, T43 | Stage sets as data: Lampwick Lane, Harbour of Brass (6-10), The Silent Cathedral (11-15) | attested (look UNVERIFIED) |
| T09 | Enemy hit reactions per projectile style | attested |
| T17 | UI flipbooks painted at runtime (4 rarity frames, claim sparkle, achievement burst) | attested |
| T10, T11, T12, T13 | GRAND ARCANA and WINTER'S HUSH get beams, impacts and captions; STARFALL checked phase by phase; Arcane Fox and Frostling signatures confirmed wired | attested (look UNVERIFIED) |
| T31 | 48 AnnoMotion CC0 icons cut with alpha (`UI Kit/art/icons_fantasy/`) | attested |
| T37 | HUD numbers follow the number-format setting | attested |
| T38 | `Tests/StageSets.test.luau` | attested |
| T40 | World rings: transparent centre, no dark plate, above the path | attested |
| T41 | Cutscene skip by tap and automatically at 2x, with full cleanup | attested |
| T42 | Start-screen flashing-lights notice with a Flashes toggle | attested |
| T15 | Repo hygiene | gate-verified at the end (also export, compile, verify-all PASS) |

## Bugs fixed
- `GameClient:2437 attempt to call a nil value` after the reveal split (ease() moved away) — fixed and re-run clean (T14).
- Settings could not be saved in a batch; now up to 16 keys per call, each validated (T06).
- Caption overlap in cutscenes (two captions on screen at once) (T10).
- Rings in the world read as dark discs (T40); flare billboards were cut by the ground (T25).
- Slash style returned a duration scaled twice by game speed (T21).
- Flipbook sheets: wisps loop seam, NaN frames in slash_arc, CandleSmoke grid cut at fractional cell width, explosion one-shots without anticipation (T24, T27).
- Start-screen toggle under the PLAY button's glow could not be clicked (T42).
- CutsceneFX error clean-up now also disconnects the cutscene's frame connections (T41).

## Tests executed and results
- Headless (Studio Edit mode): MatchSim 31/31, NumberFormat 24/24, SettingsDefaults 32/32, GameSpeed 28/28, StageSets 23/23, Balance baseline PASS.
- Gate: `checks.py export`, `compile`, `hygiene` PASS; `fx_sheet.py verify-all` PASS on 30 sheets.
- Play runs with real remotes and real mouse clicks for every Studio task; console showed only the pre-existing "User is not authorized to access Asset" lines.

## Files changed (main ones)
- Studio (mirrored in `Studio_Export/`): GameClient, MatchService, Backdrop, BackdropHarbour (new), BackdropCathedral (new), StageSetClient (new), RevealSection (new), SettingsPanel (new), Shared.SettingsDefaults/NumberFormat/StageSets (new), FrameArt, ProjectileFX, CutsceneFX, FlipbookFX/FXRecipes/TDFeedback/UIFlipbooks/ParticleFXLib/ParticleFXRegistry/YuruzuuPorts (new).
- Disk: `VFX/*.luau`, `VFX/flipbooks/*` (sheets, `yuruzuu_recipes.json`), `VFX/ASSETS.md`, `Tests/*.test.luau`, `Tests/harness/*`, `tools/` (export_receiver, free_ids, fx_sheet, fx_ingest, fx_gate_frames, pfx_registry, rbxl_emitters, icon_cut), `UI Kit/art/icons_fantasy/`, vault (`Systems.md`, `Backlog.md`, `Session Log.md`, `Research/UI/UI Quality Bar.md`).

## Blocked or not done
- **Checkpoints / commits:** blocked by the checkpoint script (see top). Commit hashes: none.
- Screen recording of Studio returned identical frames twice (PrintWindow and screen grab), so effect reviews used freeze-frame captures; continuous-motion review is UNVERIFIED.
- Not tested: phones and touch, a real second player (shared Legendary banner), slider dragging, live rejoin of saved settings.

## Recommended next actions
1. Fix `checkpoint.py` excludes, commit the branch, save the place.
2. Judge the look: `fx_contact.png`, T10/T11/T25/T36/T39/T43 captures. Known weak spots: effects small at the board camera, Starfall's very bright column hides the drake's rise, Harbour and Cathedral far props outside the frame.
3. Phone check: Low setting frame rate, bottom-corner buttons vs. thumbstick (UI Quality Bar gap 3).
4. Delete `ServerStorage.GameClient_backup` and `GameClient_backup_T14` once happy.
5. Background helpers still running on 127.0.0.1 (ports 8791-8795: export receiver and static file servers); close them or reboot.
