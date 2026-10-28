---
date: 2026-10-28
tags: [ui, vfx, method, creative]
---
# Creative Fix Method

How to turn anything generic in the game into something crafted and themed. Use it by telling Claude in one line what is generic, for example `/make-creative settings buttons` or "the shop is too generic". The skill `.claude/skills/make-creative/SKILL.md` runs this loop and adds a row to the Log below every time. Related: [[Research/UI/UI Rework 2026-10-28]], [[Research/VFX and Animation/Cinematic Cutscenes]], [[Research/VFX and Animation/Crafted Sheet Techniques]], [[Planning/Immersion - Every Action a Cutscene]].

## The rule
Every control is a **physical object from Lampwick Lane**, and its own motion is the feedback. Every big action is a **short cutscene** (skippable, shorter on repeats, obeys the Cutscenes setting). Generic = the same glass pill everywhere, flat colour, no motion, no story.

Sources behind it: Inscryption's diegetic table (a bell ends the turn, candles are lives) ([DiGRA](https://dl.digra.org/index.php/dl/article/view/2474)); Persona 5's one signature colour and posed motion ([Siliconera](https://www.siliconera.com/atlus-reveals-design-secrets-behind-persona-5s-distinctive-ui/)); Dead Space's in-world menus ([Game Developer: diegesis](https://www.gamedeveloper.com/design/diegesis-and-designing-for-immersion), [hudsandguis](https://www.hudsandguis.com/home/2012/08/22/dead-space-2-diegetic-interface-design)); trade-off: diegetic elements can hide information, so keep labels and numbers readable ([Wayline](https://www.wayline.io/blog/designing-immersive-pause-menus)).

## The loop (7 steps)
1. Capture it in Play and say in one line why it is generic.
2. One or two searches or a video frame study: how do distinctive games do this?
3. Pick a world metaphor (table below; reuse first).
4. Art: reuse uploaded ids; new object art with ComfyUI (`--style sols`), ingest, crop, upload; effects with `tools/fx_craft.py`.
5. Build in the owning module; keep behaviour; big actions use the CutsceneFX kit with `FXK.cineOff/cineShort/busy`.
6. Check in Play with captures or recordings; fix the biggest problem; 2 to 3 rounds.
7. Record: before/after in `Creative Fixes/`, a Log row here, a Session Log line.

## Metaphor table (what already exists)
| Game thing | Object | Motion = feedback | Art / code |
|---|---|---|---|
| ROLL | tarot card on a deck | tilts, lifts on hover, flips on press | `obj_tarot`, `obj_deck` |
| Roll reveal | The Reading: card on a candlelit table | rim climbs rarity colours, player turns Epic+, shatters | `RevealSection.luau` |
| START WAVE | brass bell | swings when rung; bell-tower cutscene | `obj_bell`, `FXK.bellCut` |
| ULT | pocket watch | hand sweeps as it charges; first-person cutscene | `obj_watch`, `CutsceneFX.FirstPerson` |
| AUTO / QUICK | brass dial + lamp | dial turns a quarter, lamp lights | `obj_dial` |
| Dock (left) | wax seals | badge on the seal | `obj_seal` |
| Stage | hanging iron sign | sways | `obj_sign` |
| Bottom bar | mahogany desk | everything sits on it | `obj_desk` |
| Coins / gems | brass plates | pop on gain | `obj_plaque` |
| Streak | flame badge | flame flickers, pops per perfect stage | `icon_flame` |
| Volume | brass rail, lantern knob | flame brightens with volume | `SettingsPanel.slider` |
| On / off | candle | lit / snuffed with smoke | `SettingsPanel.toggle` |
| Choice | engraved brass plate | gold pointer slides to the pick | `SettingsPanel.choice` |
| Familiar upgrades | keeper's ledger lamps + coin plates | lamps light per level | `GameClient` ledger block |
| Reset | wax seal on a plate | "break the seal" | `SettingsPanel` |
| Skill tree | lantern tree in a courtyard | first-person walk, branches grow, lantern flares on buy | `SkillGrove.luau` |
| Progression | road of milestone stones | first-person walk, lanterns flare as you pass | `TrainerRoad.luau` |
| Level up | the street's gas lamps | flare violet toward the crystal | `FXK.levelCut` |
| Defeat | lamps going out | darkness creeps down the lane, relights | `FXK.darkCut` (`ActionCuts.luau`) |
| Odds | fortune spread of tarot cards | cards fan out, tinted by rarity | `UI.oddsSpread` |
| Start / Play | lamp to light | "LIGHT THE LAMP", flame on the button | `GameClient` start menu |
| Tutorial | parchment note from the Lamplighter | ink writes itself in, paper rustle | `GameClient` tutorial block |
| Cutscene sound | one cue per beat | thud = loss, chime = win, swell = relight | `SoundCatalog` names via `FXK.play` |
| Crystal life | glass vial of violet lamp-oil, brass caps | liquid shimmers; turns red and the glass pulses under 30% | `GameClient` vial block |
| Trainer level | brass clock-bezel medallion, flame behind the number | flame flickers; XP on a brass rail with an amber channel | `GameClient` vial block |
| Boss bar | iron plate on chains: name, blood-red life ribbon, burning wick timer | swings in with a clank; pale trail catches up after hits; flame races down the wick, turns red and a watch ticks under 10 s | `GameClient` boss plate block |
| Game sounds | one sound per object | brass click on buttons, card flip on ROLL, bell toll on START WAVE, hit thud, smoke poof, coin clink, glass crack on leaks, wooden knock on move | `VFX/sfx/make_sfx.py` LAMPWICK set |
Unused ideas to try next: shop as a curio cabinet with drawers; daily reward as a letter with a wax seal; leaderboard as a newspaper front page; quests as a notice board with pinned notes.

## Pitfalls seen (check every time)
Dark text on dark object art; panels hidden behind the desk; white blow-out under bloom (threshold 0.92, keep Neon small and half-transparent); cameras inside geometry (canopy, crowds); a local named like a helper (`shade`) breaks later code; GameClient is near Luau's 200-local limit (wrap new blocks in `do ... end`); Studio caches `require`d modules during an Edit-mode test (test a clone); mouse input is about 58 px above viewport coordinates.

## Log
| Date | Thing | Before | Metaphor | Result | Evidence |
|---|---|---|---|---|---|
| 2026-10-28 | HUD buttons | identical glass pills | objects (table above) | built, seen in Play | `Creative Fixes/hud_before.png`, `hud_after.png` |
| 2026-10-28 | Settings controls | grey pills, blue bars, ON/OFF pills | instrument board: rails with lantern knobs, candles, brass plates with sliding pointer, wax-seal reset; Cutscenes row added | built, seen in Play; desk hides while the board is open | `Creative Fixes/settings_before.png`, `settings_after.png` |
| 2026-10-28 | Familiar panel | gold/grey pips, green price pills, red Delete | keeper's ledger: five lamps per upgrade light one by one, brass coin plates for prices (dim when unaffordable), Release under a wax seal; camera leans in on the familiar | built, bought one level in Play (lamp lit, price 12 to 21) | `Creative Fixes/pet_panel_before_sheet.jpg`, `pet_panel_after.png`, `pet_panel_after_buy.png` |
| 2026-10-28 | Odds panel | plain list of rarity rows | fortune spread: fanned tarot cards tinted by rarity, crystal-ball ODDS chip | built, seen in Play | `Creative Fixes/odds_after_v1.png` |
| 2026-10-28 | Start menu buttons | same glass pills as the HUD | "LIGHT THE LAMP" play button with a flame, Lampwick Gazette notice, brass Flashes plate | built, seen in Play | `Creative Fixes/start_before.png`, `start_after.png` |
| 2026-10-28 | Tutorial card | dark glass box, grey Skip pill | a note from the Lamplighter: parchment, wax-seal flame, ink that writes itself in, signature, brass Skip tag, paper rustle | built, seen in Play (rustle sound logged) | `Creative Fixes/tutorial_after.png` |
| 2026-10-28 | Cutscene sound | most cutscenes had one cue at the start | a cue on every beat: thud on bad captions, chime on good ones, swell when lamps relight, low surge for bosses | built in `ActionCuts.luau`; level-up, defeat, leak, stage-clear and boss-clear cues logged in Play; boss arrival, bell, Ascension and Farewell not triggered yet | sound log in Play |
| 2026-10-28 | Crystal HP + trainer badge | blue progress bar, purple circle with a plain purple XP bar | violet lamp-oil vial with brass caps (red pulse when low); brass clock-bezel medallion with a flame, amber XP rail | built, seen in Play; low-HP state checked | `Creative Fixes/top_hud_before.png`, `top_hud_after.png`, `vial_low_hp.png` |
| 2026-10-28 | Boss bar, game sounds, enemy and familiar motion | thin red timer bar; game silent between cutscenes; every enemy the same bounce, quick spin-shrink death; familiars always face the camera | wick-and-plate boss bar; 10 new synthesized sounds wired to hits, kills, coins, leaks, moves, upgrades, buttons and the boss timer; enemies lean, dip and bank into bends, flash white and swell before dying with a smoke wisp; familiars turn to aim and recoil | built, seen in Play; sounds logged, tilt and death measured, aim yaw measured | `Creative Fixes/boss_plate_after.png` |
| 2026-10-28 | Whole HUD (abstract blend) | heavy desk slab, boxed plates, floating controls, plain ODDS ball | abstract layer around the objects: ink field, violet disc + orbits behind ROLL, amber triangle behind START WAVE, gold line and points, seer's eye, flat bands; rules in [[Research/UI/Abstract UI]] | built, seen in Play (2 rounds) | `Creative Fixes/abstract_before.png`, `abstract_after.png` |
