# Enemy Models

Procedural enemy models for the stage sets, built in Blender headless and checked by `tools/verify_enemy_model.py <Name> [budget]` (GLB parses, triangle budget, silhouette unlike any familiar). Files in `Assets/3D/Enemies/<Name>/`. Enemy triangle budget used so far: 3,000 (the project limit for any mesh is 20,000). Not imported into Roblox yet; look UNVERIFIED by the user.

## Fog Wisp (T114)
Design from [[Backgrounds and Enemies - Mystic Victorian]]: "torn cloak with no body, glides low, trails mist; long trailing tail, no legs; pale cold blue".
`Blender/make_fog_wisp.py`: a flattened hooded cloak along a gentle S-curve (domed hood with a dark recess and two pale eye points), tapering into a long tail, seven ragged tatters trailing back and down, three thin mist strands. 3.95 long, 1.58 high, floats 0.04 to 1.6 above the ground plane, faces -Y. 1,405 triangles, 789 vertices. Texture `FogWisp_BaseColor.png` (RGBA gradient: cold blue at the head, lighter mist and fading alpha toward the tail; use AlphaMode Transparency and DoubleSided in Roblox). Stills and `_FogWisp_sheet.png` beside the GLB.
Known flaws: it reads as a hooded tadpole more than torn cloth (smooth hood, thin tatters); the tear texture is not painted; the lantern-eating idea of the later Fog Wisp redesign (T134) is not in this model; no animation, no rig (a floater template from [[Rig Template]] would fit).

## Brass Sentinel (T115)
Design from the same research table: "steam automaton, boxy torso, chimney on its back; square shoulders plus a back chimney; dark brass, red eye slit" (the heavy tank). `Blender/make_brass_sentinel.py`: a squat tank of beveled-free boxes: deep torso with a riveted chest plate, huge square shoulder pads, long thick arms ending in big fists, a small head sunk between the shoulders with a red eye slit, a deep boiler on the back with two tapered chimneys. 4.6 wide, 2.75 deep, 4.41 high, faces -Y. 368 triangles, one 4 by 4 palette texture (`BrassSentinel_Palette.png`, flat colours: dark brass, brass, worn dark, red, iron, rivet gold, black, soot). Files in `Assets/3D/Enemies/BrassSentinel/` with `_BrassSentinel_sheet.png`.
It must not be mistaken for the familiar [[Sentinel]] (also a boxy brass automaton): the first build, slim and tall, scored a side silhouette overlap of 0.59 against the familiar, so the enemy was rebuilt squat and wide with a deep boiler, and now reads as a different shape (front view 0.47 against the nearest familiar front, Gargoyle).
Known flaws: very blocky (368 triangles, no bevels), flat palette colours, no wear or steam (the steam puff is a VFX task), no rig; the three-quarter view still overlaps Ward at 0.60 at 48 px, information only.

## Clockwork Crow (T116)
Design from the task list (T136): a fast flyer, a wind-up crow. `Blender/make_clockwork_crow.py`: dark steel body with a brass chest plate and beak, two red eye points, a wind-up key on the back, a geared brass disc at each shoulder, five feather blades per wing in a raised flap pose, a three-blade tail fan, thin legs with talons. 5.53 wide, 4.35 long, 2.69 high, faces -Y, 416 triangles, one 4 by 4 palette texture (`ClockworkCrow_Palette.png`). Files in `Assets/3D/Enemies/ClockworkCrow/`. Front silhouette overlap with the nearest familiar front is 0.22 (Moth-Lantern); the side view reaches 0.50 against it (information only).
Known flaws: flat blades and palette colours, no rig (a flyer template from [[Rig Template]] would fit), no flap clip, not in Roblox.

## Lantern Thief (T117)
Design from the task list (T137): goes for the path's lamps, drops a stolen light. `Blender/make_lantern_thief.py`: a crouched hooded thief (pointed hood, two pale eyes), wide bent legs with boots, one arm flung up holding a glowing lantern, one arm trailing a grabbing hand, a big sack with a knot on its back. 4.45 wide, 2.48 deep, 4.0 high, faces -Y, 264 triangles, one 4 by 4 palette texture (`LanternThief_Palette.png`). Files in `Assets/3D/Enemies/LanternThief/`. Front silhouette overlap with the nearest familiar front is 0.31 (Archivist). The first standing version scored 0.56 against Ward and was redesigned as a crouch rather than loosening the check.
Known flaws: flat boxes and palette colours, no rig (a biped template from [[Rig Template]] would fit), not in Roblox, the lantern glow is not emissive.

## The Unbound, boss of stage 5 (T118)
Design from [[Stage Set Lore]] and [[Chapter 1 - Lampwick Lane]]: a faceless figure of fog, "what is left of a night nobody finished". `Blender/make_unbound.py` (on the new shared helper `Blender/enemy_lib.py`) builds three phase variants in `Assets/3D/Enemies/`: **Unbound** (phase 1: a wide low fog bank, a stooped figure, an oversized blank floating head, arms dragging; 292 triangles), **UnboundP2** (risen, arms flung wide, split face, shard halo; 380), **UnboundP3** (cloak gone: floating head, two hands, shards around a hollow core with a lantern glow; 204). Front silhouette overlaps with the nearest familiar: 0.43, 0.28, 0.20. The first standing-cone versions scored 0.71 (Ward) and 0.53 (Mourner) and were redesigned.
Known flaws: flat boxes and cones, no transparency (fog is solid), no rig, no phase transition animation, not in Roblox.

## The Clockmaker's Automaton, boss of stage 10 (T119)
Design from [[The Clockmaker]] (act 2) and [[Stage Set Lore]]: a gear-engine that slows the board; its hand-cranks are fresh and clean. `Blender/make_automaton.py`: four splayed legs, a huge toothed old-brass gear facing front as the body, a bright small gear and hub, a rear gear, a lamp-eye turret with a red slit, a hanging pendulum, and two bright clean cranks at the sides. 7.15 wide, 4.4 deep, 7.2 high, 568 triangles. Front silhouette overlap with the nearest familiar front 0.44 (Moth-Lantern). `enemy_lib.py` gained `disc` (a round plate facing front, optionally toothed).
Known flaws: flat boxes and palette colours, no rig, no turning gears, not in Roblox.

## Star Choir's Echo, boss of stage 15 (T120)
From [[Stage Set Lore]]: "the first sign of the sky". `Blender/make_star_echo.py`: a tall hovering singer in a silver-blue robe, open mouth, arms raised, a spiked gold star halo, plus two smaller echo copies at different heights with blue and red halos. 564 triangles; front overlap with the nearest familiar 0.30 (Ember). Known flaws: solid halos, no rig or echo animation.

## Hollow Court Regent, boss of stage 20 (T121)
From [[Chapter 4 - Clockwork Foundry]]: a crown of lit candles, ringing the Foundry's own bell. `Blender/make_regent.py`: a tall thin figure in a long ash coat, hollow dark face with ember eyes, a ring crown of seven candles, a big brass bell raised on a hook in one hand and a hand-bell in the other. 484 triangles; front overlap with the nearest familiar 0.49 (Archivist), a narrow pass, so the bell carries the difference. Known flaws: flat flames, no rig.

## The Clockmaker, final boss of stage 25 (T122)
From [[The Clockmaker]] act 5: the clock face and the apprentice's lamp inside it. `Blender/make_clockmaker.py`: a huge open brass clock hoop (24 rim blocks, tick blocks, hands) behind a tall robed faceless figure with a lamp in its hollow chest. 9.9 wide, 10.45 high, 724 triangles; front overlap with the nearest familiar 0.33. The first designs (solid disc 0.66, tower case 0.57 and 0.66) failed and the clock became an open hoop. Known flaws: the "clock face seen from behind" clue is not modelled (the hoop is seen from the front), the lamp is tiny, the figure is small against the hoop.

## Hollow Parishioner (self-assigned, SA01)
The horde grunt from the research roster: a hooded cultist, hunched, lantern in hand. `Blender/make_parishioner.py`: a deeply hunched grey-violet robe, a big round hood hanging forward with a dark hollow face, a back hump, one arm holding a tall lantern pole. 3.25 wide, 3.9 high, 332 triangles; front overlap with the nearest familiar 0.34 (Sentinel). The first two versions (hand lantern; pole at the body) scored 0.75 and 0.51 against Ward; the pole was moved outward. Uploaded as asset 94567177585107. Known flaws: flat boxes, no rig, the lantern glow is bright gold, not faint.
