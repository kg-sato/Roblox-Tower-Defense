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
root.Parent = sets
