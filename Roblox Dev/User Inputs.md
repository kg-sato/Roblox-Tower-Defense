# User Inputs

Feedback, playtest notes, references and decisions from the user, recorded by the input-collector session. Newest section last. "Said" = the user's words. "Inference" = our guess, labelled.

Related: [[Feature Pipeline]], [[How to Add a Character]], [[Backlog]], [[Research/3D and Art/Backgrounds and Enemies - Mystic Victorian]]

## 2026-10-27

**Said**
- Star Drake's cutscene (STARFALL) works, but its effects need work.
- The game was tested on mobile and works fine.
- The user saved the latest place in `C:\Users\kgsat\Documents\Roblox` (so `Claude.rbxl` on disk should be current).

**Inference (not confirmed by the user)**
- "Effects need work" is not specific yet: unknown whether it means the star rain, the intro, the impact, or sound. Waiting for details.
- The mobile pass likely closes the open "phone test" items in [[Backlog]] at least partly, but the user did not say what was checked (placement, range circle, Lampwick Lane frame rate). Treat as "works fine overall", not as a full test.

### Reference links (2026-10-27)

**Said:** learn from ALL of these, whatever the category. Categories are the user's. Not watched yet by us; see "How to watch video" below.

**Tutorials we should learn from**
- https://www.tiktok.com/@remonbiz/video/7699782239218896142
- https://www.tiktok.com/@smudger13030/video/7699123611696860418
- https://www.tiktok.com/@lihfolk/video/7690631802628705550
- https://www.tiktok.com/@ashenbot/video/7688581633502350606
- https://www.tiktok.com/@vinallac/video/7679845239653289246
- https://www.tiktok.com/@solodev_t/video/7698808784466103585
- https://www.tiktok.com/@deadj.rodev/video/7698101726175350038

**UI we can try and implement (PRIORITY)**
- https://www.tiktok.com/@syuaey_/video/7695927409681435926
- https://www.tiktok.com/@usaaa804/video/7701017387746839840
- https://www.tiktok.com/@gfxcomet/video/7695567752261586206

**3D animation, better workflow, general ideas**
- https://www.tiktok.com/@deadj.rodev/video/7701021888679808279
- https://www.tiktok.com/@vos_studiostt/video/7694693977332665630
- https://www.tiktok.com/@iag0d_/video/7692633001246641428

**Insanely impressive: benchmark for a high-quality game; add to our game where applicable (PRIORITY)**
- https://www.tiktok.com/@syuaey_/video/7689557302894152963
- https://www.tiktok.com/@sixervfx/video/7698207431645564192
- https://www.tiktok.com/@blovica/video/7690294293059161357
- https://www.tiktok.com/@goodgood3d/video/7687326536504003872
- https://www.tiktok.com/@pr0_devv/video/7679364442194234646
- https://www.tiktok.com/@lambsx/video/7697543400899366175

**Said:** screenshotting sections of a video is not reliable, and the same goes for judging animations in Studio. They asked whether there is another way to watch video, possibly an external skill they install.

### How to watch video: research (2026-10-27, nothing installed or tested)
Earlier work (see [[Research/VFX and Animation/TikTok VFX Reference Study]]) used stills every 2 to 5 s, which can miss effects under 0.5 s. Options found by search (third-party, unvetted; check each repo before install, all need a key or local tools):
- **Download + ffmpeg + Whisper by hand:** yt-dlp fetches the file (TikTok works without cookies in some tools), ffmpeg scene-change filter (`select='gt(scene,0.3)'`) pulls a keyframe at each cut plus a contact sheet, Whisper gives a timestamped transcript. We then read frames + transcript. Needs the user's OK to install tools.
- **TikTok-specific skill:** [bggg-tiktok-readvideo](https://skillselion.com/skills/binggandata/bggg-skills/bggg-tiktok-readvideo) bundles ffmpeg, whisper.cpp, tesseract (on-screen text) with scene detection and keyframes.
- **Claude Code plugin:** [claude-video-vision](https://gittrend.io/repo/jordanrendric/claude-video-vision) (frames + audio analysis).
- **MCP, Claude Vision based:** video-analyzer-mcp (scene-detection keyframes + Whisper): `claude mcp add video-analyzer -s user -- uvx video-analyzer-mcp`.
- **MCP, Gemini based (the model watches the video, ~1 frame/s):** [Video Intelligence MCP](https://glama.ai/mcp/servers/a21xfc5hkd), gemini-video-mcp-server, [MCP Gemini Video Understanding](https://www.remoteopenclaw.com/mcp/ugarchance/mcp-gemini-video-understanding). Needs a Gemini API key; its own notes say rapid cuts may need frame-by-frame checks.
- **Inference:** the real gap is fast effects (under 0.5 s) and motion feel. Best fit is scene-detect keyframes plus a dense burst (8 to 12 fps) around each cut or impact, plus Whisper for tutorials. A Gemini-style model adds motion description but is coarser at 1 fps. Studio animations can be checked the same way by recording with `tools/record_window.py` and running the same extraction. TikTok terms of use apply to downloading.
- **Open decision for the user:** which route to install (needs OK; Gemini route needs an API key).

### Video-watching setup (2026-10-27, user approved my recommended route)
**Said:** go with the recommended route; fallback is `/plugin marketplace add https://github.com/jordanrendric/claude-video-vision` then `/plugin install claude-video-vision`.
**Done:** installed ffmpeg (winget Gyan.FFmpeg) and yt-dlp + curl_cffi (pip --user). Wrote `watch.py` (in the shared side-session-notes folder, not the repo): downloads a TikTok, saves scene-change keyframes and 10 fps contact sheets (5x4 tiles = 2 s each). All 19 links downloaded OK (no cookies needed) into `side-session-notes/.../videos/<id>/`. Checked one sheet: it shows flash and glow frames the old 2 to 5 s stills would miss.
**Not done:** Whisper transcripts (system Python is 3.14, likely no wheels; would need a venv) and any study of the videos' content. Some videos are long (one gives 449 sheets); tutorials will need targeted viewing. The plugin fallback is not installed (plugin installs are slash commands only the user can run).

### Sequencing (2026-10-27)
**Said:** study the reference videos only after the workflow-tools session (the one choosing skills and tools to install) has finished, because it adds new tools to the toolbox that help with UI and workflow overall.
**Status:** waiting. Videos are already extracted and ready. Not studying until the user says the workflow-tools work is done.

### Study started (2026-10-27)
**Said:** "Start" (study the videos). Done for the 9 priority links: see [[Research/VFX and Animation/Reference Video Study 2 - Priority Links]]. The other 10 are not studied yet. Method limit: 24 sampled frames per video, no audio.

### Full study done (2026-10-27)
**Said:** study all videos; STARFALL feels low effort because the beams are plain cylinders; learn how to do these effects from the videos and online sources; if still unclear, research privately; report errors in this chat, otherwise forward to the main chat.
**Done:** all 19 viewed (sampled frames, no audio); Roblox Beam docs read via search. Recipe: [[Research/VFX and Animation/Beam and Impact VFX Recipes]]. Forwarded to the main session. No errors.

### UI and design rework list (2026-10-28, said during the VFX 1:1 session)
**Said (summary of the user's words):** rework, after the VFX 1:1 task is finished:
1. The ROLL option at the bottom: redesign it as we already discussed (see [[Planning/Direction]] and earlier design talks).
2. Loading screen is terrible: research loading screens that match our game, and add a start menu.
3. The left-side buttons are useless and the generic UI looks sloppy.
4. Skill tree is low effort; needs to be much better.
5. Progression tab is useless; make it useful.
6. Many buttons are in bad positions; move them.
7. Perfect-streak and gem indicators are ugly.
8. Overall: ugly UI and weak game design. "Work on everything once you finished it."
**Status (2026-10-28):** done in a first pass, see [[Research/UI/UI Rework 2026-10-28]]; then the user said everything was still generic and uniform, so controls became Victorian objects (same note). Look UNVERIFIED until the user plays it.

### Effect craft quality (2026-10-28, VFX 1:1 session)
**Said:** our effects are not close in quality: the real ones have well-crafted shock and cracking animations, ours look like a low-effort triangle. If we cannot make that, research how to make them like that. Full permission for this.
**Status (2026-10-28):** researched and built: [[Research/VFX and Animation/Crafted Sheet Techniques]]. Earlier status: researching how sheet effects are authored (noise erosion, gradient maps, branching cracks, distortion, bloom; Blender and free particle tools), then rebuilding the egg hatch and coin drop with that method.

### Every action is a cutscene (2026-10-28, VFX 1:1 + UI session)
**Said:** "I don't just want a generic game, I want every action the user does to be a cutscene." Examples: pressing ULTIMATE goes into first person and you see the ultimate in action; opening the SKILL TREE goes into first person, you watch the actual tree grow, walk towards it and upgrade.
Also said: "I want absolute immersion when doing anything in the game."
**Status:** design draft in [[Planning/Immersion - Every Action a Cutscene]]; not built. Needs a design pass (which actions, length per action, skip rules for repeated actions, reduced-motion setting) before building.

### Roll and bottom buttons still generic (2026-10-28)
**Said:** "Our rolling animation is still too generic. Our buttons on the bottom as well. Look at creative games with the fantasy theme and see what they are doing."
**Status:** done in a first pass: [[Research/VFX and Animation/Summon References]] (The Reading reveal, the desk). Look UNVERIFIED until the user plays it.

### Settings too generic + a quick fix tool (2026-10-28)
**Said:** the settings buttons are too generic; research creative ones; create something I can use to instantly tell you to fix and make more creative, and record how to do it in Obsidian.
**Done:** settings rebuilt as an instrument board; `/make-creative` skill (`.claude/skills/make-creative/`) and [[Research/UI/Creative Fix Method]] (loop, metaphor table, pitfalls, log).
