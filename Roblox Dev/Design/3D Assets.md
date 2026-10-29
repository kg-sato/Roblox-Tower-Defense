# 3D Assets

Models made with Hunyuan3D-2, then imported into Studio.

## Pipeline
1. Make or find a reference image (clean background, one object).
2. Generate the shape with Hunyuan3D-2 (mini-Turbo fits the 8 GB GPU).
3. Texture: low-VRAM mode, Tencent's online demo, or plain Studio colors.
4. Reduce to under 20,000 triangles per mesh (Blender Decimate).
5. Export `.glb` or `.fbx` and import with Studio's 3D Importer.
6. Check scale, pivot and collision fidelity in Studio.

Files go in `Assets/3D/`.

## Asset list

| Asset | Source image | Triangles | Textured? | In Studio? | Notes |
|---|---|---|---|---|---|
| StarDrake T1 (pilot) | `Hunyuan3D\reference\StarDrake_T1.png` (Studio render of the procedural pet) | 12,000 -> 2,800 | No (flat colour) | Yes: v2 FBX imported 2026-10-25, upright, clips verified; faces -Z; needs pose-rename + Animator after import; pilot only (plain shape, not final art) | Blender: 1 Root bone, clips Idle/Attack/Spawn; files in `Blender\out\`; see [[Research/3D and Art/Asset and Animation Workflow|Asset and Animation Workflow]] |

## Setup notes (2026-10-24)
- Installed in `Hunyuan3D/` (Python 3.11 env `.venv`, models cached in `hf_cache/`, about 9 GB; the `.venv` is another 5 GB).
- Generate: `.venv\Scripts\python generate.py <image or folder>` from the `Hunyuan3D` folder.
- Required pins: `transformers` 4.x (5.x breaks loading the image encoder) and `diffusers` 0.35. Full list in `Hunyuan3D/requirements-lock.txt`.
- Test with the demo image: 15 s, peak 4.2 GB video memory, 18,000 triangles. Shape only; no textures.
- Test output is in `Hunyuan3D/test_out/demo.glb`.

## Familiar models in the game (T102, 2026-10-29)
The 12 textured familiar models (`Assets/3D/Familiars/textured/<Name>.glb`, about 6,000 triangles each) were uploaded to the user's Roblox account as Model assets (creator user 872430111; also logged in `tools/uploads.json`) and loaded in Studio with `InsertService:LoadAsset`; the inner Model (one MeshPart plus a SurfaceAppearance) became the `Model` child of each folder in `ReplicatedStorage.Characters`. All MeshParts have `DoubleSided = true` (the thin visual-hull models, the Sentinel above all, rendered as outlines without it). Folder to familiar: Ember = Ember, Zap = Moth-Lantern, BrassHound, Sentinel, Frostling, Boulder = Gargoyle, Ward, Archivist, Mourner, VoltFox = Mirror Chorister, StarDrake, GreyVeilWraith. Sprout was removed. Asset ids: Ember 136282546009058, Moth-Lantern 106702237676803, Brass Hound 107681100958369, Sentinel 126744188043602, Frostling 110445808538728, Gargoyle 129809830834583, Ward 97817781664100, Archivist 95811615878114, Mourner 86178666978786, Mirror Chorister 118154808652383, Star Drake 101965399666864, Grey Veil Wraith 112474997904243.
New folders (BrassHound, Sentinel, Ward, Archivist, Mourner, GreyVeilWraith) carry placeholder stats chosen by rarity and role, not balanced: Brass Hound 4 damage, 0.3 s, range 14; Sentinel 14, 1.2 s, 18; Ward 6, 1.0 s, 26; Archivist 7, 0.9 s, 22; Mourner 10, 0.55 s, 24; Wraith 16, 0.65 s, 26. Role effects (Reveal, Hasten, Ward, Hush, Drain, Echo, Breach) are not implemented yet; every familiar still just shoots.

## Enemy and boss meshes uploaded 2026-10-29 (T132)
Concept-grade models from [[Enemy Models]], uploaded as Model assets (Open Cloud) and loaded in Studio Edit mode with LoadAsset (all load): FogWisp 128040982375596; BrassSentinel 95028100682755; ClockworkCrow 85256591738111; LanternThief 107872593870870; Unbound 77114404609027 (phases 2 and 3: 132477005165063, 108536993980488); ClockmakerAutomaton 105773609287319; StarChoirEcho 83373040785070; HollowCourtRegent 112741419053232; Clockmaker 117038627587754. Logged in `tools/uploads.json`.

HollowParishioner (self-assigned, 2026-10-29): asset 94567177585107, listed with the other enemy meshes above; not yet loaded back in Studio.

Gold-ink familiar textures (2026-10-29): 12 images uploaded (Gold_<Name>_BaseColor), ids in [[Design/Gold Ink Recolour]] and tools/uploads.json.
