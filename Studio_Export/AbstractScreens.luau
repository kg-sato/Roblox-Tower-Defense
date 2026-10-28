--!nocheck
-- AbstractScreens (2026-10-28). The rest of "make everything abstract" after the HUD (AbstractHUD.luau): the start menu,
-- the streak badge, the boss plate and the four panels. Same rules (Roblox Dev/Research/UI/Abstract HUD.md): no
-- rectangles, pills, plain bars or framed boxes; every control its own form built from points, lines, circles,
-- triangles and arcs; numbers stay plain text; old art is hidden, not deleted.

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local INK = Color3.fromRGB(14, 9, 26)
local VIOLET = Color3.fromRGB(110, 66, 210)
local AMBER = Color3.fromRGB(255, 176, 70)
local GOLD = Color3.fromRGB(255, 214, 130)
local CYAN = Color3.fromRGB(110, 220, 255)
local PALE = Color3.fromRGB(236, 228, 255)
local RED = Color3.fromRGB(255, 92, 92)
local GREY = Color3.fromRGB(120, 112, 140)
local SERIF = Font.fromName("Merriweather", Enum.FontWeight.Bold)

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
local function hline(parent, pos, w, color, thick, z, anchor)
	return new("Frame", { Name = "AF_line", BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = anchor or Vector2.new(0, 0.5), Position = pos, Size = UDim2.fromOffset(w, thick or 2), ZIndex = z or 5 }, parent)
end
local function caption(parent, text, pos, size, color, z, anchor, align)
	local l = new("TextLabel", { Name = "AF_text", BackgroundTransparency = 1, Text = text, FontFace = SERIF, TextScaled = true, TextColor3 = color, AnchorPoint = anchor or Vector2.new(0.5, 0.5), Position = pos, Size = size, ZIndex = z or 7, TextXAlignment = align or Enum.TextXAlignment.Center }, parent)
	new("UIStroke", { Color = INK, Thickness = 1.5, Transparency = 0.2 }, l)
	return l
end
local function strip(b, keep)
	keep = keep or {}
	for _, d in b:GetDescendants() do
		if d:IsA("GuiObject") and not d.Name:match("^AF_") and not keep[d] then
			d.Visible = false
		elseif (d:IsA("UIStroke") or d:IsA("UIGradient")) and d.Parent == b then
			d.Enabled = false
		end
	end
	if b:IsA("GuiObject") then b.BackgroundTransparency = 1 end
	if b:IsA("TextButton") then b.TextTransparency = 1 end
end
local function holder(b, z)
	return new("Frame", { Name = "AF_form", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z or 4 }, b)
end

return function(env)
	local gui = env.gui
	local reduced = env.reducedMotion or function() return false end

	----------------------------------------------------------------------------------------------- start menu
	task.spawn(function()
		local sm = gui:WaitForChild("StartMenu", 10)
		local menu = sm and sm:WaitForChild("MenuHolder", 5) and sm.MenuHolder:WaitForChild("Menu", 5)
		if not menu then return end
		-- the crown becomes a dawn mark: a point resting on a short line
		local icon = menu:FindFirstChild("Icon")
		if icon then
			icon.ImageTransparency = 1
			local f = holder(icon)
			hline(f, UDim2.new(0.5, 0, 0.72, 0), 56, GOLD, 2, 5, Vector2.new(0.5, 0.5))
			circle(f, UDim2.fromOffset(24, 24), UDim2.fromScale(0.5, 0.56), AMBER, 0, 5)
		end
		for _, c in menu:GetChildren() do
			-- PLAY: a sun rising over a horizon line
			if c:IsA("TextButton") and c.Text:find("LAMP") then
				strip(c)
				local f = holder(c)
				hline(f, UDim2.new(0, 0, 0.7, 0), 298, GOLD, 2, 5)
				local clip = new("Frame", { Name = "AF_sunclip", BackgroundTransparency = 1, ClipsDescendants = true, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0, 46, 0.7, -1), Size = UDim2.fromOffset(80, 40), ZIndex = 5 }, f)
				local sun = circle(clip, UDim2.fromOffset(76, 76), UDim2.fromScale(0.5, 1), AMBER, 0, 5)
				new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 230, 150), Color3.fromRGB(240, 120, 40)) }, sun)
				caption(f, "LIGHT THE LAMP", UDim2.new(0, 100, 0.42, 0), UDim2.fromOffset(190, 34), PALE, 7, Vector2.new(0, 0.5), Enum.TextXAlignment.Left)
				c.MouseEnter:Connect(function() if not reduced() then TweenService:Create(sun, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.8) }):Play() end end)
				c.MouseLeave:Connect(function() TweenService:Create(sun, TweenInfo.new(0.2), { Position = UDim2.fromScale(0.5, 1) }):Play() end)
			end
			-- the gazette: no parchment, just a violet line and the text
			if c.Name == "News" then
				for _, d in c:GetChildren() do
					if d:IsA("ImageLabel") or (d:IsA("Frame") and not d.Name:match("^AF_")) then d.Visible = false end
				end
				c.BackgroundTransparency = 1
				hline(c, UDim2.new(0, -4, 0, 4), 2, VIOLET, 2, 5).Size = UDim2.new(0, 3, 1, -8)
				for _, d in c:GetChildren() do
					if d:IsA("TextLabel") then
						d.FontFace = SERIF
						d.TextColor3 = d.Text:find("GAZETTE") and GOLD or PALE
						d.Rotation = 0
					end
				end
				c.Rotation = 0
			end
			-- flashes: a switch made of a line and a point
			if c.Name == "FlashToggle" then
				local keepT
				strip(c)
				local f = holder(c)
				hline(f, UDim2.new(0, 6, 0.5, 0), 34, GREY, 2, 5)
				local knob = circle(f, UDim2.fromOffset(14, 14), UDim2.new(0, 6, 0.5, 0), GREY, 0, 6)
				local t = caption(f, "", UDim2.new(0, 52, 0.5, 0), UDim2.fromOffset(130, 22), PALE, 7, Vector2.new(0, 0.5), Enum.TextXAlignment.Left)
				local function sync()
					local txt = c.Text ~= "" and c.Text or ""
					for _, d in c:GetDescendants() do if d:IsA("TextLabel") and d.Name ~= "AF_text" and d.Text ~= "" then txt = d.Text end end
					local on = txt:find("ON") ~= nil
					knob.Position = UDim2.new(0, on and 40 or 6, 0.5, 0)
					knob.BackgroundColor3 = on and AMBER or GREY
					t.Text = on and "Flashes on" or "Flashes off"
				end
				c:GetPropertyChangedSignal("Text"):Connect(function() task.defer(sync) end)
				for _, d in c:GetDescendants() do if d:IsA("TextLabel") then d:GetPropertyChangedSignal("Text"):Connect(function() task.defer(sync) end) end end
				sync()
			end
			if c.Name == "FlashNotice" then c.FontFace = SERIF; c.TextColor3 = GREY end
		end
	end)

	----------------------------------------------------------------------------------------------- streak badge
	-- a column of embers: one ember per perfect stage (up to 6), stacked upward and shrinking like a flame
	local hud = env.hud
	local streak = hud:FindFirstChild("Streak")
	if streak then
		local keep = {}
		local labels = {}
		for _, d in streak:GetChildren() do
			if d:IsA("TextLabel") then keep[d] = true; table.insert(labels, d) end
		end
		strip(streak, keep)
		for _, l in labels do
			l.FontFace = SERIF
			l.TextColor3 = l.TextSize >= 24 and AMBER or GOLD
			for _, st in l:GetChildren() do if st:IsA("UIStroke") then st.Color = INK end end
		end
		local f = holder(streak)
		local embers = {}
		for i = 1, 6 do
			local sz = 14 - i * 1.6
			embers[i] = circle(f, UDim2.fromOffset(sz, sz), UDim2.new(0, 20 + math.sin(i * 1.7) * 3, 1, -6 - (i - 1) * 7), GREY, 0, 5)
		end
		local num = labels[1]
		local function sync()
			local n = tonumber(num and num.Text:match("%d+")) or 0
			for i, e in embers do
				local lit = i <= n
				e.BackgroundColor3 = lit and (i == 1 and Color3.fromRGB(255, 120, 60) or AMBER:Lerp(GOLD, i / 6)) or Color3.fromRGB(60, 50, 70)
				e.Visible = i <= math.max(n, 3)
			end
		end
		if num then num:GetPropertyChangedSignal("Text"):Connect(function() task.defer(sync) end) end
		sync()
		local clock = 0
		RunService.RenderStepped:Connect(function(dt)
			if reduced() or not streak.Visible then return end
			clock += dt
			for i, e in embers do -- the embers sway like a flame
				e.Position = UDim2.new(0, 20 + math.sin(i * 1.7 + clock * 3) * (1 + i * 0.6), 1, -6 - (i - 1) * 7)
			end
		end)
	end

	----------------------------------------------------------------------------------------------- boss plate
	-- no plate, no chains: the boss's name, its life as a red comet (a tapered line with a diamond head that slides
	-- back as it is hit, the pale trail behind it) and the burning wick
	local function bossify(bg)
		local plate = bg:FindFirstChild("Plate")
		if not plate or plate:GetAttribute("AF") then return end
		plate:SetAttribute("AF", true)
		for _, c in plate:GetChildren() do
			if c:IsA("ImageLabel") and c.Name:match("^Obj_") then c.Visible = false end
			if c:IsA("Frame") and c.Size == UDim2.fromOffset(3, 22) then c.Visible = false end -- chains
		end
		for _, c in plate:GetChildren() do
			if c:IsA("Frame") and c:FindFirstChildOfClass("UIScale") then -- the life ribbon
				c.BackgroundTransparency = 1
				for _, st in c:GetChildren() do if st:IsA("UIStroke") then st.Enabled = false end end
				local fills = {}
				for _, d in c:GetChildren() do
					if d:IsA("Frame") then
						if d.Size == UDim2.new(0, 2, 1, 0) then d.Visible = false else table.insert(fills, d) end
					end
				end
				for _, d in fills do
					new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, d)
					local hasGrad = d:FindFirstChildOfClass("UIGradient")
					if hasGrad then -- the fill: taper toward the left, a diamond head on the right
						new("UIGradient", { Name = "AF_taper", Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(0.7, 0.1), NumberSequenceKeypoint.new(1, 0) }) }, new("Frame", { Name = "AF_dummy", Visible = false }, d))
						hasGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(0.7, 0.05), NumberSequenceKeypoint.new(1, 0) })
						local head = new("Frame", { Name = "AF_head", BackgroundColor3 = Color3.fromRGB(255, 120, 110), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(16, 16), Rotation = 45, ZIndex = 6 }, d)
					else -- the pale trail: thinner and fainter
						d.BackgroundTransparency = 0.55
					end
				end
				c.Size = UDim2.new(c.Size.X.Scale, c.Size.X.Offset, 0, 10)
			end
		end
		for _, c in plate:GetChildren() do
			if c:IsA("TextLabel") and c.Text ~= "" and c.Position.Y.Offset < 20 then -- the boss's name: a red point before it
				circle(plate, UDim2.fromOffset(9, 9), UDim2.new(0.1, 0, 0, 16), RED, 0, 6)
			end
		end
	end
	for _, c in hud:GetChildren() do
		if c:IsA("Frame") then
			if c:FindFirstChild("Plate") then bossify(c) end
			c.ChildAdded:Connect(function(k) if k.Name == "Plate" then task.defer(bossify, c) end end)
		end
	end

	----------------------------------------------------------------------------------------------- panels
	-- no glass frame: a soft pool of ink (blurred round fields, not a box) keeps text readable; dividers become thin
	-- gold lines; the close button is two crossing lines; then each panel's own controls get their own forms
	local RAR = { COMMON = Color3.fromRGB(200, 200, 210), RARE = CYAN, EPIC = Color3.fromRGB(190, 120, 255), LEGENDARY = AMBER }
	local FLAME, PLAQUE = "rbxassetid://108574647086501", "rbxassetid://83841573700983"
	local function pool(panel)
		local w, h = panel.Size.X.Offset, panel.Size.Y.Offset
		for _, rot in { 0, 90 } do -- two crossed horizontal fades on round frames = a soft radial pool
			local c = circle(panel, UDim2.fromOffset(w * 1.25, h * 1.2), UDim2.fromScale(0.5, 0.5), INK, 0, 0)
			c.Name = "AF_pool"
			new("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.25), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(0.8, 0.25), NumberSequenceKeypoint.new(1, 1) }) }, c)
		end
	end
	local function closeX(b)
		strip(b)
		local f = holder(b, 8)
		for _, r in { 45, -45 } do
			new("Frame", { Name = "AF_line", BackgroundColor3 = PALE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 2), Rotation = r, ZIndex = 8 }, f)
		end
	end
	local function dividers(panel)
		for _, d in panel:GetDescendants() do
			if d:IsA("ImageLabel") and d.Name == "Divider" then
				d.ImageTransparency = 1
				new("Frame", { Name = "AF_line", BackgroundColor3 = GOLD, BackgroundTransparency = 0.55, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.7, 0, 0, 1), ZIndex = d.ZIndex }, d)
			end
		end
	end
	local function base(panel)
		for _, c in panel:GetChildren() do
			if c:IsA("ImageLabel") and (c.Name == "Glass" or c.Name == "Emblem") then c.Visible = false end
			if c:IsA("TextButton") and c.Text == "X" then closeX(c) end
		end
		panel.BackgroundTransparency = 1
		for _, st in panel:GetChildren() do if st:IsA("UIStroke") then st.Enabled = false end end
		pool(panel)
		dividers(panel)
		for _, d in panel:GetDescendants() do
			if d:IsA("TextLabel") and not d.Name:match("^AF_") then d.FontFace = SERIF end
		end
	end

	local function oddsPanel(panel)
		-- each rarity a circle whose AREA is its chance; the tarot cards are hidden
		for _, card in panel:GetDescendants() do
			if card:IsA("Frame") and card.Size == UDim2.fromOffset(92, 200) then
				local name, pct, tint
				for _, k in card:GetChildren() do
					if k:IsA("Frame") then tint = k.BackgroundColor3; k.Visible = false end
					if k:IsA("ImageLabel") then k.Visible = false end
					if k:IsA("TextLabel") and RAR[k.Text] then name = k end
					if k:IsA("TextLabel") and k.Size == UDim2.fromOffset(100, 26) then pct = k end
				end
				card.Rotation = 0
				local col = (name and RAR[name.Text]) or tint or PALE
				local disc = circle(card, UDim2.fromOffset(20, 20), UDim2.new(0.5, 0, 0, 80), col, 0.05, 3)
				ring(card, UDim2.fromOffset(96, 96), UDim2.new(0.5, 0, 0, 80), col, 1, 2)
				local function sync()
					local v = pct and tonumber(pct.Text:match("[%d%.]+")) or 25
					local dpx = math.clamp(12 + 84 * math.sqrt(v / 100), 8, 96)
					disc.Size = UDim2.fromOffset(dpx, dpx)
				end
				if pct then pct:GetPropertyChangedSignal("Text"):Connect(function() task.defer(sync) end) end
				sync()
			end
		end
	end

	local function petPanel(panel)
		for _, row in panel:GetDescendants() do
			if row:IsA("TextButton") and row.Size == UDim2.fromOffset(104, 54) then -- buy: a plus of two lines and the price
				local txt = row:FindFirstChild("Txt")
				local keep = {}
				if txt then keep[txt] = true end
				strip(row, keep)
				local f = holder(row)
				new("Frame", { Name = "AF_line", BackgroundColor3 = AMBER, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 18, 0.5, 0), Size = UDim2.fromOffset(18, 3), ZIndex = 6 }, f)
				new("Frame", { Name = "AF_line", BackgroundColor3 = AMBER, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 18, 0.5, 0), Size = UDim2.fromOffset(3, 18), ZIndex = 6 }, f)
				if txt then
					txt.Visible = true
					txt.FontFace = SERIF
					txt.TextColor3 = GOLD
					txt.Position = UDim2.fromOffset(32, 0)
					txt.Size = UDim2.new(1, -32, 1, 0)
					txt.TextXAlignment = Enum.TextXAlignment.Left
				end
			end
			if row:IsA("TextButton") and row.Text == "Delete" then -- release: a red point struck through by a line
				strip(row)
				local f = holder(row)
				circle(f, UDim2.fromOffset(16, 16), UDim2.new(0, 22, 0.5, 0), RED, 0, 6)
				new("Frame", { Name = "AF_line", BackgroundColor3 = PALE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 22, 0.5, 0), Size = UDim2.fromOffset(28, 2), Rotation = -35, ZIndex = 7 }, f)
				caption(f, "RELEASE", UDim2.new(0, 44, 0.5, 0), UDim2.fromOffset(120, 20), RED, 7, Vector2.new(0, 0.5), Enum.TextXAlignment.Left)
			end
		end
	end

	local function settingsPanel(panel)
		for _, d in panel:GetDescendants() do
			if d:IsA("ImageLabel") and (d.Image == FLAME or d.Image == PLAQUE) then
				d.ImageTransparency = 1
				d:GetPropertyChangedSignal("ImageTransparency"):Connect(function() if d.ImageTransparency < 1 then d.ImageTransparency = 1 end end)
			end
		end
		for _, b in panel:GetDescendants() do
			if b:IsA("TextButton") and b.Text == "" then -- candles -> a point: filled amber when on, a hollow grey ring when off
				local word
				for _, k in b:GetChildren() do
					if k:IsA("TextLabel") and (k.Text == "LIT" or k.Text == "SNUFFED") then word = k end
				end
				if word then
					for _, k in b:GetChildren() do if k:IsA("Frame") then k.Visible = false end end
					local f = holder(b)
					local dot = circle(f, UDim2.fromOffset(16, 16), UDim2.new(0.2, 0, 0.5, 0), AMBER, 0, 6)
					local r = ring(f, UDim2.fromOffset(16, 16), UDim2.new(0.2, 0, 0.5, 0), GREY, 2, 6)
					local function sync()
						local on = word.Text == "LIT" or word.Text == "ON"
						dot.Visible = on
						r.Visible = not on
						word.Text = on and "ON" or "OFF"
						word.TextColor3 = on and GOLD or GREY
					end
					word:GetPropertyChangedSignal("Text"):Connect(function()
						if word.Text == "LIT" or word.Text == "SNUFFED" then task.defer(sync) end
					end)
					sync()
				end
			end
			-- the choice glow capsule (a pill) goes; the gold diamond pointer stays
			if b:IsA("Frame") and b:FindFirstChildOfClass("UICorner") and b.BackgroundTransparency >= 0.7 and b.BackgroundTransparency < 0.8 then
				b.Visible = false
			end
		end
	end

	-- bars inside panels become lines: the track is a thin grey line; the fill is a thin coloured line (with a point at
	-- its end for XP). Used for the settings volume rails and the progression XP bar.
	local function lineBar(track, color, headPoint)
		if track:GetAttribute("AF") then return end
		track:SetAttribute("AF", true)
		track.BackgroundTransparency = 1
		for _, k in track:GetChildren() do
			if k:IsA("UIStroke") then k.Enabled = false end
		end
		new("Frame", { Name = "AF_line", BackgroundColor3 = GREY, BackgroundTransparency = 0.3, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 2), ZIndex = track.ZIndex }, track)
		for _, fill in track:GetChildren() do
			if fill:IsA("Frame") and fill:FindFirstChildOfClass("UIGradient") then
				fill.BackgroundTransparency = 1
				new("Frame", { Name = "AF_line", BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 3), ZIndex = fill.ZIndex + 1 }, fill)
				if headPoint then circle(fill, UDim2.fromOffset(12, 12), UDim2.fromScale(1, 0.5), color, 0, fill.ZIndex + 2) end
			end
		end
	end
	local SEAL = "rbxassetid://78303286285946"
	local function panelBars(panel, kind)
		for _, d in panel:GetDescendants() do
			if kind == "settings" and d:IsA("Frame") and d.Active and d:FindFirstChildOfClass("UIStroke") and d:FindFirstChildOfClass("UICorner") then
				lineBar(d, AMBER, false)
			end
			if kind == "settings" and d:IsA("ImageLabel") and d.Image == SEAL then -- reset: a red triangle outline, not a wax seal
				d.ImageTransparency = 1
				local f = holder(d, (d.ZIndex or 5) + 1)
				local clip = new("Frame", { Name = "AF_tri", BackgroundTransparency = 1, ClipsDescendants = true, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.7, 0.35), ZIndex = f.ZIndex }, f)
				new("Frame", { Name = "AF_sq", BackgroundColor3 = RED, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(0.72, 1.44), SizeConstraint = Enum.SizeConstraint.RelativeXX, Rotation = 45, ZIndex = f.ZIndex }, clip)
			end
			if kind == "prog" and d:IsA("Frame") and not d:IsA("ScrollingFrame") then -- the XP bar: a frame with a gradient fill whose parent shows "XP"
				local hasFill, xpText = false, false
				for _, k in d:GetChildren() do
					if k:IsA("Frame") and k:FindFirstChildOfClass("UIGradient") then hasFill = true end
					if k:IsA("TextLabel") then xpText = true end -- its "x / y XP" text is filled in later, so only check it exists
				end
				if hasFill and xpText then lineBar(d, GOLD, true) end
			end
		end
	end
	----------------------------------------------------------------------------------------------- tutorial note
	-- no parchment, seal or plaque: a violet guide point with a line running down from it, the instruction in pale
	-- text, "the Lamplighter" in gold, and Skip as underlined text
	local tut = env.tutCard
	if tut and env.tutText then
		local keep = { [env.tutText] = true }
		local sig, skip
		for _, c in tut:GetChildren() do
			if c:IsA("TextLabel") and c.Text:find("Lamplighter") then sig = c; keep[c] = true end
			if c:IsA("TextButton") and c.Text == "Skip" then skip = c end
		end
		strip(tut, keep)
		for _, g in tut:GetChildren() do if g:IsA("UIGradient") then g.Enabled = false end end
		pool(tut)
		local f = holder(tut, 7)
		local guide = circle(f, UDim2.fromOffset(18, 18), UDim2.new(0, 22, 0, 16), VIOLET, 0, 8)
		new("Frame", { Name = "AF_line", BackgroundColor3 = VIOLET, BackgroundTransparency = 0.3, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0, 22, 0, 26), Size = UDim2.new(0, 2, 1, -32), ZIndex = 7 }, f)
		if not reduced() then
			TweenService:Create(guide, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromOffset(22, 22) }):Play()
		end
		env.tutText.Visible = true
		env.tutText.TextColor3 = PALE
		env.tutText.FontFace = SERIF
		env.tutText.Position = UDim2.new(0, 42, 0.5, -6)
		if sig then sig.TextColor3 = GOLD; sig.FontFace = SERIF end
		if skip then
			local st = skip:FindFirstChild("Txt")
			strip(skip, st and { [st] = true } or {})
			if st then st.Visible = true; st.TextColor3 = GREY; st.FontFace = SERIF end
			new("Frame", { Name = "AF_line", BackgroundColor3 = GREY, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 12), Size = UDim2.fromOffset(30, 1), ZIndex = 8 }, holder(skip, 8))
		end
	end

	----------------------------------------------------------------------------------------------- banners and toasts
	-- a banner is its words plus a line drawn out from the middle with a point at each end (Saul Bass bars); the line
	-- takes the banner's colour. A toast gets a small red point before it.
	if env.banner then
		local b = env.banner
		local bar = new("Frame", { Name = "AF_bannerline", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(b.Position.X.Scale, b.Position.X.Offset, b.Position.Y.Scale, b.Position.Y.Offset + 44), Size = UDim2.fromOffset(0, 10), ZIndex = b.ZIndex }, b.Parent)
		local ln = new("Frame", { Name = "AF_line", BackgroundColor3 = GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 2), ZIndex = b.ZIndex }, bar)
		local p1 = circle(bar, UDim2.fromOffset(9, 9), UDim2.fromScale(0, 0.5), GOLD, 0, b.ZIndex)
		local p2 = circle(bar, UDim2.fromOffset(9, 9), UDim2.fromScale(1, 0.5), GOLD, 0, b.ZIndex)
		local token = 0
		b:GetPropertyChangedSignal("Text"):Connect(function()
			token += 1
			local mine = token
			local c = b.TextColor3
			task.defer(function()
				c = b.TextColor3
				ln.BackgroundColor3, p1.BackgroundColor3, p2.BackgroundColor3 = c, c, c
				for _, o in { ln, p1, p2 } do o.BackgroundTransparency = 0 end
				bar.Size = UDim2.fromOffset(0, 10)
				local w = math.clamp(b.TextBounds.X + 80, 160, 700)
				TweenService:Create(bar, TweenInfo.new(reduced() and 0 or 0.35, Enum.EasingStyle.Quint), { Size = UDim2.fromOffset(w, 10) }):Play()
			end)
			task.delay(1.6, function()
				if mine ~= token then return end
				for _, o in { ln, p1, p2 } do TweenService:Create(o, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play() end
			end)
		end)
		b.FontFace = SERIF
		if env.subBanner then env.subBanner.FontFace = SERIF end
	end
	if env.toast then
		local t = env.toast
		t.FontFace = SERIF
		local dot = circle(t.Parent, UDim2.fromOffset(10, 10), UDim2.new(t.Position.X.Scale, 0, t.Position.Y.Scale, 0), RED, 1, t.ZIndex)
		t:GetPropertyChangedSignal("TextTransparency"):Connect(function()
			dot.BackgroundTransparency = t.TextTransparency
			dot.Position = UDim2.new(t.Position.X.Scale, t.Position.X.Offset - t.TextBounds.X / 2 - 14, t.Position.Y.Scale, t.Position.Y.Offset)
		end)
	end

	----------------------------------------------------------------------------------------------- skill tree screen
	-- hex tokens become circles: the outer hex layer becomes a thin ring, the inner layers concentric discs; each circle
	-- copies its hex's live colour and transparency (so locked / buyable / owned states keep working); the object icons
	-- go and the node's short word (GO, ATK, $, HP...) shows instead
	task.spawn(function()
		local tree = hud:WaitForChild("Tree", 10)
		if not tree then return end
		local function convertHex(img)
			if img:GetAttribute("AF") then return end
			img:SetAttribute("AF", true)
			local layer = img.Parent
			local outer = layer.Size.X.Offset >= 100
			local c = new("Frame", { Name = "AF_hexcircle", BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(outer and 0.86 or 0.92, outer and 0.86 or 0.92), ZIndex = img.ZIndex }, layer)
			new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, c)
			local st = outer and new("UIStroke", { Thickness = 2 }, c) or nil
			local function sync()
				local col, t = img.ImageColor3, img.ImageTransparency
				if outer then
					st.Color = col
					st.Transparency = t
				else
					c.BackgroundColor3 = col
					c.BackgroundTransparency = t
				end
				c.Visible = layer.Visible
			end
			img:GetPropertyChangedSignal("ImageColor3"):Connect(sync)
			img:GetPropertyChangedSignal("ImageTransparency"):Connect(sync)
			sync()
			img.Visible = false
			img:GetPropertyChangedSignal("Visible"):Connect(function() if img.Visible then img.Visible = false end end)
		end
		local function convert()
			for _, d in tree:GetDescendants() do
				if d:IsA("ImageLabel") and d.Image == "" and not d.Name:match("^AF_") and d.Parent and d.Parent:IsA("Frame") and d.Size == UDim2.fromScale(1.14285719, 1.14285719) then
					convertHex(d)
				elseif d:IsA("ImageLabel") and d.Name == "Icon" and not d:GetAttribute("AF") then
					d:SetAttribute("AF", true)
					d.Visible = false
					d:GetPropertyChangedSignal("Visible"):Connect(function() if d.Visible then d.Visible = false end end)
					for _, s in d.Parent:GetChildren() do
						if s:IsA("TextLabel") then s.Visible = true; s.FontFace = SERIF; s.TextColor3 = PALE end
					end
				elseif d:IsA("TextLabel") and not d.Name:match("^AF_") then
					d.FontFace = SERIF
				end
			end
		end
		convert()
		tree.DescendantAdded:Connect(function() task.defer(convert) end)
	end)

	-- skill tree: the info box loses its frame (a violet line at its left edge instead), BUY becomes a chevron of two
	-- lines pointing up with its text, Close becomes the two crossing lines
	task.spawn(function()
		local tree = hud:WaitForChild("Tree", 10)
		if not tree then return end
		task.wait(1)
		for _, b in tree:GetDescendants() do
			if b:IsA("TextButton") and b.Text:find("BUY") and not b:GetAttribute("AF") then
				b:SetAttribute("AF", true)
				local txt = b:FindFirstChild("Txt")
				strip(b, txt and { [txt] = true } or {})
				local f = holder(b)
				for _, sgn in { -1, 1 } do
					new("Frame", { Name = "AF_line", BackgroundColor3 = VIOLET, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 22 + sgn * 6, 0.5, 0), Size = UDim2.fromOffset(16, 3), Rotation = sgn * 45, ZIndex = 6 }, f) -- a ^ pointing up
				end
				if txt then txt.Visible = true; txt.TextColor3 = Color3.fromRGB(200, 170, 255); txt.FontFace = SERIF; txt.Position = UDim2.fromOffset(18, 0) end
				local box = b.Parent
				if box and box:IsA("Frame") and box ~= tree then
					box.BackgroundTransparency = 1
					for _, k in box:GetChildren() do
						if k:IsA("UIStroke") then k.Enabled = false end
						if k:IsA("ImageLabel") then k.Visible = false end -- frame skin and the skill's object icon
					end
					new("Frame", { Name = "AF_line", BackgroundColor3 = VIOLET, BorderSizePixel = 0, Position = UDim2.fromOffset(-8, 6), Size = UDim2.new(0, 2, 1, -12), ZIndex = box.ZIndex + 1 }, box)
				end
			elseif b:IsA("TextButton") and b.Text == "Close" and not b:GetAttribute("AF") then
				b:SetAttribute("AF", true)
				local txt = b:FindFirstChild("Txt")
				strip(b, txt and { [txt] = true } or {})
				local f = holder(b, 8)
				for _, r in { 45, -45 } do
					new("Frame", { Name = "AF_line", BackgroundColor3 = PALE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 30, 0.5, 0), Size = UDim2.fromOffset(18, 2), Rotation = r, ZIndex = 8 }, f)
				end
				if txt then txt.Visible = true; txt.TextColor3 = PALE; txt.FontFace = SERIF end
			end
		end
	end)

	local done = {}
	local function apply(f)
		if done[f] or not f:IsA("Frame") then return end
		local sz = f.Size
		local kind = (sz == UDim2.fromOffset(300, 412) and "pet") or (sz == UDim2.fromOffset(440, 360) and "odds") or (sz == UDim2.fromOffset(780, 440) and "prog") or (sz == UDim2.fromOffset(440, 560) and "settings")
		if not kind then return end
		done[f] = true
		base(f)
		if kind == "odds" then oddsPanel(f) elseif kind == "pet" then petPanel(f) elseif kind == "settings" then settingsPanel(f) end
		panelBars(f, kind)
	end
	task.delay(1, function()
		for _, f in hud:GetChildren() do
			local ok, e = pcall(apply, f)
			if not ok then warn("AbstractScreens panel: " .. tostring(e)) end
		end
	end)
	hud.ChildAdded:Connect(function(f) task.delay(0.5, function() pcall(apply, f) end) end)

	return true
end
