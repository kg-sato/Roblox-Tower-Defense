--!nocheck
-- RevealFX: rarity-tier reveal effects (Common < Rare < Epic < Legendary). Standalone: no gameplay code, no UIKit.
-- Client-side only. Source of truth is VFX/RevealFX.luau; installed as ReplicatedStorage.RevealFX.
--
--   local RevealFX = require(game.ReplicatedStorage.RevealFX)
--   local h = RevealFX.play("Legendary", { position = Vector3.new(0, 4, 0), name = "Crowned", odds = "1 in 20,000", modifier = "Gilded" })
--   h.cancel()                       -- stops everything and cleans up
--   RevealFX.setSettings({ flashes = false, particles = "Low", reducedMotion = true, skipTier = "Common" })
--   RevealFX.preview("Epic")         -- plays at the player (or a fixed point) with the live settings
--   RevealFX.audit()                 -- builds every tier x settings combination headless, returns a report with limits checked
--
-- Settings follow the Game Design Doc "Display and accessibility" spec:
--   flashes        true/false. false: no brightness spike; flashes become a slow soft colour tint (max 0.22, rise >= 0.5 s).
--   particles      "Low" / "Default" / "High" = x0.25 / x1 / x1.5 on emitter rates, burst counts and orbiting props.
--                  Every ParticleEmitter Rate is also capped at 100/s on touch devices and 400/s elsewhere (Roblox limits).
--   reducedMotion  true: no camera push, no orbiting props, no spinning; things fade instead of scaling.
--   skipTier       nil or a tier name. A reveal at or below that tier plays only a 0.3 s name card.
-- Textures are loaded from RevealFX.textures (dev preview paths; swap for uploaded asset ids). Missing textures just
-- render blank: the effect still shows through Neon parts, beams and the title card.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local RevealFX = {}

RevealFX.textures = {
	glow = "rbxasset://textures/vfx/vfx_glow.png",
	ring = "rbxasset://textures/vfx/vfx_ring.png",
	rune = "rbxasset://textures/vfx/vfx_rune.png",
	streak = "rbxasset://textures/vfx/vfx_streak.png",
	flare = "rbxasset://textures/vfx/vfx_flare.png",
	sigil = "rbxasset://textures/vfx/vfx_sigil.png",
	crack = "rbxasset://textures/vfx/vfx_crack.png",
	sword = "rbxasset://textures/vfx/vfx_sword.png",
	ink = "rbxasset://textures/vfx/vfx_ink.png",
	swirl = "rbxasset://textures/vfx/vfx_swirl.png",
}

RevealFX.settings = { flashes = true, particles = "Default", reducedMotion = false, skipTier = nil }

local ORDER = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Celestial = 6, Ultimate = 7 }
RevealFX.order = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Celestial", "Ultimate" }

-- palette per tier: one hero colour, one near-white highlight, one dark base (playbook pattern 1)
RevealFX.tiers = {
	Common = { color = Color3.fromRGB(215, 222, 235), accent = Color3.fromRGB(255, 255, 255), length = 0.9, odds = "1 in 2" },
	Rare = { color = Color3.fromRGB(60, 150, 255), accent = Color3.fromRGB(190, 225, 255), length = 1.5, odds = "1 in 20" },
	Epic = { color = Color3.fromRGB(170, 90, 255), accent = Color3.fromRGB(235, 205, 255), length = 3.0, odds = "1 in 500" },
	Legendary = { color = Color3.fromRGB(255, 190, 40), accent = Color3.fromRGB(255, 244, 205), length = 5.6, odds = "1 in 20,000" },
	-- medieval-magic ultimate: royal gold on a night-blue world, holy white-blue steel
	Ultimate = { color = Color3.fromRGB(255, 196, 60), accent = Color3.fromRGB(205, 228, 255), length = 7.6, odds = "ULTIMATE" },
	-- T057: the two top rarities have their own reveal (colours match FXRecipes.RAMP and Config.RARITIES) and a lore line under the title.
	-- Odds are the luck-0 rarity odds from the design (Mythic 0.40%, Celestial 0.08%); RevealSection passes the exact figure in opts.odds.
	Mythic = { color = Color3.fromRGB(255, 130, 195), accent = Color3.fromRGB(255, 226, 240), length = 6.6, odds = "1 in 250", lore = "A name the lamps keep for themselves." },
	Celestial = { color = Color3.fromRGB(150, 245, 255), accent = Color3.fromRGB(235, 252, 255), length = 8.4, odds = "1 in 1,250", lore = "Light that learned to walk." },
}

local MULT = { Low = 0.25, Default = 1, High = 1.5 }
local WHITE = Color3.new(1, 1, 1)

local function mergedSettings(over)
	local s = {}
	for k, v in pairs(RevealFX.settings) do
		s[k] = v
	end
	if over then
		for k, v in pairs(over) do
			s[k] = v
		end
	end
	if MULT[s.particles] == nil then
		s.particles = "Default"
	end
	return s
end

function RevealFX.setSettings(t)
	for k, v in pairs(t) do
		RevealFX.settings[k] = v
	end
end

local function rateCap(opts)
	if opts and opts.forceTouch ~= nil then
		return opts.forceTouch and 100 or 400
	end
	return UserInputService.TouchEnabled and 100 or 400
end

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do
		i[k] = v
	end
	i.Parent = parent
	return i
end

local function defaultPosition()
	local lp = Players.LocalPlayer
	local char = lp and lp.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		return root.Position - Vector3.new(0, 2.8, 0)
	end
	return Vector3.new(0, 4, 0)
end

---------------------------------------------------------------------------------------------------
-- play
---------------------------------------------------------------------------------------------------
-- opts: position (ground point), name, odds, modifier, settings (overrides), timeScale (slow motion, for stills),
--       forceTouch (test the 100/s cap), headless (no GUI/world: used by audit), sfx = function(name), onDone
function RevealFX.play(tier, opts)
	opts = opts or {}
	local def = RevealFX.tiers[tier]
	assert(def, "unknown tier " .. tostring(tier))
	local S = mergedSettings(opts.settings)
	local ts = opts.timeScale or 1
	local mult = MULT[S.particles]
	local cap = rateCap(opts)
	local color, accent = def.color, def.accent
	if tier == "Legendary" and opts.idea == "Ink" then
		color, accent = Color3.fromRGB(70, 230, 140), Color3.fromRGB(215, 255, 230)
	elseif tier == "Legendary" and opts.idea == "Vortex" then
		color, accent = Color3.fromRGB(255, 200, 70), Color3.fromRGB(255, 244, 205)
	end
	local pos = opts.position or defaultPosition()
	-- cues: every sound cue goes through here so its time is logged (stats.cues) and a sound module can play it
	local rawSfx = opts.sfx or RevealFX.defaultSfx or function() end
	local cueLog, cueT0 = {}, os.clock()
	local function sfx(name, len, pitch)
		table.insert(cueLog, { name = name, t = (os.clock() - cueT0) * (opts.timeScale or 1) })
		rawSfx(name, len, pitch)
	end
	local tex = RevealFX.textures

	local stats = { tier = tier, emitters = 0, peakRate = 0, totalRate = 0, burstTotal = 0, flashes = 0, softTints = 0, blurPeak = 0, minBlurRise = math.huge, bloomPeak = 0, minBloomRise = math.huge, maxFlashPeak = 0, minRise = math.huge, props = 0, skipped = false }
	stats.cues = cueLog
	local handle = { stats = stats, done = false }
	local alive = true
	local folder = new("Folder", { Name = "RevealFX_" .. tier }, workspace)
	local conns, tweens, extras = {}, {}, {}

	local function T(x)
		return x / ts
	end
	local function at(t, fn)
		if opts.headless then
			fn() -- audit mode: run every scheduled step at once so its limits are counted
			return
		end
		task.delay(T(t), function()
			if alive then
				fn()
			end
		end)
	end
	local function tw(inst, dur, props, style, dir)
		local t = TweenService:Create(inst, TweenInfo.new(T(dur), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
		t:Play()
		table.insert(tweens, t)
		return t
	end

	local lightingBackup -- original Lighting values, set by darken(), restored by cleanup()
	local function cleanup()
		if handle.done then
			return
		end
		handle.done = true
		alive = false
		pcall(function()
			RunService:UnbindFromRenderStep(shakeName)
		end)
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		for _, t in ipairs(tweens) do
			t:Cancel()
		end
		if lightingBackup then
			for k, v in pairs(lightingBackup) do
				Lighting[k] = v
			end
		end
		if handle._camBase and workspace.CurrentCamera then
			workspace.CurrentCamera.FieldOfView = handle._camBase
		end
		for _, e in ipairs(extras) do
			if e.Parent then
				e:Destroy()
			end
		end
		folder:Destroy()
		if opts.onDone then
			opts.onDone()
		end
	end
	handle.cancel = cleanup

	-- ---- budget helpers -------------------------------------------------------------------------
	local function emitterProps(rate, p)
		local r = math.clamp(math.floor(rate * mult), 0, cap)
		stats.emitters += 1
		stats.totalRate += r
		stats.peakRate = math.max(stats.peakRate, r)
		p.Rate = r
		return p
	end
	local function burstCount(n)
		local c = math.max(1, math.min(math.floor(n * mult), cap))
		stats.burstTotal += c
		return c
	end

	-- ---- screen layer ----------------------------------------------------------------------------
	local gui, dim, wash, titleBox, cc, bloom
	if not opts.headless then
		local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
		gui = new("ScreenGui", { Name = "RevealFX_UI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 60, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, pg)
		table.insert(extras, gui)
		dim = new("Frame", { Name = "Dim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0 }, gui)
		wash = new("Frame", { Name = "Wash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 }, gui)
		cc = new("ColorCorrectionEffect", { Name = "RevealFX_CC" }, Lighting)
		table.insert(extras, cc)
		bloom = new("BloomEffect", { Name = "RevealFX_Bloom", Intensity = 0, Size = 24, Threshold = 1 }, Lighting)
		table.insert(extras, bloom)
	end

	-- A flash is a fast white spike; with Flashes off it becomes a slow, low, coloured tint (no brightness spike).
	local function flash(peak, rise, hold, fall, tint)
		if opts.headless then
			if S.flashes then
				stats.flashes += 1
				stats.maxFlashPeak = math.max(stats.maxFlashPeak, peak)
				stats.minRise = math.min(stats.minRise, rise)
			else
				stats.softTints += 1
				stats.minRise = math.min(stats.minRise, math.max(rise, 0.5))
			end
			return
		end
		if S.flashes then
			stats.flashes += 1
			stats.maxFlashPeak = math.max(stats.maxFlashPeak, peak)
			stats.minRise = math.min(stats.minRise, rise)
			wash.BackgroundColor3 = WHITE
			wash.BackgroundTransparency = 1
			tw(wash, rise, { BackgroundTransparency = 1 - peak })
			at(rise + hold, function()
				tw(wash, fall, { BackgroundTransparency = 1 })
			end)
		else
			stats.softTints += 1
			local soft, srise = math.min(peak, 0.22), math.max(rise, 0.5)
			stats.minRise = math.min(stats.minRise, srise)
			wash.BackgroundColor3 = tint or color
			wash.BackgroundTransparency = 1
			tw(wash, srise, { BackgroundTransparency = 1 - soft }, Enum.EasingStyle.Sine)
			at(srise + hold, function()
				tw(wash, fall * 1.5, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
			end)
		end
	end

	-- ---- world pieces ----------------------------------------------------------------------------
	local anchor = new("Part", { Name = "Anchor", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) }, folder)
	local function attachment(offset)
		return new("Attachment", { Position = offset or Vector3.zero }, anchor)
	end
	local spinners = {}

	-- flat texture quad lying on the ground (or raised): ring, rune circle, glow
	local function disc(texName, d0, d1, dur, o)
		if opts.headless then
			return nil
		end
		o = o or {}
		if S.reducedMotion then
			d0 = d1 -- reduced motion: fade in place instead of growing
		end
		local p = new("Part", { Name = "Disc_" .. texName, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(d0, 0.05, d0), CFrame = CFrame.new(pos + Vector3.new(0, o.height or 0.15, 0)) * CFrame.Angles(0, math.rad(o.rot or 0), 0) }, folder)
		local decal = new("Decal", { Face = Enum.NormalId.Top, Texture = tex[texName], Color3 = o.color or color, Transparency = o.from or 1 }, p)
		local decalBottom = new("Decal", { Face = Enum.NormalId.Bottom, Texture = tex[texName], Color3 = o.color or color, Transparency = o.from or 1 }, p)
		tw(p, dur, { Size = Vector3.new(d1, 0.05, d1) }, o.style or Enum.EasingStyle.Quad)
		tw(decal, o.fadeIn or dur * 0.3, { Transparency = o.to or 0.1 })
		tw(decalBottom, o.fadeIn or dur * 0.3, { Transparency = o.to or 0.1 })
		if o.fadeOutAt then
			at(o.fadeOutAt, function()
				tw(decal, o.fadeOutDur or 0.6, { Transparency = 1 })
				tw(decalBottom, o.fadeOutDur or 0.6, { Transparency = 1 })
			end)
		end
		if o.spin and not S.reducedMotion then
			table.insert(spinners, { part = p, speed = o.spin })
		end
		return p
	end

	local function sparkles(rate, p)
		p = emitterProps(rate, p)
		local e = new("ParticleEmitter", {
			Texture = tex.flare, Color = ColorSequence.new(accent, color), LightEmission = 1, LightInfluence = 0,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, p.size or 1.4), NumberSequenceKeypoint.new(1, 0) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(p.life or 0.9, (p.life or 0.9) * 1.5), Speed = NumberRange.new(p.speed or 6, (p.speed or 6) * 1.6),
			SpreadAngle = Vector2.new(p.spread or 40, p.spread or 40), Acceleration = p.accel or Vector3.new(0, 4, 0),
			Rate = p.Rate, Enabled = p.Rate > 0 and not p.burstOnly, TimeScale = ts, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60, 60),
			EmissionDirection = p.dir or Enum.NormalId.Top, Parent = p.parent or anchor,
		})
		if p.shape then
			e.Shape = p.shape
			e.ShapeInOut = p.inout or Enum.ParticleEmitterShapeInOut.Outward
			e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		end
		return e
	end

	local function emit(e, n)
		e:Emit(burstCount(n))
	end

	local function pillar(h, w, dur, hold, tcolor, off)
		off = off or Vector3.zero
		local p = new("Part", { Name = "Pillar", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Material = Enum.Material.Neon, Color = tcolor or color, Transparency = 1, Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, S.reducedMotion and w or 0.4, S.reducedMotion and w or 0.4), CFrame = CFrame.new(pos + off + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)) }, folder)
		tw(p, dur * 0.35, { Transparency = 0.4, Size = Vector3.new(h, w, w) })
		at(dur * 0.35 + hold, function()
			tw(p, dur * 0.65, { Transparency = 1, Size = Vector3.new(h, w * 0.2, w * 0.2) })
		end)
	end

	local function beam(offset, height, width, dur, hold)
		local a0 = attachment(offset)
		local a1 = new("Attachment", { Position = offset + Vector3.new(0, height, 0) }, anchor)
		local b = new("Beam", { Attachment0 = a0, Attachment1 = a1, Texture = tex.streak, TextureMode = Enum.TextureMode.Stretch, Color = ColorSequence.new(accent, color), LightEmission = 1, LightInfluence = 0, Width0 = 0.1, Width1 = 0.1, FaceCamera = true, Transparency = NumberSequence.new(1) }, anchor)
		local v = Instance.new("NumberValue")
		table.insert(extras, v)
		v.Value = 0
		conns[#conns + 1] = v.Changed:Connect(function(x)
			b.Width0, b.Width1 = width * x, width * x * 0.6
			b.Transparency = NumberSequence.new(1 - 0.85 * x)
		end)
		tw(v, dur, { Value = 1 })
		at(dur + hold, function()
			tw(v, dur * 1.2, { Value = 0 })
		end)
	end

	-- soft glowing motes orbiting the subject (sprites on billboards: no blocky geometry)
	local function orbitProps(n, radius, height, life, size)
		if S.reducedMotion then
			return
		end
		n = math.max(2, math.floor(n * mult))
		stats.props += n
		if opts.headless then
			return
		end
		local orbs = {}
		for i = 1, n do
			local p = new("Part", { Name = "Mote", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(pos) }, folder)
			local bb = new("BillboardGui", { Adornee = p, Size = UDim2.fromScale(size * 3.4, size * 3.4), LightInfluence = 0, AlwaysOnTop = false, MaxDistance = 1000000 }, p)
			local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = tex.flare, ImageColor3 = i % 2 == 0 and accent or color, ImageTransparency = 1 }, bb)
			tw(img, 0.5, { ImageTransparency = 0.05 }, Enum.EasingStyle.Sine)
			orbs[i] = { part = p, img = img }
		end
		local t0 = os.clock()
		local c
		c = RunService.Heartbeat:Connect(function()
			if not alive then
				c:Disconnect()
				return
			end
			local t = (os.clock() - t0) * ts
			local grow = 1 - (1 - math.clamp(t / 0.9, 0, 1)) ^ 3
			for i, o in ipairs(orbs) do
				local a = t * 1.5 + i * math.tau / n
				local r = radius * grow
				o.part.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * r, height + math.sin(t * 2 + i) * 0.5, math.sin(a) * r))
			end
		end)
		table.insert(conns, c)
		at(life, function()
			for _, o in ipairs(orbs) do
				tw(o.img, 0.6, { ImageTransparency = 1 }, Enum.EasingStyle.Sine)
			end
		end)
	end

	local function blur(peak, rise, hold, fall)
		local softMode = (not S.flashes) or S.reducedMotion
		local limit = cap == 100 and 10 or 24
		if softMode then
			limit = math.min(limit, 8)
			rise, fall = math.max(rise, 0.6), math.max(fall, 0.8)
		end
		peak = math.min(peak, limit)
		stats.blurPeak = math.max(stats.blurPeak, peak)
		stats.minBlurRise = math.min(stats.minBlurRise, rise)
		local cam = workspace.CurrentCamera
		if opts.headless or not cam then
			return
		end
		if not blurFx then
			blurFx = new("BlurEffect", { Name = "RevealFX_Blur", Size = 0 }, cam)
			table.insert(extras, blurFx)
		end
		tw(blurFx, rise, { Size = peak }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		at(rise + hold, function()
			tw(blurFx, fall, { Size = 0 }, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
		end)
	end

	local function tint(amount, rise, hold, fall)
		if opts.headless or not cc then
			return
		end
		local mix = S.flashes and 1 or 0.6
		local goal = color:Lerp(WHITE, 1 - amount * mix)
		tw(cc, rise, { TintColor = goal, Saturation = 0.15 * mix }, Enum.EasingStyle.Sine)
		at(rise + hold, function()
			tw(cc, fall, { TintColor = WHITE, Saturation = 0 }, Enum.EasingStyle.Sine)
		end)
	end

	-- Darkens the WORLD (night clock, dim ambient light) and only lightly the screen, so Neon parts, beams and
	-- additive particles keep their full brightness. A UI overlay would dim the effects themselves.

	local function darken(amount, rise, hold, fall)
		if opts.headless then
			return
		end
		if not lightingBackup then
			lightingBackup = { ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
		end
		local b = lightingBackup
		local night = Color3.fromRGB(26, 32, 70)
		tw(Lighting, rise, { ClockTime = 23.5, Brightness = b.Brightness * (1 - 0.7 * amount), Ambient = b.Ambient:Lerp(night, amount * 1.2), OutdoorAmbient = b.OutdoorAmbient:Lerp(night, amount * 1.2) }, Enum.EasingStyle.Sine)
		tw(dim, rise, { BackgroundTransparency = 1 - amount * 0.35 }, Enum.EasingStyle.Sine)
		at(rise + hold, function()
			tw(Lighting, fall, { ClockTime = b.ClockTime, Brightness = b.Brightness, Ambient = b.Ambient, OutdoorAmbient = b.OutdoorAmbient }, Enum.EasingStyle.Sine)
			tw(dim, fall, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
		end)
	end

	local function cameraPush(fovDelta, rise, fall)
		local cam = workspace.CurrentCamera
		if opts.headless or S.reducedMotion or not cam or opts.camera == false then
			return
		end
		local base = handle._camBase or cam.FieldOfView
		tw(cam, rise, { FieldOfView = base - fovDelta }, Enum.EasingStyle.Quad)
		at(rise, function()
			tw(cam, fall, { FieldOfView = base }, Enum.EasingStyle.Sine)
		end)
		handle._camBase = handle._camBase or base
	end


	-- ---- ultimate helpers ---------------------------------------------------------------------
	local shakeName = "RevealFXShake" .. tostring(math.random(1, 1000000000))
	local function shake(amp, dur)
		local cam = workspace.CurrentCamera
		if opts.headless or S.reducedMotion or opts.camera == false or not cam then
			return
		end
		local t0 = os.clock()
		RunService:BindToRenderStep(shakeName, Enum.RenderPriority.Camera.Value + 20, function()
			local t = (os.clock() - t0) * ts
			if t > dur or not alive then
				RunService:UnbindFromRenderStep(shakeName)
				return
			end
			local k = (1 - t / dur) ^ 2 * amp
			cam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * k, (math.random() - 0.5) * k, 0) * CFrame.Angles(0, 0, (math.random() - 0.5) * k * 0.012)
		end)
	end

	-- cinematic bars slide in at the top and bottom (static when Reduced motion is on)
	local function bars(inDur, holdFor, outDur)
		if opts.headless then
			return
		end
		local top = new("Frame", { Name = "BarTop", Size = UDim2.fromScale(1, 0.1), Position = UDim2.fromScale(0, S.reducedMotion and 0 or -0.1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 3 }, gui)
		local bot = new("Frame", { Name = "BarBottom", Size = UDim2.fromScale(1, 0.1), Position = UDim2.fromScale(0, S.reducedMotion and 0.9 or 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 3 }, gui)
		if not S.reducedMotion then
			tw(top, inDur, { Position = UDim2.fromScale(0, 0) }, Enum.EasingStyle.Quad)
			tw(bot, inDur, { Position = UDim2.fromScale(0, 0.9) }, Enum.EasingStyle.Quad)
			at(inDur + holdFor, function()
				tw(top, outDur, { Position = UDim2.fromScale(0, -0.1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				tw(bot, outDur, { Position = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end)
		end
	end

	-- A smooth painted sword (sprite on a camera-facing billboard), tip down. h = height in studs.
	-- Returns the anchor part (move its CFrame), the distance from its centre to the tip, and the image list.
	local function buildSword(h)
		local p = new("Part", { Name = "SwordAnchor", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(pos) }, folder)
		local bb = new("BillboardGui", { Name = "Sword", Adornee = p, Size = UDim2.fromScale(h / 3, h), AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 1000000 }, p)
		local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = tex.sword, ImageTransparency = 1 }, bb)
		return p, h * 0.5 * 0.96, { img }
	end

	local function setImgAlpha(imgs, from, to, dur, style)
		for _, i in ipairs(imgs) do
			i.ImageTransparency = from
			tw(i, dur, { ImageTransparency = to }, style or Enum.EasingStyle.Sine)
		end
	end

	-- small spectral swords circling the impact point
	local function orbitSwords(n, radius, height, life)
		if S.reducedMotion then
			return
		end
		n = math.max(2, math.floor(n * mult))
		stats.props += n
		if opts.headless then
			return
		end
		local swords = {}
		for i = 1, n do
			local part, _, imgs = buildSword(8)
			setImgAlpha(imgs, 1, 0.1, 0.6)
			swords[i] = { part = part, imgs = imgs }
		end
		local t0 = os.clock()
		local c
		c = RunService.Heartbeat:Connect(function()
			if not alive then
				c:Disconnect()
				return
			end
			local t = (os.clock() - t0) * ts
			local grow = 1 - (1 - math.clamp(t / 1.1, 0, 1)) ^ 3
			for i, sw in ipairs(swords) do
				local a = t * 0.8 + i * math.tau / n
				local r = radius * grow
				sw.part.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * r, height + math.sin(t * 1.4 + i * 2) * 0.8, math.sin(a) * r))
			end
		end)
		table.insert(conns, c)
		at(life, function()
			for _, sw in ipairs(swords) do
				for _, i in ipairs(sw.imgs) do
					tw(i, 0.8, { ImageTransparency = 1 }, Enum.EasingStyle.Sine)
				end
			end
		end)
	end

	-- ---- title card ------------------------------------------------------------------------------
	local function titleCard(delay, lifetime, big)
		if opts.headless then
			return
		end
		at(delay, function()
			local box = new("Frame", { Name = "Title", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, big and 0.27 or 0.3), Size = UDim2.fromScale(big and 0.56 or 0.4, big and 0.24 or 0.16), BackgroundTransparency = 1 }, gui)
			titleBox = box
			local function label(text, y, h, size, col, font, order)
				local l = new("TextLabel", { Text = text, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, y), Size = UDim2.fromScale(1, h), BackgroundTransparency = 1, Font = font, TextScaled = true, TextColor3 = col, TextTransparency = 1, LayoutOrder = order }, box)
				new("UITextSizeConstraint", { MaxTextSize = size }, l)
				local st = new("UIStroke", { Color = Color3.new(0.04, 0.03, 0.08), StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize, Thickness = 0.06, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, l)
				tw(l, 0.35, { TextTransparency = 0 })
				tw(st, 0.35, { Transparency = 0.1 })
				return l
			end
			local odds = opts.odds or def.odds
			label(odds, 0.14, 0.2, big and 44 or 28, accent, Enum.Font.Antique, 1)
			label(opts.name or tier, 0.52, 0.5, big and 120 or 60, color, Enum.Font.Antique, 2)
			if opts.modifier then
				label(opts.modifier, 0.88, 0.22, big and 42 or 26, accent, Enum.Font.Antique, 3)
			end
			local lore = opts.lore or def.lore
			if lore then
				label(lore, 1.2, 0.3, big and 30 or 22, accent, Enum.Font.Antique, 4) -- T057: lore line under the title (box is 28 px tall at 844x390)
			end
			if S.reducedMotion then
				-- fade only
			else
				box.Size = UDim2.fromScale(box.Size.X.Scale * 0.7, box.Size.Y.Scale * 0.7)
				tw(box, 0.45, { Size = UDim2.fromScale(big and 0.56 or 0.4, big and 0.24 or 0.16) }, Enum.EasingStyle.Back)
			end
			at(delay + lifetime - 0.45, function()
				for _, d in ipairs(box:GetDescendants()) do
					if d:IsA("TextLabel") then
						tw(d, 0.4, { TextTransparency = 1 })
					elseif d:IsA("UIStroke") then
						tw(d, 0.4, { Transparency = 1 })
					end
				end
			end)
		end)
	end

	-- ---- spin ------------------------------------------------------------------------------------
	local spinConn = RunService.Heartbeat:Connect(function(dt)
		for _, s in ipairs(spinners) do
			if s.part.Parent then
				s.part.CFrame = s.part.CFrame * CFrame.Angles(0, math.rad(s.speed) * dt * ts, 0)
			end
		end
	end)
	table.insert(conns, spinConn)

	---------------------------------------------------------------------------------------------
	-- the four tiers
	---------------------------------------------------------------------------------------------
	local length = def.length
	local wantAnt = opts.anticipate == true or (opts.idea ~= nil and opts.anticipate ~= false)
	local antLen = wantAnt and ({ Rare = 0.8, Epic = 2.0, Legendary = 4.0 })[tier] or 0

	-- ---- anticipation: one tiny point of light on a dark world, growing and drifting to the result's colour ----------
	local function bloomRamp(peak, rise, hold, fall)
		local softMode = (not S.flashes) or S.reducedMotion
		if softMode then
			peak = peak * 0.45
			rise, fall = math.max(rise, 0.6), math.max(fall, 0.9)
		end
		stats.bloomPeak = math.max(stats.bloomPeak, peak)
		stats.minBloomRise = math.min(stats.minBloomRise, rise)
		if opts.headless or not bloom then
			return
		end
		bloom.Threshold = 0.9
		bloom.Size = 40
		tw(bloom, rise, { Intensity = peak }, Enum.EasingStyle.Sine)
		at(rise + hold, function()
			tw(bloom, fall, { Intensity = 0 }, Enum.EasingStyle.Sine)
		end)
	end

	local function pointOfLight(len, fromColor, toColor, holdDark)
		sfx("anticipation", len)
		darken(tier == "Legendary" and 0.55 or 0.3, math.min(0.9, len * 0.3), (holdDark or len) - 0.4, 0.8)
		if tier == "Legendary" then
			blur(12, math.min(1.4, len * 0.4), math.max(0, len - 1.4 - 0.1), 0.9) -- clears (Quad out) as the star releases
		end
		local gather = sparkles(tier == "Legendary" and 26 or 14, { size = 1.1, speed = 5, life = 1.3, shape = Enum.ParticleEmitterShape.Sphere, inout = Enum.ParticleEmitterShapeInOut.Inward, accel = Vector3.zero })
		local gp = new("Part", { Name = "GatherShape", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(11, 11, 11), CFrame = CFrame.new(pos + Vector3.new(0, 7, 0)) }, folder)
		gather.Parent = gp
		at(len, function()
			gather.Enabled = false
		end)
		if opts.headless then
			return
		end
		local p = new("Part", { Name = "Star", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(pos + Vector3.new(0, 7, 0)) }, folder)
		local bb = new("BillboardGui", { Adornee = p, Size = UDim2.fromScale(0.8, 0.8), LightInfluence = 0, AlwaysOnTop = false, MaxDistance = 1000000 }, p)
		local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = tex.flare, ImageColor3 = fromColor, ImageTransparency = 0.5 }, bb)
		tw(bb, len, { Size = UDim2.fromScale(tier == "Legendary" and 8 or 4, tier == "Legendary" and 8 or 4) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw(img, len, { ImageColor3 = toColor, ImageTransparency = 0 }, Enum.EasingStyle.Sine)
		bloomRamp(0.5, len * 0.9, 0, 0.5)
		-- release: the star flares and fades (a bloom ramp, not a white frame)
		at(len, function()
			tw(bb, 0.7, { Size = UDim2.fromScale(18, 18) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			tw(img, 0.7, { ImageTransparency = 1 }, Enum.EasingStyle.Sine)
		end)
	end

	-- ---- Legendary idea (b): motes spiralling inward and upward into a funnel ------------------------------------------
	local function vortexMotes(n, startR, height, dur)
		if S.reducedMotion then
			return
		end
		n = math.max(6, math.floor(n * mult))
		stats.props += n
		if opts.headless then
			return
		end
		local orbs = {}
		for i = 1, n do
			local part = new("Part", { Name = "Mote", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(pos) }, folder)
			local bb = new("BillboardGui", { Adornee = part, Size = UDim2.fromScale(2.4, 2.4), LightInfluence = 0, AlwaysOnTop = false, MaxDistance = 1000000 }, part)
			local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = tex.flare, ImageColor3 = i % 3 == 0 and accent or color, ImageTransparency = 1 }, bb)
			tw(img, 0.5, { ImageTransparency = 0.05 }, Enum.EasingStyle.Sine)
			orbs[i] = { part = part, img = img, phase = i / n, off = i * 2.4 }
		end
		local t0 = os.clock()
		local c
		c = RunService.Heartbeat:Connect(function()
			if not alive then
				c:Disconnect()
				return
			end
			local t = (os.clock() - t0) * ts
			local f = math.clamp(t / dur, 0, 1)
			for i, o in ipairs(orbs) do
				-- each mote is a point on a spiral; the whole funnel rotates faster as it tightens
				local u = (o.phase + t * 0.22) % 1
				local r = startR * (1 - u) ^ 1.2 * (1 - f * 0.75) + 0.6
				local a = o.off + t * (2.0 + 3.5 * f) + u * 5
				local y = height * u ^ 0.8
				o.part.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * r, 0.6 + y, math.sin(a) * r))
			end
		end)
		table.insert(conns, c)
		at(dur, function()
			for _, o in ipairs(orbs) do
				tw(o.img, 0.5, { ImageTransparency = 1 }, Enum.EasingStyle.Sine)
			end
		end)
	end

	local function buildTier()
	local skip = S.skipTier and ORDER[tier] <= (ORDER[S.skipTier] or 0)
	if skip then
		stats.skipped = true
		length = 0.3
		titleCard(0, 0.3, false)
	elseif tier == "Legendary" and opts.idea == "Ink" then
		-- (a) INK: green ink splashes across the ground, a rune ring writes itself, runes drift up. Release is a bloom ramp.
		sfx("ink")
		length = 4.8
		bloomRamp(1.0, 0.45, 0.4, 1.4)
		disc("ink", 8, 30, 0.7, { height = 0.14, from = 1, to = 0.05, rot = 20, color = color, style = Enum.EasingStyle.Quint })
		at(0.12, function()
			disc("ink", 6, 20, 0.6, { height = 0.2, from = 1, to = 0.15, rot = 140, color = Color3.fromRGB(14, 90, 54), style = Enum.EasingStyle.Quint })
		end)
		at(0.26, function()
			disc("ink", 5, 38, 0.8, { height = 0.1, from = 1, to = 0.45, rot = 250, color = Color3.fromRGB(8, 60, 38), style = Enum.EasingStyle.Quint })
		end)
		at(0.4, function()
			disc("rune", 6, 22, 1.5, { height = 0.3, spin = 18, from = 1, to = 0.1, fadeOutAt = 3.3, fadeOutDur = 1.0, color = accent, style = Enum.EasingStyle.Sine })
			disc("ring", 4, 26, 1.2, { height = 0.32, fadeOutAt = 1.2, fadeOutDur = 0.9, color = color })
		end)
		local drops = sparkles(0, { burstOnly = true, size = 1.5, speed = 20, life = 1.5, spread = 65, accel = Vector3.new(0, -30, 0) })
		emit(drops, 70)
		local runesE = sparkles(30, { size = 1.2, speed = 5, life = 2.4, spread = 10, accel = Vector3.new(0, 1.5, 0) })
		local ringPart = new("Part", { Name = "RuneRing", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(20, 0.5, 20), CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) }, folder)
		runesE.Parent = ringPart
		runesE.Shape = Enum.ParticleEmitterShape.Disc
		runesE.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		at(3.4, function()
			runesE.Enabled = false
		end)
		pillar(30, 0.7, 0.9, 1.8, accent)
		orbitProps(5, 7, 5, 3.4, 0.5)
		titleCard(0.9, length - 0.9, true)
	elseif tier == "Legendary" and opts.idea == "Vortex" then
		-- (b) VORTEX: a gold swirl turns on the ground while motes funnel up into a column, then a ramped release.
		sfx("vortex")
		length = 5.2
		disc("swirl", 4, 34, 1.3, { height = 0.2, spin = 150, from = 1, to = 0.08, fadeOutAt = 3.4, fadeOutDur = 1.0, color = color, style = Enum.EasingStyle.Quint })
		disc("swirl", 3, 20, 1.3, { height = 0.26, spin = -230, from = 1, to = 0.3, fadeOutAt = 3.0, fadeOutDur = 1.0, color = accent, style = Enum.EasingStyle.Quint })
		disc("glow", 4, 26, 1.4, { height = 0.18, from = 0.7, to = 0.3, fadeOutAt = 3.2, fadeOutDur = 1.0, color = color })
		vortexMotes(30, 16, 22, 1.9)
		at(1.9, function()
			-- collapse into the column
			bloomRamp(1.2, 0.5, 0.4, 1.4)
			pillar(46, 2.6, 0.7, 1.8, color)
			pillar(46, 0.9, 0.6, 1.9, accent)
			disc("ring", 3, 40, 1.2, { height = 0.34, fadeOutAt = 1.3, fadeOutDur = 1.0, color = accent })
			local burst = sparkles(0, { burstOnly = true, size = 2.0, speed = 24, life = 1.8, spread = 70, accel = Vector3.new(0, -6, 0) })
			emit(burst, 80)
		end)
		local trail = sparkles(24, { size = 1.2, speed = 7, life = 1.6, spread = 25 })
		at(3.6, function()
			trail.Enabled = false
		end)
		titleCard(2.2, length - 2.2, true)
	elseif tier == "Mythic" then
		-- ROSE SIGIL (T057): a rose sigil opens with a counter-turning rune ring and a petal swirl; one rose column and a crown halo.
		sfx("legendary_burst")
		bloomRamp(0.9, 0.6, 0.5, 1.4)
		darken(0.45, 0.9, length - 2.2, 1.0)
		disc("sigil", 5, 34, 1.6, { height = 0.16, spin = 14, from = 1, to = 0.15, fadeOutAt = 5.6, fadeOutDur = 0.9, style = Enum.EasingStyle.Sine })
		disc("rune", 3, 22, 1.4, { height = 0.24, spin = -26, from = 1, to = 0.2, color = accent, fadeOutAt = 5.2, fadeOutDur = 0.9, style = Enum.EasingStyle.Sine })
		disc("swirl", 3, 28, 1.6, { height = 0.3, spin = 55, from = 1, to = 0.4, fadeOutAt = 4.8, fadeOutDur = 1.0, style = Enum.EasingStyle.Quint })
		local petals = sparkles(34, { size = 1.3, speed = 6, life = 2.2, spread = 25, accel = Vector3.new(0, 2.2, 0) })
		petals.Parent = new("Part", { Name = "PetalDisc", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(24, 0.5, 24), CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) }, folder)
		petals.Shape = Enum.ParticleEmitterShape.Disc
		petals.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		at(4.8, function()
			petals.Enabled = false
		end)
		at(1.4, function()
			flash(0.75, 0.1, 0.06, 0.9)
			cameraPush(8, 0.3, 1.4)
			pillar(40, 1.5, 1.0, 2.8, color)
			pillar(40, 0.5, 0.9, 2.9, accent)
			disc("ring", 2, 30, 1.1, { fadeOutAt = 1.6, fadeOutDur = 1.0, color = accent })
			disc("ring", 1, 8, 0.9, { height = 5.2, from = 0.4, to = 0.05, spin = 50, fadeOutAt = 3.4, fadeOutDur = 1.0 }) -- crown halo
			for i = 1, 6 do
				local a = i * math.tau / 6
				beam(Vector3.new(math.cos(a) * 5, 0, math.sin(a) * 5), 34, 1.2, 0.7, 2.2)
			end
			local burst = sparkles(0, { burstOnly = true, size = 2.0, speed = 22, life = 1.8, spread = 65 })
			emit(burst, 80)
			orbitProps(7, 6, 4.5, 3.6, 0.7)
			tint(0.2, 0.4, 2.4, 1.2)
		end)
		titleCard(1.8, length - 1.8, true)
	elseif tier == "Celestial" then
		-- ARMILLARY (T057): a pale star gathers high above, three rings at different heights turn like an armillary sphere,
		-- then the star flares and a ring of light beams rains down. Cool cyan-white on a dark blue world.
		sfx("ultimate_summon")
		bars(0.7, length - 1.6, 0.8)
		bloomRamp(1.0, 0.8, 0.6, 1.6)
		darken(0.5, 1.0, length - 2.6, 1.2)
		if cc then
			tw(cc, 1.0, { Saturation = -0.2, Contrast = 0.08, TintColor = Color3.fromRGB(190, 225, 255) }, Enum.EasingStyle.Sine)
			at(length - 1.4, function()
				tw(cc, 1.2, { Saturation = 0, Contrast = 0, TintColor = WHITE }, Enum.EasingStyle.Sine)
			end)
		end
		disc("sigil", 6, 40, 1.8, { height = 0.16, spin = 6, from = 1, to = 0.18, fadeOutAt = 7.0, fadeOutDur = 1.0, style = Enum.EasingStyle.Sine })
		disc("ring", 2, 26, 1.8, { height = 3, spin = 40, from = 1, to = 0.1, color = accent, fadeOutAt = 6.8, fadeOutDur = 1.0, style = Enum.EasingStyle.Sine })
		disc("ring", 2, 20, 2.0, { height = 7, spin = -55, from = 1, to = 0.1, fadeOutAt = 6.8, fadeOutDur = 1.0, style = Enum.EasingStyle.Sine })
		disc("ring", 2, 14, 2.2, { height = 11, spin = 80, from = 1, to = 0.1, color = accent, fadeOutAt = 6.8, fadeOutDur = 1.0, style = Enum.EasingStyle.Sine })
		local gather = sparkles(30, { size = 1.1, speed = 5, life = 1.5, shape = Enum.ParticleEmitterShape.Sphere, inout = Enum.ParticleEmitterShapeInOut.Inward, accel = Vector3.zero })
		local gp = new("Part", { Name = "GatherShape", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(12, 12, 12), CFrame = CFrame.new(pos + Vector3.new(0, 11, 0)) }, folder)
		gather.Parent = gp
		at(2.2, function()
			gather.Enabled = false
		end)
		if not opts.headless then
			local star = new("Part", { Name = "Star", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(pos + Vector3.new(0, 11, 0)) }, folder)
			local bb = new("BillboardGui", { Adornee = star, Size = UDim2.fromScale(2, 2), LightInfluence = 0, AlwaysOnTop = false, MaxDistance = 1000000 }, star)
			local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = tex.flare, ImageColor3 = accent, ImageTransparency = 0.4 }, bb)
			tw(bb, 2.2, { Size = UDim2.fromScale(12, 12) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tw(img, 2.2, { ImageTransparency = 0 }, Enum.EasingStyle.Sine)
			at(2.2, function()
				tw(bb, 1.3, { Size = UDim2.fromScale(26, 26) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				tw(img, 1.3, { ImageTransparency = 1 }, Enum.EasingStyle.Sine)
			end)
		end
		at(2.2, function()
			flash(0.8, 0.1, 0.06, 0.9)
			cameraPush(10, 0.3, 1.5)
			pillar(46, 1.6, 1.0, 3.2, color)
			pillar(46, 0.5, 0.9, 3.3, accent)
			for i = 1, 8 do
				local a = i * math.tau / 8
				beam(Vector3.new(math.cos(a) * 7, 0, math.sin(a) * 7), 40, 1.3, 0.8, 2.6)
			end
			local burst = sparkles(0, { burstOnly = true, size = 2.2, speed = 24, life = 2.0, spread = 70 })
			emit(burst, 100)
			local rain = sparkles(36, { size = 1.4, speed = 8, life = 1.8, spread = 75 })
			at(4.6, function()
				rain.Enabled = false
			end)
			orbitProps(9, 7, 5, 4.2, 0.7)
			tint(0.22, 0.4, 2.8, 1.3)
		end)
		titleCard(2.6, length - 2.6, true)
	elseif tier == "Common" then
		sfx("common")
		local e = sparkles(0, { burstOnly = true, size = 1.0, speed = 5, life = 0.6, spread = 70 })
		emit(e, 10)
		disc("glow", 3, 5, 0.5, { height = 0.2, from = 0.7, to = 0.5, fadeOutAt = 0.35, fadeOutDur = 0.4 })
		titleCard(0, length, false)
	elseif tier == "Rare" then
		sfx("rare")
		disc("ring", 1, 11, 0.7, { fadeOutAt = 0.9, fadeOutDur = 0.5 })
		disc("glow", 4, 7, 0.9, { height = 0.2, from = 0.6, to = 0.3, fadeOutAt = 0.9, fadeOutDur = 0.5 })
		local e = sparkles(0, { burstOnly = true, size = 1.5, speed = 9, life = 1.1, spread = 35 })
		emit(e, 26)
		local e2 = sparkles(14, { size = 1.1, speed = 4, life = 0.9 })
		at(1.0, function()
			e2.Enabled = false
		end)
		pillar(9, 0.7, 0.5, 0.3, color)
		blur(6, 0.2, 0.05, 0.5)
		tint(0.12, 0.3, 0.5, 0.6)
		titleCard(0.15, length - 0.15, false)
	elseif tier == "Epic" then
		sfx("epic")
		darken(0.25, 0.4, 1.6, 0.8)
		blur(12, 0.6, 0.4, 0.55)
		disc("ring", 1, 15, 0.9, { fadeOutAt = 1.8, fadeOutDur = 0.8 })
		disc("rune", 3, 12, 1.2, { height = 0.18, spin = 40, fadeOutAt = 2.0, fadeOutDur = 0.8, to = 0.25, style = Enum.EasingStyle.Quad })
		disc("glow", 5, 10, 1.0, { height = 0.2, from = 0.6, to = 0.25, fadeOutAt = 2.0, fadeOutDur = 0.8 })
		for i = 1, 3 do
			local a = i * math.tau / 3
			beam(Vector3.new(math.cos(a) * 3.2, 0, math.sin(a) * 3.2), 22, 1.0, 0.6, 1.5)
		end
		pillar(16, 0.9, 0.9, 1.2, color)
		local e = sparkles(0, { burstOnly = true, size = 1.8, speed = 12, life = 1.4, spread = 45 })
		local e2 = sparkles(26, { size = 1.2, speed = 6, life = 1.3 })
		emit(e, 50)
		at(2.2, function()
			e2.Enabled = false
		end)
		orbitProps(6, 4.5, 4, 2.3, 0.55)
		flash(0.45, 0.15, 0.05, 0.5)
		tint(0.2, 0.5, 1.5, 0.9)
		titleCard(0.5, length - 0.5, true)
	elseif tier == "Ultimate" then
		-- DAWNBREAKER: a gothic sigil opens, a giant spectral sword is summoned, falls, and judges the ground.
		local steel, gold = accent, color
		sfx("ultimate_summon")
		bars(0.7, length - 1.6, 0.8)
		darken(0.5, 0.9, 5.4, 1.1)
		if cc then
			tw(cc, 1.0, { Saturation = -0.35, Contrast = 0.1, TintColor = Color3.fromRGB(170, 190, 255) }, Enum.EasingStyle.Sine)
			at(length - 1.4, function()
				tw(cc, 1.2, { Saturation = 0, Contrast = 0, TintColor = WHITE }, Enum.EasingStyle.Sine)
			end)
		end
		-- 0.0 to 2.6: the sigil opens and the arena is bounded by four gold pillars
		disc("sigil", 6, 38, 1.8, { height = 0.16, spin = 8, from = 1, to = 0.18, fadeOutAt = 6.2, fadeOutDur = 1.0, style = Enum.EasingStyle.Sine })
		disc("ring", 3, 40, 1.6, { height = 0.2, fadeOutAt = 1.6, fadeOutDur = 0.8, color = accent })
		for i = 1, 4 do
			local a = i * math.tau / 4 + math.pi / 4
			pillar(46, 0.8, 1.0, 5.2, gold, Vector3.new(math.cos(a) * 17, 0, math.sin(a) * 17))
		end
		local embers = new("Part", { Name = "EmberRing", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(30, 0.5, 30), CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) }, folder)
		local emberE = sparkles(42, { size = 1.0, speed = 7, life = 2.4, spread = 12, accel = Vector3.new(0, 2, 0) })
		emberE.Parent = embers
		emberE.Shape = Enum.ParticleEmitterShape.Disc
		emberE.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		at(6.0, function()
			emberE.Enabled = false
		end)
		-- 0.9: the sword materialises high above
		local sword, tipOff, swordImgs = buildSword(64)
		local hoverY = pos.Y + 84
		local plantY = pos.Y + tipOff - 3 -- tip a little under the ground
		local yv = Instance.new("NumberValue")
		yv.Value = hoverY
		table.insert(extras, yv)
		sword.CFrame = CFrame.new(pos.X, hoverY, pos.Z)
		table.insert(conns, yv.Changed:Connect(function(y)
			sword.CFrame = CFrame.new(pos.X, y, pos.Z)
		end))
		local light = new("PointLight", { Color = gold, Brightness = 0, Range = 60, Shadows = false }, sword)
		local bladeGlow = new("ParticleEmitter", { Texture = tex.glow, Color = ColorSequence.new(steel, gold), LightEmission = 1, LightInfluence = 0, Size = NumberSequence.new(9), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 1) }), Lifetime = NumberRange.new(0.5, 0.8), Speed = NumberRange.new(0, 0), Rate = 0, Enabled = false, TimeScale = ts }, sword)
		stats.emitters += 1
		at(0.9, function()
			setImgAlpha(swordImgs, 1, 0.04, 1.4)
			tw(light, 1.3, { Brightness = 3 })
			bladeGlow.Rate = math.clamp(math.floor(22 * mult), 1, cap)
			stats.totalRate += bladeGlow.Rate
			stats.peakRate = math.max(stats.peakRate, bladeGlow.Rate)
			bladeGlow.Enabled = true
			sfx("ultimate_sword")
		end)
		-- chains of light from the sword down to the sigil
		at(1.4, function()
			for i = 1, 6 do
				local a = i * math.tau / 6
				beam(Vector3.new(math.cos(a) * 13, 0, math.sin(a) * 13), 58, 0.7, 0.9, 1.1)
			end
		end)
		-- the descent: a rise in tension, a short hang, then a fast fall
		at(2.3, function()
			blur(8, 0.7, 0.32, 0.8)
			tw(yv, 0.5, { Value = hoverY + 5 }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			tw(light, 0.5, { Brightness = 6 })
		end)
		at(2.9, function()
			sfx("ultimate_fall")
			tw(yv, 0.42, { Value = plantY }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end)
		-- 3.32: impact
		at(3.32, function()
			sfx("ultimate_impact")
			flash(0.95, 0.05, 0.09, 1.0, accent)
			shake(2.6, 1.0)
			cameraPush(12, 0.12, 1.6)
			tw(light, 0.3, { Brightness = 10 })
			for i = 0, 2 do
				at(i * 0.14, function()
					disc("ring", 4, 100, 1.1 + i * 0.1, { height = 0.3 + i * 0.02, fadeOutAt = 0.5 + i * 0.1, fadeOutDur = 0.9, color = i == 1 and accent or gold })
				end)
			end
			disc("crack", 8, 40, 0.45, { height = 0.24, from = 0.3, to = 0.05, fadeOutAt = 3.0, fadeOutDur = 1.4, color = gold })
			disc("glow", 6, 34, 0.7, { height = 0.28, from = 0.2, to = 0.2, fadeOutAt = 1.2, fadeOutDur = 1.2 })
			pillar(80, 3.6, 0.7, 2.6, gold)
			pillar(80, 1.2, 0.6, 2.8, accent)
			for i = 1, 8 do
				local a = i * math.tau / 8
				beam(Vector3.new(math.cos(a) * 7, 0, math.sin(a) * 7), 56, 1.8, 0.5, 2.2)
			end
			local burst = sparkles(0, { burstOnly = true, size = 2.6, speed = 36, life = 2.0, spread = 75, accel = Vector3.new(0, -20, 0) })
			emit(burst, 110)
			local debris = sparkles(0, { burstOnly = true, size = 1.2, speed = 28, life = 1.6, spread = 85, accel = Vector3.new(0, -34, 0) })
			emit(debris, 60)
			local rain = sparkles(36, { size = 1.5, speed = 12, life = 2.0, spread = 80 })
			at(2.6, function()
				rain.Enabled = false
			end)
			orbitSwords(6, 11, 7, 3.2)
			tint(0.22, 0.5, 2.8, 1.3)
		end)
		titleCard(3.9, length - 3.9, true)
		-- 6.1: the sword dissolves
		at(6.1, function()
			setImgAlpha(swordImgs, 0.04, 1, 1.3)
			tw(light, 1.2, { Brightness = 0 })
			bladeGlow.Enabled = false
		end)
	else -- Legendary
		sfx("legendary_gather")
		-- 0 to 1.4 s: anticipation. Darken, desaturate, light gathers inward on a rune circle.
		darken(0.5, 0.7, 4.0, 0.9)
		blur(18, 0.6, 0.8, 0.5)
		if cc then
			tw(cc, 0.8, { Saturation = -0.45, Contrast = 0.12 }, Enum.EasingStyle.Sine)
			at(length - 1.2, function()
				tw(cc, 1.0, { Saturation = 0, Contrast = 0, TintColor = WHITE }, Enum.EasingStyle.Sine)
			end)
		end
		local gather = sparkles(70, { size = 1.5, speed = 9, life = 1.2, shape = Enum.ParticleEmitterShape.Sphere, inout = Enum.ParticleEmitterShapeInOut.Inward, accel = Vector3.zero })
		local gatherPart = new("Part", { Name = "GatherShape", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(9, 9, 9), CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) }, folder)
		gather.Parent = gatherPart
		disc("rune", 4, 9, 1.3, { height = 0.18, spin = 25, from = 1, to = 0.3, fadeOutAt = 4.6, fadeOutDur = 0.9, style = Enum.EasingStyle.Sine })
		disc("glow", 14, 3, 1.3, { height = 0.2, from = 0.9, to = 0.2, style = Enum.EasingStyle.Quad })
		-- 1.4 s: release
		at(1.4, function()
			sfx("legendary_burst")
			gather.Enabled = false
			flash(0.85, 0.08, 0.06, 0.8)
			cameraPush(9, 0.25, 1.2)
			disc("ring", 2, 32, 1.1, { fadeOutAt = 1.6, fadeOutDur = 1.0 })
			disc("rune", 9, 24, 1.6, { height = 0.22, spin = -35, to = 0.2, fadeOutAt = 3.0, fadeOutDur = 1.2 })
			disc("glow", 3, 22, 1.4, { height = 0.25, from = 0.4, to = 0.15, fadeOutAt = 3.2, fadeOutDur = 1.2 })
			pillar(34, 1.5, 1.0, 1.6, color)
			pillar(34, 0.5, 0.9, 1.7, accent)
			for i = 1, 5 do
				local a = i * math.tau / 5
				beam(Vector3.new(math.cos(a) * 5, 0, math.sin(a) * 5), 38, 1.4, 0.7, 2.2)
			end
			-- crown halo: a rune-style ring floating above the head
			disc("ring", 1, 8, 0.9, { height = 5.2, from = 0.4, to = 0.05, spin = 50, fadeOutAt = 3.4, fadeOutDur = 1.0 })
			local burst = sparkles(0, { burstOnly = true, size = 2.2, speed = 22, life = 1.8, spread = 60 })
			emit(burst, 90)
			local rain = sparkles(34, { size = 1.4, speed = 8, life = 1.6, spread = 70 })
			at(3.4, function()
				rain.Enabled = false
			end)
			orbitProps(8, 6, 4.5, 3.8, 0.7)
			tint(0.22, 0.4, 2.4, 1.2)
		end)
		titleCard(1.7, length - 1.7, true)
	end

	end -- buildTier

	if skip then
		antLen = 0
	end
	if antLen > 0 then
		local idea = opts.idea
		pointOfLight(antLen, WHITE, idea == "Ink" and Color3.fromRGB(110, 255, 170) or color, antLen + (idea and 3.2 or 0))
		at(antLen, buildTier)
	else
		buildTier()
	end
	at(antLen + length, cleanup)
	if opts.headless then
		cleanup()
	end
	return handle
end

---------------------------------------------------------------------------------------------------
-- preview and audit
---------------------------------------------------------------------------------------------------
function RevealFX.preview(tier, opts)
	opts = opts or {}
	opts.name = opts.name or ({ Common = "Pebble Pup", Rare = "Tide Fox", Epic = "Storm Drake", Legendary = "Crowned", Mythic = "Dame Orrery", Celestial = "The Lamplighter" })[tier]
	opts.modifier = opts.modifier or (tier == "Legendary" and "Gilded" or nil)
	return RevealFX.play(tier, opts)
end

-- Builds every tier under every Particles x Flashes x ReducedMotion x touch combination without any GUI or world parts,
-- and checks the limits. Returns (report, failures).
function RevealFX.audit()
	local lines, fails = {}, 0
	local variants = {}
	for _, t in ipairs(RevealFX.order) do
		table.insert(variants, { tier = t, anticipate = (t == "Rare" or t == "Epic" or t == "Legendary") })
	end
	table.insert(variants, { tier = "Legendary", idea = "Ink" })
	table.insert(variants, { tier = "Legendary", idea = "Vortex" })
	for _, v in ipairs(variants) do
		local tier = v.tier
		local name = tier .. (v.idea and ("/" .. v.idea) or "")
		for _, particles in ipairs({ "Low", "Default", "High" }) do
			for _, touch in ipairs({ true, false }) do
				for _, flashes in ipairs({ true, false }) do
					local h = RevealFX.play(tier, { headless = true, idea = v.idea, anticipate = v.anticipate, forceTouch = touch, position = Vector3.zero, settings = { particles = particles, flashes = flashes, reducedMotion = not flashes } })
					local s = h.stats
					local cap = touch and 100 or 400
					local bad = {}
					if s.peakRate > cap then
						table.insert(bad, "rate " .. s.peakRate .. " > " .. cap)
					end
					if not flashes and (s.flashes > 0 or s.minRise < 0.5 and s.softTints > 0) then
						table.insert(bad, "flash while Flashes off")
					end
					if not flashes and s.props > 0 then
						table.insert(bad, "orbiting props while Reduced motion on")
					end
					if touch and s.blurPeak > 10 then
						table.insert(bad, "blur " .. s.blurPeak .. " > 10 on touch")
					end
					if (not flashes) and (s.blurPeak > 8 or (s.blurPeak > 0 and s.minBlurRise < 0.6)) then
						table.insert(bad, "blur not soft with Flashes off")
					end
					if (not flashes) and (s.bloomPeak > 0.6 or (s.bloomPeak > 0 and s.minBloomRise < 0.6)) then
						table.insert(bad, "bloom not soft with Flashes off")
					end
					if flashes and s.flashes > 3 then
						table.insert(bad, "more than 3 flashes")
					end
					if v.idea and s.flashes > 0 then
						table.insert(bad, "idea cutscene used a flash (bloom ramp only)")
					end
					if #bad > 0 then
						fails += 1
						table.insert(lines, string.format("FAIL %s %s touch=%s flashes=%s: %s", name, particles, tostring(touch), tostring(flashes), table.concat(bad, "; ")))
					end
				end
			end
		end
		local h = RevealFX.play(tier, { headless = true, idea = v.idea, anticipate = v.anticipate, forceTouch = true, position = Vector3.zero, settings = { particles = "High", flashes = true, reducedMotion = false } })
		local s = h.stats
		table.insert(lines, string.format("%s (High, touch): emitters %d, peak rate %d/s, burst %d, props %d, flashes %d (peak %.2f, rise %.2fs), blur peak %d, bloom peak %.2f", name, s.emitters, s.peakRate, s.burstTotal, s.props, s.flashes, s.maxFlashPeak, s.minRise == math.huge and 0 or s.minRise, s.blurPeak, s.bloomPeak))
	end
	table.insert(lines, fails == 0 and "AUDIT PASS" or ("AUDIT FAILURES: " .. fails))
	return table.concat(lines, "\n"), fails
end

return RevealFX
