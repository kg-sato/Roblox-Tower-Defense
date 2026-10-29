# Ending: the cosmic closing scene (T072)

Status: draft written overnight 2026-10-28. The task fixes the shape: the cosmic ending text, and the choice is "none, just a closing scene". This page is the shot list, text, timing and what happens afterwards. It follows the default ending in [[The Clockmaker]] (option 3) and the lines already in [[Chapter 5 - Above the Grey Veil]] (C5-42 to C5-46 and C5-71). All wording is a proposal in the voice of [[Tone Guide]]. Nothing is built.

## Principle
No player choice. The player has already shown who they are by how they played; the scene shows the lantern doing what it was always for. The oath's last clause, "I let the hour go when it asks," is the hinge ([[The Lantern Role]]).

## Trigger and length
- Plays once, after the stage 25 boss defeat and its reward screen is dismissed, and again from a "Replay ending" button in the collection (no reward the second time).
- About 45 seconds; tap or the existing SKIP ends it at any time, and the credits screen follows (T073). With reduced motion on, camera moves become cuts and captions are static ([[Accessibility guidelines for our game]]).

## Shot list
| t (s) | shot | caption / text | sound |
|---|---|---|---|
| 0 to 4 | Close on the Clockmaker's hands stopping, then resting on the glass of the clock | (none) | a single held note, then silence |
| 4 to 9 | The hands on the Great Clock begin to move; the camera pulls back through the clock face | `[ THE CLOCK TURNS ]` | slow gear tick, once per second |
| 9 to 16 | The city below, the fog drawing back from every street; lamps along the Lane each flicker once | Narration: "The hands move. They go to an hour that has been waiting a long time." | music enters, low strings and a bell |
| 16 to 24 | The stars come out over Lampwick Lane; the lamps go out one by one, because they are not needed | Narration: "The stars come out over Lampwick Lane, and one by one the lamps go out, because they are not needed." | music rises, a choir note held |
| 24 to 32 | Tamsin at the Seventh Lamp lets her wick burn down; Pip and Wren at their benches look up | (none; faces only) | a soft laugh from Pip |
| 32 to 38 | The lantern in the player's hand: the glass is full of warm light, and the Voice speaks | Voice: "It is morning. I had forgotten what that looked like." | music resolves |
| 38 to 44 | Ember lifts its flame to the lantern; the lantern lights the camera | `[ A LIGHT HOLDS ]` | final chord |
| 44 to 45 | Cut to black | Narration: "The Lane is quiet, and for the first time it is a quiet that can end." | silence, then credits |

## What the player gets (server decides)
- A one-time cosmetic: a lantern frame (for example the Starlit frame in [[NPC - Tamsin the Supplier]]) and a title, granted by the server on first completion. No power, no currency.
- The game does not end: stages continue as endless mode (T016) and the skill tree stays open; the lobby's Voice has one new idle line.
- Rewards and flags are written by the server only; the client just plays the scene.

## Changes to the world afterwards (proposals)
- The lobby sky shows a few stars; the fog stays only at the stage edges.
- Pip's pool gets a line: "The hands move now. I wound a spring just to hear it."
- The Clockmaker does not appear again; Marrow's name remains in the collection lore.

## Open questions for the user
1. Does the Voice's identity stay open in the ending (default) or does the scene reveal it?
2. Is a one-time cosmetic reward right, or none at all?
3. Should the credits screen (T073) show the third-party licence list here?
4. Should the scene be skippable the first time?

## Checks
- `Overnight/evidence/T072_check.py` checks that the two captions in the shot list match the bracket format and appear in the chapter 5 script, that the narration lines appear in the chapter 5 script, and that the shot times run without gaps to 45 s. Output in `Overnight/evidence/T072.txt`.
