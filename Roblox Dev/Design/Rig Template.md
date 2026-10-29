# Rig Template (T106)

One shared skeleton family for the 12 familiars, written overnight 2026-10-29. Spec in `Blender/rig_spec.py` (pure Python, read by both Blender and the checker), builder `Blender/rig_template.py`, checker `tools/verify_rig_templates.py`, pose renders `Blender/render_rig_pose.py`. Outputs in `Assets/3D/Familiars/rigged/` (`<Name>_rigged.glb` and `.fbx`, `<Name>_rig_stats.json`, `poses/`). Skinning is automatic (distance based), not hand-painted, and nothing is imported into Roblox yet.

**Core chain, the same in every template:** Root > Pelvis > Spine > Chest > Neck > Head. A clip that only moves the core (the idle breath, the attack lean, the spawn and banish of T092 to T095) can therefore drive any familiar.

| Archetype | Extra bones | Bones | Familiars |
|---|---|---|---|
| biped | UpperArm and LowerArm, UpperLeg and LowerLeg, each .L and .R | 14 | Sentinel, Ward, Archivist, Mourner, Mirror Chorister, Frostling |
| quadruped | Front and Hind, Upper and Lower leg (.L and .R), Tail1, Tail2 | 16 | Brass Hound, Gargoyle |
| flyer | WingInner and WingOuter (.L and .R), Tail1, Tail2 | 12 | Moth-Lantern, Star Drake |
| floater | UpperArm (.L and .R), Trail1, Trail2 | 10 | Ember, Grey Veil Wraith |

Bone positions are fractions of each model's bounding box, so one template fits any size. At most 4 bones per vertex (Roblox limit for skinned meshes), weights sum to 1. Roblox needs one skinned mesh under about 150 bones; the largest template has 16.

**Known fit problems (from the checker warnings):** Brass Hound's tail bones own no vertices (the hound mesh has no tail), Gargoyle's tail bones own 6 and 14, Ember's Spine owns 5 (a flame with no body), Mirror Chorister's lower arms own about 20, Mourner's torso bones about 15 to 20 (a long robe). Those bones are harmless but give no motion; a hand-adjusted bone position or a per-familiar override in `rig_spec.py` is the fix. Thin parts (the Sentinel's halberd) follow the nearest arm bone, so raising an arm lifts the halberd (seen in the pose render).

**Open decisions for the user:** whether Frostling should be a floater (it has no real legs); whether the Hound and Gargoyle should get tail geometry or drop their tail bones; whether to export per-archetype animation clips (walk, wing flap) or keep core-only clips.
