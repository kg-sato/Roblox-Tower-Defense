-- EnemyBars (T139, 2026-10-29): readable enemy health bars and status icons at the board camera.
-- decorate() widens the bar made by GameClient.spawnEnemy, gives it a dark 2 px outline and a light top edge, and adds a row for status icons below it.
-- status() shows one icon per status (burn B, chill C with stacks, stun S, mark M, hush H): a dark disc, a ring and a letter in the status colour, so the
-- status reads by letter and position as well as by colour. Driven by the server event Status { id, kind, dur, stacks }. Contrast numbers: Overnight/evidence/T139.txt.
return function(env)
	local new, enemies, SETTINGS, tween = env.new, env.enemies, env.SETTINGS, env.tween
	local Icons = require(script.Parent:WaitForChild("StatusIcons")) -- T641 image icons; the letter stays as the fallback
	local M = {}
	M.COLORS = {
		burn = Color3.fromRGB(255, 140, 40), chill = Color3.fromRGB(110, 205, 255), stun = Color3.fromRGB(255, 230, 70),
		mark = Color3.fromRGB(255, 90, 200), hush = Color3.fromRGB(190, 140, 255),
	}
	M.GLYPHS = { burn = "B", chill = "C", stun = "S", mark = "M", hush = "H" }
	M.DISC = Color3.fromRGB(14, 14, 24)
	local ORDER = { burn = 1, chill = 2, stun = 3, mark = 4, hush = 5 }

	function M.decorate(e, bb, bg, fill)
		local boss = e.big
		local h = boss and 16 or 11
		bb.Size = UDim2.fromOffset(boss and 150 or 80, h + 22)
		bg.Size = UDim2.new(1, 0, 0, h)
		local stroke = bg:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Thickness, stroke.Transparency, stroke.Color = 2, 0, Color3.fromRGB(6, 6, 12) end
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(230, 200, 205)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 160)) }) }, fill)
		local row = new("Frame", { Name = "Status", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, h + 4), Size = UDim2.new(1, 0, 0, 18) }, bb)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, row)
		e.statusRow, e.icons = row, {}
	end

	function M.status(data)
		local e = type(data) == "table" and enemies[data.id]
		local col = e and M.COLORS[data.kind]
		if not col or not e.statusRow then return end
		local icon = e.icons[data.kind]
		if not icon then
			icon = new("TextLabel", { Name = data.kind, BackgroundColor3 = M.DISC, BackgroundTransparency = 0.05, Size = UDim2.fromOffset(18, 18), Font = Enum.Font.GothamBlack, TextSize = 13,
				TextColor3 = col, LayoutOrder = ORDER[data.kind] or 9, Text = "" }, e.statusRow)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, icon)
			new("UIStroke", { Color = col, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, icon)
			if Icons.status[data.kind] then
				Icons.badge(icon, Icons.status[data.kind], { Name = "Art", Size = UDim2.fromScale(1, 1), ZIndex = 2 })
				new("TextLabel", { Name = "Stack", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1.1, 1.1), Size = UDim2.fromOffset(12, 12), Font = Enum.Font.GothamBlack, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0, ZIndex = 4, Text = "" }, icon)
			end
			e.icons[data.kind] = icon
		end
		local n = data.stacks or 1
		local stack = icon:FindFirstChild("Stack")
		icon.Text = stack and "" or (M.GLYPHS[data.kind] .. (n > 1 and tostring(n) or ""))
		if stack then stack.Text = n > 1 and tostring(n) or "" end
		icon.TextSize = n > 1 and 11 or 13
		icon:SetAttribute("Token", (icon:GetAttribute("Token") or 0) + 1)
		local tok = icon:GetAttribute("Token")
		if not SETTINGS.reducedMotion then
			icon.Size = UDim2.fromOffset(24, 24)
			tween(icon, 0.18, { Size = UDim2.fromOffset(18, 18) }, Enum.EasingStyle.Back)
		end
		task.delay(data.dur or 2, function()
			if icon.Parent and icon:GetAttribute("Token") == tok then
				icon:Destroy()
				e.icons[data.kind] = nil
			end
		end)
	end

	return M
end
