---
date: 2026-10-27
tags: [research, ui, vfx, quality-bar]
---
# UI Quality Bar

Written by the overnight loop (T35). Builds on [[Research/UI/UI Design Playbook|UI Design Playbook]], [[Research/UI/Loading and Reveal Spec|Loading and Reveal Spec]], [[Research/UI/UI Methods and Magic Effects|UI Methods and Magic Effects]], [[Research/VFX and Animation/Beam and Impact VFX Recipes|Beam and Impact VFX Recipes]]. Labels: **Note** = an existing vault note, **Web** = fetched or searched 2026-10-27 (untrusted, blog-grade unless official), **Seen** = our own Play capture, **UNKNOWN** = no source; a human or reference video must supply it. Not read this pass (only named in the task): Screenshot Analysis, UI Recreation Coverage, bbstudios UI Reference, Community UI Approaches, UI Direction - Welcoming, Reference Video Study 2; so those aspects may be partly covered there.

Captures of our current build (Play, desktop 1333x777): `Overnight/captures/T35/` title.jpg, hud.jpg, reveal_charge.jpg, reveal_name.jpg, skilltree.jpg. Not captured this pass: familiar panel, level-up bar, boss intro, merge and hit feedback (need timed input; see gap 9).

## 1. In-match HUD
- **Reference:** minimal HUD, main action and core stats always visible, bright and large for crucial, muted for the rest; one visual language (Note: UI Design Playbook, core rules 2, 3, 6). Keep clear of the top bar and the thumbstick and jump zones in the bottom corners; default controls occupy part of the bottom-left and bottom-right (Web, official: [Position and size UI objects](https://create.roblox.com/docs/ui/position-and-size)); keep UI inside the core safe area ([On-screen UI containers](https://create.roblox.com/docs/ui/on-screen-containers)). Touch size: the official curriculum points to WCAG 9x9 mm ([Wireframe your layouts](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/wireframe-your-layouts), per search summary, page body not read); 44 px is a third-party number (Note: Playbook).
- **Ours (Seen, hud.jpg):** stage label top centre, HP chip top right, coin and gem counters and three glass buttons stacked top-left, ROLL bottom centre, START WAVE and AUTO bottom-left, ULT bottom-right. The coin counter (30) and gem counter sit directly under the Roblox menu buttons and the top-left emblem overlaps them; counters have no icons, only coloured numbers; the world behind the HUD is near-black in the capture. Update (T18): that was a capture artifact of the minimized Studio window (`python tools/studio_window.py 9` fixes it), not the game.
- **Gaps:** counters carry no icon or label (hierarchy and one-language rules); top-left stack collides with the Roblox top bar; ULT and START WAVE sit in the bottom corners where the mobile controls live (phone not tested). Type sizes, spacing in px and the states of each button (hover, pressed, disabled): UNKNOWN for the reference games.

## 2. Summon reveal
- **Reference:** anticipation is the key: a single point of light on a dark streaked backdrop, length scaled to rarity (Common none, Rare about 0.8 s, Epic about 2 s, Legendary about 4 s); release with a bloom ramp, no hard white frame; result card with odds line, big name, tier word (Note: Loading and Reveal Spec, section B). Sound: UNKNOWN (spec says out of scope).
- **Ours (Seen, reveal_charge.jpg, reveal_name.jpg):** a Rare roll shows grey shards at screen centre, then a blue glow, "RARE" top, "Frostling" and "1 in 7" bottom. The name and odds sit low and overlap the ROLL button; the pet itself is not visible in the captured frames; the shards frame looks unfinished.
- **Gaps:** result card layout puts text at the screen edges rather than around the pet; no tier-specific length or idea checked for Rare and Epic (Note: spec says audited only, not looked at); sound cues UNKNOWN.

## 3. Familiar panel
- **Reference:** tabs and a grid for large lists, count the steps to a goal (Note: Playbook rule 8); layered open: glass fade, emblem spin, header then rows, faint row separators, no borders (Note: UI Methods and Magic Effects checklist).
- **Ours:** not captured this pass. The Methods note says only the Odds panel has row separators; other panels do not.
- **Gaps:** no capture, so no comparison; row separators missing on other panels (Note); layout, sizes and states of the reference games' pet panels: UNKNOWN.

## 4. Level-up and next-unlock bar
- **Reference:** short-, mid- and long-term goals visible in the UI, end onboarding on a moment of joy (Note: Playbook, onboarding). Bar fill timing, easing, number pop-ups: UNKNOWN beyond the generic easing guidance in section 8.
- **Ours:** not captured; the HUD capture shows no XP bar. Where the level and XP show: unverified.
- **Gaps:** no visible progress bar in the HUD capture (Seen); everything else UNKNOWN.

## 5. Skill tree
- **Reference:** painted hexes with art breaking the silhouette, glass panel, serif caps title (Note: UI Methods and Magic Effects).
- **Ours (Seen, skilltree.jpg):** painted hex grid with coloured nodes, level badges, locked "?" hexes, title in gold serif caps, tooltip row with BUY button, Close button. Reads well. Hex labels are tiny (about 9 px) and the tooltip description line is very small; the subtitle is low contrast purple on dark.
- **Gaps:** label and description legibility on phone (type size minimum: UNKNOWN, no official number found); locked hexes all look identical so progress direction is unclear.

## 6. Boss intro
- **Reference:** bracketed stage captions per phase in a letterbox, charge then fire then aftermath (Note: Beam and Impact VFX Recipes, items 3 and 7).
- **Ours:** not captured; existing cutscene captions are in CutsceneFX per the notes.
- **Gaps:** no capture; caption timing and sound UNKNOWN.

## 7. Hit and merge feedback
- **Reference:** every action needs feedback (hover, press, release, sounds, progress, hit reactions) (Note: Playbook rule 4); layered impacts: ring, shockwave, light column, debris, glow, blur pulse (Note: Beam recipes item 4). Web, blog-grade ([Easton Dev, game feel](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/), [Godot forum checklist](https://forum.godotengine.org/t/game-feel-checklist-for-godot-4-hit-stop-trauma-shake-coyote-time-and-more/145340), via search summary only, pages not opened): hit flash 50 to 100 ms, hit-stop a few to 80 ms triggered once per impact, shake scaled by trauma squared, a good hit is 5 to 8 small responses within about 100 ms, give a reduce-shake option.
- **Ours:** not captured. Planned in T09, T19, T21, T25; Balance harness not related.
- **Gaps:** no capture; numbers above are unverified for Roblox.

## 8. Motion timing (all screens)
- **Reference:** loading blur 12 peak, Quad Out resolve over 0.9 s, measured against the Rivals clip (Note: Loading and Reveal Spec, update). Button press: UIScale to 0.92 with Back Out 0.12 s (Note: Playbook starter, untested). Web, blog-grade: ease-out to settle, linear feels robotic, Back or Elastic only for pops; button scale 80 to 120 ms, zoom 0.9 (Cocos default) (search summary only).
- **Gaps:** no measured easing table for reference games' HUD, panel open and close timings: UNKNOWN beyond the two measured Rivals ramps.

## Newly researched this pass (beyond the existing notes)
1. Official Roblox position-and-size and on-screen-container guidance on corner control zones and the core safe area (search summaries; first fetch of design-for-multiple-devices returned 404).
2. WCAG 9x9 mm touch target as Roblox's own curriculum recommendation; no official pixel minimum found.
3. Game-feel numbers (hit flash, hit-stop, shake model, easing guidance, button scale timing), blog-grade only.
4. Our own captures of title, HUD, reveal and skill tree.
Not found: reference-game type sizes in px, exact spacings, sound cues, empty and error states, phone layout. A human or a reference video must supply them.

## Gap list, priority order
1. HUD top-left stack collides with the Roblox top bar and menu buttons; counters have no icons (Seen hud.jpg; source: Playbook rule 3, 6 and [Position and size UI objects](https://create.roblox.com/docs/ui/position-and-size)).
2. Reveal result card: name and odds at the screen edges overlapping ROLL; pet not shown in captured frames (Seen reveal_name.jpg; source: Loading and Reveal Spec B3).
3. Bottom-corner controls (ULT, START WAVE, AUTO) sit in the mobile thumbstick and jump zones; unverified on a phone (source: [Position and size UI objects](https://create.roblox.com/docs/ui/position-and-size)).
4. No visible XP or next-unlock bar in the HUD (Seen hud.jpg; source: Playbook onboarding goals).
5. Skill tree text sizes too small, locked hexes indistinguishable (Seen skilltree.jpg; minimum type size: UNKNOWN).
6. Row separators missing on panels other than Odds (Note: UI Methods and Magic Effects).
7. Rare and Epic reveal variants only audited, not looked at (Note: Loading and Reveal Spec build status).
8. Hit, merge, boss intro, familiar panel and level-up not captured; feedback timings unverified for Roblox (source: blog-grade game-feel notes above; otherwise UNKNOWN).
9. Capture method: timed effects need `tools/record_window.py` plus frame review (T36), not single screenshots.
10. Sound cues for every screen: UNKNOWN.
