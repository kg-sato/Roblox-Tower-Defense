-- GCOddsRows (T198, 2026-10-29): block moved out of GameClient to stay under the 200,000-character script limit. Called once by GameClient with the outside locals it needs.
return function(env)
local Config, STYLE, TweenService, UI, glowStroke, label, new, oddsBody, oddsChip, oddsNote, oddsRows, round = env.Config, env.STYLE, env.TweenService, env.UI, env.glowStroke, env.label, env.new, env.oddsBody, env.oddsChip, env.oddsNote, env.oddsRows, env.round
-- Odds as a fortune-teller's spread (2026-10-28, /make-creative): four tarot cards fanned on the panel, one per rarity,
-- tinted in its colour; the chance is written under each card; rarer cards glow and sway. The text rows stay hidden.
do
	local cards, tweens = {}, {}
	local n = #Config.RARITY_ORDER
	for i, r in Config.RARITY_ORDER do
		oddsRows[r].Visible = false
		local nameL = oddsRows[r]
		for _, c in oddsBody:GetChildren() do
			if c:IsA("TextLabel") and c ~= nameL and c ~= oddsNote and c.Position.Y.Offset == 36 + (i - 1) * 62 then c.Visible = false end
			if c:IsA("ImageLabel") and c.ZIndex == 9 then c.Visible = false end -- old row dividers
		end
		local color = Config.RARITIES[r].color
		local slot = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new((i - 0.5) / n, 0, 0, 8), Size = UDim2.fromOffset(92, 200), ZIndex = 10 }, oddsBody)
		local glow = new("Frame", { BackgroundColor3 = color, BackgroundTransparency = 0.7 + 0.05 * (n - i), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(46, 70), Size = UDim2.fromOffset(100, 150), ZIndex = 10 }, slot)
		round(glow, 18)
		local card = new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://93758813189086", ImageColor3 = color:Lerp(Color3.new(1, 1, 1), 0.1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(46, 70 + math.abs(i - (n + 1) / 2) * 6), Size = UDim2.fromOffset(78, 132), Rotation = (i - (n + 1) / 2) * 9, ZIndex = 11 }, slot)
		card:SetAttribute("NoStagger", true)
		local nm = label(slot, string.upper(r), 15, color, Vector2.new(0.5, 0), UDim2.fromOffset(46, 142), UDim2.fromOffset(100, 20), STYLE.fontB)
		nm.ZIndex = 12
		local pc = label(slot, "", 22, STYLE.text, Vector2.new(0.5, 0), UDim2.fromOffset(46, 162), UDim2.fromOffset(100, 26), STYLE.fontB)
		pc.ZIndex = 12
		cards[r] = { card = card, pc = pc }
		if i >= 3 then -- rarer cards breathe
			table.insert(tweens, TweenService:Create(card, TweenInfo.new(1.4 - 0.3 * (i - 3), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = card.Rotation + 4 }))
			table.insert(tweens, TweenService:Create(glow, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.45 }))
		end
	end
	for _, t in tweens do t:Play() end
	oddsNote.Position = UDim2.new(0.5, 0, 1, -4)
	function UI.oddsSpread(pct)
		for r, c in cards do
			c.pc.Text = string.format(pct[r] < 1 and "%.2f%%" or pct[r] < 10 and "%.1f%%" or "%d%%", pct[r] < 10 and pct[r] or math.floor(pct[r] + 0.5))
		end
	end
	-- the ODDS chip becomes a small crystal ball on the desk
	UI.objectify(oddsChip)
	local ball = new("Frame", { BackgroundColor3 = Color3.fromRGB(150, 110, 255), BackgroundTransparency = 0.25, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(26, 26), ZIndex = 7 }, oddsChip)
	round(ball, 13)
	new("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(240, 220, 255), Color3.fromRGB(80, 40, 160)) }, ball)
	glowStroke(ball, Color3.fromRGB(255, 210, 120), 2, 0)
	TweenService:Create(ball, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0 }):Play()
	local t = oddsChip:FindFirstChild("Txt")
	if t then t.ZIndex = 8; t.TextColor3 = STYLE.gold end
end
end
