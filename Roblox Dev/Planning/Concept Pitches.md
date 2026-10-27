# Concept Pitches

Written 2026-10-24. Pick one, then it becomes the [[Game Design Doc]]. Related: [[Master Plan]], [[Research/Game Design and Market/Engagement Loop Playbook|Engagement Loop Playbook]]

> **Update 2026-10-24: the user chose a different concept, a merge tower defense ("Guardian Grid"). See [[Game Design Doc]]. Pitches A, B and C below are kept for reference only.**

**Constraints from your answers and the research:**
- Original theme and mechanics (Roblox bans copies of existing games, see [[Research/Game Design and Market/Roblox Success Sources|Roblox Success Sources]]).
- Explained in one sentence, fun in 10 seconds, mobile first.
- Free random drops only. No paid random items, no trading.
- Two fixed-price passes at launch.
- Solo dev with Claude building, playtested by you alone at first. So the game must show what's wrong on its own: built-in feedback prompt and analytics events.

Each pitch answers the three loop questions from the playbook: what do you do every 10 seconds, what do you spend on every 2 minutes, why come back tomorrow.

---

## A. Shell Shore (recommended)

**One sentence:** Walk the beach, grab shells, sell them to a hermit crab, and upgrade your bucket to reach rarer shells before the tide turns.

| Loop | What happens |
|---|---|
| Every 10 s | Walk over shells to scoop them (auto-pickup, no aiming). Bucket bar fills, numbers pop. |
| Every 2 min | Sell at the crab shop, buy a bigger bucket, faster boots, or a shell magnet. Always one upgrade affordable and one just out of reach. |
| Every session | Unlock the next beach zone (rocks, tide pools, reef). Each has rarer shells. |
| Tomorrow | Daily shell, a tide timer (low tide opens a rare-shell cove for a few minutes), and a collection Index to complete. |

**Why it fits us**
- Simple geometry: sand, rocks, water. Low art cost.
- Shells, crabs and props are ideal for Hunyuan3D (chunky objects, under 3,000 triangles each).
- Tide countdown gives a visible timer and a dated event rhythm for free.
- Small servers (6 to 8) with a "rarest shell" board for light social pull.

**Risks:** collecting can feel flat, so sound and number-pop matter. Needs enough variety in shells (target 24 at launch).

**Passes:** 2x Shells, and Shell Magnet (auto-pull from further away). Both save time, neither blocks free players.

---

## B. Crystal Hollow

**One sentence:** Dig down through a glowing cave, sell the gems you find, and ride your elevator deeper each time.

| Loop | What happens |
|---|---|
| Every 10 s | Tap or hold to dig a block, ore pops out. |
| Every 2 min | Sell at the surface, buy a better pickaxe or a deeper elevator stop. |
| Every session | New depth layers with new ores and a visible depth meter. |
| Tomorrow | Daily vein, cave-in event timer, gem Index. |

**Why it fits:** depth is very visible progress. **Risks:** voxel digging is the hardest part to build well and keep fast on phones; this is the most technical of the three.

**Passes:** 2x Gems, Auto-dig.

---

## C. Moth Lantern Garden

**One sentence:** Plant glow-flowers, wait for night, and gather the moths they attract.

| Loop | What happens |
|---|---|
| Every 10 s | Water and tend flowers, collect pollen. |
| Every 2 min | Buy new flower types and plots. |
| Every session | Night comes on a timer, moths arrive, you catch them for the Index. |
| Tomorrow | Flowers keep growing while you're away, so there's always something ready. |

**Why it fits:** offline growth is the strongest return hook in the research. **Risks:** closest in feel to the existing plant-and-wait hits, so it needs a clearly different theme and look to avoid reading as a copy; also relies most on waiting, which punishes a first session with little to do.

**Passes:** 2x Pollen, Extra Plot.

---

## Recommendation

**A, Shell Shore.** It has the clearest 10-second action, the lowest build risk, the best fit with Hunyuan3D, and a built-in timer (the tide) that doubles as the live-event system. C is the backup if you'd rather have offline growth; B only if you want a harder technical challenge.
