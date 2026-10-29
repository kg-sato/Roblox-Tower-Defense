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
- The models were NOT seen on the board in Play: the `Yaw` attribute is 180 (the models faced away from the camera at 0, unlike the older ones), so facing and scale on the board are UNVERIFIED. No Idle clip. Hands and faces are soft; the Veil Walker back is stripy; the face of each is the concept's, not hand-made.
- The Mythic and Celestial reveal screens reuse existing tiers (`TIER_ALIAS` in RevealFX); the odds panel for six rarities was fixed and checked in Play by the loading-eye chat (ring size scales with the count; under 1% shows two decimals).
- New placeholder stats are not balanced; the full economy rerun with them is open ([[Balance Baseline 2026-10-29]]).
- Edits to `FXRecipes` (RAMP and ORDER entries) and `RevealFX` (the alias) touched files no chat owns; the loading-eye chat said they were not theirs.
