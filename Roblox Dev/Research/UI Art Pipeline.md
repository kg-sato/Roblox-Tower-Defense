# UI Art Pipeline (why our UI felt flat, and what we changed)

Written 2026-10-25. Related: [[UI Generator Method]], [[GUI Maker Tools Review]], [[Screenshot Analysis]], [[Low-End Device Playbook]]. Code: `UI Kit/` (see its README). Renders: `Research/UI Kit Renders/art-*.jpg`.

## What the good games and the generator sites do that we did not
Short answer: **their UI is made of artwork, ours was made of frames and emoji.** Nothing about layout or prompts explains the gap.

| Thing | Good games / generator examples | Our first kit |
|---|---|---|
| Buttons, panels, headers | Hand-made sprites: glossy gradient, dark outline, lit top edge, darker lip, specular strip | `Frame` + `UICorner` + `UIStroke` + a two-colour gradient |
| Icons | Rendered or painted icons (outline, gradient, highlight, depth) | Emoji (different style per icon, some missing) |
| Material feel | Everything has a lip, highlight and shadow, so it reads as an object | Flat colour |
| Consistency | One art direction applied to every asset | Default fonts and flat colours only |
| Effort | Dozens of bespoke assets per screen | One rule-built component set |

What I could verify about robloxguimaker.dev: its examples page lists six screens (main menu, shop, trade window, obby HUD, daily reward, admin panel) and describes the **component trees and UX rules** (mirrored offers, a fixed Buy button, a skip button placed away from jump controls, dimmed claimed slots). It does not describe how its images are made, and the footer says "AI-powered image generation". So: **I could not confirm how they make their art.** The evidence that the look comes from image assets is the visual gap itself plus the product label, not a documented method.

## What we built (all local and free)
1. **Procedural sprite factory**: `UI Kit/art/make_chrome.py` (Pillow, 4x supersampled). 56 sprites: glossy 9-slice buttons in 8 colours (rectangular and pill), panels, headers in 7 colours, dark currency pills, bar tracks and 7 fill colours, close button, notification badge, inventory slot, 7 card frames, soft glow, sunburst, and 10 vector icons (coin, gem, star, heart, bolt, plus, check, crown, lock, arrow). Runs in 4 seconds.
2. **Blender icon renderer**: `UI Kit/art/blender/render_icons.py` (Blender 5.3 beta, EEVEE, headless, about 6 s for 12 icons). Glossy low-poly models with an inverted-hull outline and transparent background: egg, gift, chest, paw, gear, book, bag, trophy, key, shards, potion, crystal.
3. **Ingest pipeline**: `UI Kit/art/ingest_art.py`. Takes any image dropped in `art/inbox/` (Kimi, Blender, manual): removes a flat magenta background with a soft key and edge un-mixing (tested on a PNG and a JPEG; no fringe), trims, pads, resizes, names and registers it, and flags problems (edge-touching, small, non-solid background).
4. **Art layer**: `UIArt.luau` (generated sprite list, 9-slice insets, optional asset ids) and `UIKitArt.luau`, which upgrades `K.button`, `K.modal`, `K.pill`, `K.badge`, `K.bar`, `K.tabs`, `K.card` to sprite versions, adds `K.sprite` and `K.icon`, and maps old emoji to sprites. Every override falls back to the frame version if a sprite is missing, so nothing breaks without art.
5. **One command**: `python "UI Kit/art/build_art.py"` (sprites, ingest, UIArt, local preview install).
6. **No-upload preview**: sprites are copied into Studio's own content folder and loaded as `rbxasset://textures/uikit/<name>.png`. This is a dev-only preview. A published game needs the sprites uploaded to Roblox and referenced by asset id (`art/ids.json`, then rerun `make_uiart.py`).

## Result (screenshots in a playtest, 1617x850)
Shop, PetHud, Inventory, Rebirth and Loading were re-rendered with the sprites. The buttons, panels, bars, close button, badges and icons now look like objects instead of flat shapes, and the rendered egg, gift, paw, chest, key, potion and crystal icons are clearly closer to the reference games than emoji were. **It is still not the same quality as the best reference games**: those have richer shading, more detail per asset, decorated headers, custom fonts and animation. The new screens (Inventory, Rebirth, Loading) are the closest. The first nine screens that were not rebuilt keep their old layout, and some icons are still emoji (dragon, stopwatch, pickaxe, cart in some screens).

## Kimi: what I found, and what I could not do
- **Installed:** the unpacked Electron app is at `Documents/Roblox/Kimi/Kimi.exe` (about 1.1 GB, which is why it sits in the project folder; **do not commit this folder**). Running now: the Kimi app, `kimi-cu` (Kimi Computer Use, in `AppData/Local/Kimi Computer Use`), and `kimi-webbridge` (a local bridge on 127.0.0.1:10086).
- **I cannot drive Kimi in this session.** I have no desktop-control or computer-use tools loaded here (the tool search found none), so "remote control" is not usable by me right now. I did not try to automate the Kimi window by other means. I also did not read inside the Kimi app files, its login data, or its bridge.
- **Kimi's built-in Blender and Roblox Studio connections: not verified.** I found no documentation on this PC and did not test them. Treat them as unconfirmed. I did not use them.
- **Workflow chosen (works with or without Kimi's connections):** Kimi generates the images; **a folder is the hand-off** (`UI Kit/art/inbox/`); Claude's pipeline does everything else. Files: `UI Kit/art/briefs/KIMI-MASTER-PROMPT.md` (paste once per session: style bible, magenta background rule, file names, size), `BATCH-1-ICONS.md` (the 20 icons the current screens need, file name plus description). When Kimi finishes, say "inbox ready" and the pipeline processes it. If Kimi cannot save into the inbox itself, download its images and drop them in.
- **Why magenta:** image generators rarely give clean transparency; a flat #FF00FF background keys out cleanly (tested) and the ingest script reports any image that did not follow the rule.
- **Open question for you:** can Kimi save files to a folder, or only show them in its window? That decides whether you move files by hand.

## Automating the Kimi hand-off (researched 2026-10-25)

Goal: stop pasting prompts and moving files by hand. I looked at what each side can do. I did not touch Kimi's window, files or login data, and did not call its local bridge.

**What I can do here:** read and write files, run Python and Blender, drive Studio through its MCP, and (after a permission step) a Chrome extension that can read and click pages and upload files to page inputs. I have **no desktop-control tool in this session**, so I cannot click inside the Kimi desktop app.

**What Kimi has (from public sources, not official docs, not tested):**
- A desktop app plus **Kimi Computer Use** (a separate local agent, process `kimi-cu`) that lets Kimi control apps on this PC.
- **Kimi WebBridge / "Kimi Browser Extension"**: a browser extension plus a local daemon on `127.0.0.1:10086` that lets an agent drive your real Chrome or Edge with your logins. Its published skill says Claude Code is a supported client. That daemon is what is running on this PC. It can act as you on any site you are signed in to, so I will not use it without your explicit go-ahead; the Claude in Chrome extension is the more controlled equivalent.
- **Kimi Work** (agent with scheduled tasks) is reported in the press; status unclear.
- **No image-generation API found.** Moonshot's API is chat and vision (image in, text out). Whether the Kimi chat itself generates images depends on account, plan and mode (sources are third-party and contradictory). So there is no "script calls Kimi, gets a PNG" route that I can confirm.
- Kimi's own task folder is `Documents/kimi/tasks` and `Documents/kimi/workspace`. I only listed these names.

| Route | Automatic? | What it needs | Risk / unknown |
|---|---|---|---|
| **A. Watch folder** (`art/watch_inbox.py`, built) | Yes after Kimi saves a file: picks up `icon_*` etc. from the inbox or from Kimi's output folder (`--also "C:/Users/kgsat/Documents/kimi/workspace"`), waits for the file to finish writing, runs ingest, rebuilds the sprite list and the Studio preview | You start it once; Kimi must save files to a folder | None found. Only copies files, never deletes originals. Needs Kimi to actually save to disk |
| **B. Missing-art detector** (`art/next_batch.py`, built) | Yes on my side: scans the screens, lists icons with no sprite, writes `briefs/NEXT-BATCH.md` ready to paste (9 missing right now) | Nothing | Descriptions come from a table I maintain |
| **C. Ask Kimi to save into the inbox itself** | Yes if Kimi's agent has file access (its workspace folder suggests so) | The master prompt already asks for it | Unknown until the first batch finishes: tell me where Kimi put the files |
| **D. Claude in Chrome drives kimi.com** | Mostly: I would open Kimi in your browser, paste the prompt, wait, and collect results | Chrome extension connected, you signed in to Kimi, **your permission to browse that site**, and Kimi's web chat must offer image generation (unverified) | Downloading files needs your OK each time; sites may block automation; account and credit use are yours |
| **E. Kimi WebBridge** (port 10086) | Same effect as D, using Kimi's own bridge | Extension connected to the daemon | Broad access to your logged-in browser; I recommend D over E. Not tried |
| **F. Kimi Computer Use drives Blender and Studio** | Possibly, from Kimi's side | You instruct Kimi | Unverified; any change to `Claude.rbxl` or any upload must stay on my side with your approval |
| **G. Local image generation** (for example ComfyUI with a small icon model on the RTX 4060 Ti 8 GB) | Fully automatic and offline, no website | Installing software and downloading model files (needs your OK), a model whose licence allows game use | Quality for consistent icon sets is unproven; setup time. This is the only route I can make fully scripted without any account |
| **H. Keep using Blender and Pillow for icons** (built) | Fully automatic today | Nothing | Looks like clean low-poly 3D, not painted art; limited to shapes we model |

**Recommendation:** run A now with `--also` pointed at Kimi's workspace once you tell me where the first batch landed, use B so each new screen produces its own art list, and treat D as a pilot only if you want me to try driving kimi.com (it needs your yes and a signed-in Chrome). If Kimi cannot generate images at all on your plan, G is the free route to a fully hands-off pipeline. I will not run any of D to G without your say-so.

## Not done (needs your OK or more work)
- **No upload to Roblox.** Nothing is uploaded; the preview only works inside this Studio install. Before publishing, we need your approval to upload the sprite set (about 70 images; the upload route is Studio's `upload_image` tool, or Asset Manager, or Open Cloud with an API key) and then `ids.json`.
- Kimi-generated art: none made yet (can't drive Kimi). Everything shown was made by the Pillow and Blender scripts.
- The first nine screens were not rebuilt to the new level; several icons are still emoji.
- Typography: still Roblox built-in fonts. A distinctive font would add a lot (needs a font asset or an image-text approach).
- Not yet: animation (hover, press squash, pop-ins, shimmer), sound, particles. These are a large part of why the reference games feel alive; see [[Animation and Juice Playbook]].
- Real phone check; Device Emulator pass.

## Next
1. You: paste the Kimi master prompt, run batch 1, drop images in `inbox/` (or tell me Kimi cannot save there).
2. Me: ingest, rebuild, restyle the first nine screens with the new icons, add press and pop animations, then the remaining screen families.
3. You: decide on uploading the sprite set so the art works outside this Studio install.

## Local ComfyUI route (installed and tested 2026-10-25)
Answer to "is there an alternative to Kimi": yes, and it is now our main art source because it is fully scripted, free and has no capacity limits.
- **Stack:** ComfyUI portable (`ComfyUI/ComfyUI_windows_portable/`) + FLUX.1 schnell GGUF Q4_K_S (Apache 2.0, commercial use allowed per its model card) + t5xxl fp8 and clip_l text encoders + the FLUX VAE + the third-party node [ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF) (installed with your OK). About 14 GB on disk.
- **Use:** `python "UI Kit/art/comfy_generate.py" icon_dragon icon_shoe --inbox` (or `--missing` for everything `next_batch.py` lists, `--variants 4` to pick the best). It starts the server, generates 768 px images (4 steps), cleans the background, copies to `art/inbox/`; then `build_art.py`. Descriptions come from `next_batch.py`.
- **Measured on the RTX 4060 Ti 8 GB:** 20 to 50 s per image (first one slower: model load). No out-of-memory with Studio open.
- **Quirks:** FLUX paints the background hot pink (about #F8137C), not pure #FF00FF, and ignores "no shadow" (adds a ground shadow). `comfy_generate.py` flood-fills magenta-family regions touching the border with the corner colour, so ingest keys cleanly; `--raw` skips it. The navy outline is thinner than asked on some icons.
- **Result:** dragon and shoe (the two icons we were missing) came out clearly better than the Blender renders: painted-looking, glossy, consistent enough. Renders: `Research/UI Kit Renders/comfy-test-icons.png`. Not yet checked: style consistency across a full batch, and how they look at 64 px inside the screens.

## Fishing-style batch, Hi3D verdict and workflow test (2026-10-25)
- **Hi3D V1.0** (open-sourced 2026-10-23, per its [Hugging Face card](https://huggingface.co/hi3d-official/Hi3Dv1.0) and press release): it only **refines a coarse mesh** using a reference image. It makes no textures, needs Linux, Python 3.10, flash-attn and CUDA 12.0 to 12.5, and was validated only on a 96 GB card (smaller cards not established). Custom licence: commercial use allowed, but "Powered by Hi3D 1.0" branding and a notice above 200k MAU. **Verdict: not better for us**: it does not replace Hunyuan3D-2 mini-Turbo on an 8 GB Windows PC, and it has no use for UI icons.
- **ComfyUI A/B** (FLUX schnell Q4, same seed): 768 px / 4 steps is about 15 s and as good as 768 px / 8 steps (about 30 s); 1024 px / 4 steps was slower and worse (a 3-leaf clover). **Settings kept: 768 / 4 steps**, 3 variants, pick one. Variant 2 more often has a non-pink background, so check before ingesting.
- **New icons** (rod, bag, clover, hook, bell, fish) and two screens in the fishing reference style: `FishHud` (event timer, objective line with highlighted word, level and cash readout, numbered hotbar, luck %, round dark buttons) and `CatchHud` (depth ruler, rarity callouts, hook counter, instruction band). Renders: `fishhud.jpg`, `catchhud.jpg`. Both pass the validator.
- **Not installed in the game:** the place already has a real Guardian Grid HUD built by hand in `StarterPlayerScripts.GameClient` (2,217 lines, pixel-offset layout). My mock HUD overlapped it, so I removed the test bootstrap. Porting the real HUD onto the kit needs a decision.
