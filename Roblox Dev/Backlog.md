# Backlog

Top = next. Keep "Now" to 3 items or fewer.

## Now
- [x] Connect Studio to Claude (verified 2026-10-24: Claude.rbxl listed, game tree read; place is default Baseplate)
- [x] Choose concept: merge tower defense, see [[Game Design Doc]]
- [~] v2 rework 2026-10-24 after playtest feedback (gem rolls, adjacent merge, move, ability upgrades, no-lose stakes, close camera, left rail, highlighted tutorial). Verified: headless tests, scripted tutorial run to stage 2. NOT verified by a human: drag feel, layout, phone.
- [~] (old) Vertical slice built 2026-10-24 (Shared/Config, Path, MatchSim; ServerScriptService/MatchService; StarterPlayerScripts/GameClient; Workspace/Map). Verified: headless logic tests, scripted Play run with no errors from our scripts. NOT verified: real drag input, visuals by eye, phone layout. Next: user plays it once.

## Next
- [x] Re-imported v2 and verified (upright, clips play); duplicates deleted 2026-10-25
- [ ] **Needs the user:** attach reference images for the first real set of distinct pets ([[Research/3D Model Workflow|3D Model Workflow]]), and publish the clips as Animation assets when ready
- [~] Recreate the screenshot UIs in order: LobbyHud and BattlePass built 2026-10-25; CrateClaim, UnitView and ModeSelect built the same day; EventShop, PassShop, Profile and FirstDraw built the same day (9 screens in UIScreens2); next: unlock toast and island portals, equip-best inventory, tutorial steps, free-reward popup, idle columns, aura viewer list, settings variants, loading warning, trade menu, fishing family. Pick the order for recreating the screenshot UIs ([[Research/UI Recreation Coverage|UI Recreation Coverage]]) and whether the game HUD moves onto the UI Kit
- [ ] Wire the imported pet into `Models.buildPet` (stand-up rotation, Animator, pose-name fix) and play it in a real match
- [~] (imported 2026-10-24, tested, 4 bugs found; see workflow note) import `Blender\out\StarDrake_T1.fbx` with Studio's Bulk Import (OK given 2026-10-24; Claude cannot trigger it), then Claude tests it ([[Research/Asset and Animation Workflow|workflow]])
- [ ] Blender idle/attack animation for the other 6 pets and the 4 enemies
- [ ] Blender cinematic hatch (shell pieces, shards, rarity styles)
- [ ] Blender: find blender.exe, then egg/shard models and animation per [[Research/Blender Cinematic Pipeline|Blender Cinematic Pipeline]]
- [ ] Skill tree polish: connecting lines, respec, next-best hint
- [ ] Per-pet ultimates (each pet its own effect)
- [x] Set up Hunyuan3D-2 locally (mini-Turbo, shape only on 8 GB GPU)
- [ ] Decide source of reference images for Hunyuan3D (user-supplied or Studio renders)
- [ ] ProfileStore insert + data schema
- [ ] Waves, enemy types, boss with telegraphed attack
- [ ] Ultimates and VFX
- [ ] Crate roll (server) + reveal UI + odds panel
- [ ] HUD, menus, UIAnimator, sounds, music
- [ ] Settings foundation: `SettingsDefaults` module, `NumberFormat` function with headless tests (999, 1500, 1.5M, 13.66T, grouped, scientific, zero, negative), `settings` in the profile schema
- [ ] Settings panel (gear button, Sound / Display / Accessibility sections, reset to defaults) and `SettingsController`; server validation and rate limit on the save event
- [ ] Wire settings into systems: particle cap in VFX pool, Flashes On/Off with a no-flash crate reveal and boss intro, lobby Backdrop Moving/Still, `NumberFormat` on every number in HUD and results
- [ ] Flashing-lights notice on the loading screen (needed once any flash effect exists)
- [ ] Verify settings: each one changes what the Game Design Doc says, persists across rejoin, bad values rejected, Particles Low keeps frame rate steady on the baseline phone
- [ ] Tutorial, analytics events, daily rewards
- [ ] Passes + premium pet dev products (user creates in Creator Hub)
- [ ] Test matrix pass, bug log clean, balance simulator

## Later
- [ ] Publish (user clicks)
- [ ] Watch D1 retention and session time (see [[Analytics/Analytics Log|Analytics Log]])
- [ ] Worlds 2 and 3, co-op, events
- [ ] Settings, second batch: reduced motion, screen shake, damage numbers, UI size (read Roblox's [accessibility player preferences](https://create.roblox.com/docs/production/publishing/accessibility) first), rarity icons beside colour, hide-UI mode, haptics, quality preset

## Ideas (not committed)
- Git repo for scripts (needs user OK)
- [ ] Wire the new Lobby HUD to real data once ProfileStore and the economy exist (gems, keys, coins, rolls, leaderboard); in-match HUD (GameClient) still uses its own old UI
- [ ] Verify the restyled in-match panels (Pet upgrades, Odds, Progression, Skill Tree) and a full wave plus boss in Play after the HUD restyle; test on a real phone
- [ ] GameClient local count: keep new top-level helpers inside the UI table (limit 200)
- [ ] Test boss stage and the Pet upgrade panel after the HUD restyle; upload UI sprites to Roblox (needs the user's OK) before shipping
- [x] Boss stage and Pet panel tested after the HUD restyle (2026-10-26)
- [ ] Needs the user: import Blender\import_ready\StarDrake.fbx and Frostling.fbx (Asset Manager > Import > 3D), then Claude runs post_import_fix.luau and tests; approve or reject the other five pets from Blender/out_pets/review_sheet.jpg
- [ ] Balance check: waves cleared by leaks (no defenders) still advance the stage and pay the tutorial gems; decide whether leaks should pay less. Also: reveal card can cover the ultimate banner during Auto.
