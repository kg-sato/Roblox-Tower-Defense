# 05 - Combat animation references: the moves famous combat games are known for, and how to rebuild them in R6/R15

Research date: **2026-10-21**. All frame counts are at **60 fps**. The fighting games below (SF6, GGST, Tekken 8, DBFZ) also run at 60 fps, so their frame data maps 1:1 onto our timelines.

**Scope (set by the creator, 2026-10-21):** this file covers games with big, well-regarded combat systems only. Avatar animation packs, emotes, kid-oriented games and meme movement were dropped on purpose. Roblox: The Strongest Battlegrounds, Jujutsu Shenanigans, Deepwoken, Type Soul, Mighty Omega, Rogue Lineage, Combat Warriors. Elsewhere: Street Fighter 6, Guilty Gear Strive/Xrd, Tekken 8, Dragon Ball FighterZ, Sekiro, Elden Ring/Souls, God of War, Ghost of Tsushima, Devil May Cry 5, Sifu, Hi-Fi Rush, Absolver.

**No stolen or leaked animations.** Nothing here links to or reproduces animation files or asset IDs from any game. We describe what a move does and why it reads well, and Claude builds an original animation with a similar feel.

## Evidence tags

| Tag | Meaning |
|---|---|
| **[R#] / [N#]** | Sourced. Roblox sources are R#, non-Roblox sources are N#. Both lists are in section 13, with date and type. |
| **(derived)** | My arithmetic or geometry from sourced numbers or rig facts. |
| **(rec)** | My recipe or recommendation. It is a starting point to tune by eye, not a measurement of the original game. |
| **(unverified)** | From memory of gameplay footage, or from a single weak source. Check it against a 60 fps recording before you claim it on camera. |

**Honesty note.** No public source gives frame-by-frame animation data for any Roblox game. The Roblox wikis describe what moves *do* (wind-up, lunge, launch, stun), not how they're keyed. Every pose number in the recipes below is therefore **(rec)**: designed in our pose language to produce the described behaviour and feel. The fighting-game numbers are real frame data from Dustloop, SuperCombo and TekkenDocs.

---

## 0. TL;DR - why famous combat animation reads well (cross-game)

1. **Hit-stop scales with strength.** SF6 Ryu: jab **9 f** of hitstop, medium punch **11 f**, heavy punch **13 f**, LP Shoryuken **15 f**, HP Shoryuken **20 f**, Drive Impact **25 f** [N1]. GGST: **11-15 f** by attack level. Counter hits freeze for **21 f** or **31 f**, followed by **25 f or 35 f of slowdown** [N3]. Itsuno (DMC) on Street Fighter II: when something hits hard, *stress impact with hit-stop by "displaying certain parts of the animation for a little longer"* [N12].
2. **Wind-up length tells you how dangerous a move is.** SF6 jab startup is 4 f, against 26 f for Drive Impact [N1]. Tekken 8 jab is i10, against i20 for Rage Art [N8]. Ghost of Tsushima gives enemies "pretty long initial wind-ups" so a group attacks one at a time [N18]. Small move → short wind-up; big move → long, held telegraph.
3. **The big hits are "limited animation".** Arc System Works (Guilty Gear Xrd, DBFZ) stopped interpolating between keys entirely. "Every frame now is a key frame", described as stop motion, because interpolation "makes it look more 3D" [N5]. For us: key the strike and impact with the `constant` ease on 2s or 3s. That gives the anime battlegrounds look (rec).
4. **Recovery is part of the read.** A whiffed big move is punishable: SF6 HP Shoryuken recovers for 34 f plus 12 f of landing [N1]. A whiffed Deepwoken uppercut "completely immobilizes you" [R9]. In Rogue Lineage, a mistimed block against a heavy lets the attacker "punish" for a full M1 string [R13]. Long, readable recovery on big moves is what makes them feel heavy and fair.
5. **Cancel windows are a feature, not a bug.** God of War's designer splits cancels into *partial* (allowed only before the first hit frame or after the last) and *complete* (allowed any time) [N13]. In the Roblox games:
   - Deepwoken lets you feint by pressing M2 "during the moment your character pulls their weapon/arm back" [R9].
   - JJS "Combat Instincts" cancels an M1 or skill wind-up "with no endlag" [R6].
   - TSB players build whole techs out of dash cancels [R3].

   **The pull-back pose must read on its own**, because that is where every feint lives.
6. **Two-beat impacts.** JJS Divergent Fist lands a punch, then a *delayed* cursed-energy burst launches the target [R6]. TSB Death Counter and DBFZ Vanish teleport behind the target, hold, then hit [R1][N7]. Players love the gap between the two beats.
7. **Deflects are tiny, fast, and pay off on the attacker.** Sekiro's deflect window is **12 f**. It shrinks to 4 f, or even 0 f, if you spam, and resets after 30 f [N9]. Combat Warriors' parry window is about 0.5 s; a successful parry stuns the attacker for 3 s [R14]. The satisfying part is the **attacker's stagger animation**, not the parry pose.
8. **Four-hit strings with a launcher.** TSB M1 ×4, where the 4th knocks back [R1]. Mighty Omega ×4, where the 4th knocks back, followed by a 1.5 s cooldown [R12]. Deepwoken does 3 swings, then a "Flourish" kick sends the target away [R9]. JJS Vessel throws 3 punches and ends with a kick [R7]. The ender is always a **different body part or direction** from hits 1-3.
9. **Rhythm.** Hi-Fi Rush interpolates an action pressed slightly early or late so that it lands on the beat. Moves with a lead-in are retimed so their *finishing point* hits the beat. Jumps, dashes and parries are exempt [N21]. Mighty Omega has a "Rhythm" meter that speeds attacks up [R12]. Keep contact-to-contact spacing even inside a string (see 03 §2).
10. **R6 needs exaggeration in rotation, because it can't deform.** Guilty Gear deforms and scales meshes every key to add "imperfection" [N5]. R6 can't scale parts, so push torso twist (±30-60°), lean, and root offsets instead (rec).

---

## 1. How to read the recipes

Pose language matches `kit/animkit.py` and `anims/_lib.py`:

- Each joint is `(x, y, z)` in degrees, in the **parent part's** axes.
  - `+x`: an arm or leg swings forward, the head looks up, the torso leans back.
  - `+y`: turns to the character's left.
  - `+z`: the right limb goes out to the side; the left limb crosses the body.
- Torso `(x, y, z | px, py, pz)`: `py < 0` crouches, `pz < 0` lunges forward.

**Notation used below (rec).**

- Joints: `T` Torso, `H` Head, `RA` / `LA` Right / Left Arm, `RL` / `LL` Right / Left Leg.
- Values are **absolute joint values**, not deltas.
- The base pose `STANCE` is `_lib.FIGHT_R6`: `T(-6, -18, 0)` (bladed, left foot forward), `RA(62, 0, -14)`, `LA(78, 0, 10)`.
- **Legs are left out when they should simply stay planted.** Get there with `_lib.lean` / `_lib.twist` / `ak.plant` + `a.lock_feet`. Legs are listed only when they move on purpose.
- `→ ease` is the ease **from** that key to the next, following the kit's rule.

**Three derived R6 rules used throughout:**

- **Aim rule (derived).** On a horizontal arm, `z` swings the fist sideways: `+z` aims to the character's right. The arm rides the torso turn, so to keep a raised fist on the target's centreline set **arm `z` ≈ Torso `y`**, for both arms.

  The geometry: with `CFrame.Angles(x, y, z)`, Z is applied first, then X. A hanging arm rotated by `z = θ` and then `x = 90` points to `(sin θ, 0, -cos θ)`: forward, with a sideways component toward +X. The kit's `STANCE` rear arm already follows this rule: `z -14` with the torso at `y -18`.

  Check this on a top view before trusting it on camera.
- **Arm angle under a lean (kit rule).** `arm x = (wanted world angle from straight down) - (Torso x)`. Example: an overhead hammer that should end 45° below horizontal-forward, on a torso leaning `-38`, needs `RA x = 45 + 38 = 83`.
- **Torso `z` (derived).** `+z` tilts the torso toward the character's **left** (left shoulder drops). It follows from the same right-handed rotation that sends `+z` arms outward.

**Spins (derived).** Keyframes store CFrames, and Roblox interpolates rotations along the shortest path. A turn of more than 180° between two keys therefore spins the wrong way. Key every **≤ 90-120°** of spin.

**R15 translation (rec).**

- **Elbows.** Chamber at the wind-up: `UpperArm x` about `-20..-40`, `z` about `+30`; `LowerArm x` about `+90..+110`, so the fist sits by the ear or ribs. At contact, extend to `LowerArm x 0..+10`. The `Hand` snaps 1-2 f after the forearm (wrist lag).
- **Knees.** For kicks, chamber with `UpperLeg x +70..+90` and `LowerLeg x -80..-100`, then extend to `LowerLeg -5..0` on the strike.
- **Spine.** Split twist and lean between `LowerTorso` (about 40%) and `UpperTorso` (about 60%) so the hips lead the shoulders by 1-2 f.
- **No backward bends.** Never let an `ak.blend` overshoot bend an elbow or knee backwards (see `anims/_r15.py`).

**Game-side pieces that every recipe assumes (rec, from 03).**

- Hit-stop is done in script with `AdjustSpeed(0)` on *both* fighters, triggered by the `Hit` marker.
- Travel (dash, lunge, knockback, teleport) is applied by the script to the HumanoidRootPart, never by the animation.
- VFX and impact frames fire on markers.

---

## 2. The Strongest Battlegrounds (TSB)

**What it is.** Roblox's most-played fighting game [R4]. It's a One-Punch-Man-themed "battlegrounds" game. Characters share a universal toolkit:

- **M1 ×4.** The 4th hit knocks back [R1].
- **Mini uppercut.** Comes from holding jump into the 4th M1. Sources disagree on the exact input [R3].
- **Downslam.** The 4th M1 in the air [R3].
- **Front dash.** The front dash itself can hit; techs loop it under a falling target [R3].
- **Side dash.** Used to dodge linear moves (unverified).
- **Ragdoll cancel** (unverified). A French guide claims it is a dash on a roughly 30 s cooldown; unverified.
- **Shove.** A short push that can reflect projectiles [R1].
- **Awakening (ultimate).** Each awakening opens with a cinematic intro.

Earlier third-party data put the M1 damage ramp at 3/3/4/5%, with about 0.2 s of block lockout after M1s (03 [S27]).

**Why players love it (combined from the wiki and tech pages).**

- **The combo glue is movement.** Players name techs after the frame a dash lands, and hits can be cancelled into the next action:
  - "Twisted Dash": a forward dash the frame the 4th M1 lands, which cuts the knockback.
  - "Uppercut Dash": loop a front dash under a mini-uppercut target.
  - "True Downslam": downslam off the 3rd M1's stun.
  - "Upside Down Ragdoll": downslam the instant someone rises, so their torso over-rotates [R3].
- **Every awakening intro tells a story in one pose.** Hero Hunter's awakening has the user "dribble blood from their mouth… wipe the blood off… violently smash the ground" [R2].
- **The Strongest Hero's** (Saitama's) **ultimates are anime cutscenes.** Serious Punch, Death Counter, Table Flip and Omni-Directional Punch each have dedicated impact frames [R1].

### 2.1 Signature moves (wiki descriptions [R1][R2])

| Character (anime basis) | Move | What the body does (wiki) | Animation read (rec) |
|---|---|---|---|
| The Strongest Hero (Saitama) | M1 | "Basic punches forward 4 times, the 4th one knocking players back" | Plain boxing jabs/straights; the 4th is a full-body straight |
| | Normal Punch | "Winds their arm back before punching… direct hits ragdoll and send flying… cannot be blocked" | One huge cocked straight: the wind-up IS the telegraph |
| | Consecutive Punches | "A consecutive barrage of punches… can hit ragdolled players" | Alternating-arm blur loop (recipe 2) |
| | Shove | "A quick shove… can reflect most incoming projectiles if timed" | Two-palm push, 2-3 f strike |
| | Uppercut | "Winds their fist back, before punching upwards, jumping and launching" | Dip → rising uppercut + hop (recipe 3a / 8) |
| | Serious Punch (ult) | "Readies up their fist, pushing nearby opponents away with wind… punches… a large area of rocks caving in" | Long charge, 2 f release, very long hold (recipe 4) |
| | Death Counter (ult) | Invisible 10 s counter; on trigger "teleport behind… with your fist raised", 死 screen, close-up fist, one punch | Teleport-behind + held raised fist (recipe 5) |
| Hero Hunter (Garou) | M1 | "Water jabs 2 times… a knee strike, and then a spin kick" | Hit 3 = knee (R6: leg forward + hop), hit 4 = spin kick (recipe 9) |
| | Flowing Water | "Braces before lunging forward… strike their chest 10 times, pushing them along… before launching" | Brace pose → palm-strike barrage while travelling |
| | Hunter's Grasp | "Stomps the ground, causing a small uplift of rocks… throw the target" | Stomp (recipe 10) → grab-throw |
| | Lethal Whirlwind Stream | "Grabs their opponent by the neck… dragging them across the floor before throwing" | Grab-drag, a running-crouch pose with an arm extended forward |
| Destructive Cyborg (Genos) | M1 | "Punches 3 times before ending with a small blast of flames" | Hit 4 = two-palm blast (Hadoken shape) |
| | Machine Gun Blows | "A barrage of punches with a punch and a kick at the end, ragdolling targets upwards" | Barrage → rising kick ender |
| | Blitz Shot | "Holds up their glowing hand, charging up a projectile" | Charged held pose, arm raised and aimed |
| Deadly Ninja (Sonic) | M1 | "Slashes twice and then kicks twice. The last kick ragdolls" | Mixed weapon + kick string; the ender changes body part |
| | Whirlwind Kick | "Teleports forward and stuns… before spinning around and kicking the target downwards" | Teleport → spin axe kick |
| | Flash Strike | "Moves at a very high speed leaving a trail of slashes" | Low running iai pose + trail VFX |
| Brutal Demon (Metal Bat) | M1 | "Swings their bat thrice before smashing the ground" | Prop swings; the ender is an overhead ground smash |
| | Homerun | "Swings their bat upwards, then spins around and delivers another swing which launches" | Two-stage: upswing → 360° spin swing (keys every ≤120°) |
| | Grand Slam | "Flies into the air in an arc and slams the ground" | Leap pose → downslam |
| Blade Master (Atomic Samurai) | Quick Slice | "Dashes backwards and quickly performs a barrage of slashes" | Backstep → sword blur loop |
| | Atmos Cleave | "Stomps the ground, tripping anyone… swinging and bringing them in the air… final hit sends the opponent back down" | Stomp → rising slash → overhead slash down |
| Wild Psychic (Tatsumaki) | M1 | "Three slashes with psychic energy then pushes opponent forward using telekinesis" | Hand-gesture "M1s"; the ender is an open-palm push |
| Sorcerer (Gojo) | M1 with Infinity | Punches make air shockwaves; "the 4th m1 will be a black flash" | Same M1 string, but the ender gets impact frames |

### 2.2 TSB-style recipes (R6, snappy preset; all (rec))

**Existing M1 chain.** The `R6_M1_1..4` files already cover the 4-hit string. The universal M1 enders are recipes 3a and 3b in section 12.

**R6_Shove**: 34 f, Action.

| Frame | Pose | Ease out |
|---|---|---|
| f0 | STANCE | `quad_out` |
| f5 | GATHER: `T(-2, -8, 0 \| py -0.12)`, both palms at chest `RA(55, 0, -20)` `LA(55, 0, 20)`, `H(4, 6, 0)` | `cubic_in` |
| f7 | PUSH (2 f): `T(-16, 0, 0 \| pz -0.45)`, `RA(92, 0, -6)` `LA(92, 0, 6)` (both arms straight, hands together), rear leg extends `RL(-30, 0, 8)`. Marker `Hit` | `linear` |
| f9 | Overshoot: arms 98 | `cubic_out` |

Then hold 4 f and settle by f34. It's quick, so it reads as "reflect-ready".

**R6_NormalPunch** (TSB) / Drive-Impact-style heavy: 70 f, Action2.

| Frame | Pose | Ease out |
|---|---|---|
| f0 | STANCE | |
| f16 | COCK: `T(+6, -50, 0 \| py -0.25, pz +0.15)`, `RA(-40, 0, 30)` (fist thrown back and out, clear of the silhouette), `LA(90, 0, -35)` (lead hand aims at target), `H(-2, 34, 0)` | `cubic_in` |
| f16-f24 | Held telegraph with drift: `RA -43` at f20 | `sine_inout` |
| f26 | STRIKE: `T(-20, +32, 0 \| py -0.2, pz -0.8)`, `RA(92, 0, 28)` (aim rule: z ≈ T y), `LA(-15, 0, -22)` (lead hand snaps back to the hip), `RL(-42, 0, 10)`, `H(14, -20, 0)`. Marker `Hit` | `expo_in` from f24, then `linear` |
| f28 | Overshoot: `RA 100` | |

Hold until f40, then `cubic_out` back to STANCE by f70. The game sets hit-stop to 12-15 f.

- **Timing anchor:** SF6 Drive Impact has 26 f startup, 2 f active, 35 f recovery and 25 f hitstop [N1]. GGST Sol's Dust has 20 f startup [N4].

---

## 3. Jujutsu Shenanigans (JJS)

**What it is.** A Jujutsu Kaisen battlegrounds game: "the ability to M1, dash, block, and more" [R6]. The default character, Vessel (Yuji/Sukuna), has an M1 string of 3 punches finished by a kick [R7]. The game is famous for **timing-based** hits: Black Flash and the counter-stances.

| Move | Wiki description [R6] | Why it feels good (rec) |
|---|---|---|
| Divergent Fist | "Winds their arm back and lands a decent blow with their fist **before delayed cursed energy launches the opponent back**." The punch is blockable; the cursed-energy impact isn't. 18 s cooldown | Two beats: contact, then a delayed burst. The gap creates suspense |
| Black Flash (variant) | "If pressed again when the user's fist is pulled back **as their body flashes white**, their initial punch will unleash a Black Flash." Damage doubles if it interrupts an action | A skill check on the **held cocked pose**. A guide says to press "once the character's arm is fully cocked back" and to practise about half a second after starting [R8] (unverified) |
| Black Flash Chain | Landing on an enemy's back stuns instead of ragdolling. Chains up to 4 times, the last being "a heavy Black Flash"; the side dash refreshes after each | Escalating rhythm: the 4th gets the biggest impact frames |
| Cursed Strikes | "Swiftly slides forward with their hands poised to attack as their eyes glow red… a flurry of punches, finished with a right calf kick" | Low slide entry → barrage → low kick ender |
| Crushing Blow | "Grabbed by the torso and slammed into the ground twice, then launched" | Grab-slam rhythm: two heavy beats and a release |
| Manji Kick (counter) | "Raises their arm and one of their legs, ready to evade… performs a Taido… upward roundhouse kick" | The counter stance is a readable pose (recipe 12) |
| Combat Instincts | Cancels an M1 or skill wind-up "with no endlag", leaving the move off cooldown. A feint | Wind-up poses must look committal, or the feint has no bite |
| Cleave | "Winds their arm back to grab forward. After a short pause… a multitude of slashes" | Grab → pause → payoff |
| Infinity (Gojo block) | "They simply pose and hover on the ground when blocking" | The block is an attitude pose, not a guard |
| Lapse Blue | Pulls the target, who hangs "suspended in front of the user", then an unblockable kick | Suspended target + chambered kick |
| Hollow Purple | Charges for about 3 s, then a large forward mass | Long charge with a two-hand gesture |

**Community tech.** "Uppercut surfing": hold jump during the M1 string and delay the 4th hit to jump on the opponent's head [R6]. Front dashes "can be easily telegraphed" [R6], so the dash needs a short but visible lean-in.

### 3.1 R6_DivergentFist + R6_BlackFlash (rec; Top-12 #1)

Snappy preset, 84 f, Action2. Markers: `Flash`, `Hit`, `Burst`.

| Frame | Pose | Ease out |
|---|---|---|
| f0 | STANCE | `quad_out` |
| f10 | DRAW: `T(-2, -32, 0 \| py -0.12)`, `RA(15, 0, 10)`, `LA(84, 0, -6)`, `H(2, 20, 0)` | `cubic_out` (slow into the cock = readable) |
| f20 | COCK (the Black Flash cue): `T(+6, -48, 0 \| py -0.22, pz +0.15)`, `RA(-42, 0, 30)`, `LA(96, 0, -28)` (aims), `H(-2, 32, 0)`, rear leg `RL(-24, 0, 10)` | |
| f20-f30 | Moving hold: `RA(-45, 0, 32)` at f25, `(-42, 0, 30)` at f30. Marker `Flash` at f20; the game turns the body white for f20-f30. **That 10 f (167 ms) is the Black Flash input window** | `sine_inout` |
| f32 | STRIKE (2 f): `T(-18, +34, 0 \| py -0.18, pz -0.7)`, `RA(92, 0, 30)`, `LA(-15, 0, -22)`, `RL(-40, 0, 10)`, `LL(34, 0, -8)`, `H(14, -20, 0)`. Marker `Hit` | `expo_in` from f30, then `linear` |
| f34 | Overshoot: `RA(100, 0, 31)`, `T y +38` | |
| f34-f44 | Contact hold (drift). Game hit-stop: 8 f normal | |
| f46 | BURST (the delayed second beat, about 14 f after `Hit`): the torso jolts back `T(-12, +30)` and the arm recoils `RA(96, 0, 28)` over 2 f, then returns. Marker `Burst` → cursed-energy VFX + knockback | `linear` |
| f48-f84 | Recover to STANCE | `cubic_out` |

**Black Flash variant:**

- **Strike:** keep the same keys, but play f30→f36 with the **`constant` ease on 2s** as a stepped smear. f32 is a stretched pose, `RA x 108`, `T x -26`; f34 is the overshoot pose.
- **Game side:** fire 2-3 f of black/red inverted impact frames on `Hit`. Set hit-stop to **20-24 f**; GGST's mid counter hit freezes for 21 f [N3].
- **Burst:** skip the delay. The black flash *is* the impact.

**R15:** chamber the elbow at the cock (`RightLowerArm x 105`, fist at the ear). It extends only on f32, with the hand lagging 1 f behind.

---

## 4. Deepwoken

**What it is.** A hardcore, Souls-like Roblox RPG with permadeath. Its melee is the reference for "weighty" combat on Roblox; see 03 for the weighty preset numbers (Great Maul swings at 0.85×, 03 [S29]).

**Core mechanics [R9]:**

| Mechanic | What it does |
|---|---|
| String + Flourish | 3 consecutive swings, then a **Flourish**: "your character will kick your adversary away". It has endlag and stops infinite combos |
| Feint | M2 "during the moment your character pulls their weapon/arm back". Holding M2 feints as soon as possible |
| Running Attack | M1 while sprinting "strafe[s] forward" with "increased end-lag and slightly increased windup" |
| Critical | R or M3: weapon-specific heavy attacks, mainly for posture damage |
| Uppercut | Cheap to land; "missing an Uppercut will completely immobilize you" |
| Block and posture | Blocked hits deal posture damage scaled by weapon weight. Over the cap, a guard break **stuns for 1.05 s (63 f)** |
| Shaky block | A block-stun "indicated by your arms shaking and you covering your head" |
| Roll | Has i-frames. **Roll-cancel** with M2 mid-roll grants another roll |
| Movement | Slide from a sprint; a slide-jump launches at about 37°; there is an air dash [R9 Movement] |
| Taunt | T: the character spits |

**Why its swings feel weighty (rec, from the mechanics above plus 03).**

- **The pull-back is long and clear**, because the feint lives there. The swing itself is short.
- **Hit-stop is small (3-5 f)**, but recovery is long.
- **Heavy weapons are slower in the wind-up, not the swing** (0.85× swing speed, 03 [S29]).
- **Movement into attacks costs endlag.** A running attack stops you in place.
- **Players read "flourish = kick".** The string's last beat changes body part.

### 4.1 Recipes (weighty preset; all (rec))

- **Swings.** Reuse `R6_SwordSlash1/2` and `R6_SwordHeavy_Weighty`.

**R6_FlourishKick** (Top-12 #11), weighty, 60 f.

| Frame | Pose | Ease out |
|---|---|---|
| f0 | Weighty stance | |
| f12 | CHAMBER: `T(+10, -10, 0 \| py -0.05)`, `RL(70, 0, 8)` (R6 "knee up" = straight leg raised), sword arm back `RA(40, 0, 30)`, `LA(70, 0, -20)`, `H(-6, 6, 0)` | `cubic_in` |
| f12-f16 | Held telegraph | |
| f19 | PUSH-KICK (3 f): `T(+22, -4, 0 \| pz -0.3)`, `RL(92, 0, 4)` (horizontal teep), `LL(-10, 0, -6)`, `H(-14, 2, 0)`. Marker `Hit` | `expo_in` |
| f19-f24 | Hold. Game hit-stop 4-6 f, then knockback | |
| f24-f40 | Retract to `RL(55)` | `cubic_out` |
| f40-f60 | Settle | |

**R6_SwordFeint**, weighty, 32 f.

- **Shared wind-up:** copy the swing's keys exactly up to the pull-back peak (f12-f16), so the opponent can't tell them apart.
- **Return:** instead of striking, ease `cubic_out` back to stance by f30. Add a tiny head dip, `H x -6` at f20.
- **No marker.**

**R6_ShakyBlock**: 63 f, the guard-break stun.

- **Pose:** block, hunched (`T x -12`, `H x -16`), arms crossed over the head `LA(150, 0, 30)`, `RA(140, 0, -20)`.
- **Shake:** arms jitter ±3° every 2 f with the `constant` ease.
- **End:** settle back to the block at f63.

**R6_Roll**, `slides=True`, 26 f.

| Frame | Pose |
|---|---|
| f0 | Crouch-dive: `T(-30 \| py -0.4)`, arms forward `x 120` |
| f4-f20 | Torso x rotates through -90 → -180 → -270 → -360 (keys ≤ 90° apart). Body tucked `py -1.0` at mid-roll; arms and legs folded forward (`x 110` / `x 80`) |
| f20-f26 | Crouch landing → stance |

- **Roll-cancel:** a cancel is just the next roll clip starting from the current pose. Keep the keys symmetric so it chains.

---

## 5. Type Soul

**What it is.** A Bleach RPG. Every weapon has its own M1 string and an R "crit" [R11]. Its sword style is described as "graceful, angular" (unverified listicle). Movement is built around **Flash Step**.

| Skill | Description [R11] |
|---|---|
| Suikiwari | "Two handed jumping overhead slash" |
| Senmairoshi | "Multiple close-range slashes" |
| Thrust | "Quick long range thrust" |
| Overpowering Slash | "Close overhead slash carrying overpowering weight" |
| Flash Cut | "Crouch and swing their sword while dashing forward" |
| Blooming Cut | Crouches, then "releasing a slash that teleports them to the opponent" |
| Flash Tension | "After three consecutive blocked hits, the user teleports behind the opponent" |
| Hakuda: Rising Shot | Kick-up launcher |
| Hakuda: Whirlwind Step | "Long range fast spin kick" |
| Hakuda: Triple Striker | "3 consecutive kicks… Feintable (M2) inbetween kicks" |
| Hakuda: Dragon's Descent | "Soar into a devastating leg slam" |

### 5.1 Recipes (all (rec))

**R6_FlashCut** (iai dash-slash): Sword prop, snappy, `slides=True`, 50 f.

| Frame | Pose | Ease out |
|---|---|---|
| f0 | STANCE | |
| f8 | CROUCH-DRAW: `T(-24, +30, 0 \| py -0.5)`. Sword hand at the left hip, so the right arm crosses: `RA(30, 0, -40)`. Blade back. `LA(20, 0, -10)` holds the "sheath". Legs wide | `cubic_in` |
| f8-f14 | Held. This is the telegraph | |
| f16 | DRAWN CUT (2 f): `T(-14, -40, 0 \| pz -0.6)`, `RA(95, 0, 60)` (a horizontal sweep from left to right), `H(10, 30, 0)`. Marker `Hit`. The game dashes the HRP 10-16 studs during f14-f22 | `expo_in`, then `linear` |
| f16-f30 | Follow-through and freeze, blade out to the side (`RA(80, 0, 85)`) | `ak.drift` |
| f30 | Slow re-sheath | |

**R6_Suikiwari** (jumping two-hand overhead): 64 f.

| Frame | Pose | Ease out |
|---|---|---|
| f10 | Crouch | |
| f14 | Leap: arms overhead `RA/LA(185, 0, ±8)` (past vertical), `T(+20)`, legs tucked `x 40` | |
| f26 | Apex hold | |
| f30 | CHOP (3 f): `T(-34)`, arms `x 85` (arm-under-lean rule). Marker `Hit` at landing | |

---

## 6. Mighty Omega

**What it is.** A martial-arts Roblox fighter with real-world **Styles** [R12]: Boxing, Muay Thai, Karate, Kyokushin Karate, Kung Fu, Capoeira, Taekwondo, Sumo, Wrestling, Judo, Aikido, Kali Arnis, plus anime and personal styles.

**Rules [R12]:**

- **Normal string:** 4 normal attacks per Primary Style, then about a **1.5 s cooldown**. The **4th knocks back**.
- **Rhythm:** R charges Rhythm, which "increases your attacks' Damage and speed for some time".
- **Guard break:** stuns for **1 s**.
- **Parry and counter:** F + M1 parries Guardbreak Skills. F + M2 counters.

**Why it's a good reference.** Each style needs its **own stance and silhouette**, so it's the best Roblox example of stance identity (rec).

### 6.1 Style stances as R6 loops (all (rec))

**Boxing guard** (120 f loop):

- **Pose:** `T(-10, -22, 0 \| py -0.12)`, fists by the chin `RA(80, 0, -24)` `LA(88, 0, 4)`, `H(8, 12, 0)`.
- **Movement:** a bob-and-weave on `T z ±6` and `py ±0.05`, every 30 f.

**Muay Thai** (tall stance, 120 f loop):

- **Pose:** `T(+2, -10, 0)`, hands high and open `RA(110, 0, -16)` `LA(115, 0, 10)`.
- **Movement:** the lead leg taps every 60 f (`LL x 10 → 18`).
- **Teep:** use recipe 4.1's push-kick.
- **Roundhouse:** `T z +25`, `T y -80`, `RL(20, 0, 95)`. The shin hits; R6 has no knee, so the straight leg reads as a shin kick.

**Capoeira ginga** (96 f loop, a great R6 showcase):

- **Rhythm:** the legs alternate stepping back on a triangle (`RL x -30 ↔ +5`, `LL` mirrored), on a 48 f half-cycle.
- **Arms:** the arm opposite the back leg comes across the face (`LA(110, 0, 40)` or `RA(110, 0, -40)`).
- **Body:** `T y ±25`, `T x -10`, and `py -0.3` on the back-step beat.
- **Ease:** `sine_inout` throughout, so it loops cleanly.

---

## 7. Rogue Lineage

**What it is.** A classic permadeath Roblox RPG. Its combat is simple and readable [R13]:

| Control or rule | What it does |
|---|---|
| M1 | Light attack |
| M2 / R | Heavy attack |
| F | Block |
| Q | Roll or dash (the spear class gets a dash) |
| Punish | If you don't block an M2 in time, you "take no knockback and get hit", so a full M1 string follows |
| Parry | A fist block "can be used to parry heavy attacks, if it is pressed the exact second the attack hits" |
| M2 while rolling | Players chain M2 into rolls and forward dashes |

**Animation lesson (rec).** The heavy needs a **clearly different wind-up silhouette** from the light, so blocking it is a fair read: raise the weapon higher and hold it longer. The "punish" state is a **flinch without knockback**: 2-3 f snap, then hold.

---

## 8. Combat Warriors

**What it is.** A melee arena with many weapons and finisher animations ("Glory Kills"). It's known for its **parry** [R14]:

| Rule | Detail |
|---|---|
| Parry window | About 0.5 s (30 f) |
| Whiffed parry | Your "guard will go down and you will be stunned for about 1.5 s"; it recharges in about 3 s |
| Successful parry | Stuns the attacker for 3 s on the Parry page; the Keybinds page says 1.75-2 s |
| Other controls | E roll or dash; Q stomp, or a side kick against a parried player |
| Glory Kill | G near a player under 20 HP: "plays a long, cool animation" |
| Skills | Include Fist Barrage, Stab Dash and Skull Crush |

**Animation lesson (rec).** The parry is a **brace pose with no swing**. The payoff animation is the **attacker's parried stagger**: weapon arm flung up and back, a stumble step, then a dazed sway for the 1.75-3 s stun. That pair is Top-12 #7.

---

## 9. Other Roblox combat games (not researched in depth)

- **Untitled Boxing Game.** Recommended in 2026 listicles for "competitive one-on-one boxing", with community style tier lists (R4-type source, unverified). It's a good boxing-footwork reference.
- **Heroes Battlegrounds.** A My Hero Academia battlegrounds game. Its wiki lists characters like Explosion Hero, Green Hero, Hero Slayer and Split Ice. Same toolkit as TSB; no extra animation detail was gathered.

---

## 10. Fighting games (real frame data; all 60 fps)

### 10.1 Street Fighter 6: Ryu [N1][N2]

| Move | Startup | Active | Recovery | Hitstop | Notes |
|---|---|---|---|---|---|
| 5LP jab | 4 | 3 | 7 | **9** | Hitstun 14 |
| 5MP | 6 | 4 | 11 | **11** | |
| 5HP | 10 | 5 | 18 | **13** | |
| 5HK | 12 | 4 | 20 | **13** | |
| 6HP Solar Plexus | 20 | 2, 3 | 16 | 10, 12 | Two-hit overhead-ish advance |
| LP Shoryuken | 5 | 10 | 21 + 12 land | **15** | |
| HP Shoryuken | 7 | 10 | 34 + 12 land | **20** | Long punishable recovery |
| LP Hadoken | 16 | - | 31 | 8 | |
| HK Tatsumaki | 16 | 2(13)2(13)2 | 14 + 17 land | 15 ×3 | Spinning kick |
| 214LP Hashogeki | 12 | 6 | 18 | 15 | Palm push |
| **Drive Impact** | **26** | 2 | 35 | **25** | Armored |
| Drive Parry | 1 | 12 or held | 33 | - | Perfect Parry freezes the screen |
| Shin Shoryuken (SA3) | 5(2) | 12 | 32 + 39 land | 7, 8, 8, 8 | |
| Shinku Hadoken (SA1) | 7 | - | 79 | 8 ×5 | |

SuperCombo's definition of hitstop: "time essentially stops for both characters, making a move feel more impactful. Heavier attacks have longer hitstop, and some Punish Counters… extra long" [N2].

**What to steal (rec):**

1. **Hitstop rises with the move:** 9 → 11 → 13 for normals, 15-20 for specials, 25 for Drive Impact.
2. **Startup scales with power:** 4 f jab, 10 f heavy, 26 f armored heavy.
3. **Uppercuts stay active for a long time** (10 f) while rising, then commit to a long fall.
4. **Signature silhouettes:**
   - Hadoken: two palms forward at chest height.
   - Shoryuken: corkscrew rising fist with the lead knee up.
   - Tatsumaki: horizontal spin with one leg out.
   - Drive Impact: a big cocked heavy with green armor.

### 10.2 Guilty Gear Strive (and Xrd's animation method) [N3][N4][N5]

**Hit-stop by attack level:**

| Level | Hitstop (f) | Standing hitstun (f) |
|---|---|---|
| Lv0 | 11 | 12 |
| Lv1 | 12 | 14 |
| Lv2 | 13 | 16 |
| Lv3 | 14 | 19 |
| Lv4 | 15 | 21 |

**Counter hits:**

| Counter type | Hitstop | Slowdown afterwards |
|---|---|---|
| Small | Base value | 11 f |
| Mid | **21 f** | **25 f** |
| Large | **31 f** | **35 f** |

During slowdown the receiver's frames are doubled. Mid and Large counters create "a unique, cinematic hitstop" [N3].

**Sol Badguy (startup / active / recovery) [N4]:**

| Move | Startup | Active | Recovery | Notes |
|---|---|---|---|---|
| 5P | 5 | 5 | 9 | |
| c.S | 7 | 6 | 10 | |
| f.S | 10 | 2 | 13 | |
| 5H | 11 | 4 | 20 | |
| 6H | 9 | 3 | 43 | |
| Dust | 20 | 3 | 26 | |
| S Volcanic Viper | 9 | 14 | 40 | Invulnerable f1-11 (rising flame uppercut) |
| Bandit Revolver | 12 | | | Flip kick |
| Gun Flame | 16 | | | Ground punch that sends fire pillars |
| Tyrant Rave | 7 + 2 | | | Super |

**Xrd's limited animation (GDC 2015, Motomura) [N5]:**

- The team tried "full animation" first, but interpolated poses "look more 3D". So "we just stopped using interpolations between key frames. **Every frame now is a key frame**… Imagine 'Stop Motion'".
- Fewer frames meant each frame needed more information: about **500 bones per character**.
- They avoided simulation, "because… it just doesn't look 2D".
- They deform the mesh every key "to add imperfection".

**What to steal for R6 (rec):**

1. **Use the `constant` ease** on the strike and impact section. Key on 2s (every 2 f), or 3s for anime holds.
2. **Hold key poses as true holds** of 3-6 f before the strike. Use a moving hold elsewhere.
3. **R6 can't deform**, so get the "imperfection" from off-axis values. Give every key small asymmetries (`z`, `y` ±3-8°) so no two frames are mirror-clean.
4. **Battlegrounds hit-stop is shorter than anime-fighter hit-stop** (unverified). Our snappy preset uses 4-6 f for M1s (03); GGST uses 11-15. For the "cinematic counter" moment (Black Flash, Death Counter), borrow GGST's **21-31 f**.

### 10.3 Tekken 8 [N8]

| Move | Startup | Notes |
|---|---|---|
| Jab (1) | **i10** | +1 on block; total 27 f, recovery 17 |
| 1,2 | i10, i10 | |
| Kazuya Electric/Wind God Fist (f,n,d,df+2) | **i11-12** | |
| Kazuya df+2 launcher | i14 | Homing |
| Jin df+2 | i16-17 | |
| Jin b,f+2,1,df+2 | i28-29 on the last hit | Last hit is a Tornado |
| Heat Burst (2+3) | i16 | |
| Rage Art | **i20** | Freezes the timer on hit |

**What to steal (rec).** The crouch-dash uppercut (Wind God Fist) is a **low crouch that explodes straight up in 11 f**. The R6 version is recipe 8 with a forward pz lunge. Tekken's launchers go **up**, which is the battlegrounds "uppercut into air combo" language.

### 10.4 Dragon Ball FighterZ (Arc System Works) [N7]

| Move | Data |
|---|---|
| Vanish | Startup **7 + 9**, active 3, recovery 23, wall-bounces. "Teleports you behind the opponent and hits them"; sides switch during the super freeze |
| Super Dash | Homing flying dash. Startup **21 f** point-blank to **34 f** full-screen |
| Dragon Rush | Startup 19, active 9, recovery 24. A throw with a multi-hit sequence |

It uses the same limited-animation house style as Xrd (N5, same studio).

**What to steal (rec):**

- **Teleport-behind:** vanish, reappear behind already in the strike pose, then a hammer-fist into a wall bounce. This is TSB Death Counter and Type Soul Flash Tension (Top-12 #5).
- **Super Dash pose:** body horizontal, fist forward, legs trailing. In R6: `T x -70`, `RA(160, 0, 10)`, legs `x -10`.

### 10.5 Jujutsu Kaisen Cursed Clash

No reliable source on its Black Flash timing or animation was found. Every search hit was SEO spam. **Don't cite it.** JJS's own Black Flash (section 3) is the better-documented reference.

---

## 11. Action games

### 11.1 Sekiro [N9][N10][N11]

**Deflect rules [N9]:**

- The deflect window is **12 frames (0.2 s) before the hit**.
- Recent guard presses shrink it, "to as little as 4 frames, even 0 frames if you spam".
- The penalty clears after **30 frames** or after a successful deflect.
- Against flurries, spamming is necessary.

A second analysis (Igor, via Nexus) also gets 0.2 s / 12 f [N11]. Fextralife and Steam figures of "30 frames / 0.5 s" probably measure the whole input buffer, not the window (unverified).

**Combat [N10]:**

- Fights revolve around attacking **posture** and deflecting, which leads to "a single killing blow" (deathblow).
- A GameSpot-quoted reviewer says it "focuses all that emotion into one split second".

**Why it's praised (rec):**

- **The deflect is a tiny animation.** A 2-3 f blade snap does the work, together with spark, clang and both fighters' recoil.
- **The enemy's posture stagger makes the payoff readable.**
- **Repeated deflects alternate pose** (left/right), so a flurry looks like swordplay rather than a looped clip (unverified, check footage).
- **Danger attacks get a red kanji** (unverified).

**R6_Deflect** (unarmed or sword), 30 f; Top-12 #7.

| Frame | Pose | Ease out |
|---|---|---|
| f0 | STANCE | |
| f2 | SNAP (2 f): `T(+4, -30, 0 \| py -0.12)`, lead forearm across the face `LA(125, 0, 45)`, `RA(70, 0, -20)` guard, `H(-4, 20, 0)`. Marker `ParryOpen` at f0 and `ParryClose` at f12, the Sekiro window | `linear`, then `expo_out` |
| f4 | Recoil on success: `T(+8, -34)`, `LA(135, 0, 50)` | |
| f4-f10 | Hold. Game: spark VFX, 6-8 f hit-stop on both | |
| f10-f30 | Return to stance | |

Make a mirrored second clip (`ak.mirror` of the arms only) and alternate between the two.

**R6_ParriedStagger** (the attacker): 3 f snap and 60 f stun loop. The snap has no anticipation (reaction rule).

| Frame | Pose |
|---|---|
| f3 | `T(+22, +10, -6)`, weapon arm flung up and back `RA(150, 0, 40)`, `LA(40, 0, -50)`, head snapped back `H(+20, -8, 0)`, step back `RL(-25)` |
| f3-f14 | Overshoot and settle into the dazed pose: `T(+8, 0, 0 \| py -0.2)`, arms loose `RA(10, 0, 20)` `LA(10, 0, -20)`, `H(-12, 0, 6)` |
| f14-f60 | Loop: `T z ±4`, `H z ±6`, `sine_inout` |

Loop it for the stun length: Combat Warriors 1.75-3 s, Deepwoken guard break 1.05 s, Mighty Omega 1 s.

### 11.2 Elden Ring / Dark Souls [N24]

**Community discussion (Steam, 2022-2024):**

- Bosses use **delayed attacks** that punish early "panic" rolls; Margit's cane strike is the usual example.
- Players say some telegraphs feel "unnatural", which makes timing hard to judge.
- Frame-exact roll i-frames were **not confirmed** (unverified).

**What to steal (rec):**

- **The delayed swing:** a long held wind-up of 20-40 f with a tiny drift, then a fast strike. It reads as "dangerous" on boss-like ultimates.
- **The fairness rule:** the held pose must stay **perfectly readable**, with the weapon high and clear of the silhouette. The delay is the mind game, not hidden motion.
- **Commit:** every heavy is uncancellable after the pull-back, and recovery runs 30-45 f (weighty preset, 03).

### 11.3 God of War (2018) [N13][N14][N15][N16]

- **Hit-stop.** A developer describes freezing "the target in the hit pose and hold[ing] both Kratos and the target for a brief moment". It "emphasizes the connection of the swing and can also simulate a sort of resistance on the follow through" [N14]. The quote comes via a search snippet; the attribution is unverified.
- **GDC 2019 talks:**
  - Jason McDonald, "Redesigning combat for the new God of War".
  - Mihir Sheth, "Evolving Combat in God of War for a New Perspective": combat redesigned for a close, player-controlled over-the-shoulder camera [N15].
- **The axe recall** came from lead combat designer Vincent Napoli asking "why doesn't he just recall the axe?" [N16].
- **Cancels.** Partial cancels happen pre-hit or post-hit; complete cancels happen any time [N13].

**What to steal (rec):**

- **Play to the camera.** Roblox players see their own character from behind, so poses must read in the back three-quarter view (see 03 §5.7).
- **Hit-stop "resistance".** Hold the follow-through pose 2-4 f longer *after* the freeze so the swing feels like it pushed through something.
- **Throw/recall.** For thrown weapons, key a **catch pose** with the arm jolting back 10-15° on the `Catch` marker, then settle.

### 11.4 Ghost of Tsushima [N17][N18]

- **Speed.** The team tuned speed from **real sword fights rather than films** [N17].
- **Group combat.** Enemies attack one at a time behind "pretty long initial wind-ups".
- **Perfect parry.** L1 "just before the enemy weapon connects" instantly staggers.
- **Heavy attacks.** "Not slow", but they break guard.
- **Stances.** Stone, Water, Wind and Moon each target an enemy type [N18].
- **Glints** (unverified): blue for parryable, red for "dodge only".
- **Standoffs:** wait until the enemy commits; watch the feet.

**What to steal (rec).** The **standoff/iai pose** is a held crouch-draw. That's recipe 5.1 `R6_FlashCut`, with a 30-60 f hold on stance and a one-frame release.

### 11.5 Devil May Cry 5 [N12]

Itsuno (director) told Kotaku on 2019-03-28 that a "good-feeling" game comes first from responsiveness: the game should act the way players expect. He also explained the role of hit-stop: if something hits hard, "even if the attack animation only took a few frames, it was important to stress impact by using a hit-stop - displaying certain parts of the animation for a little longer". He credits Street Fighter II's Shoryuken as the root of Dante's and Nero's heavy hits.

**What to steal (rec).**

- **Hold the extreme, not the whole clip.** Hit-stop is a hold of the contact pose plus 1-2 f of the overshoot pose.
- **Stylish launchers and air strings.** DMC's are well known; they're not detailed here (unverified).

### 11.6 Sifu [N19][N20]

- **Choreography:** by Pak Mei master **Benjamin Colussi**; over **160 moves** [N20].
- **Mocap:** motion capture, then hand animation. **Impacts were added after capture**, because the actors couldn't actually hit each other [N20].
- **Influences:** Sekiro ("parry and structure system") and God Hand ("avoid system"), plus DMC and Metal Gear Rising. For feel, mostly action movies [N19].

**What to steal (rec).** Real martial-arts silhouettes (short-range Pak Mei strikes, palm and phoenix-eye fist) plus **added impact keys**: a 2-3 f snap-back on the striking limb at contact. On R6 that's a 3-6° recoil key right after `Hit`.

### 11.7 Hi-Fi Rush [N21][N22]

- Everything moves "in sync with the beat", and beat hits reward damage [N22].
- **Animation timing:** actions are "interpolated to land on the beat, regardless of the input timing". Moves with a lead-in are retimed so the **finishing point** hits the beat. **Jumps, dashes, parries and general movement are exempt**, so they never feel sluggish [N21].
- Cutscenes were animated to a click track at the scene's BPM.

**What to steal (rec).**

- **Pick a BPM for a combo** and space contacts on it: 120 BPM = 30 f per beat, or 15 f at half-beat. For example, M1 contacts every 15-20 f and the finisher on the next full beat.
- **Never beat-lock** dashes or parries.

### 11.8 Absolver [N23]

- **Stances:** players switch between **four stances**, defined by orientation to the enemy, and each stance changes the available moves.
- **Moves:** each move is a card in a "combat deck".
- **Chaining:** every attack starts in one stance and **ends in a specific stance**, so it can chain into another.
- **Studio goal:** "fluid, dynamic movement, similar to dance".

**What to steal (rec).** Our rule is "every clip starts and ends on the same stance" (CLAUDE.md). Absolver shows the next step: **combos that end on a mirrored stance**. Hit 1 ends southpaw, hit 2 starts southpaw and ends orthodox, and so on. That gives a 4-hit string visible variety without pops. Use `ak.mirror(STANCE)` as the second stance.

---

## 12. Recipes for the Top 12 not already shown above (all (rec))

Recipes 1 (Divergent Fist / Black Flash, §3.1), 7 (Deflect plus parried stagger, §11.1) and 11 (Flourish kick plus feint, §4.1) are already written out above.

### 2. R6_Barrage (Consecutive Punches / Machine Gun Blows / Cursed Strikes flurry), 16 + 8n + 40 f

**Set**, f0-f10:

- `T(-14, 0, 0 | py -0.15, pz -0.2)`, square to the target, legs wide.
- Fists chambered low: `RA(40, 0, -6)`, `LA(40, 0, 6)`. `H(14, 0, 0)`.
- Ease `cubic_in`.

**Loop**: 8 f per 2 punches, repeated n = 8-12 times (1-1.6 s).

| Local frame | Pose |
|---|---|
| L0 | `RA(98, 0, -8)` `LA(20, 0, 10)`, `T y +14`, `T z +3` |
| L2 | Passing: `RA(65, 0, 2)` `LA(55, 0, 2)` |
| L4 | `RA(20, 0, -10)` `LA(98, 0, 8)`, `T y -14`, `T z -3` |
| L6 | Passing |

- **Variation:** vary each cycle's extension height (`x` 88/104) and aim (`z` ±8) so the fists hit different spots.
- **Bob:** `py ±0.04`.
- **Ease, smooth blur:** `linear`.
- **Ease, anime strobe:** `constant`, with only the extended and passing keys. It reads as "many fists" (GGXrd limited-animation idea, N5).
- **Markers and VFX:** a `Hit` marker on every extension; the game spawns fist afterimages or Trails. Skip per-hit hit-stop, or use 1-2 f.

**Finisher:**

| Frame (after the loop) | Pose |
|---|---|
| +6 | Cock `T y -36`, `RA(-30, 0, 26)` |
| +8 | Straight `T(-20, +34 \| pz -0.8)`, `RA(95, 0, 30)`. Marker `Hit` |
| +8 to +18 | Hold. Game hit-stop 10-12 f |
| +18 to +40 | Recover |

### 3a. R6_M1_Uppercut (4th-hit ender; TSB mini uppercut / Deepwoken uppercut), 50 f

| Frame | Pose | Ease out |
|---|---|---|
| f0 | STANCE (or the end pose of M1_3) | |
| f6 | DIP: `T(-22, -30, 0 \| py -0.45)`, fist low behind the hip `RA(-25, 0, 18)`, `LA(70, 0, -10)`, `H(18, 18, 0)` | `cubic_in` |
| f6-f9 | Hold (telegraph) | |
| f11 | RISE-STRIKE: `T(+12, +28, 0 \| py +0.35)` up on the toes, `RA(165, 0, 18)`, `LA(-20, 0, -15)`, `H(24, -15, 0)` (looks up). Legs extend: `RL(-20)`, `LL(14)`. Marker `Hit` | `expo_in`, then `linear` |
| f13 | Overshoot: `RA 172`, `T x +15` | |
| f13-f24 | Drift hold. If the player is holding jump, the game launches both upward | |
| f24-f50 | Recover | `cubic_out` |

### 3b. R6_M1_Downslam (4th hit in the air), 40 f

| Frame | Pose | Ease out |
|---|---|---|
| f6 | RAISE: `T(+18, 0, 0)`, double-axe-handle `RA(175, 0, 12)` `LA(175, 0, -12)` (world ≈ 193°, behind the head), legs tucked forward `RL(35)` `LL(45)`, `H(-10)` | `cubic_in` |
| f6-f9 | Hold | |
| f11 | SLAM: `T(-38, 0, 0)`, `RA(85, 0, -6)` `LA(85, 0, 6)` (world ≈ 47° down-forward, arm-under-lean rule), legs in line with the torso. Marker `Hit` | `expo_in`, then `linear` |
| f11-f17 | Hold. Game hit-stop 8-10 f; the victim bounces | |
| f17-f40 | Fall and land | |

### 4. R6_SeriousPunch (ultimate), about 180 f

| Frame | Pose | Ease out |
|---|---|---|
| f0 | STANCE | |
| f20 | READY: `T(-4, -55, 0 \| py -0.3)`, `RA(-30, 0, 30)`, lead hand aims `LA(85, 0, -40)`, `H(-6, 38, 0)`, wide legs `RL(-30, 0, 14)` `LL(26, 0, -10)`. Marker `Wind` (pushes nearby players away) | `cubic_out` |
| f20-f80 | CHARGE: trembling hold, `RA(-32, 0, 31)` ↔ `(-28, 0, 29)` every 2 f, `py` -0.30 ↔ -0.32. Marker `Aura` at f40 | `constant` (stepped jitter); the last jitter key at f80 uses `cubic_in` into the sink |
| f88 | SINK: `T(+2, -62, 0 \| py -0.42)`, `RA(-45, 0, 34)` | `cubic_in` |
| f90 | STRIKE (2 f): `T(-22, +30, 0 \| py -0.3, pz -1.0)`, `RA(92, 0, 26)`, `LA(-20, 0, -24)`, `RL(-48, 0, 12)`, `LL(38, 0, -6)`, `H(12, -18, 0)`. Markers `Hit` and `ImpactFrame` | `expo_in` from f88 |
| f92 | Overshoot: `RA 98`, `T(-25, +34)` | |
| f92-f130 | Hold (drift ±1°). Game: 20-30 f hit-stop, 2-3 f impact frames, camera kick | |
| f130-f180 | Recover. The arm lowers first; the torso follows 4 f later | `cubic_out` |

### 5. R6_TeleportCounter (Death Counter / DBFZ Vanish / Flash Tension), about 90 f

The game teleports the HRP behind the victim, facing them, at f0.

| Frame | Pose | Ease out |
|---|---|---|
| f0 | APPEAR: `T(+6, -20, 0 \| py -0.1)`, fist raised high `RA(170, 0, 14)`, `LA(20, 0, -10)`, `H(-14, 12, 0)` (looking down at the victim) | |
| f0-f30 | Hold for the 死 / freeze beat. At f15 the fist tightens: `RA 172` | |
| f36 | WIND: `T(+14, -26)`, `RA(178, 0, 10)` | `cubic_in` |
| f38 | STRIKE (2 f): `T(-30, +10, 0 \| py -0.25, pz -0.5)`, `RA(95, 0, 12)`, `LA(-25, 0, -20)`, `H(16, -6, 0)`. Marker `Hit` | `expo_in` |
| f38-f58 | Hold. Game: 20-31 f hit-stop (GGST large counter) and wall bounce | |
| f58-f90 | Recover | |

- **Timing anchor:** DBFZ Vanish startup is 7 + 9 [N7].

### 6. R6_SideDash (L, mirror for R), `slides=True`, 24 f

| Frame | Pose | Ease out |
|---|---|---|
| f0 | STANCE | `quad_out` |
| f2 | PUSH: `T(-10, -18, +16 \| py -0.25)` (tilts into the travel), leading leg `LL(0, 0, -28)`, push leg `RL(-8, 0, 6)`, arms out for balance `RA(40, 0, 40)` `LA(30, 0, -50)`, head stays level `H(0, 8, -10)` | |
| f4-f14 | Travel: moving hold, `T z +18` | |
| f16 | BRAKE: counter-tilt `T(-4, -18, -8)`, `LL` plants, `RL(-2, 0, 2)` catches up, arms swing in | |
| f20-f24 | Settle to STANCE | |

- **Game side:** sideways velocity for f2-f14.
- **Front dash:** use the existing `R6_Dash`.

### 8. R6_RisingUppercut (Shoryuken / Volcanic Viper / Wind God Fist), 70 f

| Frame | Pose | Ease out |
|---|---|---|
| f5 | CROUCH: `T(-20, -30, 0 \| py -0.55)`, `RA(-10, 0, 20)`, `LA(60, 0, -10)` | `cubic_in` |
| f7 | FIRST ACTIVE (SF6 LP SRK starts on f5, HP on f7): `T(+6, +20, 0 \| py 0)`, `RA(130, 0, 20)`. Marker `Hit` | `expo_in` |
| f12 | `T y +60`, `RA(175, 0, 10)`, knee-up substitute `LL(70)`, `RL(-15)`, `py +0.6`. Marker `Hit2` | |
| f18 | Apex: `T y +80`, `py +1.2`. The game adds upward velocity | |
| f18-f40 | Fall. The torso unwinds back toward `y -18`; keys ≤ 90° apart | |
| f40 | LAND: `T(-10, -18 \| py -0.35)` | |
| f40-f70 | Recover | |

- **Keep the long recovery.** It's what makes the uppercut a commitment: HP SRK is 34 + 12 f [N1].
- **Wind God Fist variant:** add `pz -0.6` at f5-f7, a lunging crouch.

### 9. R6_SpinKick (Garou's 4th M1 / Sonic Whirlwind Kick / Whirlwind Step / Tatsumaki), 45 f

| Frame | Pose |
|---|---|
| f6 | WIND (opposite turn): `T(-8, +40, 0 \| py -0.2)`, arms in |
| f10 | `T y -60`, `RL(20, 0, 40)` |
| f13 | KICK: `T(+10, -180, +20 \| py -0.05)` (tilts away from the leg), `RL(10, 0, 95)` horizontal out to the right, arms out `RA(30, 0, 60)` `LA(30, 0, -60)`, head leads the spin by about 20°. Marker `Hit` |
| f16 | `T y -300`, `RL(0, 0, 70)` |
| f19 | `T y -378` (≡ STANCE's -18 after a full turn), `RL(-5, 0, 20)` lands |
| f19-f45 | Recover |

- **Spin keys** are every ≤ 120°, as the Spins rule requires.

### 10. R6_GroundStomp (Hunter's Grasp / Atmos Cleave stomp / Metal Bat smash / Crushing Blow), 50 f

| Frame | Pose | Ease out |
|---|---|---|
| f8 | LIFT: `T(+10, -10, +6 \| py +0.05)` (weight over the left leg), `RL(75, 0, 12)`, arms out `RA(40, 0, 50)` `LA(40, 0, -50)`, `H(-10)` | `cubic_out` |
| f8-f12 | Hold (telegraph) | |
| f14 | STOMP (2 f): `T(-16, -10, 0 \| py -0.45)`, `RL(-5, 0, 16)`, `LL(10, 0, -12)`, arms whip down and out `RA(-10, 0, 30)` `LA(-10, 0, -30)`, `H(10)`. Markers `Hit` and `Shockwave` | `expo_in` |
| f14-f24 | Low drift hold. Game: 6-8 f hit-stop, camera shake, rocks | |
| f24-f50 | Recover | |

### 12. R6_CounterStance + R6_CounterKick (JJS Manji Kick; TSB Split Second Counter style)

**Stance**: 60 f loop.

- **Pose:** `T(+4, +20, -6 | py -0.05)`, high guard `LA(150, 0, -20)`, `RA(60, 0, -20)`, raised lead leg `LL(55, 0, -10)` (crane), `RL(-4, 0, 6)`, `H(-4, -14, 0)`.
- **Sway:** `T z ±3`, `LL x ±4`, `sine_inout`.

**Kick**: 40 f.

| Frame | Pose |
|---|---|
| f3 | Pivot: `T y +60` |
| f6 | UPWARD ROUNDHOUSE: `T(+18, +100, +28 \| py +0.1)`, `RL(30, 0, 110)`, `LL(-6, 0, -10)`, `RA(20, 0, 40)`, `LA(60, 0, -70)`. Marker `Hit` |
| f8 | Overshoot: `RL z 118` |
| f20 | Retract |
| f40 | Back to STANCE. Turn `y` back to -18 with keys ≤ 120° apart |

---

## Top 12 to recreate first (battlegrounds-style Roblox game)

Ranked by **how recognisable it is to Roblox combat players × how much it will impress on video × fit for R6**. All are (rec).

| # | Move | Mainly from | Recipe | Why it's this high |
|---|---|---|---|---|
| 1 | **Delayed-impact punch + Black Flash variant** | JJS Divergent Fist / Black Flash; TSB Sorcerer's 4th M1 | §3.1 | Instantly recognised. Has a held "flash" cue, two-beat payoff and impact frames: a perfect showcase of anticipation + hit-stop |
| 2 | **Barrage + straight finisher** | TSB Consecutive Punches, Genos, JJS Cursed Strikes | §12.2 | Every battlegrounds game has one. Shows off loops, stepped (`constant`) strobe and VFX markers |
| 3 | **M1 enders: mini-uppercut and downslam** | TSB universal, Deepwoken uppercut, Tekken launchers | §12.3a/b | Completes the existing `R6_M1_1-4` chain into the real TSB grammar (ground ender, launcher, air ender) |
| 4 | **Charged ultimate punch** | TSB Serious Punch, SF6 Drive Impact | §12.4 | A one-shot "wow" clip: long charge, 2 f release, 30-40 f hold |
| 5 | **Teleport-behind counter** | TSB Death Counter, DBFZ Vanish, Type Soul Flash Tension | §12.5 | Iconic anime beat. Teaches holds plus game-side teleport by marker |
| 6 | **Side dash** (+ existing front dash) | TSB, JJS | §12.6 | The core movement of the genre; players notice bad dashes instantly |
| 7 | **Deflect + parried stagger pair** | Sekiro, Combat Warriors, Deepwoken | §11.1 | Teaches the attacker/defender pair and the window marker. Very "satisfying" on video |
| 8 | **Rising uppercut** | SF6 Shoryuken, GGST Volcanic Viper, Tekken Wind God Fist, TSB Uppercut skill | §12.8 | Universally known silhouette, with real frame data to cite |
| 9 | **Spin kick** | Garou's 4th M1, Sonic Whirlwind Kick, Type Soul Whirlwind Step, SF6 Tatsumaki | §12.9 | Shows the 360° keying gotcha and good R6 leg use |
| 10 | **Ground stomp / slam** | Hunter's Grasp, Atmos Cleave, Metal Bat, JJS Crushing Blow | §12.10 | Simple, heavy, and great with camera shake and rocks VFX |
| 11 | **Weighty sword string: Flourish kick + feint** | Deepwoken | §4.1 | Represents the "weighty" school next to the snappy ones. The feint teaches the readable pull-back |
| 12 | **Counter stance + upward roundhouse** | JJS Manji Kick | §12.12 | A distinctive pose people screenshot; shows balance on one leg in R6 |

**Honourable mentions:**

- TSB Shove (§2.2), a quick win for a short video.
- Capoeira ginga loop (§6.1), an eye-catching idle.
- Iai Flash Cut (§5.1), which pairs with Ghost of Tsushima standoffs.
- Two-palm blast (Genos M1 4 / Hadoken).

---

## 13. Sources

All accessed 2026-10-21 unless a date is given. "Via search snippet" means the page itself couldn't be fetched (403/404); the claim comes from the search engine's extract and should be re-checked.

### Roblox

| ID | Source | Type | Date |
|---|---|---|---|
| R1 | The Strongest Battlegrounds Wiki, "The Strongest Hero" (Saitama): M1, Normal Punch, Consecutive Punches, Shove, Uppercut, Serious Punch, Death Counter, Table Flip, Omni-Directional Punch. Read via the MediaWiki API (`the-strongest-battlegrounds.fandom.com/api.php`, page `The_Strongest_Hero`) | community wiki | accessed 2026-10-21 |
| R2 | TSB Wiki character pages: Hero Hunter, Destructive Cyborg, Deadly Ninja, Brutal Demon, Blade Master, Wild Psychic, Sorcerer (same API) | community wiki | accessed 2026-10-21 |
| R3 | Bloxodes, "The Strongest Battlegrounds - Techniques" (Uppercut Dash, True Downslam, Twisted Dash, Upside Down Ragdoll…), https://bloxodes.com/wiki/the-strongest-battlegrounds/techniques | community tech aggregator | undated |
| R4 | thespike.gg, "Best Roblox fighting games" (TSB "by a wide margin, the most-played fighter"; UBG for boxing), https://www.thespike.gg/roblox/best-roblox-games/best-fighting-games | listicle, via search snippet | undated (2026) |
| R5 | games.gg, "The Strongest Battlegrounds Combat Guide" (= 03 [S27]) | third-party guide | undated |
| R6 | Jujutsu Shenanigans Wiki: Vessel, Honored One, Tips & Techs, Controls & Mechanics (`jujutsu-shenanigans.fandom.com/api.php`) | community wiki | accessed 2026-10-21 |
| R7 | ItemLevel, "Jujutsu Shenanigans Yuji Itadori Vessel Guide & Showcase", https://itemlevel.net/jujutsu-shenanigans-yuji-itadori-vessel-guide-showcase/ | third-party guide | undated |
| R8 | TryHardGuides, "How to Black Flash in Jujutsu Shenanigans", https://tryhardguides.com/how-to-black-flash-in-jujutsu-shenanigans/ | third-party guide, via search snippet | undated |
| R9 | Deepwoken Wiki: Combat Mechanics, Movement (`deepwoken.fandom.com/api.php`) | community wiki | accessed 2026-10-21 |
| R10 | Deepwoken Wiki, Great Maul (= 03 [S29]) | community wiki | accessed 2026-10-21 |
| R11 | Type Soul Wiki: Kendo, Hakuda, Speed, Weapons (`type-soul.fandom.com/api.php`) | community wiki | accessed 2026-10-21 |
| R12 | Mighty Omega Wiki: Combat, Controls, Styles, Rhythm (`mightyomega.fandom.com/api.php`) | community wiki | accessed 2026-10-21 |
| R13 | Rogue Lineage Wiki: Melee Combat Tips, Block, Controls (`rogue-lineage.fandom.com/api.php`) | community wiki | accessed 2026-10-21 |
| R14 | Combat Warriors Wiki: Parry, Keybinds, Glory kills, Skills (`combat-warriors.fandom.com/api.php`) | community wiki | accessed 2026-10-21 |

### Non-Roblox

| ID | Source | Type | Date |
|---|---|---|---|
| N1 | SuperCombo, "Street Fighter 6/Ryu/Data", https://wiki.supercombo.gg/w/Street_Fighter_6/Ryu/Data | frame-data wiki | accessed 2026-10-21 |
| N2 | SuperCombo, "Street Fighter 6/Game Data" (hitstop definition, screen-freeze buffers), https://wiki.supercombo.gg/w/Street_Fighter_6/Game_Data | frame-data wiki | accessed 2026-10-21 |
| N3 | Dustloop, "GGST - Mechanics" (attack levels, counter-hit hitstop and slowdown), https://www.dustloop.com/w/GGST/Mechanics | frame-data wiki | accessed 2026-10-21 |
| N4 | Dustloop, "GGST/Sol Badguy/Frame Data", https://www.dustloop.com/w/GGST/Sol_Badguy/Frame_Data | frame-data wiki | accessed 2026-10-21 |
| N5 | Junya C. Motomura (Arc System Works), "GuiltyGearXrd's Art Style: The X Factor Between 2D and 3D", GDC 2015 handout, https://www.ggxrd.com/Motomura_Junya_GuiltyGearXrd.pdf. Session page: https://gdcvault.com/play/1022031/GuiltyGearXrd-s-Art-Style-The. ASW announcement: https://www.arcsystemworks.com/guilty-gear-xrd-art-talk-at-game-developers-conference-2015/ | GDC talk (primary) | 2015-03 |
| N7 | Dustloop, "DBFZ - System Mechanics" (Vanish, Super Dash, Dragon Rush), https://www.dustloop.com/w/DBFZ/Mechanics | frame-data wiki | accessed 2026-10-21 |
| N8 | TekkenDocs, Tekken 8 Kazuya and Jin frame data, https://tekkendocs.com/t8/kazuya and https://tekkendocs.com/t8/jin | frame-data site | accessed 2026-10-21 |
| N9 | Fextralife Sekiro Wiki, "Deflection", https://sekiroshadowsdietwice.wiki.fextralife.com/Deflection | community wiki | accessed 2026-10-21 |
| N10 | Wikipedia, "Sekiro: Shadows Die Twice" (posture, deathblow, review quote), https://en.wikipedia.org/wiki/Sekiro:_Shadows_Die_Twice | encyclopedia | accessed 2026-10-21 |
| N11 | Nexus Mods article citing Igor's DS Anim Studio analysis (deflect 0.2 s / 12 f), https://www.nexusmods.com/stellarblade/articles/199 | community analysis, via search snippet | undated |
| N12 | Kotaku, "Devil May Cry 5's Director Tells Us How They Made Combat", https://kotaku.com/devil-may-cry-5s-director-tells-us-how-they-made-combat-1833642299 | interview article | 2019-03-28 |
| N13 | Eric Williams, "Combat Canceled: God of War & Action Game Design", Gamasutra / Game Developer, https://www.gamedeveloper.com/pc/combat-canceled-i-god-of-war-i-action-game-design | developer article | 2008-02-15 |
| N14 | PlayStation Blog, "Game developers explain what makes God of War (2018)'s combat tick" (hit-stop quote; speaker attribution unverified) | press blog, via search snippet | 2018 |
| N15 | GDC 2019: Jason McDonald, "Redesigning combat for the new God of War" (video post 2021-04-26, https://gamedeveloper.com/design/video-redesigning-combat-for-the-new-i-god-of-war-i-); Mihir Sheth, "Evolving Combat in God of War for a New Perspective", https://gdcvault.com/play/1026423/Evolving-Combat-in-God-of | GDC talks (listings only) | 2019 |
| N16 | GameRevolution, "God of War axe one year later" (Napoli recall quote), https://www.gamerevolution.com/originals/525661-god-of-war-axe-origins-anniversary | article, via search snippet | 2019 |
| N17 | GamingBolt, "Ghost Of Tsushima Breaks Down Stances, Attack Speed, Parrying…" (Zimmerman breakdown), https://gamingbolt.com/ghost-of-tsushima-breaks-downs-stances-attack-speed-parrying-and-more-combat-details | news article | c. 2020-05 |
| N18 | Game Developer, "Ghost of Tsushima design analysis", https://www.gamedeveloper.com/game-platforms/ghost-of-tsushima-design-analysis | blog analysis | c. 2020 (undated in extract) |
| N19 | Nintendo Life, "We Had A Lot To Learn - Sloclap Talks Bringing Sifu To Switch", https://www.nintendolife.com/features/we-had-a-lot-to-learn-sloclap-talks-bringing-sifu-to-switch | interview | c. 2022-11 |
| N20 | TheGamer / eip.gg / NME coverage of Sifu's behind-the-scenes video (Colussi, 160+ moves, impacts added after mocap), e.g. https://www.nme.com/news/sifu-behind-the-scenes-video-dives-into-motion-capture-3076383 | news, via search snippet | 2021 |
| N21 | Unreal Engine developer interview, "Hi-Fi Rush was inspired by Shaun of the Dead and Futurama" (beat interpolation, exemptions), https://www.unrealengine.com/en-US/developer-interviews/hi-fi-rush-was-inspired-by-shaun-of-the-dead-and-futurama | developer interview, via search snippet | 2023 |
| N22 | Wikipedia, "Hi-Fi Rush", https://en.wikipedia.org/wiki/Hi-Fi_Rush | encyclopedia | accessed 2026-10-21 |
| N23 | Wikipedia, "Absolver", https://en.wikipedia.org/wiki/Absolver | encyclopedia | accessed 2026-10-21 |
| N24 | Steam Community, Elden Ring discussion threads on delayed attacks and roll timing, e.g. https://steamcommunity.com/app/1245620/discussions/0/3278065083968470167 | player forum, via search snippet | 2022-2024 |
| N25 | DevForum, "GG Camera Shake" and "Camera shake for combat", https://devforum.roblox.com/t/gg-camera-shake-screenshake-that-doesnt-suck/4731267 and https://devforum.roblox.com/t/camera-shake-for-combat/2317381 | developer forum, via search snippet | 2023-2026 |

**Not used (on purpose):** SEO and spam pages about Black Flash, YouTube "animation pack" re-uploads, and any page that links to ripped or leaked animation assets.

## 14. What still needs measuring (before claiming "this is the game's exact timing")

1. **TSB:** M1 contact-to-contact spacing, front/side dash length, Normal Punch wind-up. Record at 60 fps and step through the frames; no source has them.
2. **JJS:** Divergent Fist time from input to the white flash (a guide hints about 0.5 s), the flash window length, and the delay to the cursed-energy burst.
3. **Deepwoken:** feint window length and roll i-frames.
4. **Sekiro:** whether repeated deflects alternate pose; perilous-attack timing.
5. **Elden Ring:** roll i-frames. Community numbers conflict.
