--!nocheck
-- CutsceneFX: signature-ability cutscenes for featured familiars (cosmetic; the server already applied damage).
-- Installed as ReplicatedStorage.CutsceneFX. A character opts in with the `Signature` attribute on its folder in
-- ReplicatedStorage.Characters; the value names a function in CutsceneFX.signatures.
--
--   CutsceneFX.play(name, ctx) -> duration
--   ctx = { model = <familiar Model>, origin = Vector3, targets = { Vector3 }, color = Color3,
--           title = "STAR DRAKE", ability = "STARFALL", setCamera = function(cf or nil),
--           gameCamera = function() -> CFrame, settings = { reducedMotion, flashes }, sfx = function(name) }
--
-- Shared building blocks (letterbox, camera moves, name cut-in, impact) live in CutsceneFX.kit so every
-- signature has the same polish. Reference: [[Research/Signature Cutscenes]].

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")

local CutsceneFX = { signatures = {}, kit = {} }
local K = CutsceneFX.kit

local okFA, FA = pcall(function()
	return require(RS:WaitForChild("FrameArt", 3))
end)
local okIF, IF = pcall(function()
	return require(RS:WaitForChild("ImpactFX", 3))
end)
FA = okFA and FA and FA.ok and FA or nil
IF = okIF and IF or nil

local function tw(inst, t, props, style, dir)
	local x = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	x:Play()
	return x
end

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	for k, v in props do
		p[k] = v
	end
	p.Parent = parent or workspace
	return p
end

local function wait(t)
	task.wait(t)
end

-- Frame connections a cutscene opens; a skip disconnects them all (T41).
CutsceneFX._conns = {}
local function hold(conn)
	table.insert(CutsceneFX._conns, conn)
	return conn
end

-- ===== kit =====

-- Folder for 3D pieces; destroyed when the cutscene ends.
function K.stage()
	local f = Instance.new("Folder")
	f.Name = "Cutscene"
	f.Parent = workspace
	return f
end

-- Screen overlay with letterbox bars; returns { gui, open(), close() }.
function K.overlay()
	-- hide the HUD (and other screen GUIs) for the length of the cutscene
	local hidden = {}
	for _, g in Players.LocalPlayer.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "CutsceneGui" then
			g.Enabled = false
			table.insert(hidden, g)
		end
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "CutsceneGui"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local bars = {}
	for i, y in { 0, 1 } do
		local b = Instance.new("Frame")
		b.BackgroundColor3 = Color3.new(0, 0, 0)
		b.BorderSizePixel = 0
		b.AnchorPoint = Vector2.new(0, y)
		b.Position = UDim2.fromScale(0, y)
		b.Size = UDim2.fromScale(1, 0)
		b.ZIndex = 20
		b.Parent = gui
		bars[i] = b
	end
	CutsceneFX._hidden = hidden -- lets play() restore the HUD if a signature errors before ov.close()
	local o = { gui = gui }
	function o.open(h)
		for _, b in bars do
			tw(b, 0.35, { Size = UDim2.fromScale(1, h or 0.12) })
		end
	end
	function o.close()
		for _, b in bars do
			tw(b, 0.3, { Size = UDim2.fromScale(1, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		Debris:AddItem(gui, 0.4)
		task.delay(0.3, function()
			for _, g in hidden do
				g.Enabled = true
			end
		end)
	end
	return o
end

-- Smooth camera: moves a CFrameValue and pushes it through ctx.setCamera each frame.
function K.camera(ctx)
	local v = Instance.new("CFrameValue")
	v.Value = ctx.gameCamera()
	local shake = 0
	local conn = hold(RunService.RenderStepped:Connect(function()
		local cf = v.Value
		if shake > 0 and not ctx.settings.reducedMotion and ctx.settings.shake ~= false and IF then
			cf = cf * CFrame.new(IF.shakeOffset(os.clock(), shake))
		end
		ctx.setCamera(cf)
	end))
	local c = {}
	function c.to(cf, t, style, dir)
		if t <= 0 then
			v.Value = cf
		else
			tw(v, t, { Value = cf }, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.InOut)
		end
	end
	function c.shake(amount, t)
		shake = amount
		task.delay(t, function()
			shake = 0
		end)
	end
	function c.done(backT)
		c.to(ctx.gameCamera(), backT or 0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		task.delay(backT or 0.45, function()
			conn:Disconnect()
			v:Destroy()
			ctx.setCamera(nil)
		end)
	end
	return c
end

-- Anime-style cut-in: a slanted glass band slides across with the familiar's portrait and the ability name.
function K.cutIn(ov, ctx, hold, bandAlpha)
	local band = Instance.new("Frame")
	band.AnchorPoint = Vector2.new(0.5, 0.5)
	band.Position = UDim2.fromScale(-0.6, 0.5)
	band.Size = UDim2.fromScale(1.6, 0.26)
	band.Rotation = -7
	band.BackgroundColor3 = Color3.fromRGB(10, 8, 22)
	band.BackgroundTransparency = bandAlpha or 0.08 -- Starfall passes a see-through band so the drake's rise shows
	band.BorderSizePixel = 0
	band.ZIndex = 21
	band.Parent = ov.gui
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(ctx.color:Lerp(Color3.new(0, 0, 0), 0.75), Color3.fromRGB(8, 6, 18))
	g.Parent = band
	for _, y in { 0, 1 } do
		local edge = Instance.new("Frame")
		edge.BorderSizePixel = 0
		edge.BackgroundColor3 = ctx.color
		edge.AnchorPoint = Vector2.new(0, y)
		edge.Position = UDim2.fromScale(0, y)
		edge.Size = UDim2.new(1, 0, 0, 3)
		edge.ZIndex = 22
		edge.Parent = band
		local eg = Instance.new("UIGradient")
		eg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
		eg.Parent = edge
	end
	-- portrait: the familiar itself in a ViewportFrame
	local vpf = Instance.new("ViewportFrame")
	vpf.BackgroundTransparency = 1
	vpf.AnchorPoint = Vector2.new(0.5, 0.5)
	vpf.Position = UDim2.fromScale(0.38, 0.5)
	vpf.Size = UDim2.fromScale(0.16, 1.5)
	vpf.Rotation = 7
	vpf.Ambient = Color3.fromRGB(150, 140, 170)
	vpf.LightColor = Color3.new(1, 1, 1)
	vpf.LightDirection = Vector3.new(-0.5, -0.6, -1)
	vpf.ZIndex = 23
	vpf.Parent = band
	if ctx.model then
		local m = ctx.model:Clone()
		for _, d in m:GetDescendants() do
			if d:IsA("ParticleEmitter") or d:IsA("Light") or d.Name == "Footprint" or d.Name == "FootprintRim" or d.Name == "AuraRing" then
				d:Destroy()
			end
		end
		local cf, size = m:GetBoundingBox()
		m:PivotTo(cf:ToObjectSpace(m:GetPivot()))
		m.Parent = vpf
		local cam = Instance.new("Camera")
		local d = math.max(size.X, size.Y, size.Z) * 1.4
		cam.CFrame = CFrame.lookAt(Vector3.new(-d * 0.35, size.Y * 0.1, d), Vector3.new(0, size.Y * 0.05, 0))
		cam.FieldOfView = 40
		cam.Parent = vpf
		vpf.CurrentCamera = cam
	end
	local function label(text, size, pos, color, font)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.AnchorPoint = Vector2.new(0, 0.5)
		l.Position = pos
		l.Size = UDim2.fromScale(0.4, size)
		l.Rotation = 7
		l.Text = text
		l.TextScaled = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = color
		l.FontFace = font
		l.ZIndex = 24
		l.Parent = band
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Color = Color3.new(0, 0, 0)
		s.Transparency = 0.3
		s.Parent = l
		return l
	end
	local serif = Font.fromName("Merriweather", Enum.FontWeight.Bold)
	label(ctx.title or "", 0.22, UDim2.fromScale(0.47, 0.28), ctx.color:Lerp(Color3.new(1, 1, 1), 0.5), Font.fromName("TitilliumWeb", Enum.FontWeight.SemiBold))
	local big = label(ctx.ability or "", 0.5, UDim2.fromScale(0.465, 0.62), Color3.fromRGB(255, 246, 225), serif)
	-- slide in fast, drift slowly, slide out fast (the classic cut-in rhythm)
	tw(band, 0.28, { Position = UDim2.fromScale(0.52, 0.5) }, Enum.EasingStyle.Quint)
	task.delay(0.28, function()
		tw(band, hold, { Position = UDim2.fromScale(0.48, 0.5) }, Enum.EasingStyle.Linear)
		tw(big, hold, { Position = UDim2.fromScale(0.455, 0.62) }, Enum.EasingStyle.Linear)
	end)
	task.delay(0.28 + hold, function()
		tw(band, 0.22, { Position = UDim2.fromScale(1.7, 0.5) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		Debris:AddItem(band, 0.3)
	end)
	return 0.5 + hold
end

-- Colour grade for the whole cutscene: world darkens and desaturates so the ability colour pops.
function K.grade(color)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "CutsceneGrade"
	cc.Parent = Lighting
	tw(cc, 0.3, { Saturation = -0.45, Brightness = -0.12, Contrast = 0.15, TintColor = Color3.new(1, 1, 1):Lerp(color, 0.12) })
	return function()
		tw(cc, 0.4, { Saturation = 0, Brightness = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) })
		Debris:AddItem(cc, 0.45)
	end
end

-- Painted magic circle flat on the ground; returns the part (spin it with K.spin).
function K.circle(stage, pos, radius, color)
	local p = part({ Size = Vector3.new(radius * 2, 0.05, radius * 2), CFrame = CFrame.new(pos.X, pos.Y + 0.08, pos.Z), Transparency = 1 }, stage)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Top
	sg.LightInfluence = 0
	sg.Brightness = 2.5
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 12
	sg.Parent = p
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.ImageColor3 = color
	img.ImageTransparency = 1
	if FA then
		img.ImageContent = FA.sigil()
	end
	img.Parent = sg
	tw(img, 0.4, { ImageTransparency = 0 })
	p:SetAttribute("BaseCF", p.CFrame)
	return p, img
end

function K.spin(p, speed, t)
	local t0 = os.clock()
	local base = p.CFrame
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local e = os.clock() - t0
		if e > t or not p.Parent then
			conn:Disconnect()
			return
		end
		p.CFrame = base * CFrame.Angles(0, e * speed, 0)
	end)
end

-- Expanding flat ring (shockwave) on the ground.
function K.shockwave(stage, pos, color, radius, t)
	local p = part({ Shape = Enum.PartType.Cylinder, Color = color, Transparency = 0.1, Size = Vector3.new(0.15, 2, 2), CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2) }, stage)
	tw(p, t or 0.5, { Size = Vector3.new(0.15, radius * 2, radius * 2), Transparency = 1 }, Enum.EasingStyle.Quint)
	Debris:AddItem(p, (t or 0.5) + 0.05)
end

-- Particles converging on a point (charge-up).
function K.gather(stage, pos, color, n, radius, t)
	for i = 1, n do
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit
		local m = part({ Shape = Enum.PartType.Ball, Color = color, Size = Vector3.one * (0.25 + math.random() * 0.35), Position = pos + dir * radius * (0.7 + math.random() * 0.5) }, stage)
		local delay = math.random() * t * 0.6
		task.delay(delay, function()
			tw(m, t - delay, { Position = pos, Size = Vector3.one * 0.05 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end)
		Debris:AddItem(m, t + 0.05)
	end
end

-- Screen flash (capped by the flashes setting).
function K.flash(ov, ctx, color, peak, t)
	if ctx.settings.flashes == false then
		peak = math.min(peak, 0.2)
	end
	local f = Instance.new("Frame")
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundTransparency = 1 - peak
	f.ZIndex = 19
	f.Parent = ov.gui
	tw(f, t, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
	Debris:AddItem(f, t + 0.05)
end


-- ===== beam and impact kit (recipe: Roblox Dev/Research/VFX and Animation/Beam and Impact VFX Recipes.md) =====
local UIS = game:GetService("UserInputService")
local LIGHT = UIS.TouchEnabled and not UIS.KeyboardEnabled -- phones get fewer parts

local function anchorAt(stage, pos)
	return part({ Transparency = 1, Size = Vector3.one * 0.2, Position = pos }, stage)
end
CutsceneFX.anchorAt = anchorAt

-- A beam as stacked layers: white-hot core, wide coloured glow, two thin bent streaks.
-- from/to are parts (move `to` and the beam follows). Returns h with h.grow(t), h.fade(t).
function K.beam(from, to, color, w)
	local layers = {
		{ w = 0.35 * w, col = Color3.fromRGB(255, 255, 248), tr = 0, off = 0, curve = 0 },
		{ w = 1.7 * w, col = color, tr = 0.5, off = 0, curve = 0 },
		{ w = 0.16 * w, col = color:Lerp(Color3.new(1, 1, 1), 0.55), tr = 0.1, off = 0.9 * w, curve = 0.7 },
		{ w = 0.16 * w, col = color:Lerp(Color3.new(1, 1, 1), 0.55), tr = 0.1, off = -0.9 * w, curve = -0.7 },
	}
	local beams = {}
	for _, L in layers do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(L.off, 0, 0), Vector3.new(L.off, 0, 0)
		a0.Parent, a1.Parent = from, to
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = a0, a1
		b.Color = ColorSequence.new(L.col)
		b.Transparency = NumberSequence.new(L.tr)
		b.LightEmission = 1
		b.LightInfluence = 0
		b.FaceCamera = true
		b.Segments = 12
		b.CurveSize0, b.CurveSize1 = L.curve * 2, -L.curve * 2
		b.Width0, b.Width1 = 0, 0
		b.Parent = from
		table.insert(beams, { beam = b, w = L.w })
	end
	local h = {}
	-- narrow at the far end, wide at the near end: reads as a strike
	function h.grow(t, mult)
		for _, e in beams do
			tw(e.beam, t, { Width0 = e.w * 0.25 * (mult or 1), Width1 = e.w * (mult or 1) }, Enum.EasingStyle.Quint)
		end
	end
	function h.fade(t)
		for _, e in beams do
			tw(e.beam, t, { Width0 = 0, Width1 = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		Debris:AddItem(from, t + 0.1)
		Debris:AddItem(to, t + 0.1)
	end
	return h
end

-- Bracketed stage caption in the letterbox, e.g. "[ IMPACT CONFIRMED ]".
function K.caption(ov, text, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 1)
	l.Position = UDim2.fromScale(0.5, 0.875)
	l.Size = UDim2.fromScale(0.6, 0.05)
	l.Text = text
	l.TextScaled = true
	l.TextColor3 = color or Color3.fromRGB(255, 240, 210)
	l.FontFace = Font.fromName("Merriweather", Enum.FontWeight.Bold)
	l.TextTransparency = 1
	l.ZIndex = 25
	l.Parent = ov.gui
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Color3.new(0, 0, 0)
	s.Parent = l
	if ov.lastCaption and ov.lastCaption.Parent then
		ov.lastCaption:Destroy() -- one caption at a time (two phases close together overlapped)
	end
	ov.lastCaption = l
	tw(l, 0.2, { TextTransparency = 0 })
	task.delay(0.9, function()
		tw(l, 0.3, { TextTransparency = 1 })
		Debris:AddItem(l, 0.4)
	end)
end

-- Full impact: ground ring, shockwave, short light column, debris, dust, lingering glow, then a smaller
-- second detonation 0.4 s later (Lunar Judgment pattern).
function K.impact(stage, pos, color, size)
	size = size or 1
	local white = Color3.fromRGB(255, 250, 235)
	local ring = part({ Shape = Enum.PartType.Cylinder, Color = color, Transparency = 0.25, Size = Vector3.new(0.1, 3 * size, 3 * size), CFrame = CFrame.new(pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2) }, stage)
	tw(ring, 1.0, { Size = Vector3.new(0.1, 11 * size, 11 * size), Transparency = 1 }, Enum.EasingStyle.Quint)
	K.shockwave(stage, pos, white, 9 * size, 0.45)
	local col = part({ Shape = Enum.PartType.Cylinder, Color = color, Transparency = 0.3, Size = Vector3.new(1, 1.6 * size, 1.6 * size), CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2) }, stage)
	tw(col, 0.5, { Size = Vector3.new(16 * size, 0.2, 0.2), Transparency = 1 }, Enum.EasingStyle.Quint)
	local glow = part({ Shape = Enum.PartType.Ball, Color = color, Transparency = 0.62, Size = Vector3.one * 1.8 * size, Position = pos + Vector3.new(0, 1, 0) }, stage) -- fainter: v1 read as a solid blob
	tw(glow, 0.7, { Size = Vector3.one * 4.5 * size, Transparency = 1 }, Enum.EasingStyle.Sine)
	K.glint(stage, pos + Vector3.new(0, 1.2, 0), color, 7 * size, 0.35)
	for _ = 1, LIGHT and 3 or 6 do -- glowing shards (2026-10-28: were grey slate cubes, "effects lacking")
		local d = part({ Shape = Enum.PartType.Wedge, Material = Enum.Material.Neon, Color = color:Lerp(Color3.new(1, 1, 1), math.random() * 0.5), Size = Vector3.new(0.12, 0.7, 0.3) * size, CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0) }, stage)
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.9 + 0.5, math.random() - 0.5).Unit
		tw(d, 0.3, { Position = pos + dir * 4 * size }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.3, function()
			tw(d, 0.35, { Position = pos + Vector3.new(dir.X * 5, 0.2, dir.Z * 5) * size, Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end)
		Debris:AddItem(d, 0.75)
	end
	for k = 1, LIGHT and 5 or 10 do -- motes skim outward along the ground (was a grey dust ball)
		local a = k / (LIGHT and 5 or 10) * math.pi * 2 + math.random() * 0.4
		local mote = part({ Shape = Enum.PartType.Ball, Color = color:Lerp(Color3.new(1, 1, 1), 0.6), Size = Vector3.one * 0.18 * size, Position = pos + Vector3.new(0, 0.3, 0) }, stage)
		tw(mote, 0.6, { Position = pos + Vector3.new(math.cos(a) * 4.5, 0.5 + math.random(), math.sin(a) * 4.5) * size + Vector3.new(0, 0, 0), Size = Vector3.one * 0.05, Transparency = 1 }, Enum.EasingStyle.Quart)
		Debris:AddItem(mote, 0.65)
	end
	task.delay(0.4, function()
		K.shockwave(stage, pos, color, 5 * size, 0.35)
		local b = part({ Shape = Enum.PartType.Ball, Color = white, Transparency = 0.1, Size = Vector3.one * size, Position = pos + Vector3.new(0, 0.8, 0) }, stage)
		tw(b, 0.3, { Size = Vector3.one * 3.5 * size, Transparency = 1 })
		Debris:AddItem(b, 0.35)
	end)
end

-- ===== 2026-10-28 upgrades from the user's reference set 2 (Roblox Dev/Research/UI/Loading, Intro and UI References 2.md)

-- A star glint: two crossed thin lines and a bright point on a BillboardGui (always faces the camera). It snaps open
-- and shrinks away. corektvfx's star burst.
function K.glint(stage, pos, color, studs, t)
	local a = anchorAt(stage, pos)
	local bb = Instance.new("BillboardGui")
	bb.Size, bb.AlwaysOnTop, bb.LightInfluence = UDim2.fromScale(studs, studs), false, 0
	bb.Parent = a
	local root = Instance.new("Frame")
	root.BackgroundTransparency, root.AnchorPoint, root.Position, root.Size = 1, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.15, 0.15)
	root.Parent = bb
	for _, r in { 0, 90, 45, -45 } do
		local l = Instance.new("Frame")
		l.BorderSizePixel, l.AnchorPoint, l.Position, l.Rotation = 0, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), r
		l.Size = UDim2.new(r % 90 == 0 and 1 or 0.55, 0, 0.035, 0)
		l.BackgroundColor3 = r % 90 == 0 and Color3.new(1, 1, 1) or color
		l.Parent = root
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
		g.Parent = l
	end
	local dot = Instance.new("Frame")
	dot.BorderSizePixel, dot.AnchorPoint, dot.Position, dot.Size, dot.BackgroundColor3 = 0, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.12, 0.12), Color3.new(1, 1, 1)
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	dot.Parent = root
	tw(root, t * 0.3, { Size = UDim2.fromScale(1, 1), Rotation = 20 }, Enum.EasingStyle.Quint)
	task.delay(t * 0.3, function()
		tw(root, t * 0.7, { Size = UDim2.fromScale(0, 0), Rotation = 60 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
	Debris:AddItem(a, t + 0.1)
end

-- A diagonal light slam: a layered beam drops from the sky at a slant onto pos, with a glint where it lands and a
-- short streak of light along the ground (corektvfx's falling star).
function K.slam(stage, pos, color, size)
	size = size or 1
	local dir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
	dir = dir.Magnitude > 0.05 and dir.Unit or Vector3.xAxis
	local top = anchorAt(stage, pos - dir * 16 * size + Vector3.new(0, 30 * size, 0))
	local bot = anchorAt(stage, pos)
	local b = K.beam(top, bot, color, 1.6 * size)
	b.grow(0.07, 1.2)
	task.delay(0.12, function() b.fade(0.35) end)
	K.glint(stage, pos + Vector3.new(0, 0.6, 0), color, 9 * size, 0.45)
	local streak = part({ Material = Enum.Material.Neon, Color = color:Lerp(Color3.new(1, 1, 1), 0.4), Transparency = 0.2, Size = Vector3.new(0.25, 0.08, 0.2) * size, CFrame = CFrame.lookAt(pos + Vector3.new(0, 0.1, 0), pos + dir + Vector3.new(0, 0.1, 0)) }, stage)
	tw(streak, 0.25, { Size = Vector3.new(0.25, 0.08, 9) * size, CFrame = CFrame.lookAt(pos + dir * 4.5 * size + Vector3.new(0, 0.1, 0), pos + dir * 10 + Vector3.new(0, 0.1, 0)) }, Enum.EasingStyle.Quint)
	task.delay(0.25, function() tw(streak, 0.35, { Transparency = 1, Size = Vector3.new(0.05, 0.05, 9) * size }) end)
	Debris:AddItem(streak, 0.7)
end

-- The crystal core (fxroxx's hero object): a white-hot centre, two ghost shells (glow by duplication), three tilted
-- rings of points that turn, and six crystal shards circling. Returns c with c.model, c.at(pos), c.scale(s), c.destroy().
function K.core(stage, pos, color)
	local m = Instance.new("Model")
	m.Name = "Core"
	m.Parent = stage
	local centre = part({ Shape = Enum.PartType.Ball, Color = Color3.new(1, 1, 1), Size = Vector3.one * 0.5 }, m)
	m.PrimaryPart = centre -- so the model's pivot follows the centre (echo copies read it)
	local shells = {
		part({ Shape = Enum.PartType.Ball, Color = color:Lerp(Color3.new(1, 1, 1), 0.3), Transparency = 0.55, Size = Vector3.one * 0.85 }, m),
		part({ Shape = Enum.PartType.Ball, Color = color, Transparency = 0.82, Size = Vector3.one * 1.5 }, m),
	}
	local rings, shards = {}, {}
	for r, tilt in { CFrame.Angles(math.rad(70), 0, 0), CFrame.Angles(math.rad(70), math.rad(60), 0), CFrame.Angles(math.rad(70), math.rad(-60), 0) } do
		local pts = {}
		for i = 1, LIGHT and 10 or 16 do
			pts[i] = part({ Shape = Enum.PartType.Ball, Color = r == 1 and Color3.new(1, 1, 1) or color:Lerp(Color3.new(1, 1, 1), 0.5), Size = Vector3.one * 0.09 }, m)
		end
		rings[r] = { tilt = tilt, pts = pts, speed = (r % 2 == 0 and -1 or 1) * (1.2 + r * 0.4) }
	end
	for i = 1, LIGHT and 3 or 6 do
		shards[i] = part({ Shape = Enum.PartType.Wedge, Color = color:Lerp(Color3.fromRGB(200, 240, 255), 0.5), Transparency = 0.15, Size = Vector3.new(0.08, 0.45, 0.16) }, m)
	end
	local c = { model = m, pos = pos, s = 1 }
	local t0 = os.clock()
	local conn
	conn = hold(RunService.RenderStepped:Connect(function()
		if not m.Parent then conn:Disconnect() return end
		local t, s, p = os.clock() - t0, c.s, c.pos
		centre.CFrame = CFrame.new(p)
		centre.Size = Vector3.one * 0.5 * s
		shells[1].CFrame, shells[1].Size = CFrame.new(p), Vector3.one * 0.85 * s * (1 + math.sin(t * 9) * 0.05)
		shells[2].CFrame, shells[2].Size = CFrame.new(p), Vector3.one * 1.5 * s * (1 + math.sin(t * 6) * 0.08)
		for _, ring in rings do
			local n = #ring.pts
			for i, pt in ring.pts do
				local a = i / n * math.pi * 2 + t * ring.speed
				pt.CFrame = CFrame.new(p) * ring.tilt * CFrame.new(math.cos(a) * 1.1 * s, math.sin(a) * 1.1 * s, 0)
				pt.Size = Vector3.one * 0.09 * math.max(1, s * 0.6)
			end
		end
		for i, sh in shards do
			local a = i / #shards * math.pi * 2 - t * 1.7
			local out = Vector3.new(math.cos(a), math.sin(t * 2 + i) * 0.3, math.sin(a))
			sh.CFrame = CFrame.lookAt(p + out * 1.5 * s, p + out * 3 * s) * CFrame.Angles(math.pi / 2, 0, 0)
			sh.Size = Vector3.new(0.08, 0.45, 0.16) * s
		end
	end))
	function c.at(p) c.pos = p end
	function c.scale(s) c.s = s end
	function c.destroy() conn:Disconnect() m:Destroy() end
	return c
end

-- ===== signatures =====

-- STAR DRAKE · STARFALL
-- 0.0  letterbox, grade, low push-in on the drake, magic circle opens under it
-- 0.5  cut-in band (portrait + STARFALL), gold motes gather, drake rises
-- 1.6  camera whips up to the sky: stars appear in a ring above the field
-- 2.1  stars fall in a staggered rain onto every target, each with a trail
-- 2.3+ impacts: shockwaves, scorch, impact frame, shake
-- 3.3  camera eases back, letterbox out
CutsceneFX.signatures.Starfall = function(ctx)
	local stage = K.stage()
	local ov = K.overlay()
	local cam = K.camera(ctx)
	local ungrade = K.grade(ctx.color)
	local gold = Color3.fromRGB(255, 214, 120)
	local o = ctx.origin
	ov.open(0.11)
	ctx.sfx("legendary_gather")

	-- gold ring and sparks instead of K.impact's flat white discs
	local function starImpact(pos)
		K.shockwave(stage, pos, gold, 7, 0.45)
		local ring = part({ Shape = Enum.PartType.Cylinder, Color = gold, Transparency = 0.2, Size = Vector3.new(0.1, 3, 3), CFrame = CFrame.new(pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2) }, stage)
		tw(ring, 0.6, { Size = Vector3.new(0.1, 12, 12), Transparency = 1 }, Enum.EasingStyle.Quint)
		Debris:AddItem(ring, 0.65)
		for k = 1, 8 do
			local a = k / 8 * math.pi * 2 + math.random() * 0.3
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local spark = part({ Shape = Enum.PartType.Wedge, Material = Enum.Material.Neon, Color = gold, Size = Vector3.new(0.1, 0.5, 0.25), CFrame = CFrame.lookAt(pos + Vector3.new(0, 0.6, 0), pos + Vector3.new(0, 0.6, 0) + dir) }, stage)
			tw(spark, 0.35, { Position = pos + dir * 6 + Vector3.new(0, 0.6, 0), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			Debris:AddItem(spark, 0.45)
		end
	end

	-- 0.0 low angle push-in
	local side = Vector3.new(1, 0, 0.35).Unit
	cam.to(CFrame.lookAt(o + side * 14 + Vector3.new(0, 3, 0), o + Vector3.new(0, 3, 0)), 0)
	cam.to(CFrame.lookAt(o + side * 9 + Vector3.new(0, 2.2, 0), o + Vector3.new(0, 3.6, 0)), 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local circ = K.circle(stage, o, 9, gold)
	K.spin(circ, 0.9, 3.4)
	K.gather(stage, o + Vector3.new(0, 3, 0), gold, 28, 9, 1.4)

	-- the drake rises on a column of light
	K.caption(ov, "[ STARS GATHER ]", gold)
	local column = K.beam(anchorAt(stage, o + Vector3.new(0, 38, 0)), anchorAt(stage, o), Color3.fromRGB(190, 150, 84), 1.1)
	column.grow(0.8)
	local model = ctx.model
	local home = model and model:GetPivot()
	if model then
		-- the game's frame loop places pets every frame, so lift goes through an attribute it adds on top
		model:SetAttribute("CutsceneLift", 0)
		local lift = Instance.new("NumberValue")
		lift.Changed:Connect(function(v)
			if model.Parent then
				model:SetAttribute("CutsceneLift", v)
			end
		end)
		tw(lift, 1.4, { Value = 3.2 }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		task.delay(3.1, function()
			tw(lift, 0.4, { Value = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Debris:AddItem(lift, 0.5)
		end)
	end
	wait(0.45)
	ctx.sfx("summon")
	K.cutIn(ov, ctx, 0.75, 0.55)
	cam.shake(0.25, 1.0)
	wait(1.15)

	-- 1.6 whip up to the sky over the field
	local center = Vector3.zero
	for _, t in ctx.targets do
		center += t
	end
	center = #ctx.targets > 0 and center / #ctx.targets or o
	ctx.sfx("ultimate_summon")
	cam.to(CFrame.lookAt(center + Vector3.new(0, 18, 34), center + Vector3.new(0, 30, -10)), 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local stars = {}
	local n = math.clamp(#ctx.targets, 6, 14)
	for i = 1, n do
		local a = i / n * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * 22, 42 + math.sin(i * 1.7) * 4, math.sin(a) * 14 - 8)
		local s = part({ Shape = Enum.PartType.Ball, Color = gold, Size = Vector3.one * 0.2, Position = p }, stage)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = gold, 10, 2
		l.Parent = s
		tw(s, 0.3, { Size = Vector3.one * 2.4 }, Enum.EasingStyle.Back)
		stars[i] = s
	end
	wait(0.45)

	-- 2.1 the rain: camera pulls back to frame the field, stars fall in a stagger
	cam.to(CFrame.lookAt(center + Vector3.new(0, 34, 40), center), 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	ctx.sfx("ultimate_fall")
	K.caption(ov, "[ STARFALL ]", gold)
	for i, s in stars do
		local target = ctx.targets[(i - 1) % math.max(#ctx.targets, 1) + 1] or (center + Vector3.new(math.random(-14, 14), 0, math.random(-10, 10)))
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(0.6, 0, 0), Vector3.new(-0.6, 0, 0)
		a0.Parent, a1.Parent = s, s
		local tr = Instance.new("Trail")
		tr.Attachment0, tr.Attachment1 = a0, a1
		tr.Color = ColorSequence.new(gold, Color3.fromRGB(200, 150, 70))
		tr.Transparency = NumberSequence.new(0, 1)
		tr.Lifetime = 0.35
		tr.LightEmission = 1
		tr.FaceCamera = true
		tr.Parent = s
		task.delay((i - 1) * 0.07, function()
			local fall = 0.32
			local strike = K.beam(anchorAt(stage, s.Position), s, gold, 1.3)
			strike.grow(0.12)
			tw(s, fall, { Position = target + Vector3.new(0, 1, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(fall, function()
				if i == 1 then
					ctx.sfx("ultimate_impact")
					K.caption(ov, "[ IMPACT CONFIRMED ]", Color3.fromRGB(255, 240, 210))
					if IF then
						IF.impactFrame(ctx.settings)
					end
					cam.shake(1.0, 0.8)
				end
				strike.fade(0.35)
				starImpact(target)
				if IF then IF.scorch(target, 2.5, 2.2) end
				s:Destroy()
			end)
		end)
	end
	wait(0.32 + n * 0.07)
	K.flash(ov, ctx, gold, 0.35, 0.4)
	K.shockwave(stage, center, Color3.fromRGB(255, 220, 140), 30, 0.7)
	wait(0.45)

	-- 3.3 return
	column.fade(0.3)
	cam.done(0.5)
	ov.close()
	ungrade()
	task.delay(0.6, function()
		stage:Destroy()
	end)
	return true
end

-- ARCANE FOX · GRAND ARCANA
-- 0.0 camera circles the fox while seven cards rise and fan out around it; cut-in
-- 1.6 camera lifts; each card flies out and stands face-down over an enemy
-- 2.4 every card flips at once to show a glowing eye (the "reading")
-- 2.8 each card collapses into a violet pillar; shockwaves, impact frame
-- 3.6 return
CutsceneFX.signatures.GrandArcana = function(ctx)
	local stage = K.stage()
	local ov = K.overlay()
	local cam = K.camera(ctx)
	local violet = Color3.fromRGB(190, 130, 255)
	local gold = Color3.fromRGB(240, 205, 120)
	local ungrade = K.grade(violet)
	local o = ctx.origin + Vector3.new(0, 2.6, 0)
	ov.open(0.11)
	ctx.sfx("anticipation")
	-- orbit: four keyframes around the fox
	for k = 0, 3 do
		local a = k * 0.55
		task.delay(k * 0.4, function()
			cam.to(CFrame.lookAt(o + Vector3.new(math.cos(a) * 11, 2.5 + k * 0.6, math.sin(a) * 11), o), 0.4, Enum.EasingStyle.Linear)
		end)
	end
	local cards = {}
	local n = 7
	for i = 1, n do
		local card = Instance.new("Model")
		card.Name = "Card"
		local back = part({ Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(46, 28, 80), Size = Vector3.new(2.1, 3.1, 0.1) }, card)
		local edge = part({ Color = gold, Size = Vector3.new(2.3, 3.3, 0.06), Transparency = 0.1 }, card)
		local eye = part({ Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(255, 236, 190), Size = Vector3.new(0.04, 1.2, 1.2), Transparency = 1 }, card)
		card.PrimaryPart = back
		card:SetAttribute("i", i)
		card.Parent = stage
		cards[i] = { model = card, back = back, edge = edge, eye = eye }
	end
	local function setCard(c, cf)
		c.back.CFrame = cf
		c.edge.CFrame = cf * CFrame.new(0, 0, 0.04)
		c.eye.CFrame = cf * CFrame.new(0, 0, -0.07) * CFrame.Angles(0, math.pi / 2, 0)
	end
	-- rise and fan out in a slowly turning ring
	local t0 = os.clock()
	local ringConn = hold(RunService.Heartbeat:Connect(function()
		local e = os.clock() - t0
		for i, c in cards do
			if not c.flying then
				local a = i / n * math.pi * 2 + e * 1.2
				local r = math.min(1, e / 0.6) * 4.5
				local p = o + Vector3.new(math.cos(a) * r, math.min(1, e / 0.6) * 1.5 + math.sin(e * 3 + i) * 0.2, math.sin(a) * r)
				setCard(c, CFrame.lookAt(p, p + (p - o) * Vector3.new(1, 0, 1)))
			end
		end
	end))
	K.gather(stage, o, violet, 18, 7, 1.2)
	K.caption(ov, "[ THE CARDS ARE DRAWN ]", Color3.fromRGB(225, 200, 255))
	wait(0.4)
	ctx.sfx("summon")
	K.cutIn(ov, ctx, 0.75)
	wait(1.2)
	-- fly to targets and stand face-down
	local center = Vector3.zero
	for _, t in ctx.targets do
		center += t
	end
	center = #ctx.targets > 0 and center / #ctx.targets or ctx.origin
	cam.to(CFrame.lookAt(center + Vector3.new(0, 22, 30), center), 0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	ctx.sfx("ultimate_summon")
	local spots = {}
	for i, c in cards do
		local target = ctx.targets[(i - 1) % math.max(#ctx.targets, 1) + 1] or (center + Vector3.new(math.random(-12, 12), 0, math.random(-8, 8)))
		target = target + Vector3.new((i - 1) // math.max(#ctx.targets, 1) * 2.2, 0, 0)
		spots[i] = target
		c.flying = true
		local from = c.back.CFrame
		local dest = CFrame.lookAt(target + Vector3.new(0, 3.5, 0), target + Vector3.new(0, 3.5, 10))
		task.delay(i * 0.05, function()
			local s = os.clock()
			local conn
			conn = RunService.Heartbeat:Connect(function()
				local a = math.min(1, (os.clock() - s) / 0.4)
				local ea = TweenService:GetValue(a, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				local p = from.Position:Lerp(dest.Position, ea) + Vector3.new(0, math.sin(a * math.pi) * 4, 0)
				setCard(c, CFrame.new(p) * (from.Rotation:Lerp(dest.Rotation, ea)) * CFrame.Angles(0, (1 - ea) * 6, 0))
				if a >= 1 then
					conn:Disconnect()
				end
			end)
		end)
	end
	wait(0.85)
	ringConn:Disconnect()
	-- the reading: every card flips at once
	ctx.sfx("ring")
	K.caption(ov, "[ THE READING ]", gold)
	for i, c in cards do
		local base = c.back.CFrame
		local v = Instance.new("NumberValue")
		v.Changed:Connect(function(a)
			setCard(c, base * CFrame.Angles(0, a * math.pi, 0))
		end)
		tw(v, 0.3, { Value = 1 }, Enum.EasingStyle.Back)
		tw(c.eye, 0.3, { Transparency = 0 })
		c.back.Color = Color3.fromRGB(70, 40, 120)
		Debris:AddItem(v, 0.4)
	end
	cam.shake(0.3, 0.4)
	wait(0.55)
	-- collapse into pillars
	ctx.sfx("ultimate_impact")
	if IF then
		IF.impactFrame(ctx.settings)
	end
	cam.shake(1.0, 0.6)
	K.caption(ov, "[ JUDGEMENT FALLS ]", violet)
	for i, c in cards do
		local p = spots[i]
		-- each card becomes a layered pillar of light (white core, violet glow, bent streaks) driven into the ground
		local pillar = K.beam(anchorAt(stage, p + Vector3.new(0, 30, 0)), anchorAt(stage, p), violet, 1.6)
		pillar.grow(0.12, 1.2)
		task.delay(0.35, function()
			pillar.fade(0.35)
		end)
		K.impact(stage, p, violet, 0.8)
		for _, q in { c.back, c.edge, c.eye } do
			tw(q, 0.2, { Transparency = 1, Size = q.Size * 0.3 })
		end
		K.shockwave(stage, p, violet, 6, 0.5)
		if IF then
			IF.scorch(p, 2.2, 2)
		end
	end
	K.flash(ov, ctx, violet, 0.3, 0.4)
	wait(0.7)
	cam.done(0.5)
	ov.close()
	ungrade()
	task.delay(0.6, function()
		stage:Destroy()
	end)
	return true
end

-- FROSTLING · WINTER'S HUSH
-- 0.0 the world drains to cold blue; frost spreads out across the street from the Frostling; cut-in
-- 1.5 ice crystals close around every enemy; everything holds still (the hush), snow drifts
-- 2.3 a single crack: every crystal shatters at once; shards, flash, impact frame
-- 3.2 the frost melts away; return
CutsceneFX.signatures.WintersHush = function(ctx)
	local stage = K.stage()
	local ov = K.overlay()
	local cam = K.camera(ctx)
	local ice = Color3.fromRGB(170, 230, 255)
	local ungrade = K.grade(ice)
	local o = ctx.origin
	ov.open(0.11)
	ctx.sfx("vortex")
	cam.to(CFrame.lookAt(o + Vector3.new(-8, 2.2, 9), o + Vector3.new(0, 2.5, 0)), 0)
	cam.to(CFrame.lookAt(o + Vector3.new(-10, 9, 16), o + Vector3.new(6, 0, -4)), 1.4)
	-- frost sheet spreading out
	local frost = part({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Ice, Color = Color3.fromRGB(190, 225, 245), Transparency = 0.15, Size = Vector3.new(0.12, 1, 1), CFrame = CFrame.new(o + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2) }, stage)
	tw(frost, 1.2, { Size = Vector3.new(0.12, 90, 90) }, Enum.EasingStyle.Quart)
	local rim = part({ Shape = Enum.PartType.Cylinder, Color = ice, Transparency = 0.2, Size = Vector3.new(0.1, 1, 1), CFrame = frost.CFrame * CFrame.new(0.02, 0, 0) }, stage)
	tw(rim, 1.2, { Size = Vector3.new(0.1, 92, 92), Transparency = 1 }, Enum.EasingStyle.Quart)
	-- crystal spikes popping up behind the frost front
	task.spawn(function()
		for k = 1, 22 do
			local a = math.random() * math.pi * 2
			local r = 3 + (k / 22) * 30
			local p = o + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local h = 1 + math.random() * 1.8
			local spike = part({ Material = Enum.Material.Ice, Color = Color3.fromRGB(200, 240, 255), Transparency = 0.05, Size = Vector3.new(0.5, 0.1, 0.5), CFrame = CFrame.new(p) * CFrame.Angles(math.random() * 0.5, math.random() * 6, math.random() * 0.5) }, stage)
			tw(spike, 0.25, { Size = Vector3.new(0.5, h, 0.5), CFrame = spike.CFrame * CFrame.new(0, h / 2, 0) }, Enum.EasingStyle.Back)
			task.wait(0.05)
		end
	end)
	wait(0.35)
	ctx.sfx("summon")
	K.caption(ov, "[ THE FROST SPREADS ]", ice)
	K.cutIn(ov, ctx, 0.75)
	wait(1.15)
	-- the hush: crystals close around the enemies, snow drifts, everything holds
	local center = Vector3.zero
	for _, t in ctx.targets do
		center += t
	end
	center = #ctx.targets > 0 and center / #ctx.targets or o
	cam.to(CFrame.lookAt(center + Vector3.new(4, 7, 16), center + Vector3.new(0, 1.5, 0)), 0.8, Enum.EasingStyle.Sine)
	local blocks = {}
	local list = #ctx.targets > 0 and ctx.targets or { center }
	-- each enemy is sealed in a crystal cluster: tall shards leaning in around a glowing core
	for i, t in list do
		local cluster = {}
		local core = part({ Shape = Enum.PartType.Ball, Color = Color3.fromRGB(160, 230, 255), Transparency = 0.2, Size = Vector3.one * 0.3, Position = t + Vector3.new(0, 1.8, 0) }, stage)
		tw(core, 0.3, { Size = Vector3.one * 1.6 }, Enum.EasingStyle.Back)
		table.insert(cluster, core)
		for k = 1, 6 do
			local a = k / 6 * math.pi * 2 + i
			local h = 3.2 + (k % 3) * 0.9
			local base = t + Vector3.new(math.cos(a) * 1.1, 0, math.sin(a) * 1.1)
			local cf = CFrame.new(base) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, 0.32)
			local sh = part({ Material = Enum.Material.Ice, Color = Color3.fromRGB(205, 240, 255), Transparency = 0.05, Size = Vector3.new(0.9, 0.2, 0.9), CFrame = cf }, stage)
			tw(sh, 0.25 + k * 0.03, { Size = Vector3.new(0.9, h, 0.9), CFrame = cf * CFrame.new(0, h / 2, 0) }, Enum.EasingStyle.Back)
			table.insert(cluster, sh)
		end
		blocks[i] = cluster
	end
	ctx.sfx("ring")
	K.caption(ov, "[ HUSH ]", Color3.fromRGB(230, 245, 255))
	local snow = part({ Transparency = 1, Size = Vector3.new(60, 1, 40), CFrame = CFrame.new(center + Vector3.new(0, 16, 0)) }, stage)
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.new(1, 1, 1))
	pe.LightEmission = 0.5
	pe.Size = NumberSequence.new(0.2)
	pe.Rate = 160
	pe.Lifetime = NumberRange.new(3, 4)
	pe.Speed = NumberRange.new(2, 3)
	pe.EmissionDirection = Enum.NormalId.Bottom
	pe.Parent = snow
	wait(0.75)
	-- the crack
	ctx.sfx("ultimate_impact")
	if IF then
		IF.impactFrame(ctx.settings)
	end
	cam.shake(1.0, 0.6)
	-- frost ring and glass shards instead of K.impact's soft white balls
	local function frostRing(pos)
		local ring = part({ Shape = Enum.PartType.Cylinder, Color = ice, Transparency = 0.2, Size = Vector3.new(0.1, 2.5, 2.5), CFrame = CFrame.new(pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2) }, stage)
		tw(ring, 0.6, { Size = Vector3.new(0.1, 10, 10), Transparency = 1 }, Enum.EasingStyle.Quint)
		Debris:AddItem(ring, 0.65)
		for k = 1, 6 do
			local a = k / 6 * math.pi * 2 + math.random() * 0.3
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local shard = part({ Material = Enum.Material.Glass, Color = ice, Transparency = 0.1, Size = Vector3.new(0.12, 0.6, 0.3), CFrame = CFrame.lookAt(pos + Vector3.new(0, 0.6, 0), pos + Vector3.new(0, 0.6, 0) + dir) }, stage)
			tw(shard, 0.4, { Position = pos + dir * 5 + Vector3.new(0, 0.6, 0), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			Debris:AddItem(shard, 0.5)
		end
	end
	for _, cluster in blocks do
		local b = cluster[1]
		local p = b.Position
		for k = 2, #cluster do
			cluster[k]:Destroy()
		end
		for k = 1, 7 do
			local s = part({ Material = Enum.Material.Glass, Color = Color3.fromRGB(210, 245, 255), Transparency = 0.1, Size = Vector3.new(0.5, 0.9, 0.3), CFrame = CFrame.new(p) * CFrame.Angles(math.random() * 6, math.random() * 6, 0) }, stage)
			local dir = Vector3.new(math.random() - 0.5, math.random() * 0.9 + 0.1, math.random() - 0.5).Unit
			tw(s, 0.55, { CFrame = s.CFrame + dir * 6 - Vector3.new(0, 1.5, 0), Transparency = 1 }, Enum.EasingStyle.Quad)
		end
		b:Destroy()
		K.shockwave(stage, p - Vector3.new(0, 1.8, 0), ice, 7, 0.5)
		frostRing(p - Vector3.new(0, 1.8, 0))
	end
	K.flash(ov, ctx, Color3.fromRGB(220, 245, 255), 0.4, 0.45)
	K.caption(ov, "[ SHATTERED ]", ice)
	pe.Rate = 0
	wait(0.6)
	tw(frost, 0.6, { Transparency = 1 })
	for _, c in stage:GetChildren() do
		if c:IsA("BasePart") and c.Material == Enum.Material.Glass then
			tw(c, 0.5, { Transparency = 1 })
		end
	end
	cam.done(0.5)
	ov.close()
	ungrade()
	task.delay(0.7, function()
		stage:Destroy()
	end)
	return true
end

CutsceneFX.duration = { Starfall = 3.9, GrandArcana = 4.2, WintersHush = 4.1 }

-- ===== FIRST-PERSON ULTIMATE (2026-10-28) =====
-- The user: "when the user presses ultimate, it goes into first person and you can see the ultimate in action".
-- Research applied (Roblox Dev/Research/VFX and Animation/Cinematic Cutscenes.md): camera keyed relative to the caster
-- (Moon Animator reference-part pattern), smooth spline moves with keyed FOV (long lens for tension, wide for speed),
-- small handheld noise, an anime impact frame (~0.09 s), radial speed lines, depth of field on the subject.
-- Beats (full 3.5 s / short 1.7 s for repeats and 2x):
--   0.00  letterbox, grade, the camera swoops from the board into the familiar's eyes, looking down the lane
--   0.45  charge: an orb forms just in front of the eyes, motes and the other familiars' bolts pour into it,
--         FOV narrows 70 -> 52, handheld shake rises, the name band slides across
--   1.40  release: impact frame, FOV punches to 92, the camera rides behind the orb down the lane, speed lines
--   1.90  impact: the camera brakes beside the enemy cluster, impacts on every target, shake, caption
--   2.90  ease back to the game view
local function speedLines(ov, n, t)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = 18
	holder.Parent = ov.gui
	for i = 1, n do
		local a = math.random() * math.pi * 2
		local l = Instance.new("Frame")
		l.AnchorPoint = Vector2.new(0, 0.5)
		l.BorderSizePixel = 0
		l.BackgroundColor3 = Color3.new(1, 1, 1)
		l.BackgroundTransparency = 0.35 + math.random() * 0.4
		local r0 = 0.32 + math.random() * 0.12
		l.Position = UDim2.fromScale(0.5 + math.cos(a) * r0, 0.5 + math.sin(a) * r0 * 1.6)
		l.Size = UDim2.new(0.25 + math.random() * 0.3, 0, 0, math.random(2, 5))
		l.Rotation = math.deg(a)
		l.ZIndex = 18
		l.Parent = holder
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new(1, 0)
		g.Parent = l
	end
	-- lines flicker (re-roll angles) so they read as motion, not a static star
	local t0 = os.clock()
	local conn
	conn = hold(RunService.RenderStepped:Connect(function()
		if os.clock() - t0 > t or not holder.Parent then
			conn:Disconnect()
			if holder.Parent then holder:Destroy() end
			return
		end
		for _, l in holder:GetChildren() do
			if math.random() < 0.35 then
				local a = math.random() * math.pi * 2
				local r0 = 0.32 + math.random() * 0.12
				l.Position = UDim2.fromScale(0.5 + math.cos(a) * r0, 0.5 + math.sin(a) * r0 * 1.6)
				l.Rotation = math.deg(a)
			end
		end
	end))
end

local function catmull(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end

CutsceneFX.signatures.FirstPerson = function(ctx)
	local short = ctx.short == true
	local S = short and 0.5 or 1 -- time scale for the charge beats
	local stage = K.stage()
	local ov = K.overlay()
	ov.open(0.1)
	local ungrade = K.grade(ctx.color)
	local cam = K.camera(ctx)
	local setFov = ctx.setFov or function() end
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "CutsceneDOF"
	dof.FarIntensity, dof.NearIntensity, dof.FocusDistance, dof.InFocusRadius = 0.6, 0, 6, 8
	dof.Parent = Lighting

	-- frame of reference: the caster's head, facing the first target (the lane ahead)
	local pivot = ctx.model and ctx.model:GetPivot() or CFrame.new(ctx.origin)
	local size = ctx.model and select(2, ctx.model:GetBoundingBox()) or Vector3.new(3, 4, 3)
	local P = pivot.Position
	local first = ctx.targets[1] or (P + Vector3.new(0, 0, -30))
	local fwd = Vector3.new(first.X - P.X, 0, first.Z - P.Z)
	fwd = fwd.Magnitude > 0.1 and fwd.Unit or Vector3.new(0, 0, -1)
	local up = Vector3.yAxis
	local eye = P + up * (size.Y * 0.62) + fwd * (math.max(size.X, size.Z) * 0.45) -- just in front of the eyes
	local look = first + up * 2.5
	local center = Vector3.zero
	for _, t in ctx.targets do center += t end
	center = #ctx.targets > 0 and center / #ctx.targets or first

	-- 1) swoop into the eyes along a curve (game view -> high over the shoulder -> eyes)
	local fromCF = ctx.gameCamera()
	local mid = P - fwd * 10 + up * 9
	local swoopT = short and 0.3 or 0.45
	local t0 = os.clock()
	local a, b, c, d = fromCF.Position, fromCF.Position, mid, eye
	local swoop = hold(RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - t0) / swoopT, 0, 1)
		local e = 1 - (1 - k) ^ 3
		local pos = k < 0.5 and catmull(a, b, c, d, e * 2) or catmull(b, c, d, d, e * 2 - 1)
		local tgt = (fromCF.Position + fromCF.LookVector * 40):Lerp(look, e)
		cam.to(CFrame.lookAt(pos, tgt), 0)
		setFov(60 + 10 * e)
	end))
	task.wait(swoopT)
	swoop:Disconnect()
	ctx.sfx("legendary_gather")

	-- 2) charge in first person
	local orbPos = eye + fwd * 6.5 - up * 1.6 -- low in frame so the lane stays readable (v1 covered ~40% of the screen)
	-- the orb is the crystal core (2026-10-28; was a plain white ball): it grows from a spark while it charges
	local core = K.core(stage, orbPos, ctx.color)
	local orb = anchorAt(stage, orbPos) -- the trail beam and the light follow this anchor
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = ctx.color, 18, 2
	light.Parent = orb
	local chargeT = 0.95 * S
	local growStart = os.clock()
	local growConn = hold(RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - growStart) / chargeT, 0, 1)
		core.scale(0.25 + 1.15 * k * k)
	end))
	task.delay(chargeT, function() growConn:Disconnect() end)
	tw(light, chargeT, { Brightness = 9, Range = 26 })
	K.gather(stage, orbPos, ctx.color, short and 10 or 22, 9, chargeT)
	for i, ally in ctx.allies or {} do -- the other familiars feed the orb: beams from the sides of the frame
		if i > 6 then break end
		task.delay(0.08 * i * S, function()
			local from = anchorAt(stage, ally + up * 3)
			local to = anchorAt(stage, orbPos)
			local bm = K.beam(from, to, ctx.color, 0.5)
			bm.grow(0.15)
			task.delay(0.35 * S, function() bm.fade(0.2) end)
		end)
	end
	-- slow push and lens narrowing with growing handheld shake
	cam.to(CFrame.lookAt(eye + fwd * 0.8, look), chargeT, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	local fovStart = os.clock()
	local fovConn = hold(RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - fovStart) / chargeT, 0, 1)
		setFov(70 - 18 * k)
		dof.FocusDistance = 4.5
	end))
	cam.shake(0.25, chargeT)
	if not short then
		task.delay(0.15, function() K.cutIn(ov, ctx, 0.55) end)
	end
	task.wait(chargeT)
	fovConn:Disconnect()

	-- 3) release: impact frame, FOV punch, ride behind the orb down the lane
	ctx.sfx("legendary_burst")
	if IF and ctx.settings.flashes ~= false then
		IF.impactFrame(ctx.settings)
	else
		K.flash(ov, ctx, Color3.new(1, 1, 1), 0.6, 0.18)
	end
	local stopEcho = function() end
	pcall(function() stopEcho = require(RS.Shared.Motion).echoModel(core.model, { count = 3, gap = 2 }) end) -- multiples on the ride
	local travelT = short and 0.35 or 0.5
	local startPos = orbPos
	local endPos = center + up * 2
	speedLines(ov, short and 16 or 26, travelT + 0.1)
	dof.FarIntensity = 0
	local rideStart = os.clock()
	local ride = hold(RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - rideStart) / travelT, 0, 1)
		local e = k * k -- accelerate into the hit
		local op = startPos:Lerp(endPos, e)
		orb.Position = op
		core.at(op)
		local dir = (endPos - startPos)
		dir = dir.Magnitude > 0.1 and dir.Unit or fwd
		cam.to(CFrame.lookAt(op - dir * 7 + up * 2.2, op + dir * 3), 0)
		setFov(92 - 10 * k)
	end))
	-- a trail of light behind the orb
	local trail = anchorAt(stage, startPos)
	local tb = K.beam(trail, orb, ctx.color, 0.9)
	tb.grow(0.1)
	task.wait(travelT)
	ride:Disconnect()
	tb.fade(0.3)
	stopEcho()
	core.destroy()
	orb:Destroy()

	-- 4) impact: brake to a side vantage on the cluster
	ctx.sfx("summon")
	local side = fwd:Cross(up)
	local vantage = center - fwd * 14 + side * 9 + up * 7
	cam.to(CFrame.lookAt(vantage, center + up), 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	setFov(64)
	cam.shake(0.9, short and 0.4 or 0.8)
	dof.FarIntensity, dof.FocusDistance, dof.InFocusRadius = 0.35, (vantage - center).Magnitude, 10
	for i, t in ctx.targets do
		if i > (short and 5 or 9) then break end
		task.delay((i - 1) * 0.05, function() K.impact(stage, t, ctx.color, short and 0.9 or 1.1) end)
		if i <= (short and 2 or 4) then -- light slams onto the first few targets, staggered like falling stars
			task.delay(0.12 + (i - 1) * 0.11, function() K.slam(stage, t, ctx.color, short and 0.8 or 1) end)
		end
	end
	K.shockwave(stage, center, ctx.color, 22, 0.5) -- coloured, not white: v1 washed the frame white
	if not short then
		K.caption(ov, "[ " .. (ctx.ability or "ULTIMATE") .. " ]", ctx.color:Lerp(Color3.new(1, 1, 1), 0.5))
	end
	if ctx.onHit then pcall(ctx.onHit) end
	-- a slow drift across the impact so the aftermath reads
	cam.to(CFrame.lookAt(vantage + side * 3 + up * 1, center + up), short and 0.5 or 0.9, Enum.EasingStyle.Sine)
	task.wait(short and 0.5 or 0.95)

	-- 5) back to the board
	ungrade()
	tw(dof, 0.4, { FarIntensity = 0, InFocusRadius = 50 })
	Debris:AddItem(dof, 0.45)
	setFov(nil)
	ov.close()
	cam.done(short and 0.4 or 0.55)
	task.wait(short and 0.4 or 0.55)
	stage:Destroy()
	return true
end
CutsceneFX.duration.FirstPerson = 3.5

-- Undo everything a cutscene leaves behind: frame connections, camera, hidden HUD, stage, overlay, colour grade.
local function cleanup(ctx)
	for _, c in CutsceneFX._conns do
		c:Disconnect()
	end
	table.clear(CutsceneFX._conns)
	pcall(ctx.setCamera, nil)
	if ctx.setFov then pcall(ctx.setFov, nil) end
	for _, g in CutsceneFX._hidden or {} do
		g.Enabled = true
	end
	CutsceneFX._hidden = nil
	for _, inst in { workspace:FindFirstChild("Cutscene"), Players.LocalPlayer.PlayerGui:FindFirstChild("CutsceneGui"), Lighting:FindFirstChild("CutsceneGrade"), Lighting:FindFirstChild("CutsceneDOF") } do
		inst:Destroy()
	end
end

-- Plays a signature. A tap or click during it skips to the end (after a short grace so the cast tap itself does not
-- skip); at game speed 2x (ctx.settings.gameSpeed == 2) it skips by itself once the cut-in has shown the name.
-- ctx.onSkip() is called after a skip so the caller can release anything it was holding for the cutscene.
function CutsceneFX.play(name, ctx)
	local fn = CutsceneFX.signatures[name]
	if not fn then
		return 0
	end
	ctx.sfx = ctx.sfx or function() end
	ctx.settings = ctx.settings or {}
	local done = false
	local thread
	local function skip(reason)
		if done then
			return
		end
		done = true
		if thread and coroutine.status(thread) ~= "dead" then
			task.cancel(thread)
		end
		cleanup(ctx)
		CutsceneFX.lastSkip = reason
		if ctx.onSkip then
			pcall(ctx.onSkip)
		end
	end
	thread = task.spawn(function()
		local ok, err = pcall(fn, ctx)
		done = true
		if not ok then
			warn("CutsceneFX " .. name .. ": " .. tostring(err))
			cleanup(ctx)
		end
	end)
	local t0 = os.clock()
	local input
	input = game:GetService("UserInputService").InputBegan:Connect(function(io)
		local tap = io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch
		if tap and os.clock() - t0 > 0.4 then
			skip("tap")
		end
	end)
	function CutsceneFX.skip()
		skip("call")
	end
	if ctx.settings.gameSpeed == 2 and not ctx.short then -- short cuts already fit 2x
		task.delay(1.3, function()
			skip("2x")
		end)
	end
	task.spawn(function()
		while not done do
			task.wait(0.1)
		end
		input:Disconnect()
	end)
	return CutsceneFX.duration[name] or 3.5
end

return CutsceneFX
