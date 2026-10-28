---
date: 2026-10-28
tags: [design, immersion, cutscene, plan]
---
# Immersion: Every Action a Cutscene (design draft)

The user, 2026-10-28: "I want every action the user does to be a cutscene"; "absolute immersion when doing anything in the game". Examples given: ULTIMATE goes into first person and you see it in action; SKILL TREE goes first person, you watch the actual tree grow, walk to it and upgrade. Source: [[User Inputs]]. Status: **draft; ULTIMATE, SKILL TREE walk-up, LEGENDARY cinematic and MERGE built 2026-10-28** ([[Research/VFX and Animation/Cinematic Cutscenes]]), the rest not built.

## What exists to build on
- `CutsceneFX` (ReplicatedStorage): letterbox, camera moves, name cut-in, impact kit, three signature cutscenes (Starfall 3.9 s, Grand Arcana 4.2 s, Winter's Hush 4.1 s), HUD hide and restore, skip by tap and at 2x speed.
- `FXK.camOverride` in GameClient: any cutscene can drive the camera; the new menu camera shows the blend pattern (1.2 s ease-out back to the game view).
- 1:1 effect pipeline and crafted sheets for the visual quality.

## Proposed actions (length is the main design risk: an action you do 200 times cannot take 5 s every time)
| Action | First time / big moment | Repeat | Camera idea |
|---|---|---|---|
| ULTIMATE | 4 s first-person from the strongest familiar: charge in its paws, release, follow the shot to impact | 2 s, then 1 s at 2x | eye-level behind the familiar, then whip to the impact |
| Skill tree open | walk up a garden path to a glowing tree in a courtyard off the lane; the tree grows a branch per owned skill | 1 s dolly straight to the tree | first person, tree as a 3D model with skill fruits/lanterns |
| Buy a skill | the branch grows and a lantern lights on it | 0.6 s | stay at the tree |
| ROLL | tarot card drawn to the camera, flips, familiar steps out (already a full-screen reveal) | card flip only for Common | over-the-table first person |
| Merge | the three familiars leap together, flash, the new one lands | 0.8 s | low orbit around the merge |
| START WAVE | first person ringing the brass bell, then a sweep down the lane to the first enemy | 1 s bell swing in place | bell tower view |
| Level up | camera pulls back to show the trainer statue gaining a ring of light | 1.5 s | wide |
| Boss arrives | letterbox intro (exists for bosses) | always | low angle |
Rules to keep it playable: every cutscene can be skipped by tap; repeats get shorter automatically; a "Cinematics: Full / Short / Off" setting joins Reduced Motion; cutscenes never pause the server (it already applies results first).

## Order to build (suggested)
1. ULTIMATE first-person (closest to existing CutsceneFX).
2. Skill tree as a 3D courtyard tree (needs a model: Hunyuan3D or procedural parts).
3. START WAVE bell, merge, level up.
4. Settings toggle and the repeat-shortening rule, tested with a counter.
