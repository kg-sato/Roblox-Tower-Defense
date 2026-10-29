# Boss framework (2026-10-29, main coordinator)
Server-side framework for the five bosses of [[Boss Designs]]: per-boss definitions, three phases at 100%, 66% and 33% hp, generic timed effects, phase events and a snapshot field. Installed in Studio (`Shared.Config`, `Shared.MatchSim`) and mirrored in `Studio_Export/`; tests in `Tests/Boss.test.luau` (31 checks). The client does not read any of it yet.

## Data (`Config.BOSSES`, `Config.bossDef(stage)`, flag `Config.BOSS_PHASES`)
One entry per boss: `id`, `name`, `hpMult`, `rewardMult`, `phases` = three `{ at, banner, fx }`. `bossDef(stage)` picks by stage set; the five repeat after stage 25. Flag off gives the old generic Boss exactly.
| Boss (stage) | hpMult | rewardMult | P1 | P2 | P3 |
|---|---|---|---|---|---|
| The Unbound (5) | 1.0 | 1.0 | deny every 10 s | deny every 6 s | deny every 6 s, speed x1.2 |
| Clockmaker's Automaton (10) | 1.3 | 1.6 | slow aura 12 studs 15%, regen 3% / 8 s | slow aura, freeze all 3 s / 14 s | slow aura 25%, speed x1.15 |
| Star Choir's Echo (15) | 1.4 | 2.0 | deny every 9 s | deny, summon 2 Swift / 10 s | slow aura 10 studs 25%, summon |
| Hollow Court Regent (20) | 1.3 | 2.5 | summon 3 Grunts / 12 s | takes 85% damage, summon 2 | speed x2 |
| The Clockmaker (25) | 1.2 | 4.0 | deny every 12 s | freeze all 3 s / 20 s | regen 2% / 6 s, speed x1.1 |

## Effect vocabulary (run by `MatchSim.bossTick`, `bossSlow`, `damage`)
`regen {every, pct}`, `deny {every, dur}` (newest unit cannot fire), `freeze {every, dur}` (all units), `summon {every, kind, count}`, `slowAura {radius, slow}` (units inside cool down 1/(1+slow) as fast), `speedMult`, `damageTaken`. Timers reset at each phase change. Reward multiplier applies to the boss's coins and gems; the skill point stays.

## Events and snapshot (for the client)
`Spawn` has `boss` and `bossName`. `BossPhase { id, boss, name, phase, phases, banner, hpFrac }` once per phase entered (a big hit can fire two). `BossFx { id, kind = regen | deny | freeze | summon, slot, dur, enemy, count }`. Snapshot `boss = { id, name, phase, phases, hp, maxHp }` while a boss lives.

## Mapping to the design note and what is not implemented
Mechanics that fit the vocabulary only: the Unbound's "denial" is the deny effect; the third phase split into head, hands and core, the Automaton's lamp that heals a life, the Echo's pushes and killable echoes, the Regent's candles (damage reduction is flat 85%, not per candle), the Clockmaker's un-merge and the hit zone on the lamp are NOT built. Hollow Parishioners do not exist as an enemy, so the Regent summons Grunts. Unit slot "push" is replaced by deny.

## Balance check
Update 2026-10-29 after Crow, Thief and movement effects went on: Regent 1.6 to 1.3 and Clockmaker 2.0 to 1.2 (a seed stalled at the stage 25 boss); with all flags on the full bot clears 12 of 12 seeds, mean 574 s. The numbers below were with the flags off.
Lean full-bot runs (10 seeds, 20 simulated min, ROLL_COST 20): phases on 9 of 10 seeds clear all 25 stages, mean 635 s (10.6 min); old boss 10 of 10, mean 570 s. Softer hp multipliers did not remove the single failing seed (8, 9 and 10 of 10 across three variants), so the bot spread is mostly chance; the proposal multipliers are kept. All 15 suites pass.

## Open
- Client: phase bar, banner at each phase, flicker on denied units, freeze overlay (owner: UI chat, told; see [[Boss Designs]] T148 and T149).
- Boss sounds and music per phase ([[Boss Music Stings]]); boss models for the five (concept models exist, see [[Enemy Models]]) wired to the stage sets.
- Numbers are placeholders; a human player was not modelled.
