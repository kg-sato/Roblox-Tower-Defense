--!strict
-- Builds the arena from Config at server start, so the lane, pads and crystal can never disagree with the game rules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local existing = workspace:FindFirstChild("Map")
if existing then
	existing:Destroy()
end

local map = Instance.new("Folder")
map.Name = "Map"

local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?, wedge: boolean?): BasePart
	local p: any = if wedge then Instance.new("WedgePart") else Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape and not wedge then
		p.Shape = shape
	end
	p.Parent = map
	return p
end

local base = workspace:FindFirstChild("Baseplate")
if base and base:IsA("BasePart") then
	-- Lampwick Lane: dark wet slate ground, so the pale cobbled path is the brightest thing on screen
	base.Color = Color3.fromRGB(46, 46, 54)
	base.Material = Enum.Material.Slate
end

local pts = Config.PATH
for i = 1, #pts - 1 do
	local a, b = pts[i], pts[i + 1]
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(Vector3.new(mid.X, 0.6, mid.Z), Vector3.new(b.X, 0.6, b.Z))
	local lane = part("Lane" .. i, Vector3.new(8, 0.4, (b - a).Magnitude + 8), cf, Color3.fromRGB(150, 142, 132), Enum.Material.Cobblestone)
	lane.MaterialVariant = "LampwickCobble" -- 2026-10-28 art pass: AI-made wet cobblestone (MaterialService); darker so it no longer blows out
	-- low dark kerb under the lane edges frames the path
	part("Kerb" .. i, Vector3.new(9.6, 0.3, (b - a).Magnitude + 9.6), cf * CFrame.new(0, -0.1, 0), Color3.fromRGB(28, 28, 34), Enum.Material.Slate)
end

-- Free placement (2026-10-27): no pads. Pets stand anywhere legal (Config.canPlace) on their own
-- footprint plate, drawn by the client. Config.SLOTS remains only as preferred spawn spots.

local last = pts[#pts]
local STONE = Color3.fromRGB(96, 94, 104)
local BRASS = Color3.fromRGB(176, 136, 72)
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- cylinders run along X; this stands them up

-- Ward Lantern (what you defend): the crystal is the glowing core of a brass lantern on a plinth.
-- "Crystal" keeps its name: the client pulses it and flashes it red when hit.
do
	local c = Vector3.new(last.X + 5, 0, last.Z)
	part("WardPlinth", Vector3.new(7, 1, 7), CFrame.new(c + Vector3.new(0, 0.5, 0)), STONE, Enum.Material.Slate)
	part("WardBase", Vector3.new(0.6, 6.4, 6.4), CFrame.new(c + Vector3.new(0, 1.3, 0)) * UPRIGHT, BRASS, Enum.Material.Metal, Enum.PartType.Cylinder)
	for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		part("WardPost", Vector3.new(0.45, 7.4, 0.45), CFrame.new(c + Vector3.new(s[1] * 2.7, 4.9, s[2] * 2.7)), BRASS, Enum.Material.Metal)
	end
	part("WardRing", Vector3.new(0.5, 6.4, 6.4), CFrame.new(c + Vector3.new(0, 8.6, 0)) * UPRIGHT, BRASS, Enum.Material.Metal, Enum.PartType.Cylinder)
	for i = 0, 3 do
		part("WardRoof", Vector3.new(6.4, 2.6, 3.2), CFrame.new(c + Vector3.new(0, 10.1, 0)) * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, 0, -1.6), Color3.fromRGB(40, 38, 48), Enum.Material.Metal, nil, true)
	end
	part("WardFinial", Vector3.new(0.9, 0.9, 0.9), CFrame.new(c + Vector3.new(0, 11.8, 0)), BRASS, Enum.Material.Metal, Enum.PartType.Ball)
	local core = part("Crystal", Vector3.new(4.6, 4.6, 4.6), CFrame.new(c + Vector3.new(0, 5.0, 0)), Color3.fromRGB(90, 220, 255), Enum.Material.Neon, Enum.PartType.Ball)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(110, 220, 255)
	glow.Range = 20
	glow.Brightness = 1.4
	glow.Parent = core
	-- 2026-10-28: each area has its own protected item (Game Design Doc "Theme arc"). workspace attribute WardStyle
	-- picks it: "Lampwick" (default, the steampunk start) = the brass steampunk lantern; "Cosmic" = the hero crystal
	-- with orbit rings (WardFX animates it). Missing art falls back to the primitive lantern above.
	local style = workspace:GetAttribute("WardStyle") or "Lampwick"
	core.Parent:SetAttribute("WardStyle", style)
	local function hidePrimitives()
		for _, n in { "WardPlinth", "WardBase", "WardPost", "WardRing", "WardRoof", "WardFinial" } do
			for _, p in core.Parent:GetChildren() do
				if p.Name == n and p:IsA("BasePart") then p.Transparency, p.CanCollide = 1, false end
			end
		end
	end
	-- clone a stored model, stand it on the plinth spot at the given height (by bounding box, not pivot: v1 floated)
	local function placeArt(src, height, drop)
		local m = src:Clone()
		for _, d in m:GetDescendants() do
			if d:IsA("PackageLink") then d:Destroy() end
			if d:IsA("BasePart") then d.Anchored, d.CanCollide, d.CastShadow = true, false, true end
		end
		for _, n in drop or {} do
			local sub = m:FindFirstChild(n)
			if sub then sub:Destroy() end
		end
		local _, s0 = m:GetBoundingBox()
		if type(height) == "function" then height = height(m, s0) end -- sized after the dropped parts are gone
		m:ScaleTo(m:GetScale() * height / s0.Y)
		local cfb, sb = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + Vector3.new(c.X - cfb.Position.X, (c.Y + sb.Y / 2) - cfb.Position.Y, c.Z - cfb.Position.Z))
		m.Name = "WardLantern"
		m.Parent = core.Parent
		hidePrimitives()
		return m, m:FindFirstChild("Crystal") or m:FindFirstChild("Crystal_Node") -- the importer renames it
	end
	local SS = game:GetService("ServerStorage")
	local lamp = style == "Lampwick" and SS:FindFirstChild("WardLampwickMesh")
	local art = style == "Cosmic" and SS:FindFirstChild("WardCosmicMesh")
	if lamp then
		local m, cry = placeArt(lamp, 14)
		-- reviewer v6: "add the stepped stone plinth": keep the old slate plinth and stand the lantern on it
		local plinth = core.Parent:FindFirstChild("WardPlinth")
		if plinth then
			plinth.Transparency, plinth.CanCollide = 0, true
			m:PivotTo(m:GetPivot() + Vector3.new(0, plinth.Size.Y, 0))
		end
		for _, d in (m:FindFirstChild("Glass") and m.Glass:GetDescendants() or {}) do
			if d:IsA("MeshPart") then d.Transparency, d.Reflectance = 0.7, 0.15 end
		end
		for _, d in (cry and cry:GetDescendants() or {}) do -- Hunyuan model: the crystal is a separate sphere: make it glow
			if d:IsA("MeshPart") then
				local sa = d:FindFirstChildOfClass("SurfaceAppearance")
				if sa then sa:Destroy() end
				d.Material, d.Color, d.Transparency = Enum.Material.Neon, Color3.fromRGB(150, 235, 255), 0.1
			end
		end
		local ccf, csize = (cry or m):GetBoundingBox()
		core.Size = Vector3.one * math.min(csize.X, csize.Z) * 0.3
		core.Position = ccf.Position
		glow.Range, glow.Brightness = 30, 2.2
	elseif art then
		-- the cosmic variant (asset 74543193086211): no cage or roof (reviewer: "the crystal must be the hero"); the
		-- whole model is sized so the crystal stands ~11 studs; the neon ball becomes a small heart in the facets
		local m, cry = placeArt(art, function(mm, size)
			local _, cs = (mm:FindFirstChild("Crystal") or mm):GetBoundingBox()
			return size.Y * 11 / cs.Y
		end, { "Frame", "Roof" })
		for _, d in (cry or m):GetDescendants() do
			if d:IsA("MeshPart") then d.Transparency = 0.05 end -- nearly opaque: 0.18 washed the facets out
		end
		local ccf, csize = (cry or m):GetBoundingBox()
		core.Size = Vector3.one * math.min(csize.X, csize.Z) * 0.22
		core.Position = ccf.Position - Vector3.new(0, csize.Y * 0.1, 0)
		glow.Range, glow.Brightness = 40, 3
	end
end

-- Fog Gate (where enemies come from): a stone arch with a swirling violet veil and mist spilling out.
-- "Portal" keeps its name: the client pulses its size and transparency.
do
	local c = Vector3.new(pts[1].X - 5, 0, pts[1].Z)
	for _, s in { -1, 1 } do
		part("GatePillar", Vector3.new(1.8, 11, 1.8), CFrame.new(c + Vector3.new(0, 5.5, s * 5.4)), STONE, Enum.Material.Slate)
		part("GateCap", Vector3.new(2.4, 0.6, 2.4), CFrame.new(c + Vector3.new(0, 11.3, s * 5.4)), STONE, Enum.Material.Slate)
	end
	part("GateLintel", Vector3.new(2, 1.6, 13), CFrame.new(c + Vector3.new(0, 12.4, 0)), STONE, Enum.Material.Slate)
	part("GateKeystone", Vector3.new(2.2, 2.2, 2.2), CFrame.new(c + Vector3.new(0, 13.3, 0)) * CFrame.Angles(math.rad(45), 0, 0), Color3.fromRGB(150, 60, 200), Enum.Material.Neon)
	local veil = part("Portal", Vector3.new(0.4, 9.6, 9.6), CFrame.new(c + Vector3.new(0.3, 5.9, 0)), Color3.fromRGB(120, 50, 180), Enum.Material.Neon, Enum.PartType.Cylinder)
	veil.Transparency = 0.2
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(Color3.fromRGB(150, 110, 210))
	mist.LightEmission = 0.4
	mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.7), NumberSequenceKeypoint.new(1, 1) })
	mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 9) })
	mist.Lifetime = NumberRange.new(2.5, 4)
	mist.Rate = 6
	mist.Speed = NumberRange.new(2, 4)
	mist.EmissionDirection = Enum.NormalId.Right
	mist.SpreadAngle = Vector2.new(25, 25)
	mist.Acceleration = Vector3.new(0, -0.6, 0)
	mist.Parent = veil
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(170, 100, 255)
	light.Range = 16
	light.Brightness = 1.2
	light.Parent = veil
end

map.Parent = workspace
