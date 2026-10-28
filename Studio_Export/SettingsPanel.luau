--!nocheck
-- Settings panel content (Sound, Display, Accessibility, Reset). Lives in StarterPlayerScripts next to GameClient, which
-- builds the glass panel shell with makePanel and hands it in. Everything inside the body uses Scale only and TextScaled
-- so the UIKit validator passes on it. Changes apply at once on the client and are sent to the server in batches
-- (the server keeps one accepted save per second per player, see SettingsDefaults.allowSave).
-- ctx: new, STYLE, UI, body, apply(settings), send(batch), defaults, tween

return function(ctx)
	local new, STYLE, UI, body, tween = ctx.new, ctx.STYLE, ctx.UI, ctx.body, ctx.tween
	local UserInputService = game:GetService("UserInputService")
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

	local function header(str)
		local r = row(0.05)
		local l = text(r, string.upper(str), 13, STYLE.muted, Font.fromEnum(STYLE.fontB), Enum.TextXAlignment.Left)
		l.Size = UDim2.fromScale(1, 0.8)
		l.Position = UDim2.fromScale(0.5, 0.6)
		local line = gui("Frame", { BackgroundColor3 = STYLE.muted, BackgroundTransparency = 0.8, BorderSizePixel = 0, Size = UDim2.fromScale(1, 0.04), Position = UDim2.fromScale(0.5, 0.98), ZIndex = 9 }, r)
		return r
	end

	local function labeled(str)
		local r = row(0.075)
		local l = text(r, str, 18, STYLE.text, Font.fromEnum(STYLE.fontB), Enum.TextXAlignment.Left)
		l.Size = UDim2.fromScale(0.42, 0.9)
		l.Position = UDim2.fromScale(0.21, 0.5)
		local area = gui("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(0.54, 1), Position = UDim2.fromScale(0.73, 0.5), ZIndex = 9 }, r)
		return area
	end

	local function pill(parent, color)
		new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, parent)
		local s = new("UIStroke", { Color = color, Thickness = 0.06, StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize, Transparency = 0.35 }, parent)
		return s
	end

	local function slider(key, str)
		local area = labeled(str)
		local track = gui("Frame", { BackgroundColor3 = Color3.fromRGB(14, 16, 32), Size = UDim2.fromScale(0.72, 0.3), Position = UDim2.fromScale(0.36, 0.5), ZIndex = 10, Active = true }, area)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)
		local fill = gui("Frame", { BackgroundColor3 = STYLE.blue, Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(0.25, 0.5), ZIndex = 11 }, track)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
		local knob = gui("Frame", { BackgroundColor3 = STYLE.text, Size = UDim2.fromScale(0.07, 1.9), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 12 }, track)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, knob)
		new("UIAspectRatioConstraint", { AspectRatio = 1 }, knob)
		local readout = text(area, "", 16, STYLE.gold, Font.fromEnum(STYLE.fontB), Enum.TextXAlignment.Right)
		readout.Size = UDim2.fromScale(0.22, 0.8)
		readout.Position = UDim2.fromScale(0.89, 0.5)

		local function show(v)
			fill.Size = UDim2.fromScale(math.max(v, 0.001), 1)
			fill.Position = UDim2.fromScale(math.max(v, 0.001) / 2, 0.5)
			knob.Position = UDim2.fromScale(v, 0.5)
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
		local b = gui("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(0.5, 0.78), Position = UDim2.fromScale(0.75, 0.5), BackgroundColor3 = STYLE.grey, ZIndex = 10 }, area)
		local stroke = pill(b, STYLE.text)
		local l = text(b, "OFF", 16, STYLE.text, Font.fromEnum(STYLE.fontB))
		local function show()
			local on = state[key]
			b.BackgroundColor3 = on and Color3.fromRGB(34, 130, 90) or Color3.fromRGB(52, 58, 84)
			l.Text = on and "ON" or "OFF"
			stroke.Color = on and STYLE.green or STYLE.grey
		end
		controls[key] = { refresh = show }
		b.Activated:Connect(function()
			change(key, not state[key])
			show()
		end)
		show()
	end

	local function choice(key, str, options)
		local area = labeled(str)
		local btns = {}
		local n = #options
		for i, opt in options do
			local b = gui("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1 / n - 0.02, 0.78), Position = UDim2.fromScale((i - 0.5) / n, 0.5), BackgroundColor3 = STYLE.grey, ZIndex = 10 }, area)
			local stroke = pill(b, STYLE.text)
			local l = text(b, opt.label, 14, STYLE.text, Font.fromEnum(STYLE.fontB))
			btns[i] = { b = b, stroke = stroke, value = opt.value }
			b.Activated:Connect(function()
				change(key, opt.value)
				for _, x in btns do
					local on = x.value == state[key]
					x.b.BackgroundColor3 = on and Color3.fromRGB(150, 110, 30) or Color3.fromRGB(52, 58, 84)
					x.stroke.Color = on and STYLE.gold or STYLE.grey
				end
			end)
		end
		local function show()
			for _, x in btns do
				local on = x.value == state[key]
				x.b.BackgroundColor3 = on and Color3.fromRGB(150, 110, 30) or Color3.fromRGB(52, 58, 84)
				x.stroke.Color = on and STYLE.gold or STYLE.grey
			end
		end
		controls[key] = { refresh = show }
		show()
	end

	header("Sound")
	slider("musicVolume", "Music")
	slider("sfxVolume", "Effects")
	header("Display")
	choice("gameSpeed", "Game speed", { { label = "1x", value = 1 }, { label = "2x", value = 2 } })
	choice("particles", "Effects detail", { { label = "Low", value = "low" }, { label = "Normal", value = "default" }, { label = "High", value = "high" } })
	choice("backdrop", "Backdrop", { { label = "Moving", value = "moving" }, { label = "Still", value = "still" } })
	choice("numberFormat", "Numbers", { { label = "1.5K", value = "short" }, { label = "1,500", value = "grouped" }, { label = "1.5e3", value = "scientific" } })
	header("Accessibility")
	toggle("flashes", "Flashes")
	toggle("reducedMotion", "Reduced motion")
	toggle("shake", "Screen shake")

	order += 1
	local resetRow = gui("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(0.9, 0.08), LayoutOrder = order, ZIndex = 8, AnchorPoint = Vector2.new(0, 0) }, body)
	resetRow:SetAttribute("AnchorReason", "list layout child")
	local reset = gui("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(0.5, 0.85), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(120, 40, 56), ZIndex = 10 }, resetRow)
	pill(reset, STYLE.red)
	text(reset, "RESET TO DEFAULTS", 16, STYLE.text, Font.fromEnum(STYLE.fontB))
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
