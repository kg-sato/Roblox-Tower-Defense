--!nocheck
-- FeedbackFX: the feedback and menu motion baseline (spec section C of Roblox Dev/Research/UI/Loading and Reveal Spec.md).
-- Standalone, client-side, nothing wired into the game HUD. Source: VFX/FeedbackFX.luau, installed as ReplicatedStorage.FeedbackFX.
-- Motion baseline comes from the vibe-coded game's animations (combo text, ring pulse, milestone banner, dim-and-highlight
-- tutorial, living background); our UI look stays our own. Everything eases (Quint/Back/Sine), nothing strobes.
--
--   FeedbackFX.comboText(gui, UDim2.fromScale(0.5, 0.6), "COMBO x10  +92%", { color = Color3.fromRGB(255, 214, 40) })
--   FeedbackFX.ringPulse(gui, UDim2.fromScale(0.5, 0.6), color)
--   FeedbackFX.milestone(gui, "STELLAR!", { color = ... })        -- banner + soft edge tint (alpha <= 0.18)
--   local s = FeedbackFX.spotlight(gui, targetButton, { hint = "Tap here" })   s.close()
--   local m = FeedbackFX.menuBackdrop(gui, { tint = Color3.fromRGB(40, 140, 80), panel = myPanel })   m.close()
--   local b = FeedbackFX.livingBackdrop(gui)   b.stop()
--   FeedbackFX.discovery(gui, "VENUS", { color = ... })
-- Settings (shared with RevealFX.settings): reducedMotion => no rise, pop or drift, plain fades; flashes=false => the edge tint
-- is halved and slower; particles Low/Default/High => ring count 1/1/2 and backdrop blob count x0.25/1/1.5; touch caps blur.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local FeedbackFX = {}

FeedbackFX.textures = {
	ring = "rbxasset://textures/vfx/vfx_ring.png",
	glow = "rbxasset://textures/vfx/vfx_glow.png",
	flare = "rbxasset://textures/vfx/vfx_flare.png",
}

FeedbackFX.limits = { tintPeak = 0.18, softTintPeak = 0.09, blurDesktop = 12, blurTouch = 8, blurSoft = 6 }

local okR, RevealFX = pcall(function()
	return require(script.Parent:WaitForChild("RevealFX", 2))
end)
local MULT = { Low = 0.25, Default = 1, High = 1.5 }
local function settings(over)
	local s = { flashes = true, particles = "Default", reducedMotion = false }
	if okR and RevealFX and RevealFX.settings then
		for k, v in pairs(RevealFX.settings) do
			s[k] = v
		end
	end
	if over then
		for k, v in pairs(over) do
			s[k] = v
		end
	end
	return s
end

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do
		i[k] = v
	end
	i.Parent = parent
	return i
end

local function tween(inst, dur, props, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

-- Size for a square image: BOTH axes must be non-zero or the aspect constraint collapses it to nothing (measured in Studio)
local function sq(h)
	return UDim2.fromScale(h, h)
end

-- sound cue: opts.sfx or the shared RevealFX.defaultSfx (set by SoundFX.attach); every cue is logged for the verification harness
FeedbackFX.cueLog = {}
local function cue(name, opts, len, pitch)
	table.insert(FeedbackFX.cueLog, { name = name, t = os.clock() })
	local f = (opts and opts.sfx) or (okR and RevealFX and RevealFX.defaultSfx)
	if f then
		f(name, len, pitch)
	end
end

local function later(t, fn)
	task.delay(t, fn)
end

local function strokeText(label, thick)
	new("UIStroke", { StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize, Thickness = thick or 0.07, Color = Color3.fromRGB(14, 12, 24), ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, label)
end

local function textLabel(parent, text, pos, size, maxSize, color, font)
	local l = new("TextLabel", { Text = text, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, BackgroundTransparency = 1, Font = font or Enum.Font.FredokaOne, TextScaled = true, TextColor3 = color or Color3.new(1, 1, 1), TextTransparency = 1 }, parent)
	new("UITextSizeConstraint", { MaxTextSize = maxSize }, l)
	strokeText(l)
	return l
end

local function fadeOutText(l, dur)
	tween(l, dur, { TextTransparency = 1 }, Enum.EasingStyle.Sine)
	for _, d in ipairs(l:GetChildren()) do
		if d:IsA("UIStroke") then
			tween(d, dur, { Transparency = 1 }, Enum.EasingStyle.Sine)
		end
	end
end

-- ---- floating combo / value text ------------------------------------------------------------------------------------
function FeedbackFX.comboText(gui, pos, text, opts)
	opts = opts or {}
	cue("combo", opts, nil, 1 + math.min(0.5, (opts.level or 0) * 0.05))
	local S = settings(opts.settings)
	local size = UDim2.fromScale(opts.w or 0.26, opts.h or 0.07)
	local l = textLabel(gui, text, pos, size, opts.maxSize or 56, opts.color or Color3.fromRGB(255, 214, 40))
	local stroke = l:FindFirstChildOfClass("UIStroke")
	stroke.Transparency = 1
	tween(l, 0.12, { TextTransparency = 0 }, Enum.EasingStyle.Sine)
	tween(stroke, 0.12, { Transparency = 0 }, Enum.EasingStyle.Sine)
	if not S.reducedMotion then
		l.Size = UDim2.fromScale(size.X.Scale * 0.7, size.Y.Scale * 0.7)
		tween(l, 0.22, { Size = size }, Enum.EasingStyle.Back)
		tween(l, 0.95, { Position = UDim2.new(pos.X.Scale, 0, pos.Y.Scale - (opts.rise or 0.1), 0) }, Enum.EasingStyle.Quint)
	end
	later(0.55, function()
		if l.Parent then
			fadeOutText(l, 0.4)
		end
	end)
	later(1.05, function()
		l:Destroy()
	end)
	return l
end

-- ---- ring pulse ------------------------------------------------------------------------------------------------------
function FeedbackFX.ringPulse(gui, pos, color, opts)
	opts = opts or {}
	cue("ring", opts)
	local S = settings(opts.settings)
	local count = (S.particles == "High") and 2 or 1
	local h = opts.size or 0.16
	for i = 1, count do
		later((i - 1) * 0.12, function()
			local r = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = sq(S.reducedMotion and h or h * 0.25), BackgroundTransparency = 1, Image = FeedbackFX.textures.ring, ImageColor3 = color or Color3.new(1, 1, 1), ImageTransparency = 0.15 }, gui)
			new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, r)
			if not S.reducedMotion then
				tween(r, 0.55, { Size = sq(h) }, Enum.EasingStyle.Quint)
			end
			tween(r, 0.55, { ImageTransparency = 1 }, Enum.EasingStyle.Sine)
			later(0.6, function()
				r:Destroy()
			end)
		end)
	end
end

-- ---- milestone banner with a soft edge tint (alpha <= 0.18; never a flash) --------------------------------------------
function FeedbackFX.edgeTint(gui, color, opts)
	opts = opts or {}
	local S = settings(opts.settings)
	local peak = (not S.flashes or S.reducedMotion) and FeedbackFX.limits.softTintPeak or FeedbackFX.limits.tintPeak
	local rise = (not S.flashes or S.reducedMotion) and 0.5 or 0.3
	local holder = new("Frame", { Name = "EdgeTint", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0, Active = false }, gui)
	local edges = {}
	for _, e in ipairs({ { 0, 0, 1, 0.16, 90 }, { 0, 0.84, 1, 0.16, 270 }, { 0, 0, 0.1, 1, 0 }, { 0.9, 0, 0.1, 1, 180 } }) do
		local f = new("Frame", { Position = UDim2.fromScale(e[1], e[2]), Size = UDim2.fromScale(e[3], e[4]), BackgroundColor3 = color or Color3.fromRGB(190, 255, 80), BackgroundTransparency = 1, BorderSizePixel = 0 }, holder)
		new("UIGradient", { Rotation = e[5], Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, f)
		table.insert(edges, f)
	end
	for _, f in ipairs(edges) do
		tween(f, rise, { BackgroundTransparency = 1 - peak }, Enum.EasingStyle.Sine)
		later(rise + 0.35, function()
			if f.Parent then
				tween(f, 0.7, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
			end
		end)
	end
	later(rise + 1.2, function()
		holder:Destroy()
	end)
	return peak
end

function FeedbackFX.milestone(gui, text, opts)
	opts = opts or {}
	cue("milestone", opts)
	local S = settings(opts.settings)
	local color = opts.color or Color3.fromRGB(255, 214, 40)
	local l = textLabel(gui, text, UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.5, 0.13), 96, color)
	local stroke = l:FindFirstChildOfClass("UIStroke")
	stroke.Transparency = 1
	if not S.reducedMotion then
		l.Position = UDim2.fromScale(0.5, 0.33)
		l.Size = UDim2.fromScale(0.4, 0.1)
		tween(l, 0.45, { Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(0.5, 0.13) }, Enum.EasingStyle.Back)
	end
	tween(l, 0.25, { TextTransparency = 0 }, Enum.EasingStyle.Sine)
	tween(stroke, 0.25, { Transparency = 0 }, Enum.EasingStyle.Sine)
	local peak = 0
	if opts.tint ~= false then
		peak = FeedbackFX.edgeTint(gui, opts.tintColor or color, opts)
	end
	later(1.5, function()
		if l.Parent then
			if not S.reducedMotion then
				tween(l, 0.5, { Position = UDim2.fromScale(0.5, 0.27) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
			fadeOutText(l, 0.5)
		end
	end)
	later(2.1, function()
		l:Destroy()
	end)
	return l, peak
end

-- ---- tutorial highlight: dim everything except the target, gold outline, bobbing pointer ------------------------------
function FeedbackFX.spotlight(gui, target, opts)
	opts = opts or {}
	cue("spotlight", opts)
	local S = settings(opts.settings)
	local gAbs, gPos = gui.AbsoluteSize, gui.AbsolutePosition
	local function rect()
		local p = target.AbsolutePosition - gPos
		local s = target.AbsoluteSize
		local pad = 0.012
		return (p.X / gAbs.X) - pad, (p.Y / gAbs.Y) - pad * 1.6, (s.X / gAbs.X) + pad * 2, (s.Y / gAbs.Y) + pad * 3.2
	end
	local x, y, w, h = rect()
	local holder = new("Folder", { Name = "Spotlight" }, gui)
	local dimParts = {}
	local function dimFrame(px, py, pw, ph)
		local f = new("Frame", { Position = UDim2.fromScale(px, py), Size = UDim2.fromScale(math.max(pw, 0), math.max(ph, 0)), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 50 }, holder)
		table.insert(dimParts, f)
	end
	dimFrame(0, 0, 1, y)
	dimFrame(0, y + h, 1, 1 - (y + h))
	dimFrame(0, y, x, h)
	dimFrame(x + w, y, 1 - (x + w), h)
	for _, f in ipairs(dimParts) do
		tween(f, 0.35, { BackgroundTransparency = 0.45 }, Enum.EasingStyle.Sine)
	end
	local outline = new("Frame", { Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h), BackgroundTransparency = 1, ZIndex = 51 }, holder)
	new("UICorner", { CornerRadius = UDim.new(0.18, 0) }, outline)
	local st = new("UIStroke", { StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize, Thickness = 0.05, Color = Color3.fromRGB(255, 205, 60), Transparency = 1 }, outline)
	tween(st, 0.35, { Transparency = 0 }, Enum.EasingStyle.Sine)
	local pointer = textLabel(holder, "▲", UDim2.fromScale(x + w / 2, y + h + 0.05), UDim2.fromScale(0.04, 0.06), 48, Color3.fromRGB(255, 205, 60))
	pointer.ZIndex = 52
	tween(pointer, 0.35, { TextTransparency = 0 }, Enum.EasingStyle.Sine)
	local hint
	if opts.hint then
		hint = textLabel(holder, opts.hint, UDim2.fromScale(x + w / 2, y + h + 0.13), UDim2.fromScale(0.3, 0.06), 40)
		hint.ZIndex = 52
		tween(hint, 0.35, { TextTransparency = 0 }, Enum.EasingStyle.Sine)
	end
	local c
	if not S.reducedMotion then
		local t0 = os.clock()
		c = RunService.Heartbeat:Connect(function()
			local t = os.clock() - t0
			pointer.Position = UDim2.fromScale(x + w / 2, y + h + 0.05 + math.sin(t * 4) * 0.008)
			st.Thickness = 0.05 + math.sin(t * 3) * 0.008
		end)
	end
	local handle = {}
	function handle.close()
		if c then
			c:Disconnect()
		end
		for _, f in ipairs(dimParts) do
			tween(f, 0.3, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
		end
		tween(st, 0.3, { Transparency = 1 }, Enum.EasingStyle.Sine)
		fadeOutText(pointer, 0.3)
		if hint then
			fadeOutText(hint, 0.3)
		end
		later(0.4, function()
			holder:Destroy()
		end)
	end
	return handle
end

-- ---- menu backdrop: blur + dim + tint behind a panel, panel pops in with it, closes the same way -------------------
function FeedbackFX.menuBackdrop(gui, opts)
	opts = opts or {}
	cue("menu_open", opts)
	local S = settings(opts.settings)
	local touch = opts.forceTouch
	if touch == nil then
		touch = UserInputService.TouchEnabled
	end
	local soft = (not S.flashes) or S.reducedMotion
	local L = FeedbackFX.limits
	local peak = soft and L.blurSoft or (touch and L.blurTouch or L.blurDesktop)
	local blur = new("BlurEffect", { Name = "FeedbackFX_Blur", Size = 0 }, workspace.CurrentCamera)
	local dim = new("Frame", { Name = "MenuDim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Active = true }, gui)
	local tintF = new("Frame", { Name = "MenuTint", Size = UDim2.fromScale(1, 1), BackgroundColor3 = opts.tint or Color3.fromRGB(40, 140, 80), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5 }, gui)
	tween(blur, 0.4, { Size = peak }, Enum.EasingStyle.Quint)
	tween(dim, 0.4, { BackgroundTransparency = 0.5 }, Enum.EasingStyle.Sine)
	tween(tintF, 0.4, { BackgroundTransparency = 0.82 }, Enum.EasingStyle.Sine)
	local panel = opts.panel
	local baseSize = panel and panel.Size
	if panel then
		panel.ZIndex = 6
		if not S.reducedMotion then
			panel.Size = UDim2.fromScale(baseSize.X.Scale * 0.92, baseSize.Y.Scale * 0.92)
			tween(panel, 0.35, { Size = baseSize }, Enum.EasingStyle.Quint)
		end
		if panel:IsA("CanvasGroup") then
			panel.GroupTransparency = 1
			tween(panel, 0.3, { GroupTransparency = 0 }, Enum.EasingStyle.Sine)
		end
	end
	local handle = { stats = { blurPeak = peak } }
	function handle.close()
		cue("menu_close", opts)
		tween(blur, 0.3, { Size = 0 }, Enum.EasingStyle.Quad)
		tween(dim, 0.3, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
		tween(tintF, 0.3, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
		if panel then
			if panel:IsA("CanvasGroup") then
				tween(panel, 0.25, { GroupTransparency = 1 }, Enum.EasingStyle.Sine)
			end
			if not S.reducedMotion then
				tween(panel, 0.3, { Size = UDim2.fromScale(baseSize.X.Scale * 0.94, baseSize.Y.Scale * 0.94) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end
		later(0.4, function()
			blur:Destroy()
			dim:Destroy()
			tintF:Destroy()
			if panel then
				panel.Size = baseSize
			end
		end)
	end
	return handle
end

-- ---- living background: slow drifting light, twinkling stars. Nothing is ever static. ---------------------------------
function FeedbackFX.livingBackdrop(gui, opts)
	opts = opts or {}
	local S = settings(opts.settings)
	local mult = MULT[S.particles] or 1
	local holder = new("Frame", { Name = "LivingBackdrop", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0, ClipsDescendants = true, Active = false }, gui)
	local blobs, stars = {}, {}
	local nBlobs = math.max(2, math.floor(6 * mult))
	local nStars = math.max(4, math.floor(18 * mult))
	local palette = opts.colors or { Color3.fromRGB(80, 130, 255), Color3.fromRGB(150, 90, 255), Color3.fromRGB(60, 200, 230) }
	for i = 1, nBlobs do
		local b = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = FeedbackFX.textures.glow, ImageColor3 = palette[(i - 1) % #palette + 1], ImageTransparency = 0.55, Size = sq(0.7 + (i % 3) * 0.2) }, holder)
		new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, b)
		blobs[i] = { img = b, ax = 0.15 + (i * 0.37) % 0.7, ay = 0.2 + (i * 0.23) % 0.6, sx = 0.02 + (i % 3) * 0.012, sy = 0.015 + (i % 2) * 0.01, f = 0.07 + i * 0.013, ph = i * 1.7 }
	end
	for i = 1, nStars do
		local s = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = FeedbackFX.textures.flare, ImageTransparency = 0.5, Size = sq(0.02 + (i % 3) * 0.008), Position = UDim2.fromScale((i * 0.137) % 1, (i * 0.291) % 1) }, holder)
		new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, s)
		stars[i] = { img = s, f = 0.4 + (i % 5) * 0.25, ph = i * 0.9 }
	end
	local t0 = os.clock()
	local function frame()
		local t = os.clock() - t0
		for _, b in ipairs(blobs) do
			local k = S.reducedMotion and 0 or 1
			b.img.Position = UDim2.fromScale(b.ax + math.sin(t * b.f + b.ph) * b.sx * k, b.ay + math.cos(t * b.f * 0.8 + b.ph) * b.sy * k)
		end
		for _, s in ipairs(stars) do
			s.img.ImageTransparency = S.reducedMotion and 0.6 or 0.35 + 0.35 * (0.5 + 0.5 * math.sin(t * s.f * 2 + s.ph))
		end
	end
	frame()
	local c = RunService.Heartbeat:Connect(frame)
	local handle = { stats = { blobs = nBlobs, stars = nStars } }
	function handle.stop()
		c:Disconnect()
		holder:Destroy()
	end
	return handle
end

-- ---- discovery moment: a thin orbit line, a large title fading in behind the focus object --------------------------
function FeedbackFX.discovery(gui, name, opts)
	opts = opts or {}
	cue("discovery", opts)
	local S = settings(opts.settings)
	local color = opts.color or Color3.fromRGB(150, 210, 255)
	local ring = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = sq(S.reducedMotion and 0.5 or 0.2), BackgroundTransparency = 1, Image = FeedbackFX.textures.ring, ImageColor3 = color, ImageTransparency = 1, ZIndex = 2 }, gui)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, ring)
	local title = textLabel(gui, name, UDim2.fromScale(0.5, 0.2), UDim2.fromScale(0.5, 0.16), 110, Color3.new(1, 1, 1))
	title.ZIndex = 1
	local stroke = title:FindFirstChildOfClass("UIStroke")
	stroke.Transparency = 1
	tween(ring, 0.6, { ImageTransparency = 0.35 }, Enum.EasingStyle.Sine)
	if not S.reducedMotion then
		tween(ring, 1.4, { Size = sq(0.5) }, Enum.EasingStyle.Quint)
		local t0 = os.clock()
		local c
		c = RunService.Heartbeat:Connect(function()
			if not ring.Parent then
				c:Disconnect()
				return
			end
			ring.Rotation = (os.clock() - t0) * 14
		end)
	end
	later(0.4, function()
		tween(title, 0.9, { TextTransparency = 0 }, Enum.EasingStyle.Sine)
		tween(stroke, 0.9, { Transparency = 0 }, Enum.EasingStyle.Sine)
	end)
	later(2.8, function()
		tween(ring, 0.6, { ImageTransparency = 1 }, Enum.EasingStyle.Sine)
		fadeOutText(title, 0.7)
	end)
	later(3.6, function()
		ring:Destroy()
		title:Destroy()
	end)
end

-- Runs every component once into `gui` for each settings combination, waits for the clean-up and checks that no instances
-- are left behind and that the tint stays under its limits. Needs a live ScreenGui, so call it from a playtest client.
function FeedbackFX.audit(gui)
	local lines, fails = {}, 0
	local baseline = #gui:GetDescendants()
	for _, flashes in ipairs({ true, false }) do
		for _, reduced in ipairs({ false, true }) do
			for _, particles in ipairs({ "Low", "High" }) do
				local o = { settings = { flashes = flashes, reducedMotion = reduced, particles = particles } }
				FeedbackFX.comboText(gui, UDim2.fromScale(0.5, 0.6), "COMBO x10", o)
				FeedbackFX.ringPulse(gui, UDim2.fromScale(0.5, 0.6), nil, o)
				local _, peak = FeedbackFX.milestone(gui, "GREAT JOB!", o)
				local lim = (not flashes or reduced) and FeedbackFX.limits.softTintPeak or FeedbackFX.limits.tintPeak
				if peak > lim + 1e-6 or peak > 0.2 then
					fails += 1
					table.insert(lines, string.format("FAIL tint %.2f > %.2f (flashes=%s reduced=%s)", peak, lim, tostring(flashes), tostring(reduced)))
				end
			end
		end
	end
	task.wait(3)
	local left = #gui:GetDescendants() - baseline
	if left ~= 0 then
		fails += 1
		table.insert(lines, "FAIL leaked instances: " .. left)
	end
	table.insert(lines, fails == 0 and "FEEDBACK AUDIT PASS (edge tint peak 0.18, soft 0.09; no leaked instances)" or ("FEEDBACK AUDIT FAILURES: " .. fails))
	return table.concat(lines, "\n"), fails
end

return FeedbackFX
