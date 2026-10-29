---
date: 2026-10-27
tags: [process]
---
# Feature Pipeline

How Claude picks, builds and checks features on its own. The user steers; anything in "Needs the user" waits.

## 1. Pick
Take the top unblocked item from **Next up** in [[Backlog]]. Order of priority:
1. Bugs and gaps in something built recently (finish before starting new).
2. Things the player sees every minute (board, familiars, enemies, reveal, HUD); animation and effects quality comes first (see memory brief).
3. New systems, then content (more stages, more familiars).

Skip anything that needs the user (uploads, purchases, publishing, phone tests, commits) and list it for them instead.

## 2. Define done
One line per feature before building, for example: "stage 2 backdrop appears at stage 6, path stays the lightest value, frame time within 10% of stage 1".

## 3. Build
- Data first: new characters go in `ReplicatedStorage.Characters` ([[How to Add a Character]]); stats in folders or Config, not in code.
- Server decides gameplay (placement, merges, rolls); the client only shows it.
- GameClient is near Luau's 200-local limit: new helpers go in the `UI` or `FXK` tables.
- Visual art without uploads: `ReplicatedStorage.FrameArt` (EditableImage).

## 4. Check (evidence, not claims)
| Kind | Check |
|---|---|
| Gameplay rules | Headless test of MatchSim with fresh module copies (cached Config in the edit VM gives false errors) |
| Visuals | Screenshot from the real game camera, plus a close-up; greyscale check for readability |
| Effects and sound | Watch for created instances (Sound, emitters) in Play; Studio's SoundFX log is per-VM, so read created Sound objects instead |
| Every change | Play with no errors from our scripts in the console |

If screenshots come back dark with only the HUD: Studio is minimized and stops drawing 3D. Restore it without focus (`ShowWindow` 4), capture, then minimize it again (`ShowWindow` 7).

## 5. Record
Tick [[Backlog]], update [[Systems]] and [[Bug Log]], one line in [[Home]]. Never commit, push or upload without the user's OK; before a commit, the user downloads the place over `Claude.rbxl` and Claude verifies the file contains the work.

## Tricks learned (2026-10-27)
- **Big files to Studio:** serve the folder locally (`python -m http.server 8765 --bind 127.0.0.1` in `VFX/`), then in Edit mode `HttpService:GetAsync("http://127.0.0.1:8765/<file>")` + `ScriptEditorService:UpdateSourceAsync`. The local file stays the source of truth. Stop the server afterwards.
- **Screenshots lag about 3 s behind**, so fast cutscenes can't be caught live: at the moment you want, clone `workspace.Cutscene` and save the camera CFrame, then after it ends put the clone back, unbind `GuardianCamera`, set the camera and capture.
- **Studio minimized = no 3D drawn:** `tools/studio_window.py 4` restores it without focus, `7` minimizes it again.
- **QA:** `ServerStorage.QAGrant:Fire(petId, chargeUlt)` (Studio-only, server side) gives a pet and/or charges the ultimate.
