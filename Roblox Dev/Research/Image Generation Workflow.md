# Image Generation Workflow (ComfyUI + ChatGPT, replaces Kimi)

Written 2026-10-25. Related: [[3D Model Workflow]], [[UI Art Pipeline]], [[3D Assets]]

## Decision
Two sources, one hand-off folder. Kimi is retired (Claude could not drive it, and it was a manual download step).

| Source | Use for | Why |
|---|---|---|
| **ComfyUI** (local FLUX schnell, Claude drives it) | Bulk and iteration: UI icons, first-pass concepts, many variants, retries | Free, about 20 s per image, no hand-offs, Claude can run, view and rerun without the user |
| **ChatGPT** (user pastes the brief, saves results to the folder) | Hero art: final pet and character concepts, rarity-tier families, anything that must follow a long description or keep one design consistent across poses | Better prompt-following and detail than a Q4 FLUX model; can do multi-view sheets |

Rule of thumb: Claude generates 4 candidates in ComfyUI first. If none has enough detail or character, the brief goes to ChatGPT.

## Art direction: dark medieval fantasy (the "Sols" vibe), set 2026-10-25
The user wants the end product to feel like Sols RNG but could not put the vibe into words. From the Sols screenshots in this folder ([[aura-view-hades-summoning-circle.png]], [[sols-daily-rewards-leaderboard.png]]): near-black midnight navy, thin pale bracket-cornered frames, one glowing accent colour per item (gold, violet, crimson, cyan), arcane runes and summoning circles, gothic lettering, dramatic rim light, ancient-and-powerful mood. Not cute, not candy.
- ComfyUI: `--style sols` (`STYLE_SOLS` in `comfy_generate.py`) replaces `--style flat` for icons. The cartoon-face style (`flat`) stays only for friendly things like pets if wanted.
- First test (sword, shield, dragon, skull, book, apple, 2 seeds each, `comfy_out/sols_test.jpg`): far closer to the vibe (engraved metal, glowing runes, jewel accents). **Problem:** about half the results ignore the magenta background and paint a dark vignette, which the ingest tool cannot key. Fix before a bulk run (stronger background wording or 3 variants and auto-pick the ones with a magenta corner).
- Colour language for rarity should come from the glow colour, not from cartoon outlines.

### Prompt lessons from the first batches (2026-10-25)
Found by looking at the user's 5 sample images and a 9-icon retest (`comfy_out/sols_test2.jpg`):
- **Background varies** (dusty pink, hot pink, dark vignette). Fixed: background sentence now goes FIRST in the prompt, and `comfy_generate.py` checks the border is one flat magenta colour and retries with another seed (up to 4). Retest: all 9 had clean backgrounds.
- **Orientation.** Long objects (flag, sword, rod, pickaxe) come out tilted or diagonal, which looks wrong on UI. A generic "upright, no rotation" line (now in `COMPOSITION`) helped the flag and hook but not the sword, rod or pickaxe. FLUX schnell has no negative prompt, so it needs literal positions: "blade pointing straight up", "pole standing straight vertical". Per-icon wording is the next fix, plus a deskew step in `ingest_art.py` (rotate to the main axis) as a safety net.
- **Size.** "Equal margin" made subjects too small (about 50 to 60 percent of the frame). Ask for 90 percent; ingest trims and re-pads anyway.
- **Ground shadow and base ornaments** (apple): say "floating, nothing under it", and avoid words like "display" or "relic" for food.
- **Concept clarity.** Abstract icons (rebirth, trade) turn into coins or rings. Describe literally ("two curved arrows chasing each other around a star"), and avoid "ring" or "circle", which leaves magenta inside the shape (flood-fill keying only removes background touching the border).
- **Outline weight differs** per image (thick black halo on the bell, none on the apple). Say "thin dark outline" in every prompt.
- **Mixing styles** (glossy 3D, flat cartoon, dark fantasy) in one UI looks off; one style per set.

## Hand-off (same for both)
1. ChatGPT results are saved to `UI Kit/art/inbox/<name>.png` (pets: `Hunyuan3D/reference/<Name>_concept.png`). The file name is the asset name.
2. Claude opens every new file, checks it against the checklist below, and reports pass/fail per file. Nothing is ingested unseen.
3. Icons go through `ingest_art.py` (keys out the magenta background). Pets go to Hunyuan3D, then Blender, then the user reviews ([[3D Model Workflow]]).

## What to ask ChatGPT for
- **Background:** flat solid pure magenta #FF00FF (the ingest tool keys it). If it gives white or transparent, say so; Claude can adapt, but reports it.
- **Icons:** one object, centred, fills the frame, thick dark navy outline, flat 2D cel shading, a small face or distinctive detail where it fits, no text, no ground shadow, square.
- **Pet concepts (for 3D):** one creature, whole body, three-quarter view, limbs visible, even lighting, plain background, no cast shadow, and 3 to 4 named distinct features (horns, wings, tail, armour, gems). Then a second image: front, side and back on one sheet if the user wants the 3D to match better.
- **Families and tiers:** ask for tier 1, 2 and 3 in one request so the base design stays the same and tiers add detail.
- Full style text lives in `UI Kit/art/briefs/KIMI-MASTER-PROMPT.md` (file name kept; works as is) and the `STYLE_FLAT` block in `UI Kit/art/comfy_generate.py`.

## Review checklist (Claude applies, user has final say)
Silhouette distinct from the others; at least three secondary features; face and attitude fit the rarity; no baked-in text or watermark; subject not cropped; background clean enough to key; readable at 64 px for icons.

## Open and unverified
- ChatGPT commercial use (user's research, 2026-10-25, from third-party summaries of OpenAI's Terms of Use, not read by Claude on openai.com): user owns the output and may use it commercially in games; no exclusivity or copyright guarantee (others can get similar images); outputs may carry C2PA AI-provenance metadata; user is responsible for not copying third-party IP, brands or real people; must also follow Roblox content, IP and AI-asset rules. Still to do: read the primary OpenAI terms page and Roblox's AI-asset rules before publishing.
- ChatGPT's magenta-background reliability is untested; the first batch will show.
- Whether Hunyuan3D reads flat 2D concepts as well as 3D-looking ones is untested (first pet will show).

## Status 2026-10-25
Sols-style icons ingested (48 of 51; backups: UI Kit/art/out_3d_backup, out_flat_backup, out_sols_v1_backup). Still vector or old: bolt, rebirth, rod (thin), check, plus, arrow_up. Not yet synced to Studio or uploaded. Thin tall items (rod, hook, sword) stay small in the square.

- 2026-10-26: Studio caches textures per path, so replaced sprites kept showing the old image. Sprites now install to 	extures/uikit_v2/ (UIArt.localRoot); bump the folder name again when sprites change and Studio still shows old art. Added icon_weapons (crossed swords) and a horizontal icon_key; Lobby HUD callouts no longer overlap. Synced UIArt and UIScreens2 to Studio and checked the Lobby HUD only.
- 2026-10-26: Dark-fantasy check mark added; sprite folder is now 	extures/uikit_v3 (cache bust). Checked in Studio: Lobby HUD, Shop, Event Shop. Finding: the candy chrome (green headers, pink cards, bright buttons) clashes with the dark-fantasy icons; next step is a dark theme for the panels (Aura or a new Sols theme) rather than more icon work.

## Dark UI skin (2026-10-26)
- `UI Kit/art/make_chrome_sols.py` redraws the chrome (buttons, headers, cards, panels, bars, close, badge) in the dark-fantasy look with the same sprite names, sizes and 9-slice margins, so all screens re-skin with no code changes. The candy originals are in `UI Kit/art/out_candy_backup`; `--restore` puts them back. **Never run `make_chrome.py` or `build_art.py` afterwards** (it rewrites the candy chrome and the vector icons over the ComfyUI ones).
- `UITheme.Sols` (Sarpanch body, GrenzeGotisch titles) and `K.skin = "Sols"` in `UIKit.luau` force it for every screen; set `K.skin = nil` to get each screen's own theme back.
- Sprite folder is now `textures/uikit_v4` (cache bust).
- Checked in Studio: Shop, Lobby HUD, Event Shop (renders `UI Kit Renders/*_dark.jpg`). Not yet restyled: white tooltip, white deck and section panels in other screens (PassShop, BattlePass, Profile, FirstDraw, UnitView), the leaderboard and Daily Tasks panels' plain dark boxes. Not phone-tested.
- 2026-10-26: Dark restyle also done for Pass Shop and Battle Pass (renders *_dark.jpg). Sols text outline raised to 0.09. Still bright: Profile, First Draw, Unit View, Mode Select, Crate Claim, Loading (not re-checked); Pass Shop top tab strip still shows the old green pill.
- 2026-10-26: Unit View glow, lock tab, Mode Select tiles/chips and the shared backdrop (one midnight gradient via K.backdrop when K.skin is Sols) restyled; all UIScreens2 screens (except NowPlaying, which needs Music) validate with 0 problems. Mode Select's last chip row edit synced but not re-screenshotted. Lesson: never use Replace on a PowerShell array of pairs with only one pair (it flattened and replaced single characters across the file; restored from the Studio copy).

## Fonts (2026-10-26)
User found the Sols theme fonts thick and low quality. Cause: GrenzeGotisch (blackletter, only legible big) and Sarpanch (techno) with a heavy 0.09 text outline. Compared Roblox's built-in fonts in a lab render (`UI Kit Renders/FontLab.jpg`). Roblox `Font.new("rbxasset://fonts/families/<name>.json")` returns a default font for names that do not exist (Cinzel and the like looked identical to the default), so only the `Enum.Font` list is reliable here. Chosen for `UITheme.Sols`: titles **Fondamento** (calligraphic, readable), body and numbers **Merriweather** (sturdy serif, legible small), text outline **0.04**. Checked on Shop, Lobby HUD and Pass Shop. Alternatives if wanted: Fantasy (title), Garamond (body, thinner), Bodoni. Wide Merriweather crowds some tab labels (Pass Shop "Chronos Egg").

## Kimi K3 test pack (2026-10-26)
- Built in `UI Kit/art/k3_test/`: `make_k3_test.py` writes `K3-TEST-PROMPT.md` (master prompt plus 6 items in 2 batches, same Sols style and descriptions as ComfyUI, files named `k3test_*.png`). Images go to `k3_test/inbox/`, not `art/inbox/`, so they cannot reach the real sprites.
- `check_k3_test.py` applies the ingest rules: border must be one magenta-family colour, subject must fill 60 to 100% of the frame, and at most 0.5% of subject pixels may sit within 38 of the border colour (ingest keys by colour everywhere, so those become holes). It cannot judge style, text, shadow or orientation.
- Checker results: synthetic pure-magenta image passes; a vignette background and a magenta hole fail. ComfyUI Sols baseline: 4 of 6 pass; shop (48% fill, 9% holes) and trade (54% fill, 5% holes) fail, which matches the fill problems already noted above.
- Unverified: whether Kimi K3 exists in our Kimi app (installed 3.2.20; the only K3 mention in the project is the request itself), whether K3 keeps the flat magenta background, and whether it follows file names. The test has not been run.
