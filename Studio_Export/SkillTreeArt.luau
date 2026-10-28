--!nocheck
-- SkillTreeArt v2 (StarterPlayerScripts, 2026-10-28). Layout and polish follow the user's grader (a radial tree on
-- patterned black, small icons, a moving border, a framed hover popup), but the parts are ours (the user: "make sure
-- it's original and matches our themes"): the tree is the player's future (Game Design Doc, loading story) and every
-- skill is a lantern you kindle, as in the Skill Grove. The border is a brass watch minute-track that ticks like a
-- second hand, with our brass gears in the corners; the popup is a brass clockwork frame with a pocket watch crest;
-- the counter is a gas flame with your skill points.
-- Notes: Roblox Dev/Research/UI/Skill Tree Grader.md. GameClient keeps the logic (states, the buy remote on the server);
-- this module replaces the look. v1 (fan tree on nebula clouds) is in git history.
--   * no question marks: locked skills next to an owned one show a dark silhouette of their icon; deeper ones show an
--     empty dark hex. Their popup says "Sealed" instead of "???".
--   * click (or tap twice on touch) a skill you can afford to unlock it; the popup says so
--   * opening plays a short reveal: the centre flares, the rays draw outward, the hexes appear ring by ring
--   * unlocking plays a burst on the node and lights its ray
-- Called once from GameClient after the nodes and links exist; GameClient calls .sync(snap) at the end of refreshTree.
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local BRANCH = { -- path names by colour key (Config colours), shown above the skill name in the popup
	{ Color3.fromRGB(255, 92, 92), "Path of Embers" }, { Color3.fromRGB(255, 200, 70), "Path of Brass" }, { Color3.fromRGB(90, 150, 255), "Path of the Ward" },
	{ Color3.fromRGB(170, 110, 255), "Path of Storms" }, { Color3.fromRGB(110, 220, 120), "Path of Fortune" }, { Color3.fromRGB(80, 220, 230), "Path of Starlight" },
}
local function branchName(c)
	local best, bd = "The Path", math.huge
	for _, b in BRANCH do
		local d = (b[1].R - c.R) ^ 2 + (b[1].G - c.G) ^ 2 + (b[1].B - c.B) ^ 2
		if d < bd then best, bd = b[2], d end
	end
	return best
end

return function(env)
	local treeGui, area, nodeUI, links, Config = env.treeGui, env.treeArea, env.nodeUI, env.treeLinks, env.Config
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
	local INK, SILVER, IVORY, MUTED = Color3.fromRGB(7, 7, 9), Color3.fromRGB(170, 166, 178), Color3.fromRGB(236, 228, 214), Color3.fromRGB(150, 144, 160)
	local R1, R2, R2B = 170, 340, 300 -- ring radii (outer ring: straight-out nodes at R2, between nodes at R2B)

	-- 0) GameClient's old pieces: the title, SP line and bottom detail card go; the close button is restyled below
	for _, o in { env.treeTitle, env.treeSp, env.detail } do if o then o.Visible = false end end
	for _, d in treeGui:GetChildren() do -- old divider image under the title, old stars
		if d:IsA("GuiObject") and d ~= area and d ~= env.treeClose and d ~= env.detail and d.ZIndex <= 14 and d.Name ~= "Tree" then d.Visible = false end
	end
	for _, d in area:GetChildren() do
		if d:IsA("Frame") and d.Size == UDim2.fromOffset(620, 520) then d.Visible = false end -- old violet disc
	end
	treeGui.BackgroundColor3, treeGui.BackgroundTransparency = INK, 0
	for _, g in treeGui:GetChildren() do if g:IsA("UIGradient") then g.Enabled = false end end

	-- 1) background: near-black with a faint handwritten wallpaper (the grader's patterned black) and a vignette
	local bg = new("Frame", { Name = "TreeBackdrop", BackgroundColor3 = INK, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 12, ClipsDescendants = true }, treeGui)
	local wall = new("ImageLabel", { BackgroundTransparency = 1, Image = A.script, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(512, 512), ImageColor3 = Color3.fromRGB(175, 165, 195), ImageTransparency = 0.72, Size = UDim2.new(1, 512, 1, 512), ZIndex = 12 }, bg)
	for _, rot in { 0, 90 } do -- two crossed gradients darken all four edges (a cheap vignette)
		local v = new("Frame", { Name = "Vignette", BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 12 }, bg)
		new("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.3, 0.85), NumberSequenceKeypoint.new(0.7, 0.85), NumberSequenceKeypoint.new(1, 0.1) }) }, v)
	end
	TweenService:Create(wall, TweenInfo.new(90, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Position = UDim2.fromOffset(-512, -512) }):Play() -- the script drifts very slowly

	-- 2) layout: radial. Each node's angle comes from its hex position; ring decides the radius
	local pos, ring = {}, {}
	for _, node in Config.TREE do
		local rg = math.max(math.abs(node.q), math.abs(node.r), math.abs(-node.q - node.r))
		local hx, hy = math.sqrt(3) * (node.q + node.r / 2), 1.5 * node.r
		local a = math.atan2(hy, hx)
		local straight = (node.q == 0 or node.r == 0 or node.q == -node.r)
		local r = rg == 0 and 0 or (rg == 1 and R1 or (straight and R2 or R2B))
		pos[node.id], ring[node.id] = Vector2.new(math.cos(a) * r, math.sin(a) * r), rg
	end
	local function seg(a, b, w, color, tr, z, parent)
		local d = b - a
		return new("Frame", { BackgroundColor3 = color, BackgroundTransparency = tr, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, (a.X + b.X) / 2, 0.5, (a.Y + b.Y) / 2), Size = UDim2.fromOffset(d.Magnitude, w), Rotation = math.deg(math.atan2(d.Y, d.X)), ZIndex = z }, parent or area)
	end

	-- centre burst: many faint rays fanning out in every path colour, and a white star
	local burst = new("Frame", { Name = "Burst", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0), ZIndex = 13 }, area)
	local rays = {}
	for k = 0, 35 do
		local a = k / 36 * math.pi * 2 + 0.05
		local c = BRANCH[(k % 6) + 1][1]:Lerp(Color3.new(1, 1, 1), 0.55)
		local len = 260 + (k * 37 % 5) * 70
		local r = seg(Vector2.zero, Vector2.new(math.cos(a), math.sin(a)) * len, 1, c, 0.86, 13, burst)
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, r)
		rays[k] = { f = r, len = len, a = a }
	end
	local core = new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(120, 120), ImageColor3 = Color3.fromRGB(255, 236, 200), ImageTransparency = 0.35, ZIndex = 19 }, area) -- dimmer and warmer: it out-shone the lanterns
	TweenService:Create(core, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromOffset(140, 140), ImageTransparency = 0.5 }):Play()

	-- 3) per node: hex, glyph, glow; GameClient's hex layers, plate, badge and "?" stay hidden
	local N = {}
	for id, ui in nodeUI do
		local node = Config.TREE_BY_ID[id]
		local p = pos[id]
		ui.x, ui.y = p.X, p.Y
		ui.cont.Position = UDim2.new(0.5, p.X, 0.5, p.Y)
		local btn = ui.cont:FindFirstChildOfClass("TextButton")
		if btn then btn.Size = UDim2.fromOffset(50, 50) end
		-- round 3 (review: "make the nodes lanterns"): each skill is a small gas lantern; hex = its metal frame,
		-- glass = its panes, lit in the path colour once kindled; the glyph hangs inside the glass
		local LW, LH = 56, 73
		local glow = new("ImageLabel", { Name = "V2glow", BackgroundTransparency = 1, Image = A.glow, ImageColor3 = node.color, ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(84, 84), ZIndex = 19 }, ui.cont)
		local glass = new("ImageLabel", { Name = "V2glass", BackgroundTransparency = 1, Image = A.lantern_glass, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -2), Size = UDim2.fromOffset(LW, LH), Visible = id ~= "Start", ZIndex = 20 }, ui.cont)
		local hex = new("ImageLabel", { Name = "V2hex", BackgroundTransparency = 1, Image = A.lantern_frame, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -2), Size = UDim2.fromOffset(LW, LH), Visible = id ~= "Start", ZIndex = 22 }, ui.cont)
		-- the glyph art has a margin: 44 px shows about 30 px of symbol
		local glyph = new("ImageLabel", { Name = "V2glyph", BackgroundTransparency = 1, Image = A.icons[id] or "", AnchorPoint = Vector2.new(0.5, 0.5), Position = id == "Start" and UDim2.fromScale(0.5, 0.5) or UDim2.new(0.5, 0, 0.5, 1), Size = UDim2.fromOffset(id == "Start" and 46 or 38, id == "Start" and 46 or 38), ImageColor3 = node.color, ZIndex = 21 }, ui.cont)
		N[id] = { ui = ui, btn = btn, glow = glow, hex = hex, glass = glass, glyph = glyph, node = node, lvl = nil }
	end
	-- branches: one line per link in the outer node's colour, with a wide faint ghost copy (glow by duplication)
	local B = {}
	for _, l in links do
		local a, b = pos[l.a], pos[l.b]
		local outer = ring[l.a] > ring[l.b] and l.a or l.b
		local inner = outer == l.a and l.b or l.a
		if ring[outer] ~= ring[inner] then -- spokes only; links along a ring would cross the rays
			local d = b - a
			l.line.Position = UDim2.new(0.5, (a.X + b.X) / 2, 0.5, (a.Y + b.Y) / 2)
			l.line.Size = UDim2.fromOffset(d.Magnitude, 3)
			l.line.Rotation = math.deg(math.atan2(d.Y, d.X))
			for _, c in l.line:GetChildren() do if c:IsA("UICorner") then c:Destroy() end end
			local ghost = seg(a, b, 9, Config.TREE_BY_ID[outer].color, 0.9, 13)
			table.insert(B, { l = l, ghost = ghost, outer = outer, inner = inner })
		else
			l.line:Destroy()
			l.dead = true
		end
	end
	for i = #links, 1, -1 do if links[i].dead then table.remove(links, i) end end
	-- each path runs on past its last skill and fades out: there is more beyond (mystery, like the grader's edges)
	local tails = {}
	for id, p in pos do
		if ring[id] == 2 and (Config.TREE_BY_ID[id].q == 0 or Config.TREE_BY_ID[id].r == 0 or Config.TREE_BY_ID[id].q == -Config.TREE_BY_ID[id].r) then
			local u = p.Unit
			local t = seg(p + u * 26, p + u * 380, 2, Config.TREE_BY_ID[id].color, 0.55, 13)
			new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, t)
			for k = 1, 0 do -- (review: the faded hexes past the edge read as accidental; the fading path alone says "more")
				local q = p + u * (70 + k * 62)
				local h = new("ImageLabel", { BackgroundTransparency = 1, Image = A.hex, ImageTransparency = 0.55 + k * 0.12, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, q.X, 0.5, q.Y), Size = UDim2.fromOffset(34 - k * 3, 34 - k * 3), ZIndex = 14 }, area)
				table.insert(tails, h)
			end
			table.insert(tails, t)
		end
	end

	-- 4) the animated border: a brass watch minute-track runs round all four edges and ticks forward once a second,
	-- like a second hand; brass gears in the corners turn one notch with each tick
	local border = new("Frame", { Name = "ClockBorder", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40 }, treeGui)
	local CH = 22 -- track thickness in px (tile 60 x 30 drawn at 44 x 22)
	local strips = {}
	for _, s in { { "h", UDim2.new(0, 0, 0, 6), UDim2.new(1, 72, 0, CH), 1 }, { "h", UDim2.new(0, -72, 1, -6 - CH), UDim2.new(1, 72, 0, CH), -1 },
		{ "v", UDim2.new(0, 6, 0, -72), UDim2.new(0, CH, 1, 72), -1 }, { "v", UDim2.new(1, -6 - CH, 0, 0), UDim2.new(0, CH, 1, 72), 1 } } do
		local holder = new("Frame", { BackgroundTransparency = 1, ClipsDescendants = true, Position = s[1] == "h" and UDim2.new(0, 0, s[2].Y.Scale, s[2].Y.Offset) or UDim2.new(s[2].X.Scale, s[2].X.Offset, 0, 0), Size = s[1] == "h" and UDim2.new(1, 0, 0, CH) or UDim2.new(0, CH, 1, 0), ZIndex = 40 }, border)
		local img = new("ImageLabel", { BackgroundTransparency = 1, Image = s[1] == "h" and A.track_h or A.track_v, ScaleType = Enum.ScaleType.Tile, TileSize = s[1] == "h" and UDim2.fromOffset(44, CH) or UDim2.fromOffset(CH, 44), Size = s[1] == "h" and UDim2.new(1, 144, 1, 0) or UDim2.new(1, 0, 1, 144), Position = s[1] == "h" and UDim2.fromOffset(-72, 0) or UDim2.fromOffset(0, -72), ZIndex = 40 }, holder)
		table.insert(strips, { img = img, h = s[1] == "h", dir = s[4] })
	end
	local inner = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(CH + 14, CH + 14), Size = UDim2.new(1, -2 * (CH + 14), 1, -2 * (CH + 14)), ZIndex = 39 }, border)
	new("UIStroke", { Color = Color3.fromRGB(196, 150, 78), Thickness = 1, Transparency = 0.65 }, inner)
	local gears = {}
	for i, c in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		local g = new("ImageLabel", { BackgroundTransparency = 1, Image = A.gear, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(c.X, c.X == 0 and 22 or -22, c.Y, c.Y == 0 and 22 or -22), Size = UDim2.fromOffset(92, 92), ImageColor3 = Color3.fromRGB(190, 170, 140), ZIndex = 41 }, border)
		gears[i] = g
	end
	RunService.RenderStepped:Connect(function()
		if not treeGui.Visible then return end
		local t = os.clock()
		local sec, f = math.floor(t), t % 1
		local k = sec + 1 - (1 - math.min(1, f / 0.12)) ^ 3 -- the tick: a quick snap at the start of each second
		local off = (k * 8.8) % 44 -- one minute mark (44 px / 5) per tick
		for _, s in strips do
			local o = -44 + off * s.dir + (s.dir < 0 and 44 or 0)
			s.img.Position = s.h and UDim2.fromOffset(o, 0) or UDim2.fromOffset(0, o)
		end
		for i, g in gears do g.Rotation = (k * 6 + t * 10) * (i % 2 == 0 and -1 or 1) end -- a steady turn plus the tick (review: the tick alone read as still)
	end)
	-- the top-left 560 px belong to Roblox's buttons: no gear there
	gears[1].Visible = false

	-- 5) close (a small square with a cross, top right) and the SP count (bottom right)
	local close = env.treeClose
	if close then task.delay(1.5, function() -- after AbstractScreens has given it its line cross (hidden here)
		for _, d in close:GetDescendants() do if d:IsA("GuiObject") or d:IsA("UIStroke") or d:IsA("UIGradient") then pcall(function() d.Visible = false end) pcall(function() d.Enabled = false end) end end
		close.Text, close.TextTransparency = "", 1
		close.AnchorPoint, close.Position, close.Size = Vector2.new(1, 0), UDim2.new(1, -(CH + 28), 0, CH + 28), UDim2.fromOffset(46, 46)
		close.BackgroundColor3, close.BackgroundTransparency, close.ZIndex = INK, 0.1, 45
		local f = new("Frame", { Name = "V2close", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 45 }, close)
		new("UIStroke", { Color = SILVER, Thickness = 1.5, Transparency = 0.2 }, f)
		local inset = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), ZIndex = 45 }, f)
		new("UIStroke", { Color = SILVER, Thickness = 1, Transparency = 0.6 }, inset)
		for _, r in { 45, -45 } do
			new("Frame", { BackgroundColor3 = IVORY, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 2), Rotation = r, ZIndex = 46 }, f)
		end
		close.MouseEnter:Connect(function() tw(f, 0.15, { Rotation = 90 }) end)
		close.MouseLeave:Connect(function() tw(f, 0.15, { Rotation = 0 }) end)
	end) end
	-- the counter: a gas flame and the points you can spend (a lantern's worth of light per point)
	local counter = new("Frame", { Name = "V2points", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -(CH + 30), 1, -(CH + 22)), Size = UDim2.fromOffset(200, 56), ZIndex = 45 }, treeGui)
	local flame = new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://108574647086501", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, -2), Size = UDim2.fromOffset(30, 40), ZIndex = 46 }, counter)
	TweenService:Create(flame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 4, Size = UDim2.fromOffset(32, 43) }):Play()
	local spText = new("TextLabel", { Name = "Count", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -38, 0, 0), Size = UDim2.fromOffset(150, 34), Text = "", TextColor3 = IVORY, TextSize = 32, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 46 }, counter)
	new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -38, 0, 34), Size = UDim2.fromOffset(160, 18), Text = "skill points to kindle", TextColor3 = MUTED, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 46 }, counter)

	-- 6) the hover popup. Round 3 (review: the photoreal frame was heavy beside the flat tree and 60% border): a light
	-- card in the tree's own flat style: dark panel, a brass double rule, small diamonds at the corners, and a small
	-- pocket-watch crest on the top edge
	-- parented to the ScreenGui itself (no UIScale above it), so its offsets are screen pixels like AbsolutePosition
	local sgui = treeGui:FindFirstAncestorOfClass("ScreenGui")
	local PW, PH = 300, 320
	local BRASS = Color3.fromRGB(214, 170, 96)
	local pop = new("Frame", { Name = "TreePopup", BackgroundColor3 = Color3.fromRGB(14, 12, 12), BackgroundTransparency = 0.04, BorderSizePixel = 0, Size = UDim2.fromOffset(PW, PH), Visible = false, ZIndex = 50 }, sgui)
	local popScale = new("UIScale", { Scale = 1 }, pop)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(28, 22, 18), Color3.fromRGB(10, 9, 10)) }, pop)
	new("UIStroke", { Color = BRASS, Thickness = 1.5, Transparency = 0.1 }, pop)
	local rim = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), ZIndex = 50 }, pop)
	new("UIStroke", { Color = BRASS, Thickness = 1, Transparency = 0.6 }, rim)
	for _, c in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		new("Frame", { BackgroundColor3 = BRASS, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(c.X, c.Y), Size = UDim2.fromOffset(8, 8), Rotation = 45, ZIndex = 52 }, pop)
	end
	local crest = new("ImageLabel", { BackgroundTransparency = 1, Image = A.clock, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(44, 44), ZIndex = 53 }, pop)
	TweenService:Create(crest, TweenInfo.new(60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 }):Play()
	local function txt(name, y, h, size, color, rich)
		return new("TextLabel", { Name = name, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, y), Size = UDim2.fromScale(0.86, h), Text = "", TextSize = size, TextWrapped = true, RichText = rich or false, TextColor3 = color, ZIndex = 52 }, pop)
	end
	local pPath = txt("Path", 0.1, 0.06, 16, MUTED)
	local pTitle = txt("Title", 0.16, 0.1, 25, IVORY)
	pTitle:SetAttribute("KeepFont", true)
	pTitle.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json") -- headings in the calligraphic face
	new("Frame", { BackgroundColor3 = SILVER, BackgroundTransparency = 0.6, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.28), Size = UDim2.new(0.5, 0, 0, 1), ZIndex = 52 }, pop)
	local pDesc = txt("Desc", 0.31, 0.24, 19, IVORY, true)
	local pNext = txt("Next", 0.57, 0.07, 17, Color3.fromRGB(196, 186, 172), true)
	local pCost = txt("Cost", 0.67, 0.09, 26, IVORY, true)
	local pStatus = txt("Status", 0.8, 0.09, 24, MUTED)

	local snap, hovered, selected = nil, nil, nil
	local UNITS = { crystal = " health", ultNeed = " kill", bossTime = "s", rollDiscount = " gem", streakGuard = " leak", ultRefund = " charge", pity = " rolls" }
	local function eff(node, v)
		if node.kind == "none" then return "" end
		if node.per < 1 and not UNITS[node.kind] then return string.format("+%d%%", math.floor(v * 100 + 0.5)) end
		return (node.kind == "merge" and "x" or "+") .. v .. (UNITS[node.kind] or "")
	end
	local function hex(c) return string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255) end
	local function stateOf(id)
		if id == "Start" then return "start" end
		local node = Config.TREE_BY_ID[id]
		local lvl = snap.tree[id] or 0
		if lvl >= node.max then return "maxed" end
		if lvl > 0 then return "owned" end
		for _, n in Config.TREE_NEIGHBORS[id] do
			if (snap.tree[n] or 0) > 0 or n == "Start" then return "available" end
		end
		return "locked"
	end
	local function near(id) -- locked but touching something you can reach: shows a silhouette
		for _, n in Config.TREE_NEIGHBORS[id] do
			local s = stateOf(n)
			if s ~= "locked" then return true end
		end
		return false
	end
	local function showPopup(id)
		if not snap or not id then pop.Visible = false return end
		local d = N[id]
		local node, st = d.node, stateOf(id)
		local lvl = snap.tree[id] or 0
		local col = hex(node.color)
		if st == "locked" then
			pPath.Text, pTitle.Text = branchName(node.color), "An Unlit Lantern"
			pDesc.Text = "Its light is still in your future.\nKindle a lantern beside it to reach it."
			pNext.Text, pCost.Text, pStatus.Text = "", "", "Out of reach"
		elseif st == "start" then
			pPath.Text, pTitle.Text = "", "The Heart of the Grove"
			pDesc.Text = "Every path begins here."
			pNext.Text, pCost.Text, pStatus.Text = "", "", ""
		else
			pPath.Text, pTitle.Text = branchName(node.color), node.name
			-- numbers in the description take the path's colour (the grader colours its keywords)
			pDesc.Text = (node.desc:gsub("([%+%-]?%d+%%?)", '<font color="' .. col .. '"><b>%1</b></font>'))
			if st == "maxed" then
				pNext.Text = string.format("Rank %d / %d", lvl, node.max)
				pCost.Text, pStatus.Text = "", "Burning bright"
			else
				local cost = Config.skillCost(node, lvl)
				pNext.Text = lvl > 0 and string.format("Rank %d / %d  ·  next %s", lvl, node.max, eff(node, node.per * (lvl + 1))) or string.format("Rank 0 / %d", node.max)
				pCost.Text = string.format('%d <font size="16">skill point%s</font>', cost, cost == 1 and "" or "s")
				pStatus.Text = snap.sp >= cost and (UIS.TouchEnabled and not UIS.MouseEnabled and "Tap again to kindle" or "Click to kindle") or "Not enough light"
			end
		end
		pStatus.TextColor3 = pStatus.Text:find("kindle") and node.color:Lerp(Color3.new(1, 1, 1), 0.4) or MUTED
		pPath.TextColor3 = node.color:Lerp(MUTED, 0.35)
		-- beside the node on its outer side (away from the tree's centre), kept fully on screen
		local abs = d.ui.cont.AbsolutePosition + d.ui.cont.AbsoluteSize / 2 - sgui.AbsolutePosition
		local vs = sgui.AbsoluteSize
		local s = math.clamp(vs.Y / 900, 0.7, 1.1)
		popScale.Scale = s
		local w, h = PW * s, PH * s
		local cx = (core.AbsolutePosition + core.AbsoluteSize / 2 - sgui.AbsolutePosition).X
		-- round 3: in the empty band beside the tree (outside its outer ring), so it never covers other lanterns
		local ring2 = (R2 + 40) * d.ui.cont.AbsoluteSize.X / 96 -- node boxes are 96 units wide: their on-screen width gives the zoom
		local x = abs.X >= cx and math.max(abs.X + 50, cx + ring2) or math.min(abs.X - 50 - w, cx - ring2 - w)
		x = math.clamp(x, CH + 20, vs.X - w - CH - 20)
		local y = math.clamp(abs.Y - h / 2, CH + 20, vs.Y - h - CH - 20)
		pop.Position = UDim2.fromOffset(x, y)
		if not pop.Visible then
			pop.Visible = true
			popScale.Scale = s * 0.94
			tw(popScale, 0.16, { Scale = s }, Enum.EasingStyle.Back)
		end
	end
	local function burstAt(id)
		local d = N[id]
		local ringF = new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow, ImageColor3 = d.node.color, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40), ZIndex = 22 }, d.ui.cont)
		tw(ringF, 0.7, { Size = UDim2.fromOffset(240, 240), ImageTransparency = 1 })
		task.delay(0.75, function() ringF:Destroy() end)
		d.glyph.ImageColor3 = Color3.new(1, 1, 1)
		tw(d.glyph, 0.6, { ImageColor3 = d.node.color })
		d.ui.scale.Scale = 1.5
		tw(d.ui.scale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
		for k = 1, 10 do
			local a = k / 10 * math.pi * 2
			local sp = new("Frame", { BackgroundColor3 = d.node.color:Lerp(Color3.new(1, 1, 1), 0.5), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 2), Rotation = math.deg(a), ZIndex = 22 }, d.ui.cont)
			tw(sp, 0.5, { Position = UDim2.new(0.5, math.cos(a) * 60, 0.5, math.sin(a) * 60), Size = UDim2.fromOffset(4, 1), BackgroundTransparency = 1 }, Enum.EasingStyle.Quart)
			task.delay(0.55, function() sp:Destroy() end)
		end
		for _, b in B do -- the ray into this skill floods with light from the inside out
			if b.outer == id then
				b.ghost.BackgroundTransparency = 0.4
				tw(b.ghost, 0.9, { BackgroundTransparency = 0.82 })
			end
		end
	end
	for id, d in N do
		if d.btn then
			d.btn.MouseEnter:Connect(function() hovered = id; showPopup(id) end)
			d.btn.MouseLeave:Connect(function() if hovered == id then hovered = nil; pop.Visible = selected ~= nil; if selected then showPopup(selected) end end end)
			d.btn.Activated:Connect(function()
				if not snap then return end
				local st = stateOf(id)
				local cost = (st == "available" or st == "owned") and Config.skillCost(d.node, snap.tree[id] or 0)
				if cost and snap.sp >= cost and (hovered == id or selected == id) then
					env.buy(id) -- the server checks cost and neighbours; the burst plays when the new level arrives
				end
				selected = id
				showPopup(id)
			end)
		end
	end
	treeGui.InputBegan:Connect(function(input) -- a click on empty space clears the pinned popup
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			task.defer(function() if not hovered then selected = nil; pop.Visible = false end end)
		end
	end)

	function M.sync(s)
		snap = s
		for id, d in N do
			local ui, node = d.ui, d.node
			for _, o in { ui.sel, ui.rim, ui.body, ui.shine, ui.icon, ui.plate, ui.badge, ui.q } do if o then o.Visible = false end end
			local st = stateOf(id)
			local lvl = s.tree[id] or 0
			ui.cont.Visible = true
			if id == "Start" then
				d.glyph.ImageColor3, d.glyph.ImageTransparency = Color3.new(1, 1, 1), 0
			elseif st == "locked" then -- an unlit lantern: dark iron and dark glass; its sign shows only beside a lit one
				local seen = near(id)
				d.hex.ImageColor3, d.hex.ImageTransparency = seen and Color3.fromRGB(104, 98, 110) or Color3.fromRGB(70, 66, 78), seen and 0 or 0.3
				d.glass.ImageColor3, d.glass.ImageTransparency = Color3.fromRGB(26, 24, 32), seen and 0 or 0.3
				d.glyph.ImageColor3 = seen and node.color:Lerp(Color3.fromRGB(80, 76, 90), 0.55) or Color3.fromRGB(80, 76, 90)
				d.glyph.ImageTransparency = seen and 0.05 or 0.6
				d.glow.ImageTransparency = 1
			elseif st == "available" then -- ready to kindle: brass frame, a faint glow behind the glass
				d.hex.ImageColor3, d.hex.ImageTransparency = Color3.fromRGB(176, 150, 112), 0
				d.glass.ImageColor3, d.glass.ImageTransparency = node.color:Lerp(Color3.fromRGB(30, 26, 30), 0.55), 0
				d.glyph.ImageColor3, d.glyph.ImageTransparency = node.color:Lerp(Color3.new(1, 1, 1), 0.2), 0
				d.glow.ImageTransparency = s.sp >= Config.skillCost(node, lvl) and 0.8 or 1
			else -- kindled / mastered: polished brass, glass full of the path's light, a halo that flickers
				d.hex.ImageColor3, d.hex.ImageTransparency = st == "maxed" and Color3.fromRGB(246, 208, 130) or Color3.fromRGB(220, 176, 100), 0
				d.glass.ImageColor3, d.glass.ImageTransparency = node.color, 0
				d.glyph.ImageColor3, d.glyph.ImageTransparency = Color3.fromRGB(255, 244, 232), 0
				d.glow.ImageTransparency = st == "maxed" and 0.45 or 0.6
			end
			if d.lvl and lvl > d.lvl then burstAt(id) end
			d.lvl = lvl
		end
		for _, b in B do
			local so = stateOf(b.outer)
			local lit = (so == "owned" or so == "maxed")
			local open = so == "available"
			local c = Config.TREE_BY_ID[b.outer].color
			b.l.line.Visible = true
			-- every path keeps its colour (the grader's rays are all coloured); brightness says how far you are along it
			b.l.line.BackgroundColor3 = lit and c or c:Lerp(Color3.fromRGB(40, 38, 48), open and 0.35 or 0.6)
			b.l.line.BackgroundTransparency = lit and 0 or (open and 0.1 or 0.3)
			b.ghost.BackgroundColor3 = c
			b.ghost.BackgroundTransparency = lit and 0.82 or 1
			b.ghost.Visible = true
		end
		spText.Text = tostring(s.sp)
		flame.ImageTransparency = s.sp > 0 and 0 or 0.6
		if hovered or selected then showPopup(hovered or selected) end
	end

	-- 6b) idle life (review: the screen froze after the intro): sparks of light run outward along every lit or
	-- open path, kindled lanterns flicker like gas flames, and a few motes drift up through the dark
	local runners = {}
	for _, b in B do
		local r = new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(18, 18), ImageTransparency = 1, ZIndex = 18 }, area)
		table.insert(runners, { img = r, b = b, t = math.random() })
	end
	local motes = {}
	for i = 1, 18 do
		local m = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 220, 160), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(3, 3), BackgroundTransparency = 0.5, ZIndex = 13 }, bg)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, m)
		motes[i] = { f = m, x = math.random(), y = math.random(), v = 0.01 + math.random() * 0.02 }
	end
	RunService.RenderStepped:Connect(function(dt)
		if not treeGui.Visible or not snap then return end
		for _, r in runners do
			local so = stateOf(r.b.outer)
			local on = so ~= "locked"
			r.t = (r.t + dt * 0.45) % 1
			if on then
				local a, c = pos[r.b.inner], pos[r.b.outer]
				local p = a:Lerp(c, r.t)
				r.img.Position = UDim2.new(0.5, p.X, 0.5, p.Y)
				r.img.ImageColor3 = Config.TREE_BY_ID[r.b.outer].color:Lerp(Color3.new(1, 1, 1), 0.4)
				r.img.ImageTransparency = 0.25 + 0.75 * math.abs(r.t - 0.5) * 2
			else
				r.img.ImageTransparency = 1
			end
		end
		local now = os.clock()
		for id, d in N do
			if d.lvl and d.lvl > 0 and id ~= "Start" then
				local f = 0.12 * math.sin(now * 7 + #id) + 0.06 * math.sin(now * 13 + #id * 3) -- a gas flame's flicker
				d.glow.ImageTransparency = 0.5 + f
				d.glass.ImageTransparency = math.max(0, f * 0.8)
			end
		end
		for _, m in motes do
			m.y -= m.v * dt
			if m.y < -0.02 then m.y, m.x = 1.02, math.random() end
			m.f.Position = UDim2.fromScale(m.x + math.sin(now * 0.6 + m.v * 300) * 0.01, m.y)
		end
	end)

	-- 7) the reveal each time the screen opens: centre flares, rays draw outward, hexes appear ring by ring
	treeGui:GetPropertyChangedSignal("Visible"):Connect(function()
		if not treeGui.Visible then pop.Visible, selected, hovered = false, nil, nil return end
		local reduced = env.reduced and env.reduced()
		core.Size = UDim2.fromOffset(reduced and 150 or 420, reduced and 150 or 420)
		core.ImageTransparency = 0
		tw(core, 0.7, { Size = UDim2.fromOffset(150, 150) }, Enum.EasingStyle.Quint)
		if reduced then return end
		for _, r in rays do
			r.f.Size = UDim2.fromOffset(0, 1)
			r.f.Position = UDim2.fromScale(0.5, 0.5)
			tw(r.f, 0.8, { Size = UDim2.fromOffset(r.len, 1), Position = UDim2.new(0.5, math.cos(r.a) * r.len / 2, 0.5, math.sin(r.a) * r.len / 2) }, Enum.EasingStyle.Quart)
		end
		for id, d in N do
			d.ui.scale.Scale = 0
			task.delay(0.15 + ring[id] * 0.14, function() tw(d.ui.scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back) end)
		end
		for _, s in strips do s.img.ImageTransparency = 1; tw(s.img, 0.5, { ImageTransparency = 0 }) end
	end)

	-- 8) drag to pan, mouse wheel to zoom (kept from v1)
	local zoom = area:FindFirstChildOfClass("UIScale") or new("UIScale", { Scale = 1 }, area)
	local home = area.Position
	area.Position = UDim2.new(0.5, 0, 0.5, 0)
	home = area.Position
	local dragging, from, start = false, nil, nil
	treeGui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, from, start = true, input.Position, area.Position
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			zoom.Scale = math.clamp(zoom.Scale + input.Position.Z * 0.08, 0.7, 1.4)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - from
			area.Position = home + UDim2.fromOffset(math.clamp(start.X.Offset - home.X.Offset + d.X, -300, 300), math.clamp(start.Y.Offset - home.Y.Offset + d.Y, -260, 260))
			if pop.Visible and (hovered or selected) then showPopup(hovered or selected) end
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	treeGui:GetPropertyChangedSignal("Visible"):Connect(function()
		if treeGui.Visible then area.Position, zoom.Scale = home, math.clamp(treeGui.AbsoluteSize.Y / 800, 0.75, 1.2) end
	end)
	return M
end
