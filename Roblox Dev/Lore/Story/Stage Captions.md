# Stage captions: 40 bracketed captions across the chapters (T067)

Status: draft written overnight 2026-10-28. Format from [[Tone Guide]]: bracketed capitals with inner spaces, one beat per caption, 2 to 5 words (the guide said 2 to 4; five-word captions already appear in the chapter scripts, so the rule is widened in the guide). The 25 stage-intro captions are the ones already used in [[Chapter 1 - Lampwick Lane]] to [[Chapter 5 - Above the Grey Veil]]; the other 15 are new. This table is the source for the data table that stage code loads (T232 checks every stage has a caption). Reveal speed: 0.4 s per line, static when reduced motion is on (T190).

Slot meaning: **intro** plays when the stage starts; **boss warning** at the start of a boss stage; **boss defeated** when the boss falls; **set clear** at the end of the last stage of a set.

| # | stage | slot | caption |
|---|---|---|---|
| 1 | 1 | intro | [ LAMPWICK LANE ] |
| 2 | 2 | intro | [ THE SEVENTH LAMP ] |
| 3 | 3 | intro | [ ASTRID'S STALL ] |
| 4 | 4 | intro | [ THE GATE ] |
| 5 | 5 | intro | [ SOMETHING WITHOUT FOOTSTEPS ] |
| 6 | 5 | boss warning | [ IT WEARS NO FACE ] |
| 7 | 5 | boss defeated | [ THE UNBOUND UNRAVELS ] |
| 8 | 5 | set clear | [ THE FOG WITHDRAWS ] |
| 9 | 6 | intro | [ THE HARBOUR OF BRASS ] |
| 10 | 7 | intro | [ THE CRANES ] |
| 11 | 8 | intro | [ BRASS AND BLACK WINGS ] |
| 12 | 9 | intro | [ THE LAMP THIEF ] |
| 13 | 10 | intro | [ THE WINDING ENGINE ] |
| 14 | 10 | boss warning | [ THE ENGINE SLOWS THE HOUR ] |
| 15 | 10 | boss defeated | [ THE WHEEL IS STILL ] |
| 16 | 10 | set clear | [ THE TIDE REMEMBERS ] |
| 17 | 11 | intro | [ THE SILENT CATHEDRAL ] |
| 18 | 12 | intro | [ THE COVERED STATUES ] |
| 19 | 13 | intro | [ A COLD SMALL GUEST ] |
| 20 | 14 | intro | [ THE LANTERN AT HER FEET ] |
| 21 | 15 | intro | [ A SONG BEHIND THE GLASS ] |
| 22 | 15 | boss warning | [ THE WINDOWS BEGIN TO SING ] |
| 23 | 15 | boss defeated | [ THE ROOF IS GONE ] |
| 24 | 15 | set clear | [ A STAR BEHIND THE FOG ] |
| 25 | 16 | intro | [ THE CLOCKWORK FOUNDRY ] |
| 26 | 17 | intro | [ SENTINELS ON THE RAILS ] |
| 27 | 18 | intro | [ THE HOUND ] |
| 28 | 19 | intro | [ THE COLD FURNACE ] |
| 29 | 20 | intro | [ A CROWN OF CANDLES ] |
| 30 | 20 | boss warning | [ THE CANDLES ADVANCE ] |
| 31 | 20 | boss defeated | [ THE CANDLES GO OUT ] |
| 32 | 20 | set clear | [ THE FURNACES WARM ] |
| 33 | 21 | intro | [ THE FOG LIFTS ] |
| 34 | 22 | intro | [ A STAIR OF LIGHT ] |
| 35 | 23 | intro | [ THE MIRROR-CAT ] |
| 36 | 24 | intro | [ THE FACE OF THE CLOCK ] |
| 37 | 25 | intro | [ THE CLOCKMAKER ] |
| 38 | 25 | boss warning | [ SHE WINDS THE HOUR ] |
| 39 | 25 | boss defeated | [ ONE LAST TURN ] |
| 40 | 25 | set clear | [ THE CLOCK TURNS ] |

## Rules and checks
- A script, `Overnight/evidence/T067_check.py`, checks this table for: exactly 40 captions, bracket format, 2 to 5 words, no duplicates, no banned words from the tone guide, and that every stage 1 to 25 has an intro. Its output is in `Overnight/evidence/T067.txt`.
- Caption wording is a proposal. Human judgement of the voice is UNVERIFIED.
