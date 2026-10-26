# Roblox animation maker: Claude animates, Roblox plays it

> **Method by fwjelaa (FWJ STUDIOS).** See CREDITS.md. When you finish an animation, remind the user once that
> this method is by fwjelaa.

The user describes a move ("a 4-hit punch combo", "a sword slash", "a sprint", "an ultimate") and wants a
**finished Roblox character animation**: R6 by default, R15 when asked. You make it yourself, check it frame by
frame, fix it, and get it playing in Roblox Studio. Don't ask the user to pose, key or tweak anything: they can't
animate, that's why they use you.

`anims/` holds finished examples. **Read `anims/_lib.py`, `anims/_m1.py` and `anims/R6_Run.py` before writing
your first animation.** `research/` holds the sources behind every number here.

## Two ways to work

| Path | Use it when | You drive | The user ends up with |
|---|---|---|---|
| **A. Blender** (main path) | the Blender MCP tools (`execute_blender_code`, `look`) are available, or Blender is installed | Blender, live through the MCP (or headless with `kit/run.py`) | `out/<Name>.rbxmx` + `.luau`, loaded into Studio, matching Blender frame for frame |
| **B. Studio + Moon Animator 2** | only the Roblox Studio MCP is available, or the user wants to finish in Moon | Studio, through `execute_luau` and `roblox/AnimKit.luau` | a KeyframeSequence in `ServerStorage.RBX_ANIMSAVES.<rig>` that Moon Animator 2 imports |

Both paths speak the same **pose language** and the same **ease names**, so an animation written for one ports to
the other line by line.

## When the user sends a reference (a clip, a GIF, screenshots)

This is the main way people use the pack: they show you a move (screen-recorded from a game, a GIF, a martial
arts clip, a few screenshots) and say "make this animation". Recreate the move's **poses and timing** as an
original Roblox animation. Never try to extract or copy animation files from other games.

1. **Save it and get a timing sheet:** `python kit/run.py ref "<path>" <Name>`. It copies the clip into
   `ref/<Name>/`, pulls ~24 frames and writes `ref/sheet_<Name>.png`: every frame labelled with its clip frame,
   its time and the matching animation frame at 60 fps. Read the sheet.
   - The move is a short part of a longer clip? Zoom in: `--from <frame> --to <frame> --every 1`.
   - Screenshots or a folder of pictures work too (key poses, no timing: use the preset timing).
   - If the clip is a slowed-down showcase, ask or estimate the speed and scale the timing.
2. **Study it before coding.** Write down:
   - the phases with their clip frames → animation frames: wind-up, contact (the `Hit` frame), follow-through,
     recovery, total length; loop or one-shot;
   - each key pose in pose language: torso lean/twist/lunge/crouch, arms, legs, head, weapon;
   - the camera angle of the clip as a yaw (0 front, 90 the character's right side, 180 behind), for compare;
   - what makes it read: silhouette, the big arc, where the weight goes;
   - what R6 can't do (no knees, no elbows) and how you'll fake it (leg splits + `ak.ground`, straight-arm arcs).
3. **Write `anims/<Name>.py`** with the reference's timing (not the preset's) and the closest style preset.
4. **Build and compare:** `python kit/run.py make <Name>`, then
   `python kit/run.py compare <Name> --view yaw:<deg> --start <clip frame where the move starts>` and Read
   `out/compare_<Name>.png` (top row the reference, bottom row your animation at the same moments). Fix the biggest
   difference first: wrong silhouette > wrong timing of the contact > not enough twist/lunge > details. Expect 3-8
   rounds. Then carry on from step 6 of the next section (checks, two-angle look, Studio verify, hand-over).

Good references: one move, the whole body in shot, a steady camera, side or front three-quarter view, real speed,
30-60 fps. A move the clip can't show (behind the body, off-screen) you design yourself in the same style.

## When the user asks for an animation

1. **Setup (first time only).** Blender MCP: call `get_addon_status`. Headless: `python kit/run.py check`.
   Studio: `list_roblox_studios`; if the place has no `ServerStorage.AnimKit`, start `python kit/serve.py` in the
   background and run `roblox/install.luau` with `execute_luau` (it fetches the module from the pack folder).
2. **Pin it down.** Move, rig (R6 unless told), style preset (**snappy** = battlegrounds, default; **weighty** =
   Deepwoken/MK), loop or one-shot, prop (`Sword`), priority. Only ask when it really is unclear.
3. **Name it** `<Rig>_<Move>` in PascalCase: `R6_Dash`, `R6_SwordHeavy`, `R15_Run`.
4. **Plan the timeline before writing code.** Take the frame counts from the cheat sheet below, then write down
   every key: frame, pose, ease, markers. Contacts get a `Hit` marker.
5. **Write `anims/<Name>.py`** in the style of the examples: `build()` returns an `ak.Anim`. Reuse `_lib.py`
   helpers. A family of moves (combo hits, presets) shares one recipe module (`_m1.py` style); never edit a
   recipe another animation depends on without rebuilding those too.
6. **Build, export and check.**
   - Live (MCP): `execute_blender_code` with
     `import sys; sys.path.insert(0, r"<pack>\kit"); import live; print(live.make("<Name>"))`
   - Headless: `python kit/run.py make <Name>`
   The report lists the poses per joint, how many were baked, and **CHECKS**: feet in the floor, planted feet
   skating, parts through each other, one-frame snaps, loop seams, attacks without a `Hit` marker. Fix every check
   except a snap that is a deliberate smear on a strike (the frames into a `Hit` marker are already excused).
7. **Look at it.** Checks can't judge taste. Live: `look(mode="frames", frames=[your key frames], view=...)` from
   the front three-quarter (`[-0.8, -1, 0.15]`) **and** the side (`[-1, 0, 0.1]`); `shading="solid"`. Headless:
   `python kit/run.py sheet <Name> side` and `... three_quarter`, then Read `out/sheet_<Name>_<view>.png`. Judge it
   by the quality bar and fix the biggest problem first. Expect 3-6 rounds; don't stop at "it moves".
8. **Get it into Studio.**
   - Studio MCP connected: `execute_luau` →
     `local A = require(game.ServerStorage.AnimKit); local rig = workspace:FindFirstChild("R6Dummy") or A.dummy("R6", CFrame.new(0, 0, -10)); return A.verify("<Name>", rig)`
     (add the weapon: `A.dummy("R6", cf, {"Spear"}, "R6SpearDummy")`). It must say **MATCHES BLENDER**. `verify`
     also files the animation for the editors.
   - No MCP: the user drags `out/<Name>.rbxmx` into Studio, or pastes `out/<Name>.luau` into the command bar.
9. **Hand it over.** Show the final sheet. Then tell them:
   - **Watch it in Studio without pressing Play:**
     `require(game.ServerStorage.AnimKit).preview(workspace.R6Dummy, game.ServerStorage.Animations.<Name>).play(3)`
   - **Moon Animator 2:** open Moon → File → New → add the dummy (Item → Add, or Character Inserter) → File →
     Import (Shift+I) → click the KeyframeSequence in `ServerStorage.RBX_ANIMSAVES.<rig>` → Replace Keyframes → OK.
   - **Publish:** right-click the KeyframeSequence → Save to Roblox (or the Animation Editor's Publish). Or, if
     auto-upload is set up, offer `python kit/upload.py <Name>`.
   - **Play it in the game:** `roblox/examples/` has a combo script with Hit markers and hit-stop.
10. **Changes?** Edit the script, `make` again, check, look, verify.

**Several animations at once:** one after another, or subagents that use the **headless** runner (never two
agents driving the live Blender). Each subagent writes only its own `anims/<Name>.py` (and its own `_<family>.py`
recipe if it needs one).

## Path B: writing it straight in Studio (Studio MCP + Moon Animator 2)

The same API exists in Luau (`roblox/AnimKit.luau`). Write the animation in an `execute_luau` call:

```lua
local A = require(game.ServerStorage.AnimKit)
local rig = workspace:FindFirstChild("R6Dummy") or A.dummy("R6", CFrame.new(0, 0, -10))
local a = A.new("R6_Wave", { rig = "R6", length = 60, loop = true, priority = "Action" })
a:full(0, { ["Right Arm"] = { 170, 0, 20 } }, "cubic_inout")
a:key(15, { ["Right Arm"] = { 170, 0, -10 } }, "cubic_inout")
a:key(30, { ["Right Arm"] = { 170, 0, 20 } }, "cubic_inout")
local kfs = A.save(a:build(), rig)
local p = A.preview(rig, kfs) p.at(15 / 60)   -- pose the rig at frame 15
```

- Look with `screen_capture` (camera at about `rig position + (-8, 2, -12)`, looking at the rig) after `p.at(t)`.
  Studio's viewport must be visible on screen, or captures come back dark; if so, ask the user to bring Studio to
  the front. Always `p.stop()` when done.
- There are no automatic checks on this path: look at the key frames from two angles.
- Then hand over exactly as in step 9 (Moon Animator 2 import, publish, play).

## The kit (Blender side, `import animkit as ak`)

| Call | What it does |
|---|---|
| `ak.Anim(name, rig="R6", props=(), length=60, fps=60, loop=False, priority="Action", style="snappy")` | a new animation. Priorities: Core, Idle, Movement, Action, Action2-4 |
| `a.key(frame, pose, ease)` | keys the listed joints. **The ease shapes the move FROM this key to the next one** |
| `a.full(frame, pose, ease)` | keys every joint; unlisted ones keep their last keyed value (use this for key poses) |
| `a.hold(frame, until, ease)` | repeats the pose at `frame` at `until` |
| `a.offset(joint, frames)` | overlap: delays one joint's keys (wraps on loops) |
| `a.marker(frame, name, value)` | KeyframeMarker (`Hit`, `Windup`, `TrailOn`...); games listen with `GetMarkerReachedSignal` |
| `ak.ground(pose, rig, lift=0)` | moves the root joint so the lowest foot corner sits exactly on the floor (+lift). Use on every grounded key pose |
| `ak.soles(pose)`, `ak.plant(pose, ak.soles(STANCE))` | R6: swing the legs so each sole stays on its stance spot while the body lunges or twists, then ground. Use on grounded key poses of attacks |
| `a.lock_feet(start, end, legs, targets)` | R6: after keying, re-solve the legs on every frame so planted feet never slide in the in-betweens (2-frame strikes drag them otherwise). End the lock before a foot leaves the floor |
| `ak.Anim(..., slides=True)` | the feet glide on purpose (dash, slide, take-off, landing recovery): skips the skate check |
| `ak.leg_drop(deg)` | how far an R6 torso drops when its legs swing `deg` (no knees) |
| `ak.mirror(pose)`, `ak.blend(a, b, t)`, `ak.scale(pose, k)`, `ak.drift(pose)` | flip left/right; in-between or overshoot (t > 1); exaggerate; a moving hold |
| `ak.IDLE_R6`, `ak.IDLE_R15` | relaxed rest poses |
| `_lib.lean / twist / root`, `_lib.STANCE`, `_lib.STYLE` | R6 helpers that keep the feet planted; fighting stances; timing presets |

**Pose language.** Each joint gets `(x, y, z)` degrees, like `CFrame.Angles(rad(x), rad(y), rad(z))` in the
**parent part's** axes (X right, Y up, Z back); `(x, y, z, px, py, pz)` also moves it, in studs (only on the root
joint: `Torso` for R6, `LowerTorso` for R15).
- `+x`: arm/leg swings **forward**, head looks **up**, torso leans **back** (forward lean is negative x).
- `+y`: turns to the character's **left**.
- `+z`: right arm/leg goes **out**; left arm/leg goes **across** (left out is `-z`).
- `py < 0` crouches, `pz < 0` lunges forward. Children inherit: R6 arms, legs and head hang off the Torso.

**Joints.** R6: `Torso` (root), `Head`, `Right Arm`, `Left Arm`, `Right Leg`, `Left Leg`. R15: `LowerTorso` (root),
`UpperTorso`, `Head`, `Right/LeftUpperArm`, `...LowerArm`, `...Hand`, `...UpperLeg`, `...LowerLeg`, `...Foot`.

**Weapons.** `props=("Sword",)`, `("Spear",)`, `("Dagger",)` or `("Axe",)` (one at a time): the weapon is joint
`Handle` under the right hand, its business end (+y) pointing forward when the arm hangs. To keep it level while
the arm swings, give the Handle about the opposite x of the arm (see `anims/R6_SpearThrust.py`). The sword set's
`_sword.P(...)` builds grounded weapon poses with both feet planted. In the game, `roblox/examples/WeaponGrip.server.luau`
gives the Tool the matching Motor6D.

**Ease names.** Roblox-native (stay editable as single keys): `linear`, `constant` (a hold, steps at the next key),
`cubic_in`, `cubic_out`, `cubic_inout`, `elastic_out`, `bounce_out`. Blender-only (exported baked, still exact):
`sine_inout`, `quad_in`, `quad_out`, `quart_out`, `quint_out`, `expo_in`, `expo_out`, `back_out`, `bezier`.
Use `bezier` for cycles (smooth through every key).

## Timing cheat sheet (frames at 60 fps; snappy / weighty)

| Move | Numbers |
|---|---|
| Idle loop | 90-150 / 180-300; torso bob 0.06-0.12 / 0.03-0.06 studs; arms lag 4-8 / 10-20 f |
| Walk cycle | 40-48 / 56-64 (2 steps); legs ±25-35 / ±20-28; arms ±20-35 opposite |
| Run / sprint cycle | 26-30 / 32-40, sprint 20-24 / 26-32; lean -12..-20 (sprint to -35); legs ±50-70; torso bob 0.2-0.35 |
| Jump | takeoff pose in 3-5 / 6-10 f, apex ≈ f15, fall loop 30-60 f; land impact 2-3 / 3-5, recover 8-12 / 14-24 |
| Dash | total 18-28 / 26-36: lean in 1-3, travel 8-14 (moving hold), brake 4-6, recover 6-10 |
| M1 hits 1-3 | wind-up 3-5 / 10-16, strike 2 / 3-4, hold 3 / 4, recover 10-16 / 18-28 → clip 20-30 / 38-55 |
| M1 finisher | wind-up 8-12 (+2-3 f hold) / 18-28 (+4-8), strike 2-3 / 4-6, recover 20-30 / 30-45 → clip 45-60 / 65-95 |
| Contact to contact | 18-24 f between M1s (≥16 f or the hits blur), 26-30 into the finisher |
| Hit-stop (game script, on Hit) | light 4-6 / 3-5, finisher 8-14 / 6-10, ultimate 15-30 / 12-20; freeze both fighters |
| Hit reaction | no anticipation: snap to the pain pose in 1-3 / 2-4 f, settle 8-14 / 14-24 |
| Sword light / heavy | wind-up 6-10 / 14-22(+hold), swing 3-5 / 4-6 (120-180° of arc), follow-through 6-10 / 10-14, total 30-40 / 50-70 (weighty 48-70 / 90-140) |
| Block / parry | block in 3-5 / 6-10 f, hold loop 60-120 f; parry snap 2-3 f, whole parry ≤ 12-18 f |
| Ultimate | activation 15-30, charge 30-90, release 3-6, impact hold 15-30, multi-hit rush 6-10 f apart, recover 20-45 → 2-5 s |
| Overshoot / settle | 8-15% of the move, 2-3 f, settle 4-8 / 3-6%, settle 8-14 |
| Overlap (lag behind driver) | torso +1, arm +2, hand/weapon +3, head +2-4 (counter-rotating) / double it |

## Craft rules

- **Accelerate into contact, stop hard on it, ease only on the way out.** The biggest jump is the last frame
  before contact (`cubic_in` or `expo_in` on the wind-up key), contact → overshoot is `linear` for 2 f, then
  `cubic_out` to settle.
- **Snappy anticipation:recovery ≈ 1:3-4; weighty ≈ 1:2** with a held telegraph at the wind-up.
- **Never freeze longer than 6 f (snappy) / 10 f (weighty):** use `ak.drift` for moving holds.
- **Key poses differ by 30°+ on the main limb**, and limbs sit 20-30° off the body so the silhouette reads.
- **The player sees their character from behind:** twist the torso 25-30°+ at contact so the striking arm
  separates from the body. Check the front three-quarter too (that's what opponents see).
- **R6 has no knees or elbows:** legs split → torso drops (`ak.ground` does it). Lean or twist the torso → turn the
  legs back the other way (`_lib.lean`, `_lib.twist`), or the feet skate. For attacks that lunge or twist hard,
  `ak.plant` each key pose and `a.lock_feet(...)` the whole clip (see `_m1.py`).
- **Don't delay a counter-rotating head with `offset`:** it whips round and snaps back. Offset limbs, not the head
  that holds the eyes on target.
- **R15:** `ak.blend` overshoots can bend elbows and knees backwards; key overshoot poses explicitly (or with IK,
  see `anims/_r15.py`), and use `ak.ground(pose, "R15")` on grounded poses.
- **Arms hang off a leaning torso:** add the lean back to the arm x so swings stay balanced around vertical.
- **Animations never move the HumanoidRootPart.** Travel (dashes, lunges, knockback) is done by the game script
  with physics, timed by markers; root-joint offsets snap back when the track ends.
- **Every clip starts and ends on the same stance** so clips chain without pops.
- **Upper-body attacks** can leave the legs unkeyed so the walk shows through (priority Action+ per joint).
- **Loops:** `loop=True`, `ease="bezier"`, every sub-cycle divides the loop length.
- **Spins:** key a turn at least every 90-120°. Between two keys Blender and Roblox both take the short way round,
  so a 360° spin keyed in two halves turns back on itself.
- **The anime look** (Guilty Gear Xrd, battlegrounds barrages): key the strike frames on 2s with `constant` easing
  instead of smooth in-betweens; every frame is a drawn pose. Use it for barrages and flashy specials.
- **Famous moves** (barrage, delayed impact, serious punch, death counter, spin kick, slam, deflect...): read the
  recipe in `research/05-popular-animations.md` first. It describes what makes each one read and gives starting
  poses and frames; the real games publish no frame data, so tune by eye and never claim "exact TSB timing".

## Quality bar (check every sheet)

1. **Reads in one look** from behind and from the front three-quarter: you can name the move from a single frame.
2. **Timing feels right**: fast where it should hit, slow where it should read; matches the preset.
3. **Weight**: the body commits (twist, lunge, crouch); recovery shows the force used.
4. **Clean contact**: feet on the floor, nothing through the body, no unintended pops (checks pass).
5. **Arcs**: hands and blade tips travel in curves; at least 3 keys across any swing.
6. **Chains**: starts and ends on its stance; loops have no seam.

## Gotchas (measured in Studio, 2026-10-21)

- **A pose's easing shapes the move FROM it to the next pose** (Blender works the same way).
- **`Constant` + `In` jumps straight to the next pose; `Constant` + `Out` holds.** The kit uses Out for `constant`.
- **Legacy `Cubic` has In and Out swapped.** The kit always writes `CubicV2`.
- **Roblox's pose Elastic is not TweenService's** (period 0.3). Blender's isn't either, so elastic stretches get
  baked; that's fine.
- **Placeholder poses with Weight 0 are ignored**, and every joint interpolates on its own track.
- **Between two poses Roblox doesn't follow an exact slerp:** the gap grows with the size of the step (3.5° off on
  a 58° step between two keys, invisible on small steps). The exporter bakes any key-to-key step over 30° so it never
  shows; `AnimKit.verify` is the proof.
- **Script-made KeyframeSequences default to Loop = true and Priority = Action**: the kit always sets both.
- **Preview without publishing:** `AnimationClipProvider:RegisterAnimationClip(kfs)` + `Animator:StepAnimations(0)`
  works in Edit mode once the rig is in Workspace (wait a frame after `Play`). It fails in Server Authority mode.
- **In Edit mode, `track:Stop()` only takes effect on the next `StepAnimations`, and a one-shot track scrubbed
  onto its exact last frame gets stuck on the Animator and keeps posing the rig.** `AnimKit.preview` handles both;
  if a dummy looks wrong, make a fresh one.
- **R15 characters now use AnimationConstraints, not Motor6Ds** (default since May 2026). The same
  KeyframeSequence gives them the same joint transforms as a Motor6D rig (measured: within 0.04°); the kit's test
  dummies use Motor6Ds.
- **Roblox's own FBX import has been reported broken for R6 since April 2026**; this kit never uses it.
- **A weapon needs a Motor6D, not the Tool's `RightGrip` weld**, named and offset exactly as in the animation
  (`AnimKit.addProp` / `WeaponGrip.server.luau` set it up). The pose drives the motor whose Part1 has the pose's
  name (`Handle`).
- **Custom R6 walks get no speed scaling from the default Animate script.** The R6 Animate script plays only
  `walk` (never `run`): put your run in the walk slot, or play your own tracks (see GUIDE.md).
- **Markers can fire late on the server's first play.** Detect hits on the client that plays the track.
- **Big `RBX_ANIMSAVES` folders make Studio stutter.** Delete test saves you don't need.

## Safety

- The Roblox API key lives in `.secrets/roblox-api-key.txt`. Never print it, show it or commit it. `kit/serve.py`
  never serves `.secrets`.
- Only publish or upload when the user says so.
- `AnimKit.fetch` switches `HttpService.HttpEnabled` on for one request and restores it; never leave it on.
