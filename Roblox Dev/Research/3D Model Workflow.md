# 3D Model Workflow (simple version)

Defined 2026-10-25 by the user. This is the short rule for every character and prop. The full stage list with tools and evidence is in [[Asset and Animation Workflow]]; the Blender side is in [[Blender Cinematic Pipeline]]. Related: [[3D Assets]], [[Bug Log]]

## The loop in one line
**A 2D reference (an image the user attaches, or a file they point to) -> Hunyuan3D -> Blender -> the user checks it -> only then it goes into the game.**

The user is the quality gate. Nothing goes into Studio, into a match, or onto Roblox until the user has looked at the Blender preview renders and said it is good enough.

## Image-first update (2026-10-25)
Every model now starts as a **flat 2D concept image with character**, approved by the user before any 3D work. The same image then doubles as the UI icon, so the 3D model, the icon and the card art match.
0. **Concept image (new, Claude makes it).** `python "UI Kit\art\comfy_generate.py" <name> --prompt "<creature, personality, 3-4 distinct features>" --style flat --variants 4` (local ComfyUI + FLUX schnell, about 25 s each, outputs `UI Kit\art\comfy_out\<name>_flat_s<seed>.png`). Review 4 candidates; the user picks one or attaches their own. Check silhouette and detail with the checklist below *before* spending time on 3D.
0b. **Make it 3D-friendly.** Hunyuan3D reads best from a single object, front or three-quarter view, whole body, even lighting, plain background, no cast shadow, limbs not hidden. Regenerate with that wording if the pick fails these.
Then steps 1 to 5 below, with the approved concept image as the reference. Preview renders of the 3D model are compared against the concept image in the user's review.

## Steps
1. **Reference.** The user supplies a 2D image or file. If they supply none, Claude may make one, but a Studio render of our procedural primitives gives crude input (the Star Drake pilot showed this), so prefer real concept art, a picture the user likes, or a generated image (ComfyUI is installed, see [[UI Art Pipeline]]). The reference sits in `Hunyuan3D\reference\`.
2. **Hunyuan3D.** `Hunyuan3D\.venv\Scripts\python generate.py <image> --faces 12000 --quality normal`. Shape only, no textures on this 8 GB GPU. Output goes to `Roblox Dev\Assets\3D\`.
3. **Blender.** `Blender\process_pet.py` cleans, decimates (about 2,800 triangles for a pet, under the 20,000 hard limit), grounds, rigs and adds clips, renders preview stills, exports FBX. Blender path is in [[Blender Cinematic Pipeline]].
4. **The user reviews** the preview renders (`Blender\out\<Name>_front/_three_quarter/_side/_back.png` and the attack frames). Possible answers: approve, regenerate with another seed or reference, or change the reference. Claude does not decide this step.
5. **Game.** After approval only: the user imports the FBX in Studio (Asset Manager > Import), Claude runs the post-import fixes and tests. Details and the known import bugs are in [[Asset and Animation Workflow]].

## Quality bar: distinct, not cookie-cutter
Every model must be recognisably different from the others at game size, with enough detail to look like a finished game. Checklist to apply when judging a reference or a result:
- **Silhouette:** different outline from every other pet (ears, horns, wings, tail, stance). If two pets look the same in solid black, one of them fails.
- **Detail:** at least three secondary features (for example horns, wings, tail, armour plates, crest, gems, fur or scale shapes). Smooth blobs are not enough.
- **Character:** a face and an attitude that fit the species and rarity (a Common can be simple; a Legendary must read as special).
- **Family:** pets of one family share a theme (element, material), not a shape.
- **Budget:** about 2,800 triangles for a pet, under 3,000 for props; the detail has to survive that.
- **Evolution:** tiers add detail or accessories on top of the same base (see [[Skill Tree, Effects and Characters]]).
- Note that Hunyuan3D here produces shape only. Colour, glow and extra parts (halo, orbs) are added in Studio.

## What the pilot taught us
- A reference made from primitives gave a plain, rounded pet with flat wings. It works as a pipeline test, not as final art.
- After the first import fixes, the v2 FBX stands upright without any correction rotation and its clips play (lengths 1.17 s, 0.57 s, 0.77 s). The pet faces -Z, so rotate it 180 degrees about Y to face the game camera.
- Each import still needs two small fixes in the place: rename the root pose to the MeshPart name, and add an `Animator` under the `AnimationController`.

## Open
- Which reference images to use for the first real set of pets (user to attach).
- Whether to batch several references in one Hunyuan3D run (it loads the model once, about 25 s, then about 20 s per image).
