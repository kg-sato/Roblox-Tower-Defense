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

local INK, INK2 = Color3.fromRGB(12, 11, 10), Color3.fromRGB(26, 23, 20)
local GOLD, LIGHT, CREAM = Color3.fromRGB(184, 151, 90), Color3.fromRGB(217, 184, 120), Color3.fromRGB(239, 230, 207)
local DIM, FAINT = Color3.fromRGB(104, 88, 58), Color3.fromRGB(70, 60, 42)
local ICONS = {
	Armor = "rbxassetid://97798687917539",
	Charge = "rbxassetid://87255306276247",
	Charm = "rbxassetid://134496285484911",
	Claws = "rbxassetid://84134147080434",
	Clock = "rbxassetid://122010917635946",
	Discount = "rbxassetid://140718888692850",
	Double = "rbxassetid://128913448533576",
	Eye = "rbxassetid://70430773900363",
	Finder = "rbxassetid://110699275206672",
	Guard = "rbxassetid://93209073046299",
	Haste = "rbxassetid://78219893781799",
	Heavy = "rbxassetid://72808767830160",
	Learner = "rbxassetid://126515305812185",
	Magnet = "rbxassetid://105874413704464",
	Mega = "rbxassetid://127797835791972",
	Merger = "rbxassetid://77400237971107",
	Pity = "rbxassetid://104471144542537",
	Refund = "rbxassetid://114771222853824",
	Start = "rbxassetid://128237310134386",
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
	-- an opaque gold-ink backdrop: hides the grove's night sky, beams and blobs (the game world) while the tree is open
	new("Frame", { Name = "Backdrop", BackgroundColor3 = Color3.fromRGB(14, 12, 10), BackgroundTransparency = 0, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 13 }, root)
	local S = new("Frame", { Name = "Stage", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), ZIndex = 14 }, root)
	new("UIAspectRatioConstraint", { AspectRatio = 16 / 9, AspectType = Enum.AspectType.FitWithinMaxSize }, S)

	local BS = new("Frame", { Name = "BackStage", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), ZIndex = 13 }, root)
	new("UIAspectRatioConstraint", { AspectRatio = 16 / 9, AspectType = Enum.AspectType.FitWithinMaxSize }, BS)
	new("ImageLabel", { Name = "WarmGlow", BackgroundTransparency = 1, Image = A.glow, ImageColor3 = Color3.fromRGB(70, 52, 26), ImageTransparency = 0.35, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.6 * AR, 1.6), ZIndex = 13 }, BS)
	for k = 0, 47 do -- faint engraved rays from the hub
		local a = k / 48 * math.pi * 2
		new("Frame", { BackgroundColor3 = GOLD, BackgroundTransparency = k % 4 == 0 and 0.88 or 0.94, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + math.cos(a) * 0.475 * AR, 0.5 + math.sin(a) * 0.475), Size = UDim2.fromScale(0.95 * AR, k % 4 == 0 and 0.0016 or 0.0009), Rotation = math.deg(a), ZIndex = 13 }, BS)
	end
	new("ImageLabel", { Name = "TreeSepia", BackgroundTransparency = 1, Image = A.tree, ImageColor3 = Color3.fromRGB(176, 134, 64), ImageTransparency = 0.62, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = sq(0.9), ZIndex = 13 }, BS)
	do
		local function edge(pos, size, rot) new("UIGradient", { Rotation = rot, Transparency = NumberSequence.new(0.1, 1) }, new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Position = pos, Size = size, ZIndex = 13 }, root)) end
		edge(UDim2.fromScale(0, 0), UDim2.fromScale(0.14, 1), 0)
		edge(UDim2.fromScale(0.86, 0), UDim2.fromScale(0.14, 1), 180)
		edge(UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.14), 90)
		edge(UDim2.fromScale(0, 0.86), UDim2.fromScale(1, 0.14), 270)
	end

	-- 1) layout: hand-placed (height units from the hub). Clusters sit near their stems; nothing is on a ring.
	local rng = Random.new(11)
	local P, ringOf = {}, {}
	local POS = {
		Start = { 0, 0 }, Claws = { 0.21, 0.015 }, Magnet = { 0.14, -0.17 }, Armor = { -0.12, -0.19 }, Charge = { -0.22, 0.03 }, Charm = { -0.15, 0.17 }, Finder = { 0.10, 0.19 },
		Heavy = { 0.57, 0.02 }, Eye = { 0.40, -0.12 }, Haste = { 0.36, 0.14 }, Merger = { 0.31, -0.27 }, Learner = { 0.03, -0.31 }, Clock = { -0.28, -0.30 },
		Mega = { -0.50, -0.02 }, Refund = { -0.37, -0.15 }, Pity = { -0.39, 0.15 }, Discount = { -0.27, 0.29 }, Guard = { 0.30, 0.31 }, Double = { -0.02, 0.32 },
	}
	local MAJOR = { Claws = 1, Magnet = 1, Armor = 1, Charge = 1, Charm = 1, Finder = 1, Eye = 1, Double = 1, Haste = 1 }
	local PARENT = { Claws = "Start", Magnet = "Start", Armor = "Start", Charge = "Start", Charm = "Start", Finder = "Start", Heavy = "Claws", Eye = "Claws", Haste = "Claws",
		Merger = "Magnet", Learner = "Magnet", Clock = "Armor", Mega = "Charge", Refund = "Charge", Pity = "Charm", Discount = "Charm", Double = "Finder", Guard = "Finder" }
	local HAIR = { { "Eye", "Magnet" }, { "Haste", "Finder" }, { "Learner", "Armor" }, { "Refund", "Armor" }, { "Pity", "Charge" }, { "Double", "Charm" } }
	local CARDPOS = { Vector2.new(0.80, 0.075), Vector2.new(0.50, -0.365), Vector2.new(-0.50, -0.365), Vector2.new(-0.80, 0.075), Vector2.new(-0.50, 0.335), Vector2.new(0.50, 0.335) }
	local CARD_H = 0.135
	for _, n in Config.TREE do
		local v = POS[n.id]
		P[n.id], ringOf[n.id] = Vector2.new(v[1], v[2]), n.id == "Start" and 0 or 1
	end

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
	for _, n in Config.TREE do
		if n.id ~= "Start" then
			local parent = PARENT[n.id]
			local inner = parent == "Start"
			edgeOf[n.id] = makeEdge(parent, n.id, "main", (rng:NextInteger(0, 1) * 2 - 1) * rng:NextNumber(0.16, 0.26), inner and 12 or 11, inner and 0.0085 or 0.0062, inner and 0.0055 or 0.0042)
		end
	end
	for _, h in HAIR do makeEdge(h[1], h[2], "hair", (rng:NextInteger(0, 1) * 2 - 1) * 0.22, 8, 0.0022, 0.0022) end

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
		local p = CARDPOS[gi] or CARDPOS[1] -- an outer arc, clear of every lantern and the popup
		local ch = CARD_H -- a tarot card: double border, numeral, a sigil, the name
		local rd = new("Frame", { BackgroundColor3 = INK2, BackgroundTransparency = 0.05, AnchorPoint = Vector2.new(0.5, 0.5), Position = at(p), Size = UDim2.fromScale(ch * 0.64 * AR, ch), ZIndex = 16 }, S)
		new("UICorner", { CornerRadius = UDim.new(0.06, 0) }, rd)
		new("UIStroke", { Color = LIGHT, Thickness = 2.2 }, rd)
		local inner = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.9), ZIndex = 16 }, rd)
		new("UICorner", { CornerRadius = UDim.new(0.05, 0) }, inner)
		new("UIStroke", { Color = GOLD, Thickness = 1, Transparency = 0.5 }, inner)
		new("TextLabel", { BackgroundTransparency = 1, Text = ar[1], TextColor3 = CREAM, TextScaled = true, Size = UDim2.fromScale(0.7, 0.17), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.06), ZIndex = 17 }, rd)
		local sg = new("ImageLabel", { BackgroundTransparency = 1, Image = ICONS[far] or "", ImageColor3 = LIGHT, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.7, 0.4), ZIndex = 17 }, rd)
		new("UIAspectRatioConstraint", { AspectRatio = 1 }, sg)
		new("TextLabel", { BackgroundTransparency = 1, Text = string.upper(ar[2]), TextColor3 = LIGHT, TextScaled = true, Size = UDim2.fromScale(0.86, 0.11), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.95), ZIndex = 17 }, rd)
		P["H" .. gi] = p
		ringOf["H" .. gi] = 3
		local e = makeEdge(far, "H" .. gi, "hair", 0.12, 6, 0.0016, 0.0016)
		e.group = col
		table.insert(headings, { f = rd, col = col, name = ar[2], edge = e })
	end

	-- 6) nodes
	local N, state, lastLvl = {}, {}, {}
	local snap, hovered, selected
	local HMAJ, HMIN = 0.08, 0.056 -- node heights: about 86 and 60 px at 1080
	for _, n in Config.TREE do
		local id = n.id
		local isHub = id == "Start"
		local h = isHub and 0.125 or (MAJOR[id] and HMAJ or HMIN)
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
		local glyph = new("ImageLabel", { BackgroundTransparency = 1, Image = ICONS[id] or "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78), ZIndex = 20 }, cont)
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
	local PW, PH = 0.17, 0.245 -- of the stage width and height
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
	for f, m in { [pPath] = 19, [pTitle] = 32, [pDesc] = 25, [pNext] = 19, [pCost] = 28, [pStatus] = 20 } do new("UITextSizeConstraint", { MaxTextSize = m }, f) end
	local popScale = new("UIScale", { Scale = 1 }, pop) -- (the popup alone pops in with a spring; the layout itself is Scale-sized)

	-- a gold-framed tarot plate: ink face, bold gold border, inner hairline frame, four corner diamonds
	local function plate(b, z)
		b.BackgroundColor3, b.BackgroundTransparency = INK2, 0
		for _, c in b:GetChildren() do if c:IsA("UIStroke") or c:IsA("UIGradient") or c:IsA("UICorner") then c:Destroy() end end
		new("UICorner", { CornerRadius = UDim.new(0.1, 0) }, b)
		local st = new("UIStroke", { Color = LIGHT, Thickness = 2.5 }, b)
		local inn = new("Frame", { Name = "PlateInner", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -10, 1, -10), ZIndex = z }, b)
		new("UICorner", { CornerRadius = UDim.new(0.1, 0) }, inn)
		new("UIStroke", { Color = GOLD, Thickness = 1, Transparency = 0.35 }, inn)
		for _, c in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do
			new("Frame", { BackgroundColor3 = LIGHT, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(c[1], c[2]), Size = UDim2.fromOffset(9, 9), Rotation = 45, ZIndex = z + 1 }, b)
		end
		return st
	end

	-- 8) corner pieces: skill points, respec, next-best hint, close
	local bar = new("Frame", { Name = "Bar", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.985), Size = UDim2.fromScale(0.94, 0.07), ZIndex = 30 }, S)
	new("Frame", { BackgroundColor3 = LIGHT, BackgroundTransparency = 0.45, BorderSizePixel = 0, Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 0.02), ZIndex = 30 }, bar)
	local respec = new("TextButton", { AutoButtonColor = false, Text = "RESPEC", TextColor3 = LIGHT, TextScaled = true, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.005, 0.55), Size = UDim2.fromScale(0.15, 0.82), ZIndex = 31 }, bar)
	new("UITextSizeConstraint", { MaxTextSize = 22 }, respec)
	local rStroke = plate(respec, 31)
	local hintIcon = new("ImageLabel", { BackgroundTransparency = 1, Image = ICONS.Start, ImageColor3 = LIGHT, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.39, 0.55), Size = UDim2.fromScale(0.03, 0.62), ZIndex = 31 }, bar)
	local hint = new("TextLabel", { BackgroundTransparency = 1, Text = "", TextColor3 = LIGHT, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.4, 0.55), Size = UDim2.fromScale(0.28, 0.6), ZIndex = 31 }, bar)
	new("UITextSizeConstraint", { MaxTextSize = 27 }, hint)
	local spText = new("TextLabel", { BackgroundTransparency = 1, Text = "0", TextColor3 = CREAM, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.9, 0.55), Size = UDim2.fromScale(0.05, 0.8), ZIndex = 31 }, bar)
	new("UITextSizeConstraint", { MaxTextSize = 54 }, spText)
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
		close.AnchorPoint, close.Position, close.Size = Vector2.new(1, 0), UDim2.fromScale(0.975, 0.03), UDim2.fromScale(0.042, 0.075)
		close.ZIndex = 70
		plate(close, 70)
		local f = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62), ZIndex = 72 }, close)
		for _, r in { 45, -45 } do
			new("Frame", { BackgroundColor3 = CREAM, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.0, 0.13), Rotation = r, ZIndex = 72 }, f)
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
				pCost.Text = string.format("%d skill point%s", cost, cost == 1 and "" or "s")
				pStatus.Text = snap.sp >= cost and (UIS.TouchEnabled and not UIS.MouseEnabled and "Tap again to kindle" or "Click to kindle") or "Not enough light"
			end
		end
		pStatus.TextColor3 = pStatus.Text:find("kindle") and CREAM or DIM
		-- beside the node: try the sides, keep the one that covers the fewest neighbours, cards and the stage edge
		local p = P[id]
		local nh = (N[id].big or N[id].h) / 2 + 0.012
		local pw, ph = PW / AR, PH -- popup size in height units
		local best, bx, by = math.huge
		local cands = { { 0, -1 }, { 0, 1 } }
		for _, dx in { 1, -1 } do for _, off in { -1, -0.66, -0.33, 0, 0.33, 0.66, 1 } do table.insert(cands, { dx, off }) end end
		for _, c in cands do
			local cx = p.X + c[1] * (nh + pw / 2)
			local cy = c[1] == 0 and p.Y + c[2] * (nh + ph / 2) or p.Y + c[2] * ph * 0.5
			cx = math.clamp(cx, -0.89 + pw / 2 + 0.01, 0.89 - pw / 2 - 0.01)
			cy = math.clamp(cy, -0.5 + ph / 2 + 0.01, 0.5 - ph / 2 - 0.01)
			local function ov(x, y, w, h) -- overlap area of (x,y,w,h) centred rects with the popup
				local ox = math.max(0, (pw + w) / 2 - math.abs(cx - x))
				local oy = math.max(0, (ph + h) / 2 - math.abs(cy - y))
				return ox * oy
			end
			local score = 0
			for oid, od in N do
				if oid ~= id then score += ov(P[oid].X, P[oid].Y, od.h * 1.4, od.h * 1.4) * 150 end
			end
			score += ov(p.X, p.Y, nh * 2, nh * 2) * 60 -- never over the hovered node itself
			for _, cp in CARDPOS do score += ov(cp.X, cp.Y, CARD_H * 0.64 * 1.2, CARD_H * 1.1) * 300 end
			score += (math.abs(cx - p.X) + math.abs(cy - p.Y)) * 0.02
			if score < best then best, bx, by = score, cx, cy end
		end
		pop.Position = UDim2.fromScale(0.5 + (bx - pw / 2) * AR, 0.5 + by - ph / 2)
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
				f.BackgroundTransparency = e.avail and 0.05 or (e.kind == "hair" and 0.45 or 0.3)
				local st = f:FindFirstChildOfClass("UIStroke")
				if st then st.Enabled = false end
			end
		end
	end
	local function applyNode(d, st, lvl, s, instant)
		local node = d.node
		local owned = st == "owned" or st == "maxed"
		local big = owned and d.h * 1.1 or d.h
		d.big, d.st = big, st
		if instant then d.cont.Size = sq(big) else tw(d.cont, 0.45, { Size = sq(big) }, Enum.EasingStyle.Back) end
		d.outer.Visible = st == "maxed"
		d.oStroke.Transparency = owned and 0.45 or 1
		d.moon.BackgroundTransparency = owned and 0 or 1
		d.rank.Text = (lvl > 0 and st ~= "start") and (lvl .. "/" .. node.max) or ""
		d.rank.Visible = d.rank.Text ~= ""
		d.glyph.Size = UDim2.fromScale(0.78, 0.78)
		if st == "locked" then -- dark, desaturated, no glow
			d.stroke.Color, d.stroke.Transparency, d.stroke.Thickness = Color3.fromRGB(78, 68, 52), 0, 2
			d.iStroke.Transparency = 1
			d.ring.BackgroundColor3, d.ring.BackgroundTransparency = Color3.fromRGB(16, 15, 13), 0
			d.glyph.ImageColor3, d.glyph.ImageTransparency = Color3.fromRGB(86, 76, 60), 0.15
			d.halo.ImageTransparency = 1
		elseif st == "available" then -- ready to take: a gold ring that pulses
			d.stroke.Color, d.stroke.Transparency, d.stroke.Thickness = LIGHT, 0, 4
			d.iStroke.Color, d.iStroke.Transparency = GOLD, 0.4
			d.ring.BackgroundColor3, d.ring.BackgroundTransparency = INK2, 0
			d.glyph.ImageColor3, d.glyph.ImageTransparency = LIGHT, 0
		elseif st == "start" then
			d.stroke.Color, d.stroke.Transparency, d.stroke.Thickness = LIGHT, 0, 3
			d.ring.BackgroundColor3, d.ring.BackgroundTransparency = INK, 0
			d.glyph.ImageColor3, d.glyph.ImageTransparency = CREAM, 0
			d.halo.ImageTransparency = 0.5
		else -- owned: a solid cream disc with a dark icon
			d.stroke.Color, d.stroke.Transparency, d.stroke.Thickness = LIGHT, 0, 3
			d.iStroke.Color, d.iStroke.Transparency = INK, 0.5
			d.ring.BackgroundColor3, d.ring.BackgroundTransparency = CREAM, 0
			d.glyph.ImageColor3, d.glyph.ImageTransparency = INK, 0
			d.halo.ImageTransparency = st == "maxed" and 0.45 or 0.65
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
		tw(d.ring, 0.7, { BackgroundColor3 = CREAM })
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
		respec.TextTransparency, rStroke.Transparency = spent and 0 or 0.6, spent and 0 or 0.5
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
			if d.st == "available" then local k = 0.5 + 0.5 * math.sin(now * 2.4 + d.ph); d.halo.ImageTransparency = 0.7 + 0.25 * (1 - k); d.stroke.Transparency = 0.55 * (1 - k); d.stroke.Thickness = 3 + 2 * k end
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
					b.TextColor3 = LIGHT
					plate(b, b.ZIndex)
				end
			end
		end)
	end)
	M.showPopup, M.burst = showPopup, burstAt -- (also used by the capture harness)
	M.instances = #S:GetDescendants()
	return M
end
