# Enemy bible (T133 to T137)
Six enemy families. Numbers marked PROPOSAL are design targets, not in the game: the game today has four kinds in `Config.ENEMIES` (Grunt 30 hp speed 8, Swift 18 hp speed 13, Tank 120 hp speed 5, Boss 700 hp speed 4). Silhouette and colour rules come from [[Backgrounds and Enemies - Mystic Victorian]] (one palette per layer, variation by tint, wear and props only). Models: [[Enemy Models]]. Lore voice: [[The Clockmaker]].

| Family | Layer / game slot | Role in play | Silhouette and colour | Model |
|---|---|---|---|---|
| Hollow Parishioner | horde / Grunt | the crowd; teaches the lane and the merge economy | hunched hood, small lantern; grey-violet | HollowParishioner (SA01) |
| Fog Wisp | fast / Swift | arrives early, slips past slow towers, eats lantern light | long trailing cloak, no legs; pale cold blue | FogWisp (T114) |
| Brass Sentinel | heavy / Tank | soaks damage, punishes thin defences; stiff and telegraphed | square shoulders, back boiler; dark brass, red slit | BrassSentinel (T115) |
| Clockwork Crow | fast flyer (new) | skips the lane's blockers; takes a unit's place for one wave | wide raised wings, key on its back; dark steel, brass beak | ClockworkCrow (T116) |
| Lantern Thief | special (new) | goes for the path's lamps and carries the light off | crouched, raised stolen lantern, sack; dark coat, gold glow | LanternThief (T117) |
| The Unbound | boss, stage 5 | see [[Boss Designs]] | faceless fog figure; blue-grey | Unbound x3 (T118) |

## Family notes
**Hollow Parishioner.** Lore: the Guild's worshippers, hollowed out when the clock stopped; they still walk their old procession route carrying lanterns that no longer light. Counter: anything. A parishioner that reaches the end costs 1 life (`leak = 1`). Elite variants carry a floating card with a gold rim (research note).

**Fog Wisp (T134, redesign).** A wisp that eats lantern light: when it passes a lit lamp on the path the lamp goes dark for 6 seconds (PROPOSAL), which removes the lamp's small aura from nearby towers; killing the wisp early keeps the lamps. Readable silhouette: low, long, pale, no legs. Sound cue (PROPOSAL, needs audio): a thin rising breath that starts one second before it reaches a lamp, so the player can react. Current model: a hooded tadpole shape; the lantern-eating idea is behaviour, not in the model.

**Brass Sentinel (T135, redesign).** A stiff guard with telegraphed steps: every third step it plants its feet for 0.6 seconds (a brass clank and a steam puff from the chimney) and is immune to knockback and slow during the plant, then lurches forward (PROPOSAL). The telegraph is the plant: the player sees and hears when it is safe to burst it down. Counter: burst damage between plants; slows are wasted during the plant.

**Clockwork Crow (T136).** A fast flyer (speed about 16, 12 hp, PROPOSAL) that ignores path blockers and flies the straight line between the portal and the gate. It takes a unit's place for one wave: when it lands it perches on a tower slot and that unit stops firing for the rest of the wave unless the crow is killed. Counter: ranged units and any familiar that can hit flyers. Telegraph: a metallic ratchet sound as it dives. Model: raised flap pose, brass beak, red eyes.

**Lantern Thief (T137).** Walks the path to the nearest lit lamp, takes it (the lamp goes dark and the thief glows), then runs for the exit at speed 11 (PROPOSAL, 40 hp). If killed carrying a lamp it drops the stolen light as a pickup that relights the lamp and pays a small coin bonus; if it escapes, the lamp stays dark for the rest of the stage and the player loses 1 life. Telegraph: the sack rustles and the thief hunches before it grabs. Counter: put damage near lamps.

## Open questions for the user
1. RESOLVED 2026-10-29 (the user: "yes faceless"): the Unbound is the faceless figure of fog, as modelled; the research note's mage design is dropped.
2. Are 6 families the right count?
3. Are the numbers above acceptable as starting points for balance tests?
