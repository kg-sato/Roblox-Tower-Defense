---
date: 2026-10-27
tags: [research, ui, vfx]
---
# UI Methods and Magic Effects

Question: why does our UI still read as boxes after two restyles, and what do Roblox games use instead? Follows [[Research/UI/bbstudios UI Reference|bbstudios UI Reference]].

## Answers (sourced)
| Question | Answer | Source |
|---|---|---|
| How do games get non-box frames? | With images. 9-slice keeps decorative corners fixed while edges and centre stretch; slice properties exist only on ImageLabel/ImageButton, not Frame. UICorner only makes round corners (no bevels or ornate shapes). | [Roblox docs: 9-slice](https://create.roblox.com/docs/en-us/ui/9-slice.md), [DevForum: 9-slicing use cases](https://devforum.roblox.com/t/9-slicing-use-cases/667672), [DevForum: bevel request for UICorner](https://devforum.roblox.com/t/add-a-bevel-option-to-uicorner-for-non-rounded-corners/4044818), [DevForum: complex UI shapes](https://devforum.roblox.com/t/complex-ui-shapes/552467) |
| Can we make those images without uploading? | Yes: EditableImage. Create with `AssetService:CreateEditableImage`, write pixels with `WritePixelsBuffer`, show via `ImageLabel.ImageContent = Content.fromObject(img)`. It fails by default in published games: the owner (13+ and ID verified) must turn on "Allow Mesh / Image APIs" (Studio: Experience Settings > Security). | [EditableImage reference](https://create.roblox.com/docs/reference/engine/classes/EditableImage), [EditableImage reference (md, enable steps)](https://create.roblox.com/docs/en-us/reference/engine/classes/EditableImage.md), [DevForum: "not accessible" error](https://devforum.roblox.com/t/editableimages-api-enable-error-while-already-enabled/4761562) |
| Curved lines in UI? | `Path2D` is a GUI object with control points, Color3 and Thickness; no fill members are listed (inference: lines only). | [Path2D reference](https://create.roblox.com/docs/reference/engine/classes/Path2D) |
| Can UI blur what is behind it? | Not natively (open feature request). Workarounds: blur the whole 3D world with BlurEffect (UI stays sharp), or a glass part + DepthOfField to blur a region (some modules disable it below graphics level 8; older modules reported broken). | [DevForum: blur effects for UI](https://devforum.roblox.com/t/blur-effects-for-ui-elements/359498), [DevForum: DoF blurred UIs](https://devforum.roblox.com/t/blurred-uis-using-depth-of-field-effect/4734313), [DevForum: Objectual UI Blur](https://devforum.roblox.com/t/objectual-ui-blur/3626057), [DevForum: liquid glass with EditableImage](https://devforum.roblox.com/t/liquid-glass-ui-blur-with-editable-images/4812154) |
| Fonts | Merriweather (serif) and Fondamento load via `Font.fromName`; Cinzel, Cormorant, Playfair, EB Garamond do not (tested in Studio 2026-10-27). | Studio test |

## Why the last two passes still looked like boxes
Every surface was a Frame with a UIStroke. Strokes draw a hard rectangle outline whatever we add on top. The reference panels have no outline: their edges fade, and their silhouettes are broken by images (emblems, props).

## What was built (2026-10-27)
- `ReplicatedStorage.FrameArt` (source `UI Kit/FrameArt.luau`) paints art at runtime: feathered glass panel (9-slice, film grain, faint inner rim, top glow), glossy capsule buttons with rim and outer glow, a round emblem with rings and ticks, a tapered divider, a soft glow and a screen vignette. All pieces render in about 62 ms on this PC.
- GameClient uses it when available: panels get the emblem breaking the top-left corner, a serif caps title, a spaced subtitle, a tapered divider, an X with a hover glow, drifting motes, and an open that fades the glass, spins the emblem in and fills rows one by one. Modal panels (start, Roll Odds, Progression) blur and desaturate the world (blur 14 desktop, 10 touch, 8 with reduced motion or flashes off). The old scroll style stays as the fallback.

## Status (2026-10-27, after the user enabled Allow Mesh / Image APIs)
Seen in Play, no script errors. First look had a faint rim that still traced a box; removed (rim now top-only), glass darkened to near-black, alpha 0.9, Odds rows got faint separators, the tutorial highlight became a gold glow instead of a square outline.

Comparison with the Commands panel (video 7700685121522912542), point by point:
| Reference trait | Ours | Match |
|---|---|---|
| No border, edges fade out | feathered glass, no outline | yes |
| Dark translucent body | near-black glass, world blurred behind | yes |
| Big emblem breaking the top-left corner | 96 px ringed emblem with letter | closer: painted symbols (star, gem, paw, crown) since pass 4; theirs is calligraphy |
| Serif caps title + small spaced subtitle | Merriweather Bold caps + spaced caps subtitle | yes |
| Thin rows split by faint lines | Odds rows separated | yes (other panels not yet) |
| Accent close mark | red X with hover glow | yes |
| World dimmed behind | blur 14 + desaturate | yes (stronger than theirs) |
| Layered open | glass fade, emblem spin, header then rows | yes |
This is a checklist, not a measured score; whether it reaches "90%" is the user's call.

## Gaps
- Painted art (calligraphy glyphs, illustrated banners) still missing.
- Skill Tree hexes and the reveal glow/rays were moved to painted art on 2026-10-27 (pass 5); the 3D neon aura disc under legendary pets in the reveal still renders flat.
- EditableImage memory on low-end phones not measured.
- Region blur (DoF glass) not tried; whole-world blur only.
