# Asset and Animation Workflow

Defined 2026-10-24 by the user. Applies to every character, prop and animation we make. Related: [[Dev Process Playbook]], [[Blender Cinematic Pipeline]], [[3D Assets]], [[Skill Tree, Effects and Characters]], [[Bug Log]], [[Systems]]

## The loop
**Hunyuan3D -> Blender -> Game -> Testing -> Bugs -> Patch -> Human Testing** (then back to Testing after each patch).

| Stage | What happens | Who/what | Tool and path | Evidence required to leave the stage |
|---|---|---|---|---|
| 1. Hunyuan3D | Reference image in, shape-only `.glb` out (no textures on 8 GB) | Claude | `Hunyuan3D\.venv\Scripts\python generate.py <image> --faces N`; references in `Hunyuan3D\reference\`; output `Roblox Dev\Assets\3D\` | `.glb` exists, triangle count printed, under 20,000 |
| 2. Blender | Merge, clean, decimate to the prop budget, ground and scale, flat colour, one-bone rig, animation clips (Idle, Attack, Spawn), preview renders, export FBX and GLB | Claude | Blender 5.3.0 beta at `C:\Users\kgsat\Downloads\blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release\blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release\blender.exe` (Blender Foundation signature checked: valid); scripts in `Blender\`; outputs in `Blender\out\` | Preview PNGs read and judged; `verify_export.py` re-import shows triangle count, size, bones, clip frame ranges |
| 3. Game | Bring it into Studio and wire it up | Claude, **user approves each upload** | Studio import (uploads to the user's Roblox account) | The asset appears in Studio and is used by a script |
| 4. Testing | Play in Studio, scripted checks, real mouse input, screenshots | Claude | Studio MCP: Play, `execute_luau`, `user_mouse_input`, `screen_capture`, console | Console clean of our errors; measured numbers; screenshots at the moments that matter |
| 5. Bugs | Every finding goes into [[Bug Log]] with repro and cause | Claude | vault | Entry exists before the fix |
| 6. Patch | Fix the cause, re-run Testing on the same case | Claude | scripts | The failing case now passes and nothing else broke |
| 7. Human Testing | The user plays and reports what feels wrong | User | the game | Notes from the user; they become new Bug Log items |

Rules for the loop:
- Never skip Testing after a patch. A patch that was not re-run is "unverified".
- A screenshot shows a still, not motion. Motion, feel and timing are judged in Human Testing.
- Anything that spends money, uploads to the user's account, uses an API key or publishes needs the user's yes first: video uploads (2,000 Robux each, see [[Blender Cinematic Pipeline]]), mesh and animation uploads, Animation Kit API use.
- The Animation Kit (fwjelaa, credit required) is for humanoid rigs; our pets use the Blender route. See [[Animation Kit Review]].

## Animation coverage ("animate every aspect")
Rule from [[Animation and Juice Playbook]]: scale the effort to how often it happens. Status after 2026-10-24:

| Area | Animation | Where it comes from | Status |
|---|---|---|---|
| HUD | Slide-in entrance, press squash, hover grow, number count-up, panel pop-in and shrink-out, toast rise, level-up badge pop, SP badge bounce, START WAVE pulse, ROLL egg wobble, boss bar and HP shake | In-engine tweens | Built, console clean; screenshots seen for some |
| Skill tree | Nodes hidden until a neighbour is owned, then pop in; purchase sparks | In-engine | Built; screenshot of hide and reveal after a real click |
| Hatch | Egg drop, shake, crack, reveal, rays, title | In-engine (demo) | Built; final version is the Blender cinematic (future) |
| Pets | Bob, attack hop, spawn pop, merge flight, evolve burst | In-engine now; Blender clips Idle/Attack/Spawn exist for the pilot pet | Engine built; Blender pilot exported, not imported |
| Enemies | Spawn pop, hit flash, death spin-and-shrink, boss entrance with shock ring and shake | In-engine | Built; one in-play screenshot, console clean |
| World | Crystal pulse and hit reaction, portal pulse, ultimate cinematic | In-engine | Built; gather phase screenshot only |
| Characters (final art) | Real animated meshes | Hunyuan3D + Blender | Pilot only (see log) |

## Pilot log: StarDrake tier 1 through the loop (2026-10-24)
1. **Hunyuan3D:** reference image made from a Studio render of the procedural Star Drake (`Hunyuan3D\reference\StarDrake_T1.png`). Result `Roblox Dev\Assets\3D\StarDrake_T1.glb`, 12,000 triangles, 44 s, 4.2 GB video memory.
2. **Blender:** `Blender\process_pet.py` reduced it to 2,800 triangles, 4 studs tall, one `Root` bone, clips Idle (36 frames), Attack (18), Spawn (24). Preview renders in `Blender\out\`. Re-import check: FBX has 1 mesh, 2,800 triangles, bone `Root`, 3 actions with the right frame ranges.
3. **Game:** **not done**. It needs an upload to the user's Roblox account. Waiting for the user's OK. Whether Roblox accepts a one-bone mesh rig for animation import is unverified.
4. to 6. Bugs found and fixed inside the loop:
   - Blender stills were blended by overlapping NLA clips (the model rendered at 5% size). Fix: render stills at frame 100 and mute other clips for attack frames. Verified in the new renders.
   - The GLB export contains an extra 80-triangle mesh (probably the bone display shape). Not used for Roblox (FBX is). Open.
   - Game client script hit Luau's limit of 200 local variables ("Out of local registers") after the animation additions. Fix: the skill-tree section now lives in a `do ... end` block. Found only because Play was run; verified clean afterwards.
7. **Human Testing:** pending.


## Game stage: what can and cannot be automated (checked 2026-10-24)
- The Studio import services (`AssetImportService`, `BulkImportService`, `StudioAssetService`, `AssetManagerService`) show up in the DataModel tree, but `GetService` and `FindService` return nothing from the MCP `execute_luau` context, and there is no `plugin` global. So **Claude cannot start a mesh or animation upload from the MCP connection**. `PlaceId` is 0 (the place file is not published), which is fine for importing.
- Two ways to do the Game stage:
  1. **Manual import in Studio (recommended, about a minute).** Per the user (2026-10-24), the working route is **Asset Manager > Import > Folders >** `C:\Users\kgsat\Documents\Roblox\Blender\out`. Import the **`.fbx`** (it carries the rig and the three clips; the `.glb` has an extra 80-triangle mesh and is not used for Roblox). The folder also holds preview `.png` renders: do not upload those. Studio uploads the mesh and any animation to the user's account. The imported asset must then be inserted into Workspace (or sit in ServerStorage) of `Claude.rbxl` so Claude can see it.
  2. **Open Cloud API key:** would let Claude upload from a script, but needs a key from the Creator Hub and the user's explicit OK to store and use it. Not recommended for one asset.
- After import Claude needs: the imported Model's name and where it is in the Explorer, and any Animation asset IDs.
- Unverified: whether the importer keeps the three clips from a one-bone FBX rig and uploads them as Animation assets.

## Pilot results after the user's import (2026-10-24)
Stage 3 (Game) and 4 (Testing) ran against the imported StarDrake_T1. What the place now contains: two identical `Workspace.StarDrake_T1` models (from the FBX, imported twice), a `Workspace.Scene` model (from the GLB, mesh named `tmp8q32whwl.ply`), and `ServerStorage.RBX_ANIMSAVES.StarDrake_T1` / `.Scene` with KeyframeSequences Idle, Attack, Spawn. The mesh is uploaded (a Roblox mesh id), so Stage 3's upload is done. The animations are only local KeyframeSequences, not yet uploaded as Animation assets.

| Check | Result |
|---|---|
| Mesh in Roblox | 4 x 4 x 2.9 studs, 1 `Root` bone, an `AnimationController` (no `Animator`) |
| Clip lengths | Idle 1.17 s, Attack 0.57 s, Spawn 0.77 s: match Blender (36/18/24 frames at 30 fps) |
| Idle moves the bone | Root bone Z oscillates between -0.16 and 0 over the loop |
| Attack | Peak bone offset 0.99 studs, ends by itself (set to not loop) |
| Stands on a pad | Seen in a screenshot after correcting the tilt |

Bugs found in Testing and what was done (all in [[Bug Log]]):
1. **No deformation at all.** Cause: the saved clips' root pose was named `StarDrake_T1_Rig` (the Blender armature object) but the MeshPart is `StarDrake_T1`. Roblox matches the pose tree to part names. Patch: renamed the root pose to the MeshPart name in the place data (156 poses). Re-tested: the bone now moves. Rule for every import: **root pose name = MeshPart name**, so run the rename step after each import.
2. **Mesh imported tilted 90 degrees about X** (lying on its back). Seen by trying three rotations side by side; +90 degrees about X stands it up. Source patch in `process_pet.py` (`bake_space_transform=True`, explicit axes); a re-exported `Blender\out_v2\StarDrake_T1.fbx` exists but **the fix is unverified until it is re-imported**. For now code can stand the model up with a +90 degree X rotation.
3. **No `Animator` was created** by the importer. Code must create one under `AnimationController` before `LoadAnimation`.
4. **All three clips imported as looping.** Set Attack and Spawn to not loop in the place data; the Blender script should say so (open).
5. **Duplicates** in the place from importing the folder (FBX twice, GLB once). Not deleted; ask the user.
6. Clips run in Studio only when registered with `KeyframeSequenceProvider:RegisterKeyframeSequence` (done in tests). A published game needs the clips uploaded as Animation assets, which only the user can do (Animation Editor > Publish, or Open Cloud).

Not done: wiring the imported pet into `Models.buildPet` and the match, and the Human Testing stage.

## Open questions for the user
- OK to upload the pilot mesh and animation to your Roblox account (Game stage)?
- Is the 2,000 Robux per video acceptable for any Legendary reveal cinematic?
- Reference images: keep using Studio renders, or supply concept art?
