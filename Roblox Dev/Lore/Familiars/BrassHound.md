# Familiar 10: Brass Hound (T084)

Status: design sheet and bio written overnight 2026-10-28. Follows [[Character Bible Rules]] and [[Cast List - 12 Familiars]]. The Brass Hound is one of the four **non-humanoid** slots kept in the humanoid revision (with Ember, Star Drake and Gargoyle), so the cast keeps one four-legged creature. The turnarounds and silhouette test are drawn by code (`tools/familiar_sheet.py brass_hound`); a concept sheet, not final art. Files: `Roblox Dev/Assets/Characters/Design Sheets/BrassHound_sheet.png`, `BrassHound_silhouette.png`, `BrassHound_report.txt`. Look and feel UNVERIFIED by a human.

## Card
- **Name and epithet:** Brass Hound, keeper of the tally.
- **Faction and element:** Clockwork Guild; bronze and springs. **Rarity:** Common. **Role (one verb):** Harry (very fast, short-range chip damage). **Home set:** Clockwork Foundry.
- **Signature hue:** bronze `#C4863E` with brass plate ears, a Guild teal collar `#165C5A` and a vermilion paper-tape tongue `#D55E00`; glyph: gear.
- **Identity colour (T088, colour-blind tested):** `#E3B07A`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (21 words):** The Brass Hound keeps a tally of everyone who walks the Foundry rails, and has recently started counting them as friends.
- **Gesture:** sits and thumps its spring tail on the floor when it is pleased.
- **Flaw:** very short range, and it cannot reach flying enemies.
- **Voice (3 words):** loyal, cheerful, literal. Lines: summon "Hello! Hello! Hello!" Attack "Fetch!" Victory "Good job. Me too."

## Longer bio (collection card, about 130 words)

The Brass Hound was built to chase trespassers off the Foundry rails, and for years it did exactly that, politely, with a great deal of ticking. Then one night a very small person in a coat came down the rails, and the Hound sat down, and the person scratched its brass ear, and the Hound has been very confused and very happy ever since. It keeps a tally of visitors in a small dial on its flank: strangers, friends, strangers, friends. The friends column is longer now. It brings back whatever it is told to fetch, taking the instructions entirely literally, which is how the Guild's second-best ledger ended up in the harbour. It is not very clever. It is very, very loyal, and it has never once lost a rail. If you hold out a bolt, it will take it, gently, and put it in the friends column.

## The three turnarounds (what the sheet shows)
- **Front:** a bronze hound head-on, with a round head, two brass plate ears, button eyes, a teal collar and a vermilion paper-tape tongue; a trapezoid chest; four straight legs, each with a gear at the knee and a small paw block.
- **Side:** a long, low body with a flank tally dial, a coil-spring tail rising behind, gear knees and the same head in profile.
- **Back:** the rump with a winding gear, the spring tail and the hind legs.

## Silhouette and design decisions
- **The only long, low, four-legged shape in the cast:** a horizontal body with a spring tail and a lowered head; its side view is the widest figure in the set, and its overlap with a plain dog loaf is very low (see the report). It is a creature, kept as a non-humanoid slot by the user's own rule.
- Cute and simple by design: round button eyes, a cheerful tongue and floppy brass ears, because the Guild's other characters (Sentinel, Archivist) are stiff or dry.
- Weak points of the concept sheet: the head in the side view sits slightly detached from the neck, and the legs are thin bars. A modelling pass should add a thicker neck and chunkier legs so it reads at phone size.
- Merge tiers (T100, final): tier 2 adds a brass tally collar with one notch per friend (it counts friends now, not trespassers); tier 3 adds a second coiled spring tail segment (the Foundry wound it tighter for every friend it kept). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks
The script reports the front silhouette's overlap with a circle, square, triangle and a plain dog loaf at 64 px (aspect ratio kept), and between views. Distinctness among the cast so far is checked by `Overnight/evidence/familiar_check.py`.

## Next steps (other tasks)
Shape generation and cleanup (T089, T090), textures (T091), animations (T092 to T095), portrait card (T096), model swap and Config wiring (T101, T102).
