# Progression and economy rules (T183, T184, T188, T189, T220, T221)
Written 2026-10-29 from `Config.luau`, `MatchService.luau` and the [[Game Design Doc]]. Numbers marked PROPOSAL are design targets for the user to approve; nothing here changed the game.

## Facts the rules rest on
- Damage of a unit = base x rarity multiplier x 3.5^(tier-1) (`Config.petDamage`); rarity multipliers 1, 2.2, 5, 12; tier cap 5 (`TIER_MAX`); a merge takes 3 identical units, so tier t costs 3^(t-1) tier-1 units.
- Damage per unit at base 1: Common 1, 3.5, 12.2, 42.9, 150 (tiers 1 to 5); Rare 2.2 to 330; Epic 5 to 750; Legendary 12, 42, 147, 515, 1801.
- Rolls cost 10 gems (`ROLL_COST`), odds 60/28/10/2 with pity at 20 rolls and luck from trainer level; 12 grid slots (`MAX_UNITS`); enemy hp scales 1.2^(stage-1) (stage 25 is 79.5x).
- A save holds: level, xp, skill points, gems, skill tree, tutorial flag, settings, and the seen-familiars set (`TEMPLATE` in MatchService). A run holds coins, stage, units and per-type upgrades in memory only.

## Merge factor against the rarity cap (T183)
Finding: a Legendary roll (12 at tier 1) already equals a Common at tier 3 (12.2), which costs 9 rolls of merging; a Legendary at tier 5 (1,801) is 12 times a Common at tier 5 (150). The merge gain per slot (3.5x) is higher than the merge cost (3x units), so merging always pays, and the gap between rarities never closes.
Options: (A) keep tier cap 5 for all rarities (today); (B) cap by rarity: Common and Rare 5, Epic 4, Legendary 3, so the best Legendary (147) equals the best Common (150) per slot and rarity then changes identity and utility, not raw size; (C) keep the cap but raise merge cost for higher rarities. Recommendation: B behind a flag, because with 12 slots and enemy hp growing 79x, a tier-5 Legendary makes the other eleven slots irrelevant and the roster of twelve familiars pointless. Needs the user's decision; the flag (`Config.RARITY_TIER_CAP`, default off) is NOT implemented.

## Run-end rewards: what carries over (T184)
| Stays after a run | Resets after a run |
|---|---|
| gems, trainer level and xp, skill points and tree, collection (seen familiars), settings | coins, stage reached, units on the grid, per-type upgrades, perfect streak |
Examples: a player who reaches stage 12 with 400 coins and then closes the game keeps their gems and level but starts the next run at stage 1 with 30 coins. An Overrun (crystal reaches 0) pushes back 2 stages and takes 30% of coins within the run.
Finding: the best stage reached is not saved, so there is nothing to carry over for it. PROPOSAL: save `bestStage` and pay a one-time gem bonus for each new stage record (10 gems x set number), so progress is not all lost; needs a TEMPLATE field and a version note.

## Daily reward ladder (T188)
Seven days, free currency only, a missed day pauses the streak (no punishment, no fake countdowns), the ladder then repeats with the same rewards plus 10% gems each full cycle (cap 50%). PROPOSAL: day 1 20 gems; day 2 one free roll; day 3 30 gems; day 4 a cosmetic frame piece; day 5 40 gems; day 6 two free rolls; day 7 1 skill point and 50 gems (skill points otherwise come only from level-ups, bosses and the tutorial). 7-day total about 140 gems plus 3 rolls, against 10 gems per roll: about 17 rolls a week from the ladder, a minor share of income.

## Monetisation review (T189)
Plan in the design doc: fixed-price premium pets with the same power ceiling, two passes (2x Coins, Auto-Merge), no paid random items, no trading, every purchase checked on the server. Review:
- Fine: premium pets with the same ceiling; Auto-Merge as a convenience; no paid random items (no odds-disclosure duty, since rolls use earned gems).
- Not cosmetic-only: the 2x Coins pass buys progress speed, which is pay-for-progress in a game with no PvP; the task asks for no pay-to-win. Recommendation: replace it with cosmetics (trainer outfits from [[Trainer Outfit]], frames, lantern colours, title cards) or keep it only if the user accepts a convenience-level boost.
- Never sell gems, luck or tier cap; keep pity and the odds panel visible.
- Parents and age: the audience is 9 to 16 (assumption), so no countdown pressure, no loot boxes for Robux.
Decision needed from the user: keep or replace the 2x Coins pass.

## Inventory limit and expansion (T220)
The grid is the live limit (12 slots, `MAX_UNITS`); the collection has no limit. PROPOSAL: slots grow free, never by purchase: 12 at start, +2 at trainer levels 10, 15, 20 and 25 (20 total, as the design doc allows). Basic play is never gated by a purchase (whether 12 slots are enough for the early stages is untested).

## Trade rules (T221)
None in v1. Reasons: the design doc says no trading; trading invites duplication exploits and scams in a 9 to 16 audience; the server must own inventory. A future option once saves are stable: one-way gifting of Common duplicates between friends, rate-limited, logged, no currency attached.

## Pity (T200)
Rule in code (`MatchSim.pickRarity`, `Config.PITY_EVERY` 20): after 19 rolls without an Epic or better, the 20th roll is forced to Epic or Legendary (split in proportion 10 to 2, i.e. Legendary about 17%). Any Epic or Legendary resets the counter. The skill tree can shorten the interval (`pity` value; never below 8). The odds panel and the roll read the same table. Tested in `Tests/Rules.test.luau`: 1,800 rolls over six seeds, the longest dry streak was 19, never 20.
