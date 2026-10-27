--!nocheck
-- ProjectileFX: one projectile look per familiar (cosmetic; the server already applied the damage).
-- Installed as ReplicatedStorage.ProjectileFX. A character picks its style with the `Shot` attribute
-- on its folder in ReplicatedStorage.Characters (see [[How to Add a Character]]).
--
--   local dur = ProjectileFX.fire(style, from, to, color, width, parent, crit)
--     styles: bolt (default smear), flame, leaf, spark, ice, stone, card, star
--     returns how long the shot takes, so callers can release their effect budget.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ProjectileFX = {}

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	for k, v in props do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function ellipsoid(p)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = p
	return p
end

-- move a part along a path over `dur` seconds; pathFn(a) -> CFrame for a in 0..1
local function fly(p, dur, pathFn, onArrive)
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local a = math.min(1, (os.clock() - t0) / dur)
		if p.Parent then
			p.CFrame = pathFn(a)
		end
		if a >= 1 then
			conn:Disconnect()
			if onArrive then
				onArrive()
			end
			p:Destroy()
		end
	end)
end

-- small impact puff: an expanding, fading ball
local function puff(parent, pos, color, size)
	local b = part(parent, { Shape = Enum.PartType.Ball, Color = color, Size = Vector3.one * size * 0.4, CFrame = CFrame.new(pos), Transparency = 0.2 })
	TweenService:Create(b, TweenInfo.new(0.22, Enum.EasingStyle.Quad), { Size = Vector3.one * size * 1.6, Transparency = 1 }):Play()
	Debris:AddItem(b, 0.25)
end

-- tiny fragments that scatter from the hit point
local function shards(parent, pos, color, n, size)
	for i = 1, n do
		local s = part(parent, { Color = color, Size = Vector3.new(size, size, size * 1.8), CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, 0) })
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.2, math.random() - 0.5).Unit
		TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { CFrame = s.CFrame + dir * 2.5, Transparency = 1, Size = Vector3.one * size * 0.3 }):Play()
		Debris:AddItem(s, 0.32)
	end
end

local function arc(from, to, a, height)
	return from:Lerp(to, a) + Vector3.new(0, math.sin(a * math.pi) * height, 0)
end

local STYLES = {}

-- default: smeared bolt (leaves stretched, arrives compact)
STYLES.bolt = function(from, to, color, w, parent)
	local len = (to - from).Magnitude
	local dir = len > 0.01 and (to - from).Unit or Vector3.new(0, 0, -1)
	local b = part(parent, { Color = color, Size = Vector3.new(w * 0.6, w * 0.6, math.max(w, len * 0.35)), CFrame = CFrame.lookAt(from + dir * len * 0.175, to) })
	TweenService:Create(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.lookAt(to, to + dir), Size = Vector3.one * w * 0.7 }):Play()
	Debris:AddItem(b, 0.14)
	return 0.14
end

-- Ember Wick: a flame mote on a low arc, ember sparks behind it, a small fire puff
STYLES.flame = function(from, to, color, w, parent)
	local core = part(parent, { Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 220, 130), Size = Vector3.one * w * 0.55, CFrame = CFrame.new(from) })
	local glow = ellipsoid(part(core, { Color = Color3.fromRGB(255, 120, 40), Size = Vector3.new(w, w * 1.3, w), CFrame = CFrame.new(from), Transparency = 0.35 }))
	glow.Parent = parent
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, w * 0.3, 0), Vector3.new(0, -w * 0.3, 0)
	a0.Parent, a1.Parent = core, core
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 70, 20))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = 0.18
	trail.LightEmission = 1
	trail.Parent = core
	local dur = 0.2
	fly(glow, dur, function(a) return CFrame.new(arc(from, to, a, 1.2)) end)
	fly(core, dur, function(a) return CFrame.new(arc(from, to, a, 1.2)) end, function()
		puff(parent, to, Color3.fromRGB(255, 140, 50), w)
	end)
	return dur
end

-- Ivy Sprite: a spinning leaf that curves sideways
STYLES.leaf = function(from, to, color, w, parent)
	local leaf = ellipsoid(part(parent, { Color = Color3.fromRGB(120, 210, 110), Size = Vector3.new(w * 1.4, w * 0.15, w * 0.7), CFrame = CFrame.new(from), Material = Enum.Material.SmoothPlastic }))
	local side = (to - from):Cross(Vector3.yAxis)
	side = side.Magnitude > 0.01 and side.Unit or Vector3.xAxis
	local dur = 0.24
	fly(leaf, dur, function(a)
		local p = from:Lerp(to, a) + side * math.sin(a * math.pi) * 1.6 + Vector3.new(0, math.sin(a * math.pi) * 0.8, 0)
		return CFrame.new(p) * CFrame.Angles(0, a * 14, math.sin(a * 9) * 0.6)
	end, function()
		shards(parent, to, Color3.fromRGB(110, 200, 100), 3, w * 0.25)
	end)
	return dur
end

-- Spark Moth: an instant zigzag of light that flickers out
STYLES.spark = function(from, to, color, w, parent)
	local pts = { from }
	local n = 4
	for i = 1, n - 1 do
		local p = from:Lerp(to, i / n)
		table.insert(pts, p + Vector3.new((math.random() - 0.5) * 1.6, (math.random() - 0.5) * 1.2, (math.random() - 0.5) * 1.6))
	end
	table.insert(pts, to)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local seg = part(parent, { Color = Color3.fromRGB(255, 245, 170), Size = Vector3.new(w * 0.22, w * 0.22, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2, b) })
		TweenService:Create(seg, TweenInfo.new(0.12), { Transparency = 1, Size = Vector3.new(0.05, 0.05, (b - a).Magnitude) }):Play()
		Debris:AddItem(seg, 0.13)
	end
	puff(parent, to, Color3.fromRGB(255, 240, 150), w * 0.8)
	return 0.13
end

-- Frostling: a fast ice shard that shatters
STYLES.ice = function(from, to, color, w, parent)
	local shard = part(parent, { Color = Color3.fromRGB(190, 235, 255), Size = Vector3.new(w * 0.35, w * 0.35, w * 1.6), CFrame = CFrame.lookAt(from, to), Material = Enum.Material.Glass, Transparency = 0.15 })
	local glow = part(shard, { Color = Color3.fromRGB(170, 240, 255), Size = Vector3.new(w * 0.26, w * 0.26, w * 1.5), CFrame = shard.CFrame, Transparency = 0 })
	glow.Parent = parent
	local dur = 0.13
	local path = function(a)
		return CFrame.lookAt(from:Lerp(to, a), to + (to - from))
	end
	fly(glow, dur, path)
	fly(shard, dur, path, function()
		shards(parent, to, Color3.fromRGB(200, 240, 255), 4, w * 0.22)
	end)
	return dur
end

-- Gargoyle: a heavy stone lobbed high, dust on landing
STYLES.stone = function(from, to, color, w, parent)
	-- light stone + dust trail: a dark rock vanished against the dusk ground
	local rock = part(parent, { Shape = Enum.PartType.Ball, Color = Color3.fromRGB(196, 190, 200), Size = Vector3.one * w * 0.9, CFrame = CFrame.new(from), Material = Enum.Material.Slate })
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, w * 0.35, 0), Vector3.new(0, -w * 0.35, 0)
	a0.Parent, a1.Parent = rock, rock
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Color = ColorSequence.new(Color3.fromRGB(210, 200, 185))
	trail.Transparency = NumberSequence.new(0.45, 1)
	trail.Lifetime = 0.2
	trail.Parent = rock
	local dur = 0.3
	fly(rock, dur, function(a)
		return CFrame.new(arc(from, to, a, 4)) * CFrame.Angles(a * 8, a * 5, 0)
	end, function()
		puff(parent, to, Color3.fromRGB(150, 140, 130), w * 1.2)
		shards(parent, to, Color3.fromRGB(110, 106, 114), 3, w * 0.3)
	end)
	return dur
end

-- Arcane Fox: a flat card spinning along its path
STYLES.card = function(from, to, color, w, parent)
	local card = part(parent, { Color = Color3.fromRGB(46, 28, 80), Size = Vector3.new(w * 0.7, 0.06, w * 1.0), CFrame = CFrame.new(from), Material = Enum.Material.SmoothPlastic })
	local edge = part(parent, { Color = Color3.fromRGB(240, 205, 120), Size = Vector3.new(w * 0.78, 0.04, w * 1.08), CFrame = CFrame.new(from), Transparency = 0.1 })
	local dur = 0.2
	local path = function(a)
		return CFrame.new(from:Lerp(to, a) + Vector3.new(0, math.sin(a * math.pi) * 0.6, 0)) * CFrame.Angles(0, a * 18, 0.25)
	end
	fly(edge, dur, path)
	fly(card, dur, path, function()
		puff(parent, to, Color3.fromRGB(190, 140, 255), w)
	end)
	return dur
end

-- Star Drake: a bright star with a sparkling trail and a starburst
STYLES.star = function(from, to, color, w, parent)
	local star = part(parent, { Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 236, 160), Size = Vector3.one * w * 0.7, CFrame = CFrame.new(from) })
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 225, 140))
	pe.LightEmission = 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, w * 0.5), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.25, 0.4)
	pe.Rate = 80
	pe.Speed = NumberRange.new(0.5, 1.5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = star
	local dur = 0.18
	fly(star, dur, function(a)
		return CFrame.new(arc(from, to, a, 1.0))
	end, function()
		for i = 0, 4 do
			local ang = i * math.pi * 2 / 5
			local ray = part(parent, { Color = Color3.fromRGB(255, 230, 150), Size = Vector3.new(w * 0.15, w * 0.15, w * 1.4), CFrame = CFrame.new(to) * CFrame.Angles(0, ang, 0.4) * CFrame.new(0, 0, -w * 0.6) })
			TweenService:Create(ray, TweenInfo.new(0.22), { Transparency = 1, Size = Vector3.new(0.05, 0.05, w * 2.2) }):Play()
			Debris:AddItem(ray, 0.24)
		end
	end)
	return dur
end

function ProjectileFX.fire(style, from, to, color, w, parent, crit)
	local fn = STYLES[style] or STYLES.bolt
	local ok, dur = pcall(fn, from, to, color, w * (crit and 1.25 or 1), parent)
	if not ok then
		return STYLES.bolt(from, to, color, w, parent)
	end
	if crit then
		puff(parent, to, Color3.fromRGB(255, 220, 120), w * 1.4)
	end
	return dur
end

ProjectileFX.styles = STYLES
return ProjectileFX
