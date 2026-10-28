---
date: 2026-10-28
tags: [ui, references, skill-tree, grading]
---
# Skill Tree Grader and HUD reference

The user's two refined references (2026-10-28), in `References/2026-10-28 user refs/`. `skill_tree_grader.webp` is **the** grader for our skill tree. What makes each one refined, written down before building (see [[Harsh Grading]]).

## HUD reference (`hud_reference.webp`)
- **Fits Roblox's own top bar.** Its own top buttons are the same dark circles, same size and spacing as Roblox's, continuing the row. Nothing sits under or over them.
- **Everything small and on the edges.** Ability row, health bar and currency hug the bottom; the centre of the screen is the world.
- **One type family.** A book serif (Garamond-like) for the name tag, ability labels and currency letters. No mixed display fonts.
- **Monochrome first, colour as signal.** Grey-black UI; red only for health, blue for mana.
- **Ornament only on the frame.** The health bar has silver filigree end caps; the bar itself is plain. Four tiny diamond icons above it.
- **No overlaps, even spacing.** Every row aligned to one centre line, equal gaps.

## Skill tree grader (`skill_tree_grader.webp`)
- **Radial layout.** Every path is one straight ray from a glowing white centre; each path has its own colour; the rays run off the screen edge (there is more beyond).
- **Small icons, one style.** About 30 px glyph icons in thin dark hexes, tinted with the path colour. Not too detailed, not flat: engraved glyphs.
- **Patterned black.** The background is black with faint handwriting-like texture, so the darks are never flat.
- **Animated outside.** Heavy iron chains run round the screen edge and a frame rims it: you know it's a special screen.
- **Hover popup.** An ornate copper filigree frame with a crest; inside: "Path - Skill" title, a thin rule, a centred description with the keyword coloured, then the cost ("1 + 1 SP") and the status ("Unaffordable") large and dim.
- **Small close and counters.** A square close button top right; the SP counter bottom right next to the currencies.
- **No question marks.** Locked skills are just dimmer icons.

## What we built from it
Layout and polish ideas only; the parts are ours (the user, 2026-10-28: the copied chains and "SP" made no sense for our game). Skills are lanterns you kindle (as in the Skill Grove); the border is a brass watch minute-track that ticks once a second with brass gears in the corners; the popup is a brass frame with a pocket-watch crest; paths are named Embers, Brass, the Ward, Storms, Fortune, Starlight. Grades: [[Research/UI/Captures 2026-10-28/Grading Report]].
