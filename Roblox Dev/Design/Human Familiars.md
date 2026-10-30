# Human familiars for the higher rarities (2026-10-29)
The user: "Higher rarities should have more human characters." Four new humans fill the two new rarities: **Mythic** [[CantorVesper]] and [[DameOrrery]], **Celestial** [[TheLamplighter]] and [[VeilWalker]] (16 familiars now; the old 12 are in [[Character Bible Index]]). All four are real human figures, much closer to the concept art than the earlier blob-like familiars.

## How they were made (reusable pipeline)
1. Concept: `tools/comfy_character.py <Name> --variants N [--view back]` (local ComfyUI, FLUX schnell Q4; full body, A-pose, magenta key, engraving look). Picked one front per character; one back view each except Veil Walker (its back concept was bare skin, so its back and sides use the front's row-median colour).
2. Shape: Hunyuan3D-2 mini-Turbo from the front image (`Hunyuan3D/generate.py input_pick --faces 18000`), about 8 s each.
3. Cleanup: `Blender/cleanup_familiar.py` (9,000 triangles, 5.0 tall), `Blender/remove_floaters.py` (cut 13 floating wrench chips off Dame Orrery).
4. Texture: `tools/prep_new_textures.py` then `Blender/bake_familiar_textures.py` (front and back projection, 1024 px), `tools/recolor_familiars.py` for the gold-ink palette (20% identity blend).
5. Rig: `Blender/rig_template.py` with the biped template (14 bones, `rig_spec.ARCHETYPE`), Walk and Attack clips from `Shared.FamiliarClips`.
6. Studio: uploaded rigged GLBs, set each model's ColorMap to the gold-ink image, built the `Characters` folders, roles in `Config.ROLES`, data in `Shared.Familiars` (lore notes in `Lore/Familiars/`, generator `tools/gen_familiars_luau.py`), collection art in `FamiliarArt`.

## Roles and stats (placeholders, tested in Tests/Combat.test.luau and Tests/Rules.test.luau)
| Familiar | Rarity | Damage, cooldown, range | Tier-1 dps | Role |
|---|---|---|---|---|
| Cantor Vesper | Mythic | 18, 1.2 s, 30 | 450 | Hymn: touching familiars +20% damage |
| Dame Orrery | Mythic | 22, 1.4 s, 24 | 471 | Rewind: every 10th shot resets touching cooldowns |
| The Lamplighter | Celestial | 14, 1.0 s, 28 | 1,120 | Kindle: every familiar +10% damage |
| Veil Walker | Celestial | 12, 0.8 s, 30 | 1,200 | Veil: every familiar +12% crit chance |
Odds now (luck 0): Common 59.71%, Rare 27.87%, Epic 9.95%, Legendary 1.99%, Mythic 0.40%, Celestial 0.08%.

## Assets (logged in tools/uploads.json)
Rigged models: Vesper 87320725806516, Orrery 100541943813006, Lamplighter 100337103280707, Veil Walker 89236664532172. Gold-ink textures (decal ids): 88233563120101, 104531048923567, 81472362180131, 126845041722270 (image ids in the Studio ColorMaps). Cutouts and lore cards are in `FamiliarArt`.

## Checked
Edit-mode capture of the models next to Mourner and Ward (humans read as real figures; dark in daylight because of the gold-ink palette); Play start with the 16-familiar collection (16 cells, no errors) and `RevealFX.play` for Mythic and Celestial (aliased to the Legendary and Ultimate reveals) without errors; 13 test suites pass.
## Not checked, or open
- 2026-10-29: `Yaw` was 180 and showed the backs; set to 0 and seen on the board in Play (all four place, heights 4.4 to 4.8, face the camera). Idle (2 s loop), Hit (0.5 s) and Death (1.2 s) recipes added to `Shared.FamiliarClips`; they build for all four and the Death and Hit poses were checked as static poses in Edit mode only. Uploaded as Animation assets 2026-10-29 (20 ids in VFX/ASSETS.md, route: Studio to .rbxmx via local POST receiver, then tools/upload_asset.py) and wired into Characters/<human>/Animations (the old Walk and Attack KeyframeSequences were replaced). Play check: all five tracks load on the board with the right lengths; motion on the board is UNVERIFIED (units are about 25 px tall; Death TimePosition read 0.00 while IsPlaying). Hit and Death are not called by the client yet. Hands and faces are soft; the Veil Walker back is stripy; the face of each is the concept's, not hand-made.
- The Mythic and Celestial reveal screens reuse existing tiers (`TIER_ALIAS` in RevealFX); the odds panel for six rarities was fixed and checked in Play by the loading-eye chat (ring size scales with the count; under 1% shows two decimals).
- New placeholder stats are not balanced; the full economy rerun with them is open ([[Balance Baseline 2026-10-29]]).
- Edits to `FXRecipes` (RAMP and ORDER entries) and `RevealFX` (the alias) touched files no chat owns; the loading-eye chat said they were not theirs.

## Epic and Legendary humans (2026-10-29, main coordinator)
Constable Wren (Epic, Whistle), Madam Quill (Epic, Annotate), The Cog-Warden (Legendary, Lockstep), The Ferryman of Fog (Legendary, Crossing); 20 familiars now, spread 4/4/4/4/2/2. Lore in `Roblox Dev/Lore/Familiars/`. Pipeline as above: ComfyUI concepts (3 front variants each, one pick, back view seed 31), Hunyuan3D shape, `cleanup_familiar.py` (smooth 2, 9,000 triangles, 5.0), `prep_new_textures.py` + `bake_familiar_textures.py`, `recolor_familiars.py` (gold ink), `rig_template.py` (added the four names to `rig_spec.ARCHETYPE`, all biped), uploads (ids in `VFX/ASSETS.md`), Studio `Characters` folders plus `Config.ROLES` and `Shared.Familiars` entries, 20 clips uploaded and wired.
| Familiar | Rarity | Damage, cooldown, range | Raw dps | Role |
|---|---|---|---|---|
| Constable Wren | Epic | 12, 0.6 s, 22 | 20 | Whistle: every 4th shot splashes (radius 6, 60%) |
| Madam Quill | Epic | 10, 0.5 s, 24 | 20 | Annotate: hits mark and hush |
| The Cog-Warden | Legendary | 18, 0.75 s, 26 | 24 | Lockstep: crit stuns, every 6th shot strikes twice |
| The Ferryman of Fog | Legendary | 15, 0.65 s, 28 | 23 | Crossing: hits chill and mark, aura range +15% |
Checked 2026-10-29: 14 of 14 suites pass (Familiars.test.luau updated to 20 and 4/4/4/4/2/2); the full bot still clears 25 stages on 10 of 10 seeds, mean 570 s; in Play all four place on the board at heights 4.4 to 4.7 facing the camera and all five tracks load with correct lengths.
Role mechanics are covered by `Tests/NewRoles.test.luau` (27 checks, 2026-10-29). Not checked or open: board motion, role effects in a real wave on screen, identity colours for colour-blind safety, collection cards and cutouts (`FamiliarArt`) for the four, reveal screens (Epic and Legendary reuse existing), faces and hands soft, Madam Quill's book not modelled, stats are placeholders, place not saved, `Studio_Export/Familiars.luau` regenerated but Studio edited in place.
