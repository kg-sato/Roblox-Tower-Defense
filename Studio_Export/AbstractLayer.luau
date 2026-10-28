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
	local motion -- defined at the end; the start-menu task calls it once its orbit exists

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
	if desk then
		desk.Visible = false
		desk:GetPropertyChangedSignal("Visible"):Connect(function() -- Settings toggles it; it stays retired
			if desk.Visible then desk.Visible = false end
		end)
	end
	local bottom = {} -- decor that belongs to the roll bar and hides with it
	local field = new("Frame", { Name = "Abs_field", BackgroundColor3 = INK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, 40, 0, 120), ZIndex = 0 }, hud)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, 0.35), NumberSequenceKeypoint.new(1, 0.1) }) }, field)
	local horizon = new("Frame", { Name = "Abs_horizon", BackgroundColor3 = GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -128), Size = UDim2.new(0.9, 0, 0, 2), ZIndex = 0 }, hud)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.45), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(0.7, 0.45), NumberSequenceKeypoint.new(1, 1) }) }, horizon)

	-- 2. ROLL: violet disc (the one big calm shape) inside a turning amber orbit, faint rays behind
	if env.rollBtn and not env.abstractHUD then -- AbstractHUD draws ROLL as a spiral itself
		local rays = img("rays", 330, GOLD, 0.82, 0)
		pin(rays, env.rollBtn, -60, -6)
		local d = disc(200, VIOLET, 0.45, 0)
		pin(d, env.rollBtn, -60, -6)
		local orb = img("orbits", 250, AMBER, 0.45, 0)
		pin(orb, env.rollBtn, -60, -6)
		table.insert(bottom, rays) table.insert(bottom, d) table.insert(bottom, orb)
		spin(orb, 90)
	end

	-- 3. AUTO / QUICK hang on one gold line with a point at each end (Kandinsky: point and line)
	if env.autoBtn and env.quickBtn then
		local line = new("Frame", { Name = "Abs_line", BackgroundColor3 = GOLD, BackgroundTransparency = 0.35, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(640, 2), ZIndex = 0 }, hud)
		pin(line, env.rollBtn or env.autoBtn, 0, 26)
		table.insert(bottom, line)
		for _, x in { -320, 320 } do
			local p = disc(10, GOLD, 0.1, 0)
			pin(p, env.rollBtn or env.autoBtn, x, 26)
			table.insert(bottom, p)
		end
	end

	-- 4. START WAVE: an amber triangle rising behind the bell (the hot, active shape), half below the screen edge
	if env.startWaveBtn and not env.abstractHUD then -- AbstractHUD makes the triangle the button itself
		local tri = new("Frame", { Name = "Abs_triangle", BackgroundColor3 = AMBER, BackgroundTransparency = 0.62, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(150, 150), Rotation = 45, ZIndex = 0 }, hud)
		pin(tri, env.startWaveBtn, -78, 48)
		new("UIGradient", { Rotation = -45, Transparency = NumberSequence.new(0, 0.6) }, tri)
	end

	-- 5. ULT: the watch inside cyan orbits, turning the other way
	if env.ultBtn and not env.abstractHUD then
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
		corner.Visible = not env.abstractHUD -- with the abstract HUD it read as a stray blob behind the level vesica
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
		if p and not env.abstractHUD then
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
	if env.stagePill and not env.abstractHUD then
		local v = img("vesica", 300, VIOLET, 0.55, 0)
		pin(v, env.stagePill, 0, 40)
	end

	local rollBar = env.rollBtn and env.rollBtn.Parent
	if rollBar then
		local function sync()
			for _, o in bottom do o.Visible = rollBar.Visible end
			field.Visible, horizon.Visible = rollBar.Visible, rollBar.Visible
		end
		rollBar:GetPropertyChangedSignal("Visible"):Connect(sync)
		sync()
	end

	-- 9. panels: each gets one big shape that says what it is, plus the same gold edge line with two points.
	-- progression = af Klint's spiral (growth), odds = the vesica (fate), settings = orbits (the mechanism),
	-- familiar = the violet disc. Shapes sit under the panel's glass and spill past one edge (off-centre tension).
	local PANEL = {
		{ match = "PROGRESSION", key = "spiral", size = 560, color = VIOLET, t = 0.5, pos = UDim2.new(0, 40, 0, 60), rot = -20 },
		{ match = "ROLL ODDS", key = "vesica", size = 560, color = AMBER, t = 0.72, pos = UDim2.fromScale(0.5, 0.55), rot = 0 },
		{ match = "SETTINGS", key = "orbits", size = 440, color = CYAN, t = 0.6, pos = UDim2.new(1, -10, 0, 50), rot = 0 },
		{ match = "PET", key = "disc", size = 300, color = VIOLET, t = 0.5, pos = UDim2.new(0, 0, 0.3, 0), rot = 0 },
	}
	local done = {}
	local function titleOf(f)
		for _, d in f:GetDescendants() do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
				for _, spec in PANEL do
					local T = string.upper(d.Text)
					if T == spec.match or (T:find(spec.match, 1, true) and #T <= #spec.match + 12) then return spec end
				end
			end
		end
	end
	local function decorate(f)
		if done[f] or not f.Visible then return end
		local spec = titleOf(f)
		if not spec then return end
		done[f] = true
		local shape
		if spec.key == "disc" then
			shape = new("Frame", { BackgroundColor3 = spec.color, BackgroundTransparency = spec.t, BorderSizePixel = 0, Size = UDim2.fromOffset(spec.size, spec.size) }, f)
			new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, shape)
		else
			shape = new("ImageLabel", { BackgroundTransparency = 1, Image = IMG[spec.key], ImageColor3 = spec.color, ImageTransparency = spec.t, Size = UDim2.fromOffset(spec.size, spec.size) }, f)
		end
		shape.Name, shape.AnchorPoint, shape.Position, shape.Rotation, shape.ZIndex = "Abs_panelShape", Vector2.new(0.5, 0.5), spec.pos, spec.rot, 0
		local edge = new("Frame", { Name = "Abs_edge", BackgroundColor3 = GOLD, BackgroundTransparency = 0.35, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, -10, 0.5, 0), Size = UDim2.new(0, 2, 0.86, 0), ZIndex = 0 }, f)
		if spec.match == "PROGRESSION" then
			-- the level road becomes a constellation: no boxes, the line runs through a point per level
			for _, road in f:GetDescendants() do
				if road:IsA("ScrollingFrame") and road:FindFirstChild("L1") then
					for _, c in road:GetChildren() do
						if c:IsA("Frame") and not c.Name:match("^L%d+$") and c.Size.Y.Offset == 4 then
							c.Position = UDim2.fromOffset(c.Position.X.Offset, 31) -- through the level points
						end
					end
					for _, card in road:GetChildren() do
						if card:IsA("Frame") and card.Name:match("^L%d+$") then
							local st = card:FindFirstChildOfClass("UIStroke")
							local point = new("Frame", { Name = "Abs_point", BackgroundColor3 = INK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 23), Size = UDim2.fromOffset(46, 46), ZIndex = 12 }, card)
							new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, point)
							local ring = new("UIStroke", { Thickness = 2, Color = GOLD }, point)
							-- "next" gets an outer amber orbit ring (a plain ring: the orbit art's centre dot showed behind the number)
							local orb = new("Frame", { Name = "Abs_next", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 23), Size = UDim2.fromOffset(64, 64), ZIndex = 12, Visible = false }, card)
							new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, orb)
							new("UIStroke", { Color = AMBER, Thickness = 1.5, Transparency = 0.3 }, orb)
							local moon = new("Frame", { BackgroundColor3 = AMBER, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.85, 0.15), Size = UDim2.fromOffset(7, 7), ZIndex = 12 }, orb)
							new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, moon)
							local function restyle()
								card.BackgroundTransparency = 1
								if st then
									st.Transparency = 1
									local c = st.Color
									local nextUp = st.Thickness >= 3
									local done = c.G > c.R + 0.15 and not nextUp
									ring.Color = c
									ring.Thickness = nextUp and 3 or 2
									point.BackgroundColor3 = done and c:Lerp(INK, 0.45) or INK
									orb.Visible = nextUp
								end
							end
							card:GetPropertyChangedSignal("BackgroundTransparency"):Connect(restyle)
							if st then st:GetPropertyChangedSignal("Color"):Connect(restyle) end
							restyle()
						end
					end
				end
			end
		end
		for _, y in { 0.07, 0.93 } do
			local p = new("Frame", { BackgroundColor3 = GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, -10, y, 0), Size = UDim2.fromOffset(9, 9), ZIndex = 0 }, f)
			new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, p)
		end
	end
	local function watch(f)
		-- panel-sized frames only: the Dock's button captions say "PROGRESSION" and "SETTINGS" too
		if f:IsA("Frame") and f.Size.X.Offset >= 280 and f.Size.Y.Offset >= 300 then
			f:GetPropertyChangedSignal("Visible"):Connect(function() decorate(f) end)
			decorate(f)
		end
	end
	for _, f in hud:GetChildren() do watch(f) end
	hud.ChildAdded:Connect(watch)

	-- 10. the start menu: the featured familiar gets the one big calm shape (violet disc in turning amber orbits with
	-- faint rays); a faint vesica sits behind the title; a gold spine with a point at the crown, the rule, the lamp
	-- button and the flashes plate ties the left column together.
	task.spawn(function()
		local sm = hud.Parent:WaitForChild("StartMenu", 10)
		if not sm then return end
		local featured = sm:WaitForChild("Featured", 5)
		local menu = sm:FindFirstChild("MenuHolder") and sm.MenuHolder:FindFirstChild("Menu")
		if featured then
			local glow
			for _, c in featured:GetChildren() do
				if c:IsA("Frame") and c.BackgroundTransparency < 1 then glow = c end
			end
			if glow then
				glow.BackgroundColor3, glow.BackgroundTransparency = VIOLET, 0.55
				for _, c in glow:GetChildren() do
					if c:IsA("UIGradient") then c:Destroy() end
				end
				local function shape(key, size, color, t)
					return new("ImageLabel", { Name = "Abs_" .. key, BackgroundTransparency = 1, Image = IMG[key], ImageColor3 = color, ImageTransparency = t, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(glow.Position.X.Scale, glow.Position.X.Offset + (glow.AnchorPoint.X - 0.5) * -glow.Size.X.Offset, glow.Position.Y.Scale, glow.Position.Y.Offset + (glow.AnchorPoint.Y - 0.5) * -glow.Size.Y.Offset - 70), Size = UDim2.fromOffset(size, size), ZIndex = 11 }, featured)
					-- centred 70 px up, behind the familiar's body, so the orbit's centre point hides behind it
				end
				shape("rays", 430, GOLD, 0.9)
				local orb = shape("orbits", 360, AMBER, 0.55)
				spin(orb, 90)
			end
		end
		if menu then
			local v = new("ImageLabel", { Name = "Abs_vesica", BackgroundTransparency = 1, Image = IMG.vesica, ImageColor3 = VIOLET, ImageTransparency = 0.8, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(140, 165), Size = UDim2.fromOffset(330, 330), ZIndex = 11 }, menu)
			local spine = new("Frame", { Name = "Abs_spine", BackgroundColor3 = GOLD, BackgroundTransparency = 0.4, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(-24, 22), Size = UDim2.fromOffset(2, 434), ZIndex = 12 }, menu)
			for _, y in { 22, 265, 331, 456 } do
				local p = new("Frame", { BackgroundColor3 = GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(-24, y), Size = UDim2.fromOffset(9, 9), ZIndex = 12 }, menu)
				new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, p)
			end
		end
		motion()
	end)

	-- motion: only the two orbits turn, slowly; none with Reduced Motion
	function motion()
		local off = env.reducedMotion and env.reducedMotion()
		for _, t in spinners do
			if off then t:Pause() else t:Play() end
		end
	end
	motion()
	return { refresh = motion, layer = layer }
end
