---
date: 2026-10-28
tags: [ui, quality, measurement, textures, lighting]
---
# Why ours looks lower quality (measured)

The user (2026-10-28): the loading screen, skill tree and level path "still feel lower quality than the other games. Are they adding shaders or lowering opacity? I can't quantify the visual difference." Then: "Our current style for the loading screen is low poly? Our game is supposed to be high definition and high shader / quality."

## Answer
- **Not shaders.** Roblox has no custom shaders for UI or parts. The high-end look comes from **painted images** (soft glows, nebula, grain made in an image editor or painted at runtime) and, in 3D only, **Lighting post-effects** (Bloom, ColorCorrection, Atmosphere, DepthOfField, SunRays). Post-effects do not touch ScreenGuis.
- **The "low poly" feel was our method, not a limit:** our screens were built from flat Frames (solid rectangles and 1-2 px strokes). That reads as vector clip-art next to painted art.
- Roblox devs add texture with a tiled, semi-transparent noise or scanline ImageLabel over the UI ([DevForum: GMod-style death screen](https://devforum.roblox.com/t/how-to-recreate-a-gmod-style-death-screen-scanlines-static-and-audio-muffling/4753712); [tiling with ScaleType Tile](https://devforum.roblox.com/t/grow-a-garden-ui-example/3764006)); glow is a stretched transparent blurred image behind an element, since there is no native GUI glow ([GUI Neon/Glow Effect](https://devforum.roblox.com/t/gui-neonglow-effect/607011)).
- Art guidance: a limited (analogous or monochrome) palette and strong value structure read as more professional; high saturation only at the focal point ([Wayline](https://www.wayline.io/blog/limited-color-palettes-game-art), [Pixune](https://pixune.com/blog/color-theory-in-game-art-basics-and-complementary/), [Meriden lesson](https://instruction.meridenk12.org/courses/191/1/3/)).

## Measurement (`tools/look_quality.py`)
Five stills from the user's Roblox recordings (Bit Tensei, Dao Cultivation x2, Fishing Master, Descend) and five pins, against eight captures of ours.

| Metric | References | Ours (before) | Reading |
|---|---|---|---|
| **huesd** (spread of hues on screen) | 0.07 to 0.83 (one outlier 1.97) | **1.08 to 2.15** | ours mixed gold + violet + teal + pink + white; theirs stay in one hue family |
| **grain** (texture in dark flat areas) | 0.011 to 0.067 | **0.004 to 0.012** | ours had empty flat black behind thin lines |
| hard edges, glow halo, tone levels, vignette | overlapping ranges | overlapping ranges | not the difference |

## Fix (in progress)
- `FrameArt.luau` gains `nebula`, `grain` and `rays` painters (EditableImage, no uploads). The painter now yields every 24 rows and the nebula is 128 px, after a heavy paint call coincided with Studio closing.
- **Loading:** one warm brass/amber family through the clock tunnel, painted nebula dust, light rays, vignette and grain; painted glow at the tunnel's end. The dust cools to blue starlight when the tree forms (the arc: brass time to cosmic future).
- **Skill tree:** one blue-white family like the user's tree pins (gold only as the accent), painted nebula layers, a light pillar through the trunk, vignette, grain over the whole screen.
- **Level path (3D):** while open, night lighting, Atmosphere fog so the far end disappears, Bloom, and a ColorCorrection grade in the section's hue; all saved and restored on close.
- Then re-measure with the same tool and check in Play.
