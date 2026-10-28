--!nocheck
-- SkillGrove (2026-10-28): opening the Skill Tree walks you, in first person, up a lamplit path to a living tree whose
-- branches mirror the skill hexes (one lantern per skill: lit = owned, pulsing = can buy, bud = hidden). The branches
-- grow ring by ring as you approach; buying a skill flares its lantern. User: "When you click the skill tree, you go
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
	local function branch(a, b, thick, color)
		local len = (b - a).Magnitude
		local p = part({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Wood, Color = color or Color3.fromRGB(74, 50, 38), Size = Vector3.new(len, thick, thick), CFrame = CFrame.lookAt(a:Lerp(b, 0.5), b) * CFrame.Angles(0, math.pi / 2, 0) })
		p:SetAttribute("Full", p.Size)
		p:SetAttribute("From", a)
		p:SetAttribute("To", b)
		return p
	end

	local function build()
		folder = Instance.new("Folder")
		folder.Name = "SkillGrove"
		folder.Parent = workspace
		-- courtyard: dark ground, cobbled path, two gas lamps, a low wall ring
		part({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Slate, Color = Color3.fromRGB(32, 30, 40), Size = Vector3.new(1, 90, 90), CFrame = CFrame.new(G + Vector3.new(0, -0.5, 10)) * CFrame.Angles(0, 0, math.pi / 2) })
		for z = 6, 72, 3 do
			part({ Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(96, 88, 84), Size = Vector3.new(5, 0.2, 2.8), CFrame = CFrame.new(G + Vector3.new(math.sin(z * 0.08) * 0.6, 0.05, z)) })
		end
		for _, side in { -1, 1 } do
			for _, z in { 14, 38, 60 } do
				local base = G + Vector3.new(side * 5, 0, z)
				part({ Material = Enum.Material.Metal, Color = Color3.fromRGB(30, 30, 34), Size = Vector3.new(0.35, 7, 0.35), CFrame = CFrame.new(base + Vector3.new(0, 3.5, 0)) })
				local head = part({ Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 186, 110), Transparency = 0.35, Size = Vector3.new(0.5, 0.7, 0.5), CFrame = CFrame.new(base + Vector3.new(0, 7.3, 0)) }) -- smaller, half-clear head: v1 blew out to white blocks
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(255, 190, 110), 16, 1.6, false
				l.Parent = head
			end
		end
		for i = 0, 23 do
			local a = i / 24 * math.pi * 2
			local p = G + Vector3.new(math.cos(a) * 30, 0.9, math.sin(a) * 30 - 4)
			if math.sin(a) <= 0.8 then -- leave a gap where the path enters
				part({ Material = Enum.Material.Brick, Color = Color3.fromRGB(70, 56, 60), Size = Vector3.new(8, 1.8, 1.4), CFrame = CFrame.lookAt(p, G + Vector3.new(0, 0.9, -4)) })
			end
		end
		-- trunk: an S-curve of segments, root flares
		local pts = {}
		for i = 0, 6 do
			local t = i / 6
			pts[i] = G + Vector3.new(math.sin(t * 3) * 0.9, t * 12, math.sin(t * 2) * -0.6)
		end
		for i = 1, 6 do
			branch(pts[i - 1], pts[i], 3.4 - i * 0.3)
		end
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2 + 0.3
			branch(G + Vector3.new(0, 1.6, 0), G + Vector3.new(math.cos(a) * 3.4, -0.2, math.sin(a) * 3.4), 0.9)
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
				nodes[n.id] = { branch = branch(parentPos, pos, ring(n) == 1 and 1.25 or 0.75) } -- v1 read thin and spindly
			else
				nodes[n.id] = {}
			end
			local glass = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Glass, Transparency = 0.55, Color = Color3.fromRGB(220, 220, 255), Size = Vector3.one * 1.3, CFrame = CFrame.new(pos) })
			local core = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = n.color, Size = Vector3.one * 0.75, CFrame = CFrame.new(pos) })
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness, light.Shadows = n.color, 9, 0, false
			light.Parent = core
			nodes[n.id].glass, nodes[n.id].core, nodes[n.id].light, nodes[n.id].pos = glass, core, light, pos
		end
		-- canopy: soft violet-gold leaf clouds and drifting motes
		local rng = Random.new(7)
		for i = 1, 90 do
			local around = nodePos(Config.TREE[rng:NextInteger(1, #Config.TREE)])
			local leaf = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = (i % 3 == 0) and Color3.fromRGB(255, 210, 140) or Color3.fromRGB(150, 110, 230), Transparency = 0.72, Size = Vector3.one * rng:NextNumber(3, 5.5), CFrame = CFrame.new(around + Vector3.new(rng:NextNumber(-1.6, 1.6), rng:NextNumber(-0.8, 1.6), rng:NextNumber(-2, 0.5))) })
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
			nd.glass.Transparency = st == "locked" and 1 or 0.55
			nd.light.Brightness = (st == "owned" or st == "maxed") and 1.4 or 0
			nd.core.Size = Vector3.one * (st == "maxed" and 0.95 or 0.75)
			if nd.branch then
				nd.branch.Color = (st == "owned" or st == "maxed") and n.color:Lerp(Color3.fromRGB(74, 50, 38), 0.55) or Color3.fromRGB(74, 50, 38)
				nd.branch.Material = (st == "owned" or st == "maxed") and Enum.Material.Neon or Enum.Material.Wood
				nd.branch.Transparency = (st == "owned" or st == "maxed") and 0.2 or 0
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
					p.Size = Vector3.one * 0.1
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
				tw(nd.glass, 0.35, { Size = Vector3.one * 1.3 }, Enum.EasingStyle.Back)
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
