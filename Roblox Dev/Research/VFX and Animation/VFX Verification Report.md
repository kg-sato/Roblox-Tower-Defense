# VFX Verification Report

Run 2026-10-25, because nobody could review the effects by eye or ear. Method: checks the machine can run (numbers, comparisons against known values, frame measurements, timing logs). Related: [[Loading and Reveal Spec]], [[Smooth Motion and Blur Playbook]], [[Video Reference Analysis]], [[Systems]] (VFX row). Code: `VFX/` (`VFXVerify.luau`, `verify_stills.py`, `verify_curves.py`, `sfx/analyze_sfx.py`). Evidence stills: `Research/VFX Renders/verify/`.

**Read this first: what "verified" means here.** PASS means a measurement or comparison confirmed it. It does **not** mean it sounds or feels good: nobody has listened to a single sound or watched a single animation play. Those are listed under UNVERIFIED and are the real remaining risk, especially for the two things the game depends on most: sound effects and motion blur.

## Summary
| Area | PASS | FAIL (now fixed) | UNVERIFIED |
|---|---|---|---|
| Sound effects (23, synthesized) | 23 of 23 analyzer checks, 4 engine checks, cue timing, cue coverage | 16 of 23 failed the first analysis (fixed, see below) | how they sound, mix balance, phone speakers, music interplay |
| Motion blur (camera + UI trail) | maths, caps, response to speed, image evidence, clean-up, reduced motion | my first camera rig was wrong (test bug) | how it feels, GPU cost on phones, translation-only movement, directional blur (impossible in Roblox) |
| Loading | beats in order, cues on beats, blur curve vs Rivals ramp | blur curve shape from the playbook (changed) | phone-sized viewport, real frame rate |
| Reveals (tiers, Ink, Vortex, Ultimate) | limits audit, cue timing, flash on/off luminance, clean-up | HUD showing during loading, zero-size images (fixed earlier) | how they look in motion, low-end phones |
| Feedback (combo, ring, milestone, spotlight, menu, backdrop) | audit, no leaks, tint limits | zero-size image bug (fixed) | feel |

## 1. Sound effects
Method: a pure-Python synthesizer (`sfx/make_sfx.py`, 23 original sounds, nothing downloaded), an analyzer (`sfx/analyze_sfx.py`) that measures each file, then engine tests in a Studio playtest.
- **Analyzer, first run: 16 of 23 failed.** Real problems found: the Ultimate impact peaked 227 ms after it started (weak punch) with its energy high instead of low; the summon drone was drowned by noise; the fall whoosh and menu whooshes were too bright; several sounds ended abruptly (anticipation, gather) without a fade.
- **Fixed** in the synthesis (30 ms end fade, lower and punchier impact, quieter noise bed, steeper filters). **Also corrected the analyzer itself:** the first click test measured the first millisecond, which a 5 ms fade makes non-zero by design, so it flagged good files; it now checks the actual first and last samples. Two spectral windows were guesses and were widened (ink: chime harmonics are part of the design; gather: it is a riser to 4 kHz). These are noted in the script.
- **Analyzer, final: 23 of 23 pass.** Peak -1.4 to -8 dBFS (no clipping), RMS -12.8 to -23.3 dBFS, no DC, no clicks at either end, durations and spectral centroids inside their design windows, impacts attack in under 50 ms, swells take over a second. Loudness spread across the set about 10.5 dB (UI sounds are quieter by design).
- **Engine (real playtest):** all 23 files load and their `TimeLength` matches the analysis (PASS); a playing sound's `TimePosition` advances (0.35 s after 0.35 s, PASS); 14 rapid cues never exceed 8 live sounds (PASS, UI sounds drop first); finished sounds destroy themselves (PASS).
- **Cue timing, real time (PASS):** Ultimate summon 0.000 s, sword 0.904, fall 2.903, impact 3.333 (intended 0, 0.9, 2.9, 3.32); Legendary/Ink anticipation 0.000, ink 4.001 (intended 0 and 4.0); the anticipation cue carries its length (4.0) so the riser is trimmed to it. Loading cues equal their beat times to the millisecond (fadeUp 0.001, synced 2.279, resolve 4.301). Every cue name any module can emit has a sound; `ui_click` exists but no module triggers it yet (UNVERIFIED-informational).
- **UNVERIFIED (needs ears):** whether any of it sounds good or fits the game; balance against music (there is none); how it plays on phone speakers; audio memory on low-end phones; the quiet analysis cannot tell a pleasant chime from a harsh one. Roblox's `TimePosition` advancing shows the engine is playing the sound, not that a speaker is audible.

## 2. Motion blur
Roblox has no native motion blur, so `MotionBlurFX` builds it: world blur proportional to camera speed (smoothed, capped), and fading echo copies for fast UI.
- **Maths (PASS):** frame-rate independent (same value at 30, 60 and 144 fps within 0.02), a dead zone at 0.35 rad/s so normal play stays sharp, monotonic response, caps 8 desktop / 4 touch / 4.8 with Particles Low, off with Reduced motion.
- **Engine response (PASS, driven at known speeds):** 0 / 0.5 / 1 / 2 / 4 / 8 rad/s gave blur 0.00 / 0.33 / 1.43 / 3.63 / 8.00 / 8.00, exactly the formula; cap never exceeded; blur is 0.00 one second after the camera stops; touch cap 4 reached; Reduced motion creates nothing; `stop()` removes the BlurEffect.
- **Image evidence (PASS, a real comparison):** sharpness of the same grass region (variance of an edge filter): still 559, camera at 2 rad/s 444 (0.79x), at 4 rad/s 293 (0.52x), after stopping 571 (recovers). Static blur sizes gave 556, 385, 274, 234, 233, 233 for sizes 0, 3.6, 7.2, 10.8, 14.4, 18, so the motion frames match the sizes the module reported (3.0 gives about 420, 6.8 about 285). **Finding:** in these stills the image stops getting blurrier past a BlurEffect size of about 11, so large sizes cost GPU without changing the look.
- **UI echo (PASS):** 4 echoes alive mid-slide, capped at 4 (Default), 0 left afterwards, 0 with Reduced motion.
- **A test bug I made and fixed:** my first camera rig rotated about the camera's tilted axis and swept into the sky, so those frames could not be compared; redone with a world-axis yaw.
- **UNVERIFIED:** how it feels in play (the 8-pixel desktop cap may be too subtle or too strong); cost on phones; blur from camera travel alone (a small share only); it is uniform, never directional, because Roblox cannot do directional blur.

## 3. Loading
- Beats in order at real speed (PASS): fadeUp 0.00, wait 0.51, synced 2.28, handoff, resolve, done. Cues land on the beats (PASS).
- **Blur curve compared against the Rivals ramp (PASS after a change).** Method: the Rivals sharpness series (683, 1270, 2027, 2795, 3559, 4133, from the video analysis) normalised, against our curves pushed through the measured size-to-sharpness table, same fractions of the resolve. RMSE (below 0.12 = same shape): Exponential Out 18 (the playbook's value) **0.256, different shape, rejected**; Quad Out 18 0.109 (borderline); **Quad Out 11 0.070**; Quad Out 10 (touch) 0.078; soft 8 0.109; linear 0.302. Because the stills stop changing past about 11, the desktop loading peak was lowered from 18 to **12**. Re-measured at real speed: 12.0, 9.8, 7.4, 5.7, 3.9, 2.4, 1.5, 0.7, 0.2, 0.0 at +0.0 to +0.9 s.
- UNVERIFIED: a phone-sized viewport (not resizable from here, layout is Scale-only), frame rate with the blur on a low-end phone, reduced-motion loading as a still. Caveats on the comparison: sharpness depends on the scene, the Rivals frames contain UI, one resolve per side; it compares shape, not look.

## 4. Reveals and flashes
- Audit across every tier and idea x Low/Default/High x touch/desktop x flashes on/off x reduced motion (PASS): emitter rates within 100/s on touch, blur and bloom soft and capped when Flashes is off, no orbiting props with Reduced motion, ideas use no flash.
- **Flash comparison (PASS):** the same Ultimate impact frame: mean luminance **0.649 with Flashes on, 0.045 with Flashes off**, against 0.026 just before the impact. So Flashes-off removes the spike (an increase of 0.019 vs 0.62).
- **Risk to know (not a failure):** with Flashes ON the impact is a single near-full-screen flash (0.026 to 0.649 in one beat). It happens once per reveal, not three times a second, but I did not check it against a formal photosensitivity standard, and back-to-back Ultimates would chain flashes. Recommend Flashes off by default on first launch and a cooldown between Ultimates.
- Leaks (PASS): after all tests no effect objects in Workspace or Lighting, no BlurEffect on the camera, no sound allocated, Lighting restored (Brightness 3, ClockTime 14).
- UNVERIFIED: how any of it looks in motion; low-end phone frame rate (Vortex draws up to 45 billboard motes at High).

## 5. Feedback
`FeedbackFX.audit()` PASS (edge tint peak 0.18, 0.09 soft; nothing leaks). Zero-size image bug found and fixed. UNVERIFIED: feel and timing against the vibe-coded game's baseline beyond what the earlier stills showed.

## Bugs this verification found (all fixed)
Analyzer false alarms (two check definitions); sound design flaws (impact punch, brightness, abrupt ends); HUD visible during loading (CanvasGroup `GroupTransparency` 1 still draws: also set `Visible = false`); zero-size image with an aspect constraint; the blur curve shape (Exponential Out rejected, peak lowered 18 to 12); my own broken camera test rig.

## What still needs a human (cannot be automated here)
1. Listen to the 23 sounds in the actual game moments: balance, taste, harshness. Replace the synthesized set with licensed or composed audio if they do not meet the bar.
2. Watch the motion: is camera-speed blur at cap 8 the right strength, do echoes read as speed.
3. A real phone: frame rate with blur and billboards, touch layout, phone speakers.
4. Upload decisions: every texture and sound loads from this PC's local Studio folder; nothing works for other players until uploaded (needs the owner's OK).

## Re-run
```
python VFX/sfx/make_sfx.py && python VFX/sfx/analyze_sfx.py && python VFX/sfx/gen_catalog.py
python VFX/verify_curves.py
python VFX/verify_stills.py sharp 100,620,700,840 <images>    (and: lum <images>)
```
In Studio: `VFXVerify.static()` (Edit mode), then in a playtest client `sounds()`, `cues(pos)`, `loadingSync(hud)`, `motion()`, `echo(gui)`, `leaks()`.

## Addendum 2026-10-25 (second pass): music, merge ladder, MergeCore, roster
Same method (machine checks, honest labels). Nobody has listened to the music or the new sounds.
- **Music (5 CC0 tracks, `Audio/CREDITS.md`).** Source pages confirmed CC0 and gave direct files; downloads checked by file signature and size. Measured with Blender's audio decoder (`Audio/analyze_music.py`): **"Shinsei" decoded with a +13 dB sample peak** (a hot master that would clip); all tracks were leveled to about -18 dBFS RMS with a soft limiter, peaks now -1.1 to -6.0 dBFS, durations unchanged. Loop seams: Artifact Room -0.8 dB (clean), Iremos Forest +3.5 dB (a small jump when it loops), the three songs end in silence so they crossfade instead of looping. **In the engine (`VFXVerify.music()`, 10 of 10 PASS after one fix):** fades in smoothly, one main track, crossfade overlaps then settles, combined level never exceeds one track, tension bed about 10 dB under the music, music dips 12% at most, ducking works, the music volume setting is honoured, `stop()` leaves nothing. **A test found a real bug:** a requested 50% duck reached only 31% because the music was released after 0.15 s; fixed (hold the dip, overlapping ducks safe), now 49%. **UNVERIFIED:** whether any track is "lo-fi, magical, with a tiny bit of tension". The moods come from the source pages; tempo and brightness from our analysis (Chill lofi about 109 bpm, centroid 1.9 kHz; Artifact Room centroid 0.68 kHz, the darkest and most dynamic); a rough tempo estimate is not a mood.
- **Merge sound ladder + 7 new cues (38 sounds, 38 pass).** First analyzer run failed 18 of 38: loudness did not escalate (tiers 2 to 4 were not louder than 1 to 3), tiers 5 to 7 had almost no low end, and my duration windows ignored the reverb tail. Fixed by normalizing the ladder by loudness instead of peak and strengthening the sub-bass layer. Final: RMS -26.0, -25.0, -24.0, -23.0, -21.8, -20.6, -19.4, -18.3 dB; length 0.95 to 5.2 s; low-end share 0.12, 0.10, 0.07, 0.04, then 0.50, 0.43, 0.43, 0.51 from tier 5. In the engine all 38 files load and match their lengths. **UNVERIFIED:** that the escalation is "dramatic" and not just louder; half the energy under 200 Hz from tier 5 may be muddy on some speakers and inaudible on phones (the upper layers still carry the cue).
- **MergeCore (rules): PASS.** Merge rules, value conservation with echo and surge off, no dead end on a full board, top-tier ascension, determinism, tier ranges, cue names (every result maps to a cue that exists).
- **Difficulty simulation (`MergeCore.simulate`, 200 games per bot, 10 simulated minutes).** First result: time per tier doubled (focused 29, 56, 110, 206 s for tiers 5 to 8) and the low-attention bot reached tier 5 in only 26% of games with 56 board overflows. Added catch-up spawning and an idle auto-merge; now focused 26, 50, 74, 100 s (about +24 s per tier), casual 40, 72, 114, 161 s, low-attention 90, 213, 337, 399 s with tier 5 in 100% of games. UNVERIFIED: that it is fun, and whether it is too easy (a focused player finishes the chain in under two minutes).
- **Roster: PASS after two fixes.** The distinctness test (names, notes, main colours at least 60 apart in RGB) failed twice: Pip and Solenne (both orange-gold, 50) and Vesper and Mirelle (both dark blue, 57). Solenne became rose with gold accents, Vesper a lighter indigo; closest pair now Lumo/Vesper at 78. Portraits are ranked by `VFX/verify_roster_art.py` (subject coverage, free margin, dominant hue against the roster colour); style consistency and anatomy are judged only by reading the images.

- **Music in the actual game (playtest, 2026-10-25):** a separate Studio-only script `StarterPlayerScripts.MusicBootstrap` starts the "play" playlist (`GameClient` untouched). Confirmed in a real playtest: `MUS_chill_lofi` playing, `TimePosition` 12.7 s, volume 0.44 (= 0.55 trim x 0.8 setting), no new console errors. It is silent outside Studio by design: the tracks load from local files until they are uploaded. The menu/play/tension states are **not** wired to game events (that needs `GameClient`).
- **Portraits (8 characters, `Roblox Dev/Assets/Characters/`):** ranked by `verify_roster_art.py` plus a visual check; the first Vesper (navy) duplicated Mirelle's navy robe, so she was regenerated in violet (hue gap to her roster colour 34 to 16 degrees). Style consistency and anatomy are judged only by reading the images.

## Addendum: audio upload attempt (2026-10-25)
The upload was confirmed by the user but could not be done with the available tools (Studio MCP uploads images only; no documented audio route in the scripting API; the importer needs a person at the file dialog; Open Cloud needs an API key, which must not be created or stored). **Not uploaded; nothing was published.** Prepared: `Audio/Upload/` (43 files, 14 MB, within the 20 MB and 7 minute limits), steps in `Audio/Upload/README.md`, and `Audio/apply_ids.py` + `VFX/AudioIds.luau` so the game switches to uploaded ids automatically. After wiring the id fallback, sounds (4/4) and music (10/10) were re-run: PASS. **Test note:** `VFXVerify.music()` must run with `StarterPlayerScripts.MusicBootstrap` disabled (it ran with the bootstrap on once and showed 5 false failures because the bootstrap's own music was playing); it is re-enabled now.
