# Familiar 6: Ward (T080)

Status: design sheet and bio written overnight 2026-10-28. Follows [[Character Bible Rules]], [[Cast List - 12 Familiars]] and its humanoid revision (the task list called Ward a lighthouse spirit; it is now a human lighthouse keeper). The turnarounds and silhouette test are drawn by code (`tools/familiar_sheet.py ward`); a concept sheet, not final art. Files: `Roblox Dev/Assets/Characters/Design Sheets/Ward_sheet.png`, `Ward_silhouette.png`, `Ward_report.txt`. Look and feel UNVERIFIED by a human. **Humanoid:** yes, a human figure.

## Card
- **Name and epithet:** Ward, keeper of the harbour light.
- **Faction and element:** Lantern Keepers; glass and light. **Rarity:** Rare. **Role (one verb):** Ward (raises the range of adjacent familiars). **Home set:** Harbour of Brass.
- **Signature hue:** harbour slate oilskin `#546C84` with a deep coat `#36485E`, lantern glass `#B0E2EC`, lamp glow `#FFD66E` and brass; glyph: fire triangle (the Keepers').
- **Identity colour (T088, colour-blind tested):** `#7FA0C0`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (22 words):** Ward kept the harbour light for forty years of tides, and went on keeping it after the sea forgot to come in.
- **Gesture:** raises the lantern toward the water, as if signalling a ship.
- **Flaw:** only helps neighbours that stay put; a familiar that was just moved gets nothing from Ward for one wave.
- **Voice (3 words):** patient, wry, weathered. Lines: summon "Visitors. Better than ships." Attack "Mind the rocks." Victory "The light held."

## Longer bio (collection card, about 130 words)

Ward was the last keeper of the harbour light, a small, stooped person in a coat the colour of wet slate, with a hat that has seen more weather than most people. Every night for forty years Ward carried a glass lantern down to the end of the quay and held it up for ships that arrived, and every night after the tide stopped, Ward carried it down anyway. Nobody asked it to. Nobody told it to stop. It is not sad about this; it is simply very good at waiting. When a Lantern Keeper walks down the quay, Ward falls in beside them without being asked, lifts the lantern and makes the dark a little wider for whoever is standing nearby. It will not say what it is waiting for. It says that waiting is a skill, and that it intends to be excellent at it.

## The three turnarounds (what the sheet shows)
- **Front:** a human figure in a long cone-shaped oilskin coat with brass buttons, high collar flaps, a wide-brimmed sou'wester hat and a calm face; a glass lantern with a brass cap and base hangs from one hand at hip height.
- **Side:** the hat brim sweeps back, the lantern is forward, the face in profile.
- **Back:** a seam down the back of the coat, the hat from behind, the lantern hanging on the other side.

## Silhouette and design decisions
- **Cone coat, wide brim, lantern at the hip:** a slim, tall, human proportion with a flared hem and one big glass shape at the side; the opposite of Sentinel's boxy outline with a halberd that rises above its head. Overlap with a plain cone is moderate (see the report), since the coat is a cone; the hat and lantern are what set it apart, and a human should check this at 64 px in the T087 strip.
- The first familiar designs were all creatures; this one follows the humanoid rule. It is also the first design that is explicitly a person (an old keeper) instead of a spirit.
- The lantern glass is pale cyan so the cast has one clearly translucent element, which also helps the Keepers read as the faction of glass and light.
- Merge tiers (T100, final): tier 2 adds a second small lantern on the belt (it keeps a spare light for the next ship); tier 3 adds a cape of rain-shimmer (forty years of tides left their shine on it). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks
The script reports the front silhouette's overlap with a circle, square, triangle and a plain cone at 64 px, and between views. Distinctness among the cast so far is checked by `Overnight/evidence/familiar_check.py`.

## Next steps (other tasks)
Shape generation and cleanup (T089, T090), textures (T091), animations (T092 to T095), portrait card (T096), model swap and Config wiring (T101, T102).
