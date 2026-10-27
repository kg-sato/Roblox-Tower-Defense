---
date: 2026-10-27
tags: [research, tools, process]
---
# Workflow Tools and Skills

Which tools, skills and connectors would speed up this project, ranked by value for effort. **Nothing here is installed.** Every item needs the user's OK first. Related: [[Feature Pipeline]], [[User Inputs]], [[Research/Process and Tools/Workflow Gaps and Game Feel|Workflow Gaps and Game Feel]].

Labels: **Fact** = read from a source or checked on this PC today (2026-10-27). **Inference** = our reasoning.

## 0. Done 2026-10-27 (user approved items 1 and 2)
- `tools/video_scenes.py` written and tested on `Rolling Animations.mp4` (50.7 s, 11 s to run): found 9 cuts and 2 motion spikes, wrote `motion.csv`, keyframes, 0.1 s burst frames and contact sheets (checked one sheet by eye: frames read left to right, row by row, 0.1 s apart). Usage: `python tools/video_scenes.py <video> <out_dir> [--thresh 0.3] [--burst-fps 10] [--burst-sec 1.0] [--spikes 6]`. Needs only ffmpeg and system Python.
- `tools/bin/yt-dlp.exe` downloaded from the official GitHub release (yt-dlp 2026.10.26, 23.6 MB); it runs and prints its version. Not yet tried on a TikTok link. Whisper not installed.

## 0b. Skills installed 2026-10-27 (user said "install all of these")
Source read first (clone in scratchpad): no network calls or settings writes found in the skill files; ponytail's hooks run Node locally only. Installed as plain files in `.claude/skills/` (this project only): `brainstorming` (obra/superpowers), `grill-me` + `grilling` (mattpocock/skills), `find-skills` (vercel-labs/skills), `design-taste-frontend` (leonxlnx/taste-skill), `ui-ux-pro-max` (nextlevelbuilder, path edited from the plugin variable to the project path), `agent-browser` (vercel-labs; also `npm i -g agent-browser` 0.39.4 and Chrome 156 for Testing, 199 MB, in `~/.agent-browser`).
- **Ponytail installed by the user 2026-10-27** (plugin 5.3.2, user scope, commit 09c434a, same as vetted). Skills: ponytail, ponytail-review, ponytail-audit, ponytail-debt, ponytail-gain, ponytail-help.
- **When to use each** is in the memory file `reference-installed-third-party-skills`. Short version: brainstorming for new features with unknowns; grill-me only on request; taste and ui-ux-pro-max for web pages, not Roblox UI (use `/make-ui`); agent-browser for scripted web checks, built-in browser stays default.
- Not tested in use yet; the skill list shows all six loaded. The npm postinstall for agent-browser was blocked by npm's script guard but `agent-browser install` still downloaded Chrome.

- **Codex:** the same skills, adapted, are packaged in [[Codex Handoff/README|Codex Handoff]] (dry-run install script, AGENTS.md snippet); untested in Codex.

## 1. What we already have (do not duplicate)
Checked on this PC today.
- **ffmpeg 9.0.2 is already installed** (WinGet link on PATH). The earlier note in [[User Inputs]] says it was missing; that is out of date.
- Python 3.14 (system, no OpenCV), `Hunyuan3D/.venv` (has OpenCV and Pillow, used by `tools/video_sheets.py`), Node, Git, winget 1.29.
- Not installed: yt-dlp, selene, stylua, luau-lsp, rokit, uv/uvx, gh, any Whisper package.
- Our scripts in `tools/`: `record_window.py` (records Studio at about 20 fps), `video_sheets.py` (contact sheets plus a sharpness curve), `video_info.py`, `studio_window.py`, `upload_asset.py` (Open Cloud, dry run only).
- Plugins on the account: roblox-dev (security, DataStore, typing, performance, UI, testing skills), Git/GitKraken, engineering, design. Project skill: `/make-ui`.
- Studio MCP (official, built into Studio) already offers more than we use. Fact, from the [Roblox docs](https://create.roblox.com/docs/en-us/studio/mcp.md): a `subagent` of type `playtest`, `user_mouse_input` / `user_keyboard_input` / `character_navigation`, and `screen_capture` with a custom camera position and look-at target. The page mentions no recording tool.

## 2. Ranked recommendations

| # | Item | Gap it closes | Install | Cost | Risk | Verdict |
|---|---|---|---|---|---|---|
| 1 | **Scene-detect and burst script on the ffmpeg we already have** (we write `tools/video_scenes.py`) | Stills miss effects under 0.5 s | Nothing to install | Free | None (local files only) | **Do it** (no OK needed beyond writing a script in `tools/`, which is outside `Roblox Dev/`, so confirm) |
| 2 | **yt-dlp** (single `yt-dlp.exe`) | Fetching the 19 TikToks (and later references) as files so #1 can read them | Download `yt-dlp.exe` from the GitHub release into a new folder, e.g. `tools/bin/` | Free, Unlicense | Downloads a binary; TikTok terms of use apply to saving videos; TikTok extraction breaks now and then | **Install** (after OK) |
| 3 | **faster-whisper** in its own venv, CPU, `small` model | Spoken tutorials (7 of the 19 links) become timestamped text | `python -m venv`, `pip install faster-whisper`; the model downloads from Hugging Face on first use | Free, MIT | Downloads a few hundred MB; CPU only is slow-ish, GPU on Windows needs extra CUDA libraries | **Maybe**: only if the tutorials' voice matters; many TikTok tutorials are text captions |
| 4 | **luau-lsp** (VS Code extension, plus `luau-lsp analyze` CLI) | Catches type and typo errors in `VFX/*.luau` and `Stages/*.luau` before they are pushed to Studio | VS Code Marketplace id `JohnnyMorganz.luau-lsp` | Free, MIT | Extension only; opt-in crash reports; our files use Studio instance paths with no Rojo, so some diagnostics will be noise until the Studio plugin sync is on | **Maybe**: good for the user's own editing, moderate for Claude |
| 5 | **Selene** (linter) | Unused variables, shadowing | Release binary or `cargo install` | Free, MPL-2.0 | Needs a Roblox standard-library file generated first; adds config files | **Skip for now** |
| 6 | **StyLua** (formatter) | Consistent style | winget id `JohnnyMorganz.StyLua` (per a third-party listing) | Free, MPL-2.0 | Would rewrite whole files and bury real diffs | **Skip** |
| 7 | **Open Cloud Luau Execution** | Run Luau headlessly (tests, place edits) without Studio | Needs an API key with `universe.place.luau-execution-session:write` | Free; 5 calls/min per key owner | An API key is on the user's "ask first" list; keys expire | **Hold**: the Studio MCP already runs Luau, so little gain |
| 8 | **Video MCP servers** (video-analyzer-mcp, Gemini-based ones) | Same as #1 and #3 in one package | `claude mcp add video-analyzer -s user -- uvx video-analyzer-mcp` | Needs `ANTHROPIC_API_KEY` (or a Gemini key) and installs uv | Unvetted package (version 0.1.2); a key; sends frames to a paid API | **Skip**: #1 plus #3 does it locally |
| 9 | **Third-party Roblox skills** (afrxo/roblox-agent-skills, sentinelcore/roblox-skills, brockmartin/roblox-game-skill) | More Luau advice | `/plugin marketplace add ...` | Free | Unvetted prompts running with our permissions; one star to about 1.2k installs; the roblox-dev plugin already covers the same areas | **Skip** |
| 10 | **Jest / TestEZ runners** | Unit tests | Needs Rojo-style layout or Open Cloud | Free | Conflicts with the "no Rojo" rule; we already test with MatchSim headless | **Skip** |

## 3. Why this order
- **Fact:** the user's stated worry is that stills are unreliable for fast effects and for judging animation. Items 1 to 3 address exactly that, and #1 costs no install because ffmpeg is already here.
- **Inference:** the scene-detect script should (a) cut a keyframe at each scene change with `select='gt(scene,0.3)'`, (b) dump a dense burst (8 to 12 fps) in a 1 s window around each cut and each frame-difference spike, (c) write a CSV of frame-to-frame difference (a motion curve), and (d) build contact sheets with time labels. The same script then works on our own `record_window.py` recordings, so Studio effects are judged the same way as the references. `video_sheets.py` already does (d) plus a sharpness curve.
- **Inference:** a model that "watches" at 1 frame per second (the Gemini MCPs) is coarser than a 10 fps burst, so it does not beat the local route for sub-second effects.
- Linting (4 to 6) is low value here because most bugs found so far were visual or runtime, not type errors, and the project deliberately avoids a Rojo toolchain.

## 4. Sources
- Studio MCP tool list and requirements: [Roblox Creator Docs, Studio MCP](https://create.roblox.com/docs/en-us/studio/mcp.md)
- Luau Execution API, scope and quota (5 calls/min per key owner): [Roblox Luau Execution](https://create.roblox.com/docs/cloud/reference/features/luau-execution.md). The beta or stable status differs between language versions of the docs; check the English page before relying on it.
- [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp): MIT, VS Code id `JohnnyMorganz.luau-lsp`, standalone `analyze`, Studio companion plugin. The page shows no release number.
- [Selene](https://github.com/Kampfkarren/selene): MPL-2.0. The page gives no install or release details; see the project's docs site.
- [StyLua](https://github.com/JohnnyMorganz/StyLua): MPL-2.0, README shows 2.6.0 in its install examples; install routes listed are GitHub release, cargo, npm, pip/uv, Aftman, VS Code extension (winget and Rokit are not listed by the README; the winget id comes from a [third-party listing](https://winstall.app/apps/JohnnyMorganz.StyLua)).
- [yt-dlp](https://github.com/yt-dlp/yt-dlp): Unlicense; the standalone `yt-dlp.exe` is recommended for Windows (bundled builds contain GPLv3+ code). I could not read the TikTok support list or the legal section.
- [PySceneDetect](https://github.com/Breakthrough/PySceneDetect): BSD-3-Clause, v0.7.2 (11 Oct 2026), `pip install scenedetect`, `scenedetect -i video.mp4 save-images`, needs OpenCV. A possible alternative to ffmpeg's scene filter, not needed.
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper): MIT, CPU int8 works; GPU on Windows needs CUDA 12 and cuDNN 9 libraries (the README points to a separate standalone package); large-v2 fp16 used about 4.5 GB on an RTX 3070 Ti.
- Video-watching MCPs and plugins (unvetted, third-party): [video-analyzer-mcp listing](https://glama.ai/mcp/servers/b4xi6lqssi), [claude-video-vision](https://github.com/jordanrendric/claude-video-vision), [mcp-video-analyzer](https://github.com/guimatheus92/mcp-video-analyzer).
- Roblox skill collections: [roblox-agent-skills](https://skillselion.com/marketplace/afrxo/roblox-agent-skills), [roblox-skills](https://claudemarketplaces.com/skills/sentinelcore/roblox-skills), [roblox-game-skill](https://github.com/brockmartin/roblox-game-skill). Star and install counts come from directory sites and may be stale.
- Test runners: [rproj docs on Jest and Open Cloud](https://docs.rs/crate/rproj/0.13.1). I found nothing on Luau code coverage.

## Gaps (what this research did not settle)
- **Not tested:** no tool here was installed or run, so install steps are from documentation only. In particular, yt-dlp's current TikTok support was not verified.
- **Not found:** a tool that records Studio with sound (the docs list no recording tool; our `record_window.py` has no audio), so sound timing is still checked by the analyzer, not by ear.
- **Not found:** a way to remove the roughly 3 s screenshot lag. The Studio MCP `screen_capture` with a custom camera might help; untested.
- **Not found:** phone-test automation. Real devices remain manual; Roblox's Studio device emulator is the closest and we already use an emulated 812x375 view.
- **Not checked:** Obsidian helper plugins and audio tools (the audio chain with Blender and ffmpeg already works); nothing missing there was reported.
- The uploads gap is unchanged: `tools/upload_asset.py` needs the user's Open Cloud key, which stays on the ask-first list.
- Verify live before installing anything: versions, winget ids and marketplace listings change.
