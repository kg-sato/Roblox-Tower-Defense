--!nocheck
-- TitleScene (StarterPlayerScripts ModuleScript, 2026-10-29). Title-page background: a huge faceless fog figure (the Unbound)
-- bends toward a tiny traveller on a bridge. Layers drift at different slow speeds, the figure breathes, a glow pulses,
-- god-rays turn, mist wraps, dust floats; intro = wipe from black, then it is never still. UI only: reads nothing from the server.
-- Art: UI Kit/art/title_bg (gold-ink palette). Called from StartMenuArt with its env; Scale-only sizes.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ID = { sky = "rbxassetid://135189074641926", rays = "rbxassetid://96973107269185", figure = "rbxassetid://118678537152629",
	mistFar = "rbxassetid://82813632895739", mistNear = "rbxassetid://108963568266256", fg = "rbxassetid://97923729896441",
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
	local rays = img("Rays", ID.rays, 11, { Position = UDim2.fromScale(0.55, 0.05), Size = UDim2.fromScale(1.6, 1.6), ImageTransparency = 0.35 })
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, rays)
	local fig = img("Figure", ID.figure, 12, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1.02, 1.02) })
	local glow = img("HeadGlow", ID.glow, 12, { Position = UDim2.fromScale(0.585, 0.3), Size = UDim2.fromScale(0.2, 0.2), ImageColor3 = GOLD, ImageTransparency = 0.7 })
	new("UIAspectRatioConstraint", { AspectRatio = 1 }, glow)
	local mists = {}
	for k, d in { { "mistFar", 0.5, 0.03, 13, 0.55 }, { "mistNear", 0.72, 0.06, 15, 0.3 } } do
		for n = 0, 1 do
			mists[#mists + 1] = { img("Mist" .. k .. n, ID[d[1]], d[4], { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromScale(1, 0.4), Position = UDim2.fromScale(n, d[2]), ImageTransparency = d[5] }), n, d[2], d[3] }
		end
	end
	local fg = img("Foreground", ID.fg, 16, { Size = UDim2.fromScale(1.02, 1.02) })
	local dust = {}
	local rng = Random.new(7)
	for i = 1, 28 do
		local s = rng:NextNumber(0.0025, 0.006)
		local d = new("Frame", { BackgroundColor3 = CREAM, BackgroundTransparency = rng:NextNumber(0.5, 0.85), BorderSizePixel = 0, Size = UDim2.fromScale(s, s * 16 / 9), ZIndex = 17 }, root)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, d)
		dust[i] = { d, rng:NextNumber(), rng:NextNumber(0.2, 1), rng:NextNumber(0.004, 0.012), rng:NextNumber(0, 6.28) }
	end
	-- the left third stays calm for the title and buttons
	local shade = new("Frame", { Name = "LeftShade", BackgroundColor3 = INK, BorderSizePixel = 0, Size = UDim2.fromScale(0.42, 1), ZIndex = 18 }, root)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }) }, shade)
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
		glow.ImageTransparency = 0.72 + 0.12 * math.sin(t * 0.8 + 0.6)
		for _, m in mists do m[1].Position = UDim2.fromScale((-t * m[4]) % 1 - 1 + m[2], m[3]) end
		fg.Position = UDim2.fromScale(0.5 + 0.004 * math.sin(t * 0.3), 0.5)
		for _, d in dust do
			local y = (d[2] - t * d[4]) % 1.0
			d[1].Position = UDim2.fromScale((d[3] + 0.015 * math.sin(t * 0.5 + d[5])) % 1, y)
		end
	end)
end
