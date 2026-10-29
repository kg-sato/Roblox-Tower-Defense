# Project queue (mandatory whenever more than one chat is working)

The user, 2026-10-29: "make the queue system mandatory for all parts of the project whenever there are multiple chats ongoing."
This file is the one shared queue for every Claude chat working on this project: the main chat, side sessions, the
overnight loop and any Sonnet or other model. It replaces the old side-session-notes `QUEUES.md`, which only the
main chat's family could see. It is not committed on its own; it is a live file.

## Rules (every chat, every time)
1. **Read this file before starting work.** If another chat is listed under Active chats, follow rules 2 to 6.
2. **Claim before you touch.** Before you use a shared resource (table below) or edit an area you do not own, write your
   chat's name, what you touch and the time in its row. If the row is held by someone else, wait or ask them. Do not
   take it.
3. **Release when done.** Set the row back to `FREE` with the time and the state you left it in, for example "Edit mode".
4. **Studio Play:** only the Studio holder may start or stop Play. Never stop a server, Play session or process you
   did not start.
5. **Ownership:** edit only areas your chat owns (table below). To change something another chat owns, ask it first
   (SendMessage, or a note under its queue section if you cannot reach it).
6. **Tell the others.** If you can, SendMessage `CLAIM <what>` and `RELEASE` to every chat listed under Active chats,
   and keep your own queue section current: now, next, done.
7. When you finish or go idle for good, remove your row from Active chats and release everything you hold.
8b. **Chat-to-chat communication goes through files, not prompts (user, 2026-10-29):** use `python tools/comms.py` (statuses in `Roblox Dev/Comms/status/<chat>.md`, messages in `Roblox Dev/Comms/inbox/<chat>.md`, decisions in `Roblox Dev/Comms/Decisions.md`). At the start of each task and after each finished task run `comms.py read --chat <you>` (prints only unread lines) and `comms.py status --chat <you> --now ... --next ... --done ...` (one overwritten file, short). Read another chat's status with `comms.py show --chat <name>`; do NOT ask it by prompt. Use SendMessage only when another agent must reason or decide something. A background loop (`comms.py digest --push --loop 900`) pushes a one-line digest to the user's phone every 15 minutes when something changed, with no model calls.
8a. **Chat output limit (user, 2026-10-29, newest): only the main manager chat ("Low") may write to the user, at most ONE sentence per 15 minutes and only if needed. Every other chat and worker writes nothing to the user (send phone pushes only; hand-backs to a manager stay short).**
8. **SILENT MODE (user, 2026-10-29, overrides everything below): do not write status text to the user or to the main chat. Finish tasks, then run `python tools/notify.py --done "outcome, evidence, unverified"`; reply in chat only for an emergency (`--reason`) or when the user asks a question. Final replies at the end of a turn: at most one short line. Workers' hand-backs to a manager stay short.** Earlier wording: **Milestones go to the phone, not the chat** (user, 2026-10-29): when a major part finishes, run `python tools/notify.py --done "one sentence: outcome, evidence, what is unverified"` (max 200 characters, allowed at any time, also overnight and in quiet hours; it logs to `Roblox Dev/Notify Log.md`). Keep chat replies to the main chat short; details belong in the vault. Emergencies (`--reason`) keep their old limits.

## Active chats
| Chat | Id / how to reach | Model | Since |
|---|---|---|---|
| loading-eye (main UI chat) | local_e6ef5e2a | Opus | 2026-10-29 |
| Sonnet (familiar art) | local_58787b6b | Sonnet | 2026-10-29 |
| main coordinator (this chat; also does familiar art/animation wiring) | local_6d23e2 ("Low") | Sonnet | 2026-10-29 |
| ui-rework-mgr (title page and skill tree rework, runs Sonnet/Haiku workers; owns the old loading-eye chat's UI files except the loading finale) | local_3ae4002b-8de3-45a2-ab68-dec502613e3c | Sonnet | 2026-10-29 |
| loading-anim (loading finale, then the loading clock) | local_edb20698-6c34-4271-a6de-188a1a59fd1b | Sonnet | 2026-10-29 |
| ui-rework-manager (title page, skill tree; workers: skill-tree, title-page) | local_b5267220-e2b5-4e16-af76-f5ba6f32cbc9 | Sonnet | 2026-10-29 |
| overnight loop | Overnight/ACTIVE, see Overnight/PROGRESS.md | | 2026-10-29 |

## Shared resources (one holder at a time)
| Resource | Holder | Since |
|---|---|---|
| Roblox Studio (Edit edits, Play, recordings) | HELD by skill-tree worker round 2, 2026-10-29 (SkillTreeV3 only). Previous: FREE (title-page worker released 2026-10-29; Edit mode, Play stopped; TitleScene installed, place not saved). Previous: FREE (skill-tree worker released 2026-10-29; Edit mode, Play stopped; SkillTreeV3 installed, GameClient hook line changed (173,824 chars), place not saved). Earlier state: loading-animation thread released; Edit mode, Play stopped; LoadingScreen clock installed, place not saved | 2026-10-29 |
| ComfyUI 127.0.0.1:8188 (GPU, 8 GB) | HELD by title-worker round 2 (title art), 2026-10-29. Previous: FREE (server stopped) | 2026-10-29 |
| GPU for Hunyuan3D (shares the 8 GB with ComfyUI) | HELD by title-worker round 2 with ComfyUI, 2026-10-29. Previous: FREE | 2026-10-29 |
| Blender (CPU, headless; several runs are fine) | FREE | |
| File server for Studio_Export (127.0.0.1:8770 or 8798) | FREE | 2026-10-29 |
| Git (commit, push; only with the user's OK) | FREE | |

(Note from title-worker 2026-10-29: this file was found cut off after the Studio row; the resource rows above are restored from memory. The Ownership table and the per-chat queue sections below the Studio row were lost in that cut and are NOT restored here; whoever has the full text or `git diff QUEUE.md` should re-add them.)

## Ownership (Studio scripts, Studio_Export files and art) (restored by title-worker from the 2026-10-29 copy)
| Owner | Owns |
|---|---|
| loading-eye (NO LONGER RUNS; ui-rework-manager owns these EXCEPT the loading finale + loading timing, owned by loading-anim local_edb20698) | LoadingScreen, start menu (StartMenuArt), fonts (FontPass), skill tree (SkillTreeArt, SkillGrove), FrameArt, AbstractScreens, AbstractHUD, AbstractLayer, GameClient, IntroTour, ArtIds; UI Kit/art (menu, eye, lid, lash art) |
| Sonnet (familiar art) | ReplicatedStorage.Characters, Shared.Config, Shared.Familiars, Shared.FamiliarClips, Shared.FamiliarMaterials, ReplicatedStorage.FamiliarArt, ServerScriptService.MatchService, StarterPlayerScripts.CollectionScreen; Blender/* character work |
| 3d-art (if it returns) | MapBuilder, WardFX, ServerStorage models (Ward meshes, metal_white) |
| Sonnet, stage set 5 | ServerScriptService.BackdropVeil, the AboveTheGreyVeil entry in Shared.StageSets, the `veil` state in MusicFX.states |
| Sonnet, cutscenes | StarterPlayerScripts.CutsceneDirector, StarterPlayerScripts.StageSetClient, Shared.StageCaptions |
| title-worker (ui-rework-manager) | StarterPlayerScripts.TitleScene, UI Kit/art/title_bg |
| shared, append-only | VFX/ASSETS.md, UI Kit/art/upload_1028/ids.txt and decal_ids.txt, Roblox Dev/Session Log.md |
