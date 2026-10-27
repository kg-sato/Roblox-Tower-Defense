---
date: 2026-10-26
tags: [research, workflow, game-feel, tools]
---
# Workflow Gaps and Game Feel

This follows [[Research/TikTok VFX Reference Study|TikTok VFX Reference Study]]. It answers specific questions about what our pipeline is missing and how to add it, then lists what was built.

## 1. Questions and answers (sourced)

| Question | Answer | Source | Status for us |
|---|---|---|---|
| Can uploads skip the manual Asset Manager import? | Yes. Open Cloud `POST https://apis.roblox.com/assets/v1/assets` (form fields `request` + `fileContent`, header `x-api-key`), then poll `GET /assets/v1/operations/{id}` until `done`, which returns `assetId`. Types: Model (.fbx/.gltf/.glb/.rbxm), Decal/Image (.png/.jpg/.bmp/.tga, under 8000 px), Audio (.mp3/.ogg/.wav/.flac, up to 7 min, 100 per month if ID-verified, else 10), Animation (.rbxm/.rbxmx, "files edited outside Studio might not upload or function"), Video (.mp4/.mov). 20 MB per call. Only .fbx content can be updated later. | [Roblox: Usage guide for assets](https://create.roblox.com/docs/cloud/guides/usage-assets) | **Built** `tools/upload_asset.py` (dry run tested). Needs your API key and OK before any real upload |
| Can the built-in Studio MCP do it? | No upload from local files: `upload_image` takes **HTTP URLs**, `store_image` makes a local URI for other tools. It also has `generate_procedural_model`, `generate_material`, `generate_mesh`, `insert_asset`, input simulation, and a `playtest` subagent. | [Roblox: Studio MCP server](https://create.roblox.com/docs/en-us/studio/mcp) | Unchanged; Open Cloud is the upload path |
| Does Studio's device emulator test phone performance? | No. Roblox says the emulator is for layout and touch, not performance. Profile on the device: MicroProfiler (Ctrl+Alt+F6, or the network web view via Settings), Developer Console F9 Memory tab, and 10 to 15 minute sessions to catch thermal throttling. | [Roblox: Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware) | **Needs you**: one session on a real phone |
| How do we review motion without a person watching? | Record the Studio window to video and make frame sheets. No ffmpeg on this PC; OpenCV + Pillow in the Hunyuan3D venv are enough. `gdigrab` has known window-capture bugs (FFmpeg ticket #11542). | [FFmpeg trac #11542](https://ffmpeg.org/pipermail/ffmpeg-trac/2025-April/073280.html) | **Built** `tools/record_window.py` (PrintWindow, works with Studio behind other windows, about 20 fps at 1080p) |
| How can an ability be fired with a better feel? | Layer several cues on the same instant: a brief freeze or "impact frame" (rule of thumb 50 to 100 ms on heavy hits only), trauma-style shake (amount decays, offset uses amount squared and smooth noise), flash, knockback, sound. | [Wayline game feel](https://www.wayline.io/learn/game-feel/1), [Uhiyama UE5 hit feedback](https://uhiyama-lab.com/en/notes/ue/game-feel-hit-feedback/), [Godot checklist](https://forum.godotengine.org/t/game-feel-checklist-for-godot-4-hit-stop-trauma-shake-coyote-time-and-more/145340); origin: Squirrel Eiserloh, "Juice It or Lose It", GDC 2014 (not opened here) | **Built** (ImpactFX) |
| Should we use a camera-shake module? | Sleitnick's RbxCameraShaker (an EZ Camera Shake port) is the common one. Usage: multiply camera CFrame each frame at RenderPriority.Camera+1; LocalScript only. Community reports an abrupt `Stop()` with no fade. | [GitHub RbxCameraShaker](https://github.com/Sleitnick/RbxCameraShaker), [DevForum thread](https://devforum.roblox.com/t/ez-camera-shake-ported-to-roblox/98482) | Not needed: our camera already runs at Camera+1, and ImpactFX now gives a smooth decaying shake |
| Smear frames? | 1 frame usually, 2 for very violent actions; keep them on the arc and keep the silhouette. | [Rebus Farm](https://rebusfarm.net/blog/smear-frames-in-animation-how-animators-create-fast-and-dynamic-motion), [Wikipedia: Smear frame](https://www.wikipedia.org/wiki/Smear_frame) | **Built** for shots (stretched bolt) |
| Telegraphs? | No standard duration; tune in playtests. A ground outline that fills over the warning shows both area and time left. | [Bugnet: attack telegraphs](https://bugnet.io/blog/how-to-design-enemy-attack-telegraphs), [itch.io thread](https://itch.io/post/1790933) | **Built** for the boss escape timer |
| What do the Roblox VFX creators use, and what does it cost? | VFX Forge: pay-what-you-want, suggested minimum $16.67 USD (particles, beams, trails, mesh VFX, lightning, camera shake, Bezier editor, scripting API). Moon Animator 2: about $29.99 one-time per a secondary blog (not confirmed on an official page). Creators in our TikTok study named Forge, Moon Animator and Eclipse Animator. No price found for Qwinkle Particles or Eclipse. | [VFX Forge on itch.io](https://zilibobi.itch.io/vfx-forge), [Moon Animator price (secondary)](https://thetoolstrunk.com/how-much-is-moon-animator/) | Purchases need you; not required for what's built |
| Animation upload without Studio? | Open Cloud lists Animation (.rbxm/.rbxmx). The community tool Asphalt uses a cookie-based route and calls it experimental; don't use cookies. For local testing, `KeyframeSequenceProvider:RegisterKeyframeSequence` gives a temporary id. | [Roblox assets guide](https://create.roblox.com/docs/cloud/guides/usage-assets), [Asphalt](https://github.com/jackTabsCode/asphalt), [KeyframeSequenceProvider](https://create.roblox.com/docs/reference/engine/classes/KeyframeSequenceProvider) | Try Open Cloud with a Studio-saved .rbxm once you OK it |

## 2. What was built and verified (2026-10-26)

| Item | Where | Check | Result |
|---|---|---|---|
| ImpactFX module: impact frame (ColorCorrection 0.06 s, flashes off = skipped, reduced motion = half), scorch mark, filling telegraph ring, smooth noise shake | `VFX/ImpactFX.luau` / `ReplicatedStorage.ImpactFX` | `ImpactFX.audit()` in Play | PASS (5/5: skip when flashes off, peak contrast 0.55, fill 5.70 at 50%, shake scales, nothing left after 1 s) |
| Camera shake: random per-frame jitter replaced by smooth noise | GameClient camera step | runs in every shake | PASS (no errors; used by ult, boss, leaks) |
| Shot smear: bolt leaves stretched along its path, arrives compact (no extra parts) | GameClient `shotFx` | real wave | PASS: 22 shots, 18 stretched bolts drawn (rest skipped by the existing effect cap) |
| Verdant Rend on big pets: crit from a tier 3+ pet plays AbilityFX down the lane, at most once per 6 s | GameClient `shotFx` | fake events: 2 crits 0.3 s apart | PASS: exactly 1 Rend, cleaned up |
| Ultimate and boss kill: impact frame + scorch (+ shake on boss kill) | GameClient | DebugUlt | PASS: contrast peak 0.55, scorch seen, 0 parts after 4.5 s |
| Boss escape warning: red ring at the crystal fills over the last 8 s | GameClient `applySnapshot` | fake snapshots counting down | PASS: fill 0.1 to 13.1 studs (max 13.4), removed when the timer ended; screenshot shows it reading clearly |
| Ultimate full-screen flash 0.95 to 0.7 | GameClient | recorded motion showed a whole white frame | PASS: measured peak 0.62 one frame in |
| Window recorder | `tools/record_window.py` | 8 s recording of ult + Rend | PASS: 157 frames at 19.6 fps, sheets in `Research/VFX Renders/motion/` |
| Open Cloud uploader | `tools/upload_asset.py` | dry run on Frostling.fbx | PASS (dry run only; nothing uploaded) |
| Frame time | Play, this PC | idle vs ult vs 3 Rends (High) | about 29 ms in all three (Studio capped around 34 fps in the background); no measurable cost **on this PC**. Phone UNVERIFIED |

## 3. Motion review notes (first time our effects were watched as video)

From `ult_rend_view_sheet_*.jpg`:
- **Ultimate:** golden gather (0.8 to 1.2 s), a whole white frame at 1.3 s (now softened to 0.7), then a large translucent dome and rings (1.4 to 2.3 s) with gold spokes. The scorch sits under the rings and is barely visible during the ult; it shows afterwards.
- **Verdant Rend:** a sparkle at the pets (4.0 to 4.1 s), a thin streak (4.2 s), a violet ring at the lane end (4.3 to 4.5 s) and a fade by 4.7 s. The order reads well. The crescent is only a streak at game distance: a future pass could use a textured Beam (needs an uploaded texture) for a real crescent shape.

## Gaps

- Nobody has felt the impact frame or shake in person; the recording is 20 fps, so 1 to 2 frame events (the 0.06 s impact frame) may not appear in it.
- Real boss stage not played with the new ring; tested with fake snapshots.
- No phone test; Roblox's own docs say Studio can't stand in for one.
- The Open Cloud uploader has only been dry-run. A real upload needs your API key in `ROBLOX_API_KEY` and your OK; Animation uploads via Open Cloud are untested.
- Qwinkle and Eclipse Animator prices not found; the Moon Animator price is from a secondary source.
