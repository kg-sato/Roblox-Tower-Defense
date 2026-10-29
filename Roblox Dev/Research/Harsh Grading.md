# Harsh Grading

Set 2026-10-28 after the user judged the overnight and research results as not good enough. The builder may not grade its own work alone.

## Rules
1. **Separate reviewer.** A fresh subagent that never saw the build grades it. It gets only the reference, our version and this checklist, never the builder's notes.
2. **Blind A/B.** The reviewer sees the reference and ours unlabelled, in random order, and must say which is the reference and why. If it picks ours out with high confidence, that's a FAIL. PASS only when it can't tell, or when it picks ours as the better one.
3. **Motion, not stills.** Grade a recording (`tools/record_window.py`, frames checked as moving), plus frames at the same moments. A still that looks fine does not count.
4. **Score out of 10 per item:** silhouette and shape, texture and material detail, colour and lighting, motion and timing, readability at the board camera. Any item below 7 is a FAIL. The total is not averaged away.
5. **Default to FAIL.** Unsure means FAIL. The reviewer lists the three biggest differences, even on a PASS.
6. **Numbers support, never decide.** Metrics (`tools/fx_quality.py`, `tools/ui_quality.py`) can fail a piece, but they can't pass one alone.
7. **The user is the final judge.** Every piece gets a side-by-side capture saved for the user, labelled PASS-by-reviewer, not "done".

## Art sources (uploads pre-approved 2026-10-28)
- Studio MCP `generate_mesh` (textured, at most 20,000 triangles) and `generate_texture` for characters, enemies and props.
- Hunyuan3D shapes, textured in Studio with `generate_texture` or in Blender.
- Blender driven by Python scripts for hard-surface pieces (path tiles, crystal, buildings).
- Vetted free Creator Store assets through `insert_asset`.
- `tools/upload_asset.py --upload` for FBX, images and audio (needs `ROBLOX_API_KEY`).
