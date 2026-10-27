# Upload package (prepared 2026-10-25, NOT uploaded)
43 files, 14 MB, all under Roblox's limits (single track, mp3/ogg/wav/flac, under 20 MB and 7 minutes, 44.1 kHz): `../Music/game/` (5 Ogg Vorbis, CC0, credits in `../CREDITS.md`; the copy that used to be in `Upload/music/` was an identical duplicate and was removed 2026-10-27) and `sfx/` (38 original synthesized WAV, no third-party material).

## Why it is not uploaded
The upload was approved, but nothing available to the assistant can upload audio: Studio's MCP upload tool handles images only, the scripting API has no documented audio upload (`AssetService:CreateAssetAsync` documents Mesh and Model examples only), the Studio importer opens a file dialog that a person must use, and Open Cloud needs an API key, which must not be created or stored.

## What you do (about five minutes at the PC)
1. In Studio open **View > Asset Manager > Audio > Import** (or the Importer queue) and select all files in `Audio/Music/game/` and `Audio/Upload/sfx/`. Check the import dialog for the monthly limit on your account (sources disagree: 100 or 2,000 per 30 days if ID-verified, 10 or 100 if not; 43 files). A short sound may be classified as a sound effect and a long one as a song: both are fine for your own experience.
2. Audio is private by default: make sure your experience is allowed to use it (Asset Manager lists permissions per asset).
3. Copy the asset ids (right-click each asset > Copy Asset ID) into `Audio/asset_ids.json` as `{"music": {"shinsei": 123}, "sfx": {"merge_1": 456}}`, using the file names without extension. Tell the assistant, and it runs `python Audio/apply_ids.py`, re-syncs `VFX/AudioIds.luau` and runs the checks.
Untested shortcut: `StudioService:PromptImportFilesAsync()` run from the command bar opens a multi-file picker and may return the imported assets with their ids (not verified for audio).

## What will and will not be verified afterwards
The existing checks confirm each id loads and its length matches the files. Nobody has listened to any of these; Roblox's moderation may still reject or flag a file (CC0 does not guarantee acceptance).
