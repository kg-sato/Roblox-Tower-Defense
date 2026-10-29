# Monetisation players accept versus what they hate (T027)

Question: which monetisation models have been accepted, which caused backlash, and what are the Roblox rules we must follow?

All Wikipedia pages and the Roblox page were fetched 2026-10-28. This note is about what is documented; "what the community accepts" is read from backlash and regulation history, since no survey was found.

## Facts (sourced)
**Accepted pattern: cosmetics only.** Dota 2, Fortnite Battle Royale and StarCraft II sell only cosmetics so paying players keep equal footing. [Wikipedia, Free-to-play](https://en.wikipedia.org/wiki/Free-to-play) Fortnite is cited for locking no gameplay content behind payment, though critics say camouflage-style skins can still give an edge. [Wikipedia, Microtransaction](https://en.wikipedia.org/wiki/Microtransaction)

**Battle pass.** Free track plus paid premium track; origins in Dota 2's Compendium (2013); Fortnite made it widely popular in 2018. Rewards are shown up front, unlike loot boxes. Critics call it predatory because seasonal rewards that may never return create fear of missing out, and the best rewards sit at the end of the track so players grind or pay to skip. In August 2024 Fortnite announced that past pass cosmetics may return to the shop after 18 months. [Wikipedia, Battle pass](https://en.wikipedia.org/wiki/Battle_pass)

**Backlash and regulation (dated).**
- Oblivion horse armor (2006): about US$2.50 for small content seen as poor value.
- Star Wars Battlefront II (2017 to 2018): gameplay-affecting purchases; players computed over 48 hours of play to unlock a hero; EA removed those purchases in March 2018 and kept cosmetic ones.
- World of Tanks (June 2013): Wargaming dropped pay-to-win mechanics after criticism.
- Belgium and Netherlands (April 2018) acted against loot boxes; UK Parliament committee (Sep to Oct 2019) recommended treating microtransactions as gambling. [Wikipedia, Microtransaction](https://en.wikipedia.org/wiki/Microtransaction); [Wikipedia, Free-to-play](https://en.wikipedia.org/wiki/Free-to-play)
- Currency that hides real prices ("money illusion") was argued in a 2020 German study and used in a 2021 legal action against Epic over Fortnite. [Wikipedia, Free-to-play](https://en.wikipedia.org/wiki/Free-to-play)

**Roblox rules for paid random items** ([Creator Hub, Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items); undated page).
- Applies to anything bought with Robux or Robux-bought currency (eggs, chests, enhancements, luck boosts, indirect keys or spin tickets). Before purchase, show every outcome with exact percentages that total 100%; a labelled button to a details list is acceptable.
- Odds boosters must state their numeric effect and update displayed odds while active; a once-only outcome must update the remaining odds.
- Random rewards earned in play without Robux or paid currency do not need odds disclosure.
- Check `PolicyService:GetPolicyInfoForPlayerAsync()`; if `ArePaidRandomItemsRestricted` is true, the user cannot use paid random items and the creator must offer an alternative (free earn path, fixed disclosed order, direct sale of the outcome, or hide the item). Paid-item trading depends on `IsPaidItemTradingAllowed`.

## Not found
- No survey data on what Roblox players accept; the grouping above is inference from history.

## Recommendations (not sourced rules)
1. Cosmetics-only shop and a battle pass with every reward visible and no expiry on core items, matching T189 and T024 tasks.
2. If paid rolls are ever added, they must show odds and respect PolicyService; the safer plan is no paid random items in v1, and rolls earned only by play (no disclosure rule applies, but we publish odds anyway, see [[Roll and reveal pacing, non-predatory]]).
3. Show real prices, not obscured currency conversions (the money-illusion point).
4. Let past pass cosmetics return so the pass does not drive FOMO (the Fortnite change in 2024 is a precedent).
5. Keep the economy sim honest (T190) so gameplay power is never sold.

## Sources
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://en.wikipedia.org/wiki/Free-to-play | fetched 2026-10-28; 2013 to 2021 events | read |
| 2 | https://en.wikipedia.org/wiki/Battle_pass | fetched 2026-10-28; 2013 to Aug 2024 | read |
| 3 | https://en.wikipedia.org/wiki/Microtransaction | fetched 2026-10-28; 2006 to 2019 | read |
| 4 | https://create.roblox.com/docs/production/monetization/paid-random-items | fetched 2026-10-28; undated | read |
| 5 | https://create.roblox.com/docs/reference/engine/classes/PolicyService | not visited | check API name before coding |
