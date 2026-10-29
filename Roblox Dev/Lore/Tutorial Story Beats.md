# Tutorial story beats (T060)

Status: draft written overnight 2026-10-28. It supplies the story layer for the tutorial rewrite (T003 in the task list: 6 steps, each teaching one mechanic with a lore line). The existing intro tour (`IntroTour.luau`) already has four title beats: "WELCOME TO LAMPWICK LANE", "THE NIGHT COMES THROUGH THE GATE", "SUMMON AND MERGE FAMILIARS", "KEEP THE CRYSTAL LIT". The beats below extend those. All wording is a proposal in the style of [[Tone Guide]]; names follow [[Glossary]]. It sets up [[The Clockmaker]] without revealing anything.

## Who speaks
- **The Voice in the Lantern:** a calm, young, slightly worried voice that speaks from the player's brass lantern. It is never named in the tutorial. (The lobby's friendly apprentice, T069, may be the same voice; the open question is in [[The Clockmaker]].)
- **Ember:** the first familiar; speaks only through gesture and one line at the end.
- No other voices before stage 1 ends, so the player is never lost.

## What is at stake
The lantern. The existing tour says "if they reach it, the lane goes dark." Fiction: the lantern holds the fog back from Lampwick Lane; each enemy that leaks dims it; at zero the dusk ends in fog. Gameplay already matches (leaks cost lives; see Config enemy `leak` values). The tutorial states the stake once, in step 1, and shows it, never repeats it.

## Ember's bond to the player
Ember is "the first lamp a Keeper ever carried home" (the card line in [[Tone Guide]]). In the tutorial it is gifted, not rolled, so the player's first familiar is guaranteed and named. Bond starts at level 1 and rises when the player first merges it (step 4), shown as a small flame icon; the bond system itself is T207. Ember's gesture (per [[Character Bible Rules]]) is lifting its flame to the lantern when the player taps it.

## The six beats
Each beat teaches one mechanic. Captions use the existing bracketed style; narration lines are 4 to 12 words.
| # | Mechanic taught | Caption | Voice line | Success condition |
|---|---|---|---|---|
| 1 | The goal and the stake | `[ THE LANTERN ]` | "Keep it lit. The fog is patient." | Player looks at the lantern (camera beat ends) |
| 2 | Summon | `[ A SMALL FLAME ]` | "Something is warm enough to follow you." | Player taps summon; Ember arrives (guaranteed) |
| 3 | Place a familiar on a slot | `[ HOLD THE LANE ]` | "Stand it where the lane bends." | Player places Ember on a highlighted slot |
| 4 | Merge (three touching become one) | `[ ONE HOUR, LONGER ]` | "Three that touch learn a longer hour." | Player merges three Embers; bond reaches 1 |
| 5 | Defend and watch the wave | `[ THE FIRST WAVE ]` | "They do not hurry. Neither do we." | Wave 1 cleared with no forced loss |
| 6 | Reward and the next step | `[ A LIGHT HOLDS ]` | "Keep summoning. The Lane is long." | Stage 1 reward shown; skill tree hint appears |

Notes:
- Beats 2 to 4 reuse the roll and merge systems already in the game; the tutorial only guarantees the first outcome (beat 2 gives Ember) and a safe board (no leaks in wave 1). Both need small server rules (the server decides rewards), tested before it ships.
- Beat 6 points at the skill tree and daily systems later; it does not teach them.
- Total target time: under 3 minutes; every beat has a skip, and the intro tour's SKIP already exists.

## Lines for failure and replay
- If the player leaks an enemy in wave 1: "That is what the fog does. Again." (no blame).
- If the tutorial is replayed from settings: the Voice says "Back to the first hour." and the beats run with Ember's bond ignored.

## Checks (for the build task)
- Each beat has one mechanic, one caption and one success condition (this table).
- No text longer than the tone limits; captions respect reduced motion (static text).
- Look and feel are UNVERIFIED until the user plays it.
