# Known issues (T245)
Compiled 2026-10-29: every open row of [[Bug Log]] plus the gaps found while working on familiars, enemies and design notes. Severity as in the Bug Log: crash, major (breaks or blocks a feature), minor, cosmetic, unverified. "Gap" means a missing piece, not a defect in something that exists.

## Open bugs from the Bug Log
| Severity | Issue | Where |
|---|---|---|
| unverified | Drag-to-merge with a real mouse or touch has never been exercised (only remotes fired from a script) | Bug Log #1 |
| minor | Console line "User is not authorized to access Asset" from `cloud_3976620715.Sprint Execute`; not our script | Bug Log #2 |
| minor | Two ModuleScripts named `MatchSim` in `ReplicatedStorage.Shared` (a stale 694-line copy is a trap); delete the old one and save the place | Bug Log #3 |
| minor | Ward lantern MetalnessMap uses a Decal id instead of an Image id, so its SurfaceAppearance fails | Bug Log #4 |

## Gaps and risks found 2026-10-29
| Severity | Issue | Detail and next step |
|---|---|---|
| major | Familiar and enemy walk and attack clips cannot play in a published game | The clips are KeyframeSequences registered in Studio only; a published game needs uploaded Animation assets. See [[Design/Upload Plan]] |
| major | Tonight's Studio changes are not saved in `Claude.rbxl` | They live in the open Studio session and in the `Studio_Export/` mirrors; the place file was not saved (needs the user) |
| major | Familiar roles (Hasten, Ward, Reveal, Hush, Echo and so on) do not exist in code | Only damage, cooldown and range; designs are in [[Design/Familiar Systems]] |
| minor | New familiars' stats are placeholders | Damage, cooldown and range for the nine new familiars were set by hand, never balanced |
| minor | Rig deformation was never verified visually in Roblox | The viewport was blank in captures; bone data and clips were checked by script |
| minor | No Idle clips for the familiars in Roblox | Idle animations exist as Blender GLBs (T092, `Assets/3D/Familiars/idle/`) but `FamiliarClips` has only Walk and Attack recipes |
| minor | Familiar textures are a first-pass projection | Blotches and stray colours; the 512 px maps in [[Design/Texture Maps]] inherit them |
| minor | Best stage reached is not saved | Nothing carries over for stage progress; [[Design/Progression Rules]] proposes `bestStage` |
| minor | Tier cap mismatch in the notes | Config and the design doc say 5; a task text says tier 8; the merge evolution note defines 3 looks |
| minor | Stage set 5 is installed but never run in Play | `BackdropVeil`, its `StageSets` entry and the `veil` music state exist in the open Studio session and `Studio_Export/` (2026-10-29); the place file is not saved and the set has not been seen in Play ([[Design/Stage Set 5 Plan]]) |
| minor | One 234-stud path serves all 25 stages | Only hp and count change; [[Design/Difficulty Curve]], [[Design/Stage Set Plans]] |
| minor | Enemy and boss models are concept-grade and unseen in a stage | Flat colours, no rigs, not placed; [[Design/Enemy Models]] |
| minor | Task numbering in `Overnight/TODO.md` is inconsistent | The second block reuses numbers (for example T017 has evidence T217); a quick removal by number can hit the wrong line |
| minor | Sound cap can stop a higher-priority sound | When all 8 voices are priority 3 and a priority 2 sound plays, `SoundFX.play` stops a priority 3 sound; fix in [[Design/Sound Priority]] |
| minor | Stray test folder `ReplicatedStorage._GameSpeedTest` | A leftover from an earlier test run; harmless, not removed |
| cosmetic | The Fog Wisp imports as 3 MeshParts | The recess and eye points keep their own materials |
| cosmetic | The loading-screen title still grazes the largest clock face's lower rim | Noted in Bug Log #5 (fixed row) |

Not listed: anything the user asked for but has not seen (for example every texture and every enemy model is UNVERIFIED by the user).
