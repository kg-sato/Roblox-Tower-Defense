# Game Design Doc

Working title: **Guardian Grid** (placeholder). Concept chosen 2026-10-24 by the user: a merge tower defense, replacing the three pitches in [[Concept Pitches]]. Related: [[Merge Tower Defense Playbook]], [[Systems]], [[Master Plan]], [[Dev Process Playbook]]

## Design v2 (2026-10-24, after first playtest) - supersedes "Core loop", "Match rules" and "Gacha / crates" below
User feedback: start too slow, camera too far, coins left with menus beside them, merge only with neighbours, movable turrets, ability upgrades, highlighted tutorial, a faster gacha/rolling loop, no way to lose but real stakes, research payments.
- **Loop:** endless stages, not a 10-wave match. Kills drop **coins** (upgrades) and **gems** (rolls). Tap ROLL (10 gems) for a random pet straight onto the grid. Rolls are free-currency, so no odds-disclosure duty, but the odds panel is built anyway.
- **Rarity:** Common 60 / Rare 28 / Epic 10 / Legendary 2 percent, pity guarantees Epic or better within 20 rolls. One table in `Config` drives roll and odds panel.
- **Merge:** three identical pets (same pet and tier) that **touch** (orthogonal neighbours on the 2x6 grid) merge; result lands where you dropped. Dropping on an empty pad moves, on a different pet swaps. Recycle (drop on the red button) gives coins so a full grid never soft-locks.
- **Upgrades by ability:** per pet type, coins buy Power (+30% dmg), Haste (+14% speed), Crit (+8% for 2.5x), 5 levels each. Tap a pet to open.
- **Cannot lose, still stakes:** crystal at 0 = **Overrun**: pushed back 2 stages, lose 30% of coins, streak reset. Bosses (every 5 stages) have a 35 s timer; if they escape you drop 1 stage. Any leak resets the **perfect streak**, which multiplies gem income (up to x3). 
- **Tutorial:** the first run is the tutorial: forced rolls, highlighted steps (roll, merge, upgrade, move, defend), then +50 gems.
- **Payments:** see [[Research/Payments and Robux|Payments and Robux]]. Shop is not built until saving exists.
- **Camera:** close three-quarter view fitted to ~96 studs wide.
- **v2.1 (2026-10-24, second playtest):** pets and enemies are now procedural 3D characters (seven pet species, four enemy types). **Coolness = (tier-1) + 0.7 x (rarity-1)**: 0 is plain (Common tier 1), >=1 rarity gem, >=2 glowing ring and light, >=3 orbiting orbs and sparkles, >=4 halo, aura and light pillar. Rolls play an **egg animation** (drop, shake, crack, reveal) whose length and effects scale with rarity, per [[Research/Magical Roll Animation Playbook|Magical Roll Animation Playbook]]; Quick Roll skips Common/Rare. **Trainer progression:** XP from kills and stage clears, level up pays gems and adds Luck (better rarities likelier, shown in the odds panel), level 3 unlocks Auto Roll. **Tap a pet** for Upgrades or Delete (+coins; Epic+ or tier 3+ asks for a second tap). Hunyuan3D models are not used yet; the procedural models are placeholders for them.
- **v2.2 (2026-10-24, third playtest):** waves no longer start by themselves: a **START WAVE** button begins each stage, and **AUTO** starts waves automatically (and rolls for you at trainer level 3+). Tapping a pet opens one right-hand panel with its three upgrades and **Delete** at the bottom; the Upgrades and Roll Odds rail buttons are gone (odds are one tap from a small ODDS button beside ROLL). Hatching is now a **full-screen egg sequence** (egg drop, shake, crack, flash, pet pop, rarity title, odds); Common and Rare shorten with Quick Roll or AUTO, tap skips. Ultimate: dim, golden shockwaves, lightning on every enemy, camera shake, glowing button when ready.
- **v2.3 (2026-10-24, fourth playtest):** **Merge rule changed:** two matching pets that touch plus a third dragged from anywhere onto one of the pair (the older all-touching chain still works); hovering shows green pads and highlights the pair. **Skill Tree** (honeycomb, 19 nodes, Skill Points from level-ups, bosses, tutorial), see [[Research/Skill Tree, Effects and Characters|Skill Tree, Effects and Characters]]. **Ultimate** is now a short cinematic (gather, orb, release, meteor storm). **Final hatch** will be Blender-made: see [[Research/Blender Cinematic Pipeline|Blender Cinematic Pipeline]]; the current in-engine hatch is the demo.
- **Open design risk:** with 7 pet types in 12 slots, triples are rare without recycling; watch it in playtests.

## One-line pitch
Summon cute guardian pets onto a grid, merge three into a stronger one, and hold the crystal against waves of gloom monsters and bosses.

## Genre and similar games
- Genre: merge tower defense, session-based matches with a permanent collection.
- Similar on Roblox: Anime Vanguards and Tower Defense Simulator style games (for Creator Analytics benchmark comparison). Theme and mechanics here are original: merging on a grid, pets, no copied assets.

## Target player
- Age range: 9 to 16 (assumption, check Creator Analytics after launch).
- Device: phone first (touch drag, big buttons), tablet and PC supported.
- Session length: one match is 8 to 12 minutes; 2 to 3 matches per sitting.

## Core loop
Every 10 s: tap Summon (coins), drag matching pets together to merge, tap a charged ultimate.
Every 2 min: a wave clears, a boss telegraphs and dies, coins flow back into summons.
Every match: win or lose, get shards and a crate. Open the crate with a satisfying reveal, level a pet, pick a harder world.
Tomorrow: daily free crate, 3 daily quests, a new world or event unlocked.

## Match rules (v1)
- One lane path, 12 grid slots to start (up to 20 with upgrades), 30 waves, a boss on wave 10, 20 and 30.
- Summon costs coins; cost rises with each summon. Three identical pets (same type and tier) merge into next tier. Tier cap 5.
- Crystal has HP. Lose all HP, lose the match.
- Enemies follow the lane; modifiers (armored, swift, regenerating, shielded) arrive by world difficulty.
- Ultimate: each pet fills a bar from its own kills; tap to cast (area burst, freeze, heal crystal, etc.).
- Solo matches at launch (each player has their own instance of the lane). Co-op is a "Later".

## Progression
- **Worlds:** Meadow (Normal), Frost (Hard), Volcano (Nightmare). Each is a new look, harder mob quality, new boss, better crate quality.
- **Pet levels:** shards from matches level a pet permanently (small stat boosts).
- **Collection Index:** every pet and its tiers, with a completion reward.
- **Daily:** free crate, three quests, a streak.

## Gacha / crates (free currency only at launch)
- Crates are opened with **earned** gems and crate drops, never Robux. Rarity tiers: Common, Rare, Epic, Legendary.
- Server-side roll from one data table that also drives the odds panel shown in the UI.
- Reveal: shake, flash, rarity-coloured burst, pet spins in, duplicate converts to shards.
- Pity (guaranteed Epic every N crates) planned; it is a free-currency crate so no regional restriction issue, but re-check [[Competitors and Policy]] if currency ever becomes purchasable.

## Monetization
- Premium pets: **fixed-price** Robux purchases (developer products), cheap tiers (e.g. low Robux price points), better quality and style than free pets, same power ceiling. Exact prices to decide by the user.
- Game passes (two at launch): 2x Coins in matches, Auto-Merge helper (suggests/executes valid merges). Neither blocks free players.
- Rule: all purchases, currency and rewards are checked on the server. No paid random items, no trading.

## Art direction
- Style: bright, chunky, readable at phone size; strong silhouettes, rarity colours (grey, blue, purple, gold).
- Colours / font / radii: defined in a style guide module (`UIStyle`), one font, one corner radius.
- 3D models: Hunyuan3D-2 (shape only, no textures on this GPU), under 3,000 triangles per prop and under 20,000 hard limit; colour applied in Studio. Needs reference images (see [[3D Assets]]).

## Audio
Music loop per world, UI sounds on every press, hit/merge/summon/ultimate/boss/crate sounds. Roblox audio library assets must be checked for licence and availability in the user's account; unverified until tested in Studio.

## Display and accessibility settings
Source of the idea: the card game's settings screen in [[Screenshot Analysis]] ([[card-settings-display-options.png]]), which uses one panel for reduced motion, low-end performance, and player preference. Ties to [[Animation and Juice Playbook]] and [[Low-End Device Playbook]]. Items marked (ours) are our design choices, not Roblox rules.

### Launch settings (must have)
| Setting | Options | Default | What it changes |
|---|---|---|---|
| Music volume | slider 0 to 100% | 80% (ours) | Music group volume |
| SFX volume | slider 0 to 100% | 100% | UI, hit, merge, summon, crate sounds |
| Flashes | On / Off | On, with a warning (see below) | On: full-screen flashes (crate reveal, ultimate, boss intro). Off: replace each with a soft glow or colour tint, no brightness spike |
| Particles | Low / Default / High | Low on touch devices, Default elsewhere (ours, tune on the baseline phone) | Cap on live particle emitters and pooled VFX (starting multipliers 0.25 / 1 / 1.5, tune) |
| Backdrop | Moving / Still | Moving on PC, Still on touch devices (ours) | Animated lobby and menu backdrop, ambient world motion (drifting clouds, floating motes) |
| Number format | 1.5M / 1,500,000 / 1.5e6 | 1.5M | Every coin, gem, damage, and HP number in HUD, shop, and results |

### Should have (after the first playable)
| Setting | Options | Notes |
|---|---|---|
| Reduced motion | On / Off | Stops looping tweens (pulsing badges, bobbing arrows), turns pop-ins into short fades, disables screen shake. Implies Backdrop Still and Flashes Off |
| Screen shake | Off / Low / Default | Keep shake small even at Default (GameAnalytics juice article) |
| Damage numbers | Off / Compact / Full | Reduces clutter in big waves and saves UI instances |
| UI size | Small / Default / Large | Roblox's adaptive design page says text and UI scaling preferences should drive element sizing; implement as one `UIScale` on the root screen. Read the [accessibility player-preferences section](https://create.roblox.com/docs/production/publishing/accessibility) before building (not read yet) |
| Rarity cues | Colour + icon (always) | Never rely on colour alone: Common, Rare, Epic, Legendary each get a distinct shape or icon and a text label (ours) |
| Hide UI | toggle and button | For recording and streaming ([Design for Roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox)) |
| Haptics | On / Off | Mobile vibration on merge and summon, if supported |
| Quality preset | Low / Medium / High / Custom | One switch that sets Particles, Backdrop, and damage numbers together; changing any one flips it to Custom |

### Photosensitivity rule
- If any effect flashes, show a short notice on the loading screen, as the card game does ([[card-loading-screen-flash-warning.png]]), and keep the Flashes option one tap away in Settings.
- Never flash full-screen more than 3 times in any one second (a common accessibility guideline; I have not checked it against Roblox's own docs). Avoid saturated red flashes.
- Crate reveal and boss intro must have a no-flash version from day one.

### Panel layout
- Opened from a gear button in the nav, labelled "Settings". Same modal pattern as every other menu (dim, panel, red X top-right outside the panel).
- Sections in this order: Sound, Display, Accessibility. Rows are label on the left, control on the right: sliders for volume, segmented buttons for 2 to 3 options.
- A "Reset to defaults" button at the bottom. Changes apply immediately (no Apply button) so players see the effect.
- Phone: one column, comfortable tap targets, text readable at the smallest supported size (test on the baseline phone; Roblox gives no numeric minimum). Never put a pixel font on labels.
- Desktop: optional side panel explaining the highlighted setting, as in [[duel-settings-audio.png]].

### How it is built
- One shared `SettingsDefaults` module holds names, allowed values, and defaults. Both client and server read it, so validation and UI never disagree.
- Client `SettingsController` holds the live values and fires a changed signal. Systems subscribe: VFX pool (particle cap), `UIAnimator` (reduced motion, flashes), `NumberFormat` (format), lobby backdrop, audio groups.
- Persistence: add a `settings` table to the player profile in [[Systems]] (ProfileStore schema, bump `version`). The client sends the whole table through one RemoteEvent; the server checks every key against the allowed values, rate-limits it, and saves. Apply locally first, then save (debounced), so the UI feels instant. Follows the security rules in [[Systems]] (settings are not security-critical, but never trust the client's types).
- `NumberFormat.format(n, style)` is one shared function. Test cases for the headless test harness: 999 -> "999", 1500 -> "1.5K", 1500000 -> "1.5M", 13660000000000 -> "13.66T"; the "1,500,000" style groups digits; the "1.5e6" style uses scientific notation; negative and zero values do not error; very large values fall back to scientific rather than showing an undefined suffix.
- Do not tween the thickness of a text `UIStroke` (official; flicker and cost). Respect Particles and Reduced Motion in every new effect before shipping it.

### Verification
- Each setting changes exactly what the table says, checked in Play on a phone-size emulator and on a real low-end phone (the emulator is not reliable for memory).
- Settings persist across rejoin and are validated server-side (send a bad value, expect it rejected or clamped).
- With Flashes Off and Reduced Motion On, play one full match plus a crate reveal and confirm there is no full-screen flash or looping motion left.
- Particles Low keeps frame rate steady in the heaviest wave on the baseline phone (target from [[Low-End Device Playbook]]).

## Scope for launch (must have)
Menu/lobby, 1 world with 30 waves and a boss, 8 pets x 5 tiers (tiers are recolour/scale/VFX), 3 enemy types + 1 boss, summon/merge/ultimate, crate with reveal, pet collection, ProfileStore saving, HUD, two passes, premium pet purchase, sounds, music, analytics events, tutorial, **settings panel with music, SFX, Flashes, Particles, Backdrop, and Number format**.

## Not for launch (later)
Worlds 2 and 3, co-op, trading (excluded), paid crates, events, leaderboards.

## Open questions
- Premium pet price points in Robux (user decision).
- Where reference images for Hunyuan3D come from (user-supplied, or rendered from Studio primitives).
- Whether to initialize Git (not done; user approval needed).

## Design v3 proposal (2026-10-25): merge chain, supersedes the triple-merge parts of v2.x once approved
Full text: [[Game Redesign - Merge Academy]]. Decisions received so far (relayed from the user): **bosses can be lost; a boss fight is 30 seconds** (the 35 s timer in v2 becomes 30 s); character names and looks are kept; combat stays; the gacha gives Relics and Skins, not characters; idle (Hearth) and active (Journey) modes share one board. Open: chain length (about three minutes to the first Archmage, flagged as possibly too fast). Not started in code: nothing in `GameClient` or the match scripts changed, by the user's priority (effects before gameplay).
