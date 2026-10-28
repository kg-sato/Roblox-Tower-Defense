--!nocheck
-- StartMenuArt (StarterPlayerScripts ModuleScript, 2026-10-28). The start menu, refined after the user's HUD
-- reference (everything small, aligned to one column, nothing overlapping, sitting cleanly under Roblox's own top bar):
--   * the title is an image in Beyond Wonderland (inky, smeared Victorian letters); it arrives with two fading echo
--     copies sliding into place, so it smears in
--   * one left column on a single edge: title, a one-line italic tagline, a flourish rule, the lamp button, the gazette
--   * the lamp button: a dark plate with an engraved double rule, a gas flame and the words in Beyond Wonderland; a
--     light glint sweeps across on hover and the flame rises
--   * the featured familiar stands in front of the turning brass clock from the loading screen (one story)
-- Called once from GameClient after the start screen is built; it waits for the abstract passes and hides their
-- shapes (AbstractScreens / AbstractLayer), then builds its own. GameClient's PLAY button stays the hit area.
local TweenService = game:GetService("TweenService")

return function(env)
	local sm, btn = env.startScreen, env.startBtn
	local A = require(game:GetService("ReplicatedStorage"):WaitForChild("ArtIds"))
	local reduced = env.reduced or function() return false end
	local function new(class, props, parent)
		local i = Instance.new(class)
		for k, v in props do i[k] = v end
		i.Parent = parent
		return i
	end
	local function tw(i, t, p, s, d)
		local x = TweenService:Create(i, TweenInfo.new(t, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p)
		x:Play()
		return x
	end
	local GOLD, IVORY, MUTED, PLATE = Color3.fromRGB(226, 186, 120), Color3.fromRGB(238, 230, 214), Color3.fromRGB(214, 204, 188), Color3.fromRGB(16, 12, 18)

	task.delay(1.6, function() -- after AbstractScreens (1 s) and AbstractLayer have run
		local holder = sm:FindFirstChild("MenuHolder")
		local menu = holder and holder:FindFirstChild("Menu")
		if not menu then return end
		local news = menu:FindFirstChild("News")
		local newsLines = {}
		if news then
			for _, d in news:GetDescendants() do
				if d:IsA("TextLabel") and d.Text:find("\n") then
					for line in d.Text:gmatch("[^\n]+") do table.insert(newsLines, line) end
				end
			end
		end
		holder.Size = UDim2.fromOffset(470, 470)
		for _, c in menu:GetChildren() do
			if c:IsA("GuiObject") and c ~= btn and c.Name ~= "FlashNotice" and c.Name ~= "FlashToggle" then c.Visible = false end
		end
		-- the photosensitivity notice and its switch: one line at the bottom of the column
		local note, toggle = menu:FindFirstChild("FlashNotice"), menu:FindFirstChild("FlashToggle")
		if note then
			note.AnchorPoint, note.Position, note.Size, note.TextScaled = Vector2.new(0, 0), UDim2.fromOffset(0, 446), UDim2.fromOffset(160, 30), false
			note.TextSize, note.TextXAlignment, note.TextColor3 = 17, Enum.TextXAlignment.Left, Color3.fromRGB(200, 190, 176)
		end
		if toggle then
			toggle.AnchorPoint, toggle.Position, toggle.Size = Vector2.new(0, 0), UDim2.fromOffset(170, 446), UDim2.fromOffset(170, 30) -- right edge = the lamp plate's
			for _, c in toggle:GetChildren() do if c:IsA("ImageLabel") then c.Visible = false elseif c:IsA("UICorner") then c:Destroy() end end -- the violet brass plate; square like the lamp plate
			toggle.BackgroundColor3, toggle.BackgroundTransparency = PLATE, 0.15
			for _, c in toggle:GetChildren() do if c:IsA("UIStroke") then c.Color, c.Transparency = GOLD, 0.5 end end
			for _, l in toggle:GetDescendants() do -- same face as the lamp button (review: a third, heavier face read bolted on)
				if l:IsA("TextLabel") then
					l:SetAttribute("KeepFont", true)
					l.FontFace, l.TextScaled, l.TextSize, l.TextColor3 = Font.new("rbxasset://fonts/families/Fondamento.json"), false, 19, Color3.fromRGB(250, 236, 206)
				end
			end
			if not toggle:FindFirstChildOfClass("UIStroke") then new("UIStroke", { Color = GOLD, Thickness = 1, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, toggle) end
		end
		-- the PLAY button: keep it as the invisible hit area over the new plate
		for _, d in btn:GetDescendants() do if d:IsA("GuiObject") then d.Visible = false end end
		btn.BackgroundTransparency, btn.TextTransparency = 1, 1
		btn.AnchorPoint, btn.Position, btn.Size = Vector2.new(0, 0), UDim2.fromOffset(0, 236), UDim2.fromOffset(340, 66)
		btn.ZIndex = 20

		local col = new("Frame", { Name = "SM2", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12 }, menu)
		-- title + two echo copies that slide down into it (the smear)
		local TW, TH = 470, 109 -- the title image is 1525 x 355
		local title = new("ImageLabel", { Name = "Title", BackgroundTransparency = 1, Image = A.title, Position = UDim2.fromOffset(-20, 20), Size = UDim2.fromOffset(TW, TH), ZIndex = 14 }, col)
		local echoes = {}
		for k = 1, 2 do
			echoes[k] = new("ImageLabel", { BackgroundTransparency = 1, Image = A.title, Position = UDim2.fromOffset(-20, 20 - k * 14), Size = UDim2.fromOffset(TW, TH), ImageTransparency = 0.55 + k * 0.15, ZIndex = 13 }, col)
		end
		local tag = new("TextLabel", { Name = "Tagline", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 140), Size = UDim2.fromOffset(470, 26), Text = "Summon familiars. Merge three that touch. Hold the lamplit lane.", TextSize = 20, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 14 }, col)
		tag.FontFace = Font.new("rbxasset://fonts/families/AccanthisADFStd.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
		-- flourish rule: a line that fades out to the right, a small diamond where it starts
		local rule = new("Frame", { BackgroundColor3 = GOLD, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 190), Size = UDim2.fromOffset(328, 1), ZIndex = 14 }, col)
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, rule)
		new("Frame", { BackgroundColor3 = GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(4, 190), Size = UDim2.fromOffset(7, 7), Rotation = 45, ZIndex = 14 }, col)

		-- the lamp plate
		local plate = new("Frame", { Name = "LampPlate", BackgroundColor3 = PLATE, BackgroundTransparency = 0.15, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 236), Size = UDim2.fromOffset(340, 66), ClipsDescendants = true, ZIndex = 14 }, col)
		local outer = new("UIStroke", { Color = GOLD, Thickness = 1.5, Transparency = 0.35 }, plate)
		local innerF = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), ZIndex = 14 }, plate)
		new("UIStroke", { Color = GOLD, Thickness = 1, Transparency = 0.7 }, innerF)
		local glint = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.88, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(-0.3, 0, 0.5, 0), Size = UDim2.new(0, 60, 2, 0), Rotation = 20, ZIndex = 15 }, plate)
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, glint)
		local flameHalo = new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow, ImageColor3 = Color3.fromRGB(255, 170, 80), ImageTransparency = 0.55, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(38, 33), Size = UDim2.fromOffset(70, 70), ZIndex = 15 }, plate)
		local flame = new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://108574647086501", AnchorPoint = Vector2.new(0.5, 0.75), Position = UDim2.fromOffset(38, 44), Size = UDim2.fromOffset(30, 40), ZIndex = 16 }, plate)
		TweenService:Create(flame, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 4 }):Play()
		new("Frame", { BackgroundColor3 = GOLD, BackgroundTransparency = 0.6, BorderSizePixel = 0, Position = UDim2.fromOffset(72, 14), Size = UDim2.new(0, 1, 1, -28), ZIndex = 15 }, plate)
		-- review: the rendered label read muddy at this size; light ink in the calligraphic face, with a soft shadow
		local words = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 88, 0.5, 0), Size = UDim2.new(1, -104, 0, 40), Text = "Light the Lamp", TextSize = 30, TextColor3 = Color3.fromRGB(250, 236, 206), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 16 }, plate)
		words:SetAttribute("KeepFont", true)
		words.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json")
		new("UIStroke", { Color = Color3.fromRGB(30, 16, 6), Thickness = 1.5, Transparency = 0.35 }, words)
		btn.MouseEnter:Connect(function()
			tw(outer, 0.2, { Transparency = 0 })
			tw(flame, 0.25, { Size = UDim2.fromOffset(40, 54) }, Enum.EasingStyle.Back)
			tw(flameHalo, 0.25, { ImageTransparency = 0.25, Size = UDim2.fromOffset(96, 96) })
			if not reduced() then
				glint.Position = UDim2.new(-0.3, 0, 0.5, 0)
				tw(glint, 0.55, { Position = UDim2.new(1.3, 0, 0.5, 0) }, Enum.EasingStyle.Sine)
			end
		end)
		btn.MouseLeave:Connect(function()
			tw(outer, 0.2, { Transparency = 0.35 })
			tw(flame, 0.2, { Size = UDim2.fromOffset(30, 40) })
			tw(flameHalo, 0.2, { ImageTransparency = 0.55, Size = UDim2.fromOffset(70, 70) })
		end)
		btn.MouseButton1Down:Connect(function() tw(plate, 0.08, { Position = UDim2.fromOffset(0, 238) }) end)
		btn.MouseButton1Up:Connect(function() tw(plate, 0.12, { Position = UDim2.fromOffset(0, 236) }) end)
		btn.Activated:Connect(function() tw(flame, 0.15, { Size = UDim2.fromOffset(70, 92) }) end)

		-- the gazette: a small heading and three short lines, same left edge, under the button
		local head = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 326), Size = UDim2.fromOffset(470, 24), Text = "The Lampwick Gazette", TextSize = 21, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 14 }, col)
		head:SetAttribute("KeepFont", true)
		head.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json")
		for i, line in newsLines do
			if i > 3 then break end
			new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 354 + (i - 1) * 26), Size = UDim2.fromOffset(560, 24), Text = "·  " .. line, TextSize = 18, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 14 }, col)
		end

		-- arrival: the echoes catch up with the title, the rest fades in from the left
		if not reduced() then
			title.ImageTransparency = 1
			tw(title, 0.6, { ImageTransparency = 0 })
			for k, e in echoes do
				e.Position = UDim2.fromOffset(-20 - k * 30, 20 - k * 22)
				tw(e, 0.7 + k * 0.12, { Position = UDim2.fromOffset(-20, 20), ImageTransparency = 1 }, Enum.EasingStyle.Quint)
			end
			for i, o in { tag, rule, plate, head } do
				local p = o.Position
				o.Position = p - UDim2.fromOffset(16, 0)
				task.delay(0.2 + i * 0.08, function() tw(o, 0.45, { Position = p }, Enum.EasingStyle.Quint) end)
			end
		else
			for _, e in echoes do e.ImageTransparency = 1 end
		end

		-- featured familiar: hide the abstract violet disc, orbits and rays; a brass clock turns slowly behind it
		local featured = sm:FindFirstChild("Featured")
		if featured then
			for _, c in featured:GetDescendants() do -- also the grey light pillar (a tall thin shape) that read as a bug
				if c:IsA("GuiObject") and not c:IsA("ViewportFrame") and not c:IsA("TextLabel") and not c:FindFirstAncestorOfClass("ViewportFrame")
					and ((c:IsA("Frame") and c.BackgroundTransparency < 1) or (c:IsA("ImageLabel") and c.Name:match("^Abs_")) or (c.AbsoluteSize.Y > c.AbsoluteSize.X * 2.5)) then
					c.Visible = false
				end
			end
			local vpf = featured:FindFirstChildOfClass("ViewportFrame")
			if vpf then -- shading on the familiar: a darker ambient and a warm key light from the upper left
				-- round 3 (review: "flat yellow placeholder"): a low violet ambient and a strong warm key light from the
				-- upper left give the body light and shadow sides; its neon bits become lit metal so they shade too
				vpf.Ambient, vpf.LightColor, vpf.LightDirection = Color3.fromRGB(46, 40, 66), Color3.fromRGB(255, 236, 200), Vector3.new(-1, -0.8, -0.5)
				task.delay(0.5, function() -- the pet model's light pillar (a long thin neon bar) and its flat gold aura disc
					for _, p in vpf:GetDescendants() do
						if p:IsA("BasePart") and p.Material == Enum.Material.Neon then
							if math.max(p.Size.X, p.Size.Y, p.Size.Z) > 4 * math.min(p.Size.X, p.Size.Y, p.Size.Z) and math.max(p.Size.X, p.Size.Y, p.Size.Z) > 10 then p.Transparency = 1 end
							if p.Name == "AuraRing" then p.Transparency = 0.75 end
						end
						if p:IsA("BasePart") and p.Transparency < 0.5 and p.Name ~= "AuraRing" then
							if p.Material == Enum.Material.Neon then p.Material = Enum.Material.Metal end
							local h, sat, v = p.Color:ToHSV()
							p.Color = Color3.fromHSV(h, sat * 0.75, v * 0.9) -- less saturated gold reads as metal, not paint
						end
					end
				end)
			end
			-- the open ring version (no ivory dial), dimmed, so the familiar stays the brightest thing
			local clock = new("ImageLabel", { Name = "Clock", BackgroundTransparency = 1, Image = A.ring, ImageColor3 = Color3.fromRGB(190, 170, 150), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.92, 0.92), ImageTransparency = 0.4, ZIndex = 11 }, featured)
			new("UIAspectRatioConstraint", { AspectRatio = 1 }, clock)
			local gear = new("ImageLabel", { Name = "Gear", BackgroundTransparency = 1, Image = A.gear, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.9, 0.24), Size = UDim2.fromScale(0.22, 0.22), ImageTransparency = 0.5, ZIndex = 10 }, featured) -- behind the rim, clear of the crown
			new("UIAspectRatioConstraint", { AspectRatio = 1 }, gear)
			local glow = new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow, ImageColor3 = Color3.fromRGB(255, 196, 120), ImageTransparency = 0.6, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.7, 0.7), ZIndex = 11 }, featured)
			new("UIAspectRatioConstraint", { AspectRatio = 1 }, glow)
			if not reduced() then
				TweenService:Create(clock, TweenInfo.new(240, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 }):Play()
				TweenService:Create(gear, TweenInfo.new(60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = -360 }):Play()
			end
			for _, l in featured:GetChildren() do -- the name and its tag: quieter, the familiar is the subject
				if l:IsA("TextLabel") then
					l.TextColor3 = l.TextSize >= 24 and IVORY or GOLD
					for _, st in l:GetChildren() do if st:IsA("UIStroke") then st.Transparency = 0.4 end end
				end
			end
		end
	end)
end
