# Bug Log

Newest at the top. Move fixed bugs to **Fixed** with the date.
Severity: `crash` / `major` (breaks a feature) / `minor` / `cosmetic`

## Open

| # | Date | Severity | Bug | Steps to reproduce | System |
|---|---|---|---|---|---|
| 10 | 2026-10-29 | minor | Stage set 5 (Above the Grey Veil) was missing, so stages 21 to 25 reused set 1. Added 2026-10-29 (`BackdropVeil`, `StageSets` entry, `veil` music) but never run in Play and not saved in the place file | Play stage 21 | StageSets |
| 11 | 2026-10-29 | minor | `SoundFX.play` can stop a higher-priority sound: with all 8 voices at priority 3, a priority 2 sound stops a priority 3 one | read `Studio_Export/SoundFX.luau` lines 72 to 90; fix in [[Design/Sound Priority]] | SoundFX |
| 1 | 2026-10-24 | unverified | Drag-to-merge input (mouse and touch) never exercised by a real pointer; tested only by firing remotes from a script | Play in Studio, drag one pet onto a matching pet with three on the grid | Client input |
| 2 | 2026-10-24 | minor | Console shows "User is not authorized to access Asset" from `cloud_3976620715.Sprint Execute`. Not our script; source unidentified (likely Studio/plugin) | Start Play | Studio |
| 4 | 2026-10-28 | minor | Ward lantern's MetalnessMap fails: `rbxassetid://84849520457882` is a Decal id, not an Image id ("Asset type does not match requested type"), so its SurfaceAppearance does not generate. Open Cloud uploads of type Decal return the Decal id; resolve the Image id with `InsertService:LoadAsset(id)` (the Decal's Texture) | Start Play, read the Output | Workspace.Map.WardLantern (3D art session) |
| 3 | 2026-10-27 | minor | Two ModuleScripts named `MatchSim` sit in `ReplicatedStorage.Shared`: the current one (760 lines, has `loadMeta`, `pickPet`) and a stale older copy (694 lines). `require` and `WaitForChild` by name return the first child (the current one), so the game works, but the stale copy is a trap | Open `ReplicatedStorage.Shared` in Studio, or parse the saved place | Studio place. Found 2026-10-27 in the saved `Claude.rbxl` and live Studio; delete the 694-line copy and save. 2026-10-29: `Studio_Export/MatchSim.luau` was the STALE copy (693 lines, no `loadMeta`); refreshed from the 760-line module; the stale Studio copy is still there (deleting it needs a Studio edit and a save; left for the user or the next Studio holder) |

## Fixed

| # | Date found | Date fixed | Bug | Fix |
|---|---|---|---|---|
| 5 | 2026-10-29 | 2026-10-29 | Loading screen parts overlapped and were not centred (the user) | Audited in Play by Sonnet (tools/loading_audit.luau). Fixes: the clock tunnel glides to the screen centre for the finale (concentric with the eye, measured 0, 0), gears centred on their faces, key parts named, and (the user: "move it") the title, bar and status moved into a dark panel along the bottom below the tunnel (tunnel raised to 0.36). Verified by Play capture: text legible on the panel; the title still grazes the largest clock face's lower rim |
| 1 | 2026-10-24 | 2026-10-24 | Enemies froze and showed only a health bar after the tutorial | Spawn time was taken from a sim clock that stands still while the tutorial is paused, so enemies looked far past the lane end. Server now stamps real server time at spawn. Verified in Play: enemies move 8.1 studs/s after a 3.5 s idle |
| 2 | 2026-10-24 | 2026-10-24 | Pets looked off-centre from their coloured pads | Floating spheres sat above the pad and the tilted camera shifted them. Pets are now models standing on the pad. Verified: pivot offset 0.00 studs on slots 2 to 4 |
| 3 | 2026-10-24 | 2026-10-24 | Dragged pet glitched | Now snaps to the pad centre under the pointer, with green/red pad hint for valid/invalid merge. Not verified by a human |
| 4 | 2026-10-24 | 2026-10-24 | Pads and lane did not match where pets stood (reported twice) | Root cause: the static Map was built in Edit mode from a cached, outdated copy of Config (`require` returns the old module until Studio restarts the DataModel), so pads and lane followed the old layout. Map is now built at server start from Config by `MapBuilder`. Verified in Play: pad vs Config offset 0.000 studs; screenshot showed pet centred on pad |
| 5 | 2026-10-24 | 2026-10-24 | Stage popup outline stayed after the text faded | The black text outline is a separate UIStroke that was never faded. Text and outline now fade together. Verified: both transparency 1.00 after the popup |
| 6 | 2026-10-24 | 2026-10-24 | ROLL text hidden behind the egg icon | UIPadding shifted the icon too. Label used instead. Seen in screenshot; fix not re-screenshotted |
| 7 | 2026-10-26 | 2026-10-26 | Hatch reveal covered banners fired during it (ULTIMATE!, LEVEL UP, STAGE CLEAR) | Reveal frame sits above the HUD layer. `showBanner` now queues while the reveal is visible (max 3) and plays them 1.1 s apart after the queue empties. Verified in Play: STAGE 2 banner held during a Legendary reveal, shown after |
| 8 | 2026-10-26 | 2026-10-26 | `SkipTutorial` remote restarted the run at any time with no rate limit (wipes progress, spam creates sims) | MatchService ignores it unless the current run is still the tutorial. Verified in Play: second skip mid-run ignored, roll count kept |
| 9 | 2026-10-24 | 2026-10-26 | (was open #3) finished matches never cleaned up | Obsolete: the no-lose rework removed the match-over state; sessions end on player leave. Checked MatchSim/MatchService source |

**Lesson (Dev Process):** in Studio, `require` caches modules by instance, so edit-mode scripts that read Config after it changed can use stale data. Clone the module folder before requiring in tests, and build anything that mirrors Config at runtime.

**QA note 2026-10-24:** the Roblox Studio mouse tool takes coordinates without the 58 px top bar (GUI space); screenshots and `WorldToViewportPoint` include it. Subtract 58 from y when clicking world objects. Real mouse drag-merge now verified (pet 4 onto pair at 2-3 merged to tier 2).

**Found by running Play 2026-10-24:** the client script exceeded Luau's 200-local limit after the animation additions ("Out of local registers"), which stopped the whole HUD script. Fixed by scoping the skill-tree section in a `do` block. Lesson: run Play after every large client edit; new UI code should go in ModuleScripts, not the one big script. Open: the Blender GLB export carries an extra 80-triangle mesh (FBX is clean).

**Blocked 2026-10-24:** Studio import services are not reachable from the MCP script context, so the pilot upload needs a manual Bulk Import by the user (steps in [[Research/3D and Art/Asset and Animation Workflow|Asset and Animation Workflow]]).

**Pilot import 2026-10-24 (Hunyuan3D -> Blender -> Studio):** (1) clips did not move the mesh: root pose `StarDrake_T1_Rig` did not match MeshPart `StarDrake_T1`; fixed in the place data, verified (bone moves); (2) mesh tilted 90 degrees about X on import, Blender export patched, unverified until re-import of `Blender/out_v2`; (3) importer left no `Animator`; (4) Attack/Spawn imported as looping, fixed in place data; (5) duplicate imported models in Workspace (waiting on the user). Details: [[Research/3D and Art/Asset and Animation Workflow|Asset and Animation Workflow]].

**2026-10-25:** v2 re-import checked in Play: tilt fixed (upright without correction); clips needed the same pose-rename and loop patch again (the importer repeats the same naming issue, so it is a fixed post-import step); the model faces -Z. Old duplicate models and their clip saves deleted by the user's request.

- 2026-10-25 FIXED: K.bar returns a nil fill at value 0 when sprite art is on; NowPlaying uses its own track/fill boxes. Note: Studio MusicFX source uses CRLF line endings when patching.
