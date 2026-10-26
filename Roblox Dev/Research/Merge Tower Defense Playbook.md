# Merge Tower Defense Playbook

Researched 2026-10-24. Related: [[Game Design Doc]], [[Systems]], [[Competitors and Policy]], [[Animation and Juice Playbook]], [[Low-End Device Playbook]], [[Dev Process Playbook]]

## Source quality (read this first)
- **Good for engineering:** DevForum threads on tower defense enemy systems and the community framework [jTDF](https://devforum.roblox.com/t/jtdf-high-performance-tower-defense-framework-parallel-luau/4061864). Numbers there are one developer's own tests, not guarantees. Re-measure in our game.
- **Weak for design:** the search results on merge tower defense economy were mostly SEO pages and game-jam entries ([MayonMergeTD](https://kohf1.itch.io/mayonmergetd), [NeoDefense](https://kazerdous.itch.io/neodefense), [game-ace article](https://game-ace.com/?p=11664)). Treat them as examples of ideas, not proof.
- **Not found:** postmortems or GDC talks on a successful merge TD, and any independent analysis of Tower Defense Simulator. Anime Vanguards data comes from fan guides and a stats aggregator ([rowatcher](https://rowatcher.com/games/5578556129)), including a revenue estimate that is a model output, not a reported figure.
- Everything under "Our rules" is my synthesis. It is a hypothesis to test in playtests, not a verified fact.

## What the sources say
- Economy: too much money removes the challenge, too little frustrates. Late-game upgrade costs can outrun income, which pushes players toward income units and supports.
- Scaling: unit power should keep pace with enemy strength, otherwise early units are trivial or late units useless. Vary enemy types inside a wave to avoid stale patterns.
- Merge specifics seen in examples: summon price rises as the match goes on, a hard cap on top tier (14 in one entry), random summon plus merge of matching units.
- Synergy: slow + splash + armor-shred combine into kill zones; support units (buffs, discounts) become near-essential on hard modes.
- Roblox TD engineering: keep enemies as **data on the server** (position along path as a number), not Humanoids. Humanoid state checks are the usual bottleneck. Update logic at a fixed tick (0.1 to 0.2 s for targeting), replicate lightweight state, render on clients. Parallel Luau Actors help beyond a few hundred enemies; we likely don't need it for a mobile-friendly cap.
- Anime Vanguards style: rotating banners, listed odds (fan guide: 75.5 / 20 / 4 / 0.5 / 0.004 %), 50 gems per roll. This is the paid-random model, which our policy decision excludes (see below).

## Our rules (hypotheses)
1. **Path follow by distance, not pathfinding.** One fixed lane of waypoints. Enemy = `{id, type, hp, dist}` on the server. Position = interpolate along path. Cheap, deterministic, testable.
2. **Server sim at 10 Hz, client render at frame rate.** Server sends spawn events and periodic snapshots; client interpolates movement itself from `speed` and spawn time. Kills and damage are server decisions.
3. **Hard caps:** about 60 live enemies, about 24 units on the grid, pooled projectiles and damage numbers. Cap particles on low-end devices (see [[Low-End Device Playbook]]).
4. **Merge rule:** 3 identical units (same pet, same tier) merge into one of the next tier. Merge happens on the server after a drag-drop request; client animates optimistically but reverts on rejection. Tier cap 5 for launch.
5. **Economy loop inside a match:** kills give coins; summon cost rises each summon; a merge frees a slot and is always the best "free" power spike. Always show "next summon cost" and a one-tap summon button.
6. **Difficulty = quality of mobs, not just HP.** Normal, Hard, Nightmare worlds add enemy modifiers (armored, swift, regenerating, shielded), elite versions with auras, and mini-bosses. Boss every 10 waves with a telegraphed ability.
7. **Ultimates:** each pet has a charge bar filled by kills; manual tap fires a big animated effect. Gives mobile players a thing to do every 10 seconds.
8. **Instant gratification:** first merge inside 30 seconds, first boss inside 3 minutes, first crate inside 2 minutes. Matches should last 8 to 12 minutes.
9. **Repeatability:** each run grants shards and crates; shards level pets permanently; harder worlds unlock by clearing earlier ones; daily quests and a daily free crate.

## Monetization (matches [[Competitors and Policy]])
- **Decision needed and recorded 2026-10-24:** the request says "gacha / lootbox effects" and "monetization from cheap, better quality pets". The vault policy is no paid random items. Resolution used here: **gacha effects on crates opened with free, earned currency (no odds disclosure required, still show odds); premium pets sold at a fixed Robux price (dev products or passes), deterministic.** Paid random crates stay out of launch.
- Pets are better in quality, not exclusive win buttons: premium pets reach the same ceiling as free pets but start stronger and look better. Free players can earn comparable pets through crates.
- Re-read the full paid-random-items page before ever adding a paid crate.

## Open risks
- Merge feel depends on drag-drop on touch; test early on the Device Emulator.
- Balance can't be verified without many runs. Plan: a headless balance simulator (pure-Luau module) that plays waves with a bot and prints clear rates per wave.
