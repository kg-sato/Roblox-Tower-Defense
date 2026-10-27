---
name: make-ui
description: Builds Roblox UI (HUD, shop, modal, settings, tutorial, collection, roll/reveal screens) in Studio from a description or a reference screenshot, using the project's UI Kit (design tokens, components, Scale-only rules, validator). Use when the user asks for a Roblox screen, menu, HUD, popup or "UI like this image", or types /make-ui.
---

# Make a Roblox UI screen

This is the project's version of what the paid "AI Roblox UI generator" sites do: a fixed design vocabulary, a component set, a validator and a visual check. Do not hand-set hundreds of properties. Compose components.

Read first: `UI Kit/README.md`. Reference images: `Roblox Dev/Research/*.png` (see `Roblox Dev/Research/UI/Screenshot Analysis.md` for what each shows and the patterns to copy). Rules and sources: `Roblox Dev/Research/UI/UI Design Playbook.md`, `Low-End Device Playbook.md`, `GUI Maker Tools Review.md`.

## Steps

1. **Pin it down.** Which screen, which theme (`Candy` chunky, `Pixel` dark retro, `Aura` thin sci-fi), which reference image. If an image is given, Read it and write down: layout regions (as fractions of the screen), each component and its colour token, text, states, what is edge-pinned. Do not ask the user to measure anything.
2. **Map to components** (all in `UI Kit/luau/UIKit.luau`): `screen, backdrop, box, text, button, nav, pill, badge, modal, bar, slider, segmented, tabs, cells, rows, card, toast, banner, hex, bracketPanel, rarityTitle, popIn, countdown, fmt`. If a needed pattern is missing, add a component to UIKit (small, token-driven) instead of one-off code, then use it.
3. **Write the screen** as a function in `UI Kit/luau/UIScreens.luau`: `S.Name = function(K, parent) K.use("Candy") local g, root = K.screen("Name", parent) ... return g end`. Add its name to `S.order`. Put the image filename it recreates in a comment above it.
4. **Hard rules** (the validator checks these): Scale only (no Offset anywhere), centered AnchorPoint unless edge-pinned (pass `anchor` and `reason`), `UIStroke` ScaledSize, `UICorner` Scale, `TextScaled` with a size constraint, tokens not raw numbers, images only for art that frames cannot do. Square things get `aspect = 1`; panels get an `aspect`. Keep important buttons out of the phone's bottom corners and under the top bar.
5. **Install and build in Studio** (Studio MCP, Edit mode): `ReplicatedStorage.UIKit` holds the five modules (UITheme, UIKit, UIScreens, UIValidate, UIBuild). After editing files on disk, recreate the modules (destroy and re-create the ModuleScripts; changing `Source` alone does not refresh `require`, and hot-sync inside a running playtest does not work). Easiest: serve `UI Kit/luau` on localhost only and fetch with HttpService in Edit mode (see `UI Kit/README.md`, "How to work on it"), then stop the server. Build into a temporary folder; never leave test screens in `StarterGui`. `require(...UIBuild).one("Shop", folder)` prints `OK` or the list of problems; fix every one.
6. **Look at it.** Edit mode does not draw UI in captures. Start a playtest, build into the Client `PlayerGui` (hide other ScreenGuis), wait about 2 seconds for fonts, then `screen_capture`. Compare with the reference image; fix the biggest difference first (layout, then colour, then text, then detail). For phone shape, add a `UIAspectRatioConstraint` of 844/390 to the root (aspect only, not real pixels). Expect 2 to 4 rounds.
7. **Report honestly**: what matches, what is approximated (emoji icons instead of art, no 3D bevels, no particles), what is untested. A screenshot is not an interaction test.

## Art first (the biggest quality lever)
The kit looks right only with real artwork. Before building a screen, check what sprites exist (`UI Kit/luau/UIArt.luau`) and use `K.icon` / `K.sprite` with sprite names, not emoji. Missing icon? Request it: Blender (`UI Kit/art/blender/render_icons.py`, add a model), Pillow (`make_chrome.py`), or Kimi (`UI Kit/art/briefs/`, drop images in `UI Kit/art/inbox/`), then run `python "UI Kit/art/build_art.py"`. Never upload art to Roblox without the owner's OK. Eight modules sync to Studio (UITheme, UIArt, UIMotion, UIKitArt, UIKit, UIScreens, UIValidate, UIBuild). Details: `Roblox Dev/Research/UI/UI Art Pipeline.md`.

## Motion (use it on every screen)
Call `K.popIn(panel)` after building a modal; `K.stagger(container)` on grids, card rows and lists; `K.pulse(btn)` on anything claimable; `K.countUp(label, value, {prefix})` for rewards; `K.shake(inst)` for "locked / not enough". Buttons made with `K.button` already get hover, press and release. All are Scale-only and honour `K.setReducedMotion`. To test motion, sample `AbsoluteSize` over time in a playtest (a screenshot cannot show it), and use `user_mouse_input` for real hover and press. Details: `UI Kit/README.md`, "Motion layer".

## Gotchas measured in Studio (2026-10-25)
- Set `TextWrapped = true` before `TextScaled = true`; setting `TextWrapped = false` afterwards turns TextScaled off.
- Scaled stroke and corner values are relative to the element's shortest side: use small numbers (about 0.01 stroke, 0.04 corner) on big panels, tokens only on small controls.
- Emoji that do NOT draw: coin (U+1FA99), blueberries, magic wand, nest, and the plain check mark (dark glyph). Safe: money bag, gem, star, egg, paw prints, dragon, gift, garlic, apple, stopwatch, alarm clock, candy, wrench, butter, watermelon, refresh arrows, smiley, chequered flag, shopping cart, open book, pickaxe, sneaker, cash, up arrow, check-mark box, padlock, pumpkin, crown, fire, lightning, heart, test tube, dagger, trophy, bullseye, bell, gear, sparkles, four-leaf clover, glowing star, dog, cat, fox, dragon, grapes.
- Keep important HUD away from the phone's bottom corners (Roblox thumbstick and jump button).

## What the kit cannot do (say so, do not fake it)
- Custom art (the 3D-looking icons, rarity frames, stars, ribbons): needs image assets. Emoji or flat shapes stand in until art exists.
- Inner shadows, blur, radial gradients: not native in Roblox UI.
- Game logic: components only take callbacks. Currency, purchases, crates stay server-side (see CLAUDE.md rules).
- Paid random items: odds panel needed (see `Competitors and Policy.md`). Crates here use free currency.

## Credits
The Scale-only and validator rules come from `xtrair/figma-to-roblox-ui` (MIT). Keep that credit.
