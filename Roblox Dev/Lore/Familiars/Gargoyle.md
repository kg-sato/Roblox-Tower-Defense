# Familiar 2: Gargoyle (T076)

Status: design sheet and bio written overnight 2026-10-28. Follows [[Character Bible Rules]] and [[Cast List - 12 Familiars]]. The turnarounds and silhouette test are drawn by code (`tools/familiar_sheet.py gargoyle`); a concept sheet, not final art. Files: `Roblox Dev/Assets/Characters/Design Sheets/Gargoyle_sheet.png`, `Gargoyle_silhouette.png`, `Gargoyle_report.txt`. Look and feel UNVERIFIED by a human.

## Card
- **Name and epithet:** Gargoyle, watcher of the west front.
- **Faction and element:** Hollow Court; stone. **Rarity:** Rare. **Role (one verb):** Crush (slow, heavy hits). **Home set:** Silent Cathedral. Replaces Boulder in the current code.
- **Signature hue:** ash grey stone `#8C8E98` with a sky-blue scarf `#56B4E9` (the Court's pale blue); glyph: water triangle.
- **Identity colour (T088, colour-blind tested):** `#4A4C58`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (23 words):** The Gargoyle has watched the cathedral's west front since before the bell was hung, and it holds strong opinions about being looked at.
- **Gesture:** turns its head very slowly toward whatever moved last.
- **Flaw:** wakes late, so its first attack of a wave is delayed; it is the slowest starter in the cast.
- **Voice (3 words):** gruff, deadpan, loyal. Lines: summon "Fine. I was awake anyway." Attack "Move along." Victory "Do not touch the scarf."

## Longer bio (collection card, about 130 words)
The Gargoyle was carved to frighten off whatever the cathedral's builders feared, and it has been faithfully frightening it ever since, mostly pigeons. It sits on its plinth with its wings folded and its fists planted and has never once been surprised, or admitted to it. Someone, nobody will say who, tied a sky-blue scarf around its neck one winter, and it has refused to take it off, on the grounds that it would be rude. It speaks rarely, and when it does the words arrive late, like a thrown stone landing. It is not unkind. It simply regards everything as something that will eventually be looked at, and prefers to do the looking first. If you stand it where the lane bends, it will hold that bend until the fog gives up, or until the lantern says it may rest.

## Silhouette and design decisions
- **Wide and low** against Ember's tall teardrop: a hunched body on a plinth, folded wings that rise as two pointed shapes behind the shoulders, two horns, a tail curling off the plinth, and a scarf. In greyscale the folded wings read as spikes, which gives the top of the shape a crown of points; when it is modelled, scalloped bat-wing edges would read better than flat triangles.
- The heavy brow and small pale eyes read as deadpan, in line with the eye rule being drafted for T111 (low, wide-set, small eyes read as stolid).
- The scarf is the one warm-ish accent and the Court colour; it also gives the silhouette a hanging tail on one side, so the figure is not symmetrical.
- Merge tiers (T100, final): tier 2 adds a second scarf tail (the scarf was a gift and it will not wear less of it); tier 3 adds polished stone plates on the shoulders (weather and many years of being looked at have polished it). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks
The script reports the front silhouette's overlap with a circle, square, triangle and a plain rock at 64 px, and the overlap between views. The overlap between Gargoyle and Ember is checked by `Overnight/evidence/familiar_check.py`.

## Next steps (other tasks)
Shape generation and cleanup (T089, T090), textures (T091), animations (T092 to T095), portrait card (T096), model swap and Config wiring (T101, T102).
