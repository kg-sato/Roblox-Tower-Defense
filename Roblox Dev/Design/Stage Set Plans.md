# Stage set plans: enemy variants, path shapes, set cards (T151, T155, T156, T160, T161)
Design written 2026-10-29 from [[Stage Set Lore]], [[Stage Captions]] and the board in `Config.luau` (bounds x -50 to 46, z -26 to 28; lane half width 4.8; the current path is one 234-stud route with 90-degree corners). All PROPOSAL; nothing is implemented. The five sets: Lampwick Lane (stages 1 to 5), Harbour of Brass (6 to 10), Silent Cathedral (11 to 15), Clockwork Foundry (16 to 20), Above the Grey Veil (21 to 25).

## Enemy variants by stage set (T151)
Rule from the research note (one palette per layer, variation by tint, wear and props): each set re-skins the same families, never adds a new palette per enemy.
| Set | Look | How it shows on a Parishioner, Wisp, Sentinel |
|---|---|---|
| Lampwick Lane | dry cobbles, warm | the base look (violet hood, pale blue wisp, dark brass sentinel) |
| Harbour of Brass | wet, verdigris | dark wet sheen on cloth, green verdigris streaks on brass, droplets in the wisp's mist |
| Silent Cathedral | gilded and pale | gold edging on hoods, candle-wax drips, a faint stained-glass colour wash on the sentinel's plates |
| Clockwork Foundry | soot and heat | ash-brown darkening, ember-orange glow in seams, sulfur-dark tarnish |
| Above the Grey Veil | cold and starlit | blue-white rim light, star-dust flecks, lamp orange only on what carries a lantern |
How to build: a tint colour per set applied through the model's palette texture or a SurfaceAppearance colour tint (the enemy models use a 4 by 4 palette, so a tint is cheap), plus 1 or 2 small prop swaps. Not built.

## Path shapes (T155 and T156)
Waypoints in board coordinates (x, z); the table is computed by script, not by hand: length, number of corners, sharpest turn, smallest distance between two non-adjacent legs (the slot rows need at least 14 studs), and whether every point lies inside the board bounds. The old path is 234 studs.
| Set | Shape | Idea | Length | Corners | Sharpest turn | Min leg gap | In bounds | Waypoints |
|---|---|---|---|---|---|---|---|---|
| 4 | A Serpentine | four long runs back and forth, 16 studs apart, one slot row between runs | 384 | 6 | 90 | 16.0 | yes | `(-44,-24), (40,-24), (40,-8), (-44,-8), (-44,8), (40,8), (40,24), (-44,24)` |
| 4 | B Inward spiral | an outer loop that winds inward to the furnace door | 288 | 5 | 90 | 14.0 | yes | `(-44,-22), (40,-22), (40,22), (-30,22), (-30,-6), (18,-6), (18,8)` |
| 4 | C Split with a merge point (top branch) | the short branch; enemies pick a branch at random, both rejoin at x = 30 | 132 | 4 | 90 | 22.0 | yes | `(-44,0), (-30,0), (-30,-22), (30,-22), (30,0), (44,0)` |
| 4 | C Split with a merge point (bottom branch) | the longer branch with a notch in the middle (more tower coverage) | 160 | 8 | 90 | 14.0 | yes | `(-44,0), (-30,0), (-30,22), (-6,22), (-6,8), (14,8), (14,22), (30,22), (30,0), (44,0)` |
| 5 | A Stair and back | three steps climbing diagonally across the board, one slot row between rows | 132 | 6 | 90 | 14.0 | yes | `(-44,22), (-20,22), (-20,8), (0,8), (0,-6), (20,-6), (20,-22), (44,-22)` |
| 5 | B Ring round the clock | a 45-degree ring round the clock face (not on the path), entry left, exit left below the entry | 161 | 7 | 63 | 17.9 | yes | `(-44,0), (-30,0), (-22,-16), (0,-24), (22,-16), (30,0), (22,16), (0,24), (-22,16)` |
| 5 | C Bridge with pockets | a straight bridge with a notch of 52 studs where a direct line would be 20 | 120 | 4 | 90 | 16.0 | yes | `(-44,-4), (-10,-4), (-10,-20), (10,-20), (10,-4), (44,-4)` |

Findings: the serpentine and the spiral are longer than today's path (384 and 288 against 234), so they could carry more hp per unit of tower coverage; the split-merge branches (132 and 160), the stair (132) and the bridge (120) are SHORTER, which makes them harder unless enemy hp or counts are lowered, so they suit sets that want pressure. The split needs engine support for two branches (the current `Path` module follows one list of points), and the ring uses 45 to 63 degree turns, so any curvature rule (T179) must allow them. Not built, not placed in Studio, slot positions for each shape not designed.

## Stage intro and clear cards (T160 and T161)
Text from the existing captions plus the "what went wrong" line of each set; art plates are described, not painted.
| Set | Intro title and lore line | Art plate (intro) | Clear title, reward, flavour line |
|---|---|---|---|
| Lampwick Lane | [ LAMPWICK LANE ] "The dusk never finishes." | a lamp row with one dark bracket, warm gold on wet cobbles | [ THE FOG WITHDRAWS ] 50 gems; "One more lamp burns." |
| Harbour of Brass | [ THE HARBOUR OF BRASS ] "The tide stopped with the clock." | a steamship at an angle on still water, verdigris on the cranes | [ THE TIDE REMEMBERS ] 60 gems; "The water moves, a little." |
| Silent Cathedral | [ THE SILENT CATHEDRAL ] "Someone covered the statues." | moonlit nave, a covered statue, a bell with its rope cut | [ A STAR BEHIND THE FOG ] 70 gems; "The first light that is not yours." |
| Clockwork Foundry | [ THE CLOCKWORK FOUNDRY ] "The furnaces were banked, not put out." | a cold furnace with one lit door and a small coat on a hook | [ THE FURNACES WARM ] 80 gems; "Something here was loved." |
| Above the Grey Veil | [ THE FOG LIFTS ] "This is where it ends." | the clock face from behind, the apprentice's lamp inside | [ THE CLOCK TURNS ] 100 gems; the ending scene |
Reward sizes are a PROPOSAL (rising with the set). Flavour lines are drafts in the project voice ([[Tone Guide]]), for the user to approve. Cards need UI work, which belongs to the UI chat.

## Open questions for the user
1. Which path shapes (T155, T156) should be built first, and is a branching path in scope (it needs new engine code)?
2. Are the set-clear gem rewards (50 to 100) right against the economy in [[Progression Rules]]?
