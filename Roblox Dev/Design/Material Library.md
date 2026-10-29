# Material Library (T105)

Eight material recipes for the familiars, written overnight 2026-10-29 as data in `Studio_Export/FamiliarMaterials.luau` (installed as `ReplicatedStorage.Shared.FamiliarMaterials`; test `Tests/FamiliarMaterials.test.luau`, 69 checks). A recipe is a Roblox built-in material plus colour, reflectance and transparency, and for the glowing ones a point light and a small particle emitter. `FamiliarMaterials.apply(part, name)` sets it and returns the extras. Look and fit on the real familiar models are UNVERIFIED: the swatches were only checked on plain spheres and blocks.

| Recipe | Material | Colour | Reflectance, transparency | Extras | Used for |
|---|---|---|---|---|---|
| brass | Metal | `#C9A24B` | 0.35, 0 | none | oil lamps, lanterns, Clockwork Guild plates |
| bone | Limestone | `#E8E0C8` | 0, 0 | none | Mourner and Archivist paper, veils, masks |
| glass | Glass | `#BEE1EB` | 0.2, 0.45 | none | lantern panes, Moth-Lantern wings, mirror faces |
| stone | Slate | `#64687A` | 0, 0 | none | Gargoyle, plinths, cathedral |
| ember | Neon | `#FF7628` | 0, 0 | orange point light (1.6, range 9), spark emitter 9 per second | Ember's flame, lamp cores |
| frost | Ice | `#9ED4F0` | 0.12, 0.12 | pale sparkle emitter 5 per second | Frostling, icicles, cold breath |
| ink | Glass | `#0C0A14` | 0.18, 0 | none | veils, wet cloth, shadow |
| starDust | Neon | `#465AD2` | 0, 0.15 | blue-white point light (1.1, range 10), sparkle emitter 14 per second | Star Drake, Mirror Chorister, orbiting stars |

Rules: use the recipe for the whole part, never mix two on one surface; the identity colour of a familiar (T088) still sets the name plate and glow, not the material; glowing recipes (ember, starDust) add at most one light and one emitter per part, so a familiar should apply them to one or two parts only (performance: see the particle budget in the VFX notes). Neon has no surface detail, so ember and starDust read as flat colour in a still and rely on the light and the sparkles in motion.

Open decisions: whether the textured Hunyuan models (T091) should be recoloured with these recipes or keep their baked textures (the recipes work best on the Roblox-built parts, such as the rarity kit and merge-tier features); a MaterialVariant or SurfaceAppearance version of each recipe (real roughness and normal maps) is possible later, but it needs texture uploads.
