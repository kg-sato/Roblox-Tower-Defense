# Bug Log

Newest at the top. Move fixed bugs to **Fixed** with the date.
Severity: `crash` / `major` (breaks a feature) / `minor` / `cosmetic`

## Open

| # | Date | Severity | Bug | Steps to reproduce | System |
|---|---|---|---|---|---|
| 1 | 2026-10-24 | unverified | Drag-to-merge input (mouse and touch) never exercised by a real pointer; tested only by firing remotes from a script | Play in Studio, drag one pet onto a matching pet with three on the grid | Client input |
| 2 | 2026-10-24 | minor | Console shows "User is not authorized to access Asset" from `cloud_3976620715.Sprint Execute`. Not our script; source unidentified (likely Studio/plugin) | Start Play | Studio |
| 3 | 2026-10-24 | minor | Match ends are never cleaned up server-side except on player leave; "Over" sessions keep sending snapshots every 0.25 s | Finish a match | MatchService |

## Fixed

| # | Date found | Date fixed | Bug | Fix |
|---|---|---|---|---|
| 1 | 2026-10-24 | 2026-10-24 | Enemies froze and showed only a health bar after the tutorial | Spawn time was taken from a sim clock that stands still while the tutorial is paused, so enemies looked far past the lane end. Server now stamps real server time at spawn. Verified in Play: enemies move 8.1 studs/s after a 3.5 s idle |
| 2 | 2026-10-24 | 2026-10-24 | Pets looked off-centre from their coloured pads | Floating spheres sat above the pad and the tilted camera shifted them. Pets are now models standing on the pad. Verified: pivot offset 0.00 studs on slots 2 to 4 |
| 3 | 2026-10-24 | 2026-10-24 | Dragged pet glitched | Now snaps to the pad centre under the pointer, with green/red pad hint for valid/invalid merge. Not verified by a human |
| 4 | 2026-10-24 | 2026-10-24 | Pads and lane did not match where pets stood (reported twice) | Root cause: the static Map was built in Edit mode from a cached, outdated copy of Config (`require` returns the old module until Studio restarts the DataModel), so pads and lane followed the old layout. Map is now built at server start from Config by `MapBuilder`. Verified in Play: pad vs Config offset 0.000 studs; screenshot showed pet centred on pad |
| 5 | 2026-10-24 | 2026-10-24 | Stage popup outline stayed after the text faded | The black text outline is a separate UIStroke that was never faded. Text and outline now fade together. Verified: both transparency 1.00 after the popup |
| 6 | 2026-10-24 | 2026-10-24 | ROLL text hidden behind the egg icon | UIPadding shifted the icon too. Label used instead. Seen in screenshot; fix not re-screenshotted |

**Lesson (Dev Process):** in Studio, `require` caches modules by instance, so edit-mode scripts that read Config after it changed can use stale data. Clone the module folder before requiring in tests, and build anything that mirrors Config at runtime.

**QA note 2026-10-24:** the Roblox Studio mouse tool takes coordinates without the 58 px top bar (GUI space); screenshots and `WorldToViewportPoint` include it. Subtract 58 from y when clicking world objects. Real mouse drag-merge now verified (pet 4 onto pair at 2-3 merged to tier 2).

**Found by running Play 2026-10-24:** the client script exceeded Luau's 200-local limit after the animation additions ("Out of local registers"), which stopped the whole HUD script. Fixed by scoping the skill-tree section in a `do` block. Lesson: run Play after every large client edit; new UI code should go in ModuleScripts, not the one big script. Open: the Blender GLB export carries an extra 80-triangle mesh (FBX is clean).

**Blocked 2026-10-24:** Studio import services are not reachable from the MCP script context, so the pilot upload needs a manual Bulk Import by the user (steps in [[Research/Asset and Animation Workflow|Asset and Animation Workflow]]).

**Pilot import 2026-10-24 (Hunyuan3D -> Blender -> Studio):** (1) clips did not move the mesh: root pose `StarDrake_T1_Rig` did not match MeshPart `StarDrake_T1`; fixed in the place data, verified (bone moves); (2) mesh tilted 90 degrees about X on import, Blender export patched, unverified until re-import of `Blender/out_v2`; (3) importer left no `Animator`; (4) Attack/Spawn imported as looping, fixed in place data; (5) duplicate imported models in Workspace (waiting on the user). Details: [[Research/Asset and Animation Workflow|Asset and Animation Workflow]].

**2026-10-25:** v2 re-import checked in Play: tilt fixed (upright without correction); clips needed the same pose-rename and loop patch again (the importer repeats the same naming issue, so it is a fixed post-import step); the model faces -Z. Old duplicate models and their clip saves deleted by the user's request.

- 2026-10-25 FIXED: K.bar returns a nil fill at value 0 when sprite art is on; NowPlaying uses its own track/fill boxes. Note: Studio MusicFX source uses CRLF line endings when patching.
