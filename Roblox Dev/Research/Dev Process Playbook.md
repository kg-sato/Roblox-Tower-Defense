# Dev Process Playbook

Researched 2026-10-24. How we build any game here, not just tower defense. Related: [[Master Plan]], [[Merge Tower Defense Playbook]], [[Bug Log]], [[Roblox Success Sources]]

## Source quality
- Roblox-specific QA guidance is thin. Search returned vendor blogs (bugnet.io solo-QA posts) and gig listings; no official Roblox release checklist was found. The general ideas below are common practice, so treat them as sensible defaults, not standards. Official Studio test modes (Play Solo, Start Server with multiple clients) are real and used here.
- Roblox docs to rely on for specifics: [Roblox Success Sources](Roblox%20Success%20Sources.md) and the pages it lists.

## The process we follow
1. **Define done first.** Each task gets a one-line outcome and a check (a test we can run), written in [[Backlog]].
2. **Vertical slice before breadth.** One path from menu to match to reward to saved data works end to end, ugly, before we add content.
3. **Data-driven content.** Units, enemies, waves, crate odds live in config modules. Adding content is data, not code. One table feeds both gameplay and UI (so odds shown equal odds rolled).
4. **Server authority from the first line.** Every RemoteEvent validates type, range, rate. See [[Systems]] security rules.
5. **Pure-logic modules + tests.** Merge rules, wave generation, economy, crate rolls, damage math have no Instance dependencies, so they can be run by a script in Studio (`execute_luau`) and asserted.
6. **Test in the real thing.** After each system: run a playtest via Studio, read the console, check no errors/warnings, exercise the path. A script that parses is not a feature that works.
7. **Test matrix before shipping:** Play Solo, Start Server with 2 clients, Device Emulator (phone, tablet), slow/low graphics, rejoin with saved data, leave mid-match, purchase prompt cancel path, data store failure path.
8. **Bug log discipline.** Every bug goes in [[Bug Log]] with repro, fix, and how verified. Regression checklist rerun before each publish.
9. **Version safety.** No Git repo yet (not initialized). Until the user approves one, save the place often and keep scripts exported copies inside the vault only when asked. Recommend initializing Git before week 2.
10. **Measure after release.** Log funnel events (joined, first summon, first merge, first wave cleared, first boss, first crate, left). Review in Creator Analytics weekly.
11. **Ship small, then iterate.** Publish privately, test, then public; the user clicks Publish.

## What "bug free" means here
It cannot be proven. Our claim will be: the listed test matrix passes with zero console errors, and known issues are in the Bug Log. Anything unchecked is reported as unverified.

## Asset and animation loop
See [[Asset and Animation Workflow]]: Hunyuan3D -> Blender -> Game -> Testing -> Bugs -> Patch -> Human Testing, with the evidence needed at each step.
