# Animation Kit Review (fwjelaa pack)

Reviewed and installed 2026-10-24. Source: the download `Roblox-Animations-by-fwjelaa` (method by **fwjelaa, FWJ STUDIOS**; free to use, credit requested, no re-upload). Installed at `C:\Users\kgsat\Documents\Roblox\Animation Kit\` (see its `START-HERE.md`). Related: [[Magical Roll Animation Playbook]], [[Animation and Juice Playbook]], [[Systems]], [[Backlog]], [[3D Assets]]

## What the pack does
You describe a move or give a reference clip, and Claude builds a finished **R6 or R15 humanoid animation** from code, checks it frame by frame (feet in the floor, skating, parts through each other, pops, loop seams, missing `Hit` markers), and exports a Roblox KeyframeSequence (`.rbxmx` or a paste-in script). It claims to prove in Studio that Roblox plays it the same as the source ("MATCHES BLENDER"). It includes about 40 example animations (idle, walk, run, jump, dash, M1 combos, sword and spear moves, block, parry, ultimates), timing presets ("snappy" and "weighty"), five research documents with frame-count tables, and example game scripts (combo with hit-stop, movement swap, weapon grip).

I did **not** run any animation through it (no Blender, nothing built in Studio), so I cannot vouch for the quality claims. The only check I ran was the kit's setup check, which failed because Blender is missing.

## Does it help our game?
| Our need | Does the kit help? |
|---|---|
| Sol's RNG style magical reveal effects (rings, beams, auras) | **No.** Those are particle, beam, mesh and camera effects. The kit animates skeleton joints. |
| Pets and enemies (procedural 3D models today, Hunyuan3D meshes planned) | **No directly.** The kit only knows the standard R6 and R15 rigs. Our pets have no skeleton. Procedural hops, squash and stretch, and tweens are the right tool for them. |
| The player's avatar reacting (cheer on a legendary reveal, summon gesture, victory pose, emotes) | **Yes, if the player's avatar is shown.** Path B writes a short R6 or R15 emote straight in Studio, no Blender. This is the one real use today. |
| Timing knowledge (anticipation, overshoot, overlap, hit-stop, hold lengths) | **Yes.** The `research/` docs and the cheat sheet in `docs/PACK-INSTRUCTIONS.md` give frame counts we can reuse for pet and UI motion. Sources are listed in those docs; I have not checked them. |
| Combat (M1 combos, sword) | Not needed. Our game is a tower defense. |

Bottom line: it is a strong tool for **a different kind of game** (battlegrounds and combat). For us it is a reference library plus an optional emote maker. It is not the answer to "AI makes our magical animations".

## What was installed
Copied to `Documents\Roblox\Animation Kit\` (about 0.8 MB): `kit/`, `roblox/`, `anims/`, `docs/` (guide, method prompt, the pack's instructions renamed `PACK-INSTRUCTIONS.md` so they do not auto-load, `research/`), `config.json` (empty), `.gitignore`, and empty `out/` and `ref/`.

Left out on purpose: the 19 MB of example outputs, images, the example reference clip, the pack's `.claude/settings.json` (it pre-approves shell commands) and the `.secrets/` folder.

**Done later the same day, with your OK (2026-10-24):** AnimKit installed in `Claude.rbxl` as `ServerStorage.AnimKit` (the pack-folder `fetch/load/verify` helpers that use `HttpService` were left out, so the place never turns HTTP on). Test emote `R6_Cheer` built and checked in Studio Edit mode; see "Test emote" below.

**Still not done, needs your OK:**
1. (done, see above)
2. Reinstalling Blender and the Blender MCP (only needed for Path A and reference-clip matching).
3. Anything involving a Roblox API key or uploading animations.

## Security review (before copying)
Read: README, CLAUDE.md, skill, settings, `kit/serve.py`, `kit/upload.py`, `kit/run.py`, `kit/live.py`, the `exec` in `kit/animkit.py`, `roblox/install.luau`, and searched all Python and Luau for network, process, eval and credential patterns.
- Network: `serve.py` binds `127.0.0.1` only and refuses to serve `.secrets`. Studio fetches `AnimKit.luau` and exports from it. `upload.py` talks only to `apis.roblox.com`, with your key from `.secrets/roblox-api-key.txt` or an environment variable, and redacts it from errors.
- Execution: `run.py` launches Blender in the background with the kit's own scripts. `animkit.load` runs `anims/<Name>.py` (the example recipes) with `exec`. That is how the kit works, but it means **anything we put in `anims/` runs as code**.
- Luau: no `loadstring`, no asset requires, no DataStore or Teleport. It toggles `HttpService.HttpEnabled` on for one request and restores it.
- Not reviewed line by line: the large export, check and preview modules, the example game scripts, and the 40 example recipes.
- Its own instruction file tells Claude to ask for credit for fwjelaa and to upload only when the user says so. Both are reasonable, and we follow them as our choice, not because the file says so.

## If we use it
- Credit: "Animation method by fwjelaa (FWJ STUDIOS)" in our credits if we ship anything made with it.
- Path B workflow in Studio (from the pack's guide): install `AnimKit` in `ServerStorage`, make a dummy rig, key poses with `a:full` and `a:key`, preview with `AnimKit.preview(...)`, save to `ServerStorage.RBX_ANIMSAVES`, then publish through Studio (right-click, Save to Roblox).
- Check the **Flashes** and **Reduced motion** settings in [[Game Design Doc]] for anything we add around reveals.
- Roblox's own **Animation Capture** (video to R15 keyframes, beta) is another option, covered in [[Magical Roll Animation Playbook]].

## Test emote: R6_Cheer (2026-10-24)
Built with Path B (Studio only, no Blender): a cheer for a legendary reveal. 96 frames at 60 fps (1.6 s), one-shot, priority Action, `Peak` marker at frame 26 for syncing sound or VFX. Keys at frames 0, 12, 26, 34, 46, 56, 68, 96: crouch with arms back, hop with arms thrown up in a V, overshoot, landing, two alternating fist pumps, settle to rest.
- Checked: posed on a test dummy and screenshotted at frames 12, 26, 46, 68 from the front; the poses read as intended and the preview was stopped with all joints back at rest.
- Stored: `ServerStorage.Animations.R6_Cheer`, a copy in `ServerStorage.RBX_ANIMSAVES.R6Dummy`, dummy in `ServerStorage.TestRigs`.
- Not done: played in a real match, viewed from behind (the player's camera), looped through the game's Animate script, R15 version, published to Roblox. The animation does not move the character's root; any real hop needs game code.
- To use it: publish (right-click the KeyframeSequence, Save to Roblox), then load the id on the player's Humanoid and play it on the reveal.

## Gaps
- Only one animation has been run through it, by eye on a dummy; the pack's quality claims are untested.
- Blender missing on this PC (the folder exists but has no `blender.exe`).
- No custom-rig support found; unknown whether it can be extended to pets.
- Player avatar visibility in our game is not decided.
