# UI Kit

Our open, free replacement for the paid "describe a UI and get a Roblox UI" websites. Built 2026-10-25.

**Status (2026-10-25, tested in Studio):** installed as `ReplicatedStorage.UIKit`. All 9 screens build without errors, pass the validator (`OK (Scale only, centered)`), and were screenshotted in a live playtest and compared by eye with the reference images. Renders are in `Roblox Dev/Research/UI Kit Renders/`. **Not yet:** a human playtest, a real phone, any custom art, or wiring into the game's own UI. See "Verified results" below for exactly what was and was not checked.

## Art layer (added 2026-10-25)
The first version used flat frames and emoji, which is why it did not feel like the reference games. Now:
- `art/make_chrome.py` draws 56 sprites (glossy 9-slice buttons, panels, headers, bars, cards, badge, close, vector icons).
- `art/blender/render_icons.py` renders 12 glossy 3D icons with Blender (headless).
- `art/ingest_art.py` turns any inbox image (Kimi, Blender) into a sprite (magenta key, trim, resize, register).
- `luau/UIArt.luau` (generated) and `luau/UIKitArt.luau` swap components to sprite versions when sprites exist.
- One command: `python "UI Kit/art/build_art.py"`. Automation: `art/watch_inbox.py` (auto-process new `icon_*` images; `--also <folder>` for Kimi's output folder; not started by default) and `art/next_batch.py` (writes `briefs/NEXT-BATCH.md` of icons the screens still lack). Workflow with Kimi: `art/briefs/KIMI-MASTER-PROMPT.md`. Local generator (no account): `art/comfy_generate.py` (ComfyUI + FLUX schnell in `ComfyUI/`, see `Roblox Dev/Research/UI Art Pipeline.md`).
- Studio preview needs no upload (`art/preview_install.py` copies PNGs into Studio's content folder). Published games need uploaded asset ids in `art/ids.json` (**needs the owner's approval**).
- Details, evidence and limits: `Roblox Dev/Research/UI Art Pipeline.md`. Renders: `Roblox Dev/Research/UI Kit Renders/art-*.jpg`.
- New screens built with it (all pass the validator, checked by screenshot): `Inventory`, `Rebirth`, `Loading`. The first nine were not restyled.
- Eight Luau modules now go into `ReplicatedStorage.UIKit`: UITheme, UIArt, UIMotion, UIKitArt, UIKit, UIScreens, UIValidate, UIBuild (order matters only for sync; `UIKit` loads the art layer with `FindFirstChild`).

## Motion layer (added 2026-10-25)
`luau/UIMotion.luau` (loaded by `UIKit` before the art layer) replaces the old one-off press tween:
- **Buttons** (`K.pressFx`, used by every button): hover grows 6% (mouse only, never on touch), press squashes to 94%, release springs back with an overshoot. One state machine, so hover and press never fight.
- **Panels** (`K.popIn`): modal grows from 80% with a small overshoot while the dim fades in. Used by the Shop, Welcome Back, Daily Tasks, Inventory and Rebirth screens.
- **Grids and rows** (`K.stagger(container, {step, from})`): children pop in one after another. Used by Shop cards, Inventory slots, daily-streak cells.
- **Attention** (`K.pulse`): gentle looping grow and shrink on claimable buttons and notification badges. Stops when the player hovers or presses.
- **Feedback** (`K.shake` for "locked / not enough"; `K.countUp` for reward numbers).
- **Reduced motion**: `K.setReducedMotion(true)` makes every effect apply its end state instantly and starts no loops. **Wired to the Settings screen** (new REDUCED MOTION row; turning it ON also sets Flashes to OFF and Backdrop to STILL). **Nothing is saved yet**: it resets when the game restarts. Verified with a real mouse in a playtest: ON flips `K.Motion.reduced`, Flashes and Backdrop follow, a modal built afterwards appears at full size at once (1003 px, dim 0.50, instead of growing from 647), and RESET TO DEFAULTS restores every control and turns reduced motion off. The Settings sliders and segmented controls now return a second value `api` with `set(...)` (used by Reset).
- **Sound hook**: set `K.sfx = function(name) ... end`; it is called with `"click"` on every press. No sound assets exist yet.
- Rules: Size and Position tweened in Scale only, never UIScale, never a text UIStroke thickness.
- **Eight** modules now sync to Studio: UITheme, UIArt, UIMotion, UIKitArt, UIKit, UIScreens, UIValidate, UIBuild.
- Verified in a playtest (numbers, not just looks): panel 647 > 824 > 808 px with the dim fading 1.0 > 0.5 and the reward counting up; stagger Day 1 at 0.11 s, Day 4 at 0.26 s, Day 7 at 0.52 s; a Claim button pulsing between about 128 and 138 px; a real mouse on the Index button gave 178 > 189 (hover) > 167 (press) > 189 (release) > 178 (leave); reduced motion landed final states instantly. **Not verified:** feel by eye (timing may need tuning), touch input on a real device, performance with many animated 9-slice sprites on a low-end phone.

## UIScreens2 (added 2026-10-25)
`luau/UIScreens2.luau` holds screens added after the first set (`LobbyHud`, `BattlePass`, `CrateClaim`, `UnitView`, `ModeSelect`, `EventShop`, `PassShop`, `Profile`, `FirstDraw`). Use: `require(UIKit.UIScreens2).LobbyHud(require(UIKit), parent)`. Synced to Studio with the localhost fetch method below; validator OK; renders in `Roblox Dev/Research/UI Kit Renders/`.

## Why this exists
The sites in the sponsored videos (RobloxGUIMaker, ForgeGUI, Bloxsmith, LuaPilot and similar) appear to share one design: a closed **style preset** (colours, fonts, corner radii), a fixed **component set**, some **art assets**, and an automatic **check** of the result. The "one prompt" effect comes from that closed vocabulary, not from a smarter model. I could not read their internals (they are proprietary), so this is inferred from their marketing pages and from open-source methods like `xtrair/figma-to-roblox-ui`. Details: `Roblox Dev/Research/UI Generator Method.md`.

We copy the idea with our own parts:

| Their part | Our part |
|---|---|
| Style presets | `luau/UITheme.luau`: `Candy`, `Pixel`, `Aura` tokens, taken from the reference screenshots |
| Component set | `luau/UIKit.luau`: box, text, button, nav, pill, badge, modal, bar, slider, segmented, tabs, cards, toast, banner, hex, bracket panel, rarity title |
| Prompt/skill config | `.claude/skills/make-ui/SKILL.md` (the project skill) |
| Example screens | `luau/UIScreens.luau`: 9 screens recreating the references |
| Automatic check | `luau/UIValidate.luau`: Scale-only, centered anchors, scaled strokes and corners |
| Builder | `luau/UIBuild.luau`: build one or all screens and print the validator report |

## Screens built (recreating the images in `Roblox Dev/Research`)
| Screen | Recreates | Theme |
|---|---|---|
| PetHud | pet-main-hud-tap-button, egg-main-hud-auto-swing | Candy |
| Shop | pet-shop-featured, duel-shop-home, pet-shop-chronos-egg-odds | Candy |
| WelcomeBack | pet-offline-earnings-popup | Candy |
| DailyTasks | duel-daily-tasks-streak-contracts | Candy |
| Settings | card-settings-display-options (and our settings spec) | Pixel |
| TutorialHud | fruit-tutorial-3-click-fruits | Candy |
| CollectionLog | card-collection-log | Pixel |
| AuraRoll | sols-roll-result-crowned-1-in-20000 | Aura |
| UpgradeHex | fruit-hex-upgrade-tree | Candy |

**Not built yet** (families seen in the screenshots): battle pass track, trade menu, rebirth panel, mode-select tiles, fishing depth meter and minigame HUD, loading screen with warning card, profile page, aura viewer list, idle-game text columns, shop passes list. Most reuse existing components; the hard part for all of them is art, not layout.

## What it cannot reproduce
- **The art.** The reference games use hand-made 3D-looking icons, rarity frames and effects. Here, emoji and flat gradients stand in. To get the same look we need image assets (generated or drawn) plus a 9-slice frame set.
- **Effects on top** (glows, particles, screen takeovers): that is the separate reveal-effects work in `Magical Roll Animation Playbook.md`.
- **Exact pixels.** Layout is by eye from the screenshots.

## Verified results (2026-10-25)

Method: modules installed in Edit mode, `UIBuild` run on all 9 screens, then a playtest where each screen was built into `PlayerGui` and captured with `screen_capture` at the editor viewport (1617x850). Phone shape was approximated by constraining the screen root to 844:390 (aspect only, not real pixels). Two or three rounds of fixes per screen.

| Screen | Compared with | Verdict (by eye, from the render) |
|---|---|---|
| PetHud | pet-main-hud-tap-button, egg-main-hud-auto-swing | **Close.** Nav stack with badge, goal banner, big action button, currency pills and timer all match. Holds at phone aspect. Icons are emoji, not game art |
| Shop | pet-shop-featured, duel-shop-home | **Close in structure.** Tabs, 3 cards with tags, price buttons, red X. Fewer items and no 3D-look art; sale strikethroughs, odds panel and countdown not built. The coin-price button (money bag) was changed after the last capture and not re-captured |
| WelcomeBack | pet-offline-earnings-popup | **Layout matches**, no coin shower or count-up animation |
| DailyTasks | duel-daily-tasks-streak-contracts | **Close.** Streak row, task rows with bars and rewards, Claim buttons |
| Settings | card-settings-display-options | **Close, and matches our settings spec** (sliders, On/Off, Low/Default/High, number format). Controls respond to input but save nothing. Phone aspect checked |
| TutorialHud | fruit-tutorial-3-click-fruits | **Close.** Numbered banner with counter, left nav, "New!" toasts, edge offer buttons |
| CollectionLog | card-collection-log | **Close.** Left nav, filter chips, empty-state grid, detail pane |
| AuraRoll | sols-roll-result-crowned-1-in-20000 | **Layout matches** (odds line, rarity-coloured name, tier, bracket leaderboard and controls). No glow, particles or screen takeover, which are most of the real look |
| UpgradeHex | fruit-hex-upgrade-tree | **Matches the idea**: honeycomb with locked "?" nodes, built from rotated rectangles. Fewer nodes, no art |

**What this does NOT show:** custom icons, 3D bevels, rarity frames, particles, animations, sound; behaviour with real game data; real phone screens (text legibility at 390 px tall is unknown); mobile thumbstick and jump button overlap (the PetHud bottom-left pills and bottom-right timer sit where Roblox's mobile controls sit); gamepad; the unbuilt screens listed above.

## Bugs found and fixed while testing
1. **`TextWrapped = false` after `TextScaled = true` turns TextScaled off** in this Studio build, so every label rendered at 8 px. Fix: set `TextWrapped = true`, then `TextScaled = true` (TextScaled forces wrapping anyway). Fixed in `K.text`.
2. **Scaled strokes and corners are relative to the element's shortest side**, so tokens made for buttons produced huge borders and pill-shaped panels. Modal panels and cards now use small numeric values (0.012 stroke, 0.04 corner); keep token strokes for small controls.
3. **Four emoji do not draw** in this Roblox build (coin, blueberry, magic wand, nest) and plain check mark shows as a dark glyph. Use the money bag for coins, grapes, and the green check box. 46 other tested emoji draw as colour icons (list in `.claude/skills/make-ui/SKILL.md`).
4. Overlaps: SALE tag over card titles, toasts over the tutorial banner, slider knob over its value, collection grid under the detail pane, aura controls touching. All fixed.
5. The first title looked thin only because fonts load asynchronously; wait about 2 seconds before capturing.

`UIStroke.StrokeSizingMode = ScaledSize`, `UITextSizeConstraint`, `UIGradient`, and rotated frames all work as assumed.

## Testing with the mouse tool
- `user_mouse_input` adds the 58 px top-bar offset itself. Give it the **UI coordinates** (`AbsolutePosition + AbsoluteSize / 2`), not screen coordinates: asking for y=674 landed at y=732. To check where it landed, compare `UserInputService:GetMouseLocation()` minus `GuiService:GetGuiInset()` with `PlayerGui:GetGuiObjectsAtPosition`.
- Rows with identical names (several `SegmentedRow`) cannot be addressed by `instance_path`; use coordinates, or give rows unique names.

## How to work on it (gotchas learned)
- **Edit mode does not draw UI in captures** (not StarterGui, not CoreGui). To look, start a playtest and build into `PlayerGui` on the client.
- **`require` caches modules and runtime edits to `Source` are not picked up.** After changing a file: stop the playtest, replace the five ModuleScripts with fresh instances in Edit mode (destroy and recreate, do not just set `Source`), then start the playtest. Hot-syncing inside a running playtest did not work.
- **Sync from disk without pasting:** serve `UI Kit/luau` on localhost only (`python -I -m http.server 8766 --bind 127.0.0.1 --directory "UI Kit/luau"`), then in Edit mode fetch the five files with `HttpService:GetAsync` (turn `HttpEnabled` on only for the fetch and restore it) and recreate the modules. Stop the server afterwards. Studio blocks HTTP on the client side of a playtest.
- **Build target:** build into a temporary folder (or `PlayerGui`), never leave test screens in `StarterGui`, or they will appear in the game.
- Keep the Studio MCP shell working directory at the project root (`Documents\Roblox`); moving into a subfolder drops the connection.

## Install in Studio (already done in `Claude.rbxl`)
`ReplicatedStorage.UIKit` holds `UITheme`, `UIKit`, `UIScreens`, `UIValidate`, `UIBuild`, matching `luau/*.luau` as of 2026-10-25 (checked byte for byte). To validate: in Edit mode run `print(require(game.ReplicatedStorage.UIKit.UIBuild).all(someFolder))`. To look at a screen, build it into `PlayerGui` during a playtest.

## Status of the screens (2026-10-25)
Every screen here (including `FishHud` and `CatchHud`, the fishing-reference HUD and catch screens, and the 6 fishing icons) is a **reusable asset in the kit, not installed in the game**. The real Guardian Grid HUD is hand-built in `StarterPlayerScripts.GameClient` and was deliberately left alone (user decision: effects and assets first, gameplay later). Do not add a bootstrap that builds these over the game.

## Next steps
1. Art: generate and upload a small icon and frame set; let components use `ImageLabel` for those pieces.
2. Build the unbuilt screen families (battle pass track, trade menu, rebirth panel, mode tiles, fishing depth meter and minigame HUD, loading screen with warning card, profile page, aura viewer list, text-column idle UI, passes list).
3. Port the screens the game needs (HUD, shop, crate reveal, settings) into the game's own UI with real data; keep server-side rules intact.
4. Test on a real phone or the Device Emulator, including the mobile control overlap.

## Licences
Rules and validator adapted from `xtrair/figma-to-roblox-ui` (MIT; keep the credit). Everything else here is ours. Reference screenshots belong to their games and are used only as private design references, not shipped.
