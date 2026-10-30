--!nocheck
-- Clockwork Foundry (stage set 4, stages 16-20): furnaces with glowing orange mouths, gear wheels, rails and sparks in a
-- smoky works. Installed as ServerScriptService.BackdropFoundry; builds workspace.StageSets.ClockworkFoundry. Visual only.
-- Same rings as the other sets: calm board, a lit edge ring the board camera sees, dark tall walls beyond.

local sets = workspace:FindFirstChild("StageSets") or Instance.new("Folder")
sets.Name = "StageSets"
sets.Parent = workspace
local old = sets:FindFirstChild("ClockworkFoundry")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "ClockworkFoundry"

local IRON = Color3.fromRGB(46, 42, 40)
local BRASS = Color3.fromRGB(150, 104, 52)
local DARK = Color3.fromRGB(30, 27, 26)
local ORANGE = Color3.fromRGB(255, 132, 40)
local FLOOR = Color3.fromRGB(42, 36, 34)

local function part(size, cf, color, material, shape)
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Size, p.CFrame, p.Color = size, cf, color
	p.Material = material or Enum.Material.Metal
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = root
	return p
end

-- works floor under the board, and the far walls
part(Vector3.new(230, 1, 110), CFrame.new(0, -0.62, 0), FLOOR, Enum.Material.Slate)
for _, z in { -64, 66 } do
	part(Vector3.new(240, 46, 4), CFrame.new(0, 23, z), DARK, Enum.Material.Brick)
end
for _, x in { -112, 112 } do
	part(Vector3.new(4, 46, 140), CFrame.new(x, 23, 0), DARK, Enum.Material.Brick)
end

-- rails across the back of the works, with sleepers
for _, z in { -44, -41 } do
	part(Vector3.new(180, 0.6, 0.6), CFrame.new(0, 0.3, z), BRASS, Enum.Material.Metal)
end
for x = -86, 86, 4 do
	part(Vector3.new(0.7, 0.4, 3.2), CFrame.new(x, 0.1, -42.5), DARK, Enum.Material.Wood)
end

-- furnaces: an iron drum, a flue, and a glowing orange mouth with a light and sparks
local function furnace(x, z, facing)
	local base = CFrame.new(x, 0, z) * CFrame.Angles(0, facing, 0)
	part(Vector3.new(7, 9, 7), base * CFrame.new(0, 4.5, 0), IRON, Enum.Material.Metal)
	part(Vector3.new(2.2, 16, 2.2), base * CFrame.new(0, 14, 0), DARK, Enum.Material.Metal)
	local mouth = part(Vector3.new(3.2, 2.6, 0.4), base * CFrame.new(0, 3.2, -3.6), ORANGE, Enum.Material.Neon)
	mouth.Transparency = 0.1
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = ORANGE, 14, 1.2, false
	light.Parent = mouth
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(ORANGE)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new(0.4)
	sparks.Lifetime = NumberRange.new(0.6, 1.2)
	sparks.Rate = 6
	sparks.Speed = NumberRange.new(3, 6)
	sparks.SpreadAngle = Vector2.new(30, 30)
	sparks.Parent = mouth
end
furnace(-70, -56, 0)
furnace(-24, -58, math.rad(8))
furnace(40, -56, math.rad(-6))
furnace(84, -52, 0)
furnace(-92, 40, math.rad(90))
furnace(92, 36, math.rad(-90))

-- gear wheels on the back wall (discs in the XY plane)
local function gear(x, y, z, r)
	part(Vector3.new(0.8, r * 2, r * 2), CFrame.new(x, y, z) * CFrame.Angles(0, math.pi / 2, 0), BRASS, Enum.Material.Metal, Enum.PartType.Cylinder)
	part(Vector3.new(0.9, r * 0.5, r * 0.5), CFrame.new(x, y, z) * CFrame.Angles(0, math.pi / 2, 0), DARK, Enum.Material.Metal, Enum.PartType.Cylinder)
end
gear(-52, 24, -61.2, 8)
gear(-30, 30, -61.2, 6)
gear(8, 22, -61.2, 9)
gear(60, 28, -61.2, 7)

-- the edge ring the board camera sees: a kerb and warm lamps along the board's sides
local X0, X1, Z0, Z1 = -54, 50, -30, 32
for _, c in { { X0, Z0, X1, Z0 }, { X0, Z1, X1, Z1 }, { X0, Z0, X0, Z1 }, { X1, Z0, X1, Z1 } } do
	local a, b = Vector3.new(c[1], 0, c[2]), Vector3.new(c[3], 0, c[4])
	local mid, len = (a + b) / 2, (b - a).Magnitude
	part(Vector3.new(1.2, 0.9, len), CFrame.lookAt(mid + Vector3.new(0, 0.45, 0), b + Vector3.new(0, 0.45, 0)), DARK, Enum.Material.Metal)
end
local function lamp(x, z)
	part(Vector3.new(0.5, 4.5, 0.5), CFrame.new(x, 2.25, z), IRON, Enum.Material.Metal)
	local glow = part(Vector3.new(0.6, 0.6, 0.6), CFrame.new(x, 4.8, z), ORANGE, Enum.Material.Neon)
	glow.Transparency = 0.2
	local light = Instance.new("PointLight")
	light.Name = "LampLight"
	light.Color, light.Range, light.Brightness, light.Shadows = ORANGE, 16, 1.4, true
	light.Parent = glow
end
for _, p in { { X0, Z0 }, { X1, Z0 }, { X0, Z1 }, { X1, Z1 }, { -18, Z0 }, { 16, Z0 }, { -18, Z1 }, { 16, Z1 } } do
	lamp(p[1], p[2])
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
landmark("ChimneyStack", -24, -35, 7, function(m, x, z)
	LP(m, Vector3.new(44, 9, 9), CFrame.new(x, 22, z) * UP, Color3.fromRGB(70, 46, 40), Enum.Material.Brick, CYL)
	LP(m, Vector3.new(1.6, 10.4, 10.4), CFrame.new(x, 40, z) * UP, BRASS, Enum.Material.Metal, CYL)
	local f = LP(m, Vector3.new(6, 6, 6), CFrame.new(x, 47, z), ORANGE, Enum.Material.Neon, BALL)
	f.Transparency = 0.25
	LGLOW(f, ORANGE, 48, 3)
	LP(m, Vector3.new(4, 4, 4), CFrame.new(x + 2, 53, z), Color3.fromRGB(80, 66, 60), Enum.Material.SmoothPlastic, BALL).Transparency = 0.5
end)
landmark("GreatCog", 22, -39, 11, function(m, x, z)
	LP(m, Vector3.new(2, 24, 24), CFrame.new(x, 24, z) * FACE, BRASS, Enum.Material.Metal, CYL)
	for i = 0, 11 do
		LP(m, Vector3.new(3, 4, 2), CFrame.new(x, 24, z) * CFrame.Angles(0, 0, math.rad(i * 30)) * CFrame.new(0, 13, 0), BRASS)
	end
	local h = LP(m, Vector3.new(2.4, 7, 7), CFrame.new(x, 24, z + 1.2) * FACE, ORANGE, Enum.Material.Neon, CYL)
	LGLOW(h, ORANGE, 38, 2.4)
	LP(m, Vector3.new(3, 12, 3), CFrame.new(x, 6, z - 1), IRON)
end)
landmark("Crucible", 60, -10, 12, function(m, x, z)
	LP(m, Vector3.new(14, 10, 10), CFrame.new(x, 14, z) * UP, IRON, Enum.Material.Metal, CYL)
	local pool = LP(m, Vector3.new(0.6, 9, 9), CFrame.new(x, 21.2, z) * UP, ORANGE, Enum.Material.Neon, CYL)
	LGLOW(pool, ORANGE, 38, 2.6)
	for _, s in { -1, 1 } do
		LP(m, Vector3.new(2, 20, 2), CFrame.new(x + s * 8, 10, z), DARK)
	end
	LP(m, Vector3.new(18, 1.6, 1.6), CFrame.new(x, 20.5, z), DARK)
end)
-- T164: this set's weather, one wide emitter over the board (only the shown set is parented to workspace on the client, so only one runs).
do
	local w = Instance.new("Part")
	w.Name = "Weather"
	w.Size, w.CFrame, w.Transparency = Vector3.new(120, 1, 80), CFrame.new(0, 0.5, -4), 1
	w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch = true, false, false, false
	local e = Instance.new("ParticleEmitter")
	e.Name = "WeatherEmitter"
	e.Shape, e.EmissionDirection = Enum.ParticleEmitterShape.Box, Enum.NormalId.Top
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 140, 50))
	e.Rate, e.Lifetime, e.Speed = 24, NumberRange.new(3, 4), NumberRange.new(6, 9)
	e.Size = NumberSequence.new(0.35)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.LightEmission, e.Acceleration, e.LockedToPart = 1, Vector3.new(0.8, 2, 0.3), false
	
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
		d.Size, d.Color, d.Material, d.Transparency = Vector3.new(0.5, 9, 5.2), Color3.fromRGB(46, 42, 40), Enum.Material.DiamondPlate, 0
		d.CFrame = CFrame.new(gx, 5, gz - s * 5.4) * CFrame.new(0, 0, s * 2.7)
		d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
		d:SetAttribute("Hinge", Vector3.new(gx, 5, gz - s * 5.4))
		d:SetAttribute("Side", s)
		d.Parent = doors
	end
	doors.Parent = root
end
root.Parent = sets
