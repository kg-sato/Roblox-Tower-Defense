---
date: 2026-10-28
tags: [animation, motion, blur, springs, smears, capabilities]
---
# Animation Craft and Capabilities

User (2026-10-28): "research more on animations and your capabilities in making them", plus "try duplicating objects and slightly moving them so that the animations have more glare / blur". This note was a 30-minute focus session. Earlier notes it builds on: [[Research/VFX and Animation/Animation and Juice Playbook]] (easing, juice recipes), [[Research/VFX and Animation/Smooth Motion and Blur Playbook]] (blur toolkit, measured blur curves), [[Research/VFX and Animation/Effect Quality]].

## 1. Smears, multiples and afterimages (blur drawn by hand)
- A **smear frame** is a single frame that shows motion by stretching, distorting or **multiplying** the subject. Its most common use is to stand in for camera motion blur ([RebusFarm](https://rebusfarm.net/blog/smear-frames-in-animation-how-animators-create-fast-and-dynamic-motion), [GarageFarm](https://garagefarm.net/blog/smear-frames-enhancing-motion-in-animation)). Chuck Jones is named as a pioneer. Sources advise using them sparingly, in fast moves only.
- **Multiples:** several copies of the subject (or a limb) in different states of the move, all in one frame ([RebusFarm](https://rebusfarm.net/blog/smear-frames-in-animation-how-animators-create-fast-and-dynamic-motion)). This is the user's "duplicate and slightly move" idea.
- **Roblox has no motion-blur instance.** DevForum threads say directional blur isn't possible; the workarounds are frame-stacking (copies), Trails, or scripted blur, which "won't look natural" ([Motion Blur Effect thread](https://devforum.roblox.com/t/motion-blur-effect/102658), [blur drag thread](https://devforum.roblox.com/t/how-would-i-create-a-blur-drag-effect-like-amnesia-tdd/4807845)).
- **Afterimage recipe (engine-neutral):** clone the subject, make it transparent and let it chase the original, or spawn a copy at a fixed interval that fades on its own ([Defold forum](https://forum.defold.com/t/how-do-you-make-an-afterimage-effect/65628), [Touhou Ice Hockey devlog](https://chocola-mint.itch.io/touhou-ice-hockey-festival/devlog/483653/tech-blog-how-i-did-the-afterimage-effect)).
- **Trail streak:** a Trail between two attachments, with a Transparency and WidthScale that start at 0, reach 0.5 in the middle and end at 0 ([Bloxy teleport thread](https://devforum.roblox.com/t/bloxys-teleportation-effect/1134702)). The Trail docs list Lifetime, Min/MaxLength, WidthScale, FaceCamera, LightEmission, and note that it needs two attachments and movement ([Trail reference](https://create.roblox.com/docs/reference/engine/classes/Trail)).

**Our measured result:** the moth's echo trail (3 copies, 2/4/6 frames behind) and the grove's ghost lines (2 copies per line, 2.6x/5x thicker, nudged 5-16 cm) both read in Play. See [[Research/UI/Abstract HUD]] round 4.

## 2. Springs and second-order motion (procedural "personality")
- **Second-order system** (t3ssel8r, "Giving Personality to Procedural Animations using Math" ([video mirror](https://yt.dorper.me/v/yt/KPoeNZZ6H4s), [Patreon write-up](https://www.patreon.com/posts/procedural-video-82487305), which was **403 for me**)). Three dials: **f** (speed, Hz), **ζ** (damping: <1 wobbles, 1 settles exactly, >1 sluggish), and **r** (initial response: 0 eases in, 1 is immediate, >1 overshoots, <0 anticipates, so one dial gives "anticipation"). The write-up says the same parameters also cover first-order (exponential smoothing), and that stability depends on frequency vs. update rate.
- Equation, in the form widely used for this model: y + k1·y′ + k2·y″ = x + k3·x′, with k1 = ζ/(πf), k2 = 1/(2πf)², k3 = r·ζ/(2πf). **Unverified against the write-up (403)**; derived to match ω = 2πf from [Allen Chou](https://allenchou.net/2015/04/game-math-precise-control-over-numeric-springing) (k1 = 2ζ/ω, k2 = 1/ω²). Our module checks it with a self-test (section 5).
- **Picking ζ** (Allen Chou): ω = 2πf; to keep a fraction p of the wobble after time t_d, ζ = −ln(p)/(ω·t_d). Example: 2 Hz wobble, 90% gone in 0.5 s → ζ ≈ 0.367. His implicit-Euler step is unconditionally stable ([same post](https://allenchou.net/2015/04/game-math-precise-control-over-numeric-springing)).
- Opsive: low stiffness = soft sway, high = stiff; low damping = loose, high = settles fast or shakes ([Opsive springs](https://opsive.com/support/documentation/ultimate-character-controller/animation/springs/)).

## 3. The 12 principles, game version (Game Developer, from Jonathan Cooper's *Game Anim*)
Source: [The 12 principles of animation in video games](https://gamedeveloper.com/production/the-12-principles-of-animation-in-video-games).
- **Squash and stretch** keeps volume: stretch one axis, squash the other.
- **Anticipation:** short on the player's own actions (responsiveness), long on enemy telegraphs (readability).
- **Follow-through / overlap:** let parts lag; set the frame where control returns.
- **Slow in / out:** instant first response, slow follow-through for weight.
- **Timing:** no instant full-speed starts (weightless); hold key poses so they read.
- **Exaggeration:** push hits so they read from a distant game camera, consistently.
- Overshoot "pop" on arrival, ease-out "settle"; linear looks robotic ([game-feel skill guide](https://claudeskills.info/ja/skills/gamedev-skills/awesome-gamedev-agent-skills/game-feel/)).
- No source maps the principles to UI frame counts; tune by measuring (our recorder, section 4).

## 4. What Roblox gives us for animation
| Tool | Use | Note |
|---|---|---|
| TweenService | UI and part property tweens | fixed easing curves; no velocity carry-over when retargeted (a spring fixes that) |
| RenderStepped + our code | springs, smears, echo copies, procedural walk cycles | everything in [[Research/UI/Abstract HUD]] round 4 is this |
| Trail / Beam | streaks behind moving parts; laser lines | Trail needs two attachments and movement |
| IKControl | procedural poses (look-at, reach, foot plant) on a Humanoid or ChainRoot; Weight blends with animation; SmoothTime default 0.05 | can make unrealistic wrists without constraints ([IKControl](https://create.roblox.com/docs/reference/engine/classes/IKControl), [IK guide](https://create.roblox.com/docs/animation/inverse-kinematics)) |
| AnimationController + KeyframeSequence | keyframed rigs | our AnimKit (`ServerStorage.AnimKit`) builds them by script |
| DepthOfField / Blur / camera FOV | focus pulls, speed feel | measured in [[Research/VFX and Animation/Smooth Motion and Blur Playbook]] |

## 5. What I (Claude) can and cannot do
| Can | Cannot / limits |
|---|---|
| Write procedural motion in Luau: springs, smears, echoes, IK, tweens, cameras | Hand-key in Studio's Animation Editor (no reliable GUI drag) |
| Build KeyframeSequences by script (AnimKit), and Blender scenes by script | Upload animations or meshes without the user's OK |
| Record Studio at 10-15 fps (`tools/record_window.py`) and measure frames (`tools/fx_quality.py`, sheets) | Judge "feel" by eye like a player; I measure (echo spacing, overshoot %, settle time) and the user judges |
| Check every change in Play and compare same moments before / after | Studio capture tops out near 15 fps, so very fast motion is under-sampled |

## 6. Rules we adopt
1. **Fast things get multiples:** anything that crosses more than its own width per frame gets 2-3 echo copies (fading 0.6 / 0.75 / 0.9) or a Trail.
2. **Glow = a duplicate:** a key line gets two ghost copies (thicker, fainter, nudged) instead of a flat neon.
3. **Follow with springs, not re-tweens:** UI that chases a value (counters, bars, hover) uses the second-order follower so velocity carries over.
4. **Pops overshoot ~10%, then settle;** player-triggered motion starts on the first frame.
5. **Squash and stretch keeps area** (x·y constant) on impact pops.
6. **Reduced Motion** turns echoes, smears and springs off (end state at once).

## 7. Implemented (2026-10-28)
`Studio_Export/Motion.luau`, installed as `ReplicatedStorage.Shared.Motion`:
- `follower(f, z, r, x0)`: the second-order follower with the low-frame-rate stability clamp. **Self-test passes in Studio:** critical damping settles with no overshoot; ζ 0.3 overshoots by more than 20% then settles; r = −1 dips the wrong way first (anticipation); a 12 Hz spring stays stable at 10 fps.
- `echoGui` / `echoModel`: multiples. Copies are cloned once and replayed from a position history (no per-frame cloning); they clean up when the source is destroyed (checked: 0 copies left).
- `pop(gui, amount)`: squash and stretch that keeps area, springing back with about 20% overshoot. **Not used yet.**

Used in the game:
- **Merge leap** (GameClient, `kind == "Merge"`): each leaping familiar gets 3 echo copies, unless Reduced Motion is on. Checked in Play by replaying the same leap path on a Star Drake with the module attached (a real merge needs a matched board). The echoes smear the leap into a bright arc. A faint dark patch stayed at the start spot in the recording; cause not found (the real merge removes the footprint plates first).
- **Skill grove** ghost lines and the **moth** echo trail: same idea, written into those scripts (see [[Research/UI/Abstract HUD]] round 4).

Skill: `.claude/skills/make-motion/SKILL.md` (the method as a checklist, `/make-motion <thing>`).
