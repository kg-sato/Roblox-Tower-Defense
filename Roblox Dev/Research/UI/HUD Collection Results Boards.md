# HUD, Collection and Results Boards (T027, 2026-10-29)

Research boards for three screens, with takeaways for our game: dark gold-ink palette, mobile landscape 844x390. Related: [[UI Quality Bar]], [[Abstract HUD]], [[Accessibility guidelines for our game]], [[Enemy health and status readability]], [[Hearthstone reveal and rarity presentation]], [[Familiar Systems]].

**Verification level:** every claim below comes from a WebSearch result summary written 2026-10-29. Pages were NOT opened in full, so each is labelled `search-summary`. Several sources are vendor or hobby blogs, flagged `weak`. Text is paraphrased.

## Board 1: HUD (in-match)
Sources:
1. [Understanding Players' Interaction Patterns with Mobile Game App UI via Visualizations (arXiv 2110.08753)](https://arxiv.org/pdf/2110.08753): touch-heatmap study of mobile game UIs. search-summary, academic.
2. [Designing mobile game input unreachability (AHFE / CMS Conferences)](https://openaccess.cms-conferences.org/publications/book/978-1-964867-13-7/article/978-1-964867-13-7_13): thumb comfort zones; a reach radius of roughly 27 to 41 mm is the easiest zone, 41 to 55 mm is usable but covers the screen; warns against important controls outside reach. search-summary, academic, one test setup.
3. [Responsive game UI (abratabia)](https://www.abratabia.com/game-ui-design/responsive-game-ui.php): 44 px is a floor for touch targets, 48 to 56 px better for fast tapping; space between targets matters as much as size. search-summary, weak.
4. [QA testing for touch controls on mobile (bugnet)](https://bugnet.io/blog/qa-testing-for-touch-controls-on-mobile): check every control sits in the usable area on each device; multi-touch collisions are a common bug. search-summary, weak.
5. [GuiService reference (Roblox Creator Docs)](https://create.roblox.com/docs/reference/engine/classes/GuiService.md) and [ScreenInsets enum](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets.md): `ScreenInsets`, `DeviceSafeInsets` and `TopbarSafeInsets` give an area clear of notches and Roblox's top bar. search-summary, official.

Takeaways for us:
- Put the actions used every few seconds (ROLL, START WAVE, AUTO, ultimate) in the lower-right thumb arc; keep rarely used things (settings, odds) top corners.
- Every tappable control at least 48 px tall at 844x390 (about 12% of height); gap of at least 8 px. Our Scale-only rule already handles resize; the 48 px floor still needs a validator check (unverified: not yet in `UI Kit` validator).
- Respect `TopbarSafeInsets` for the top row; the left of the screen has Roblox's own menu, so crystal HP and gems go top-centre or top-right. Unverified: exact inset values on a real phone.
- Do not cover the lane: the board is the centre; panels slide from the right edge only.
- Gold-ink on near-black: numbers in warm gold, danger (crystal HP low, boss) in a single dull red, never pure white; contrast checks per [[Accessibility guidelines for our game]].
- Boss phase bar (open in [[Backlog]]): thin bar under the top row, three ticks, banner at each phase change.

HUD wireframe (844x390, landscape; `#` = lane/board area, brackets = tappable):
```
+--------------------------------------------------------------------------+
| [gear]   STAGE 7/25  ~~ BOSS ##|##|## ~~    GEMS 120   COINS 340 [odds]  | top row, inside TopbarSafeInsets
|                                                                          |
| crystal HP                                                    [Pet panel]|
| |||||||||                                                    (opens from|
|     ###########################################                right)   |
|     #   enemy lane (234-stud path, one for all stages)   #               |
|     #   ### ### ### ### board grid, 12 slots ### ### ### #               |
|     ###########################################                         |
|                                                                          |
| [skill tree]  [collection]                  [AUTO] [START WAVE] [ROLL 20]|
|                                  [ULT ring]                              |
+--------------------------------------------------------------------------+
 left-bottom: rarely used     centre-bottom: ult     right-bottom: thumb arc, 48 px+ each
```

## Board 2: Collection (FAMILIARS, 20 cells)
Sources:
1. ["The Collecting Itself Feels Good": Towards Collection Interfaces for Digital Game Objects (University of Waterloo)](https://uwspace.uwaterloo.ca/items/24cdb052-87cb-48a6-ae80-b96220f0ee2d/full): implications are to let players curate, keep the game's rules visible, keep play context, and allow sharing. search-summary, academic.
2. [Collection manager (Hearthstone Wiki)](https://hearthstone.wiki.gg/wiki/Collection_manager): search syntax in the collection (for example filtering owned or duplicate cards). search-summary, community wiki, not official.
3. [Marvel Snap collection and statistics tracker, answered (Prima Games)](https://primagames.com/tips/is-there-a-marvel-snap-collection-and-statistics-tracker-answered): says the built-in overview has limited sorting and search, so players use outside tools. search-summary, weak.
4. [Card variant albums update (Ginx)](https://www.ginx.tv/en/card-variant-album-release): an album-style view let players sort variants for the first time. search-summary, weak.
5. [Marvel Snap Zone tracker update](https://marvelsnapzone.com/marvel-snap-tracker-companion-feature-update/): third-party tracker shows completion progress and rarity. search-summary, weak.

Takeaways for us:
- With only 20 cells, use one paged grid (no scrolling lists): 5 across x 2 rows per page at 844x390, or a horizontal strip with a large card preview on the right.
- Show a completion counter ("12 / 20") and rarity ordering (six rarities, see [[Human Familiars]]); locked cells as unlit silhouettes, in line with the lantern idea in [[Backlog]].
- Selecting a cell shows the card, role (one verb), and Idle clip; the game's rules (merge tiers) stay visible, per source 1.
- Filters: rarity chips and faction chips only; a search box is not worth the keyboard on a phone. Unverified: whether players want sorting by owned count.
- Duplicates: no useful source found; decide ourselves (show tier reached, not a duplicate count).

## Board 3: Results (stage clear / defeat / overrun)
Sources:
1. [How to design a results or victory screen (bugnet)](https://bugnet.io/blog/how-to-design-a-results-or-victory-screen): acknowledge the achievement, show how the player did, end satisfied. search-summary, weak.
2. [Post game behavior (Overwolf developer guidelines)](https://dev.overwolf.com/ow-native/guides/product-guidelines/app-screen-behavior/post-game-behavior): key-stat breakdown with optional comparison. search-summary, vendor docs.
3. [Please reorder the Victory cards more sensibly (Gems of War forum)](https://community.gemsofwar.com/t/please-reorder-the-victory-cards-more-sensibly/73345): players want the most important rewards first and less empty space. search-summary, player opinion.
4. [Momonga Monday: The New Retina Interface (Paladin Studios)](https://paladinstudios.com/2012/05/07/momonga-monday-the-new-retina-interface): results as a sequence; "how did I do" first, then rewards; skipped parts when not earned. search-summary, developer blog, 2012.
5. [On our way to WIN, a gamification UI/UX case study (UX Planet)](https://uxplanet.org/on-our-way-to-win-a-gamification-ui-ux-case-study-776ae75b8273): clear call to action from the results to the next step. search-summary, weak.

Takeaways for us:
- Order: headline (STAGE CLEARED / OVERRUN), then gems with the combo bonus, then new unlocks, then one big NEXT STAGE button in the bottom-right thumb arc; RETRY secondary.
- Our rule "you cannot lose" (a leak still advances, [[Systems]]): the overrun case needs wording that says the run slid back N stages and lost coins without a harsh defeat tone.
- Tick-up counters for gems, skippable with one tap; honour Flashes and reduced-motion settings.
- Show only earned lines (no empty rows), per sources 3 and 4.
- Number format via `NumberFormat` ([[Systems]]).

## Open
- Pages were not fetched in full; a human or later pass should open sources 2 and 3 of board 1 and the Waterloo paper before relying on exact numbers.
- Wireframe is a plan, not built; not checked on a real phone.
