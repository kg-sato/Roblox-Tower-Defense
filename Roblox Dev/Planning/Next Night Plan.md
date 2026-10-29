# Next-night plan: the 20 most important open items (T241)
Chosen 2026-10-29 by what blocks a playable, publishable build first, then what the user will notice. "Needs" says what must come first.

1. DONE 2026-10-29: gold-ink recolour of the 12 familiars applied in Studio ([[Design/Gold Ink Recolour]]); next, look at it in Play and decide whether to also recolour the on-disk GLBs and the enemy models.
2. Save `Claude.rbxl` with today's Studio changes (rigged familiars, scripts). Needs the user (the place file is theirs to save).
3. Export the Walk and Attack clips as Animation assets and upload them (see [[Design/Upload Plan]]); without this a published game cannot animate. Needs a Studio session.
4. Verify rig deformation in Roblox with a working viewport (the blank captures never showed it). Needs a Studio claim.
5. Implement familiar roles (Hasten, Ward, Reveal, Hush, Echo, Starfall, Drain) from [[Design/Familiar Systems]]. T193, T194, T212, T213.
6. Balance the nine new familiars' placeholder stats with the economy simulator (T190, T191).
7. Boss framework: per-boss definitions, phases and a phase bar (T143 to T149, T187).
8. Save `bestStage` in the profile and the migration test (T184, T204).
9. Implement the rarity tier-cap flag if the user agrees (T183).
10. Rig and animate the six enemy models (walk, hit, death) and place them in a stage; the Hollow Parishioner model now exists (SA01).
11. Stage set 5 backdrop and lighting (T154) so stages 21 to 25 look different.
12. Build the first new path shapes with slot rows and curvature rule (T155, T156, T179).
13. Wire the 512 px maps into SurfaceAppearance and look at them in Play (T123, T127, T128).
14. Improve the first-pass familiar textures where they blotch (the user will see these first).
15. Enemy telegraphs and spawn telegraph (T138, T152), starting with the Brass Sentinel plant and the Fog Wisp lamp.
16. Unit tests for every server rule and a full headless 25-stage run (T202, T203).
17. Remote audit of the new remotes (T227).
18. Idle clips for the 12 familiars as Roblox clips (the Blender idle animations from T092 exist; `FamiliarClips` has no Idle recipe).
19. Quests and daily ladder after the economy is checked (T222, T188).
20. Update the Game Design Doc with the new roster, lore and systems (T242).
