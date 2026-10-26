--!nocheck
-- UIKit: the component library. A screen script (see UIScreens) only calls these functions with token names
-- from UITheme, so "make a shop like X" becomes a short script instead of hundreds of property edits.
-- Rules baked in (from the MIT-licensed figma-to-roblox-ui method by xtrair, plus our own UI Design Playbook):
--   * Scale only: Offset is 0 everywhere. Positions and sizes are fractions of the PARENT.
--   * Centered AnchorPoint by default; any other anchor gets an AnchorReason attribute.
--   * UICorner and UIStroke use Scale (stroke: ScaledSize); text is TextScaled with a size constraint.
--   * No game logic here. Callbacks are passed in.
-- Not yet tested in Studio (see UI Kit/README.md).

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Themes = require(script.Parent:WaitForChild("UITheme"))

local K = {}
K.Themes = Themes
K.T = Themes.Candy

local CENTER = Vector2.new(0.5, 0.5)
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

-- K.skin forces one theme for every screen (screens still ask for Candy/Pixel); set it to nil for their own looks
K.skin = "Sols"

function K.use(name)
	name = K.skin or name
	K.T = assert(Themes[name], "unknown theme " .. tostring(name))
	return K.T
end

---------------------------------------------------------------------------------------------------
-- tokens and small helpers
---------------------------------------------------------------------------------------------------

local function col(v)
	if typeof(v) == "Color3" then
		return v
	end
	return assert(K.T.colors[v], "unknown colour token " .. tostring(v))
end
K.col = col

local function shade(c, f)
	return c:Lerp(BLACK, f)
end
local function tint(c, f)
	return c:Lerp(WHITE, f)
end
K.shade, K.tint = shade, tint

local function radius(v)
	if type(v) == "number" then
		return v
	end
	return assert(K.T.radius[v], "unknown radius token " .. tostring(v))
end

local function strokeW(v)
	if type(v) == "number" then
		return v
	end
	return assert(K.T.stroke[v], "unknown stroke token " .. tostring(v))
end

local function fromScale(x, y)
	return UDim2.fromScale(x, y)
end

-- true on a phone-sized viewport (narrow landscape). Screens switch to their phone layout with this.
function K.isPhone()
	local cam = workspace.CurrentCamera
	return cam ~= nil and cam.ViewportSize.X < 1000
end

-- 1500 -> "1.5K", 13660000000000 -> "13.66T" (matches the NumberFormat tests in the Game Design Doc)
function K.fmt(n)
	local neg = n < 0
	n = math.abs(n)
	local out
	if n < 1000 then
		out = tostring(math.floor(n))
	else
		local names = { "K", "M", "B", "T", "Qa" }
		local i = math.min(#names, math.floor(math.log10(n) / 3))
		local v = n / 1000 ^ i
		local s = string.format("%.2f", v):gsub("%.?0+$", "")
		out = s .. names[i]
	end
	return (neg and "-" or "") .. out
end

function K.clock(seconds)
	seconds = math.max(0, math.floor(seconds))
	local d, h, m, s = seconds // 86400, seconds % 86400 // 3600, seconds % 3600 // 60, seconds % 60
	if d > 0 then
		return string.format("%dd %02dh", d, h)
	elseif h > 0 then
		return string.format("%dh %02dm", h, m)
	end
	return string.format("%dm %02ds", m, s)
end

---------------------------------------------------------------------------------------------------
-- core: box
---------------------------------------------------------------------------------------------------

-- o: name, class, x, y, w, h (all 0..1 of the PARENT, x/y = anchor point position), anchor (+reason),
--    fill (token or Color3), alpha, corner (token or number), stroke (token or number), strokeColor,
--    gradient = {top, bottom} (Color3 or token) or gradient = true (auto), z, aspect (w/h), clip, rotation
function K.box(parent, o)
	local f = Instance.new(o.class or "Frame")
	f.Name = o.name or "Box"
	local anchor = o.anchor or CENTER
	f.AnchorPoint = anchor
	if anchor ~= CENTER then
		f:SetAttribute("AnchorReason", o.reason or "edge-pinned")
	end
	f.Position = fromScale(o.x or 0.5, o.y or 0.5)
	f.Size = fromScale(o.w or 1, o.h or 1)
	f.BorderSizePixel = 0
	if o.fill then
		f.BackgroundTransparency = o.alpha or 0
		if o.gradient then
			f.BackgroundColor3 = WHITE
		else
			f.BackgroundColor3 = col(o.fill)
		end
	else
		f.BackgroundTransparency = 1
	end
	if o.z then
		f.ZIndex = o.z
	end
	if o.rotation then
		f.Rotation = o.rotation
	end
	if o.clip then
		f.ClipsDescendants = true
	end
	if o.corner then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(radius(o.corner), 0)
		c.Parent = f
	end
	if o.gradient and o.fill then
		local base = col(o.fill)
		local top, bottom
		if o.gradient == true then
			top, bottom = tint(base, 0.28), shade(base, 0.12)
		else
			top, bottom = col(o.gradient[1]), col(o.gradient[2])
		end
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(top, bottom)
		g.Rotation = 90
		g.Parent = f
	end
	if o.stroke then
		local s = Instance.new("UIStroke")
		s.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		s.Thickness = strokeW(o.stroke)
		s.Color = col(o.strokeColor or "outline")
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = f
	end
	if o.aspect then
		local a = Instance.new("UIAspectRatioConstraint")
		a.AspectRatio = o.aspect
		a.Parent = f
	end
	f.Parent = parent
	return f
end

---------------------------------------------------------------------------------------------------
-- core: text
---------------------------------------------------------------------------------------------------

-- o: text, x, y, w, h, size (max px), color, font, align ("Left"|"Center"|"Right"), outline (bool),
--    outlineColor, wrap, z, left (x is the left edge) / right (x is the right edge)
function K.text(parent, o)
	local anchor, x = CENTER, o.x or 0.5
	local reason
	if o.left then
		anchor, reason = Vector2.new(0, 0.5), "left-aligned text"
	elseif o.right then
		anchor, reason = Vector2.new(1, 0.5), "right-aligned text"
	end
	local t = K.box(parent, {
		class = "TextLabel", name = o.name or "Text", x = x, y = o.y or 0.5, w = o.w or 1, h = o.h or 1,
		anchor = anchor, reason = reason, z = o.z,
	})
	t.Text = tostring(o.text or "")
	-- order matters: setting TextWrapped = false AFTER TextScaled = true turns TextScaled back off
	-- (measured in Studio 2026-10-25). TextScaled = true also forces wrapping on, so set it last.
	t.TextWrapped = true
	t.TextScaled = true
	t.Font = o.font or K.T.font
	t.TextColor3 = col(o.color or "text")
	local align = o.align or (o.left and "Left") or (o.right and "Right") or "Center"
	t.TextXAlignment = Enum.TextXAlignment[align]
	t.TextYAlignment = Enum.TextYAlignment.Center
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = o.size or 36
	c.MinTextSize = 6
	c.Parent = t
	local outline = o.outline
	if outline == nil then
		outline = K.T.textStroke > 0
	end
	if outline then
		local s = Instance.new("UIStroke")
		s.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		s.Thickness = K.T.textStroke > 0 and K.T.textStroke or 0.05
		s.Color = col(o.outlineColor or "outline")
		s.Parent = t
	end
	return t
end

---------------------------------------------------------------------------------------------------
-- screens
---------------------------------------------------------------------------------------------------

-- Returns the ScreenGui and a full-size transparent Root frame. parent defaults to StarterGui.
function K.screen(name, parent)
	parent = parent or StarterGui
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = parent
	local root = K.box(g, { name = "Root", w = 1, h = 1 })
	return g, root
end

-- a flat colour or gradient backdrop, handy for mock screens so panels have something behind them
function K.backdrop(root, topColor, bottomColor)
	if K.skin == "Sols" then -- one midnight backdrop for every screen
		topColor, bottomColor = Color3.fromRGB(16, 20, 44), Color3.fromRGB(4, 5, 14)
	elseif K.skin == "Hearth" then -- warm dusk sky
		topColor, bottomColor = Color3.fromRGB(96, 160, 220), Color3.fromRGB(255, 196, 120)
	end
	return K.box(root, { name = "Backdrop", fill = topColor, gradient = { topColor, bottomColor or topColor }, z = 0 })
end

---------------------------------------------------------------------------------------------------
-- interaction effects
---------------------------------------------------------------------------------------------------

-- press feedback by tweening Size (not UIScale, which mis-scales ScaledSize strokes)
local function pressFx(btn)
	local base = btn.Size
	local down = fromScale(base.X.Scale * 0.94, base.Y.Scale * 0.94)
	local function to(size, info)
		TweenService:Create(btn, info, { Size = size }):Play()
	end
	btn.MouseButton1Down:Connect(function()
		to(down, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
	end)
	local function release()
		to(base, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
	end
	btn.MouseButton1Up:Connect(release)
	btn.MouseLeave:Connect(release)
end

K.pressFx = pressFx

-- pop a panel in (call after building it): scale from 85% with a little overshoot
function K.popIn(frame)
	local base = frame.Size
	frame.Size = fromScale(base.X.Scale * 0.85, base.Y.Scale * 0.85)
	TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = base }):Play()
end

-- keeps a label updated once per second until it is destroyed. fn(seconds) -> string
function K.countdown(label, seconds, fn)
	fn = fn or K.clock
	task.spawn(function()
		local left = seconds
		while label.Parent and left >= 0 do
			label.Text = fn(left)
			left -= 1
			task.wait(1)
		end
	end)
end

---------------------------------------------------------------------------------------------------
-- components
---------------------------------------------------------------------------------------------------

-- o: text, icon, color (token), x, y, w, h, size, aspect, anchor, onClick, badge (string), z
function K.button(parent, o)
	local base = col(o.color or "green")
	local b = K.box(parent, {
		class = "TextButton", name = o.name or ("Button_" .. tostring(o.text or o.icon or "")), x = o.x, y = o.y,
		w = o.w or 0.3, h = o.h or 0.12, anchor = o.anchor, reason = o.reason, z = o.z, aspect = o.aspect,
		fill = base, gradient = { tint(base, 0.3), shade(base, 0.1) }, corner = o.corner or "md",
		stroke = o.stroke or "md",
	})
	b.Text = ""
	b.AutoButtonColor = false
	if o.icon and o.text then
		K.text(b, { text = o.icon, x = 0.17, w = 0.24, h = 0.62, size = 40, outline = false, name = "Icon" })
		K.text(b, { text = o.text, x = 0.64, w = 0.56, h = 0.52, size = o.size or 34, name = "Label" })
	elseif o.icon then
		K.text(b, { text = o.icon, w = 0.7, h = 0.7, size = 44, outline = false, name = "Icon" })
	elseif o.text then
		K.text(b, { text = o.text, w = 0.84, h = 0.56, size = o.size or 36, name = "Label" })
	end
	if o.badge then
		K.badge(b, { text = o.badge, x = 0.93, y = 0.1 })
	end
	K.pressFx(b)
	if o.onClick then
		b.Activated:Connect(o.onClick)
	end
	return b
end

-- round red notification dot with a count or "!"
function K.badge(parent, o)
	local b = K.box(parent, {
		name = "Badge", x = o.x or 0.9, y = o.y or 0.1, w = o.w or 0.34, h = o.h or 0.34, aspect = 1,
		fill = o.color or "red", corner = "pill", stroke = "md", strokeColor = "text", z = 5,
	})
	K.text(b, { text = o.text, w = 0.7, h = 0.7, size = 24, outline = false })
	return b
end

-- currency capsule: icon bubble + value + optional green plus. o: icon, value, color, plus
function K.pill(parent, o)
	local p = K.box(parent, {
		name = o.name or "Pill", x = o.x, y = o.y, w = o.w or 0.3, h = o.h or 0.08, anchor = o.anchor, reason = o.reason,
		fill = "panelDark", alpha = 0.25, corner = "pill", stroke = "thin", strokeColor = "outline",
	})
	K.box(p, { name = "IconBubble", x = 0.11, w = 0.2, h = 1.0, aspect = 1, fill = o.color or "coin", corner = "pill", stroke = "md", gradient = true })
	K.text(p, { text = o.icon or "", x = 0.11, w = 0.18, h = 0.7, size = 36, outline = false })
	K.text(p, { text = tostring(o.value), x = o.plus and 0.5 or 0.58, w = o.plus and 0.5 or 0.62, h = 0.7, size = 40, color = o.valueColor or "text", name = "Value" })
	if o.plus then
		K.button(p, { text = "+", color = "green", x = 0.9, w = 0.18, h = 0.8, aspect = 1, size = 40, corner = "pill", name = "Plus" })
	end
	return p
end

-- darkened full-screen layer that also blocks clicks behind it
function K.dim(root, alpha)
	local d = K.box(root, { name = "Dim", fill = "dim", alpha = alpha or 0.5, z = 10 })
	d.Active = true
	return d
end

-- Modal: dim + panel + coloured header + red X outside the top right corner (the convention seen in every
-- reference game). Returns panel, content (an inner frame for your widgets), dim.
-- o: title, color (header token), aspect (default 1.7), w (default 0.62), onClose
function K.modal(root, o)
	local dim = K.dim(root, 0.5)
	local panel = K.box(dim, {
		name = "Panel", w = o.w or 0.62, h = 0.9, aspect = o.aspect or 1.7, fill = "panel", corner = 0.04,
		stroke = 0.012, strokeColor = "outline", z = 11,
	})
	local header = K.box(panel, {
		name = "Header", y = 0.085, w = 1, h = 0.17, fill = o.color or "header", gradient = true, corner = 0.28, z = 12,
	})
	K.text(header, { text = o.title, x = 0.035, w = 0.7, h = 0.74, size = 72, left = true, font = K.T.titleFont, name = "Title" })
	local close = K.button(panel, {
		name = "Close", text = "X", color = "red", x = 0.985, y = 0.0, w = 0.085, h = 0.13, aspect = 1, size = 40,
		corner = "md", z = 20, onClick = function()
			dim:Destroy()
			if o.onClose then
				o.onClose()
			end
		end,
	})
	local content = K.box(panel, { name = "Content", y = 0.6, w = 0.94, h = 0.76, z = 12 })
	return panel, content, dim
end

-- progress bar. o: value (0..1), color, text (overlay), x, y, w, h. The fill grows from the left.
function K.bar(parent, o)
	local color = col(o.color or "green")
	local track = K.box(parent, {
		name = o.name or "Bar", x = o.x, y = o.y, w = o.w or 0.8, h = o.h or 0.08, anchor = o.anchor, reason = o.reason,
		fill = "panelDark", corner = "pill", stroke = "md", strokeColor = "outline", clip = true,
	})
	local v = math.clamp(o.value or 0, 0, 1)
	local fill = K.box(track, {
		name = "Fill", x = 0, y = 0.5, w = math.max(v, 0.001), h = 1, anchor = Vector2.new(0, 0.5), reason = "progress fill grows from the left",
		fill = color, gradient = { tint(color, 0.35), shade(color, 0.08) }, corner = "pill",
	})
	local label
	if o.text then
		label = K.text(track, { text = o.text, w = 0.9, h = 0.78, size = o.size or 34, z = 3 })
	end
	return track, fill, label
end

-- draggable slider. o: value (0..1), label, valueText, onChange(v)
function K.slider(parent, o)
	local row = K.box(parent, { name = o.name or "SliderRow", x = o.x, y = o.y, w = o.w or 0.9, h = o.h or 0.12, fill = "panelLight", alpha = 0.45, corner = "md" })
	K.text(row, { text = o.label, x = 0.03, w = 0.2, h = 0.5, size = 30, left = true })
	local track = K.box(row, { name = "Track", x = 0.52, w = 0.46, h = 0.22, fill = "panelDark", corner = "pill", stroke = "thin" })
	track.Active = true
	local fill = K.box(track, { name = "Fill", x = 0, w = o.value or 0.5, h = 1, anchor = Vector2.new(0, 0.5), reason = "slider fill grows from the left", fill = o.color or "blue", gradient = true, corner = "pill" })
	local knob = K.box(track, { name = "Knob", x = o.value or 0.5, w = 0.07, h = 1.7, aspect = 1, fill = "text", corner = "pill", stroke = "md", z = 4 })
	local valueLabel = K.text(row, { text = o.valueText or "100%", x = 0.97, w = 0.17, h = 0.5, size = 30, right = true, color = o.color or "blue", name = "Value" })
	local dragging = false
	local function show(rel)
		fill.Size = fromScale(math.max(rel, 0.001), 1)
		knob.Position = fromScale(rel, 0.5)
		valueLabel.Text = tostring(math.round(rel * 100)) .. "%"
	end
	local function set(px)
		local rel = math.clamp((px - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		show(rel)
		if o.onChange then
			o.onChange(rel)
		end
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			set(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			set(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	return row, { set = show }
end

-- segmented choice (2 to 4 options) used for On/Off, Low/Default/High, number formats.
-- o: label, options = {"On","Off"}, value (index), onChange(index, text)
function K.segmented(parent, o)
	local row = K.box(parent, { name = o.name or "SegmentedRow", x = o.x, y = o.y, w = o.w or 0.9, h = o.h or 0.12, fill = "panelLight", alpha = 0.45, corner = "md" })
	K.text(row, { text = o.label, x = 0.03, w = 0.4, h = 0.5, size = 30, left = true })
	local chars = 0
	for _, t in ipairs(o.options) do
		chars += math.max(#t, 3)
	end
	local group = K.box(row, { name = "Group", x = 0.97, w = math.clamp(0.06 + chars * 0.02 + 0.02 * #o.options, 0.2, 0.62), h = 0.76, anchor = Vector2.new(1, 0.5), reason = "right-aligned control", fill = "panelDark", corner = "md", stroke = "thin" })
	local buttons = {}
	local current = o.value or 1
	local function paint()
		for i, b in ipairs(buttons) do
			local on = i == current
			b.BackgroundColor3 = on and col(o.color or "blue") or col("panelDark")
			b.BackgroundTransparency = on and 0 or 1
			b.Label.TextColor3 = on and col("text") or col("gray")
		end
	end
	local n = #o.options
	for i, text in ipairs(o.options) do
		local b = K.box(group, { class = "TextButton", name = "Opt" .. i, x = (i - 0.5) / n, w = 0.96 / n, h = 0.84, fill = "blue", corner = "sm" })
		b.Text = ""
		b.AutoButtonColor = false
		K.text(b, { text = text, w = 0.9, h = 0.55, size = 26, outline = false, name = "Label" })
		b.Activated:Connect(function()
			current = i
			paint()
			if o.onChange then
				o.onChange(i, text)
			end
		end)
		buttons[i] = b
	end
	paint()
	-- api.set(i) changes the choice from code without calling onChange (used by Reset and by linked settings)
	local api = {
		set = function(i)
			current = i
			paint()
		end,
		get = function()
			return current
		end,
	}
	return row, api
end

-- tab strip. o: tabs = {"Featured","Pets","Passes"}, value, colors, onChange(i)
function K.tabs(parent, o)
	local strip = K.box(parent, { name = "Tabs", x = o.x, y = o.y, w = o.w or 0.9, h = o.h or 0.1, anchor = o.anchor, reason = o.reason })
	local n = #o.tabs
	local buttons = {}
	local current = o.value or 1
	local function paint()
		for i, b in ipairs(buttons) do
			local on = i == current
			b.Gradient.Color = ColorSequence.new(on and col(o.color or "blue") or col("grayDark"))
			b.Label.TextColor3 = on and col("text") or col("gray")
		end
	end
	for i, name in ipairs(o.tabs) do
		local b = K.box(strip, { class = "TextButton", name = "Tab" .. i, x = (i - 0.5) / n, w = 0.96 / n, h = 1, fill = "gray", gradient = true, corner = "md", stroke = "md" })
		b.Text = ""
		b.AutoButtonColor = false
		b:FindFirstChildOfClass("UIGradient").Name = "Gradient"
		K.text(b, { text = name, w = 0.86, h = 0.56, size = 32, name = "Label" })
		b.Activated:Connect(function()
			current = i
			paint()
			if o.onChange then
				o.onChange(i, name)
			end
		end)
		buttons[i] = b
	end
	paint()
	return strip
end

-- grid positions inside a container: returns an array of {x, y, w, h} in 0..1 of the container.
function K.cells(cols, rows, gap)
	gap = gap or 0.02
	local w = (1 - gap * (cols + 1)) / cols
	local h = (1 - gap * (rows + 1)) / rows
	local out = {}
	for r = 1, rows do
		for c = 1, cols do
			table.insert(out, { x = gap + (c - 1) * (w + gap) + w / 2, y = gap + (r - 1) * (h + gap) + h / 2, w = w, h = h })
		end
	end
	return out
end

-- Shop card. o: title, icon (emoji), price, kind ("robux" | "coin" | "gem" | "free"), tag ("SALE", "BEST VALUE"),
--   tagColor, note, color (accent), odds (list of strings shown small), x, y, w, h, onClick
function K.card(parent, o)
	local accent = col(o.color or "blue")
	local c = K.box(parent, { name = o.name or "Card", x = o.x, y = o.y, w = o.w or 0.3, h = o.h or 0.8, fill = "panelDark", corner = 0.07, stroke = 0.022, strokeColor = accent })
	K.box(c, { name = "Glow", y = 0.44, w = 0.9, h = 0.5, fill = accent, alpha = 0.7, gradient = { tint(accent, 0.2), shade(accent, 0.5) }, corner = 0.08 })
	K.text(c, { text = o.title, y = 0.1, w = 0.9, h = 0.12, size = 34, name = "Title" })
	K.text(c, { text = o.icon or "?", y = 0.44, w = 0.8, h = 0.42, size = 130, outline = false, name = "Icon" })
	if o.note then
		K.text(c, { text = o.note, y = 0.74, w = 0.88, h = 0.07, size = 24, color = "yellow", outline = false, name = "Note" })
	end
	if o.tag then
		local t = K.box(c, { name = "Tag", x = 0.2, y = 0.0, w = 0.36, h = 0.085, fill = o.tagColor or "red", gradient = true, corner = 0.3, stroke = 0.05, z = 4 })
		K.text(t, { text = o.tag, w = 0.88, h = 0.62, size = 24, outline = false })
	end
	local kind = o.kind or "robux"
	local btnColor = kind == "robux" and "robux" or (kind == "free" and "green" or (kind == "gem" and "blue" or "yellow"))
	local symbol = kind == "robux" and "R$ " or (kind == "gem" and "💎 " or (kind == "coin" and "💰 " or ""))
	K.button(c, { text = symbol .. tostring(o.price or "Free"), color = btnColor, y = 0.89, w = 0.86, h = 0.15, size = 40, onClick = o.onClick, name = "Buy" })
	return c
end

-- toast with a small "New!" tag. o: title, text, tag, x, y, w, h, icon
function K.toast(parent, o)
	local t = K.box(parent, { name = "Toast", x = o.x, y = o.y, w = o.w or 0.22, h = o.h or 0.1, anchor = o.anchor, reason = o.reason, fill = "panelDark", alpha = 0.35, corner = "md" })
	K.text(t, { text = o.icon or "✨", x = 0.12, w = 0.2, h = 0.7, size = 44, outline = false })
	K.text(t, { text = o.title, x = 0.36, y = 0.3, w = 0.62, h = 0.36, size = 30, left = true })
	K.text(t, { text = o.text or "", x = 0.36, y = 0.68, w = 0.62, h = 0.28, size = 18, left = true, color = "gray", outline = false })
	if o.tag then
		K.text(t, { text = o.tag, x = 0.05, y = 0.0, w = 0.2, h = 0.22, size = 20, color = "yellow", outline = true })
	end
	return t
end

-- a full-width dim banner for tutorials or goals. o: title (small), text (main), counter, x, y, w, h
function K.banner(parent, o)
	local b = K.box(parent, { name = o.name or "Banner", x = o.x, y = o.y, w = o.w or 0.5, h = o.h or 0.12, anchor = o.anchor, reason = o.reason, fill = "dim", alpha = 0.45, corner = "md" })
	if o.title then
		K.text(b, { text = o.title, y = 0.2, w = 0.9, h = 0.26, size = 24, color = "gray", outline = false })
	end
	K.text(b, { text = o.text, y = o.title and 0.64 or 0.5, w = 0.94, h = o.title and 0.44 or 0.7, size = 44, name = "Main" })
	return b
end

-- flat-top hexagon built from three rotated rectangles (Roblox has no hex frame). o: fill, outline, x, y, w
-- Returns the container; put text inside it. Container aspect is fixed so the shape stays regular.
function K.hex(parent, o)
	local c = K.box(parent, { name = o.name or "Hex", x = o.x, y = o.y, w = o.w or 0.12, h = (o.w or 0.12) * 0.866, anchor = o.anchor, reason = o.reason, aspect = 1.1547 })
	local function layer(scale, color, name)
		for i, rot in ipairs({ 0, 60, 120 }) do
			K.box(c, { name = name .. i, w = 0.5 * scale, h = 1.0 * scale, rotation = rot, fill = color })
		end
	end
	layer(1.0, o.outline or "outline", "Outline")
	layer(0.9, o.fill or "orange", "Fill")
	if o.text then
		K.text(c, { text = o.text, w = 0.8, h = 0.3, size = 22, z = 5 })
	end
	return c
end

-- thin sci-fi frame with four corner brackets (Aura theme panels). Returns the frame.
function K.bracketPanel(parent, o)
	local p = K.box(parent, { name = o.name or "Bracket", x = o.x, y = o.y, w = o.w or 0.4, h = o.h or 0.5, anchor = o.anchor, reason = o.reason, fill = "panel", alpha = 0.15 })
	local t = 0.012
	for _, c in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
		local ax, ay = c[1], c[2]
		K.box(p, { name = "BracketH", x = ax, y = ay, w = 0.06, h = t, anchor = Vector2.new(ax, ay), reason = "corner bracket", fill = "text", z = 3 })
		K.box(p, { name = "BracketV", x = ax, y = ay, w = t * 0.6, h = 0.12, anchor = Vector2.new(ax, ay), reason = "corner bracket", fill = "text", z = 3 })
	end
	return p
end

-- n rows inside a container: array of {y, h}
function K.rows(n, gap)
	gap = gap or 0.04
	local h = (1 - gap * (n + 1)) / n
	local out = {}
	for i = 1, n do
		table.insert(out, { y = gap + (i - 1) * (h + gap) + h / 2, h = h })
	end
	return out
end

-- vertical stack of icon+label buttons pinned to the left screen edge (the Shop/Index/Trade column).
-- o: items = { {text, icon, color, badge, onClick}, ... }, x, y, w, h, gap
function K.nav(parent, o)
	local col = K.box(parent, {
		name = "Nav", x = o.x or 0.012, y = o.y or 0.5, w = o.w or 0.12, h = o.h or 0.5, anchor = Vector2.new(0, 0.5),
		reason = "HUD pinned to the left screen edge",
	})
	local rows = K.rows(#o.items, o.gap or 0.06)
	for i, it in ipairs(o.items) do
		it.x, it.y, it.w, it.h = 0.5, rows[i].y, 1, rows[i].h
		it.size = it.size or 30
		K.button(col, it)
	end
	return col
end

-- a rarity-coloured title block: odds line, big name, tier word (the Sol's RNG result look)
function K.rarityTitle(parent, o)
	local color = K.T.rarity[o.rarity] or col("text")
	local f = K.box(parent, { name = "RarityTitle", x = o.x, y = o.y, w = o.w or 0.6, h = o.h or 0.3, anchor = o.anchor, reason = o.reason })
	K.text(f, { text = o.odds, y = 0.14, w = 0.5, h = 0.2, size = 28, color = "text", name = "Odds" })
	K.text(f, { text = o.name, y = 0.5, w = 1, h = 0.5, size = 96, color = color, font = K.T.titleFont, name = "Name" })
	K.text(f, { text = string.upper(o.rarity or ""), y = 0.9, w = 0.4, h = 0.16, size = 26, color = color, name = "Tier" })
	return f
end

-- real artwork layer: replaces components with sprite versions when UIArt + UIKitArt are present
local UIMotionModule = script.Parent:FindFirstChild("UIMotion")
if UIMotionModule then
	local okM, motion = pcall(require, UIMotionModule)
	if okM then
		motion(K)
	else
		warn("UIKit motion layer not loaded: " .. tostring(motion))
	end
end
local UIArtModule = script.Parent:FindFirstChild("UIArt")
local UIKitArtModule = script.Parent:FindFirstChild("UIKitArt")
if UIArtModule and UIKitArtModule then
	local okA, UIArt = pcall(require, UIArtModule)
	local okP, patch = pcall(require, UIKitArtModule)
	if okA and okP then
		patch(K, UIArt)
	else
		warn("UIKit art layer not loaded: " .. tostring(okA and patch or UIArt))
	end
end

return K
