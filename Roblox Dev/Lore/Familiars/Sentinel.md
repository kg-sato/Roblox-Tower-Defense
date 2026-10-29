# Familiar 5: Sentinel (T079)

Status: design sheet and bio written overnight 2026-10-28. Follows [[Character Bible Rules]] and [[Cast List - 12 Familiars]]. The turnarounds and silhouette test are drawn by code (`tools/familiar_sheet.py sentinel`); a concept sheet, not final art. Files: `Roblox Dev/Assets/Characters/Design Sheets/Sentinel_sheet.png`, `Sentinel_silhouette.png`, `Sentinel_report.txt`. Look and feel UNVERIFIED by a human. **Humanoid:** yes, a brass guard with a head, torso, two arms and two legs (see the humanoid revision in the cast list).

## Card
- **Name and epithet:** Sentinel, keeper of the rounds.
- **Faction and element:** Clockwork Guild; brass. **Rarity:** Common. **Role (one verb):** Breach (damage that ignores brass armour). **Home set:** Clockwork Foundry.
- **Signature hue:** brass `#C9A24B` with a bluish green gear `#009E73` and an amber visor slit; glyph: gear.
- **Identity colour (T088, colour-blind tested):** `#7A5C26`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (22 words):** The Sentinel obeys the last order it was ever given, walks its rounds every night, and still tips its helmet to strangers.
- **Gesture:** tips its helmet, then lowers the halberd.
- **Flaw:** freezes for a beat after every step, so its attacks are telegraphed and easy to read.
- **Voice (3 words):** stiff, polite, literal. Lines: summon "Reporting for duty." Attack "Halt. Please." Victory "Rounds complete."

## Longer bio (collection card, about 130 words)

The Foundry's Sentinels were built to guard the furnaces, and when the clock stopped nobody came to tell them they could stop too. So this one walks the same rail it walked on the night the furnaces were banked, in the same stiff, polite step, checking doors that have not opened in years. Its helmet is polished every day by someone it has never seen. Inside the brim, in pencil, someone wrote the words good lad, and the Sentinel has never been able to decide whether that was an order or a compliment. It does not hate anyone. It is only certain that the rounds must be completed. If you ask nicely, it will tip its helmet, lower its halberd and stand where you put it, because you asked nicely, and that is a kind of order it can follow.

## The three turnarounds (what the sheet shows)
- **Front:** a boxy brass guard with a domed helmet, brim and spike, a single amber visor slit, round gear pauldrons, a bluish green chest gear, a halberd on one side and two straight legs.
- **Side:** narrower, the visor slit forward, the halberd beside it and a large winding key on its back.
- **Back:** the winding key plate and the back of the helmet (no visor).

## Silhouette and design decisions
- **Straight lines and one tall point:** a rectangular body with a spiked helmet and a halberd that rises above everything; the winding key and the gear pauldrons break the box. It reads as the stiffest figure in the cast and is the first clearly humanoid one (head, torso, two arms and two legs).
- The first draft is plain. The side view is cluttered (key, arm and halberd overlap), and a modelling pass should separate them; noted for T090.
- Merge tiers (T100, final): tier 2 adds a cape of overlapping brass plates on the shoulders (its rounds have worn a cloak of brass onto it); tier 3 adds a taller plumed crest on the helmet (the Guild promoted it for the rounds it never missed). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks
The script reports the front silhouette's overlap with a circle, square, triangle and a plain boxy robot at 64 px, and between views. Distinctness among the cast so far is checked by `Overnight/evidence/familiar_check.py`.

## Next steps (other tasks)
Shape generation and cleanup (T089, T090), textures (T091), animations (T092 to T095), portrait card (T096), model swap and Config wiring (T101, T102).
