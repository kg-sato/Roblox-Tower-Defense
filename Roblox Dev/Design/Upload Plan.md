# Upload plan (T129)
Uploads to the user's Roblox account are pre-approved since 2026-10-28; publishing the game is not. Tool: `tools/upload_asset.py <file> --user 872430111 --name N --upload` (Open Cloud, key in `ROBLOX_API_KEY`, 20 MB per file). Every upload is appended to `tools/uploads.json`; ids are copied into [[3D Assets]] and `VFX/ASSETS.md`.

| Group | State 2026-10-29 | Where the ids are |
|---|---|---|
| 12 familiar static textured models | uploaded, load in Studio | [[3D Assets]], Overnight/evidence/T130.txt |
| 12 familiar rigged models | uploaded, load in Studio | same |
| familiar cutouts, lore cards, loading and menu art (95 decals) | uploaded | `tools/uploads.json`, `UI Kit/art/upload_1028/` |
| 11 enemy and boss models (T114 to T122) | uploaded, load in Studio (T132) | [[3D Assets]], Overnight/evidence/T132.txt |
| Walk and Attack clips | NOT uploaded: they are KeyframeSequences registered in Studio only, so a published game cannot play them | see below |
| 512 px texture sets, normal and emissive maps (T123 to T128) | not made | no uploads until made |
| trainer, props, rarity kit, merge frames | concept sheets only, no models | no uploads until modelled |

## Order for what is left
1. Animations: export each clip as an Animation asset (Roblox needs an uploaded Animation id for a published game). `upload_asset.py` supports `.rbxmx` as Animation; the clips need to be written out of Studio as KeyframeSequence `.rbxmx` first (Studio's Save to Roblox or a plugin), then uploaded; log ids into `Shared.FamiliarClips`. Needs a Studio session and is the main blocker for a published build.
2. Texture sets and maps, once made (T123 to T128): upload as Decal/Image, wire into SurfaceAppearance on the MeshParts; log ids.
3. New models (trainer, props, rarity kit): upload when built.
4. After every batch: LoadAsset in Edit mode (claim Studio in `QUEUE.md`) and write the ids into the evidence file.

## Rules
- One name pattern: `Enemy_<Name>` for enemies and bosses; familiars use the file name.
- Log every id the same minute it is created.
- Never upload anything with a licence conflict (see the Hunyuan3D note in `CLAUDE.md`: shape only; Tencent's licence does not apply in the EU, UK or South Korea).
