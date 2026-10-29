# Familiar 11: Moth-Lantern (T085)

Status: design sheet and bio written overnight 2026-10-28. The task called this a "light that flies in the fog" (a moth). Following the user's request for humanoid characters (see the humanoid revision in [[Cast List - 12 Familiars]]) it is now **a humanoid young lamplighter in a cloak of moth wings, with a lantern on a pole**; the moth survives as wings and feathered antennae. Follows [[Character Bible Rules]]. The turnarounds and silhouette test are drawn by code (`tools/familiar_sheet.py moth_lantern`); a concept sheet, not final art. Files: `Roblox Dev/Assets/Characters/Design Sheets/MothLantern_sheet.png`, `MothLantern_silhouette.png`, `MothLantern_report.txt`. Look and feel UNVERIFIED by a human.

## Card
- **Name and epithet:** Moth-Lantern, the one who follows the light.
- **Faction and element:** Lantern Keepers; light and dusk. **Rarity:** Common. **Role (one verb):** Reveal (marks enemies for extra damage). **Home set:** Lampwick Lane. Replaces Zap (fast chip damage) in the current code.
- **Signature hue:** moth gold `#E69628` and cream `#F2E0B6` wings, a dark brown tunic, a glowing lantern `#FFD66E`; glyph: fire triangle.
- **Identity colour (T088, colour-blind tested):** `#E69F00`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (21 words):** The Moth-Lantern flies after any light in the fog, and finds, more often than not, that someone has left one on.
- **Gesture:** flutters its wings once, then holds the lantern up high.
- **Flaw:** its marks fade quickly when no lit lamp is near, so it is weakest in the darkest corners of a board.
- **Voice (3 words):** dreamy, drifting, kind. Lines: summon "Oh! So bright!" Attack "Look, look there." Victory "Everything is shining."

## Longer bio (collection card, about 130 words)

Lampwick Lane has a lamplighter that no one hired. It arrives at dusk, young and a little untidy, in a cloak of cream and gold moth wings that is a size too big for them, with two feathered antennae that quiver when a light is near. It carries a lantern on a long pole, and it follows every flame it sees. Sometimes that is a street lamp. Sometimes it is a window. Once, they say, it was a lit match in a child's hand, and it followed that for three streets. The Moth-Lantern does not know how to be afraid of the fog; it only knows how to look past it for something warm. When it points, enemies that were hiding in the dark are suddenly lit up for everyone, and a great many are very embarrassed. It says it is simply being helpful.

## The three turnarounds (what the sheet shows)
- **Front:** a slim young figure in a dark tunic and brass belt, two large cream wings with gold lower lobes and eye-spots, two feathered antennae, a lantern on a tall pole held in one hand.
- **Side:** one wing visible folded behind the shoulder, the lantern pole forward.
- **Back:** both wings spread with large eye-spots, the antennae and the lantern pole.

## Silhouette and design decisions
- **A broad X above a slim body:** the wings are large rounded lobes behind a thin body and make a butterfly-shaped outline, with antennae and a tall pole breaking the top; it reads as the airiest shape in the cast. Its overlap with a plain butterfly is moderate (0.60, see the report).
- Humanoid: yes (head, torso, two arms and two legs), with the moth features as wings and antennae.
- Weak points of the concept sheet: the wings are plain circles and ellipses; moth wings need pointed tips and scalloped edges, and the body is a plain tunic. A modelling pass should shape the wings and add a hooded cloak.
- The tall lantern pole is similar to the Sentinel's halberd in position (a tall pole on the right), so the two read similarly at the right edge; a human should check them side by side in the T087 strip.
- Merge tiers (T100, final): tier 2 adds a second, smaller lantern hung from the other antenna (it now guides two walkers at once); tier 3 adds wing tips edged with thin gold map-lines (it has flown the whole of Lampwick Lane and remembers it). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks
The script reports the front silhouette's overlap with a circle, square, triangle and a plain butterfly at 64 px (aspect ratio kept), and between views. Distinctness among the cast so far is checked by `Overnight/evidence/familiar_check.py`.

## Next steps (other tasks)
Shape generation and cleanup (T089, T090), textures (T091), animations (T092 to T095), portrait card (T096), model swap and Config wiring (T101, T102).
