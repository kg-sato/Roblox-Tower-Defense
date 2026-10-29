# Familiar 7: Mirror Chorister (T081)

Status: design sheet and bio written overnight 2026-10-28. The task asked for a Star Choir mirror-cat that retires the old animal design. Following the user's request for humanoid characters (see the humanoid revision in [[Cast List - 12 Familiars]]) it is now **a humanoid robed singer whose face is a mirror**, with a hood that has two cat ears as a nod to the original idea. Follows [[Character Bible Rules]]. The turnarounds and silhouette test are drawn by code (`tools/familiar_sheet.py mirror_chorister`); a concept sheet, not final art. Files: `Roblox Dev/Assets/Characters/Design Sheets/MirrorChorister_sheet.png`, `MirrorChorister_silhouette.png`, `MirrorChorister_report.txt`. Look and feel UNVERIFIED by a human.

## Card
- **Name and epithet:** Mirror Chorister, the one who sings back.
- **Faction and element:** Star Choir; mirror and starlight. **Rarity:** Epic. **Role (one verb):** Echo (repeats the neighbouring familiar's attack at reduced power). **Home set:** Above the Grey Veil. Replaces VoltFox in the current code.
- **Signature hue:** Choir blue `#0072B2` with a silver mirror face `#CED6E4`, a star-white sash and small gold stars; glyph: star.
- **Identity colour (T088, colour-blind tested):** `#0072B2`, used for the card frame, name plate and glow; the body colours above are unchanged.
- **Lore line (20 words):** The Mirror Chorister sings only what it hears, and shows each listener a face made of their own reflected light.
- **Gesture:** tilts its head and holds out an open palm, as if offering you your own voice.
- **Flaw:** its echo is weaker than the original (about 60 percent in the plan), and it does nothing when it has no neighbour.
- **Voice (3 words):** sly, curious, kind. Lines: summon "Oh. There you are." Attack "Again, but softer." Victory "I saw it first."

## Longer bio (collection card, about 130 words)

Every choir needs someone who sings the second line, the answer to the call, and the Star Choir's answer was a figure in a hooded blue robe with two small ears at the hood and a round mirror where a face should be. The Mirror Chorister has no voice of its own. It has yours: everything you say near it comes back a little softer and a little truer, and some listeners leave the room in tears. It is curious about everything that makes a sound, and it is always listening. It likes cats, which is why the hood has ears. It has never asked anyone what they see in the mirror, because it would rather not know. If you stand it beside a loud familiar, it will repeat every strike like a second heartbeat, and the enemies will wonder which of the two sounds to dodge.

## The three turnarounds (what the sheet shows)
- **Front:** a slim blue robe with a star-white sash, wide bell sleeves raised in song, a dark hood with two pointed ears and an oval silver mirror face with a small gold star reflected in it.
- **Side:** the robe narrower, one sleeve raised, the mirror turned into a narrow oval.
- **Back:** a dark back panel on the robe and the back of the hood with a silver stripe.

## Silhouette and design decisions
- **A Y on a column:** the two raised sleeves and the ear points make a tall, symmetrical Y above a narrow robe; this is the only figure in the cast with both arms raised, which gives it its own outline. Its closest overlap is with a plain column (0.55).
- The mirror face is how the unfamiliar part reads: a character with no eyes, only reflected light. It also lets the model carry a changing emissive reflection later (T128).
- The first drawings are stiff: the sleeves are rectangular and the pose is symmetrical; a modelling pass should curve them and add a slight lean.
- Merge tiers (T100, final): tier 2 adds a second pair of hood ears (it hears the echo of the echo); tier 3 adds a hand mirror held at the chest (it finally keeps one reflection for itself). The figure grows to 115 and then 130 percent. Body-attached, so it never clashes with the rarity kit ([[Rarity Silhouettes]]).

## Machine checks
The script reports the front silhouette's overlap with a circle, square, triangle and a plain column at 64 px, and between views. Distinctness among the cast so far is checked by `Overnight/evidence/familiar_check.py`.

## Next steps (other tasks)
Shape generation and cleanup (T089, T090), textures (T091), animations (T092 to T095), portrait card (T096), model swap and Config wiring (T101, T102).
