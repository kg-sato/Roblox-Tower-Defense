# Engagement Loop Playbook

Researched 2026-10-24. Related: [[Roblox Success Sources]], [[UI Design Playbook]], [[Game Design Doc]], [[Backlog]], [[Analytics/Analytics Log|Analytics Log]]

## Evidence quality (read this first)

- **Solid:** Roblox's official design docs, and the Wikipedia pages for [Grow a Garden](https://en.wikipedia.org/wiki/Grow_a_Garden) and [Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot) for mechanics and player counts.
- **Weak:** the "simple low-quality games get huge" idea. I found commentary, not data. No source gave Day-1 or Day-7 retention for either game. Some analysts say Grow a Garden "doesn't typically sustain its peaks for long" (PocketGamer.biz, via Wikipedia), and one blog claims Brainrot-style games convert well at launch but retain poorly. That is one blog's opinion.
- **Takeaway:** high concurrent players show a loop that is easy to start and share. They do not prove it retains. We should measure our own retention, not assume.
- Several sources I searched (AI-written "skills" pages, SEO blogs) were low quality and are not used as facts here.

## What the two giants have in common

| | Grow a Garden | Steal a Brainrot |
|---|---|---|
| Loop | Plant, wait, harvest, sell, buy better seeds | Buy from conveyor, earn income over time, steal/defend, buy rarer |
| Understood in | Seconds | About 30 seconds (per a commentator) |
| Time pressure | Crops grow, even offline; rotating stock | Income ticks up; shield timer |
| Social hook | Gifting, trading, stealing crops (Robux) | Stealing from and defending against others |
| Progress | Visible garden growth, rarer seeds | Rarer characters, rebirth |
| Live ops | Weekly exclusives and named updates (needs you online) | "Admin abuse" events, cross-game events, concert |
| Monetization | Pets from loot boxes, Robux to speed up waiting | Robux items, bought "admin" powers |

Peak concurrent players (Wikipedia, cited per page): Grow a Garden about 22.3M (Aug 23, 2025); Steal a Brainrot 24M (Sep 13, 2025) and 25.4M (Oct 2025). Brainrot was reported to have licensed a Fortnite version and a film adaptation.

## The loop, as a design pattern

Source: [Core loops](https://create.roblox.com/docs/production/game-design/core-loops) (official) plus a third-party description of simulators.

Official definition: a core loop has (1) minute-to-minute interaction, (2) the most repeated set of actions, and (3) a progression engine that moves players forward. Without the engine the game gets repetitive and shallow.

Layering (third-party guide, [creation.dev](https://www.creation.dev/pt/glossary/simulator), unverified): primary loop about 30 s to 2 min, secondary loop (unlock a zone, buy an upgrade) over a session, tertiary loop (rebirth/prestige, collection) over days.

**Design the loop as three questions:**
1. What does the player do every 10 seconds? It must feel good by itself (sound, number pop, animation).
2. What do they spend the reward on every 2 minutes? There must always be something affordable and something slightly out of reach.
3. What do they come back for tomorrow? A timer, a daily, an event, a friend, a rare thing.

## Why these loops hold attention

Each point is tied to a source; my interpretation is labelled.

1. **Instant start, low friction.** Roblox players hop between games and favour variety; get them into the fun fast, keep tutorials short and visual, use familiar genre conventions ([Design for Roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox)).
2. **Early wins.** Keep early XP thresholds low so players level up quickly; give enough starter currency to enjoy it; end onboarding with a joyful moment ([Onboarding](https://create.roblox.com/docs/production/game-design/onboarding)). Roblox's own discovery data counts first-play bounce (under 60 s) as a negative signal ([Discovery](https://create.roblox.com/docs/production/promotion/discovery)).
3. **Layered goals.** Short (one session), mid (days), long (months) goals visible in the UI ([Quest design](https://create.roblox.com/docs/production/game-design/introduction-to-quest-design)).
4. **Dailies.** Short, simple, finishable in one session, with steady soft-currency rewards. Rotate them. This is what the discovery system measures as "play days per user."
5. **Waiting that progresses without you.** Grow a Garden crops grow offline; Brainrot income ticks. (My interpretation: this makes returning feel rewarding and gives a reason to check back.)
6. **Scarcity and live events.** Limited-time content "incentivizes players to engage" and gives prestige ([LiveOps essentials](https://create.roblox.com/docs/production/game-design/liveops-essentials)). Roblox suggests a cadence of roughly weekly to monthly, built on systems that already exist.
7. **Social pull.** Players often join with friends; co-play days are a discovery signal. Trading, gifting, parties, and shared goals give people a reason to invite others.
8. **Visible progress.** A growing garden, a bigger number, a rarer item, a newly unlocked area. Make progress something you can see and show off.
9. **Constant feedback.** Respond to every action with sound, animation, and numbers ([UI and UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).

## Economy rules (so the loop doesn't break)

Source: [Balance virtual economies](https://create.roblox.com/docs/production/game-design/balance-virtual-economies).
- For every source of currency, plan a matching sink. Otherwise rare things lose value.
- Estimate event impact before launch: reward value x drop chance, summed, times expected daily activity. Compare with a normal day.
- Use a separate event currency that only buys event shop items, to protect the main economy.
- Tune live with Roblox Configs and test prices with Experiments.

## Monetization that doesn't poison the loop

Sources: [Monetization foundations](https://create.roblox.com/docs/production/game-design/monetization-foundations), [Contextual purchases](https://create.roblox.com/docs/production/game-design/contextual-purchases).
- Fix retention first, then monetize (official DevForum guidance, see [[Roblox Success Sources]]).
- Offer value players can feel. Place offers at natural progression moments. Keep it fair and transparent.
- Both giants were criticised for it: Grow a Garden for excessive monetization, Steal a Brainrot as pay-to-win ("the best items are only available for cash," per Polygon via Wikipedia). Their popularity shows it didn't stop growth, but it is a reputational and policy risk for us.
- **Paid random items (loot boxes) and trading have official rules:** every outcome and its real odds must be shown before purchase, percentages must total 100%, and regional restrictions apply. See [[Competitors and Policy]]. Suggested: skip them at launch.
- Our audience is young. Prefer designs where Robux saves time or adds expression, not designs built around pressure or fear of missing out.

## Plan for our month (suggested)

1. Pick a loop that can be explained in one sentence and played in 10 seconds. Write it in [[Game Design Doc]].
2. Prototype only the 10-second action and the first 2-minute purchase. Playtest with a few people before adding anything else ([Prototyping](https://create.roblox.com/docs/production/game-design/prototyping)).
3. Build onboarding: first reward within 30 seconds, first upgrade within 2 minutes, a visible next goal at all times.
4. Add one daily reward and one 3-item daily quest set.
5. Add one waiting mechanic (timer or offline growth).
6. Publish with a custom thumbnail and accurate title ([Discovery](https://create.roblox.com/docs/production/promotion/discovery)).
7. Watch in [[Analytics/Analytics Log|Analytics Log]]: Day-1 retention, bounce under 60 s, session length. Use the Player Funnel to find where players quit.
8. Ship a small update on a regular cadence.

## Gaps

- No retention figures for any of these games; need our own data.
- Did not read: Roblox analytics pages, Content updates, Contextual purchases in full, Prototyping in full, Roblox paid-random-item policy.
- Other popular "simple" games (Blox Fruits, Brookhaven, Adopt Me) were not analysed.
