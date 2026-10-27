# Master Plan

Written 2026-10-24. Related: [[Concept Pitches]], [[Backlog]], [[Systems]], [[Analytics/Analytics Log|Analytics Log]], [[Research/Game Design and Market/Roblox Success Sources|Roblox Success Sources]], [[Research/Game Design and Market/Engagement Loop Playbook|Engagement Loop Playbook]], [[Research/UI/UI Design Playbook|UI Design Playbook]], [[Research/Game Design and Market/Competitors and Policy|Competitors and Policy]]

**Goal:** a published Roblox game in four weeks that new players understand in seconds and want to come back to. "Success" in month one means good retention and session length against Roblox's own similar-game benchmarks in Creator Analytics, not a big player count. Numbers from blogs are not targets.

**Decisions so far (2026-10-24):** pick from three original pitches; Studio connected through the official plugin; only you playtest at first; two fixed-price passes at launch; no paid random items, no trading.

> **Update 2026-10-24: concept changed to a merge tower defense ([[Game Design Doc]]). The weekly lists below still name Shell Shore items; the week structure stays (loop, reasons to return, ship, measure) but the content is replaced by the vertical-slice-first order in [[Backlog]] and the process in [[Dev Process Playbook]]. Rewrite this plan once the vertical slice exists.**

## How we split the work

| Claude | You |
|---|---|
| Design docs, all Luau code, UI, building in Studio, 3D models with Hunyuan3D, tests, security review, updating this vault | Playtest every build and tell me what felt bad or confusing |
| Run playtests in Studio and read console errors | Approve thumbnails, name and description |
| Write the passes and the shop code | Create the passes in Creator Hub and give me their IDs |
| Prepare the publish checklist | Click Publish, set the game public, check the real device |
| Analyze the numbers you paste in | Copy weekly numbers from Creator Analytics into [[Analytics/Analytics Log|Analytics Log]] |

Rule: I never publish, buy, or change account settings without your yes.

## Principles (from the research)

1. **Retention first.** Players who leave in under 60 seconds hurt discovery most. First reward in 30 s, first upgrade in 2 min, always a visible next goal.
2. **One loop, done well.** Prototype only the 10-second action and the first purchase before anything else.
3. **Server is the boss.** Currency, rewards, purchases, cooldowns and timers all live on the server. The client only shows things.
4. **Mobile first.** Design the phone layout first, test with the Device Emulator.
5. **Feedback on everything.** Sound, motion, and number pop-ups for every action.
6. **Measure, don't guess.** Log key events from day one so the Player Funnel shows where players quit.
7. **Small and safe.** Free random drops only, passes that save time rather than gate fun, honest titles and thumbnails.

## Week 1: the loop (days 1 to 7)

Done when: you can join, scoop shells, sell, buy a bucket upgrade, leave, and come back with progress saved.

- Connect Studio to Claude and confirm with a test (see Backlog).
- Write the style guide: 3 colors, 1 font, corner radius, button states.
- Build: spawn beach, shell spawner, bucket, sell shop, first upgrade tier.
- Data saving with ProfileStore; currency and upgrades validated on the server.
- HUD: currency counter, bucket bar, one Shop button, next-goal banner.
- Sound and number pop on pickup.
- Add analytics events: joined, first pickup, first sale, first upgrade, left.
- Gate: solo playtest. Can a stranger know what to do within 10 seconds, with no text tutorial?

## Week 2: reasons to return (days 8 to 14)

Done when: there is a reason to come back tomorrow and a reason to stay 15 minutes.

- Zones 2 and 3 with rarer shells and 24 shells in the collection Index.
- Daily reward and a 3-item daily quest set.
- Tide timer with a low-tide rare cove (the live event rhythm).
- Onboarding: highlight, dim, arrow, end with a joyful moment.
- 3 easy early badges.
- 3D shells, crab, and props from Hunyuan3D, under 3,000 triangles each.
- Server size 6 to 8; rarest-shell board.
- Gate: playtest full 15-minute session, then a return visit next day.

## Week 3: ship it (days 15 to 21)

Done when: the game is public with an honest thumbnail and everything is safe.

- Two passes (2x Shells, Shell Magnet): code by Claude, creation by you.
- Shop and purchase prompts matching the UI style; no pressure tactics.
- Custom thumbnail and icon (required for Home recommendations), accurate title and description.
- Performance pass and Device Emulator pass on phone, tablet, desktop.
- Security review of every RemoteEvent: types, ranges, rate limits.
- Publish privately, test, then public.

## Week 4: measure and iterate (days 22 to 28)

Done when: one update shipped based on real numbers.

- Read Creator Analytics: Day-1 retention, bounce under 60 s, session length, Player Funnel.
- Fix the top drop-off point first.
- Ship update 1 with a "Next update ???" teaser and an event banner.
- Only consider ads after retention looks healthy against benchmarks.

## Risks

- **Generic feel.** Mitigation: a distinct look, strong audio, one signature mechanic (the tide).
- **Solo testing blind spots.** Mitigation: first-time-player checklist, an in-game feedback prompt, and fresh eyes on a phone before publishing.
- **Policy.** Read the full paid-random-items and monetization pages again before shipping anything beyond fixed-price passes ([[Research/Game Design and Market/Competitors and Policy|Competitors and Policy]]).
- **Tooling.** If the Studio connection breaks, fall back to writing scripts here and pasting them into Studio.
- **Hunyuan3D license.** Not valid in the EU, UK or South Korea. Confirmed: you're in Canada, so it's covered.
