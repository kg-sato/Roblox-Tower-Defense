# Boss telegraphs: Dark Souls, Hollow Knight, Cuphead (T017)

Question: how do these games telegraph boss attacks, and what timings should our bosses use?

**Gap against the task:** no source read gives telegraph timings or frame counts for the three games. The note records what qualitative design points were found and a reaction-time basis for our own numbers.

## Facts (sourced)
- A good telegraph gives a clear windup, a sense of timing and a window to react. Test: after a death, the player can see what they should have done. Dark Souls' Bed of Chaos floor collapses have no consistent visual cue (a poor-communication example); Hollow Knight's Grimm has clear animations, steady speed and a dodge window; Cuphead attacks follow a visual beat and learnable phase patterns. [Choost Games, "What makes a good boss fight"](https://choostgames.com/blog/what-makes-a-good-boss-fight/) (21 Apr 2026; fetched 2026-10-28; a studio blog, opinion). The article has no timing figures.
- Dark Souls 2: windups are only described as obvious on bosses; cool-down is "a second or two", varying by enemy. [Gamer Guides, attack wind-up and cool-down times](https://gamerguides.com/dark-souls-2/guide/beginners-guide/combat-101/attack-wind-up-and-cool-down-times-) (undated; fetched 2026-10-28). It gives no frame counts.
- Cuphead (29 Sep 2017): pattern-based bosses with no boss health bars; regular and expert modes for most bosses; pink objects can be parried; hand-drawn animation at 24 frames per second while gameplay runs at 60. Reviewers disagree on how much is memorisation. [Wikipedia, Cuphead](https://en.wikipedia.org/wiki/Cuphead) (fetched 2026-10-28; first 100,000 of 158,293 characters read). The page does not describe how bosses signal attacks.
- Reaction-time basis: typical visual response is about 190 ms (lab manual) to about 250 ms (a blog), and auditory about 160 ms. [LibreTexts lab manual, reaction timer](https://eng.libretexts.org/Bookshelves/Electrical_Engineering/Electronics/Laboratory_Manual_-_Embedded_Controllers_Using_C_and_Arduino_(Fiore)/10%3A_Arduino_Reaction_Timer/10.1%3A_Introduction) and [PubNub blog](https://www.pubnub.com/blog/how-fast-is-realtime-human-perception-and-technology/) (both search summaries only, undated).
- A Cuphead analysis video by Game Maker's Toolkit and a university poster logging attack cue frames exist ([amara.org transcript](https://amara.org/videos/TbmQ6Ac3Z6pb/en/3100937)), but the transcript returned 403 and only headings were seen.

## Not found
- Actual windup durations in any of the three games. A designer should measure them by recording frames, not quote a number from here.

## Recommendation for our bosses (inference, not sourced)
1. Use a one-second warning for new attacks (matches T138), shortening once players learn a pattern; at 60 fps this is 60 frames, over four times the reaction range above.
2. Pair every warning with a shape and a sound (the sound lands first, since auditory reaction is faster).
3. Keep windup speed constant per attack, as Grimm does, so players can learn it (T187 stores timing as data).
4. Test with the death-review question above in the morning playtest (T239).
5. For real numbers, record our own build's frames, and optionally frame-step Hollow Knight or Cuphead videos by hand.

## Sources and dates
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://choostgames.com/blog/what-makes-a-good-boss-fight/ | 21 Apr 2026 | read |
| 2 | https://gamerguides.com/dark-souls-2/guide/beginners-guide/combat-101/attack-wind-up-and-cool-down-times- | undated | read |
| 3 | https://en.wikipedia.org/wiki/Cuphead | fetched 2026-10-28; 2017 | partly read |
| 4 | https://eng.libretexts.org/Bookshelves/Electrical_Engineering/Electronics/Laboratory_Manual_-_Embedded_Controllers_Using_C_and_Arduino_(Fiore)/10%3A_Arduino_Reaction_Timer/10.1%3A_Introduction | undated | search summary |
| 5 | https://amara.org/videos/TbmQ6Ac3Z6pb/en/3100937 | undated | 403; unread |

Caveat: timings per game are missing; reaction-time figures are loosely sourced.
