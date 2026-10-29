---
date: 2026-10-27
tags: [howto, characters]
---
# How to Add a Character

No code changes. Everything reads from `ReplicatedStorage.Characters` (see `Config` "Character registry" and `Models` "Character folders").

## Steps (in Studio)
1. In `ReplicatedStorage > Characters`, duplicate an existing folder (or add a Folder) and name it with the new id, no spaces (e.g. `Lanternling`).
2. Set its attributes:

| Attribute | Type | Example | Meaning |
|---|---|---|---|
| DisplayName | string | Lanternling | Name shown in the game |
| Rarity | string | Common / Rare / Epic / Legendary | Roll pool it joins |
| Damage | number | 9 | Damage per hit at tier 1 |
| Cooldown | number | 0.8 | Seconds between attacks |
| Range | number | 24 | Attack range in studs (the range circle) |
| Footprint | number | 2.4 | Radius it occupies; others can't overlap |
| Color | Color3 | | Shot and accent colour |
| Order | number | 8 | Sort order in lists |
| Signature | string | Starfall | Optional cutscene ultimate (function name in `ReplicatedStorage.CutsceneFX.signatures`); `SignatureName` is the title on the cut-in, `SignaturePower` the damage multiplier (default 1.25) |
| Shot | string | flame | Projectile look: bolt, flame, leaf, spark, ice, stone, card, star (`ReplicatedStorage.ProjectileFX`) |

3. Optional children:
   - **Model**: a `MeshPart` or `Model`. Attributes on the folder style it: `Height` (studs), `Yaw` (degrees, turn so it faces -Z), `Tint` (Color3), `Material` (e.g. SmoothPlastic). For skinned meshes with clips, the clip's top pose must be named after the id.
   - **Animations**: `Animation` objects (uploaded ids, work live) or `KeyframeSequence`s (Studio only) named `Idle` and `Attack`.
   - **Effects**: ParticleEmitters, Lights or Attachments; they are cloned onto the pet.
4. Press Play. The character is in the roll pool, the odds panel and the pet panel. Without a Model it uses a round fallback in its `Color`.

Tested 2026-10-27 with a temporary folder (attributes + one emitter): it joined the Rare pool, built, and got its effect.

## Rarity escalation (convention)
Put these in the folder's `Effects` so rarer familiars look rarer: Common nothing; Rare a soft sparkle emitter in the rarity colour; Epic also a PointLight; Legendary also gold star sparkles and a slow rising aura. Copy them from an existing folder of the same rarity. Merging adds tier glow on top automatically.

## Modelling tip
Roblox `Ball` parts are always perfect spheres. For ellipses (wings, leaves, bodies) use a Block part with a `SpecialMesh` of type Sphere.
