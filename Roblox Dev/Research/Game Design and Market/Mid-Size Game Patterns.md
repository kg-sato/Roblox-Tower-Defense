# Mid-Size Game Patterns

Researched 2026-10-24. Question: what do the medium games (roughly 5K to 30K players, centered near 10K) have in common, especially simulators and minigames that repeat the same idea? Related: [[Engagement Loop Playbook]], [[Screenshot Analysis]], [[Competitors and Policy]], [[Concept Pitches]], [[Master Plan]], [[Analytics/Analytics Log|Analytics Log]]

## How this was measured (and what it can't tell us)

- **Source:** Roblox's own [Charts page](https://www.roblox.com/charts) (computer, Canada view), read on 2026-10-24. It has five lists: Top Trending, Up-and-Coming, Top Playing Now, Fun with Friends, Top Revisited. After removing duplicates there were **295 games**. **166** of them had 4,000 to 30,000 players, and **61** had 7,000 to 15,000.
- **Dates and visits:** for 25 games I looked up the creation date, visits, favorites, and server size from Roblox's public games API.
- **Biases to keep in mind:**
  - It is a **single snapshot**, taken during the Halloween events. Many games are boosted by event updates.
  - It only includes games Roblox put on a chart, not every game at 10K.
  - I picked the 25 games for the age check because their titles fit a formula, so they are not a random sample.
  - My grouping into archetypes used title keywords, so it is rough. About 70 of 166 landed in "Other".
  - A snapshot shows what is popular now, not what keeps players. I have no retention data.
- **Third-party claims:** a RoLearn guide says fewer than 0.01% of games sustain 10K and that 78% of games reaching 1K never sustain 10K. It cites no sources or method, so treat it as a guess ([guide](https://rolearn.dev/insights/roblox-10k-ccu-milestone-guide)). Its revenue range for 10K (about $5K to $17.5K a month) is also uncited.

## What is in the 4K to 30K band (rough counts out of 166)

| Archetype | Games | Typical players | Median rating | Examples (players now) |
|---|---|---|---|---|
| "Mundane job" simulators: `[Verb] a [Thing]` | 16 | 12K | 93% | Feed A Mosquito 29.9K, Chop A Forest 24.5K, Save the Krusty Krab 19.8K, Eat Everything In A Grocery Store 15.1K, Wash the Car 13.4K, Sell Lemons 12.8K, Build a Keyboard 12.2K |
| Small PvP, duels, sports | 31 | 9.5K | 87% | Turbo Soccer 27.6K, Sniper Arena 16.6K, untitled boxing game 15.5K, Rally Panic 5.9K |
| `+1 X Evolution` style clickers | 7 | 13.5K | 92% | +1 Venom Evolution 21.3K, +1 Stone Skipping 19.4K, +1 Pickaxe Swing for Eggs 16.5K, +1 Dance Battle Evolution 13.5K |
| Fishing, mining, digging | 5 | 14K | 96% | Heavyweight Fishing 17.1K, My Anime Mine 16.5K, Storage Hunters 14.2K, Deep Fishing 10.7K |
| Racing, vehicles, physics toys | 9 | 18.6K | 89% | Backseat Rally 30K, Kukirin Life 19.5K, Drag Drive Simulator 18.6K |
| Social, avatar, roleplay | 8 | 23K | 91% | My Avatar! 28.6K, Dreamville 27.1K |
| Horror | 7 | 6.6K | 83% | PINKIE PROMISE 12.1K, HUSH 7.7K |
| Tower defense | 4 | 18K | 96% | Cameraman Tower Defense 26.3K, Tower Defense Simulator 17.9K |
| Egg and animal collecting | 4 | 28K | 89% | Fake an Egg 28.9K |
| "(Anomaly)" spot-the-difference survival | 2 here, 4 on the charts | 20K | 92% | Clone Baby Care 20.4K, Animal Hospital 34.4K, Sell Fries 50.7K, Airport Security 6.2K |
| RNG and roll games | 2 | 9K | 95% | Roll A Stickman 9.2K |

Takeaway: the simulator and "mundane job" family is the biggest cluster in the 10K to 30K band and has the highest ratings. Small PvP is larger by count but has lower ratings. Horror sits lower, near 6K.

## The age check (this is the most useful part)

Server size and age for 25 sampled games, from the games API. Players are the live count at the time.

| Game | Created | Visits | Players | Max players |
|---|---|---|---|---|
| Backseat Rally | 2026-10-05 | 25M | 30.3K | 8 |
| Feed A Mosquito | 2026-08-21 | 18M | 30.2K | 7 |
| Cameraman Tower Defense | 2026-08-26 | 43M | 26.6K | 30 |
| Chop A Forest | 2026-09-21 | 27M | 24.4K | 18 |
| +1 Venom Evolution | 2026-10-05 | 11M | 21.4K | 16 |
| Clone Baby Care (Anomaly) | 2026-10-09 | 14M | 20.5K | 24 |
| Save the Krusty Krab | 2026-09-29 | 14M | 19.9K | 30 |
| +1 Stone Skipping | 2026-09-05 | 65M | 19.5K | 10 |
| Heavyweight Fishing | 2025-08-04 | 68M | 17.2K | 10 |
| Eat Everything In A Grocery Store | 2026-10-03 | 12M | 15.0K | 12 |
| +1 Dance Battle Evolution | 2026-09-21 | 7M | 13.4K | 12 |
| Wash the Car | 2026-08-16 | 15M | 13.3K | 6 |
| Sell Lemons | 2025-03-17 | 488M | 12.8K | 10 |
| Build a Keyboard | 2026-07-29 | 29M | 12.3K | 7 |
| Bubble Gum Simulator INFINITY | 2024-09-02 | 617M | 11.8K | 12 |
| Deep Fishing | 2026-07-18 | 20M | 10.7K | 12 |
| Roll A Stickman | 2026-09-10 | 3M | 9.2K | 16 |
| Survive Overnight in a Mega Store | 2025-01-09 | 647M | 9.1K | 25 |
| Fix My Phone | 2026-10-05 | 7M | 8.3K | 8 |
| Murder Mystery DUELS | 2025-06-06 | 96M | 8.1K | 30 |
| Make Rugs! | 2026-10-07 | 5M | 7.9K | 4 |
| Harpoon a Fish | 2026-08-28 | 7M | 7.8K | 6 |
| Candy Kingdom Defense | 2026-09-29 | 4M | 7.8K | 24 |
| Make Ramen To Get Rich | 2026-10-08 | 8M | 7.0K | 10 |
| Rally Panic | 2026-10-02 | 16M | 5.9K | 16 |

What it shows:
1. **Most of these are very new.** 20 of the 25 were created since the end of July 2026, many only 2 to 3 weeks ago. Several went from nothing to 20K+ in under a month (Clone Baby Care: 14M visits in about 2 weeks). So the 10K band is mostly fresh games riding a trend, not old games coasting. (Caveat: I chose games with trendy titles.)
2. **A few of these have lasted.** Sell Lemons (created March 2025, 488M visits), Survive Overnight in a Mega Store (January 2025, 647M), Bubble Gum Simulator INFINITY (September 2024, 617M), Heavyweight Fishing (August 2025), and Murder Mystery DUELS (June 2025) are still at 8K to 17K. These are the best examples of a medium game that lasts. Common thread: all are simple simulators, and all are still being updated (each was updated within the last two days).
3. **Servers are small.** The median max-players is 12. 15 of the 25 allow 12 or fewer. Make Rugs holds 4, Wash the Car 6, Build a Keyboard 7, Harpoon a Fish 6. Small servers keep the world feeling lively with few players and keep friends together. Only tower defense, survival, and duel games go up to 24 to 30.
4. **Everything updates constantly.** All 25 were updated in the last 3 days (21 on the day I looked).
5. **Very high favorite counts relative to visits.** +1 Stone Skipping has 2.08M favorites on 65M visits (3.2%). Wash the Car 3.6%, Fix My Phone 4.2%, Build a Keyboard 2.3%. Heavyweight Fishing has 0.17%. The pet and egg games in your screenshots had a popup rewarding likes and favorites ([[egg-free-reward-popup.png]]), so my guess is these games reward favorites in play. That is an inference. Roblox's discovery page does not list favorites as a ranking signal, and I haven't checked whether rewarding favorites is allowed. Read the Community Standards before copying it.

## The formula behind each family (what stays the same)

Observed from titles, genres, and the screenshots. These are descriptions of the pattern, not Roblox rules.

1. **"Mundane job" simulator.** Pick a familiar everyday task (sell lemons, wash cars, make rugs, fix phones, make ramen, build keyboards). The player does it by hand at first, earns money, buys faster tools and more stations, then hires or automates. Titles are plain and describe the loop in four words. Roblox tags most as "Simulation / Tycoon" and the screenshots show the same pieces (shop, upgrades, rebirth-style resets). Small servers (4 to 10). Highest ratings in the band.
2. **`+1 X Evolution` clicker.** One repeatable action (swing, kill, skip a stone, dance battle), each success gives +1, which unlocks stronger forms or new worlds ("World 2"). Roblox tags these "Incremental Simulator". Servers of 10 to 16.
3. **Collect-by-activity.** Fishing, mining, digging, harpooning: do an action to get items of different rarities, sell, upgrade the tool, go deeper. Deep Fishing in your screenshots is the model: depth meter, rarity-colored catch values, rod upgrades. Rarity text and "New Best!!!" give constant small wins.
4. **Eat, chop, survive "big number" sims.** Chop A Forest, Eat Everything In A Grocery Store, Feed A Mosquito: a comic premise plus visible growth of the character or numbers.
5. **Anomaly-spotting.** Clone Baby Care and the other "(Anomaly)" games: a short repeating round where you spot what's wrong and survive. Different from the money loop but also easy to learn and easy to clip.
6. **Quick duels and mini-matches.** Rally Panic (2-player rally), Murder Mystery DUELS: a match lasts minutes and you can queue again immediately.
7. **Physics and vehicle toys.** Backseat Rally, drag and drift games: a funny physics situation that makes good short videos.
8. **Tower defense with a twist.** Cameraman Tower Defense (a known IP-style twist on an old genre).

Common to nearly all of them:
- **A premise you can explain in one line** and understand from the title.
- **A loop that works in the first 30 seconds** (see [[Engagement Loop Playbook]]).
- **Visible upgrades**: a number, a tool, or a station that gets better.
- **Frequent updates and a holiday event** (Halloween branding appears in the title of about a third of the band).
- **Clean mobile-friendly controls**; most are one-action games.

## What this means for our game

1. **A `[Verb] a [Thing]` simulator or a `+1` clicker is the best-supported choice for a solo one-month build.** They are common in the band, have the highest ratings, and need a small content set. Compare each pitch in [[Concept Pitches]] against these archetypes.
2. **Pick a premise with a built-in twist.** Roblox's discovery guidance says copies of existing games hurt exposure and to add your own twist to trends ([Discovery](https://create.roblox.com/docs/production/promotion/discovery)). The pattern is copyable; the exact theme and title are not.
3. **Use a small server size (4 to 12).** It matches 60% of the sampled games and fits a low player count at launch.
4. **Plan updates from day one.** Every sampled game updated within 3 days. Budget a small update every week.
5. **Aim for the proven longevity pattern:** simple loop, steady weekly updates, and a seasonal event, as seen in Sell Lemons, Bubble Gum Simulator INFINITY, and Survive Overnight.
6. **Trends fade; we need retention.** Several games here are only weeks old, so a spike is not a business. Track Day-1 and Day-7 retention in [[Analytics/Analytics Log|Analytics Log]].
7. **Check policy before copying engagement tricks:** rewarding likes or favorites, limited-time pressure, and paid random items (see [[Competitors and Policy]]).

## Gaps and next steps

- **No time series.** To see which games keep their players, take this same snapshot weekly (I can repeat it with the same method) and compare. Third-party trackers (RoMonitor, Rolimons) would give history but I did not access them.
- **Revenue per game** is not public. The RoLearn estimates are unsourced.
- **Genre and creation date** were only checked for 25 games.
- The Charts page shows a Canada, computer view. Other regions and devices may rank differently.
- I did not analyze in-game UI for these new games. If you want, send screenshots of two or three (for example Sell Lemons, Wash the Car, +1 Stone Skipping) and I'll add them to [[Screenshot Analysis]].
