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

root.Parent = sets
