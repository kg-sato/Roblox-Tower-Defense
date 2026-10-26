# Blender Cinematic Pipeline

Written 2026-10-24. Goal from the user: keep the current in-engine hatch as the demo, and make the final hatch (and ultimates) cinematic with Blender. Related: [[Magical Roll Animation Playbook]], [[Skill Tree, Effects and Characters]], [[3D Assets]], [[Game Design Doc]]

## Status (updated 2026-10-24)
- The old install folder `C:\Program Files\Blender Foundation\Blender 4.3\` has no `blender.exe`; ignore it.
- The user supplied Blender 5.3.0 beta at `C:\Users\kgsat\Downloads\blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release\blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release\blender.exe` (the folder is nested twice). Authenticode signature checked: valid, signer Blender Foundation. It runs headless (`-b`). It is a **beta**, so expect API changes; our scripts are in `Roblox\Blender\`.
- A pilot pet went Hunyuan3D -> Blender and was exported and re-checked: see [[Asset and Animation Workflow]]. Nothing has been uploaded to Roblox.

## What Roblox can and cannot take (official [VideoFrame docs](https://create.roblox.com/docs/ui/video-frames))
- Video: `.mp4` or `.mov`, 5 minutes or less, at most 4096x2160. **Alpha is ignored**, so a video is always an opaque rectangle.
- **Uploading video costs 2,000 Robux per video**, max 20 per day, needs ID-verified 13+ account and the Video Uploads beta turned on. That is the user's account and money, so I will not do it without a clear yes.
- A VideoFrame must sit in a ScreenGui, SurfaceGui or BillboardGui. Up to 2 videos play at once. Mobile performance and memory are not documented on that page (unknown).
- Not checked: mesh and animation upload rules and costs in Studio (free as far as I know, unverified), image/sprite-sheet limits.

## Options, with cost and fit
| Option | What Blender does | Roblox side | Cost / limits | Verdict |
|---|---|---|---|---|
| A. Pre-rendered video | Full cinematic render of an egg or crystal cracking open with rarity colours | VideoFrame plays it, then the pet appears in-engine | 2,000 Robux per video; opaque; pet cannot be inside the video unless one video per pet | Good for 1 to 2 big moments (Legendary, Mythic intro), too costly for every rarity |
| B. Blender-made animated assets | Model and animate egg shell pieces, crystal shards, runes, props, rig a hero pet; export FBX/glTF | Imported as meshes and animations, played with our code, plus in-engine particles, lights and camera | Upload costs not verified; needs a rig that Roblox accepts | **Best default**: unlimited reuse, pets show correctly, stays interactive |
| C. Image sequence / sprite sheet | Render frames (smoke, magic, energy) | ImageLabel flipbook or particle texture | Image uploads; resolution and frame count limits unverified | Good for particle textures and glows |
| D. Stay procedural (today) | none | Parts, particles, tweens | free | Fine for the demo; looks crude close up (seen in a screenshot) |

Recommendation: **B + C for every rarity, A only for the Legendary/Mythic reveals if the user chooses to pay 2,000 Robux each.** The hero pets themselves should come from Hunyuan3D or Blender sculpts instead of the placeholder shapes.

## Pipeline if we go with B + C
1. Style sheet per rarity (palette, props, length, music mood), written in the vault before modelling. Start from the tiers in [[Magical Roll Animation Playbook]] (Common under 1 s up to Legendary 5 to 6 s).
2. Model in Blender: egg or capsule with a crack-apart shell (pre-fractured), crystal shards, rune ring, orbit props. Keep each mesh under 3,000 triangles (our prop budget in [[Game Design Doc]]).
3. Animate in Blender (shell burst, shard spin), export `.fbx` or `.glb` with the animation. Claude can write and run Blender Python (`blender -b -P script.py`) once `blender.exe` is available; renders and exports can be checked as PNG frames.
4. Import into Studio (user approves each upload), build an `HatchCinematic` module that plays the animation, camera moves, particles and music, with a Quick-skip and a no-flash variant per the Settings design.
5. Review loop: Claude renders stills at fixed times (and Studio screenshots, which worked in Play), the user judges motion, we iterate.
6. Phone check with Particles Low and Flashes Off.

## Decisions needed from the user
- Is `blender.exe` installed somewhere? Where?
- Is spending 2,000 Robux per video acceptable for the Legendary/Mythic reveal, or stay with B + C only?
- Reference stills per rarity (the Sol's screenshots in this folder count).
- Music: licensed or generated tracks (none exist yet).
