# Character bible rules (T056)

Status: draft written overnight 2026-10-28. The six rules (silhouette first, one hue per character, a lore line, a gesture, a flaw, a voice) come from the task list. The wording, limits and tests are proposals, drawn from the research notes linked under each rule. Every familiar task (T074 to T086) and every enemy or boss task follows this page. Bans from the task list: no sprout-style or fox-style designs.

## The six rules
1. **Silhouette first.** Design the outline in solid black before any detail. Each character must read as a different shape from every other at 64 px in greyscale (T087). Test: put all 12 outlines in one strip; a stranger should be able to tell any two apart. Basis: [[Plants vs Zombies character readability]], [[Hollow Knight creature design]], [[Clockwork creature silhouettes]]; the claims there are mostly inference, so the test is the real rule.
2. **One hue per character.** A single signature hue (from the colour-blind-safe set, [[Colour theory for readable teams]]) plus neutrals and brass trim. Each character also carries a faction glyph, so colour is never the only cue ([[Factions]]). Test: colour-blind simulation script on the full cast (T088); fix any pair under about 15 delta E.
3. **A lore line.** One sentence, 15 to 25 words, stating a fact and implying a feeling: a place, an object and one odd detail ([[Short lore writing references]]). The long bio is 120 to 200 words in the collection (T097). Test: it mentions one named place or object from [[Stage Set Lore]] and does not repeat another card's line.
4. **A gesture.** One signature movement that shows the personality, used in the idle and in the ultimate: a head turn, a wing flap, a lantern lift ([[Clockwork creature silhouettes]]: movement sells a mechanical creature). Test: described in one verb phrase; no two characters share it.
5. **A flaw.** One limit that shows in play or in text: slow to start, afraid of dark, loses its lines when the lantern is out. It must be visible in the kit or in a line, so the character is not a pure upgrade ([[Factions]] flaws set the tone). Test: the flaw shows up in a stat note or a caption.
6. **A voice.** Three short lines (summon, attack, victory) plus a tone tag in three words, written as text for later recording ([[Hades voice and lore delivery]], [[Disco Elysium voice and UI text]]). Test: read the line without the name; the speaker should still be guessable.

## Additional hard rules
- **One job.** Name the role in one verb (block, burst, reach, support); two characters may not share a verb unless their ranges differ ([[Plants vs Zombies character readability]]).
- **Name:** a short given name plus an epithet, distinct first letters and sounds across the cast ([[Naming in whimsical dark fantasy]]).
- **Faction and element:** exactly one of the four factions or the unaligned slot, and one element or material ([[Factions]]).
- **Rarity changes the silhouette,** not only the colour (T099); 3 merge tiers each add one visible body feature with a reason (T100, [[Pokemon creature archetypes for merge units]]).
- **Tone:** soft shapes, warm light, danger carried by props and text, no gore ([[Cult of the Lamb tone and cult-building UI]]).
- **Budget:** under 20,000 triangles per mesh; texture sizes by size on screen ([[Mobile performance limits]]).
- **Bans:** no sprout-style or fox-style designs (task list), and no recolours presented as new characters.
- **Accessibility:** no meaning carried by colour alone; no strobing effects ([[Accessibility guidelines for our game]]).
- **Originals only:** use references for principles, never copy a design or phrasing from another game.

## Character sheet template (copy for each character)
```
Name + epithet:
Faction / element:
Role (one verb):
Silhouette note (shape in 6 words):
Signature hue (hex) / glyph:
Lore line (15-25 words):
Gesture (one phrase):
Flaw (one phrase):
Voice tone (3 words) + summon / attack / victory lines:
Merge tiers (3): feature added at each:
Rarity silhouette change:
Triangle budget / texture size:
Checks: silhouette strip [ ]  colour-blind [ ]  unique verb [ ]  unique gesture [ ]
```

## Review checklist (used for T087, T088, T231)
- All rules above pass for each of the 12 familiars, the enemy families and the five bosses.
- Automated test (T231): every familiar has a bio, a portrait, a voice line and a silhouette entry.
- Human review stays UNVERIFIED until the user looks at the sheets.
