-- GCBossPlate (T198, 2026-10-29): block moved out of GameClient to stay under the 200,000-character script limit. Called once by GameClient with the outside locals it needs.
return function(env)
local Config, FXK, RunService, TweenService, UI, bossBar, bossBarBg, bossBarLabel, enemies, fmt, new, round, tween = env.Config, env.FXK, env.RunService, env.TweenService, env.UI, env.bossBar, env.bossBarBg, env.bossBarLabel, env.enemies, env.fmt, env.new, env.round, env.tween
-- ===== Boss plate "The Wick" (2026-10-28; user: "a more unique boss bar"). An iron-framed plate swings down on its
-- chains when a boss walks in: the boss's name, its life as a blood-red ribbon with a pale trail that catches up after
-- each hit, and the escape timer as a lamp wick burning down toward the left with a live flame. Under 10 s the flame
-- turns red and a pocket watch ticks every second. The old bar stays as the data source (applySnapshot sets it).
do
	local B = { last = -1, shown = false, ghost = 1, hp = 1, t = 1, drop = 0 }
	B.titles = { "THE GASLIGHT WARDEN", "THE BRASS LEVIATHAN", "THE HOLLOW BISHOP" } -- same names as the boss cutscene
	B.serif = Font.fromName("Merriweather", Enum.FontWeight.Bold)
	for _, c in bossBarBg:GetChildren() do
		if c:IsA("UIStroke") or c:IsA("UICorner") or c:IsA("UIGradient") then c:Destroy() end
	end
	for _, c in bossBar:GetChildren() do
		if c:IsA("UIStroke") or c:IsA("UICorner") or c:IsA("UIGradient") then c:Destroy() end
	end
	bossBarBg.BackgroundTransparency, bossBar.BackgroundTransparency, bossBarLabel.Visible = 1, 1, false
	bossBarBg.Size = UDim2.fromOffset(320, 78) -- compact: the top lane stays visible
	B.plate = new("Frame", { Name = "Plate", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1, 1), ZIndex = 2 }, bossBarBg)
	for _, x in { 0.2, 0.8 } do -- the chains it hangs from
		new("Frame", { BackgroundColor3 = Color3.fromRGB(40, 36, 40), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(x, 0.08), Size = UDim2.fromOffset(3, 22), ZIndex = 1 }, B.plate)
	end
	B.art = UI.objImg(B.plate, "plaque", UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), nil, 2, Enum.ScaleType.Stretch)
	B.art.ImageColor3 = Color3.fromRGB(175, 95, 90)
	B.title = new("TextLabel", { BackgroundTransparency = 1, FontFace = B.serif, TextScaled = true, TextColor3 = Color3.fromRGB(255, 200, 160), Text = "", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.new(0.8, 0, 0, 17), ZIndex = 5 }, B.plate)
	new("UIStroke", { Color = Color3.fromRGB(30, 8, 8), Thickness = 1.5 }, B.title)
	-- life ribbon
	B.rib = new("Frame", { BackgroundColor3 = Color3.fromRGB(30, 8, 10), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 29), Size = UDim2.new(0.84, 0, 0, 14), ZIndex = 3 }, B.plate)
	new("UIStroke", { Color = Color3.fromRGB(190, 140, 60), Thickness = 1.5 }, B.rib)
	B.ribScale = new("UIScale", { Scale = 1 }, B.rib)
	B.ghostF = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 225, 205), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 3 }, B.rib)
	B.fill = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 4 }, B.rib)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 110, 100)), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(190, 20, 40)), ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 0, 20)) }) }, B.fill)
	for i = 1, 3 do
		new("Frame", { BackgroundColor3 = Color3.fromRGB(190, 140, 60), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(i / 4, 0.5), Size = UDim2.new(0, 2, 1, 0), ZIndex = 5 }, B.rib)
	end
	B.hpText = new("TextLabel", { BackgroundTransparency = 1, FontFace = B.serif, TextScaled = true, TextColor3 = Color3.fromRGB(255, 240, 225), Text = "", Size = UDim2.fromScale(1, 0.85), Position = UDim2.fromScale(0, 0.08), ZIndex = 6 }, B.rib)
	new("UIStroke", { Color = Color3.fromRGB(40, 0, 0), Thickness = 1.2 }, B.hpText)
	-- the wick: charred trail behind, rope ahead, flame at the burning end
	B.ash = new("Frame", { BackgroundColor3 = Color3.fromRGB(40, 30, 28), BackgroundTransparency = 0.3, BorderSizePixel = 0, Position = UDim2.new(0.08, 0, 0, 51), Size = UDim2.new(0.84, 0, 0, 3), ZIndex = 3 }, B.plate)
	B.wick = new("Frame", { BackgroundColor3 = Color3.fromRGB(225, 205, 160), BorderSizePixel = 0, Position = UDim2.new(0.08, 0, 0, 50), Size = UDim2.new(0.84, 0, 0, 5), ZIndex = 4 }, B.plate)
	round(B.wick, 2)
	new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 225, 190)), ColorSequenceKeypoint.new(0.93, Color3.fromRGB(200, 170, 120)), ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 30, 20)) }) }, B.wick)
	B.flame = new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://108574647086501", AnchorPoint = Vector2.new(0.5, 0.85), Size = UDim2.fromOffset(18, 25), ZIndex = 6 }, B.plate)
	TweenService:Create(B.flame, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromOffset(15, 29), Rotation = 6 }):Play()
	B.timer = new("TextLabel", { BackgroundTransparency = 1, FontFace = B.serif, TextScaled = true, TextColor3 = Color3.fromRGB(255, 220, 170), Text = "", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 58), Size = UDim2.new(0.6, 0, 0, 13), ZIndex = 5 }, B.plate)
	RunService.Heartbeat:Connect(function(dt)
		if not bossBarBg.Visible then
			B.shown = false
			return
		end
		if not B.shown then -- entrance: the plate swings down on its chains with an iron clank
			B.shown, B.ghost, B.hp, B.t, B.last = true, 1, 1, 1, -1
			B.title.Text = B.titles[math.clamp(math.ceil(((env.getSnap() and env.getSnap().stage) or 5) / 5), 1, #B.titles)]
			B.plate.Position, B.plate.Rotation = UDim2.new(0.5, 0, 0, -110), -9
			tween(B.plate, 0.6, { Position = UDim2.fromScale(0.5, 0), Rotation = 0 }, Enum.EasingStyle.Back)
			FXK.play("iron_clank")
		end
		local boss
		for _, e in enemies do
			if e.big then boss = e break end
		end
		local hp = boss and math.clamp(boss.hp / boss.maxHp, 0, 1) or B.hp
		if hp < B.hp - 0.001 then -- a hit: the ribbon jolts and the pale trail waits a beat before catching up
			B.drop = os.clock()
			B.ribScale.Scale = 1.06
			tween(B.ribScale, 0.18, { Scale = 1 })
		end
		B.hp = hp
		if os.clock() - B.drop > 0.35 then B.ghost = math.max(hp, B.ghost - dt * 0.8) end
		B.fill.Size = UDim2.fromScale(hp, 1)
		B.ghostF.Size = UDim2.fromScale(math.max(hp, B.ghost), 1)
		B.hpText.Text = boss and (fmt(math.clamp(math.ceil(boss.hp), 0, math.ceil(boss.maxHp))) .. " / " .. fmt(math.ceil(boss.maxHp))) or ""
		B.t += (bossBar.Size.X.Scale - B.t) * math.min(1, dt * 6) -- the wick burns smoothly between snapshots
		B.wick.Size = UDim2.new(0.84 * B.t, 0, 0, 5)
		B.flame.Position = UDim2.new(0.08 + 0.84 * B.t, 0, 0, 53)
		local secs = math.max(0, math.ceil(bossBar.Size.X.Scale * Config.BOSS_TIME))
		B.timer.Text = "ESCAPES IN " .. secs .. "s"
		if secs ~= B.last then
			if secs <= 10 and B.last ~= -1 then FXK.play("clock_tick", { pitch = secs % 2 == 0 and 1 or 0.8 }) end
			B.last = secs
		end
		local low = secs <= 10
		B.flame.ImageColor3 = low and Color3.fromRGB(255, 90, 70) or Color3.new(1, 1, 1)
		B.timer.TextColor3 = low and Color3.fromRGB(255, 120, 110) or Color3.fromRGB(255, 220, 170)
	end)
end
end
