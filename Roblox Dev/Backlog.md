# Backlog

Top = next. Keep "Now" to 3 items or fewer.

## Next up (picked by Claude; see [[Feature Pipeline]])
1. Stage sets 2 to 5 as data (one folder per set, backdrop switches by stage), starting with Harbour of Brass
2. [x] (2026-10-27) Familiar attack feel: per-familiar projectiles via the `Shot` attribute; next: a hit reaction on enemies per style
3. Settings panel (reduced motion, flashes, shake, sound volume) wired to the existing SETTINGS stub
4. Balance check: leaked waves still advance and pay

1a. Candidates from the priority reference videos (stage captions in cutscenes, per-rarity reveal worlds, objective HUD, Bezier projectiles): see [[Research/VFX and Animation/Reference Video Study 2 - Priority Links]]; user to pick
1b. Star Drake STARFALL cutscene: beams are plain cylinders, rebuild as layered beams + impact set per [[Research/VFX and Animation/Beam and Impact VFX Recipes]]; effects need work (user, 2026-10-27; specifics pending, see [[User Inputs]])

**Needs the user:** (HOLD until the workflow-tools session finishes, user's order; route chosen and installed: ffmpeg + yt-dlp, all 19 videos extracted) study the 19 reference links, PRIORITY: 3 UI links and 6 benchmark-quality links.

User reports the game was tested on mobile and works fine ([[User Inputs]]); confirm which phone items below are covered.

**Needs the user:** phone test (placement, range circle, Lampwick Lane cost); uploads (clips, sprites); commits.

## Now
- [x] Connect Studio to Claude (verified 2026-10-24: Claude.rbxl listed, game tree read; place is default Baseplate)
- [x] Choose concept: merge tower defense, see [[Game Design Doc]]
- [~] v2 rework 2026-10-24 after playtest feedback (gem rolls, adjacent merge, move, ability upgrades, no-lose stakes, close camera, left rail, highlighted tutorial). Verified: headless tests, scripted tutorial run to stage 2. NOT verified by a human: drag feel, layout, phone.
- [~] (old) Vertical slice built 2026-10-24 (Shared/Config, Path, MatchSim; ServerScriptService/MatchService; StarterPlayerScripts/GameClient; Workspace/Map). Verified: headless logic tests, scripted Play run with no errors from our scripts. NOT verified: real drag input, visuals by eye, phone layout. Next: user plays it once.

## Next
- [x] Re-imported v2 and verified (upright, clips play); duplicates deleted 2026-10-25
- [ ] **Needs the user:** attach reference images for the first real set of distinct pets ([[Research/3D and Art/3D Model Workflow|3D Model Workflow]]), and publish the clips as Animation assets when ready
- [~] Recreate the screenshot UIs in order: LobbyHud and BattlePass built 2026-10-25; CrateClaim, UnitView and ModeSelect built the same day; EventShop, PassShop, Profile and FirstDraw built the same day (9 screens in UIScreens2); next: unlock toast and island portals, equip-best inventory, tutorial steps, free-reward popup, idle columns, aura viewer list, settings variants, loading warning, trade menu, fishing family. Pick the order for recreating the screenshot UIs ([[Research/UI/UI Recreation Coverage|UI Recreation Coverage]]) and whether the game HUD moves onto the UI Kit
- [ ] Wire the imported pet into `Models.buildPet` (stand-up rotation, Animator, pose-name fix) and play it in a real match
- [~] (imported 2026-10-24, tested, 4 bugs found; see workflow note) import `Blender\out\StarDrake_T1.fbx` with Studio's Bulk Import (OK given 2026-10-24; Claude cannot trigger it), then Claude tests it ([[Research/3D and Art/Asset and Animation Workflow|workflow]])
- [ ] Blender idle/attack animation for the other 6 pets and the 4 enemies
- [ ] Blender cinematic hatch (shell pieces, shards, rarity styles)
- [ ] Blender: find blender.exe, then egg/shard models and animation per [[Research/3D and Art/Blender Cinematic Pipeline|Blender Cinematic Pipeline]]
- [ ] Skill tree polish: connecting lines, respec, next-best hint
- [ ] Per-pet ultimates (each pet its own effect)
- [x] Set up Hunyuan3D-2 locally (mini-Turbo, shape only on 8 GB GPU)
- [ ] Decide source of reference images for Hunyuan3D (user-supplied or Studio renders)
- [x] ProfileStore insert + data schema (meta only for now: level, xp, sp, gems, tree)
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
- [x] (2026-10-27, obsolete: pets are now familiar models in Characters folders) Approve or reject the other five Blender pets so they can replace their shape versions the same way (add to MESHED in Models)
- [ ] **Needs the user before going live:** upload the Frostling/Star Drake Idle and Attack clips (now in `ReplicatedStorage.Characters/<id>/Animations`; right-click a KeyframeSequence > Save to Roblox) and replace each with an Animation object holding the id. Without that, clips only play in Studio
- [x] (2026-10-27) Watch a real wave with a Frostling on the board (seen from the game camera; pads no longer exist)
- [x] (2026-10-27) UI pass 2 from [[Research/UI/bbstudios UI Reference]]: rows stagger in after the unroll, dim + sigil intro on Progression and Skill Tree, Odds/Progression sit below the tutorial scroll
- [x] (2026-10-27, superseded by the glass passes) UI pass 3: restyle the Skill Tree detail card and the Pet panel contents
- [x] (2026-10-27, enabled by the user; glass UI checked in Play) **Needs the user:** turn on Experience Settings > Security > Allow Mesh / Image APIs (owner must be 13+ ID verified), then Claude checks the glass UI against the reference
- [x] (2026-10-27) Glass pass 4: HP bar, Skill Tree detail card and Pet panel rows in the glass style; painted emblem symbols
- [x] (2026-10-27) Glass pass 5: Skill Tree hexes and the hatch-reveal glow/rays/titles
- [x] (2026-10-27, 0558bc7 pushed) **Decide:** remove `archive-JKGEwB/gk_3.1.77_windows_amd64.zip` (9.9 MB, not ours) from the repo? It was pushed in 8e97690
- [x] (2026-10-27) Build stage 1 "Lampwick Lane" backdrop (three rings + fog recipe) from [[Research/3D and Art/Backgrounds and Enemies - Mystic Victorian]]
- [x] (2026-10-27) Restyle enemies to the roster (Hollow Parishioner, Fog Wisp, Brass Sentinel, The Unbound) with the silhouette and greyscale checks
- [ ] Phone check of Lampwick Lane (10 shadow lamps + fog particles); add a Low setting that turns lamp shadows off if needed
- [ ] Stage sets 2 to 5 (Harbour of Brass, Silent Cathedral, Clockwork Foundry, Above the Grey Veil) and switching backdrop by stage
- [x] (2026-10-27) Restyle the portal (Fog Gate) and crystal (Ward Lantern) to fit Lampwick Lane
- [x] (2026-10-27) Free placement with per-character ranges and footprints; range circle; data-driven characters; summoning card replaces the egg
- [x] (2026-10-27) Restyle the pet roster as mystic familiars (rarity escalation: variants, glow, aura) using the Characters folders
- [x] (2026-10-27) Card flip that shows the pet silhouette before the burst; reveal sounds
- [ ] Phone test: drag placement and range circle with touch
- [ ] More maps/paths with line-of-sight blockers (difficulty from length and blockers)
- [x] ProfileStore saving of gems, level, xp, skill points and skill tree (audit finding 1, 2026-10-27; `Vendor/ProfileStore.luau`, `MatchService`). A rejoin on the live game is still unchecked
- [ ] Split GameClient (3,294 lines, at Luau's 200-local limit): move reveal and ultimate into modules (audit finding 8)
- [ ] Delete duplicate audio: `Audio/Upload/music` vs `Audio/Music/game` (5 identical pairs) and raw mp3s (audit finding 7)
- [ ] Apply the layered-beam kit (`CutsceneFX.kit.beam/impact/caption`) to GRAND ARCANA pillars and WINTER'S HUSH

## From the community research (2026-10-27, suggestions, not started)
- [ ] Spring helper for button press and hover, compared with tweens by the user ([[Research/UI/Community UI Approaches|Community UI Approaches]])
- [ ] Blender-made slash/ring/crescent mesh set for cutscenes and projectiles ([[Research/VFX and Animation/Community VFX Techniques|Community VFX Techniques]])
- [ ] Test the Studio MCP `generate_mesh` tool once and record what it returns; GenerationService.GenerateMeshAsync is deprecated ([[Research/3D and Art/Community 3D Pipelines|Community 3D Pipelines]])
- [ ] Decide how to get Studio-only scripts into git: local export vs a mirror MCP server ([[Research/Process and Tools/Community Vaults and Workflows|Community Vaults and Workflows]])
- [ ] Add `Handoff:` to unfinished Session Log lines; monthly vault lint
