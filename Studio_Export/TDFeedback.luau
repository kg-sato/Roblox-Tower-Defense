--!nocheck
-- TDFeedback: tower-defense feedback sized for the far board camera (bold shapes, big on screen).
-- Flat effects lie on the ground as a thin Part with a SurfaceGui (FrameArt ring / sigil images, no upload needed), so
-- they do not float or get cut by the ground the way billboards did (T25). Particles go through FlipbookFX.
-- Install as ReplicatedStorage.TDFeedback (HTTP pull from VFX/). Client side only.
--
--   TDFeedback.placement(pos, color)                 -- ring snaps in + sigil turns, then fades (about 0.8 s)
--   TDFeedback.upgrade(pos, color, tier)             -- light column + `tier` chevrons climbing it (about 1 s)
--   local h = TDFeedback.range(pos, radius, color)   -- range ring that stays; h.hide()
--   TDFeedback.splash(pos, radius, color)            -- one splash ring pulse
--   TDFeedback.coinDrop(pos)                         -- a coin pops up, spins, lands with a glint
-- TDFeedback.timeScale > 1 slows everything down (captures only).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local T = { timeScale = 1 }

local okFA, FA = pcall(function()
	return require(ReplicatedStorage:WaitForChild("FrameArt", 3))
end)
FA = okFA and FA or nil
local okF, F = pcall(function()
	return require(ReplicatedStorage:WaitForChild("FlipbookFX", 3))
end)
F = okF and F or nil
if F then
	F.defineDefaults()
end

local function folder()
	local f = workspace:FindFirstChild("TDFeedback")
	if not f then
		f = Instance.new("Folder")
		f.Name = "TDFeedback"
		f.Parent = workspace
	end
	return f
end

local function tw(inst, t, props, style, dir)
	local tween = TweenService:Create(inst, TweenInfo.new(t * T.timeScale, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

local function later(inst, t)
	task.delay(t * T.timeScale, function()
		if inst.Parent then
			inst:Destroy()
		end
	end)
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	for k, v in props do
		p[k] = v
	end
	p.Parent = folder()
	return p
end

-- A flat image on the ground: invisible thin part + SurfaceGui on its top face. Returns part, image label.
local function decal(pos, size, art, color)
	local p = part({ Transparency = 1, Size = Vector3.new(size, 0.05, size), CFrame = CFrame.new(pos + Vector3.new(0, 0.75, 0)) }) -- above the path tiles, which stand about 0.6 studs proud
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Top
	sg.LightInfluence = 0
	sg.Brightness = 2
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 24
	sg.Parent = p
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromScale(0.5, 0.5)
	img.Size = UDim2.fromScale(1, 1)
	img.ImageColor3 = color
	if FA then
		img.ImageContent = art == "sigil" and FA.sigil() or (art == "glow" and FA.glow() or (FA.thinRing and FA.thinRing() or FA.ring()))
	else
		img.Image = "rbxasset://textures/particles/sparkles_main.dds"
	end
	img.Parent = sg
	return p, img
end

function T.placement(pos: Vector3, color: Color3)
	local p, ring = decal(pos, 12, "ring", color)
	ring.Size = UDim2.fromScale(1.6, 1.6)
	ring.ImageTransparency = 0.6
	tw(ring, 0.18, { Size = UDim2.fromScale(0.75, 0.75), ImageTransparency = 0 }, Enum.EasingStyle.Back)
	local sp, sig = decal(pos, 9, "sigil", color:Lerp(Color3.new(1, 1, 1), 0.3))
	sig.ImageTransparency = 1
	tw(sig, 0.2, { ImageTransparency = 0.15 })
	tw(sig, 0.8, { Rotation = 90 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	task.delay(0.45 * T.timeScale, function()
		tw(ring, 0.35, { ImageTransparency = 1, Size = UDim2.fromScale(1.05, 1.05) })
		tw(sig, 0.35, { ImageTransparency = 1 })
	end)
	later(p, 0.85)
	later(sp, 0.85)
end

function T.upgrade(pos: Vector3, color: Color3, tier: number)
	local h = 14
	local col = part({ Shape = Enum.PartType.Cylinder, Color = color, Transparency = 0.35, Size = Vector3.new(h, 1.6, 1.6), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	tw(col, 0.15, { Size = Vector3.new(h, 2.6, 2.6) }, Enum.EasingStyle.Back)
	task.delay(0.5 * T.timeScale, function()
		tw(col, 0.45, { Transparency = 1, Size = Vector3.new(h, 0.3, 0.3) })
	end)
	later(col, 1.0)
	for i = 1, math.clamp(tier or 1, 1, 5) do
		task.delay((0.08 * i) * T.timeScale, function()
			local y0 = 2 + i * 0.6
			local base = CFrame.new(pos + Vector3.new(0, y0, 0))
			local arms = {}
			for _, s in { -1, 1 } do -- a chevron: two bars meeting in a point
				local a = part({ Color = Color3.new(1, 1, 1):Lerp(color, 0.35), Size = Vector3.new(2.6, 0.45, 0.45), CFrame = base * CFrame.new(s * 1.0, 0, 0) * CFrame.Angles(0, 0, math.rad(-s * 35)) })
				table.insert(arms, a)
			end
			for _, a in arms do
				tw(a, 0.7, { CFrame = a.CFrame + Vector3.new(0, 7, 0), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				later(a, 0.75)
			end
		end)
	end
	if F then
		F.play("Sparkle", CFrame.new(pos + Vector3.new(0, 3, 0)), { scale = 1.6, color = color })
	end
end

function T.range(pos: Vector3, radius: number, color: Color3)
	local p, ring = decal(pos, radius * 2, "ring", color)
	ring.ImageTransparency = 1
	tw(ring, 0.2, { ImageTransparency = 0.35 })
	-- no filled disc: on a SurfaceGui a faint colour fill reads as a dark plate that hides the street (T40)
	return {
		part = p,
		hide = function()
			tw(ring, 0.15, { ImageTransparency = 1 })
			later(p, 0.2)
		end,
	}
end

function T.splash(pos: Vector3, radius: number, color: Color3)
	local p, ring = decal(pos, radius * 2, "ring", color)
	ring.Size = UDim2.fromScale(0.2, 0.2)
	tw(ring, 0.35, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Quint)
	tw(ring, 0.45, { ImageTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	later(p, 0.5)
end

function T.coinDrop(pos: Vector3)
	local gold = Color3.fromRGB(255, 208, 96)
	local coin = part({ Shape = Enum.PartType.Cylinder, Color = gold, Material = Enum.Material.Neon, Size = Vector3.new(0.35, 2.4, 2.4), CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0)) })
	local rim = part({ Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(200, 140, 30), Material = Enum.Material.SmoothPlastic, Size = Vector3.new(0.3, 2.7, 2.7), CFrame = coin.CFrame })
	local t0 = os.clock()
	local up, dur = 6, 0.7 * T.timeScale
	local conn
	conn = game:GetService("RunService").RenderStepped:Connect(function()
		local a = math.min(1, (os.clock() - t0) / dur)
		local y = 1.5 + up * 4 * a * (1 - a) -- up and back down
		local cf = CFrame.new(pos + Vector3.new(0, y, 0)) * CFrame.Angles(0, a * math.pi * 4, 0) * CFrame.Angles(0, 0, math.rad(90))
		if coin.Parent then
			coin.CFrame, rim.CFrame = cf, cf
		end
		if a >= 1 then
			conn:Disconnect()
			if F then
				F.play("Sparkle", CFrame.new(pos + Vector3.new(0, 1.5, 0)), { scale = 1.4, color = gold })
			end
			tw(coin, 0.25, { Transparency = 1 })
			tw(rim, 0.25, { Transparency = 1 })
			later(coin, 0.3)
			later(rim, 0.3)
		end
	end)
end

return T
