# UI rework 2026-10-29: title page and skill tree

From the 94 Pinterest pins ([[Research/UI/Pinterest Batch 1 - Tarot, UI, VFX, Themes (2026-10-29)]]). Manager chat with Sonnet workers. Graded blind per [[Research/Harsh Grading]]; the reviewers could NOT open the reference pins (overnight Read hook blocks that path), so grades are against the brief only. Motion is not gradable from stills; Play capture in Studio kept serving stale frames, so motion is UNVERIFIED except property reads and frame diffs on the skill tree.

## Skill tree (`StarterPlayerScripts.SkillTreeV3`, mirror `Studio_Export/SkillTreeV3.luau`, one-line hook in GameClient)
| Round | Scores (shape/icons/colour/tarot/readability/polish) | Verdict |
|---|---|---|
| 2 | 5/5/5/6/5/5 | FAIL (blue world leaking through, ring layout, weak states) |
| 3 | 5/6/7/7/5/4 | FAIL (blue fraction now 0.0, gold-ink, tarot cards; ring layout still reads symmetric) |
Open bugs: Storm node shows rank "5/4"; bottom-left FAMILIARS label garbled; RESPEC weight changes between frames; card captions tiny; popup can cover a neighbour. Reviews: `Captures 2026-10-29/skilltree_r2_review.md`, `skilltree_r3_review.md`; frames in `Captures 2026-10-29/skilltree/`.

## Title page (`StarterPlayerScripts.TitleScene`, mirror `Studio_Export/TitleScene.luau`, 2-line hook in StartMenuArt; art in `UI Kit/art/title_bg/`, ids in `VFX/ASSETS.md`)
Faceless Unbound facing a tiny lantern-lit character on a bridge, layered parallax (sky, rays, figure, mist, foreground), wipe intro.
| Round | Scores (awe/silhouette/colour/menu/polish) | Verdict |
|---|---|---|
| 2 | 6/5/4/-/4 | FAIL |
| 3 | 6/4/6/7/4 | FAIL (reads as reaper, sticker edge) |
| 4 (real Play capture, two frames) | 5/5/7/7/5 | FAIL by default (feathered matte, halo, gold button done; still reaper-like, no visible player, flat mid-tone body) |
Next fixes from the reviewer: small sharp player with bright lantern on the bridge, bright crown/halo instead of a void face, near-black robe with gold rim light, crisp bridge, larger gazette text. Round 4 frames `title/r4_play_a.jpg`, `r4_play_b.jpg` show the rays, figure and particles moving between frames. Reviews: `title_r2_review.md`, `title_r3_review.md`, `title_r4_review.md`.

## Not done
Loading clock (owned by loading-anim). Tarot roll/reveal and transitions (not started). The user is the final judge: nothing here is "PASS".
