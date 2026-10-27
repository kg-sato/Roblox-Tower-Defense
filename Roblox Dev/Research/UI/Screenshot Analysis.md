# Screenshot Analysis

Analyzed 2026-10-24 from the 31 screenshots in `Research/` (now renamed; see the index below). Related: [[UI Design Playbook]], [[Animation and Juice Playbook]], [[Low-End Device Playbook]], [[Competitors and Policy]], [[Engagement Loop Playbook]]

## What was in the set

All 31 are desktop captures at 1920x1080. **None show a phone layout**, so this tells us what the UI contains and how it looks, not how it adapts to mobile. I did not rename your files. Games are identified only by what is visible on screen.

| Game (as seen) | Files (time in name) | Screens |
|---|---|---|
| Duel shooter with weapon crates, daily tasks, battle pass, Halloween event | 203817 to 203908 (11 files) | welcome-back crate claim, lobby HUD, backpack, weapon view, daily tasks and contracts, shop home, battle pass, audio settings, crosshair settings, event shop, mode select |
| Pet tapping / egg hatching with rebirth and trading | 203940 to 204024 (10 files) | main HUD, offline earnings popup, unlock toast, shop featured, Chronos Egg tab, passes tab, trade, rebirth panel, island portals |
| "Deep Fishing" | 204041 to 204123 (7 files) | title and depth meter, hub town, shop stalls, portal and event, fishing minigame |
| "Break an Egg" (pickaxe and pets) | 204139 to 204158 (3 files) | main HUD with Auto Swing, base arrow, free-reward popup |

The files were renamed on 2026-10-24 from `Screenshot 2026-10-24 HHMMSS.png` to the names below. Prefixes: `duel-`, `pet-`, `fishing-`, `egg-`. The time in the old name is kept in the table so older notes still make sense.

## Screenshot index

### Duel shooter
| Old time | File | Shows |
|---|---|---|
| 203817 | [[duel-welcome-back-crate-claim.png]] | "Welcome back" free crate, green Claim button |
| 203823 | [[duel-lobby-hud-daily-tasks-nav-bar.png]] | Lobby HUD: bottom nav with badges, daily tasks, leaderboard, currency |
| 203827 | [[duel-backpack-inventory-grid.png]] | Backpack grid with xN counts and red X |
| 203832 | [[duel-weapon-view-level-up.png]] | Weapon screen: level bar, level-up cost, contracts |
| 203839 | [[duel-daily-tasks-streak-contracts.png]] | Daily tasks, 7-day streak, contracts with progress bars |
| 203844 | [[duel-shop-home.png]] | Shop home with tabs, price pills, season pass, special offer |
| 203849 | [[duel-battle-pass-track.png]] | Battle pass: free and premium rows, level bar, bundles |
| 203854 | [[duel-settings-audio.png]] | Settings: sliders, typed values, per-row reset |
| 203857 | [[duel-settings-crosshair.png]] | Settings: crosshair toggles with live preview |
| 203902 | [[duel-event-shop-candy.png]] | Limited event shop, locked until daily tasks done |
| 203908 | [[duel-mode-select-tiles.png]] | Mode select tiles, locked Ranked |

### Pet tapping game
| Old time | File | Shows |
|---|---|---|
| 203940 | [[pet-main-hud-tap-button.png]] | Main HUD: Shop/Trade, big tap button, "NEXT UP" goal |
| 203942 | [[pet-offline-earnings-popup.png]] | "Welcome Back" offline earnings with coin shower |
| 203947 | [[pet-hud-unlock-toast-chevrons.png]] | "2 NEW EGGS UNLOCKED" toast, ground chevrons, coin counter |
| 203952 | [[pet-shop-featured.png]] | Shop Featured tab: hero deal, sale, limited sold-out card |
| 203955 | [[pet-shop-chronos-egg-odds.png]] | Egg card with odds, countdown, 1/3/10 bundles |
| 203958 | [[pet-shop-gamepasses.png]] | Gamepasses with "or tokens" prices and bundles |
| 204007 | [[pet-trade-menu.png]] | Trade list and "Who can send you trades?" setting |
| 204015 | [[pet-rebirth-panel.png]] | Rebirth panel with locked tabs and benefits |
| 204019 | [[pet-rebirth-panel-gem-upgrades.png]] | Rebirth panel, Gem Upgrades NPC, season pets |
| 204024 | [[pet-island-portals.png]] | Island portals with tap-power requirement |

### Deep Fishing
| Old time | File | Shows |
|---|---|---|
| 204041 | [[fishing-title-depth-meter.png]] | Title card, depth ruler, one-line instruction |
| 204056 | [[fishing-catch-celebration.png]] | Big catch held up, hub town signs |
| 204100 | [[fishing-hud-start.png]] | Minimal HUD: level, money, 2-slot hotbar, event timer |
| 204104 | [[fishing-head-to-pier-stalls.png]] | "Head to the Pier" objective, Baits/Sell stalls, ground chevrons |
| 204108 | [[fishing-upgrades-rods-stalls.png]] | Colored stall signs (Upgrades, Rods, Portal, Boats) |
| 204114 | [[fishing-portal-halloween-event.png]] | Halloween event portal and in-world timers |
| 204123 | [[fishing-minigame.png]] | Fishing minigame: rarity-colored prices, hook counter, event bar |

### Break an Egg
| Old time | File | Shows |
|---|---|---|
| 204139 | [[egg-main-hud-auto-swing.png]] | HUD with Shop/Index buttons, Auto Swing toggle, timers |
| 204143 | [[egg-your-base-arrow.png]] | "Your Base" home arrow, side buttons, badge toast |
| 204158 | [[egg-free-reward-popup.png]] | "Free Reward!" popup (like, favorite, join group) |

Examples used in the analysis below: nav bar and badges ([[duel-lobby-hud-daily-tasks-nav-bar.png]]), offline earnings ([[pet-offline-earnings-popup.png]]), odds on the egg card ([[pet-shop-chronos-egg-odds.png]]), the overlap problem ([[pet-shop-featured.png]]), minimal HUD ([[fishing-hud-start.png]]).

## The most notable qualities (across all four)

1. **Persistent navigation with icon + one-word label.** The duel shooter has a 7-button bar at the bottom (Backpack, Weapons, Tasks, Shop, Pass, Settings, Event). The pet game has two big blue buttons on the left (Shop, Trade). Break an Egg has a stacked column (Shop, Index). Always: a big icon, a one-word label, a saturated color.
2. **Red notification badges and callout bubbles.** Numbered red dots on the bar buttons (5 on Weapons, 3 on Tasks), a red "!" on Shop, and a red speech-bubble pointing at the button ("Claim your FREE reward now!"). This is the main way these games pull you back to a menu.
3. **Chunky, saturated style.** Heavy outlined text (a thick dark stroke on white or yellow type), rounded panels, thick borders, gradients on buttons, bright candy colors. Text stays readable on busy 3D backgrounds because of the stroke.
4. **One modal pattern.** Dim and blur the world, centered dark or white panel, title with icon at the top, and a **red square X outside the panel's top-right**. Same in every game. Matches Roblox's guidance that close buttons always look and sit in the same place.
5. **Color-coded currencies and price pills.** Green pill = Robux, yellow pill = keys, orange pill = candy. Currency counters sit top-center (duel shooter, with a green "+" to buy more) or bottom-left (pet game: coins, gems, rebirths).
6. **Always-visible next goal and timers.** Pet game: top-center banner "NEXT UP! Make a Golden pet!". Deep Fishing: top-center "Next Event in: 19:02", plus signs in the world ("Update in 15h 19m"). Break an Egg: "Titanic Egg spawns in 18:23" and a timer bottom-right. A countdown is on screen almost all the time.
7. **Retention surfaces built into the UI.** Daily tasks panel with progress bars and rewards, a 7-day streak row with a check on claimed days, contracts sorted by "Near Completion", a battle pass with a free row and a premium row, a "Welcome back" claim screen. The pet game's offline-earnings popup ("Your pets kept tapping for 10h" with 266,221 coins and a coin shower) is the strongest example.
8. **In-world guidance, not text tutorials.** Chevron arrows on the ground and a pointing hand (pet game, Deep Fishing, Break an Egg), a short objective line ("Head to the Pier"), big colored signs above stalls (RODS, UPGRADES, SELL, PORTAL).
9. **Social proof.** Server-wide chat lines like "DerPaule13 hatched a Mythical Elegance (1/5K)", a leaderboard listing rebirths, eggs hatched, and rarest hatch, and in-world top-money boards.
10. **Monetization UI patterns.** Hero banner for the best deal, crossed-out old price plus "SAVE 5%", "BEST VALUE" and "SALE!" stickers, 1/3/10 bundle ladders, "LIMITED" tags with "Only 2,000 will ever exist" and a big SOLD OUT stamp, a "Leaves in 2d 12:20:05" countdown, an "or tokens" second payment option, and a "watch a video for free rewards" row.
11. **Odds shown on the egg.** The Chronos Egg card lists each pet's chance (34%, 33.9%, 26%, Mythical 6%, Secret 0.1%). That fits Roblox's paid-random-item rule in [[Competitors and Policy]].
12. **Rich settings.** The duel shooter's settings have tabs, numbered pages, sliders with typed percentage boxes and up/down arrows, a red reset button per row, toggles, and a side panel that explains the selected option (with a live preview for the crosshair).
13. **Minimal HUD in the simplest game.** Deep Fishing shows level, money, a 2-slot hotbar, one timer, and a luck icon. Its minigame adds a depth ruler and one instruction line. Fewest elements, clearest focus.
14. **Gating with a visible reason.** Ranked is shown locked "Unlocked at Level 100". The event shop says "Complete your Daily Tasks to start earning Candy!" with lock icons. Locked things are visible, which creates a goal.
15. **Mode select as picture tiles.** 1v1 to 5v5 are large tiles with a screenshot behind giant text, plus a limited-time banner row of small reward icons.

## Weaknesses to avoid (visible in these screenshots)

- **Overlaps.** In the pet game, the top-right leaderboard stays on top of the shop and the Chronos Egg card, covering prices and buttons ("SOLD OUT" also sits over text). Chat, the backpack search bar, and the hotbar overlap in the trade and rebirth screens. **Rule for us:** opening a full-screen menu hides the leaderboard, chat, and side panels, or the menu sits on a higher layer.
- **Tiny text.** Odds, prices, and descriptions on shop cards are very small at 1080p (for example the small price pills and the "Special Offer" tiles). They would be unreadable on a phone. Official guidance: pick font sizes readable on phones and test the smallest size on a real device ([Adaptive design](https://create.roblox.com/docs/production/publishing/adaptive-design)).
- **Density.** The shop home and pass screens show 15 or more items at once. Fine for a mouse, heavy for a thumb. Collapse into tabs and fewer cards on small screens.
- **Text on busy backgrounds without a plate.** "Welcome back" and "Head to the Pier" depend on stroke and a dark band to stay legible.
- **Pressure patterns.** "LIMITED TIME!", SOLD OUT stamps, countdowns, and "Like, Favorite, Join Group to claim" all push urgency. They work, but the audience is young. Use them with restraint (see [[Engagement Loop Playbook]]). I have not checked whether Roblox's rules allow rewarding likes or favorites; read the Community Standards before copying that popup.

## What to copy into our game (shortlist)

1. A bottom or side nav of 4 to 6 buttons: icon, one word, color, red numeric badge.
2. A single modal component: blur + dim, panel, header icon + title, red X top-right outside the panel.
3. A currency bar with color-coded pills and a "+" button.
4. A permanent "Next goal" banner and one visible countdown.
5. A daily tasks panel and a 7-day streak row.
6. A "Welcome back" popup with a count-up number and a Claim button (we can implement offline earnings later).
7. Ground chevrons and a one-line objective for onboarding.
8. Server-wide announcements for rare drops (only if we ship rarity).
9. Locked-but-visible features with a clear unlock reason.
10. Heavy text stroke, rounded panels, and one consistent palette.

Everything above is structure, not art. Use our own icons, colors, and wording.

---

# Round 2: three more games (12 screenshots, added 2026-10-24)

All desktop 1920x1080 again, no phone captures. Files were renamed with prefixes `card-`, `fruit-`, `idle-`. Games are identified only by what is on screen; I do not have their names or player counts.

## Round 2 index

### Pixel card game ("Draw a Card" on its loading screen)
| Old time | File | Shows |
|---|---|---|
| 212510 | [[card-loading-screen-flash-warning.png]] | Loading bar with "Loading icons" and a percent, plus a "Flashing lights" warning card |
| 212521 | [[card-first-draw-tutorial.png]] | One deck in the middle, "NEXT: Tap the deck to draw a card", pointer, Book and Settings buttons |
| 212525 | [[card-collection-log.png]] | Collection log: left nav, filter chips, "Uniques 0", detail pane, empty-state text |
| 212528 | [[card-profile.png]] | Profile: server badge, best hit, lifetime stats, customize tabs, Collection Log button |
| 212534 | [[card-settings-display-options.png]] | Settings: sliders, Flashes, Particles, Rays, Backdrop, Numbers, Auto Pack toggles |

### Fruit roller (orange and purple voxel world)
| Old time | File | Shows |
|---|---|---|
| 212634 | [[fruit-tutorial-1-pull-lever.png]] | "TUTORIAL 1/11: Pull the lever!", left button stack, right-side offer cards |
| 212703 | [[fruit-tutorial-3-click-fruits.png]] | Step 3/11 with a (0/3) counter, "New!" discovery toasts, time-skip offer |
| 212714 | [[fruit-tutorial-4-grab-coins.png]] | Step 4/11 "Grab the coins you dropped! (0/12)", floating fruit name and income |
| 212735 | [[fruit-inventory-equip-best.png]] | Step 11/11, Fruits inventory (2/1000), income per second, Sort and Equip Best |
| 212740 | [[fruit-hex-upgrade-tree.png]] | Honeycomb upgrade tree with locked "?" nodes and a Free Reward toast |

### Dark text idle game
| Old time | File | Shows |
|---|---|---|
| 212806 | [[idle-main-loop-columns.png]] | Three columns (Instant, Loop, Upgrades), vitals bars, log tabs, "Goal 1 of 17" |
| 212816 | [[idle-shop-tokens-passes.png]] | Shop: currency tiles, 5/50/500 token tiers, free-token timer, two passes |

## Notable qualities (round 2)

1. **Display and accessibility options in settings** ([[card-settings-display-options.png]]). Flashes On/Off, Particles Low/Default/High, Rays Low/Default/High, Backdrop Moving/Still, **Numbers 1.5M vs 1.5e6**, Auto Pack. This one screen does three jobs: reduced motion, low-end performance, and player preference. It matches what [[Animation and Juice Playbook]] and [[Low-End Device Playbook]] recommend, and we should copy it.
2. **A photosensitivity warning on the loading screen** ([[card-loading-screen-flash-warning.png]]), plus a progress bar with a percent and a status label. Cheap, honest, and respectful.
3. **A one-object first screen.** The card game starts with a single deck, one instruction ("Tap the deck to draw a card") and a pointer. No menus compete. This is the clearest example of the 30-second loop in [[Engagement Loop Playbook]].
4. **A numbered tutorial with counters** ([[fruit-tutorial-3-click-fruits.png]]): "TUTORIAL 3/11", the action in one line, key words in yellow, and a live count (0/3), (0/12). Players always know how far they are. It ends with an unlock: the fruit game's Fruits button appears on the left stack only at step 11 (compare [[fruit-tutorial-1-pull-lever.png]] with [[fruit-inventory-equip-best.png]]). **Progressive disclosure: show buttons as features unlock.**
5. **"New! ... You've discovered this for the first time!" toasts** ([[fruit-tutorial-3-click-fruits.png]]). Discovery is celebrated in a small stack on the right. The card game has the same idea as its Collection Log, with a "Uniques" counter and the empty-state line "Every look you draw for the first time lands here". **A collection is a retention surface**, and it links to the pet and egg indexes in round 1.
6. **Contextual offer cards at the screen edge** ([[fruit-tutorial-1-pull-lever.png]]): "x8 Meme Fruit Pack ONLY 799", "x2 Coin! ONLY 19", "5m Time Skip ONLY 39", each with a price tag. Small, always visible, rotating. "Pack" suggests a random item, so check [[Competitors and Policy]] before copying.
7. **Event timer with its currency** (bottom-left of the fruit screens): "Ends In: 06d 19h" above candy and coin counters, and a **Friend Boost +0%** with a green plus (social boost, an invite hook).
8. **Honeycomb upgrade tree** ([[fruit-hex-upgrade-tree.png]]). Unlocked nodes show an icon, name, level, and cost. **Locked nodes are blank "?" hexes**, which shows how much more there is without spoiling it. "Open" nodes are orange. A short success line ("Your plot is up and running") confirms the action.
9. **Equip Best, Sort, Search** in the inventory ([[fruit-inventory-equip-best.png]]), and "4/6 sec" income per equipped item. Inventory management is one tap for casual players.
10. **A fully text, near-flat UI** ([[idle-main-loop-columns.png]], [[idle-shop-tokens-passes.png]]). Serif font, thin ornate borders, three plain columns, vitals bars, and a log. Almost no art, almost no animation. It is still readable and coherent because of consistent rules. This is the cheapest UI to build and the lightest on a phone.
11. **A visible goal bar** ("GOAL 1 OF 17: Beg for Coins") at the bottom of the idle game, like the "NEXT UP" banner in the pet game.
12. **Shop clarity in the idle game**: currency tiles at the top with counts (Duel Tickets 24/24), a 5 / 50 / 500 ladder where the biggest is boxed in gold and labeled "Best value", a free token with a countdown, and passes with one-line plain descriptions ("Twice the Mana per second while training"). No stickers, no strikethroughs.
13. **A profile page as a showcase** ([[card-profile.png]]): server number, "in this server", best hit, lifetime stats, customizable backdrop/skin/badge/pins, with View/Edit. Gives players something to personalize and show.
14. **Consistent look per game.** Card game: pixel font, purple and gold, one icon style. Fruit game: voxel world and a chunky pixel font. Idle game: gothic serif. In each, the typeface carries the identity.

## Weaknesses (round 2)

- **Readability.** The card game's pixel font is very hard to read at the small size used for labels and instructions (see [[card-first-draw-tutorial.png]] and [[card-settings-display-options.png]]). On a phone it would be worse. Use a pixel font only for titles and big numbers.
- **Overlapping text.** The fruit game's floating names collide in [[fruit-tutorial-1-pull-lever.png]] ("Locked" overlaps another label), and node labels overlap their icons in [[fruit-hex-upgrade-tree.png]]. Cap label length and give labels a plate.
- **Dense edges.** The fruit HUD fills the left, right, and bottom corners at once, near where mobile controls sit. See [[Low-End Device Playbook]].
- **Empty panels.** The collection log is mostly empty on first open. Fine for a new account, but pre-fill with silhouettes of what can be found.

## Add to our shortlist

15. A **display settings** panel: Flashes, Particles, Backdrop, Number format, and a quality level that also helps low-end phones.
16. A **flashing-lights warning** if we use flashes.
17. A **numbered tutorial** with live counters that **unlocks UI buttons step by step**.
18. A **collection / index** with "first time" discovery toasts and silhouettes for undiscovered items. Fits our tower defense as a unit collection.
19. A **locked-node upgrade tree** with "?" nodes.
20. **Equip Best / Sort / Search** on any inventory of units or towers.
21. Contextual offers at the screen edge, **fixed-price** only at launch.

For our merge tower defense (see [[Game Design Doc]]), the closest matches are items 15 to 20: a unit index, an upgrade tree, one-tap "equip best", and a numbered tutorial.
