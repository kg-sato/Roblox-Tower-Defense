--!nocheck
-- TitleScene (StarterPlayerScripts ModuleScript, 2026-10-29). Title-page background: a huge faceless fog figure (the Unbound)
-- bends toward a tiny traveller on a bridge. Layers drift at different slow speeds, the figure breathes, a glow pulses,
-- god-rays turn, mist wraps, dust floats; intro = wipe from black, then it is never still. UI only: reads nothing from the server.
-- Art: UI Kit/art/title_bg (gold-ink palette). Called from StartMenuArt with its env; Scale-only sizes.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ID = { sky = "rbxassetid://92817932891073", rays = "rbxassetid://104036777344439", figure = "rbxassetid://90065295875133", ground = "rbxassetid://93486746494519",
	mistFar = "rbxassetid://86165216780461", mistNear = "rbxassetid://110511940628499", fg = "rbxassetid://94128836200313",
	glow = "rbxassetid://122630907915085" }
local GOLD, CREAM, INK = Color3.fromRGB(217, 184, 120), Color3.fromRGB(239, 230, 207), Color3.fromRGB(11, 10, 9)

return function(env)
	local sm = env.startScreen
	local reduced = env.reduced or function() return false end
	local function new(class, props, parent)
		local i = Instance.new(class)
		for k, v in props do i[k] = v end
		i.Parent = parent
		return i
	end
	local root = new("Frame", { Name = "TitleScene", BackgroundColor3 = INK, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, ZIndex = 10 }, sm)
	local function img(name, id, z, props)
		props = props or {}
		props.Name, props.Image, props.BackgroundTransparency, props.ZIndex = name, id, 1, z
		props.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
		props.Position = props.Position or UDim2.fromScale(0.5, 0.5)
		props.Size = props.Size or UDim2.fromScale(1, 1)
		return new("ImageLabel", props, root)
	end
	local sky = img("Sky", ID.sky, 10, { Size = UDim2.fromScale(1.06, 1.06), ScaleType = Enum.ScaleType.Crop })
	local rays = img("Rays", ID.rays, 11, { Position = UDim2.fromScale(0.64, 0.265), Size = UDim2.fromScale(1.8, 1.8), ImageTransparency = 0.35 })
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, rays)
	local ground = img("Ground", ID.ground, 12, { Size = UDim2.fromScale(1.04, 1.04), Position = UDim2.fromScale(0.5, 0.52) })
	local fig = img("Figure", ID.figure, 13, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1.02, 1.02) })
	local glow = img("HeadGlow", ID.glow, 12, { Position = UDim2.fromScale(0.64, 0.265), Size = UDim2.fromScale(0.26, 0.26), ImageColor3 = CREAM, ImageTransparency = 0.4 })
	new("UIAspectRatioConstraint", { AspectRatio = 1 }, glow)
	local mists = {}
	for k, d in { { "mistFar", 0.55, 0.03, 14, 0.72 }, { "mistNear", 0.76, 0.06, 15, 0.6 } } do
		for n = 0, 1 do
			mists[#mists + 1] = { img("Mist" .. k .. n, ID[d[1]], d[4], { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromScale(1, 0.4), Position = UDim2.fromScale(n, d[2]), ImageTransparency = d[5] }), n, d[2], d[3] }
		end
	end
	local fg = img("Foreground", ID.fg, 16, { Size = UDim2.fromScale(1.02, 1.02) })
	local lamp = img("LampGlow", ID.glow, 17, { Position = UDim2.fromScale(0.439, 0.77), Size = UDim2.fromScale(0.09, 0.09), ImageColor3 = GOLD, ImageTransparency = 0.45 })
	new("UIAspectRatioConstraint", { AspectRatio = 1 }, lamp)
	local dust = {}
	local rng = Random.new(7)
	for i = 1, 28 do
		local s = rng:NextNumber(0.0025, 0.006)
		local d = new("Frame", { BackgroundColor3 = CREAM, BackgroundTransparency = rng:NextNumber(0.5, 0.85), BorderSizePixel = 0, Size = UDim2.fromScale(s, s * 16 / 9), ZIndex = 17 }, root)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, d)
		dust[i] = { d, rng:NextNumber(), rng:NextNumber(0.2, 1), rng:NextNumber(0.004, 0.012), rng:NextNumber(0, 6.28) }
	end
	-- the left third stays calm for the title and buttons
	local shade = new("Frame", { Name = "LeftShade", BackgroundColor3 = INK, BorderSizePixel = 0, Size = UDim2.fromScale(0.55, 1), ZIndex = 18 }, root)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.3), NumberSequenceKeypoint.new(1, 1) }) }, shade)
	local cover = new("Frame", { Name = "Wipe", BackgroundColor3 = INK, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(1, 1), ZIndex = 19 }, root)
	if not reduced() then
		TweenService:Create(cover, TweenInfo.new(2.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0, 1) }):Play()
		fig.Position = UDim2.fromScale(0.5, 1.04)
		TweenService:Create(fig, TweenInfo.new(3.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 1) }):Play()
	else
		cover.Visible = false
	end
	task.delay(1.7, function() local f = sm:FindFirstChild("Featured"); if f then f.Visible = false end end) -- the familiar stage sat where the figure stands
	local t0, still = os.clock(), reduced()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not root.Parent then conn:Disconnect() return end
		if not sm.Visible then return end
		local t = still and 0 or os.clock() - t0
		sky.Position = UDim2.fromScale(0.5 + 0.014 * math.sin(t * 0.12), 0.5 + 0.009 * math.sin(t * 0.17))
		rays.Rotation = t * 1.6
		rays.ImageTransparency = 0.4 + 0.1 * math.sin(t * 0.4)
		local b = 1.02 + 0.016 * math.sin(t * 0.8)
		fig.Size = UDim2.fromScale(b, b)
		lamp.ImageTransparency = 0.5 + 0.15 * math.sin(t * 2.1)
		ground.Position = UDim2.fromScale(0.5 + 0.003 * math.sin(t * 0.2), 0.52)
		glow.ImageTransparency = 0.4 + 0.1 * math.sin(t * 0.8 + 0.6)
		for _, m in mists do m[1].Position = UDim2.fromScale((-t * m[4]) % 1 - 1 + m[2], m[3]) end
		fg.Position = UDim2.fromScale(0.5 + 0.004 * math.sin(t * 0.3), 0.5)
		for _, d in dust do
			local y = (d[2] - t * d[4]) % 1.0
			d[1].Position = UDim2.fromScale((d[3] + 0.015 * math.sin(t * 0.5 + d[5])) % 1, y)
		end
	end)
end
