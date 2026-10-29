# Gold-ink recolour of the familiars (2026-10-29)
The user: "make the new 3D model similar in coloring" (the etched loading-screen eye, "i wanted these colors"), then answered "yes applied" to recolouring the 12 familiars. Done with `tools/recolor_familiars.py`: the gradient measured from `UI Kit/art/menu_art/etched_eye_onscreen.png` (dark umber, antique gold, cream; same as `UI Kit/art/recolor_etched.py`), each familiar's brightness stretched onto it (gamma 1.6, +60% saturation) and blended 20% with the original colour so each keeps a hint of identity (`--keep 0` for pure gold-ink, `--keep 1` to undo).

Measured: mean colour of the brightest 5% of the reference is RGB (212, 198, 167); the 12 outputs are 204 to 251 red, 189 to 222 green, 152 to 173 blue (distance 8 to 47; the brightest-source familiars Ember, StarDrake, Brass Hound run hotter). Outputs in `Assets/3D/Familiars/gold/` with `gold_sheet.png` and `gold_report.json`.

Applied in Studio (Edit mode): each `ReplicatedStorage.Characters/<id>/Model` MeshPart's `SurfaceAppearance.ColorMap` now points at the new image; the old id is kept in the attribute `OldColorMap` (set ColorMap back to it to undo). Checked in an Edit-mode capture of all 12 models side by side: they read as gold-ink on dark umber. Not seen in Play or on a phone; the place file is not saved. The static textured and rigged GLB files on disk and in Roblox are the old colours (only the Studio models changed).

| Familiar | Uploaded decal id | Image id used (ColorMap) |
|---|---|---|
| Archivist | 121329864059928 | 84155357607791 |
| BrassHound | 138198391308071 | 138215767452717 |
| Ember | 115946418684385 | 134021618165653 |
| Frostling | 97979918602753 | 110929783935121 |
| Gargoyle (Boulder) | 131719185397624 | 119832644458896 |
| GreyVeilWraith | 81845267358772 | 100314314036583 |
| MirrorChorister (VoltFox) | 138490009696681 | 84121295558572 |
| MothLantern (Zap) | 71720131845912 | 125136309167146 |
| Mourner | 78745132081973 | 140191501326583 |
| Sentinel | 91121196376632 | 125160748862638 |
| StarDrake | 125195486658583 | 76845918667455 |
| Ward | 130240582337054 | 136919736690202 |
