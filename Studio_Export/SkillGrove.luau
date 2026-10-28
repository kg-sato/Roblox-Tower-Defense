--!nocheck
-- SkillGrove (2026-10-28): opening the Skill Tree walks you, in first person, up a lamplit path to a living tree whose
-- branches mirror the skill hexes (one lantern per skill: lit = owned, pulsing = can buy, bud = hidden). The branches
-- grow ring by ring as you approach; buying a skill flares its lantern. 2026-10-28 abstract pass: lines, points and
-- circles only (see Roblox Dev/Research/UI/Abstract HUD.md, round 4). User: "When you click the skill tree, you go
-- into first person and see the actual tree grow before walking towards it and upgrading."
-- Installed as StarterPlayerScripts.SkillGrove (client only, visual only). GameClient:
--   local Grove = require(script.Parent.SkillGrove)({ Config = Config, setCamera = fn(cf|nil), setFov = fn(f|nil),
--                                                     settings = SETTINGS, sfx = FXK.play })
--   Grove.open(snap, onArrive)  Grove.light(id, snap)  Grove.close(onDone)  Grove.refresh(snap)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local G = Vector3.new(0, 0, 420) -- the courtyard, far beyond the board and the skyline
local SQ3 = math.sqrt(3)
local SPREAD = 2.4

return function(ctx)
	local Config = ctx.Config
	local M = {}
	local folder, nodes, opens = nil, {}, 0
	local camConn, fade

	local function tw(i, t, p, s, d)
		local x = TweenService:Create(i, TweenInfo.new(t, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p)
		x:Play()
		return x
	end
	local function part(props, parent)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		for k, v in props do p[k] = v end
		p.Parent = parent or folder
		return p
	end
	local function ring(n) -- hex distance from the centre
		return math.max(math.abs(n.q), math.abs(n.r), math.abs(-n.q - n.r))
	end
	local function nodePos(n)
		local x, y = SQ3 * (n.q + n.r / 2), 1.5 * n.r
		return G + Vector3.new(x * SPREAD, 12 - y * SPREAD, -ring(n) * 0.9)
	end
	-- abstract pass (2026-10-28): no wood, cobbles, gas lamps or brick. The tree is a constellation of lines and points
	-- over a dark ground; the canopy is three af Klint circles; the path is one gold line with points.
	local INK, DIM = Color3.fromRGB(14, 12, 22), Color3.fromRGB(110, 100, 140)
	local GOLD, VIOLET = Color3.fromRGB(255, 214, 130), Color3.fromRGB(150, 110, 230)
	local FACE = CFrame.Angles(0, math.pi / 2, 0) -- turns a cylinder's flat side to face the walker (+Z)
	local function branch(a, b, thick, color)
		local len = (b - a).Magnitude
		local p = part({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Color = color or DIM, Transparency = 0.5, Size = Vector3.new(len, thick, thick), CFrame = CFrame.lookAt(a:Lerp(b, 0.5), b) * CFrame.Angles(0, math.pi / 2, 0) })
		p:SetAttribute("Full", p.Size)
		p:SetAttribute("From", a)
		p:SetAttribute("To", b)
		return p
	end

	local function build()
		folder = Instance.new("Folder")
		folder.Name = "SkillGrove"
		folder.Parent = workspace
		-- ground: a dark ink disc; the path: one gold line with a point every 6 studs
		part({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.SmoothPlastic, Color = INK, Size = Vector3.new(1, 90, 90), CFrame = CFrame.new(G + Vector3.new(0, -0.47, 10)) * CFrame.Angles(0, 0, math.pi / 2) })
		part({ Material = Enum.Material.Neon, Color = GOLD, Transparency = 0.3, Size = Vector3.new(0.12, 0.05, 66), CFrame = CFrame.new(G + Vector3.new(0, 0.05, 39)) })
		for z = 6, 72, 6 do
			part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = GOLD, Size = Vector3.one * 0.35, CFrame = CFrame.new(G + Vector3.new(0, 0.15, z)) })
		end
		-- lamps: floating amber points on a faint vertical line
		for _, side in { -1, 1 } do
			for _, z in { 14, 38, 60 } do
				local base = G + Vector3.new(side * 5, 0, z)
				part({ Material = Enum.Material.Neon, Color = DIM, Transparency = 0.6, Size = Vector3.new(0.06, 7, 0.06), CFrame = CFrame.new(base + Vector3.new(0, 3.5, 0)) })
				local head = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 186, 110), Size = Vector3.one * 0.35, CFrame = CFrame.new(base + Vector3.new(0, 7.3, 0)) })
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(255, 190, 110), 16, 1.2, false
				l.Parent = head
			end
		end
		-- the courtyard edge: a ring of 24 violet points instead of a brick wall
		for i = 0, 23 do
			local a = i / 24 * math.pi * 2
			if math.sin(a) <= 0.8 then -- leave a gap where the path enters
				part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = VIOLET, Transparency = 0.2, Size = Vector3.one * 0.5, CFrame = CFrame.new(G + Vector3.new(math.cos(a) * 30, 0.6, math.sin(a) * 30 - 4)) })
			end
		end
		-- THE MAIN TREE (user: "a really majestic main tree"): a trunk woven from seven strands of light that rise
		-- from spread roots and braid into one at the crown, then a fractal canopy of five limbs. Every decor line has
		-- two ghost copies, thicker, fainter and nudged a hair off, so it blooms like a long-exposure photo (user:
		-- "duplicate objects and slightly move them so the animations have more glare / blur").
		local PALE = Color3.fromRGB(236, 228, 255)
		local function glowLine(a, b, thick, color, tr)
			local main = branch(a, b, thick, color)
			main.Transparency = tr
			for k, g in { { 2.6, 0.84, Vector3.new(0.05, 0.03, -0.08) }, { 5, 0.94, Vector3.new(-0.06, -0.02, -0.16) } } do
				local p = branch(a + g[3], b + g[3], thick * g[1], color)
				p.Transparency = 1 - (1 - tr) * (1 - g[2])
			end
			return main
		end
		local crown = G + Vector3.new(0, 12, -0.6)
		local function curve(t) return G + Vector3.new(math.sin(t * 3) * 0.9, t * 12, math.sin(t * 2) * -0.6) end
		local pts = {}
		for i = 0, 6 do pts[i] = curve(i / 6) end
		pts[6] = crown
		for s = 0, 6 do -- seven strands, spread at the root, braided at the crown
			local a0 = s / 7 * math.pi * 2
			local spread = Vector3.new(math.cos(a0) * 1.8, 0, math.sin(a0) * 1.2)
			local prev
			for i = 0, 8 do
				local t = i / 8
				local twist = a0 + t * 2.2
				local p = curve(t):Lerp(crown, t ^ 3) + Vector3.new(math.cos(twist) * 1.8, 0, math.sin(twist) * 1.2) * (1 - t) ^ 1.4
				if i == 0 then p = G + spread end
				if prev then glowLine(prev, p, 0.11, PALE:Lerp(GOLD, t), 0.35) end
				prev = p
			end
		end
		for k = 0, 8 do -- roots: gold lines running out along the ground
			local a = k / 9 * math.pi * 2 + 0.2
			local mid = G + Vector3.new(math.cos(a) * 2.6, 0.08, math.sin(a) * 2.6)
			local tip = G + Vector3.new(math.cos(a + 0.25) * (5 + (k % 3) * 1.5), 0.08, math.sin(a + 0.25) * (5 + (k % 3) * 1.5))
			glowLine(G + Vector3.new(math.cos(a) * 1.4, 0.08, math.sin(a) * 1.0), mid, 0.1, GOLD, 0.25)
			glowLine(mid, tip, 0.07, GOLD, 0.45)
		end
		-- canopy: five limbs from the crown, each splitting four times; gold points at the tips
		local rngC = Random.new(3)
		local function limb(a, dir, len, thick, depth, maxD, ghost)
			local b = a + dir * len
			local k = 1 - depth / maxD
			if ghost then
				glowLine(a, b, thick, VIOLET:Lerp(GOLD, k), 0.5 + k * 0.25) -- tinted and fainter than the lanterns, which stay the focus
			else
				branch(a, b, thick, DIM).Transparency = 0.45 + k * 0.3
			end
			if depth == 0 then
				local tip = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = ghost and GOLD or VIOLET, Size = Vector3.one * (ghost and 0.3 or 0.2), CFrame = CFrame.new(b) })
				tip:SetAttribute("Leaf", tip.Size)
				return
			end
			for _, sgn in { -1, 1 } do
				local r = sgn * (0.38 + rngC:NextNumber() * 0.22)
				local d = Vector3.new(dir.X * math.cos(r) - dir.Y * math.sin(r), dir.X * math.sin(r) + dir.Y * math.cos(r), dir.Z - 0.04).Unit
				limb(b, d, len * 0.74, thick * 0.68, depth - 1, maxD, ghost)
			end
		end
		for _, ang in { -1.15, -0.58, 0, 0.58, 1.15 } do
			limb(crown, Vector3.new(math.sin(ang), math.cos(ang), -0.08).Unit, 4.8, 0.2, 4, 4, true)
		end
		-- backdrop: a stepped halo sun behind the crown (four stacked circles = a soft glow), a gold horizon line,
		-- and four smaller violet trees far off on either side so the main tree has a court
		for i, spec in { { 50, 0.96 }, { 40, 0.94 }, { 30, 0.92 }, { 20, 0.88 } } do
			local s = spec[1]
			local disc = part({ Transparency = 1, Size = Vector3.new(s, s, 0.05), CFrame = CFrame.new(G + Vector3.new(0, 13, -16 + i * 0.2)) })
			local sg = Instance.new("SurfaceGui")
			sg.Face, sg.LightInfluence, sg.CanvasSize = Enum.NormalId.Back, 0, Vector2.new(400, 400)
			local c = Instance.new("Frame")
			c.BackgroundColor3, c.BackgroundTransparency, c.BorderSizePixel, c.Size = Color3.fromRGB(255, 196, 120), spec[2], 0, UDim2.fromScale(1, 1)
			Instance.new("UICorner", c).CornerRadius = UDim.new(0.5, 0)
			c.Parent = sg
			sg.Parent = disc
			disc:SetAttribute("Leaf", disc.Size)
		end
		glowLine(G + Vector3.new(-80, 0.06, -30), G + Vector3.new(80, 0.06, -30), 0.08, GOLD, 0.3)
		for _, spec in { { -20, -10, 1 }, { 20, -10, 1 }, { -34, -20, 0.7 }, { 34, -20, 0.7 } } do
			local base = G + Vector3.new(spec[1], 0, spec[2])
			local top = base + Vector3.new(0, 6 * spec[3], 0)
			branch(base, top, 0.12, DIM).Transparency = 0.4
			for _, ang in { -0.7, 0, 0.7 } do
				limb(top, Vector3.new(math.sin(ang), math.cos(ang), 0).Unit, 3 * spec[3], 0.09, 3, 3, false)
			end
		end
		-- skill branches and lanterns: each node hangs off its neighbour one ring nearer the centre
		for _, n in Config.TREE do
			local pos = nodePos(n)
			if n.id ~= "Start" then
				local parentPos = pts[6]
				for _, nb in Config.TREE_NEIGHBORS[n.id] do
					local o = Config.TREE_BY_ID[nb]
					if ring(o) == ring(n) - 1 then
						parentPos = nodePos(o)
						break
					end
				end
				nodes[n.id] = { branch = branch(parentPos, pos, ring(n) == 1 and 0.16 or 0.1) }
			else
				nodes[n.id] = {}
			end
			-- the lantern: a point inside a faint circle that faces the walker
			local glass = part({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 0.8, Color = n.color, Size = Vector3.new(0.04, 1.6, 1.6), CFrame = CFrame.new(pos + Vector3.new(0, 0, -0.1)) * FACE })
			local core = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = n.color, Size = Vector3.one * 0.75, CFrame = CFrame.new(pos) })
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness, light.Shadows = n.color, 9, 0, false
			light.Parent = core
			nodes[n.id].glass, nodes[n.id].core, nodes[n.id].light, nodes[n.id].pos = glass, core, light, pos
		end
		-- canopy: three concentric af Klint circles behind the branches (violet, gold, violet), plus drifting motes
		-- drawn on a SurfaceGui so the edges are true circles (a 24-stud cylinder shows facets)
		for i, spec in { { 24, VIOLET, 0.93 }, { 16, GOLD, 0.92 }, { 8, VIOLET, 0.88 } } do
			local leaf = part({ Transparency = 1, Size = Vector3.new(spec[1], spec[1], 0.05), CFrame = CFrame.new(G + Vector3.new(0, 12, -6 + i * 0.3)) })
			local sg = Instance.new("SurfaceGui")
			sg.Face, sg.LightInfluence, sg.CanvasSize = Enum.NormalId.Back, 0, Vector2.new(400, 400)
			local c = Instance.new("Frame")
			c.BackgroundColor3, c.BackgroundTransparency, c.BorderSizePixel, c.Size = spec[2], spec[3], 0, UDim2.fromScale(1, 1)
			Instance.new("UICorner", c).CornerRadius = UDim.new(0.5, 0)
			local st = Instance.new("UIStroke")
			st.Color, st.Thickness, st.Transparency = spec[2], 3, 0.35
			st.Parent = c
			c.Parent = sg
			sg.Parent = leaf
			leaf:SetAttribute("Leaf", leaf.Size)
		end
		local emitterPart = part({ Transparency = 1, Size = Vector3.new(16, 1, 6), CFrame = CFrame.new(G + Vector3.new(0, 15, -1)) })
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxassetid://74135098013493" -- our dot texture
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 220, 160), Color3.fromRGB(190, 150, 255))
		pe.LightEmission, pe.LightInfluence, pe.Brightness = 1, 0, 2
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.35), NumberSequenceKeypoint.new(1, 0) })
		pe.Lifetime, pe.Rate = NumberRange.new(3, 5), 14
		pe.Speed, pe.Acceleration = NumberRange.new(0.3, 0.8), Vector3.new(0, -0.6, 0)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Parent = emitterPart
	end

	-- state of each lantern from the snapshot (same rules as the hex UI)
	local function stateOf(id, snap)
		if id == "Start" then return "owned" end
		local n = Config.TREE_BY_ID[id]
		local lvl = snap.tree[id] or 0
		if lvl > 0 then return lvl >= n.max and "maxed" or "owned" end
		for _, nb in Config.TREE_NEIGHBORS[id] do
			if (snap.tree[nb] or 0) > 0 or nb == "Start" then return "available" end
		end
		return "locked"
	end
	function M.refresh(snap)
		if not folder then return end
		for id, nd in nodes do
			local st = stateOf(id, snap)
			local n = Config.TREE_BY_ID[id]
			nd.state = st
			nd.core.Transparency = st == "locked" and 1 or (st == "available" and 0.45 or 0)
			nd.core.Color = st == "locked" and Color3.fromRGB(60, 40, 30) or n.color
			nd.glass.Transparency = st == "locked" and 1 or (st == "available" and 0.86 or 0.78)
			nd.light.Brightness = (st == "owned" or st == "maxed") and 1.4 or 0
			nd.core.Size = Vector3.one * (st == "maxed" and 0.95 or 0.75)
			if nd.branch then -- a lit line in the skill's colour once owned; a faint grey line before
				local lit = st == "owned" or st == "maxed"
				nd.branch.Color = lit and n.color or DIM
				nd.branch.Transparency = lit and 0 or (st == "locked" and 0.75 or 0.5)
			end
		end
	end

	-- grow: every branch extends from its base, ring by ring; lanterns and leaves follow
	local function grow(total)
		for _, p in folder:GetDescendants() do
			if p:IsA("BasePart") then
				local full, from, to = p:GetAttribute("Full"), p:GetAttribute("From"), p:GetAttribute("To")
				if full then
					local delay = math.clamp((from - G).Magnitude / 22, 0, 1) * total * 0.6
					p.Size = Vector3.new(0.01, full.Y, full.Z)
					p.CFrame = CFrame.lookAt(from, to) * CFrame.Angles(0, math.pi / 2, 0)
					task.delay(delay, function()
						tw(p, total * 0.4, { Size = full, CFrame = CFrame.lookAt(from:Lerp(to, 0.5), to) * CFrame.Angles(0, math.pi / 2, 0) }, Enum.EasingStyle.Quint)
					end)
				end
				local leaf = p:GetAttribute("Leaf")
				if leaf then
					p.Size = Vector3.new(0.1, 0.1, leaf.Z)
					task.delay(total * (0.5 + math.random() * 0.4), function() tw(p, 0.5, { Size = leaf }, Enum.EasingStyle.Back) end)
				end
			end
		end
		for _, nd in nodes do
			local full = nd.core.Size
			nd.core.Size, nd.glass.Size = Vector3.one * 0.05, Vector3.one * 0.05
			local delay = math.clamp((nd.pos - G).Magnitude / 22, 0, 1) * total * 0.6 + total * 0.35
			task.delay(delay, function()
				tw(nd.core, 0.35, { Size = full }, Enum.EasingStyle.Back)
				tw(nd.glass, 0.35, { Size = Vector3.new(0.04, 1.6, 1.6) }, Enum.EasingStyle.Back)
			end)
		end
	end

	local function fadeTo(alpha, t)
		if not fade then
			local sg = Instance.new("ScreenGui")
			sg.Name, sg.IgnoreGuiInset, sg.DisplayOrder, sg.ResetOnSpawn = "GroveFade", true, 60, false
			sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
			fade = Instance.new("Frame")
			fade.BackgroundColor3, fade.BorderSizePixel, fade.Size, fade.BackgroundTransparency = Color3.new(0, 0, 0), 0, UDim2.fromScale(1, 1), 1
			fade.Parent = sg
		end
		return tw(fade, t, { BackgroundTransparency = 1 - alpha })
	end

	local VIEW_AT = G + Vector3.new(0, 9.5, 0)
	function M.open(snap, onArrive)
		if not folder then build() end
		M.refresh(snap)
		opens += 1
		local short = opens > 1 or ctx.settings.gameSpeed == 2 or ctx.settings.reducedMotion or (ctx.short and ctx.short())
		local walkT = short and 0.9 or 2.4
		local from = G + Vector3.new(0, 5.6, short and 36 or 66)
		local to = G + Vector3.new(0, 6.6, 24)
		fadeTo(1, 0.22).Completed:Wait()
		grow(walkT + 0.3)
		ctx.sfx("anticipation", { pitch = 0.8 })
		local t0 = os.clock()
		if camConn then camConn:Disconnect() end
		camConn = RunService.RenderStepped:Connect(function()
			local k = math.clamp((os.clock() - t0) / walkT, 0, 1)
			local e = k < 1 and (1 - (1 - k) ^ 2) or 1
			local pos = from:Lerp(to, e)
			local bob = (ctx.settings.reducedMotion or k >= 1) and 0 or math.sin((os.clock() - t0) * 9) * 0.14 * (1 - e)
			local sway = (ctx.settings.reducedMotion or k >= 1) and 0 or math.sin((os.clock() - t0) * 4.5) * 0.08 * (1 - e)
			local look = VIEW_AT:Lerp(VIEW_AT + Vector3.new(0, 1.5, 0), e) + Vector3.new(sway * 4, 0, 0)
			ctx.setCamera(CFrame.lookAt(pos + Vector3.new(sway, bob, 0), look))
			ctx.setFov(72 - 10 * e)
		end)
		fadeTo(0, 0.35)
		task.wait(walkT + (short and 0.25 or 0.7)) -- hold on the grown tree before the panel covers it
		if onArrive then onArrive() end
	end

	function M.light(id, snap)
		if not folder then return end
		M.refresh(snap)
		local nd = nodes[id]
		if not nd then return end
		ctx.sfx("ring", { pitch = 1.2 })
		local full = nd.core.Size
		nd.core.Size = full * 2.2
		tw(nd.core, 0.5, { Size = full }, Enum.EasingStyle.Back)
		nd.light.Brightness = 6
		tw(nd.light, 0.8, { Brightness = 1.4 })
		for k = 1, 12 do -- sparks fly off the lantern
			local s = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = nd.core.Color, Size = Vector3.one * 0.25, CFrame = CFrame.new(nd.pos) })
			local dir = Vector3.new(math.random() - 0.5, math.random() - 0.2, math.random() - 0.5).Unit
			tw(s, 0.6, { Position = nd.pos + dir * 3.5, Size = Vector3.one * 0.02, Transparency = 1 })
			task.delay(0.65, function() s:Destroy() end)
		end
	end

	function M.close(onDone)
		fadeTo(1, 0.2).Completed:Wait()
		if camConn then camConn:Disconnect() camConn = nil end
		ctx.setCamera(nil)
		ctx.setFov(nil)
		if onDone then onDone() end
		fadeTo(0, 0.3)
	end

	return M
end
