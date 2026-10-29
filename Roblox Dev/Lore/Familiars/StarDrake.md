# Familiar 4: Star Drake (T078)

Status: design sheet and bio written overnight 2026-10-28. Follows [[Character Bible Rules]] and [[Cast List - 12 Familiars]]. The turnarounds and silhouette test are drawn by code (`tools/familiar_sheet.py star_drake`); a concept sheet, not final art. Files: `Roblox Dev/Assets/Characters/Design Sheets/StarDrake_sheet.png`, `StarDrake_silhouette.png`, `StarDrake_report.txt`. Look and feel UNVERIFIED by a human.

## Card
- **Name and epithet:** Star Drake, last of the Choir.
- **Faction and element:** Star Choir; cosmic. **Rarity:** Legendary. **Role (one verb):** Starfall (long-range burst, ranged ultimate). **Home set:** Above the Grey Veil. Kept from the current code (same name, redesigned; the code colour is gold, here the body is indigo with gold stars, so the code colour would change in T101).
- **Signature hue:** deep indigo `#1E2A78` with wing blue `#3454AA`, star white and star gold `#F0C040`; glyph: star (the Choir's).
- **Identity colour (T088, colour-blind tested):** `#1E2A78`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (23 words):** The Star Drake is the last voice of the Star Choir, and it sings one long note so the city will not forget.
- **Gesture:** sings one long note while its tail star flares.
- **Flaw:** slow to charge its ultimate when it has no other familiar nearby; it does not like to sing alone.
- **Voice (3 words):** remote, grand, lonely. Lines: summon "I have been singing for some time." Attack "Listen." Victory "It is not finished. It never is."

## Longer bio (collection card, about 140 words)

The Star Choir once sang the whole sky into tune, one voice for each constellation, and the Star Drake carried the lowest note. The others stopped singing when the clock stopped, one by one, as the fog took their hours, and the drake alone is still holding its part. It does not know whether anyone is listening. It does not stop. Its body is a river of dark indigo with a line of stars running down it, and where it flies the stars rearrange into shapes that are almost words. It is wary of the lantern, because lamps keep the sky closed, but it is lonely, and loneliness has made it brave. If you light the lantern and keep it lit, the drake will come down to the edge of the fog and sing beside it. That is all it has ever wanted: a second voice.

## The three turnarounds (what the sheet shows)
- **Front:** a long S-curved body with a line of small stars joined like a constellation, two spread wings of angled fans with a gold star at each tip, a pentagonal head with two swept horns and a three-star crown, narrow white eyes, and a large gold star at the tail.
- **Side:** the S-curve sways more widely, one wing, the head in profile.
- **Back:** the same body and wings with the head turned away (no eyes).
- **Colour:** indigo body so it stands out against the pale gaslit set and against black cosmic skies; the gold stars give it Legendary warmth.

## Silhouette and design decisions
- **Long, thin and flowing:** the tallest, narrowest and most S-curved shape in the cast, against Ember's tall teardrop, Gargoyle's wide block and Frostling's round bell. Its overlap with a plain pole is very low (see the report), meaning the S-curve and wings change the shape a lot.
- The first drawing had the wings so wide that they were cut off at the edge of the sheet and the side-view horns collapsed into thin lines; I shortened the wings and widened the horn bases before finalising.
- The wings are fans with gold tip stars so the Legendary silhouette has a glittering outline in the dark; at the far camera the tip stars will read as sparkles rather than shapes, so the wings carry the shape.
- Merge tiers (T100, final): tier 2 adds a second, smaller pair of wings (the long note carries further on more wing); tier 3 adds a tail tipped with one lit star-point (the last star of the Choir answers it). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks
The script reports the front silhouette's overlap with a circle, square, triangle and a plain pole at 64 px, and between views. Distinctness among the first four familiars is checked by `Overnight/evidence/familiar_check.py`.

## Next steps (other tasks)
Shape generation and cleanup (T089, T090), textures (T091), animations and the starfall ultimate (T092 to T095, T138), portrait card (T096), model swap and Config wiring (T101, T102).
