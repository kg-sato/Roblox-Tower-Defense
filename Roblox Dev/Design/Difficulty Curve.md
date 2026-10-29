# Difficulty curve and path length (T150, T158)
Computed 2026-10-29 from `Config.luau` (`stageSpawns`, `hpScale`, `ENEMIES`, `PATH`) by replaying the formulas for stages 1 to 25 (not by playing). Enemy counts: `min(5 + floor(1.3 x stage), 28)`; a Swift every 3rd enemy from stage 3, a Tank every 5th from stage 6, one Boss at stages 5, 10, 15, 20 and 25; every enemy's hp is multiplied by `1.2^(stage-1)`.

## Path length
There is one path for all 25 stages: 6 points, 234 studs long (68 + 28 + 54 + 14 + 70). So "path length against difficulty" is flat: stage 25 has the same lane as stage 1. Crossing times at that length: Grunt 29.2 s (speed 8), Swift 18.0 s (13), Tank 46.8 s (5), Boss 58.5 s (4). The boss timer (`BOSS_TIME` 35 s) is shorter than the boss's crossing time, so a boss that nobody damages escapes at 35 s, as the design says.
Implication for the map tasks (T155, T156, T167 to T171): each stage set could lengthen or shorten the lane to shape difficulty; today only hp and count change.

## Stage table
Last column is a rough yardstick: total hp divided by what one tier-1 Ember (12 damage per second) deals during one Grunt crossing (29.2 s), i.e. how many tier-1 Embers it takes to kill the stage if everything is in range for the whole crossing. It ignores range overlap, misses, crit, upgrades and the per-unit differences, so it is a scale, not a prediction.

| Stage | Enemies | Grunt | Swift | Tank | Boss | hp scale | total hp | Ember-tier-1 equivalents |
|---|---|---|---|---|---|---|---|---|
| 1 | 6 | 6 | 0 | 0 | 0 | 1.0x | 180 | 0.5 |
| 2 | 7 | 7 | 0 | 0 | 0 | 1.2x | 252 | 0.7 |
| 3 | 8 | 6 | 2 | 0 | 0 | 1.4x | 311 | 0.9 |
| 4 | 10 | 7 | 3 | 0 | 0 | 1.7x | 456 | 1.3 |
| 5 | 12 | 8 | 3 | 0 | 1 | 2.1x | 2,061 | 5.9 |
| 6 | 12 | 6 | 4 | 2 | 0 | 2.5x | 1,224 | 3.5 |
| 7 | 14 | 8 | 4 | 2 | 0 | 3.0x | 1,648 | 4.7 |
| 8 | 15 | 8 | 4 | 3 | 0 | 3.6x | 2,408 | 6.9 |
| 9 | 16 | 9 | 4 | 3 | 0 | 4.3x | 3,018 | 8.6 |
| 10 | 19 | 10 | 5 | 3 | 1 | 5.2x | 7,482 | 21.3 |
| 11 | 19 | 11 | 5 | 3 | 0 | 6.2x | 4,830 | 13.8 |
| 12 | 20 | 11 | 5 | 4 | 0 | 7.4x | 6,687 | 19.1 |
| 13 | 21 | 11 | 6 | 4 | 0 | 8.9x | 8,185 | 23.3 |
| 14 | 23 | 13 | 6 | 4 | 0 | 10.7x | 10,464 | 29.8 |
| 15 | 25 | 13 | 7 | 4 | 1 | 12.8x | 21,775 | 62.0 |
| 16 | 25 | 13 | 7 | 5 | 0 | 15.4x | 17,194 | 49.0 |
| 17 | 27 | 14 | 8 | 5 | 0 | 18.5x | 21,521 | 61.3 |
| 18 | 28 | 15 | 8 | 5 | 0 | 22.2x | 26,490 | 75.5 |
| 19 | 28 | 15 | 8 | 5 | 0 | 26.6x | 31,788 | 90.6 |
| 20 | 29 | 15 | 8 | 5 | 1 | 31.9x | 60,510 | 172.4 |
| 21 | 28 | 15 | 8 | 5 | 0 | 38.3x | 45,775 | 130.4 |
| 22 | 28 | 15 | 8 | 5 | 0 | 46.0x | 54,930 | 156.5 |
| 23 | 28 | 15 | 8 | 5 | 0 | 55.2x | 65,916 | 187.8 |
| 24 | 28 | 15 | 8 | 5 | 0 | 66.2x | 79,099 | 225.4 |
| 25 | 29 | 15 | 8 | 5 | 1 | 79.5x | 150,567 | 429.0 |

## Reading the table
- Count stops growing at 28 from stage 18; from there all growth is the 1.2x hp factor, so stage 25 is 79.5x stage 1 per enemy and about 840x in total hp (150,567 against 180).
- Boss stages are spikes: stage 5 is 4.5 times stage 4 (2,061 against 456), stage 10 is 2.5 times stage 9, stage 25 is 1.9 times stage 24. The boss alone is 700 hp x scale (stage 25: 55,650 hp).
- Reaching stage 25 needs about 429 tier-1-Ember equivalents. A tier-4 Common deals 42.9 times a tier-1 Common (`3.5^3`), so 12 tier-4 Commons give about 515 equivalents at the same base damage: stage 25 sits at the edge of what 12 Common tier-4 units can do, and Rare, Epic and Legendary units raise it a lot (rarity multipliers 2.2, 5, 12). See [[Progression Rules]] for the merge and rarity analysis.
- Stages 6 and 11 dip against the boss stage before them (1,224 after 2,061; 4,830 after 7,482): a planned breather.

## Tests
`Tests/Rules.test.luau` (31 checks, run in Studio Edit mode 2026-10-29: PASS) covers the formulas above: hp scale, the enemy count and boss rules for all 25 stages, the Swift and Tank start stages, rarity odds, tier damage, recycle, upgrade cost, trainer luck, the combo clamp and the pity streak. It checks formulas, not whether a stage can be beaten; the bot runs in `Tests/Balance.test.luau` do that (T191).
