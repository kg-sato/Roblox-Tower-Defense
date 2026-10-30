# Combat systems implemented (2026-10-29, Sonnet, at the user's request)
The user: "Add more tiers and rarities ... Roles are a good idea so are status effects. Enemy behavior needs to be added too. Work in the economy". Installed in Studio (Edit mode, not saved in the place file) and mirrored in `Studio_Export/Config.luau` and `MatchSim.luau`; tests in `Tests/Combat.test.luau` (51 checks), `Rules`, `ServerRules`; all 14 suites PASS. Designs: [[Familiar Systems]], [[Enemy Bible]].

## Tiers and rarities
- `Config.TIER_MAX` 5 to 8 (tier t needs 3^(t-1) tier-1 units; damage 3.5^(t-1); recycle 3^(t-1)).
- Two new rarities, Mythic (order 5, odds 0.4, multiplier 30) and Celestial (order 6, odds 0.08, multiplier 80). A rarity with no familiar has weight 0, so they are harmless until familiars exist; the odds panel and reveal loop over `RARITY_ORDER` (6 rows now, layout unchecked; `FXRecipes.ORDER` and `RevealFX` have no Mythic or Celestial entry, so a reveal of one would break until the UI side adds them).
- Open: no Mythic or Celestial familiar exists. Each needs a lore note, a model, a rig and stats.

## Roles (`Config.ROLES`, applied in `MatchSim.roleHit` and `auras`)
Ember lights burn; Moth-Lantern marks; Brass Hound hits twice every 5th shot; Sentinel pierces brass; Frostling chills; Gargoyle stuns on a crit; Ward adds 20% range to touching familiars; Archivist adds 15% attack speed to touching familiars; Mourner hushes; Mirror Chorister echoes 35% of a touching familiar's hit; Star Drake splashes 50% to enemies within 8 studs every 8th shot; Grey Veil Wraith pierces all armour and heals the crystal by 1 every 10 hits.

## Statuses (`Config.STATUS`, `MatchSim.applyStatus`)
Burn (3 s, 20% of the hit per second, refreshes), chill (2 s, up to 3 stacks, a full stack freezes 0.5 s), stun (1 s, then 5 s immunity), mark (4 s, +25% damage), hush (2 s, cancels an enemy special). Bosses halve durations and are never frozen. A planted Sentinel ignores chill and stun. Events: `Status`, `Echo`, `Drain`.

## Armour and damage types (`Config.ARMOR_MULT`, `DAMAGE_TYPE`)
Enemies: Grunt flesh, Swift fog, Tank brass, Boss none. Fire 0.7 against brass and 1.2 against flesh; ice 1.3 against brass; stone 0.7 and light 1.3 against fog; stone armour (no enemy yet) 0.7 spring and 1.3 cosmic.

## Enemy behaviour (`MatchSim.enemyTick`)
- Brass Tank: every 4 s a 1 s telegraph (`Telegraph` event), then a 0.6 s plant (`Plant`); hush cancels it.
- Clockwork Crow (new, 12 hp, speed 16): at half the path it perches on the nearest familiar for 6 s, which cannot fire (`Perch`); killing the crow frees it.
- Lantern Thief (new, 40 hp, speed 11): at 30% of the path it steals (`Steal`); leaking while carrying costs 1 extra crystal hp; killing it drops 10 coins (`Drop`).
- Not built: Fog Wisp lamp-eating (the board has no lamps in the sim), a Sentinel or Crow model in the client.

## Two flags, both off
- `Config.NEW_ENEMIES` (Crow and Thief in the wave lists): off, because the client has no model for them.
- `Config.MOVEMENT_EFFECTS` (slows, stuns, freezes, plants and the thief speed-up change enemy speed): off, because the client moves enemies at a constant speed from their spawn time and would show them in the wrong place. With it on the sim emits `Pace {id, dist, speed, t}` on every speed change; the client needs one handler: on `Pace`, set the enemy's `spawnTime` so that `(now - spawnTime) * speed` equals `dist` at `t`, and use the new speed. Until then roles that work through damage, marks, burn, auras, echo, splash, drain, perch and armour are live, and chill, stun and plant do nothing visible.

## Economy
`Config.HP_GROWTH` 1.2 to 1.27 (enemy hp per stage; stage 25 is 296 times stage 1 instead of 79). Bots (3 seeds, 20 minutes): the perfect "full" bot still clears 25 stages in 356 to 388 s (about 6 minutes; it was 5.5), the upgrade bot stalls at stage 16 (was 22), the roll bot at 11. Tried 1.25 (full bot 332 to 363 s) and 1.3 (seed 1 never clears stage 25, seed 3 takes 18 minutes). The perfect bot is bounded by 12 slots and tier 3, so more hp growth alone cannot slow it to 10 minutes without failing weaker players; the other levers (slots, merge cost, reward per kill) are in [[Balance Baseline 2026-10-29]] and [[Progression Rules]].

## Not changed
Nothing was deleted. The stale 694-line `MatchSim` copy in Studio is still there (Bug Log #3) because deleting it needs your OK.

## Update 2026-10-29: Crow, Thief and movement effects are ON
`Config.NEW_ENEMIES` and `Config.MOVEMENT_EFFECTS` are now true. Crow and Thief have client models (`ReplicatedStorage.EnemyCrowMesh` and `EnemyThiefMesh` from the uploaded GLBs, heights 2.6 and 4.4 in `Models.MESH_HEIGHT`, no walk or flap animation). The server emits `Pace {id, dist, speed, t}` whenever an enemy's speed multiplier changes (movement effects times the boss phase's speedMult); `StarterPlayerScripts.PaceClient` applies it (spawnTime = t - dist / speed; a stun is held at speed 1e-4) through the shared slot `ReplicatedStorage.EnemyPace`, which `GameClient` fills with one line. `MatchService` sets the Pace `t` to the game clock. Play check: a stage 12 wave spawned 2 Crows and 3 Thieves, 30 Pace events arrived, no script errors; the facing of the two new models at board zoom is unverified. Combat.test.luau now sets the flag off before its off-check.
