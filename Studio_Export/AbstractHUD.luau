--!nocheck
-- AbstractHUD (2026-10-28). User: "make everything abstract, without UI that looks similar" -> chose: replace the
-- objects too, main HUD first. Every control becomes its own abstract form built from points, lines, circles,
-- triangles and arcs (Kandinsky's point-line-plane, af Klint's circles and spirals, Bauhaus primaries, Mini Metro's flat
-- fields). No two controls share a form. The buttons keep their positions, sizes, behaviour and text; only their skins
-- change (all old art is hidden, not deleted, so it can be restored). Rules and checklist: Roblox Dev/Research/UI/Abstract UI.md.
--
--   ROLL        the spiral: af Klint's spiral turning in a violet disc; spins up when pressed
--   AUTO        the orbit: a thin ring with one point; the point circles while AUTO is on
--   QUICK       the speed lines: three slanted lines; they lengthen and warm when on
--   ODDS        the eye (already abstract)
--   START WAVE  the triangle: a solid amber triangle pointing up (Kandinsky: the hot, active shape); hollow while a wave runs
--   ULT         the ring of points: 24 points that light up as the charge fills; the whole ring breathes when full
--   Coins       a solid amber point;  Gems  a cyan diamond
--   Level       the vesica (two overlapping circles) holding the number; XP is a line of ten points that fill
--   Stage       a big numeral inside a thin circle
--   Crystal HP  the moon: a pale disc that wanes into a crescent as the crystal loses health
--   Skill Tree  three points joined as a branch;  Progression  three points climbing;  Settings  two rings and a point

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local IMG = { spiral = "rbxassetid://128142388272489", vesica = "rbxassetid://140628629392455" }
local INK = Color3.fromRGB(14, 9, 26)
local VIOLET = Color3.fromRGB(110, 66, 210)
local AMBER = Color3.fromRGB(255, 176, 70)
local GOLD = Color3.fromRGB(255, 214, 130)
local CYAN = Color3.fromRGB(110, 220, 255)
local PALE = Color3.fromRGB(236, 228, 255)
local RED = Color3.fromRGB(255, 92, 92)
local GREY = Color3.fromRGB(120, 112, 140)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do
		o[k] = v
	end
	o.Parent = parent
	return o
end
local function circle(parent, size, pos, color, t, z)
	local f = new("Frame", { Name = "AF_point", BackgroundColor3 = color, BackgroundTransparency = t or 0, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, ZIndex = z or 5 }, parent)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
	return f
end
local function ring(parent, size, pos, color, thick, z)
	local f = new("Frame", { Name = "AF_ring", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, ZIndex = z or 5 }, parent)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
	local s = new("UIStroke", { Color = color, Thickness = thick or 2 }, f)
	return f, s
end
local function line(parent, p0, p1, color, thick, z) -- p0, p1 in offset pixels inside parent
	local d = p1 - p0
	local f = new("Frame", { Name = "AF_line", BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((p0.X + p1.X) / 2, (p0.Y + p1.Y) / 2), Size = UDim2.fromOffset(d.Magnitude, thick or 2), Rotation = math.deg(math.atan2(d.Y, d.X)), ZIndex = z or 5 }, parent)
	return f
end

-- hide everything a control used to draw (kept, not destroyed), restyle its text
local function strip(b, keepText)
	for _, d in b:GetDescendants() do
		if d:IsA("GuiObject") and not (keepText and d.Name == "Txt") and not d.Name:match("^AF_") then
			d.Visible = false
		elseif d:IsA("UIStroke") and d.Parent == b then
			d.Enabled = false
		elseif d:IsA("UIGradient") and d.Parent == b then
			d.Enabled = false
		end
	end
	if b:IsA("GuiObject") then
		b.BackgroundTransparency = 1
	end
	if b:IsA("TextButton") then
		b.TextTransparency = 1
	end
	b.ChildAdded:Connect(function(c) -- art some later code adds (sparkles, plates) stays hidden too
		task.defer(function()
			if c:IsA("GuiObject") and c.Name ~= "Txt" and not c.Name:match("^AF_") then c.Visible = false end
		end)
	end)
end
local function holder(b, z)
	return new("Frame", { Name = "AF_form", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z or 4 }, b)
end
local function caption(parent, text, pos, size, color, z, anchor)
	local l = new("TextLabel", { Name = "AF_text", BackgroundTransparency = 1, Text = text, FontFace = Font.fromName("Merriweather", Enum.FontWeight.Bold), TextScaled = true, TextColor3 = color, AnchorPoint = anchor or Vector2.new(0.5, 0.5), Position = pos, Size = size, ZIndex = z or 7 }, parent)
	new("UIStroke", { Color = INK, Thickness = 1.5, Transparency = 0.2 }, l)
	return l
end
local function txtOf(b) -- the button's own Text first: the Txt copy is updated by another handler that may run after ours
	if b:IsA("TextButton") and b.Text ~= "" then return b.Text end
	local t = b:FindFirstChild("Txt")
	return (t and t.Text) or ""
end

return function(env)
	local reduced = env.reducedMotion or function() return false end
	local spin = {}

	-- ROLL: the spiral in a violet disc
	do
		local b = env.rollBtn
		strip(b, false)
		local f = holder(b)
		local disc = circle(f, UDim2.fromOffset(96, 96), UDim2.new(0, 64, 0.5, -6), VIOLET, 0.15, 4)
		new("UIGradient", { Rotation = 120, Color = ColorSequence.new(Color3.fromRGB(160, 120, 255), Color3.fromRGB(60, 30, 140)) }, disc)
		local sp = new("ImageLabel", { Name = "AF_spiral", BackgroundTransparency = 1, Image = IMG.spiral, ImageColor3 = PALE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.86), ZIndex = 6 }, disc)
		table.insert(spin, { o = sp, speed = 25 })
		caption(f, "ROLL", UDim2.new(0, 120, 0.5, -14), UDim2.fromOffset(120, 34), PALE, 7, Vector2.new(0, 0.5))
		if env.rollCost then -- the cost stays the game's own label, restyled
			env.rollCost.Visible = true
			env.rollCost.Parent = f
			env.rollCost.FontFace = Font.fromName("Merriweather", Enum.FontWeight.Bold)
			env.rollCost.TextColor3 = CYAN
			env.rollCost.Position = UDim2.new(0, 121, 0.5, 18)
			env.rollCost.AnchorPoint = Vector2.new(0, 0.5)
			env.rollCost.Size = UDim2.fromOffset(120, 22)
			env.rollCost.ZIndex = 7
		end
		b.Activated:Connect(function() -- spins up when drawn
			if reduced() then return end
			for _, s in spin do
				if s.o == sp then
					s.boost = 1
				end
			end
		end)
	end

	-- AUTO: the orbit
	do
		local b = env.autoBtn
		strip(b, false)
		local f = holder(b)
		local r = ring(f, UDim2.fromOffset(34, 34), UDim2.new(0, 34, 0.5, 0), GREY, 2, 5)
		local dot = circle(r, UDim2.fromOffset(10, 10), UDim2.fromScale(0.5, 0), GREY, 0, 6)
		local t = caption(f, "AUTO", UDim2.new(0, 62, 0.5, 0), UDim2.fromOffset(80, 22), GREY, 7, Vector2.new(0, 0.5))
		local on = false
		local function sync()
			on = txtOf(b):find("ON") ~= nil
			local c = on and AMBER or GREY
			r:FindFirstChildOfClass("UIStroke").Color = c
			dot.BackgroundColor3 = c
			t.TextColor3 = on and GOLD or GREY
		end
		b:GetPropertyChangedSignal("Text"):Connect(sync)
		sync()
		local a = 0
		RunService.RenderStepped:Connect(function(dt)
			if on and not reduced() then
				a += dt * 3
				dot.Position = UDim2.fromScale(0.5 + 0.5 * math.sin(a), 0.5 - 0.5 * math.cos(a))
			end
		end)
	end

	-- QUICK: the speed lines
	do
		local b = env.quickBtn
		strip(b, false)
		local f = holder(b)
		local ls = {}
		for i = 0, 2 do
			ls[i + 1] = line(f, Vector2.new(14 + i * 9, 34), Vector2.new(30 + i * 9, 14), GREY, 3, 5)
		end
		local t = caption(f, "QUICK", UDim2.new(0, 62, 0.5, 0), UDim2.fromOffset(84, 22), GREY, 7, Vector2.new(0, 0.5))
		local function sync()
			local on = txtOf(b):find("ON") ~= nil
			for i, l in ls do
				l.BackgroundColor3 = on and AMBER or GREY
				l.Size = UDim2.fromOffset(on and 30 or 22, 3)
			end
			t.TextColor3 = on and GOLD or GREY
		end
		b:GetPropertyChangedSignal("Text"):Connect(sync)
		sync()
	end

	-- ODDS: keep the eye, drop the chip's plate
	if env.oddsChip then
		for _, d in env.oddsChip:GetChildren() do
			if d:IsA("ImageLabel") and d.Name ~= "Abs_eye" then d.Visible = false end
		end
		env.oddsChip.BackgroundTransparency = 1
	end

	-- START WAVE: the triangle
	do
		local b = env.startWaveBtn
		strip(b, false)
		local f = holder(b)
		-- a triangle = the top half of a square turned 45 degrees, clipped
		local clip = new("Frame", { Name = "AF_tri", BackgroundTransparency = 1, ClipsDescendants = true, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0, 40, 1, -8), Size = UDim2.fromOffset(80, 40), ZIndex = 4 }, f)
		local sq = new("Frame", { Name = "AF_sq", BackgroundColor3 = AMBER, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromOffset(57, 57), Rotation = 45, ZIndex = 4 }, clip)
		local grad = new("UIGradient", { Rotation = -45, Color = ColorSequence.new(Color3.fromRGB(255, 225, 140), Color3.fromRGB(230, 120, 40)) }, sq)
		local hollow = new("UIStroke", { Color = AMBER, Thickness = 3, Enabled = false }, sq)
		local t = caption(f, "BEGIN", UDim2.new(0, 92, 0.5, -8), UDim2.fromOffset(140, 30), GOLD, 7, Vector2.new(0, 0.5))
		local sub = caption(f, "THE WAVE", UDim2.new(0, 93, 0.5, 18), UDim2.fromOffset(100, 16), AMBER, 7, Vector2.new(0, 0.5))
		local function sync()
			local ready = txtOf(b):find("START") ~= nil
			sq.BackgroundTransparency = ready and 0 or 1
			hollow.Enabled = not ready
			t.Text = ready and "BEGIN" or "RUNNING"
			t.TextColor3 = ready and GOLD or GREY
			sub.Visible = ready
		end
		b:GetPropertyChangedSignal("Text"):Connect(sync)
		sync()
	end

	-- ULT: the ring of points
	do
		local b = env.ultBtn
		strip(b, false)
		local f = holder(b)
		local pts = {}
		local N = 24
		for i = 1, N do
			local a = (i - 1) / N * math.pi * 2
			pts[i] = circle(f, UDim2.fromOffset(7, 7), UDim2.new(0.5, math.sin(a) * 40, 0.5, -math.cos(a) * 40), Color3.fromRGB(50, 70, 90), 0, 5)
		end
		local core = circle(f, UDim2.fromOffset(30, 30), UDim2.fromScale(0.5, 0.5), Color3.fromRGB(30, 50, 70), 0, 5)
		local t = caption(f, "ULT", UDim2.new(0.5, 0, 0.5, 0), UDim2.fromOffset(40, 16), PALE, 7)
		local full = false
		local function sync()
			local frac = env.ultFill and env.ultFill.Size.Y.Scale or 0
			local lit = math.floor(frac * N + 0.5)
			for i, p in pts do
				p.BackgroundColor3 = i <= lit and CYAN or Color3.fromRGB(50, 70, 90)
				p.Size = i <= lit and UDim2.fromOffset(9, 9) or UDim2.fromOffset(6, 6)
			end
			full = frac >= 0.999
			core.BackgroundColor3 = full and CYAN or Color3.fromRGB(30, 50, 70)
			t.TextColor3 = full and INK or PALE
		end
		if env.ultFill then env.ultFill:GetPropertyChangedSignal("Size"):Connect(sync) end
		sync()
		local clock = 0
		RunService.RenderStepped:Connect(function(dt)
			clock += dt
			if full and not reduced() then
				local s = 1 + 0.12 * math.sin(clock * 5)
				core.Size = UDim2.fromOffset(30 * s, 30 * s)
			end
		end)
	end

	-- Coins: a solid amber point.  Gems: a cyan diamond.
	local function purse(pill, label, form)
		if not pill then return end
		strip(pill, false)
		if label then
			label.Visible = true
			label.FontFace = Font.fromName("Merriweather", Enum.FontWeight.Bold)
		end
		local f = holder(pill)
		form(f)
	end
	purse(env.coinPill, env.coinLabel, function(f)
		local c = circle(f, UDim2.fromOffset(24, 24), UDim2.new(0, 14, 0.5, 0), AMBER, 0, 5)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 220, 140), Color3.fromRGB(220, 130, 40)) }, c)
		if env.coinLabel then env.coinLabel.TextColor3 = GOLD end
	end)
	purse(env.gemPill, env.gemLabel, function(f)
		local d = new("Frame", { Name = "AF_diamond", BackgroundColor3 = CYAN, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(17, 17), Rotation = 45, ZIndex = 5 }, f)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(200, 245, 255), Color3.fromRGB(60, 160, 230)) }, d)
		if env.gemLabel then env.gemLabel.TextColor3 = CYAN end
	end)

	-- Level: the vesica holding the number; XP as a line of ten points
	if env.lvlPill then
		local p = env.lvlPill
		strip(p, false)
		local f = holder(p)
		local v = new("ImageLabel", { Name = "AF_vesica", BackgroundTransparency = 1, Image = IMG.vesica, ImageColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 22, 0.5, 0), Size = UDim2.fromOffset(78, 78), ZIndex = 5 }, f)
		if env.lvlNum then
			env.lvlNum.Visible = true
			env.lvlNum.Parent = f
			env.lvlNum.AnchorPoint = Vector2.new(0.5, 0.5)
			env.lvlNum.Position = UDim2.new(0, 22, 0.5, 0)
			env.lvlNum.Size = UDim2.fromOffset(30, 30)
			env.lvlNum.TextColor3 = INK
			env.lvlNum.ZIndex = 7
			local st = env.lvlNum:FindFirstChildOfClass("UIStroke")
			if st then st.Enabled = false end
		end
		caption(f, "TRAINER", UDim2.new(0, 68, 0, 14), UDim2.fromOffset(110, 16), GOLD, 7, Vector2.new(0, 0.5))
		local xp = {}
		for i = 1, 10 do
			xp[i] = circle(f, UDim2.fromOffset(9, 9), UDim2.new(0, 72 + (i - 1) * 15, 0, 38), GREY, 0, 5)
		end
		local function sync()
			local frac = env.xpFill and env.xpFill.Size.X.Scale or 0
			local n = frac * 10
			for i, d in xp do
				local lit = math.clamp(n - (i - 1), 0, 1)
				d.BackgroundColor3 = GREY:Lerp(GOLD, lit)
				d.Size = UDim2.fromOffset(7 + 4 * lit, 7 + 4 * lit)
			end
		end
		if env.xpFill then env.xpFill:GetPropertyChangedSignal("Size"):Connect(sync) end
		sync()
	end

	-- Stage: a big numeral inside a thin circle
	if env.stagePill and env.stageLabel then
		local p = env.stagePill
		strip(p, false)
		local f = holder(p)
		f.Position = UDim2.fromOffset(0, 0)
		local r = ring(f, UDim2.fromOffset(64, 64), UDim2.new(0.5, 0, 1, -40), PALE, 1.5, 5)
		local num = caption(f, "1", UDim2.new(0.5, 0, 1, -40), UDim2.fromOffset(44, 36), PALE, 7)
		local word = caption(f, "STAGE", UDim2.new(0.5, 0, 1, -2), UDim2.fromOffset(60, 12), GOLD, 7)
		local boss = circle(f, UDim2.fromOffset(9, 9), UDim2.new(0.5, 30, 1, -66), RED, 0, 6)
		local function sync()
			local txt = env.stageLabel.Text
			num.Text = txt:match("%d+") or "?"
			local isBoss = txt:find("BOSS") ~= nil
			boss.Visible = isBoss
			r:FindFirstChildOfClass("UIStroke").Color = isBoss and RED or PALE
		end
		env.stageLabel:GetPropertyChangedSignal("Text"):Connect(sync)
		sync()
	end

	-- Crystal HP: the moon, waning into a crescent
	if env.hpPill and env.hpFill then
		local p = env.hpPill
		strip(p, false)
		local f = holder(p)
		local moonClip = new("CanvasGroup", { Name = "AF_moon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -18, 0.5, 4), Size = UDim2.fromOffset(34, 34), ZIndex = 5 }, f)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, moonClip)
		local moon = circle(moonClip, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Color3.fromRGB(200, 235, 255), 0, 5)
		new("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(240, 250, 255), Color3.fromRGB(120, 190, 255)) }, moon)
		local shadow = circle(moonClip, UDim2.fromScale(1.02, 1.02), UDim2.fromScale(1.6, 0.5), INK, 0, 6)
		local hp = caption(f, "", UDim2.new(0.5, 6, 0.5, 4), UDim2.fromOffset(80, 18), Color3.fromRGB(200, 235, 255), 7, Vector2.new(0, 0.5))
		local function sync()
			local frac = env.hpFill.Size.X.Scale
			shadow.Position = UDim2.fromScale(0.5 + 1.1 * frac, 0.5) -- full: shadow off to the side; empty: shadow covers the moon
			local low = frac < 0.3
			moon.BackgroundColor3 = low and RED or Color3.fromRGB(200, 235, 255)
			if env.hpLabel then hp.Text = env.hpLabel.Text end
		end
		env.hpFill:GetPropertyChangedSignal("Size"):Connect(sync)
		if env.hpLabel then env.hpLabel:GetPropertyChangedSignal("Text"):Connect(sync) end
		sync()
	end

	-- the dock: three different point-and-line figures
	if env.dock then
		local figures = {
			["Skill Tree"] = function(f) -- a branch
				local c = Vector2.new(36, 36)
				line(f, Vector2.new(36, 52), Vector2.new(36, 34), VIOLET, 3, 5)
				line(f, Vector2.new(36, 34), Vector2.new(22, 20), VIOLET, 3, 5)
				line(f, Vector2.new(36, 34), Vector2.new(50, 20), VIOLET, 3, 5)
				circle(f, UDim2.fromOffset(12, 12), UDim2.fromOffset(36, 54), VIOLET, 0, 6)
				circle(f, UDim2.fromOffset(12, 12), UDim2.fromOffset(22, 20), Color3.fromRGB(200, 170, 255), 0, 6)
				circle(f, UDim2.fromOffset(12, 12), UDim2.fromOffset(50, 20), Color3.fromRGB(200, 170, 255), 0, 6)
			end,
			["Progression"] = function(f) -- three points climbing
				line(f, Vector2.new(16, 54), Vector2.new(36, 38), GOLD, 2, 5)
				line(f, Vector2.new(36, 38), Vector2.new(56, 18), GOLD, 2, 5)
				circle(f, UDim2.fromOffset(9, 9), UDim2.fromOffset(16, 54), GOLD, 0, 6)
				circle(f, UDim2.fromOffset(12, 12), UDim2.fromOffset(36, 38), GOLD, 0, 6)
				circle(f, UDim2.fromOffset(16, 16), UDim2.fromOffset(56, 18), AMBER, 0, 6)
			end,
			["Settings"] = function(f) -- two rings and a point
				ring(f, UDim2.fromOffset(46, 46), UDim2.fromOffset(36, 36), CYAN, 2, 5)
				ring(f, UDim2.fromOffset(26, 26), UDim2.fromOffset(36, 36), CYAN, 2, 5)
				circle(f, UDim2.fromOffset(8, 8), UDim2.fromOffset(36, 36), PALE, 0, 6)
			end,
		}
		local done = {}
		local function apply(h)
			local fig = figures[h.Name]
			local b = h:FindFirstChildWhichIsA("GuiButton")
			if fig and b and not done[h] then
				done[h] = true
				-- keep the badge (skill points) visible: it is information, not skin
				local badge
				for _, c in b:GetChildren() do
					if c:IsA("Frame") and c.Size == UDim2.fromOffset(26, 26) then badge = c end
				end
				strip(b, false)
				if badge then
					badge.Visible = true
					for _, d in badge:GetDescendants() do if d:IsA("GuiObject") then d.Visible = true end end
					badge.ZIndex = 9
				end
				local f = holder(b)
				fig(f)
				for _, c in h:GetChildren() do -- restyle the caption under it
					if c:IsA("TextLabel") then
						c.FontFace = Font.fromName("Merriweather", Enum.FontWeight.Bold)
						c.TextColor3 = h.Name == "Skill Tree" and Color3.fromRGB(200, 170, 255) or (h.Name == "Progression" and GOLD or CYAN)
					end
				end
			end
		end
		for _, h in env.dock:GetChildren() do apply(h) end
		env.dock.ChildAdded:Connect(function(h) task.wait(0.2) apply(h) end) -- Settings is added later in GameClient
	end

	-- slow motion only; none with Reduced Motion
	RunService.RenderStepped:Connect(function(dt)
		if reduced() then return end
		for _, s in spin do
			s.boost = math.max(0, (s.boost or 0) - dt * 1.2)
			s.o.Rotation = (s.o.Rotation + dt * (s.speed + 600 * s.boost)) % 360
		end
	end)
	return true
end
