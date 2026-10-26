# 04 - Blender MCP servers, AI animation tools, and the Blender 5.x animation API

Research date: **2026-10-21**. Every claim has a source with a date, or is marked **(verified locally)** when I ran it on this machine (Blender 5.1.2, Windows 11), or **(unverified)** when it comes from a single secondary source or was assembled by me and not run.

---

## 0. TL;DR for the tutorial

1. **"MCP for Blender" and `ahujasid/blender-mcp` are the same project.** It was renamed on 2026-09-16. The PyPI package `blender-mcp` is now `mcp-for-blender`, and the repo moved to `ahujasid/mcp-for-blender`. Old configs (`uvx blender-mcp`) still work through a compatibility wrapper. The author is Siddharth Ahuja. It's MIT-licensed, the current version is 2.2.2 (2026-10-20), and the repo has about 31.9k stars.
2. **There is now an official MCP server from Blender Lab, the Blender Foundation's innovation space** (`projects.blender.org/lab/blender_mcp`, v1.0.3, 2026-09-11). It needs Blender 5.1+ and bundles the 5.x Python API docs as a searchable tool. It has no animation-strip viewer. Its add-on uses the **same default port 9876** as MCP for Blender, so if both add-ons run, one of them must move to another port.
3. **For animation work, use MCP for Blender.** Its `look(mode="frames")` returns an animation strip and `shading="xray"` shows bones, which gives Claude a built-in visual review loop. If you want official API-doc lookups, add the Blender Lab server on a second port.
4. **This machine's addon is outdated.** It reports protocol 13, but the 2.2.x server expects 14. Run `uvx mcp-for-blender install-addon`, then restart Blender, or disable and re-enable "Interface: MCP for Blender" (verified locally via `get_addon_status`).
5. **The Blender 5.x F-curve API:** `action.fcurves` was **removed in 5.0** (2025-11-18). F-curves now live in a channelbag per slot: `anim_utils.action_get_channelbag_for_slot(action, slot).fcurves` (verified locally, see section 4.3).
6. **`keyframe_insert` is keyword-only after `data_path` in 5.1.2.** `pb.keyframe_insert("location", 0, frame=1)` raises `TypeError: takes at most 1 positional argument` (verified locally). Old tutorials pass the index positionally, and that now breaks.
7. **The Blender-to-Roblox bridge to show is Cautioned's "RBXMonkey" Blender Animations Plugin** (v3.1.2, 2026-10-17, works on Blender 5.2). It pairs a Blender add-on with a Studio plugin, live-syncs over port 31337, and supports R6/R15 Motor6D rigs. It is the community standard.
8. **Roblox's built-in Studio MCP has no animation tools and no animation skill.** It does have `execute_luau`, which can build `KeyframeSequence`/`Pose` data, plus `insert_asset` (which accepts animations) and `screen_capture`. Roblox's roadmap lists "Avatar Prompt-to-Animation" for **late 2026**; it has not shipped yet.
9. **Mocap or Mixamo onto R6 is lossy.** R6 has 6 parts and no elbows or knees, so the usual route is mocap → R15 → convert to R6. For R6, hand-keyed pose-to-pose animation from Claude is the better story. Roblox's own video "Animation Capture - Body" is **R15 only** and takes clips under 15 seconds.
10. **Community reaction matters for the video's framing.** On the DevForum (Oct 2026), "obviously AI generated animations" is already an insult, and a pack suspected of being "asked Claude to create" got called out for wrong sword angles and pivots. Position the video as "Claude does the grunt work, you direct and verify," not "one prompt, done."

---

## 1. Blender MCP servers (state on 2026-10-21)

### 1.1 MCP for Blender (formerly `blender-mcp`), by Siddharth Ahuja

| Fact | Value | Source / date |
|---|---|---|
| Maker | Siddharth Ahuja (ahujasid@gmail.com) | PyPI 2.2.2, 2026-10-20 |
| Repo | github.com/ahujasid/mcp-for-blender (old URL redirects); created 2025-03-07; 31,873 stars | GitHub API, 2026-10-21 |
| Package | `mcp-for-blender` 2.2.2, Python >= 3.10; 19 releases since 1.9.0 (2026-09-01) | PyPI JSON, 2026-10-21 |
| Rename | `blender-mcp` → `mcp-for-blender`; "nothing breaks, `uvx blender-mcp` still works" | Issue #366, 2026-09-16 |
| Addon | `addon.py` bl_info `"version": (1, 8)`, `PROTOCOL_VERSION = 14`, `"blender": (3, 0, 0)` | repo HEAD, 2026-10-21 |
| Transport | Addon runs a TCP socket server in Blender (`localhost:9876`); MCP server talks JSON over that socket (`{type, params}` → `{status, result|message}`) | README |
| License | MIT | README badge |

**Tools (9):**

| Tool | Use |
|---|---|
| `execute_blender_code` | Run Python in your live Blender |
| `look` | Shows the scene as one image. Modes: `viewport`, `camera`, `angles` (auto-framed multi-view), `frames` (**animation strip**, `frame_count` 2-12 or explicit `frames`). Shading: `solid`, `material`, `rendered`, `wireframe`, `xray` (bones in front). Can also show an image file or "Render Result". |
| `get_scene_info` | One line per object with chosen fields; drill in with `root`/`query` |
| `generate_3d` | Tripo / Hunyuan3D / Hyper3D Rodin / Meshy model generation |
| `search_assets` / `import_asset` | Poly Haven, Sketchfab, Poly Pizza |
| `get_addon_status` | Blender version, addon version and protocol, enabled libraries and generators |
| `disable_telemetry`, `record_trajectory_feedback` | Data-collection controls |

**Install (exact commands, from the README on PyPI 2.2.2):**

```powershell
# One-line installer: installs uv, configures detected clients (Claude Desktop, Claude Code, Codex,
# Cursor, VS Code, Windsurf, OpenCode, Antigravity), installs and enables the addon, keeps .bak copies
irm https://www.mcp-for-blender.com/install.ps1 | iex

# Without running a script:
winget install --id=astral-sh.uv -e
uvx mcp-for-blender setup
```

Manual install:

```bash
# 1. uv (use the official installer, not pip install uv)
winget install --id=astral-sh.uv -e

# 2a. Claude Code
claude mcp add blender uvx mcp-for-blender
#     user-wide + telemetry fully off (standard Claude Code flags; this combination is unverified):
claude mcp add --scope user -e DISABLE_TELEMETRY=true blender -- uvx mcp-for-blender

# 3. Blender addon
uvx mcp-for-blender install-addon
#   then in Blender: Edit > Preferences > Add-ons > enable "Interface: MCP for Blender"
#   N-panel > "MCP for Blender" tab > Start MCP Server (it auto-starts when Blender opens)
```

Claude Desktop (`Settings > Developer > Edit Config` → `claude_desktop_config.json`):

```json
{ "mcpServers": { "blender": { "command": "uvx", "args": ["mcp-for-blender"] } } }
```

- **Windows `spawn uvx ENOENT`:** GUI clients don't inherit PATH. Use the full path (`where uvx` → `C:\Users\<you>\.local\bin\uvx.exe`) or `"command": "cmd", "args": ["/c","uvx","mcp-for-blender"]`. Quit Claude Desktop from the system tray, not just its window.
- **Pin Python if conda or pyenv gets in the way:** `"args": ["--python","3.11","mcp-for-blender"], "env": {"UV_PYTHON_PREFERENCE":"only-managed"}`. To clear a broken cache: `uv cache clean mcp-for-blender blender-mcp && uvx --refresh mcp-for-blender`.
- **Update:** `uvx mcp-for-blender@latest update` (use `@latest` the first time; versions before 2.1.7 have no `update`). Then restart the client and re-enable the addon.
- **Several Blenders at once:** `uvx mcp-for-blender --port 9877`; env vars `BLENDER_HOST`, `BLENDER_PORT`.
- **Safe mode:** `BLENDER_MCP_SAFE_MODE=1` validates scripts before they run.
- **Only run one MCP client against the addon at a time.**
- **Telemetry:** an anonymous usage record (install ID, versions, OS, timestamp) is sent by default. Prompts, code, screenshots and scene data are opt-in only. `DISABLE_TELEMETRY=true` turns everything off.

**Free vs Premium** (mcp-for-blender.com/premium, read 2026-10-21; the page shows no date):

| Plan | Price | Standard gens/mo | High-quality gens/mo | Notes |
|---|---|---|---|---|
| Free | $0 | (bring your own Hunyuan3D / Rodin / Meshy keys) | - | All scene editing, Poly Haven, Sketchfab, Poly Pizza |
| Hobby | $10/mo | 25 | 0 | up to 3 computers |
| Pro | $20/mo | 25 | 8 | adds Tripo P2 |
| Studio | $60/mo | 60 | 30 | 3 concurrent gens |
| Max | $100/mo | 100 | 50 | 3 concurrent gens |
| Enterprise | custom | | | |

Failed generations don't count against the allowance, and unused ones don't roll over. **Animation needs nothing from Premium**, because Premium only adds model generation.

**Local state (verified 2026-10-21, `get_addon_status`):**

```text
blender_version 5.1.2 | addon_version (1, 8) | protocol 13, expected 14 -> up_to_date: false
generators: tripo off (Premium only), hunyuan3d off, hyper3d off, meshy "not in this addon version"
telemetry_consent: false
fix: uvx mcp-for-blender install-addon, then restart Blender or toggle the addon, then Start MCP Server
```

### 1.2 Blender Lab MCP Server (official, Blender Foundation)

| Fact | Value | Source / date |
|---|---|---|
| Home | blender.org/lab/mcp-server; source projects.blender.org/lab/blender_mcp | read 2026-10-21 |
| Releases | 26.04.10 pre-release (2026-04-10), v1.0.0 (2026-04-27), v1.0.2 (2026-09-08), **v1.0.3 (2026-09-11)**; repo updated 2026-09-29 | Gitea API |
| Requirement | **Blender 5.1 or newer** | blender.org page |
| License | GPL-3.0-or-later | manifest.json |
| Architecture | MCP client ⇄ stdio ⇄ `blender-mcp` (Python pkg `blmcp`) ⇄ TCP ⇄ Blender extension `mcp`; **default `localhost:9876`** | readme.md, `mcp_to_blender_server.py` |
| Security | The page says plainly: "executes LLM generated code in Blender without any guards". It recommends a VM. | blender.org page |

**Tools (24):** `execute_blender_code`, `execute_blender_code_for_cli` (background Blender process), `get_python_api_docs`, `search_api_docs`, `search_manual_docs`, `get_objects_summary`, `get_object_detail_summary`, `get_blendfile_summary_*` (datablocks, missing files, linked libraries, path info, usage guess; most also have `_for_cli` variants), `get_screenshot_of_area_as_image`, `get_screenshot_of_window_as_image`, `get_screenshot_of_window_as_json`, `jump_to_tab_by_name`, `jump_to_tab_by_space_type`, `render_thumbnail_to_path`, `render_viewport_to_path`.

**Install (from the Setup wiki):** install the extension (drag-and-drop from the blender.org page twice: once for the repo, once for the add-on), then:

```powershell
cd C:\
git clone https://projects.blender.org/lab/blender_mcp.git
```

```json
{ "mcpServers": { "blender": { "command": "uv", "args": ["--directory", "C:\\blender_mcp\\mcp", "run", "blender-mcp"] } } }
```

Claude Code equivalent (assembled by me, **unverified**). The name `blender-lab` avoids clashing with the `blender` entry for MCP for Blender:

```bash
claude mcp add blender-lab -- uv --directory C:\blender_mcp\mcp run blender-mcp
```

There is also an `.mcpb` bundle for clients that support it (Claude Desktop does). Alternative: `pip install git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp`.

**Gotchas**
- Its console script is also named `blender-mcp`, which is the old PyPI name of Ahuja's package. Don't confuse the two.
- Both add-ons default to port 9876. Change one in its add-on preferences (official: Host/Port prefs) or start MCP for Blender with `--port`.

### 1.3 Other servers worth knowing (GitHub, 2026-10-21)

| Repo | Stars | Last push | What |
|---|---|---|---|
| VxASI/blender-mcp-vxai | 300 | 2026-09-29 | Fork with its own add-on file; not interchangeable with Ahuja's |
| seehiong/blender-mcp-bridge | 79 | 2026-10-21 | 93 tools (modeling, sculpt, architecture/MEP), record/replay editor |
| sandraschi/blender-mcp | 62 | 2026-10-20 | Headless FastMCP, 41 "portmanteau" tools |
| bpy-dev/blender-mcp | 98 | 2026-10-06 | "Independent enhanced distribution of Blender Lab MCP" |
| **ThatGuyTHD/animation-mcp** | 4 | 2026-07-28 | **Roblox combat animations authored through Blender**; Studio import plugin; `claude mcp add animation-mcp --scope user -- uv --directory "<path>" run animation-mcp` |
| **mrosadevs/Roblox-AI-Animator-MCP** | 5 | 2026-08-28 | **Studio-native, no Blender.** 87 tools: rig inspect, `.anim.json` docs, two-bone IK, foot-slide fix, loop/mirror/retarget, self-critique, writes real `KeyframeSequence`. R15 semantic joint names; R6 mapped (`Torso→chest`, `Left Arm→arm.upper.left`). Motor6D first-class. |

### 1.4 Which one for animation, and why

**MCP for Blender**, for these reasons:
- `look(mode="frames", frame_count=8, shading="xray")` gives Claude an animation strip with bones visible in one call. That is the self-review loop animation needs. The official server only has single screenshots and `render_viewport_to_path`.
- It works on any Blender from 3.0 up and is already installed here.
- `get_scene_info` has a compact per-object summary, useful for reading a rig.

The official server's strength is `search_api_docs` / `get_python_api_docs` over the bundled 5.x docs, which directly prevents the stale `action.fcurves` code LLMs keep writing. If the video wants to show off "official," run it as a second server on another port, purely for doc lookup. Otherwise, a skill file with the correct 5.x API (section 2) covers the same gap with less setup.

---

## 2. Existing skills and agent prompts

### 2.1 Blender animation skills (Claude Code `SKILL.md` format)

| Repo / file | Date | Verdict |
|---|---|---|
| **EL4CTEO/blender-skills** → `skills/blender-animation/SKILL.md` (60 lines), plus `skills/blender-character-rigging`, `skills/blender-rendering`, `skills/blender-export-pipelines/references/roblox.md` | created 2026-10-14, pushed 2026-10-19, MIT, 336 stars | **Best found.** Targets Blender 5.2 and gets the channelbag API right (`action_ensure_channelbag_for_slot`, `fcurves.ensure(..., group_name=)`, and the note that "`action.fcurves` no longer exists"). Covers the blocking → splining workflow, loops (first and last frame identical), FPS, root motion, a `bake_action.py` script for control rig → export skeleton, mocap/BVH retargeting with `COPY_ROTATION`, cleaning mocap with `graph.decimate` and Butterworth, and the gotcha "set `frame_set(f)` before `pb.matrix = ...` + keyframe". Its Roblox reference (dated "verified 2026-10") covers 1 stud ≈ 0.28 m, FBX "Apply Scalings = FBX Unit Scale", "Add Leaf Bones off", and "don't animate bone scale (Roblox doesn't support it)". https://github.com/EL4CTEO/blender-skills |
| **elithril/blender-kiln** → `plugin/references/animation.md` | pushed 2026-10-21, MIT, 54 stars | **Best rules for scripted animation**, each measured on a real failure. Drive a bone in its own rest frame; solve the IK pole angle from the rest pose; keep legs at ≤ 95% of their length; measure a rotation's sign before using it; a P-frame loop keys 0..P-1; "judge motion in motion, and with numbers". Also measured AI generators (see section 3). https://github.com/elithril/blender-kiln |
| **arjun988/blender-skills** → `.claude/skills/animation/SKILL.md` (124 lines) + `references/walk-cycle.md`, `combat-animation.md`, `rigging/references/humanoid-rig.md` | pushed 2026-07-10, MIT, 373 stars | Good craft checklists (cycle frame tables at 30 fps, "stepped then Bezier", NLA for export). Workflow-level only, with no 5.x API specifics. https://github.com/arjun988/blender-skills |
| MAX-786/claude-3d-harness → `library/cc/blender-animation/SKILL.md` (306 lines), `animation-quality-gate`, `gaius/blender-rig` | pushed 2026-09-21 | Recipe-style, with a "Blender 5.x changed the Action API" warning and a layers/strips/channelbags loop. Wraps several pinned skill libraries. https://github.com/MAX-786/claude-3d-harness |
| kevinbadi/blender-skills | 2026-04-04, 177 stars | Product shots and camera animation only, no character animation. |
| powerhouse90/Blender-Superskill | 2026-04-26, 28 stars | General "improve MCP control" skill, not animation-specific. |

### 2.2 Roblox animation skills

| Repo / file | Date | Verdict |
|---|---|---|
| **adnvli/roblox-cinematic-animation** (`SKILL.md` + `references/animation-measured-tables.md`, `animation-recipes.md`, `character-animation.md`, `creature-animation.md`) | 2026-10-15, **AGPL-3.0**, 1 star | The most animation-specific one. It drives KeyframeSequences through a Studio MCP, and its locomotion tables come from real mocap (3 actors, 17-59 takes per row: pelvis bob as % of hip height, arm swing angles, elbow max, knee swing, pelvis and shoulder yaw), with scaling to R15 hipHeight 2.19 studs. Mine the numbers; respect AGPL if you copy text. https://github.com/adnvli/roblox-cinematic-animation |
| japalarp-creator/roblox-moon-animator-skill | 2026-10-12, MIT | Its "honesty contract" is worth borrowing: keep runtime motion, editable KeyframeSequence data and published asset IDs separate in every report, and never claim to drive Moon Animator without a tool. It also notes that Pose CFrames are joint-local (the `Motor6D.Transform` value). https://github.com/japalarp-creator/roblox-moon-animator-skill |
| TabooHarmony/roblox-brain (DevForum thread 2026-09-25) | pushed 2026-10-15, 119 stars | 29 skills including animation/VFX and Studio MCP. adnvli's skill builds on it. https://github.com/TabooHarmony/roblox-brain |
| EL4CTEO/roblox-skills → `roblox-characters-animation` | pushed 2026-10-17, MIT, 42 stars | Playback side (Animator, priorities, markers, IKControl). https://github.com/EL4CTEO/roblox-skills |
| sentinelcore/roblox-skills → `roblox-animations` | 2026-02-23, 28 stars | Playback, priority and blending reference. |
| AshExplained/roblox-skills → `roblox-animation-audio-feedback` | 2026-07-01, 26 stars | Game-feel level. |

**Gap: no skill covers "Claude drives Blender to author an R6/R15 animation and ship it to Roblox" end to end.** That is the tutorial pack's opening. The pieces exist: EL4CTEO's 5.x API, kiln's measured rules, adnvli's mocap tables, and the RBXMonkey bridge.

### 2.3 The official Roblox Studio MCP

**Standalone server, now archived:** `Roblox/studio-rust-mcp-server` was archived on **2026-04-03** ("no longer being actively developed"; Roblox points to the built-in server). Its last tool set was `run_code`, `insert_model`, `get_console_output`, `start_stop_play`, `run_script_in_play_mode`, `get_studio_mode`. Old Claude Code form: `claude mcp add --transport stdio Roblox_Studio -- <path>\rbx-studio-mcp.exe --stdio`.

**Built-in Studio MCP server** (doc last_updated 2026-10-20). Enable it with **Assistant > `…` > Manage MCP Servers > "Enable Studio as MCP server"**. Quick connect supports Claude Code and Claude Desktop. Windows JSON:

```json
{ "mcpServers": { "Roblox_Studio": { "command": "cmd.exe", "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"] } } }
```

The documented CLI command is `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`. The Claude Code form, assembled by me and **unverified** (the quick-connect button is the safe path): `claude mcp add Roblox_Studio -- cmd.exe /c "%LOCALAPPDATA%\Roblox\mcp.bat"`.

**Tools:** `script_read`, `multi_edit`, `script_search`, `script_grep`, `generate_mesh`, `generate_material`, `generate_procedural_model`, `wait_job_finished`, `search_asset`, `insert_asset` (models, meshes, images, audio, video, **animations**, packages), `upload_image`, `store_image`, `subagent` (explore and playtest types), `search_game_tree`, `inspect_instance`, `execute_luau` (Edit, Client or Server datamodel), `get_studio_state`, `start_stop_play`, `get_console_output`, `screen_capture` (optional camera position and look-at), `character_navigation`, `user_keyboard_input`, `user_mouse_input`, `http_get` (Roblox docs only), `skill`, `list_roblox_studios`. This machine's live server also exposes `segment_mesh`, which isn't in the doc table yet. Since 2026-08-19, **every tool takes a `studio_id`**; `set_active_studio` was removed (DevForum "Studio MCP: Multi-Agent Improvements", 2026-08-19).

**Animation tools: none.** You author animation through `execute_luau`, either by building a `KeyframeSequence > Keyframe > Pose` tree with joint-local CFrames, or by scrubbing `Motor6D.Transform` for preview. Check the result with `screen_capture` or a playtest.

**Built-in skills** (live list from this machine's `skill` tool, 2026-10-21): `rbx-create-skill`, `rbx-debug`, `rbx-device-simulator-lua`, `rbx-docs-search`, `rbx-perf-profiling`, `rbx-scene-analysis` (inspects animation and audio assets for memory), `rbx-unit-test`. **No animation skill.** `rbx-create-skill` lets you author a custom one, and the roadmap says Assistant will "follow your skill files" (mid 2026).

**Roadmap** (DevForum Creator Roadmap 2026 Spring Update, 2026-05-08): "**Avatar Prompt-to-Animation** - use text prompts to produce new complex avatar animations or modify existing ones (**Late 2026**)". Also: R15 platform avatars gained articulated fingers, clavicles and ball-of-foot joints, and **Animation Graphs** are available. The Fall Update (2026-09-18) adds "Unified agentic permission" for Assistant, MCP and plugins (late 2026). I found no evidence that Prompt-to-Animation has shipped as of 2026-10-21.

---

## 3. Who is already making Roblox animations with AI, and how well it works

| Route | What it is | Roblox fit | Quality reports |
|---|---|---|---|
| **Roblox Animation Capture** (Animation Editor) | Face: webcam, up to 60 s, dynamic heads. Body: upload `.mp4`/`.mov`, **< 15 s, one person, continuous single shot, stable camera** | **Body = R15 only** | Official docs only; I found no DevForum threads about jitter or foot sliding (searched 2026-10-21). |
| **Cascadeur** | Physics-assisted keyframing (AutoPosing, AutoPhysics). R6 and R15 characters come pre-rigged (tutorial for 2025.2+). "Export to Roblox" command bakes the interval and strips the control rig. | R6 + R15 | Cascadeur's own help warns: the Animation Editor may drop the last-frame pose (add an extra key), and it is sensitive to bone orientation, extra bones and mesh/bone name clashes. "Try export with and without mesh." |
| **Rokoko Create** (text-to-motion, launched 2026-04-03) and Rokoko Video (video mocap) | Browser-based; FBX export via Rokoko Studio; **5 free exports per month**, paid from $120/yr | Via Blender retarget | CG Channel: aimed at "prototyping, blocking", may need foot-slip cleanup. Body only. |
| **DeepMotion Animate 3D** | Video mocap, custom character upload | R15 support **unverified** (their forum thread asks the user to export the rig as FBX) | No solid reports found |
| **Mixamo** | ~2,500 free clips, auto-rigger | Through Blender retarget, or a community Studio plugin | Plugin thread (2023-04, last reply 2026-04): "R6 support" is done by **converting R15 → R6**; a user porting to R15 said "the arms bend inwards most of the time". Mixamo's auto-rigger fails on blocky, disconnected Roblox meshes. |
| **UniMate** (text → motion for any skeleton; SIGGRAPH Asia 2026 per kiln) | Research code (MIT), **weights CC BY-NC (non-commercial)** | Needs a skeleton with real knees and elbows | blender-kiln measured: a human walk and a dragon wing-flap approved; walks unusable on 4 quadrupeds; "a leg made of one bone cannot fold a knee" → **unusable on R6-like rigs** (unverified beyond kiln). |
| **MoCapAnything V2** (video → any rig, MIT) | | | kiln: "excellent on rigs from its own training set, unusable on two from outside it"; about 25 min per clip on CPU. |
| **LLM-authored keyframes** (Claude, ChatGPT via MCP) | Pose-to-pose keys written as code | Works for R6 and R15 | DevForum, 2026-10-18/19, on a 48-anim "R6 & R15 Combat Pack": replies say it looks like someone "asked claude to create a bunch of animations", "the sword ... isn't even angled correctly", "Obviously AI generated". Another reply: R6 versions were "converted from R15". **Raw LLM output reads as AI. Visual review and human direction are required.** |

**What works with LLM keyframing** (synthesised from kiln's rules, EL4CTEO's skill, the Roblox-AI-Animator-MCP design, and this kit):
- Plan in phases (anticipation → action → follow-through → settle) and key golden poses first, with `CONSTANT` interpolation while blocking.
- Use measured reference numbers (adnvli's tables: run pelvis bob ≈ 14% of hip height, arm swing +29°/-59°, and so on) instead of "make it look natural".
- **Measure a rotation's sign before using it.** This is the number-one LLM failure: limbs going the wrong way.
- Judge from a frame strip (`look mode=frames`) plus numbers (foot height, loop seam), never from a single frame.

**What doesn't:** one-shot "make a combo" prompts, mocap generators on rigs outside their training set, and anything needing contact accuracy (props, weapons) without a constraint or IK pass.

### 3.1 Is mocap/Mixamo → R6 a thing?

Partly, and it's lossy. R6 Motor6Ds are `RootJoint` (HumanoidRootPart→Torso), `Neck`, `Left/Right Shoulder` and `Left/Right Hip`, so each limb is **one rigid part**. Every converter therefore throws away elbow and knee bend and usually aims the R6 limb along the upper-limb (or shoulder→hand) direction. Expect stiff arms, feet clipping the floor during crouches, and floaty punches. The 2026-10-20 DevForum suggestion "AI-Assisted R6 to R15 conversion" confirms there is **no official Roblox converter in either direction**. The reply argued for documented deterministic retargeting instead.

**Recommendation for the pack:** use R6 for the "Claude hand-keys it" episode, which suits R6's stylised, snappy look. Use R15 for any mocap or Animation Capture comparison.

### 3.2 Getting Blender animation into Roblox (needed for every episode)

- **Cautioned "RBXMonkey" Blender Animations Plugin**: https://github.com/Cautioned/Blender-Animations-Plugin. GPL-3.0, 110 stars, **v3.1.2 2026-10-17**. 3.1.0/3.1.1 (2026-10-09) say "Blender 5.2 should now work properly". It's a fork of Den_S's original exporter (DevForum 2017). The Blender add-on (N-panel "RBXMonkey") runs a server on **port 31337**; the Studio plugin (Creator Store asset 16708835782) connects through its "Blender Sync" tab. Features: import/export both ways, **live sync**, bones synced as Motor6Ds, and "easing transfers losslessly where possible". Studio needs HTTP/network permission for the plugin.
- **R6 IK+FK Blender rig v2.5** (DevForum, created 2025-03-31, active to 2026-10-18; requires the Cautioned plugin, works on 4.2+): IK/FK blend sliders, prop and tool attachment points. Good stock rig for the R6 episode.
- **FBX path** (Animation Editor `⋯ > Import > From File` on a standard rig → convert to `CurveAnimation` → save for an asset ID): known **-180° Motor6D track** problem on multi-mesh rigs. Roblox adds Motor6D tracks for every MeshPart; the fix is to delete those tracks or zero them (DevForum 2025-10-22). Axes: Roblox is +Y up / -Z forward, Blender is +Z up / -Y forward.
- **Roblox rotation semantics:** KeyframeSequence Poses are joint-local CFrames interpolated by shortest-path quaternion. CurveAnimation can be Euler (with a chosen order) or quaternion (Curve Editor doc). **`PoseEasingDirection` In/Out are backwards** compared with TweenService and most tools ("for legacy compatibility reasons", engine enum docs). `PoseEasingStyle` = Linear, Constant, Elastic, Cubic, Bounce, CubicV2. `KeyInterpolationMode` (curves) = Constant, Linear, Cubic.

---

## 4. Blender-side scripted animation with bpy (4.4 → 5.2)

Version facts (developer.blender.org release-notes index, read 2026-10-21): 4.4 introduced slotted actions (2025-03-18). **5.0 removed the legacy API** (2025-11-18). 5.1 came out 2026-03-17 and is installed here as 5.1.2. **5.2 LTS (2026-07-14) is the current stable.** 5.3 is in beta and 5.4 in alpha. 4.5 LTS is supported until July 2027.

### 4.1 Rotation mode: QUATERNION vs Euler

```python
pb = arm.pose.bones["RightArm"]
pb.rotation_mode = "QUATERNION"   # enum: QUATERNION, XYZ, XZY, YXZ, YZX, ZXY, ZYX, AXIS_ANGLE (verified 5.1.2)
pb.rotation_quaternion = Quaternion((1, 0, 0), math.radians(90))
pb.keyframe_insert("rotation_quaternion", frame=10, group="RightArm")   # keys W, X, Y, Z
```

- **Use QUATERNION for anything exported to Roblox.** Roblox poses are CFrames (quaternion, shortest path), so Euler order and gimbal issues stay out of the pipeline. Both kit files already do this (`rigs.py:232`).
- **Watch out:** Blender interpolates the 4 quaternion F-curves per component (not slerp), and q and -q are the same rotation. If neighbouring keys flip sign, the bone takes the long way round. Fix it before keying: `q.make_compatible(prev_q)` (exists in 5.1.2, verified). Keep adjacent keys under about 90-120° apart and add a breakdown key for bigger swings. Roblox will take the shortest path regardless.
- Use Euler only for single-axis hinges or spins beyond 180° (a wheel, a propeller). Clean them with `bpy.ops.graph.euler_filter()`.

### 4.2 Keyframes, interpolation, easing and handles per key

```python
# 5.x: everything after data_path is KEYWORD-ONLY (verified 5.1.2):
#   keyframe_insert(data_path, *, index=-1, frame=..., group="", options=set(), keytype='KEYFRAME')
pb.keyframe_insert("location", index=2, frame=12)          # OK
# pb.keyframe_insert("location", 2, frame=12)              # TypeError in 5.1.2

kp = fc.keyframe_points[i]
kp.interpolation = "BACK"        # CONSTANT LINEAR BEZIER SINE QUAD CUBIC QUART QUINT EXPO CIRC BACK BOUNCE ELASTIC
kp.easing = "EASE_OUT"           # AUTO EASE_IN EASE_OUT EASE_IN_OUT
kp.back = 1.5                    # overshoot for BACK; kp.amplitude / kp.period for ELASTIC
kp.handle_left_type = kp.handle_right_type = "AUTO_CLAMPED"   # FREE ALIGNED VECTOR AUTO AUTO_CLAMPED
fc.update()                      # re-sort and recalc handles after edits
# A key's interpolation governs the segment FROM that key TO the next one (same idea as a Roblox Pose's easing).
# New-key defaults: bpy.context.preferences.edit.keyframe_new_interpolation_type ('BEZIER'),
#                   .keyframe_new_handle_type ('AUTO_CLAMPED')
```

**Blender → Roblox easing map.** Anything Roblox can't represent must be **baked** into denser keys:

| Blender | Roblox Pose EasingStyle | Note |
|---|---|---|
| CONSTANT | Constant | |
| LINEAR | Linear | |
| BEZIER (auto handles) | Cubic (InOut) | approximate |
| BOUNCE / ELASTIC | Bounce / Elastic | **swap EASE_IN↔Out**: PoseEasingDirection is reversed |
| SINE QUAD QUART QUINT EXPO CIRC BACK | (none) | bake: key every 1-2 frames, LINEAR between |

### 4.3 The correct Blender 5.x way to reach F-curves (verified on 5.1.2)

`action.fcurves`, `action.groups` and `action.id_root` were **removed in 5.0**. In 5.1.2, `'fcurves' in bpy.types.Action.bl_rna.properties` is `False`. The structure is: Action → `slots` (one per animated ID) and `layers[] → strips[] (KEYFRAME) → channelbags[]` (one per slot) → `fcurves` / `groups`.

```python
from bpy_extras import anim_utils

ad = arm.animation_data
action, slot = ad.action, ad.action_slot

# A) the channelbag of the slot this object is actually using (most common)
cb = anim_utils.animdata_get_channelbag_for_assigned_slot(ad)        # may be None if nothing is keyed
# equivalent:
cb = anim_utils.action_get_channelbag_for_slot(action, slot)
for fc in cb.fcurves:
    print(fc.data_path, fc.array_index, len(fc.keyframe_points))     # e.g. pose.bones["RightArm"].rotation_quaternion 0 3

# B) every F-curve in the action, all slots/layers/strips
for layer in action.layers:
    for strip in layer.strips:
        for bag in strip.channelbags:
            for fc in bag.fcurves:
                ...

# C) find / create / ensure one F-curve (5.0+ helpers)
cb = anim_utils.action_ensure_channelbag_for_slot(action, slot)     # creates layer + strip if missing
fc = cb.fcurves.find('pose.bones["RightArm"].rotation_quaternion', index=0)
fc = cb.fcurves.ensure("location", index=2, group_name="Object Transforms")  # 'action_group=' became 'group_name='
# also on the action: action.fcurve_ensure_for_datablock(datablock, data_path, index=..., group_name=...)
```

Available in 5.1.2 `anim_utils`: `action_ensure_channelbag_for_slot`, `action_get_channelbag_for_slot`, `action_get_first_suitable_slot`, `animdata_get_channelbag_for_assigned_slot`, `bake_action`, `bake_action_iter`, `bake_action_objects(object_action_pairs, *, frames, bake_options)`, `bake_action_objects_iter`. `ActionChannelbagFCurves` methods: `new`, `new_from_fcurve`, `ensure`, `find`, `remove`, `clear`.

**Building an action purely from data**, without `keyframe_insert` (fast and deterministic; verified, evaluates to π at frame 12):

```python
act  = bpy.data.actions.new("CubeSpin")
slot = act.slots.new(id_type="OBJECT", name="Cube")          # identifier becomes "OBCube"
cb   = anim_utils.action_ensure_channelbag_for_slot(act, slot)
fc   = cb.fcurves.ensure("rotation_euler", index=2, group_name="Object Transforms")
fc.keyframe_points.add(3)
fc.keyframe_points.foreach_set("co", [1, 0.0,  12, math.pi,  24, 2 * math.pi])
for kp in fc.keyframe_points: kp.interpolation = "LINEAR"
fc.update()
ad = ob.animation_data_create()
ad.action = act
ad.action_slot = slot     # REQUIRED in 4.4+: assigning an action does not always auto-pick a slot
```

### 4.4 NLA, baking, frame rate

```python
# NLA push-down (verified): strips carry their own slot
track = ad.nla_tracks.new()
strip = track.strips.new("Spin", 1, act)            # (name, start, action); strip.action_slot auto-set ("OBCube")
# strip.blend_type REPLACE/ADD/COMBINE, strip.extrapolation, strip.repeat, strip.action_frame_start/_end

# Bake constraints/IK/drivers to plain FK keys before export (operator props verified 5.1.2):
bpy.ops.nla.bake(frame_start=1, frame_end=48, step=1, only_selected=True, visual_keying=True,
                 clear_constraints=False, clear_parents=False, use_current_action=True,
                 clean_curves=True, bake_types={'POSE'}, channel_types={'ROTATION', 'LOCATION'})
# enums (verified 5.1.2): bake_types POSE, OBJECT; channel_types LOCATION, ROTATION, SCALE, BBONE, PROPS
# leave SCALE out for Roblox, which does not play bone scale

# Frame rate: Roblox stores keyframe TIME IN SECONDS, so author at 30 fps (EL4CTEO, arjun988 and Cautioned workflows)
scene.render.fps = 30; scene.render.fps_base = 1.0
scene.frame_start, scene.frame_end = 1, 48
```

### 4.5 Other 5.x changes that break old animation scripts

- `context.space_data.action` (Dope Sheet) was removed. Use `context.active_action`.
- Bone selection moved: `pose.bones[i].select` is new; `bones[i].select/select_head/select_tail` were removed (use `edit_bones`). `bones[i].hide` now affects edit bones only; use `pose.bones[i].hide` for pose visibility.
- `INSERTKEY_XYZ_TO_RGB` was removed. The `ANIM_OT_convert_legacy_action` operator was removed in 5.1 (all actions are layered).
- 5.1 added a non-destructive **Gaussian Smooth** F-curve modifier, which must be first in the stack. Handy for mocap cleanup.
- Render: the EEVEE id is `BLENDER_EEVEE` again (was `BLENDER_EEVEE_NEXT`). `ImageFormatSettings.media_type` must be set **before** `file_format` (see section 5).
- Read the evaluated pose only after `scene.frame_set(f)`. Setting `pb.matrix` before `frame_set` gets overwritten by evaluation (EL4CTEO gotcha).

---

## 5. Rendering previews for review and for YouTube (Blender 5.x)

### 5.1 Fastest for Claude's own review: the MCP `look` tool

```text
look(mode="frames", frame_count=8, shading="xray", view="front", max_size=768)
```

This returns one strip image of sampled frames. Every setting it changes is restored afterwards. Use `frames=[1,6,12,18,24]` for exact frames and `view="camera"` to go through the scene camera.

### 5.2 Viewport playblast from a script: `bpy.ops.render.opengl(animation=True)`

**It does not work in background mode.** Running it under `blender -b` gives `Error: Cannot use OpenGL render in background mode (no opengl context)` (verified 5.1.2). Inside a UI session, such as one driven by MCP, it needs a 3D-View context override. The code below is **verified** in a GUI Blender 5.1.2: 12 PNGs rendered and a contact sheet built.

```python
import bpy, os
scene = bpy.context.scene
r = scene.render
r.resolution_x, r.resolution_y, r.resolution_percentage = 1920, 1080, 100
r.image_settings.media_type = "IMAGE"        # 5.x: set media_type BEFORE file_format
r.image_settings.file_format = "PNG"
r.filepath = "//preview/pb_####"

win = bpy.context.window_manager.windows[0]
area = next(a for a in win.screen.areas if a.type == "VIEW_3D")
region = next(rg for rg in area.regions if rg.type == "WINDOW")
space = area.spaces.active
space.shading.type = "SOLID"
space.overlay.show_overlays = False          # clean frames for YouTube (keep True + show_bones to show the rig)
with bpy.context.temp_override(window=win, area=area, region=region):
    bpy.ops.render.opengl(animation=True, view_context=True)   # view_context=False -> render from scene.camera
# operator props (5.1.2): animation, render_keyed_only, sequencer, write_still, view_context
```

Use `scene.frame_step = 2` for a quick half-rate pass. In the UI this is View > Viewport Render Animation.

### 5.3 Headless or background (official server's `_for_cli` tools, CI): Workbench render

```python
r.engine = "BLENDER_WORKBENCH"               # works under -b (verified 5.1.2)
sh = scene.display.shading
sh.light = "STUDIO"; sh.color_type = "MATERIAL"   # color_type: MATERIAL OBJECT RANDOM VERTEX TEXTURE SINGLE
sh.show_cavity = True; sh.show_object_outline = True; sh.show_shadows = False
bpy.ops.render.render(animation=True)
```

Command line: `blender -b file.blend --python-expr "..." -a`, or `--python script.py`.

### 5.4 Straight to MP4 (Blender 5.x names, verified 5.1.2)

```python
r.image_settings.media_type = "VIDEO"        # enum: IMAGE, MULTI_LAYER_IMAGE, VIDEO
r.image_settings.file_format = "FFMPEG"
r.ffmpeg.format = "MPEG4"                    # MPEG4 MKV WEBM AVI DV FLASH MPEG1 MPEG2 OGG QUICKTIME
r.ffmpeg.codec = "H264"                      # also AV1, H265, PRORES, ...
r.ffmpeg.constant_rate_factor = "HIGH"       # NONE LOSSLESS PERC_LOSSLESS HIGH MEDIUM LOW VERYLOW LOWEST CUSTOM
r.ffmpeg.ffmpeg_preset = "GOOD"              # BEST GOOD REALTIME
r.filepath = "//preview/anim_"
```

### 5.5 Frame strip or contact sheet without PIL (verified 5.1.2, Blender image API + numpy)

```python
import bpy, math, numpy as np
def contact_sheet(paths, out_path, cols=6, thumb_w=240):
    tiles = []
    for p in paths:
        img = bpy.data.images.load(p, check_existing=False)
        img.scale(thumb_w, int(img.size[1] * thumb_w / img.size[0]))
        w, h = img.size
        px = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(px)
        tiles.append(px.reshape(h, w, 4)); bpy.data.images.remove(img)
    h, w = tiles[0].shape[:2]; rows = math.ceil(len(tiles) / cols)
    sheet = np.ones((rows * h, cols * w, 4), dtype=np.float32)
    for i, t in enumerate(tiles):
        r_, c = divmod(i, cols)
        y0 = (rows - 1 - r_) * h               # Blender pixel rows run bottom-to-top
        sheet[y0:y0 + h, c * w:(c + 1) * w] = t
    out = bpy.data.images.new("contact_sheet", cols * w, rows * h, alpha=True)
    out.pixels.foreach_set(sheet.ravel()); out.filepath_raw = out_path; out.file_format = "PNG"; out.save()
    bpy.data.images.remove(out)
```

FFmpeg alternative (**unverified** here, ffmpeg not checked): `ffmpeg -i pb_%04d.png -vf "select=not(mod(n\,4)),scale=320:-1,tile=6x2" -frames:v 1 sheet.png`.

**YouTube tips:** render at 1920x1080 and 30 fps to match the Roblox authoring rate (60 fps only for slow-mo b-roll). Show the strip **and** the motion. Kiln's warning applies: "a contact sheet showed a jump as a body lying flat; the hip height said it rose 0.32 → 0.61 m."

---

## 6. Local verification log (2026-10-21)

Scripts are in the session scratchpad (`bpy_anim_test.py`, `bpy_anim_test2.py`, `bpy_playblast_test.py`, `bpy_render_props.py`). They ran in **separate** `--factory-startup` Blender 5.1.2 processes; the user's live Blender session was only inspected, never modified.

- `Action` has no `fcurves` property; layered action auto-created by `keyframe_insert`; slot `OBArmature`; 4 quaternion F-curves found through `action_get_channelbag_for_slot`, through layers/strips/channelbags, and through `animdata_get_channelbag_for_assigned_slot` (same object).
- Positional index in `keyframe_insert` → `TypeError`.
- Per-key `BACK` + `EASE_OUT` + `back=1.5` accepted; evaluated quaternion at f10 = (0.707, 0.707, 0, 0).
- `render.opengl` fails under `-b`; works in GUI with `temp_override`; Workbench `render.render(animation=True)` works under `-b`; `media_type="VIDEO"` → `FFMPEG` → `MPEG4`/`H264` accepted.
- Data-API action + explicit slot assignment evaluates correctly; NLA strip auto-assigns slot.
- The kit (`kit/animkit.py`) already uses `animdata_get_channelbag_for_assigned_slot` and keyword `frame=`, so it is 5.x-correct.

---

## Sources

**Blender MCP**
- PyPI `mcp-for-blender` 2.2.2 (released 2026-10-20): https://pypi.org/project/mcp-for-blender/ and JSON API https://pypi.org/pypi/mcp-for-blender/json
- PyPI `blender-mcp` 2.0.0 (compatibility wrapper; read 2026-10-21): https://pypi.org/project/blender-mcp/
- GitHub ahujasid/mcp-for-blender (created 2025-03-07, pushed 2026-10-20): https://github.com/ahujasid/mcp-for-blender
- Rename notice, issue #366 (2026-09-16): https://github.com/ahujasid/mcp-for-blender/issues/366
- Premium pricing page (undated; read 2026-10-21): https://www.mcp-for-blender.com/premium
- Blender Lab MCP Server page (read 2026-10-21): https://www.blender.org/lab/mcp-server/
- Blender Lab repo + releases v1.0.3 (2026-09-11), Setup wiki: https://projects.blender.org/lab/blender_mcp and https://projects.blender.org/lab/blender_mcp/wiki/Setup
- ThatGuyTHD/animation-mcp (2026-06-17 → 2026-07-28): https://github.com/ThatGuyTHD/animation-mcp
- mrosadevs/Roblox-AI-Animator-MCP (2026-08-28): https://github.com/mrosadevs/Roblox-AI-Animator-MCP
- VxASI/blender-mcp-vxai (2026-09-29): https://github.com/VxASI/blender-mcp-vxai ; seehiong/blender-mcp-bridge (2026-10-21): https://github.com/seehiong/blender-mcp-bridge ; sandraschi/blender-mcp (2026-10-20): https://github.com/sandraschi/blender-mcp
- Existing tutorial content: DesignCode "Create 3D with Claude AI with Blender MCP" 26 min (March 2025, date unverified): https://yt.chop.dev/en/v/lCyQ717DuzQ ; The Rundown guide (2026-05-18): https://app.therundown.ai/guides/how-to-3d-model-anything-with-claude-blender

**Skills**
- EL4CTEO/blender-skills (2026-10-14 → 2026-10-19): https://github.com/EL4CTEO/blender-skills
- elithril/blender-kiln (pushed 2026-10-21): https://github.com/elithril/blender-kiln
- arjun988/blender-skills (2026-07-05 → 2026-07-10): https://github.com/arjun988/blender-skills
- MAX-786/claude-3d-harness (2026-09-18 → 2026-09-21): https://github.com/MAX-786/claude-3d-harness
- kevinbadi/blender-skills (2026-04-04): https://github.com/kevinbadi/blender-skills ; powerhouse90/Blender-Superskill (2026-04-26): https://github.com/powerhouse90/Blender-Superskill
- adnvli/roblox-cinematic-animation (2026-10-15): https://github.com/adnvli/roblox-cinematic-animation
- japalarp-creator/roblox-moon-animator-skill (2026-10-12): https://github.com/japalarp-creator/roblox-moon-animator-skill
- TabooHarmony/roblox-brain (pushed 2026-10-15) + DevForum thread (2026-09-25): https://github.com/TabooHarmony/roblox-brain , https://devforum.roblox.com/t/4894055
- EL4CTEO/roblox-skills (2026-10-17): https://github.com/EL4CTEO/roblox-skills ; sentinelcore/roblox-skills (2026-02-23): https://github.com/sentinelcore/roblox-skills ; AshExplained/roblox-skills (2026-07-01): https://github.com/AshExplained/roblox-skills
- UniMate (per blender-kiln; not checked directly, unverified): https://github.com/Friedrich-M/UniMate

**Roblox**
- Roblox/studio-rust-mcp-server (archived 2026-04-03): https://github.com/Roblox/studio-rust-mcp-server
- Built-in Studio MCP docs (last_updated 2026-10-20): https://create.roblox.com/docs/studio/mcp
- DevForum "Studio MCP: Multi-Agent Improvements and Connected AI Clients" (2026-08-19): https://devforum.roblox.com/t/4820583
- Creator Roadmap 2026 Spring Update (2026-05-08): https://devforum.roblox.com/t/creator-roadmap-2026-spring-update/4625473
- Creator Roadmap 2026 Fall Update (2026-09-18): https://devforum.roblox.com/t/4880208
- Animation capture docs (creator-docs main, read 2026-10-21): https://create.roblox.com/docs/animation/capture
- Emote/FBX import → CurveAnimation: https://create.roblox.com/docs/avatar/emotes/import ; Curve editor: https://create.roblox.com/docs/animation/curve-editor ; Animation Editor: https://create.roblox.com/docs/animation/editor
- PoseEasingDirection / PoseEasingStyle / KeyInterpolationMode enums: https://create.roblox.com/docs/reference/engine/enums/PoseEasingDirection , .../PoseEasingStyle , .../KeyInterpolationMode
- Cautioned/Blender-Animations-Plugin (v3.1.2, 2026-10-17): https://github.com/Cautioned/Blender-Animations-Plugin
- R6 IK+FK Blender Rig thread (2025-03-31 → 2026-10-18): https://devforum.roblox.com/t/r6-ik-fk-blender-rig-v191/3586405
- -180° Motor6D import thread (2025-10-22): https://devforum.roblox.com/t/4020911
- Mixamo Plugin thread (2023-04-15 → 2026-04-04): https://devforum.roblox.com/t/mixamo-plugin-released/2298825
- R6 & R15 Combat Animation Pack thread, AI critique replies (2026-10-18/19): https://devforum.roblox.com/t/4943274
- AI-Assisted R6→R15 conversion suggestion (2026-10-20): https://devforum.roblox.com/t/4946261
- Cascadeur "Export to Roblox Studio" (undated; images 2025-04): https://cascadeur.com/help/category/280 ; tutorial (2025.2+): https://cascadeur.com/tutor/robloxanimation
- CG Channel "Rokoko Create generates full-body animations for free" (2026-04-03): https://www.cgchannel.com/?p=175043
- DeepMotion forum, Roblox thread (undated): https://forum.deepmotion.com/t/y4hkf1j/roblox-animation-with-deepmotion

**Blender API**
- Blender 5.0 Python API release notes (5.0 released 2025-11-18): https://developer.blender.org/docs/release_notes/5.0/python_api/
- Slotted Actions: Upgrading to 4.4 (4.4 released 2025-03-18): https://developer.blender.org/docs/release_notes/4.4/upgrading/slotted_actions/
- Blender 5.1 Animation & Rigging notes (2026-03-17): https://developer.blender.org/docs/release_notes/5.1/animation_rigging/
- Release notes index (5.2 LTS 2026-07-14 current): https://developer.blender.org/docs/release_notes/
- API reference ActionChannelbag / ActionChannelbagFCurves / ActionKeyframeStrip (5.0): https://docs.blender.org/api/5.0/bpy.types.ActionChannelbag.html , https://docs.blender.org/api/5.0/bpy.types.ActionChannelbagFCurves.html , https://docs.blender.org/api/5.0/bpy.types.ActionKeyframeStrip.html
- Local runs of Blender 5.1.2 (`C:\Program Files\Blender Foundation\Blender 5.1\blender.exe`), 2026-10-21.
