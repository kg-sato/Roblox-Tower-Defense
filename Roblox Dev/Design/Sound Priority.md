# Sound priority list (T187) and sound length check (T236)
Source: `Studio_Export/SoundCatalog.luau` (generated from `VFX/sfx/analysis.json`), 48 sounds, `pri` 1 to 3, and the voice limit in `Studio_Export/SoundFX.luau`. Read 2026-10-29.

## What the code does today
At most 8 sounds play at once (6 on touch devices). When the cap is reached:
1. a new priority 1 sound is dropped;
2. any other new sound stops the oldest sound of the lowest priority currently playing, then plays.

## Priority list
| Priority | Meaning | Sounds |
|---|---|---|
| 1 (dropped first) | UI and filler | bank, brass_click, card_flip, charge_ready, coin_clink, combo, echo, enemy_hit, enemy_poof, menu_close, menu_open, merge_fail, place_thud, ring, spotlight, summon, ui_click |
| 2 | gameplay and mid reveals | the 18 sounds not in the other two lists (for example bell_toll, clock_tick, common, discovery, epic, glass_crack, iron_clank) |
| 3 (kept longest) | boss, ultimate, top reveals | anticipation, ink, legendary_burst, legendary_gather, merge_6, merge_7, merge_8, ultimate_fall, ultimate_impact, ultimate_summon, ultimate_sword, vortex, wish_pull |

## Finding
Rule 2 compares only against the lowest priority playing: when all 8 playing sounds are priority 3 and a priority 2 sound arrives, it stops a priority 3 sound to make room. A lower-priority newcomer should be dropped instead. Fix (not applied; MatchService and SoundFX belong to the audio and UI sessions): in `SoundFX.play`, when `worst.pri >= e.pri`, drop the new sound rather than stopping `worst`.
Not tested: the cap and priority behaviour in Play (needs a Studio session and the audio owner); the task asks for a test, so T187 stays open.

## Sound length check (T236)
`python tools/check_sound_lengths.py` reads each catalog `dur` and the matching `VFX/sfx/out/<name>.wav`, and fails when a file is longer than its declared length by more than 0.05 s, when a declared sound has no file, and prints WAV files with no catalog entry. Run 2026-10-29: 48 sounds checked, all within their declared length, longest ultimate_impact 5.40 s, no problems. This is a file check, not a check of `Sound.TimeLength` in Studio.
