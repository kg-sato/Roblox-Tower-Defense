--!nocheck
-- The Silent Cathedral (stage set 3, stages 11-15): a moonlit gothic nave around the board. Stained glass, candles,
-- statues with covered faces. Installed as ServerScriptService.BackdropCathedral; builds
-- workspace.StageSets.SilentCathedral. Visual only. StageSetClient shows it and applies its light (Shared.StageSets).
-- Same rings as the other sets: calm board, a lit edge ring the board camera sees, dark tall walls and windows beyond.

local sets = workspace:FindFirstChild("StageSets") or Instance.new("Folder")
sets.Name = "StageSets"
sets.Parent = workspace
local old = sets:FindFirstChild("SilentCathedral")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "SilentCathedral"

local STONE = Color3.fromRGB(58, 56, 66)
local DARK = Color3.fromRGB(30, 30, 38)
local CLOTH = Color3.fromRGB(190, 186, 196)
local CANDLE = Color3.fromRGB(255, 200, 130)
local MOON = Color3.fromRGB(170, 190, 255)

local function part(size, cf, color, material, shape)
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Size, p.CFrame, p.Color = size, cf, color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = root
	return p
end

local X0, X1, Z0, Z1 = -54, 50, -30, 32

-- nave floor: dark flagstones under the board
part(Vector3.new(230, 1, 110), CFrame.new(0, -0.62, 0), Color3.fromRGB(40, 38, 46), Enum.Material.Slate)

-- far walls with tall lancet windows of stained glass (the only colour)
local GLASS = { Color3.fromRGB(150, 60, 200), Color3.fromRGB(60, 110, 220), Color3.fromRGB(200, 60, 80), Color3.fromRGB(220, 170, 60) }
for _, z in { -64, 66 } do
	part(Vector3.new(240, 46, 4), CFrame.new(0, 23, z), STONE, Enum.Material.Brick)
	for k = -4, 4 do
		local x = k * 22
		local w = part(Vector3.new(6, 20, 0.4), CFrame.new(x, 11, z + (z > 0 and -2.2 or 2.2)), GLASS[(k + 5) % 4 + 1], Enum.Material.Glass)
		w.Transparency = 0.15
		local tip = part(Vector3.new(6, 6, 0.4), CFrame.new(x, 23, z + (z > 0 and -2.2 or 2.2)) * CFrame.Angles(0, 0, math.rad(45)), GLASS[(k + 6) % 4 + 1], Enum.Material.Glass)
		tip.Size = Vector3.new(4.2, 4.2, 0.4)
		tip.Transparency = 0.15
	end
end
-- side walls
for _, x in { -112, 112 } do
	part(Vector3.new(4, 46, 140), CFrame.new(x, 23, 0), STONE, Enum.Material.Brick)
end

-- columns along the long sides of the board, just outside the rail line, with arches between
local function column(x, z)
	part(Vector3.new(3, 30, 3), CFrame.new(x, 15, z), STONE, Enum.Material.Limestone)
	part(Vector3.new(4.4, 1.2, 4.4), CFrame.new(x, 0.6, z), DARK, Enum.Material.Limestone)
	part(Vector3.new(4.4, 1.2, 4.4), CFrame.new(x, 29.6, z), DARK, Enum.Material.Limestone)
end
for x = X0, X1, 20 do
	column(x, Z0 - 6)
	column(x, Z1 + 6)
end

-- the edge ring the board camera sees: low stone kerb, candle stands with LampLight, covered statues, pews
for i, c in { { X0, Z0, X1, Z0 }, { X0, Z1, X1, Z1 }, { X0, Z0, X0, Z1 }, { X1, Z0, X1, Z1 } } do
	local a, b = Vector3.new(c[1], 0, c[2]), Vector3.new(c[3], 0, c[4])
	local mid, len = (a + b) / 2, (b - a).Magnitude
	part(Vector3.new(1.2, 0.9, len), CFrame.lookAt(mid + Vector3.new(0, 0.45, 0), b + Vector3.new(0, 0.45, 0)), DARK, Enum.Material.Limestone)
end
local function candles(x, z)
	part(Vector3.new(0.5, 4.5, 0.5), CFrame.new(x, 2.25, z), Color3.fromRGB(70, 56, 34), Enum.Material.Metal)
	part(Vector3.new(2.4, 0.3, 2.4), CFrame.new(x, 4.6, z), Color3.fromRGB(70, 56, 34), Enum.Material.Metal)
	for k = 0, 2 do
		local a = k * 2.1
		local px, pz = x + math.cos(a) * 0.7, z + math.sin(a) * 0.7
		part(Vector3.new(0.35, 1.1, 0.35), CFrame.new(px, 5.3, pz), Color3.fromRGB(235, 228, 210), Enum.Material.SmoothPlastic)
		local flame = part(Vector3.new(0.25, 0.45, 0.25), CFrame.new(px, 6.05, pz), CANDLE, Enum.Material.Neon)
		flame.Transparency = 0.1
	end
	local glow = part(Vector3.new(0.2, 0.2, 0.2), CFrame.new(x, 6.2, z), CANDLE, Enum.Material.Neon)
	glow.Transparency = 1
	local light = Instance.new("PointLight")
	light.Name = "LampLight"
	light.Color, light.Range, light.Brightness, light.Shadows = CANDLE, 16, 1.4, true
	light.Parent = glow
end
for _, p in { { X0, Z0 }, { X1, Z0 }, { X0, Z1 }, { X1, Z1 }, { -18, Z0 }, { 16, Z0 }, { -18, Z1 }, { 16, Z1 } } do
	candles(p[1], p[2])
end
-- statues with covered faces: a plinth, a robed body and a cloth draped over the head
local function statue(x, z, facing)
	local base = CFrame.new(x, 0, z) * CFrame.Angles(0, facing, 0)
	part(Vector3.new(3, 2, 3), base * CFrame.new(0, 1, 0), DARK, Enum.Material.Limestone)
	part(Vector3.new(2.2, 5.5, 1.8), base * CFrame.new(0, 4.75, 0), Color3.fromRGB(120, 118, 128), Enum.Material.Limestone)
	part(Vector3.new(2.3, 2.3, 2.3), base * CFrame.new(0, 8.4, 0), CLOTH, Enum.Material.Fabric, Enum.PartType.Ball)
	part(Vector3.new(2.8, 3.4, 2.1), base * CFrame.new(0, 7, 0), CLOTH, Enum.Material.Fabric)
end
statue(X0 - 6, 0, math.rad(90))
statue(X1 + 6, 0, math.rad(-90))
statue(-36, Z0 - 6, 0)
statue(34, Z1 + 6, math.rad(180))
-- pews behind the near rail
for x = -40, 36, 12 do
	part(Vector3.new(9, 1.6, 1.6), CFrame.new(x, 0.8, Z1 + 11), Color3.fromRGB(60, 44, 34), Enum.Material.Wood)
	part(Vector3.new(9, 2.2, 0.4), CFrame.new(x, 2.2, Z1 + 11.8), Color3.fromRGB(60, 44, 34), Enum.Material.Wood)
end

-- moonbeams through the far windows (soft cold shafts, no shadows)
for k = -2, 2 do
	local shaft = part(Vector3.new(5, 0.2, 60), CFrame.new(k * 30, 14, -36) * CFrame.Angles(math.rad(-28), 0, 0), MOON, Enum.Material.Neon)
	shaft.Transparency = 0.9
end

-- dust in the air, slow
local dust = part(Vector3.new(120, 1, 70), CFrame.new(0, 10, 0), Color3.new(1, 1, 1))
dust.Transparency = 1
local pe = Instance.new("ParticleEmitter")
pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
pe.Color = ColorSequence.new(Color3.fromRGB(200, 210, 255))
pe.Size = NumberSequence.new(0.15)
pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 1) })
pe.Lifetime = NumberRange.new(8, 12)
pe.Rate = 6
pe.Speed = NumberRange.new(0.2, 0.5)
pe.SpreadAngle = Vector2.new(180, 180)
pe.Parent = dust

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
landmark("RoseWindow", -24, -35, 7, function(m, x, z)
	for _, s in { -1, 1 } do
		LP(m, Vector3.new(4, 26, 4), CFrame.new(x + s * 11, 13, z), STONE, Enum.Material.Slate)
	end
	LP(m, Vector3.new(1.4, 24, 24), CFrame.new(x, 27, z) * FACE, STONE, Enum.Material.Slate, CYL)
	local w = LP(m, Vector3.new(0.8, 20, 20), CFrame.new(x, 27, z + 0.9) * FACE, Color3.fromRGB(150, 70, 210), Enum.Material.Neon, CYL)
	w.Transparency = 0.2
	LGLOW(w, MOON, 40, 2.2)
	for i = 0, 3 do
		LP(m, Vector3.new(20, 1, 0.5), CFrame.new(x, 27, z + 1.4) * CFrame.Angles(0, 0, math.rad(i * 45)), DARK)
	end
end)
landmark("BellTower", 22, -39, 11, function(m, x, z)
	LP(m, Vector3.new(8, 24, 8), CFrame.new(x, 12, z), STONE, Enum.Material.Slate)
	for _, p in { { -3.5, -3.5 }, { 3.5, -3.5 }, { -3.5, 3.5 }, { 3.5, 3.5 } } do
		LP(m, Vector3.new(1.2, 10, 1.2), CFrame.new(x + p[1], 29, z + p[2]), STONE, Enum.Material.Slate)
	end
	LP(m, Vector3.new(10, 2, 10), CFrame.new(x, 35, z), DARK)
	local b = LP(m, Vector3.new(5, 5, 5), CFrame.new(x, 28, z) * UP, Color3.fromRGB(176, 132, 58), Enum.Material.Metal, CYL)
	LGLOW(b, CANDLE, 30, 1.8)
end)
landmark("Candelabra", 60, -10, 12, function(m, x, z)
	LP(m, Vector3.new(1.2, 22, 1.2), CFrame.new(x, 11, z), Color3.fromRGB(176, 132, 58))
	LP(m, Vector3.new(16, 0.8, 0.8), CFrame.new(x, 20, z), Color3.fromRGB(176, 132, 58))
	for _, s in { -7.6, 0, 7.6 } do
		LP(m, Vector3.new(4, 1.6, 1.6), CFrame.new(x + s, 21.5, z) * UP, CLOTH, Enum.Material.Marble, CYL)
		local f = LP(m, Vector3.new(1.2, 1.8, 1.2), CFrame.new(x + s, 24, z), CANDLE, Enum.Material.Neon, BALL)
		LGLOW(f, CANDLE, 26, 1.6)
	end
end)
-- T164: this set's weather, one wide emitter over the board (only the shown set is parented to workspace on the client, so only one runs).
do
	local w = Instance.new("Part")
	w.Name = "Weather"
	w.Size, w.CFrame, w.Transparency = Vector3.new(120, 1, 80), CFrame.new(0, 30, -4), 1
	w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch = true, false, false, false
	local e = Instance.new("ParticleEmitter")
	e.Name = "WeatherEmitter"
	e.Shape, e.EmissionDirection = Enum.ParticleEmitterShape.Box, Enum.NormalId.Bottom
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(190, 205, 255))
	e.Rate, e.Lifetime, e.Speed = 14, NumberRange.new(8, 11), NumberRange.new(0.5, 1)
	e.Size = NumberSequence.new(0.3)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.35), NumberSequenceKeypoint.new(0.8, 0.35), NumberSequenceKeypoint.new(1, 1) })
	e.LightEmission, e.Acceleration, e.LockedToPart = 0.6, Vector3.new(0.2, -0.1, 0), false
	
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
		d.Size, d.Color, d.Material, d.Transparency = Vector3.new(0.5, 9, 5.2), Color3.fromRGB(84, 62, 46), Enum.Material.WoodPlanks, 0
		d.CFrame = CFrame.new(gx, 5, gz - s * 5.4) * CFrame.new(0, 0, s * 2.7)
		d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
		d:SetAttribute("Hinge", Vector3.new(gx, 5, gz - s * 5.4))
		d:SetAttribute("Side", s)
		d.Parent = doors
	end
	doors.Parent = root
end
root.Parent = sets
