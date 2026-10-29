# Familiar dialogue: two short exchanges per pair that share a stage (T068)

Status: draft written overnight 2026-10-28. Familiar names, factions and roles come from the cast list in the task list (T074 to T086) and [[Factions]]; the home stage set of each familiar is my assignment (the "share a stage" rule needs one). Voice tags are proposals under [[Character Bible Rules]] (rule 6) and [[Tone Guide]]. Lines are original, 12 words or fewer. Nothing is built.

## Home sets and pairs
A pair "shares a stage" when both have the same home set. Cross-set pairs are not covered here (see the note at the end).
| Home set (stages) | Familiars |
|---|---|
| Lampwick Lane (1 to 5) | Ember, Moth-Lantern |
| Harbour of Brass (6 to 10) | Ward, Clockwork Owl |
| Silent Cathedral (11 to 15) | Frostling, Mourner, Gargoyle |
| Clockwork Foundry (16 to 20) | Brass Hound, Sentinel |
| Above the Grey Veil (21 to 25) | Star Drake, Mirror-cat, Grey Veil Wraith |

That gives 1 + 1 + 3 + 1 + 3 = 9 pairs and 18 exchanges.

## Voice tags (three words each)
Ember: eager, earnest, small. Moth-Lantern: dreamy, drifting, kind. Ward: patient, wry, weathered. Clockwork Owl: precise, dry, tidy. Frostling: cheerful, blunt, childlike. Mourner: soft, formal, faceless. Gargoyle: gruff, deadpan, loyal. Brass Hound: loyal, cheerful, literal. Sentinel: stiff, polite, literal. Star Drake: remote, grand, lonely. Mirror-cat: sly, curious, kind. Grey Veil Wraith: sparse, echoing, unmoored.

## Trigger
An exchange plays once per profile when both familiars are on the board in a stage of their home set (a banter pool, T186 pattern). The second exchange of a pair plays after the first has been seen. Reduced motion does not affect it; it is text over the portraits.

## Exchanges
Format: speaker: line, with " / " between lines. Pair id is `home set / pair / 1 or 2`.

| id | pair | exchange |
|---|---|---|
| FD-01 | Ember and Moth-Lantern, 1 | Ember: You are very bright. / Moth-Lantern: So are you. Hold still. I like it. |
| FD-02 | Ember and Moth-Lantern, 2 | Moth-Lantern: Where do you go when the fog comes? / Ember: Closer to the lantern. |
| FD-03 | Ward and Clockwork Owl, 1 | Ward: The tide has been out forty years. / Clockwork Owl: Forty years, three days, six hours. |
| FD-04 | Ward and Clockwork Owl, 2 | Clockwork Owl: You count the ships. / Ward: Someone has to wait for them. |
| FD-05 | Frostling and Mourner, 1 | Frostling: Why do you not have a face? / Mourner: I gave it to someone who needed it more. |
| FD-06 | Frostling and Mourner, 2 | Mourner: You are very cold. / Frostling: You are very quiet! We should trade! |
| FD-07 | Frostling and Gargoyle, 1 | Frostling: Can I climb on you? / Gargoyle: No. / Frostling: Thank you! |
| FD-08 | Frostling and Gargoyle, 2 | Gargoyle: You are sitting on my wing. / Frostling: It is warm up here. |
| FD-09 | Mourner and Gargoyle, 1 | Mourner: You keep the west front. / Gargoyle: Somebody has to be looked at. |
| FD-10 | Mourner and Gargoyle, 2 | Gargoyle: You never blink. / Mourner: I have not the means. I am comfortable. |
| FD-11 | Brass Hound and Sentinel, 1 | Brass Hound: Fetch? / Sentinel: I do not fetch. I patrol. / Brass Hound: Patrol-fetch! |
| FD-12 | Brass Hound and Sentinel, 2 | Sentinel: You have not been given an order. / Brass Hound: I like you. |
| FD-13 | Star Drake and Mirror-cat, 1 | Mirror-cat: You are the last of them. / Star Drake: Last is only a position. |
| FD-14 | Star Drake and Mirror-cat, 2 | Star Drake: You show me myself. / Mirror-cat: Only the good angles. |
| FD-15 | Star Drake and Grey Veil Wraith, 1 | Star Drake: You belong to no one. / Wraith: ...nor you. ...nor you. |
| FD-16 | Star Drake and Grey Veil Wraith, 2 | Wraith: ...the sky is ...larger. / Star Drake: It was always this size. |
| FD-17 | Mirror-cat and Grey Veil Wraith, 1 | Mirror-cat: You have no reflection. / Wraith: ...I have yours. |
| FD-18 | Mirror-cat and Grey Veil Wraith, 2 | Wraith: ...stay. / Mirror-cat: Only if you do not make it strange. |

## Notes
- Pairs with cross-set familiars (for example Ember and Frostling) are not written; a later task can add faction-level banter using [[Factions]] colour and glyph.
- The Mourner's lines imply the gift of its face without saying whom it went to (see the open question in [[The Clockmaker]]).
- Hades-style variety (lines unlikely to repeat for many plays) needs many more lines; this set is the minimum for the nine pairs ([[Hades voice and lore delivery]]).
- Check: `Overnight/evidence/T068_check.py` counts exchanges (18) and pairs (9, two exchanges each) and checks the 12-word line limit and banned words; output in `Overnight/evidence/T068.txt`.
