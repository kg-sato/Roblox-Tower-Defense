# Direction (2026-10-27)

Where the game goes next, written after a long discussion thread and three decision-council runs. Related: [[Game Design Doc]], [[Systems]], [[Backlog]], [[Game Redesign - Merge Academy]] (not chosen), [[Research/Game Design and Market/Competitors and Policy|Competitors and Policy]], [[Research/Game Design and Market/Merge Tower Defense Playbook|Merge Tower Defense Playbook]].

Labels: **Decided** = the user said so. **Proposed** = council or Claude suggestion, not confirmed. **Measured** = from rough bot simulations (no human data). **Guessed** = an estimate. Nothing here has been built or tested with players.

## 1. The idea
An endless tower defense run (Bloons endless style) with a light gacha on top. The gacha should add thrill when a rare familiar drops, but must not decide whether a free player can enjoy the game. Players should want to come back, and the game must not run out of ideas.

## 2. Decided
- A run ends when the crystal falls. Level, skill tree and collection are kept (meta progress). In-run coins, upgrades and placements reset.
- The player can cash out (end the run and bank the score) and pause at any time. A typical run is about 20 minutes, but long sessions must stay rewarding.
- Co-op is cut for launch. Keep run state server-side so it can be added later.
- No separate time modes yet. Run length is tuned with the wave curve. Keep the start stage and wave settings in data.
- The boss timer is dropped. A boss reaching the crystal is the check.
- Rolls are earned with free currency. Robux sells fixed-price items. **No paid random rolls at launch** (see Competitors and Policy).
- Legendary raw power is about 3.5x Common (the user's choice, to be patched after play). Legendaries also get better effects. Every familiar, even Common, gets a unique effect.
- Roster expansion and a roster revamp to fit the mystic theme (the current seven are elemental pets) are major goals.
- A 1x / 2x speed setting for gameplay, plus skippable cutscenes.
- Playtest with friends after the overnight work.
- **Theme arc (2026-10-28):** the world starts steampunk with quiet magic and grows more magical with progress; the endgame is cosmic (Lord of the Mysteries as the model). The game is split into themed sections along the way, and future sections may be less serious. Full note: [[Game Design Doc#Theme arc: steampunk magic to cosmic (Decided, 2026-10-28)]].

## 3. Proposed
- **Characters (S3 Hybrid):** account-saved collection, lobby rolls with earned tickets, duplicates level a familiar, a 3 to 4 slot loadout, and the in-run summon draws from the loadout. Build it in two stages: the collection and loadout first, the loadout-only summon second. New players start with 3 Commons.
- **Bosses:** every 5 stages, with telegraphed abilities (shield, stealth, heal) countered by familiar tags (pierce, reveal, burst, slow). Reward: a short cutscene, a ticket and a pick of 1 of 3 run boons.
- **Level-ups:** skill points plus a fixed account perk (loadout slot, ticket, cosmetic), with a "next unlock" bar.
- **Skill tree:** keep the 19 nodes. Keystones with trade-offs and a free respec only if cheap.
- **Layouts:** hand-authored lane layouts, a few per district, switched every 10 stages like dungeon floors. Check each with the sim (placeable ground in range, lane length within about 10 percent).
- **Not generic:** familiar reactions or combos, copy limits per familiar, a tap ability. Pick one or two, not all.
- **Content engine:** one fog-city district per update (enemy faction, 3 to 5 familiars, a boss). New familiars are sideways, not stronger. Old ones stay in a permanent pool. Roadmap only three updates ahead.
- **Flop plan:** keep lore and assets reusable for a second game. Decide a day-X gate (day-1 retention and session length).

## 4. The power curve problem (do this first)
- **Measured:** a Legendary at tier 1 does about 23x a Common. Each merge tier is x3.5, and a tier-5 Common (about 1,800 damage per second) beats a tier-1 Legendary (about 280). Merging, not rarity, is the real power curve.
- A 3.5x rarity cap equals exactly one merge tier, so it changes little alone. Either flatten the merge factor or apply the cap to power including tier. Open: the user has not chosen.
- Enemy HP grows x1.2 per stage, so a power multiple m buys about ln(m)/ln(1.2) stages (3.5x is about 7 stages, about 14 percent of a wall near stage 50). A free-player floor target: best Commons reach at least 70 percent of a Legendary player's stage.
- **Measured:** first Legendary arrives in about 1 to 2 minutes at about 140 gems per minute. Slow it down with tickets. The bot's 20 minute wall near stage 50 conflicts with "hours stay rewarding", so meta power must raise the wall (open).
- Going from 23x to 3.5x is a big nerf, so waves and bosses need a retune. The headless sim is the tool.

## 5. Scope (council, guessed)
The council judged the whole plan to be about 2 to 3 times a solo month. Its recommendation was MODIFY: keep the direction, cut launch scope roughly in half.
- **Launch:** 9 to 10 familiars, 2 layouts, 3 bosses, loadout and collection, ticket roll, wave-clear summary, level-up bar.
- **Update 1 or later:** 12 to 15 familiars, layouts beyond 2, daily-seed leaderboards, streaks, most reactions and active abilities, the in-run summon stage 2, long roadmap.
- **Biggest cost (guessed):** roster art and effects. About 1 to 1.5 days per Common if effects are shared parametric rigs, 2 to 3 days if hand built; Epic 3 to 4, Legendary with cutscene 5 to 6.
- **Invalidated if:** per-familiar effects cost more than 3 days each (then ship 7 to 8 familiars), the shared map cannot be isolated per player without restructuring, or the revamped 7 plus bosses already hit the day-1 target.

## 6. Order of work (logic: each item needs the one above it)
1. **Check facts:** is the map built once and shared between players? (Needs Config.PATH and MapBuilder; gates layouts.) Build a repeatable balance harness: the bot sim as a saved test that reports waves reached, gems per minute, time to first Legendary and loadout spread.
2. **Decide the curve:** merge factor vs rarity cap; re-run the harness; retune waves.
3. **Lock the schema:** ProfileStore fields for collection, duplicates and loadout (migrations after launch hurt).
4. **Run structure:** crystal-zero ends the run, cash out and pause, speed setting.
5. **Familiar framework:** an effect is a data table plus shared emitters and sound helpers. Then revamp the existing 7 to the mystic theme, each with one unique effect.
6. **Collection loop:** lobby ticket roll, duplicate levels, 3 slot loadout, starter loadout.
7. **Bosses and rewards:** 3 bosses with counters, the reward moment, level-up perks.
8. **Layout 2** (needs step 1's answer), then new familiars on the shared rigs.
9. **Playtest** with 3 or more friends; freeze scope around day 24; add day-1 retention tracking.

## 7. Overnight order (existing tasks in `Overnight/TODO.md`; nothing there was edited)
Rule: never start a task before the one it needs. Tasks marked N are new and not in TODO.md yet.
1. **T01** mirror scripts to `Studio_Export/` (needed for checkpoints and T14).
2. **N1** read-only audit of the map and `MapBuilder` (shared or per player?), result in a note. **N2** save the balance harness as a headless test (baseline numbers, no game changes). Both feed every balance decision.
3. **T02** stage, wave, boss and leak tests (before any run-end change).
4. **Settings chain, in order:** T03, then T04, then T05 (needs T04), then T06 (needs T03 to T05), then T07 and T22 (both need T05).
5. **N3** speed setting 1x / 2x (server runs two steps per tick, client reads the same speed; needs T04's validation pattern; cutscenes skippable).
6. **T14** split the reveal out of GameClient (needs T01 and T02; do it before T20, which edits the reveal).
7. **FX chain, in order:** T18 spike, then T16 kit, then T25 recipes and T26 quality gate; T19, T20, T21 and T29 after T16. Art side in parallel order: T24, then T27, then T28, then T30. T23 needs the user's asset ids, otherwise mark it blocked.
8. **Content:** T08 stage sets as data, T09 hit reactions.
9. **Lowest priority:** T10 to T13 (extra cutscenes; the council says cut boss and Legendary cutscenes beyond reusing existing ones), T17, T31.
10. **T15** hygiene check last.
**Added later the same day (at the user's request):** T35 (UI and effects quality bar with a research gate, after T33) and T36 (apply the pass to existing priority screens, after T35, T06, T16, T20 and T25). T32 to T34 are the map audit, the balance test and the speed setting (the N1 to N3 above).
**Not for overnight (needs a decision first):** the merge-versus-rarity change, run-end details (what carries over, in particular gems), the roster revamp, layouts, the collection schema. These wait for the morning.

## 8. Open questions for the user
1. Merge factor vs rarity cap: which one changes (see section 4)?
2. Launch scope: 9 to 10 familiars and 2 layouts, rest in update 1? (Pending.)
3. How long did the last signature cutscene or effect take end to end? This sets the real roster size.
4. What does "fun" mean for this game, in the user's words?
5. How does meta power raise the wall so long sessions stay rewarding?
6. Is a day-X retention gate set?
7. Gems on run end: kept, or reset? (Gems are meta progress today.)

## 9. Evidence quality
- Research on similar games was thin: mostly fan wikis, SEO guides and stats sites. No design postmortems, and no number for how much stronger a Legendary should be. Bloons' three upgrade paths are documented on its fan wiki. Roblox leaders (Anime Vanguards and similar) are described as combining gacha banners, evolution quests, many modes and frequent updates (third-party sources).
- The sim bots are crude. They cannot show fun, confusion or feel.
