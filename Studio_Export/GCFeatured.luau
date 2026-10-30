-- GCFeatured (T198, 2026-10-29): block moved out of GameClient to stay under the 200,000-character script limit. Called once by GameClient with the outside locals it needs.
return function(env)
local Config, Models, RunService, STYLE, TweenService, label, new, startScreen = env.Config, env.Models, env.RunService, env.STYLE, env.TweenService, env.label, env.new, env.startScreen
-- featured familiar: a Legendary turning on a glowing pedestal (ViewportFrame + WorldModel)
do
	local legend = Config.petsOfRarity("Legendary")[1] or next(Config.PETS)
	local stage = new("Frame", { Name = "Featured", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.95, 0.52), Size = UDim2.fromScale(0.36, 0.64), ZIndex = 11 }, startScreen)
	new("UIAspectRatioConstraint", { AspectRatio = 0.9 }, stage)
	local halo = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.62, 0.55), BackgroundColor3 = Config.RARITIES.Legendary.color, BackgroundTransparency = 0.8, ZIndex = 11 }, stage)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, halo)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.7, 0.85), NumberSequenceKeypoint.new(1, 1) }) }, halo)
	TweenService:Create(halo, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.9 }):Play()
	local vpf = new("ViewportFrame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12, Ambient = Color3.fromRGB(150, 140, 170), LightColor = Color3.fromRGB(255, 230, 190), LightDirection = Vector3.new(-1, -1, -0.6) }, stage)
	local world = new("WorldModel", {}, vpf)
	local vcam = new("Camera", { FieldOfView = 30 }, vpf)
	vpf.CurrentCamera = vcam
	local ok, model = pcall(function() return (Models.buildPet(legend, 3)) end)
	if ok and model then
		model.Parent = world
		local cf, size = model:GetBoundingBox()
		local radius = math.max(size.X, size.Y, size.Z)
		local focus = cf.Position
		local spin = 0
		local conn
		conn = RunService.RenderStepped:Connect(function(dt)
			if not startScreen.Parent then conn:Disconnect() return end
			if not startScreen.Visible then return end
			spin += dt * 0.6
			model:PivotTo(CFrame.new(focus) * CFrame.Angles(0, spin, 0) * (cf - cf.Position))
			vcam.CFrame = CFrame.lookAt(focus + Vector3.new(0, radius * 0.35, radius * 2.6), focus)
		end)
		pcall(function() Models.playClip(model, "Idle") end)
	end
	local name = label(stage, string.upper(Config.PETS[legend].name), 30, Color3.fromRGB(255, 236, 190), Vector2.new(0.5, 1), UDim2.fromScale(0.5, 0.97), UDim2.fromScale(1, 0.08), STYLE.display)
	name.ZIndex = 13
	local tag = label(stage, "FEATURED  ·  LEGENDARY", 15, Config.RARITIES.Legendary.color, Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1.03), UDim2.fromScale(1, 0.05), STYLE.fontB)
	tag.ZIndex = 13
end
end
