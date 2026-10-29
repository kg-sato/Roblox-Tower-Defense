# Content plans: quests, battle pass, challenges, fusion, friend invites (T217, T218, T222, T224, T226)
Design written 2026-10-29. All PROPOSAL; nothing is implemented. Currencies: gems (10 per roll), coins (in-run), skill points (rare). Rules from [[Progression Rules]]: cosmetic-only paid content, no paid random items, no fake countdowns.

## Twenty quests (T222)
Daily quests (3 shown per day, drawn from the 10 below; each pays gems and a battle-pass XP chunk):
D1 Roll 5 familiars (15 gems). D2 Merge 3 times (15). D3 Clear 3 stages (20). D4 Defeat a boss (30). D5 Finish a stage with no leaks (25). D6 Place a familiar from each of 2 factions in one run (20). D7 Upgrade any familiar to level 3 (15). D8 Use the lantern power twice (20, needs T211). D9 Recycle 2 units (10). D10 Reach a perfect streak of 5 (25).
Story quests (one-off, each unlocked by a story beat; reward gems plus a lore fragment): S1 Light the first lamp on Lampwick Lane (clear stage 1). S2 Meet the Unbound (reach stage 5). S3 Cross the Harbour (clear stage 10). S4 Find the child's lantern (reach stage 12). S5 Sing with the Choir (clear stage 15). S6 Ring the Foundry bell (reach stage 18). S7 Look behind the clock (clear stage 20). S8 Climb above the grey veil (reach stage 21). S9 Wake the apprentice's lamp (reach stage 24). S10 Turn the clock (clear stage 25, the ending).
Rewards stay small against the economy: a day of three dailies is about 60 gems (6 rolls); story quests total about 300 gems and 2 skill points over the whole game.

## Quest tracker in the HUD (T223)
Not designed here (UI is owned by the UI chat): one line, collapsible, showing the one pinned quest and its progress.

## Battle pass, 40 levels, cosmetic only (T224)
XP comes from quests and stage clears, about 100 XP a level (PROPOSAL), 40 levels take about 4 weeks of casual play. Free track: gems at levels 5, 10, 15, 20, 25, 30, 35, 40 (20 gems each); lantern colour variants at 8, 24 and 32; a title card at 12 and 36; a frame at 16. Premium track (cosmetic only, no power, no gems for a pay-back loop): trainer outfit variants (4 from [[Trainer Outfit]]) at levels 1, 10, 20, 30; familiar palette skins (alternate colours, no stats) at 5, 15, 25, 35; a loading-screen eye variant at 40; emotes at 3, 13, 23, 33; frames and title cards on the other multiples of 4. The final reward is a golden lantern trail. Every item is cosmetic; the premium track never gives gems, rolls, skill points or stat changes.
Not decided: the Robux price (the user decides), whether late-joining players can buy past levels (recommend no).

## Challenge stages (T217)
Five fixed-rule stages, each unlocked by clearing a boss; clears give a one-time cosmetic and 40 gems. 1 **Single File** (unlocked after boss 1): only 6 slots. 2 **Brass Only** (boss 2): only Common familiars may be placed. 3 **Quiet Hour** (boss 3): no abilities or ultimates. 4 **Furnace Run** (boss 4): enemies are 50% faster and 30% fewer. 5 **Backwards Clock** (boss 5): the path is mirrored and the Clockmaker un-merges one unit every wave. Rules as data (a table of modifiers) so they reuse the wave modifiers of T215.

## Fusion (T218)
The task says a tier 8 familiar can fuse into a legend, but the game's tier cap is 5 (`TIER_MAX`) and the design doc says 5; there is no tier 8. Recommendation: fuse at the cap instead: two different tier-5 familiars of the same faction fuse into one Legend variant (a recoloured and re-crowned version with a combined role, for example Ember plus Moth-Lantern becomes a Keeper's Lamp that scorches and marks). Rules: costs both units, one fusion per run, the Legend counts as Legendary rarity, cannot be fused again, shown in the collection as a gold-framed entry. Needs the user's decision on the tier number and on whether fusion is wanted at all (it adds 20 or more new designs).

## Friend invites (T226)
Use Roblox's own invite prompt (`SocialService:PromptGameInvite`, after `CanSendGameInviteAsync`; API names from memory, UNVERIFIED here), so the platform handles consent and the player picks the friends. Rules: only from a button the player presses, never automatically; at most one prompt per player per day; no reward for sending, a small reward (30 gems) only when an invited friend finishes the tutorial, up to 5 friends a week, once per friend, checked on the server. No pop-ups, no counters that pressure.

## Open questions for the user
1. Is the 10 plus 10 quest set a good size?
2. Battle pass price and whether to ship one at all in v1.
3. Fusion at tier 5 instead of tier 8, or no fusion.
