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
local SETTINGS = { flashes = true, reducedMotion = false, shake = true, damageNumbers = true, uiSize = "normal" }
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
local UI = require(script.Parent:WaitForChild("UILib"))({ ReplicatedStorage = ReplicatedStorage, SETTINGS = SETTINGS, STYLE = STYLE, TweenService = TweenService, UserInputService = UserInputService }) -- the UI helper library lives in StarterPlayerScripts.UILib
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
local makePanel = require(script.Parent:WaitForChild("GCPanelKit"))({ STYLE = STYLE, UI = UI, label = label, makeButton = makeButton, new = new, round = round, shade = shade, tween = tween })

-- ===== HUD skeleton =====
local gui = new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))
if UI.fa then
	-- soft violet vignette framing the whole screen
	new("ImageLabel", { Name = "Vignette", BackgroundTransparency = 1, ImageContent = UI.fa.vignette(), Size = UDim2.fromScale(1, 1), ZIndex = 0, Active = false }, gui)
	task.spawn(UI.blurLoop)
end
local UI_SIZE_MUL = { small = 0.85, normal = 1, large = 1.2 }
local hud = new("Frame", { Name = "Hud", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false }, gui)
local uiScale = new("UIScale", { Scale = 1 }, hud)

local function relayout()
	local vp = camera.ViewportSize
	local sc = IS_PHONE and math.clamp(vp.Y / 420, 0.8, 1.0) or math.clamp(vp.Y / 780, 0.6, 1.2)
	sc *= UI_SIZE_MUL[SETTINGS.uiSize] or 1 -- T117: Small / Normal / Large from the settings
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

-- ===== HUD v2 (2026-10-28 rework): trainer card + purse top-left, icon dock left, run status top centre,
-- Sol's-style roll bar bottom centre (AUTO | ROLL | QUICK), START WAVE + ULT dial bottom right. Same locals as v1,
-- so the rest of the client keeps working. Icons are the uploaded UI Kit art (UIArt.ids); text-only fallback if missing.
local function iconImg(parent, name, size, pos, anchor, z)
	local img = UI.art and UI.art.has(name) and UI.art.image(name)
	if not img then
		return nil
	end
	return new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = img, ScaleType = Enum.ScaleType.Fit, Size = size, Position = pos, AnchorPoint = anchor or Vector2.new(0.5, 0.5), ZIndex = z or 4 }, parent)
end

local function glowStroke(gui, color, thickness, transparency)
	return new("UIStroke", { Color = color, Thickness = thickness or 2, Transparency = transparency or 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, gui)
end

-- top-left: trainer card and purse
local rail = new("Frame", { Name = "Rail", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(250, 160) }, hud)
do -- keep below Roblox's top bar (UI Quality Bar gap 1)
	local GuiService = game:GetService("GuiService")
	local function placeRail()
		local ok, inset = pcall(function() return GuiService.TopbarInset.Height end)
		rail.Position = UDim2.fromOffset(12, 8 + (ok and inset or 58) / math.max(uiScale.Scale, 0.01))
	end
	placeRail()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(placeRail)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(placeRail)
end

local lvlPill = pill(rail, UDim2.fromOffset(236, 58), "Level")
lvlPill.Position = UDim2.fromOffset(10, 0)
local lvlBadge = new("Frame", { Name = "Medallion", BackgroundColor3 = STYLE.purple, Size = UDim2.fromOffset(62, 62), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(18, 29), ZIndex = 4 }, lvlPill)
round(lvlBadge, 31)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(196, 150, 255), Color3.fromRGB(88, 40, 160)) }, lvlBadge)
glowStroke(lvlBadge, STYLE.gold, 3, 0)
local lvlNum = label(lvlBadge, "1", 30, STYLE.text, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.54), UDim2.fromScale(1, 0.7), STYLE.fontB)
lvlNum.ZIndex = 5
local lvlTitle = label(lvlPill, "TRAINER", 15, STYLE.gold, Vector2.new(0, 0), UDim2.fromOffset(58, 5), UDim2.new(1, -66, 0, 18), STYLE.font)
lvlTitle.TextXAlignment = Enum.TextXAlignment.Left
local xpBg = new("Frame", { BackgroundColor3 = Color3.fromRGB(10, 10, 26), Position = UDim2.fromOffset(58, 28), Size = UDim2.new(1, -68, 0, 18), ZIndex = 3 }, lvlPill)
round(xpBg, 9)
glowStroke(xpBg, Color3.fromRGB(120, 90, 200), 1.5, 0.3)
local xpFill = new("Frame", { BackgroundColor3 = STYLE.purple, Size = UDim2.fromScale(0, 1), ZIndex = 3 }, xpBg)
round(xpFill, 9)
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(140, 90, 255), Color3.fromRGB(230, 170, 255)) }, xpFill)
local xpLabel = label(xpBg, "", 13, STYLE.text, nil, nil, nil, STYLE.fontB)
xpLabel.ZIndex = 4

local function currencyPill(y, color, name, icon)
	local p = pill(rail, UDim2.fromOffset(176, 42), name)
	p.Position = UDim2.fromOffset(24, y)
	local back = new("Frame", { Name = "Back", BackgroundColor3 = Color3.fromRGB(10, 10, 24), BackgroundTransparency = 0.3, Size = UDim2.fromScale(1, 1), ZIndex = 1 }, p)
	round(back, 21)
	glowStroke(back, color, 1.5, 0.45)
	local l = label(p, "0", 26, color, Vector2.new(0, 0.5), UDim2.new(0, 34, 0.5, 0), UDim2.new(1, -42, 1, 0), STYLE.fontB)
	l.TextXAlignment = Enum.TextXAlignment.Left
	local sc = new("UIScale", { Scale = 1 }, p)
	-- the icon breaks the capsule's left edge, larger than the bar (reference: paid simulator HUDs)
	local ic = iconImg(p, icon, UDim2.fromOffset(50, 50), UDim2.new(0, 2, 0.5, 0), nil, 5)
	return p, l, sc, ic
end
local coinPill, coinLabel, coinScale, coinIcon = currencyPill(68, STYLE.gold, "Coins", "icon_coin")
local gemPill, gemLabel, gemScale, gemIcon = currencyPill(116, STYLE.gem, "Gems", "icon_gem")
for _, pair in { { coinPill, coinIcon, STYLE.gold }, { gemPill, gemIcon, STYLE.gem } } do
	if not pair[2] then -- no art: a simple drawn token so the counter still has an icon
		local t = new("Frame", { BackgroundColor3 = pair[3], Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 2, 0.5, 0), ZIndex = 5 }, pair[1])
		round(t, 13)
	end
end

-- left: icon dock (tiles with painted icons, label under, badge corner)
local dock = new("Frame", { Name = "Dock", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 10), Size = UDim2.fromOffset(84, 300) }, hud)
new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, dock)
local DOCK_ICONS = { ["Progression"] = "icon_trophy", ["Skill Tree"] = "icon_star", ["Settings"] = "icon_gear" }
local function railButton(text, order, color)
	local holder = new("Frame", { Name = text, BackgroundTransparency = 1, Size = UDim2.fromOffset(84, 92), LayoutOrder = order }, dock)
	local b = makeButton(holder, "", UDim2.fromOffset(72, 72), UDim2.new(0.5, 0, 0, 36), color or STYLE.blue)
	local ic = iconImg(b, DOCK_ICONS[text] or "icon_star", UDim2.fromOffset(54, 54), UDim2.fromScale(0.5, 0.5), nil, 6)
	if not ic then
		b.Text = string.sub(text, 1, 1)
		b.TextSize = 30
	end
	local cap = label(holder, string.upper(text), 14, STYLE.text, Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, 0), UDim2.new(1, 16, 0, 18), STYLE.fontB)
	cap.ZIndex = 4
	return b
end
local progressBtn = railButton("Progression", 3, STYLE.purple)
local skillsBtn = railButton("Skill Tree", 2, STYLE.blue)
local spBadge = new("Frame", { BackgroundColor3 = STYLE.red, Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), ZIndex = 8, Visible = false }, skillsBtn)
round(spBadge, 13)
outline(spBadge, 2, 0.1, Color3.new(1, 1, 1))
local spBadgeLabel = label(spBadge, "0", 15, STYLE.text, nil, nil, nil, STYLE.fontB)
spBadgeLabel.ZIndex = 9

-- top centre: stage plate, crystal bar under it, streak badge to the right
local stagePill = pill(hud, UDim2.fromOffset(220, 46), "Stage")
stagePill.AnchorPoint = Vector2.new(0.5, 0)
stagePill.Position = UDim2.new(0.5, 0, 0, 10)
local stageLabel = label(stagePill, "STAGE 1", 28, STYLE.gold, nil, nil, nil, STYLE.fontB)

local hpPill = new("Frame", { Name = "Crystal", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 62), Size = UDim2.fromOffset(280, 26) }, hud)
local hpBg = new("Frame", { BackgroundColor3 = Color3.fromRGB(8, 12, 28), BackgroundTransparency = 0.15, Position = UDim2.fromOffset(18, 2), Size = UDim2.new(1, -18, 1, -4), ZIndex = 2 }, hpPill)
round(hpBg, 11)
glowStroke(hpBg, Color3.fromRGB(90, 170, 255), 1.5, 0.25)
local hpFill = new("Frame", { BackgroundColor3 = STYLE.blue, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, hpBg)
round(hpFill, 11)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 220, 255), Color3.fromRGB(40, 110, 230)) }, hpFill)
local hpLabel = label(hpBg, "", 16, STYLE.text, nil, nil, nil, STYLE.fontB)
hpLabel.ZIndex = 4
iconImg(hpPill, "icon_crystal", UDim2.fromOffset(40, 40), UDim2.new(0, 14, 0.5, 0), nil, 5)

-- streak badge: flame icon, big multiplier, small gem bonus; hidden at 0
local streakBadge = pill(hud, UDim2.fromOffset(150, 46), "Streak")
streakBadge.AnchorPoint = Vector2.new(0, 0)
streakBadge.Position = UDim2.new(0.5, 122, 0, 10)
streakBadge.Visible = false
do
	local back = new("Frame", { Name = "Back", BackgroundColor3 = Color3.fromRGB(24, 12, 8), BackgroundTransparency = 0.25, Size = UDim2.fromScale(1, 1), ZIndex = 1 }, streakBadge)
	round(back, 23)
	glowStroke(back, STYLE.orange, 1.5, 0.35)
end
local streakScale = new("UIScale", { Scale = 1 }, streakBadge)
local flame = iconImg(streakBadge, "icon_flame", UDim2.fromOffset(52, 52), UDim2.new(0, 14, 0.5, -4), nil, 6)
local streakNum = label(streakBadge, "x1", 28, STYLE.orange, Vector2.new(0, 0), UDim2.fromOffset(42, -1), UDim2.fromOffset(100, 30), STYLE.fontB)
streakNum.TextXAlignment = Enum.TextXAlignment.Left
local streakSub = label(streakBadge, "", 15, STYLE.gem, Vector2.new(0, 1), UDim2.new(0, 43, 1, -2), UDim2.fromOffset(104, 18), STYLE.fontB)
streakSub.TextXAlignment = Enum.TextXAlignment.Left
local streakLabel = streakNum -- old name kept for code that reads it
if flame then
	TweenService:Create(flame, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 6, Size = UDim2.fromOffset(56, 58) }):Play()
end
local lastCombo = 0
function UI.setStreak(combo, mult)
	streakBadge.Visible = combo > 0
	if combo <= 0 then
		lastCombo = 0
		return
	end
	streakNum.Text = "x" .. combo
	streakSub.Text = string.format("GEMS x%.2f", mult)
	if combo > lastCombo then -- pop on every new perfect stage
		streakScale.Scale = 1.25
		tween(streakScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	lastCombo = combo
end

local bossBarBg = new("Frame", { BackgroundColor3 = STYLE.panelDark, Size = UDim2.fromOffset(280, 20), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 94), Visible = false }, hud)
round(bossBarBg, 10)
outline(bossBarBg, 2, 0.3, STYLE.red)
local bossBar = new("Frame", { BackgroundColor3 = STYLE.red, Size = UDim2.fromScale(1, 1) }, bossBarBg)
round(bossBar, 10)
gradient(bossBar, STYLE.red)
local bossBarLabel = label(bossBarBg, "", 13, STYLE.text, nil, nil, nil, STYLE.fontB)
bossBarLabel.ZIndex = 4

-- bottom centre: the roll bar
local rollBar = new("Frame", { Name = "RollBar", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.fromOffset(600, 92) }, hud)
local rollBtn, rollScale = makeButton(rollBar, "", UDim2.fromOffset(250, 80), UDim2.new(0.5, 0, 1, -40), STYLE.green)
local rollText = label(rollBtn, "ROLL", 36, STYLE.text, Vector2.new(0, 0), UDim2.fromOffset(88, 4), UDim2.new(1, -96, 0, 42))
rollText.TextXAlignment = Enum.TextXAlignment.Left
local eggIcon = UI.fa and new("ImageLabel", { Name = "CardIcon", BackgroundTransparency = 1, ImageContent = UI.fa.cardIcon(), ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(54, 70), Position = UDim2.fromOffset(20, 5), ZIndex = 3 }, rollBtn)
	or iconImg(rollBtn, "icon_gem", UDim2.fromOffset(60, 60), UDim2.fromOffset(48, 40), nil, 4)
	or new("Frame", { BackgroundColor3 = STYLE.gem, Size = UDim2.fromOffset(40, 52), Position = UDim2.fromOffset(26, 12) }, rollBtn)
local rollCost = label(rollBtn, "", 19, STYLE.gem, Vector2.new(0, 1), UDim2.new(0, 116, 1, -8), UDim2.new(1, -124, 0, 22), STYLE.fontB)
rollCost.TextXAlignment = Enum.TextXAlignment.Left
iconImg(rollBtn, "icon_gem", UDim2.fromOffset(26, 26), UDim2.new(0, 102, 1, -19), nil, 5)
local oddsChip = makeButton(rollBar, "ODDS", UDim2.fromOffset(62, 26), UDim2.new(0.5, 125, 1, -82), STYLE.gold, Vector2.new(1, 0.5))
oddsChip.TextSize = 14
local autoBtn = makeButton(rollBar, "AUTO: OFF", UDim2.fromOffset(160, 50), UDim2.new(0.5, -142, 1, -40), STYLE.grey, Vector2.new(1, 0.5))
autoBtn.TextSize = 17
iconImg(autoBtn, "icon_rebirth", UDim2.fromOffset(30, 30), UDim2.new(0, 18, 0.5, 0), nil, 6)
local quickBtn = makeButton(rollBar, "QUICK: OFF", UDim2.fromOffset(160, 50), UDim2.new(0.5, 142, 1, -40), STYLE.grey, Vector2.new(0, 0.5))
quickBtn.TextSize = 17
iconImg(quickBtn, "icon_stopwatch", UDim2.fromOffset(30, 30), UDim2.new(0, 18, 0.5, 0), nil, 6)

-- bottom right: START WAVE with the ULT charge dial above it
local startWaveBtn = makeButton(hud, "START WAVE", UDim2.fromOffset(240, 66), UDim2.new(1, -12, 1, -12), STYLE.orange, Vector2.new(1, 1))
startWaveBtn.TextSize = 22
iconImg(startWaveBtn, "icon_sword", UDim2.fromOffset(44, 44), UDim2.new(0, 30, 0.5, 0), nil, 6)

local ultBtn, ultScale = makeButton(hud, "ULT", UDim2.fromOffset(96, 96), UDim2.new(1, -74, 1, -136), STYLE.gold)
for _, c in ultBtn:GetChildren() do -- strip the square glass skin: the dial is a circle with a gold ring
	if c:IsA("UICorner") or c:IsA("UIStroke") or (c:IsA("ImageLabel") and c.Name ~= "Icon") then c:Destroy() end
end
ultBtn.BackgroundTransparency = 0.1
ultBtn.BackgroundColor3 = Color3.fromRGB(18, 14, 34)
round(ultBtn, 48)
new("UIStroke", { Color = Color3.fromRGB(200, 160, 80), Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, ultBtn)
ultBtn.ClipsDescendants = false
ultBtn.TextYAlignment = Enum.TextYAlignment.Bottom
ultBtn.TextSize = 18
new("UIPadding", { PaddingBottom = UDim.new(0, 8) }, ultBtn)
local ultClip = new("CanvasGroup", { Name = "Charge", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0 }, ultBtn) -- CanvasGroup clips to the round corner; ClipsDescendants would clip square
round(ultClip, 48)
local ultFill = new("Frame", { BackgroundColor3 = STYLE.gold, BackgroundTransparency = 0.35, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), ZIndex = 0 }, ultClip)
iconImg(ultBtn, "icon_bolt", UDim2.fromOffset(50, 50), UDim2.new(0.5, 0, 0.42, 0), nil, 6)
local ultGlow = new("UIStroke", { Color = STYLE.gold, Thickness = 6, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, ultBtn)
local ultPulse = new("UIScale", { Scale = 1 }, ultBtn)
local ultTweens = {}

do -- phone layout: the dock moves to the right edge, START WAVE and ULT sit above the roll bar's sides
	local function applyLayout(phone)
		dock.AnchorPoint = phone and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
		dock.Position = phone and UDim2.new(1, -8, 0.5, -20) or UDim2.new(0, 12, 0.5, 10)
		if phone then
			startWaveBtn.AnchorPoint = Vector2.new(1, 1)
			startWaveBtn.Position = UDim2.new(1, -8, 1, -112)
			startWaveBtn.Size = UDim2.fromOffset(200, 60)
			ultBtn.Position = UDim2.new(0.5, 190, 0, 34) -- top, beside the stage plate: bottom-right is the jump button
		else
			startWaveBtn.AnchorPoint = Vector2.new(1, 1)
			startWaveBtn.Position = UDim2.new(1, -12, 1, -12)
			startWaveBtn.Size = UDim2.fromOffset(240, 66)
			ultBtn.Position = UDim2.new(1, -74, 1, -136)
		end
	end
	applyLayout(IS_PHONE)
	gui:GetAttributeChangedSignal("PhoneLayout"):Connect(function()
		applyLayout(gui:GetAttribute("PhoneLayout") == true)
	end)
end

-- ===== Victorian objects (2026-10-28). User: "all the buttons are the same uniform look". After Inscryption (every
-- control is a physical object: a bell ends the turn) and Persona 5 (one signature colour, tilted shapes, motion with
-- intent), each control here is its own object with its own motion. Art: UI Kit/art/out/obj_*.png (ComfyUI, ours).
do -- block scope: the main chunk is near Luau's 200-local limit
local OBJ = { tarot = 93758813189086, bell = 94301673165085, watch = 138594781895934, seal = 78303286285946, sign = 132850205596088, dial = 135064433494937, plaque = 83841573700983 }
local function objImg(parent, key, size, pos, anchor, z, scaleType)
	local img = new("ImageLabel", { Name = "Obj_" .. key, BackgroundTransparency = 1, Image = "rbxassetid://" .. OBJ[key], ScaleType = scaleType or Enum.ScaleType.Fit, Size = size, Position = pos, AnchorPoint = anchor or Vector2.new(0.5, 0.5), ZIndex = z or 1 }, parent)
	img:SetAttribute("Tint", true)
	return img
end
local function objectify(b) -- drop the shared glass skin; the object image becomes the button
	local skin = b:FindFirstChild("Skin")
	if skin then skin.Visible = false end
	for _, c in b:GetChildren() do
		if c:IsA("UIGradient") or (c:IsA("UIStroke") and c ~= ultGlow) then c:Destroy() end
	end
	b.BackgroundTransparency = 1
	b:SetAttribute("ObjectButton", true)
end
local function hideIcon(b)
	local ic = b:FindFirstChild("Icon")
	if ic then ic.Visible = false end
end

-- stage: an iron street sign hanging from chains above the board, swaying a little
do
	local g = stagePill:FindFirstChild("Glass")
	if g then g.Visible = false end
	stagePill.Size = UDim2.fromOffset(176, 120)
	stagePill.Position = UDim2.new(0.5, 0, 0, -30)
	local sign = objImg(stagePill, "sign", UDim2.fromOffset(176, 158), UDim2.fromScale(0.5, 0), Vector2.new(0.5, 0), 2)
	stageLabel.Parent = sign
	stageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	stageLabel.Position = UDim2.fromScale(0.5, 0.66)
	stageLabel.Size = UDim2.fromScale(0.62, 0.2)
	stageLabel.TextScaled = true
	stageLabel.ZIndex = 4
	TweenService:Create(sign, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 2.5 }):Play()
	sign.Rotation = -2.5
	hpPill.Position = UDim2.new(0.5, 0, 0, 124)
	bossBarBg.Position = UDim2.new(0.5, 0, 0, 154)
	streakBadge.Position = UDim2.new(0.5, 100, 0, 18)
end

-- ROLL: a tarot card you draw. Tilted at rest, straightens and lifts on hover, flips when pressed.
do
	objectify(rollBtn)
	objImg(rollBtn, "plaque", UDim2.new(1, 26, 1, 14), UDim2.fromScale(0.5, 0.5), nil, 1, Enum.ScaleType.Stretch)
	eggIcon.Visible = false
	local card = objImg(rollBtn, "tarot", UDim2.fromOffset(78, 132), UDim2.new(0, 48, 0.5, -18), nil, 4)
	card.Rotation = -9
	local rest, lift = card.Position, UDim2.new(0, 48, 0.5, -30)
	rollBtn.MouseEnter:Connect(function() tween(card, 0.2, { Rotation = 0, Position = lift }, Enum.EasingStyle.Back) end)
	rollBtn.MouseLeave:Connect(function() tween(card, 0.25, { Rotation = -9, Position = rest }) end)
	rollBtn.Activated:Connect(function()
		tween(card, 0.09, { Size = UDim2.fromOffset(4, 132) }).Completed:Connect(function()
			tween(card, 0.14, { Size = UDim2.fromOffset(78, 132) }, Enum.EasingStyle.Back)
		end)
	end)
	rollText.Position = UDim2.fromOffset(100, 4)
	rollCost.Position = UDim2.new(0, 124, 1, -8)
	for _, c in rollBtn:GetChildren() do -- move the small gem beside the cost
		if c.Name == "Icon" then c.Position = UDim2.new(0, 110, 1, -19) end
	end
end

-- START WAVE: a brass bell on a plate; ringing it starts the wave (Inscryption's bell)
do
	objectify(startWaveBtn)
	hideIcon(startWaveBtn)
	objImg(startWaveBtn, "plaque", UDim2.new(1, 24, 1, 14), UDim2.fromScale(0.5, 0.5), nil, 1, Enum.ScaleType.Stretch)
	local bell = objImg(startWaveBtn, "bell", UDim2.fromOffset(48, 104), UDim2.new(0, 22, 0.5, -10), nil, 4)
	local swinging = false
	startWaveBtn.Activated:Connect(function()
		if swinging then return end
		swinging = true
		task.spawn(function()
			for _, r in { 22, -16, 10, -5, 0 } do
				tween(bell, 0.12, { Rotation = r }, Enum.EasingStyle.Sine).Completed:Wait()
			end
			swinging = false
		end)
	end)
end

-- ULT: a pocket watch; a glowing hand sweeps once round as the ultimate charges
do
	for _, c in ultBtn:GetChildren() do
		if c:IsA("UIStroke") and c ~= ultGlow then c:Destroy() end
	end
	ultBtn.BackgroundTransparency = 1
	ultBtn:SetAttribute("ObjectButton", true)
	hideIcon(ultBtn)
	ultClip.Visible = false
	local watch = objImg(ultBtn, "watch", UDim2.fromOffset(100, 130), UDim2.fromScale(0.5, 0.38), nil, 2)
	local pivot = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.585), Size = UDim2.fromOffset(60, 60), ZIndex = 5 }, watch)
	-- the hand sits on the top half of a square pivot, so turning the pivot turns the hand round the dial centre
	local hand = new("Frame", { BackgroundColor3 = STYLE.gold, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 28), ZIndex = 6 }, pivot)
	round(hand, 2)
	glowStroke(hand, Color3.fromRGB(255, 240, 180), 1.5, 0.2)
	ultFill:GetPropertyChangedSignal("Size"):Connect(function()
		pivot.Rotation = math.clamp(ultFill.Size.Y.Scale, 0, 1) * 360
	end)
	ultBtn.TextYAlignment = Enum.TextYAlignment.Bottom
end

-- AUTO / QUICK: brass dials on plates; the dial turns a quarter when switched on
for _, b in { autoBtn, quickBtn } do
	objectify(b)
	hideIcon(b)
	objImg(b, "plaque", UDim2.new(1, 20, 1, 12), UDim2.fromScale(0.5, 0.5), nil, 1, Enum.ScaleType.Stretch)
	local dial = objImg(b, "dial", UDim2.fromOffset(46, 46), UDim2.new(0, 14, 0.5, 0), nil, 4)
	local lamp = new("Frame", { BackgroundColor3 = Color3.fromRGB(60, 40, 30), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(12, 12), ZIndex = 4 }, b)
	round(lamp, 6)
	b:GetAttributeChangedSignal("On"):Connect(function()
		local on = b:GetAttribute("On") == true
		tween(dial, 0.25, { Rotation = on and 90 or 0 }, Enum.EasingStyle.Back)
		tween(lamp, 0.2, { BackgroundColor3 = on and STYLE.green or Color3.fromRGB(60, 40, 30) })
	end)
end

-- dock tiles: crimson wax seals with the icon pressed into them
function UI.sealButton(b)
	objectify(b)
	objImg(b, "seal", UDim2.new(1, 14, 1, 14), UDim2.fromScale(0.5, 0.5), nil, 1)
end
for _, holder in dock:GetChildren() do
	local b = holder:IsA("Frame") and holder:FindFirstChildOfClass("TextButton")
	if b then UI.sealButton(b) end
end

-- purse: brass plates behind the counters
for _, p in { coinPill, gemPill } do
	local back = p:FindFirstChild("Back")
	if back then back.Visible = false end
	objImg(p, "plaque", UDim2.new(1, 16, 1, 10), UDim2.fromScale(0.5, 0.5), nil, 1, Enum.ScaleType.Stretch)
end
-- the counter: one mahogany-and-brass desk along the bottom; the deck, dials, bell and watch sit on it instead of
-- floating on separate plates (Inscryption's table, Hearthstone's board). 9-sliced so the carved corners keep their shape.
do
	local desk = new("ImageLabel", { Name = "Desk", BackgroundTransparency = 1, Image = "rbxassetid://110714108088884", ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(120, 95, 522, 300), SliceScale = 0.32, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 8), Size = UDim2.new(1, 16, 0, 128), ZIndex = 0 }, hud)
	desk:SetAttribute("Tint", true)
	for _, b in { rollBtn, autoBtn, quickBtn, startWaveBtn } do
		local plate = b:FindFirstChild("Obj_plaque")
		if plate then plate.Visible = false end
	end
	-- the deck under the tarot card: ROLL draws its top card
	local deck = new("ImageLabel", { Name = "Obj_deck", BackgroundTransparency = 1, Image = "rbxassetid://88735086829516", ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 48, 0.5, 10), Size = UDim2.fromOffset(104, 108), ZIndex = 3 }, rollBtn)
	deck:SetAttribute("Tint", true)
end
require(script.Parent:WaitForChild("GCHudDressing"))({ TweenService = TweenService, hpBg = hpBg, hpFill = hpFill, hpLabel = hpLabel, hpPill = hpPill, lvlBadge = lvlBadge, lvlNum = lvlNum, lvlTitle = lvlTitle, new = new, round = round, xpBg = xpBg, xpFill = xpFill, xpLabel = xpLabel })
do -- abstract layer around the objects (AbstractLayer.luau)
	local ok, err = pcall(function() UI.abstract = require(script.Parent:WaitForChild("AbstractLayer", 5))({ hud = hud, rollBtn = rollBtn, autoBtn = autoBtn, quickBtn = quickBtn, startWaveBtn = startWaveBtn, ultBtn = ultBtn, oddsChip = oddsChip, coinPill = coinPill, gemPill = gemPill, rail = rail, dock = dock, stagePill = stagePill, abstractHUD = true, reducedMotion = function() return SETTINGS.reducedMotion end }) end)
	if not ok then warn("AbstractLayer: " .. tostring(err)) end
	local ok2, err2 = pcall(function() require(script.Parent:WaitForChild("AbstractHUD", 5))({ rollBtn = rollBtn, rollCost = rollCost, autoBtn = autoBtn, quickBtn = quickBtn, oddsChip = oddsChip, startWaveBtn = startWaveBtn, ultBtn = ultBtn, ultFill = ultFill, coinPill = coinPill, coinLabel = coinLabel, gemPill = gemPill, gemLabel = gemLabel, lvlPill = lvlPill, lvlNum = lvlNum, xpFill = xpFill, stagePill = stagePill, stageLabel = stageLabel, hpPill = hpPill, hpFill = hpFill, hpLabel = hpLabel, dock = dock, reducedMotion = function() return SETTINGS.reducedMotion end }) end)
	if not ok2 then warn("AbstractHUD: " .. tostring(err2)) end
end
UI.objectify, UI.objImg = objectify, objImg -- shared with screens built later (familiar ledger)
-- text above the object art
coinLabel.ZIndex, gemLabel.ZIndex, rollText.ZIndex, rollCost.ZIndex = 3, 3, 5, 5
for _, b in { ultBtn, startWaveBtn, autoBtn, quickBtn } do
	local t = b:FindFirstChild("Txt")
	if t then t.ZIndex = 6 end
end
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
require(script.Parent:WaitForChild("GCUpgradeRows"))({ UI = UI, deleteBtn = deleteBtn, glowStroke = glowStroke, new = new, round = round, upRows = upRows })

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
local progPanel, progBody, progScale, progClose = makePanel(hud, UDim2.fromOffset(780, 440), "Trainer Progression", STYLE.purple)
UI.blurHolders[progPanel] = true
progPanel.AnchorPoint = Vector2.new(0.5, 0.5)
progPanel.Position = UDim2.fromScale(0.5, 0.5)
progPanel.ZIndex = 9
-- Trainer Road (2026-10-28 rework): header with level, XP and what luck buys; a scrolling road of level cards
-- (claimed / next / locked) with their rewards; a footer that says how XP is earned.
local progHead = label(progBody, "", 24, STYLE.text, Vector2.new(0, 0), UDim2.fromOffset(28, 4), UDim2.fromOffset(330, 30), STYLE.font)
progHead.TextXAlignment = Enum.TextXAlignment.Left
progHead.ZIndex = 10
local progXpBg = new("Frame", { BackgroundColor3 = Color3.fromRGB(14, 12, 30), Position = UDim2.fromOffset(28, 40), Size = UDim2.fromOffset(420, 20), ZIndex = 10 }, progBody)
round(progXpBg, 10)
glowStroke(progXpBg, Color3.fromRGB(140, 100, 220), 1.5, 0.3)
local progXp = new("Frame", { BackgroundColor3 = STYLE.purple, Size = UDim2.fromScale(0, 1), ZIndex = 11 }, progXpBg)
round(progXp, 10)
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(140, 90, 255), Color3.fromRGB(230, 170, 255)) }, progXp)
local progXpText = label(progXpBg, "", 13, STYLE.text, nil, nil, nil, STYLE.fontB)
progXpText.ZIndex = 12
local luckChip = pill(progBody, UDim2.fromOffset(270, 56), "Luck")
luckChip.Position = UDim2.fromOffset(482, 4)
iconImg(luckChip, "icon_star", UDim2.fromOffset(40, 40), UDim2.fromOffset(28, 28), nil, 11)
local luckLine = label(luckChip, "", 18, STYLE.gold, Vector2.new(0, 0), UDim2.fromOffset(54, 6), UDim2.fromOffset(210, 22), STYLE.fontB)
luckLine.TextXAlignment = Enum.TextXAlignment.Left
luckLine.ZIndex = 11
local luckSub = label(luckChip, "", 13, STYLE.muted, Vector2.new(0, 0), UDim2.fromOffset(54, 30), UDim2.fromOffset(210, 18), STYLE.fontB)
luckSub.TextXAlignment = Enum.TextXAlignment.Left
luckSub.ZIndex = 11

local road = new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(14, 76), Size = UDim2.new(1, -28, 0, 230), ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 6, ScrollBarImageColor3 = STYLE.purple, CanvasSize = UDim2.fromOffset(Config.LEVEL_MAX * 118 + 20, 0), ZIndex = 10 }, progBody)
local roadLine = new("Frame", { BackgroundColor3 = Color3.fromRGB(60, 50, 90), BorderSizePixel = 0, Position = UDim2.fromOffset(60, 104), Size = UDim2.fromOffset((Config.LEVEL_MAX - 1) * 118, 4), ZIndex = 10 }, road)
local roadFill = new("Frame", { BackgroundColor3 = STYLE.gold, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 11 }, roadLine)
local roadCards = {}
for lv = 1, Config.LEVEL_MAX do
	local c = new("Frame", { Name = "L" .. lv, BackgroundColor3 = Color3.fromRGB(20, 16, 40), BackgroundTransparency = 0.1, Position = UDim2.fromOffset(12 + (lv - 1) * 118, 10), Size = UDim2.fromOffset(100, 196), ZIndex = 12 }, road)
	round(c, 14)
	local st = glowStroke(c, Color3.fromRGB(90, 80, 130), 2, 0.2)
	local num = label(c, tostring(lv), 30, STYLE.text, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 6), UDim2.new(1, 0, 0, 34), STYLE.fontB)
	num.ZIndex = 13
	local gemI = iconImg(c, "icon_gem", UDim2.fromOffset(34, 34), UDim2.new(0.5, -22, 0, 66), nil, 13)
	local gemT = label(c, "+" .. Config.levelGems(lv), 18, STYLE.gem, Vector2.new(0, 0.5), UDim2.new(0.5, -4, 0, 66), UDim2.fromOffset(50, 22), STYLE.fontB)
	gemT.TextXAlignment = Enum.TextXAlignment.Left
	gemT.ZIndex = 13
	local spT = label(c, "+1 SKILL PT", 13, STYLE.blue, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 92), UDim2.new(1, -6, 0, 16), STYLE.fontB)
	spT.ZIndex = 13
	local luckT = label(c, string.format("LUCK +%d%%", math.floor(Config.luck(lv) * 100 + 0.5)), 13, STYLE.gold, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 112), UDim2.new(1, -6, 0, 16), STYLE.fontB)
	luckT.ZIndex = 13
	local special = lv == 3 and "AUTO ROLL" or (lv % 5 == 0 and "MILESTONE" or nil)
	local sp
	if special then
		sp = label(c, special, 13, STYLE.green, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 134), UDim2.new(1, -6, 0, 16), STYLE.fontB)
		sp.ZIndex = 13
		iconImg(c, lv == 3 and "icon_rebirth" or "icon_chest", UDim2.fromOffset(32, 32), UDim2.new(0.5, 0, 0, 170), nil, 13)
	end
	local stateT = label(c, "", 12, STYLE.muted, Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -4), UDim2.new(1, 0, 0, 16), STYLE.fontB)
	stateT.ZIndex = 13
	roadCards[lv] = { frame = c, stroke = st, num = num, state = stateT }
end
local progFoot = label(progBody, "Earn XP:  defeat monsters  ·  clear stages  ·  beat bosses", 16, STYLE.muted, Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -10), UDim2.new(1, -40, 0, 22), STYLE.fontB)
progFoot.ZIndex = 10
local progList = progFoot -- old name kept

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
require(script.Parent:WaitForChild("GCTutSeal"))({ SETTINGS = SETTINGS, STYLE = STYLE, TweenService = TweenService, UI = UI, label = label, new = new, tutCard = tutCard, tutSkip = tutSkip, tutText = tutText })

-- Start screen
-- ===== Start menu (2026-10-28 rework): the world stays visible behind a left-side shade; logo, tagline and a big PLAY
-- on the left; a featured Legendary familiar turns on a glowing pedestal on the right. Same locals as before
-- (startScreen, startCard, startScale, startSub, startBtn) so the flashes notice and the Start flow keep working.
do -- abstract forms for the start menu, panels, tutorial note and banners (needs tutCard, banner, toast above)
	local ok3, err3 = pcall(function() UI.abstractScreens = require(script.Parent:WaitForChild("AbstractScreens", 5))({ gui = gui, hud = hud, tutCard = tutCard, tutText = tutText, banner = banner, subBanner = subBanner, toast = toast, reducedMotion = function() return SETTINGS.reducedMotion end }) end)
	if not ok3 then warn("AbstractScreens: " .. tostring(err3)) end
end
local startScreen = new("Frame", { Name = "StartMenu", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 10 }, gui)
local menuShade = new("Frame", { BackgroundColor3 = Color3.fromRGB(6, 4, 16), BackgroundTransparency = 0, Size = UDim2.fromScale(1, 1), ZIndex = 10 }, startScreen)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.45, 0.35), NumberSequenceKeypoint.new(1, 0.75) }) }, menuShade)
UI.blurHolders[startScreen] = true

-- holder carries the screen-fit scale; the card's own UIScale is left for popIn
local menuHolder = new("Frame", { Name = "MenuHolder", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.07, 0.52), Size = UDim2.fromOffset(470, 420), ZIndex = 11 }, startScreen)
local fitScale = new("UIScale", { Scale = 1 }, menuHolder)
local startCard = new("Frame", { Name = "Menu", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 11 }, menuHolder)
local startScale = new("UIScale", { Scale = 1 }, startCard)
do -- the menu keeps its size relative to the screen height (same rule as the HUD)
	local function fit()
		fitScale.Scale = math.clamp(camera.ViewportSize.Y / 780, 0.6, 1.2)
	end
	fit()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
end
local crownImg = iconImg(startCard, "icon_crown", UDim2.fromOffset(96, 96), UDim2.fromOffset(48, 22), nil, 13)
local logo1 = label(startCard, "GUARDIAN", 64, Color3.fromRGB(255, 226, 150), Vector2.new(0, 0), UDim2.fromOffset(0, 70), UDim2.fromOffset(470, 70), STYLE.display)
local logo2 = label(startCard, "GRID", 92, Color3.fromRGB(255, 200, 90), Vector2.new(0, 0), UDim2.fromOffset(0, 128), UDim2.fromOffset(470, 96), STYLE.display)
for _, l in { logo1, logo2 } do
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextScaled = true
	l.ZIndex = 12
	l.TextStroke.Thickness = 3
	l.TextStroke.Transparency = 0
	l.TextStroke.Color = Color3.fromRGB(40, 18, 6)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 244, 210), Color3.fromRGB(226, 150, 50)) }, l)
end
local startSub = label(startCard, "Summon familiars. Merge three that touch. Hold the lamplit lane.", 20, Color3.fromRGB(214, 206, 236), Vector2.new(0, 0), UDim2.fromOffset(4, 228), UDim2.fromOffset(440, 30), STYLE.fontB)
startSub.TextXAlignment = Enum.TextXAlignment.Left
startSub.ZIndex = 12
local rule = new("Frame", { BackgroundColor3 = STYLE.gold, BorderSizePixel = 0, Position = UDim2.fromOffset(4, 266), Size = UDim2.fromOffset(300, 2), ZIndex = 12 }, startCard)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, rule)

local startBtn = makeButton(startCard, "PLAY", UDim2.fromOffset(300, 84), UDim2.fromOffset(154, 332), STYLE.green)
startBtn.ZIndex = 12
startBtn.TextSize = 40
iconImg(startBtn, "icon_sword", UDim2.fromOffset(54, 54), UDim2.new(0, 42, 0.5, 0), nil, 14)

do -- what's new: a short changelog like Sol's title screen
	local news = pill(startCard, UDim2.fromOffset(300, 112), "News")
	news.Position = UDim2.fromOffset(330, 284) -- right of PLAY, clear of the flashes notice below
	local head = label(news, "WHAT'S NEW", 16, STYLE.gold, Vector2.new(0, 0), UDim2.fromOffset(14, 8), UDim2.fromOffset(270, 20), STYLE.fontB)
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.ZIndex = 13
	local body = label(news, "New look: tarot summons, the brass bell and the pocket-watch ultimate\nTrainer Road: see every level's reward\nSkill tree paths light up as you grow", 14, Color3.fromRGB(210, 204, 230), Vector2.new(0, 0), UDim2.fromOffset(14, 30), UDim2.fromOffset(276, 76), STYLE.fontB)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.ZIndex = 13
	-- the news is a notice pinned to the board: parchment, ink, a red pin, a slight tilt (/make-creative 2026-10-28)
	local g = news:FindFirstChild("Glass")
	if g then g.Visible = false end
	news.BackgroundTransparency = 0
	news.BackgroundColor3 = Color3.fromRGB(232, 218, 186)
	news.Rotation = -2.5
	round(news, 4)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(248, 238, 214), Color3.fromRGB(205, 186, 150)) }, news)
	head.Text, head.TextColor3, head.FontFace = "THE LAMPWICK GAZETTE", Color3.fromRGB(110, 30, 30), UI.TITLE_FONT
	head.TextStroke.Transparency = 1
	body.TextColor3 = Color3.fromRGB(60, 44, 30)
	body.TextStroke.Transparency = 1
	local pin = new("Frame", { BackgroundColor3 = Color3.fromRGB(190, 30, 40), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 2), Size = UDim2.fromOffset(14, 14), ZIndex = 14 }, news)
	round(pin, 7)
end

-- PLAY is "Light the lamp": a brass plate with a gas flame that grows when you hover and flares when you press
do
	UI.objectify(startBtn)
	UI.objImg(startBtn, "plaque", UDim2.new(1, 16, 1, 10), UDim2.fromScale(0.5, 0.5), nil, 11, Enum.ScaleType.Stretch)
	local ic = startBtn:FindFirstChild("Icon")
	if ic then ic.Visible = false end
	local flame = new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://108574647086501", AnchorPoint = Vector2.new(0.5, 0.75), Position = UDim2.new(0, 46, 0.5, 0), Size = UDim2.fromOffset(44, 58), ZIndex = 14 }, startBtn)
	TweenService:Create(flame, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 5 }):Play()
	startBtn.Text = "LIGHT THE LAMP"
	startBtn.TextSize = 30
	local t = startBtn:FindFirstChild("Txt")
	if t then -- text right of the flame (UIPadding does not move the glass skin's text label)
		t.ZIndex = 14
		t.TextColor3 = Color3.fromRGB(255, 224, 150)
		t.Size = UDim2.new(1, -78, 1, 0)
		t.Position = UDim2.fromOffset(72, 0)
	end
	startBtn.MouseEnter:Connect(function() tween(flame, 0.2, { Size = UDim2.fromOffset(60, 80) }, Enum.EasingStyle.Back) end)
	startBtn.MouseLeave:Connect(function() tween(flame, 0.2, { Size = UDim2.fromOffset(44, 58) }) end)
	startBtn.Activated:Connect(function() tween(flame, 0.15, { Size = UDim2.fromOffset(90, 120) }) end)
end

require(script.Parent:WaitForChild("GCFeatured"))({ Config = Config, Models = Models, RunService = RunService, STYLE = STYLE, TweenService = TweenService, label = label, new = new, startScreen = startScreen })
do -- refined start menu (StartMenuArt, 2026-10-28): Beyond Wonderland title, one clean column, lamp plate
	local okM, errM = pcall(function() require(script.Parent:WaitForChild("StartMenuArt", 3))({ startScreen = startScreen, startBtn = startBtn, reduced = function() return SETTINGS.reducedMotion end }) end)
	if not okM then warn("StartMenuArt: " .. tostring(errM)) end
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
require(game.ReplicatedStorage.EnemyPace).enemies = enemies
local liveFx = 0
local dying, flying = {}, {}
local lastSnap = nil
local camZoom = 1
local shake = { t = 0, amp = 0 }
-- Impact kit (ImpactFX, AbilityFX). One table to stay under Luau's 200-local limit; missing modules just skip the extras.
local FXK = { lastRend = 0 }
-- one cutscene at a time: busy while any cutscene holds the camera or a summon reveal covers the screen
function FXK.cineOff() -- the Cutscenes setting (Off) or Reduced Motion
	return SETTINGS.reducedMotion or SETTINGS.cinematics == "off"
end
function FXK.cineShort() -- Short cutscenes, or 2x speed
	return SETTINGS.gameSpeed == 2 or SETTINGS.cinematics == "short"
end
function FXK.busy()
	return FXK.camOverride ~= nil or (FXK.hatchRunning ~= nil and FXK.hatchRunning())
end
-- wait (up to `limit` s) for the screen to be free; true if it is
function FXK.waitFree(limit)
	local t0 = os.clock()
	while FXK.busy() and os.clock() - t0 < limit do task.wait(0.1) end
	return not FXK.busy()
end
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
require(script.Parent:WaitForChild("GCSettingsApply"))({ FXK = FXK, ReplicatedStorage = ReplicatedStorage, RunService = RunService, SETTINGS = SETTINGS, UI = UI, UI_SIZE_MUL = UI_SIZE_MUL, relayout = relayout, script = script })
-- play a SoundFX cue if the module is present (sounds are Studio-preview files until uploaded)
function FXK.play(name, o)
	if FXK.sfx then
		pcall(FXK.sfx.play, name, o or {})
	end
end
UI.play = FXK.play -- for UI code that runs above FXK (tutorial note)
do
	local lastClick = 0
	local function hook(b)
		if not b:IsA("GuiButton") or b:GetAttribute("ClickSfx") == false then return end
		b.Activated:Connect(function()
			if os.clock() - lastClick < 0.05 then return end
			lastClick = os.clock()
			if b == rollBtn then FXK.play("card_flip")
			elseif b == startWaveBtn then FXK.play("bell_toll", { volume = 0.8 })
			else FXK.play("brass_click") end
		end)
	end
	local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, d in pg:GetDescendants() do hook(d) end
	pg.DescendantAdded:Connect(hook)
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

local EnemyBars = require(script.Parent:WaitForChild("EnemyBars"))({ new = new, enemies = enemies, SETTINGS = SETTINGS, tween = tween }) -- T139 readable health bars and status icons
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
	EnemyBars.decorate(enemies[data.id], bb, bg, fill)
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
	if os.clock() - (FXK.lastPoofSfx or 0) > 0.06 then
		FXK.lastPoofSfx = os.clock()
		FXK.play("enemy_poof", { pitch = e.kind == "Boss" and 0.6 or 1 })
	end
	if os.clock() - (FXK.lastCoinSfx or 0) > 0.12 then -- the coins land a beat later
		FXK.lastCoinSfx = os.clock()
		task.delay(0.25, FXK.play, "coin_clink")
	end
	-- a wisp of lamp smoke rises from where it fell
	if not SETTINGS.reducedMotion and liveFx < 30 then
		local wisp = new("Part", { Shape = Enum.PartType.Ball, Anchored = true, CanCollide = false, CanQuery = false, CastShadow = false, Material = Enum.Material.Neon, Color = Color3.fromRGB(215, 210, 255), Transparency = 0.35, Size = Vector3.one * (e.kind == "Boss" and 3 or 1.2), Position = at }, visuals)
		tween(wisp, 0.7, { Position = at + Vector3.new(0, e.kind == "Boss" and 8 or 4.5, 0), Size = wisp.Size * 2.6, Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		Debris:AddItem(wisp, 0.75)
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
	table.insert(dying, { model = e.model, pivot = e.model:GetPivot(), t = 0, spin = e.kind == "Boss" and 4 or 9, hl = e.hl })
	if e.kind == "Boss" then
		screenFlash(Color3.fromRGB(255, 240, 200), 0.6)
		shake.t, shake.amp = 0.5, 2
		if FXK.impact then
			FXK.impact.impactFrame(SETTINGS)
			FXK.impact.scorch(Vector3.new(at.X, GROUND - 0.4, at.Z), 7, 3)
		end
	end
end

require(script.Parent:WaitForChild("GCBossPlate"))({ Config = Config, FXK = FXK, RunService = RunService, TweenService = TweenService, UI = UI, bossBar = bossBar, bossBarBg = bossBarBg, bossBarLabel = bossBarLabel, enemies = enemies, fmt = fmt, new = new, round = round, tween = tween, getSnap = function() return lastSnap end })

local function shotFx(data)
	local e = enemies[data.id]
	local entry = petParts[data.slot]
	if not e or not entry then
		return
	end
	e.hp -= data.dmg
	e.flash = 1
	entry.aim, entry.aimT = e.model:GetPivot().Position, os.clock() -- the familiar turns to face what it shoots
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
	if os.clock() - (FXK.lastHitSfx or 0) > 0.07 then -- hits land audibly, at most about 14 a second
		FXK.lastHitSfx = os.clock()
		task.delay(shotDur, FXK.play, "enemy_hit", { pitch = data.crit and 0.75 or 1 })
	end
	FXK.floatFx.hit(to, data, entry.pet) -- T194: family colour; the Damage numbers setting (T116) is honoured inside
	entry.kick = 1
end

-- ===== Camera: close, Bloons-style three-quarter view, with shake for big moments =====
RunService:BindToRenderStep("GuardianCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FXK.fovOverride or 60 -- cutscenes may key the lens
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
	-- inspect view (2026-10-28): while a familiar's panel is open the camera leans in on it (about a third of the way),
	-- keeping it left of the panel; eases back when the panel closes. Off with Reduced Motion.
	FXK.inspectK = FXK.inspectK or 0
	local want = (FXK.inspect and FXK.inspectPos and not SETTINGS.reducedMotion) and 1 or 0
	FXK.inspectK += (want - FXK.inspectK) * math.min(1, dt * 4)
	if FXK.inspectK > 0.005 and FXK.inspectPos then
		local tp = FXK.inspectPos + Vector3.new(0, 2, 0)
		local icf = CFrame.lookAt(tp + (cf.Position - tp).Unit * 22 + Vector3.new(0, -5, 0), tp + cf.RightVector * 6)
		cf = cf:Lerp(icf, FXK.inspectK * 0.85)
	end
	FXK.gameCF = cf
	-- a signature cutscene drives the camera while it plays
	camera.CFrame = FXK.camOverride or cf
end)

-- Start-menu camera (2026-10-28, after Sol's RNG and the Roblox main-menu tutorials): a street-level shot down the
-- lane that leans a little toward the mouse (clamped parallax), then a 1.2 s sweep into the game view after PLAY.
do
	local UIS = game:GetService("UserInputService")
	local MENU_EYE, MENU_AT = Vector3.new(-58, 9, 62), Vector3.new(4, 3, -2)
	local PARALLAX = 3 -- studs at the screen edge
	local lean, blend, wasMenu, fromCF = Vector2.zero, 1, false, nil
	RunService:BindToRenderStep("MenuCamera", Enum.RenderPriority.Camera.Value + 2, function(dt)
		local menu = startScreen.Visible and not FXK.camOverride
		if menu then
			local vp, m = camera.ViewportSize, UIS:GetMouseLocation()
			local want = Vector2.new(math.clamp((m.X / vp.X - 0.5) * 2, -1, 1), math.clamp((m.Y / vp.Y - 0.5) * 2, -1, 1))
			lean = lean:Lerp(want, math.min(1, dt * 3))
			local base = CFrame.lookAt(MENU_EYE, MENU_AT)
			local cf = base * CFrame.new(lean.X * PARALLAX, -lean.Y * PARALLAX * 0.5, 0)
			cf = CFrame.lookAt(cf.Position, MENU_AT)
			camera.CFrame = cf
			wasMenu, blend, fromCF = true, 0, cf
		elseif wasMenu and blend < 1 and fromCF then
			-- first PLAY of a session: a 4 s establishing crane (high over the rooftops, down along the lane, settle on the
			-- board); later PLAYs and Reduced Motion keep the 1.2 s sweep
			local dur = (FXK.introDone or FXK.cineOff() or FXK.cineShort()) and 1.2 or 4
			blend = math.min(1, blend + dt / dur)
			local e = blend < 0.5 and 4 * blend ^ 3 or 1 - (-2 * blend + 2) ^ 3 / 2
			if dur > 2 then
				local game0 = camera.CFrame
				local p0 = fromCF.Position
				local p1 = Vector3.new(-70, 70, 90) -- above the rooftops, the whole street below
				local p2 = Vector3.new(30, 26, 60)
				local p3 = game0.Position
				local u = 1 - e
				local pos = u ^ 3 * p0 + 3 * u ^ 2 * e * p1 + 3 * u * e ^ 2 * p2 + e ^ 3 * p3
				local tgt = (fromCF.Position + fromCF.LookVector * 40):Lerp(game0.Position + game0.LookVector * 60, e)
				camera.CFrame = CFrame.lookAt(pos, tgt)
			else
				camera.CFrame = fromCF:Lerp(camera.CFrame, 1 - (1 - blend) ^ 3)
			end
			if blend >= 1 then
				wasMenu = false
				FXK.introDone = true
			end
		end
	end)
	startBtn.Activated:Connect(function()
		screenFlash(Color3.new(1, 1, 1), 0.55) -- Sol's ends its title with a flash
	end)
end

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
	FXK.inspect = nil
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
			local fl = pip:FindFirstChild("Flame")
			if fl then -- ledger lamps: lit up to the level
				pip.BackgroundColor3 = p <= level and Color3.fromRGB(120, 70, 20) or Color3.fromRGB(40, 30, 24)
				fl.Visible = p <= level
			else
				pip.BackgroundColor3 = p <= level and STYLE.gold or STYLE.grey
			end
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
		deleteBtn.Text = "Release  (+" .. Config.recycleValue(entry.pet, entry.tier) .. " coins)"
		setButtonColor(deleteBtn, STYLE.red)
	end
end

local function openPanel(slot)
	selectedSlot = slot
	FXK.inspect, FXK.inspectPos = slot, slotPos(slot)
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
	if UI.oddsSpread then UI.oddsSpread(pct) end
end

require(script.Parent:WaitForChild("GCOddsRows"))({ Config = Config, STYLE = STYLE, TweenService = TweenService, UI = UI, glowStroke = glowStroke, label = label, new = new, oddsBody = oddsBody, oddsChip = oddsChip, oddsNote = oddsNote, oddsRows = oddsRows, round = round })

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
	progHead.Text = "TRAINER LEVEL " .. s.level
	local frac = s.level >= Config.LEVEL_MAX and 1 or math.clamp(s.xp / s.xpNeed, 0, 1)
	progXp.Size = UDim2.fromScale(frac, 1)
	progXpText.Text = s.level >= Config.LEVEL_MAX and "MAX LEVEL" or string.format("%s / %s XP", fmt(s.xp), fmt(s.xpNeed))
	local pct = Config.rarityPercents(s.luck)
	luckLine.Text = string.format("LUCK +%d%%", math.floor(s.luck * 100 + 0.5))
	luckSub.Text = string.format("Legendary %.1f%%  ·  Epic %.1f%%", pct.Legendary or 0, pct.Epic or 0)
	for lv, card in roadCards do
		local done, nextUp = lv <= s.level, lv == s.level + 1
		card.frame.BackgroundTransparency = 0 -- opaque so the road line passes behind the cards
		card.frame.BackgroundColor3 = done and Color3.fromRGB(14, 30, 26) or (nextUp and Color3.fromRGB(40, 30, 14) or Color3.fromRGB(20, 16, 40))
		card.stroke.Color = nextUp and STYLE.gold or (done and Color3.fromRGB(110, 200, 150) or Color3.fromRGB(90, 80, 130))
		card.stroke.Thickness = nextUp and 3 or 2
		card.num.TextColor3 = nextUp and STYLE.gold or (done and Color3.fromRGB(170, 230, 190) or STYLE.text)
		card.state.Text = done and "CLAIMED" or (nextUp and "NEXT" or "")
		card.state.TextColor3 = nextUp and STYLE.gold or Color3.fromRGB(120, 200, 150)
	end
	roadFill.Size = UDim2.fromScale(math.clamp((s.level - 1 + frac) / (Config.LEVEL_MAX - 1), 0, 1), 1)
	road.CanvasPosition = Vector2.new(math.max(0, (s.level - 2) * 118), 0)
end

do -- Progression: first-person walk along the Trainer's Road (TrainerRoad module), then the panel opens over it
	local okR, RoadMod = pcall(function() return require(script.Parent:WaitForChild("TrainerRoad", 3)) end)
	local Road = okR and RoadMod and RoadMod({
		Config = Config, settings = SETTINGS, sfx = FXK.play, short = FXK.cineShort,
		setCamera = function(cf) FXK.camOverride = cf end,
		setFov = function(f) FXK.fovOverride = f end,
	}) or nil
	if Road then
		UI.blurHolders[progPanel] = nil -- the road stays sharp behind the panel
	end
	local busy, hidden = false, {}
	local function closeProg()
		if not progPanel.Visible or busy then return end
		hidePanel(progPanel, progScale)
		if Road and next(hidden) then
			busy = true
			task.spawn(function()
				Road.close(function()
					for g in hidden do g.Visible = true end
					table.clear(hidden)
				end)
				busy = false
			end)
		end
	end
	progressBtn.Activated:Connect(function()
		if busy then return end
		if progPanel.Visible then
			closeProg()
			return
		end
		progPanel.Position = UDim2.new(0.5, 0, 0.5, tutCard.Visible and 48 or 0)
		updateProgress()
		if Road and lastSnap and not FXK.cineOff() then
			busy = true
			for _, c in hud:GetChildren() do
				if c:IsA("GuiObject") and c.Visible and c ~= progPanel then
					hidden[c] = true
					c.Visible = false
				end
			end
			task.spawn(function()
				Road.open(lastSnap, function()
					progPanel.Visible = true
					popIn(progScale, 0.85)
				end)
				busy = false
			end)
		else
			UI.intro(gui, STYLE.purple, function()
				progPanel.Visible = true
				popIn(progScale, 0.85)
			end, SETTINGS.reducedMotion)
		end
	end)
	progClose.Activated:Connect(closeProg)
end

do -- settings panel: shell here, content in the SettingsPanel module
	local settingsBtn = railButton("Settings", 6, STYLE.grey)
	if UI.sealButton then UI.sealButton(settingsBtn) end
	UI.SYMS["Settings"] = "star"
	UI.SUBS["Settings"] = "SOUND  ·  DISPLAY  ·  ACCESS"
	local panel, body, scale, close = makePanel(hud, UDim2.fromOffset(440, 560), "Settings", STYLE.blue)
	UI.blurHolders[panel] = true
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 70) -- top-anchored so the reset seal clears the desk at the bottom
	panel:GetPropertyChangedSignal("Visible"):Connect(function() -- the desk steps aside while the board is open
		for _, n in { "RollBar", "Desk" } do
			local d = hud:FindFirstChild(n)
			if d then d.Visible = not panel.Visible end
		end
	end)
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
	do local ev = Instance.new("BindableEvent"); ev.Name = "OpenSettings"; ev.Parent = ReplicatedStorage; ev.Event:Connect(function() if not panel.Visible then UI.intro(gui, STYLE.blue, function() panel.Visible = true; popIn(scale, 0.85) end, SETTINGS.reducedMotion) end end) end -- T097: opened by the pause menu
end

do -- skill tree scope
local lastSp = 0
-- ===== Skill tree: honeycomb of permanent upgrades =====
local SQ3 = math.sqrt(3)
local HEX_R = 48
local HEX_GAP = 1.3 -- room between hexes so the path lines show
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
detail.Size = UDim2.fromOffset(600, 104)
detIcon = new("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(72, 72), ScaleType = Enum.ScaleType.Fit, ZIndex = 15 }, detail)
detPips = {}
for i = 1, 5 do
	local pip = new("Frame", { BackgroundColor3 = Color3.fromRGB(50, 46, 70), Position = UDim2.fromOffset(98 + (i - 1) * 26, 84), Size = UDim2.fromOffset(22, 8), ZIndex = 15 }, detail)
	round(pip, 4)
	detPips[i] = pip
end
local detName = label(detail, "", 24, STYLE.text, Vector2.new(0, 0), UDim2.fromOffset(98, 4), UDim2.new(1, -280, 0, 30))
detName.TextXAlignment = Enum.TextXAlignment.Left
detName.ZIndex = 15
local detDesc = label(detail, "", 15, STYLE.muted, Vector2.new(0, 0), UDim2.fromOffset(98, 34), UDim2.new(1, -280, 0, 20), STYLE.fontB)
detDesc.TextXAlignment = Enum.TextXAlignment.Left
detDesc.ZIndex = 15
local detLevel = label(detail, "", 16, STYLE.gold, Vector2.new(0, 0), UDim2.fromOffset(98, 56), UDim2.new(1, -280, 0, 22), STYLE.fontB)
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
NODE_ICONS = {
	damage = "icon_sword", coins = "icon_coin", crystal = "icon_crystal", ultNeed = "icon_bolt", luck = "icon_star", gems = "icon_gem",
	bossDamage = "icon_skull", merge = "icon_chest", bossTime = "icon_stopwatch", ultDamage = "icon_bolt", rollDiscount = "icon_gem",
	streakGuard = "icon_shield", crit = "icon_sword", xp = "icon_trophy", pity = "icon_crown", ultRefund = "icon_bolt", Start = "icon_crown",
}
-- soft glow behind the tree and faint stars, so the tree sits in a scene instead of on a flat sheet
do
	local g = new("Frame", { BackgroundColor3 = Color3.fromRGB(150, 110, 255), BackgroundTransparency = 0.82, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(620, 520), ZIndex = 13 }, treeArea)
	round(g, 300)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.7, 0.9), NumberSequenceKeypoint.new(1, 1) }) }, g)
	for i = 1, 40 do
		local sz = math.random(2, 4)
		local st = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 236, 200), BackgroundTransparency = 0.4 + math.random() * 0.4, BorderSizePixel = 0, Position = UDim2.fromScale(math.random(), math.random()), Size = UDim2.fromOffset(sz, sz), ZIndex = 13 }, treeGui)
		round(st, 2)
		TweenService:Create(st, TweenInfo.new(1 + math.random() * 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.95 }):Play()
	end
end

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
	local art = iconImg(icon, NODE_ICONS[node.kind] or NODE_ICONS[node.id] or "", UDim2.fromOffset(46, 46), UDim2.fromScale(0.5, 0.5), nil, 19)
	if art then -- painted icon on a dark disc ringed in the skill's colour, instead of a 3-letter code
		code.Visible = false
		icon.BackgroundColor3 = Color3.fromRGB(16, 14, 30)
		icon.Size = UDim2.fromOffset(44, 44)
		round(icon, 22)
		local st = icon:FindFirstChildOfClass("UIStroke")
		if st then st.Color = node.color; st.Transparency = 0; st.Thickness = 2.5 end
	end
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

local treeLinks = {}
for id, ui in nodeUI do
	for _, n in Config.TREE_NEIGHBORS[id] or {} do
		local other = nodeUI[n]
		if other and id < n then
			local dx, dy = other.x - ui.x, other.y - ui.y
			local line = new("Frame", { BackgroundColor3 = Color3.fromRGB(80, 70, 120), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, (ui.x + other.x) / 2, 0.5, (ui.y + other.y) / 2), Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), 5), Rotation = math.deg(math.atan2(dy, dx)), ZIndex = 13 }, treeArea)
			round(line, 3)
			table.insert(treeLinks, { a = id, b = n, line = line })
		end
	end
end
do -- the many-branch magical layout and vibrant backdrop (SkillTreeArt, the user's 2026-10-28 design)
	local okA, errA = pcall(function() UI.treeArt = require(script.Parent:WaitForChild("SkillTreeV3", 3))({ fire = function(...) ActionRemote:FireServer(...) end, treeGui = treeGui, treeArea = treeArea, nodeUI = nodeUI, treeLinks = treeLinks, Config = Config,
		treeTitle = treeTitle, treeSp = treeSp, detail = detail, treeClose = treeClose, reduced = function() return SETTINGS.reducedMotion end,
		buy = function(id) ActionRemote:FireServer("Skill", id) end }) end) -- v2 look: radial lantern tree, ticking brass border, hover popup
	if not okA then warn("SkillTreeArt: " .. tostring(errA)) end
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
	if Grove and treeGui.Visible then
		Grove.refresh(snap)
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
	for _, l in treeLinks do -- paths: gold once both ends are owned, dim while one end is still open
		local sa, sb = nodeState(l.a, snap), nodeState(l.b, snap)
		local ownA = sa == "owned" or sa == "maxed" or sa == "start"
		local ownB = sb == "owned" or sb == "maxed" or sb == "start"
		l.line.Visible = nodeUI[l.a].cont.Visible and nodeUI[l.b].cont.Visible
		l.line.BackgroundColor3 = (ownA and ownB) and STYLE.gold or ((ownA or ownB) and Color3.fromRGB(150, 130, 210) or Color3.fromRGB(60, 54, 90))
		l.line.BackgroundTransparency = (ownA and ownB) and 0 or 0.35
	end
	local node = Config.TREE_BY_ID[selectedNode]
	local state = nodeState(selectedNode, snap)
	local lvl = snap.tree[selectedNode] or 0
	if detIcon then
		detIcon.Image = (UI.art and UI.art.has(NODE_ICONS[node.kind] or NODE_ICONS[node.id] or "") and UI.art.image(NODE_ICONS[node.kind] or NODE_ICONS[node.id])) or ""
		detIcon.Visible = state ~= "locked"
	end
	for i, pip in detPips do
		pip.Visible = state ~= "locked" and state ~= "start" and i <= node.max
		pip.BackgroundColor3 = i <= lvl and node.color or Color3.fromRGB(50, 46, 70)
	end
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
		detLevel.Text = lvl >= node.max and string.format("MAX  ·  %s", fmtEffect(node, node.per * lvl))
			or string.format("Now %s   >   Next %s", lvl > 0 and fmtEffect(node, node.per * lvl) or "none", fmtEffect(node, node.per * (lvl + 1)))
		if state == "maxed" then
			buyBtn.Text = "MAXED"
			setButtonColor(buyBtn, STYLE.gold)
		else
			local cost = Config.skillCost(node, lvl)
			buyBtn.Text = "BUY  " .. cost .. " SP"
			setButtonColor(buyBtn, snap.sp >= cost and STYLE.green or STYLE.grey)
		end
	end
	if UI.treeArt then UI.treeArt.sync(snap) end
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

local groveBusy, groveHidden = false, {}
local function setTreeOpen(open)
	if open == treeGui.Visible or groveBusy then
		return
	end
	if not open then
		hidePanel(treeGui, treeScale)
		if Grove and next(groveHidden) then
			-- walk back out: fade, camera home, then the rest of the HUD returns
			groveBusy = true
			task.spawn(function()
				Grove.close(function()
					for g in groveHidden do g.Visible = true end
					table.clear(groveHidden)
				end)
				groveBusy = false
			end)
		else
			tween(blur, 0.25, { Size = 0 })
		end
		return
	end
	for _, id in { "Claws", "Magnet", "Armor", "Charge", "Charm", "Finder" } do
		if nodeState(id, lastSnap) == "available" and lastSnap.sp >= Config.skillCost(Config.TREE_BY_ID[id], 0) then
			selectedNode = id
			break
		end
	end
	refreshTree()
	treeInit = true
	if Grove and not FXK.cineOff() then
		-- first person: hide the HUD, walk up to the living tree as it grows, then the skill panel opens over it
		groveBusy = true
		for _, c in hud:GetChildren() do
			if c:IsA("GuiObject") and c.Visible and c ~= treeGui then
				groveHidden[c] = true
				c.Visible = false
			end
		end
		treeGui.BackgroundTransparency = 0.62 -- let the grove show behind the hexes
		task.spawn(function()
			Grove.open(lastSnap, function()
				treeGui.Visible = true
				popIn(treeScale, 0.9)
			end)
			groveBusy = false
		end)
	else
		tween(blur, 0.25, { Size = 14 })
		UI.intro(gui, STYLE.blue, function()
			treeGui.Visible = true
			popIn(treeScale, 0.9)
		end, SETTINGS.reducedMotion)
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
Grove = (function() -- first-person walk to the living skill tree (SkillGrove module); nil if it is missing
	local ok, mod = pcall(function() return require(script.Parent:WaitForChild("SkillGrove", 3)) end)
	if not ok or not mod then return nil end
	return mod({
		Config = Config, settings = SETTINGS, sfx = FXK.play, short = FXK.cineShort,
		setCamera = function(cf) FXK.camOverride = cf end,
		setFov = function(f) FXK.fovOverride = f end,
	})
end)()
local Hatch = require(script.Parent.RevealSection)({
	cineLite = function() return FXK.cineOff() or FXK.cineShort() end,
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
FXK.hatchRunning = Hatch.running

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
		local ph = clock * (4 + e.speed * 0.5) + id -- stride rate follows walk speed
		local hop = math.abs(math.sin(ph))
		local pos = Vector3.new(p.X, 0.8 + hop * (e.big and 0.2 or 0.4), p.Z)
		local further = Path.positionAt(math.min(d + 3, Path.length))
		local dir2 = Vector3.new(further.X - ahead.X, 0, further.Z - ahead.Z)
		local turn = (dir.Magnitude > 0.01 and dir2.Magnitude > 0.01) and dir.Unit:Cross(dir2.Unit).Y or 0
		local roll = math.sin(ph) * 0.08 - turn * 0.35 -- sway, and bank into the corner ahead
		local lean = -0.08 - (1 - hop) * 0.07 -- leans into the walk and dips on each landing
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
		e.model:PivotTo(cf * CFrame.Angles(lean, 0, roll))
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
		local k = d.t / 0.46
		if k >= 1 then
			d.model:Destroy()
			table.remove(dying, i)
		else
			local sc, rise, spin = 1, 0, 0
			if k < 0.22 then -- anticipation: it flashes white and swells
				sc = 1 + 0.18 * math.sin(k / 0.22 * math.pi / 2)
			else -- then shrinks, rises and spins away, accelerating
				local b = (k - 0.22) / 0.78
				sc, rise, spin = 1.18 * (1 - b * b), b * b * 3, b * d.spin
			end
			d.model:ScaleTo(math.max(0.05, sc))
			d.model:PivotTo(d.pivot * CFrame.new(0, rise, 0) * CFrame.Angles(0, spin, spin * 0.13))
			if d.hl then
				d.hl.FillColor = Color3.new(1, 1, 1)
				d.hl.FillTransparency = math.clamp(k / 0.5, 0, 1)
			end
		end
	end
	for i = #flying, 1, -1 do
		local f = flying[i]
		f.t += dt
		local k = math.min(1, math.max(0, f.t - (f.delay or 0)) / (f.dur or 0.24))
		local e2 = k * k
		local pos = f.from:Lerp(f.to, f.dur and k or e2) + Vector3.new(0, math.sin(k * math.pi) * (f.arc or 3), 0)
		f.model:PivotTo(CFrame.new(pos) * CFrame.Angles(f.flip and k * math.pi * 2 or 0, math.pi + k * (f.spin or 6), 0))
		f.model:ScaleTo(math.max(0.1, 1 - (f.shrink or 0.6) * e2))
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
		local want = math.pi -- face the camera when idle
		if entry.aim and os.clock() - entry.aimT < 1.4 and not (drag and drag.active and drag.from == slot) then
			local dv = entry.aim - target
			if dv.Magnitude > 0.5 then want = math.atan2(-dv.X, -dv.Z) end
		end
		entry.yaw = entry.yaw or math.pi
		entry.yaw += ((want - entry.yaw + math.pi) % (2 * math.pi) - math.pi) * math.min(1, dt * 12)
		local pivot = CFrame.new(pos) * CFrame.Angles(0, entry.yaw, 0) * CFrame.Angles(entry.kick * 0.22, 0, 0) -- recoil leans back
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
	toggle.BackgroundTransparency = 1 -- brass plate instead of a dark pill
	toggle.TextColor3 = Color3.fromRGB(255, 224, 150)
	local plate = new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://83841573700983", ScaleType = Enum.ScaleType.Stretch, Size = UDim2.new(1, 10, 1, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 12 }, toggle)
	-- children draw over the button's own text, so the text moves to a label above the plate
	local tl = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(0.9, 0.8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), TextScaled = true, Font = STYLE.fontB, TextColor3 = Color3.fromRGB(255, 224, 150), Text = toggle.Text, ZIndex = 13 }, toggle)
	toggle.TextTransparency = 1
	toggle:GetPropertyChangedSignal("Text"):Connect(function() tl.Text = toggle.Text end)
	toggle.Activated:Connect(function()
		local off = SETTINGS.flashes ~= false
		ActionRemote:FireServer("Setting", { flashes = not off, reducedMotion = off and true or SETTINGS.reducedMotion })
		toggle.Text = off and "Flashes: OFF" or "Flashes: ON"
	end)
end
startWaveBtn.Activated:Connect(function()
	local ready = lastSnap and lastSnap.state == "ready"
	ActionRemote:FireServer("StartWave")
	if ready and FXK.bellCut then FXK.bellCut(lastSnap.stage) end
end)
require(script.Parent:WaitForChild("ActionCuts"))({ -- per-action cutscenes live in their own module (script size limit)
	FXK = FXK, SETTINGS = SETTINGS, Config = Config, Path = Path, GROUND = GROUND, camera = camera,
	enemies = enemies, petParts = petParts, groundOf = groundOf, STYLE = STYLE, floatText = floatText, rarityColor = rarityColor, new = new,
	snap = function() return lastSnap end,
	crystal = function() return crystalPart end,
	hitCrystal = function() crystalHit = 1 end,
})

quickBtn.Activated:Connect(function()
	quickRoll = not quickRoll
	quickBtn.Text = quickRoll and "QUICK: ON" or "QUICK: OFF"
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
	UI.setStreak(s.combo, Config.comboMult(s.combo))
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

local mergeCut = require(script.Parent:WaitForChild("GCMergeCut"))({ FXK = FXK, ReplicatedStorage = ReplicatedStorage, SETTINGS = SETTINGS, STYLE = STYLE, burst = burst, camera = camera, floatText = floatText, flying = flying, groundOf = groundOf, pending = pending, petParts = petParts, rarityColor = rarityColor, ring = ring, screenFlash = screenFlash, setPet = setPet, shake = shake, tween = tween })

local BossBar = require(script.Parent:WaitForChild("BossBar"))({ hud = hud, bossBarBg = bossBarBg, STYLE = STYLE, new = new, tween = tween, showBanner = showBanner, showToast = showToast, floatText = floatText, petParts = petParts, groundOf = groundOf, FXK = FXK, SETTINGS = SETTINGS }) -- T149 boss phase bar, deny and freeze feedback
FXK.telegraph = require(script.Parent:WaitForChild("EnemyTelegraph"))({ enemies = enemies, new = new, tween = tween, SETTINGS = SETTINGS, FXK = FXK, Path = Path }) -- T138 one second warning before plant, perch, steal
FXK.floatFx = require(script.Parent:WaitForChild("FloatText"))({ Config = Config, SETTINGS = SETTINGS, STYLE = STYLE, floatText = floatText, fmt = fmt }) -- T194 damage numbers
FXK.hint = require(script.Parent:WaitForChild("PlacementHint"))({ Config = Config, UI = UI, visuals = visuals, getStage = function() return lastSnap and lastSnap.stage or 1 end, selectedPet = function() return selectedSlot and petParts[selectedSlot] and petParts[selectedSlot].pet end, firstPet = function() local _, e = next(petParts) return e and e.pet end }) -- T178 good-tile heat map (H)
FXK.bossFx = require(script.Parent:WaitForChild("BossFx"))({ hud = hud, enemies = enemies, FXK = FXK, SETTINGS = SETTINGS, new = new, tween = tween, shake = shake, ring = ring, screenFlash = screenFlash }) -- T148 boss phase look, cut and sound

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
			if not FXK.tourDone and not FXK.cineOff() then -- first-time captioned camera tour (IntroTour), blended out of the crane
				FXK.tourDone = true
				local okT, Tour = pcall(require, script.Parent:WaitForChild("IntroTour", 2))
				if okT and Tour then
					tutCard.Visible = false
					task.spawn(function() -- at once: the tour blends out of the opening crane (one move, not crane then cut)
						Tour.play({ hud = hud, camera = camera, sfx = FXK.play }, function() tutCard.Visible = tut.active end)
					end)
				end
			end
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
		BossBar.snap(data.boss)
	elseif kind == "Status" then
		EnemyBars.status(data)
	elseif kind == "BossPhase" or kind == "BossFx" then
		BossBar.event(kind, data)
	elseif kind == "Denied" then
		showToast(data.reason or "Can't do that")
		FXK.play("merge_fail", { pitch = 1.25, volume = 0.6 })
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
		mergeCut(data)
	elseif kind == "Move" then
		FXK.pos[data.id] = Vector3.new(data.x, GROUND, data.z)
		if selectedSlot == data.id and petParts[data.id] then
			UI.showRange(slotPos(data.id), Config.PETS[petParts[data.id].pet].range, Color3.fromRGB(235, 240, 255))
		end
		ring(slotPos(data.id), Color3.fromRGB(235, 240, 255), 7, 0.35)
		FXK.play("place_thud")
	elseif kind == "Recycle" then
		local farewell = FXK.recycleCut and FXK.recycleCut(data)
		if not farewell then
			FXK.play("echo", { pitch = 0.9 })
			removePet(data.slot, true)
			floatText(groundOf(data.slot) + Vector3.new(0, 4, 0), "+" .. data.coins, STYLE.gold, 24)
		end
	elseif kind == "Upgrade" then
		if data.level >= Config.UPGRADE_MAX and FXK.maxCut then FXK.maxCut(data) end
		FXK.play("bank")
		task.delay(0.08, FXK.play, "coin_clink", { pitch = 0.9 })
		for slot, e in petParts do
			if e.pet == data.pet then
				burst(groundOf(slot) + Vector3.new(0, 2, 0), STYLE.gold, 8)
				floatText(groundOf(slot) + Vector3.new(0, 6, 0), data.kind .. " " .. data.level, STYLE.green, 20)
			end
		end
	elseif kind == "Spawn" then
		spawnEnemy(data)
		if data.kind == "Boss" then
			if FXK.bossCut then FXK.bossCut(data) end
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
		FXK.play("glass_crack")
		if FXK.leakCut then FXK.leakCut(data) end
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
		if FXK.clearCut then FXK.clearCut(data) end
		showBanner(data.perfect and "PERFECT!" or "STAGE CLEAR", data.perfect and STYLE.green or STYLE.gold, "+" .. data.bonus .. " gems")
	elseif kind == "LevelUp" then
		if FXK.levelCut then FXK.levelCut(data) end
		showBanner("LEVEL UP!  " .. data.level, STYLE.purple, string.format("+%d gems   +1 Skill Point   Luck +%d%%", data.gems, math.floor(data.luck * 100 + 0.5)))
		screenFlash(STYLE.purple, 0.25)
		badgeScale.Scale = 1.6
		tween(badgeScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(xpFill, 0.15, { BackgroundColor3 = Color3.new(1, 1, 1) })
		task.delay(0.2, function() tween(xpFill, 0.4, { BackgroundColor3 = Color3.new(1, 1, 1) }) end)
	elseif kind == "Overrun" then
		if FXK.darkCut then FXK.darkCut("[ OVERRUN · BACK TO STAGE " .. data.stage .. " ]") end
		clearEnemies()
		screenFlash(STYLE.red, 0.4)
		showBanner("OVERRUN!", STYLE.red, string.format("Pushed back to stage %d  (-%s coins)", data.stage, fmt(data.lostCoins)))
	elseif kind == "BossEscaped" then
		if FXK.darkCut then FXK.darkCut("[ THE BOSS ESCAPED · BACK TO STAGE " .. data.stage .. " ]") end
		clearEnemies()
		showBanner("BOSS ESCAPED", STYLE.red, "Back to stage " .. data.stage .. " - streak lost")
	elseif kind == "Ult" then
		-- the caster is the most powerful familiar on the board (the server's Ult event names none)
		local slot, entry, best = nil, nil, -1
		for sl, en in petParts do
			local score = (en.cool or 0) * 10 + (en.tier or 1)
			if score > best then slot, entry, best = sl, en, score end
		end
		local def = entry and Config.PETS[entry.pet]
		-- user, 2026-10-28: the ultimate is always seen in first person; the older signature cutscenes stay in
		-- CutsceneFX for later (def.signature) but every cast now uses the first-person one
		local sig = "FirstPerson"
		if entry and FXK.cut and FXK.cut.signatures[sig] and not FXK.cineOff() and not FXK.busy() then -- busy: the board-view ultimate instead
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
			local allies = {}
			for sl in petParts do
				if sl ~= slot then table.insert(allies, groundOf(sl)) end
			end
			-- repeats get the short cut: full the first two times, then 1.7 s (and always at 2x game speed)
			FXK.ultCasts = (FXK.ultCasts or 0) + 1
			FXK.cut.play(sig, {
				model = entry.model, origin = groundOf(slot), targets = targets, color = rarityColor(entry.pet),
				title = string.upper(def.name), ability = def.signatureName or "ULTIMATE", allies = allies,
				short = FXK.ultCasts > 2 or FXK.cineShort(),
				setCamera = function(cf) FXK.camOverride = cf end,
				setFov = function(f) FXK.fovOverride = f end,
				gameCamera = function() return FXK.gameCF or camera.CFrame end,
				settings = SETTINGS, sfx = FXK.play,
				onHit = function() ultHoldUntil = 0 end, -- enemy deaths show when the orb lands
				onSkip = function() ultHoldUntil = 0; FXK.fovOverride = nil end,
			})
			-- deaths are held until the orb lands (1.9 s full, 1.15 s short), not the whole cutscene
			ultHoldUntil = os.clock() + ((FXK.ultCasts > 2 or FXK.cineShort()) and 1.15 or 1.9)
		else
			playUlt()
		end
	elseif kind == "SkillBought" then
		FXK.play("charge_ready")
		if Grove and lastSnap then
			task.delay(0.1, function() Grove.light(data.id, lastSnap) end) -- after the snapshot carries the new level
		end
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
		FXK.play("milestone")
		showBanner("TUTORIAL COMPLETE", STYLE.green, "+" .. data.gems .. " gems and +" .. data.sp .. " Skill Points! Open the Skill Tree.")
		screenFlash(STYLE.green, 0.3)
		clearHighlights()
		highlightGui(skillsBtn)
		task.delay(8, clearHighlights)
	end
end)

popIn(startScale)
