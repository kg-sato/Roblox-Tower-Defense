# Familiar 3: Frostling (T077)

Status: design sheet and bio written overnight 2026-10-28. Follows [[Character Bible Rules]] and [[Cast List - 12 Familiars]]. The turnarounds and silhouette test are drawn by code (`tools/familiar_sheet.py frostling`); a concept sheet, not final art. Files: `Roblox Dev/Assets/Characters/Design Sheets/Frostling_sheet.png`, `Frostling_silhouette.png`, `Frostling_report.txt`. Look and feel UNVERIFIED by a human.

## Card
- **Name and epithet:** Frostling, the cold small guest.
- **Faction and element:** Hollow Court; ice. **Rarity:** Rare. **Role (one verb):** Chill (slows enemies). **Home set:** Silent Cathedral. Kept from the current code (same name, redesigned).
- **Signature hue:** pale ice blue `#9ED4F0` with a deeper hood `#5896C8`, frost white and one warm mitten accent `#CC79A7`; glyph: water triangle (shared with the Court).
- **Identity colour (T088, colour-blind tested):** `#9ED4F0`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (21 words):** The Frostling followed a mourner into the cathedral on the first night of frost, and nobody had the heart to send it away.
- **Gesture:** blows on its mittens, then holds them out toward the enemy.
- **Flaw:** slows down when lamps are near, so it chills less on the brightest tiles.
- **Voice (3 words):** cheerful, blunt, childlike. Lines: summon "Is it cold enough yet?" Attack "Frost flowers!" Victory "We won! Can I keep it?"

## Longer bio (collection card, about 150 words)

Nobody in the Silent Cathedral will tell you where the Frostling came from, because nobody saw it arrive. One winter morning there was a small footprint of frost on the altar step, and then a mitten, and then a child-sized shape in a pointed hood swinging its feet and asking the mourners whether anyone wanted to play. The Court is a quiet place and the Frostling is not, which is exactly why it was allowed to stay. It laughs at things that are not funny, which turns out to be a kindness. It leaves tiny frost flowers where it points, and enemies that walk through them find their feet slow and their breath visible. It is cold, but it is warm company. If you ask it why it follows the lantern, it will say that it is the only thing in the cathedral that burns.

## The three turnarounds (what the sheet shows)
- **Front:** a round bell body with a jagged icicle hem, stubby feet, two round mittens held out, a frost-crystal collar, and a pointed hood with its tip flicked to one side and a white bobble. Big round eager eyes, rosy cheeks.
- **Side:** the same shape, narrower, hood tip flicking back, one mitten forward and one eye.
- **Back:** the hood from behind and a snowflake mark on the back.

## Silhouette and design decisions
- **Round and soft** against Gargoyle's spiky wide bulk and Ember's tall flame: a bell body with a flicked hood tip, round mittens like two dots, and a jagged hem. The first drawing had a thin detached hood spike that read like an antenna; I redrew the hood as a proper cone before finalising.
- It is deliberately small and child-like so the Hollow Court has one warm face; the mourner and the Gargoyle are the grave ones.
- The mitten is the only warm colour; it ties to the cathedral story lines (a child's mitten on the altar step in the lore fragments).
- Merge tiers (T100, final): tier 2 adds a longer icicle point on the hood (each winter it stays, the cold grows on it); tier 3 adds a scarf of frost that trails behind (the mourners knitted it one, and it froze). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks
The script reports the front silhouette's overlap with a circle, square, triangle and a plain snowball at 64 px, and the overlap between views. Distinctness from Ember and Gargoyle is checked by `Overnight/evidence/familiar_check.py`.

## Next steps (other tasks)
Shape generation and cleanup (T089, T090), textures (T091), animations (T092 to T095), portrait card (T096), model swap and Config wiring (T101, T102).
