# Animation and Juice Playbook

Researched 2026-10-24. The point of good UI is to give good animations somewhere to happen: every panel, button, number, and reward needs a clear state change to animate. Related: [[Screenshot Analysis]], [[UI Design Playbook]], [[Low-End Device Playbook]], [[Engagement Loop Playbook]]

## Source quality

- **Official:** [UI animation](https://create.roblox.com/docs/ui/animation) (TweenService, easing styles, sequences, CanvasGroup), [Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers), [UI and UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design).
- **Reasonable (industry article):** [GameAnalytics: Squeezing more juice out of your game design](https://www.gameanalytics.com/blog/squeezing-more-juice-out-of-your-game-design).
- **Weak:** other game-feel pages from search (community "skill" pages and blogs). Their specific millisecond ranges below are conventions, not standards. Test them on your own game.
- **Not researched:** character and tool animation (Animation Editor, rigs). Only UI and feedback animation are covered here.

## Principles

1. **Respond to every input, instantly.** Hover, press, release, purchase, error. Missing feedback makes players think something is broken (official).
2. **Ease, don't glide.** Appearing UI should ease out so it decelerates into place. Avoid pure linear motion for movement (GameAnalytics). Roblox lists Linear, Sine, Quad (default), Cubic, Quart, Quint, Exponential, Circular, Back, Bounce, Elastic, with In / Out / InOut directions.
3. **Scale the juice to how often it happens.** The more common the action, the simpler its feedback. A tap that happens 5 times a second gets a tiny pop; a rare Mythical hatch gets a full celebration (GameAnalytics).
4. **Juice should echo the core mechanic.** Bouncy, elastic effects suit a tapping game; they don't suit every game.
5. **Anticipation and follow-through.** A short wind-up before the payoff, and a small overshoot that settles. This is what makes a chest opening or a button press feel weighty. (Common animation principle; the sources I found agree but are third-party.)
6. **Rough timing guide (convention, test it):** roughly 50 to 200 ms for feedback, 500 to 2000 ms for celebratory moments, and a hit-pause of about 50 to 100 ms on big impacts.
7. **Restraint.** Official guidance: use motion sparingly for attention (a pulsing arrow in tutorials). Too much overwhelms. Keep screen shake small.
8. **Sound is half of it.** Every interaction gets clear, full-feeling audio. Casual games suit happy, rewarding tones (GameAnalytics).

## What the screenshots animate (and what each needs)

From [[Screenshot Analysis]]. For each, the UI needs the listed parts in place so animation is possible.

| Moment | Likely animation | UI parts needed |
|---|---|---|
| Open a menu | Backdrop blur/dim fades in, panel pops in (scale 0.85 to 1, ease Back Out) | Dimmer frame, panel with `UIScale`, `CanvasGroup` for fade |
| Press a button | Squash to 0.92, spring back, click sound | `UIScale` on each button |
| Currency changes | Number counts up, small "+6" floats up and fades, counter pulses | Separate label for counter, template for floating text |
| Claim a reward (welcome back, offline earnings) | Coin shower, big number counts up, claim button pulses | Particle/coin template pool, count-up function |
| New notification | Badge pops with overshoot, red bubble bobs | Badge frame with `UIScale`, looping gentle tween |
| Progress bar | Fill tweens to new value, small flash at the end | Fill frame sized by Scale, `UIGradient` |
| Rare reveal (egg hatch) | Anticipation shake, flash, item scales in, rarity-colored burst | Full-screen overlay, rarity color table |
| Countdown reaching zero | Number pulses red in the last 10 s | Label + text color tween |
| Locked item tapped | Quick horizontal wiggle, lock icon pulse, tooltip with reason | `UIScale` or `Position` tween, tooltip |
| Tutorial arrow | Chevrons slide along the path in sequence (the screenshots show this) | Part with `Decal` or `BillboardGui`, looping tween |

## Luau recipes (examples I wrote, **not tested in Studio**)

Put UI animation in LocalScripts or client modules. Per Roblox's performance guide, tween on the client, not the server.

Pop-in for a modal:

```lua
local TweenService = game:GetService("TweenService")

local function popIn(panel: GuiObject, group: CanvasGroup, scale: UIScale)
	scale.Scale = 0.85
	group.GroupTransparency = 1
	local info = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(scale, info, { Scale = 1 }):Play()
	TweenService:Create(group, TweenInfo.new(0.15), { GroupTransparency = 0 }):Play()
end
```

Count-up number (for reward totals):

```lua
local RunService = game:GetService("RunService")

local function countUp(label: TextLabel, from: number, to: number, duration: number)
	local start = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - start) / duration, 0, 1)
		local eased = 1 - (1 - t) ^ 3 -- ease out cubic
		label.Text = tostring(math.floor(from + (to - from) * eased))
		if t >= 1 then
			conn:Disconnect()
		end
	end)
end
```

Notes: the connection is disconnected when done (Roblox's guide says active connections are never garbage collected). Only run frame-rate code while the animation is playing. Use a number formatter (1.2K, 3.4M, 13.66T) for the display, as the screenshots do.

Floating "+N" text: clone a template `TextLabel`, tween `Position` up by a small Scale amount and `TextTransparency` to 1 over about 0.6 s, then destroy it. Reuse a small pool instead of creating a new label for every tap on fast loops.

## Rules from the official docs

- Tween `Position` and `Size` with **Scale**, and set `AnchorPoint` first.
- Wrap a whole panel in a `CanvasGroup` and tween `GroupTransparency` to fade it as one piece.
- Chain animations with the tween's `Completed` event.
- **Don't tween the thickness of a text `UIStroke`.** It can flicker or hurt performance. Tween color, transparency, or scale instead.
- Typewriter text: step `MaxVisibleGraphemes`.
- Respect players' reduced-motion needs: keep a setting that turns off shake, flashing, and big bounces. (The screenshots' settings screens show this kind of customization is normal. Roblox's accessibility page is the place to read the details; I haven't read it.)

## Animation build order

1. Build one `UIAnimator` module with `press`, `popIn`, `popOut`, `shake`, `pulse`, `countUp`, and `floatText`. Every screen uses it.
2. Add sounds to the same module so animation and audio stay in sync.
3. Add a reduced-motion switch that the module checks.
4. Profile on a phone ([[Low-End Device Playbook]]) before adding particles.

## Gaps

- Character, tool, and NPC animation not researched.
- No official Roblox page on particle best practices beyond the performance notes.
- Sound design sources not researched.
