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

- [x] Wire `AbilityFX.rend` to a pet ability (tier 3+ crits) and add impact frame + smooth shake (2026-10-26)
- [x] Boss escape telegraph ring and scorch after big hits (2026-10-26)
- [x] (2026-10-27: not needed this time; the Studio-imported meshes were used instead, see below) **Needs the user:** create an Open Cloud API key (Assets read+write) and OK the first real upload with `tools/upload_asset.py` (StarDrake/Frostling FBX would skip the manual import)
- [ ] **Needs the user:** 10-15 min session on a real phone with MicroProfiler / F9 memory
- [ ] Textured Beam crescent for Verdant Rend (needs one uploaded texture)
- [ ] Needs the user: watch Verdant Rend in Play and judge feel; send a sharper frame or the source for the bbstudios4 font if wanted

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
- [x] (2026-10-27: imported by the user, wired in as `ReplicatedStorage.PetMeshes`; in-game pets now use the meshes, flat colour, no rig animation yet) Needs the user: import Blender\import_ready\StarDrake.fbx and Frostling.fbx (Asset Manager > Import > 3D), then Claude runs post_import_fix.luau and tests; approve or reject the other five pets from Blender/out_pets/review_sheet.jpg
- [ ] Balance check: waves cleared by leaks (no defenders) still advance the stage and pay the tutorial gems; decide whether leaks should pay less. (Reveal covering the ultimate banner: fixed 2026-10-26, banners now wait for the reveal.)
- [x] (2026-10-27: Idle loops and Attack plays on each shot via `Models.playClip`; Spawn clip is empty in Roblox (scale-only), so the existing pop-in stays) Play the imported Idle/Attack/Spawn clips on the Frostling and Star Drake meshes (they sit in ServerStorage.RBX_ANIMSAVES; the pets are anchored and only bob through the pivot today)
- [ ] Approve or reject the other five Blender pets so they can replace their shape versions the same way (add to MESHED in Models)
- [ ] **Needs the user before going live:** upload the Frostling/Star Drake Idle and Attack clips as Animation assets (Studio: right-click the KeyframeSequence in ReplicatedStorage.PetAnims > Save to Roblox) and paste the ids into `UPLOADED` in Models. Without that, clips only play in Studio
- [ ] Watch a real wave with a Frostling or Star Drake on a pad (the in-run hook was not observed; the debug hatch does not keep pets)
- [x] (2026-10-27) UI pass 2 from [[Research/bbstudios UI Reference]]: rows stagger in after the unroll, dim + sigil intro on Progression and Skill Tree, Odds/Progression sit below the tutorial scroll
- [ ] UI pass 3: restyle the Skill Tree detail card and the Pet panel contents as scroll pieces; painted banner/card art (needs uploads)
- [x] (2026-10-27, enabled by the user; glass UI checked in Play) **Needs the user:** turn on Experience Settings > Security > Allow Mesh / Image APIs (owner must be 13+ ID verified), then Claude checks the glass UI against the reference
- [x] (2026-10-27) Glass pass 4: HP bar, Skill Tree detail card and Pet panel rows in the glass style; painted emblem symbols
- [x] (2026-10-27) Glass pass 5: Skill Tree hexes and the hatch-reveal glow/rays/titles
- [x] (2026-10-27, 0558bc7 pushed) **Decide:** remove `archive-JKGEwB/gk_3.1.77_windows_amd64.zip` (9.9 MB, not ours) from the repo? It was pushed in 8e97690
- [x] (2026-10-27) Build stage 1 "Lampwick Lane" backdrop (three rings + fog recipe) from [[Research/Backgrounds and Enemies - Mystic Victorian]]
- [x] (2026-10-27) Restyle enemies to the roster (Hollow Parishioner, Fog Wisp, Brass Sentinel, The Unbound) with the silhouette and greyscale checks
- [ ] Phone check of Lampwick Lane (10 shadow lamps + fog particles); add a Low setting that turns lamp shadows off if needed
- [ ] Stage sets 2 to 5 (Harbour of Brass, Silent Cathedral, Clockwork Foundry, Above the Grey Veil) and switching backdrop by stage
- [ ] Restyle the portal (still a neon purple slab) and crystal to fit Lampwick Lane
