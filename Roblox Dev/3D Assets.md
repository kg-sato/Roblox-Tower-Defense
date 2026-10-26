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
| StarDrake T1 (pilot) | `Hunyuan3D\reference\StarDrake_T1.png` (Studio render of the procedural pet) | 12,000 -> 2,800 | No (flat colour) | Yes: v2 FBX imported 2026-10-25, upright, clips verified; faces -Z; needs pose-rename + Animator after import; pilot only (plain shape, not final art) | Blender: 1 Root bone, clips Idle/Attack/Spawn; files in `Blender\out\`; see [[Research/Asset and Animation Workflow|Asset and Animation Workflow]] |

## Setup notes (2026-10-24)
- Installed in `Hunyuan3D/` (Python 3.11 env `.venv`, models cached in `hf_cache/`, about 9 GB; the `.venv` is another 5 GB).
- Generate: `.venv\Scripts\python generate.py <image or folder>` from the `Hunyuan3D` folder.
- Required pins: `transformers` 4.x (5.x breaks loading the image encoder) and `diffusers` 0.35. Full list in `Hunyuan3D/requirements-lock.txt`.
- Test with the demo image: 15 s, peak 4.2 GB video memory, 18,000 triangles. Shape only; no textures.
- Test output is in `Hunyuan3D/test_out/demo.glb`.
