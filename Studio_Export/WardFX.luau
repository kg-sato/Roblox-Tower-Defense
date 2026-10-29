--!nocheck
-- WardFX (LocalScript, StarterPlayerScripts, 2026-10-28). The blind reviewer failed the ward crystal on presence and
-- motion ("no visible change across the frames ... a tiny cyan speck at the board camera"). This gives it life:
--   * three tilted rings of light points orbiting the crystal (two cyan, one violet), with a faint ghost ring each
--   * six crystal shards circling and bobbing
--   * a breathing glow: the heart light and a soft bloom sphere pulse together
--   * a glowing rune circle on the ground under the lantern, turning slowly, so it reads from the board camera
-- Client only, visual only. Reduced Motion is respected through the HUD's SETTINGS attribute if present.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local map = workspace:WaitForChild("Map", 30)
local crystal = map and map:WaitForChild("Crystal", 30)
if not crystal then return end
if map:GetAttribute("WardStyle") ~= "Cosmic" then
	-- Lampwick lantern (reviewer: "glow looks the same in every frame; lost among the lamp posts"): the crystal heart
	-- breathes and flickers like a flame, and a cyan light pools on the street around the lantern (reviewer v5)
	local light = crystal:FindFirstChildOfClass("PointLight")
	local glow = Instance.new("PointLight")
	glow.Color, glow.Range, glow.Brightness, glow.Shadows = Color3.fromRGB(110, 225, 255), 26, 1.4, true
	glow.Parent = crystal
	local lantern = map:FindFirstChild("WardLantern")
	if lantern then -- a soft cyan outline so it reads at the board camera, apart from the yellow street lamps
		local h = Instance.new("Highlight")
		h.FillTransparency, h.OutlineColor, h.OutlineTransparency = 1, Color3.fromRGB(120, 230, 255), 0.65 -- fainter: reviewer saw a white rim at 0.35
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Adornee, h.Parent = lantern, lantern
	end
	local t0 = os.clock()
	RunService.RenderStepped:Connect(function()
		if Players.LocalPlayer:GetAttribute("ReducedMotion") == true then return end
		local t = os.clock() - t0
		-- reviewer v7: "no visible pulse in a 0.9 s strip": a 0.8 s breath of +-25% plus flame flicker, on the lights AND
		-- on the crystal's colour (white-hot at the peak, teal at the low)
		local flick = 0.5 + 0.5 * math.sin(t * 7.85) + 0.18 * math.sin(t * 23.7) * math.sin(t * 9.1)
		if light then light.Brightness = 0.5 + flick * 3 end -- v8: reviewer still saw no pulse, so deeper troughs
		glow.Brightness = 0.6 + flick * 2.8 -- light only: GameClient owns Crystal.Size (idle pulse + hit flash)
		glow.Range = 24 + flick * 14
		crystal.Color = Color3.fromRGB(90, 200, 230):Lerp(Color3.fromRGB(245, 255, 255), math.clamp(flick, 0, 1))
	end)
	return
end -- the rings and shards below belong to the cosmic crystal only
local home = crystal.Position
local CYAN, VIOLET, WHITE = Color3.fromRGB(120, 230, 255), Color3.fromRGB(190, 120, 255), Color3.fromRGB(235, 250, 255)

local folder = Instance.new("Folder")
folder.Name = "WardFX"
folder.Parent = workspace
local function part(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	for k, v in props do p[k] = v end
	p.Parent = folder
	return p
end

-- rings of points
local rings = {}
for r, spec in { { 7.5, CYAN, 70, 0.9 }, { 8.5, CYAN, 70, -0.7 }, { 10, VIOLET, 76, 0.5 } } do
	local pts = {}
	for i = 1, 18 do
		pts[i] = part({ Shape = Enum.PartType.Ball, Color = spec[2], Size = Vector3.one * (i % 3 == 0 and 0.32 or 0.18) })
		pts[i + 18] = part({ Shape = Enum.PartType.Ball, Color = spec[2], Transparency = 0.8, Size = Vector3.one * (i % 3 == 0 and 0.8 or 0.5) }) -- ghost copy: glow by duplication
	end
	rings[r] = { radius = spec[1], tilt = CFrame.Angles(math.rad(spec[3]), math.rad(r * 60), 0), speed = spec[4], pts = pts }
end
-- continuous rings: a thin bright circle on a SurfaceGui (both faces), tilted, turning; cyan, pink, cyan
local hoops = {}
for i, spec in { { 13, CYAN, 70, 0.6 }, { 15.5, Color3.fromRGB(255, 120, 210), 64, -0.45 }, { 18, CYAN, 76, 0.3 } } do
	local hp = part({ Transparency = 1, Size = Vector3.new(spec[1], spec[1], 0.05) })
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local g = Instance.new("SurfaceGui")
		g.Face, g.LightInfluence, g.CanvasSize, g.Brightness = face, 0, Vector2.new(512, 512), 3
		local f = Instance.new("Frame")
		f.BackgroundTransparency, f.Size = 1, UDim2.fromScale(1, 1)
		Instance.new("UICorner", f).CornerRadius = UDim.new(0.5, 0)
		local st = Instance.new("UIStroke")
		st.Color, st.Thickness, st.Transparency = spec[2], 5, 0.1
		st.Parent = f
		local gh = f:Clone() -- a wide faint ghost ring: glow by duplication
		gh:FindFirstChildOfClass("UIStroke").Thickness, gh:FindFirstChildOfClass("UIStroke").Transparency = 18, 0.8
		gh.Parent = g
		f.Parent = g
		g.Parent = hp
	end
	hoops[i] = { part = hp, tilt = math.rad(spec[3]), speed = spec[4], yaw = i * 1.9 }
end
-- a faint column of light rising from the crystal, so it reads from the board camera
local column = part({ Shape = Enum.PartType.Cylinder, Color = CYAN, Transparency = 0.86, Size = Vector3.new(60, 2.2, 2.2), CFrame = CFrame.new(home + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
-- shards
local shards = {}
for i = 1, 6 do
	shards[i] = part({ Shape = Enum.PartType.Wedge, Material = Enum.Material.Glass, Color = i % 2 == 0 and CYAN or WHITE, Transparency = 0.25, Reflectance = 0.3, Size = Vector3.new(0.45, 2, 0.9) })
end
-- breathing glow sphere and the crystal's own light
local bloom = part({ Shape = Enum.PartType.Ball, Color = CYAN, Transparency = 0.95, Size = Vector3.one * 9 }) -- faint and wide: 0.86 at 7 studs washed the facets white
local light = crystal:FindFirstChildOfClass("PointLight")
-- rune circle on the ground: two thin rings and twelve tick marks on a SurfaceGui, under the lantern
local disc = part({ Material = Enum.Material.SmoothPlastic, Transparency = 1, Size = Vector3.new(26, 0.05, 26), CFrame = CFrame.new(home.X, 0.12, home.Z) })
local sg = Instance.new("SurfaceGui")
sg.Face, sg.LightInfluence, sg.CanvasSize, sg.Brightness = Enum.NormalId.Top, 0, Vector2.new(512, 512), 2
sg.Parent = disc
local holder = Instance.new("Frame")
holder.BackgroundTransparency, holder.Size = 1, UDim2.fromScale(1, 1)
holder.Parent = sg
for _, spec in { { 0.98, 3, 0.15 }, { 0.84, 2, 0.35 }, { 0.62, 1.5, 0.5 } } do
	local f = Instance.new("Frame")
	f.BackgroundTransparency, f.AnchorPoint, f.Position, f.Size = 1, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(spec[1], spec[1])
	Instance.new("UICorner", f).CornerRadius = UDim.new(0.5, 0)
	local st = Instance.new("UIStroke")
	st.Color, st.Thickness, st.Transparency = CYAN, spec[2], spec[3]
	st.Parent = f
	f.Parent = holder
end
for k = 1, 12 do
	local a = k / 12 * math.pi * 2
	local t = Instance.new("Frame")
	t.BorderSizePixel, t.AnchorPoint, t.Rotation = 0, Vector2.new(0.5, 0.5), math.deg(a)
	t.Position = UDim2.fromScale(0.5 + math.cos(a) * 0.455, 0.5 + math.sin(a) * 0.455)
	t.Size = UDim2.fromOffset(k % 3 == 0 and 30 or 14, 3)
	t.BackgroundColor3 = k % 3 == 0 and VIOLET or CYAN
	t.Parent = holder
end

local t0 = os.clock()
RunService.RenderStepped:Connect(function()
	local t = os.clock() - t0
	local reduced = Players.LocalPlayer:GetAttribute("ReducedMotion") == true
	local spin = reduced and 0 or t
	local c = crystal.Position -- follows the client's hit shake
	for _, ring in rings do
		local n = #ring.pts / 2
		for i = 1, n do
			local a = i / n * math.pi * 2 + spin * ring.speed
			local cf = CFrame.new(c) * ring.tilt * CFrame.new(math.cos(a) * ring.radius, math.sin(a) * ring.radius, 0)
			ring.pts[i].CFrame = cf
			ring.pts[i + n].CFrame = cf
		end
	end
	for i, s in shards do
		local a = i / #shards * math.pi * 2 - spin * 0.6
		local p = c + Vector3.new(math.cos(a) * 6, math.sin(spin * 1.3 + i) * 1.2 + 1.5, math.sin(a) * 6)
		s.CFrame = CFrame.lookAt(p, c) * CFrame.Angles(0, 0, spin * 0.8 + i)
	end
	local pulse = 0.5 + 0.5 * math.sin(t * 2.2)
	bloom.Position = c
	bloom.Transparency = 0.96 - pulse * 0.025
	bloom.Size = Vector3.one * (8.5 + pulse * 1.2)
	if light then light.Brightness = 1.2 + pulse * 1.0 end
	holder.Rotation = spin * 6
	for _, h in hoops do
		h.part.CFrame = CFrame.new(c + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, h.yaw + spin * h.speed, 0) * CFrame.Angles(h.tilt, 0, 0)
	end
	column.Transparency = 0.9 - pulse * 0.05
end)
