---
date: 2026-10-28
tags: [references, pinterest, skill-tree, level-path, loading, ultimate, theme-arc]
---
# References 3 (the user's Pinterest set)

53 pins in 8 groups, fetched once the user's profile was public (one pin failed: overall UI #5). Sheets: `1_skilltree.jpg` ... `8_eye_char.jpg`.

**Theme arc (Decided):** steampunk with quiet magic at the start, more magical with progress, cosmic endgame (Lord of the Mysteries). Recorded in [[Game Design Doc]] ("Theme arc") with the user's skill tree, level path and loading decisions.

| Group | What the pins show |
|---|---|
| 1 Main skill tree | glowing trees of white / blue light, roots of light, a galaxy filament network, a floating purple bonsai |
| 2 Level path | stairways into light, a glowing path through a valley, a waterfall under a moon, rainy black-and-white lamplit streets |
| 3 Star Drake ultimate | meteor showers, lightning in clouds, a prism beam, a gold beam down onto a rune circle, a star chart |
| 4 Future ultimates | a black hole with formulas, a figure inside a light vortex, galaxy discs |
| 5 Skill tree upgrade UI | Witcher 3 / Wolcen / talent trees: icon nodes on branches, a constellation dial, a radial web |
| 6 Loading | a clock tunnel, a tree forming from glitching pieces, eyes in the dark, a vortex, a cosmic eye |
| 7 Overall UI | white rune rings, light pillars with stacked rings, a black-hole book, an iridescent horizon |
| 8 Eye character | eyes with clock or symbol irises, spiral eyes, eyes in the sky over landscapes |

## Built (2026-10-28, checked in Play)
- **Loading v3** (`Studio_Export/LoadingScreen.luau`): falling through a tunnel of brass clock faces (it speeds up as loading completes); then a glitch, a tree of light forming from flying squares, a ring of eyes turned toward it, and a vortex that swallows it all before the menu appears. `ours_loading_v3_timetravel.jpg`. After the recording the tree was made smaller (it ran off the top); not re-recorded.
- **Skill tree** (`Studio_Export/SkillTreeArt.luau`, called from GameClient): the same 19 skills and rules, laid out as a tree fanning up from the Start root, with glowing branches, a trunk and roots, many twigs with star tips, nebula clouds in our colours, slowly turning brass clock rings, and drag to pan / wheel to zoom. `ours_skilltree_branches.png`. Pan and zoom not tested by hand.
- **Level path** (`Studio_Export/TrainerRoad.luau`): three sections along the road, each with a title where it starts: LAMPWICK LANE (levels 1 to 8: gas lamps, brick walls), THE THINNING VEIL (9 to 16: violet mist, floating stones with runes), THE STARWARD STAIR (17 on: the road lifts into glowing floating steps with rune rings and stars). The road runs on past the last level and fades, so the end is never in sight. `ours_levelpath_sections.jpg`.

## Not built yet
- Star Drake ultimate restyle (meteor shower, beam onto a rune circle), the future ultimates and the eye character.
- More sections on the level path as levels are added (the arc allows less serious ones later).
- The sky above the road is Roblox's default day blue; a night sky per section would help.
