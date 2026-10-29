# Facial Expressions (T110)

Three expressions for the four familiars that have a drawn face: Ember, Frostling, Brass Hound, Gargoyle. Concept sheets painted by code (`tools/familiar_expressions.py`) over the textured front stills, in `Assets/Characters/Expressions/` (`<Name>_expressions.png`, `_expressions_sheet.png`). Look UNVERIFIED by the user; the other eight familiars have no drawn face (masks, hoods, helmets, a hollow face) and are not covered here.

| Expression | Used when | Eyes | Mouth |
|---|---|---|---|
| happy | idle, spawn, victory | closed upward arcs | small smile |
| fierce | attack | narrow with inner brows lowered | zigzag with one fang |
| hurt | taking damage, banish | wide with highlight, inner brows raised, a tear | small frown |

The reference column is the face as modelled (round open eyes). The face parts are baked into the colour texture, so in game each expression is a **separate colour texture** (3 per familiar, 12 in all) swapped on the SurfaceAppearance, or an overlay decal on a small face plane; the choice and the texture work belong to T123 (texture sets). The concept sheets are not usable as game textures: they are painted on a 384 px still, not on the model's UV map.
Known flaws: the cover patch under the Frostling's mouth shows as a bluish smudge; the Brass Hound's mouth sits on the collar edge; Gargoyle's happy eyes are small arcs on a dark face and read weakly.
