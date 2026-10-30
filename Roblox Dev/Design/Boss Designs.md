# Boss designs (T143 to T147)
One boss at the end of each stage set (stages 5, 10, 15, 20, 25). The five fights follow the Clockmaker's grief arc from [[The Clockmaker]] (denial, bargaining, anger, sorrow, acceptance) and use the five story clues of the same note. Today the game has one generic `Boss` (700 hp, speed 4, size 6.5, `Config.hpScale` 1.2 per stage). The numbers below are PROPOSALS for balance testing, relative to that boss at its stage; the server side is implemented (2026-10-29, see [[Boss Framework]]: three phases, deny, freeze, summon, slow aura, regen, speed and damage effects; the per-boss special mechanics noted there are not); the client does not show phases yet. Models: [[Enemy Models]] (concept-grade). Phase rule for all five: three phases at 100%, 66% and 33% hp, each with a visual change, a sound and a new attack (see T148 and T149 for the transitions and the bar).

## 1. The Unbound, stage 5 (T143), act 1: denial
Faceless fog figure; it rolls back what the player just did. Hp 1.0x. Phase 1 (bank of fog, drifting): slow walk; every 10 s it "denies" the last placed unit, which loses its next shot (telegraph: the unit's glow flickers for 1 s). Phase 2 (risen, arms wide): the fog thickens, towers at the lane edge lose 20% range; a ring of shards fires at the nearest tower every 6 s (telegraph: the shards light teal 1 s before). Phase 3 (the cloak gone): it splits into the head, two hands and a core; killing the hollow core, not the head, ends it. Clue: the street clock with no hands. Counter: keep a spare unit ready and focus the core.

## 2. The Clockmaker's Automaton, stage 10 (T144), act 2: bargaining
A gear-engine that slows the board. Hp 1.6x, speed 3. Phase 1: a slow aura (unit cooldowns lengthen 15% within 12 studs) and it winds its own cranks every 8 s, healing 5% (telegraph: the crank handle glows bright). Phase 2: it offers a pause: for 4 s all units freeze but so does the automaton, and a lit lamp on the path heals the player 1 life (the bargain). Phase 3: the gears overheat; steam vents on the path every 5 s damage units on the nearest slots (telegraph: the vent hisses 1 s). Clue: the cranks are clean. Counter: out-damage the winding; ignore the offer or use it to merge.

## 3. The Star Choir's Echo, stage 15 (T145), act 3: anger
Sings and pushes familiars; a choir mechanic. Hp 1.8x. Phase 1: one singer; its note pushes the nearest unit one slot away every 9 s (telegraph: a rising chime and a ring on the pushed unit). Phase 2: two echoes appear and each repeats the last note a moment later, so pushes come in pairs; killing an echo before it repeats cancels the repeat. Phase 3: the three sing a chord; the fog thickens and units lose range unless the player kills an echo within 10 s. Clue: a covered statue with a child's lantern at its feet. Counter: kill the echoes first; keep units away from slot edges.

## 4. The Hollow Court Regent, stage 20 (T146), act 4: sorrow
A crown of candles and the Foundry's bell; summons mourners. Hp 2.2x. Phase 1: it rings the bell every 12 s, spawning 3 Hollow Parishioners (telegraph: the bell tolls twice). Phase 2: it lights its candles one by one (7 candles); each lit candle adds 8% damage reduction, and killing a mourner snuffs a candle. Phase 3: the fog thins and the crown burns down; the bell tolls faster and summons stop, but it moves at double speed for the last stretch. Clue: the cold furnace, one lit door, a small coat on a hook. Counter: kill the mourners to snuff the candles before bursting it.

## 5. The Clockmaker, stage 25 (T147), act 5: acceptance
Time stop; reverses one merge per wave. Hp 3.0x. Phase 1: it walks behind its own clock; at the start of each wave it un-merges one of the player's merged units back into its parts (the lantern flare from [[The Cosmic Turn]] can hold one merge, spent as a shield). Phase 2: time stop: every 20 s all units freeze for 3 s (telegraph: the clock hands halt and a deep tick; the flare can shorten it to 1.5 s). Phase 3: the hands run backwards and the lamp in its chest brightens; hitting the lamp (a small hit zone) ends the fight and plays the ending (option 3: the closing scene `[ THE CLOCK TURNS ]`). Counter: save the flare, keep spare merge material, hit the lamp.

## Cross-cutting
- Each boss gets a phase bar with three ticks (T149) and a banner at each phase change (T148).
- Rewards scale from the generic boss (60 coins, 25 gems): 1.0x, 1.6x, 2.0x, 2.5x, 4.0x (PROPOSAL).
- None of this exists in code: Config.ENEMIES has one `Boss`. Implementing it needs per-boss definitions, phase logic in MatchService and a client phase bar.

## Open questions for the user
0. The Unbound is faceless fog (the user confirmed 2026-10-29).
1. Is a unique mechanic per boss (above) wanted, or a lighter reskin of one boss?
2. Is un-merging a unit (boss 5) acceptable, given it undoes the player's progress? The lore says the Clockmaker will undo merges; it is still a design call for the user.
