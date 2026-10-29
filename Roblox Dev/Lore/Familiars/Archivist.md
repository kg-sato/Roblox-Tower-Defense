# Familiar 8: Archivist (T082)

Status: design sheet and bio written overnight 2026-10-28. The task called this the Clockwork Owl. Following the user's request for humanoid characters (see the humanoid revision in [[Cast List - 12 Familiars]]) it is now **the Archivist, a humanoid clockwork scribe in an owl mask** (the owl is kept as the mask, ear tufts and a feather mantle). Follows [[Character Bible Rules]]. The turnarounds and silhouette test are drawn by code (`tools/familiar_sheet.py archivist`); a concept sheet, not final art. Files: `Roblox Dev/Assets/Characters/Design Sheets/Archivist_sheet.png`, `Archivist_silhouette.png`, `Archivist_report.txt`. Look and feel UNVERIFIED by a human.

## Card
- **Name and epithet:** Archivist, memory keeper of the Guild.
- **Faction and element:** Clockwork Guild; brass and paper. **Rarity:** Rare. **Role (one verb):** Hasten (raises the attack speed of adjacent familiars). **Home set:** Harbour of Brass.
- **Signature hue:** Guild teal `#165C5A` with brass `#C9A24B`, lens glass `#AAE8EC` and a brown ledger; glyph: gear.
- **Identity colour (T088, colour-blind tested):** `#2BA69A`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (21 words):** The Archivist keeps the Guild's ledger of every lost hour, and has never once admitted that a page might be missing.
- **Gesture:** turns its head all the way round, with a soft click, when something is mentioned that it has not recorded.
- **Flaw:** it hastens its neighbours but not itself, so its own attack rate is the lowest in the cast.
- **Voice (3 words):** precise, dry, tidy. Lines: summon "Entered in the ledger." Attack "Noted." Victory "Recorded, with footnotes."

## Longer bio (collection card, about 130 words)

Somewhere in the Foundry's offices there is a ledger the size of a door, and the Archivist is the one who keeps it. It wears an owl mask with two round lens eyes that tick when it reads, a mantle of brass feathers that rattles softly, and a long teal coat with a pocket watch that has never been right. It records everything: the hour the crane was lifted, the shift the thief changed, the name of every lamp. It does not forget, which makes it good company and dreadful at secrets. It is fond of the Lantern Keepers, because they leave interesting things behind. If you stand it beside another familiar, it will speak a single quick word of encouragement that no one else can hear, and the other will move a little faster for the rest of the wave.

## The three turnarounds (what the sheet shows)
- **Front:** an owl-masked scribe with two big glass lenses with gears inside, a small beak and two ear tufts, a scalloped feather mantle across the shoulders, a ledger held at the chest and a pocket watch on a chain, on two thin legs with large brass feet.
- **Side:** the mask in profile with one lens and a beak, the ledger held forward.
- **Back:** the back of the mantle with a large winding cog.

## Silhouette and design decisions
- **A big egg on stilts:** a wide feather mantle over a round body, a big round head with two ear tufts, and thin legs with large feet. This is unlike the cone-coated Ward and the pointed-hood Frostling; its overlap with a plain egg is high (0.72, see the report), because it is an egg, so a human should confirm in the T087 strip that the head, tufts and thin legs make it distinct.
- Weaknesses on this concept sheet: the mantle tiers read like stacked trays, the head sits a little detached from the body, and the arms are barely visible (only hands at the ledger). A modelling pass should add visible arms, a neck and a draped mantle.
- Humanoid: yes in intent (head, torso, hands, two legs), with the owl features as a mask; it keeps the owl theme from the task list.
- Merge tiers (T100, final): tier 2 adds a second, smaller ledger under the other wing (the Guild trusted it with the spare lost hours); tier 3 adds a brass watch chain with a wax seal (it was sworn in as keeper of the ledger). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks
The script reports the front silhouette's overlap with a circle, square, triangle and a plain egg at 64 px, and between views. Distinctness among the cast so far is checked by `Overnight/evidence/familiar_check.py`.

## Next steps (other tasks)
Shape generation and cleanup (T089, T090), textures (T091), animations (T092 to T095), portrait card (T096), model swap and Config wiring (T101, T102).
