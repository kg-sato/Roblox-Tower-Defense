---
date: 2026-10-28
tags: [vfx, summon, reveal, ui, research]
---
# Summon References and The Reading

The user, 2026-10-28: "Our rolling animation is still too generic. Our buttons on the bottom as well. Look at creative games with the fantasy theme and see what they are doing." Clips were downloaded at 360p (first 4 to 45 s, yt-dlp, the video-study route the user approved earlier) and sampled at 16 frames; sheets are in `Summon References/`. Labels: **Seen** = from those frames; **Web** = text source.

## What the best summons do (Seen)
| Game | Clip | What happens | Idea we took |
|---|---|---|---|
| Fate/Grand Order | `9jp5AVp7dHQ_sheet.jpg` | a glowing summoning circle on the floor, lightning, a light pillar, a card standing on the circle; silver vs gold card tells the rarity; a rare "card transformation" teases an upgrade | circle on the table, the card stands over it, the card's colour is the tell |
| Hearthstone | `TPrly2nOn14_sheet.jpg` | five face-down cards on a board; hovering a card glows its rarity colour (gold = Legendary) before the player flips it | the player turns the card themselves (Epic and above) |
| Honkai: Star Rail | `3-SmLQMV-CM_sheet.jpg` | a story vehicle (the train) and a shooting star whose colour tells the rarity, then the character performs a short intro, then the card | the reveal belongs to our world (a fortune-teller's table on Lampwick Lane) |
| Anime Vanguards (Roblox) | `9TdpXhlUnAA_sheet.jpg` | white flash, then 0.3 s extreme close-ups of the unit's details (hat, eyes, hands), then a pose before a giant rune circle with the name | hero cuts on the familiar: face, low angle, side, white flash between |
Web: rarity tiers are often signalled by colour climbing a ladder (green, yellow, orange, purple, rainbow) before the result ([Re:Monster wiki](https://re-monster.fandom.com/wiki/Re:Monster_Game:Gacha)); Hearthstone players read the orange hover glow as Legendary ([TouchArcade](https://toucharcade.com/2017/04/04/designing-hearthstone-card-packs-animations-iterations-ungoro-and-more-with-art-director-ben-thompson), page blocked, from search summary); Inscryption sets the whole game on a physical table ([DiGRA paper](https://dl.digra.org/index.php/dl/article/view/2474), [Patreon analysis](https://www.patreon.com/ProblemMachine/posts/inscryption-and-58748955)).

## The Reading (built 2026-10-28, `RevealSection.luau`, old orrery backed up as `ServerStorage.RevealSection_backup_orrery`)
1. Seated first person at a velvet table with two candles and a gold chalk circle.
2. A tarot card arcs up from the deck and lands face down over the circle (0.5 s).
3. The tell: its rim climbs the rarity colours one tier at a time (white, cyan, pink, gold), each with a clack, a pulse, sparks and a harder tremble.
4. Epic and above: "Tap to turn the card" (waits up to 2.5 s); others turn by themselves. The card flips; Epic and above shatter into shards.
5. Epic and above: three hero cuts (face, low angle, side, 0.3 s each, white flash), then the existing pose with name, rarity and odds.
Seen: `ours_reading_legendary_v1.jpg` (v1 bugs: the rim covered the turned card, the art was blank on the first draw, the cuts were too close), `ours_reading_epic_v2.jpg` (all three fixed).

## The counter (bottom controls)
The bottom is one 9-sliced mahogany-and-brass desk (`obj_desk`) holding the tarot deck (`obj_deck`) with the ROLL card on top, the brass dials, the bell and the watch, instead of separate plates (Inscryption's table, Hearthstone's board). Seen: `UI Rework 2026-10-28/hud_desk.png`.

## Not done / not checked
Common and Rare reveals of The Reading not recorded; sounds reuse the old cue names; the card front has no familiar portrait (the familiar appears after the flip); phone layout of the desk; the deck does not visibly lose its top card.

## Legendary manga cinematic (2026-10-28)
The user sent [a "manga animated" edit](https://www.youtube.com/watch?v=cX5uDl97yp0) (20 s, sampled: `cX5uDl97yp0_sheet.jpg`) and asked for a cinematic like it. Its beats: iridescent flash, a white page with a drifting title, a vivid butterfly wipes the title, a slow push on an inked close-up, a back view in a field of red spider lilies framed by red brush arcs with one line of text, a white flash to a hand reaching for the butterfly, a hard cut to black.
Ours (Legendary only, after the card turns, `RevealSection.luau`): iridescent flash, the familiar's name drifting on a cream page with screentone, a glowing moth (new art `obj_moth`, ComfyUI, ours) crosses and wipes it, slow push on the familiar's face, a lily field with red brush arcs and "...the lamp has a new keeper.", white flash and the moth lands, cut to black, then the usual LEGENDARY card. About 9 s. Seen in Play: `ours_legendary_manga_v1.jpg`. Fixed after review, not re-recorded: face shot too tight, title text too small, lilies visible in the black beat. Not matched: hand-drawn ink linework (our familiars are 3D), the "back view" shows the familiar facing the camera.

