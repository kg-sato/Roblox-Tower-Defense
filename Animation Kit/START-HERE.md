# Animation Kit (fwjelaa) — start here

Installed 2026-10-24 from the download `Roblox-Animations-by-fwjelaa` by **fwjelaa (FWJ STUDIOS)**. Free to use in our own game; **credit fwjelaa** if we show or share the method, and do not re-upload the pack as our own (see `docs/CREDITS.md`).

Project review and decisions: `Roblox Dev/Research/3D and Art/Animation Kit Review.md` (read that first).

## What it is
A pipeline that makes **humanoid R6 or R15 character animations** (runs, combos, sword swings, dashes, emotes) as Roblox KeyframeSequences. Two paths:
- **Path A, Blender + Python.** Needs Blender 4.2+ and the Blender MCP. **Not usable right now:** the Blender folder on this PC (`C:\Program Files\Blender Foundation\Blender 4.3`) has no `blender.exe`, so Blender needs reinstalling first.
- **Path B, Studio only.** `roblox/AnimKit.luau` is a ModuleScript that writes keyframes straight into Studio through the Studio MCP (`execute_luau`). No Blender needed. **Installed in `Claude.rbxl` on 2026-10-24** as `ServerStorage.AnimKit` (trimmed: the HttpService helpers `fetch/load/verify` were left out). Test emote: `ServerStorage.Animations.R6_Cheer`.

## What it is not
- Not a particle / aura / VFX tool. The Sol's RNG style reveal effects are separate (see `Roblox Dev/Research/VFX and Animation/Magical Roll Animation Playbook.md`).
- Not for our current pets. They are procedural 3D models, and the kit only knows the standard R6 and R15 rigs (plus Sword, Spear, Dagger, Axe props).

## Folder
| Path | What |
|---|---|
| `kit/` | Python: rig data, animation API, export, checks, preview, headless runner (`python -I kit/run.py ...`), local file server for Studio, optional Open Cloud uploader |
| `roblox/` | `AnimKit.luau` (Studio module), installers, example game scripts (combo, movement, weapon grip) |
| `anims/` | 40+ example animation recipes as short Python files (helpers start with `_`) |
| `docs/` | `GUIDE.md`, the method prompt, `PACK-INSTRUCTIONS.md` (the pack's own Claude instructions, renamed so they do not auto-load), `research/` (5 research docs with timing numbers) |
| `out/`, `ref/` | empty; exports and reference clips go here |
| `config.json` | empty; only needed for the optional uploader |

## Left out on purpose
- `out/` (about 19 MB of finished example animations as .rbxmx/.luau/.json), `images/`, `ref/PunchRef/` example clip. They are in the original download if needed.
- The pack's `.claude/settings.json` (it pre-approves shell commands) and `.secrets/` (API key folder). Do not add an API key unless we decide to auto-upload.

## Safety notes from the review
- The kit's code was read before copying: no hidden network calls. The only network uses are `kit/serve.py` (127.0.0.1 only, never serves `.secrets`), Studio fetching from that local server, and `kit/upload.py` (sends your own API key only to `apis.roblox.com`, only when we run it).
- `kit/serve.py` and the Studio installers switch `HttpService.HttpEnabled` on for one request and restore it. Do not leave it on in the published game.
- Only upload or publish animations when the owner says so.
- Run Python with `-I` (isolated mode) from this folder: `python -I kit/run.py check`.
