# Balance baseline with the 12 familiars (T191, T192)
Run 2026-10-29 in Studio (Edit mode) with `Tests/Balance.test.luau`: headless bots on seeds 1, 2, 3, 0.1 s steps, 20 simulated minutes per run, nothing in the game changed. The numbers are a baseline, not assertions. Familiar damage, cooldown and range for the nine new familiars are PLACEHOLDERS (never balanced); the roster is the live `Config.PETS` (Ember, Moth-Lantern, Brass Hound, Sentinel, Frostling, Gargoyle, Ward, Archivist, Mourner, Mirror Chorister, Star Drake, Grey Veil Wraith, held under their folder ids Ember, Zap, BrassHound, Sentinel, Frostling, Boulder, Ward, Archivist, Mourner, VoltFox, StarDrake, GreyVeilWraith).

## Bot strategies: stage reached by minute (mean of 3 seeds)
| Strategy | 1 min | 2 | 3 | 5 | 10 | 20 | gems/min | units at 20 min | max tier |
|---|---|---|---|---|---|---|---|---|---|
| idle (auto waves only) | 2.0 | 4.0 | 3.0 | 3.0 | 3.0 | 3.0 | 7 | 0 | 0 |
| roll (rolls gems) | 6.3 | 10.0 | 10.7 | 11.3 | 11.3 | 11.3 | 86 | 12 | 1 |
| upgrade (roll and coin upgrades) | 7.0 | 11.0 | 14.3 | 17.7 | 21.0 | 22.3 | 141 | 12 | 1 |
| full (roll, merge, upgrade, recycle) | 7.3 | 12.3 | 16.3 | 24.0 | 36.3 | 39.0 | 249 | 12 | 3 |
Reading: the stage reached by minute is the closest the harness gets to a stage clear time. The "full" bot reaches stage 24 by minute 5 and stage 39 by minute 20, i.e. it passes the 25-stage content in about 5 to 6 minutes. First pulls: Common instantly, Rare about 5 s, Epic about 8 s, Legendary 11 to 56 s (the roll bot hits a Legendary in only 1 of 3 seeds within 20 minutes).
Finding: either the economy is far too generous for a bot that plays optimally, or the bots overstate a human; with 12 slots and the new placeholder stats, stage 25 is cleared early. A human is slower (the bot merges and upgrades with no delay), so this is an upper bound on speed, not a verdict.

## Clear time per stage (T191), full bot (mean of 3 seeds, seconds)
s1 to s4 7 s each; s5 14; s6 to s9 9 to 11; s10 15; s11 to s14 12 to 13; s15 18; s16 to s19 15 to 16; s20 21; s21 to s24 16; s25 21. The 25 stages take about 5 minutes in total. The upgrade bot is slower and gets stuck on boss stages (s15 81 s, s20 202 s in 2 of 3 seeds, never clears 25); the roll bot clears up to stage 9 in all seeds and stage 14 in one seed; the idle bot clears only stages 1 to 3 at about 33 s each. The shortest possible stage is about 7 s (spawn gaps and walking), so early stages are limited by the spawn timer, not by damage.

## Income per stage (T190, from Config; before the perfect-streak gem multiplier of up to 3x)
Kill rewards: Grunt 2 coins 1 gem, Swift 2 and 1, Tank 6 and 3, Boss 60 and 25. The roll cost is flat at 10 gems (`ROLL_COST`; the design doc v1 said it would rise with each summon; it does not).
| Stage | enemies | coins | gems | rolls the gems buy (10 gems) |
|---|---|---|---|---|
| 1 | 6 | 12 | 6 | 0.6 |
| 2 | 7 | 14 | 7 | 0.7 |
| 3 | 8 | 16 | 8 | 0.8 |
| 4 | 10 | 20 | 10 | 1.0 |
| 5 | 12 | 82 | 36 | 3.6 |
| 6 | 12 | 32 | 16 | 1.6 |
| 7 | 14 | 36 | 18 | 1.8 |
| 8 | 15 | 42 | 21 | 2.1 |
| 9 | 16 | 44 | 22 | 2.2 |
| 10 | 19 | 108 | 49 | 4.9 |
| 11 | 19 | 50 | 25 | 2.5 |
| 12 | 20 | 56 | 28 | 2.8 |
| 13 | 21 | 58 | 29 | 2.9 |
| 14 | 23 | 62 | 31 | 3.1 |
| 15 | 25 | 124 | 57 | 5.7 |
| 16 | 25 | 70 | 35 | 3.5 |
| 17 | 27 | 74 | 37 | 3.7 |
| 18 | 28 | 76 | 38 | 3.8 |
| 19 | 28 | 76 | 38 | 3.8 |
| 20 | 29 | 136 | 63 | 6.3 |
| 21 | 28 | 76 | 38 | 3.8 |
| 22 | 28 | 76 | 38 | 3.8 |
| 23 | 28 | 76 | 38 | 3.8 |
| 24 | 28 | 76 | 38 | 3.8 |
| 25 | 29 | 136 | 63 | 6.3 |
| total 1 to 25 | | 1628 | 789 | 79 |

Total for 25 stages: 1628 coins and 789 gems before the streak multiplier, i.e. about 78 rolls. Against that, the full bot earned 249 gems a minute (the streak multiplier and the trainer level gems included), which is far more than the kills alone give (789 gems in 25 stages), so the streak multiplier and trainer level-ups must supply the rest; I did not break the bot's income down by source.

## Tier-1 power by familiar (T192)
Damage per second at tier 1 with no upgrades (damage x rarity multiplier / cooldown):
| Familiar (folder id) | Rarity | Damage | Cooldown | Range | DPS |
|---|---|---|---|---|---|
| Ember | Common | 12 | 1.0 | 20 | 12.0 |
| Moth-Lantern (Zap) | Common | 4 | 0.35 | 18 | 11.4 |
| Brass Hound | Common | 4 | 0.3 | 14 | 13.3 |
| Sentinel | Common | 14 | 1.2 | 18 | 11.7 |
| Frostling | Rare | 10 | 0.8 | 24 | 27.5 |
| Gargoyle (Boulder) | Rare | 20 | 1.4 | 20 | 31.4 |
| Ward | Rare | 6 | 1.0 | 26 | 13.2 |
| Archivist | Rare | 7 | 0.9 | 22 | 17.1 |
| Mourner | Epic | 10 | 0.55 | 24 | 90.9 |
| Mirror Chorister (VoltFox) | Epic | 9 | 0.45 | 24 | 100.0 |
| Star Drake | Legendary | 14 | 0.6 | 28 | 280.0 |
| Grey Veil Wraith | Legendary | 16 | 0.65 | 26 | 295.4 |
Mean DPS by rarity: Common 12.1, Rare 22.3, Epic 95.5, Legendary 287.7; ratios to Common 1.8, 7.9, 23.8. The rarity multipliers alone are 2.2, 5 and 12, so Epic and Legendary are about 1.6 and 2 times stronger than the multiplier intends, because their base damage over cooldown is also higher than the Commons'.
Tested in `Tests/Rules.test.luau` (37 of 37 pass): the mean DPS climbs with rarity, no familiar is over 4 times the weakest of its rarity (Rare is widest, 13.2 to 31.4, because Ward and Archivist are supports with low damage), and a Legendary is under 30 times a Common (23.8 now). Those limits are my choices.

## Findings and next steps
1. Stage 25 falls in about 5 minutes for a perfect bot: raise the hp scale, the enemy count or the boss hp, or tighten the economy ([[Difficulty Curve]], [[Progression Rules]]); the user decides the target session length (the design doc says a match is 8 to 12 minutes).
2. Epic and Legendary base stats double-count rarity; normalise their damage over cooldown so the multiplier carries the rarity (PROPOSAL), then re-run.
3. Re-run the harness after any change. The harness now also prints the clear time per stage (added 2026-10-29).
