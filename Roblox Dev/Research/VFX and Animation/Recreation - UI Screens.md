---
date: 2026-10-28
tags: [ui, 1to1]
---
# Recreation - UI Screens

Method and tool: [[Effect Recreation 1to1 - Index]] step 7 (`tools/ui_compare.py`). The screen is built inside a 16:9 `Stage` frame with four 6 px magenta corner markers; the capture is resized to the reference's 1920x1080 so every pixel lines up.

## Baseline: Sol's RNG roll result vs our UIKit `AuraRoll` (Measured, 2026-10-28)
Reference: `Research/Reference Screens/sols-roll-result-crowned-1-in-20000.png`. Ours: `UIScreens.AuraRoll` as built on 2026-10-25 (judged by eye then).
| Region (reference px) | Edge F1 | Delta E | Finding (Seen) |
|---|---|---|---|
| Whole screen | 0.07 | 29 | the reference's 3D world and character are not UI, so whole-screen scores stay low by nature |
| Title stack 800,350-1100,475 | 0.24 | 33 | ours sits about 270 px higher and is spread out; the reference stacks "1 in 20,000", "Crowned", "Gilded [MUTATED]" tightly above the character's head |
| Roll bar 680,960-1240,1020 | 0.18 | 44 | ours: three tall filled navy buttons; reference: thin outlined boxes, "Roll" with a "4/10" counter under it |
| Currency stack 0,960-210,1075 | 0.00 | 28 | ours has none; reference: three outlined rows with icons (cyan, purple, gold) |
| Leaderboard 1500,0-1920,550 | 0.08 | 30 | ours: small centred table with corner brackets; reference: full-height rows with avatar icons, coloured names, right-aligned numbers |
Images: `1to1/ui_auraroll_v0_side.jpg`, `1to1/ui_auraroll_v0_edges.jpg`. Verdict: **not a match**; this is the starting point for the UI rework the user asked for (roll bar at the bottom, loading screen, start menu, side buttons, skill tree, progression, indicators).
