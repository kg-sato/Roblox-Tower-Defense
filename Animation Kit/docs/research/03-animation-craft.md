# 03 - Animation craft: numeric rules for code-keyed Roblox combat animation

Research date: **2026-10-21**. Every frame count is at **60 fps** (1 frame = 16.7 ms) unless marked otherwise. To get the Roblox Animation Editor's default 30 fps, halve the number. Convert 24 fps sources with ×2.5.

Every claim carries one of these tags:
- **[S#]** comes from a source in the list in section 10. It has a date and a type.
- **(derived)** is my arithmetic from sourced numbers or from Roblox physics or rig facts.
- **(rec)** is a recommended default I chose for the preset. It is a starting value to tune by eye, not a measured fact.
- **(unverified)** comes from memory or a single weak source. Check it before stating it on camera.

**Important honesty note.** No public source gives frame data for The Strongest Battlegrounds, Jujutsu Shenanigans, or Deepwoken animations. Their wikis are paywalled or blocked (fandom returned 402/403), and third-party guides give only damage numbers and qualitative notes [S27]. The two presets below therefore anchor on:
- fighting-game frame data: SF6, KOF XIII, Smash, and Capcom's own hitstop example,
- action-game measurements: Ninja Gaiden, God of War,
- game-animation guidance: Game Anim / gameanim.com, Cartwright's GDC talk, MoCap Online,
- Animator's Survival Kit timing,
- Roblox engine facts.

Those numbers were then tuned toward the "snappy battlegrounds" or "weighty" feel. If the video claims "this is TSB's exact timing", that claim has to be measured first. Record the game at 60 fps and step through it frame by frame.

Pose language matches `kit/animkit.py`. Each joint is `(x, y, z)` in degrees, rotated in the PARENT part's axes (X right, Y up, Z back). Translation `(px, py, pz)` in studs applies to the Torso (RootJoint).
- `+x`: an arm or leg swings FORWARD, the head looks UP, the torso leans BACK. A forward lean is therefore **negative x**.
- `+y`: turns to the character's LEFT.
- `+z`: the right limb goes OUT to the side. The left limb mirrors it with `-z`.
- Forward lunge = **negative pz**. Crouch = **negative py**.

---

## 0. TL;DR - the 15 rules that matter most

1. **Contact is a hard stop, not an ease.** Accelerate into contact so the biggest spacing is the last frame before it. Hold or freeze on contact. Ease only on the way out. [S3][S12] (rec)
2. **Hitstop scales with weight.** Capcom's teaching example is light/medium/heavy = **8/12/16 frames** [S8]. KOF XIII uses **7 light / 11 heavy** [S6]. Smash Ultimate uses about **0.65 × damage + 6**, capped at **30** [S7]. For snappy M1s use 4-6 f, finishers 8-14 f, ultimates 15-30 f (rec).
3. **Freeze both fighters during hitstop.** Shake the victim (and the attacker slightly). On the ground the shake is side to side, in the air it is up and down, and its amplitude decays over the stop [S9].
4. **Player attacks get short anticipation.** NPC attacks get longer anticipation so players can react [S2]. Even **1 frame** of anticipation improves readability [S13].
5. **Real light attacks are tiny.** SF6 Ryu's 5LP is **4 startup / 3 active / 7 recovery** (14 f total) and 5LK is **5/3/11** [S5]. Heavy normals are never faster than about **8-9 f startup** [S28].
6. **Hits closer together than 16 f at 60 fps read as one long hit** unless each hit has its own VFX or SFX. Song's measurement is <8 f apart at 30 fps is hard to read and <5 f reads as one hit [S11].
7. **Snappy uses about 1:3-4** anticipation:recovery. **Weighty uses about 1:2**, with a held telegraph at the wind-up extreme. (rec, built on [S5][S20])
8. **Walk timing:** a natural walk is 12 frames per step at 24 fps, which is **30 f per step at 60 fps**. A run is 6 frames per step at 24 fps, which is **15 f**. Contact poses fall at 1/13/25 at 24 fps [S1]. A game run cycle is 16-20 f at 30 fps (32-40 f at 60) and a sprint is 12-16 f at 30 fps (24-32 f at 60), with a **15-30° sprint lean** [S19].
9. **R6 has no knees.** Whenever legs split by ±φ, lower the Torso by `2·(1 − cos φ)` studs or the feet float. Examples: 25° → 0.19, 35° → 0.36, 45° → 0.59 (derived, leg length 2 studs).
10. **In R6 the legs hang off the Torso.** Leaning the Torso by θ means adding the opposite θ to both legs. Twisting the Torso by y means counter-twisting the legs and head (derived).
11. **Offset the chain.** Root leads, then torso +1, arm +2, hand/weapon +3, head +2-4 frames (snappy). Double those for weighty (rec, from [S2][S13]).
12. **Animation priorities:** use Action+ for attacks and leave the legs unkeyed for upper-body M1s. Priority is evaluated **per joint, from high to low, until the weights sum to 1.0** [S14].
13. **Animations never move the HumanoidRootPart.** Torso offsets snap back when the track ends. Drive real travel with physics or CFrame, synced by markers [S35].
14. **Use the CubicV2 easing style, never Cubic.** Cubic "has a bug where the direction is reversed between the editor and runtime." Pose In/Out are named **backwards** from TweenService [S15][S16]. See section 8.4. The kit's `roblox_alpha` needs a one-time Studio check.
15. **Put a `Hit` KeyframeMarker on the contact frame and fire hit logic from the client** that plays the track. Markers can be late on the server's first play, so send the result over a RemoteEvent [S17][S36].

---

## 1. Movement set

### 1.1 Idle

| Parameter | A: snappy (battlegrounds stance) | B: weighty | Basis |
|---|---|---|---|
| Loop length | 90-150 f (1.5-2.5 s) | 180-300 f (3-5 s) | Rest breathing is 12-20 breaths/min, so 3-5 s per breath [S33]. Snappy runs faster because a "ready" stance is aroused, not resting (rec) |
| Torso `py` bob (peak to peak) | 0.06-0.12 studs | 0.03-0.06 studs | (rec) At 15 studs from the camera, 0.06 studs is about 3 px at 1080p (derived, sec 7.7) |
| Torso `x` (chest rise) | ±1-2° | ±0.5-1.5° | (rec) |
| Arms `x` | ±2-4° (guard up: arms x +30..+60, fists forward) | ±1-2°, hanging | (rec) |
| Arm lag behind torso | 4-8 f | 10-20 f | Overlap (rec) |
| Head lag | 6-10 f, counter to the torso | 10-20 f | (rec) |
| Weight shift (`z` roll ±1-2°, `px` ±0.05) | optional, 1 per loop | on a slow cycle at 2× or 3× the breath loop | (rec) |

Rules:
- Every sub-cycle period must divide the loop length exactly. Otherwise the loop seam pops.
- Never leave an idle fully static. The minimum is the breath bob.
- Snappy stance idle: feet apart. For R6 that means legs at z ±6-10° with the Torso dropped by the formula, about 0.01-0.03 studs at those angles. Lead foot forward x +10..+15, rear foot x −10..−15, Torso y +10..+20 (bladed stance, lead shoulder toward the target).

### 1.2 Walk cycle

Sources: Animator's Survival Kit timing via the Monmouth teaching page [S1]. Contact on 1, 13 and 25 at 24 fps. The passing position sits exactly halfway between contacts, with the body moving up a bit. The page's table has arithmetic slips; corrected values are below.

| Survival Kit cycle @24 | Frames per step @24 | @60: frames per step / cycle | Character |
|---|---|---|---|
| 48 | 24 | 60 / 120 | slow step |
| 32 | 16 | 40 / 80 | strolling |
| 24 | 12 | **30 / 60** | natural, "business" walk |
| 16 | 8 | 20 / 40 | slow run / cartoon walk |
| 12 | 6 | **15 / 30** | run / very fast walk |
| 8 | 4 | 10 / 20 | very fast run |

The page lists 4 frames per step for the 12-frame cycle and 6 for the 16-frame cycle. Those are inconsistent with a 2-step cycle and are corrected above (derived).

**Pose order within one step, from Williams' contact → down → passing → up method.** For a 30 f step at 60 fps:
- contact at f0 (legs at their extremes, heel down)
- down at about f7 (body lowest, weight absorbed)
- passing at f15 (legs cross)
- up at about f22 (body highest, push-off)
- next contact at f30.

**R6 adaptation (derived).** With rigid legs, the geometry inverts the bob. The body is naturally *lowest at contact*, because the legs are split ±φ and the feet rise by `2(1−cos φ)`. It is *highest at passing*, because the legs are vertical. Key `py = −k·2(1−cos φ)` at contact (k = 0.6-1.0; below 1 the feet sink a little, which nobody sees) and `py = +0.02..0.06` at passing.

Stylized R6 walk values (rec, informed by human gait):

| Joint | A snappy | B weighty | Human reference |
|---|---|---|---|
| Legs x | ±25-35° | ±20-28° | Hip about 30° flexion at initial contact and about 10-15° extension in late stance, ~40° total [S31] |
| Arms x (opposite the legs) | ±20-35° | ±12-20° | Elbow range in walking is about 29.7° (Kang 2023) [S32]. R6 has no elbow, so the shoulder exaggerates it |
| Torso y (shoulder twist following the arms) | ±3-6° | ±2-4° | counter-rotation of shoulders against hips [S20] |
| Head y | counter the Torso y (−60..−80% of it) | same | keeps eyes forward |
| Torso py | formula above | formula above, lowest held 1-2 f longer | |
| Arm lag behind opposite leg | 1-2 f | 2-4 f | overlap |

**Speed matching on Roblox (derived).**
- The default `WalkSpeed` is 16 studs/s.
- With legs swinging ±φ, one step covers at most about `4·sin φ` studs (2-stud legs, front extreme to back extreme). At φ = 30° that is 2 studs per step.
- Walking at 16 studs/s without sliding would need 8 steps/s, about 7.5 f per step. That is far too fast to read.
- **Accept 40-60% foot slide.** It is the standard R6 look.
- Pick a cycle that reads: 40-48 f (snappy) or 56-64 f (weighty). Scale playback with `AdjustSpeed(currentSpeed / authoredSpeed)`.
- The default R6 Animate script is believed to scale its walk clip by `speed / 14.5` (unverified recall; check `Animate` in a Play session).

### 1.3 Run and sprint

| | A snappy | B weighty | Source |
|---|---|---|---|
| Run cycle | 26-30 f (13-15 f/step) | 32-40 f (16-20 f/step) | Game run 16-20 f @30 = 32-40 @60 [S19]. Survival Kit run "on 6s" = 15 f/step [S1] |
| Sprint cycle | 20-24 f (10-12 f/step) | 26-32 f | Sprint 12-16 f @30 [S19]. Survival Kit "on 4s" = 10 f/step [S1] |
| Torso lean (x), run / sprint | −12..−20° / −20..−35° | −6..−12° / −12..−20° | Sprint 15-30° lean [S19] |
| Legs x | ±50-70° | ±40-55° | (rec) |
| Arms x | ±50-80° pumping, OR the "trailing" style below | ±35-55° | aggressive arm pump in a sprint [S19] |
| Torso py, peak to peak | 0.20-0.35 | 0.15-0.25 | (rec). Lowest point just after contact ("down"), highest in flight |
| Head | counter-pitch +40-70% of the lean so the eyes stay level; bob lags 2-4 f | same, lag 3-5 f | "head bobs a few frames after foot impact" [S20] |
| Leg lean compensation | add +|lean| to both legs' x | same | (derived, rule 10) |

Run pose order per step: contact → down (lowest, 2-3 f after contact in snappy, 3-5 in weighty) → push-off → flight (highest) → next contact. Run cycles have fewer frames than walks [S21].

**The R6 run look.** There are three community archetypes. I observed these but did **not** verify which specific game uses which:
1. **Straight-arm pump (classic R6).** Arms and legs swing opposite as straight rods. Keep arms at ≤ ±70°, because beyond that the rods read as windmills. The legacy procedural R6 Animate used `amplitude * sin(time * frequency)` on shoulders and hips, with arms and legs in counter-phase [S24].
2. **Trailing-arm "ninja" sprint.** Both arms x −60..−90 with z ±10-20 (trailing behind). Torso x −25..−35. Fast leg cycle at ±60-70°. Head x +15..+25 to look forward.
3. **Brawler jog.** Arms held in guard at x +20..+40 with a small ±10-15° pump. Torso x −8..−12. Use it for "combat stance" movement.

R15 differences (rec plus gait data):
- Bend the knees instead of using the drop formula: about 60-65° knee flexion in walk swing [S31], 90-120° in run swing.
- Elbows: about 30° range in a walk [S32], held at about 70-100° flexed in a run.
- Waist (UpperTorso) counter-twists the hips by ±8-15°.
- The R15 Animate script blends walk and run by speed, with about a 0.2 s blend [S25].

### 1.4 Jump, fall, land

Roblox physics (derived):
- Gravity is 196.2 studs/s². The default jump (JumpPower 50) gives v₀ = 50 studs/s.
- Time to apex is 50/196.2 = **0.255 s ≈ 15 f**. Flat-ground airtime is about **31 f**.
- With `JumpHeight` 7.2, the apex comes at about 16 f.

| Phase | A snappy | B weighty | Notes |
|---|---|---|---|
| Pre-jump anticipation | **0 f in gameplay** | 0 f (or 3-5 f only if gameplay allows a delayed jump) | The engine launches on input, so the anticipation has to be folded into the landing or skipped. A 2-3 f "micro-anticipation" is used in platformers when the design allows it [S34] |
| Takeoff to extreme pose | 3-5 f | 6-10 f | Legs: lead x +30..+45, trail x −10..−20. Arms x +30..+60. Torso x +5 |
| Rise hold to apex | until about f15 (moving hold) | same | Then cross-fade into the fall loop |
| Fall loop | 30-60 f loop, limbs ±5-10° | 40-80 f, ±3-6° | |
| Land impact (down) | 2-3 f, Torso py −0.3..−0.6 with legs split by the formula | 3-5 f, py −0.4..−0.8 | |
| Land recovery | 8-12 f | 14-24 f | Do not lock movement on normal landings (responsiveness). Heavy "superhero" landings: lock 20-40 f |

The legacy R6 Animate copy uses `jumpAnimDuration = 0.175` and `fallTransitionTime = 0.2` (other community copies say 0.3/0.3) [S24]. Its jump clip plays 0.175-0.3 s and then cross-fades to fall over 0.2-0.3 s.

### 1.5 Dash (front, side, back)

DevForum dash examples:
- Side dash: LinearVelocity Plane mode at **32 studs/s for 0.25 s ≈ 8 studs** [S37].
- Front dash: velocity ramping from 50 to 0 [S38], or a constant 45 studs/s [S39].
- Flatten the look-vector Y, or the dash drifts when the root tilts [S39].

| Phase (frames) | A front | A side | A back | B front | B side |
|---|---|---|---|---|---|
| Start (lean into it) | 1-3 | 1-2 | 2-3 | 3-5 | 2-4 |
| Travel (moving hold, 1-3° drift) | 8-14 | 8-12 | 8-12 | 12-18 | 10-14 |
| Brake (counter-lean, front foot planted) | 4-6 | 3-5 | 4-6 | 8-12 | 6-8 |
| Recover to stance | 6-10 | 4-8 | 6-8 | 10-14 | 8-12 |
| **Total** | **18-28** | **14-20** | **18-24** | **26-36** | **20-28** |

Pose values (rec):
- Front travel: Torso x −20..−35, legs trailing x −30..−50 (one leg tucked forward +30), arms trailing x −40..−70. Brake: Torso x +10..+15 counter-lean.
- Side: Torso z ±10-20 into the direction plus y ±10-20, legs splayed z ±20-35 (Torso drop formula).
- Back: Torso x +10..+20 (leaning away), arms forward x +30..+50 (guard), legs x ±25.
- Add a py arc during travel: −0.1..−0.2 at the midpoint, so the root path curves instead of moving in a straight line (sec 7.5).

---

## 2. M1 punch combo (4-hit battlegrounds style)

### 2.1 What is known about the real games

TSB:
- The chain is 4 hits at 3%/3%/4%/5%. The 4th hit launches the opponent.
- Jump-modified inputs turn the 4th hit into an uppercut (from the ground) or a downslam (from the air).
- After each M1 there is about a **0.2 s window where you cannot block** [S27].

DevForum combo systems usually reset the chain after about **1-2 s** of no input. One sample stuns for 1 s at WalkSpeed 3 on the final hit [S40].

No source gives TSB or JJS frame timing.

### 2.2 Reference anchors

- **Ninja Gaiden basic combo:** contacts on frames **7, 16, 29 @30 fps → 14, 32, 58 @60**, so intervals of 18 and 26 f. The heavy-sword combo hits on **11, 27, 38, 46, 54 @30 → 22, 54, 76, 92, 108 @60**. The first gap is the longest, then hits accelerate [S11].
- **SF6:** 5LP 4/3/7, 5LK 5/3/11. Chain cancel hit-confirm window 13 f [S5].
- **Multi-hit readability:** at 30 fps, hits <8 f apart are hard to read and <5 f apart read as one. At 60 fps keep **≥16 f** between beats that must read separately, or give each hit its own VFX/SFX [S11].

### 2.3 Snappy preset (A) - per-hit timing (rec)

| Hit | Anticipation | Strike travel | Contact key at | Active (hitbox) | Hitstop on hit | Hold after contact | Recovery (to stance) | Chain window opens | Clip length |
|---|---|---|---|---|---|---|---|---|---|
| 1 jab (lead arm) | 3-4 f | 2 f | f5-6 | 2-3 f | 4-6 f | 3-4 f | 10-14 f | contact +4..+6 | 20-24 f |
| 2 cross (rear arm) | 3-4 | 2 | f5-7 | 2-3 | 4-6 | 3-4 | 10-14 | contact +4..+6 | 22-26 |
| 3 hook / knee / kick | 4-6 | 2-3 | f7-9 | 3 | 5-7 | 3-5 | 14-18 | contact +6 | 26-30 |
| 4 finisher | 8-12 (2-3 f hold at the extreme) | 2-3 | f12-16 | 3-4 | **8-14** + 1-3 f impact flash | 4-6 | 20-30 | (combo ends) | 45-60 |

Cadence when the player chains as fast as allowed:
- Contact to contact is about **18-24 f (0.30-0.40 s)** for hits 1→2→3, and about 26-30 f from 3→4.
- Contacts fall at about f6, f28, f52, f80. Final contact is about **1.35 s** after the first input, plus whatever hitstop occurs (up to about 0.4 s on all-hits). The full combo ends about 2.0-2.3 s after the first input.
- The gameplay "M1 endlag" cooldown after hit 4 (0.5-1.5 s) is a design value, not part of the clip.

### 2.4 Weighty preset (B) - per-hit timing (rec)

| Hit | Anticipation | Strike | Contact at | Active | Hitstop | Recovery | Clip |
|---|---|---|---|---|---|---|---|
| 1-3 | 10-16 f (hold 2-4 f at the extreme) | 3-4 f | f14-20 | 4-6 f | 3-6 f, or a "drag" (attacker at 10-25% speed for 2-4 f) | 18-28 f | 38-55 f |
| 4 heavy | 18-28 f (hold 4-8 f, the telegraph) | 4-6 | f24-34 | 5-8 | 6-10 | 30-45 | 65-95 |

Cadence: 30-40 f contact to contact. Four hits take about 2.2-2.8 s.

"Drag" instead of a freeze for heavy weapons:
- In KUF: TC, quick attacks freeze the attacker while heavy weapons swing through [S11].
- MoCap Online recommends a "hit confirm" of 2-4 f of reduced attack velocity at contact [S12].

### 2.5 Pose recipes (R6, right-handed, starting values to tune visually) (rec)

- **Jab wind-up (f3):** Torso (0, −12, 0, 0, −0.03, +0.08). Right Arm (−20, 0, 8). Left Arm guard (55, 0, −12). Head (0, +8, 0). Legs y +8 (counter).
- **Jab contact (f6):** Torso (−8, +28, 0, 0, −0.05, −0.35). Right Arm (95, 0, −6). Left Arm (35, 0, −10). Head (−2, −18, 0). Right Leg (8, −18, 0), Left Leg (−6, −18, 0).
- **Cross:** mirror the jab with `ak.mirror()` and add 10% more twist.
- **Hook:** arm x +80 combined with z +35→−25 (sweeping across), Torso y −20→+40.
- **Uppercut (4th, ground):**
  - Load: Torso py −0.45..−0.6 with legs split ±40° (formula: 2(1−cos40°) = 0.47). Right Arm x −30, Torso x −15.
  - Contact: Right Arm x +160..+170, Torso x +8..+15 (lean back), py +0.3..+0.6 (rise), Head x +15.
- **Downslam (4th, air):**
  - Wind: both arms x +160..+180 (overhead), Torso x +15..+20 (arch).
  - Strike: arms x +20..+40, Torso x −35..−45 (fold forward), legs x +25..+40 (tuck).
- **Knockback straight punch (4th):** jab contact pushed to its limit. Torso y +45..+55, pz −0.8..−1.0 (lunge), Right Arm x 95 plus a 0.3-0.5 stud arm translation forward for 1-2 f ("stretch" smear, sec 7.6).

### 2.6 Hitstop, impact frames, hit marker

- **Hitstop lengths:**
  - Capcom example: light/medium/heavy **8/12/16 f**. Multi-hit moves get shorter hitstop so they don't feel sluggish. Projectiles give the attacker no hitstop [S8].
  - KOF XIII: **7** light, **11** heavy [S6].
  - Smash Ultimate: about 0.65·damage + 6 (15% damage → 15 f), capped at 30 f [S7].
  - Generic game-feel guides: 2-5 f [S34]. MoCap: 1-4 f [S12].
  - Chosen: A uses 4-6 / 8-14 / 15-30 (light / finisher / ultimate). B uses 3-5 / 6-10 / 12-20 (rec).
- **Who freezes.** Both fighters freeze, for the same duration [S9]. God of War holds "both Kratos and the target in that first frame" of the hit pose [S18].
- **Shake during hitstop [S9]:**
  - The victim vibrates and the attacker vibrates slightly.
  - Grounded characters shake side to side, airborne characters up and down.
  - Amplitude starts large and decays, and scales up with camera distance.
  - Hurtboxes do not move.
  - Victim flinch → hurt pose transition takes **4 frames** inside the stop.
  - Values: A ±0.08-0.15 studs on the victim, decaying, alternating every 1-2 f. Attacker 30% of that. B ±0.03-0.06 (rec).
- **Impact frames (anime flash):** about **1 frame** in anime-style flashes [S41]. A Minecraft impact-frame mod defaults to 2 frames and allows 1-5 [S42]. Use 1-3 f, on finishers and ultimates only (rec). Ninja Gaiden flashes white on certain kicks, and Dynasty Warriors darkens the screen before specials [S11].
- **Hit marker placement:**
  - Put a KeyframeMarker named `Hit` on the **contact key**: the first active frame, where the fist or blade reaches its extended pose. Do not put it at the start of the swing.
  - Keep the hitbox alive for the active frames (A 2-4 f, B 4-8 f), or do one overlap query at the marker. A DevForum battlegrounds tutorial does a single `GetPartBoundsInBox` at the punch with a box of **4.6 × 4 × 5.75 studs** in front of the HRP, detects on the client and confirms on the server [S43].
  - Useful extra markers: `Windup` (SFX), `TrailOn`/`TrailOff`, `Cancel` (chain window), `End`.

### 2.7 Hit reactions and stun

| | A snappy | B weighty |
|---|---|---|
| Entry | **no anticipation**. Snap to the pain pose in 1-3 f (fadeTime 0-0.03 s). Frozen on that frame during hitstop | 2-4 f snap |
| Pain pose | Head x +20..+35 (snaps back), Torso x +10..+20, py −0.1, pz +0.2..+0.4 (shoved back), arms flung x −20..−40 | half the amplitudes. Feet step back (R6 legs split ±15-20°) |
| Settle into the stun loop | 8-14 f | 14-24 f |
| Directional variants | front / left / right / back | same. Reactions 0.3-0.5 s, interruptible, authored for 4 directions [S12] |
| Alternate clips | A/B alternation on consecutive M1s so each hit reads | same |
| Stun duration (gameplay) | 0.4-0.8 s per M1 (rec). Final hit 1 s at WalkSpeed 3 in one DevForum sample [S40] | 0.3-0.6 s, posture-break stagger 40-70 f |
| Knockback (4th) | launch pose (Torso x +30..+45 arched, limbs trailing) → tumble / ragdoll → get-up 30-60 f | heavier stumble, 40-80 f get-up |

Also: dying enemies should still react to hits [S11]. Enemies sell power with large pose changes [S18].

---

## 3. Sword combat

### 3.1 Timing

MoCap Online's sword guide gives these numbers at 30 fps [S12]. Converted to 60 fps:
- Light swing phase 6-12 f → **12-24 f**.
- Heavy swing phase 12-24 f → **24-48 f**.
- Full light attack 20-35 f → **40-70 f**.
- Full heavy attack 45-80 f → **90-160 f**.
- One-handed swings take 0.4-0.8 s. Two-handed heavies recover in 0.8-1.5 s.
- The fastest point of the swing is at **60-70% of the arc**. Horizontal swings carry **30-60° past center** before decelerating.
- The combo window opens at about **70% of recovery**.
- A missed heavy leaves you exposed for 1-2 s.

| Phase (frames @60) | A light | A heavy | B light | B heavy |
|---|---|---|---|---|
| Wind-up | 6-10 | 14-22 + 2-4 hold | 12-20 | 24-40 + 4-10 hold (telegraph) |
| Swing (blade travels 120-180°) | 3-5 | 4-6 | 6-10 | 6-10 |
| Contact | at 60-70% of the swing | same | same | same |
| Hitstop | 3-5 | 8-12 | 2-4, or drag | 5-9, or drag |
| Follow-through (blade 30-60° past center) | 6-10 | 10-14 | 10-16 | 14-20 |
| Recovery | 10-16 | 18-28 | 16-24 | 36-60 |
| **Total** | **30-40** | **50-70** | **48-70** | **90-140** |

Deepwoken relative data point: the Great Maul swings at **0.85×** speed and is among the faster greathammers [S29]. Heavy weapons are described as deliberate wind-up with long recovery.

### 3.2 Arcs and wrist lag (R6 has no wrist, so the weapon joint is the wrist)

- Key at least **3 poses across the swing** (start, middle, end) so the blade tip follows an arc, not a chord.
- **Overlap:**
  - In the wind-up, the blade **trails** the arm by 1-2 f (snappy) or 2-4 f (weighty).
  - In the swing, the hand leads and the blade whips through 1-2 f later.
  - In the follow-through, the blade overshoots 10-20° and settles over 6-10 f.
- **Horizontal right-to-left slash (rec):**
  - Wind: Torso y −35..−50. Right Arm (70, 0, +45) (forward and out to the right). Blade yawed back about 60° (trailing).
  - Contact: Torso y +30..+45. Right Arm (80, 0, −35) (across the body). Blade leading by about 40°.
  - Follow-through: Torso y +50..+60. Right Arm (60, 0, −60). Then settle.
- **Trail VFX:** on at swing start (not during anticipation), off when the follow-through starts decelerating. Trail length scales with swing speed [S12].
- Common DevForum feedback on sword swings:
  - Use a longer wind-up with a brief hold before the swing [S44].
  - Slow the limbs while the sword is raised [S44].
  - Point the sword forward during the swing, not up [S44].
  - Overshoot the end pose, then settle [S44].
  - Pull the blade back after the slash instead of snapping to idle [S44][S45].

### 3.3 Block and parry

| | A snappy | B weighty | Source |
|---|---|---|---|
| Block enter | 3-5 f | 6-10 f | (rec) |
| Block hold | loop 60-120 f, ±1° drift. Must be comfortable to hold 5-10 s | same | [S12] |
| Block pose (R6, sword) | sword arm x 70-100, blade horizontal across the chest. Torso x −5..−10, py −0.15..−0.3 | same, py −0.3 | (rec) |
| Block pose (R6, fists) | both arms x 100-120 with inward z ±25-35 (forearms crossing in front of the face). Head x −10 | | (rec) |
| Block-stun (hit while blocking) | 6-10 f shove (pz +0.1..+0.2) | 10-16 f | (rec) |
| Parry input animation | ≤ 12-18 f (0.2-0.3 s) | same | [S12] |
| Parry active window (gameplay) | 10-18 f (0.17-0.3 s) | 8-14 f | Sekiro deflect about **12 f (0.2 s)** from animation data [S30]. MoCap: about 4-8 frames, fps unstated [S12] |
| Deflect | snap 2-3 f, spark plus 6-10 f mutual hitstop, hold 4-6 f, recover 10-16 f | snap 3-4, hold 6-8, recover 16-24 | (rec) |
| Attacker "parried" stagger | 30-45 f (weapon thrown back, Torso x +15) | 45-70 f | (rec) |

Parry design note from the DevForum: only allow parrying while the attacker's attack animation is in its active part, not whenever a hitbox touches [S46].

### 3.4 Attaching and animating the weapon on Roblox

- The default Tool grip is a **Weld named `RightGrip`**, which cannot be animated. Replace it with a **Motor6D**:
  - Part0 = `Right Arm` (R6) or `RightHand` (R15).
  - Part1 = the handle (or a `BodyAttach` root part).
  - Keep the name and C0/C1 identical between the animation rig and runtime. A pose drives the motor whose Part1 has the pose's name [S16].
  - Using `Motor` instead of `Motor6D`, or name clashes, are the usual failure causes [S47].
- **Headstackk's standard method [S26]:**
  - Give the tool a `BodyAttach` part. Weld the static parts to it and Motor6D the moving parts.
  - On the server, add a Motor6D `ToolGrip` to the character's Torso (UpperTorso for R15).
  - On equip, set `ToolGrip.Part1 = BodyAttach`. Optionally mirror this in a LocalScript for zero-latency attach.
  - Turn `RequireHandle` off.
  - Play the hold animation at **Action** priority, so custom idles don't override it.
- **Which part to attach to:** attach to the Right Arm when the weapon follows the hand. Attach to the Torso when it must leave the hand (throws, hand swaps) [S26].
- The default Animate `toolnone` animation raises the R6 right arm when a tool is equipped. Override it with your own hold animation, or remove that ID [S47].

---

## 4. Specials and ultimates

Structure (rec; anchors in brackets):

| Phase | A snappy (battlegrounds) | B weighty | Notes |
|---|---|---|---|
| 1. Activation / "super flash" | 15-30 f | 10-20 f | MUGEN's SuperPause defaults to **30 ticks = 0.5 s** with a screen darken [S48]. KOF and SF freeze the screen on super activation [S49]. Camera punch-in: FOV 70 → 55-60 over 6-10 f (rec; Roblox default FOV is 70 [S50]) |
| 2. Charge / coil | 30-90 f, or a 20-40 f loop for hold-to-charge | 20-60 f | Vibrating hold: root jitter ±0.02-0.05 studs or ±0.5-1° every 1-2 f. The anticipation extreme is the pose |
| 3. Release | 3-6 f to the strike extreme (smear/stretch) | 6-10 f | |
| 4. Impact | hitstop 15-30 f (Smash cap 30 [S7]) plus 2-4 f impact flash. Camera kick FOV +10-20, shake 0.3-0.6 studs decaying over 15-25 f | hitstop 12-20 f, shake 0.15-0.3 | Slow-motion before the big hit is used in God of War and PoP:WW [S11] |
| 5. Multi-phase rush (optional) | 5-12 hits **6-10 f apart**, each with its own VFX/SFX. Final hit gets the biggest freeze | 3-5 hits 12-20 f apart | <16 f spacing needs per-hit effects [S11] |
| 6. Pose hold for camera | 30-60 f moving hold (1-3° drift plus camera drift) | 20-40 f | |
| 7. Recovery | 20-45 f | 30-60 f | |
| **Typical total** | **2-5 s** (cinematic awakenings 4-8 s) | **1.5-3 s** | estimate (no source for Roblox games) |

Camera on Roblox:
- A KeyframeSequence cannot animate `workspace.CurrentCamera` directly.
- Common practice is to animate a **camera part** in the rig (Moon Animator-style) and copy its CFrame to the camera every frame during the move, or to drive camera tweens from KeyframeMarkers (unverified as "the" standard).
- Some games freeze the round clock during cinematic supers (MvC Infinite) [S49].

---

## 5. Universal principles as coder rules

### 5.1 Timing ratios

| Rule | A snappy | B weighty |
|---|---|---|
| Anticipation share of the clip | 15-25% | 25-40% |
| Contact at | 20-30% of the clip | 30-45% |
| Recovery share | 50-65% | 45-60% |
| Anticipation : recovery | 1 : 3-4 | 1 : 2 |
| Telegraph hold at the wind-up extreme | 0-3 f | 4-10 f |
| NPC/enemy version of the same attack | anticipation ×1.5-3, with a 4-10 f hold | same |

Anchors:
- SF6 5LP startup is 29% of a 14 f move, and 5LK is 26% [S5].
- Players get short anticipations and NPCs long ones [S2].
- "Even one frame" of anticipation helps readability [S13].
- Recovery must show the force used. A recovery that looks effortless makes the punch read as a "light tap" [S45].

### 5.2 Ease per phase (kit ease names)

| Segment | Ease | Why |
|---|---|---|
| rest → wind-up extreme | `cubic_inout`, or `quad_out` to decelerate into the extreme | slow into the anticipation pose |
| wind-up hold | `linear`, with 1-3° drift | moving hold |
| wind-up → contact | `cubic_in`/`expo_in`, or `linear` over 2 f (snappy) | accelerate. **The biggest spacing is the last frame before contact** |
| contact → overshoot | `linear` 1-2 f | keep the velocity through the hit |
| overshoot → settle | `cubic_out` / `back_out` | |
| recovery → stance | `cubic_out`, or `sine_inout` for weighty | |
| hit reaction entry | `constant` or `linear` (1-3 f) | no anticipation on reactions |
| cycles (walk/run/idle) | `sine_inout` / `bezier` | continuous velocity across the loop seam |

One DevForum authoring trick: block the animation in Constant (stepped), then switch to Linear [S45].

### 5.3 Overshoot and settle

| | A | B |
|---|---|---|
| Overshoot past the target | 8-15% of the motion (5-12° on a 90° swing) | 3-6% (2-5°) |
| Overshoot duration | 2-3 f | 3-5 f |
| Settle | 4-8 f, one rebound | 8-14 f, no visible rebound |
| One-frame "overextend then retract" | yes, on strikes [S13][S45] | rarely |

Elastic and Bounce easing can fake overshoot. DevForum posters like Back/Elastic for power [S45], but the amplitude can't be controlled, so key explicit overshoot poses (rec).

### 5.4 Holds

- Never leave a pose fully static for more than **6 f (A)** or **10 f (B)**. Use **moving holds**: 1-3° (A) or 0.5-1.5° (B) of drift, plus 0.01-0.03 stud of root drift (rec).
- Hitstop freezes are the exception, because they are meant to be static. Put the shake on the root instead.

### 5.5 Arcs

- Joint rotations already arc the limb tips.
- **Root translations are straight lines.** Add a vertical component in lunges and dashes (py −0.1..−0.3 at the midpoint). Add a middle key to any translation longer than 0.5 studs (rec).
- Check the arc by sampling the hand or blade-tip world position every frame. The path must be smooth with no reversals except at intended extremes.

### 5.6 Offsetting and overlap (frames the part lags its driver)

| Chain | A | B |
|---|---|---|
| Root/hips (driver) | 0 | 0 |
| Torso/chest | +1 | +2 |
| Shoulder/arm | +2 | +3-4 |
| Hand / weapon tip | +3 | +5-6 |
| Head | +2-4 (usually **counter**-rotating to stay on target) | +4-8 |
| Arms vs legs in cycles | 1-2 | 2-4 |

On R6, "root/hips" and "torso" are one joint, the RootJoint. So the chain is Torso → arms/head → weapon joint. In the kit use `Anim.offset(joint, frames)`.

### 5.7 Readability from the Roblox camera (derived)

- Default FOV is 70° [S50]. At 1080p that gives about **64 px per stud at 12 studs**, **51 px/stud at 15 studs**, and **39 px/stud at 20 studs** of camera distance (derived from 2·d·tan35°).
- A 5-stud R6 character fills about **24-30%** of the screen height at 12-15 studs.
- A 5° rotation of a 2-stud limb moves the tip about 0.17 studs, about 9 px at 15 studs. 1° is about 2 px, which is fine for breathing and invisible for acting.
- Key poses should differ by **≥30° on the main limb**.
- **The player sees their own character from behind.** Twist the torso ≥25-30° at contact so the striking arm separates from the torso silhouette. Keep limbs ≥20-30° away from the body at key poses. Vertical motion (crouch, jump) reads better than motion toward or away from the camera.
- Opponents see you from the front 3/4. Check both views. The kit's `preview.sheet` has a `three_quarter` view, so render rear and front too.
- Make attack and block silhouettes clearly distinct [S13].

### 5.8 Exaggeration and smears

| | A snappy | B weighty |
|---|---|---|
| Range of motion vs realistic | ×1.3-1.6 (twist 35-60°, lunge 0.5-1.0 studs) | ×1.0-1.2 |
| Peak strike angular speed | 30-45°/frame | 12-25°/frame |
| Smear frames (>40°/f, which the kit's `checks.py` flags as a pop) | 1 frame per strike, deliberate | none |
| Limb "stretch" (translate the arm or leg joint 0.3-0.6 studs along the limb for 1-2 f) | at contact on finishers | no |
| Skip in-betweens (Constant into contact) | yes [S45] | no |

Distorting limbs ("breaking" the body) for power is acceptable because players won't notice [S13].

---

## 6. Weight between the presets, as one knob

If one parameter `w` (0 = snappy, 1 = weighty) is wanted:
- anticipation = lerp(3, 14, w)
- hold at the extreme = lerp(0, 6, w)
- recovery = lerp(12, 26, w)
- hitstop (light) = lerp(5, 4, w), but heavies lerp(11, 8, w), because weighty sells weight with drag and follow-through more than with freeze
- overshoot % = lerp(12, 4, w)
- overlap frames ×(1 + w)
- exaggeration = lerp(1.5, 1.1, w)
- fadeTime = lerp(0.05, 0.18, w) s

---

## 7. Roblox-specific gotchas

### 7.1 Priorities and blending

- The order is Core < Idle < Movement < Action < Action2 < Action3 < Action4.
- Priority is evaluated **per joint from high to low while the summed weight is < 1.0**. Once a joint reaches 1.0, lower tracks are ignored for that joint. Equal-priority tracks blend by weight [S14][S15].
- An attack that keys only the arms leaves the legs to the walk track.
- Recommended ladder (rec):

| Priority | Use |
|---|---|
| Core | default Animate (the Animate script plays at Core [S25]) |
| Idle | custom idle / stance |
| Movement | walk, run, sprint, dash, land |
| Action | M1s, block hold, tool hold [S26] |
| Action2 | skills, sword heavies |
| Action3 | ultimates, grabs, cinematic full-body moves |
| Action4 | **victim** hit-stun, knockdown, grabbed-by reactions. These must beat the victim's own attack |

- Only one Action-or-higher animation per body group at a time. Two at the same priority on the same joint jitter [S51].
- Upper-body attacks: do **not** key the legs or Torso translation. Then lower `WalkSpeed` during the attack, or the legs skate under a frozen punch. Suggested: 16 → 6-10 during M1s 1-3, 0-4 during finishers and heavies (rec). Full-body attacks that key the legs must lock or slow movement.
- (unverified) Intermediate poses that exist only to reach a child (for example `HumanoidRootPart` → `Torso` → `Right Arm` when only the arm is keyed) should not claim the RootJoint. Check how `export.py` writes unkeyed parent poses (Weight 0 vs 1) by playing an arm-only clip over a walk.

### 7.2 Root motion

- An Animation never moves the HumanoidRootPart.
- When a track ends, the Torso offset vanishes and the character snaps back.
- Fixes [S35]:
  1. Keep RootJoint translation ≤ about 1-1.5 studs in attacks, and return it to 0 by the end of the clip.
  2. Move the real body with LinearVelocity, an impulse, AlignPosition, or a CFrame tween, started by a marker.
  3. For moves that end displaced, set the HRP CFrame to the Torso at an `End` marker or on `track.Ended`.
- Dashes use physics on the HRP with the animation running in place [S37][S38][S39].

### 7.3 Markers and events

- `track:GetMarkerReachedSignal("Hit")` fires with the marker's string parameter [S17]. Markers are added in the editor event track [S17].
- Marker signals are client-side in practice:
  - Fire your hit logic on the client that plays the track, then send it to the server for validation.
  - The **server's first play can fire markers late**. Warm it up with play() then stop(), or don't rely on it [S36].
  - The animation must be owned by the experience owner (user or group), or it won't play and markers never fire [S36].
- Markers don't advance while the track is at speed 0 (hitstop). Place them at least 1-2 f before the last key, because freezing on, or relying on, the final keyframe is unreliable [S52].
- Looped tracks fire markers every loop. Use `Step` markers for footstep SFX.

### 7.4 Easing traps (important for the kit)

- `PoseEasingStyle.Cubic` is **deprecated**: "Cubic has a bug where the direction is reversed between the editor and runtime." Use **CubicV2** [S16].
- `PoseEasingDirection` In and Out "are backwards from how these terms are used by most other animation tools and by TweenService." The docs define Out as the curve applied forward from the current key to the next, and In as the reversed curve [S16b]. TweenService defines In as "forward" (slow start) and Out as "reverse" [S16c].
- Easing set on a Pose controls the segment **to the next** keyframe ("the easing style to use to reach the next Pose's value") [S16].
- **Action for the kit:** `export.py` `roblox_alpha` models CubicV2 `In` as `t³` (slow start) and maps Blender `EASE_IN` to Roblox `In`. Read literally, the docs say Roblox `In` is the reversed curve, so the mapping may be backwards. The kit's replay check uses the same model, so it **cannot catch this**.
- Run this probe once in Studio's command bar (untested; it creates and deletes a temp model):

```lua
-- Easing-direction probe (command bar, edit mode). Prints the RootJoint yaw after 25% of a 0->90 deg key pair.
local KSP = game:GetService("KeyframeSequenceProvider")
local m = Instance.new("Model"); m.Name = "EaseProbe"
local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Anchored = true; root.Parent = m
local torso = Instance.new("Part"); torso.Name = "Torso"; torso.Parent = m
local j = Instance.new("Motor6D"); j.Name = "RootJoint"; j.Part0 = root; j.Part1 = torso; j.Parent = root
m.PrimaryPart = root
local animator = Instance.new("Animator"); animator.Parent = Instance.new("AnimationController", m)
m.Parent = workspace
local function probe(dir)
  local ks = Instance.new("KeyframeSequence")
  for i, t in ipairs({0, 1}) do
    local kf = Instance.new("Keyframe"); kf.Time = t; kf.Parent = ks
    local pr = Instance.new("Pose"); pr.Name = "HumanoidRootPart"; pr.Weight = 0; pr.Parent = kf
    local pt = Instance.new("Pose"); pt.Name = "Torso"; pt.Parent = pr
    pt.CFrame = (i == 1) and CFrame.new() or CFrame.Angles(0, math.rad(90), 0)
    pt.EasingStyle = Enum.PoseEasingStyle.CubicV2; pt.EasingDirection = dir
  end
  local a = Instance.new("Animation"); a.AnimationId = KSP:RegisterKeyframeSequence(ks)
  local tr = animator:LoadAnimation(a); tr:Play(0)
  animator:StepAnimations(0.25)
  local _, y = j.Transform:ToEulerAnglesYXZ()
  print(dir.Name, math.floor(math.deg(math.abs(y)) + 0.5), "deg  (t^3 => ~1, 1-(1-t)^3 => ~52)")
  tr:Stop(0)
end
probe(Enum.PoseEasingDirection.In); probe(Enum.PoseEasingDirection.Out)
m:Destroy()
```

- Safest policy: bake any curve whose direction matters into dense Linear keys (every 1-2 f). The kit already bakes Back, Expo and Bezier.

### 7.5 Fades, pops, loops

- **Defaults:** `Play(fadeTime=0.1, weight=1, speed=1)` and `Stop(fadeTime=0.1)`. A track's `Length` is 0 until the animation loads [S15].
- **Fade times (rec):**
  - Snappy attack start 0.03-0.06 s (2-4 f).
  - Hit reactions 0-0.03 s (an intended snap).
  - M1 → M1 cross-fade 0.05-0.08 s.
  - Weighty 0.15-0.25 s.
  - One blog suggests 0.1-0.2 s generally and 0.1-0.15 s cross-fades [S51].
  - A fade of 0 is an intentional cut only.
- **First-frame pops:**
  1. Load tracks once, at spawn or equip, and cache them. Preload the asset. Never call `LoadAnimation` per click.
  2. Key **every joint the clip owns at t = 0**, close to the stance or idle pose it starts from.
  3. Chain with cross-fades, never `Stop()` then `Play()` at 0 fade.
  4. End one-shots on a pose near idle or stance, or call `Stop(fade)` a few frames early. `Stopped` fires at the end and `Ended` fires after the fade-out [S15].
- **Looping:**
  - Roblox does **not** blend the last key back to the first. Duplicate the first key at the end [S53].
  - `track.Looped` overrides the KeyframeSequence setting, and a change applies after the current loop finishes [S15].
  - Match velocities across the seam (sine-style keys). The idle loop length must be a multiple of every sub-cycle.
- **Hitstop implementation:**
  - `track:AdjustSpeed(0)`, then restore after N/60 s. Freeze both fighters' tracks.
  - AdjustSpeed(0) replication from the server is inconsistent [S52]. Have the server broadcast `hitstop(attacker, victim, frames)` and let **each client freeze its local view** of both characters.
  - Freezing exactly on the final keyframe can fail, so leave a frame after it [S52].
  - Use `Stop()` to end and `AdjustSpeed(0)` to hold a pose [S52].

### 7.6 R6 rig quirks

- **Rig facts:**
  - Torso 2×2×1, arms and legs 1×2×1, head 2×1×1. Total height about 5 studs.
  - Shoulder pivot about 1.5 studs from the fist. Hip pivot 2 studs from the sole.
  - Joints: `RootJoint` (HRP → Torso), `Neck`, `Right/Left Shoulder`, `Right/Left Hip`. Pose names = Part1 names (`Torso`, `Head`, `Right Arm`, ...).
- **Raw Motor6D axes are rotated.** This matters only when keying CFrames by hand instead of through the kit's parent-axes language.
  - Shoulders and hips have C0/C1 rotated ±90° about Y, so their local Z points sideways and is mirrored left vs right. In raw terms, `CFrame.Angles(0,0,+θ)` swings the **right** limbs forward but the **left** limbs backward.
  - RootJoint and Neck frames are rotated so that local **Z = up, Y = back, X = left**. Raw Torso "move up" is therefore the Z channel.
  - Motion is applied through `Motor6D.Transform` on top of C0/C1, which are unchanged [S16]. Animator overwrites Transform every frame between PreAnimation and PreSimulation [S54].
  - (Axis details derived from the standard R6 C0/C1 values; verify with one probe pose.)
- **In the Animation Editor the Torso *is* the root joint.** Select it to rotate the whole body [S55]. The "Adaptive Animations" beta blocked R6 Torso editing for one user, and turning it off fixed it [S56].
- **No knees:** use the Torso-drop formula `2(1 − cos φ)` whenever the legs split (sec 1.2). Crouches are leg-split stances.
- **No elbows:** punches read through torso twist, shoulder angle and a root lunge. A 1-2 f arm translation of 0.3-0.5 studs can fake extension. Blocks cross the straight arms in an X.
- **Legs follow the torso:** lean −θ means legs +θ, twist +y means legs −y (and the head −0.6..−0.8·y).
- **Tools:** `toolnone` raises the right arm. `RightGrip` is a Weld (sec 3.4).
- **Default Animate:**
  - The R6 walk is scaled by speed (believed to be `speed/14.5`; unverified).
  - Legacy copy values: jump 0.175 s, fall transition 0.2 s, all play calls fade 0.1 s [S24].

### 7.7 Frame-rate facts

- The Animation Editor defaults to **30 fps** [S53]. Key times are stored in seconds, so author on a 60 fps grid (`time = frame/60`) and Roblox interpolates at whatever the client renders.
- For a pop that must land on one exact frame, use `constant` (Constant) on the key before it.

---

## 8. Numbers cheat sheet (frames @60 fps; halve for the 30 fps editor)

| Item | A: battlegrounds snappy | B: weighty / realistic |
|---|---|---|
| Idle loop | 90-150 | 180-300 |
| Idle Torso bob (py, peak to peak, studs) | 0.06-0.12 | 0.03-0.06 |
| Idle limb / head lag | 4-8 / 6-10 | 10-20 / 10-20 |
| Walk cycle (frames per step) | 40-48 (20-24) | 56-64 (28-32); natural walk 60 (30) [S1] |
| Walk legs / arms x | ±25-35° / ±20-35° | ±20-28° / ±12-20° |
| Run cycle (per step) | 26-30 (13-15) | 32-40 (16-20) [S19] |
| Sprint cycle | 20-24 | 26-32 [S19] |
| Run legs / arms x | ±50-70° / ±50-80° (or trailing −60..−90) | ±40-55° / ±35-55° |
| Torso lean run / sprint | −12..−20° / −20..−35° | −6..−12° / −12..−20° (sprint 15-30° [S19]) |
| Run Torso bob (peak to peak) | 0.20-0.35 | 0.15-0.25 |
| R6 leg-split Torso drop | 2(1−cos φ): 25°→0.19, 35°→0.36, 45°→0.59 | same |
| Jump: takeoff to extreme / apex | 3-5 / ~15 (engine) | 6-10 / ~15 |
| Land: impact / recovery | 2-3 / 8-12 | 3-5 / 14-24 |
| Dash total: front / side / back | 18-28 / 14-20 / 18-24 | 26-36 / 20-28 / 24-32 |
| M1 1-3: antic / active / recovery | 3-5 / 2-3 / 10-16 | 10-16 (+2-4 hold) / 4-6 / 18-28 |
| M1 1-3 clip length | 20-30 | 38-55 |
| M1 contact-to-contact | 18-24 (0.30-0.40 s) | 30-40 |
| M1 4th: antic / active / recovery / clip | 8-12 / 3-4 / 20-30 / 45-60 | 18-28 (+4-8 hold) / 5-8 / 30-45 / 65-95 |
| 4-hit combo, first input → last contact | ~80 (1.35 s) + hitstops | ~120-150 (2.0-2.5 s) |
| Hitstop light / heavy / ultimate | 4-6 / 8-14 / 15-30 | 3-5 (or 2-4 f drag) / 6-10 / 12-20 |
| Reference hitstop (L/M/H) | Capcom example 8/12/16; KOF13 7/11; Smash cap 30 | |
| Impact flash | 1-3 (finishers only) | 0-1 |
| Victim shake during hitstop | ±0.08-0.15 studs, decaying | ±0.03-0.06 |
| Hit reaction: snap / settle | 1-3 / 8-14 | 2-4 / 14-24 |
| Min spacing for separately readable hits | ≥16 (or per-hit VFX at 6-10) | ≥16 |
| Sword light: wind / swing / FT / recovery / total | 6-10 / 3-5 / 6-10 / 10-16 / 30-40 | 12-20 / 6-10 / 10-16 / 16-24 / 48-70 |
| Sword heavy total | 50-70 | 90-140 (MoCap 90-160 [S12]) |
| Blade lag behind hand | 1-2 | 2-4 |
| Block enter / block-stun | 3-5 / 6-10 | 6-10 / 10-16 |
| Parry anim / window / deflect hold | ≤12-18 / 10-18 (Sekiro ≈12 [S30]) / 4-6 | ≤12-18 / 8-14 / 6-8 |
| Parried stagger | 30-45 | 45-70 |
| Ultimate: flash / charge / impact freeze / total | 15-30 / 30-90 / 15-30 / 120-300 | 10-20 / 20-60 / 12-20 / 90-180 |
| Anticipation share of the clip | 15-25% | 25-40% |
| Overshoot / settle | 8-15% (5-12°) over 2-3 f / 4-8 f | 3-6% (2-5°) over 3-5 f / 8-14 f |
| Max static hold | 6 | 10 |
| Moving-hold drift | 1-3° | 0.5-1.5° |
| Overlap: torso / arm / hand-weapon / head | +1 / +2 / +3 / +2-4 | +2 / +3-4 / +5-6 / +4-8 |
| Exaggeration vs real | ×1.3-1.6 | ×1.0-1.2 |
| Peak strike speed | 30-45°/f (1 smear frame allowed) | 12-25°/f |
| fadeTime: attack in / reaction / cross-fade | 0.03-0.06 s / 0-0.03 / 0.05-0.08 | 0.15-0.25 / 0.03-0.06 / 0.1-0.2 |
| Priority | M1 Action, skill Action2, ult Action3, victim stun Action4 | same |

---

## 9. What I could not verify (say so on camera, or measure first)

- TSB, JJS and Deepwoken frame timings: no public data. Their wikis returned 402/403. Record the game at 60 fps and step through it.
- The direction of CubicV2 In/Out at runtime: run the probe in 7.4.
- The current R6 Animate walk scaling (`speed/14.5`) and current jump/fall constants. Read the `Animate` LocalScript in a Play session.
- How unkeyed parent poses (Weight) affect joint ownership in exported KeyframeSequences.
- Mortal Kombat 1 frame data: no accessible source found. "MK weight" here comes from general fighting-game ranges, not MK numbers.
- Real SF6 hitstop per strength: the SuperCombo SF6 page says only "heavier attacks have longer hitstop" [S4]. The 8/12/16 figure is Capcom's illustrative example [S8].

---

## 10. Sources (type, date)

| # | Source | Type | Date |
|---|---|---|---|
| S1 | Monmouth University Animation Instruction Pages, "Movement: Walk Cycle" (adapts Williams' *Animator's Survival Kit* and SIGGRAPH HyperGraph timing) - https://animation.monmouth.edu/instruct/?p=351 | university teaching page | Jan 2021 |
| S2 | gameanim.com, "Basics: Fast vs Slow" (anticipation/apex/recoil; NPC vs PC anticipation) - https://www.gameanim.com/?p=115 | blog on Jonathan Cooper's Game Anim site (authorship not confirmed on the page) | c. Jun 2005 |
| S3 | Jonathan Cooper, *Game Anim: Video Game Animation Explained* (2nd ed.), chapter list: anticipation vs response, recovery timing, five fundamentals - https://www.routledge.com/Game-Anim-Video-Game-Animation-Explained/Cooper/p/book/9780367707651 | book (table of contents and secondary summaries only) | 2021 (2nd ed.) |
| S4 | SuperCombo wiki, "Street Fighter 6/Game Data" (hitstop is heavier for stronger attacks; frames are 1/60 s) - https://srk.shib.live/w/Street_Fighter_6/Game_Data | community wiki | accessed 2026-10-21 |
| S5 | SuperCombo wiki, "Street Fighter 6/Ryu" (5LP 4/3/7, 5LK 5/3/11, 13f cancel window) - https://wiki.supercombo.gg/w/Street_Fighter_6/Ryu | community wiki frame data | accessed 2026-10-21 |
| S6 | SuperCombo wiki, "KOF XIII Hitstun/Blockstun state" (light hitstop 7, heavy 11; hitstun 14/20) - https://srk.shib.live/w/The_King_of_Fighters_XIII/Character_States/Hitstun_Blockstun_state | community wiki | accessed 2026-10-21 |
| S7 | SmashWiki, "Hitlag" (15% damage → 15 f in Ultimate; cap 30 f) - https://www.ssbwiki.com/Hitlag | community wiki | accessed 2026-10-21 |
| S8 | Capcom CFN "SF Seminar: Hit Stop/Block Stop" (example L/M/H 8/12/16; multi-hit shortened; projectiles give the attacker none) - https://game.capcom.com/cfn/sfv/column/131545 | official developer column | SFV era, exact date unknown. Site returned 503; read via search excerpt 2026-10-21 |
| S9 | Source Gaming translation of Sakurai's Famitsu column Vol. 490, "Thinking About Hitstop" - https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/ | translated designer column (fan translation) | 2015-11-11 |
| S11 | Jiesang Song, "Improving the Combat 'Impact' of Action Games" (Ninja Gaiden hit frames, readability spacing, freeze, flash) - https://www.gamedeveloper.com/audio/improving-the-combat-impact-of-action-games | trade article (Game Developer) | 2005-04-28 |
| S12 | MoCap Online, "Sword & Melee Weapon Animation: Impactful Combat Guide" - https://mocaponline.com/blogs/mocap-news/sword-melee-animation-guide | vendor guide | 2026-03-17 |
| S13 | 80.lv, "Tips on Making Fluid and Powerful Animations" (Mariel Cartwright, GDC 2014 *Skullgirls* talk) - https://80.lv/articles/tips-on-making-fluid-and-powerful-animations ; talk: https://gdcvault.com/play/1020575/ | article summarizing a GDC talk | 2020-03-28 (talk 2014) |
| S14 | Roblox Creator Docs, AnimationPriority enum - https://create.roblox.com/docs/reference/engine/enums/AnimationPriority | official docs | accessed 2026-10-21 |
| S15 | Roblox Creator Docs, AnimationTrack (Play/Stop defaults, Looped, Length, Stopped/Ended) - https://create.roblox.com/docs/reference/engine/classes/AnimationTrack | official docs | accessed 2026-10-21 |
| S16 | Roblox Creator Docs: Pose (easing to the next pose; Transform, not C0/C1) and PoseEasingStyle (Cubic deprecated: reversed editor vs runtime) - https://create.roblox.com/docs/reference/engine/classes/Pose , creator-docs GitHub `enums/PoseEasingStyle.yaml` | official docs | accessed 2026-10-21 |
| S16b | Roblox Creator Docs, PoseEasingDirection ("backwards ... from TweenService") - https://create.roblox.com/docs/reference/engine/enums/PoseEasingDirection | official docs | accessed 2026-10-21 |
| S16c | Roblox Creator Docs, EasingDirection (TweenService In = forward) - https://create.roblox.com/docs/reference/engine/enums/EasingDirection | official docs | accessed 2026-10-21 |
| S17 | Roblox Creator Docs, "Animation events" - https://create.roblox.com/docs/animation/events | official docs | updated 2026-10-20 |
| S18 | PlayStation Blog, "Game developers explain what makes God of War (2018)'s combat tick" (hit stop holds both in the first hit frame) - https://blog.playstation.com/?p=370399 | developer interview article | 2022-10-04 |
| S19 | MoCap Online, "Run Cycle Animation: The Developer's Guide" (run 16-20 f @30; sprint 12-16 f @30; 15-30° lean) - https://mocaponline.com/blogs/mocap-news/run-cycle-animation | vendor guide | 2026-04-09 |
| S20 | Jason Zirpolo, "Animating the Run Cycle" (counter-rotation, head bob lag, loop export) - https://www.gamedeveloper.com/art/animating-the-run-cycle | trade article | 1999-06-18 |
| S21 | Ulster University animation blog, run cycles use fewer frames than walks (12-16 vs 24) - https://blogs.ulster.ac.uk/scottmoore/category/animation-strategies/page/2 | student/teaching blog | 2024-10-21 |
| S24 | Legacy R6 `Animate` LocalScript copy (jumpAnimDuration 0.175, fallTransitionTime 0.2, sine limb swing) - https://glot.io/snippets/gsyg6dx90m | code copy (unofficial; ~2013-14 asset IDs) | undated |
| S25 | DevForum threads on the Animate script (Core priority; R15 walk/run blend about 0.2 s) - https://devforum.roblox.com/t/run-animation-overides-jump-and-fall-animation/1471532 , https://devforum.roblox.com/t/r15-strafing-runwalk-threshold-change/3020381 | forum | 2021; ≈2024 |
| S26 | Headstackk, "How to animate Tool Parts (Guns, Knifes etc.)" - https://devforum.roblox.com/t/topic/359484 | community tutorial | 2019-09-30 (upd. 2022-12-13) |
| S27 | games.gg, "The Strongest Battlegrounds Combat Guide" (M1 3/3/4/5%, 4th launches, uppercut/downslam, ~0.2 s post-M1 block lockout) - https://games.gg/roblox/guides/the-strongest-battlegrounds-combat-guide/ | third-party game guide | undated (accessed 2026-10-21) |
| S28 | Infil, "Killer Instinct: The Basics" (close heavies never faster than ~8-9 f) - https://ki.infil.net/basics2.html | community guide | c. 2016+ |
| S29 | Deepwoken fandom wiki, Great Maul (0.85× swing speed) - https://deepwoken.fandom.com/wiki/Great_Maul | community wiki | accessed 2026-10-21 |
| S30 | Nexus Mods (Stellar Blade) article citing Sekiro deflect window 0.2 s / 12 f from DS Anim Studio - https://www.nexusmods.com/stellarblade/articles/199 | modder article (via search excerpt; page 403) | undated |
| S31 | Univ. of Missouri PM&R "Normal Gait" slides, plus PMC normative gait tables (hip ~30° flex at IC; knee ~60-65° in swing) - https://medicine.missouri.edu/sites/default/files/pm-r/Normal_Gait.pdf | clinical teaching slides | 2020 version |
| S32 | Kang et al., "The elbow is the load-bearing joint during arm swing," *Clinics in Shoulder and Elbow* (elbow ROM 29.7° walking) - https://www.cisejournal.org/journal/view.php?number=923 | peer-reviewed study | 2023 |
| S33 | Normal resting adult respiratory rate 12-20/min (nursing reference) - https://nprep.in/question-answer/what-is-the-normal-respiration-rate-in-an-adult-nxt20fv37eS_01tM_VNFR | clinical convention | accessed 2026-10-21 |
| S34 | MoCap Online platformer guide (2-3 f micro-anticipation) and game-feel skill guide (hitstop 2-5 f) - https://mocaponline.com/blogs/mocap-news/platformer-animation-guide | vendor guide / secondary | 2026 |
| S35 | DevForum, root motion and snap-back threads - https://devforum.roblox.com/t/how-does-roblox-reconcile-animations-with-physics/4094572 , https://devforum.roblox.com/t/2564865 | forum | ≈2025; ≈2023 |
| S36 | DevForum marker threads (server first-play late; client-side; ownership) - https://devforum.roblox.com/t/help-with-animation-markers/3165325 , https://devforum.roblox.com/t/getmarkerreachedsignal-not-firing-for-an-npc-but-works-for-regular-players/3760880 | forum | ≈2024; ≈2025 |
| S37 | DevForum "Dash System Issues" (32 studs/s × 0.25 s ≈ 8 studs) - https://devforum.roblox.com/t/dash-system-issues/2617066 | forum | ≈2023 |
| S38 | DevForum "Is mine script for dash is normal?" (front dash 50 → 0 ramp) - https://devforum.roblox.com/t/is-mine-script-for-dash-is-normal/2868825 | forum | ≈2024 |
| S39 | DevForum "Inaccurate Dash Angles" (LinearVelocity 45; flatten look Y) - https://devforum.roblox.com/t/inaccurate-dash-angles/3869031 | forum | ≈2025 |
| S40 | DevForum combo-reset threads (1-2 s reset; final hit stun 1 s at WalkSpeed 3) - https://devforum.roblox.com/t/combatsystem-hit-counter-resets-in-the-middle-of-the-combo/3138840 | forum | ≈2024 |
| S41 | 3DJuegos on impact frames in ZZZ (flashes lasting ~1 frame) - https://www.3djuegos.com/juegos/zenless-zone-zero/noticias/ | games press (via search excerpt) | ≈2024-25 |
| S42 | "Impact Frames" Minecraft mod (default 2 frames, 1-5) - https://www.modpackindex.com/mod/112214/impact-frames | mod page (via search excerpt) | undated |
| S43 | melvinpetersen, "Creating a Battlegrounds-like Hitbox" - https://devforum.roblox.com/t/creating-a-battlegrounds-like-hitbox/3623640 | community tutorial | 2025-04-23 |
| S44 | DevForum "Tips on Animating" (sword wind-up, overshoot, pull-back) - https://devforum.roblox.com/t/tips-on-animating/3091970 | forum | 2024-07-28/29 |
| S45 | DevForum "Combat Animation Lacks Power" (Back/Elastic, Cartwright tips, recovery shows force) and "Better animation tips..." (Constant → Linear) - https://devforum.roblox.com/t/combat-animation-lacks-power/1875328 , https://devforum.roblox.com/t/better-animation-tips-if-you-dont-have-any-good-animation-software/3920410 | forum | 2022-07-12; ≈2025 |
| S46 | DevForum "Parry System Doesnt Work" (parry only during the attack animation) - https://devforum.roblox.com/t/parry-system-doesnt-work/2995819 | forum | ≈2024 |
| S47 | DevForum tool-animation threads (convert RightGrip to Motor6D; toolnone raises the arm) - https://devforum.roblox.com/t/how-to-animate-tool/2321931 , https://devforum.roblox.com/t/help-with-animation/1217205 | forum | ≈2023; 2021 |
| S48 | MUGEN SuperPause default 30 ticks plus darken (mugenguild forum) - https://mugenguild.com/forum/ | engine documentation via forum (search excerpt) | undated |
| S49 | SuperCombo "KOF XIII Super Freeze"; EventHubs on MvC:I cinematic supers freezing time - https://srk.shib.live/w/The_King_of_Fighters_XIII/Game_Elements/Super_Freeze | community wiki / press | accessed 2026-10-21 / 2017 |
| S50 | Roblox Creator Docs, "Customize the camera" (FieldOfView default 70) - https://create.roblox.com/docs/workspace/camera | official docs | accessed 2026-10-21 |
| S51 | KitsBlox, "Why Your Roblox Animations Look Choppy (And How to Fix It)" - https://kitsblox.com/blog/fix-choppy-roblox-animations | third-party blog | 2026-03-05 |
| S52 | DevForum AdjustSpeed(0) threads (replication, final-keyframe freeze, Stop vs speed 0) - https://devforum.roblox.com/t/adjustspeed-not-correctly-replicating-to-other-clients/2907655 , https://devforum.roblox.com/t/adjustspeed-not-working/2860896 , https://devforum.roblox.com/t/adjustspeed-working-inconsistently/2643111 | forum | ≈2023-24 |
| S53 | Roblox Creator Docs, Animation Editor (30 fps default; easing list; loop doesn't blend last→first) - https://create.roblox.com/docs/animation/editor | official docs | updated 2026-10-20 |
| S54 | Roblox Creator Docs, Motor6D (Transform applied after PreSimulation; Animator overwrites it) - https://create.roblox.com/docs/reference/engine/classes/Motor6D | official docs | accessed 2026-10-21 |
| S55 | DevForum "Full body rotation" (Torso is the Root Joint in the editor) - https://devforum.roblox.com/t/full-body-rotation/409414 | forum | 2019 |
| S56 | DevForum "I Can't Animate R6 Torso" (Adaptive Animations beta) - https://devforum.roblox.com/t/i-cant-animate-r6-torso/4220245 | forum | ≈2026 |

(The S10, S22 and S23 numbers are unused.)
