# HUD rework blind reviews (2026-10-30), harsh subagent, images only
Screens: Overnight/evidence/hud_rework/r1..r3. Rubric: 7 = shippable.
| Round | HUD | Collection | Results | Reveal |
|---|---|---|---|---|
| r1 | 5.5 | 6 | 5 (collection was open behind it: test artefact) | 4.5 |
| r2 | 5 | 6 | 6 | 4 |
| r3 | 5.5 | not re-run (not touched) | not re-run | not re-run |
Target 7 NOT met on any screen. Collection, Results and Reveal were not reworked here (other owners' files; only the cyan focus box on Results was removed). Remaining HUD asks from the reviewer: ROLL clearly biggest with BEGIN and AUTO/QUICK quieter; FAMILIARS icon; ult as character portrait with ready/cooldown ring; labels bigger; one accent colour.
Flag: Config.HUD_REWORK = false (default). RESULTS_SCREEN and PAUSE_MENU unchanged (false).
Checks: 33/33 RunAll PASS, lean bot 10/10 seeds clear 25 stages (before the last UI-only edits; no sim code touched).
UNVERIFIED: phone size (no viewport emulation via MCP), real mouse hover feel, gamepad.

## Round 2 (r4, 2026-10-30): HUD=5, PROGRESSION=5, SETTINGS=5 (harsh blind subagent). Target 7 NOT met.
Fixed this round: gold accent on HP, quieter AUTO/QUICK/BEGIN, FAMILIARS icon, badge in corner, settings panel clear of top strip. Reviewer's remaining asks: ROLL larger and brighter; one baseline for the bottom row; trainer road card clipped at the right edge; settings needs real segmented controls and tidier fonts.
Flag left Config.HUD_REWORK = false (Studio and Studio_Export). Captures: Roblox Dev/Research/UI/Captures 2026-10-30/ (editor viewport 1617x777, not 1920x1080: MCP cannot set it). Overnight/captures/hud_a.png, hud_b.png.
T200 type fixes (NumberFormat, Bond, Quests, LeaderboardRules) synced into Studio; RunAll 33/33 PASS.

## Round 3 (r5, r6; 2026-10-30): brass art. HUD=5 (r5), HUD=5 (r6), SETTINGS=3 (r5, still flat). Target 7 NOT met.
Art: ComfyUI FLUX renders (UI Kit/art/make_hud_art.py, outputs UI Kit/art/hud_art/final, ids in UI Kit/art/upload_1028/ids.txt): wide plate, roll plate, ring, tall rail, winged crest, all on 9-slice or stretch in HudRework (ART table). Server stopped, ComfyUI/GPU rows released.
Reviewer's remaining asks: a corner bolt baked into the plate art overlaps text (regenerate plates without it); roll as brass-framed amber glass fused with the crest; plates read flat at HUD scale (need bigger relief/inner shadow); Settings, Progression and Collection panels are not brass yet; small labels.
Flag Config.HUD_REWORK = false left in Studio and Studio_Export. Captures: Overnight/captures/hud_c.png, hud_d.png and Roblox Dev/Research/UI/Captures 2026-10-30/hud_brass_*.jpg.

## Rounds 4 to 6 (r7, r8, r9; 2026-10-30): HUD=5.5, 5.5, 5.5. Target 7 NOT met after the 3 extra rounds; stopped as instructed.
Changes: new corner-bolt-free plate and amber-glass roll bezel (ComfyUI, ids in UI Kit/art/upload_1028/ids.txt), depth gradients and drop shadows, HUD scaled up about 15 percent, glass-tube gauge look on XP and HP, ult beside BEGIN.
Reviewer's standing issues: frames read as flat bars at editor-viewport size (no visible bevel or rope relief); roll amber slab clashes with brass and the winged crest looks pasted on; bottom row uneven heights and baselines; micro labels (163/835, MENU, OFF); left rail and FAMILIARS tab not one piece; Settings, Progression, Collection not brass.
Flag Config.HUD_REWORK = false (Studio, Studio_Export). Captures: Overnight/captures/hud_e.png, hud_f.png.

## Round 7 (whimsical vine restyle, skill-tree look), 2026-10-30
Art: ComfyUI gold-leaf vine plates (ids in UI Kit/art/upload_1028/ids.txt), warm velvet fill, vine frames on Settings, Levels and Pet panels (HudRework.skinPanel, hook in GCPanelKit). Blind scores (board / settings / levels): r10 5.5/3.5/4.5, r12 5/4.5/4.5, r13 5.5/4.5/5 = 5/10. Flag stays off. Captures Overnight/captures/hud_g.png, hud_h.png; r10 to r13 in this folder.
Open: panel interiors flat brown, micro text small, Flashes row and level 13 clipped, ult orb plain, HP bar plain, FAMILIARS frame differs. Not re-run: RunAll and bot (UI only). Phone size unverified.

## Round 8 (steampunk gears on the vine look), 2026-10-30
Added slowly turning brass gears (one linear tween each, off when art id empty), a pressure gauge on the stage bar, steam puffs on ROLL and BEGIN, bottom row aligned on one centre line, larger Settings and Levels text, orb ULT ring, warm panel fill. Art ids in UI Kit/art/upload_1028/ids.txt. Blind (board / settings / levels): r20 5.5/4/4.5, r21 5.5/5/4.5 = 5/10. Flag stays off.
Open: ROLL still a flat amber slab; panel interiors flat; Levels title clipped by frame and right column cut; Flashes row clipped; FAMILIARS and ULT unlike the rail; gears sparse. Collection, Results, Reveal and Pause not restyled. RunAll, bot and phone size unverified. Captures hud_i.png, hud_j.png.

## Round 9 (vines made subtle), 2026-10-30
Vine art at 0.55 image transparency with a gold hairline velvet frame (HudRework brass/skinPanel). Blind r22: board 5.5, settings 5.5 = 5.5/10. Flag stays off. Open: vines still run behind rail labels and slider rows, AUTO/QUICK/BEGIN/MENU/FAMILIARS/ULT lack the ROLL brass treatment, loose gears, no lantern glow, Flashes row clipped. Captures hud_k.png, hud_l.png.

## Round 10 (Art Nouveau ironwork replaces the leaf vines), 2026-10-30
Art: ComfyUI Guimard-style brass whiplash curves and coils (make_hud_art.py iron_*; keyed i_wide 125691901559686, i_tall 138167356804947, i_panel 77648763399473, i_ring 119143998198845), image transparency 0.4; gears, gauge and steam kept. Blind r23 (Opus): board 5, settings 4.5 = 4.75/10. Flag stays off. Reviewer issues: plates still flat fill with hairline (need baked 9-slice brass with bevel and rivets); the same gear sticker about 10 times without shadow; Settings double inset border and empty bottom third; web-style sliders and toggles; purple tutorial bubble off theme; flat monoline icons and mixed fonts; ROLL is still a flat peach slab. Captures hud_m.png (board), hud_n.png (settings); r23_board.png, r23_settings.png here.
