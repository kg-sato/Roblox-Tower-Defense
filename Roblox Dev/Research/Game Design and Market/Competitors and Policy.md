# Competitors and Policy

Second pass, 2026-10-24. Related: [[UI Design Playbook]], [[Engagement Loop Playbook]], [[Roblox Success Sources]], [[Systems]]

## 1. Paid random items (loot boxes, egg hatching, spins)

Source: [Paid random items policy guidelines](https://create.roblox.com/docs/production/monetization/paid-random-items) (official; the page was last revised October 15, 2026 according to a search snippet, so re-read it before shipping).

What counts: any random outcome bought with Robux, directly or indirectly. That includes capsules/eggs, enhancement and combination items, and keys or spin tickets bought with Robux. Odds boosters (luck potions, pity systems) are covered too. Random rewards earned in play without spending Robux or paid currency do not need odds disclosure.

Requirements:
1. **Show every possible outcome and its real numeric odds** before the player buys.
2. **Percentages, summing to exactly 100%.** Long decimals may be rounded with a disclaimer. Items with identical odds can share one stated rate.
3. **Visible in the item's UI or in a clearly labelled details pop-up.** A bare "i" icon with no descriptive word is not enough.
4. **One-time outcomes:** if a player can win an outcome only once, update the remaining odds for that player.
5. **Odds boosters** must explain their effect numerically and show the player's updated odds while active.
6. **Regional restrictions:** rules vary by country. Check `PolicyService` for the flag saying paid random items are restricted for that user. For restricted users, pick one: a free way to earn the item, outcomes in a fixed disclosed order, sell the specific outcome directly at a price based on expected value, hide or remove the random item, block the purchase with an error, or move the user away from those areas.
7. **Trading:** the same API flag says whether trading of paid items is allowed. Where a user is ineligible, don't let them trade outcomes of paid random items or other paid items.

Implications for our design:
- Build the odds panel into the egg/crate UI from day one. Put the percentages in the shop card, or a labelled "Odds" button.
- Server-side roll only. Never let the client decide the outcome (see [[Systems]] security rules).
- Make the odds table data-driven (one table feeds both the roll and the UI) so they can never disagree.
- Simplest safe path for our one-month solo plan: **skip paid random items at launch.** Use fixed-price items and earnable randomness (free drops from play), which need no disclosure. Add paid random items only after we've read the full policy and added `PolicyService` handling.
- Trading: the policy confirms a paid-item trading restriction exists. Real-money trading of items for cash outside Roblox is against the Terms (per Wikipedia's note on Grow a Garden). We don't need trading to launch, so defer it.
- Not verified: the full legal text, age rules (the page doesn't address age), and the exact `PolicyService` property names. Look them up in the [PolicyService reference](https://create.roblox.com/docs/reference/engine/classes/PolicyService) when implementing.

## 2. Competitor snapshot (live Roblox pages, viewed 2026-10-24)

I opened the public game pages in the built-in browser. These pages show the store-front, not the in-game screens (those need the Roblox client and a login).

| | Grow a Garden | Steal a Brainrot |
|---|---|---|
| Active now | about 25.8K | about 245.8K |
| Visits | 35.9B+ | 74.1B+ |
| Favorites | about 11.5M | about 29.6M |
| Server size | 4 | 8 |
| Genre | Simulation / Tycoon | Simulation / Tycoon |
| Last updated | 2026-10-24 | 2026-10-24 |
| Page structure | Events carousel (3 scheduled events with dates and "Notify Me"), About, Store, Servers | About, Store, Servers |

What this shows:
- **Peaks fade.** Grow a Garden peaked around 22M concurrent in 2025 ([Wikipedia](https://en.wikipedia.org/wiki/Grow_a_Garden)) and sits near 26K today. Brainrot is still strong. A huge peak is not the same as lasting retention, which supports measuring our own Day-1 and Day-7.
- **Both ship updates on the day I checked.** Grow a Garden lists Ghoul Garden 2 (Halloween part 2), a Watering Wednesday admin-abuse event on Oct 28, and a teaser "Next update ???" on Oct 31. The "???" teaser plus Notify Me button is a cheap, copyable retention hook.
- **Small servers.** Server sizes of 4 and 8 make the game feel social and low-lag, and keep friend groups together.
- **One-line descriptions and a how-to list.** Brainrot's page says "Buy a Brainrot, Steal, Generate money, Rebirth" with emoji bullets. Grow a Garden's page gives numbered planting steps. Both state the loop in under 10 seconds of reading.
- **Cross-promotion.** Their "People Also Join" lists show the current simple-loop hits: Steal An Egg (about 1.3M active), Escape Tsunami For Brainrots, 99 Nights in the Forest, Brookhaven. Worth studying next.
- **Badges.** Grow a Garden has easy letter badges (G, A, R, each about 21% rarity) that hundreds of millions of players have earned. Cheap early badges give new players an immediate win.

## 3. In-game UI: what I could and could not confirm

From fan guides (low reliability, may be outdated):
- Grow a Garden: seed shop restocks about every 5 minutes with a countdown; a daily-deals section refreshes every 24 hours; stock is the same across servers; a separate gear shop ([rblxguide](https://rblxguide.com/games/grow-a-garden/crops/seed-shop)). Sources disagree on which seeds are always in stock.
- Steal a Brainrot: a conveyor sells characters from common to rare; a shop sells traps and boosts; a Rebirth button sits on the left of the screen, and a yellow confirm button appears at the bottom when requirements are met; a base-lock button gives temporary protection ([Sportskeeda](https://www.sportskeeda.com/roblox-news/steal-brainrot-rebirth-1-guide)).

Patterns worth copying (structure, not art):
1. **A countdown on anything that restocks.** A visible timer makes players come back or wait.
2. **A single left or right side-rail of menu buttons** (Shop, Inventory, Rebirth) instead of many HUD elements.
3. **A confirm button that only lights up when the requirement is met** (clear disabled state, matches the official "grey means unavailable" convention).
4. **Always-visible currency counter** with a number pop on change.
5. **Event banners with dates** and a notify option.

Still unconfirmed: the real in-game layouts, sizes, colours, fonts, and mobile placement. To get them, play each game on a phone (or the emulator) and screenshot the HUD, shop, inventory, purchase prompt, and rebirth screen, then drop the images in `Research/Screenshots/`. I can analyze them once they're in the vault.

## 4. Updates to the plan

- Launch **without** paid random items and without trading.
- Add a countdown shop restock and a dated event banner to the first update.
- Keep server size small (4 to 8) to start.
- Add 2 to 3 trivial early badges.
- Track retention weekly in [[Analytics/Analytics Log|Analytics Log]]; compare to a 90-day decline like Grow a Garden's, not to peak numbers.
