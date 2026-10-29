# Fog, haze and volumetric light in Roblox (T050)

Question: which Roblox settings make fog, haze and light shafts, and what values do our stage sets start from?

Roblox Creator Hub pages fetched 2026-10-28 (undated). The Hub pages give few ranges and no performance numbers for these effects.

## Facts (sourced)
**Atmosphere** ([Creator Hub, Atmosphere guide](https://create.roblox.com/docs/environment/atmosphere); class page [Atmosphere](https://create.roblox.com/docs/reference/engine/classes/Atmosphere) lists the six properties without ranges)
- Density: how many particles fill the air; higher values block more of the view of objects and terrain and also affect the skybox seen through them (example 0.35).
- Offset: light transmission between camera and sky; higher values create a horizon silhouette, lower values blend distant terrain into the sky; balance against Density (range shown 0 to 1).
- Haze: haziness above the horizon and into the distance; pair with Color for a smoky or foggy tint.
- Color: the atmosphere's hue; works best with a high Haze value.
- Glare: a glow around the sun (range shown 0 to 1); needs Haze above 0.
- Decay: the hue away from the sun, fading from Color to Decay; needs Haze and Glare above 0.
- The guide does not cover Lighting.FogEnd, Technology, sun rays, or recommended settings.

**Lighting properties** ([Creator Hub, Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting)): FogColor, FogStart, FogEnd, Ambient, OutdoorAmbient, Brightness, ColorShift_Top, EnvironmentDiffuseScale, EnvironmentSpecularScale, ExposureCompensation, ShadowSoftness exist; the page lists no defaults or ranges. Lighting.Technology and ShadowColor are marked deprecated.

**Post-processing** ([Creator Hub, Post-processing effects](https://create.roblox.com/docs/environment/post-processing-effects)): BloomEffect (light parts glow), BlurEffect, ColorCorrectionEffect (Brightness, Contrast, Saturation, TintColor; useful for feedback such as a red low-health tint), DepthOfFieldEffect, SunRaysEffect (a halo of rays around the sun that moves with ClockTime; objects between camera and sun shape the rays; Intensity and Spread properties, no ranges on the page), ColorGradingEffect (tone mapping). Effects in Lighting apply to all players; effects on Camera apply to one player. Some effects may not appear unless Studio's Editor Quality Level is the highest. The page gives no performance or mobile guidance. See [[Mobile performance limits]] for the general performance advice (shadows are expensive; transparency overdraw).

## What our place has now (read-only query of Studio, Edit mode, 2026-10-28)
Lighting: Ambient and OutdoorAmbient (0.275, 0.275, 0.275); Brightness 3; ClockTime 14; FogColor (0.753, 0.753, 0.753); FogStart 0; FogEnd 100000 (effectively no distance fog); ExposureCompensation 0; GlobalShadows true. Children: Sky; SunRays (Intensity 0.01, Spread 0.1); Atmosphere (Density 0.3, Offset 0.25, Haze 0, Glare 0, Color 0.78 grey); Bloom (Intensity 1, Threshold 2); DepthOfField. Runtime scripts may change these per stage set; I did not check Play mode.

## Recommendations (not sourced)
1. Fog by Atmosphere, not FogEnd: raise Haze above 0 and tint Color for each set (Harbour: cool blue-grey; Cathedral: moon-silver; Foundry: ash brown; Grey Veil: pale violet), with Density 0.3 to 0.4 as a start and the camera's sightline in mind (T164).
2. Light shafts: SunRays is cheap to set but its Intensity is near zero now (0.01); the Cathedral window shafts (T105) are better as lightweight angled neon-transparent parts or beams than as the global SunRays; test cost on a phone before using many.
3. Keep Brightness lower and ClockTime near night for the lamp-lit sets so lamps (about 2400 K, see [[Victorian interiors and lamplight palettes]]) pop; lift Ambient slightly so units stay readable.
4. Colour-grade by ColorCorrection tint per set rather than adding more effects; one grading effect per set keeps cost down.
5. Test on Low quality: effects can disappear at low graphics levels, so the board must read without them.

## Sources
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://create.roblox.com/docs/environment/atmosphere | fetched 2026-10-28 | read |
| 2 | https://create.roblox.com/docs/reference/engine/classes/Atmosphere | fetched 2026-10-28 | property list only |
| 3 | https://create.roblox.com/docs/reference/engine/classes/Lighting | fetched 2026-10-28 | property list only |
| 4 | https://create.roblox.com/docs/environment/post-processing-effects | fetched 2026-10-28 | read |
| 5 | https://create.roblox.com/docs/reference/engine/classes/SunRaysEffect | fetched 2026-10-28 | properties only |
