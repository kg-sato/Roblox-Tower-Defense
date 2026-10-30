--!nocheck
-- Above the Grey Veil (stage set 5, stages 21-25): the roof of the city above the lifted fog. Deep blue and white on black, the Great Clock mounted behind the
-- board (its back, with the apprentice's lamp inside), broken bridge arches, rune circles, two mirror-cat statues, far-off eyes and star dust.
-- Lamp orange appears only on the clock's lamp (and the player's lantern), so the lantern is the warmest thing on screen.
-- Installed as ServerScriptService.BackdropVeil; builds workspace.StageSets.AboveTheGreyVeil. Visual only. Plan: Roblox Dev/Design/Stage Set 5 Plan.md.
-- Same rings as the other sets: calm board, a cool-lit edge ring the board camera sees, far props beyond.

local sets = workspace:FindFirstChild("StageSets") or Instance.new("Folder")
sets.Name = "StageSets"
sets.Parent = workspace
local old = sets:FindFirstChild("AboveTheGreyVeil")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "AboveTheGreyVeil"

local FLOOR = Color3.fromRGB(22, 28, 56)
local NIGHT = Color3.fromRGB(14, 18, 38)
local BLUE = Color3.fromRGB(60, 84, 160)
local PALE = Color3.fromRGB(216, 226, 250)
local BRASS = Color3.fromRGB(104, 92, 70)
local STAR = Color3.fromRGB(170, 196, 255)
local LAMP = Color3.fromRGB(255, 170, 70)

local function part(size, cf, color, material, shape)
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Size, p.CFrame, p.Color = size, cf, color
	p.Material = material or Enum.Material.Slate
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = root
	return p
end
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

-- the roof floor under the board, and a cloud floor far below instead of fog
part(Vector3.new(230, 1, 110), CFrame.new(0, -0.62, 0), FLOOR, Enum.Material.Slate)
local cloud = part(Vector3.new(900, 2, 900), CFrame.new(0, -46, 0), Color3.fromRGB(70, 86, 140), Enum.Material.SmoothPlastic)
cloud.Transparency = 0.35

-- the Great Clock from behind: a brass back plate, 12 radial beams, a toothed ring, a hub with the apprentice's lamp inside
local CX, CY, CZ, R = 0, 36, -84, 28
part(Vector3.new(2, R * 2, R * 2), CFrame.new(CX, CY, CZ) * CFrame.Angles(0, math.pi / 2, 0), NIGHT, Enum.Material.Metal, CYL)
for k = 0, 11 do
	local a = math.rad(30 * k)
	part(Vector3.new(1.4, R * 0.86, 1.4), CFrame.new(CX + math.sin(a) * R * 0.45, CY + math.cos(a) * R * 0.45, CZ + 1.4) * CFrame.Angles(0, 0, -a), BRASS, Enum.Material.Metal)
end
for k = 0, 23 do
	local a = math.rad(15 * k)
	part(Vector3.new(2.2, 3, 1.8), CFrame.new(CX + math.sin(a) * R, CY + math.cos(a) * R, CZ + 1.2) * CFrame.Angles(0, 0, -a), BRASS, Enum.Material.Metal)
end
part(Vector3.new(1.6, R * 1.1, R * 1.1), CFrame.new(CX, CY, CZ + 1) * CFrame.Angles(0, math.pi / 2, 0), BLUE, Enum.Material.Metal, CYL)
part(Vector3.new(2, 11, 11), CFrame.new(CX, CY, CZ + 2.6) * CFrame.Angles(0, math.pi / 2, 0), BRASS, Enum.Material.Metal, CYL)
local lamp = part(Vector3.new(5, 5, 5), CFrame.new(CX, CY, CZ + 4.2), LAMP, Enum.Material.Neon, BALL)
lamp.Name = "ApprenticeLamp"
local lampLight = Instance.new("PointLight")
lampLight.Color, lampLight.Range, lampLight.Brightness, lampLight.Shadows = LAMP, 16, 1.2, false
lampLight.Parent = lamp
local glass = part(Vector3.new(7, 7, 7), CFrame.new(CX, CY, CZ + 4.2), PALE, Enum.Material.Glass, BALL)
glass.Transparency = 0.6

-- broken bridge arches along the back (some lintels fallen)
for i, x in { -70, -36, 0, 36, 70 } do
	for _, dx in { -6, 6 } do
		part(Vector3.new(3, 16, 3), CFrame.new(x + dx, 8, -52), PALE, Enum.Material.Marble)
	end
	if i % 2 == 1 then
		part(Vector3.new(16, 2.4, 3), CFrame.new(x, 17, -52), PALE, Enum.Material.Marble)
	else
		part(Vector3.new(8, 2.4, 3), CFrame.new(x - 4, 17, -52), PALE, Enum.Material.Marble)
		part(Vector3.new(7, 2.4, 3), CFrame.new(x + 7, 1.2, -49) * CFrame.Angles(0, math.rad(20), math.rad(8)), PALE, Enum.Material.Marble)
	end
end

-- a stair on the left side that climbs and a brass rail beside it
for s = 0, 7 do
	part(Vector3.new(6, 1, 10), CFrame.new(-92 - s * 5, s + 0.5, -4), PALE, Enum.Material.Marble)
	part(Vector3.new(0.4, 3, 0.4), CFrame.new(-92 - s * 5, s + 2.2, 1.4), BRASS, Enum.Material.Metal)
end

-- rune circles on the ground: a glowing ring (outer disc, inner disc in the floor colour, a small glyph ring)
local function rune(x, z, d)
	local flat = CFrame.new(x, 0.03, z) * CFrame.Angles(0, 0, math.pi / 2)
	local ring = part(Vector3.new(0.1, d, d), flat, STAR, Enum.Material.Neon, CYL)
	ring.Transparency = 0.35
	part(Vector3.new(0.12, d - 1.4, d - 1.4), CFrame.new(x, 0.05, z) * CFrame.Angles(0, 0, math.pi / 2), FLOOR, Enum.Material.Slate, CYL)
	local glyph = part(Vector3.new(0.14, d * 0.45, d * 0.45), CFrame.new(x, 0.07, z) * CFrame.Angles(0, 0, math.pi / 2), STAR, Enum.Material.Neon, CYL)
	glyph.Transparency = 0.55
	part(Vector3.new(0.16, d * 0.45 - 1, d * 0.45 - 1), CFrame.new(x, 0.09, z) * CFrame.Angles(0, 0, math.pi / 2), FLOOR, Enum.Material.Slate, CYL)
end
rune(-74, 12, 16)
rune(72, -8, 16)
rune(6, -46, 14)
rune(-30, 46, 12)

-- two mirror-cat statues at the back corners
local function cat(x, z, face)
	local base = CFrame.new(x, 0, z) * CFrame.Angles(0, face, 0)
	part(Vector3.new(6, 2, 6), base * CFrame.new(0, 1, 0), PALE, Enum.Material.Marble)
	part(Vector3.new(3, 5, 4.4), base * CFrame.new(0, 4.5, 0), STAR, Enum.Material.Glass)
	part(Vector3.new(2.6, 2.6, 2.6), base * CFrame.new(0, 8.2, -1), STAR, Enum.Material.Glass)
	for _, dx in { -0.9, 0.9 } do
		part(Vector3.new(0.9, 1.6, 0.9), base * CFrame.new(dx, 10, -1), STAR, Enum.Material.Glass)
	end
	part(Vector3.new(0.7, 0.7, 4.5), base * CFrame.new(0, 3, 4) * CFrame.Angles(math.rad(-25), 0, 0), STAR, Enum.Material.Glass)
end
cat(-62, -34, math.rad(15))
cat(58, -36, math.rad(-15))

-- three far eyes in the dark that watch the board
for _, e in { { -64, 30, -118 }, { 8, 52, -126 }, { 70, 26, -112 } } do
	local eye = part(Vector3.new(12, 7, 2), CFrame.new(e[1], e[2], e[3]), PALE, Enum.Material.Neon, BALL)
	eye.Transparency = 0.15
	part(Vector3.new(3.4, 3.4, 1), CFrame.new(e[1], e[2], e[3] + 0.9), NIGHT, Enum.Material.SmoothPlastic, BALL)
end

-- star dust drifting over the board
local dust = part(Vector3.new(200, 1, 100), CFrame.new(0, 24, 0), NIGHT, Enum.Material.SmoothPlastic)
dust.Transparency = 1
local sparks = Instance.new("ParticleEmitter")
sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
sparks.Color = ColorSequence.new(STAR)
sparks.LightEmission = 1
sparks.Size = NumberSequence.new(0.35)
sparks.Lifetime = NumberRange.new(6, 10)
sparks.Rate = 14
sparks.Speed = NumberRange.new(0.5, 1.5)
sparks.SpreadAngle = Vector2.new(180, 180)
sparks.Parent = dust

-- the edge ring the board camera sees: a kerb and cool star-blue lamps (no orange here)
local X0, X1, Z0, Z1 = -54, 50, -30, 32
for _, c in { { X0, Z0, X1, Z0 }, { X0, Z1, X1, Z1 }, { X0, Z0, X0, Z1 }, { X1, Z0, X1, Z1 } } do
	local a, b = Vector3.new(c[1], 0, c[2]), Vector3.new(c[3], 0, c[4])
	local mid, len = (a + b) / 2, (b - a).Magnitude
	part(Vector3.new(1.2, 0.9, len), CFrame.lookAt(mid + Vector3.new(0, 0.45, 0), b + Vector3.new(0, 0.45, 0)), NIGHT, Enum.Material.Marble)
end
local function lampPost(x, z)
	part(Vector3.new(0.5, 4.5, 0.5), CFrame.new(x, 2.25, z), BRASS, Enum.Material.Metal)
	local glow = part(Vector3.new(0.6, 0.6, 0.6), CFrame.new(x, 4.8, z), STAR, Enum.Material.Neon)
	glow.Transparency = 0.2
	local light = Instance.new("PointLight")
	light.Name = "LampLight"
	light.Color, light.Range, light.Brightness, light.Shadows = STAR, 16, 1.2, true
	light.Parent = glow
end
for _, p in { { X0, Z0 }, { X1, Z0 }, { X0, Z1 }, { X1, Z1 }, { -18, Z0 }, { 16, Z0 }, { -18, Z1 }, { 16, Z1 } } do
	lampPost(p[1], p[2])
end
-- T162: three landmarks the board camera can see (named Landmark_*, each a Model with its own light), placed at the back-left,
-- back-right and right edge of the camera view (the board camera looks steeply down, so they are small: 11 to 15 studs tall). Visual only.
local function LP(m, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Size, p.CFrame, p.Color = size, cf, color
	p.Material = mat or Enum.Material.Metal
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end
local function LGLOW(p, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Name, l.Color, l.Range, l.Brightness = "LandmarkLight", color, range, brightness or 2
	l.Parent = p
end
local UP = CFrame.Angles(0, 0, math.rad(90)) -- stands a cylinder upright (its axis is X)
local FACE = CFrame.Angles(0, math.rad(90), 0) -- turns a cylinder's axis to Z so its flat face looks at the camera
local function landmark(name, x, z, h, build) -- built at its own size, then scaled to height h and stood on the floor at x, z
	local m = Instance.new("Model")
	m.Name = "Landmark_" .. name
	build(m, x, z)
	local _, sz = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * h / sz.Y)
	local cf2, sz2 = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(x - cf2.Position.X, -(cf2.Position.Y - sz2.Y / 2), z - cf2.Position.Z))
	m.Parent = root
end
local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
landmark("BrokenArch", -24, -35, 7, function(m, x, z)
	LP(m, Vector3.new(4, 30, 4), CFrame.new(x - 8, 15, z), PALE, Enum.Material.Marble)
	LP(m, Vector3.new(4, 20, 4), CFrame.new(x + 8, 10, z), PALE, Enum.Material.Marble)
	LP(m, Vector3.new(12, 3, 4), CFrame.new(x - 3, 31, z) * CFrame.Angles(0, 0, math.rad(8)), PALE, Enum.Material.Marble)
	local g = LP(m, Vector3.new(1, 1, 1), CFrame.new(x + 8, 21.5, z), STAR, Enum.Material.Neon, BALL)
	LGLOW(g, STAR, 30, 1.8)
end)
landmark("StarObelisk", 22, -39, 11, function(m, x, z)
	LP(m, Vector3.new(6, 24, 6), CFrame.new(x, 12, z), BLUE, Enum.Material.Marble)
	LP(m, Vector3.new(4, 12, 4), CFrame.new(x, 30, z), BLUE, Enum.Material.Marble)
	local t = LP(m, Vector3.new(3, 3, 3), CFrame.new(x, 38, z) * CFrame.Angles(0.6, 0.6, 0), PALE, Enum.Material.Neon)
	LGLOW(t, PALE, 46, 3)
	LP(m, Vector3.new(0.5, 18, 18), CFrame.new(x, 38, z) * FACE, STAR, Enum.Material.Neon, CYL).Transparency = 0.7
end)
landmark("Orrery", 60, -10, 12, function(m, x, z)
	LP(m, Vector3.new(2, 14, 2), CFrame.new(x, 7, z), BRASS)
	local c = LP(m, Vector3.new(3, 3, 3), CFrame.new(x, 17, z), LAMP, Enum.Material.Neon, BALL)
	LGLOW(c, LAMP, 30, 1.8)
	for i, r in { 10, 15 } do
		local ring = LP(m, Vector3.new(0.5, r, r), CFrame.new(x, 17, z) * CFrame.Angles(i * 0.7, 0, i * 0.4) * FACE, PALE, Enum.Material.Neon, CYL)
		ring.Transparency = 0.45
	end
end)
-- T164: this set's weather, one wide emitter over the board (only the shown set is parented to workspace on the client, so only one runs).
do
	local w = Instance.new("Part")
	w.Name = "Weather"
	w.Size, w.CFrame, w.Transparency = Vector3.new(120, 1, 80), CFrame.new(0, 36, -4), 1
	w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch = true, false, false, false
	local e = Instance.new("ParticleEmitter")
	e.Name = "WeatherEmitter"
	e.Shape, e.EmissionDirection = Enum.ParticleEmitterShape.Box, Enum.NormalId.Bottom
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(170, 196, 255))
	e.Rate, e.Lifetime, e.Speed = 22, NumberRange.new(5, 7), NumberRange.new(2.5, 3.5)
	e.Size = NumberSequence.new(0.4)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.LightEmission, e.Acceleration, e.LockedToPart = 1, Vector3.new(0, 0, 0), false
	
	e.Parent = w
	w.Parent = root
end

-- T152: the spawn gate's two doors (hinged at the arch pillars of the fog gate that MapBuilder builds at the lane start). Closed at rest;
-- the client script GateFX swings them open when a wave spawns and shows an enemy shadow in the gateway. Visual only.
do
	local gp = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")).PATH[1]
	local gx, gz = gp.X - 4.4, gp.Z
	local doors = Instance.new("Model")
	doors.Name = "GateDoors"
	for _, s in { 1, -1 } do
		local d = Instance.new("Part")
		d.Name = s == 1 and "DoorL" or "DoorR"
		d.Size, d.Color, d.Material, d.Transparency = Vector3.new(0.5, 9, 5.2), Color3.fromRGB(190, 210, 255), Enum.Material.Glass, 0.45
		d.CFrame = CFrame.new(gx, 5, gz - s * 5.4) * CFrame.new(0, 0, s * 2.7)
		d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
		d:SetAttribute("Hinge", Vector3.new(gx, 5, gz - s * 5.4))
		d:SetAttribute("Side", s)
		d.Parent = doors
	end
	doors.Parent = root
end
root.Parent = sets
