# How enemies show health and status at a glance (T022)

Question: how do top tower defense games show enemy health and status, and what should our enemies do?

**Gap against the task:** no read source describes how the top tower defense games (Bloons, Kingdom Rush, Roblox TD titles) display health and status. The Bloons wiki pages returned 402 and 403, and Wikipedia's Bloons TD 6 page has no visual details. What follows is from small developer posts and forum snippets; they show common practice, not top-game practice.

## Facts (sourced, low authority)
- A small TD game, JUSTD, shows the health bar always on enemies, a blue shield bar only when shield is above zero, and a yellow armor bar sharing the shield's look for consistency. [JUSTD devlog, "Health indicator and turret stats extended"](https://fairytalesgames.itch.io/justd/devlog/706544/health-indicator-and-turret-stats-extended) (30 Mar 2024; fetched 2026-10-28).
- Bloons TD 6 has resistances (explosions, ice, magic), MOAB-class enemies with more health and armour, and boss bloons every 20 rounds from round 40. [Wikipedia, Bloons TD 6](https://en.wikipedia.org/wiki/Bloons_TD_6) (fetched 2026-10-28). It does not describe how health or status is drawn.
- From search snippets of dev posts and forums (not read in full): too many small icons clutter enemies; group icons by type (health, status, intent) in different spots, and move minor detail to tooltips ([itch.io thread](https://itch.io/post/13092079)); a Moonbreaker request asks for a small symbol beside the health bar for poison, burn or stun, with details on hover ([Moonbreaker feature board](https://moonbreaker.nolt.io/65)); a Songs of Conquest thread asks for consistent bar colours and a bigger bar decoration so it does not blend into terrain ([Songs of Conquest suggestion](https://songsofconquest.featureupvote.com/suggestions/324077/more-readable-colors)); a Notion document suggests capping the number of status icons on a bar ([In-World Healthbar Document](https://astonishing-couch-d67.notion.site/In-World-Healthbar-Document-13004faa53928080998cdcb5b183c694), page text did not load; snippet only).

## Not found
- Kingdom Rush and Roblox TD health displays. Bloons' colour-layer system is well known but was not confirmed by any source I could read.

## Recommendations for us (not sourced rules)
1. Bar at the board camera: wide, high contrast, with an outline so it survives terrain colour; contrast check is already a task (T139).
2. Show shield and armour bars only when present, as JUSTD does; keep one bar style across the game.
3. Cap status icons at three per enemy; show the rest on tap or in a tooltip (T085, T139).
4. Put identity on the body, not the bar: colour or silhouette per enemy family (T133) so health is secondary.
5. Show status on the model too (tint, particle) since small icons fail at far camera (T277 status visuals).
6. Boss bar is separate with phase ticks (T149, T267).

## Sources and dates
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://fairytalesgames.itch.io/justd/devlog/706544/health-indicator-and-turret-stats-extended | 30 Mar 2024 | read; small indie game |
| 2 | https://en.wikipedia.org/wiki/Bloons_TD_6 | fetched 2026-10-28 | read; no visuals |
| 3 | https://itch.io/post/13092079 | undated | snippet |
| 4 | https://moonbreaker.nolt.io/65 | undated | snippet |
| 5 | https://songsofconquest.featureupvote.com/suggestions/324077/more-readable-colors | undated | snippet |

Caveat: evidence is indie-scale and mostly snippets; recommendations are mine.
