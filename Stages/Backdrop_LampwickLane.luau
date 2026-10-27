--!nocheck
-- Lampwick Lane (stage set 1): a gaslit Victorian street at dusk around the board.
-- Installed as ServerScriptService.Backdrop. Visual only: nothing here is gameplay.
-- Plan: [[Research/3D and Art/Backgrounds and Enemies - Mystic Victorian]] (three rings: calm board, warm-lit props, dark skyline in fog).
-- Rules: the path stays the lightest value on screen; only lamps and windows are warm; far things are dark and fogged.

local Lighting = game:GetService("Lighting")

local old = workspace:FindFirstChild("Backdrop")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "Backdrop"

local rng = Random.new(1887)

local SOOT = Color3.fromRGB(38, 36, 46) -- far buildings
local BRICK = Color3.fromRGB(70, 52, 50) -- near walls
local ROOF = Color3.fromRGB(30, 30, 40)
local IRON = Color3.fromRGB(26, 26, 32)
local WARM = Color3.fromRGB(255, 186, 110)
local WOOD = Color3.fromRGB(84, 62, 46)

local function part(parent, size, cf, color, material, kind)
	local p
	if kind == "wedge" then
		p = Instance.new("WedgePart")
	else
		p = Instance.new("Part")
		if kind then
			p.Shape = kind
		end
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function folder(name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = root
	return f
end

-- ===== Light and fog: overcast dusk, grey-blue haze, violet away from the sun =====
Lighting.ClockTime = 17.9
Lighting.Brightness = 1.6
Lighting.Ambient = Color3.fromRGB(64, 66, 84)
Lighting.OutdoorAmbient = Color3.fromRGB(96, 98, 118)
Lighting.ColorShift_Top = Color3.fromRGB(255, 214, 170)
Lighting.EnvironmentDiffuseScale = 0.4
Lighting.EnvironmentSpecularScale = 0.6
local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
atmo.Density = 0.36
atmo.Offset = 0.22
atmo.Haze = 2.2
atmo.Color = Color3.fromRGB(150, 160, 182)
atmo.Decay = Color3.fromRGB(72, 54, 104)
atmo.Glare = 0.25
local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
if bloom then
	bloom.Intensity = 0.7
	bloom.Size = 28
	bloom.Threshold = 0.92
end
local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
if rays then
	rays.Intensity = 0.04
end
local grade = Lighting:FindFirstChild("StageGrade") or Instance.new("ColorCorrectionEffect")
grade.Name = "StageGrade"
grade.Saturation = -0.18
grade.Contrast = 0.08
grade.TintColor = Color3.fromRGB(236, 238, 255)
grade.Parent = Lighting

-- ===== Far ring: rowhouses, spires, a leaning clocktower, factory stacks =====
local far = folder("Skyline")
local function window(parent, cf, lit)
	local w = part(parent, Vector3.new(1.6, 2.4, 0.2), cf, lit and WARM or Color3.fromRGB(20, 20, 28), lit and Enum.Material.Neon or Enum.Material.SmoothPlastic)
	if lit then
		w.Transparency = 0.1
	end
	return w
end

local function house(x, z, w, h, facing)
	local m = Instance.new("Model")
	m.Name = "House"
	local base = CFrame.new(x, 0, z) * CFrame.Angles(0, facing, 0)
	local body = part(m, Vector3.new(w, h, 12), base * CFrame.new(0, h / 2, 0), rng:NextNumber() < 0.5 and SOOT or BRICK, Enum.Material.Brick)
	body.CastShadow = false
	-- gable roof: two wedges
	local rh = w * 0.45
	part(m, Vector3.new(12, rh, w / 2), base * CFrame.new(-w / 4, h + rh / 2, 0) * CFrame.Angles(0, math.rad(90), 0), ROOF, Enum.Material.Slate, "wedge")
	part(m, Vector3.new(12, rh, w / 2), base * CFrame.new(w / 4, h + rh / 2, 0) * CFrame.Angles(0, math.rad(-90), 0), ROOF, Enum.Material.Slate, "wedge")
	-- chimney with a little steam
	local ch = part(m, Vector3.new(1.6, 5, 1.6), base * CFrame.new(w * 0.3, h + rh * 0.6 + 1.5, 2), SOOT, Enum.Material.Brick)
	if rng:NextNumber() < 0.35 then
		local a = Instance.new("Attachment", ch)
		a.Position = Vector3.new(0, 2.6, 0)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(150, 150, 165))
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) })
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 6) })
		pe.Lifetime = NumberRange.new(4, 6)
		pe.Rate = 1.5
		pe.Speed = NumberRange.new(1.5, 2.5)
		pe.SpreadAngle = Vector2.new(12, 12)
		pe.Acceleration = Vector3.new(1.2, 0.3, 0)
		pe.Parent = a
	end
	-- windows on the face toward the board (local -Z after facing)
	local cols = math.max(1, math.floor(w / 4))
	local rows = math.max(1, math.floor((h - 3) / 5))
	for r = 1, rows do
		for c = 1, cols do
			if rng:NextNumber() < 0.75 then
				local wx = -w / 2 + (c - 0.5) * (w / cols)
				window(m, base * CFrame.new(wx, 2 + r * 5 - 1.5, -6.1), rng:NextNumber() < 0.28)
			end
		end
	end
	m.Parent = far
	return m
end

-- back row (behind the board, facing it) and a second taller row further back
for x = -96, 96, 15 do
	house(x + rng:NextNumber(-2, 2), -44 - rng:NextNumber(0, 6), rng:NextInteger(11, 15), rng:NextInteger(16, 30), 0)
end
for x = -110, 110, 18 do
	house(x + rng:NextNumber(-3, 3), -66 - rng:NextNumber(0, 8), rng:NextInteger(13, 17), rng:NextInteger(26, 40), 0)
end
-- side rows, turned to face the board
for z = -36, 28, 14 do
	house(-70 - rng:NextNumber(0, 5), z, rng:NextInteger(11, 14), rng:NextInteger(12, 22), math.rad(-90))
	house(66 + rng:NextNumber(0, 5), z, rng:NextInteger(11, 14), rng:NextInteger(12, 22), math.rad(90))
end

-- cathedral spires and the leaning clocktower (the first "wrong" note: it leans more the higher it goes)
local function spire(x, z, h)
	part(far, Vector3.new(6, h, 6), CFrame.new(x, h / 2, z), SOOT, Enum.Material.Slate)
	local cap = 16
	for i = 0, 3 do
		part(far, Vector3.new(6, cap, 3), CFrame.new(x, h + cap / 2, z) * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, 0, -1.5), ROOF, Enum.Material.Slate, "wedge")
	end
end
spire(-58, -84, 52)
spire(46, -90, 60)
do
	local x, z = -6, -92
	local lean = 0
	local y = 0
	for i = 1, 5 do
		local h = 12
		lean += math.rad(2.2) * i
		local seg = part(far, Vector3.new(10 - i * 0.6, h, 10 - i * 0.6), CFrame.new(x + y * math.sin(lean) * 0.35, y + h / 2, z) * CFrame.Angles(0, 0, -lean), SOOT, Enum.Material.Brick)
		seg.CastShadow = false
		if i == 4 then
			local face = part(far, Vector3.new(0.4, 6, 6), seg.CFrame * CFrame.new(0, 0, -(5.2 - i * 0.3)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(230, 220, 180), Enum.Material.Neon, Enum.PartType.Cylinder)
			face.Transparency = 0.15
		end
		y += h
	end
end
-- factory stacks on the right with heavier smoke
for i, x in { 86, 98 } do
	local stack = part(far, Vector3.new(46 + i * 6, 4, 4), CFrame.new(x, 23 + i * 3, -58) * CFrame.Angles(0, 0, math.rad(90)), BRICK, Enum.Material.Brick, Enum.PartType.Cylinder)
	local a = Instance.new("Attachment", stack)
	a.Position = Vector3.new((46 + i * 6) / 2, 0, 0)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(110, 108, 124))
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 16) })
	pe.Lifetime = NumberRange.new(6, 9)
	pe.Rate = 3
	pe.Speed = NumberRange.new(3, 5)
	pe.EmissionDirection = Enum.NormalId.Right
	pe.Acceleration = Vector3.new(2, 0, 0)
	pe.Parent = a
end

-- ===== Mid ring: iron fence, gas lamps, street props =====
local mid = folder("Street")
local X0, X1, Z0, Z1 = -54, 50, -30, 32
local function post(x, z)
	part(mid, Vector3.new(0.5, 4, 0.5), CFrame.new(x, 2, z), IRON, Enum.Material.Metal)
	part(mid, Vector3.new(0.9, 0.9, 0.9), CFrame.new(x, 4.3, z) * CFrame.Angles(0, math.rad(45), math.rad(45)), IRON, Enum.Material.Metal)
end
local function rail(a, b)
	local midp = (a + b) / 2
	local len = (b - a).Magnitude
	for _, y in { 1.2, 3.4 } do
		part(mid, Vector3.new(0.25, 0.25, len), CFrame.lookAt(Vector3.new(midp.X, y, midp.Z), Vector3.new(b.X, y, b.Z)), IRON, Enum.Material.Metal)
	end
end
local corners = { Vector3.new(X0, 0, Z0), Vector3.new(X1, 0, Z0), Vector3.new(X1, 0, Z1), Vector3.new(X0, 0, Z1) }
for i = 1, 4 do
	local a, b = corners[i], corners[i % 4 + 1]
	rail(a, b)
	local n = math.floor((b - a).Magnitude / 8)
	for k = 0, n - 1 do
		local p = a:Lerp(b, k / n)
		post(p.X, p.Z)
	end
end

local function lamp(x, z)
	-- cylinders run along their X axis, so the pole is 11 long on X and turned upright
	part(mid, Vector3.new(11, 0.6, 0.6), CFrame.new(x, 5.5, z) * CFrame.Angles(0, 0, math.rad(90)), IRON, Enum.Material.Metal, Enum.PartType.Cylinder)
	part(mid, Vector3.new(1.4, 0.6, 1.4), CFrame.new(x, 0.3, z), IRON, Enum.Material.Metal)
	local glass = part(mid, Vector3.new(1.3, 1.8, 1.3), CFrame.new(x, 11.6, z), WARM, Enum.Material.Neon)
	glass.Transparency = 0.15
	part(mid, Vector3.new(1.9, 0.5, 1.9), CFrame.new(x, 12.7, z), IRON, Enum.Material.Metal)
	local light = Instance.new("PointLight")
	light.Color = WARM
	light.Range = 22
	light.Brightness = 1.6
	light.Shadows = true
	light.Parent = glass
end
for _, p in { { X0, Z0 }, { X1, Z0 }, { X0, Z1 }, { X1, Z1 }, { -18, Z0 }, { 16, Z0 }, { -18, Z1 }, { 16, Z1 }, { X0, 1 }, { X1, 1 } } do
	lamp(p[1], p[2])
end

local function crate(x, z, s, rot)
	part(mid, Vector3.new(s, s, s), CFrame.new(x, s / 2, z) * CFrame.Angles(0, rot, 0), WOOD, Enum.Material.WoodPlanks)
end
local function barrel(x, z)
	part(mid, Vector3.new(3, 2.2, 2.2), CFrame.new(x, 1.5, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 50, 38), Enum.Material.Wood, Enum.PartType.Cylinder)
end
local function carriage(x, z, rot)
	local base = CFrame.new(x, 0, z) * CFrame.Angles(0, rot, 0)
	part(mid, Vector3.new(5, 4, 8), base * CFrame.new(0, 3.6, 0), Color3.fromRGB(28, 24, 30), Enum.Material.Wood)
	part(mid, Vector3.new(5.6, 0.5, 8.6), base * CFrame.new(0, 5.8, 0), Color3.fromRGB(20, 18, 22), Enum.Material.Wood)
	for _, w in { { -2.8, -2.8 }, { 2.8, -2.8 }, { -2.8, 2.8 }, { 2.8, 2.8 } } do
		part(mid, Vector3.new(0.4, 3, 3), base * CFrame.new(w[1], 1.5, w[2]), Color3.fromRGB(60, 44, 30), Enum.Material.Wood, Enum.PartType.Cylinder)
	end
	local win = part(mid, Vector3.new(5.1, 1.4, 2), base * CFrame.new(0, 4.2, 0), WARM, Enum.Material.Neon)
	win.Transparency = 0.55
end
crate(-60, -36, 3, 0.2)
crate(-61, -32, 2.4, 0.7)
crate(56, -37, 3, -0.3)
barrel(58, -33)
barrel(-60, 38)
crate(56, 38, 2.6, 0.4)
carriage(-62, 12, math.rad(8))
carriage(60, -8, math.rad(-12))

-- ===== Drifting fog sheets along the board edges =====
local fog = folder("Fog")
local function fogBank(x, z, w, d)
	local p = part(fog, Vector3.new(w, 1, d), CFrame.new(x, 1.5, z), Color3.new(1, 1, 1))
	p.Transparency = 1
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(170, 176, 196))
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.86), NumberSequenceKeypoint.new(0.7, 0.88), NumberSequenceKeypoint.new(1, 1) })
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 14), NumberSequenceKeypoint.new(1, 26) })
	pe.Lifetime = NumberRange.new(10, 14)
	pe.Rate = 1.2
	pe.Speed = NumberRange.new(0.6, 1.2)
	pe.SpreadAngle = Vector2.new(180, 0)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-6, 6)
	pe.LightInfluence = 1
	pe.Parent = p
end
fogBank(-4, -40, 140, 10)
fogBank(-66, 0, 10, 70)
fogBank(62, 0, 10, 70)
fogBank(-4, 42, 140, 8)

root.Parent = workspace
