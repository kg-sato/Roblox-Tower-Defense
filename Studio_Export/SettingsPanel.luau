--!nocheck
-- Settings panel content (Sound, Display, Accessibility, Reset). Lives in StarterPlayerScripts next to GameClient, which
-- builds the glass panel shell with makePanel and hands it in. Everything inside the body uses Scale only and TextScaled
-- so the UIKit validator passes on it. Changes apply at once on the client and are sent to the server in batches
-- (the server keeps one accepted save per second per player, see SettingsDefaults.allowSave).
-- ctx: new, STYLE, UI, body, apply(settings), send(batch), defaults, tween

return function(ctx)
	local new, STYLE, UI, body, tween = ctx.new, ctx.STYLE, ctx.UI, ctx.body, ctx.tween
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	-- GUI objects are centered on their Position (the UIKit rule); list-layout children are the one marked exception
	local function gui(class, props, parent)
		props.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
		return new(class, props, parent)
	end

	local state = table.clone(ctx.defaults)
	local controls = {} -- key -> { refresh = function }
	local pending, lastSend, scheduled = {}, 0, false
	local dragging = nil

	local function flush()
		scheduled = false
		if next(pending) then
			local batch = pending
			pending = {}
			lastSend = os.clock()
			ctx.send(batch)
		end
	end

	local function change(key, value)
		if state[key] == value then
			return
		end
		state[key] = value
		pending[key] = value
		ctx.apply(state)
		pcall(function() -- master and interface sliders (T605); GameClient's apply only knows music and effects
			local RS = game:GetService("ReplicatedStorage")
			require(RS.SoundCues).applyMix(state, require(RS.SoundFX), require(RS.MusicFX))
		end)
		if not scheduled then
			scheduled = true
			task.delay(math.max(0.05, 1.1 - (os.clock() - lastSend)), flush)
		end
	end

	local list = new("UIListLayout", { Padding = UDim.new(0.008, 0), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, body)
	local order = 0

	local function text(parent, str, size, color, font, align)
		local l = gui("TextLabel", {
			BackgroundTransparency = 1, Text = str, TextColor3 = color, FontFace = font, TextWrapped = true,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
			TextXAlignment = align or Enum.TextXAlignment.Center, ZIndex = 10,
		}, parent)
		l.TextScaled = true
		new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 6 }, l)
		return l
	end

	local function row(height)
		order += 1
		local r = gui("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(0.9, height), LayoutOrder = order, ZIndex = 8, AnchorPoint = Vector2.new(0, 0) }, body)
		r:SetAttribute("AnchorReason", "list layout child")
		return r
	end

	-- ===== "The Lamplighter's Instrument Board" (2026-10-28 restyle; user: settings buttons too generic) =====
	-- Each control is a physical object, same idea as the HUD (Inscryption/Dead Space style diegetic controls):
	-- volumes are brass rails with a glowing amber channel and a lantern knob; on/off settings are candles (lit = on,
	-- snuffed with a wisp of smoke = off); choices are an engraved brass plate with a gold pointer that slides to the pick.
	local FLAME, PLAQUE = "rbxassetid://108574647086501", "rbxassetid://83841573700983"
	local GOLD, AMBER, INK = Color3.fromRGB(255, 208, 110), Color3.fromRGB(255, 160, 60), Color3.fromRGB(58, 36, 18)
	local SERIF = Font.fromName("Merriweather", Enum.FontWeight.Bold)

	local function header(str)
		local r = row(0.055)
		local l = text(r, "\u{25C6}  " .. string.upper(str) .. "  \u{25C6}", 19, GOLD, SERIF, Enum.TextXAlignment.Center)
		l.Size = UDim2.fromScale(1, 0.8)
		l.Position = UDim2.fromScale(0.5, 0.55)
		local line = gui("Frame", { BackgroundColor3 = GOLD, BorderSizePixel = 0, Size = UDim2.fromScale(1, 0.04), Position = UDim2.fromScale(0.5, 0.98), ZIndex = 9 }, r)
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }) }, line)
		return r
	end

	local function labeled(str)
		local r = row(0.075)
		local l = text(r, str, 22, Color3.fromRGB(236, 226, 206), SERIF, Enum.TextXAlignment.Left)
		l.Size = UDim2.fromScale(0.42, 0.9)
		l.Position = UDim2.fromScale(0.21, 0.5)
		local area = gui("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(0.54, 1), Position = UDim2.fromScale(0.73, 0.5), ZIndex = 9 }, r)
		return area
	end

	local function pill(parent, color)
		new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, parent)
		local st = new("UIStroke", { Color = color, Thickness = 0.06, StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize, Transparency = 0.35 }, parent)
		return st
	end

	local function slider(key, str)
		local area = labeled(str)
		-- brass rail: dark channel in a gold frame
		local track = gui("Frame", { BackgroundColor3 = Color3.fromRGB(28, 18, 12), Size = UDim2.fromScale(0.72, 0.26), Position = UDim2.fromScale(0.36, 0.5), ZIndex = 10, Active = true }, area)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)
		new("UIStroke", { Color = Color3.fromRGB(190, 140, 60), Thickness = 0.12, StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize }, track)
		local fill = gui("Frame", { BackgroundColor3 = AMBER, Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(0.25, 0.5), ZIndex = 11 }, track)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
		new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(150, 60, 20), Color3.fromRGB(255, 220, 140)) }, fill)
		-- notches every 25%
		for i = 1, 3 do
			gui("Frame", { BackgroundColor3 = Color3.fromRGB(190, 140, 60), BackgroundTransparency = 0.3, BorderSizePixel = 0, Size = UDim2.fromScale(0.008, 0.5), Position = UDim2.fromScale(i / 4, 0.5), ZIndex = 12 }, track)
		end
		-- lantern knob: brass disc with a little flame
		local knob = gui("Frame", { BackgroundColor3 = Color3.fromRGB(70, 46, 24), Size = UDim2.fromScale(0.09, 2.6), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 13 }, track)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, knob)
		new("UIAspectRatioConstraint", { AspectRatio = 1 }, knob)
		new("UIStroke", { Color = GOLD, Thickness = 0.1, StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize }, knob)
		local kf = gui("ImageLabel", { BackgroundTransparency = 1, Image = FLAME, Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.5, 0.45), ZIndex = 14 }, knob)
		local readout = text(area, "", 20, GOLD, SERIF, Enum.TextXAlignment.Right)
		readout.Size = UDim2.fromScale(0.22, 0.8)
		readout.Position = UDim2.fromScale(0.89, 0.5)

		local function show(v)
			fill.Size = UDim2.fromScale(math.max(v, 0.001), 1)
			fill.Position = UDim2.fromScale(math.max(v, 0.001) / 2, 0.5)
			knob.Position = UDim2.fromScale(v, 0.5)
			kf.ImageTransparency = 0.75 - 0.75 * v -- the flame burns brighter as the volume rises
			readout.Text = math.floor(v * 100 + 0.5) .. "%"
		end
		controls[key] = { refresh = function() show(state[key]) end }
		local function setFromX(x)
			local v = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			v = math.floor(v * 20 + 0.5) / 20
			show(v)
			change(key, v)
		end
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = setFromX
				setFromX(input.Position.X)
			end
		end)
		show(state[key])
	end

	local function toggle(key, str)
		local area = labeled(str)
		-- a candle on a brass dish; click to light or snuff it
		local b = gui("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(0.7, 1), Position = UDim2.fromScale(0.65, 0.5), ZIndex = 10 }, area)
		local dish = gui("Frame", { BackgroundColor3 = Color3.fromRGB(150, 104, 44), Size = UDim2.fromScale(0.34, 0.14), Position = UDim2.fromScale(0.2, 0.86), ZIndex = 11 }, b)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dish)
		local wax = gui("Frame", { BackgroundColor3 = Color3.fromRGB(240, 230, 205), Size = UDim2.fromScale(0.12, 0.5), Position = UDim2.fromScale(0.2, 0.58), ZIndex = 12 }, b)
		new("UICorner", { CornerRadius = UDim.new(0.2, 0) }, wax)
		new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 250, 235), Color3.fromRGB(200, 185, 160)) }, wax)
		local flame = gui("ImageLabel", { BackgroundTransparency = 1, Image = FLAME, Size = UDim2.fromScale(0.3, 0.7), Position = UDim2.fromScale(0.2, 0.14), ZIndex = 13 }, b)
		new("UIAspectRatioConstraint", { AspectRatio = 0.75 }, flame)
		local smoke = gui("Frame", { BackgroundColor3 = Color3.fromRGB(150, 150, 160), BackgroundTransparency = 0.5, Size = UDim2.fromScale(0.03, 0.3), Position = UDim2.fromScale(0.2, 0.18), ZIndex = 13 }, b)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, smoke)
		local l = text(b, "", 19, GOLD, SERIF, Enum.TextXAlignment.Left)
		l.Size = UDim2.fromScale(0.6, 0.7)
		l.Position = UDim2.fromScale(0.72, 0.5)
		local flicker = TweenService:Create(flame, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 6, Size = UDim2.fromScale(0.27, 0.66) })
		local function show()
			local on = state[key]
			flame.Visible, smoke.Visible = on, not on
			l.Text = on and "LIT" or "SNUFFED"
			l.TextColor3 = on and GOLD or Color3.fromRGB(150, 140, 150)
			if on then flicker:Play() else flicker:Cancel() end
		end
		controls[key] = { refresh = show }
		b.Activated:Connect(function()
			change(key, not state[key])
			show()
			if state[key] then -- strike: the flame pops in
				flame.Size = UDim2.fromScale(0.05, 0.1)
				tween(flame, 0.25, { Size = UDim2.fromScale(0.3, 0.7) })
			end
		end)
		show()
	end

	local function choice(key, str, options)
		local area = labeled(str)
		-- engraved brass plate; the gold pointer slides to the picked option
		local plate = gui("ImageLabel", { BackgroundTransparency = 1, Image = PLAQUE, ScaleType = Enum.ScaleType.Stretch, Size = UDim2.fromScale(1.04, 1.05), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 9 }, area)
		local n = #options
		local pointer = gui("Frame", { BackgroundColor3 = GOLD, Size = UDim2.fromScale(0.05, 0.22), Rotation = 45, Position = UDim2.fromScale(0.5, 0.95), ZIndex = 12 }, area)
		new("UIAspectRatioConstraint", { AspectRatio = 1 }, pointer)
		local glow = gui("Frame", { BackgroundColor3 = Color3.fromRGB(255, 200, 100), BackgroundTransparency = 0.75, Size = UDim2.fromScale(1 / n - 0.04, 0.6), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 10 }, area)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, glow)
		local btns = {}
		local function show()
			for i, x in btns do
				local on = x.value == state[key]
				x.l.TextColor3 = on and Color3.fromRGB(255, 240, 200) or Color3.fromRGB(190, 168, 136) -- engraved, still readable on the dark plate
				if on then
					tween(pointer, 0.2, { Position = UDim2.fromScale((i - 0.5) / n, 0.95) }, Enum.EasingStyle.Back)
					tween(glow, 0.2, { Position = UDim2.fromScale((i - 0.5) / n, 0.5) }, Enum.EasingStyle.Back)
				end
			end
		end
		for i, opt in options do
			local b = gui("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1 / n, 0.8), Position = UDim2.fromScale((i - 0.5) / n, 0.5), ZIndex = 11 }, area)
			local l = text(b, opt.label, 19, INK, SERIF)
			btns[i] = { b = b, l = l, value = opt.value }
			b.Activated:Connect(function()
				change(key, opt.value)
				show()
			end)
		end
		controls[key] = { refresh = show }
		show()
	end

	header("Sound")
	slider("masterVolume", "Master")
	slider("musicVolume", "Music")
	slider("sfxVolume", "Effects")
	slider("uiVolume", "Interface")
	header("Display")
	choice("gameSpeed", "Game speed", { { label = "1x", value = 1 }, { label = "2x", value = 2 } })
	choice("cinematics", "Cutscenes", { { label = "Full", value = "full" }, { label = "Short", value = "short" }, { label = "Off", value = "off" } })
	choice("particles", "Effects detail", { { label = "Low", value = "low" }, { label = "Normal", value = "default" }, { label = "High", value = "high" } })
	choice("backdrop", "Backdrop", { { label = "Moving", value = "moving" }, { label = "Still", value = "still" } })
	choice("numberFormat", "Numbers", { { label = "1.5K", value = "short" }, { label = "1,500", value = "grouped" }, { label = "1.5e3", value = "scientific" } })
	header("Accessibility")
	toggle("flashes", "Flashes")
	toggle("reducedMotion", "Reduced motion")
	toggle("shake", "Screen shake")
	toggle("damageNumbers", "Damage numbers")
	choice("uiSize", "UI size", { { label = "Small", value = "small" }, { label = "Normal", value = "normal" }, { label = "Large", value = "large" } })
	-- T075: Controls group. Key rows are a read-only reference; Hide UI is the saved setting (applied by HideUI, kept after rejoin).
	header("Controls")
	toggle("hideUi", "Hide UI")
	local function keyRow(str, keys)
		local area = labeled(str)
		local l = text(area, keys, 20, GOLD, SERIF, Enum.TextXAlignment.Right)
		l.Size = UDim2.fromScale(0.95, 0.8)
		l.Position = UDim2.fromScale(0.5, 0.5)
	end
	keyRow("Hide or show the HUD", "H key")
	keyRow("Move between buttons", "Arrow keys / D-pad")
	keyRow("Close a panel", "Esc")
	local okC, Cfg = pcall(function() return require(game:GetService("ReplicatedStorage").Shared.Config) end)
	if okC and Cfg.PAUSE_MENU then
		keyRow("Pause menu", "P key")
	end

	order += 1
	local resetRow = gui("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(0.9, 0.08), LayoutOrder = order, ZIndex = 8, AnchorPoint = Vector2.new(0, 0) }, body)
	resetRow:SetAttribute("AnchorReason", "list layout child")
	local reset = gui("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(0.5, 0.85), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(120, 40, 56), ZIndex = 10 }, resetRow)
	-- a torn wax seal: "break the seal" to restore the defaults
	reset.BackgroundTransparency = 1
	gui("ImageLabel", { BackgroundTransparency = 1, Image = PLAQUE, ScaleType = Enum.ScaleType.Stretch, Size = UDim2.fromScale(1.1, 1), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 9 }, reset)
	local seal = gui("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://78303286285946", Size = UDim2.fromScale(0.3, 1.3), Position = UDim2.fromScale(0.08, 0.5), ZIndex = 11 }, reset)
	new("UIAspectRatioConstraint", { AspectRatio = 1 }, seal)
	local rl = text(reset, "BREAK THE SEAL  ·  RESET", 15, Color3.fromRGB(236, 214, 170), SERIF)
	rl.Size = UDim2.fromScale(0.8, 0.7)
	rl.Position = UDim2.fromScale(0.58, 0.5)
	reset.Activated:Connect(function()
		for k, v in ctx.defaults do
			change(k, v)
		end
		for _, c in controls do
			c.refresh()
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			dragging(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = nil
		end
	end)

	return {
		-- values from the server (join, and after each accepted save); ignored while the player is dragging a slider
		sync = function(s)
			if dragging or next(pending) then
				return
			end
			for k in ctx.defaults do
				if s[k] ~= nil then
					state[k] = s[k]
				end
			end
			for _, c in controls do
				c.refresh()
			end
		end,
		body = body,
	}
end
