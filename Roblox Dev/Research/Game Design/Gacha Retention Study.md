# Gacha Retention Study

Date: 2026-10-30. What Honkai: Star Rail (HSR), Arknights: Endfield, Reverse: 1999 (R1999) and Limbus Company do to bring players back daily, and what to take for our merge tower defense. Related: [[Game Design Doc]], [[Progression Rules]], [[Familiar Systems]], [[Content Plans]], [[Engagement Loop Playbook]], [[Summon References]] (reveal staging, already studied: not repeated), [[Competitors and Policy]], [[Payments and Robux]], [[Research/Index|Research Index]].

## Evidence quality (read first)
- Sources are guide sites and fan wikis. No developer interview or GDC talk on daily-loop design was found for these four games (searched; HSR's only dev interview found covers class design, not retention). So "why it works" statements are **inference**, marked (Inf). Numbers are **Reported** by the cited page; fan guides disagree on soft-pity starts, so treat as approximate.
- Fandom wikis and Prydwen returned 402/403, so the Endfield, R1999 and HSR numbers come from search summaries plus one fetched page each where it worked. Re-check in game before copying any figure.
- Reveal staging and skip buttons were not verifiable from text sources; those rows are **Unverified (from general knowledge)**. Our own frame study of HSR's reveal is in [[Summon References]].

## 1. Per-game summon anatomy

| | HSR | Endfield | R1999 | Limbus |
|---|---|---|---|---|
| Banners | Character event, Light Cone event, Standard, Departure (50 pulls, new players) | Chartered (limited) character, Standard, New Horizons (beginner, 40-pull guaranteed permanent 6-star), weapon "Arsenal" banner | Standard, limited pick-up, selector/rerun | Standard, Target (new Identity/EGO, Sinner, Faction), quarterly Walpurgis Night, New Manager's Welcome |
| Pull currency | Stellar Jade -> Star Rail (Special) Pass | Oroberyl (500 a pull, 5,000 a 10-pull), HH Permits; weapon pulls use Arsenal Tickets (1,980 per 10) | Clear Drops (180 = 1 summon); Crystal Drops convert 1:1 | Lunacy (130 a pull, 1,300 a 10-pull), Extraction Tickets |
| Top-rarity pity | Hard 90 (char), 80 (Light Cone); soft about 74 | Soft 65 (+5% per pull), hard 80 | Hard 70; soft about 60 | Standard banner: none. Limited: **Ideality**, 1 per pull, spend 200 on a chosen featured unit |
| Featured guarantee | 50/50, then guaranteed (carries across banners, per one guide); Light Cone 75/25 | 50/50 on 6-star; featured guaranteed at pull 120, once per banner, no carry; dupe token at 240 | Featured guaranteed within two 6-stars (one source) | Chosen pick at 200 Ideality; unused Ideality becomes Thread at banner end |
| Multi-pull | x10 | x10; beta page says ten singles equal one ten-pull | not verified | x10 guarantees one 2-star Identity or better; 3-star-assured ten-pull ticket |
| Counter on screen | Warp history; pity visible in tracker (Reported by guides) | Remaining-pulls counter on the banner for the 10-pull guarantee (beta wiki) | not verified | Ideality shown as a spendable number |
| Dupes | Eidolons (see section 3); extra copies also give Undying Starlight (5-star: 40, then 100 after E6) | Potential; a beginner guide calls it "not aggressive" (single opinion) | Insight/portrait (not verified) | EGO leaves the pool once owned; dupe Announcers -> 50 Thread Crates; Identity dupes -> shards |

Sources: [Siliconera HSR pity](https://www.siliconera.com/heres-how-to-calculate-pity-in-honkai-star-rail/); [AFK Gaming HSR](https://afkgaming.com/mobileesports/guide/honkai-star-rail-pity-system-explained-rates-soft-pity-hard-pity-and-more); [Endfield wiki.gg Headhunting (beta)](https://endfield.wiki.gg/wiki/Beta_Test:Headhunting); [Dexerto Endfield pity](https://www.dexerto.com/wikis/arknights-endfield/arknights-what-is-pity/); [KeenGamer Endfield](https://www.keengamer.com/articles/guides/arknights-endfield-complete-gacha-system-guide/); [Dot Esports Endfield](https://dotesports.com/arknights-endfield/news/arknights-endfield-gacha-system-explained); [HostedGG R1999](https://hostedgg.com/wiki/reverse-1999/gacha-pity-system); [Prima R1999](https://primagames.com/tips/reverse-1999-pity-system-and-banners-explained); [Limbus wiki Extraction](https://limbuscompany.wiki.gg/wiki/Extraction). Search date 2026-10-30. Conflicts: Endfield pity carry-over is described differently by Dexerto and another guide; Limbus pity was called "effectively pity-free" by one 2026 guide but the wiki documents Ideality (use the wiki).

### What the table says (Inf)
1. Every game shows one **number toward a promise** (pulls to guarantee, remaining pulls, Ideality). The promise is the retention hook: "one more session gets me there".
2. Two guarantee layers: top rarity by N, then featured by M. Limbus replaces luck with a **spendable** counter (200), the most transparent and the most child-safe.
3. Currency is split: premium-adjacent "soft" currency (Jade, Oroberyl, Lunacy) converts to tickets. One pull-currency per screen is enough for us.
4. Banner switching is a left or top tab list; the pity state is per banner family.

### Recommended layout: separate Summon menu for this game (moving the Roll button out of the HUD)
Landscape phone baseline 844x390. Opened from a round Victorian-object button (not the HUD roll button). Same modal pattern as other menus (dim, panel, X top-right).

```
+------------------------------------------------------------------+
| [Lampwick Draw] [Set Banner]  tabs        gems 240  [Rates][Log]  X |
|------------------------------------------------------------------|
| banner art: tarot table +      | PITY RING: "Epic or better in 7"|
| featured familiar of the set   | "Legendary chance 2%" (Rates)    |
|                                | Skip [x]   Auto-10 [ ]           |
|                                |  [ Roll x1  20 ]  [ Roll x10 200 ]|
+------------------------------------------------------------------+
```
- **Pity ring beside the buttons**, never hidden behind a tap. Text states the rule in words ("Guaranteed Epic or better every 20 rolls"). The ring reads the same `Config` table as the roll (single source, already our rule).
- **Rates** is a labelled text button, not a bare (i): Roblox's own policy requires a labelled button when odds are not inline ([Roblox paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items), fetched 2026-10-30). Not strictly required for us (earned gems), kept anyway.
- **Roll x10** shows total cost on the button; a **cost confirmation only above a threshold** (e.g. 10 rolls) to avoid a double-tap spend. Failing a roll for lack of gems opens "how to earn gems" not a store.
- **Reveal flow:** result -> existing egg/tarot staging ([[Summon References]]) -> **summary grid** of all 10 (NEW and Duplicate badges) -> Tap anywhere to continue. **Skip** is persistent (setting + per-roll), not hidden; Common/Rare already shorten with Quick Roll.
- **History** list (last 50 rolls, rarity and time) next to Rates: transparency, cheap (S).
- **Banner tabs**: tab 1 permanent. Tab 2 only if we add a set banner (section 3). No limited-time countdown on tabs.
- On the HUD leave a small summon-ready indicator only (gems >= roll cost), no pulsing red badge.

## 2. Daily, weekly, progression, mid-session (what the four do)
| Layer | Reported | Source |
|---|---|---|
| Stamina | HSR Trailblaze Power: 1 per 6 min, cap 240 (guide) / 300 (wiki, later patch); 1.3 added Reserved TP so overflow banks | [HostedGG](https://hostedgg.com/blog/honkai-star-rail-daily-weekly-checklist-guide), [PCInvasion 1.3](https://www.pcinvasion.com/quality-of-life-changes-detailed-for-honkai-star-rail-version-1-3/), [Fandom via search](https://honkai-star-rail.fandom.com/wiki/Trailblaze_Power). Endfield Sanity: unspent is lost; Sanity Essence restores 120 ([Dexerto](https://www.dexerto.com/wikis/arknights-endfield/arknights-endfield-sanity-explained), [DTGRE](https://www.dtgre.com/2026/01/arknights-endfield-daily-tasks-routines-guide.html)). Limbus Enkephalin is the "only hard stamina limit" ([HostedGG](https://hostedgg.com/blog/limbus-company-luxcavation-thread-farming-guide)) |
| Daily meter | HSR Daily Training to 500 points = chest; v1.6 made tasks easier. Endfield Daily Activity capped at 100 | [Siliconera 1.6](https://www.siliconera.com/how-much-has-daily-training-improved-in-honkai-star-rail-version-1-6/) |
| Weekly | HSR Echo of War 3 discounted clears, lost if skipped; Mondays; Nameless Honor weeklies. Limbus 3 bonus Mirror Dungeon charges per week | HostedGG above |
| Biweekly | HSR Memory of Chaos / Pure Fiction / Apocalyptic Shadow: large Stellar Jade payouts per cycle | HostedGG above |
| Login events | R1999: 3.2 offered 30 free pulls; 2.5th anniversary up to 100 free pulls via 10 days of login; 20 days login = 20 pulls | [Reverb](https://reverbinc.com/newsletters/reverse-1999-a-flowing-feast-update-serves-massive-rewards/), [Sportskeeda](https://sportskeeda.com/mobile-games/reverse-1999-version-2-5-update-1-5th-anniversary-free-rewards-new-events-banners) |
| Duplicates | HSR Eidolons can double output or add almost nothing; duplicates give Undying Starlight convertible to pulls | [ProGameGuides](https://progameguides.com/honkai-star-rail/honkai-star-rail-eidolons-what-are-they/), [Pushsquare](https://www.pushsquare.com/guides/honkai-star-rail-how-to-get-undying-starlight) |
| Story | not verifiable from these sources (no pacing data found); general knowledge: chapter per patch, ~6 weeks (Unverified) | n/a |
| Monetisation | Limbus: Paid Lunacy needed at the Dispenser, 2,600 Paid Lunacy for a Pass EGO ([wiki](https://limbuscompany.wiki.gg/wiki/Lunacy) via search). Endfield/R1999 monthly card/pass: **not found** | n/a |

(Inf) pattern: a **daily floor** (small, finishes in minutes), a **weekly deadline** (miss it, lose it: the strongest return driver and the biggest dark-pattern risk), and an **optional endgame cycle**. Limbus players call the stamina the one hard limit and warn against letting it sit at cap: capped stamina is a loss-aversion timer.

## 3. Ten retention mechanics, ranked by fit for a merge tower defense
Fit = does it use what a merge TD already has (short runs, gems, grid, stages) without needing new content volume.

| # | Mechanic (seen in) | Fit | Why |
|---|---|---|---|
| 1 | Visible pity ring + guarantee text (all four) | Very high | Already built (pity 20); it is UI only |
| 2 | Daily ladder, missed day pauses (R1999 logins, HSR) | Very high | Spec exists in [[Progression Rules]] |
| 3 | Best-stage / set-clear milestone rewards (HSR first clears) | Very high | Natural to endless stages; `bestStage` proposal exists |
| 4 | Weekly discounted boss run (HSR Echo of War, Limbus bonus charges) | High | Reuse the five bosses; but see guardrails (no forfeiture) |
| 5 | Daily task meter with milestone chest (HSR Daily Training 500) | High | Tasks = merges, boss kills, rolls; quests flag exists |
| 6 | Duplicates -> permanent small power (Eidolon, Potential), plus conversion to currency | High | Duplicates are inevitable with 20 familiars; avoid required |
| 7 | Rotating challenge stage with fixed rules (HSR Memory of Chaos) | Medium-high | Merge puzzle with constraints = good fit; needs content |
| 8 | Stage-set lore drip (all four story chapters) | Medium | Five sets x five stages already; Clockmaker mystery in [[The Clockmaker]] |
| 9 | Banked energy (HSR Reserved TP, Endfield Sanity) | Medium | We have no stamina; copy only the "never lost" part as banked daily rolls |
| 10 | Limited-time rate-up banners / anniversaries (Limbus Walpurgis, R1999) | Low | Rotating scarcity needs live-ops team and is the riskiest pattern for kids |

Not adopted: stamina caps (runs are the game) and a paid pass with gacha currency. The chosen-pick counter (Limbus Ideality) is adopted as proposal P2.

## 4. Proposals for THIS game
Effort S = under a day, M = a few days, L = a week or more. Risk = chance it hurts balance, kids' safety or build time.

| ID | Proposal | Maps to | Effort | Risk |
|---|---|---|---|---|
| P1 | **Summon menu** with pity ring, labelled Rates, History, Skip, x10 and summary grid (layout above) | Config rolls, odds panel, existing reveal | M | Low; UI-only if rules unchanged |
| P2 | **Chosen guarantee (Ideality-style):** every roll adds 1 "Lantern Oil"; at 100 pick one familiar of Rare+ from the roster. Resets nothing, unspent never expires | `Config`, collection set, save TEMPLATE field | M | Low-Med; economy needs the bot run in [[Balance Baseline 2026-10-29]] |
| P3 | **10-roll floor:** each 10-roll guarantees one Rare or better (Endfield/Limbus pattern) | `MatchSim.pickRarity` | S | Low |
| P4 | **Daily ladder and 3 daily tasks with a progress chest** (merge 5 times, clear stage, roll 3) | daily ladder spec, quests flag (overnight) | M | Low; no penalty for missing |
| P5 | **Best-stage record rewards** (gems per new stage, set-clear lore card) | `bestStage` proposal | S | Low |
| P6 | **Weekly Bell Tower:** one boss rush per week, three attempts, rewards skill points; a missed week costs nothing (rewards stay claimable until next week's) | Boss Framework, skill tree | M | Med; balance of repeatable boss |
| P7 | **Familiar Bonds (duplicates):** extra copies fill a bond bar, 5 small steps (+3% to +15% per familiar), max one extra effect; surplus becomes gems at 10 per copy | Bond module (overnight flag), collection | M | Med; must not make dupes feel mandatory |
| P8 | **Clockmaker's Diary:** one lore card unlocked per stage set cleared and per bond step | [[Stage Set Lore]], collection index | S-M | Low; also a story hook |
| P9 | **Rotating Rule Stage (Memory of Chaos style):** fortnightly stage with a twist (no Recycle, double enemies, only Common familiars); reward cosmetic + skill points; rules visible, no timer | Config stage modifiers, leaderboard | L | Med-High; content and bot testing |
| P10 | **Themed season skins** by arc (steampunk to cosmic), cosmetic only; free track earnable by play | UI Kit, [[Trainer Outfit]] | L | Med |
| P11 | **Rested bonus:** time away banks up to 24 h of extra gem income on the next run; never expires beyond cap, shown as "rested" not "wasted" | save, MatchService | S | Low (cap abuse) |
| P12 | **Mid-session hooks:** mini-goal strip under HUD ("2 merges to Bond step"), boss telegraph, a mid-run chest every 5 stages | HUD, quests | S-M | Low |

Suggested order: P1, P3, P5, P4, P8, then P2, P7, P11, P6; P9 and P10 after launch metrics.

## 5. Ethical guardrails (audience includes children, 9 to 16 assumed)
Project rules: never sell gems, luck or tier cap; pity and odds always visible; no dark patterns.

**Evidence base**
- Roblox treats paid random items (eggs, chests, gems used on them, luck boosts, pity systems) as regulated: odds must be shown before purchase, boosted odds must update, and some users are restricted by `PolicyService` ([Roblox policy](https://create.roblox.com/docs/production/monetization/paid-random-items), fetched 2026-10-30). Our gems are earned only, so we stay outside by design; selling gems or luck later would put us inside.
- In January 2025 the FTC settlement with Cognosphere (Genshin Impact) for $20 million alleged obscured loot-box costs and misleading odds, and barred purchases without parental consent for under-16s; the company did not admit wrongdoing ([Esports.gg](https://esports.gg/news/genshin-impact/cognosphere-hoyoverse-settles-with-the-ftc-for-20-million-over-unfair-loot-box-marketing-targeting-minors), [PocketGamer.biz](https://www.pocketgamer.biz/hoyoverse-agrees-to-20-million-settlement-with-ftc-over-loot-boxes); press coverage, not the FTC text). Treat as a signal of regulator attention on children plus gacha.

**Rules**
1. Gems are earned only; no Robux path to gems, rolls, pity, luck or tier cap. Cosmetics only for Robux, fixed price, shown in Robux.
2. Pity and Rates inline on the Summon menu; the odds shown equal the server table; show the history.
3. Pity never resets on banner change; no "expires" counters. (Endfield's per-banner 120-pull reset and Limbus's expiring Ideality are what to avoid; we convert leftovers to something useful instead.)
4. Missing a day or week costs nothing. Streaks pause, not reset (already in [[Progression Rules]]).

**Avoid, and why**
| Mechanic | Seen in | Why avoid |
|---|---|---|
| Stamina that caps and is lost | HSR, Endfield | Loss-aversion timer; HSR itself raised its cap and added Reserved TP after complaints (PCInvasion 1.3 above) |
| Weekly clears that vanish if missed | HSR Echo of War | FOMO; use "claimable until next reset" |
| Limited-time exclusive units | Limbus Walpurgis, R1999 | Fake scarcity for kids; rotate only cosmetics, put old items in a permanent shop |
| Countdowns on purchases, "last chance" sales | genre | Pressure on minors; none |
| Pass that sells gacha currency | genre | Pays for luck; breaks rule 1 |
| Variable-ratio daily spin that nudges purchase | genre | Habit-forming; our dailies are fixed |
| Pulsing red badges for unclaimed rewards | genre | Guilt; use a calm static dot |
| Streak-loss shaming, "your friends played" nags | genre | Social pressure |
| Pay-to-skip a run or pay-to-revive | genre | Sells progress |
| Hiding rarity odds behind an (i) icon | many | Roblox requires labelled button |

**Also**: no chat or trade surfaces tied to rolls; default Auto-Roll cap (stop at 50 rolls unless re-enabled); and a "take a break" nudge after 90 minutes is optional (our idea, Unverified benefit).

## Gaps and next checks
- Find developer commentary (GDC Vault, HoYoverse or Gryphline dev blogs) on stamina and daily design; none found.
- Verify R1999 portrait/insight and Endfield monthly card in game.
- Run [[Balance Baseline 2026-10-29]] with P2/P3/P7 before changing `Config`.
- User decisions needed: P2 (chosen guarantee, 100 oil), P3 (10-roll floor), whether Bond duplicates are acceptable.
