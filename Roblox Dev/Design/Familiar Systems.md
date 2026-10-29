# Familiar systems: upgrade paths, synergies, statuses, armour (T193, T194, T196, T212, T213)
Design written 2026-10-29. Roles come from the lore notes in `Roblox Dev/Lore/Familiars/` (one verb per familiar). Today the game has three global upgrades per unit type (Power +30% damage, Haste +14% speed, Crit +8% for 2.5x, 5 levels each, `Config.UPGRADES`) and no roles, statuses or armour in code. Everything below is a PROPOSAL, and nothing is implemented.

## Upgrade paths (T196): three paths per familiar, each with its own identity
Each familiar keeps Power and Haste as the two generic levers and swaps Crit for an identity path tied to its verb; a unit takes levels in all three (the cost curve stays `12 x 1.75^level`). Identity paths:

| Familiar | Verb | Path A (generic) | Path B (generic) | Identity path (replaces Crit) |
|---|---|---|---|---|
| Ember | Scorch | Power: hotter flame | Haste: quicker lighting | **Kindle**: burn lasts longer and spreads to the next enemy |
| Moth-Lantern | Reveal | Power | Haste | **Lure**: marked enemies take more damage and are easier to hit |
| Brass Hound | Harry | Power | Haste | **Swarm**: every 5th bite hits twice |
| Sentinel | Breach | Power | Haste | **Pierce**: also ignores fog armour at level 5 |
| Frostling | Chill | Power | Haste | **Deepfreeze**: slow gets stronger with each hit on the same enemy |
| Gargoyle | Crush | Power | Haste | **Shatter**: crits on stunned or frozen enemies |
| Ward | Ward | Power | Haste | **Beacon**: the range bonus to neighbours grows |
| Archivist | Hasten | Power | Haste | **Chronicle**: the speed bonus reaches two tiles away |
| Mourner | Hush | Power | Haste | **Silence**: interrupts last longer and block a second special move |
| Mirror Chorister | Echo | Power | Haste | **Reverb**: the echo copies at higher power |
| Star Drake | Starfall | Power | Haste | **Constellation**: the ultimate leaves a field that keeps burning |
| Grey Veil Wraith | Drain | Power | Haste | **Wake**: the heal grows, up to a cap per wave |

## Synergies as data (T193)
A synergy is a row: `{ a, b, relation, effect }`. Relation is adjacent, same faction or same row. Starting list (PROPOSAL): Ward + any ranged unit (Ward raises range); Archivist + any fast unit (Hasten); Moth-Lantern + Gargoyle (marked enemies take Crush at +50%); Frostling + Gargoyle (a frozen enemy takes Crush crits); Mirror Chorister + Star Drake (the echo repeats a Starfall at reduced power); Mourner + Sentinel (a silenced Brass Sentinel cannot plant its feet, see [[Enemy Bible]]); Ember + Frostling (burn and chill cancel each other: a deliberate anti-synergy to teach placement); Grey Veil Wraith + Archivist (drain heal is hastened).
Not made yet: the data file (`Shared.Synergies`) and the code that reads it.

## Status effects (T194)
| Status | Source | Duration | Stack rule | Effect |
|---|---|---|---|---|
| Burn | Ember | 3 s | refreshes, does not stack | 20% of the hit per second |
| Chill | Frostling | 2 s | strengthens: up to 3 stacks, 15% slow each | slows speed; at 3 stacks becomes frozen for 0.5 s |
| Stun | Gargoyle crit, Mourner Hush | 1 s | does not stack; 5 s immunity after | stops movement and specials |
| Mark | Moth-Lantern | 4 s | refreshes | +25% damage from all sources |
| Lantern-bright | the player's lantern power | 3 s | refreshes | enemies are revealed and take +10% damage; allies in the light attack 10% faster |
Rule for all: at most one of each status per enemy, a boss halves durations and cannot be frozen, and statuses never stack by adding damage across units (they refresh). Not made: the code and the test.

## Combo system (T212)
Two familiars of the same faction standing next to each other give +8% damage each; three or more of one faction in a row (a 2 by 6 grid has rows of six) give +15%. Factions: Lantern Keepers (Ember, Moth-Lantern, Ward), Clockwork Guild (Brass Hound, Sentinel, Archivist), Hollow Court (Frostling, Gargoyle, Mourner), Star Choir (Mirror Chorister, Star Drake), Unaligned (Grey Veil Wraith). This conflicts a little with merging (merging wants identical units to touch, which is also same faction), so the bonus should be small. Not made.

## Armour types (T213)
Four armour types on enemies: brass (Brass Sentinel, Automaton), fog (Fog Wisp, Unbound), flesh (Parishioner, Thief, Crow), stone (none yet; Regent's coat could be). Damage types by familiar: fire (Ember), light (Moth-Lantern, Ward), ice (Frostling), stone (Gargoyle), cosmic (Star Drake, Mirror Chorister), spring (Brass Hound), shadow (Mourner, Wraith), brass (Sentinel, Archivist). Multipliers (PROPOSAL): brass takes 0.7 from fire and 1.3 from ice; fog takes 0.7 from stone and 1.3 from light; flesh takes 1.0 from everything except 1.2 from fire; stone takes 0.7 from spring and 1.3 from cosmic. Sentinel's Breach ignores brass armour and Wraith's Drain ignores all armour (both from the lore verbs). Not made.

## Open questions for the user
1. Replace Crit with an identity path, or keep Crit as a fourth lever?
2. Is a deliberate anti-synergy (Ember with Frostling) wanted, or only positive pairs?
3. Is armour worth the complexity at this stage, with 12 familiars and 4 enemy kinds?
