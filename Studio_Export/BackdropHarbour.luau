--!nocheck
-- Harbour of Brass (stage set 2, stages 6-10): foggy docks around the board, steamships, cranes, rope and chain props.
-- Installed as ServerScriptService.BackdropHarbour; builds workspace.StageSets.HarbourOfBrass. Visual only.
-- The client shows one set at a time (StageSetClient) and applies the set's light and fog from Shared.StageSets.
-- Same three rings as Lampwick Lane: calm board, lit props near the edge, dark silhouettes in fog far away.

local sets = workspace:FindFirstChild("StageSets") or Instance.new("Folder")
sets.Name = "StageSets"
sets.Parent = workspace
local old = sets:FindFirstChild("HarbourOfBrass")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "HarbourOfBrass"

local BRASS = Color3.fromRGB(150, 112, 58)
local DARKBRASS = Color3.fromRGB(78, 62, 40)
local HULL = Color3.fromRGB(30, 34, 40)
local PIER = Color3.fromRGB(70, 56, 44)
local WATER = Color3.fromRGB(16, 30, 38)
local LAMP = Color3.fromRGB(220, 236, 255)

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

-- wet stone quay under and around the board (the board's own parts sit on top of it)
part(Vector3.new(230, 1, 96), CFrame.new(0, -0.62, 0), Color3.fromRGB(46, 52, 58), Enum.Material.Slate)
-- water all round the far edge (the board itself is untouched)
part(Vector3.new(420, 1, 140), CFrame.new(0, -1.2, -120), WATER, Enum.Material.Glass).Transparency = 0.15
part(Vector3.new(420, 1, 140), CFrame.new(0, -1.2, 118), WATER, Enum.Material.Glass).Transparency = 0.15

-- piers with bollards and rope coils along the near edge
for _, z in { -52, 50 } do
	part(Vector3.new(170, 1, 12), CFrame.new(0, -0.2, z), PIER, Enum.Material.WoodPlanks)
	for x = -78, 78, 13 do
		part(Vector3.new(1.4, 2.2, 1.4), CFrame.new(x, 1.2, z + (z > 0 and 4 or -4)), Color3.fromRGB(24, 24, 28), Enum.Material.Metal, Enum.PartType.Cylinder).CFrame = CFrame.new(x, 1.2, z + (z > 0 and 4 or -4)) * CFrame.Angles(0, 0, math.rad(90))
	end
	for x = -70, 70, 35 do
		part(Vector3.new(0.8, 2.4, 2.4), CFrame.new(x + 4, 0.7, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 120, 80), Enum.Material.Fabric, Enum.PartType.Cylinder)
	end
end

-- cranes: tall brass trusses with a jib over the water
local function crane(x, z, facing)
	local base = CFrame.new(x, 0, z) * CFrame.Angles(0, facing, 0)
	for _, s in { -1, 1 } do
		part(Vector3.new(0.8, 34, 0.8), base * CFrame.new(s * 2, 17, 0), DARKBRASS, Enum.Material.Metal)
	end
	for y = 4, 32, 6 do
		part(Vector3.new(4.6, 0.5, 0.5), base * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(28)), BRASS, Enum.Material.Metal)
	end
	part(Vector3.new(1, 1, 30), base * CFrame.new(0, 34, -12), BRASS, Enum.Material.Metal)
	part(Vector3.new(0.2, 14, 0.2), base * CFrame.new(0, 27, -24), Color3.fromRGB(20, 20, 24), Enum.Material.Metal) -- hook line
	part(Vector3.new(2, 1, 2), base * CFrame.new(0, 20, -24), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
end
crane(-70, -60, 0)
crane(40, -40, math.rad(10)) -- T104: pulled in so its base sits in the top band of the default board camera
crane(84, 60, math.rad(180))

-- steamship silhouettes in the fog
local function ship(x, z, len, rot)
	local base = CFrame.new(x, 0, z) * CFrame.Angles(0, rot, 0)
	part(Vector3.new(len, 8, 12), base * CFrame.new(0, 3, 0), HULL, Enum.Material.Metal)
	part(Vector3.new(len * 0.5, 6, 9), base * CFrame.new(-len * 0.1, 10, 0), Color3.fromRGB(46, 48, 54), Enum.Material.Metal)
	for i, off in { -0.15, 0.1 } do
		part(Vector3.new(14, 3.4, 3.4), base * CFrame.new(len * off, 18, 0) * CFrame.Angles(0, 0, math.rad(90)), i == 1 and Color3.fromRGB(110, 40, 34) or Color3.fromRGB(30, 30, 34), Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	for k = -2, 2 do -- lit portholes
		local w = part(Vector3.new(1.2, 1.2, 0.3), base * CFrame.new(k * len * 0.15, 4, -6.1), Color3.fromRGB(255, 200, 130), Enum.Material.Neon)
		w.Transparency = 0.2
	end
end
ship(-30, -40, 70, 0) -- T104: pulled in from -118 so the hull shows in the top band of the default camera
ship(70, -132, 90, math.rad(-6))
ship(-90, 130, 80, math.rad(178))

-- warehouses on the sides (dark, a few warm windows)
for _, x in { -104, 104 } do
	for z = -30, 30, 20 do
		part(Vector3.new(22, 18, 18), CFrame.new(x, 9, z), Color3.fromRGB(40, 38, 46), Enum.Material.Brick)
		part(Vector3.new(22, 1, 19), CFrame.new(x, 18.4, z), Color3.fromRGB(28, 28, 34), Enum.Material.Slate)
		local win = part(Vector3.new(0.3, 2, 3), CFrame.new(x + (x > 0 and -11.1 or 11.1), 8, z), Color3.fromRGB(255, 190, 120), Enum.Material.Neon)
		win.Transparency = 0.25
	end
end

-- brass pipes with steam vents along the inner rail
for _, z in { -46, 44 } do
	part(Vector3.new(150, 1.2, 1.2), CFrame.new(0, 1, z) * CFrame.Angles(0, 0, 0) * CFrame.Angles(0, math.rad(90), math.rad(90)), BRASS, Enum.Material.Metal, Enum.PartType.Cylinder).CFrame = CFrame.new(0, 1, z) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(90))
	for x = -60, 60, 40 do
		local v = part(Vector3.new(1, 1, 1), CFrame.new(x, 2, z), DARKBRASS, Enum.Material.Metal)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(210, 220, 224))
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
		pe.Size = NumberSequence.new(1.5, 5)
		pe.Lifetime = NumberRange.new(1.5, 2.5)
		pe.Rate = 3
		pe.Speed = NumberRange.new(3, 5)
		pe.SpreadAngle = Vector2.new(12, 12)
		pe.Parent = v
	end
end

-- harbour lamps: cold white, named LampLight so the Low setting can switch their shadows off
for _, p in { { -84, -46 }, { -28, -46 }, { 28, -46 }, { 84, -46 }, { -84, 44 }, { 0, 44 }, { 84, 44 } } do
	part(Vector3.new(0.6, 10, 0.6), CFrame.new(p[1], 5, p[2]), Color3.fromRGB(26, 26, 32), Enum.Material.Metal)
	local glass = part(Vector3.new(1.4, 1.6, 1.4), CFrame.new(p[1], 10.6, p[2]), LAMP, Enum.Material.Neon)
	glass.Transparency = 0.15
	local light = Instance.new("PointLight")
	light.Name = "LampLight"
	light.Color, light.Range, light.Brightness, light.Shadows = LAMP, 20, 1.4, true
	light.Parent = glass
end

-- low fog banks over the water
for _, z in { -70, 66 } do
	local p = part(Vector3.new(200, 1, 14), CFrame.new(0, 1, z), Color3.new(1, 1, 1))
	p.Transparency = 1
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(160, 182, 186))
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.84), NumberSequenceKeypoint.new(0.7, 0.86), NumberSequenceKeypoint.new(1, 1) })
	pe.Size = NumberSequence.new(14, 28)
	pe.Lifetime = NumberRange.new(10, 14)
	pe.Rate = 1.4
	pe.Speed = NumberRange.new(0.6, 1.2)
	pe.SpreadAngle = Vector2.new(180, 0)
	pe.Parent = p
end

-- ===== Edge ring (T39): what the board camera actually sees, like Lampwick's rails and lamps =====
-- Same rectangle as Lampwick's rail (x -54..50, z -30..32): a dock edge of planks with chain posts, bollards,
-- rope coils, crates, cold lamps and one crane leaning over the board. All darker than the path.
local X0, X1, Z0, Z1 = -54, 50, -30, 32
local function post(x, z)
	part(Vector3.new(0.9, 3.2, 0.9), CFrame.new(x, 1.6, z), Color3.fromRGB(34, 32, 36), Enum.Material.Metal)
	part(Vector3.new(1.3, 0.4, 1.3), CFrame.new(x, 3.3, z), DARKBRASS, Enum.Material.Metal)
end
local function chain(a, b)
	local mid, len = (a + b) / 2, (b - a).Magnitude
	part(Vector3.new(0.25, 0.25, len), CFrame.lookAt(mid + Vector3.new(0, 2.2, 0), b + Vector3.new(0, 2.2, 0)), Color3.fromRGB(70, 66, 60), Enum.Material.Metal)
end
local corners = { Vector3.new(X0, 0, Z0), Vector3.new(X1, 0, Z0), Vector3.new(X1, 0, Z1), Vector3.new(X0, 0, Z1) }
for i = 1, 4 do
	local a, b = corners[i], corners[i % 4 + 1]
	local n = math.floor((b - a).Magnitude / 9)
	for k = 0, n - 1 do
		local p1, p2 = a:Lerp(b, k / n), a:Lerp(b, (k + 1) / n)
		post(p1.X, p1.Z)
		chain(p1, p2)
	end
end
-- plank dock strips just outside the rail on the long sides
for _, z in { Z0 - 4, Z1 + 4 } do
	part(Vector3.new(X1 - X0 + 16, 0.4, 7), CFrame.new((X0 + X1) / 2, -0.1, z), PIER, Enum.Material.WoodPlanks)
end
-- props along the edge: bollards with rope, crates, a barrel stack
local function crate(x, z, sz, rot)
	part(Vector3.new(sz, sz, sz), CFrame.new(x, sz / 2, z) * CFrame.Angles(0, rot or 0, 0), Color3.fromRGB(86, 64, 44), Enum.Material.WoodPlanks)
end
for _, p in { { -44, Z0 - 4 }, { -8, Z0 - 4 }, { 30, Z0 - 4 }, { -30, Z1 + 4 }, { 10, Z1 + 4 }, { 42, Z1 + 4 } } do
	part(Vector3.new(1.8, 1.8, 1.8), CFrame.new(p[1], 0.9, p[2]) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(24, 24, 28), Enum.Material.Metal, Enum.PartType.Cylinder)
	part(Vector3.new(0.7, 2.6, 2.6), CFrame.new(p[1] + 2.4, 0.4, p[2]) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 120, 80), Enum.Material.Fabric, Enum.PartType.Cylinder)
end
crate(-58, -12, 3.2, 0.3)
crate(-58, -8.5, 2.4, 0.1)
crate(55, 18, 3, -0.2)
crate(56, 14, 2.2, 0.5)
crate(55, -20, 2.8, 0.2)
-- cold harbour lamps on the rail, named LampLight so the Low setting can switch their shadows off
for _, p in { { X0, Z0 }, { X1, Z0 }, { X0, Z1 }, { X1, Z1 }, { -18, Z0 }, { 16, Z0 }, { -18, Z1 }, { 16, Z1 } } do
	part(Vector3.new(0.6, 11, 0.6), CFrame.new(p[1], 5.5, p[2]), Color3.fromRGB(26, 26, 32), Enum.Material.Metal)
	local glass = part(Vector3.new(1.3, 1.6, 1.3), CFrame.new(p[1], 11.6, p[2]), LAMP, Enum.Material.Neon)
	glass.Transparency = 0.15
	part(Vector3.new(1.8, 0.4, 1.8), CFrame.new(p[1], 12.6, p[2]), DARKBRASS, Enum.Material.Metal)
	local light = Instance.new("PointLight")
	light.Name = "LampLight"
	light.Color, light.Range, light.Brightness, light.Shadows = LAMP, 22, 1.5, true
	light.Parent = glass
end
-- one crane on the near-left corner with its jib over the board's edge
crane(-66, -26, math.rad(-35))

root.Parent = sets
