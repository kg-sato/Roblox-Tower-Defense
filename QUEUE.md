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

## Active chats
| Chat | Id / how to reach | Model | Since |
|---|---|---|---|
| loading-eye (main UI chat) | local_e6ef5e2a | Opus | 2026-10-29 |
| Sonnet (familiar art) | local_58787b6b | Sonnet | 2026-10-29 |
| overnight loop | Overnight/ACTIVE, see Overnight/PROGRESS.md | | 2026-10-29 |

## Shared resources (one holder at a time)
| Resource | Holder | Since |
|---|---|---|
| Roblox Studio (Edit edits, Play, recordings) | FREE (Sonnet released, Edit mode; temp modules deleted) | 2026-10-29 |
| ComfyUI 127.0.0.1:8188 (GPU, 8 GB) | FREE (server stopped) | 2026-10-29 |
| GPU for Hunyuan3D (shares the 8 GB with ComfyUI) | FREE | |
| Blender (CPU, headless; several runs are fine) | FREE | |
| File server for Studio_Export (127.0.0.1:8770 or 8798) | FREE; whoever starts it stops it | |
| Git (commit, push; only with the user's OK) | FREE | |

## Ownership (Studio scripts, Studio_Export files and art)
| Owner | Owns |
|---|---|
| loading-eye (main UI chat) | LoadingScreen, start menu (StartMenuArt), fonts (FontPass), skill tree (SkillTreeArt, SkillGrove), FrameArt, AbstractScreens, AbstractHUD, AbstractLayer, GameClient, IntroTour, ArtIds; UI Kit/art (menu, eye, lid, lash art) |
| Sonnet (familiar art) | ReplicatedStorage.Characters, Shared.Config, Shared.Familiars, Shared.FamiliarClips, Shared.FamiliarMaterials, ReplicatedStorage.FamiliarArt, ServerScriptService.MatchService, StarterPlayerScripts.CollectionScreen; Blender/* character work |
| 3d-art (if it returns) | MapBuilder, WardFX, ServerStorage models (Ward meshes, metal_white) |
| Sonnet, stage set 5 (new, 2026-10-29) | ServerScriptService.BackdropVeil (new), the AboveTheGreyVeil entry in Shared.StageSets, the `veil` state in MusicFX.states |
| shared, append-only | VFX/ASSETS.md, UI Kit/art/upload_1028/ids.txt and decal_ids.txt, Roblox Dev/Session Log.md (add lines, never rewrite) |

## Queue: loading-eye (main UI chat)
- Now: idle, holding nothing. Loading screen done (2D etched eye, text panel below the tunnel; Bug Log #5 fixed).
- Next, only if the user asks: a Respec button on the skill tree screen (server side by Sonnet: `Action:FireServer("Respec")`, answer event "Respec" {refunded, cost}).
- Done 2026-10-29: eye forming, twitch fix, counter-rotating dials, whirlpool suck-in, etched gold-ink recolour.
- For Sonnet: the user's colour request ("make the new 3D model similar in coloring", "i wanted these colors"). The
  reference is the etched loading-screen eye, `UI Kit/art/menu_art/etched_eye_onscreen.png`: a gold-ink engraving on
  near-black. Its lashes and linework are pure black over cream. `UI Kit/art/recolor_etched.py` maps an image onto
  that palette. Which model is meant is for the user to say.

## Queue: Sonnet (familiar art)
(Sonnet keeps this section.)
- Done: gold-ink recolour of the 12 familiar textures applied in Studio (user said yes). Now: working through `Overnight/TODO.md` without Studio (Blender models, design notes in `Roblox Dev/Design/`, Python checks). Holding nothing. Colour request still paused until the user says which model is meant (12 familiars or the loading-screen eye).
- Next (needs a Studio CLAIM first): hide the FAMILIARS button on the start menu (done earlier by CollectionScreen change, needs a Play check); wire the 512 px maps; Idle clips.
- Done 2026-10-29: T074 to T110 (familiars), T111 to T122 (eye system, props, trainer sheet, eleven enemy and boss models (nine designs, three Unbound phases), uploads checked in Edit mode), texture maps, enemy bible, boss designs, progression, difficulty curve, content plans, stage set plans, indexes, known issues, playtest checklist, decision log, next-night plan.
- Studio state I left: Edit mode, nothing loaded, place file not saved by me. Commit `dbf8634` is pushed on `overnight/2026-10-27`; no PR yet (no `gh`, GitKraken not signed in).
