# Roblox game project

Solo, one-month Roblox game. Place file: `Claude.rbxl`. Studio is connected through the official Roblox Studio plugin (Studio MCP server).

## Folder layout
- `Roblox Dev/`: the Obsidian vault (notes, plans, bugs, analytics)
- `Hunyuan3D/`: local 3D model generator (Python 3.11 env in `.venv`, script `generate.py`)
- `Claude.rbxl`: the Studio place file
- `Blender/`: our Blender 5.3 beta scripts (`process_pet.py`, `verify_export.py`) and outputs in `Blender/out/`. The exe is in Downloads (path in `Roblox Dev/Research/3D and Art/Blender Cinematic Pipeline.md`). Workflow: `Roblox Dev/Research/3D and Art/Asset and Animation Workflow.md`. Uploading to Roblox still needs the user's OK.
- `Kimi/`: the unpacked Kimi desktop app (about 1.1 GB; image generator). Not ours; do not commit it. I cannot drive it from Claude; hand-off is the folder `UI Kit/art/inbox/`.
- `ComfyUI/`: local image generator (ComfyUI portable + FLUX.1 schnell Q4 GGUF + the city96 ComfyUI-GGUF node), about 14 GB, installed 2026-10-25. Not ours; do not commit it. Run `python "UI Kit/art/comfy_generate.py" icon_x [--variants N] [--inbox]` (starts the server itself on 127.0.0.1:8188, about 25 s per 768 px icon). Stop the server afterwards (it holds VRAM).
- `UI Kit/`: our free UI generator (design tokens, components, screens, validator) plus the `/make-ui` project skill in `.claude/skills/make-ui/`. Written and tested in Studio 2026-10-25 (installed as `ReplicatedStorage.UIKit`; 9 screens validated and screenshotted; no art, not wired into the game UI yet). Has an art layer (`UI Kit/art`: Pillow sprites, Blender icon renders, Kimi inbox; `UI Kit/art/briefs/KIMI-MASTER-PROMPT.md`). Read `UI Kit/README.md` and `Roblox Dev/Research/UI/UI Art Pipeline.md` first. Sprites are not uploaded to Roblox yet (needs the owner's OK).
- `Animation Kit/`: third-party R6/R15 humanoid animation pipeline by fwjelaa (credit required). Read `Animation Kit/START-HERE.md` and `Roblox Dev/Research/3D and Art/Animation Kit Review.md` before using it. Not a VFX tool; not for our procedural pets. Installed in `Claude.rbxl` on 2026-10-24 as `ServerStorage.AnimKit` (no HttpService helpers); test emote `R6_Cheer` is in `ServerStorage.Animations`, test dummy in `ServerStorage.TestRigs`. Do not set up Blender, add an API key, upload or publish animations without the user's OK.

## Every session
0. Read `QUEUE.md` (repo root). Whenever more than one chat is working on this project, its rules are mandatory for every part of the project: claim a shared resource (Studio, ComfyUI, GPU, Blender, file server, git) or another chat's area before touching it, release it when done, only the Studio holder starts or stops Play, and keep your queue section current (the user, 2026-10-29).
1. Read `Roblox Dev/Home.md`, then `Roblox Dev/Backlog.md` and any notes it links that matter for today's task.
2. When work is done, update the vault: tick items in `Backlog.md`, add or close bugs in `Bug Log.md`, update statuses in `Systems.md`, and add one line to `Roblox Dev/Session Log.md`.

## Vault notes (in `Roblox Dev/`)
- `Design/Game Design Doc.md`: pitch, core loop, progression, scope (`Design/` also holds Feature Pipeline, How to Add a Character, User Inputs, 3D Assets)
- `Session Log.md`: one line per work session; `Research/Index.md`: research notes by area; `Planning/`: early plans
- `Systems.md`: every system and its status
- `Bug Log.md`: open and fixed bugs
- `Backlog.md`: what's next
- `Analytics/`: weekly analytics notes (template in `Templates/Weekly Analytics.md`)
- `Design/3D Assets.md`: 3D pipeline and asset list; model files in `Assets/3D/`

Use Obsidian `[[wikilinks]]` when linking notes.

## 3D models (Hunyuan3D-2 mini-Turbo, shape only)
Run from `Hunyuan3D/`:
`.venv\Scripts\python generate.py <image or folder> [--faces 18000] [--quality fast|normal|high]`
Output `.glb` files go to `Roblox Dev/Assets/3D/`, cleaned and reduced under 20,000 triangles. Texture generation needs about 16 GB of video memory, which this PC lacks (8 GB), so color models in Studio.
License: Tencent's license does not apply in the EU, UK or South Korea.

## Rules
- Uploads to the user's Roblox account (meshes, textures, images, audio, animations) and Studio AI generation (`generate_mesh`, `generate_texture`, `generate_material`, `insert_asset` of vetted free assets) are pre-approved since 2026-10-28; log every asset id. Publishing the game still needs the user. Older "needs the user's OK" notes about uploads below are superseded.
- Server decides currency, rewards, purchases, inventory and cooldowns. Never trust the client.
- Use ProfileStore for player data.
- Keep meshes under 20,000 triangles.
- Keep it simple: Studio + MCP plugin + Git. No Rojo unless asked.

## Hardware
RTX 4060 Ti (8 GB), 32 GB RAM, Windows 11. System Python is 3.14 (too new for Hunyuan3D), so always use `Hunyuan3D/.venv`.
