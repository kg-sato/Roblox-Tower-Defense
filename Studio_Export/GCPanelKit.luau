-- GCPanelKit (T198, 2026-10-29): block moved out of GameClient to stay under the 200,000-character script limit. Called once by GameClient with the outside locals it needs.
return function(env)
local STYLE, UI, label, makeButton, new, round, shade, tween = env.STYLE, env.UI, env.label, env.makeButton, env.new, env.round, env.shade, env.tween
local function makePanel(parent, size, title, accent)
	accent = accent or STYLE.blue
	if UI.fa then
		-- glass panel: emblem breaking the top-left corner, serif caps title + spaced subtitle, tapered divider
		local panel = new("Frame", { BackgroundTransparency = 1, Size = size, Visible = false, ZIndex = 5 }, parent)
		UI.glass(panel, accent)
		UI.motes(panel, accent, 7)
		UI.emblem(panel, accent, UI.SYMS[title] or string.sub(title, 1, 1), 96, UDim2.fromOffset(16, 14), 9)
		local header = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 70), ZIndex = 6 }, panel)
		header:SetAttribute("Stagger", true)
		local t = new("TextLabel", { BackgroundTransparency = 1, Text = string.upper(title), FontFace = UI.TITLE_FONT, TextSize = 26, TextColor3 = Color3.fromRGB(246, 240, 255), TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(74, 10), Size = UDim2.new(1, -120, 0, 32), ZIndex = 8 }, header)
		new("UIStroke", { Name = "TextStroke", Thickness = 1.5, Color = Color3.new(0, 0, 0), Transparency = 0.5 }, t)
		local sub = new("TextLabel", { BackgroundTransparency = 1, Text = UI.SUBS[title] or "", Font = STYLE.fontB, TextSize = 12, TextColor3 = shade(accent, 0.25), TextTransparency = 0.15, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(76, 40), Size = UDim2.new(1, -120, 0, 16), ZIndex = 8 }, header)
		-- letter-space by UTF-8 character (byte-wise spacing split the middle dot into two broken bytes)
		local chars = {}
		for _, cp in utf8.codes(sub.Text) do
			table.insert(chars, utf8.char(cp))
		end
		sub.Text = table.concat(chars, " ")
		UI.divider(header, accent, UDim2.new(0.5, 0, 1, -4), UDim2.new(1, -24, 0, 12), 7)
		local close = new("TextButton", { BackgroundTransparency = 1, Text = "X", FontFace = UI.TITLE_FONT, TextSize = 20, TextColor3 = shade(STYLE.red, 0.15), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0, 28), Size = UDim2.fromOffset(32, 32), ZIndex = 9, AutoButtonColor = false }, panel)
		local halo = new("ImageLabel", { BackgroundTransparency = 1, ImageContent = UI.fa.glow(), ImageColor3 = STYLE.red, ImageTransparency = 0.8, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(48, 48), ZIndex = 8 }, close)
		close.MouseEnter:Connect(function() tween(halo, 0.15, { ImageTransparency = 0.45 }) end)
		close.MouseLeave:Connect(function() tween(halo, 0.15, { ImageTransparency = 0.8 }) end)
		local body = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -72), Position = UDim2.fromOffset(0, 72), ZIndex = 6 }, panel)
		body:SetAttribute("Stagger", true)
		local scale = new("UIScale", { Scale = 1 }, panel)
		return panel, body, scale, close, t
	end
	local panel = new("Frame", { BackgroundColor3 = STYLE.panel, Size = size, Visible = false, ZIndex = 5 }, parent)
	round(panel, 8)
	new("UIGradient", { Color = ColorSequence.new(shade(STYLE.panel, 0.06), STYLE.panelDark), Rotation = 90 }, panel)
	-- open header: sigil + title + a divider that fades out at both ends
	local header = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), ZIndex = 6 }, panel)
	local sigil = UI.diamond(header, 26, accent, UDim2.fromOffset(30, 27), 7)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(shade(accent, 0.4), shade(accent, -0.45)) }, sigil)
	UI.diamond(sigil, 10, STYLE.panelDark, UDim2.fromScale(0.5, 0.5), 8).Rotation = 0
	local t = label(header, title, 26, shade(accent, 0.55), Vector2.new(0, 0.5), UDim2.new(0, 54, 0.5, 2), UDim2.new(1, -110, 1, 0), STYLE.font)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 8
	local divider = new("Frame", { BackgroundColor3 = accent, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, -36, 0, 2), ZIndex = 7 }, header)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1) }) }, divider)
	UI.diamond(divider, 8, accent, UDim2.fromScale(0.5, 0.5), 8)
	local close = makeButton(header, "X", UDim2.fromOffset(32, 32), UDim2.new(1, -12, 0.5, 0), STYLE.red, Vector2.new(1, 0.5))
	close.TextSize = 18
	close.ZIndex = 8
	close:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
	local body = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -50), Position = UDim2.fromOffset(0, 50), ZIndex = 6 }, panel)
	body:SetAttribute("Stagger", true)
	local scale = new("UIScale", { Scale = 1 }, panel)
	UI.scroll(panel, accent)
	return panel, body, scale, close, t
end
return makePanel
end
