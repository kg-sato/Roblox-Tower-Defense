# UI Design Playbook

Researched 2026-10-24. Every rule below comes from an official Roblox page unless marked otherwise. Related: [[Roblox Success Sources]], [[Engagement Loop Playbook]], [[Systems]], [[Game Design Doc]]

## What popular games do (and what I could verify)

I could not inspect the actual UI of Grow a Garden or Steal a Brainrot from text sources, so I am not claiming pixel-level details about them. What the sources do confirm is their structure:
- [Grow a Garden](https://en.wikipedia.org/wiki/Grow_a_Garden): plant, harvest, earn currency, buy better seeds. Rotating seed stock, weekly exclusive items, loot-box pets, Robux to skip waiting.
- [Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot): a conveyor belt sells characters, each earns income over time, a base with a shield button, steal from others, rebirth.

Both UIs therefore exist to serve a few things: a currency counter, a shop with stock, an inventory/collection, a progress or timer indicator, and Robux purchase prompts. **To do:** open both games, screenshot each screen (HUD, shop, inventory, purchase prompt), and save them in the vault under `Research/Screenshots/` so we copy the structure, not the art. Roblox's own advice is the same: [study popular games in your genre to learn which conventions players expect](https://create.roblox.com/docs/production/game-design/ui-ux-design).

## Core rules (official)

Source: [UI and UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design), [Design for Roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox), [Adaptive design](https://create.roblox.com/docs/production/publishing/adaptive-design).

1. **Mobile first.** Most Roblox players are on mobile. Design the phone layout first, then expand for larger screens. Test on real low-end devices.
2. **Minimal HUD.** Show only what the player needs right now. Core stats and the main action always visible; everything else in menus or tabs.
3. **Hierarchy.** Most important info first. Bright colour and larger size for crucial elements, muted for the rest. Group related things by proximity.
4. **Feedback on every action.** Hover, pressed, and released states; purchase sounds; progress bars; hit reactions. Missing feedback makes players think something is broken.
5. **Use conventions.** X closes dialogs, grey means unavailable, a lock icon means locked, E for proximity prompts. Fewer instructions needed.
6. **One visual language.** Same shapes, colours, icon style everywhere. A stat keeps its colour on every screen; unaffordable prices always look the same; close buttons always sit in the same place. Write it down as a style guide in the vault.
7. **Visuals over text.** The audience is young and international. Use consistent icons, short labels, and make translation easy.
8. **Tabs and search** for large lists (pets, items). Count the steps to reach a goal and cut them.
9. **Motion sparingly.** Pulsing arrows or buttons help in tutorials. Too much overwhelms.
10. **Streamer-friendly.** Consider a hide-UI mode so the game is easy to record and share.

## Making it responsive

Sources: [DevForum UI tips](https://devforum.roblox.com/t/3074034), [Adaptive design](https://create.roblox.com/docs/production/publishing/adaptive-design), [Cross-platform](https://create.roblox.com/docs/projects/cross-platform), [List and flex layouts](https://create.roblox.com/docs/ui/list-flex-layouts).

- **Scale over Offset** for size and position. Use Offset only for pixel-precise alignment, small icons, and `UIStroke` thickness (strokes only support Offset).
- **Set AnchorPoint and Position together.** Centre: anchor (0.5, 0.5), position {0.5,0},{0.5,0}. Bottom-right: anchor (1,1), position {1,0},{1,0}.
- **`UIAspectRatioConstraint`** keeps shapes proportional. **`UICorner`** with Scale keeps the look consistent across devices.
- **Add a text size constraint.** A 75%-width panel is huge on a 4K TV. The cross-platform page warns about this and recommends size constraints for text.
- **Flex layouts:** `UIListLayout` with `HorizontalFlex` for tab bars, `UIFlexItem` so one control fills remaining width, `Wraps` for overflow. Use grid layouts for strict item grids (inventories). Flex has a small performance cost, so use it where it helps.
- **Screen size categories:** `GuiService.ViewportDisplaySize` returns Small (phones, tablets, handhelds), Medium (laptops, monitors), Large (TVs). Use it or Style Editor queries to rearrange or collapse UI on small screens.
- **Respect Roblox's own UI.** Keep clear of the top bar, chat, player list, mobile controls, and device cutouts (use `ScreenInsets`). The top bar height is disputed: a DevForum post says 36 px, a commenter says 58 px. Don't hardcode it; check in the device emulator.
- **Inputs:** `UserInputService.PreferredInput` and `GetImageForKeyCode()` give the right button prompt for keyboard, gamepad, or touch. `InputActionLabel` shows the right prompt with no code. Make every control focusable for gamepad.
- **Test with the Device Emulator** (Test tab) in both orientations.
- Not found in official docs: a minimum touch-target size. A third-party guide ([creation.dev](https://www.creation.dev/blog/roblox-ui-design-best-practices)) says 44x44 px, which is a common mobile convention but not a Roblox rule. Treat it as a starting point.

## Making it look modern

Source: [Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers).

| Effect | How |
|---|---|
| Rounded, pill-shaped buttons | `UICorner` Scale 0.5 or higher |
| Depth | `UIGradient` with two close colours and a slight rotation; gradient on the stroke too |
| Soft lift | `UIShadow` with high blur, low transparency, offset slightly downward |
| Recessed panels | Inset `UIShadow` |
| Outlined / hollow style | `UIStroke` with transparency above 0, or text transparency 1 with stroke only |
| Bold readable text | `UIStroke` on text; avoid thin or decorative fonts; high contrast |

Notes: some `UIGradient` and `UIShadow` options need **Upgraded UIGradients / UIShadows** turned on in Beta Features. Don't tween the thickness of a text `UIStroke` (flicker and performance problems). Wrap a whole panel in a `CanvasGroup` to fade it as one piece.

## Animation (what makes UI feel alive)

Source: [UI animation](https://create.roblox.com/docs/ui/animation).

- `TweenService:Create(gui, TweenInfo.new(time, style, direction), {props}):Play()`.
- Tween Position and Size using Scale, with the AnchorPoint set first.
- Easing styles: Linear, Sine, Quad (default), Cubic, Quart, Quint, Exponential, Circular, Back, Bounce, Elastic. `Back` and `Elastic` Out give the bouncy "pop" common in simulator UIs (my suggestion; the docs list the styles but don't prescribe them).
- Button feedback pattern: tween size up on hover or press, back on release, play a sound.
- Typewriter text: increase `MaxVisibleGraphemes` step by step.
- Sequence tweens through the `Completed` event.

Starter snippet for a pressable button (LocalScript; my example, untested in Studio):

```lua
local TweenService = game:GetService("TweenService")
local info = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function addPress(button: GuiButton)
	local scale = Instance.new("UIScale")
	scale.Parent = button
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, info, { Scale = 0.92 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, info, { Scale = 1 }):Play()
	end)
end
```

## Onboarding UI

Sources: [Onboarding](https://create.roblox.com/docs/production/game-design/onboarding), [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques).

- Highlight the target button, dim the rest of the screen, add an arrow (Hello Kitty Cafe).
- Teach in context: show a tip when the player first needs it, not up front.
- Timed hints: if most players press the button within 10 s, highlight it at 11 s for the stuck ones only.
- End onboarding with a deliberate moment of joy (reward, animation, effects).
- Show short-, mid-, and long-term goals in visible UI spots.

## Build order for our game

1. Write a one-page style guide: 3 colours, 1 font, corner radius, stroke width, button states.
2. Build a reusable button, panel, and currency-counter component (a ModuleScript that applies the style).
3. Mobile-first HUD: currency, main action, one menu button.
4. Shop and inventory with tabs and a grid layout.
5. Feedback pass: sounds, press tweens, number pop-ups when currency changes.
6. Device Emulator test on phone, tablet, and desktop; check nothing overlaps the top bar or controls.

## Gaps

- No direct inspection of competitor UIs yet (see the to-do above).
- Not read: the Style Editor docs (themes and tokens), accessibility player-preference docs, ProximityPrompt docs.
