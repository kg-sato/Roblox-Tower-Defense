--!nonstrict
-- Procedural characters. Front of every model is -Z. Pivot sits on the ground at the model's centre.
-- "Coolness" grows with tier and rarity: Common tier 1 is plain, high tier / rarity adds glow, orbits, halo, aura.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Models = {}

local BALL, BLOCK, CYL = Enum.PartType.Ball, Enum.PartType.Block, Enum.PartType.Cylinder
local PLASTIC, NEON = Enum.Material.SmoothPlastic, Enum.Material.Neon

local function newModel(name)
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root
	return model
end

-- Builder: m(shape, size, position, color, material, rotation, transparency)
local function builder(model, scale)
	return function(shape, size, pos, color, material, rot, transparency)
		local p
		if shape == "wedge" then
			p = Instance.new("WedgePart")
		else
			p = Instance.new("Part")
			p.Shape = shape
		end
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Material = material or PLASTIC
		p.Color = color
		p.Transparency = transparency or 0
		p.Size = size * scale
		p.CFrame = CFrame.new(pos * scale) * (rot or CFrame.new())
		p.Parent = model
		return p
	end
end

local function eyes(m, y, z, spread, r, angry)
	for _, sx in { -1, 1 } do
		m(BALL, Vector3.one * r * 2, Vector3.new(sx * spread, y, z), Color3.new(1, 1, 1))
		m(BALL, Vector3.one * r * 1.1, Vector3.new(sx * spread, y - r * 0.1, z - r * 0.7), Color3.fromRGB(20, 20, 30))
		if angry then
			m(BLOCK, Vector3.new(r * 2.2, r * 0.45, r * 0.5), Vector3.new(sx * spread, y + r * 1.25, z - r * 0.4), Color3.fromRGB(20, 20, 30), PLASTIC, CFrame.Angles(0, 0, -sx * 0.4))
		end
	end
end

-- Species. Each returns the top height (unscaled) so accessories can sit above it.
local species = {}

-- Fallback look for a character folder with no Model: a round familiar in its own colour.
species.Generic = function(m, cool, color)
	color = color or Color3.fromRGB(200, 200, 220)
	m(BALL, Vector3.new(2.3, 2.2, 2.3), Vector3.new(0, 1.15, 0), color)
	m(BALL, Vector3.new(1.0, 1.0, 1.0), Vector3.new(0, 2.6, -0.2), color:Lerp(Color3.new(1, 1, 1), 0.3), cool >= 1 and NEON or PLASTIC)
	eyes(m, 1.4, -1.0, 0.45, 0.27)
	return 3.1
end

-- ===== Character folders (ReplicatedStorage.Characters/<id>) =====
-- Model: a MeshPart or Model, scaled to the Height attribute (studs), turned by Yaw (degrees),
--        coloured by Tint and Material (optional). Its first pose name must match the pet id for clips.
-- Effects: anything inside is cloned onto the pet's root (ParticleEmitters, Lights, Attachments).
-- Animations: Animation (uploaded id, works live) or KeyframeSequence (Studio only) named Idle / Attack.
local charFolder = ReplicatedStorage:FindFirstChild("Characters")
local function charOf(pet)
	return charFolder and charFolder:FindFirstChild(pet)
end

local function buildFromFolder(pet, model, scale)
	local f = charOf(pet)
	local template = f and f:FindFirstChild("Model")
	if not template then
		return nil
	end
	local height = f:GetAttribute("Height") or 3.5
	local yaw = math.rad(f:GetAttribute("Yaw") or 0)
	local tint = f:GetAttribute("Tint")
	local mat = f:GetAttribute("Material")
	local inst = template:Clone()
	inst.Name = pet
	local function style(p)
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		if tint then
			p.Color = tint
		end
		if mat and Enum.Material[mat] then
			p.Material = Enum.Material[mat]
		end
	end
	if inst:IsA("BasePart") then
		inst.Size = template.Size * (height * scale / template.Size.Y)
		inst.CFrame = CFrame.new(0, inst.Size.Y / 2, 0) * CFrame.Angles(0, yaw, 0)
		style(inst)
	elseif inst:IsA("Model") then
		local _, size = inst:GetBoundingBox()
		inst:ScaleTo(inst:GetScale() * height * scale / math.max(size.Y, 0.01))
		local cf, sz = inst:GetBoundingBox()
		inst:PivotTo(CFrame.Angles(0, yaw, 0) * (inst:GetPivot() - cf.Position) + Vector3.new(0, sz.Y / 2, 0))
		for _, d in inst:GetDescendants() do
			if d:IsA("BasePart") then
				style(d)
			end
		end
	else
		return nil
	end
	inst.Parent = model
	if f:FindFirstChild("Animations") then
		local ctrl = Instance.new("AnimationController")
		Instance.new("Animator").Parent = ctrl
		ctrl.Parent = model
	end
	model:SetAttribute("MeshPet", pet)
	return height
end

local function applyEffects(pet, model)
	local f = charOf(pet)
	local fx = f and f:FindFirstChild("Effects")
	if fx then
		for _, c in fx:GetChildren() do
			c:Clone().Parent = model.Root
		end
	end
end

local clipIds = {}
local tracks = setmetatable({}, { __mode = "k" })
local function clipId(pet, clip)
	local key = pet .. "/" .. clip
	if clipIds[key] == nil then
		clipIds[key] = false
		local f = charOf(pet)
		local a = f and f:FindFirstChild("Animations") and f.Animations:FindFirstChild(clip)
		if a and a:IsA("Animation") and a.AnimationId ~= "" then
			clipIds[key] = a.AnimationId
		elseif a and a:IsA("KeyframeSequence") then
			local ok, id = pcall(function()
				return game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(a)
			end)
			clipIds[key] = ok and id or false
		end
	end
	return clipIds[key]
end

-- Play a clip on a meshed pet (no-op for shape pets or if the clip can't load). Model must be in the workspace.
function Models.playClip(model, clip, speed)
	local pet = model and model:GetAttribute("MeshPet")
	local ctrl = pet and model:FindFirstChildOfClass("AnimationController")
	if not ctrl or not model:IsDescendantOf(workspace) then
		return nil
	end
	local cache = tracks[model]
	if not cache then
		cache = {}
		tracks[model] = cache
	end
	local track = cache[clip]
	if track == nil then
		local id = clipId(pet, clip)
		track = false
		if id then
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			local ok, t = pcall(function()
				return ctrl.Animator:LoadAnimation(anim)
			end)
			track = ok and t or false
		end
		cache[clip] = track
	end
	if track then
		track:Play(clip == "Idle" and 0.3 or 0.08, 1, speed or 1)
	end
	return track or nil
end

-- cool = (tier - 1) + 0.7 * (rarityOrder - 1)
function Models.coolness(pet, tier)
	local order = Config.RARITIES[Config.PETS[pet].rarity].order
	return (tier - 1) + 0.7 * (order - 1)
end

-- Returns model, animate(t) closure (orbit etc. relative to current pivot).
function Models.buildPet(pet, tier)
	local def = Config.PETS[pet]
	local rcolor = Config.RARITIES[def.rarity].color
	local cool = Models.coolness(pet, tier)
	local scale = 0.8 + tier * 0.13
	local model = newModel(def.name)
	local m = builder(model, scale)
	local top = buildFromFolder(pet, model, scale) or (species[pet] or species.Generic)(m, cool, def.color)
	applyEffects(pet, model)
	local anims = {}

	if cool >= 1 then
		m(BALL, Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, top * 0.55, -1.15), rcolor, NEON)
	end
	if cool >= 2 then
		m(CYL, Vector3.new(0.12, 5.6, 5.6), Vector3.new(0, 0.1, 0), rcolor, NEON, CFrame.Angles(0, 0, math.pi / 2), 0.35).Name = "AuraRing"
		local light = Instance.new("PointLight")
		light.Color = rcolor
		light.Range = 10
		light.Brightness = 1.2
		light.Parent = model.Root
	end
	if cool >= 3 then
		local count = cool >= 5 and 4 or 2
		local orbs = {}
		for i = 1, count do
			orbs[i] = m(BALL, Vector3.new(0.55, 0.55, 0.55), Vector3.new(0, 0, 0), rcolor, NEON)
		end
		table.insert(anims, function(t, pivot)
			for i, orb in orbs do
				local a = t * 2.2 + i * (math.pi * 2 / count)
				orb.CFrame = pivot * CFrame.new(math.cos(a) * 2.3 * scale, (top * 0.5 + math.sin(t * 3 + i)) * scale, math.sin(a) * 2.3 * scale)
			end
		end)
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(rcolor)
		pe.Rate = 8
		pe.Lifetime = NumberRange.new(0.8, 1.4)
		pe.Speed = NumberRange.new(2, 4)
		pe.EmissionDirection = Enum.NormalId.Top
		pe.SpreadAngle = Vector2.new(40, 40)
		pe.LightEmission = 0.8
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		pe.Parent = model.Root
	end
	if cool >= 4 then
		local halo = m(CYL, Vector3.new(0.14, 2.6, 2.6), Vector3.new(0, top + 0.9, 0), Color3.fromRGB(255, 225, 110), NEON, CFrame.Angles(0, 0, math.pi / 2), 0.15)
		m(BALL, Vector3.new(6, 6, 6), Vector3.new(0, top * 0.5, 0), rcolor, NEON, nil, 0.88)
		m(CYL, Vector3.new(14, 1.0, 1.0), Vector3.new(0, 7, 0), rcolor, NEON, CFrame.Angles(0, 0, math.pi / 2), 0.82)
		table.insert(anims, function(t, pivot)
			halo.CFrame = pivot * CFrame.new(0, (top + 0.9 + math.sin(t * 2) * 0.15) * scale, 0) * CFrame.Angles(0, t * 1.5, math.pi / 2)
		end)
	end
	return model, anims, cool
end

local enemyBuilders = {}

-- Lampwick Lane roster ([[Research/Backgrounds and Enemies - Mystic Victorian]]): four distinct silhouettes,
-- cold colours (only lamps and pets are warm), one look per enemy layer.
local FABRIC, METAL = Enum.Material.Fabric, Enum.Material.Metal
local COLD_GLOW = Color3.fromRGB(150, 230, 215)

-- Hollow Parishioner (horde): hunched hooded cultist carrying a cold lantern. Read: round hood + small light.
enemyBuilders.Grunt = function(m)
	local robe = Config.ENEMIES.Grunt.color
	local dark = Color3.fromRGB(40, 36, 52)
	m(BALL, Vector3.new(2.4, 2.6, 2.2), Vector3.new(0, 1.25, 0.1), robe, FABRIC)
	m("wedge", Vector3.new(2.3, 1.2, 1.6), Vector3.new(0, 0.6, -0.4), robe, FABRIC, CFrame.Angles(0, math.pi, 0))
	-- hood leaning forward, with a dark empty face
	m(BALL, Vector3.new(1.8, 1.9, 1.9), Vector3.new(0, 2.75, -0.35), dark, FABRIC)
	m(BALL, Vector3.new(1.15, 1.2, 0.5), Vector3.new(0, 2.65, -1.15), Color3.fromRGB(6, 6, 10))
	for _, sx in { -1, 1 } do
		m(BALL, Vector3.new(0.16, 0.16, 0.16), Vector3.new(sx * 0.22, 2.75, -1.36), Color3.fromRGB(210, 230, 255), NEON)
	end
	-- lantern on a short arm
	m(BLOCK, Vector3.new(0.25, 0.9, 0.25), Vector3.new(1.15, 1.7, -0.7), dark)
	m(BLOCK, Vector3.new(0.6, 0.75, 0.6), Vector3.new(1.15, 1.05, -0.7), COLD_GLOW, NEON, nil, 0.15)
	m(BLOCK, Vector3.new(0.75, 0.15, 0.75), Vector3.new(1.15, 1.48, -0.7), dark, METAL)
end

-- Fog Wisp (fast): a legless torn cloak gliding low, trailing mist. Read: long fading tail, no legs.
enemyBuilders.Swift = function(m)
	local c = Config.ENEMIES.Swift.color
	m(BALL, Vector3.new(1.9, 2.1, 2.0), Vector3.new(0, 2.1, -0.4), c, FABRIC, nil, 0.1)
	m(BALL, Vector3.new(1.3, 1.2, 0.4), Vector3.new(0, 2.15, -1.32), Color3.fromRGB(8, 10, 18))
	for _, sx in { -1, 1 } do
		m(BALL, Vector3.new(0.24, 0.24, 0.24), Vector3.new(sx * 0.28, 2.25, -1.52), Color3.fromRGB(190, 245, 255), NEON)
	end
	-- tail: shrinking, fading segments behind and below
	for i = 1, 4 do
		local k = 1 - i * 0.18
		m(BALL, Vector3.new(1.4 * k, 1.2 * k, 1.3), Vector3.new(0, 2.0 - i * 0.32, i * 0.95), c, FABRIC, nil, 0.1 + i * 0.18)
	end
	-- tattered hem: three thin wedges hanging under the hood
	for _, sx in { -0.5, 0, 0.5 } do
		m("wedge", Vector3.new(0.35, 0.9, 0.3), Vector3.new(sx, 1.05, -0.2), c, FABRIC, CFrame.Angles(math.pi, 0, 0), 0.25)
	end
end

-- Brass Sentinel (heavy): boxy steam automaton with a chimney on its back. Read: square shoulders + back stack.
enemyBuilders.Tank = function(m)
	local brass = Config.ENEMIES.Tank.color
	local iron = Color3.fromRGB(44, 42, 50)
	for _, sx in { -1, 1 } do
		m(BLOCK, Vector3.new(1.0, 1.3, 1.2), Vector3.new(sx * 0.8, 0.65, 0), iron, METAL)
	end
	m(BLOCK, Vector3.new(3.0, 2.4, 2.4), Vector3.new(0, 2.5, 0), brass, METAL)
	for _, sx in { -1, 1 } do
		m(BLOCK, Vector3.new(1.1, 0.7, 2.0), Vector3.new(sx * 1.85, 3.5, 0), brass, METAL)
		m(BLOCK, Vector3.new(0.7, 1.7, 0.7), Vector3.new(sx * 1.85, 2.2, 0), iron, METAL)
	end
	m(BLOCK, Vector3.new(3.1, 0.35, 2.5), Vector3.new(0, 1.9, 0), iron, METAL)
	m(BLOCK, Vector3.new(1.3, 0.9, 1.2), Vector3.new(0, 4.1, -0.3), iron, METAL)
	m(BLOCK, Vector3.new(0.9, 0.18, 0.1), Vector3.new(0, 4.15, -0.92), Color3.fromRGB(255, 70, 60), NEON)
	-- chimney on the back
	m(CYL, Vector3.new(2.2, 0.7, 0.7), Vector3.new(0.5, 4.4, 1.3), iron, METAL, CFrame.Angles(0, 0, math.pi / 2))
	m(CYL, Vector3.new(0.25, 0.95, 0.95), Vector3.new(0.5, 5.5, 1.3), iron, METAL, CFrame.Angles(0, 0, math.pi / 2))
end

-- The Unbound (boss): a gentleman mage who lost control. Tall coat and top hat; a crown of too many arms;
-- one huge eye opened in the chest. Read: tall + hat + spiky crown, sickly glow.
enemyBuilders.Boss = function(m)
	local glow = Config.ENEMIES.Boss.color
	local coat = Color3.fromRGB(26, 24, 32)
	local skin = Color3.fromRGB(150, 150, 160)
	m(BLOCK, Vector3.new(3.4, 4.6, 2.6), Vector3.new(0, 3.6, 0), coat, FABRIC)
	m("wedge", Vector3.new(4.4, 1.8, 1.6), Vector3.new(0, 0.9, -0.7), coat, FABRIC, CFrame.Angles(0, math.pi, 0))
	m("wedge", Vector3.new(4.4, 1.8, 1.6), Vector3.new(0, 0.9, 0.7), coat, FABRIC)
	m(BALL, Vector3.new(1.6, 1.8, 1.6), Vector3.new(0, 6.6, 0), skin)
	m(CYL, Vector3.new(0.2, 2.8, 2.8), Vector3.new(0, 7.45, 0), coat, PLASTIC, CFrame.Angles(0, 0, math.pi / 2))
	m(CYL, Vector3.new(2.0, 1.7, 1.7), Vector3.new(0, 8.5, 0), coat, PLASTIC, CFrame.Angles(0, 0, math.pi / 2))
	m(CYL, Vector3.new(0.3, 1.75, 1.75), Vector3.new(0, 7.8, 0), glow, NEON, CFrame.Angles(0, 0, math.pi / 2))
	-- the eye in the chest
	m(BALL, Vector3.new(2.2, 2.2, 0.8), Vector3.new(0, 4.2, -1.3), Color3.fromRGB(235, 240, 220))
	m(BALL, Vector3.new(1.1, 1.1, 0.5), Vector3.new(0, 4.2, -1.62), glow, NEON)
	m(BALL, Vector3.new(0.45, 0.8, 0.3), Vector3.new(0, 4.2, -1.85), Color3.fromRGB(8, 8, 10))
	-- crown of arms fanning up from the shoulders
	for i = -3, 3 do
		local a = i * 0.32
		local len = 3.6 - math.abs(i) * 0.25
		m(BLOCK, Vector3.new(0.35, len, 0.35), Vector3.new(math.sin(a) * (1.3 + len / 2), 5.7 + math.cos(a) * len / 2, 0.4), coat, FABRIC, CFrame.Angles(0, 0, -a))
		m(BALL, Vector3.new(0.45, 0.45, 0.45), Vector3.new(math.sin(a) * (1.3 + len), 5.7 + math.cos(a) * len, 0.4), glow, NEON)
	end
	-- ground sigil
	m(CYL, Vector3.new(0.3, 8.6, 8.6), Vector3.new(0, 0.15, 0), glow, NEON, CFrame.Angles(0, 0, math.pi / 2), 0.6)
end

-- 2026-10-28 art pass: Blender-made enemy meshes (ReplicatedStorage.Enemy<Kind>Mesh, VFX/ASSETS.md) replace the
-- primitive builders when present. Sized to the old model's height, standing on y = 0, facing -Z like the others.
local addWalk -- defined below (Sentinel walk)
local MESH_HEIGHT = { Tank = 10.5 } -- reviewer v7c: "a tiny grey speck at board zoom", 1.4x
local MESH_YAW = { Tank = 0 } -- measured in Play: with no turn the front already faces -Z
local function meshEnemy(model, kind)
	local art = game:GetService("ReplicatedStorage"):FindFirstChild("Enemy" .. kind .. "Mesh")
	if not (art and MESH_HEIGHT[kind]) then return false end
	local m = art:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("PackageLink") then d:Destroy() end
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.CastShadow = true, false, false, false, true
			if d.Parent and d.Parent.Name == "Eye" then -- glowing eye: Neon ignores SurfaceAppearance, so drop it
				local sa = d:FindFirstChildOfClass("SurfaceAppearance")
				if sa then sa:Destroy() end
				d.Material, d.Color = NEON, Color3.fromRGB(255, 70, 40)
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 80, 50), 5, 1.3 -- v7c: brighter; still small: 9 studs washed the whole body red (reviewer v2)
				l.Parent = d
			end
		end
	end
	local _, s0 = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * MESH_HEIGHT[kind] / s0.Y)
	m:PivotTo(CFrame.Angles(0, MESH_YAW[kind] or 0, 0))
	local cf, s1 = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(-cf.Position.X, s1.Y / 2 - cf.Position.Y, -cf.Position.Z))
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then d.Parent = model end -- flat, like the primitive builders, so the movers can pivot it
	end
	if kind == "Tank" then -- steam from the back chimney (reviewer: no secondary motion). No outline or fill light per
		-- enemy: Roblox draws at most 31 Highlights and lights cost phones; the brightened texture does the job.
		local cf2, s2 = model:GetBoundingBox()
		local puff = Instance.new("Part")
		puff.Name, puff.Transparency, puff.Size, puff.Anchored, puff.CanCollide, puff.CanQuery, puff.CanTouch = "SteamPoint", 1, Vector3.one * 0.2, true, false, false, false
		puff.CFrame = CFrame.new(cf2.Position + Vector3.new(s2.X * 0.12, s2.Y / 2 - 0.2, s2.Z * 0.3))
		puff.Parent = model
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(200, 195, 190))
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.4) })
		pe.Lifetime, pe.Rate, pe.Speed = NumberRange.new(1.2, 1.8), 6, NumberRange.new(2, 3)
		pe.EmissionDirection, pe.SpreadAngle, pe.LightInfluence = Enum.NormalId.Top, Vector2.new(12, 12), 0.6
		pe.Parent = puff
	end
	if model:FindFirstChild("LegL_Upper") then -- after the steam point, so it rides the body bob too
		addWalk(model)
	end
	return true
end

-- Sentinel walk (v10, the user: "split + walk"). The mesh arrives as limb parts (Blender/sentinel_hs.py). Every frame
-- each part is placed from the model pivot; the movers PivotTo the model absolutely, so nothing accumulates. The gait
-- advances with the distance walked, so it stops when the enemy stops: heavy stomp (the body drops at each footfall),
-- a roll onto the planted leg, arms swinging against the legs, a dust puff under the landing boot.
local RunService = game:GetService("RunService")
local walkers = {}
local STRIDE = 7 -- studs per full cycle (two steps) at the 10.5-stud Sentinel
local TAU = math.pi * 2
local walkConn
local function stepWalkers(dt)
	for model, w in walkers do
		if not model.Parent then continue end
		local pivot = model:GetPivot()
		local d = Vector3.new(pivot.X - w.last.X, 0, pivot.Z - w.last.Z).Magnitude
		w.last = pivot.Position
		if d > 3 then d = 0 end -- spawn or teleport, not a step
		local before = math.cos(w.phase)
		w.phase += d / STRIDE * TAU
		w.amp += ((d > 0.002 and 1 or 0) - w.amp) * math.min(1, dt * 5)
		local a, ph = w.amp, w.phase
		if a > 0.3 and math.sign(math.cos(ph)) ~= math.sign(before) then -- a boot lands
			local dust = w.dust[math.cos(ph) < 0 and "L" or "R"]
			if dust then dust:Emit(7) end
		end
		local body = pivot * CFrame.new(0, -0.35 * a * math.abs(math.sin(ph)) ^ 3, 0) * CFrame.Angles(0, 0, 0.05 * a * math.sin(ph))
		for p, r in w.rest do
			local limb = w.limb[p]
			if not limb then
				p.CFrame = body * r
				continue
			end
			local sideph = ph + limb.offset
			local swing = (limb.arm and -0.35 or 0.45) * a * math.sin(sideph)
			local cf = body * CFrame.new(limb.top) * CFrame.Angles(swing, 0, 0) * CFrame.new(-limb.top)
			if limb.mid then
				local bend = limb.arm and (0.2 + 0.2 * a * math.max(0, -math.sin(sideph))) or (-0.7 * a * math.max(0, math.cos(sideph)))
				cf = cf * CFrame.new(limb.mid) * CFrame.Angles(bend, 0, 0) * CFrame.new(-limb.mid)
			end
			p.CFrame = cf * r
		end
	end
end

function addWalk(model)
	local piv = model:GetPivot()
	local w = { last = piv.Position, phase = 0, amp = 0, rest = {}, limb = {}, dust = {} }
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then w.rest[p] = piv:ToObjectSpace(p.CFrame) end
	end
	local function topOf(name) -- joint = top centre of the part, in pivot space (the meshes import axis-aligned)
		local p = model:FindFirstChild(name)
		return p and piv:PointToObjectSpace(p.Position + Vector3.new(0, p.Size.Y / 2, 0))
	end
	for _, side in { "L", "R" } do
		local offset = side == "L" and 0 or math.pi
		for _, kind in { "Leg", "Arm" } do
			local up, low = model:FindFirstChild(kind .. side .. "_Upper"), model:FindFirstChild(kind .. side .. "_Lower")
			if not (up and low) then continue end
			local top, mid = topOf(up.Name), topOf(low.Name)
			w.limb[up] = { top = top, offset = offset, arm = kind == "Arm" }
			w.limb[low] = { top = top, mid = mid, offset = offset, arm = kind == "Arm" }
			if kind == "Leg" then
				local at = Instance.new("Attachment")
				at.Position = Vector3.new(0, -low.Size.Y / 2, 0)
				at.Parent = low
				local pe = Instance.new("ParticleEmitter")
				pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
				pe.Color = ColorSequence.new(Color3.fromRGB(150, 135, 115))
				pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
				pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 2.6) })
				pe.Lifetime, pe.Rate, pe.Speed = NumberRange.new(0.5, 0.8), 0, NumberRange.new(3, 5)
				pe.SpreadAngle, pe.EmissionDirection, pe.Drag = Vector2.new(80, 80), Enum.NormalId.Top, 6
				pe.Parent = at
				w.dust[side] = pe
			end
		end
	end
	walkers[model] = w
	model.Destroying:Connect(function() walkers[model] = nil end)
	walkConn = walkConn or RunService.RenderStepped:Connect(stepWalkers)
end

function Models.buildEnemy(kind)
	local model = newModel(kind)
	if meshEnemy(model, kind) then
		return model
	end
	-- 1.3x: the dusk street is darker, so enemies need more screen size to read (visual only)
	enemyBuilders[kind](builder(model, 1.3))
	return model
end

-- Sealed summoning card for the roll (replaces the egg; mystic Victorian theme). Returns model, edge.
-- The edge is the rarity tell: the reveal warms it toward the rarity colour and makes it glow for Epic+.
function Models.buildCard()
	local model = newModel("SummonCard")
	local m = builder(model, 1)
	local violet = Color3.fromRGB(42, 26, 74)
	local gold = Color3.fromRGB(232, 200, 130)
	-- edge: a slightly larger plate behind the face shows as a border on both sides
	local edge = m(BLOCK, Vector3.new(2.8, 3.95, 0.12), Vector3.new(0, 1.98, 0), gold, Enum.Material.Metal)
	m(BLOCK, Vector3.new(2.5, 3.65, 0.2), Vector3.new(0, 1.98, 0), violet)
	for _, side in { -1, 1 } do
		local z = side * 0.11
		local flip = side > 0 and 0 or math.pi
		-- eye sigil: ring, iris, pupil
		m(CYL, Vector3.new(0.02, 1.5, 1.5), Vector3.new(0, 2.0, z), gold, NEON, CFrame.Angles(0, math.pi / 2 + flip, 0), 0.1)
		m(CYL, Vector3.new(0.03, 1.2, 1.2), Vector3.new(0, 2.0, z + side * 0.005), violet, PLASTIC, CFrame.Angles(0, math.pi / 2 + flip, 0))
		m(CYL, Vector3.new(0.04, 0.55, 0.55), Vector3.new(0, 2.0, z + side * 0.01), Color3.fromRGB(255, 236, 190), NEON, CFrame.Angles(0, math.pi / 2 + flip, 0))
		-- rays above and below the eye, and diamond pips in the corners
		for _, dy in { -1, 1 } do
			m(BLOCK, Vector3.new(0.08, 0.5, 0.02), Vector3.new(0, 2.0 + dy * 1.05, z), gold, NEON, nil, 0.2)
			for _, dx in { -1, 1 } do
				m(BLOCK, Vector3.new(0.22, 0.22, 0.02), Vector3.new(dx * 0.95, 2.0 + dy * 1.5, z), gold, NEON, CFrame.Angles(0, 0, math.pi / 4), 0.2)
			end
		end
	end
	return model, edge
end


-- The Orrery (our summon, unique to this game): four brass gimbal rings around a dark glass core.
-- Rings are built facing the camera (XY plane) around the origin; the reveal spins and locks them.
-- Returns model, rings { Model }, core (glass), fill (neon inner light, scale it to show charge).
function Models.buildOrrery()
	local model = newModel("Orrery")
	local brass = Color3.fromRGB(196, 150, 78)
	local rings = {}
	for i, r in { 3.4, 2.85, 2.3, 1.8 } do
		local ring = Instance.new("Model")
		ring.Name = "Ring" .. i
		local segs = 40
		local segLen = 2 * math.pi * r / segs * 1.08
		for s = 1, segs do
			local a = s / segs * math.pi * 2
			local p = Instance.new("Part")
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.Material = Enum.Material.Metal
			p.Color = brass
			p.Size = Vector3.new(segLen, 0.16, 0.16)
			p.CFrame = CFrame.new(math.cos(a) * r, math.sin(a) * r, 0) * CFrame.Angles(0, 0, a + math.pi / 2)
			p.Parent = ring
		end
		-- a bead (planet) on each ring and a tick at the top, so the spin reads
		local bead = Instance.new("Part")
		bead.Shape = Enum.PartType.Ball
		bead.Anchored, bead.CanCollide, bead.CanQuery, bead.CastShadow = true, false, false, false
		bead.Material = Enum.Material.Metal
		bead.Color = brass:Lerp(Color3.new(1, 1, 1), 0.2)
		bead.Size = Vector3.one * (0.42 - i * 0.04)
		bead.CFrame = CFrame.new(math.cos(i * 1.9) * r, math.sin(i * 1.9) * r, 0)
		bead.Name = "Bead"
		bead.Parent = ring
		ring.WorldPivot = CFrame.new()
		ring.Parent = model
		rings[i] = ring
	end
	local core = Instance.new("Part")
	core.Shape = Enum.PartType.Ball
	core.Anchored, core.CanCollide, core.CanQuery, core.CastShadow = true, false, false, false
	core.Material = Enum.Material.Glass
	core.Color = Color3.fromRGB(40, 30, 70)
	core.Transparency = 0.25
	core.Size = Vector3.one * 2.2
	core.Name = "Core"
	core.Parent = model
	local fill = Instance.new("Part")
	fill.Shape = Enum.PartType.Ball
	fill.Anchored, fill.CanCollide, fill.CanQuery, fill.CastShadow = true, false, false, false
	fill.Material = Enum.Material.Neon
	fill.Color = Color3.fromRGB(230, 225, 255)
	fill.Size = Vector3.one * 0.2
	fill.Name = "Fill"
	fill.Parent = model
	return model, rings, core, fill
end

return Models
