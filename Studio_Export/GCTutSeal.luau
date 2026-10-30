-- GCTutSeal (T198, 2026-10-29): block moved out of GameClient to stay under the 200,000-character script limit. Called once by GameClient with the outside locals it needs.
return function(env)
local SETTINGS, STYLE, TweenService, UI, label, new, tutCard, tutSkip, tutText = env.SETTINGS, env.STYLE, env.TweenService, env.UI, env.label, env.new, env.tutCard, env.tutSkip, env.tutText
-- the tutorial is a note from the Lamplighter (/make-creative 2026-10-28): parchment, ink that writes itself in, a wax
-- seal with the lamp's flame as the guide's portrait, a signature, and Skip as a small brass tag
do
	local g = tutCard:FindFirstChild("Glass")
	if g then g.Visible = false end
	tutCard.BackgroundTransparency = 0
	tutCard.BackgroundColor3 = Color3.fromRGB(236, 222, 190)
	tutCard.Size = UDim2.fromOffset(540, 92)
	for _, c in tutCard:GetChildren() do if c:IsA("UIStroke") then c.Color = Color3.fromRGB(150, 110, 60); c.Thickness = 2 end end
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(250, 240, 216), Color3.fromRGB(208, 188, 150)) }, tutCard)
	local seal = new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://78303286285946", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(78, 78), ZIndex = 8 }, tutCard)
	local fl = new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://108574647086501", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.5, 0.6), ZIndex = 9 }, seal)
	TweenService:Create(fl, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 6 }):Play()
	tutText.Position = UDim2.new(0, 52, 0.5, -6)
	tutText.Size = UDim2.new(1, -150, 1, -26)
	tutText.TextColor3 = Color3.fromRGB(58, 40, 26)
	tutText.TextStroke.Transparency = 1
	local sig = label(tutCard, "- the Lamplighter", 14, Color3.fromRGB(120, 40, 30), Vector2.new(1, 1), UDim2.new(1, -104, 1, -4), UDim2.fromOffset(160, 18), STYLE.font)
	sig.ZIndex = 8
	sig.TextXAlignment = Enum.TextXAlignment.Right
	sig.TextStroke.Transparency = 1
	-- ink writes itself in whenever the step changes
	tutText:GetPropertyChangedSignal("Text"):Connect(function()
		if SETTINGS.reducedMotion then tutText.MaxVisibleGraphemes = -1 return end
		tutText.MaxVisibleGraphemes = 0
		if tutText.Text ~= "" and UI.play then UI.play("menu_open", { pitch = 0.75, volume = 0.6 }) end
		local n = utf8.len(tutText.Text) or #tutText.Text
		local t0 = os.clock()
		task.spawn(function()
			while tutText.MaxVisibleGraphemes ~= -1 do
				local k = math.floor((os.clock() - t0) * 60)
				if k >= n then tutText.MaxVisibleGraphemes = -1 break end
				tutText.MaxVisibleGraphemes = k
				task.wait()
			end
		end)
	end)
	UI.objectify(tutSkip) -- Skip as a small brass tag
	UI.objImg(tutSkip, "plaque", UDim2.new(1, 8, 1, 6), UDim2.fromScale(0.5, 0.5), nil, 6, Enum.ScaleType.Stretch)
	local st = tutSkip:FindFirstChild("Txt")
	if st then st.ZIndex = 8; st.TextColor3 = Color3.fromRGB(255, 224, 150) end
end
end
