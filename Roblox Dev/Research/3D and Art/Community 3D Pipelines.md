---
date: 2026-10-27
tags: [research, 3d, ai, roblox]
---
# Community 3D Pipelines

How people get stylised 3D models into Roblox and which AI generators they use, found 2026-10-27, against our setup (Hunyuan3D-2 mini-Turbo shape only on an 8 GB RTX 4060 Ti, Blender 5.3 beta cleanup, 20,000 triangle cap). Related: [[Research/3D and Art/3D Model Workflow|3D Model Workflow]], [[Research/3D and Art/Asset and Animation Workflow|Asset and Animation Workflow]], [[Research/3D and Art/Blender Cinematic Pipeline|Blender Cinematic Pipeline]], [[Research/3D and Art/Image Generation Workflow|Image Generation Workflow]], [[3D Assets]], [[Research/Index]].

Labels: **Fact** = read on the page. **Vendor claim** = the seller says it. **Inference** = our reading. **Unverified** = listing only.

## Headline
Every source agrees on the same chain: generate (image or text to 3D), **clean up in Blender** (repair, decimate, fix normals), then import. Nobody skips the cleanup. Our chain already matches; the new information is VRAM numbers, licences, and a change in Roblox's own generator.

## Roblox's own generator changed (Fact, act on it)
[GenerationService](https://create.roblox.com/docs/reference/engine/classes/GenerationService) (official docs, opened):
- `GenerateMeshAsync` is marked **deprecated**; `LoadGeneratedMeshAsync(generationId)` returns a MeshPart and needs the `DynamicGeneration` capability.
- The class sample uses **`GenerateModelAsync(inputs, schema)`** with `inputs = { TextPrompt = ... }` and a `PredefinedSchema` (the sample uses `"Car5"`), returning a model.
- Rate limits, triangle count, and Studio-only versus live use are **not stated** on the page.
- **Inference:** our Studio MCP exposes a `generate_mesh` tool. Before anyone relies on it, test what it returns and check whether it calls the deprecated route. Cube 3D launch coverage ([GameFromScratch](https://gamefromscratch.com/roblox-announced-cube-3d-genai-system/)) describes usage caps without numbers.

## Generators compared (all numbers are from write-ups, not our tests)
| Tool | Type | Notes |
|---|---|---|
| Hunyuan3D 2.x / 2.1 | Open, local | [Local-setup article](https://www.tspi.at/2026/05/01/opensource3dassets.html): minimal turbo models about **8 to 10 GB VRAM**, single-image inference **12 to 16 GB**, multi-view **24 GB+**; a `--low_vram_mode` flag exists (no number given); example run on an RTX 3060 took about **10 minutes** (60 steps, octree 512). Outputs often non-manifold; topology less clean than Tripo in the author's test. Other sources quote different VRAM figures (6 GB, 10 GB shape-only, 21 GB texture-only), so treat all as unreliable. |
| TRELLIS / TRELLIS.2 | Open, local | Original listed at 16 GB (a community change reportedly gets it to 8 GB, unofficial); TRELLIS.2 listed at 24 GB. MIT licence. |
| Meshy | Hosted | **Vendor claim:** Roblox Studio connection, auto-rigging, 500+ animations, "preferred by 63.8% of evaluators" (its own survey). |
| Tripo | Hosted | **Vendor-side review:** fast, remeshing and rigging; refine in Blender. |
| 3D AI Studio | Hosted | Its own [Roblox roundup](https://www.3daistudio.com/blog/best-ai-tools-for-roblox-2026) ranks itself first (promotional); says Roblox's built-in AI makes materials and textures, not full custom meshes; gives no triangle or texture sizes. |

- **Licence (Fact: one aggregator, plus our CLAUDE.md):** Tencent's community licence for Hunyuan3D excludes the EU, UK and South Korea and caps at 1 million monthly users. Our CLAUDE.md already notes the territory limit; the user is in Toronto, so it does not block local use. Re-check before publishing.
- **Triangle limit (conflict):** two vendor blogs say Roblox caps single meshes at 10,000 (batch import) or 20,000 to 21,000 triangles. We keep the stricter project rule of 20,000. **Unverified against Roblox docs.**
- **Inference for our 8 GB card:** shape-only (what we do) fits; texture generation would not (matches the CLAUDE.md note), so colour in Studio or Blender. TRELLIS is only an option with the unofficial 8 GB change.

## Cleanup checklist people agree on (from the Blender-cleanup guides listed; none opened in full)
Import and audit the mesh, repair geometry, **reduce polygons**, fix normals, then export. **Inference:** this is what `Blender/process_pet.py` and `verify_export.py` already do; no change needed.

## Suggested next steps (not started)
1. Test the MCP `generate_mesh` tool on one prompt and record what comes back (triangles, texture, deprecation warnings).
2. If hosted tools are ever considered, check each tool's terms for game use and its Roblox UGC rules first; hosted generation needs the user's OK and may cost money.
3. Keep Hunyuan3D shape-only; stylise colour in Studio.

## Not verified
All VRAM and speed figures on our hardware; Meshy and Tripo claims; the Roblox triangle caps; whether `generate_mesh` uses the deprecated method.
