# Familiar 1: Ember (T075)

Status: design sheet and bio written overnight 2026-10-28. Everything follows [[Character Bible Rules]] and the cast entry in [[Cast List - 12 Familiars]]. The three turnarounds and the silhouette test are drawn by code (`tools/familiar_sheet.py ember`), so they are a clean concept sheet, not final art. Look and feel are UNVERIFIED until the user views the sheet. Sheet files: `Roblox Dev/Assets/Characters/Design Sheets/Ember_sheet.png`, `Ember_silhouette.png` and `Ember_report.txt`.

## Card
- **Name and epithet:** Ember, the first flame.
- **Faction and element:** Lantern Keepers; fire. **Rarity:** Common. **Role (one verb):** Scorch (steady single-target fire damage). **Home set:** Lampwick Lane.
- **Signature hue:** vermilion-orange `#D55E00` with a gold core and brass `#C9A24B`. **Glyph:** fire triangle.
- **Identity colour (T088, colour-blind tested):** `#D55E00`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (21 words):** Ember was the first flame a Keeper ever carried home through the fog, and it has never forgotten the way back.
- **Gesture:** lifts its flame toward the lantern when it is tapped or when it attacks.
- **Flaw:** gutters and shrinks when the lantern is out, so it is weakest at one life.
- **Voice (3 words):** eager, earnest, small. Lines: summon "Here! I remembered the way." Attack "Bright, bright, bright!" Victory "Is the lamp still lit? Good."

## Longer bio (collection card, about 120 words)
Before there were maps, there were Keepers, and before there were Keepers, there was a single small flame in a brass lamp that someone carried home through a fog so thick the street had no name. That flame is Ember. It does not remember who carried it, only that the carrying was done gently and that the lamp was set down on a table where someone was waiting. It has been looking for that table ever since. Ember follows a lantern the way a child follows a coat: close, and a little too fast. It is the first familiar every new Keeper meets, and it is the only one that will go out ahead of the lantern to check the dark. When Ember burns low, it is not afraid; it is listening. When it burns bright, you will know that someone, somewhere, has set a lamp down on a table.

## The three turnarounds (what the sheet shows)
- **Front:** a teardrop flame with big round eager eyes and a small smile, standing on a brass oil lamp with a spout on one side and a ring handle on the other, two detached sparks at shoulder height.
- **Side:** the flame leans forward with its tip flicking back, one eye, spout forward and handle behind; one spark.
- **Back:** the flame, the same two sparks, and a keyhole vent on the lamp's belly (a small secret: a Keeper's key fits it).
- **Colour:** the flame is three layers (vermilion, amber, pale gold core) so it still has depth on a dark board; verdigris streaks on the brass tie it to the harbour set.

## Silhouette and design decisions
- The shape is a **flame on an oil lamp with a spout and a handle ring**: three clear parts. I first drew the flame in a flowerpot-style cup with leaf-like side flames, and changed it because that combination looks like a sprout in a pot, which the plan bans. The oil-lamp body and the detached round-ended sparks avoid it.
- Eyes follow the eye rule drafted for T111: large, round, wide-set, with one highlight, which reads as eager (to be confirmed when T111 is written).
- Rarity: Common, so the silhouette is the simplest of the cast; higher rarities add silhouette features (T099).
- Merge tiers (T100, final): tier 2 adds a second, smaller flame tongue beside the main flame (it has learned to carry the light of two lamps); tier 3 adds a brass key on a chain from the handle (a Keeper trusted it with the key to the lamp room). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks (see the evidence file)
The script reports the greyscale silhouette's overlap with a circle, square, triangle and a plain teardrop flame at 64 px, and the overlap between views. The numbers show the shape is not one of the basic shapes; they do not prove it will read among the other eleven (that strip test is T087).

## Next steps for Ember (other tasks)
Shape generation and cleanup (T089, T090), textures (T091), idle, attack, spawn, banish (T092 to T095), portrait card (T096), model swap and Config wiring (T101, T102).
