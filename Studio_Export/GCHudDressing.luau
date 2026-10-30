-- GCHudDressing (T198, 2026-10-29): block moved out of GameClient to stay under the 200,000-character script limit. Called once by GameClient with the outside locals it needs.
return function(env)
local TweenService, hpBg, hpFill, hpLabel, hpPill, lvlBadge, lvlNum, lvlTitle, new, round, xpBg, xpFill, xpLabel = env.TweenService, env.hpBg, env.hpFill, env.hpLabel, env.hpPill, env.lvlBadge, env.lvlNum, env.lvlTitle, env.new, env.round, env.xpBg, env.xpFill, env.xpLabel
-- crystal life: a brass-capped glass vial of violet lamp-oil hanging under the stage sign (was a blue progress bar).
-- The liquid shimmers; under 30% it turns red and the glass pulses. Trainer: a brass clock-bezel medallion with a
-- flame behind the level, XP as a brass rail with an amber channel (same rail as the settings board).
do
	local GOLD, BRASS = Color3.fromRGB(255, 208, 110), Color3.fromRGB(190, 140, 60)
	local SERIF = Font.fromName("Merriweather", Enum.FontWeight.Bold)
	local function strip(g)
		for _, c in g:GetChildren() do
			if c:IsA("UIStroke") or c:IsA("UIGradient") then c:Destroy() end
		end
	end
	-- the vial
	strip(hpBg)
	hpBg.BackgroundColor3, hpBg.BackgroundTransparency = Color3.fromRGB(20, 12, 30), 0.1
	new("UIStroke", { Color = BRASS, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, hpBg)
	for _, x in { 0, 1 } do -- brass end caps
		local cap = new("Frame", { Name = "Cap", BackgroundColor3 = BRASS, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.5), Size = UDim2.new(0, 12, 1, 10), ZIndex = 6 }, hpBg)
		round(cap, 4)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 160)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 140, 60)), ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 70, 30)) }) }, cap)
	end
	strip(hpFill)
	hpFill.BackgroundColor3 = Color3.new(1, 1, 1)
	local liquid = new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(120, 60, 220), Color3.fromRGB(200, 150, 255)) }, hpFill)
	local glint = new("Frame", { Name = "Glint", BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), ZIndex = 3 }, hpFill)
	round(glint, 11)
	local gg = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1) }), Offset = Vector2.new(-1, 0) }, glint)
	TweenService:Create(gg, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1), { Offset = Vector2.new(1, 0) }):Play()
	-- glass reflection along the top of the tube
	local shine = new("Frame", { Name = "Shine", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, Position = UDim2.new(0, 8, 0, 3), Size = UDim2.new(1, -16, 0, 3), ZIndex = 4 }, hpBg)
	round(shine, 2)
	for _, c in hpPill:GetChildren() do -- the crystal icon sits on top of the left cap
		if c:IsA("ImageLabel") then c.ZIndex = 8 end
	end
	hpLabel.FontFace = SERIF
	hpLabel.TextColor3 = Color3.fromRGB(255, 240, 210)
	hpLabel.ZIndex = 7
	local pulse
	hpFill:GetPropertyChangedSignal("Size"):Connect(function()
		local low = hpFill.Size.X.Scale < 0.3
		liquid.Color = low and ColorSequence.new(Color3.fromRGB(170, 30, 40), Color3.fromRGB(255, 120, 110)) or ColorSequence.new(Color3.fromRGB(120, 60, 220), Color3.fromRGB(200, 150, 255))
		if low and not pulse then
			pulse = TweenService:Create(hpBg, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundColor3 = Color3.fromRGB(70, 14, 20) })
			pulse:Play()
		elseif not low and pulse then
			pulse:Cancel()
			pulse = nil
			hpBg.BackgroundColor3 = Color3.fromRGB(20, 12, 30)
		end
	end)

	-- the trainer medallion
	strip(lvlBadge)
	lvlBadge.BackgroundColor3 = Color3.fromRGB(44, 28, 20)
	new("UIStroke", { Color = GOLD, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, lvlBadge)
	new("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(255, 235, 200), Color3.fromRGB(120, 90, 70)) }, lvlBadge)
	local inner = new("Frame", { Name = "Bezel", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.74, 0.74), ZIndex = 4 }, lvlBadge)
	round(inner, 23)
	new("UIStroke", { Color = BRASS, Thickness = 1.5, Transparency = 0.2 }, inner)
	for i = 0, 11 do -- clock ticks round the bezel
		local a = math.rad(i * 30)
		local big = i % 3 == 0
		new("Frame", { BackgroundColor3 = big and GOLD or BRASS, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + 0.43 * math.sin(a), 0.5 - 0.43 * math.cos(a)), Size = UDim2.fromOffset(2, big and 6 or 4), Rotation = i * 30, ZIndex = 5 }, lvlBadge)
	end
	local flame = new("ImageLabel", { Name = "Flame", BackgroundTransparency = 1, Image = "rbxassetid://108574647086501", ImageTransparency = 0.55, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromScale(0.62, 0.62), ZIndex = 4 }, lvlBadge)
	TweenService:Create(flame, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { ImageTransparency = 0.35, Size = UDim2.fromScale(0.58, 0.66) }):Play()
	lvlNum.FontFace = SERIF
	lvlNum.TextColor3 = Color3.fromRGB(255, 236, 200)
	lvlNum.ZIndex = 6
	lvlTitle.FontFace = SERIF
	-- XP rail
	strip(xpBg)
	xpBg.BackgroundColor3 = Color3.fromRGB(28, 18, 12)
	new("UIStroke", { Color = BRASS, Thickness = 1.5 }, xpBg)
	strip(xpFill)
	xpFill.BackgroundColor3 = Color3.new(1, 1, 1)
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(150, 60, 20), Color3.fromRGB(255, 220, 140)) }, xpFill)
	for i = 1, 3 do
		new("Frame", { BackgroundColor3 = BRASS, BackgroundTransparency = 0.3, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 2, 0.5, 0), Position = UDim2.fromScale(i / 4, 0.5), ZIndex = 4 }, xpBg)
	end
	xpLabel.FontFace = SERIF
	xpLabel.TextColor3 = Color3.fromRGB(255, 240, 210)
	xpLabel.ZIndex = 5
end
end
