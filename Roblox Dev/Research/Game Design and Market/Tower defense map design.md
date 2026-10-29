# Tower defense map design: path length, corners, choke points, pacing (T020)

Question: what map-design rules from Bloons, Kingdom Rush and Vampire Survivors-style pacing apply to our stage sets?

## Facts (sourced)
- Path types: fixed path with towers placed along it, player-built mazes (Desktop Tower Defense), and hybrids where towers reshape the route. "Mazing" lengthens the route so enemies spend longer under fire; "juggling" blocks exits on alternate sides to make enemies backtrack. Air units can ignore the path. The page does not discuss choke points. Kingdom Rush (2011) sold over seventeen million copies. [Wikipedia, Tower defense](https://en.wikipedia.org/wiki/Tower_defense) (fetched 2026-10-28).
- Kingdom Rush uses prebuilt tower spots where each spot has set advantages and drawbacks: area-of-effect towers do better on the inside of a turn, single-target towers on straights. This comes from a search summary of a games article, not read in full: [PocketGamer, article 042878](https://www.pocketgamer.co.uk/articles/042878/r/) (snippet only, undated).
- Bloons TD6 maps give each map a signature path shape (split lanes, curvy path, tight space): see [[Bloons TD6 upgrades and paths]] (sourced to the Bloons wiki, search summaries).
- Vampire Survivors: runs have a 15, 20 or 30 minute soft limit; at the limit enemies clear and a Reaper appears, with a new one each minute; level-ups offer three or four choices; early access Dec 2021, full release 20 Oct 2022. [Wikipedia, Vampire Survivors](https://en.wikipedia.org/wiki/Vampire_Survivors) (fetched 2026-10-28; first 100,000 of 101,678 characters). The page does not detail wave scaling.
- Hobbyist devlogs (snippets only, low weight): a repeated choke point early teaches tower efficiency and one is removed later to raise difficulty ([Uppsala student devlog, Tower Offensive](https://babel.speldesign.uu.se/?p=5600)); a circular path gives a lone tower more fire time ([Key Defence devlog](https://mikalagrand.itch.io/key-defence/devlog/97895/level-walkthrough)); random path generation can enforce length by restarting generation when out of range ([Hive Workshop thread](https://www.hiveworkshop.com/threads/random-path-generation.262313/)).

## Not found
- No numbers for ideal path length, corner angles or choke-point spacing. The devlogs give examples, not rules.

## Takeaways for us (recommendations, not sourced)
1. One signature shape per stage set (serpentine, double-back, split-merge, loop, climb-and-return) as in T155, T156 and T167 to T171.
2. Mark corner-inside tiles as strong area-of-effect spots and straights as strong single-target spots; show in the placement hint (T178).
3. Use a choke point as a teaching tool in stage 1 and remove it from later stages (T159).
4. Path length and difficulty curve per stage should be written as data and checked by the sim (T158, T179).
5. Vampire Survivors' timed escalation suggests a late-wave "Reaper" style pressure for endless mode (T016 endless).

## Sources and dates
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://en.wikipedia.org/wiki/Tower_defense | fetched 2026-10-28; 1978 to 2011 | read |
| 2 | https://en.wikipedia.org/wiki/Vampire_Survivors | fetched 2026-10-28; 2021 to 2025 | read |
| 3 | https://www.pocketgamer.co.uk/articles/042878/r/ | undated | snippet |
| 4 | https://babel.speldesign.uu.se/?p=5600 | undated | snippet |
| 5 | https://mikalagrand.itch.io/key-defence/devlog/97895/level-walkthrough | undated | snippet |

Caveat: Kingdom Rush and Bloons points rest on snippets; no designer talk was found.
