# Game feel references: hit-stop, screen shake, squash (T021)

Question: what do Celeste and Vlambeer teach about hit-stop, shake and squash, and what numbers should we start from?

**Gap against the task:** the Celeste thread (GameSpot) returned 403 and the Vlambeer "Art of Screenshake" talk was not read; only its existence and one secondhand implementation sketch were found. The numbers here come from a general guide and are starting points, not rules from those games.

## Facts (sourced)
- Vlambeer was founded by Rami Ismail and Jan Willem Nijman on 1 Sep 2010; games include Super Crate Box (2010), Ridiculous Fishing (2013), Luftrausers (2014), Nuclear Throne (2015). The Wikipedia page does not mention the screenshake talk. [Wikipedia, Vlambeer](https://en.wikipedia.org/wiki/Vlambeer) (fetched 2026-10-28).
- "The Art of Screenshake" by Nijman is a roughly 40-minute talk, widely recommended by developers; search results confirmed it exists but not its contents. [Kenney, must-see videos for indie developers](https://kenney.nl/learn/must-see-videos-for-indie-developers) (listing; not read).
- One write-up describes a shake implementation: offset the camera a few pixels from its aim point, add a shake amount, decay it quickly, with the total set by the pixels the screen may move in each direction. [infovore.org, Making Game "Feel"](https://infovore.org/tag/feel/) (search summary only; the fetch of the post page showed unrelated content).
- Maddy Thorson's thread on ten game-feel techniques in Celeste (first item: coyote time, a grace period for jumping after leaving a ledge) is reported by [GameSpot](https://www.gamespot.com/articles/celeste-dev-explains-how-they-made-their-game-feel/1100-6474775/) (403 on fetch; snippet only, undated). A hobbyist devlog says freeze frames at the start of a dash were inspired by Celeste ([Hack Club Stardance devlog](https://stardance.hackclub.com/projects/2129/devlogs/50732), snippet).
- Hit-stop: a 50 to 100 ms freeze on a heavy hit; screen shake should stay small because large shake can cause nausea; squash and stretch on pickups, with easing instead of snapping. No other numbers given. [Wayline, Game Feel and Juice](https://www.wayline.io/learn/game-feel/1) (undated; fetched 2026-10-28; tutorial site, weak authority).
- A game-feel guide recommends a reduce-shake option and avoiding over-juicing routine actions. [Claude Skills, game feel](https://claudeskills.info/ko/skills/gamedev-skills/awesome-gamedev-agent-skills/game-feel/) (snippet; low authority, skipped as a basis).

## Not found
- No primary text from Celeste's makers or Vlambeer was read. The existing project already has hit-stop and shake logged in Overnight tasks (see run notes for T025 and the reduced motion setting), so this note should be read next to those.

## Starting values for our build (recommendations, not sourced rules)
1. Hit-stop: 2 to 5 frames (about 33 to 83 ms at 60 fps) for small hits, up to the 100 ms ceiling for a boss phase hit. The 2 to 5 frame range was already chosen in an earlier task (T025) and fits the Wayline range.
2. Shake: short and decaying, scaled by impact, with the amount from a data table (T140); off when reduced motion is on.
3. Squash: a short pop on placement and merge (T135), eased, and keep area roughly constant.
4. Keep routine actions plain; save big effects for merges, bosses and ultimates.
5. Before locking numbers, watch the Vlambeer talk and Thorson's thread by hand (a human task).

## Sources and dates
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://en.wikipedia.org/wiki/Vlambeer | fetched 2026-10-28; 2010 to 2023 | read |
| 2 | https://www.wayline.io/learn/game-feel/1 | undated; fetched 2026-10-28 | read |
| 3 | https://www.gamespot.com/articles/celeste-dev-explains-how-they-made-their-game-feel/1100-6474775/ | undated | 403; snippet |
| 4 | https://kenney.nl/learn/must-see-videos-for-indie-developers | undated | listing |
| 5 | https://infovore.org/tag/feel/ | undated | search summary |

Caveat: weakest note so far on primary sources; numbers are guide-level.
