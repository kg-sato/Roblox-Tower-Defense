# Roblox engine limits for particles, lights, shadows and triangles on phones (T025)

Question: what hard and soft limits does Roblox document for the effects our game uses on phones?

All figures come from the Roblox Creator Hub pages below, fetched 2026-10-28. The pages are undated, so re-check them before relying on a number. The Hub gives few hard caps; most advice is qualitative.

## Facts (sourced)
**Triangles and meshes**
- A single mesh cannot exceed 20,000 triangles. The page gives no limits for vertices, size in studs or texture resolution. [Creator Hub, Mesh specifications](https://create.roblox.com/docs/art/modeling/specifications)
- The performance page uses an example device baseline of under 1,000 draw calls and about 1,000,000 triangles on screen; it states this is one example, not a universal mobile limit. Reuse meshes and textures to keep draw calls low. [Creator Hub, Performance design](https://create.roblox.com/docs/performance-optimization/design)

**Textures**
- Uploads up to 4096 x 4096 pixels. Suggested sizes by object size: 5 x 5 studs 256 px, 10 x 10 studs 512 px, 20 x 20 studs 1024 px. Default part material shows 1024 px on an 8 x 8 stud face. PBR texture maps are limited to 1024 x 1024 in the UV section, which conflicts with the 4096 limit elsewhere on the page; no file size limit is given. [Creator Hub, Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)

**Particles**
- Particle emitters do not batch well and add draw calls; changing emitter properties at runtime can have a large impact. [Creator Hub, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Live particles at steady state are Rate multiplied by Lifetime (the docs' example: 5 per second, 1 s lifetime, about 5 particles); `Emit()` defaults to 16 particles; no hard cap is listed. [Creator Hub, ParticleEmitter](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter)

**Lights and shadows**
- Shadows are expensive. Turn off `Light.Shadows` where not needed; limit light range and angle; use fewer lights; disable lights outside the player's current area; turn off `CastShadow` on small or distant parts (can cause artifacts); disable shadows on moving objects. The engine lowers shadow quality as the graphics level drops and turns shadows off below level 4. [Creator Hub, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- PointLight page: no Range maximum or count limit stated (example uses Range 16, Brightness 1). [Creator Hub, PointLight](https://create.roblox.com/docs/reference/engine/classes/PointLight)

**Transparency, memory, frame time**
- Partial transparency causes overdraw; keep transparency fully on or off where possible. [Creator Hub, Performance design](https://create.roblox.com/docs/performance-optimization/design)
- At 60 FPS a frame has about 16.67 ms; spread heavy work (for example about 5 ms per frame over 20 frames) instead of one 100 ms block. Low-end mobile devices have tight memory and can crash with out-of-memory errors. Studio's device emulator overstates memory use because server and client run together. Same page.
- Instance streaming is recommended for most places (shorter joins, less memory, higher frame rate). Same page.

## Not found
- No documented cap on live emitters, lights or particles per scene, and no mobile-specific triangle number. Our own gate in Studio (emitters at or below 7 per recipe, Low peak 26 vs 33, per the T22/T26 run log) is project policy, not an engine limit.

## What this means for us (recommendations, not sourced)
1. Keep the 20,000 triangle mesh limit as the hard cap (also our project rule) and set a per-scene triangle budget by measuring on a phone, since the 1,000,000 figure is only an example.
2. Texture sizes by stud size above are a good default: familiars 512 px, props 256 to 512 px, stage sets 1024 px (T123 to T126).
3. Shadows: off on moving units and small props; keep the Low setting that turns lamp shadows off (T07 earlier); remember the level-4 cutoff.
4. Particles: keep Rate and Lifetime small and measure live counts; avoid editing emitter properties each frame (our effect kit uses Clear then Emit).
5. Avoid partial transparency stacks on fog and glass props.
6. Test on a real phone or the closest emulator and treat the emulator memory as an overestimate (T205, T206).

## Sources
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://create.roblox.com/docs/art/modeling/specifications | fetched 2026-10-28; undated page | read |
| 2 | https://create.roblox.com/docs/performance-optimization/design | fetched 2026-10-28 | read |
| 3 | https://create.roblox.com/docs/performance-optimization/improve | fetched 2026-10-28 | read |
| 4 | https://create.roblox.com/docs/art/modeling/texture-specifications | fetched 2026-10-28 | read |
| 5 | https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter | fetched 2026-10-28 | read |
