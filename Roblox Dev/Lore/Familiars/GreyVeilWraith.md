# Familiar 12: Grey Veil Wraith (T086)

Status: design sheet and bio written overnight 2026-10-28. Follows [[Character Bible Rules]], [[Cast List - 12 Familiars]] and its humanoid revision (the Wraith is humanoid: a ghostly figure with head, torso and arms, and no legs). The turnarounds and silhouette test are drawn by code (`tools/familiar_sheet.py grey_veil_wraith`); a concept sheet, not final art. Files: `Roblox Dev/Assets/Characters/Design Sheets/GreyVeilWraith_sheet.png`, `GreyVeilWraith_silhouette.png`, `GreyVeilWraith_report.txt`. Look and feel UNVERIFIED by a human.

## Card
- **Name and epithet:** Grey Veil Wraith, the unbound.
- **Faction and element:** Unaligned; fog. **Rarity:** Legendary (boss-tier). **Role (one verb):** Drain (hits through armour and heals the lantern a little). **Home set:** Above the Grey Veil.
- **Signature hue:** Grey Veil grey `#9698A2` with a darker hood `#545664`, pale `#D6D8E2` and one streaming ribbon in pale violet `#B8AADC`; no faction glyph (unaligned).
- **Identity colour (T088, colour-blind tested):** `#EDEEF4`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (25 words):** The Wraith belongs to no faction and answers to no hour, and it follows the lantern only because it is the one thing still warm.
- **Gesture:** reaches out one long arm, palm up, then closes it slowly.
- **Flaw:** it is unbound, so it ignores every neighbour buff (no Ward, Archivist or Echo bonuses), good or bad.
- **Voice (3 words):** sparse, echoing, unmoored. Lines: summon "...here. ...or there." Attack "...take." Victory "...none. ...mine."

## Longer bio (collection card, about 130 words)

The fog above the city has a shape, and sometimes the shape stands up. The Grey Veil Wraith is what is left when an hour is lost and nobody mourns it: a tall figure of grey cloth with no legs, drifting a hand's breadth above the ground, with a hood that sits a little to one side and a hollow face in which two pale points of light float like the last two stars. A single violet ribbon trails from its shoulder and is the only thing about it that is quite certain. It belongs to no faction. The Court will not have it, the Guild cannot file it, and the Choir sings around it. It follows the lantern because the lantern is warm. It will take what it is given, and it will give back exactly as much, and not one coin more.

## The three turnarounds (what the sheet shows)
- **Front:** a tall, slumped, hooded grey figure with a hollow dark face and two pale eyes, long thin arms with spread fingers, a ragged hem broken into wisps, hovering above the ground, and a violet ribbon streaming up from one shoulder.
- **Side:** the same figure in profile with one arm and the face turned.
- **Back:** the hood from behind, the long arms and the wisps.

## Silhouette and design decisions
- **The only floating, ragged, asymmetrical figure:** no feet, jagged wisps at the hem, a head tilted to one side and a long S-ribbon rising above it; the ribbon is its signature, and gives the shape a tall asymmetric top. Its overlap with a plain ghost sheet is moderate (0.48 in the report).
- The first drawing had a stiff zig-zag ribbon like a lightning bolt; I redrew it as a flowing curve before finalising.
- Weak points of the concept sheet: the wisps are dark spikes, not soft tatters, and the arms are plain bars. A modelling pass should make the hem soft and semi-transparent (a Roblox transparency material or a few separate wisp parts).
- Boss-tier means it should look rare: the pinprick eyes and the violet ribbon are the two high-contrast details; everything else is grey on purpose so that they are what the player sees.
- Merge tiers (T100, final): tier 2 adds a second trailing ribbon of grey cloth (more fog has chosen to follow it); tier 3 adds a pale lantern held in one trailing sleeve (it follows the lantern, so now it carries one). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks
The script reports the front silhouette's overlap with a circle, square, triangle and a plain ghost sheet at 64 px (aspect ratio kept), and between views. Distinctness among the cast is checked by `Overnight/evidence/familiar_check.py`.

## Next steps (other tasks)
The 12-up greyscale silhouette strip (T087), the colour-blind test (T088), shape generation and cleanup (T089, T090), textures (T091), animations (T092 to T095), portrait card (T096), model swap and Config wiring (T101, T102).
