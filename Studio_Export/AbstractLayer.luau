--!nocheck
-- AbstractLayer (2026-10-28). User: "fix the UI, research abstract works and make it abstract" -> chose "Blend": keep the
-- brass/tarot objects, make what surrounds them abstract. Research note: Roblox Dev/Research/UI/Abstract UI.md.
--   Hilma af Klint: overlapping circles (vesica), spirals, orbits as symbols; Kandinsky: point, line, plane and the
--   tension of a shape off-centre (circle = calm, triangle = hot/active); Bauhaus: few shapes, few colours, asymmetry,
--   no ornament; Mini Metro: flat fields, grouped peripheral info, empty space; Metaphor critique: not everything moves.
-- What it does: the mahogany desk becomes a flat ink field with a gold horizon line; ROLL sits on a violet disc inside a
-- slowly turning orbit (the main action gets the one big calm shape); START WAVE sits on an amber triangle (the "go"
-- shape); AUTO and QUICK hang on a gold line with points at each end; the ULT watch sits in cyan orbits; ODDS becomes
-- the seer's eye; the left column is tied together by a gold spine with a point at each item over a violet field;
-- a faint vesica sits behind the stage sign. Only two shapes move (both slow rotations), and none with Reduced Motion.
--
--   require(script.Parent.AbstractLayer)({ hud = hud, rollBtn = rollBtn, ... , reducedMotion = function() ... end })

local TweenService = game:GetService("TweenService")

local IMG = {
	vesica = "rbxassetid://140628629392455", spiral = "rbxassetid://128142388272489", orbits = "rbxassetid://133077605323965",
	eye = "rbxassetid://137981105271928", rays = "rbxassetid://106824495648529",
}
local INK = Color3.fromRGB(14, 9, 26)
local VIOLET = Color3.fromRGB(96, 56, 190)
local AMBER = Color3.fromRGB(255, 176, 70)
local GOLD = Color3.fromRGB(255, 214, 130)
local CYAN = Color3.fromRGB(110, 220, 255)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do
		o[k] = v
	end
	o.Parent = parent
	return o
end

return function(env)
	local hud = env.hud
	local layer = new("Folder", { Name = "Abstract" }, hud)
	local scale = hud:FindFirstChildOfClass("UIScale")
	local spinners = {}

	-- keep a decor element centred on a HUD control, in the HUD's own (pre-UIScale) offsets
	local function pin(decor, target, dx, dy)
		local function place()
			local s = scale and scale.Scale or 1
			local c = target.AbsolutePosition + target.AbsoluteSize / 2 - hud.AbsolutePosition
			decor.Position = UDim2.fromOffset(c.X / s + (dx or 0), c.Y / s + (dy or 0))
		end
		place()
		target:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
		target:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
		hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	end
	local function img(key, size, color, transparency, z)
		return new("ImageLabel", { Name = "Abs_" .. key, BackgroundTransparency = 1, Image = IMG[key], ImageColor3 = color, ImageTransparency = transparency, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(size, size), ZIndex = z or 0 }, hud)
	end
	local function disc(size, color, transparency, z)
		local f = new("Frame", { BackgroundColor3 = color, BackgroundTransparency = transparency, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(size, size), ZIndex = z or 0 }, hud)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
		return f
	end
	local function spin(o, secs)
		table.insert(spinners, TweenService:Create(o, TweenInfo.new(secs, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 }))
	end

	-- 1. the bottom: a flat ink field fading up into the board, with a gold horizon line
	local desk = hud:FindFirstChild("Desk")
	if desk then desk.Visible = false end
	local field = new("Frame", { Name = "Abs_field", BackgroundColor3 = INK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, 40, 0, 120), ZIndex = 0 }, hud)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, 0.35), NumberSequenceKeypoint.new(1, 0.1) }) }, field)
	local horizon = new("Frame", { Name = "Abs_horizon", BackgroundColor3 = GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -128), Size = UDim2.new(0.9, 0, 0, 2), ZIndex = 0 }, hud)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.45), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(0.7, 0.45), NumberSequenceKeypoint.new(1, 1) }) }, horizon)

	-- 2. ROLL: violet disc (the one big calm shape) inside a turning amber orbit, faint rays behind
	if env.rollBtn then
		local rays = img("rays", 330, GOLD, 0.82, 0)
		pin(rays, env.rollBtn, -60, -6)
		local d = disc(200, VIOLET, 0.45, 0)
		pin(d, env.rollBtn, -60, -6)
		local orb = img("orbits", 250, AMBER, 0.45, 0)
		pin(orb, env.rollBtn, -60, -6)
		spin(orb, 90)
	end

	-- 3. AUTO / QUICK hang on one gold line with a point at each end (Kandinsky: point and line)
	if env.autoBtn and env.quickBtn then
		local line = new("Frame", { Name = "Abs_line", BackgroundColor3 = GOLD, BackgroundTransparency = 0.35, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(640, 2), ZIndex = 0 }, hud)
		pin(line, env.rollBtn or env.autoBtn, 0, 26)
		for _, x in { -320, 320 } do
			local p = disc(10, GOLD, 0.1, 0)
			pin(p, env.rollBtn or env.autoBtn, x, 26)
		end
	end

	-- 4. START WAVE: an amber triangle rising behind the bell (the hot, active shape), half below the screen edge
	if env.startWaveBtn then
		local tri = new("Frame", { Name = "Abs_triangle", BackgroundColor3 = AMBER, BackgroundTransparency = 0.62, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(150, 150), Rotation = 45, ZIndex = 0 }, hud)
		pin(tri, env.startWaveBtn, -78, 48)
		new("UIGradient", { Rotation = -45, Transparency = NumberSequence.new(0, 0.6) }, tri)
	end

	-- 5. ULT: the watch inside cyan orbits, turning the other way
	if env.ultBtn then
		local orb = img("orbits", 170, CYAN, 0.5, 0)
		pin(orb, env.ultBtn)
		spin(orb, 70)
		orb.Rotation = 0
	end

	-- 6. ODDS: the seer's eye instead of a plain ball
	if env.oddsChip then
		local function hideBall(c) -- the old plain ball (it may be built after this runs)
			if c:IsA("Frame") and c.Size == UDim2.fromOffset(26, 26) then c.Visible = false end
		end
		for _, c in env.oddsChip:GetChildren() do hideBall(c) end
		env.oddsChip.ChildAdded:Connect(hideBall)
		new("ImageLabel", { Name = "Abs_eye", BackgroundTransparency = 1, Image = IMG.eye, ImageColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, -2, 0.5, 0), Size = UDim2.fromOffset(44, 44), ZIndex = 8 }, env.oddsChip)
	end

	-- 7. the left column: a violet field off the corner, a gold spine with a point at each item
	if env.rail then
		local corner = disc(440, VIOLET, 0.72, 0)
		corner.Name = "Abs_corner"
		corner.Position = UDim2.fromOffset(40, 40)
		local spine = new("Frame", { Name = "Abs_spine", BackgroundColor3 = GOLD, BackgroundTransparency = 0.45, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(2, 10), ZIndex = 0 }, hud)
		local points = {}
		local items = { env.coinPill, env.gemPill }
		if env.dock then
			for _, h in env.dock:GetChildren() do
				if h:IsA("Frame") then table.insert(items, h) end
			end
		end
		for _, it in items do
			if it then
				local p = disc(8, GOLD, 0.1, 0)
				table.insert(points, { p = p, it = it })
			end
		end
		local function layout()
			local s = scale and scale.Scale or 1
			local x, top, bottom = 12, math.huge, -math.huge
			for _, e in points do
				local c = (e.it.AbsolutePosition + e.it.AbsoluteSize / 2 - hud.AbsolutePosition) / s
				local lx = (e.it.AbsolutePosition.X - hud.AbsolutePosition.X) / s - 2
				x = math.max(4, math.min(lx, 14))
				e.p.Position = UDim2.fromOffset(x, c.Y)
				top, bottom = math.min(top, c.Y), math.max(bottom, c.Y)
			end
			if top < bottom then
				spine.Position = UDim2.fromOffset(x, top)
				spine.Size = UDim2.fromOffset(2, bottom - top)
			end
		end
		layout()
		hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
		task.delay(1.5, layout) -- after the HUD's entrance tweens settle
	end

	-- 7b. coins and gems: flat ink bands fading to the right instead of boxed brass plates (Mini Metro: flat fields);
	-- a coloured point sits behind each icon
	for _, pair in { { env.coinPill, AMBER }, { env.gemPill, CYAN } } do
		local p = pair[1]
		if p then
			local plate = p:FindFirstChild("Obj_plaque")
			if plate then plate.Visible = false end
			local glass = p:FindFirstChild("Glass")
			if glass then glass.Visible = false end
			local band = new("Frame", { Name = "Abs_band", BackgroundColor3 = INK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -6, 0.5, 0), Size = UDim2.new(1, 10, 0.86, 0), ZIndex = 0 }, p)
			new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.7, 0.45), NumberSequenceKeypoint.new(1, 1) }) }, band)
			local dot = new("Frame", { Name = "Abs_point", BackgroundColor3 = pair[2], BackgroundTransparency = 0.55, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(44, 44), ZIndex = 1 }, p)
			new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dot)
		end
	end

	-- 8. a faint vesica behind the stage sign
	if env.stagePill then
		local v = img("vesica", 300, VIOLET, 0.55, 0)
		pin(v, env.stagePill, 0, 40)
	end

	-- motion: only the two orbits turn, slowly; none with Reduced Motion
	local function motion()
		local off = env.reducedMotion and env.reducedMotion()
		for _, t in spinners do
			if off then t:Pause() else t:Play() end
		end
	end
	motion()
	return { refresh = motion, layer = layer }
end
