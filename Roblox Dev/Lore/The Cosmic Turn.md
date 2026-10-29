# The cosmic turn: why the sky opens, and what changes (T054)

Status: draft written overnight 2026-10-28. The arc itself is decided by the user (steampunk and quiet magic at the start, cosmic at the end: white light on black, stars, rune circles, light pillars, eyes; see [[Game Design Doc]]). The in-world reason and the specific changes below are proposals. It builds on [[World Bible]] and [[Factions]].

## Why the sky opens (in-world)
The fog is the city's lost time. The more time the player's lantern wins back from the fog, the less the fog hides, and what it was hiding is the sky. The city was never under a roof: the fog and the stopped Great Clock together held a single moment shut. As stages are cleared, the moment loosens. The Star Choir has been waiting for this and sings the last notes; the Keepers and the Guild must decide whether to let it open (see the open questions in Factions). The turn is therefore earned by the player's own progress, not delivered by a cutscene alone.

## When it happens
- **Foreshadow (stages 1 to 15):** a single star in a gap in the fog at the end of each set; the clock tunnel in the loading screen already shows the future.
- **First crack (stages 16 to 20, Clockwork Foundry):** a crack of white light across the sky; the clock ticks once.
- **The turn (stage 21, Above the Grey Veil):** the veil lifts as a short non-skippable-by-accident but skippable-by-tap scene (T143 camera nudge rule); the board's backdrop swaps from city to open sky.
- **Resolution (stages 22 to 25):** the cosmic look is full; stage 25 ends on the Clockmaker (T147).

## What changes visually (proposals)
- **Light:** warm lamp orange (about 2400 K, see [[Victorian interiors and lamplight palettes]]) gives way to white light on near-black, with the lanterns kept as the only warm points so the player's lantern stays the focus. Atmosphere Haze drops and Glare rises in steps (see [[Fog haze and volumetric light in Roblox]]).
- **Backdrop:** gothic skyline silhouettes ([[Gothic silhouettes for backdrops]]) break into floating fragments around rune circles, light pillars and a few slow eyes; the stage-set data (StageSets) gets a fifth entry with its own edge ring (T154, T163).
- **Palette:** deep blue and white from the Choir colour (see Factions), with brass kept as a thin gold trim so the old city is still visible.
- **UI:** frames shift from brass and glass to thinner light-line frames with Art Nouveau curves ([[Art Nouveau ornament references]]); skill tree already moves cosmic by design.
- **Familiars:** the Star Drake and mirror-cat become available as rolls (higher star weight in late rolls), and starfall trails appear on attacks (T154 effects).

## What changes mechanically (proposals, all as data)
1. **Wave modifiers (T015):** a "gravity" modifier that pulls enemies off the path's shortest line for a few seconds; a "silence" modifier that mutes one familiar family's ultimates until a lantern is relit.
2. **Weather (T010):** star-fall events replace fog waves; they give a short range bonus to cosmic familiars and a slow to enemies.
3. **Lantern power (T011):** from stage 21 the lantern gains a second use (a flare that clears a lane of fog), unlocked by clearing the turn stage.
4. **Boss (T147):** the final Clockmaker reverses one merge per wave; the player's answer is the lantern flare. Keep the rule simple so it is learnable.
5. **No power spike from payment:** none of these can be bought (see [[Monetisation players accept vs hate]]).

All values live in data tables (T199), and each mechanic is tested headless (T202) before it ships.

## Risks and open questions
- Too sudden a swap would feel like a different game; the foreshadow and first-crack steps exist to prevent that.
- Lag risk from stars, pillars and eyes on phones: budget them against [[Mobile performance limits]] before building.
- The user's open questions: does the sky open fully at stage 25, and is the Choir's opened sky a victory or a threat?
