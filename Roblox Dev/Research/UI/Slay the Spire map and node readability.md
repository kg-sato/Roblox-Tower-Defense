# Slay the Spire map and node readability (T043)

Question: how does Slay the Spire present its branching map and node types so route choices are readable, and what should our stage select map take?

## Facts (sourced)
- Release: early access November 2017; full PC release 23 Jan 2019; mobile in 2020 and 2021. Each floor has encounters arranged in a branching structure and ends with a boss. Node types: monsters, elites (tougher, better rewards), rest sites (heal or upgrade a card), shops, treasure, events, boss. The branching paths and random events were inspired by FTL: Faster Than Light. The page does not describe how players choose routes. [Wikipedia, Slay the Spire](https://en.wikipedia.org/wiki/Slay_the_Spire) (fetched 2026-10-28).
- The team moved enemies from a hidden-move "Next Turn" system to an "Intents" system that shows enemy actions with icons and numbers, after playtesters found hidden moves confusing. The game was tested with expert Netrunner players and balanced with gameplay data. Same source.
- Mega Crit's GDC 2019 talk by Anthony Giovannetti was on metrics-driven design and balance, not on the map. [GDC news, Slay the Spire metrics-driven balancing](https://gdconf.com/news/learn-slay-spires-successful-metrics-driven-approach-game-balancing-gdc-2019) (January 2019; snippet only).
- From search snippets (not read in full): the sequel's guide lists seven node types including an "unknown" question-mark room, shown as nodes joined by dotted lines ([Untapped.gg guide](https://sts2.untapped.gg/en/guides/how-to-make-the-best-map-choices-in-slay-the-spire-2)); one player report says it took several levels to understand that the icons were a map showing what to expect (anecdote, [itch.io post](https://itch.io/post/15552706)).

## Not found
- Developer statements on icon design or legibility, node spacing, or colours. The readability conclusions are mine.

## Recommendations for our stage select screen (not sourced)
1. Show the path ahead as a branching node map with a fixed, small icon set, one icon shape per node type, so the type reads from shape rather than colour (accessibility note).
2. Always show what is on the node before the player commits, using the Intents idea: display enemy family icons and boss marker on the node, and make unknowns obviously unknown.
3. Make the safe or recovery node (our lamp or rest) look different from the combat nodes by silhouette, in the Lantern language.
4. Add a short onboarding line the first time the map appears, since a player report suggests it may not read as a map at first.
5. For our five sets, one map per set with the boss as the last node and an optional locked branch (the Act IV idea) for the cosmic turn (T094, T054).
6. Use the stage select task (T094) to test icons at phone size.

## Sources
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://en.wikipedia.org/wiki/Slay_the_Spire | fetched 2026-10-28; 2017 to 2021 | read |
| 2 | https://gdconf.com/news/learn-slay-spires-successful-metrics-driven-approach-game-balancing-gdc-2019 | Jan 2019 | snippet |
| 3 | https://sts2.untapped.gg/en/guides/how-to-make-the-best-map-choices-in-slay-the-spire-2 | undated | snippet |
| 4 | https://itch.io/post/15552706 | undated | snippet; anecdote |
| 5 | https://en.wikipedia.org/wiki/Slay_the_Spire_II | undated | listing only |
