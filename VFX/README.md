# VFX (RevealFX)

Standalone reveal and ultimate effects. **Not wired into gameplay** (the user wants effects first). Source of truth: `VFX/RevealFX.luau`; installed as `ReplicatedStorage.RevealFX` in `Claude.rbxl` (inert until required).

- `RevealFX.play(tier, opts)` / `RevealFX.preview(tier, opts)`: tiers `Common` (0.9 s), `Rare` (1.5 s), `Epic` (3 s), `Legendary` (5.6 s), `Ultimate` (7.6 s, "Dawnbreaker"). `h.cancel()` stops and cleans up (restores Lighting, camera FOV, camera shake).
- `RevealFX.setSettings{ flashes, particles = "Low"|"Default"|"High", reducedMotion, skipTier }` follows the Game Design Doc display spec. Flashes off: no white spike, slow low coloured tint instead. Particles x0.25 / x1 / x1.5, every emitter rate capped at 100/s on touch, 400/s otherwise. Reduced motion: no camera push or shake, no orbiting props, no spinning, things fade in place. skipTier: a 0.3 s name card only.
- `RevealFX.audit()` builds every tier across Low/Default/High x touch/desktop x flashes on/off headless and checks the limits. Last run: AUDIT PASS (Ultimate at High on touch: peak rate 63/s, 1 flash, peak 0.95 rise 0.05 s).
- Preview/test: `RevealFX.preview("Ultimate", { position = pos, timeScale = 0.25 })` slow motion for stills. A playtest needs the game's own HUD and camera out of the way (see how the test did it: disable other ScreenGuis, bind a fixed camera at `RenderPriority.Camera + 10`).
- Textures: `make_vfx.py` (Pillow, white on transparent: glow, ring, rune, streak, flare, sigil, crack) copies to Studio's local `content/textures/vfx/`. Dev preview only; a published game needs them uploaded (needs the owner's OK) and `RevealFX.textures` pointed at asset ids. Missing textures render blank, the Neon parts, beams and title card still show.
- The sword is built from parts (no mesh upload). Blender was not used yet for this; a modelled sword or crown would need a mesh upload.
- Sounds: `opts.sfx(name)` hook only (names `common`, `rare`, `epic`, `legendary_gather`, `legendary_burst`, `ultimate_summon`, `ultimate_sword`, `ultimate_fall`, `ultimate_impact`). No audio exists yet.
- Claude only sees stills, not motion. Renders are in `Roblox Dev/Research/VFX Renders/`.

## Rules from the user (2026-10-25)
- Reference for effects: Sol's RNG (`sols-*`, `aura-view-*`). UI around them: the other screenshots and the UI Kit.
- No low-poly, blocky or studded props or UI. The Ultimate sword and the orbiting motes are smooth sprites on billboards (`vfx_sword.png`, `vfx_flare.png`), not block parts.
- Smooth and elegant above all: everything eases; blur pulses (camera-parented BlurEffect, capped 10 on touch, 8 when Flashes off or Reduced motion, slow ramps). Measured: BlurEffect blurs the 3D world only, UI stays sharp.
- Rivals loading blur reference: not seen yet (add `rivals-*` files to `Roblox Dev/Research/`). A loading screen has not been built.

## Loading, reveal ideas and feedback (2026-10-25, from the Rivals / Sol's / vibe-game video analysis)
Modules (all standalone, none wired into the game, all honour `RevealFX.settings`): `LoadingFX.luau`, `FeedbackFX.luau`, and the Legendary ideas inside `RevealFX.luau`. Textures added by `make_vfx.py`: `vfx_emblem` (original Guardian Grid mark), `vfx_ink`, `vfx_swirl`.
- **LoadingFX** (`LoadingFX.play{ title, total, hud, tip, minTime }`, `h.setProgress(n)`, `h.finish()`, `h.skip()`, `LoadingFX.audit()`): beats fade-up, wait scene (world blurred 18 desktop / 10 touch / 8 soft and dimmed, eased progress), SYNCED (corner brackets, underline, soft light lift 0.25 over 0.7 s), handoff (logo glows in while the HUD fades in over the blurred world), resolve (blur eases out in 0.9 s, logo shrinks 15%, drifts up, fades). Flashes off or Reduced motion: no light lift, blur cap 8, no scale or drift, 0.4 s crossfade. The HUD you pass in (a CanvasGroup) is hidden until the handoff.
- **Reveal ideas** (`RevealFX.preview("Legendary", { idea = "Ink" | "Vortex", anticipate = ... })`): a point-of-light anticipation (Rare 0.8 s, Epic 2 s, Legendary 4 s; the star grows, drifts colour, light gathers inward, world darkens and blurs) then a release that is a **bloom ramp, never a flash**. `Ink` (green): ink splashes spread, a rune ring writes itself, runes drift up. `Vortex` (gold): a swirl turns on the ground while motes funnel up into a column, then a collapse and release.
- **FeedbackFX** (`comboText`, `ringPulse`, `milestone` with soft edge tint (peak 0.18, soft 0.09), `spotlight`, `menuBackdrop`, `livingBackdrop`, `discovery`, `audit(gui)`): the vibe-coded game's motion baseline, our own look.
- Audits: `RevealFX.audit()` (now includes the two ideas and anticipation), `LoadingFX.audit()`, `FeedbackFX.audit(gui)` (needs a live ScreenGui; checks tint limits and that nothing leaks). All passed on 2026-10-25.
- Not wired, no sound, no uploads. Textures load from the local preview folder only.

## Sound, motion blur and self-verification (2026-10-25)
Built because nobody could review by eye or ear, and sound effects and motion blur are the priorities.
- **Sound:** `sfx/make_sfx.py` synthesizes 23 original sounds (pure Python, nothing downloaded) into `sfx/out/` and the local Studio folder `content/sounds/vfx/`; `sfx/analyze_sfx.py` measures them; `sfx/gen_catalog.py` writes `SoundCatalog.luau`; `SoundFX.luau` plays them (one SoundGroup, 8 at once or 6 on touch, UI dropped first, `length` trims long risers, self-destroying). `SoundFX.attach(RevealFX)` makes every module play its cues; every cue is also logged with its time.
- **Motion blur:** `MotionBlurFX.cameraBlur()` blurs the world in proportion to how fast the camera turns (dead zone, cap 8 desktop / 4 touch, smoothing independent of frame rate, off with Reduced motion); `MotionBlurFX.slide()` leaves fading echo copies behind fast UI motion. Measured: sharpness 559 still, 444 at 2 rad/s, 293 at 4 rad/s.
- **Verification:** `VFXVerify.luau` (static, sounds, cues, loadingSync, motion, echo, leaks) + `verify_stills.py` + `verify_curves.py`. Results and gaps: `Roblox Dev/Research/VFX Verification Report.md`.
- Loading desktop blur peak is now 12 (was 18): measured, the image stops getting blurrier past about 11, and a peak near 11 matches the Rivals ramp best.

## Merge game, music and roster (2026-10-25)
- `MergeCore.luau`: the 2048-style rules as pure logic, tests (`C.test()`), difficulty simulation (`C.simulate("casual", 600, 200)`), cue mapping (`C.cuesFor(result)`). `Roster.luau`: eight characters as data with a distinctness test. Design: `Roblox Dev/Game Redesign - Merge Academy.md`.
- `MusicFX.luau` + generated `MusicCatalog.luau`: menu, play and wish playlists with 3 s crossfades, a quiet tension bed, ducking under big cues (`Music.attach(RevealFX)`), volume setting. Tracks: `Audio/` (CC0, `Audio/CREDITS.md`); prepare and install with `Audio/prepare_music.py` (Blender) and `Audio/install_music.py`. `VFXVerify.music()` tests it.
- Sound effects: 38 sounds including the merge ladder `merge_1` to `merge_8` (louder, longer and heavier with every tier) and summon, surge, echo, bank, charge ready, merge fail, wish pull.
- `verify_roster_art.py` ranks the character portraits against the roster colours.
- `StarterPlayerScripts.MusicBootstrap` (Studio only) plays the soundtrack in playtests; remove it to silence. State switching (menu, play, tension) is not wired to game events yet.
