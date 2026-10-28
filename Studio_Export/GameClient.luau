--!nonstrict
-- Client: UI, rendering, input, full-screen hatch, ultimate effects and tutorial. Every outcome comes from the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Path = require(Shared:WaitForChild("Path"))
local MatchSim = require(Shared:WaitForChild("MatchSim"))
local Models = require(script.Parent:WaitForChild("Models"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local ActionRemote = remotes:WaitForChild("Action")
local EventRemote = remotes:WaitForChild("Event")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local map = workspace:WaitForChild("Map")
map:WaitForChild("Crystal")

-- Stand-in for the future Settings panel (see Game Design Doc). Flashes Off softens every full-screen flash.
local SETTINGS = { flashes = true, reducedMotion = false, shake = true }
local GROUND = 1.0 -- top of the pads
local IS_PHONE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local visuals = Instance.new("Folder")
visuals.Name = "ClientVisuals"
visuals.Parent = workspace

-- ===== Style =====
local STYLE = {
	-- dark medieval fantasy (the Sols look): midnight panels, one bright accent per colour, pale bracket corners
	panel = Color3.fromRGB(12, 15, 32),
	panelDark = Color3.fromRGB(4, 6, 14),
	header = Color3.fromRGB(20, 16, 52),
	text = Color3.fromRGB(240, 244, 255),
	muted = Color3.fromRGB(150, 160, 196),
	green = Color3.fromRGB(70, 235, 160),
	gold = Color3.fromRGB(255, 208, 96),
	orange = Color3.fromRGB(255, 154, 66),
	gem = Color3.fromRGB(110, 210, 255),
	red = Color3.fromRGB(255, 76, 90),
	blue = Color3.fromRGB(80, 175, 255),
	purple = Color3.fromRGB(186, 128, 255),
	grey = Color3.fromRGB(110, 120, 156),
	font = Enum.Font.Fondamento, -- headings and button text
	fontB = Enum.Font.TitilliumWeb, -- numbers and small text (Sarpanch's 'a' reads as 'o' when small)
	display = Enum.Font.GrenzeGotisch, -- big titles only
}

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in props do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function round(gui, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, gui)
end

local function outline(gui, thickness, transparency, color)
	return new("UIStroke", {
		Color = color or Color3.new(1, 1, 1), Thickness = thickness or 2, Transparency = transparency or 0.7,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, gui)
end

local function shade(color, amount)
	return color:Lerp(amount > 0 and Color3.new(1, 1, 1) or Color3.new(0, 0, 0), math.abs(amount))
end

local function gradient(gui, color, rotation)
	return new("UIGradient", { Color = ColorSequence.new(shade(color, 0.22), shade(color, -0.25)), Rotation = rotation or 90 }, gui)
end

local TEXT_STROKE = 0.3
-- helpers live in one table: this script is close to Luau's limit of 200 local variables
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

local function label(parent, text, size, color, anchor, pos, dims, font)
	local l = new("TextLabel", {
		BackgroundTransparency = 1, Text = text, TextSize = size, TextColor3 = color or STYLE.text,
		Font = font or STYLE.font, AnchorPoint = anchor or Vector2.new(0.5, 0.5),
		Position = pos or UDim2.fromScale(0.5, 0.5), Size = dims or UDim2.fromScale(1, 1),
	}, parent)
	new("UIStroke", { Name = "TextStroke", Thickness = 1.5, Color = Color3.new(0, 0, 0), Transparency = TEXT_STROKE }, l)
	if (font or STYLE.font) == STYLE.font then
		UI.numFont(l)
	end
	return l
end

-- Numbers on screen go through Shared.NumberFormat with the player's numberFormat setting (T37).
UI.numberMode = "short"
local NumberFormat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local function fmt(n)
	return NumberFormat.format(math.floor(n), UI.numberMode)
end

local function tween(inst, time, props, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

-- The black text outline is its own UIStroke, so it must fade together with the text.
local function setLabelVisible(l, visible)
	l.TextTransparency = visible and 0 or 1
	local stroke = l:FindFirstChild("TextStroke")
	if stroke then
		stroke.Transparency = visible and TEXT_STROKE or 1
	end
end

local function fadeLabel(l, time)
	tween(l, time, { TextTransparency = 1 })
	local stroke = l:FindFirstChild("TextStroke")
	if stroke then
		tween(stroke, time, { Transparency = 1 })
	end
end

local function makeButton(parent, text, size, pos, color, anchor)
	local b = new("TextButton", {
		Text = text, TextSize = 22, Font = STYLE.font, TextColor3 = STYLE.text, TextStrokeTransparency = 0.6,
		BackgroundColor3 = color, AutoButtonColor = false, Size = size, Position = pos,
		AnchorPoint = anchor or Vector2.new(0.5, 0.5),
	}, parent)
	if UI.fa then
		UI.glassButton(b, color)
	else
		round(b, 10)
		outline(b, 2, 0.05, color)
		UI.tintButton(b, color)
		UI.notches(b, color)
	end
	UI.numFont(b)
	local scale = new("UIScale", { Scale = 1 }, b)
	b.MouseButton1Down:Connect(function() tween(scale, 0.07, { Scale = 0.93 }) end)
	b.MouseButton1Up:Connect(function() tween(scale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back) end)
	b.MouseEnter:Connect(function() tween(scale, 0.12, { Scale = 1.05 }) end)
	b.MouseLeave:Connect(function() tween(scale, 0.12, { Scale = 1 }) end)
	return b, scale
end

local function setButtonColor(b, color)
	UI.tintButton(b, color)
end

local function popIn(scale, from)
	if scale.Parent and scale.Parent:GetAttribute("Glass") then
		UI.glassOpen(scale.Parent)
		from = math.max(from or 0.6, 0.94)
	elseif scale.Parent and scale.Parent:GetAttribute("Scroll") then
		UI.unroll(scale.Parent, true)
		from = math.max(from or 0.6, 0.94)
	end
	scale.Scale = from or 0.6
	tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Close with a short shrink instead of vanishing.
local function hidePanel(panel, scale)
	if not panel.Visible then
		return
	end
	if panel:GetAttribute("Scroll") then
		UI.unroll(panel, false)
	end
	local glass = panel:FindFirstChild("Glass")
	if glass then
		tween(glass, 0.12, { ImageTransparency = 1 })
	end
	tween(scale, 0.12, { Scale = 0.85 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.13, function()
		panel.Visible = false
		scale.Scale = 1
	end)
end

-- Numbers roll up or down instead of snapping.
local counters = {}
function UI.refreshNumbers() -- redraw counters in the new number format
	for lbl, c in counters do
		lbl.Text = fmt(c.shown)
	end
end

local function countTo(lbl, value)
	local c = counters[lbl]
	if not c then
		counters[lbl] = { shown = value, target = value }
		lbl.Text = fmt(value)
		return
	end
	if c.target == value then
		return
	end
	c.target = value
	if c.tween then
		c.tween:Cancel()
	end
	local v = Instance.new("NumberValue")
	v.Value = c.shown
	v.Changed:Connect(function()
		c.shown = v.Value
		lbl.Text = fmt(v.Value)
	end)
	c.tween = TweenService:Create(v, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = value })
	c.tween.Completed:Connect(function()
		lbl.Text = fmt(value)
		c.shown = value
		v:Destroy()
	end)
	c.tween:Play()
end

-- Quick jitter for hits and warnings.
local function shakeGui(obj, amp, time)
	local home = obj:GetAttribute("HomePos")
	if not home then
		home = obj.Position
		obj:SetAttribute("HomePos", home)
	end
	task.spawn(function()
		local start = os.clock()
		while os.clock() - start < time do
			local k = 1 - (os.clock() - start) / time
			obj.Position = home + UDim2.fromOffset((math.random() - 0.5) * amp * 2 * k, (math.random() - 0.5) * amp * 2 * k)
			RunService.RenderStepped:Wait()
		end
		obj.Position = home
	end)
end

-- Slide a HUD element in from off-screen with a little overshoot.
local function enter(obj, dx, dy, delay)
	local target = obj.Position
	obj.Position = target + UDim2.fromOffset(dx, dy)
	task.delay(delay, function()
		tween(obj, 0.45, { Position = target }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
end

-- Panel with header bar, title and close button. Returns panel, body, scale, close, titleLabel.
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

-- ===== HUD skeleton =====
local gui = new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))
if UI.fa then
	-- soft violet vignette framing the whole screen
	new("ImageLabel", { Name = "Vignette", BackgroundTransparency = 1, ImageContent = UI.fa.vignette(), Size = UDim2.fromScale(1, 1), ZIndex = 0, Active = false }, gui)
	task.spawn(UI.blurLoop)
end
local hud = new("Frame", { Name = "Hud", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false }, gui)
local uiScale = new("UIScale", { Scale = 1 }, hud)

local function relayout()
	local vp = camera.ViewportSize
	local sc = IS_PHONE and math.clamp(vp.Y / 420, 0.8, 1.0) or math.clamp(vp.Y / 780, 0.6, 1.2)
	uiScale.Scale = sc
	hud.Size = UDim2.fromScale(1 / sc, 1 / sc)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(relayout)
relayout()

local function pill(parent, size, name)
	local f = new("Frame", { Name = name, BackgroundColor3 = STYLE.panel, BackgroundTransparency = 0.05, Size = size }, parent)
	if UI.fa then
		UI.glass(f, UI.STEEL, 14, 12, 0.8)
		return f
	end
	round(f, 10)
	UI.fadeStroke(f, UI.STEEL, 1.5, 0)
	local shine = new("Frame", { Name = "Shine", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 2), Size = UDim2.new(1, -8, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, f)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.75), NumberSequenceKeypoint.new(1, 1) }) }, shine)
	new("UIGradient", { Color = ColorSequence.new(shade(STYLE.panel, 0.08), STYLE.panelDark), Rotation = 90 }, f)
	return f
end

local rail = new("Frame", { Name = "Rail", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(168, 300) }, hud)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, rail)
do -- keep the rail below Roblox's top bar (it sat under the menu buttons and hid the level pill; UI Quality Bar gap 1)
	local GuiService = game:GetService("GuiService")
	local function placeRail()
		local ok, inset = pcall(function() return GuiService.TopbarInset.Height end)
		rail.Position = UDim2.fromOffset(12, 12 + (ok and inset or 58) / math.max(uiScale.Scale, 0.01))
	end
	placeRail()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(placeRail)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(placeRail)
end

local lvlPill = pill(rail, UDim2.new(1, 0, 0, 54), "Level")
lvlPill.LayoutOrder = 0
local lvlBadge = new("Frame", { BackgroundColor3 = STYLE.purple, Size = UDim2.fromOffset(38, 38), Position = UDim2.fromOffset(8, 8), Rotation = 45 }, lvlPill)
round(lvlBadge, 8)
gradient(lvlBadge, STYLE.purple)
local lvlNum = label(lvlPill, "1", 24, STYLE.text, Vector2.new(0.5, 0.5), UDim2.fromOffset(27, 27), UDim2.fromOffset(38, 38), STYLE.fontB)
lvlNum.ZIndex = 3
local lvlTitle = label(lvlPill, "TRAINER", 14, STYLE.muted, Vector2.new(0, 0), UDim2.fromOffset(54, 6), UDim2.new(1, -60, 0, 16), STYLE.fontB)
lvlTitle.TextXAlignment = Enum.TextXAlignment.Left
local xpBg = new("Frame", { BackgroundColor3 = Color3.fromRGB(14, 16, 32), Position = UDim2.fromOffset(54, 28), Size = UDim2.new(1, -64, 0, 16) }, lvlPill)
round(xpBg, 8)
local xpFill = new("Frame", { BackgroundColor3 = STYLE.purple, Size = UDim2.fromScale(0, 1) }, xpBg)
round(xpFill, 8)
gradient(xpFill, STYLE.purple)
local xpLabel = label(xpBg, "", 11, STYLE.text, nil, nil, nil, STYLE.fontB)
xpLabel.ZIndex = 4

local function currencyPill(order, color, name)
	local p = pill(rail, UDim2.new(1, 0, 0, 42), name)
	p.LayoutOrder = order
	local l = label(p, "0", 26, color, Vector2.new(0, 0.5), UDim2.new(0, 48, 0.5, 0), UDim2.new(1, -54, 1, 0), STYLE.fontB)
	l.TextXAlignment = Enum.TextXAlignment.Left
	local sc = new("UIScale", { Scale = 1 }, p)
	return p, l, sc
end

local coinPill, coinLabel, coinScale = currencyPill(1, STYLE.gold, "Coins")
local coinIcon = UI.artIcon(coinPill, "icon_coin", UDim2.fromOffset(34, 34), UDim2.fromOffset(8, 4))
if not coinIcon then
	coinIcon = new("Frame", { BackgroundColor3 = STYLE.gold, Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(10, 7) }, coinPill)
	round(coinIcon, 14)
	outline(coinIcon, 3, 0, Color3.fromRGB(200, 140, 20))
	gradient(coinIcon, STYLE.gold)
end

local gemPill, gemLabel, gemScale = currencyPill(2, STYLE.gem, "Gems")
local gemIcon = UI.artIcon(gemPill, "icon_gem", UDim2.fromOffset(34, 34), UDim2.fromOffset(8, 4))
if not gemIcon then
	gemIcon = new("Frame", { BackgroundColor3 = STYLE.gem, Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(14, 10), Rotation = 45 }, gemPill)
	round(gemIcon, 5)
	outline(gemIcon, 2, 0.2, Color3.fromRGB(30, 130, 180))
	gradient(gemIcon, STYLE.gem)
end

local function railButton(text, order, color)
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = order }, rail)
	local b = makeButton(holder, text, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), color or STYLE.blue)
	b.TextSize = 20
	return b
end

local progressBtn = railButton("Progression", 3, STYLE.purple)
local skillsBtn = railButton("Skill Tree", 4, STYLE.blue)
local quickBtn = railButton("Quick Roll: OFF", 5, STYLE.grey)
quickBtn.TextSize = 15
local spBadge = new("Frame", { BackgroundColor3 = STYLE.red, Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 2), ZIndex = 4, Visible = false }, skillsBtn)
round(spBadge, 12)
outline(spBadge, 2, 0.2, Color3.new(1, 1, 1))
local spBadgeLabel = label(spBadge, "0", 14)
spBadgeLabel.ZIndex = 5

-- Top centre
local stagePill = pill(hud, UDim2.fromOffset(200, 46), "Stage")
stagePill.AnchorPoint = Vector2.new(0.5, 0)
stagePill.Position = UDim2.new(0.5, 0, 0, 12)
local stageLabel = label(stagePill, "STAGE 1", 26, STYLE.text, nil, nil, nil, STYLE.fontB)
local streakLabel = label(hud, "", 18, STYLE.gold, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 62), UDim2.fromOffset(340, 26))
local bossBarBg = new("Frame", { BackgroundColor3 = STYLE.panelDark, Size = UDim2.fromOffset(260, 20), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 90), Visible = false }, hud)
round(bossBarBg, 10)
outline(bossBarBg, 2, 0.4, STYLE.red)
local bossBar = new("Frame", { BackgroundColor3 = STYLE.red, Size = UDim2.fromScale(1, 1) }, bossBarBg)
round(bossBar, 10)
gradient(bossBar, STYLE.red)
local bossBarLabel = label(bossBarBg, "", 13, STYLE.text, nil, nil, nil, STYLE.fontB)
bossBarLabel.ZIndex = 4

-- Top right: crystal
local hpPill = pill(hud, UDim2.fromOffset(176, 46), "Crystal")
hpPill.AnchorPoint = Vector2.new(1, 0)
hpPill.Position = UDim2.new(1, -12, 0, 12)
local hpBg = new("Frame", { BackgroundColor3 = Color3.fromRGB(14, 16, 32), Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6) }, hpPill)
round(hpBg, 9)
local hpFill = new("Frame", { BackgroundColor3 = STYLE.blue, Size = UDim2.fromScale(1, 1) }, hpBg)
round(hpFill, 9)
gradient(hpFill, STYLE.blue)
local hpLabel = label(hpBg, "", 20, STYLE.text, nil, nil, nil, STYLE.fontB)
hpLabel.ZIndex = 4
if UI.fa then
	-- glossy glowing capsule fill instead of a flat bar
	hpBg.BackgroundTransparency = 0.4
	hpFill.BackgroundTransparency = 1
	local c, sl, f = UI.fa.button(STYLE.blue, true)
	new("ImageLabel", { Name = "Skin", BackgroundTransparency = 1, ImageContent = c, ScaleType = Enum.ScaleType.Slice, SliceCenter = sl, SliceScale = 0.6, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, f * 1.2, 1, f * 1.2), ZIndex = 3 }, hpFill)
end

-- Bottom centre: roll (+ odds link)
local rollBtn, rollScale = makeButton(hud, "ROLL", UDim2.fromOffset(250, 78), UDim2.new(0.5, 0, 1, -54), STYLE.green)
rollBtn.Text = ""
local rollText = label(rollBtn, "ROLL", 34, STYLE.text, Vector2.new(0, 0), UDim2.fromOffset(92, 6), UDim2.new(1, -100, 0, 40))
rollText.TextXAlignment = Enum.TextXAlignment.Left
-- summoning card icon (painted at runtime) instead of the old egg art
local eggIcon = UI.fa and new("ImageLabel", { Name = "CardIcon", BackgroundTransparency = 1, ImageContent = UI.fa.cardIcon(), ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(52, 68), Position = UDim2.fromOffset(22, 5), ZIndex = 3 }, rollBtn) or UI.artIcon(rollBtn, "icon_egg", UDim2.fromOffset(60, 66), UDim2.fromOffset(18, 6))
if not eggIcon then
	eggIcon = new("Frame", { BackgroundColor3 = Color3.fromRGB(250, 244, 228), Size = UDim2.fromOffset(46, 58), Position = UDim2.fromOffset(24, 10) }, rollBtn)
	round(eggIcon, 24)
	outline(eggIcon, 3, 0, Color3.fromRGB(190, 175, 150))
end
local rollCost = label(rollBtn, "", 20, STYLE.gem, Vector2.new(0, 1), UDim2.new(0, 92, 1, -6), UDim2.new(1, -100, 0, 22), STYLE.fontB)
rollCost.TextXAlignment = Enum.TextXAlignment.Left
local oddsChip = makeButton(hud, "ODDS", UDim2.fromOffset(64, 30), UDim2.new(0.5, 136, 1, -16), STYLE.grey, Vector2.new(0, 1))
oddsChip.TextSize = 14

-- Bottom left: start wave + auto
local startWaveBtn = makeButton(hud, "START WAVE", UDim2.fromOffset(220, 64), UDim2.new(0, 12, 1, -12), STYLE.orange, Vector2.new(0, 1))
startWaveBtn.TextSize = 26
local autoBtn = makeButton(hud, "AUTO: OFF", UDim2.fromOffset(220, 38), UDim2.new(0, 12, 1, -84), STYLE.grey, Vector2.new(0, 1))
autoBtn.TextSize = 18

-- Bottom right: ultimate with a ready glow
local ultBtn, ultScale = makeButton(hud, "ULT", UDim2.fromOffset(90, 90), UDim2.new(1, -72, 1, -72), STYLE.grey)
for _, c in ultBtn:GetChildren() do if c:IsA("UICorner") then c:Destroy() end end
round(ultBtn, 6)
local ultFill = new("Frame", { BackgroundColor3 = STYLE.gold, BackgroundTransparency = 0.3, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), ZIndex = 0 }, ultBtn)
round(ultFill, 5)
local ultGlow = new("UIStroke", { Color = STYLE.gold, Thickness = 6, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, ultBtn)
local ultPulse = new("UIScale", { Scale = 1 }, ultBtn)
local ultTweens = {}

do -- block scope keeps the phone layout's locals off the top level
-- Phone layout. Roblox puts the thumbstick bottom-left and the jump button bottom-right, so on a phone the three rail
-- buttons move to a right-hand column under the crystal bar, AUTO and START WAVE flank ROLL at the bottom centre,
-- and ULT sits above the jump button. Toggle by hand with gui:SetAttribute("PhoneLayout", true/false).
local rightRail = new("Frame", { Name = "RightRail", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 66), Size = UDim2.fromOffset(168, 170) }, hud)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, rightRail)
local railHolders = { progressBtn.Parent, skillsBtn.Parent, quickBtn.Parent }
local function applyLayout(phone)
	rail.Position = UDim2.fromOffset(12, phone and 52 or 12) -- clear of Roblox's own top-left buttons on a phone
	for i, holder in railHolders do
		holder.Parent = phone and rightRail or rail
		holder.Size = UDim2.new(1, 0, 0, phone and 50 or 38) -- 50 logical = about 44 px at the phone scale
		holder.LayoutOrder = i + 2
	end
	if phone then
		autoBtn.AnchorPoint = Vector2.new(1, 1)
		autoBtn.Position = UDim2.new(0.5, -142, 1, -12)
		autoBtn.Size = UDim2.fromOffset(150, 52)
		startWaveBtn.AnchorPoint = Vector2.new(0, 1)
		startWaveBtn.Position = UDim2.new(0.5, 142, 1, -12)
		startWaveBtn.Size = UDim2.fromOffset(190, 64)
		oddsChip.AnchorPoint = Vector2.new(0.5, 1)
		oddsChip.Position = UDim2.new(0.5, 0, 1, -104)
		oddsChip.Size = UDim2.fromOffset(92, 50)
		ultBtn.Position = UDim2.new(0.5, 184, 0, 52) -- top, beside the stage pill: bottom-right is the jump button
	else
		autoBtn.AnchorPoint = Vector2.new(0, 1)
		autoBtn.Position = UDim2.new(0, 12, 1, -84)
		autoBtn.Size = UDim2.fromOffset(220, 38)
		startWaveBtn.AnchorPoint = Vector2.new(0, 1)
		startWaveBtn.Position = UDim2.new(0, 12, 1, -12)
		startWaveBtn.Size = UDim2.fromOffset(220, 64)
		oddsChip.AnchorPoint = Vector2.new(0, 1)
		oddsChip.Position = UDim2.new(0.5, 136, 1, -16)
		oddsChip.Size = UDim2.fromOffset(64, 30)
		ultBtn.Position = UDim2.new(1, -72, 1, -72)
	end
end
applyLayout(IS_PHONE)
gui:GetAttributeChangedSignal("PhoneLayout"):Connect(function()
	applyLayout(gui:GetAttribute("PhoneLayout") == true)
end)
end

local toast = label(hud, "", 24, STYLE.text, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.7), UDim2.fromOffset(420, 36))
toast.ZIndex = 40
setLabelVisible(toast, false)
local banner = label(hud, "", 56, STYLE.gold, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.26), UDim2.fromOffset(760, 80), STYLE.display)
banner.ZIndex = 40
setLabelVisible(banner, false)
local bannerScale = new("UIScale", { Scale = 1 }, banner)
local subBanner = label(hud, "", 24, STYLE.text, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.34), UDim2.fromOffset(760, 40), STYLE.fontB)
subBanner.ZIndex = 40
setLabelVisible(subBanner, false)

local flash = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 30, Active = false }, gui)
local dim = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2, Active = false }, gui)

-- Pet panel: upgrades plus Delete at the bottom
local upPanel, upBody, upScale, upClose, upTitle = makePanel(hud, UDim2.fromOffset(300, 412), "Pet", STYLE.blue)
upPanel.AnchorPoint = Vector2.new(1, 0.5)
upPanel.Position = UDim2.new(1, -12, 0.5, 0)
local upInfo = label(upBody, "", 15, STYLE.muted, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 6), UDim2.new(1, -20, 0, 20), STYLE.fontB)
upInfo.ZIndex = 8
local upRows = {}
for i, kind in Config.UPGRADE_ORDER do
	local def = Config.UPGRADES[kind]
	local row = new("Frame", { BackgroundColor3 = Color3.fromRGB(40, 46, 84), Size = UDim2.new(1, -20, 0, 78), Position = UDim2.new(0, 10, 0, 32 + (i - 1) * 86), ZIndex = 7 }, upBody)
	if UI.fa then
		-- open rows split by a faint line (no solid boxes)
		row.BackgroundTransparency = 1
		local sep = UI.divider(row, UI.STEEL, UDim2.new(0.5, 0, 1, 4), UDim2.new(1, 0, 0, 8), 7)
		sep.ImageTransparency = 0.7
	else
		round(row, 12)
	end
	local n = label(row, def.name, 20, STYLE.text, Vector2.new(0, 0), UDim2.fromOffset(12, 5), UDim2.fromOffset(130, 24))
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.ZIndex = 8
	local desc = label(row, def.desc, 14, STYLE.muted, Vector2.new(0, 0), UDim2.fromOffset(12, 29), UDim2.fromOffset(150, 30), STYLE.fontB)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.ZIndex = 8
	local pips = {}
	for p = 1, Config.UPGRADE_MAX do
		local pip = new("Frame", { BackgroundColor3 = STYLE.grey, Size = UDim2.fromOffset(20, 8), Position = UDim2.fromOffset(12 + (p - 1) * 24, 62), ZIndex = 8 }, row)
		round(pip, 4)
		if UI.fa then
			new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 160)) }, pip)
		end
		pips[p] = pip
	end
	local buy = makeButton(row, "", UDim2.fromOffset(104, 54), UDim2.new(1, -8, 0.5, 0), STYLE.green, Vector2.new(1, 0.5))
	buy.TextSize = 18
	buy.ZIndex = 8
	upRows[kind] = { pips = pips, buy = buy }
end
local deleteBtn = makeButton(upBody, "Delete", UDim2.new(1, -20, 0, 44), UDim2.new(0.5, 0, 1, -10), STYLE.red, Vector2.new(0.5, 1))
deleteBtn.TextSize = 18
deleteBtn.ZIndex = 8

-- Odds panel
local oddsPanel, oddsBody, oddsScale, oddsClose = makePanel(hud, UDim2.fromOffset(440, 360), "Roll Odds", STYLE.gold)
UI.blurHolders[oddsPanel] = true
oddsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
oddsPanel.Position = UDim2.fromScale(0.5, 0.5)
oddsPanel.ZIndex = 9
local oddsRows = {}
for i, r in Config.RARITY_ORDER do
	local names = {}
	for _, id in Config.petsOfRarity(r) do
		table.insert(names, Config.PETS[id].name)
	end
	local l = label(oddsBody, "", 20, Config.RARITIES[r].color, Vector2.new(0, 0), UDim2.fromOffset(18, 10 + (i - 1) * 62), UDim2.new(1, -36, 0, 26))
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 10
	local n = label(oddsBody, table.concat(names, ", "), 16, STYLE.muted, Vector2.new(0, 0), UDim2.fromOffset(18, 36 + (i - 1) * 62), UDim2.new(1, -36, 0, 20), STYLE.fontB)
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.ZIndex = 10
	if UI.fa and i < #Config.RARITY_ORDER then
		-- faint row separator, like the reference's list rows
		local sep = UI.divider(oddsBody, UI.STEEL, UDim2.new(0.5, 0, 0, 62 + (i - 1) * 62), UDim2.new(1, -30, 0, 8), 9)
		sep.ImageTransparency = 0.7
	end
	oddsRows[r] = l
end
local oddsNote = label(oddsBody, "", 16, STYLE.gem, Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -8), UDim2.new(1, -30, 0, 40), STYLE.fontB)
oddsNote.TextWrapped = true
oddsNote.ZIndex = 10

-- Progression panel
local progPanel, progBody, progScale, progClose = makePanel(hud, UDim2.fromOffset(400, 380), "Trainer Progression", STYLE.purple)
UI.blurHolders[progPanel] = true
progPanel.AnchorPoint = Vector2.new(0.5, 0.5)
progPanel.Position = UDim2.fromScale(0.5, 0.5)
progPanel.ZIndex = 9
local progHead = label(progBody, "", 22, STYLE.text, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 10), UDim2.new(1, -20, 0, 30))
progHead.ZIndex = 10
local progXpBg = new("Frame", { BackgroundColor3 = Color3.fromRGB(14, 16, 32), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 46), Size = UDim2.new(1, -40, 0, 20), ZIndex = 10 }, progBody)
round(progXpBg, 10)
local progXp = new("Frame", { BackgroundColor3 = STYLE.purple, Size = UDim2.fromScale(0, 1), ZIndex = 11 }, progXpBg)
round(progXp, 10)
gradient(progXp, STYLE.purple)
local progList = label(progBody, "", 18, STYLE.muted, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 78), UDim2.new(1, -40, 0, 250), STYLE.fontB)
progList.TextXAlignment = Enum.TextXAlignment.Left
progList.TextYAlignment = Enum.TextYAlignment.Top
progList.ZIndex = 10

-- Tutorial card
local tutCard = new("Frame", { BackgroundColor3 = STYLE.panelDark, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 112), Size = UDim2.fromOffset(480, 82), Visible = false, ZIndex = 6 }, hud)
round(tutCard, 16)
outline(tutCard, 3, 0.1, STYLE.gold)
local tutText = label(tutCard, "", 20, STYLE.text, Vector2.new(0, 0.5), UDim2.new(0, 16, 0.5, 0), UDim2.new(1, -112, 1, -10), STYLE.fontB)
tutText.TextWrapped = true
tutText.TextXAlignment = Enum.TextXAlignment.Left
tutText.ZIndex = 7
local tutSkip = makeButton(tutCard, "Skip", UDim2.fromOffset(76, 40), UDim2.new(1, -16, 0.5, 0), STYLE.grey, Vector2.new(1, 0.5))
tutSkip.TextSize = 16
tutSkip.ZIndex = 7
if UI.fa then
	UI.glass(tutCard, STYLE.gold, 26, 18)
else
	UI.scroll(tutCard, STYLE.gold, true)
end

-- Start screen
local startScreen = new("Frame", { BackgroundColor3 = Color3.fromRGB(10, 12, 28), BackgroundTransparency = 0.2, Size = UDim2.fromScale(1, 1), ZIndex = 10 }, gui)
local startCard = new("Frame", { BackgroundColor3 = STYLE.panel, Size = UDim2.fromOffset(460, 310), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 11 }, startScreen)
round(startCard, 10)
outline(startCard, 3, 0.15, STYLE.gold)
UI.brackets(startCard, 20, 3, 5)
new("UIGradient", { Color = ColorSequence.new(shade(STYLE.panel, 0.08), STYLE.panelDark), Rotation = 90 }, startCard)
local startScale = new("UIScale", { Scale = 1 }, startCard)
label(startCard, "GUARDIAN GRID", 50, STYLE.gold, Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.07), UDim2.new(1, -20, 0, 60), STYLE.display).ZIndex = 12
local startSub = label(startCard, "Summon familiars, merge three that touch, and push the stage as far as you can. You can't lose, but every leak costs your streak.", 18, STYLE.muted, Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.29), UDim2.new(1, -50, 0, 100), STYLE.fontB)
startSub.TextWrapped = true
startSub.ZIndex = 12
local startBtn = makeButton(startCard, "PLAY", UDim2.fromOffset(240, 70), UDim2.fromScale(0.5, 0.8), STYLE.green)
startBtn.ZIndex = 12
if UI.fa then
	UI.glass(startCard, STYLE.gold)
	UI.motes(startCard, STYLE.gold, 9)
	UI.emblem(startCard, STYLE.gold, "crown", 112, UDim2.new(0.5, 0, 0, 0), 14)
	for _, c in startCard:GetChildren() do
		if c:IsA("TextLabel") and c.Text == "GUARDIAN GRID" then
			c.Position = UDim2.fromScale(0.5, 0.17)
			c.FontFace = UI.TITLE_FONT
			c.TextSize = 40
			c.TextColor3 = Color3.fromRGB(255, 226, 150)
		end
	end
	startSub.Position = UDim2.fromScale(0.5, 0.4)
	UI.divider(startCard, STYLE.gold, UDim2.fromScale(0.5, 0.36), UDim2.new(0.8, 0, 0, 12), 12)
	UI.blurHolders[startCard] = true
else
	UI.scroll(startCard, STYLE.gold)
end

local tutScale = new("UIScale", { Scale = 1 }, tutCard)
local badgeScale = new("UIScale", { Scale = 1 }, lvlBadge)

local function playHudEntrance()
	enter(rail, -220, 0, 0)
	enter(stagePill, 0, -90, 0.08)
	enter(hpPill, 0, -90, 0.14)
	enter(rollBtn, 0, 140, 0.1)
	enter(oddsChip, 0, 140, 0.18)
	enter(startWaveBtn, -260, 0, 0.16)
	enter(autoBtn, -260, 0, 0.22)
	enter(ultBtn, 160, 0, 0.2)
end

-- the egg on the ROLL button wobbles all the time
TweenService:Create(eggIcon, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 9 }):Play()
eggIcon.Rotation = -9

-- START WAVE pulses while it is waiting for you
local startPulse = new("UIScale", { Scale = 1 }, startWaveBtn)
local startPulseTween = TweenService:Create(startPulse, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.07 })
local startPulsing = false
local function setStartReady(ready)
	if ready == startPulsing then
		return
	end
	startPulsing = ready
	if ready then
		startPulseTween:Play()
	else
		startPulseTween:Cancel()
		tween(startPulse, 0.15, { Scale = 1 })
	end
end

-- ===== Feedback helpers =====
local function showToast(text)
	toast.Text = text
	setLabelVisible(toast, true)
	toast.Position = UDim2.new(0.5, 0, 0.7, 16)
	tween(toast, 0.35, { Position = UDim2.new(0.5, 0, 0.7, -6) }, Enum.EasingStyle.Back)
	task.delay(0.5, function()
		fadeLabel(toast, 0.9)
	end)
end

local bannerToken = 0
-- The hatch reveal covers the HUD, so banners wait until it closes (oldest dropped past 3).
local bannerWait = {}
local function showBanner(text, color, sub)
	local rg = gui:FindFirstChild("Reveal")
	if rg and rg.Visible then
		table.insert(bannerWait, { text, color, sub })
		if #bannerWait > 3 then
			table.remove(bannerWait, 1)
		end
		return
	end
	bannerToken += 1
	local mine = bannerToken
	banner.Text = text
	banner.TextColor3 = color or STYLE.gold
	setLabelVisible(banner, true)
	subBanner.Text = sub or ""
	setLabelVisible(subBanner, sub ~= nil)
	bannerScale.Scale = 0.5
	tween(bannerScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(1.6, function()
		if mine == bannerToken then
			fadeLabel(banner, 0.5)
			fadeLabel(subBanner, 0.5)
		end
	end)
end

local function flushBanners()
	task.spawn(function()
		while #bannerWait > 0 do
			local b = table.remove(bannerWait, 1)
			showBanner(b[1], b[2], b[3])
			if #bannerWait > 0 then
				task.wait(1.1)
			end
		end
	end)
end

local function screenFlash(color, strength)
	if not SETTINGS.flashes then
		strength = strength * 0.25
	end
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 1 - strength
	tween(flash, 0.5, { BackgroundTransparency = 1 })
end

-- ===== World =====
local petParts = {} -- slot -> { model, anims, pet, tier, cool, popT, kick }
local pending = {} -- slot -> true while a hatch is still playing for it
local enemies = {} -- id -> { model, fill, spawnTime, speed, hp, maxHp, kind }
local liveFx = 0
local dying, flying = {}, {}
local lastSnap = nil
local camZoom = 1
local shake = { t = 0, amp = 0 }
-- Impact kit (ImpactFX, AbilityFX). One table to stay under Luau's 200-local limit; missing modules just skip the extras.
local FXK = { lastRend = 0 }
do
	local ok1, m1 = pcall(function() return require(ReplicatedStorage:WaitForChild("ImpactFX", 5)) end)
	local ok2, m2 = pcall(function() return require(ReplicatedStorage:WaitForChild("AbilityFX", 5)) end)
	FXK.impact = ok1 and m1 or nil
	FXK.ability = ok2 and m2 or nil
	local ok3, m3 = pcall(function() return require(ReplicatedStorage:WaitForChild("SoundFX", 5)) end)
	FXK.sfx = ok3 and m3 or nil
	local ok4, m4 = pcall(function() return require(ReplicatedStorage:WaitForChild("ProjectileFX", 5)) end)
	FXK.proj = ok4 and m4 or nil
	local ok5, m5 = pcall(function() return require(ReplicatedStorage:WaitForChild("CutsceneFX", 5)) end)
	FXK.cut = ok5 and m5 or nil
	local ok6, m6 = pcall(function() return require(ReplicatedStorage:WaitForChild("TDFeedback", 5)) end)
	FXK.td = ok6 and m6 or nil -- board feedback sized for the far camera (T19)
	local ok7, m7 = pcall(function() return require(ReplicatedStorage:WaitForChild("ParticleFXLib", 5)) end)
	FXK.pfx = ok7 and m7 or nil -- ParticleFX catalogue by name: FXK.pfx.play(name, cframe, opts) (T29)
	-- particlefx.studio sheets for the board events (T23). A sheet is used only once Roblox has finished processing
	-- the upload (fetch status Success); until then, or with no id, the procedural TDFeedback effect plays instead.
	FXK.SHEETS = { upgrade = "tower-upgrade", splash = "splash-damage-ring", coin = "enemy-defeat-coin-drop", rarityFrame = "rarity-frames", placement = "tower-placement", achievement = "achievement-unlocked" }
	local okR, reg = pcall(function() return require(ReplicatedStorage:WaitForChild("ParticleFXRegistry", 5)) end)
	FXK.pfxReg = okR and reg or {}
	function FXK.sheetReady(kind)
		local name = FXK.SHEETS[kind]
		local e = name and FXK.pfxReg[name]
		if not (FXK.pfx and e and e.id) then
			return nil
		end
		local ok, st = pcall(function() return game:GetService("ContentProvider"):GetAssetFetchStatus("rbxassetid://" .. tostring(e.id)) end)
		return (ok and st == Enum.AssetFetchStatus.Success) and name or nil
	end
	task.spawn(function() -- ask for the sheets early so they are ready by the first merge or kill
		local list = {}
		for _, name in FXK.SHEETS do
			local e = FXK.pfxReg[name]
			if e and e.id then
				local il = Instance.new("ImageLabel")
				il.Image = "rbxassetid://" .. tostring(e.id)
				table.insert(list, il)
			end
		end
		pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
	end)
end
-- Player settings from the server (SettingsDefaults). SETTINGS is changed in place so every reader sees the new values.
function FXK.applySettings(s)
	if type(s) ~= "table" then
		return
	end
	SETTINGS.flashes = s.flashes ~= false
	SETTINGS.reducedMotion = s.reducedMotion == true
	SETTINGS.shake = s.shake ~= false
	if FXK.flashToggle then
		FXK.flashToggle.Text = SETTINGS.flashes and "Flashes: ON" or "Flashes: OFF"
	end
	SETTINGS.gameSpeed = s.gameSpeed == 2 and 2 or 1 -- CutsceneFX skips signatures by itself at 2x
	local particles = s.particles == "low" and "Low" or (s.particles == "high" and "High" or "Default")
	-- Low effects detail: the Lampwick Lane lamps stop casting shadows (10 shadowed lights are the costliest part of the set)
	FXK.lowGfx = s.particles == "low"
	if s.numberFormat and s.numberFormat ~= UI.numberMode then
		UI.numberMode = s.numberFormat
		UI.refreshNumbers()
	end
	FXK.quality = FXK.CAP[s.particles] and s.particles or "default"
	if FXK.proj then
		FXK.proj.quality = FXK.quality
		FXK.proj.timeScale = s.gameSpeed == 2 and 2 or 1
	end
	for _, d in workspace:GetDescendants() do
		if d:IsA("PointLight") and d.Name == "LampLight" then
			d.Shadows = not FXK.lowGfx
		end
	end
	-- Emitter budget for everything that lives in the world (familiars, fog, portal; burst emitters have Rate 0 and are left to burst()): Rate scales with the quality, and on
	-- Low the 2nd and later emitter on one part (the secondary layers) is switched off. Bursts have their own cap in burst().
	function FXK.budgetEmitter(pe)
		if pe:GetAttribute("BaseRate") == nil then
			pe:SetAttribute("BaseRate", pe.Rate)
			pe:SetAttribute("BaseEnabled", pe.Enabled)
		end
		local base = pe:GetAttribute("BaseRate")
		if base > 0 then
			pe.Rate = base * (FXK.quality == "low" and 0.5 or (FXK.quality == "high" and 1.25 or 1))
		end
		local secondary = false
		if FXK.quality == "low" and pe.Parent then
			local first
			for _, c in pe.Parent:GetChildren() do
				if c:IsA("ParticleEmitter") then
					first = first or c
				end
			end
			secondary = first ~= pe
		end
		pe.Enabled = pe:GetAttribute("BaseEnabled") and not secondary
	end
	for _, d in workspace:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			FXK.budgetEmitter(d)
		end
	end
	if not FXK.lampHook then
		FXK.lampHook = workspace.DescendantAdded:Connect(function(d)
			if d:IsA("PointLight") and d.Name == "LampLight" then
				d.Shadows = not FXK.lowGfx
			elseif d:IsA("ParticleEmitter") then
				task.defer(FXK.budgetEmitter, d)
			end
		end)
	end
	local okR, Reveal = pcall(function() return require(ReplicatedStorage:WaitForChild("RevealFX", 2)) end)
	if okR and Reveal then
		Reveal.setSettings({ flashes = SETTINGS.flashes, reducedMotion = SETTINGS.reducedMotion, particles = particles })
	end
	if FXK.sfx and type(s.sfxVolume) == "number" then
		pcall(FXK.sfx.setVolumes, { sfx = s.sfxVolume })
	end
	local okM, Music = pcall(function() return require(ReplicatedStorage:WaitForChild("MusicFX", 2)) end)
	if okM and Music and type(s.musicVolume) == "number" then
		pcall(Music.setVolumes, { music = s.musicVolume })
	end
	if game:GetService("RunService"):IsStudio() then
		script:SetAttribute("AppliedSettings", game:GetService("HttpService"):JSONEncode({ s = SETTINGS, reveal = okR and Reveal and { f = Reveal.settings.flashes, r = Reveal.settings.reducedMotion, p = Reveal.settings.particles } or false, music = okM and Music and Music.volumes and Music.volumes.music or false }))
	end
end
-- play a SoundFX cue if the module is present (sounds are Studio-preview files until uploaded)
function FXK.play(name, o)
	if FXK.sfx then
		pcall(FXK.sfx.play, name, o or {})
	end
end

-- Free placement: "slot" is now a unit id; its position comes from the server (snapshot, Roll and Move events).
FXK.pos = {}
local function slotPos(slot)
	return FXK.pos[slot] or Config.SLOTS[slot] or Vector3.new(0, 1, 0)
end

local function groundOf(slot)
	local p = slotPos(slot)
	return Vector3.new(p.X, GROUND, p.Z)
end

-- Effect budget: only so many burst emitters live at once (each lives 1.3 s), fewer and smaller on Low. Big moments
-- (boss defeat, ultimate) pass priority and may use a little headroom. Skipped bursts are counted in FXK.skipped.
FXK.quality, FXK.liveBursts, FXK.skipped = "default", 0, 0
FXK.CAP = { low = 10, default = 20, high = 32 }
-- Game clock from the server (see MatchService.snap): enemy positions follow it so 1x and 2x both look right.
FXK.clock = { g = 0, at = 0, speed = 1 }
function FXK.simNow()
	return FXK.clock.g + (workspace:GetServerTimeNow() - FXK.clock.at) * FXK.clock.speed
end
local function burst(pos, color, count, speed, priority)
	local q = FXK.quality
	if FXK.liveBursts >= FXK.CAP[q] + (priority and 6 or 0) then
		FXK.skipped += 1
		return
	end
	FXK.liveBursts += 1
	task.delay(1.3, function()
		FXK.liveBursts -= 1
	end)
	count = math.max(2, math.floor((count or 16) * (q == "low" and 0.5 or (q == "high" and 1.25 or 1)) + 0.5))
	local anchor = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, Transparency = 1, Size = Vector3.one, Position = pos }, visuals)
	local pe = new("ParticleEmitter", {
		Color = ColorSequence.new(color), Lifetime = NumberRange.new(0.4, 0.9), Speed = NumberRange.new((speed or 10) * 0.5, speed or 22),
		SpreadAngle = Vector2.new(180, 180), Rate = 0, LightEmission = 0.7,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) }),
	}, anchor)
	pe:Emit(count or 16)
	Debris:AddItem(anchor, 1.3)
end

local function floatText(pos, text, color, size)
	if liveFx > 40 then
		return
	end
	liveFx += 1
	local anchor = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, Transparency = 1, Size = Vector3.one, Position = pos }, visuals)
	local bb = new("BillboardGui", { Size = UDim2.fromOffset(150, 40), AlwaysOnTop = true, Adornee = anchor, StudsOffset = Vector3.new(0, 2, 0) }, anchor)
	local l = label(bb, text, size or 22, color)
	tween(bb, 0.7, { StudsOffset = Vector3.new(0, 6, 0) })
	fadeLabel(l, 0.7)
	Debris:AddItem(anchor, 0.8)
	task.delay(0.8, function() liveFx -= 1 end)
end

local function ring(pos, color, endSize, time)
	local p = new("Part", {
		Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false, Material = Enum.Material.Neon,
		Color = color, Transparency = 0.2, Size = Vector3.new(0.2, 2, 2), CFrame = CFrame.new(pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2),
	}, visuals)
	tween(p, time, { Size = Vector3.new(0.2, endSize, endSize), Transparency = 1 })
	Debris:AddItem(p, time + 0.1)
end

local function pillar(pos, color, time, width)
	local p = new("Part", {
		Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false, Material = Enum.Material.Neon,
		Color = color, Transparency = 0.35, Size = Vector3.new(70, width or 3, width or 3), CFrame = CFrame.new(pos + Vector3.new(0, 35, 0)) * CFrame.Angles(0, 0, math.pi / 2),
	}, visuals)
	tween(p, time, { Size = Vector3.new(70, 0.4, 0.4), Transparency = 1 })
	Debris:AddItem(p, time + 0.1)
end

local function rarityColor(pet)
	return Config.RARITIES[Config.PETS[pet].rarity].color
end

local function setPet(slot, pet, tier, animate)
	local old = petParts[slot]
	if old then
		old.model:Destroy()
	end
	local model, anims, cool = Models.buildPet(pet, tier)
	-- footprint plate: brass disc the size of the pet's footprint, rimmed in its rarity colour (Bloons-style)
	local fp = Config.footprint(pet)
	new("Part", { Name = "Footprint", Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 92, 50), Size = Vector3.new(0.3, fp * 2, fp * 2), CFrame = model:GetPivot() * CFrame.new(0, -0.12, 0) * CFrame.Angles(0, 0, math.pi / 2) }, model)
	new("Part", { Name = "FootprintRim", Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Material = Enum.Material.Neon, Color = rarityColor(pet), Transparency = 0.45, Size = Vector3.new(0.12, fp * 2 + 0.5, fp * 2 + 0.5), CFrame = model:GetPivot() * CFrame.new(0, -0.2, 0) * CFrame.Angles(0, 0, math.pi / 2) }, model)
	model.Parent = visuals
	local entry = { model = model, anims = anims, pet = pet, tier = tier, cool = cool, popT = animate and 0 or 1 }
	petParts[slot] = entry
	model:PivotTo(CFrame.new(groundOf(slot)) * CFrame.Angles(0, math.pi, 0))
	-- imported pets: skeletal idle (shape pets ignore this). The Blender Spawn clip is scale-only, which Roblox
	-- bone poses drop, so spawning keeps the existing pop-in scale instead.
	Models.playClip(model, "Idle")
	return entry
end

local function removePet(slot, withBurst)
	local entry = petParts[slot]
	if entry then
		if withBurst then
			burst(groundOf(slot) + Vector3.new(0, 2, 0), rarityColor(entry.pet), 14)
		end
		entry.model:Destroy()
		petParts[slot] = nil
	end
end

local function clearWorld()
	for slot in petParts do
		removePet(slot, false)
	end
	for _, e in enemies do
		e.model:Destroy()
	end
	table.clear(enemies)
	table.clear(pending)
end

local function clearEnemies()
	for _, e in enemies do
		burst(e.model:GetPivot().Position + Vector3.new(0, 2, 0), Color3.new(1, 1, 1), 6)
		e.model:Destroy()
	end
	table.clear(enemies)
end

local function spawnEnemy(data)
	local def = Config.ENEMIES[data.kind]
	local model = Models.buildEnemy(data.kind)
	model.Parent = visuals
	local isBoss = data.kind == "Boss"
	local bb = new("BillboardGui", { Size = UDim2.fromOffset(isBoss and 130 or 62, isBoss and 14 or 8), StudsOffset = Vector3.new(0, model:GetExtentsSize().Y + 1, 0), AlwaysOnTop = true, Adornee = model.Root }, model.Root)
	local bg = new("Frame", { BackgroundColor3 = Color3.fromRGB(18, 18, 30), Size = UDim2.fromScale(1, 1) }, bb)
	round(bg, 4)
	outline(bg, 1, 0.4, Color3.new(0, 0, 0))
	local fill = new("Frame", { BackgroundColor3 = STYLE.red, Size = UDim2.fromScale(1, 1) }, bg)
	round(fill, 4)
	model:ScaleTo(0.1)
	-- faint cold outline so dark enemies keep their silhouette on the dusk street (Darktide's distance rim idea);
	-- Roblox draws at most 31 highlights at once, so in huge waves some enemies lose the outline
	local hl = new("Highlight", { Adornee = model, FillColor = Color3.new(1, 1, 1), FillTransparency = 1, OutlineColor = Color3.fromRGB(205, 220, 255), OutlineTransparency = 0.55, DepthMode = Enum.HighlightDepthMode.Occluded }, model)
	enemies[data.id] = { model = model, fill = fill, spawnTime = data.spawnTime, speed = def.speed, hp = data.maxHp, maxHp = data.maxHp, kind = data.kind, popT = 0, flash = 0, hl = hl, big = isBoss }
end

local function killEnemy(data)
	local e = enemies[data.id]
	if not e then
		return
	end
	enemies[data.id] = nil
	local at = e.model:GetPivot().Position + Vector3.new(0, 2, 0)
	burst(at, Config.ENEMIES[e.kind].color, e.kind == "Boss" and 40 or 10, nil, e.kind == "Boss")
	if FXK.td and (FXK.coinsLive or 0) < 6 then -- coin drop, at most 6 at once
		FXK.coinsLive = (FXK.coinsLive or 0) + 1
		local sheet = FXK.sheetReady("coin")
		if sheet then
			FXK.pfx.play(sheet, CFrame.new(at))
		else
			FXK.td.coinDrop(at - Vector3.new(0, 2, 0))
		end
		task.delay(1.1, function() FXK.coinsLive -= 1 end)
	end
	floatText(at, "+" .. data.coins, STYLE.gold, 20)
	floatText(at + Vector3.new(2.5, 0, 0), "+" .. data.gems, STYLE.gem, 20)
	if (data.sp or 0) > 0 then
		floatText(at + Vector3.new(0, 3, 0), "+1 SKILL POINT", STYLE.purple, 26)
	end
	local bar = e.model.Root:FindFirstChildOfClass("BillboardGui")
	if bar then
		bar:Destroy()
	end
	table.insert(dying, { model = e.model, pivot = e.model:GetPivot(), t = 0, spin = e.kind == "Boss" and 4 or 9 })
	if e.kind == "Boss" then
		screenFlash(Color3.fromRGB(255, 240, 200), 0.6)
		shake.t, shake.amp = 0.5, 2
		if FXK.impact then
			FXK.impact.impactFrame(SETTINGS)
			FXK.impact.scorch(Vector3.new(at.X, GROUND - 0.4, at.Z), 7, 3)
		end
	end
end

local function shotFx(data)
	local e = enemies[data.id]
	local entry = petParts[data.slot]
	if not e or not entry then
		return
	end
	e.hp -= data.dmg
	e.flash = 1
	if entry.model:GetAttribute("MeshPet") then
		entry.atk = entry.atk or Models.playClip(entry.model, "Attack")
		if entry.atk and not entry.atk.IsPlaying then
			entry.atk:Play(0.08)
		end
	end
	e.fill.Size = UDim2.fromScale(math.clamp(e.hp / e.maxHp, 0, 1), 1)
	if liveFx > 30 then
		return
	end
	liveFx += 1
	local color = data.crit and STYLE.gold or Config.PETS[entry.pet].color
	local from = groundOf(data.slot) + Vector3.new(0, 3, 0)
	local to = e.model:GetPivot().Position + Vector3.new(0, 1.5, 0)
	-- smear: the bolt leaves stretched along its path and arrives compact (one-frame-style smear, no extra parts)
	local w = (0.6 + entry.tier * 0.25) * (data.crit and 1.6 or 1)
	local len = (to - from).Magnitude
	local dir = len > 0.01 and (to - from).Unit or Vector3.new(0, 0, -1)
	-- each familiar's own projectile (its Characters folder sets Shot); the default is the smeared bolt
	local shotDur = 0.14
	if FXK.proj then
		shotDur = FXK.proj.fire(Config.PETS[entry.pet].shot, from, to, color, w, visuals, data.crit) or 0.14
	else
		local bolt = new("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, Material = Enum.Material.Neon,
			Color = color, Size = Vector3.new(w * 0.6, w * 0.6, math.max(w, len * 0.35)), CFrame = CFrame.lookAt(from + dir * len * 0.175, to),
		}, visuals)
		tween(bolt, 0.12, { CFrame = CFrame.lookAt(to, to + dir), Size = Vector3.one * w * 0.7 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Debris:AddItem(bolt, 0.14)
	end
	-- big pets' crits trigger Verdant Rend down the lane (cosmetic; damage is the server's). At most once per 6 s.
	if data.crit and entry.tier >= 3 and FXK.ability and os.clock() - FXK.lastRend > 6 then
		FXK.lastRend = os.clock()
		FXK.ability.rend(groundOf(data.slot), dir, { length = math.clamp(len, 8, 40), color = color, settings = { reducedMotion = SETTINGS.reducedMotion, flashes = SETTINGS.flashes, particles = FXK.quality == "low" and "Low" or (FXK.quality == "high" and "High" or "Default") } })
	end
	-- hit reaction per projectile style when the shot lands (T09): tint, push, wobble or jitter, plus a small accent
	if FXK.proj and FXK.proj.REACT then
		local style = Config.PETS[entry.pet].shot or "bolt"
		task.delay(shotDur, function()
			local en = enemies[data.id]
			if not en then
				return
			end
			local r = FXK.proj.react(style, en.model:GetPivot().Position + Vector3.new(0, 1.5, 0), visuals, data.crit)
			en.hlColor = en.hlColor or en.hl.FillColor
			en.hl.FillColor = r.tint
			en.react = { t = 0, dur = r.dur, jolt = r.jolt, wobble = r.wobble, tilt = r.tilt, jitter = r.jitter, hold = r.hold }
			en.model:SetAttribute("LastReact", style)
		end)
	end
	task.delay(shotDur, function() liveFx -= 1 end)
	if data.crit then
		floatText(to, fmt(data.dmg) .. "!", STYLE.gold, 26)
	elseif data.dmg >= 25 then
		floatText(to, fmt(data.dmg), color, 18)
	end
	entry.kick = 1
end

-- ===== Camera: close, Bloons-style three-quarter view, with shake for big moments =====
RunService:BindToRenderStep("GuardianCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 60
	local vp = camera.ViewportSize
	local aspect = math.max(vp.X / math.max(vp.Y, 1), 0.3)
	local need = 96 / (2 * math.tan(math.rad(30)) * aspect)
	local dist = math.clamp(need, 60, 230) * camZoom
	local dir = Vector3.new(0, 0.82, 0.57).Unit
	local target = Vector3.new(0, 0, 5)
	local cf = CFrame.lookAt(target + dir * dist, target)
	if shake.t > 0 and (SETTINGS.reducedMotion or not SETTINGS.shake) then
		shake.t = 0
	end
	if shake.t > 0 then
		shake.t -= dt
		local a = shake.amp * math.max(shake.t, 0)
		-- smooth noise shake (eases in and out) instead of per-frame random jitter
		local off = FXK.impact and FXK.impact.shakeOffset(os.clock(), math.sqrt(a)) or Vector3.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0)
		cf = cf * CFrame.new(off)
	end
	FXK.gameCF = cf
	-- a signature cutscene drives the camera while it plays
	camera.CFrame = FXK.camOverride or cf
end)

-- ===== Input helpers =====
local function toScreen(position)
	local inset = GuiService:GetGuiInset()
	return Vector2.new(position.X + inset.X, position.Y + inset.Y)
end

local function groundPoint(screen)
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	if math.abs(ray.Direction.Y) < 1e-4 then
		return nil
	end
	local t = (GROUND - ray.Origin.Y) / ray.Direction.Y
	return ray.Origin + ray.Direction * t
end

-- The pet under a ground point: within its footprint plus `extra` studs.
local function nearestSlot(hit, extra)
	local best, bestDist = nil, math.huge
	for id, e in petParts do
		local s = slotPos(id)
		local d = Vector2.new(hit.X - s.X, hit.Z - s.Z).Magnitude
		if d < Config.footprint(e.pet) + extra and d < bestDist then
			best, bestDist = id, d
		end
	end
	return best
end

-- Range circle on the ground (Bloons-style): soft fill with a crisp edge. One shared ring.
function UI.showRange(pos, radius, color)
	local r = FXK.rangeRing
	if not r then
		r = new("Part", { Name = "RangeRing", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(2, 0.05, 2) }, visuals)
		if UI.fa then
			local sg = new("SurfaceGui", { Face = Enum.NormalId.Top, LightInfluence = 0, AlwaysOnTop = false, PixelsPerStud = 8, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud }, r)
			new("ImageLabel", { Name = "Img", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ImageContent = UI.fa.ring() }, sg)
		else
			r.Shape = Enum.PartType.Cylinder
			r.Material = Enum.Material.Neon
		end
		FXK.rangeRing = r
	end
	if UI.fa then
		r.Size = Vector3.new(radius * 2, 0.05, radius * 2)
		r.CFrame = CFrame.new(pos.X, 0.95, pos.Z)
		r.SurfaceGui.Img.ImageColor3 = color
	else
		r.Size = Vector3.new(0.05, radius * 2, radius * 2)
		r.CFrame = CFrame.new(pos.X, 0.95, pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
		r.Color = color
		r.Transparency = 0.8
	end
	r.Parent = visuals
end

function UI.hideRange()
	if FXK.rangeRing then
		FXK.rangeRing.Parent = nil
	end
end

-- Units with positions, for the shared placement check (Config.canPlace) on the client.
function UI.unitTable()
	local t = {}
	for id, e in petParts do
		local p = slotPos(id)
		t[id] = { pet = e.pet, tier = e.tier, x = p.X, z = p.Z }
	end
	return t
end

-- ===== Pet panel (upgrades + delete) =====
local selectedSlot = nil
local deleteArmed = 0

local function closePanel()
	hidePanel(upPanel, upScale)
	UI.hideRange()
	selectedSlot = nil
	deleteArmed = 0
end

local function refreshPanel()
	if not selectedSlot then
		return
	end
	local entry = petParts[selectedSlot]
	if not entry or not lastSnap then
		closePanel()
		return
	end
	local def = Config.PETS[entry.pet]
	upTitle.Text = def.name
	upTitle.TextColor3 = rarityColor(entry.pet)
	upInfo.Text = string.format("%s  -  Tier %d  -  upgrades apply to every %s", def.rarity, entry.tier, def.name)
	for kind, r in upRows do
		local level = lastSnap.upgrades[entry.pet][kind]
		for p, pip in r.pips do
			pip.BackgroundColor3 = p <= level and STYLE.gold or STYLE.grey
		end
		if level >= Config.UPGRADE_MAX then
			r.buy.Text = "MAX"
			setButtonColor(r.buy, STYLE.grey)
		else
			local cost = Config.upgradeCost(level)
			r.buy.Text = fmt(cost)
			setButtonColor(r.buy, lastSnap.coins >= cost and STYLE.green or STYLE.grey)
		end
	end
	if os.clock() - deleteArmed > 3 then
		deleteBtn.Text = "Delete  (+" .. Config.recycleValue(entry.pet, entry.tier) .. " coins)"
		setButtonColor(deleteBtn, STYLE.red)
	end
end

local function openPanel(slot)
	selectedSlot = slot
	deleteArmed = 0
	local e = petParts[slot]
	if e then
		UI.showRange(slotPos(slot), Config.PETS[e.pet].range, Color3.fromRGB(235, 240, 255))
	end
	local wasOpen = upPanel.Visible
	upPanel.Visible = true
	if not wasOpen then
		popIn(upScale, 0.85)
	end
	refreshPanel()
end

for kind, r in upRows do
	r.buy.Activated:Connect(function()
		local entry = selectedSlot and petParts[selectedSlot]
		if entry then
			ActionRemote:FireServer("Upgrade", entry.pet, kind)
		end
	end)
end
upClose.Activated:Connect(closePanel)

deleteBtn.Activated:Connect(function()
	local slot = selectedSlot
	local entry = slot and petParts[slot]
	if not entry then
		return
	end
	local valuable = Config.RARITIES[Config.PETS[entry.pet].rarity].order >= 3 or entry.tier >= 3
	if valuable and os.clock() - deleteArmed > 3 then
		deleteArmed = os.clock()
		deleteBtn.Text = "Sure? Tap again"
		setButtonColor(deleteBtn, STYLE.orange)
		return
	end
	ActionRemote:FireServer("Recycle", slot)
	closePanel()
end)

local function updateOdds()
	local luck = lastSnap and lastSnap.luck or 0
	local pct = Config.rarityPercents(luck)
	for r, l in oddsRows do
		l.Text = string.format("%s   %.1f%%", r:upper(), pct[r])
	end
	oddsNote.Text = string.format("Luck bonus +%d%% from trainer level. Epic or better is guaranteed within %d rolls.", math.floor(luck * 100 + 0.5), Config.PITY_EVERY)
end

oddsChip.Activated:Connect(function()
	if oddsPanel.Visible then
		hidePanel(oddsPanel, oddsScale)
	else
		-- sit below the tutorial scroll when it is showing (its rods used to overlap the panel's top rod)
		oddsPanel.Position = UDim2.new(0.5, 0, 0.5, tutCard.Visible and 48 or 0)
		oddsPanel.Visible = true
		updateOdds()
		popIn(oddsScale, 0.85)
	end
end)
oddsClose.Activated:Connect(function() hidePanel(oddsPanel, oddsScale) end)

local function updateProgress()
	if not lastSnap then
		return
	end
	local s = lastSnap
	progHead.Text = string.format("LEVEL %d   (Luck +%d%%)", s.level, math.floor(s.luck * 100 + 0.5))
	progXp.Size = UDim2.fromScale(math.clamp(s.xp / s.xpNeed, 0, 1), 1)
	local lines = { string.format("%d / %d XP to level %d", s.xp, s.xpNeed, math.min(s.level + 1, Config.LEVEL_MAX)), "" }
	for lv = s.level + 1, math.min(s.level + 6, Config.LEVEL_MAX) do
		table.insert(lines, string.format("Level %d:  +%d gems,  Luck +%d%%", lv, Config.levelGems(lv), math.floor(Config.luck(lv) * 100 + 0.5)))
	end
	table.insert(lines, "")
	table.insert(lines, "XP comes from defeating monsters and clearing stages.")
	table.insert(lines, "Level 3 unlocks auto-rolling when AUTO is on.")
	progList.Text = table.concat(lines, "\n")
end

progressBtn.Activated:Connect(function()
	if progPanel.Visible then
		hidePanel(progPanel, progScale)
	else
		progPanel.Position = UDim2.new(0.5, 0, 0.5, tutCard.Visible and 48 or 0)
		updateProgress()
		UI.intro(gui, STYLE.purple, function()
			progPanel.Visible = true
			popIn(progScale, 0.85)
		end, SETTINGS.reducedMotion)
	end
end)
progClose.Activated:Connect(function() hidePanel(progPanel, progScale) end)

do -- settings panel: shell here, content in the SettingsPanel module
	local settingsBtn = railButton("Settings", 6, STYLE.grey)
	UI.SYMS["Settings"] = "star"
	UI.SUBS["Settings"] = "SOUND  ·  DISPLAY  ·  ACCESS"
	local panel, body, scale, close = makePanel(hud, UDim2.fromOffset(420, 540), "Settings", STYLE.blue)
	UI.blurHolders[panel] = true
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.ZIndex = 9
	local Defaults = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SettingsDefaults"))
	FXK.settingsPanel = require(script.Parent:WaitForChild("SettingsPanel"))({
		new = new, STYLE = STYLE, UI = UI, body = body, tween = tween, defaults = Defaults.defaults,
		apply = function(s) FXK.applySettings(s) end,
		send = function(batch) ActionRemote:FireServer("Setting", batch) end,
	})
	settingsBtn.Activated:Connect(function()
		if panel.Visible then
			hidePanel(panel, scale)
		else
			UI.intro(gui, STYLE.blue, function()
				panel.Visible = true
				popIn(scale, 0.85)
			end, SETTINGS.reducedMotion)
		end
	end)
	close.Activated:Connect(function() hidePanel(panel, scale) end)
end

do -- skill tree scope
local lastSp = 0
-- ===== Skill tree: honeycomb of permanent upgrades =====
local SQ3 = math.sqrt(3)
local HEX_R = 48
local HEX_GAP = 1.07
local blur = new("BlurEffect", { Size = 0 }, game:GetService("Lighting"))

treeGui = new("Frame", { Name = "Tree", BackgroundColor3 = Color3.fromRGB(6, 8, 22), BackgroundTransparency = 0.04, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 12, Active = true }, hud)
local treeTitle = label(treeGui, "SKILL TREE", 38, STYLE.gold, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 14), UDim2.fromOffset(500, 48))
treeTitle.ZIndex = 14
local treeSp = label(treeGui, "", 22, STYLE.purple, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 62), UDim2.fromOffset(500, 30))
treeSp.ZIndex = 14
treeArea = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -24), Size = UDim2.fromOffset(560, 430), ZIndex = 13 }, treeGui)
local treeScale = new("UIScale", { Scale = 1 }, treeGui)

local detail = new("Frame", { BackgroundColor3 = STYLE.panelDark, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -68), Size = UDim2.fromOffset(540, 92), ZIndex = 14 }, treeGui)
round(detail, 16)
local detailStroke = outline(detail, 3, 0.3, STYLE.gold)
local detName = label(detail, "", 22, STYLE.text, Vector2.new(0, 0), UDim2.fromOffset(14, 6), UDim2.new(1, -190, 0, 28))
detName.TextXAlignment = Enum.TextXAlignment.Left
detName.ZIndex = 15
local detDesc = label(detail, "", 14, STYLE.muted, Vector2.new(0, 0), UDim2.fromOffset(14, 36), UDim2.new(1, -190, 0, 20), STYLE.fontB)
detDesc.TextXAlignment = Enum.TextXAlignment.Left
detDesc.ZIndex = 15
local detLevel = label(detail, "", 14, STYLE.gold, Vector2.new(0, 0), UDim2.fromOffset(14, 58), UDim2.new(1, -190, 0, 24), STYLE.fontB)
detLevel.TextXAlignment = Enum.TextXAlignment.Left
detLevel.ZIndex = 15
local buyBtn = makeButton(detail, "BUY", UDim2.fromOffset(160, 64), UDim2.new(1, -12, 0.5, 0), STYLE.green, Vector2.new(1, 0.5))
buyBtn.TextSize = 22
buyBtn.ZIndex = 15
local treeClose = makeButton(treeGui, "Close", UDim2.fromOffset(220, 48), UDim2.new(0.5, 0, 1, -12), STYLE.red, Vector2.new(0.5, 1))
treeClose.ZIndex = 15
if UI.fa then
	-- glass detail card; let the blurred world show through the backdrop; serif title with a divider
	UI.glass(detail, STYLE.gold, 30, 20)
	-- the HUD is UI, so blur cannot hide it: keep the backdrop nearly opaque, with a violet tint
	treeGui.BackgroundTransparency = 0.03
	treeGui.BackgroundColor3 = Color3.new(1, 1, 1)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(40, 30, 70), Color3.fromRGB(8, 8, 20)) }, treeGui)
	treeTitle.Font = Enum.Font.Legacy
	treeTitle.FontFace = UI.TITLE_FONT
	treeTitle.TextSize = 34
	UI.divider(treeGui, STYLE.gold, UDim2.new(0.5, 0, 0, 62), UDim2.fromOffset(420, 12), 14)
	treeSp.Position = UDim2.new(0.5, 0, 0, 70)
end

local function hexLayers(parent, radius, color, z, transparency)
	local holder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(radius * 2, radius * 2), ZIndex = z }, parent)
	if UI.fa and z >= 14 and z <= 17 then
		-- painted hexagon (z 14 selection glow, 15 rim, 16 body, 17 sheen) instead of three overlapping bars
		local kind = z == 16 and "body" or (z == 17 and "shine" or "rim")
		new("ImageLabel", { BackgroundTransparency = 1, ImageContent = UI.fa.hex(kind), ImageColor3 = color, ImageTransparency = kind == "shine" and 0.55 or (transparency or 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(UI.fa.HEX_FIT, UI.fa.HEX_FIT), ZIndex = z }, holder)
		return holder
	end
	for i = 0, 2 do
		new("Frame", { BackgroundColor3 = color, BackgroundTransparency = transparency or 0, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(radius * SQ3, radius), Rotation = i * 60, ZIndex = z }, holder)
	end
	return holder
end

local function tintHex(holder, color)
	for _, f in holder:GetChildren() do
		if f:IsA("ImageLabel") then
			f.ImageColor3 = color
		else
			f.BackgroundColor3 = color
		end
	end
end

nodeUI = {}
local selectedNode = "Claws"

for _, node in Config.TREE do
	local x = HEX_R * SQ3 * HEX_GAP * (node.q + node.r / 2)
	local y = HEX_R * 1.5 * HEX_GAP * node.r
	local cont = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, x, 0.5, y), Size = UDim2.fromOffset(HEX_R * 2, HEX_R * 2), ZIndex = 14 }, treeArea)
	local scale = new("UIScale", { Scale = 1 }, cont)
	local sel = hexLayers(cont, HEX_R + 6, STYLE.gold, 14)
	sel.Visible = false
	local rim = hexLayers(cont, HEX_R, Color3.fromRGB(14, 16, 30), 15)
	local body = hexLayers(cont, HEX_R - 4, Color3.fromRGB(60, 64, 90), 16)
	local shine = hexLayers(cont, HEX_R - 13, Color3.new(1, 1, 1), 17, 0.86)
	local icon = new("Frame", { BackgroundColor3 = node.color, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(38, 38), ZIndex = 18 }, cont)
	round(icon, 19)
	outline(icon, 2, 0.3, Color3.new(0, 0, 0))
	local code = label(icon, node.short, #node.short > 3 and 11 or 15, STYLE.text)
	code.ZIndex = 19
	local plate = new("Frame", { BackgroundColor3 = Color3.fromRGB(10, 12, 26), BackgroundTransparency = 0.1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.fromOffset(HEX_R * 1.55, 17), ZIndex = 18 }, cont)
	round(plate, 8)
	local nameLabel = label(plate, node.name, 12, STYLE.text)
	nameLabel.TextScaled = true
	new("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 8 }, nameLabel)
	nameLabel.ZIndex = 19
	local badge = new("Frame", { BackgroundColor3 = STYLE.gold, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.86, 0.2), Size = UDim2.fromOffset(26, 26), ZIndex = 20 }, cont)
	round(badge, 13)
	outline(badge, 2, 0.2, Color3.new(0, 0, 0))
	local badgeLabel = label(badge, "", 14)
	badgeLabel.ZIndex = 21
	local q = label(cont, "?", 44, Color3.fromRGB(160, 166, 190), Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(60, 60))
	q.ZIndex = 18
	local btn = new("TextButton", { BackgroundTransparency = 1, Text = "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(HEX_R * 1.6, HEX_R * 1.7), ZIndex = 22 }, cont)
	nodeUI[node.id] = { cont = cont, scale = scale, sel = sel, rim = rim, body = body, shine = shine, icon = icon, plate = plate, badge = badge, badgeLabel = badgeLabel, q = q, x = x, y = y }
	btn.Activated:Connect(function()
		selectedNode = node.id
		if refreshTree then refreshTree() end
	end)
end

local function nodeState(id, snap)
	if id == "Start" then
		return "start"
	end
	local node = Config.TREE_BY_ID[id]
	local lvl = snap.tree[id] or 0
	if lvl >= node.max then
		return "maxed"
	end
	if lvl > 0 then
		return "owned"
	end
	for _, n in Config.TREE_NEIGHBORS[id] do
		if (snap.tree[n] or 0) > 0 then
			return "available"
		end
	end
	return "locked"
end

local UNITS = { crystal = " HP", ultNeed = " kills", bossTime = "s", rollDiscount = " gems", streakGuard = " leak", ultRefund = " charge", pity = " rolls" }
local function fmtEffect(node, v)
	if node.kind == "none" then
		return ""
	end
	if node.per < 1 and not UNITS[node.kind] then
		return string.format("%+d%%", math.floor(v * 100 + 0.5))
	end
	return (node.kind == "merge" and "x" or "+") .. v .. (UNITS[node.kind] or "")
end

function refreshSkillBadge()
	if not lastSnap then
		return
	end
	spBadge.Visible = lastSnap.sp > 0
	spBadgeLabel.Text = tostring(lastSnap.sp)
	if lastSnap.sp > lastSp then
		spBadge.Size = UDim2.fromOffset(38, 38)
		tween(spBadge, 0.4, { Size = UDim2.fromOffset(24, 24) }, Enum.EasingStyle.Bounce)
	end
	lastSp = lastSnap.sp
end

local treeInit = false
function refreshTree()
	local snap = lastSnap
	if not snap then
		return
	end
	treeSp.Text = string.format("Skill Points: %d     (level-ups, bosses and the tutorial give points)", snap.sp)
	for id, ui in nodeUI do
		local node = Config.TREE_BY_ID[id]
		local state = nodeState(id, snap)
		local lvl = snap.tree[id] or 0
		ui.sel.Visible = id == selectedNode
		local teaser = false
		if state == "locked" then
			for _, n in Config.TREE_NEIGHBORS[id] do
				local ns = nodeState(n, snap)
				if ns == "available" or ns == "owned" or ns == "maxed" then
					teaser = true
					break
				end
			end
		end
		ui.q.Visible = teaser
		local wasShown = ui.cont.Visible
		ui.cont.Visible = state ~= "locked" or teaser
		if ui.cont.Visible and not wasShown and treeInit then
			ui.scale.Scale = 0.1
			tween(ui.scale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
		end
		ui.icon.Visible = state ~= "locked"
		ui.plate.Visible = state ~= "locked"
		ui.badge.Visible = state == "owned" or state == "maxed" or state == "available"
		if state == "locked" then
			tintHex(ui.body, Color3.fromRGB(52, 56, 74))
			tintHex(ui.rim, Color3.fromRGB(20, 22, 36))
		elseif state == "available" then
			tintHex(ui.body, Color3.fromRGB(58, 64, 100))
			tintHex(ui.rim, node.color)
			local cost = Config.skillCost(node, lvl)
			ui.badge.BackgroundColor3 = snap.sp >= cost and STYLE.gold or STYLE.red
			ui.badgeLabel.Text = tostring(cost)
		elseif state == "owned" then
			tintHex(ui.body, shade(node.color, -0.35))
			tintHex(ui.rim, shade(node.color, 0.2))
			ui.badge.BackgroundColor3 = Color3.new(1, 1, 1)
			ui.badgeLabel.Text = tostring(lvl)
			ui.badgeLabel.TextColor3 = Color3.fromRGB(20, 20, 30)
		elseif state == "maxed" then
			tintHex(ui.body, Color3.fromRGB(190, 140, 30))
			tintHex(ui.rim, STYLE.gold)
			ui.badge.BackgroundColor3 = STYLE.gold
			ui.badgeLabel.Text = "MAX"
			ui.badgeLabel.TextColor3 = Color3.fromRGB(20, 20, 30)
		else -- start
			tintHex(ui.body, Color3.fromRGB(40, 150, 190))
			tintHex(ui.rim, STYLE.gem)
		end
		if state == "available" then
			ui.badgeLabel.TextColor3 = Color3.fromRGB(20, 20, 30)
		end
	end
	local node = Config.TREE_BY_ID[selectedNode]
	local state = nodeState(selectedNode, snap)
	local lvl = snap.tree[selectedNode] or 0
	detailStroke.Color = state == "locked" and STYLE.grey or node.color
	if state == "locked" then
		detName.Text = "???"
		detDesc.Text = "Buy a neighbouring skill to reveal this one."
		detLevel.Text = ""
		buyBtn.Text = "LOCKED"
		setButtonColor(buyBtn, STYLE.grey)
	elseif state == "start" then
		detName.Text = node.name
		detDesc.Text = node.desc
		detLevel.Text = "Every path begins here."
		buyBtn.Text = "OWNED"
		setButtonColor(buyBtn, STYLE.grey)
	else
		detName.Text = node.name
		detDesc.Text = node.desc
		detLevel.Text = string.format("Level %d / %d     Now: %s", lvl, node.max, lvl > 0 and fmtEffect(node, node.per * lvl) or "none")
		if state == "maxed" then
			buyBtn.Text = "MAXED"
			setButtonColor(buyBtn, STYLE.gold)
		else
			local cost = Config.skillCost(node, lvl)
			buyBtn.Text = "BUY  " .. cost .. " SP"
			setButtonColor(buyBtn, snap.sp >= cost and STYLE.green or STYLE.grey)
		end
	end
end

buyBtn.Activated:Connect(function()
	ActionRemote:FireServer("Skill", selectedNode)
end)

function uiSparks(parent, pos, color, count, far)
	for i = 1, count do
		local size = math.random(5, 12)
		local spark = new("Frame", { BackgroundColor3 = color, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(size, size), Rotation = math.random(0, 90), ZIndex = 30 }, parent)
		round(spark, 2)
		local a = math.random() * math.pi * 2
		local d = far * (0.4 + math.random() * 0.6)
		tween(spark, 0.6, { Position = UDim2.new(pos.X.Scale, pos.X.Offset + math.cos(a) * d, pos.Y.Scale, pos.Y.Offset + math.sin(a) * d), BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 2) })
		Debris:AddItem(spark, 0.7)
	end
end

local function setTreeOpen(open)
	if open == treeGui.Visible then
		return
	end
	tween(blur, 0.25, { Size = open and 14 or 0 })
	if not open then
		hidePanel(treeGui, treeScale)
		return
	end
	treeGui.Visible = true
	if open then
		for _, id in { "Claws", "Magnet", "Armor", "Charge", "Charm", "Finder" } do
			if nodeState(id, lastSnap) == "available" and lastSnap.sp >= Config.skillCost(Config.TREE_BY_ID[id], 0) then
				selectedNode = id
				break
			end
		end
		treeGui.Visible = false
		UI.intro(gui, STYLE.blue, function()
			treeGui.Visible = true
			popIn(treeScale, 0.9)
		end, SETTINGS.reducedMotion)
		refreshTree()
		treeInit = true
	end
end

skillsBtn.Activated:Connect(function()
	if lastSnap then
		setTreeOpen(not treeGui.Visible)
	end
end)
treeClose.Activated:Connect(function() setTreeOpen(false) end)

end

-- ===== Full-screen hatch: the code lives in the RevealSection module (T14) =====
local quickRoll = false
local autoOn = false
local Hatch = require(script.Parent.RevealSection)({
	new = new, label = label, round = round, tween = tween, fadeLabel = fadeLabel, setLabelVisible = setLabelVisible,
	STYLE = STYLE, UI = UI, FXK = FXK, Config = Config, Models = Models, burst = burst, ring = ring, pillar = pillar,
	groundOf = groundOf, screenFlash = screenFlash, flushBanners = flushBanners, shake = shake, pending = pending,
	setPet = setPet, camera = camera, gui = gui,
	petModel = function(slot) local e = petParts[slot] return e and e.model end,
	snap = function() return lastSnap end,
	quick = function() return quickRoll end,
	auto = function() return autoOn end,
})
local revealGui, revealQueue, playRoll = Hatch.gui, Hatch.queue, Hatch.playRoll

local function ease(a, style, dir)
	return TweenService:GetValue(a, style, dir)
end

-- ===== Ultimate: a short cinematic. Gather power, orb, release, meteor storm. =====
local ultHoldUntil = 0
local playUlt = require(script.Parent.UltFX)({
	new = new, tween = tween, visuals = visuals, dim = dim, shake = shake, petParts = petParts, enemies = enemies,
	groundOf = groundOf, GROUND = GROUND, screenFlash = screenFlash, showBanner = showBanner, ring = ring, pillar = pillar,
	burst = burst, FXK = FXK, SETTINGS = SETTINGS, STYLE = STYLE, Config = Config, Path = Path,
	hold = function(t) ultHoldUntil = t end,
	setZoom = function(v) camZoom = v end,
	snapStage = function() return lastSnap and lastSnap.stage or 1 end,
})

local function setUltReady(ready)
	for _, t in ultTweens do
		t:Cancel()
	end
	table.clear(ultTweens)
	if ready then
		ultGlow.Transparency = 0.1
		if not SETTINGS.reducedMotion then
			local info = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			table.insert(ultTweens, TweenService:Create(ultGlow, info, { Transparency = 0.75 }))
			table.insert(ultTweens, TweenService:Create(ultPulse, info, { Scale = 1.1 }))
			for _, t in ultTweens do
				t:Play()
			end
		end
	else
		ultGlow.Transparency = 1
		ultPulse.Scale = 1
	end
end

-- ===== Tutorial =====
local highlights = {}
local function clearHighlights()
	for _, h in highlights do
		for _, o in h do
			if o.Parent then o:Destroy() end
		end
	end
	table.clear(highlights)
end

-- tutorial pointer: the chevron sprite turned to point down (a text arrow if the UI Kit art is missing)
function UI.pointer(parent, size, anchor, pos)
	local img = UI.artIcon(parent, "icon_chevron", UDim2.fromOffset(size, size), pos)
	if img then
		img.Rotation = 90
		img.AnchorPoint = anchor
		img.ZIndex = 30
		return img
	end
	local t = label(parent, "v", size, STYLE.gold, anchor, pos, UDim2.fromOffset(size, size))
	t.ZIndex = 30
	return t
end

local function highlightWorld(target, height)
	local h = new("Highlight", { Adornee = target, FillColor = STYLE.gold, FillTransparency = 0.55, OutlineColor = Color3.new(1, 1, 1), DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, target)
	local anchorPart = target:IsA("Model") and target.Root or target
	local bb = new("BillboardGui", { Size = UDim2.fromOffset(60, 40), StudsOffset = Vector3.new(0, height or 7, 0), AlwaysOnTop = true, Adornee = anchorPart }, anchorPart)
	UI.pointer(bb, 44, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5))
	if not SETTINGS.reducedMotion then
		TweenService:Create(h, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { FillTransparency = 0.15 }):Play()
		TweenService:Create(bb, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { StudsOffset = Vector3.new(0, (height or 7) + 1.5, 0) }):Play()
	end
	table.insert(highlights, { h, bb })
end

local function highlightGui(obj)
	local stroke
	if UI.fa then
		-- pulsing gold glow behind the target instead of a square outline
		stroke = new("ImageLabel", { Name = "HighlightGlow", BackgroundTransparency = 1, ImageContent = UI.fa.glow(), ImageColor3 = STYLE.gold, ImageTransparency = 0.25, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1.5, 0, 2.4, 0), ZIndex = 0, Active = false }, obj)
		if not SETTINGS.reducedMotion then
			TweenService:Create(stroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { ImageTransparency = 0.7 }):Play()
		end
		local arrow = UI.pointer(obj, 40, Vector2.new(0.5, 1), UDim2.new(0.5, 0, 0, -2))
		if not SETTINGS.reducedMotion then
			TweenService:Create(arrow, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.new(0.5, 0, 0, -10) }):Play()
		end
		table.insert(highlights, { stroke, arrow })
		return
	end
	stroke = new("UIStroke", { Color = STYLE.gold, Thickness = 5, Transparency = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, obj)
	local arrow = UI.pointer(obj, 40, Vector2.new(0.5, 1), UDim2.new(0.5, 0, 0, -2))
	if not SETTINGS.reducedMotion then
		TweenService:Create(stroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.7 }):Play()
		TweenService:Create(arrow, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.new(0.5, 0, 0, -10) }):Play()
	end
	table.insert(highlights, { stroke, arrow })
end

local tut = { step = 0, active = false, hlKey = nil }

local function setTutStep(step)
	popIn(tutScale, 0.92)
	tut.step = step
	tut.hlKey = nil
	clearHighlights()
	if step == 1 then
		tutText.Text = "Welcome! Tap ROLL to draw a summoning card. Each card calls a familiar and costs gems."
		highlightGui(rollBtn)
	elseif step == 2 then
		tutText.Text = "Two matching pets that TOUCH, plus a third: drag the third onto one of the pair to merge all three into a stronger pet!"
		for _, e in petParts do
			highlightWorld(e.model, 6)
		end
	elseif step == 3 then
		tutText.Text = "Tap your new pet to open its panel, then buy POWER with coins."
	elseif step == 4 then
		tutText.Text = "Pets go anywhere on the street. Drag yours to a new spot: the circle shows its range, red means it can't stand there."
	elseif step == 5 then
		tutText.Text = "Press START WAVE! Monsters drop coins (upgrades) and gems (rolls)."
		highlightGui(startWaveBtn)
	elseif step == 6 then
		tut.active = false
		tutCard.Visible = false
		clearHighlights()
		ActionRemote:FireServer("EndTutorial")
	end
end

local function updateTutorial(s)
	if not tut.active then
		return
	end
	if tut.step == 1 and s.rolls >= 3 and #revealQueue == 0 and not Hatch.running() then
		setTutStep(2)
	elseif tut.step == 2 and s.maxTier >= 2 then
		setTutStep(3)
	elseif tut.step == 3 then
		if s.upgradeCount >= 1 then
			setTutStep(4)
		else
			local key = upPanel.Visible and "panel" or "pet"
			if tut.hlKey ~= key then
				tut.hlKey = key
				clearHighlights()
				if key == "panel" then
					highlightGui(upRows.Power.buy)
				else
					for _, e in petParts do
						if e.tier >= 2 then
							highlightWorld(e.model, 6)
							break
						end
					end
				end
			end
		end
	elseif tut.step == 4 and s.moves >= 1 then
		setTutStep(5)
	elseif tut.step == 5 then
		if s.state == "active" and tut.hlKey ~= "running" then
			tut.hlKey = "running"
			clearHighlights()
			tutText.Text = "Defend! Clear stage 1 to finish the tutorial."
		end
		if s.stage >= 2 then
			setTutStep(6)
		end
	end
end

tutSkip.Activated:Connect(function()
	tut.active = false
	tutCard.Visible = false
	clearHighlights()
	ActionRemote:FireServer("SkipTutorial")
end)

-- ===== Frame loop =====
local crystalPart = map:FindFirstChild("Crystal")
local portalPart = map:FindFirstChild("Portal")
local crystalBase = crystalPart and crystalPart.Size
local crystalHome = crystalPart and crystalPart.Position
local portalBase = portalPart and portalPart.Size
local crystalHit = 0
local dragHls = {}
local function clearDragHl()
	for _, h in dragHls do
		h:Destroy()
	end
	table.clear(dragHls)
end

local drag = nil -- { from, start, active, snap, point }

RunService.RenderStepped:Connect(function(dt)
	local now = FXK.simNow()
	local clock = os.clock()
	for id, e in enemies do
		local d = math.max(now - e.spawnTime, 0) * e.speed
		local p = Path.positionAt(math.min(d, Path.length))
		local ahead = Path.positionAt(math.min(d + 1, Path.length))
		local dir = Vector3.new(ahead.X - p.X, 0, ahead.Z - p.Z)
		local pos = Vector3.new(p.X, 0.8 + math.abs(math.sin(clock * 7 + id)) * 0.35, p.Z)
		local roll = math.sin(clock * 7 + id) * 0.08
		local cf = dir.Magnitude > 0.01 and CFrame.lookAt(pos, pos + dir) or CFrame.new(pos)
		local r = e.react
		if r then
			r.t += dt
			local k = math.max(0, 1 - r.t / r.dur)
			if k <= 0 then
				e.react = nil
				if e.hlColor then
					e.hl.FillColor = e.hlColor
				end
			elseif not SETTINGS.reducedMotion then
				cf = cf * CFrame.new(0, 0, r.jolt * k * k) -- pushed back along the lane, easing out
				if r.jitter > 0 then
					cf = cf * CFrame.new((math.random() - 0.5) * r.jitter * k, 0, (math.random() - 0.5) * r.jitter * k)
				end
				roll += math.sin(r.t * 40) * r.wobble * k + r.tilt * k
			end
			if r and r.hold > 0 and r.t < r.hold then
				e.flash = math.max(e.flash, 0.5) -- frost and burn tints stay on a moment
			end
		end
		e.model:PivotTo(cf * CFrame.Angles(0, 0, roll))
		if e.popT < 1 then
			e.popT = math.min(1, e.popT + dt / (e.big and 0.6 or 0.28))
			e.model:ScaleTo(math.max(0.05, ease(e.popT, Enum.EasingStyle.Back, Enum.EasingDirection.Out)))
		end
		if e.flash > 0 then
			e.flash = math.max(0, e.flash - dt * 7)
			e.hl.FillTransparency = 1 - 0.8 * e.flash
		end
	end
	for i = #dying, 1, -1 do
		local d = dying[i]
		d.t += dt
		local k = d.t / 0.32
		if k >= 1 then
			d.model:Destroy()
			table.remove(dying, i)
		else
			d.model:ScaleTo(math.max(0.05, 1 - k * k))
			d.model:PivotTo(d.pivot * CFrame.new(0, k * 2.5, 0) * CFrame.Angles(0, k * d.spin, k * 1.2))
		end
	end
	for i = #flying, 1, -1 do
		local f = flying[i]
		f.t += dt
		local k = math.min(1, f.t / 0.24)
		local e2 = k * k
		local pos = f.from:Lerp(f.to, e2) + Vector3.new(0, math.sin(k * math.pi) * 3, 0)
		f.model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.pi + k * 6, 0))
		f.model:ScaleTo(math.max(0.1, 1 - 0.6 * e2))
		if k >= 1 then
			f.model:Destroy()
			table.remove(flying, i)
		end
	end
	if crystalPart then
		crystalHit = math.max(0, crystalHit - dt * 2.5)
		crystalPart.Size = crystalBase * (1 + 0.05 * math.sin(clock * 2.2) + crystalHit * 0.25)
		crystalPart.Color = Color3.fromRGB(90, 220, 255):Lerp(Color3.fromRGB(255, 70, 70), crystalHit)
		crystalPart.Position = crystalHome + Vector3.new((math.random() - 0.5) * crystalHit * 2, math.sin(clock * 1.7) * 0.3, (math.random() - 0.5) * crystalHit * 2)
	end
	if portalPart then
		portalPart.Size = portalBase * (1 + 0.06 * math.sin(clock * 3))
		portalPart.Transparency = 0.1 + 0.15 * (0.5 + 0.5 * math.sin(clock * 2.1))
	end
	for slot, entry in petParts do
		local base = groundOf(slot)
		local target = base
		local lift = 0
		if drag and drag.active and drag.from == slot then
			target = drag.snap and groundOf(drag.snap) or (drag.point and Vector3.new(drag.point.X, GROUND, drag.point.Z) or base)
			lift = 1.6
		end
		if entry.popT < 1 then
			entry.popT = math.min(1, entry.popT + dt / 0.35)
			entry.model:ScaleTo(math.max(0.05, ease(entry.popT, Enum.EasingStyle.Back, Enum.EasingDirection.Out)))
		end
		entry.kick = math.max(0, (entry.kick or 0) - dt * 8)
		local bob = math.sin(clock * 2.2 + slot) * 0.08 + entry.kick * 0.35
		local pos = Vector3.new(target.X, GROUND + bob + lift + (entry.model:GetAttribute("CutsceneLift") or 0), target.Z)
		local pivot = CFrame.new(pos) * CFrame.Angles(0, math.pi, 0)
		entry.model:PivotTo(pivot)
		for _, fn in entry.anims do
			fn(clock, pivot)
		end
	end
end)

-- ===== Input: tap = pet panel, drag = move / swap / merge (snaps to pad centres) =====
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not hud.Visible or revealGui.Visible then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local screen = toScreen(input.Position)
		local hit = groundPoint(screen)
		local slot = hit and nearestSlot(hit, 1.2)
		if slot and petParts[slot] then
			drag = { from = slot, start = screen, active = false }
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not drag then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local screen = toScreen(input.Position)
		if not drag.active and (screen - drag.start).Magnitude > 10 then
			drag.active = true
		end
		if drag.active then
			local hit = groundPoint(screen)
			drag.point = hit
			local a = petParts[drag.from]
			if not hit or not a then
				return
			end
			-- over another pet: merge target (only a matching pet with a touching third is valid)
			local over = nearestSlot(hit, 0.6)
			if over == drag.from then
				over = nil
			end
			local snap, mergeOk = nil, false
			if over and petParts[over] and not pending[over] then
				local b = petParts[over]
				if a.pet == b.pet and a.tier == b.tier then
					snap = over
					mergeOk = MatchSim.findThird(UI.unitTable(), drag.from, over) ~= nil
				end
			end
			if snap ~= drag.snap then
				clearDragHl()
				drag.snap = snap
				if snap and mergeOk then
					local third = MatchSim.findThird(UI.unitTable(), drag.from, snap)
					for _, slot in { third, snap } do
						if petParts[slot] then
							local h = new("Highlight", { Adornee = petParts[slot].model, FillColor = STYLE.green, FillTransparency = 0.5, OutlineColor = Color3.new(1, 1, 1), DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, petParts[slot].model)
							table.insert(dragHls, h)
						end
					end
				end
			end
			drag.mergeOk = mergeOk
			-- free spot: same rule the server uses
			drag.valid = snap == nil and Config.canPlace(UI.unitTable(), a.pet, hit.X, hit.Z, drag.from)
			local center = snap and slotPos(snap) or hit
			local color = snap and (mergeOk and STYLE.green or STYLE.red) or (drag.valid and Color3.fromRGB(235, 240, 255) or STYLE.red)
			UI.showRange(center, Config.PETS[a.pet].range, color)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local d = drag
	drag = nil
	if not d then
		return
	end
	clearDragHl()
	if not d.active then
		if petParts[d.from] then openPanel(d.from) end
		return
	end
	if selectedSlot and petParts[selectedSlot] then
		UI.showRange(slotPos(selectedSlot), Config.PETS[petParts[selectedSlot].pet].range, Color3.fromRGB(235, 240, 255))
	else
		UI.hideRange()
	end
	local to = d.snap
	local entry = petParts[d.from]
	if to and to ~= d.from and not pending[to] then
		ActionRemote:FireServer("Drop", d.from, to)
	elseif d.valid and d.point then
		-- optimistic move; the server's Move event or next snapshot confirms or puts it back
		FXK.pos[d.from] = Vector3.new(d.point.X, GROUND, d.point.Z)
		ActionRemote:FireServer("Move", d.from, { x = d.point.X, z = d.point.Z })
	elseif d.point then
		showToast("Can't stand there")
	end
	if entry then
		entry.popT = 0.6
	end
end)

rollBtn.Activated:Connect(function() ActionRemote:FireServer("Roll") end)
ultBtn.Activated:Connect(function() ActionRemote:FireServer("Ult") end)
startBtn.Activated:Connect(function() ActionRemote:FireServer("Start") end)
do -- photosensitivity notice on the start screen (T42): the game has flashes; one tap turns them off before playing
	local note = new("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.985),
		Size = UDim2.fromScale(0.92, 0.075), Text = "Contains flashing lights.", TextColor3 = STYLE.muted, TextScaled = true,
		Font = STYLE.fontB, ZIndex = 13, Name = "FlashNotice",
	}, startCard)
	note.Size = UDim2.fromScale(0.5, 0.075)
	note.Position = UDim2.fromScale(0.3, 1.13) -- under the card: the PLAY button's glow skin covered it inside
	local toggle = new("TextButton", {
		BackgroundColor3 = STYLE.panelDark, AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.76, 1.14), Size = UDim2.fromScale(0.4, 0.1), Text = "Flashes: ON",
		TextColor3 = STYLE.text, TextScaled = true, Font = STYLE.fontB, ZIndex = 13, Name = "FlashToggle",
	}, startCard)
	round(toggle, 6)
	outline(toggle, 1.5, 0.3, STYLE.muted)
	FXK.flashToggle = toggle
	toggle.Activated:Connect(function()
		local off = SETTINGS.flashes ~= false
		ActionRemote:FireServer("Setting", { flashes = not off, reducedMotion = off and true or SETTINGS.reducedMotion })
		toggle.Text = off and "Flashes: OFF" or "Flashes: ON"
	end)
end
startWaveBtn.Activated:Connect(function() ActionRemote:FireServer("StartWave") end)

quickBtn.Activated:Connect(function()
	quickRoll = not quickRoll
	quickBtn.Text = quickRoll and "Quick Roll: ON" or "Quick Roll: OFF"
	setButtonColor(quickBtn, quickRoll and STYLE.green or STYLE.grey)
end)

autoBtn.Activated:Connect(function()
	autoOn = not autoOn
	autoBtn.Text = autoOn and "AUTO: ON" or "AUTO: OFF"
	setButtonColor(autoBtn, autoOn and STYLE.green or STYLE.grey)
	ActionRemote:FireServer("AutoWave", autoOn)
	if autoOn and lastSnap and lastSnap.level < 3 then
		showToast("Auto starts waves now. It rolls for you from trainer level 3.")
	end
end)

-- With AUTO on, trainer level 3+ also rolls for you whenever you can afford it.
task.spawn(function()
	while true do
		task.wait(0.5)
		if autoOn and hud.Visible and lastSnap and not lastSnap.paused and lastSnap.level >= 3 and lastSnap.gems >= lastSnap.rollCost then
			local count = 0
			for _ in petParts do count += 1 end
			for _ in pending do count += 1 end
			if count < Config.MAX_UNITS and #revealQueue < 2 then
				ActionRemote:FireServer("Roll")
			end
		end
	end
end)

-- ===== State from server =====
local lastCoins, lastGems, ultReady = 0, 0, false
local lastCrystal = Config.CRYSTAL_HP

local function applySnapshot(s)
	lastSnap = s
	if s.gclock then
		FXK.clock.g, FXK.clock.at, FXK.clock.speed = s.gclock, s.gat, s.gspeed
	end
	countTo(coinLabel, s.coins)
	countTo(gemLabel, s.gems)
	if s.coins > lastCoins then
		coinScale.Scale = 1.1
		tween(coinScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	if s.gems > lastGems then
		gemScale.Scale = 1.1
		tween(gemScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	lastCoins, lastGems = s.coins, s.gems
	lvlNum.Text = tostring(s.level)
	xpLabel.Text = s.level >= Config.LEVEL_MAX and "MAX" or (s.xp .. "/" .. s.xpNeed)
	tween(xpFill, 0.25, { Size = UDim2.fromScale(math.clamp(s.xp / s.xpNeed, 0, 1), 1) })
	stageLabel.Text = "STAGE " .. s.stage .. (Config.isBossStage(s.stage) and "  BOSS" or "")
	streakLabel.Text = s.combo > 0 and string.format("PERFECT STREAK x%d   gems x%.2f", s.combo, Config.comboMult(s.combo)) or ""
	if s.state == "ready" then
		startWaveBtn.Text = "START WAVE"
		setButtonColor(startWaveBtn, STYLE.orange)
		setStartReady(true)
	else
		startWaveBtn.Text = "WAVE RUNNING"
		setButtonColor(startWaveBtn, STYLE.grey)
		setStartReady(false)
	end
	if s.bossClock then
		bossBarBg.Visible = true
		bossBar.Size = UDim2.fromScale(math.clamp(s.bossClock / Config.BOSS_TIME, 0, 1), 1)
		bossBarLabel.Text = string.format("BOSS ESCAPES IN %ds", math.ceil(s.bossClock))
	else
		bossBarBg.Visible = false
	end
	if s.crystal < lastCrystal then
		shakeGui(hpPill, 6, 0.3)
	end
	lastCrystal = s.crystal
	if s.bossClock and s.bossClock < 10 then
		shakeGui(bossBarBg, 3, 0.2)
	end
	-- escape warning at the crystal: a ring that fills as the boss timer runs out (shows where and how long)
	if s.bossClock and s.bossClock < 8 and FXK.impact and crystalPart then
		if not FXK.tele then
			local cp = crystalPart.Position
			FXK.tele = FXK.impact.telegraph(Vector3.new(cp.X, GROUND - 0.9, cp.Z), 7, STYLE.red)
		end
		FXK.tele.set(1 - s.bossClock / 8)
	elseif FXK.tele then
		FXK.tele.destroy()
		FXK.tele = nil
	end
	local frac = math.clamp(s.crystal / s.maxHp, 0, 1)
	tween(hpFill, 0.2, { Size = UDim2.fromScale(frac, 1) })
	hpLabel.Text = s.crystal .. " HP"
	rollCost.Text = s.rollCost .. " gems"
	setButtonColor(rollBtn, s.gems >= s.rollCost and STYLE.green or STYLE.grey)
	tween(ultFill, 0.2, { Size = UDim2.fromScale(1, s.ult / s.ultNeed) })
	local ready = s.ult >= s.ultNeed
	if ready ~= ultReady then
		ultReady = ready
		setUltReady(ready)
	end
	ultBtn.Text = ready and "ULT!" or "ULT"
	for slot in petParts do
		if not s.grid[tostring(slot)] then
			removePet(slot, false)
			FXK.pos[slot] = nil
		end
	end
	for key, u in s.grid do
		local slot = tonumber(key)
		if u.x and not (drag and drag.active and drag.from == slot) then
			FXK.pos[slot] = Vector3.new(u.x, GROUND, u.z)
		end
		if not pending[slot] then
			local entry = petParts[slot]
			if not entry or entry.pet ~= u.pet or entry.tier ~= u.tier then
				setPet(slot, u.pet, u.tier, entry == nil)
			end
		end
	end
	refreshPanel()
	refreshSkillBadge()
	if treeGui.Visible then refreshTree() end
	if progPanel.Visible then updateProgress() end
	if oddsPanel.Visible then updateOdds() end
	updateTutorial(s)
end

EventRemote.OnClientEvent:Connect(function(kind, data)
	if kind == "Begin" then
		clearWorld()
		table.clear(revealQueue)
		lastCoins, lastGems = 0, 0
		startScreen.Visible = false
		hud.Visible = true
		playHudEntrance()
		closePanel()
		autoOn = false
		autoBtn.Text = "AUTO: OFF"
		setButtonColor(autoBtn, STYLE.grey)
		tut.active = data.snapshot.tutorial
		tutCard.Visible = tut.active
		clearHighlights()
		lastSnap = data.snapshot
		applySnapshot(data.snapshot)
		if tut.active then
			setTutStep(1)
		end
	elseif kind == "SharedSummon" then
		-- another player in this server pulled a Legendary: a short shared banner (their reveal itself stays on their screen)
		if type(data) == "table" and type(data.name) == "string" and type(data.pet) == "string" and Config.PETS[data.pet] then
			showBanner(data.name .. " summoned " .. Config.PETS[data.pet].name .. "!", Config.RARITIES.Legendary.color, "LEGENDARY")
		end
	elseif kind == "Settings" then
		FXK.applySettings(data)
		if FXK.settingsPanel then
			FXK.settingsPanel.sync(data)
		end
	elseif kind == "State" then
		applySnapshot(data)
	elseif kind == "Denied" then
		showToast(data.reason or "Can't do that")
		tween(rollScale, 0.1, { Scale = 0.95 })
		task.delay(0.1, function() tween(rollScale, 0.15, { Scale = 1 }, Enum.EasingStyle.Back) end)
	elseif kind == "Roll" then
		if data.x then
			FXK.pos[data.slot] = Vector3.new(data.x, GROUND, data.z)
		end
		if data.bonus then
			floatText(groundOf(data.slot) + Vector3.new(0, 8, 0), "DOUBLE SUMMON!", STYLE.gem, 26)
		end
		playRoll(data.slot, data.pet, data.rarity)
	elseif kind == "Merge" then
		pending[data.to] = true
		local target = groundOf(data.to) + Vector3.new(0, 1, 0)
		for _, sl in data.from do
			local entry = petParts[sl]
			if entry then
				petParts[sl] = nil
				table.insert(flying, { model = entry.model, from = entry.model:GetPivot().Position, to = target, t = 0 })
			end
		end
		task.delay(0.24, function()
			pending[data.to] = nil
			setPet(data.to, data.pet, data.tier, true)
			burst(groundOf(data.to) + Vector3.new(0, 3, 0), Color3.new(1, 1, 1), 24, nil, true)
			ring(groundOf(data.to), rarityColor(data.pet), 10 + data.tier * 2, 0.6)
			local sheet = FXK.sheetReady("upgrade")
			if sheet then
				FXK.pfx.play(sheet, CFrame.new(groundOf(data.to) + Vector3.new(0, 3, 0)), { color = rarityColor(data.pet) })
			elseif FXK.td then
				FXK.td.upgrade(groundOf(data.to), rarityColor(data.pet), data.tier) -- light column + one chevron per tier
			end
			floatText(groundOf(data.to) + Vector3.new(0, 7, 0), data.tier >= 4 and "EVOLVED!" or "MERGE!", STYLE.gold, 26)
		end)
		if (data.coins or 0) > 0 then
			floatText(groundOf(data.to) + Vector3.new(2.5, 5, 0), "+" .. data.coins, STYLE.gold, 20)
		end
		if data.tier >= 4 then
			screenFlash(rarityColor(data.pet), 0.25)
		end
	elseif kind == "Move" then
		FXK.pos[data.id] = Vector3.new(data.x, GROUND, data.z)
		if selectedSlot == data.id and petParts[data.id] then
			UI.showRange(slotPos(data.id), Config.PETS[petParts[data.id].pet].range, Color3.fromRGB(235, 240, 255))
		end
		ring(slotPos(data.id), Color3.fromRGB(235, 240, 255), 7, 0.35)
	elseif kind == "Recycle" then
		removePet(data.slot, true)
		floatText(groundOf(data.slot) + Vector3.new(0, 4, 0), "+" .. data.coins, STYLE.gold, 24)
	elseif kind == "Upgrade" then
		for slot, e in petParts do
			if e.pet == data.pet then
				burst(groundOf(slot) + Vector3.new(0, 2, 0), STYLE.gold, 8)
				floatText(groundOf(slot) + Vector3.new(0, 6, 0), data.kind .. " " .. data.level, STYLE.green, 20)
			end
		end
	elseif kind == "Spawn" then
		spawnEnemy(data)
		if data.kind == "Boss" then
			shake.t, shake.amp = 0.6, 2.5
			ring(Path.positionAt(0), STYLE.red, 40, 0.8)
			pillar(Path.positionAt(0), STYLE.red, 0.8, 5)
			showBanner("BOSS!", STYLE.red, "Defeat it before it escapes")
		end
	elseif kind == "Shot" then
		shotFx(data)
	elseif kind == "Kill" then
		if os.clock() < ultHoldUntil then
			task.delay(ultHoldUntil - os.clock(), killEnemy, data)
		else
			killEnemy(data)
		end
	elseif kind == "Leak" then
		local e = enemies[data.id]
		if e then
			e.model:Destroy()
			enemies[data.id] = nil
		end
		screenFlash(STYLE.red, 0.3)
		crystalHit = 1
		shake.t, shake.amp = 0.3, 1.2
		local last = Config.PATH[#Config.PATH]
		floatText(Vector3.new(last.X + 5, 7, last.Z), "LEAK! streak lost", STYLE.red, 24)
	elseif kind == "Stage" then
		if not tut.active or tut.step >= 5 then
			showBanner(data.boss and "BOSS STAGE " .. data.stage or "STAGE " .. data.stage, data.boss and STYLE.red or STYLE.gold)
		end
	elseif kind == "Clear" then
		showBanner(data.perfect and "PERFECT!" or "STAGE CLEAR", data.perfect and STYLE.green or STYLE.gold, "+" .. data.bonus .. " gems")
	elseif kind == "LevelUp" then
		showBanner("LEVEL UP!  " .. data.level, STYLE.purple, string.format("+%d gems   +1 Skill Point   Luck +%d%%", data.gems, math.floor(data.luck * 100 + 0.5)))
		screenFlash(STYLE.purple, 0.25)
		badgeScale.Scale = 1.6
		tween(badgeScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(xpFill, 0.15, { BackgroundColor3 = Color3.new(1, 1, 1) })
		task.delay(0.2, function() tween(xpFill, 0.4, { BackgroundColor3 = STYLE.purple }) end)
	elseif kind == "Overrun" then
		clearEnemies()
		screenFlash(STYLE.red, 0.4)
		showBanner("OVERRUN!", STYLE.red, string.format("Pushed back to stage %d  (-%s coins)", data.stage, fmt(data.lostCoins)))
	elseif kind == "BossEscaped" then
		clearEnemies()
		showBanner("BOSS ESCAPED", STYLE.red, "Back to stage " .. data.stage .. " - streak lost")
	elseif kind == "Ult" then
		local entry = data.signature and petParts[data.slot]
		if entry and FXK.cut and FXK.cut.signatures[data.signature] and not SETTINGS.reducedMotion then
			local targets = {}
			for _, e in enemies do
				local p = e.model:GetPivot().Position
				table.insert(targets, Vector3.new(p.X, GROUND - 0.2, p.Z))
			end
			-- no enemies left: the ability lands along the street instead of around the caster
			if #targets == 0 then
				for k = 1, 7 do
					local p = Path.positionAt(Path.length * (k - 0.5) / 7)
					table.insert(targets, Vector3.new(p.X, GROUND - 0.2, p.Z))
				end
			end
			local def = Config.PETS[data.pet]
			local dur = FXK.cut.play(data.signature, {
				model = entry.model, origin = groundOf(data.slot), targets = targets, color = rarityColor(data.pet),
				title = string.upper(def.name), ability = def.signatureName or data.signature,
				setCamera = function(cf) FXK.camOverride = cf end,
				gameCamera = function() return FXK.gameCF or camera.CFrame end,
				settings = SETTINGS, sfx = FXK.play,
				onSkip = function() ultHoldUntil = 0 end, -- a skipped cutscene releases the held enemy deaths at once
			})
			-- hold enemy death visuals until the hits land in the cutscene
			ultHoldUntil = os.clock() + dur * 0.65
		else
			playUlt()
		end
	elseif kind == "SkillBought" then
		local ui = nodeUI[data.id]
		if ui then
			ui.scale.Scale = 1.3
			tween(ui.scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
			uiSparks(treeArea, UDim2.new(0.5, ui.x, 0.5, ui.y), Config.TREE_BY_ID[data.id].color, 16, 80)
		end
		if lastSnap then
			refreshTree()
		end
	elseif kind == "TutorialDone" then
		showBanner("TUTORIAL COMPLETE", STYLE.green, "+" .. data.gems .. " gems and +" .. data.sp .. " Skill Points! Open the Skill Tree.")
		screenFlash(STYLE.green, 0.3)
		clearHighlights()
		highlightGui(skillsBtn)
		task.delay(8, clearHighlights)
	end
end)

popIn(startScale)
