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
ProjectileFX.timeScale = 1 -- game speed (1 or 2): flights take dur / timeScale, set by GameClient
ProjectileFX.quality = "default" -- "low" | "default" | "high"; set by GameClient from the player's Effects detail setting

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
	dur = dur / ProjectileFX.timeScale
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
	pe.Rate = ProjectileFX.quality == "high" and 100 or 80
	pe.Speed = NumberRange.new(0.5, 1.5)
	pe.SpreadAngle = Vector2.new(180, 180)
	if ProjectileFX.quality == "low" then
		pe:Destroy() -- Low drops the secondary sparkle layer
	else
		pe.Parent = star
	end
	local dur = 0.18
	fly(star, dur, function(a)
		return CFrame.new(arc(from, to, a, 1.0))
	end, function()
		for i = 0, (ProjectileFX.quality == "low" and 1 or 4) do
			local ang = i * math.pi * 2 / 5
			local ray = part(parent, { Color = Color3.fromRGB(255, 230, 150), Size = Vector3.new(w * 0.15, w * 0.15, w * 1.4), CFrame = CFrame.new(to) * CFrame.Angles(0, ang, 0.4) * CFrame.new(0, 0, -w * 0.6) })
			TweenService:Create(ray, TweenInfo.new(0.22), { Transparency = 1, Size = Vector3.new(0.05, 0.05, w * 2.2) }):Play()
			Debris:AddItem(ray, 0.24)
		end
	end)
	return dur
end

-- Slash arc (melee-style hit): a crescent swept by a Trail 3 studs in front of the attacker, facing the target.
-- Combo: each attacker's hits roll the arc 0, 160, -35 degrees in turn. Heavy (crit) hits play at half speed
-- (TimeScale 0.5). Sparks at the target use ZOffset 1.5 so they draw in front of the enemy. Additive glow only for
-- bright colours; dark ink or smoke colours use LightEmission 0 (additive blending would make them vanish).
ProjectileFX.combo = {}
local COMBO = { 0, 160, -35 }
STYLES.slash = function(from, to, color, w, parent, crit)
	local key = string.format("%d,%d", math.floor(from.X + 0.5), math.floor(from.Z + 0.5))
	local n = (ProjectileFX.combo[key] or 0) % #COMBO + 1
	ProjectileFX.combo[key] = n
	local slow = (crit and 2 or 1) / ProjectileFX.timeScale -- TimeScale 0.5 on heavy hits = twice as long
	local dur = 0.12 * slow
	local nominal = 0.12 * (crit and 2 or 1) -- fire() divides by the game speed itself
	local ink = (color.R + color.G + color.B) / 3 < 0.25
	local flat = Vector3.new(to.X, from.Y, to.Z)
	-- laid almost flat (tilted 80 degrees) so the crescent reads from the high board camera; the combo roll turns it
	local pivot = CFrame.lookAt(from, flat) * CFrame.new(0, 0, -3) * CFrame.Angles(math.rad(-80), 0, 0) * CFrame.Angles(0, 0, math.rad(COMBO[n]))
	local r = 2.6 * w
	local blade = part(parent, { Transparency = 1, Size = Vector3.one * 0.2, CFrame = pivot })
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, r, 0), Vector3.new(0, r * 0.72, 0)
	a0.Parent, a1.Parent = blade, blade
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Color = ColorSequence.new(ink and color or Color3.new(1, 1, 1), color)
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.1) })
	trail.Lifetime = 0.16 * slow
	trail.LightEmission = ink and 0 or 1
	trail.LightInfluence = 0
	trail.Parent = blade
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local a = math.min(1, (os.clock() - t0) / dur)
		local e = 1 - (1 - a) ^ 3 -- fast start, settles at the end of the swing
		blade.CFrame = pivot * CFrame.Angles(0, 0, math.rad(-70 + 170 * e))
		if a >= 1 then
			conn:Disconnect()
			local sp = part(parent, { Transparency = 1, Size = Vector3.one * 0.2, CFrame = CFrame.new(to) })
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			pe.Color = ColorSequence.new(color)
			pe.LightEmission = ink and 0 or 1
			pe.LightInfluence = 0
			pe.ZOffset = 1.5
			pe.TimeScale = crit and 0.5 or 1
			pe.Size = NumberSequence.new(0.6 * w, 0)
			pe.Lifetime = NumberRange.new(0.25, 0.4)
			pe.Speed = NumberRange.new(6, 12)
			pe.SpreadAngle = Vector2.new(60, 60)
			pe.Rate = 0
			pe.Parent = sp
			pe:Emit(crit and 14 or 8)
			Debris:AddItem(sp, 1.2 / ProjectileFX.timeScale)
			Debris:AddItem(blade, trail.Lifetime + 0.05)
		end
	end)
	return nominal
end

function ProjectileFX.fire(style, from, to, color, w, parent, crit)
	local fn = STYLES[style] or STYLES.bolt
	local ok, dur = pcall(fn, from, to, color, w * (crit and 1.25 or 1), parent, crit)
	if not ok then
		return STYLES.bolt(from, to, color, w, parent) / ProjectileFX.timeScale
	end
	if crit then
		puff(parent, to, Color3.fromRGB(255, 220, 120), w * 1.4)
	end
	return dur / ProjectileFX.timeScale
end

-- Hit reactions per projectile style (T09): how the enemy reacts when the shot lands. GameClient reads the numbers
-- (tint on the enemy's highlight, push back along the lane, wobble, tilt, jitter, how long a tint holds) and calls
-- ProjectileFX.react for the small accent at the hit point. Reduced motion keeps only the tint.
ProjectileFX.REACT = {
	bolt = { tint = Color3.fromRGB(255, 255, 255), jolt = 0.6, wobble = 0, tilt = 0, jitter = 0, hold = 0, dur = 0.18 },
	flame = { tint = Color3.fromRGB(255, 140, 60), jolt = 0.3, wobble = 0, tilt = 0, jitter = 0, hold = 0.35, dur = 0.4 },
	leaf = { tint = Color3.fromRGB(120, 230, 110), jolt = 0.2, wobble = 0.35, tilt = 0, jitter = 0, hold = 0, dur = 0.35 },
	spark = { tint = Color3.fromRGB(170, 230, 255), jolt = 0.1, wobble = 0, tilt = 0, jitter = 0.45, hold = 0.15, dur = 0.3 },
	ice = { tint = Color3.fromRGB(140, 200, 255), jolt = 0.15, wobble = 0, tilt = 0, jitter = 0, hold = 0.6, dur = 0.7 },
	stone = { tint = Color3.fromRGB(190, 170, 150), jolt = 1.3, wobble = 0, tilt = 0.12, jitter = 0, hold = 0, dur = 0.3 },
	card = { tint = Color3.fromRGB(190, 140, 255), jolt = 0.25, wobble = 0, tilt = 0.3, jitter = 0, hold = 0, dur = 0.3 },
	star = { tint = Color3.fromRGB(255, 225, 140), jolt = 0.4, wobble = 0.2, tilt = 0, jitter = 0, hold = 0.1, dur = 0.3 },
	slash = { tint = Color3.fromRGB(255, 240, 220), jolt = 0.8, wobble = 0, tilt = 0.2, jitter = 0, hold = 0, dur = 0.22 },
}

-- Small accent at the hit point for the style (puffs and shards from this module; nothing persistent).
function ProjectileFX.react(style, at, parent, crit)
	local r = ProjectileFX.REACT[style] or ProjectileFX.REACT.bolt
	local k = crit and 1.4 or 1
	if ProjectileFX.ext and ProjectileFX.ext[style] then -- per-familiar accent from FamiliarShots
		pcall(ProjectileFX.ext[style], at, parent, crit)
		return r
	end
	if style == "flame" then
		puff(parent, at, Color3.fromRGB(255, 120, 40), 1.6 * k)
	elseif style == "leaf" then
		shards(parent, at, Color3.fromRGB(110, 200, 90), 4, 0.35 * k)
	elseif style == "spark" then
		shards(parent, at, Color3.fromRGB(190, 240, 255), 5, 0.22 * k)
	elseif style == "ice" then
		puff(parent, at, Color3.fromRGB(200, 230, 255), 1.4 * k)
		shards(parent, at, Color3.fromRGB(235, 248, 255), 4, 0.3 * k)
	elseif style == "stone" then
		puff(parent, at - Vector3.new(0, 1, 0), Color3.fromRGB(130, 118, 104), 2.2 * k)
	elseif style == "card" then
		puff(parent, at, Color3.fromRGB(170, 120, 255), 1.2 * k)
	else
		puff(parent, at, r.tint, 1 * k)
	end
	return r
end

ProjectileFX.styles = STYLES
-- T133: 20 per-familiar shot styles ("fs_<PetId>")
pcall(function() require(script.Parent:WaitForChild("FamiliarShots", 5)).install(ProjectileFX, STYLES) end)
return ProjectileFX
