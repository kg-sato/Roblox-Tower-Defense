# UI Generator Method

Researched 2026-10-25. Question: the sponsored videos show whole games "made in one prompt" with sites like RobloxGUIMaker and ForgeGUI. Is there something we can copy so Claude builds Roblox UI as easily, using free or open-source parts? Related: [[GUI Maker Tools Review]], [[UI Design Playbook]], [[Screenshot Analysis]], [[Low-End Device Playbook]], [[Magical Roll Animation Playbook]]. Built result: `Documents/Roblox/UI Kit/README.md`.

## What the sites actually seem to do (inferred, not verified)
I could not read any of their code, so this is from their marketing pages and from open-source methods.
- **A closed style preset.** Bloxsmith advertises "real style presets"; the AI picks from a fixed look instead of inventing one. Fixed colours, fonts and radii remove most of what makes AI UI look inconsistent.
- **A fixed component set.** The prompt is mapped to known pieces (frames, buttons, images) and emitted as Luau or Studio objects (GuiForge and Roblox GUI Maker export Luau; some also `.rbxmx` or React-Lua).
- **Curated art assets.** Bloxsmith says it pulls in curated assets. ForgeGUI generates GUI art as images. This is a large part of why their results look polished.
- **Automatic checking.** Bloxsmith claims "automated validation". The open-source `figma-to-roblox-ui` skill shows what such a check looks like: a Luau validator that flags Offset sizes, uncentered anchors, fixed-size strokes and unscaled text.
- **The one-prompt demos are curated.** The sponsor videos picked cases that fit the preset. A closed vocabulary makes a good demo easy and a new look hard. Treat "whole game in one prompt" as marketing; the repeatable gain is in the first four points.

I found no evidence that they rely on a smarter model. The advantage is **structure around the model**.

## What we copied (all free / ours)
| Their part | Ours |
|---|---|
| Style presets | `UI Kit/luau/UITheme.luau`: Candy, Pixel, Aura, derived from the reference screenshots |
| Component set | `UI Kit/luau/UIKit.luau` (about 20 components) |
| The "readme/config" that steers the AI | `.claude/skills/make-ui/SKILL.md`: the procedure, rules and honesty limits |
| Validation | `UI Kit/luau/UIValidate.luau`, adapted from xtrair's MIT validator |
| Example output | `UI Kit/luau/UIScreens.luau`: 9 screens recreating the images |
| Builder | `UI Kit/luau/UIBuild.luau` |

## Open-source parts worth knowing about
- `xtrair/figma-to-roblox-ui` (MIT): the rules and validator we adapted. Written for Figma input; we use its rules without Figma.
- `thynomex/figrbx`, `UiUyHerrera/FigmaToRoblox` (MIT): only if we ever design in Figma.
- `react-lua` (jsdotlua, MIT), `Fusion` (Elttob), `Quark` (creepersaur, MIT): reactive UI libraries. A heavier route than our plain component functions; worth it only if screens become highly dynamic. None of them ships ready-made buttons and modals.
- Excalidraw plugin for Obsidian (AGPL-3.0, installed): the drawing surface in [[UI Screens]].

## Status and honest limits
- **Tested 2026-10-25 in Studio.** Installed as `ReplicatedStorage.UIKit`; all 9 screens build, pass the validator, and were screenshotted in a playtest (renders: `UI Kit Renders/`). The `ScaledSize` stroke API works. Three real bugs were found and fixed (TextWrapped/TextScaled order, scaled stroke and corner size on big panels, four emoji that do not draw). Per-screen verdicts and limits: `UI Kit/README.md`.
- **Coverage:** 9 screens built out of the families in the 67 screenshots; about 10 families are not built yet (listed in the UI Kit README).
- **Art is the gap.** The reference games look the way they do mostly because of custom 3D-style icons, frames and effects. The kit uses emoji and flat gradients. To match the references we need image assets; that part is not solved by any code.
- **"Objects" and "games"** from your earlier requests are not covered by this kit: 3D pets/props belong to the Hunyuan3D pipeline and procedural models, and the merge tower defense game is separate.

## Next steps
1. (Done) Install, validate, playtest, compare, fix.
2. Build the unbuilt screen families and test on a real phone.
3. Decide on art: generate a small icon and frame set (an image generator plus upload to Roblox) and let `UIKit` use `ImageLabel` for those pieces.
4. Port the screens the game really needs (HUD, shop, crate reveal, settings) into the game's own UI, replacing the mock text with real data.

## Gaps
- No access to the vendors' real prompts, schemas or code.
- Not read: Bloxsmith's and LuaPilot's own docs beyond their landing pages.
