# Market Snapshots

A weekly copy of Roblox's public Charts page, so we can see which mid-size games keep their players and which formulas are fading. This is **market** data, not our own game's numbers (those go in the weekly notes made from [[Templates/Weekly Analytics]]). Linked from [[Analytics/Analytics Log|Analytics Log]]. Background: [[Research/Mid-Size Game Patterns|Mid-Size Game Patterns]].

## How it works

- A scheduled Claude task runs every **Saturday around 10:00** (local time). It only runs while the Claude desktop app is open; if the app was closed it runs on the next launch.
- It opens `roblox.com/charts` (computer, Canada view) in the app's browser and saves every game with 4,000 or more players to `Analytics/Market Snapshots/YYYY-MM-DD.csv` (columns: placeId, ccu, rating, name).
- It compares to the previous file **by placeId** (titles change with events), then adds a new entry at the top of **Weekly log** below and updates the "Latest" line in the Analytics Log.
- Every snapshot has the same blind spots: one region, one device view, only games on a chart, and event weeks (such as Halloween) inflate numbers. Compare week to week, not against outside numbers.

## Tracked games

Always reported, even if they leave the 4K band (shown as "below 4K"):

| Group | Games (placeId) |
|---|---|
| Mundane-job sims | Sell Lemons 79268393072444, Wash the Car 70733580049633, Make Rugs 123184865562509, Build a Keyboard 112398753926712, Fix My Phone 139165770588984, Make Ramen 102155891663543, Harpoon a Fish 113384248926706 |
| `+1` clickers | +1 Venom Evolution 116448925875915, +1 Stone Skipping 111543903102439, +1 Dance Battle Evolution 76413295757565, Roll A Stickman 115068315659966 |
| Collect, fish, survive | Deep Fishing 132239307080610, Heavyweight Fishing 98502499119821, Chop A Forest 103363457515322, Eat Everything In A Grocery Store 128201586883489, Feed A Mosquito 125310131519813, Survive Overnight in a Mega Store 127380660530951, Save the Krusty Krab 129332901430212, Clone Baby Care 87346021451395 |
| Tower defense, duels, vehicles | Cameraman Tower Defense 132929771812494, Candy Kingdom Defense 111053011787075, Murder Mystery DUELS 128119795963270, Rally Panic 138572313449154, Backseat Rally 94278659624110 |
| Long-running simulator | Bubble Gum Simulator INFINITY 85896571713843 |
| Giants, to watch decay | Grow a Garden 126884695634066, Steal a Brainrot 109983668079237 |

## Weekly log (newest first)

### 2026-10-24 (baseline, Halloween week)
- Source: Charts page, computer, Canada. 296 unique games listed, 216 saved with 4,000+ players ([[Analytics/Market Snapshots/2026-10-24.csv]]).
- Games with 4,000 to 30,000 players: **166**. With 7,000 to 15,000: **61**.
- Tracked games now: Sell Lemons 12.8K, Wash the Car 13.4K, Make Rugs 8.0K, Build a Keyboard 12.2K, Fix My Phone 8.3K, Make Ramen 6.9K, Harpoon a Fish 7.8K, +1 Venom Evolution 21.3K, +1 Stone Skipping 19.4K, +1 Dance Battle Evolution 13.5K, Roll A Stickman 9.2K, Deep Fishing 10.7K, Heavyweight Fishing 17.1K, Chop A Forest 24.5K, Eat Everything In A Grocery Store 15.1K, Feed A Mosquito 29.9K, Survive Overnight 8.9K, Save the Krusty Krab 19.8K, Clone Baby Care 20.5K, Cameraman Tower Defense 26.3K, Candy Kingdom Defense 7.8K, Murder Mystery DUELS 8.1K, Rally Panic 5.9K, Backseat Rally 30.0K, Bubble Gum Simulator INFINITY 11.8K, Grow a Garden 26.1K, Steal a Brainrot 265.1K.
- Note: the first comparison happens on 2026-10-31.
