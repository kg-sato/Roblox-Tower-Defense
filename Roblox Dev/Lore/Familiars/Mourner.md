# Familiar 9: Mourner (T083)

Status: design sheet and bio written overnight 2026-10-28. Follows [[Character Bible Rules]], [[Cast List - 12 Familiars]] and its humanoid revision (the Mourner was already humanoid). The turnarounds and silhouette test are drawn by code (`tools/familiar_sheet.py mourner`); a concept sheet, not final art. Files: `Roblox Dev/Assets/Characters/Design Sheets/Mourner_sheet.png`, `Mourner_silhouette.png`, `Mourner_report.txt`. Look and feel UNVERIFIED by a human. **Humanoid:** yes, a tall veiled human figure. Tone: grief by implication, no gore ([[Tone Guide]]).

## Card
- **Name and epithet:** Mourner, who gave up its face.
- **Faction and element:** Hollow Court; silence and veil. **Rarity:** Epic. **Role (one verb):** Hush (interrupts an enemy's special move). **Home set:** Silent Cathedral.
- **Signature hue:** ash charcoal coat `#3E4252` with a pale blue veil `#B0BED4`, a bone-white blank face and a white lily; glyph: water triangle (the Court's).
- **Identity colour (T088, colour-blind tested):** `#1F2230`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (20 words):** The Mourner gave its face to someone who needed it more, and has worn the veil ever since, without complaint.
- **Gesture:** bows its head and raises a single finger to where its lips would be.
- **Flaw:** Hush needs two still seconds to prime, so it is weakest on a tile where enemies arrive without warning.
- **Voice (3 words):** soft, formal, faceless. Lines: summon "Forgive the interruption." Attack "Hush." Victory "Rest now. All of you."

## Longer bio (collection card, about 130 words)

Nobody in the Silent Cathedral will tell you whom the Mourner gave its face to, and the Mourner will not say. It will only tell you that someone needed one, and that it had one to spare. It wears a long charcoal coat, a veil the colour of the hour before dawn and a smooth bone-white oval where its features used to be, with one hairline crack from the last time it wept. It is the most courteous being in the nave. It apologises when it steps on your shadow. When a loud thing comes down the aisle, the Mourner lifts one finger to its absent lips, and the loud thing finds, to its own surprise, that it would rather not. It carries a single white lily in its clasped hands. Nobody has ever seen it wilt.

## The three turnarounds (what the sheet shows)
- **Front:** a very tall, narrow figure in a long A-line coat with pale buttons, a wide veil cape across the shoulders, long sleeves hanging, hands clasped over a white lily, a rounded veiled hood and a blank oval face with one crack.
- **Side:** the head bowed forward, the veil falling behind as a long train, the face in profile.
- **Back:** the long veil falling the full height of the back, the dark back panel of the coat.

## Silhouette and design decisions
- **A pawn-like shape:** a rounded hood over a wide shoulder cape on a narrow column, so it is wide at the top and narrow below, the reverse of Ember's wide-footed flame; the long train in the side view makes a unique profile. The first version had a pointed hood and a plain column, which read as a spike next to Ember in the T087 strip; a one-sided shawl made it worse (it read like Ward's cone, 0.72), so I settled on the cape and the round hood. Its overlap with a plain tall column is 0.75 in the report.
- The blank face is the key idea: a character with no eyes or mouth can still read as sad through posture alone (head bowed, hands clasped, finger raised).
- Weak points of this concept sheet: the hands and the lily are tiny and unclear, the arms read as straight bars, and the cape is a flat trapezoid. A modelling pass should add visible hands, a folded sleeve and a drape to the veil.
- Merge tiers (T100, final): tier 2 adds a second veil layer (it has given up more of its face than before); tier 3 adds a small candle held in the free hand (it now lights the way for those who follow). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks
The script reports the front silhouette's overlap with a circle, square, triangle and a plain tall column at 64 px (aspect ratio kept; the earlier reports were redone after I fixed the way tall figures were stretched), and between views. Distinctness among the cast so far is checked by `Overnight/evidence/familiar_check.py`.

## Next steps (other tasks)
Shape generation and cleanup (T089, T090), textures (T091), animations (T092 to T095), portrait card (T096), model swap and Config wiring (T101, T102).
