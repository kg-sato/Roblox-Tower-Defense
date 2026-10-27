# Smooth Motion and Blur Playbook

Researched 2026-10-25. Priority for all our animations and effects: **smooth and elegant, like motion blur**: nothing snaps, everything eases, fast things are softened. The user also liked the **blur effect in the Rivals loading animations**. Related: [[Animation and Juice Playbook]], [[Magical Roll Animation Playbook]], [[Low-End Device Playbook]], [[UI Design Playbook]], [[Game Design Doc]] (Flashes, Particles, reduced-motion settings)

## Source quality
- **Official Roblox docs read:** [BlurEffect](https://create.roblox.com/docs/reference/engine/classes/BlurEffect), [DepthOfFieldEffect](https://create.roblox.com/docs/reference/engine/classes/DepthOfFieldEffect), [BloomEffect](https://create.roblox.com/docs/reference/engine/classes/BloomEffect), [Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting), [Loading screens](https://create.roblox.com/docs/players/loading-screens), [UI animation](https://create.roblox.com/docs/ui/animation).
- **Community (DevForum, unofficial):** [Camera Motion Blur Script](https://devforum.roblox.com/t/camera-motion-blur-script/1666079), [Motion Blur Effect request](https://devforum.roblox.com/t/motion-blur-effect/102658), [spr spring module](https://devforum.roblox.com/t/spring-driven-motion-spr/714728), [Cutscene Loading Screen](https://devforum.roblox.com/t/cutscene-loading-screen/811214).
- **Not found:** how Rivals itself builds its loading animation. I have no Rivals screenshots or clips and found no write-up. Everything below about "Rivals-style" is a reasonable recipe for a blur-based loading transition, not a copy of theirs. Please add a few `rivals-*` stills or a short clip to `Research/` so we can match it.
- **Time and numbers marked "convention"** below are common practice from animation guides, not Roblox rules. Tune by eye.

## 1. What "smooth and elegant" means in practice
1. **Everything eases.** No linear motion except continuous rotation. Entrances: ease-out (Quint or Exponential Out). Moves between two states: ease-in-out (Quad or Sine). Exits: ease-in then fade. Roblox's easing styles: Linear, Sine, Quad, Cubic, Quart, Quint, Exponential, Circular, Back, Bounce, Elastic.
2. **Avoid abrupt change.** No hard cuts in brightness, blur or colour. Fade in and out; never strobe.
3. **Use springs for things the player interacts with, tweens for scripted sequences.** Springs keep their velocity when interrupted (a button released mid-press does not jump), tweens restart. A DevForum thread on spring UI makes this point about buttons that get stuck pressed when tweened repeatedly.
4. **Spring settings.** Critically damped (damping ratio 1) is the neutral default; below 1 (about 0.6 to 0.8) overshoots for a "pop"; above 1 settles slower with no overshoot. Frequency about 0.5 (slow) to 4 (fast) in the `spr` examples.
5. **Overlap and stagger.** Children start 30 to 60 ms apart (convention) so a panel's contents arrive in a wave instead of all at once.
6. **Fast things get softened.** That is the motion-blur idea: a quick move gets a short streak, a glow or a fade-in tail so the eye reads speed without a jarring jump (section 2).
7. **Durations (convention).** Micro feedback 100 to 200 ms. Panels and menus 250 to 400 ms. Screen transitions 400 to 700 ms. Celebration moments 1 to 6 s. Longer is not more elegant; slow-and-heavy reads as laggy on phones.
8. **Frame-rate independence.** Use `dt`-based smoothing (section 4), not "move 5% per frame", so motion looks the same at 30, 60 and 120 fps.
9. **Keep it light on phones.** Post-processing and many particles cost more on low-end devices. Honor the Particles and Reduced motion settings (see [[Low-End Device Playbook]]).

## 2. The blur toolkit (what Roblox gives us)
| Tool | What it does | Notes from the docs |
|---|---|---|
| **BlurEffect** | Gaussian blur of the **rendered world**. `Size` in pixels, `Enabled` | Must be parented to `Lighting` or `Workspace.CurrentCamera`. **Only one BlurEffect applies at a time: the one with the largest Size wins.** No directional property. The docs do not mention tweening it, but `Size` is a normal number property so TweenService works |
| **DepthOfFieldEffect** | Blurs what is out of focus: `FocusDistance`, `InFocusRadius`, `NearIntensity`, `FarIntensity` | Same parenting. Docs say it can focus attention on an item. Animating focus onto a subject during a reveal is our suggestion |
| **BloomEffect** | Glow: `Intensity`, `Size`, `Threshold` | Multiple bloom effects combine. Good for the soft peak of a reveal |
| **ColorCorrectionEffect** | Brightness, contrast, saturation, tint | Not read this session (from my own knowledge of the API; verify). Use for a gentle tint or desaturate, not a flash |
| **SunRaysEffect, Atmosphere** | Light shafts, haze | Atmosphere is a separate object in Lighting |
| **Trail, Beam, ParticleEmitter** | Streaks and glow in 3D | See [[Animation and Juice Playbook]] for emitter limits (mobile rate cap 100/s) |

**There is no built-in motion blur and no directional blur.** The DevForum has long-standing requests for one, and community scripts fake it. Honest options, from simplest to most work:

1. **Blur transition (best for loading and reveals).** Tween `BlurEffect.Size` from 0 up to about 12 to 24 and back with an eased curve while a UI fades or moves. This is the effect most polished Roblox games use for transitions. **Parent it to the camera, not Lighting**: a DevForum reply on a loading-screen thread notes that blur added to Lighting can persist, and camera-parented ones are easier to clean up.
2. **Camera-speed blur.** Each frame, measure how fast the camera turns, convert to a blur size, **smooth it** (exponential smoothing), clamp it to a small maximum, and set one shared `BlurEffect.Size`. Existing community scripts do this from the camera's look vector change. Limit: it only reacts to **camera** motion, not to objects that move while the camera is still, and it is a uniform blur, not directional.
3. **Focus pull.** Tween `DepthOfField.FocusDistance` and `InFocusRadius` to shift attention to the subject during a reveal; the background softens without a global blur.
4. **UI motion blur (our technique, untested).** For a UI element that moves fast, draw 2 or 3 faint "echo" copies behind it along its path with decreasing transparency, plus a slight stretch along the motion axis, then fade the echoes out as it settles. Combine with a short `UIGradient` streak.
5. **3D motion streaks.** `Trail` and `Beam` behind fast props, with a gradient from solid to transparent.

Rules for blur: keep it **short** (about 0.4 to 0.8 s peak-to-clear), **eased** (never snapped), **capped** (about 10 on a phone, about 24 on desktop; convention), and **removed** when the setting says so. With **Flashes Off or Reduced motion**, replace blur pulses with a slow fade and cap Size lower.

## 3. Loading screen with blur (Rivals-style recipe, unverified match)
Official pattern ([Loading screens](https://create.roblox.com/docs/players/loading-screens)): put a LocalScript in `ReplicatedFirst`, call `ReplicatedFirst:RemoveDefaultLoadingScreen()`, build a ScreenGui, keep it up for a minimum time, wait for `game:IsLoaded()` or `game.Loaded`, then remove it. Animate with TweenService.

Our smooth version:
1. **Intro (0 to 0.6 s):** the world is blurred (BlurEffect on the camera, Size 24) and slightly dark; logo fades and scales up 0.95 to 1 with ease-out.
2. **Progress:** a thin bar whose fill **eases toward the real progress** (exponential smoothing), never jumping; a tip text that crossfades.
3. **Outro (0.5 to 0.7 s):** the UI fades and drifts out while the blur eases 24 to 0 with Exponential Out, then the BlurEffect is destroyed.
4. Minimum display time short (about 1.5 to 2 s) so it does not feel slow; the DevForum notes players see the loading screen for about 1 to 2 s anyway.
5. Honor Reduced motion: no scale, only a fade; cap blur lower.

## 4. Code recipes (Luau, **untested in Studio**)
Frame-rate independent smoothing (use for bars, camera blur, follow motion):
```lua
-- rate: higher = snappier. current moves toward target the same speed at any frame rate.
local function smooth(current, target, rate, dt)
	return current + (target - current) * (1 - math.exp(-rate * dt))
end
```

A small damped spring (sub-stepped so it stays stable; frequency in Hz, damping ratio 1 = no overshoot):
```lua
local function springStep(pos, vel, target, freq, damping, dt)
	local w = 2 * math.pi * freq
	local steps = math.max(1, math.ceil(dt / (1 / 240)))
	local h = dt / steps
	for _ = 1, steps do
		local accel = w * w * (target - pos) - 2 * damping * w * vel
		vel += accel * h
		pos += vel * h
	end
	return pos, vel
end
```
(`spr` and similar community modules exist; I could not confirm their licences, so we write our own.)

Blur transition, parented to the camera and cleaned up:
```lua
local TweenService = game:GetService("TweenService")

local function blurTransition(peak, inTime, holdTime, outTime)
	local blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = workspace.CurrentCamera
	local up = TweenService:Create(blur, TweenInfo.new(inTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = peak })
	local down = TweenService:Create(blur, TweenInfo.new(outTime, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { Size = 0 })
	up:Play()
	up.Completed:Wait()
	task.wait(holdTime)
	down:Play()
	down.Completed:Wait()
	blur:Destroy()
end
```

Camera-speed blur (one shared effect, smoothed, clamped):
```lua
local RunService = game:GetService("RunService")
local cam = workspace.CurrentCamera
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = cam
local last = cam.CFrame.LookVector
local size = 0
RunService.RenderStepped:Connect(function(dt)
	local look = cam.CFrame.LookVector
	local speed = (look - last).Magnitude / math.max(dt, 1 / 240) -- how fast the view turns
	last = look
	local target = math.clamp(speed * 3, 0, 8) -- small cap; tune by eye
	size = size + (target - size) * (1 - math.exp(-12 * dt))
	blur.Size = size
end)
```
Note: only one BlurEffect applies (largest Size wins), so reveal blur and camera-speed blur can coexist, but the bigger one dominates.

## 5. Reveal timeline with blur (for the rarity tiers in [[Magical Roll Animation Playbook]])
| Tier | Blur and motion |
|---|---|
| Common | None. A soft scale-pop and a glow fade (under 1 s) |
| Rare | Tiny blur pulse (Size 0 to 6 to 0, about 0.5 s) with the ring rising |
| Epic | Blur 0 to 12 while light gathers (0.6 s), focus pull onto the pet, release with Exponential Out (0.5 s) |
| Legendary | Darken and blur 0 to 18 (0.6 s ease-in-out), hold while particles gather (0.8 s), burst: bloom rises (not a flash) while blur clears 18 to 0 (0.5 s Exponential Out), then the title eases in and the camera drifts |
With **Flashes Off / Reduced motion:** cap blur at 8, replace the bloom spike with a slow rise, no fast oscillation.

## 6. Elegance checklist (apply to every animation we add)
- [ ] Every property change is eased or sprung; nothing snaps.
- [ ] Entrances ease-out, exits ease-in, moves ease-in-out.
- [ ] Fast moves have a softening (echo, streak, blur, or fade tail).
- [ ] Children are staggered, not simultaneous.
- [ ] No brightness or blur jump larger than a smooth ramp; no strobing.
- [ ] Looks the same at 30 and 60 fps (dt-based).
- [ ] Respects Flashes, Particles and Reduced motion settings.
- [ ] Checked on a real low-end phone with post-processing on.

## Gaps
- Rivals' real loading animation unseen (needs your stills or clip).
- Not verified: ColorCorrectionEffect details, whether a BlurEffect blurs ScreenGui UI (I believe UI draws on top and stays sharp; check in Studio), frame-rate behaviour of community spring modules, mobile cost of BlurEffect and DepthOfField.
- No code here has run in Studio.

## Measured in Studio (2026-10-25, correction to the Gaps above)
- **BlurEffect does not blur ScreenGui UI.** With a BlurEffect of Size 24 parented to `workspace.CurrentCamera`, the 3D world was heavily blurred and a ScreenGui TextLabel stayed perfectly sharp (still: `VFX Renders/blur-test-ui-stays-sharp.jpg`). So title cards and HUD stay readable during a blur pulse, and a UI that should blur needs its own trick (fade or echo copies).
- **Parenting to the camera works** and cleans up: after `cancel()` no BlurEffect was left on the camera.
- **Strong blur hides the hero prop.** At Size 14 the hanging sword in the Ultimate became unreadable at normal viewing size; 8 keeps its shape while still softening the world. Use the high values for gathering light, not while the player must read a prop.
- Implemented in `VFX/RevealFX.luau` as `blur(peak, rise, hold, fall)`: Quint out in, Exponential out; cap 24 desktop, 10 touch; with Flashes off or Reduced motion the cap is 8 and ramps are at least 0.6 s in, 0.8 s out. The headless audit checks all of this. Not measured: mobile cost of BlurEffect, ColorCorrection edge cases, real frame rate.
- Not checked against Rivals (no stills yet): this is our own blur transition, not a copy. The user liked Rivals' loading blur; please add `rivals-*` stills or a short clip to `Research/`.

## Measured blur curves (2026-10-25, LoadingFX at real speed)
Resolving 18 to 0 over 0.9 s: **Exponential Out** is very front-loaded (4.1 left after 0.2 s, clear by 0.5 s) and reads as a snap; **Quad Out** gave a steady, flattening curve (14.7, 11.1, 8.6, 5.8, 3.7, 2.3, 1.0, 0.2 at 0.1 s steps) that matches the Rivals sharpness ramp better. Use Quad Out for a blur handoff; keep Quint or Exponential for things that should feel instant. Blur ramp-up with Quint Out reached 98% of peak in 0.37 s.
