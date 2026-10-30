-- UILib (2026-10-29): the UI helper library (scroll, glass, intro, stagger, button skins, number fonts) moved out of GameClient, which had hit Roblox's 200,000-character
-- script limit. GameClient calls this with the five locals it needs and keeps using the returned UI table exactly as before (later code adds more fields to it).
return function(env)
	local ReplicatedStorage, SETTINGS, STYLE, TweenService, UserInputService = env.ReplicatedStorage, env.SETTINGS, env.STYLE, env.TweenService, env.UserInputService
local UI = { STEEL = Color3.fromRGB(122, 134, 176), PALE = Color3.fromRGB(226, 232, 255) }

-- UI Kit art (icons), used when ReplicatedStorage.UIKit exists; frames are the fallback
do
	local okArt, mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("UIKit", 3):WaitForChild("UIArt", 3))
	end)
	UI.art = okArt and mod or nil
end
function UI.artIcon(parent, name, size, pos)
	local UIArt = UI.art
	if not (UIArt and UIArt.has(name)) then
		return nil
	end
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Image = UIArt.image(name)
	img.ScaleType = Enum.ScaleType.Fit
	img.Size = size
	img.Position = pos
	img.Parent = parent
	-- preview art lives in Studio's content folder only; if it never loads (live game, not installed), draw a simple
	-- coin / gem shape instead of an empty square (UI Quality Bar gap 1: counters had no icon)
	task.delay(3, function()
		if img.Parent and not img.IsLoaded then
			img.Visible = false
			local gem = string.find(name, "gem") ~= nil
			local f = Instance.new("Frame")
			f.BackgroundColor3 = gem and Color3.fromRGB(110, 210, 255) or Color3.fromRGB(255, 208, 96)
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = img.Position + UDim2.fromOffset(img.Size.X.Offset / 2, img.Size.Y.Offset / 2)
			f.Size = UDim2.fromOffset(gem and 20 or 26, gem and 20 or 26)
			f.Rotation = gem and 45 or 0
			local c = Instance.new("UICorner")
			c.CornerRadius = gem and UDim.new(0, 4) or UDim.new(0.5, 0)
			c.Parent = f
			local s = Instance.new("UIStroke")
			s.Color = gem and Color3.fromRGB(30, 130, 180) or Color3.fromRGB(200, 140, 20)
			s.Thickness = 2
			s.Parent = f
			f.Parent = img.Parent
		end
	end)
	return img
end

-- Runtime-painted art (EditableImage). Nil when the API is unavailable; the scroll style is the fallback.
do
	local okFa, fa = pcall(function()
		return require(ReplicatedStorage:WaitForChild("FrameArt", 3))
	end)
	UI.fa = okFa and fa and fa.ok and fa or nil
end
UI.TITLE_FONT = Font.fromName("Merriweather", Enum.FontWeight.Bold)
UI.SYMS = { ["Pet"] = "paw", ["Roll Odds"] = "gem", ["Trainer Progression"] = "star" }
UI.SUBS = { ["Pet"] = "UPGRADE  ·  MANAGE", ["Roll Odds"] = "CHANCES PER SUMMON", ["Trainer Progression"] = "LEVELS  ·  REWARDS" }

-- thin pale corner brackets: the dark-fantasy frame signature
function UI.brackets(gui, len, thick, inset)
	local holder = Instance.new("Frame")
	holder.Name = "Brackets"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Active = false
	holder.Parent = gui
	for _, c in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do
		local ax, ay = c[1], c[2]
		for _, horizontal in { true, false } do
			local bar = Instance.new("Frame")
			bar.BackgroundColor3 = UI.PALE
			bar.BorderSizePixel = 0
			bar.Active = false
			bar.AnchorPoint = Vector2.new(ax, ay)
			bar.Position = UDim2.new(ax, ax == 0 and inset or -inset, ay, ay == 0 and inset or -inset)
			bar.Size = horizontal and UDim2.fromOffset(len, thick) or UDim2.fromOffset(thick, len)
			bar.Parent = holder
		end
	end
	return holder
end

-- ===== Arcane scroll frame (2026-10-27) =====
-- Panels read as scrolls: gold rods with gem knobs overhang the sheet, the outline fades along the sides,
-- edges get a soft vignette, and opening unrolls the sheet from the centre with a glow flash.
UI.ROD = Color3.fromRGB(214, 170, 92)
function UI.new(class, props, parent)
	local i = Instance.new(class)
	for k, v in props do
		i[k] = v
	end
	i.Parent = parent
	return i
end

function UI.fadeStroke(gui, color, thickness, along)
	local s = UI.new("UIStroke", { Color = color, Thickness = thickness or 1.5, Transparency = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, gui)
	UI.new("UIGradient", {
		Rotation = along or 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.5, 0.8), NumberSequenceKeypoint.new(1, 0.05) }),
	}, s)
	return s
end

function UI.diamond(parent, size, color, pos, z)
	local d = UI.new("Frame", { Name = "Diamond", BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(size, size), Rotation = 45, ZIndex = z or 1, Active = false }, parent)
	UI.new("UIStroke", { Color = Color3.fromRGB(10, 8, 20), Thickness = 1, Transparency = 0.2 }, d)
	return d
end

function UI.rod(frame, at, horizontal, accent, z)
	local r = UI.new("Frame", {
		Name = "Rod", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UI.ROD, BorderSizePixel = 0, ZIndex = z,
		Size = horizontal and UDim2.new(0, 12, 1, 24) or UDim2.new(1, 28, 0, 12),
		Position = horizontal and UDim2.fromScale(at, 0.5) or UDim2.fromScale(0.5, at),
	}, frame)
	r:SetAttribute("At", at)
	UI.new("UICorner", { CornerRadius = UDim.new(1, 0) }, r)
	UI.new("UIGradient", { Rotation = horizontal and 0 or 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UI.ROD:Lerp(Color3.new(1, 1, 1), 0.5)), ColorSequenceKeypoint.new(0.45, UI.ROD), ColorSequenceKeypoint.new(1, UI.ROD:Lerp(Color3.new(0, 0, 0), 0.55)),
	}) }, r)
	UI.new("UIStroke", { Color = Color3.fromRGB(30, 20, 10), Thickness = 1, Transparency = 0.35 }, r)
	for _, e in { 0, 1 } do
		local k = UI.new("Frame", {
			Name = "Knob", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = z + 1,
			Size = UDim2.fromOffset(18, 18), Position = horizontal and UDim2.fromScale(0.5, e) or UDim2.fromScale(e, 0.5),
		}, r)
		UI.new("UICorner", { CornerRadius = UDim.new(1, 0) }, k)
		UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(accent:Lerp(Color3.new(1, 1, 1), 0.45), accent:Lerp(Color3.new(0, 0, 0), 0.4)) }, k)
		UI.new("UIStroke", { Color = accent, Thickness = 2.5, Transparency = 0.55 }, k)
		local hi = UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.25, BorderSizePixel = 0, Size = UDim2.fromOffset(5, 5), Position = UDim2.fromOffset(4, 3), ZIndex = z + 2 }, k)
		UI.new("UICorner", { CornerRadius = UDim.new(1, 0) }, hi)
	end
	return r
end

-- Turns an existing frame into a scroll. Its children move into Sheet/Content (same size, so layout is unchanged).
function UI.scroll(frame, accent, horizontal)
	accent = accent or Color3.fromRGB(255, 208, 96)
	local z = frame.ZIndex
	local sheet = UI.new("Frame", {
		Name = "Sheet", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = frame.BackgroundColor3, BackgroundTransparency = frame.BackgroundTransparency, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = z,
	}, nil)
	local content = UI.new("Frame", { Name = "Content", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = frame.Size, ZIndex = z }, nil)
	for _, c in frame:GetChildren() do
		if c:IsA("UICorner") then
			c.Parent = sheet
		elseif c:IsA("UIGradient") then
			c:Destroy()
		elseif c:IsA("UIStroke") or c.Name == "Brackets" then
			c:Destroy()
		elseif not c:IsA("UIScale") then
			c.Parent = content
		end
	end
	frame.BackgroundTransparency = 1
	-- midnight indigo fading to near-black, with a faint glow of the accent at the top
	sheet.BackgroundColor3 = Color3.fromRGB(30, 26, 66)
	sheet.BackgroundTransparency = 0
	UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(70, 70, 80)) }, sheet)
	local glow = UI.new("Frame", { Name = "Glow", BackgroundColor3 = accent, BorderSizePixel = 0, Size = horizontal and UDim2.fromScale(0.5, 1) or UDim2.fromScale(1, 0.5), ZIndex = z, Active = false }, sheet)
	UI.new("UIGradient", { Rotation = horizontal and 0 or 90, Transparency = NumberSequence.new(0.84, 1) }, glow)
	local margin = UI.new("Frame", { Name = "Margin", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -14, 1, -14), ZIndex = z, Active = false }, sheet)
	UI.new("UICorner", { CornerRadius = UDim.new(0, 6) }, margin)
	UI.new("UIStroke", { Color = accent, Thickness = 1, Transparency = 0.78 }, margin)
	-- soft edges across the sheet (darker toward the open sides)
	local vig = UI.new("Frame", { Name = "Vignette", BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = z, Active = false }, sheet)
	UI.new("UIGradient", { Rotation = horizontal and 90 or 0, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.14, 1), NumberSequenceKeypoint.new(0.86, 1), NumberSequenceKeypoint.new(1, 0.3),
	}) }, vig)
	UI.fadeStroke(sheet, accent, 1.5, horizontal and 0 or 90)
	content.Parent = sheet
	sheet.Parent = frame
	UI.rod(frame, 0, horizontal, accent, z + 3)
	UI.rod(frame, 1, horizontal, accent, z + 3)
	frame:SetAttribute("Scroll", true)
	frame:SetAttribute("Horizontal", horizontal == true)
	frame:SetAttribute("Accent", accent)
	frame:GetPropertyChangedSignal("Size"):Connect(function()
		content.Size = frame.Size
	end)
	return sheet, content
end

-- ===== Glass style (2026-10-27, pass 3) =====
-- Soft-edged translucent panels painted at runtime, big emblems that break the frame, tapered dividers,
-- drifting light motes, and a world blur behind modal panels. See [[Research/UI Methods and Magic Effects]].
function UI.glass(frame, accent, feather, radius, alpha)
	for _, c in frame:GetChildren() do
		if c:IsA("UICorner") or c:IsA("UIStroke") or c:IsA("UIGradient") or c.Name == "Brackets" then
			c:Destroy()
		end
	end
	frame.BackgroundTransparency = 1
	local content, slice, f = UI.fa.panel(accent, feather, radius, alpha)
	local img = UI.new("ImageLabel", {
		Name = "Glass", BackgroundTransparency = 1, ImageContent = content, ScaleType = Enum.ScaleType.Slice, SliceCenter = slice,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 2 * f, 1, 2 * f),
		ZIndex = math.max(0, frame.ZIndex - 1), Active = false,
	}, frame)
	img:SetAttribute("NoStagger", true)
	frame:SetAttribute("Glass", true)
	frame:SetAttribute("Accent", accent)
	return img
end

function UI.emblem(parent, accent, glyph, size, pos, z)
	local e = UI.new("ImageLabel", { Name = "Emblem", BackgroundTransparency = 1, ImageContent = UI.fa.emblem(accent), AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(size, size), ZIndex = z }, parent)
	UI.new("UIScale", { Scale = 1 }, e)
	local sym = UI.fa.symbol and UI.fa.symbol(glyph)
	if sym then
		UI.new("ImageLabel", { Name = "Symbol", BackgroundTransparency = 1, ImageContent = sym, ImageColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.65), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.42, 0.42), ZIndex = z + 1 }, e)
		e:SetAttribute("NoStagger", true)
		return e
	end
	local g = UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = glyph, TextColor3 = Color3.new(1, 1, 1), FontFace = UI.TITLE_FONT, TextSize = math.floor(size * 0.3), ZIndex = z + 1 }, e)
	UI.new("UIStroke", { Color = accent, Thickness = 1.5, Transparency = 0.4 }, g)
	e:SetAttribute("NoStagger", true)
	return e
end

function UI.divider(parent, accent, pos, size, z)
	return UI.new("ImageLabel", { Name = "Divider", BackgroundTransparency = 1, ImageContent = UI.fa.divider(), ImageColor3 = accent, ImageTransparency = 0.25, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, ZIndex = z }, parent)
end

-- Show painted art in place of a flat Frame while existing code keeps animating the Frame:
-- its colour and transparency are copied onto the image. The Frame's own fill is hidden by a fully
-- transparent UIGradient (it never gets reset to 1: change signals are deferred, so resets raced the copy).
function UI.mirror(frame, content)
	for _, g in frame:GetChildren() do
		if g:IsA("UIGradient") or g:IsA("UICorner") then
			g:Destroy()
		end
	end
	UI.new("UIGradient", { Name = "HideFill", Transparency = NumberSequence.new(1) }, frame)
	local img = UI.new("ImageLabel", { Name = "Art", BackgroundTransparency = 1, ImageContent = content, Size = UDim2.fromScale(1, 1), ImageColor3 = frame.BackgroundColor3, ImageTransparency = frame.BackgroundTransparency, ZIndex = frame.ZIndex, Active = false }, frame)
	frame:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
		img.ImageTransparency = frame.BackgroundTransparency
	end)
	frame:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		img.ImageColor3 = frame.BackgroundColor3
	end)
	return img
end

-- slow light motes drifting up inside a panel (looping tweens; cheap)
function UI.motes(frame, accent, n)
	for i = 1, n do
		local s = math.random(5, 11)
		local x = math.random(8, 92) / 100
		local m = UI.new("ImageLabel", { Name = "Mote", BackgroundTransparency = 1, ImageContent = UI.fa.glow(), ImageColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.3), ImageTransparency = 0.35, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(s, s), Position = UDim2.fromScale(x, 0.95), ZIndex = frame.ZIndex, Active = false }, frame)
		m:SetAttribute("NoStagger", true)
		local tw = TweenService:Create(m, TweenInfo.new(math.random(40, 75) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, math.random() * 3), { Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.12, 0.08), ImageTransparency = 1 })
		tw:Play()
	end
end

-- Capsule button skin; the text moves to a child label so it draws above the skin.
function UI.glassButton(b, color)
	local content, slice, f = UI.fa.button(color)
	b.BackgroundTransparency = 1
	b.TextTransparency = 1
	b.TextStrokeTransparency = 1
	local skin = UI.new("ImageLabel", { Name = "Skin", BackgroundTransparency = 1, ImageContent = content, ScaleType = Enum.ScaleType.Slice, SliceCenter = slice, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 2 * f, 1, 2 * f), ZIndex = 1, Active = false }, b)
	local txt = UI.new("TextLabel", { Name = "Txt", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2, Active = false }, b)
	UI.new("UIStroke", { Name = "TextStroke", Thickness = 1.2, Color = Color3.new(0, 0, 0), Transparency = 0.45 }, txt)
	local function sync()
		txt.Text, txt.FontFace, txt.TextSize, txt.TextColor3 = b.Text, b.FontFace, b.TextSize, b.TextColor3
		txt.TextXAlignment, txt.TextYAlignment, txt.TextWrapped, txt.RichText = b.TextXAlignment, b.TextYAlignment, b.TextWrapped, b.RichText
	end
	for _, p in { "Text", "FontFace", "TextSize", "TextColor3", "TextXAlignment", "TextYAlignment", "TextWrapped", "RichText" } do
		b:GetPropertyChangedSignal(p):Connect(sync)
	end
	sync()
	b:SetAttribute("GlassButton", true)
end

-- World blur + slight desaturation while a modal glass panel is on screen (UI stays sharp).
UI.blurHolders = {}
function UI.onScreen(g)
	local p = g
	while p and p:IsA("GuiObject") do
		if not p.Visible then
			return false
		end
		p = p.Parent
	end
	return p ~= nil and (not p:IsA("ScreenGui") or p.Enabled)
end
function UI.blurLoop()
	local Lighting = game:GetService("Lighting")
	local blur = Instance.new("BlurEffect")
	blur.Name = "PanelBlur"
	blur.Size = 0
	blur.Parent = workspace.CurrentCamera
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "PanelCC"
	cc.Parent = Lighting
	local on = false
	while true do
		local want = false
		for g in UI.blurHolders do
			if g.Parent and UI.onScreen(g) then
				want = true
				break
			end
		end
		if want ~= on then
			on = want
			local cap = (SETTINGS.reducedMotion or SETTINGS.flashes == false) and 8 or (UserInputService.TouchEnabled and 10 or 14)
			if blur.Parent ~= workspace.CurrentCamera then
				blur.Parent = workspace.CurrentCamera
			end
			TweenService:Create(blur, TweenInfo.new(on and 0.35 or 0.25, Enum.EasingStyle.Quad), { Size = on and cap or 0 }):Play()
			TweenService:Create(cc, TweenInfo.new(0.35), { Saturation = on and -0.3 or 0, Brightness = on and -0.06 or 0, TintColor = on and Color3.fromRGB(225, 220, 255) or Color3.new(1, 1, 1) }):Play()
		end
		task.wait(0.1)
	end
end

-- Glass open: body fades in, emblem spins up, header then rows fill in.
function UI.glassOpen(frame)
	local glass = frame:FindFirstChild("Glass")
	if glass then
		glass.ImageTransparency = 1
		TweenService:Create(glass, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { ImageTransparency = 0 }):Play()
	end
	local emb = frame:FindFirstChild("Emblem", true)
	if emb then
		local s = emb:FindFirstChildOfClass("UIScale")
		s.Scale = 0.3
		emb.Rotation = -40
		TweenService:Create(s, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		TweenService:Create(emb, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
	end
	local d0 = 0.08
	local staggered = false
	for _, d in frame:GetDescendants() do
		if d:GetAttribute("Stagger") then
			UI.stagger(d, d0)
			d0 += 0.12
			staggered = true
		end
	end
	if not staggered then
		UI.stagger(frame, 0.08)
	end
end

-- Rows fill in one by one (top to bottom, then left to right): each slides up 12 px and fades in.
-- Original transparencies are remembered per row, so reopening mid-animation never loses them.
UI.stag = setmetatable({}, { __mode = "k" })
function UI.stagger(container, d0)
	local items = {}
	for _, c in container:GetChildren() do
		if c:IsA("GuiObject") and c.Visible and not c:GetAttribute("NoStagger") then
			table.insert(items, c)
		end
	end
	table.sort(items, function(a, b)
		if math.abs(a.AbsolutePosition.Y - b.AbsolutePosition.Y) > 4 then
			return a.AbsolutePosition.Y < b.AbsolutePosition.Y
		end
		return a.AbsolutePosition.X < b.AbsolutePosition.X
	end)
	local info = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for i, it in items do
		local rec = UI.stag[it]
		if not rec then
			rec = { home = it.Position, saved = {} }
			for _, p in { it, unpack(it:GetDescendants()) } do
				if p:IsA("TextLabel") or p:IsA("TextButton") or p:IsA("TextBox") then
					rec.saved[p] = { TextTransparency = p.TextTransparency, BackgroundTransparency = p.BackgroundTransparency }
				elseif p:IsA("ImageLabel") or p:IsA("ImageButton") then
					rec.saved[p] = { ImageTransparency = p.ImageTransparency, BackgroundTransparency = p.BackgroundTransparency }
				elseif p:IsA("Frame") then
					rec.saved[p] = { BackgroundTransparency = p.BackgroundTransparency }
				elseif p:IsA("UIStroke") then
					rec.saved[p] = { Transparency = p.Transparency }
				end
			end
			UI.stag[it] = rec
		end
		rec.token = (rec.token or 0) + 1
		local token = rec.token
		for p, props in rec.saved do
			for k in props do
				p[k] = 1
			end
		end
		it.Position = rec.home + UDim2.fromOffset(0, 12)
		task.delay(d0 + (i - 1) * 0.05, function()
			for p, props in rec.saved do
				if p.Parent then
					TweenService:Create(p, info, props):Play()
				end
			end
			TweenService:Create(it, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = rec.home }):Play()
			task.delay(0.32, function()
				if UI.stag[it] == rec and rec.token == token then
					UI.stag[it] = nil
				end
			end)
		end)
	end
	return #items
end

-- Big-screen intro (from the reference shop): the world dims, a light streak crosses the screen and a large
-- sigil pops up; then it collapses as the panel unrolls. onReveal fires at that moment. ~0.5 s.
function UI.intro(root, accent, onReveal, reduced)
	if reduced then
		onReveal()
		return
	end
	-- a second tap during the intro is ignored (it would start a second intro)
	if root:GetAttribute("IntroBusy") then
		return
	end
	root:SetAttribute("IntroBusy", true)
	local dim = UI.new("Frame", { Name = "IntroDim", BackgroundColor3 = Color3.fromRGB(4, 4, 16), BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 40, Active = false }, root)
	local streak = UI.new("Frame", { BackgroundColor3 = accent, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 0, 0, 4), ZIndex = 41 }, dim)
	UI.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(1, 1) }) }, streak)
	local holder = UI.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(140, 140), ZIndex = 42 }, dim)
	local sc = UI.new("UIScale", { Scale = 0.2 }, holder)
	local halo = UI.new("Frame", { BackgroundColor3 = accent, BackgroundTransparency = 0.55, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.3, 1.3), ZIndex = 42 }, holder)
	UI.new("UICorner", { CornerRadius = UDim.new(1, 0) }, halo)
	UI.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1) }) }, halo)
	local big = UI.diamond(holder, 78, accent, UDim2.fromScale(0.5, 0.5), 43)
	UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(accent:Lerp(Color3.new(1, 1, 1), 0.5), accent:Lerp(Color3.new(0, 0, 0), 0.5)) }, big)
	local mid = UI.diamond(big, 44, Color3.fromRGB(10, 10, 26), UDim2.fromScale(0.5, 0.5), 44)
	mid.Rotation = 0
	local core = UI.diamond(mid, 18, accent:Lerp(Color3.new(1, 1, 1), 0.3), UDim2.fromScale(0.5, 0.5), 45)
	core.Rotation = 0
	TweenService:Create(dim, TweenInfo.new(0.18), { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(streak, TweenInfo.new(0.28, Enum.EasingStyle.Quint), { Size = UDim2.new(1, 0, 0, 4) }):Play()
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(big, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Rotation = 135 }):Play()
	task.delay(0.42, function()
		root:SetAttribute("IntroBusy", nil)
		onReveal()
		TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.1 }):Play()
		TweenService:Create(streak, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(halo, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(dim, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
		task.delay(0.5, function()
			dim:Destroy()
		end)
	end)
end

-- open = unroll from the centre with a glow flash; close = roll up fast
function UI.unroll(frame, open)
	local sheet = frame:FindFirstChild("Sheet")
	if not sheet then
		return
	end
	local horiz = frame:GetAttribute("Horizontal")
	local t = open and 0.42 or 0.13
	local info = TweenInfo.new(t, open and Enum.EasingStyle.Quint or Enum.EasingStyle.Quad, open and Enum.EasingDirection.Out or Enum.EasingDirection.In)
	local full, shut = UDim2.fromScale(1, 1), horiz and UDim2.fromScale(0, 1) or UDim2.fromScale(1, 0)
	if open then
		sheet.Size = shut
	end
	TweenService:Create(sheet, info, { Size = open and full or shut }):Play()
	for _, r in frame:GetChildren() do
		if r.Name == "Rod" then
			local at = r:GetAttribute("At")
			local home = horiz and UDim2.fromScale(at, 0.5) or UDim2.fromScale(0.5, at)
			local mid = UDim2.fromScale(0.5, 0.5)
			if open then
				r.Position = mid
			end
			TweenService:Create(r, info, { Position = open and home or mid }):Play()
		end
	end
	if open then
		local accent = frame:GetAttribute("Accent") or Color3.new(1, 1, 1)
		local ring = UI.new("Frame", { Name = "OpenFlash", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = accent, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = math.max(1, frame.ZIndex - 1), Active = false }, frame)
		UI.new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, ring)
		UI.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 0.2), NumberSequenceKeypoint.new(1, 1) }) }, ring)
		TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1.5, 1.5), BackgroundTransparency = 1 }):Play()
		local content = sheet:FindFirstChild("Content")
		local target = content
		for _, d in content:GetDescendants() do
			if d:GetAttribute("Stagger") then
				target = d
				break
			end
		end
		UI.stagger(target, 0.16)
		task.delay(0.55, function()
			ring:Destroy()
		end)
	end
end

-- small diamond notches on a button's sides + a soft top shine (replaces corner brackets)
function UI.notches(b, color)
	local shine = UI.new("Frame", { Name = "Shine", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 2), Size = UDim2.new(1, -6, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, BorderSizePixel = 0, Active = false }, b)
	UI.new("UICorner", { CornerRadius = UDim.new(0, 8) }, shine)
	UI.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.86, 1) }, shine)
	if b.Size.X.Offset >= 60 or b.Size.X.Scale > 0 then
		UI.diamond(b, 9, color, UDim2.fromScale(0, 0.5))
		UI.diamond(b, 9, color, UDim2.fromScale(1, 0.5))
	end
end

-- dark tinted body with a bright accent line instead of a candy gradient
-- Fondamento draws the digit 1 like a lowercase i, so any text with a number switches to the body font
function UI.numFont(inst)
	local function update()
		if inst:GetAttribute("KeepFont") then
			return
		end
		inst.Font = string.find(inst.Text, "%d") and STYLE.fontB or STYLE.font
	end
	inst:GetPropertyChangedSignal("Text"):Connect(update)
	update()
end

function UI.tintButton(b, color)
	if b:GetAttribute("ObjectButton") then -- object buttons: grey = dim the art, green = switched on
		local dim = color == STYLE.grey
		for _, o in b:GetDescendants() do
			if o:IsA("ImageLabel") and o:GetAttribute("Tint") then
				o.ImageColor3 = dim and Color3.fromRGB(125, 122, 140) or Color3.new(1, 1, 1)
			end
		end
		b:SetAttribute("On", color == STYLE.green)
		return
	end
	local skin = b:FindFirstChild("Skin")
	if skin and UI.fa then
		skin.ImageContent = UI.fa.button(color)
		return
	end
	-- solid dark body: a UIGradient on a TextButton would also tint (darken) its text
	b.BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.68)
	local g = b:FindFirstChildOfClass("UIGradient")
	if g then
		g:Destroy()
	end
	local s = b:FindFirstChildOfClass("UIStroke")
	if s then
		s.Color = color
	end
end

	return UI
end
