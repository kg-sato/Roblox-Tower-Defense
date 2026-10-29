--!nocheck
-- SkillTreeV3 (StarterPlayerScripts, 2026-10-29). The user: the skill tree was "too straight / clunky; more whimsical,
-- less straightforward". Replaces SkillTreeArt v2 (kept as the backup; GameClient requires this module instead).
-- A gold-ink tarot web: a glowing hub with a slow zodiac ring, six arcana headings (Roman numeral roundels), branches
-- that are drawn as S-curves from a thick stem outward with hairline twigs, nodes at irregular spots (small ring
-- icons, dim when locked, lit and larger when owned, a tiny orbit ring around lit ones), drifting dust, four-point
-- star twinkles, an iris-ring opening wipe, and a line that grows from the stem when a skill is unlocked.
-- UI only: the server decides points and purchases (env.buy, env.fire("Respec")). Scale sizing; Offset only in strokes.
-- Called once from GameClient (same env as SkillTreeArt plus fire); GameClient calls .sync(snap) after each refresh.
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local INK = Color3.fromRGB(12, 11, 10)
local GOLD, LIGHT, CREAM = Color3.fromRGB(184, 151, 90), Color3.fromRGB(217, 184, 120), Color3.fromRGB(239, 230, 207)
local DIM, FAINT = Color3.fromRGB(104, 88, 58), Color3.fromRGB(70, 60, 42)
local ICONS = {
	Armor = "rbxassetid://140485132734548",
	Charge = "rbxassetid://137915456412547",
	Charm = "rbxassetid://91321861751583",
	Claws = "rbxassetid://104503848358426",
	Clock = "rbxassetid://70371876518220",
	Discount = "rbxassetid://132380128059909",
	Double = "rbxassetid://79355991077094",
	Eye = "rbxassetid://118479517178330",
	Finder = "rbxassetid://140672373757552",
	Guard = "rbxassetid://83091671363094",
	Haste = "rbxassetid://99346353544120",
	Heavy = "rbxassetid://79764788010440",
	Learner = "rbxassetid://128027987548468",
	Magnet = "rbxassetid://114214626329333",
	Mega = "rbxassetid://130998936325390",
	Merger = "rbxassetid://87654079598346",
	Pity = "rbxassetid://139228403939798",
	Refund = "rbxassetid://85148876319062",
	Start = "rbxassetid://88116451873049",
}
local AR = 9 / 16 -- height units to stage width fraction
local ARCANA = { { "I", "The Ember" }, { "II", "The Brass" }, { "III", "The Ward" }, { "IV", "The Storm" }, { "V", "The Fortune" }, { "VI", "The Star" } }
local UNITS = { crystal = " HP", ultNeed = " kill", bossTime = "s", merge = "", rollDiscount = " gem" }

return function(env)
	local treeGui, Config = env.treeGui, env.Config
	local A = require(game:GetService("ReplicatedStorage"):WaitForChild("ArtIds"))
	local M = {}
	local function new(class, props, parent)
		local i = Instance.new(class)
		for k, v in props do i[k] = v end
		i.Parent = parent
		return i
	end
	local function tw(i, t, p, s, d)
		local x = TweenService:Create(i, TweenInfo.new(t, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p)
		x:Play()
		return x
	end
	local function sq(h) return UDim2.fromScale(h * AR, h) end
	local function at(v) return UDim2.fromScale(0.5 + v.X * AR, 0.5 + v.Y) end
	local function reduced() return env.reduced and env.reduced() end

	-- 0) the old pieces go; this module owns the whole screen
	for _, o in { env.treeTitle, env.treeSp, env.detail } do if o then o.Visible = false end end
	for _, d in treeGui:GetChildren() do
		if d:IsA("GuiObject") and d ~= env.treeClose then d.Visible = false end
	end
	for _, g in treeGui:GetChildren() do if g:IsA("UIGradient") then g.Enabled = false end end
	treeGui.BackgroundColor3, treeGui.BackgroundTransparency = INK, 0
	local root = new("Frame", { Name = "TreeV3", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 13, ClipsDescendants = true }, treeGui)
	new("Frame", { Name = "Scrim", BackgroundColor3 = INK, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 13 }, root)
	local S = new("Frame", { Name = "Stage", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), ZIndex = 14 }, root)
	new("UIAspectRatioConstraint", { AspectRatio = 16 / 9, AspectType = Enum.AspectType.FitWithinMaxSize }, S)

	-- 1) layout: hex angles with a seeded wobble, so nothing sits on a grid (positions in height units from the hub)
	local rng = Random.new(11)
	local function hexRing(n) return math.max(math.abs(n.q), math.abs(n.r), math.abs(-n.q - n.r)) end
	local P, ringOf, ids = {}, {}, {}
	local armK, armA = {}, {} -- per path colour: length factor and a curl (angle drift with distance)
	local function layout(seed)
		local g = Random.new(seed)
		P, ringOf, ids, armK, armA = {}, {}, {}, {}, {}
		for _, n in Config.TREE do
			if n.id ~= "Start" and not armK[n.color] then armK[n.color], armA[n.color] = g:NextNumber(0.82, 1.18), g:NextNumber(-0.32, 0.32) end
		end
		local minD = math.huge
		for _, n in Config.TREE do
			local rg = hexRing(n)
			local hx, hy = math.sqrt(3) * (n.q + n.r / 2), 1.5 * n.r
			local a = math.atan2(hy, hx) + math.rad(g:NextNumber(-16, 16))
			local straight = (n.q == 0 or n.r == 0 or n.q == -n.r)
			local r = rg == 0 and 0 or (rg == 1 and g:NextNumber(0.17, 0.25) or (straight and g:NextNumber(0.33, 0.43) or g:NextNumber(0.3, 0.4)))
			if n.id ~= "Start" then r *= armK[n.color]; a += armA[n.color] * (rg - 1) end
			P[n.id], ringOf[n.id] = Vector2.new(math.cos(a) * r * 1.62, math.sin(a) * r), rg
			table.insert(ids, n.id)
		end
		for i = 1, #ids do
			for j = i + 1, #ids do minD = math.min(minD, (P[ids[i]] - P[ids[j]]).Magnitude) end
			if math.abs(P[ids[i]].Y) > 0.37 or math.abs(P[ids[i]].X) > 0.72 then minD = 0 end
		end
		return minD
	end
	for seed = 11, 400 do if layout(seed) >= 0.115 then break end end
	for k = 1, 3 do rng:NextNumber() end

	-- 2) drawing: segments and S-curves
	local function seg(a, b, th, color, tr, z, parent)
		local d = b - a
		local m = (a + b) / 2
		return new("Frame", { BackgroundColor3 = color, BackgroundTransparency = tr, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = at(m), Size = UDim2.fromScale(d.Magnitude * AR, th), Rotation = math.deg(math.atan2(d.Y, d.X)), ZIndex = z }, parent or S)
	end
	local function curve(a, b, bow, n) -- cubic bezier, an S: the two control points bow opposite ways
		local d = b - a
		local perp = Vector2.new(-d.Y, d.X)
		local c1, c2 = a + d / 3 + perp * bow, a + d * 2 / 3 - perp * bow
		local pts = {}
		for i = 0, n do
			local t = i / n
			local u = 1 - t
			pts[i] = a * (u * u * u) + c1 * (3 * u * u * t) + c2 * (3 * u * t * t) + b * (t * t * t)
		end
		return pts
	end
	local edges, edgeOf = {}, {} -- edgeOf[childId] = the primary branch into it
	local function makeEdge(a, b, kind, bow, nseg, th0, th1)
		local pts = curve(P[a], P[b], bow, nseg)
		local e = { a = a, b = b, kind = kind, n = nseg, pts = pts, segs = {}, prog = 0, progT = 0, litP = 0, litT = 0, dirty = true, hold = 0 }
		for i = 1, nseg do
			local th = th0 + (th1 - th0) * (i - 0.5) / nseg
			local f = seg(pts[i - 1], pts[i], th, FAINT, 1, kind == "hair" and 14 or 15)
			f.Visible = false
			if kind == "main" then new("UIStroke", { Color = LIGHT, Thickness = 5, Transparency = 0.78, Enabled = false }, f) end
			table.insert(e.segs, { f = f, t = (i - 0.5) / nseg, main = true })
		end
		if kind == "main" then -- a hairline twig with a dot at its tip, growing from a point along the branch
			local k = rng:NextInteger(4, nseg - 3)
			local o = pts[k]
			local dir = (pts[k + 1] - pts[k - 1]).Unit
			local sgn = rng:NextInteger(0, 1) * 2 - 1
			local ang = math.rad(55) * sgn
			local tdir = Vector2.new(dir.X * math.cos(ang) - dir.Y * math.sin(ang), dir.X * math.sin(ang) + dir.Y * math.cos(ang))
			local tip = o + tdir * rng:NextNumber(0.04, 0.075)
			local tp = curve(o, tip, sgn * 0.3, 4)
			for i = 1, 4 do
				local f = seg(tp[i - 1], tp[i], 0.0011, FAINT, 1, 14)
				f.Visible = false
				table.insert(e.segs, { f = f, t = k / nseg + i / 4 * 0.12 + 0.02, twig = true })
			end

		end
		table.insert(edges, e)
		return e
	end
	local hubEdges = {}
	local primary = {}
	for _, n in Config.TREE do
		if n.id ~= "Start" then
			local parent
			for _, nb in Config.TREE_NEIGHBORS[n.id] do
				if ringOf[nb] == ringOf[n.id] - 1 then parent = parent or nb end
			end
			parent = parent or "Start"
			primary[n.id .. ">" .. parent], primary[parent .. ">" .. n.id] = true, true
			local inner = ringOf[n.id] == 1
			edgeOf[n.id] = makeEdge(parent, n.id, "main", (rng:NextInteger(0, 1) * 2 - 1) * rng:NextNumber(0.13, 0.24), inner and 12 or 11, inner and 0.0056 or 0.0042, inner and 0.0036 or 0.0028)
		end
	end
	local seen = {}
	for _, n in Config.TREE do
		for _, nb in Config.TREE_NEIGHBORS[n.id] do
			local k = n.id < nb and n.id .. ">" .. nb or nb .. ">" .. n.id
			if not seen[k] and not primary[n.id .. ">" .. nb] and n.id ~= "Start" and nb ~= "Start" then
				seen[k] = true
				makeEdge(n.id, nb, "hair", (rng:NextInteger(0, 1) * 2 - 1) * 0.2, 7, 0.0011, 0.0011)
			end
		end
	end

	-- 3) hub: glow, zodiac rings, concentric lines
	local hubG = new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow, ImageColor3 = LIGHT, ImageTransparency = 0.45, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = sq(0.42), ZIndex = 14 }, S)
	local function runeRing(h, n, tickH, gap)
		local c = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = sq(h), ZIndex = 14 }, S)
		for k = 0, n - 1 do
			local a = k / n * math.pi * 2
			local big = k % gap == 0
			new("Frame", { BackgroundColor3 = big and LIGHT or GOLD, BackgroundTransparency = big and 0.35 or 0.7, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + math.cos(a) * 0.5, 0.5 + math.sin(a) * 0.5), Size = UDim2.fromScale(tickH * (big and 1.8 or 1) * AR, 0.0016), Rotation = math.deg(a), ZIndex = 14 }, c)
		end
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, c)
		new("UIStroke", { Color = GOLD, Thickness = 1, Transparency = 0.7 }, c)
		return c
	end
	local zodiac = runeRing(0.95, 72, 0.02, 6)
	local zodiac2 = runeRing(0.62, 48, 0.014, 4)
	for _, rr in { 0.14, 0.52, 0.76 } do
		local c = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = sq(rr), ZIndex = 14 }, S)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, c)
		new("UIStroke", { Color = GOLD, Thickness = 1, Transparency = 0.82 }, c)
	end

	-- 4) ambient: dust and four-point stars
	local dust, stars = {}, {}
	for i = 1, 34 do
		local f = new("Frame", { BackgroundColor3 = i % 3 == 0 and CREAM or LIGHT, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = sq(0.004 + (i % 4) * 0.0012), BackgroundTransparency = 0.4, ZIndex = 14 }, S)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
		dust[i] = { f = f, x = rng:NextNumber(), y = rng:NextNumber(), v = rng:NextNumber(0.008, 0.026), ph = rng:NextNumber(0, 6.28) }
	end
	local function starShape(parent, size, z)
		local c = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = size, ZIndex = z }, parent)
		for _, r in { 0, 90 } do
			new("Frame", { BackgroundColor3 = CREAM, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = r == 0 and UDim2.fromScale(1, 0.12) or UDim2.fromScale(0.12, 1), ZIndex = z }, c)
		end
		new("Frame", { BackgroundColor3 = CREAM, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.2, 0.2), Rotation = 45, ZIndex = z }, c)
		return c
	end
	for i = 1, 14 do -- soft glints (round, no crosses)
		local ang, rr = rng:NextNumber(0, 6.28), rng:NextNumber(0.14, 0.5)
		local f = new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow, ImageColor3 = LIGHT, ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = at(Vector2.new(math.cos(ang) * rr * 1.7, math.sin(ang) * rr * 0.95)), Size = sq(rng:NextNumber(0.02, 0.04)), ZIndex = 14 }, S)
		stars[i] = { f = f, ph = rng:NextNumber(0, 6.28), sp = rng:NextNumber(0.6, 1.6) }
	end

	-- 5) arcana headings: a Roman numeral roundel and a name, outside each path's outermost lantern
	local groups = {}
	local function hue(c) -- which of the six paths a node colour belongs to
		for _, n in Config.TREE do if n.color == c then return n end end
	end
	local order = {}
	for _, n in Config.TREE do
		if n.id ~= "Start" then
			if not groups[n.color] then groups[n.color] = { sum = Vector2.zero, k = 0, far = 0 }; table.insert(order, n.color) end
			local g = groups[n.color]
			g.sum += P[n.id].Unit
			g.k += 1
			g.far = math.max(g.far, P[n.id].Magnitude)
		end
	end
	local headings = {}
	for gi, col in order do
		local g = groups[col]
		local dir = g.sum.Unit
		local ar = ARCANA[gi] or ARCANA[1]
		local far
		for _, n in Config.TREE do if n.color == col and (not far or P[n.id].Magnitude > P[far].Magnitude) then far = n.id end end
		local p = P[far] + dir * 0.15
		for _ = 1, 12 do -- keep clear of every lantern
			for _, n in Config.TREE do
				local dv = p - P[n.id]
				if dv.Magnitude < 0.125 and dv.Magnitude > 0 then p += dv.Unit * 0.035 end
			end
			p = Vector2.new(math.clamp(p.X, -0.8, 0.8), math.clamp(p.Y, -0.38, 0.33))
		end
		local ch = 0.115 -- a small tarot card: double border, numeral, a sigil, the name
		local rd = new("Frame", { BackgroundColor3 = INK, BackgroundTransparency = 0.05, AnchorPoint = Vector2.new(0.5, 0.5), Position = at(p), Size = UDim2.fromScale(ch * 0.64 * AR, ch), ZIndex = 16 }, S)
		new("UICorner", { CornerRadius = UDim.new(0.06, 0) }, rd)
		new("UIStroke", { Color = LIGHT, Thickness = 1.4 }, rd)
		local inner = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.9), ZIndex = 16 }, rd)
		new("UICorner", { CornerRadius = UDim.new(0.05, 0) }, inner)
		new("UIStroke", { Color = GOLD, Thickness = 1, Transparency = 0.5 }, inner)
		new("TextLabel", { BackgroundTransparency = 1, Text = ar[1], TextColor3 = CREAM, TextScaled = true, Size = UDim2.fromScale(0.7, 0.2), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.07), ZIndex = 17 }, rd)
		local sg = new("ImageLabel", { BackgroundTransparency = 1, Image = ICONS[far] or "", ImageColor3 = LIGHT, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.4 * 0.64 / 0.64), ZIndex = 17 }, rd)
		new("UIAspectRatioConstraint", { AspectRatio = 1 }, sg)
		new("TextLabel", { BackgroundTransparency = 1, Text = string.upper(ar[2]), TextColor3 = LIGHT, TextScaled = true, Size = UDim2.fromScale(0.8, 0.12), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.94), ZIndex = 17 }, rd)
		P["H" .. gi] = p
		ringOf["H" .. gi] = 3
		local e = makeEdge(far, "H" .. gi, "hair", 0.12, 6, 0.0016, 0.0016)
		e.group = col
		table.insert(headings, { f = rd, col = col, name = ar[2], edge = e })
	end

	-- 6) nodes
	local N, state, lastLvl = {}, {}, {}
	local snap, hovered, selected
	local HN, HO = 0.082, 0.094 -- node heights (about 67 and 78 px at 1080)
	for _, n in Config.TREE do
		local id = n.id
		local isHub = id == "Start"
		local h = isHub and 0.125 or HN
		local cont = new("Frame", { Name = id, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = at(P[id]), Size = sq(h), ZIndex = 18 }, S)
		local halo = new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow, ImageColor3 = LIGHT, ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(2.4, 2.4), ZIndex = 17 }, cont)
		local orbit = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.55, 1.55), ZIndex = 18 }, cont)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, orbit)
		local oStroke = new("UIStroke", { Color = LIGHT, Thickness = 1, Transparency = 1 }, orbit)
		local moon = new("Frame", { BackgroundColor3 = CREAM, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, -0.05), Size = UDim2.fromScale(0.09, 0.09), BackgroundTransparency = 1, ZIndex = 19 }, orbit)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, moon)
		local ring = new("Frame", { BackgroundColor3 = INK, BackgroundTransparency = 0.12, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 19 }, cont)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
		local stroke = new("UIStroke", { Color = DIM, Thickness = 1.5 }, ring)
		local inner = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.82, 0.82), ZIndex = 19 }, ring)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, inner)
		local iStroke = new("UIStroke", { Color = DIM, Thickness = 1, Transparency = 0.7 }, inner)
		local outer = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.22, 1.22), ZIndex = 19, Visible = false }, cont)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, outer)
		new("UIStroke", { Color = CREAM, Thickness = 1, Transparency = 0.55 }, outer)
		local glyph = new("ImageLabel", { BackgroundTransparency = 1, Image = ICONS[id] or "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.66, 0.66), ZIndex = 20 }, cont)
		local rank = new("TextLabel", { BackgroundColor3 = INK, BackgroundTransparency = 0.15, Text = "", TextColor3 = CREAM, TextScaled = true, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 1.0), Size = UDim2.fromScale(0.5, 0.26), ZIndex = 21, Visible = false }, cont)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, rank)
		new("UIStroke", { Color = GOLD, Thickness = 1 }, rank)
		local nextR = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.35, 1.35), ZIndex = 19, Visible = false }, cont)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, nextR)
		local nStroke = new("UIStroke", { Color = CREAM, Thickness = 1.5, Transparency = 0.2 }, nextR)
		local btn = new("TextButton", { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.15, 1.15), ZIndex = 22 }, cont)
		N[id] = { oStroke = oStroke, id = id, node = n, cont = cont, halo = halo, orbit = orbit, moon = moon, ring = ring, stroke = stroke, iStroke = iStroke, outer = outer, glyph = glyph, rank = rank, nextR = nextR, nStroke = nStroke, btn = btn, h = h, ph = rng:NextNumber(0, 6.28) }
	end

	-- 7) the popup: an ornate gold-ink frame, a title, a thin rule, a description, cost and status
	local PW, PH = 0.2, 0.25 -- of the stage width and height
	local pop = new("Frame", { Name = "Popup", BackgroundColor3 = INK, BackgroundTransparency = 0.04, Visible = false, Size = UDim2.fromScale(PW, PH), ZIndex = 50 }, S)
	new("UIStroke", { Color = LIGHT, Thickness = 1.6 }, pop)
	local pin = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.03, 0.03 * PW * 16 / 9 / PH), Size = UDim2.fromScale(0.94, 1 - 0.06 * PW * 16 / 9 / PH), ZIndex = 50 }, pop)
	new("UIStroke", { Color = GOLD, Thickness = 1, Transparency = 0.5 }, pin)
	for _, c in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do
		new("Frame", { BackgroundColor3 = LIGHT, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(c[1], c[2]), Size = UDim2.fromScale(0.05, 0.05 * PW / PH * 16 / 9), Rotation = 45, ZIndex = 52 }, pop)
	end
	local function lab(props) return new("TextLabel", props, pop) end
	local pPath = lab({ BackgroundTransparency = 1, TextColor3 = GOLD, TextScaled = true, Position = UDim2.fromScale(0.08, 0.07), Size = UDim2.fromScale(0.84, 0.07), ZIndex = 51, Text = "" })
	local pTitle = lab({ BackgroundTransparency = 1, TextColor3 = CREAM, TextScaled = true, Position = UDim2.fromScale(0.08, 0.15), Size = UDim2.fromScale(0.84, 0.13), ZIndex = 51, Text = "" })
	local rule = new("Frame", { BackgroundColor3 = LIGHT, BackgroundTransparency = 0.3, BorderSizePixel = 0, Position = UDim2.fromScale(0.12, 0.3), Size = UDim2.fromScale(0.76, 0.006), ZIndex = 51 }, pop)
	local pDesc = lab({ BackgroundTransparency = 1, TextColor3 = CREAM, TextScaled = true, RichText = true, TextWrapped = true, Position = UDim2.fromScale(0.08, 0.34), Size = UDim2.fromScale(0.84, 0.27), ZIndex = 51, Text = "" })
	local pNext = lab({ BackgroundTransparency = 1, TextColor3 = GOLD, TextScaled = true, Position = UDim2.fromScale(0.08, 0.62), Size = UDim2.fromScale(0.84, 0.07), ZIndex = 51, Text = "" })
	local pCost = lab({ BackgroundTransparency = 1, TextColor3 = LIGHT, TextScaled = true, RichText = true, Position = UDim2.fromScale(0.08, 0.72), Size = UDim2.fromScale(0.84, 0.1), ZIndex = 51, Text = "" })
	local pStatus = lab({ BackgroundTransparency = 1, TextColor3 = DIM, TextScaled = true, Position = UDim2.fromScale(0.08, 0.84), Size = UDim2.fromScale(0.84, 0.08), ZIndex = 51, Text = "" })
	for f, m in { [pPath] = 16, [pTitle] = 26, [pDesc] = 20, [pNext] = 15, [pCost] = 22, [pStatus] = 16 } do new("UITextSizeConstraint", { MaxTextSize = m }, f) end
	local popScale = new("UIScale", { Scale = 1 }, pop) -- (the popup alone pops in with a spring; the layout itself is Scale-sized)

	-- 8) corner pieces: skill points, respec, next-best hint, close
	local bar = new("Frame", { Name = "Bar", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.985), Size = UDim2.fromScale(0.94, 0.07), ZIndex = 30 }, S)
	new("Frame", { BackgroundColor3 = LIGHT, BackgroundTransparency = 0.45, BorderSizePixel = 0, Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 0.02), ZIndex = 30 }, bar)
	local respec = new("TextButton", { BackgroundColor3 = INK, BackgroundTransparency = 0, AutoButtonColor = false, Text = "RESPEC", TextColor3 = LIGHT, TextScaled = true, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.55), Size = UDim2.fromScale(0.13, 0.7), ZIndex = 31 }, bar)
	new("UICorner", { CornerRadius = UDim.new(0.2, 0) }, respec)
	new("UITextSizeConstraint", { MaxTextSize = 22 }, respec)
	local rStroke = new("UIStroke", { Color = GOLD, Thickness = 1.5 }, respec)
	local hintIcon = new("ImageLabel", { BackgroundTransparency = 1, Image = ICONS.Start, ImageColor3 = LIGHT, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.39, 0.55), Size = UDim2.fromScale(0.03, 0.62), ZIndex = 31 }, bar)
	local hint = new("TextLabel", { BackgroundTransparency = 1, Text = "", TextColor3 = LIGHT, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.4, 0.55), Size = UDim2.fromScale(0.28, 0.6), ZIndex = 31 }, bar)
	new("UITextSizeConstraint", { MaxTextSize = 22 }, hint)
	local spText = new("TextLabel", { BackgroundTransparency = 1, Text = "0", TextColor3 = CREAM, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.9, 0.55), Size = UDim2.fromScale(0.05, 0.8), ZIndex = 31 }, bar)
	new("UITextSizeConstraint", { MaxTextSize = 40 }, spText)
	spText:SetAttribute("KeepFont", true)
	spText.Font = Enum.Font.Bodoni
	new("ImageLabel", { BackgroundTransparency = 1, Image = ICONS.Start, ImageColor3 = LIGHT, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.905, 0.55), Size = UDim2.fromScale(0.03, 0.7), ZIndex = 31 }, bar)
	new("TextLabel", { BackgroundTransparency = 1, Text = "POINTS", TextColor3 = GOLD, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.94, 0.58), Size = UDim2.fromScale(0.06, 0.35), ZIndex = 31 }, bar)
	local armed = false
	respec.Activated:Connect(function()
		if respec:GetAttribute("off") then return end
		if not armed then
			armed = true
			respec.Text = "CLICK AGAIN"
			task.delay(3, function() armed = false; respec.Text = "RESPEC" end)
		else
			armed = false
			respec.Text = "RESPEC"
			if env.fire then env.fire("Respec") end
		end
	end)
	local close = env.treeClose
	if close then task.delay(1.5, function() -- after AbstractScreens has styled it
		for _, d in close:GetDescendants() do if d:IsA("GuiObject") or d:IsA("UIStroke") or d:IsA("UIGradient") then pcall(function() d.Visible = false end) pcall(function() d.Enabled = false end) end end
		close.Text, close.TextTransparency = "", 1
		close.AnchorPoint, close.Position, close.Size = Vector2.new(1, 0), UDim2.fromScale(0.975, 0.035), UDim2.fromScale(0.026, 0.046)
		close.BackgroundColor3, close.BackgroundTransparency, close.ZIndex = INK, 0.15, 70
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, close)
		local f = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 70 }, close)
		new("UIStroke", { Color = GOLD, Thickness = 1.5 }, f)
		for _, r in { 45, -45 } do
			new("Frame", { BackgroundColor3 = CREAM, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.06), Rotation = r, ZIndex = 71 }, f)
		end
		close.MouseEnter:Connect(function() tw(f, 0.2, { Rotation = 90 }) end)
		close.MouseLeave:Connect(function() tw(f, 0.2, { Rotation = 0 }) end)
	end) end

	-- 9) rules (read only: the same as the server's)
	local function stateOf(id)
		if id == "Start" then return "start" end
		local node = Config.TREE_BY_ID[id]
		local lvl = snap.tree[id] or 0
		if lvl >= node.max then return "maxed" end
		if lvl > 0 then return "owned" end
		for _, nb in Config.TREE_NEIGHBORS[id] do
			if (snap.tree[nb] or 0) > 0 or nb == "Start" then return "available" end
		end
		return "locked"
	end
	local function eff(node, v)
		if node.kind == "none" then return "" end
		if node.per < 1 and not UNITS[node.kind] then return string.format("+%d%%", math.floor(v * 100 + 0.5)) end
		return (node.kind == "merge" and "x" or "+") .. v .. (UNITS[node.kind] or "")
	end
	local function hex(c) return string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255) end
	local function pathName(id)
		for gi, g in order do if g == Config.TREE_BY_ID[id].color then return "Arcanum " .. (ARCANA[gi] or ARCANA[1])[1] .. "  ·  " .. (ARCANA[gi] or ARCANA[1])[2] end end
		return ""
	end
	local function showPopup(id)
		if not snap or not id then pop.Visible = false return end
		local node, st = Config.TREE_BY_ID[id], stateOf(id)
		local lvl = snap.tree[id] or 0
		if st == "locked" then
			pPath.Text, pTitle.Text = pathName(id), "A Sealed Card"
			pDesc.Text = "Its light is still in your future.\nKindle a neighbour to reach it."
			pNext.Text, pCost.Text, pStatus.Text = "", "", "Out of reach"
		elseif st == "start" then
			pPath.Text, pTitle.Text = "", "The Heart of the Wheel"
			pDesc.Text = "Every path begins here."
			pNext.Text, pCost.Text, pStatus.Text = "", "", ""
		else
			pPath.Text, pTitle.Text = pathName(id), node.name
			pDesc.Text = (node.desc:gsub("([%+%-]?%d+%%?)", '<font color="' .. hex(CREAM) .. '"><b>%1</b></font>'))
			if st == "maxed" then
				pNext.Text, pCost.Text, pStatus.Text = string.format("Rank %d / %d", lvl, node.max), "", "Burning bright"
			else
				local cost = Config.skillCost(node, lvl)
				pNext.Text = lvl > 0 and string.format("Rank %d / %d  ·  next %s", lvl, node.max, eff(node, node.per * (lvl + 1))) or string.format("Rank 0 / %d", node.max)
				pCost.Text = string.format('%d <font size="16">skill point%s</font>', cost, cost == 1 and "" or "s")
				pStatus.Text = snap.sp >= cost and (UIS.TouchEnabled and not UIS.MouseEnabled and "Tap again to kindle" or "Click to kindle") or "Not enough light"
			end
		end
		pStatus.TextColor3 = pStatus.Text:find("kindle") and CREAM or DIM
		-- beside the node, on the side away from the hub, kept on the stage
		local p = P[id]
		local right = p.X >= 0
		local x = 0.5 + p.X * AR + (right and 0.045 or -0.045 - PW)
		x = math.clamp(x, 0.02, 0.98 - PW)
		local y = math.clamp(0.5 + p.Y - PH / 2, 0.03, 0.97 - PH)
		pop.Position = UDim2.fromScale(x, y)
		if not pop.Visible then
			pop.Visible = true
			popScale.Scale = 0.92
			tw(popScale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	for id, d in N do
		d.btn.MouseEnter:Connect(function() hovered = id; showPopup(id) end)
		d.btn.MouseLeave:Connect(function() if hovered == id then hovered = nil; pop.Visible = selected ~= nil; if selected then showPopup(selected) end end end)
		d.btn.Activated:Connect(function()
			if not snap then return end
			local st = stateOf(id)
			local cost = (st == "available" or st == "owned") and Config.skillCost(d.node, snap.tree[id] or 0)
			if cost and snap.sp >= cost and (hovered == id or selected == id) then env.buy(id) end
			selected = id
			showPopup(id)
		end)
	end
	treeGui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			task.defer(function() if not hovered then selected = nil; pop.Visible = false end end)
		end
	end)

	-- 10) state to looks
	local function setEdgeLit(e, lit, instant)
		e.litT = lit and 1 or 0
		if instant or reduced() then e.litP = e.litT end
		e.dirty = true
	end
	local function paintEdge(e)
		local total = #e.segs
		for _, s in e.segs do
			local shown = s.t <= e.prog + 0.0001
			local lit = e.litT > 0 and s.t <= e.litP
			local f = s.f
			if f.Visible ~= shown then f.Visible = shown end
			if not shown then continue end
			if s.dot then
				f.BackgroundColor3, f.BackgroundTransparency = lit and CREAM or DIM, lit and 0 or 0.4
			elseif lit then
				f.BackgroundColor3, f.BackgroundTransparency = e.kind == "hair" and LIGHT or CREAM:Lerp(LIGHT, 0.35), 0
				local st = f:FindFirstChildOfClass("UIStroke")
				if st then st.Enabled = true end
			else
				f.BackgroundColor3 = e.avail and LIGHT or (e.kind == "hair" and DIM or GOLD)
				f.BackgroundTransparency = e.avail and 0.1 or (e.kind == "hair" and 0.6 or 0.5)
				local st = f:FindFirstChildOfClass("UIStroke")
				if st then st.Enabled = false end
			end
		end
	end
	local function applyNode(d, st, lvl, s, instant)
		local node = d.node
		local owned = st == "owned" or st == "maxed"
		local big = owned and HO or d.h
		d.big, d.st = big, st
		if instant then d.cont.Size = sq(big) else tw(d.cont, 0.45, { Size = sq(big) }, Enum.EasingStyle.Back) end
		d.outer.Visible = st == "maxed"
		d.oStroke.Transparency = owned and 0.45 or 1
		d.moon.BackgroundTransparency = owned and 0 or 1
		d.rank.Text = (lvl > 0 and st ~= "start") and (lvl .. "/" .. node.max) or ""
		d.rank.Visible = d.rank.Text ~= ""
		d.stroke.Thickness = 2
		if st == "locked" then -- clearly there, clearly dark: a dim gold ring on ink
			d.stroke.Color, d.stroke.Transparency = Color3.fromRGB(150, 124, 80), 0.1
			d.iStroke.Color, d.iStroke.Transparency = DIM, 0.6
			d.ring.BackgroundColor3, d.ring.BackgroundTransparency = INK, 0.05
			d.glyph.ImageColor3, d.glyph.ImageTransparency = Color3.fromRGB(150, 124, 80), 0.2
			d.halo.ImageTransparency = 1
		elseif st == "available" then -- ready to take: bright gold ring that pulses
			d.stroke.Color, d.stroke.Transparency, d.stroke.Thickness = LIGHT, 0, 3
			d.iStroke.Color, d.iStroke.Transparency = GOLD, 0.3
			d.ring.BackgroundColor3, d.ring.BackgroundTransparency = INK, 0
			d.glyph.ImageColor3, d.glyph.ImageTransparency = LIGHT, 0
		elseif st == "start" then
			d.stroke.Color, d.stroke.Transparency, d.stroke.Thickness = LIGHT, 0, 2.5
			d.ring.BackgroundColor3, d.ring.BackgroundTransparency = INK, 0
			d.glyph.ImageColor3, d.glyph.ImageTransparency = CREAM, 0
			d.halo.ImageTransparency = 0.5
		else -- owned: filled gold, dark engraving, a halo
			d.stroke.Color, d.stroke.Transparency, d.stroke.Thickness = CREAM, 0, 2.5
			d.iStroke.Color, d.iStroke.Transparency = INK, 0.4
			d.ring.BackgroundColor3, d.ring.BackgroundTransparency = st == "maxed" and CREAM or LIGHT, 0
			d.glyph.ImageColor3, d.glyph.ImageTransparency = INK, 0
			d.halo.ImageTransparency = st == "maxed" and 0.4 or 0.55
		end
	end
	local function burstAt(id)
		local d = N[id]
		local ringF = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), ZIndex = 21 }, d.cont)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, ringF)
		local rs = new("UIStroke", { Color = CREAM, Thickness = 2.5 }, ringF)
		tw(ringF, 0.8, { Size = UDim2.fromScale(3.4, 3.4) }, Enum.EasingStyle.Quart)
		tw(rs, 0.8, { Transparency = 1 })
		task.delay(0.85, function() ringF:Destroy() end)
		for k = 1, 8 do
			local a = k / 8 * math.pi * 2
			local sp = new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow, ImageColor3 = CREAM, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.35, 0.35), ZIndex = 21 }, d.cont)
			tw(sp, 0.7, { Position = UDim2.fromScale(0.5 + math.cos(a) * 1.5, 0.5 + math.sin(a) * 1.5) }, Enum.EasingStyle.Quart)
			task.delay(0.72, function() sp:Destroy() end)
		end
		d.ring.BackgroundColor3 = Color3.new(1, 1, 1)
		tw(d.ring, 0.7, { BackgroundColor3 = LIGHT })
	end

	local first = true
	function M.sync(s)
		snap = s
		local nbest = Config.nextBestSkill and Config.nextBestSkill(s.tree, s.sp)
		local spent = false
		for id, d in N do
			local st = stateOf(id)
			local lvl = s.tree[id] or 0
			if id ~= "Start" and lvl > 0 then spent = true end
			local was = lastLvl[id]
			state[id] = st
			applyNode(d, st, lvl, s, first or was == nil or reduced())
			d.nextR.Visible = id == nbest
			if was and lvl > was then
				burstAt(id)
				local e = edgeOf[id]
				if e then -- the line draws from the stem outward
					e.prog = 1
					e.litP, e.litT = 0, 1
					e.dirty = true
				end
				for _, ed in edges do
					if ed.kind == "hair" and (ed.a == id or ed.b == id) and (s.tree[ed.a] or 0) > 0 and (s.tree[ed.b] or 0) > 0 then ed.litP, ed.litT, ed.dirty = 0, 1, true end
				end
			end
			lastLvl[id] = lvl
		end
		for _, e in edges do
			if e.kind == "main" then
				local lit = (s.tree[e.b] or 0) > 0
				local av = not lit and (state[e.b] == "available")
				if e.avail ~= av then e.avail, e.dirty = av, true end
				if lit and e.litT == 0 then setEdgeLit(e, true, first) elseif not lit and e.litT ~= 0 then setEdgeLit(e, false, true) end
			else
				local lit = (s.tree[e.a] or 0) > 0 and (s.tree[e.b] or 0) > 0
				if e.group then
					lit = false
					for _, nn in Config.TREE do if nn.color == e.group and (s.tree[nn.id] or 0) > 0 then lit = true end end
				end
				if lit and e.litT == 0 then setEdgeLit(e, true, first) elseif not lit and e.litT ~= 0 then setEdgeLit(e, false, true) end
			end
		end
		spText.Text = tostring(s.sp)
		respec:SetAttribute("off", not spent)
		respec.TextTransparency, rStroke.Transparency = spent and 0 or 0.5, spent and 0 or 0.5
		hintIcon.Visible = nbest ~= nil
		hint.Text = nbest and ("Next: " .. Config.TREE_BY_ID[nbest].name) or ""
		first = false
		if hovered or selected then showPopup(hovered or selected) end
	end

	-- 11) the opening: iris rings run out from the hub; edges and cards appear as the ring passes them
	local conn, openAt = nil, 0
	local function depthOf(v) return v.Magnitude end
	local function open()
		openAt = os.clock()
		pop.Visible = false
		local quick = reduced()
		for _, e in edges do
			e.hold = quick and 0 or (depthOf(P[e.a]) * 1.9 + (e.kind == "hair" and 0.35 or 0.1))
			e.prog, e.progT = quick and 1 or 0, 1
			if e.kind == "main" then e.litP = (e.litT > 0 and quick) and 1 or 0 end
			e.dirty = true
		end
		for _, d in N do
			local delay = quick and 0 or depthOf(P[d.id]) * 1.9
			local want = d.big or d.h
			d.cont.Size = quick and sq(want) or sq(0.001)
			if not quick then task.delay(delay, function() tw(d.cont, 0.5, { Size = sq(want) }, Enum.EasingStyle.Back) end) end
		end
		for gi, h in headings do
			h.f.BackgroundTransparency = 1
			task.delay(quick and 0 or 0.9 + gi * 0.08, function() tw(h.f, 0.5, { BackgroundTransparency = 0.2 }) end)
		end
		if not quick then
			for k = 1, 3 do
				local r = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = sq(0.02), ZIndex = 40 }, S)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, r)
				local rs = new("UIStroke", { Color = k == 1 and CREAM or LIGHT, Thickness = 3 - k * 0.6, Transparency = 0.1 }, r)
				task.delay((k - 1) * 0.16, function()
					tw(r, 1.1, { Size = sq(1.5 + k * 0.1) }, Enum.EasingStyle.Quart)
					tw(rs, 1.1, { Transparency = 1 })
					task.delay(1.15, function() r:Destroy() end)
				end)
			end
			S.Position = UDim2.fromScale(0.5, 0.515)
			tw(S, 0.9, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Quart)
		end
		hubG.ImageTransparency = 0.1
		tw(hubG, 1.2, { ImageTransparency = 0.45 })
	end

	-- 12) the never-still loop (only while the screen is open)
	local runners = {}
	for _, e in edges do
		if e.kind == "main" then
			local r = new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow, ImageColor3 = CREAM, ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = sq(0.03), ZIndex = 16 }, S)
			table.insert(runners, { f = r, e = e, ph = rng:NextNumber() })
		end
	end
	local last = os.clock()
	local function step()
		local now = os.clock()
		local dt = math.min(now - last, 0.1)
		last = now
		local still = reduced()
		for _, e in edges do
			local moved = false
			if e.prog < e.progT and now - openAt >= e.hold then e.prog = math.min(e.progT, e.prog + dt / 0.55); moved = true end
			if e.litP < e.litT and (e.prog >= 1 or e.prog > e.litP) then e.litP = math.min(1, e.litP + dt / 0.7); moved = true end
			if moved or e.dirty then e.dirty = false; paintEdge(e) end
		end
		if still then return end
		zodiac.Rotation = (now * 3) % 360
		zodiac2.Rotation = -(now * 5) % 360
		hubG.Size = sq(0.42 + math.sin(now * 1.3) * 0.02)
		for _, p in dust do
			p.y -= p.v * dt
			if p.y < -0.02 then p.y, p.x = 1.02, math.random() end
			p.f.Position = UDim2.fromScale(p.x + math.sin(now * 0.5 + p.ph) * 0.012, p.y)
			p.f.BackgroundTransparency = 0.35 + 0.4 * math.abs(math.sin(now * 0.8 + p.ph))
		end
		for _, st in stars do st.f.ImageTransparency = 1 - math.max(0, math.sin(now * st.sp + st.ph)) * 0.55 end
		for _, d in N do
			if d.moon.BackgroundTransparency < 1 then d.orbit.Rotation = (now * 40 + d.ph * 50) % 360 end
			if d.nextR.Visible then
				local k = 0.5 + 0.5 * math.sin(now * 3)
				d.nextR.Size = UDim2.fromScale(1.3 + k * 0.18, 1.3 + k * 0.18)
				d.nStroke.Transparency = 0.15 + k * 0.5
			end
			if d.st == "available" then local k = 0.5 + 0.5 * math.sin(now * 2.4 + d.ph); d.halo.ImageTransparency = 0.5 + 0.35 * (1 - k); d.stroke.Transparency = 0.25 * (1 - k) end
			if d.halo.ImageTransparency < 0.95 and d.id ~= "Start" then d.halo.Size = UDim2.fromScale(2.4 + math.sin(now * 2 + d.ph) * 0.12, 2.4 + math.sin(now * 2 + d.ph) * 0.12) end
		end
		for _, r in runners do
			local e = r.e
			if e.litT > 0 and e.litP >= 1 and e.prog >= 1 then
				local u = ((now / 3.2) + r.ph) % 1
				local fi = u * e.n
				local i = math.clamp(math.floor(fi), 0, e.n - 1)
				local p = e.pts[i]:Lerp(e.pts[i + 1], fi - i)
				r.f.Position, r.f.ImageTransparency = at(p), 0.35 + 0.5 * math.abs(u - 0.5) * 2
			else
				r.f.ImageTransparency = 1
			end
		end
	end
	local function onVisible()
		if conn then conn:Disconnect(); conn = nil end
		if treeGui.Visible then
			last = os.clock()
			open()
			conn = RunService.RenderStepped:Connect(step)
		end
	end
	treeGui:GetPropertyChangedSignal("Visible"):Connect(onVisible)
	if treeGui.Visible then onVisible() end
	task.delay(2, function() -- the Familiars button shares this screen: gold ink to match
		pcall(function()
			for _, b in treeGui.Parent:GetChildren() do
				if b:IsA("TextButton") and b.Text == "FAMILIARS" then
					for _, c in b:GetChildren() do if c:IsA("UIStroke") or c:IsA("UIGradient") then c:Destroy() end end
					b.BackgroundColor3, b.BackgroundTransparency, b.TextColor3 = INK, 0, LIGHT
					new("UIStroke", { Color = GOLD, Thickness = 1.5 }, b)
				end
			end
		end)
	end)
	M.instances = #S:GetDescendants()
	return M
end
