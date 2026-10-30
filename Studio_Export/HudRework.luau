--!nocheck
-- ReplicatedStorage? No: StarterPlayerScripts.HudRework (ModuleScript), 2026-10-30. HUD rework from Roblox Dev/Design/HUD Rework Brief 2026-10-30.md
-- and Roblox Dev/Research/UI/Refs 2026-10-30/Style Spec.md. GameClient calls it once (flag Config.HUD_REWORK) with the HUD's own objects and gets
-- { snap = fn } back. The real buttons keep their handlers; this module moves them to scale positions, hides their old art and draws a calm one:
-- dark plaques, one gold hairline, Titillium Web, line icons, no constant glow, no odds chip, one currency bar, one top strip, one left bar,
-- the menu button top right, and an ultimate button that shows the familiar who will cast it.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local P = {
	ink = Color3.fromRGB(20, 15, 11), ink2 = Color3.fromRGB(38, 29, 21), gold = Color3.fromRGB(201, 169, 106), goldHi = Color3.fromRGB(236, 208, 144),
	text = Color3.fromRGB(240, 230, 208), mute = Color3.fromRGB(196, 182, 156), rose = Color3.fromRGB(168, 88, 74), roseHi = Color3.fromRGB(222, 122, 106),
	violet = Color3.fromRGB(110, 78, 190), violetLo = Color3.fromRGB(40, 26, 80), cyan = Color3.fromRGB(128, 206, 232),
}
local FONT = Font.new("rbxasset://fonts/families/TitilliumWeb.json", Enum.FontWeight.SemiBold)
local FONTB = Font.new("rbxasset://fonts/families/TitilliumWeb.json", Enum.FontWeight.Bold)
local SPIRAL = "rbxassetid://128142388272489"
local C0 = Vector2.new(0.5, 0.5)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function round(o, r) return new("UICorner", { CornerRadius = UDim.new(r, 0) }, o) end
local function stroke(o, color, th, tr)
	return new("UIStroke", { Color = color, Thickness = th, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize }, o)
end
local function text(parent, str, pos, size, anchor, color, align, font, z)
	local l = new("TextLabel", { Name = "AF_hr_text", BackgroundTransparency = 1, Text = str, FontFace = font or FONT, TextColor3 = color or P.text, TextXAlignment = align or Enum.TextXAlignment.Center, AnchorPoint = anchor or C0, Position = pos, Size = size, ZIndex = z or 6 }, parent)
	l:SetAttribute("KeepFont", true)
	l.TextWrapped = true
	l.TextScaled = true
	new("UITextSizeConstraint", { MaxTextSize = 44, MinTextSize = 14 }, l)
	return l
end
local function ibox(parent, x, y, h, z) -- square holder: both sides are a fraction of the parent's height
	return new("Frame", { Name = "AF_hr_icon", BackgroundTransparency = 1, AnchorPoint = C0, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(h, h), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = z or 5 }, parent)
end
local function dot(h, x, y, d, color, z)
	local f = new("Frame", { Name = "AF_hr_dot", BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = C0, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(d, d), ZIndex = z or 6 }, h)
	round(f, 0.5)
	return f
end
local function ring(h, x, y, d, color, th, z)
	local f = new("Frame", { Name = "AF_hr_ring", BackgroundTransparency = 1, AnchorPoint = C0, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(d, d), ZIndex = z or 6 }, h)
	round(f, 0.5)
	return f, stroke(f, color, th or 0.08)
end
local function bar(h, x1, y1, x2, y2, th, color, z)
	local dx, dy = x2 - x1, y2 - y1
	return new("Frame", { Name = "AF_hr_line", BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = C0, Position = UDim2.fromScale((x1 + x2) / 2, (y1 + y2) / 2), Size = UDim2.fromScale(math.sqrt(dx * dx + dy * dy), th), Rotation = math.deg(math.atan2(dy, dx)), ZIndex = z or 6 }, h)
end
-- hyperrealistic brass art (ComfyUI FLUX renders, UI Kit/art/hud_art/final, uploaded 2026-10-30); nil id = the flat fallback below
-- round 11 (hud-design): baked brass plates (UI Kit/art/make_brass_bake.py: bevelled rim, twisted rope, whiplash coils, rivets, recessed enamel or amber glass)
local BK = { plate = "rbxassetid://107915370915613", panel = "rbxassetid://129023355926061", roll = "rbxassetid://123188401890303", disc = "rbxassetid://135420478773352" }
local ART = {
	wide = { id = BK.plate, c = Rect.new(80, 80, 432, 112), top = 80, k = 0.42 },
	tall = { id = BK.plate, c = Rect.new(80, 80, 432, 112), top = 80, k = 0.42 },
	roll = { id = BK.roll, stretch = true },
	ring = { id = BK.disc },
	panel = { id = BK.panel, c = Rect.new(120, 120, 392, 392), top = 120, k = 0.16 },
	glow = { id = "rbxassetid://122630907915085" },
}
local function brass(parent, kind, z)
	local a = ART[kind]
	if a.vine then
		local base = new("Frame", { Name = "AF_hr_velvet", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AnchorPoint = C0, Position = UDim2.fromScale(0.5, 0.5), Size = a.amber and UDim2.fromScale(0.84, 0.56) or UDim2.fromScale(0.93, kind == "tall" and 0.97 or 0.74), ZIndex = (z or 1) + (a.amber and 2 or 0) }, parent)
		round(base, 0.34)
		stroke(base, P.gold, 0.035, 0.45)
		new("UIGradient", { Rotation = 90, Color = a.amber and ColorSequence.new(Color3.fromRGB(255, 206, 120), Color3.fromRGB(214, 128, 52)) or ColorSequence.new(Color3.fromRGB(78, 54, 42), Color3.fromRGB(28, 19, 26)) }, base)
	end
	local im = new("ImageLabel", { Name = "AF_hr_img", BackgroundTransparency = 1, Image = a.id, ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = a.vine and 0.4 or 0, ScaleType = Enum.ScaleType.Slice, SliceCenter = a.c, Size = UDim2.fromScale(1, 1), ZIndex = (z or 1) + 1 }, parent)
	if a.stretch then im.ScaleType = Enum.ScaleType.Stretch return im end
	local function f() im.SliceScale = math.max(0.04, (a.k or 0.2) * math.min(im.AbsoluteSize.X, im.AbsoluteSize.Y) / a.top) end
	im:GetPropertyChangedSignal("AbsoluteSize"):Connect(f)
	f()
	return im
end
-- steampunk accents (ComfyUI brass art, round 8): slow cogs on one linear tween each, steam puffs on press. Ids filled by the art upload; "" = skipped.
local GEAR = { big = "rbxassetid://74207288462160", small = "rbxassetid://103653817949934", gauge = "rbxassetid://132728809319640", pipe = "rbxassetid://97064932194117", chain = "rbxassetid://122061789218481" }
local function gear(parent, key, x, y, d, secs, dir, z, tint)
	if GEAR[key] == "" then return nil end
	local function one(name, pos, col, tr, zz)
		return new("ImageLabel", { Name = name, BackgroundTransparency = 1, Image = GEAR[key], ImageColor3 = col, ImageTransparency = tr, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromScale(d, d), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = zz, Active = false }, parent)
	end
	local sh = one("AF_hr_gearshadow", UDim2.new(x, 2, y, 4), Color3.new(0, 0, 0), 0.45, (z or 8) - 1)
	local h = one("AF_hr_gear", UDim2.fromScale(x, y), tint or Color3.new(1, 1, 1), 0, z or 8)
	if secs then
		h.Rotation = math.random(0, 359)
		sh.Rotation = h.Rotation
		for _, o in { h, sh } do
			TweenService:Create(o, TweenInfo.new(secs, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = h.Rotation + 360 * (dir or 1) }):Play()
		end
	end
	return h
end
local function puff(parent, x, y)
	for i = 1, 3 do
		local p = new("ImageLabel", { Name = "AF_hr_puff", BackgroundTransparency = 1, Image = "rbxassetid://122630907915085", ImageColor3 = Color3.fromRGB(240, 236, 228), ImageTransparency = 0.45, AnchorPoint = C0, Position = UDim2.fromScale(x + (i - 2) * 0.03, y), Size = UDim2.fromOffset(18, 18), ZIndex = 20, Active = false }, parent)
		TweenService:Create(p, TweenInfo.new(0.7 + i * 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromScale(x + (i - 2) * 0.06, y - 0.5), Size = UDim2.fromOffset(52, 52), ImageTransparency = 1 }):Play()
		task.delay(1.2, function() p:Destroy() end)
	end
end
local function plaque(parent, name, pos, size, anchor, tr, corner, kind)
	local f = new("Frame", { Name = name, AnchorPoint = anchor or Vector2.zero, Position = pos, Size = size, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = tr or 0.1, BorderSizePixel = 0, ZIndex = 2 }, parent)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(P.ink2, P.ink) }, f)
	if ART[kind or "wide"] and ART[kind or "wide"].id ~= "" then
		f.BackgroundTransparency = 1
		local A = ART[kind or "wide"]
		if A.vine then -- ink (or lantern-amber) velvet under the transparent middle of the vine art, a still warm halo, no pulsing
			new("ImageLabel", { Name = "AF_hr_halo", BackgroundTransparency = 1, Image = ART.glow.id, ImageColor3 = Color3.fromRGB(255, 178, 84), ImageTransparency = A.amber and 0.55 or 0.86, AnchorPoint = C0, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.22, 1.7), ZIndex = 0 }, f)
			brass(f, kind or "wide", 2)
			new("UIStroke", { Enabled = false }, f)
			return f
		end
		local sh = new("ImageLabel", { Name = "AF_hr_shadow", BackgroundTransparency = 1, Image = ART.glow.id, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.35, AnchorPoint = C0, Position = UDim2.fromScale(0.5, 0.58), Size = UDim2.fromScale(1.12, 1.35), ZIndex = 0 }, f)
		brass(f, kind or "wide")
		new("UIStroke", { Enabled = false }, f)
	else
		round(f, corner or 0.16)
		stroke(f, P.gold, 0.03, 0.3)
	end
	return f
end

-- twenty ultimate glyphs, one per familiar role (unit square; l line, o ring, d dot)
local GLYPH = {
	Scorch = { { "l", .5, .12, .3, .55 }, { "l", .5, .12, .7, .55 }, { "o", .5, .64, .4 }, { "d", .5, .66, .14 } },
	Reveal = { { "l", .12, .5, .5, .27 }, { "l", .5, .27, .88, .5 }, { "l", .12, .5, .5, .73 }, { "l", .5, .73, .88, .5 }, { "d", .5, .5, .22 } },
	Harry = { { "l", .18, .75, .38, .25 }, { "l", .4, .75, .6, .25 }, { "l", .62, .75, .82, .25 } },
	Breach = { { "l", .15, .5, .85, .5 }, { "l", .62, .27, .85, .5 }, { "l", .62, .73, .85, .5 }, { "d", .2, .5, .12 } },
	Chill = { { "l", .5, .12, .5, .88 }, { "l", .17, .31, .83, .69 }, { "l", .17, .69, .83, .31 }, { "d", .5, .5, .12 } },
	Crush = { { "l", .5, .15, .5, .85 }, { "l", .22, .28, .78, .28 }, { "l", .28, .85, .72, .85 } },
	Ward = { { "l", .5, .12, .2, .28 }, { "l", .5, .12, .8, .28 }, { "l", .2, .28, .28, .68 }, { "l", .8, .28, .72, .68 }, { "l", .28, .68, .5, .88 }, { "l", .72, .68, .5, .88 } },
	Hasten = { { "l", .2, .22, .47, .5 }, { "l", .2, .78, .47, .5 }, { "l", .52, .22, .79, .5 }, { "l", .52, .78, .79, .5 } },
	Hush = { { "o", .5, .5, .76 }, { "l", .3, .5, .7, .5 } },
	Echo = { { "d", .5, .5, .14 }, { "o", .5, .5, .42 }, { "o", .5, .5, .72 } },
	Starfall = { { "l", .72, .12, .72, .44 }, { "l", .56, .28, .88, .28 }, { "l", .64, .4, .2, .86 } },
	Drain = { { "l", .18, .22, .82, .22 }, { "l", .18, .22, .5, .84 }, { "l", .82, .22, .5, .84 }, { "d", .5, .45, .12 } },
	Hymn = { { "d", .38, .72, .2 }, { "l", .47, .72, .47, .18 }, { "l", .47, .18, .72, .34 } },
	Rewind = { { "o", .5, .5, .76 }, { "l", .5, .5, .5, .26 }, { "l", .5, .5, .68, .6 } },
	Kindle = { { "l", .5, .42, .5, .88 }, { "d", .5, .24, .2 }, { "l", .36, .88, .64, .88 } },
	Veil = { { "l", .15, .2, .85, .2 }, { "l", .27, .2, .2, .82 }, { "l", .5, .2, .5, .82 }, { "l", .73, .2, .8, .82 } },
	Whistle = { { "o", .4, .56, .48 }, { "l", .62, .42, .88, .42 }, { "d", .4, .56, .12 } },
	Annotate = { { "l", .22, .84, .76, .22 }, { "l", .76, .22, .86, .42 }, { "l", .76, .22, .56, .16 } },
	Lockstep = { { "o", .5, .5, .5 }, { "o", .5, .5, .2 }, { "l", .5, .1, .5, .25 }, { "l", .5, .75, .5, .9 }, { "l", .1, .5, .25, .5 }, { "l", .75, .5, .9, .5 } },
	Crossing = { { "l", .15, .56, .85, .56 }, { "l", .26, .56, .4, .76 }, { "l", .74, .56, .6, .76 }, { "l", .4, .76, .6, .76 }, { "l", .5, .56, .5, .16 } },
	_none = { { "o", .5, .5, .6 }, { "d", .5, .5, .14 } },
}
local function glyph(h, name, color)
	for _, p in GLYPH[name] or GLYPH._none do
		if p[1] == "l" then bar(h, p[2], p[3], p[4], p[5], 0.075, color)
		elseif p[1] == "o" then ring(h, p[2], p[3], p[4], color, 0.09)
		else dot(h, p[2], p[3], p[4], color) end
	end
end

-- line icons for the controls
local ICON = {
	tree = function(h, c) bar(h, .5, .82, .5, .5, .07, c) bar(h, .5, .5, .24, .24, .07, c) bar(h, .5, .5, .76, .24, .07, c) dot(h, .5, .84, .2, c) dot(h, .22, .22, .2, c) dot(h, .78, .22, .2, c) end,
	steps = function(h, c) for i = 1, 3 do local top = .72 - i * .2 local f = new("Frame", { Name = "AF_hr_line", BackgroundColor3 = c, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(.1 + (i - 1) * .27, .86), Size = UDim2.fromScale(.2, .86 - top - .14), ZIndex = 6 }, h) end end,
	dial = function(h, c) ring(h, .5, .5, .62, c, .09) dot(h, .5, .5, .16, c) for i = 0, 7 do local a = math.rad(i * 45) bar(h, .5 + .38 * math.sin(a), .5 - .38 * math.cos(a), .5 + .48 * math.sin(a), .5 - .48 * math.cos(a), .07, c) end end,
	menu = function(h, c) for i = 0, 2 do bar(h, .18, .26 + i * .24, .82, .26 + i * .24, .09, c) end end,
	auto = function(h, c) ring(h, .5, .5, .68, c, .09) dot(h, .5, .16, .17, c) end,
	quick = function(h, c) bar(h, .16, .22, .44, .5, .09, c) bar(h, .16, .78, .44, .5, .09, c) bar(h, .5, .22, .78, .5, .09, c) bar(h, .5, .78, .78, .5, .09, c) end,
	coin = function(h, c) local d = dot(h, .5, .5, .86, c) ring(h, .5, .5, .5, P.ink, .12) end,
	gem = function(h, c) local d = new("Frame", { Name = "AF_hr_dot", BackgroundColor3 = c, BorderSizePixel = 0, AnchorPoint = C0, Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(.62, .62), Rotation = 45, ZIndex = 6 }, h) bar(h, .27, .27, .73, .73, .06, P.ink) end,
	crystal = function(h, c) local d = new("Frame", { Name = "AF_hr_dot", BackgroundColor3 = c, BorderSizePixel = 0, AnchorPoint = C0, Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(.6, .6), Rotation = 45, ZIndex = 6 }, h) end,
}
local function play(h, color, hollow) -- a triangle: a square turned 45 degrees, clipped to its left half
	local clip = new("Frame", { Name = "AF_hr_tri", BackgroundTransparency = 1, ClipsDescendants = true, AnchorPoint = C0, Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(.5, 1), ZIndex = 6 }, h)
	local sq = new("Frame", { Name = "AF_hr_sq", BackgroundColor3 = color, BackgroundTransparency = hollow and 1 or 0, BorderSizePixel = 0, AnchorPoint = C0, Position = UDim2.fromScale(0, .5), Size = UDim2.fromScale(1.414, .707), Rotation = 45, ZIndex = 6 }, clip)
	local st = stroke(sq, color, .08)
	st.Enabled = hollow and true or false
	return sq, st
end

return function(env)
	local Config, SETTINGS = env.Config, env.SETTINGS
	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera
	local hud = env.hud
	local reduced = function() return SETTINGS and SETTINGS.reducedMotion end
	local M = {}
	function M.skinPanel(panel) -- baked brass frame (9-slice) with one slow gear; the glass frame under it is hidden so there is one border, not two
		for _, c in panel:GetChildren() do
			if c:IsA("GuiObject") and c:IsA("ImageLabel") and not c.Name:match("^AF_hr") then c.Visible = false end
		end
		local im = new("ImageLabel", { Name = "AF_hr_frame", BackgroundTransparency = 1, Image = ART.panel.id, ScaleType = Enum.ScaleType.Slice, SliceCenter = ART.panel.c, AnchorPoint = C0, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 24, 1, 24), ZIndex = 4, Active = false }, panel)
		local function f() im.SliceScale = math.max(0.04, 150 / ART.panel.top * math.min(1, im.AbsoluteSize.X / 600)) end
		im:GetPropertyChangedSignal("AbsoluteSize"):Connect(f)
		f()
		gear(panel, "big", 0.015, 0.02, 0.12, 60, 1, 9)
		local function drop(c) -- PanelCard's card and crest draw a second border; the brass frame replaces them
			if c.Name == "Card" or c.Name == "Crest" then task.defer(function() c.Visible = false end) end
		end
		for _, c in panel:GetChildren() do drop(c) end
		panel.ChildAdded:Connect(drop)
	end
	local mine = {} -- frames this module lays out each half second: { obj, pos, size, anchor }

	local function place(o, pos, size, anchor)
		table.insert(mine, { o, pos, size, anchor })
	end
	local function topY() return camera.ViewportSize.Y < 600 and 0.12 or 0.07 end

	-- hide what a button used to draw, keep its handler and its badge
	local keep = {}
	local function ours(c) return c.Name:match("^AF_hr") ~= nil end
	local function skin(b)
		for _, c in b:GetChildren() do
			if c:IsA("GuiObject") and not ours(c) and not keep[c] then c.Visible = false
			elseif c:IsA("UIStroke") or c:IsA("UIGradient") then c.Enabled = false end
		end
		for _, c in b:GetChildren() do if c:IsA("UIPadding") then c:Destroy() end end
		b.BackgroundTransparency = 1
		if b:IsA("TextButton") then b.TextTransparency = 1 end
		b.ChildAdded:Connect(function(c)
			task.defer(function()
				if c.Parent == b and c:IsA("GuiObject") and not ours(c) and not keep[c] then c.Visible = false end
			end)
		end)
		return new("Frame", { Name = "AF_hr_skin", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, b)
	end
	local function mirror(src, dst, fmt)
		local function f() dst.Text = fmt and fmt(src.Text) or src.Text end
		src:GetPropertyChangedSignal("Text"):Connect(f)
		f()
	end
	local function hide(o) if o then o.Visible = false end end

	local blank = Instance.new("Frame")
	blank.BackgroundTransparency = 1
	for _, b in { env.rollBtn, env.autoBtn, env.quickBtn, env.startWaveBtn, env.ultBtn } do b.SelectionImageObject = blank end

	-- ===== old pieces off =====
	hide(env.rail) hide(env.stagePill) hide(env.hpPill) hide(env.oddsChip)
	if env.oddsChip then env.oddsChip.Active = false end

	-- ===== currency bar and level (top left, below Roblox's own buttons) =====
	local cur = plaque(hud, "AF_hr_Currency", UDim2.fromScale(0.012, 0.07), UDim2.fromScale(0.235, 0.12), Vector2.zero)
	place(cur, UDim2.fromScale(0.012, 0.07), UDim2.fromScale(0.235, 0.12), Vector2.zero)
	do
		local c1 = ibox(cur, 0.15, 0.34, 0.3) ICON.coin(c1, P.gold)
		local t1 = text(cur, "0", UDim2.fromScale(0.2, 0.34), UDim2.fromScale(0.26, 0.3), Vector2.new(0, 0.5), P.text, Enum.TextXAlignment.Left, FONTB)
		mirror(env.coinLabel, t1)
		new("Frame", { Name = "AF_hr_div", ZIndex = 5, BackgroundColor3 = P.gold, BackgroundTransparency = 0.6, BorderSizePixel = 0, AnchorPoint = C0, Position = UDim2.fromScale(0.52, 0.34), Size = UDim2.fromScale(0.006, 0.26) }, cur)
		local c2 = ibox(cur, 0.6, 0.34, 0.3) ICON.gem(c2, P.cyan)
		local t2 = text(cur, "0", UDim2.fromScale(0.65, 0.34), UDim2.fromScale(0.28, 0.3), Vector2.new(0, 0.5), P.text, Enum.TextXAlignment.Left, FONTB)
		mirror(env.gemLabel, t2)
	end
	local lvl = new("Frame", { Name = "AF_hr_Level", BackgroundTransparency = 1, AnchorPoint = C0, Position = UDim2.fromScale(0.5, 0.68), Size = UDim2.fromScale(0.82, 0.26), ZIndex = 5 }, cur)
	do
		local t = text(lvl, "LV 1", UDim2.fromScale(0.0, 0.5), UDim2.fromScale(0.26, 1), Vector2.new(0, 0.5), P.goldHi, Enum.TextXAlignment.Left, FONTB)
		mirror(env.lvlNum, t, function(s) return "LV " .. s end)
		local track = new("Frame", { Name = "AF_hr_track", ZIndex = 5, BackgroundColor3 = Color3.fromRGB(10, 7, 5), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.26, 0.5), Size = UDim2.fromScale(0.46, 0.2) }, lvl)
		round(track, 0.5)
		stroke(track, P.gold, 0.18, 0.1)
		local fill = new("Frame", { Name = "AF_hr_fill", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, track)
		round(fill, 0.5)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 226, 150), Color3.fromRGB(176, 118, 40)) }, fill)
		local shine = new("Frame", { Name = "AF_hr_shine", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.7, BorderSizePixel = 0, Position = UDim2.fromScale(0.03, 0.12), Size = UDim2.fromScale(0.94, 0.25), ZIndex = 3 }, track)
		round(shine, 0.5)
		local xt = text(lvl, "", UDim2.fromScale(0.99, 0.5), UDim2.fromScale(0.26, 0.8), Vector2.new(1, 0.5), P.text, Enum.TextXAlignment.Right)
		local function sync()
			fill.Size = UDim2.fromScale(math.clamp(env.xpFill.Size.X.Scale, 0, 1), 1)
			xt.Text = env.xpLabel and env.xpLabel.Text or ""
		end
		env.xpFill:GetPropertyChangedSignal("Size"):Connect(sync)
		if env.xpLabel then env.xpLabel:GetPropertyChangedSignal("Text"):Connect(sync) end
		sync()
	end

	-- ===== top strip: stage and crystal life =====
	local top = plaque(hud, "AF_hr_Top", UDim2.fromScale(0.5, 0.015), UDim2.fromScale(0.34, 0.08), Vector2.new(0.5, 0))
	place(top, UDim2.fromScale(0.5, 0.015), UDim2.fromScale(0.34, 0.08), Vector2.new(0.5, 0))
	do
		local st = text(top, "STAGE 1", UDim2.fromScale(0.06, 0.5), UDim2.fromScale(0.24, 0.5), Vector2.new(0, 0.5), P.goldHi, Enum.TextXAlignment.Left, FONTB)
		local boss = false
		local function ss()
			local t = env.stageLabel.Text
			st.Text = t:upper()
			boss = t:upper():find("BOSS") ~= nil
			st.TextColor3 = boss and P.roseHi or P.goldHi
		end
		env.stageLabel:GetPropertyChangedSignal("Text"):Connect(ss)
		ss()
		new("Frame", { Name = "AF_hr_div", ZIndex = 5, BackgroundColor3 = P.gold, BackgroundTransparency = 0.6, BorderSizePixel = 0, AnchorPoint = C0, Position = UDim2.fromScale(0.33, 0.5), Size = UDim2.fromScale(0.004, 0.5) }, top)
		local ci = ibox(top, 0.385, 0.5, 0.5) ICON.crystal(ci, P.gold)
		gear(top, "gauge", 0.385, 0.5, 0.95, nil, 1, 9)
		local track = new("Frame", { Name = "AF_hr_track", ZIndex = 5, BackgroundColor3 = Color3.fromRGB(10, 7, 5), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.43, 0.5), Size = UDim2.fromScale(0.35, 0.3) }, top)
		round(track, 0.5)
		stroke(track, P.gold, 0.14, 0.1)
		local fill = new("Frame", { Name = "AF_hr_fill", BackgroundColor3 = P.gold, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, track)
		round(fill, 0.5)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 226, 150), Color3.fromRGB(176, 118, 40)) }, fill)
		local shine = new("Frame", { Name = "AF_hr_shine", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.7, BorderSizePixel = 0, Position = UDim2.fromScale(0.03, 0.12), Size = UDim2.fromScale(0.94, 0.25), ZIndex = 3 }, track)
		round(shine, 0.5)
		local ht = text(top, "", UDim2.fromScale(0.93, 0.5), UDim2.fromScale(0.16, 0.5), Vector2.new(1, 0.5), P.text, Enum.TextXAlignment.Right, FONTB)
		local function sh()
			local f = math.clamp(env.hpFill.Size.X.Scale, 0, 1)
			fill.Size = UDim2.fromScale(f, 1)
			fill.BackgroundColor3 = f < 0.3 and P.roseHi or Color3.new(1, 1, 1)
			ht.Text = env.hpLabel.Text
		end
		env.hpFill:GetPropertyChangedSignal("Size"):Connect(sh)
		env.hpLabel:GetPropertyChangedSignal("Text"):Connect(sh)
		sh()
	end
	local streak = hud:FindFirstChild("Streak")
	if streak then place(streak, UDim2.fromScale(0.5, 0.085), nil, nil) end

	-- ===== left bar: three tiles =====
	local dock = env.dock
	dock.BackgroundTransparency = 1
	brass(dock, "tall", -1)
	for _, c in dock:GetChildren() do if c:IsA("UIListLayout") or c:IsA("UIGridLayout") then c:Destroy() end end
	local ORDER = { "Skill Tree", "Progression", "Settings" }
	local CAPTION = { ["Skill Tree"] = "SKILL TREE", Progression = "LEVELS", Settings = "SETTINGS" }
	local ICONFN = { ["Skill Tree"] = ICON.tree, Progression = ICON.steps, Settings = ICON.dial }
	local tiles = {}
	local function dockTile(t)
		if tiles[t] or not t:IsA("Frame") then return end
		local fn = ICONFN[t.Name]
		if not fn then return end
		tiles[t] = true
		local b = t:FindFirstChildWhichIsA("GuiButton")
		if not b then return end
		for _, c in b:GetChildren() do
			if c:IsA("Frame") and c.Size == UDim2.fromOffset(26, 26) then -- the skill-point badge is information, keep it
				keep[c] = true
				c.AnchorPoint, c.Position, c.Size, c.SizeConstraint = C0, UDim2.fromScale(0.76, 0.24), UDim2.fromScale(0.24, 0.24), Enum.SizeConstraint.RelativeXX
				c.ZIndex = 9
				c.BackgroundColor3 = P.rose
			end
		end
		for _, c in t:GetChildren() do if c:IsA("TextLabel") then c.Visible = false end end
		local sk = skin(b)
		local hl = new("Frame", { Name = "AF_hr_hl", BackgroundColor3 = P.gold, BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = C0, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.92), ZIndex = 1 }, sk)
		round(hl, 0.1)
		local icon = ibox(sk, 0.5, 0.4, 0.44) fn(icon, P.gold)
		text(sk, CAPTION[t.Name], UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.96, 0.2), C0, P.text, Enum.TextXAlignment.Center, FONTB)
		b.MouseEnter:Connect(function() TweenService:Create(hl, TweenInfo.new(0.12), { BackgroundTransparency = 0.88 }):Play() end)
		b.MouseLeave:Connect(function() TweenService:Create(hl, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play() end)
		b.Size, b.Position, b.AnchorPoint = UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Vector2.zero
		t.ClipsDescendants = false
	end
	local function dockLayout()
		local n = 0
		for _, name in ORDER do
			local t = dock:FindFirstChild(name)
			if t then
				dockTile(t)
				t.AnchorPoint, t.Size, t.Position = Vector2.zero, UDim2.fromScale(0.8, 0.88 / #ORDER), UDim2.fromScale(0.1, 0.06 + 0.88 * n / #ORDER)
				local b = t:FindFirstChildWhichIsA("GuiButton")
				if b then b.Size, b.Position, b.AnchorPoint = UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Vector2.zero end
				n += 1
			end
		end
	end
	place(dock, UDim2.fromScale(0.012, 0.3), UDim2.fromScale(0.075, 0.44), Vector2.zero)

	-- ===== menu button, top right =====
	local menuDone = false
	local function menuTile()
		local t = hud:FindFirstChild("Menu")
		if not t or menuDone then return end
		local b = t:FindFirstChildWhichIsA("GuiButton")
		if not b then return end
		menuDone = true
		for _, c in t:GetChildren() do if c:IsA("TextLabel") then c.Visible = false end end
		t.BackgroundTransparency = 1
		local sk = skin(b)
		local pl = plaque(sk, "AF_hr_plate", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Vector2.zero)
		local ic = ibox(pl, 0.5, 0.36, 0.42) ICON.menu(ic, P.gold)
		text(pl, "MENU", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.9, 0.2), C0, P.text, Enum.TextXAlignment.Center, FONTB)
		b.Size, b.Position, b.AnchorPoint = UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Vector2.zero
		place(t, UDim2.fromScale(0.988, 0.02), UDim2.fromScale(0.068, 0.11), Vector2.new(1, 0))
	end

	-- ===== bottom: AUTO  ROLL  QUICK =====
	local rb = env.rollBtn.Parent
	rb.Size, rb.Position, rb.AnchorPoint = UDim2.fromScale(0.5, 0.14), UDim2.fromScale(0.5, 0.985), Vector2.new(0.5, 1)
	place(rb, UDim2.fromScale(0.5, 0.985), UDim2.fromScale(0.52, 0.16), Vector2.new(0.5, 1))
	local function toggle(b, label, iconFn, x)
		local sk = skin(b)
		local pl = plaque(sk, "AF_hr_plate", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Vector2.zero)
		local st = pl:FindFirstChildOfClass("UIStroke")
		local ic = ibox(pl, 0.27, 0.5, 0.42) iconFn(ic, P.mute)
		local nm = text(pl, label, UDim2.fromScale(0.45, 0.36), UDim2.fromScale(0.45, 0.32), Vector2.new(0, 0.5), P.mute, Enum.TextXAlignment.Left, FONTB)
		local state = text(pl, "OFF", UDim2.fromScale(0.45, 0.7), UDim2.fromScale(0.45, 0.32), Vector2.new(0, 0.5), P.mute, Enum.TextXAlignment.Left, FONTB)
		local orbit = ic:FindFirstChild("AF_hr_dot")
		local function sync()
			local on = b.Text:find("ON") ~= nil
			local col = on and P.goldHi or P.mute
			nm.TextColor3, state.TextColor3, state.Text = col, col, on and "ON" or "OFF"
			st.Color, st.Transparency = on and P.goldHi or P.gold, on and 0 or 0.45
			for _, d in ic:GetChildren() do
				if d.Name == "AF_hr_dot" then d.BackgroundColor3 = col elseif d.Name == "AF_hr_ring" then d:FindFirstChildOfClass("UIStroke").Color = col elseif d.Name == "AF_hr_line" then d.BackgroundColor3 = col end
			end
			local im = pl:FindFirstChild("AF_hr_img")
			if im then im.ImageColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(150, 140, 130) else pl.BackgroundColor3 = on and Color3.fromRGB(255, 240, 205) or Color3.new(1, 1, 1) end
			ic:SetAttribute("on", on)
		end
		b:GetPropertyChangedSignal("Text"):Connect(sync)
		sync()
		b.AnchorPoint = Vector2.new(x, 0.5)
		place(b, UDim2.fromScale(x, 0.5), UDim2.fromScale(0.2, 0.64), Vector2.new(x, 0.5))
		return ic
	end
	local autoIcon = toggle(env.autoBtn, "AUTO", ICON.auto, 0)
	toggle(env.quickBtn, "QUICK", ICON.quick, 1)
	local rollGlow
	do
		local b = env.rollBtn
		local sk = skin(b)
		local pl = plaque(sk, "AF_hr_plate", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Vector2.zero, 0.04, 0.2, "roll")
		rollGlow = pl:FindFirstChildOfClass("UIStroke")
		local disc = ibox(pl, 0.2, 0.5, 0.7)
		local d = dot(disc, 0.5, 0.5, 1, P.ink, 3)
		stroke(d, P.gold, 0.05, 0.2)
		new("ImageLabel", { Name = "AF_hr_bezel", BackgroundTransparency = 1, Image = ART.ring.id, AnchorPoint = C0, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.12, 1.12), ZIndex = 6 }, disc) -- baked brass bezel round the spiral
		local sp = new("ImageLabel", { Name = "AF_hr_spiral", BackgroundTransparency = 1, Image = SPIRAL, ImageColor3 = P.text, AnchorPoint = C0, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78), ZIndex = 7 }, disc)
		M.spiral = sp
		text(pl, "ROLL", UDim2.fromScale(0.6, 0.4), UDim2.fromScale(0.5, 0.34), C0, Color3.fromRGB(46, 24, 8), Enum.TextXAlignment.Center, FONTB)
		local cost = text(pl, "", UDim2.fromScale(0.6, 0.64), UDim2.fromScale(0.5, 0.2), C0, Color3.fromRGB(70, 36, 10), Enum.TextXAlignment.Center, FONTB)
		M.cost = cost
		if env.rollCost then mirror(env.rollCost, cost) end
		b.AnchorPoint = C0
		place(b, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.46, 1), C0)
		b.Activated:Connect(function() M.spin = 1 puff(rb, 0.5, 0.1) end)
			gear(pl, "big", 0.04, 0.12, 0.62, 48, 1, 9)
	end

	-- ===== bottom right: BEGIN THE WAVE and the ultimate =====
	do
		local b = env.startWaveBtn
		local sk = skin(b)
		local pl = plaque(sk, "AF_hr_plate", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Vector2.zero)
		local ic = ibox(pl, 0.22, 0.5, 0.4)
		local sq, st = play(ic, P.goldHi, false)
		local t1 = text(pl, "BEGIN", UDim2.fromScale(0.36, 0.38), UDim2.fromScale(0.5, 0.34), Vector2.new(0, 0.5), P.goldHi, Enum.TextXAlignment.Left, FONTB)
		local t2 = text(pl, "THE WAVE", UDim2.fromScale(0.36, 0.7), UDim2.fromScale(0.5, 0.3), Vector2.new(0, 0.5), P.mute, Enum.TextXAlignment.Left, FONT)
		local function sync()
			local ready = b.Text:find("START") ~= nil
			sq.BackgroundTransparency = ready and 0 or 1
			st.Enabled = not ready
			t1.Text, t2.Text = ready and "BEGIN" or "RUNNING", ready and "THE WAVE" or "wave in progress"
			t1.TextColor3 = ready and P.goldHi or P.mute
		end
		b:GetPropertyChangedSignal("Text"):Connect(sync)
		sync()
		place(b, UDim2.fromScale(0.985, 0.905), UDim2.fromScale(0.15, 0.1), Vector2.new(1, 0.5))
			b.Activated:Connect(function() puff(hud, 0.93, 0.86) end)
	end
	local ultSkin
	do
		local b = env.ultBtn
		local sk = skin(b)
		local disc = dot(sk, 0.5, 0.5, 0.74, Color3.fromRGB(96, 52, 78), 1)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(130, 82, 70), Color3.fromRGB(34, 18, 36)) }, disc)
		local ringIm = new("ImageLabel", { Name = "AF_hr_img", BackgroundTransparency = 1, Image = ART.ring.id, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, sk)
		local pts = {}
		for i = 1, 24 do
			local a = (i - 1) / 24 * math.pi * 2
			pts[i] = dot(sk, 0.5 + 0.285 * math.sin(a), 0.5 - 0.285 * math.cos(a), 0.03, P.mute, 5)
		end
		local gh = new("Frame", { Name = "AF_hr_glyph", BackgroundTransparency = 1, AnchorPoint = C0, Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.34, 0.34), ZIndex = 6 }, sk)
		local tag = text(sk, "ULT", UDim2.fromScale(0.5, 0.7), UDim2.fromScale(0.42, 0.14), C0, P.text, Enum.TextXAlignment.Center, FONTB)
		local name = text(b, "", UDim2.fromScale(0.5, -0.12), UDim2.fromScale(1.2, 0.2), C0, P.text, Enum.TextXAlignment.Center, FONTB)
		name.BackgroundTransparency, name.BackgroundColor3 = 1, P.ink
		name:GetPropertyChangedSignal("Text"):Connect(function() name.BackgroundTransparency = name.Text == "" and 1 or 0.2 end)
		round(name, 0.3)
		name.Name = "AF_hr_caster"
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.SizeConstraint = Enum.SizeConstraint.RelativeYY
		place(b, UDim2.fromScale(0.836, 0.905), UDim2.fromScale(0.12, 0.12), Vector2.new(1, 0.5))
		local state = { role = nil, color = P.gold, frac = 0, ready = false }
		function ultSkin()
			local lit = math.floor(state.frac * 24 + 0.5)
			for i, p in pts do
				p.BackgroundColor3 = i <= lit and state.color or P.mute
				p.BackgroundTransparency = i <= lit and 0 or 0.55
			end
			for _, c in gh:GetChildren() do c:Destroy() end
			glyph(gh, state.role or "_none", state.ready and state.color or state.color:Lerp(P.mute, 0.5))
			ringIm.ImageColor3 = state.ready and Color3.new(1, 1, 1) or Color3.fromRGB(175, 165, 155)
			tag.Text = state.ready and "READY" or "ULT"
			tag.TextColor3 = state.ready and state.color or P.text
			name.Text = state.name or ""
		end
		M.ultState = state
		ultSkin()
	end

	-- ===== the familiar who will cast the ultimate: highest tier, then rarity (the server's rule, MatchSim.castUlt) =====
	local roleOf = {}
	pcall(function()
		for _, f in require(game:GetService("ReplicatedStorage").Shared.Familiars).list do roleOf[f.charId or f.id] = f.role end
	end)
	local lastKey
	function M.snap(s)
		if not s then return end
		local st = M.ultState
		local best, bestPet = -1, nil
		for _, u in s.grid or {} do
			local def = Config.PETS[u.pet]
			if def then
				local sc = (u.tier or 1) * 10 + ((Config.RARITIES[def.rarity] or { order = 0 }).order or 0)
				if sc > best then best, bestPet = sc, u.pet end
			end
		end
		local def = bestPet and Config.PETS[bestPet]
		st.frac = math.clamp(s.ult / math.max(1, s.ultNeed), 0, 1)
		st.ready = s.ult >= s.ultNeed
		local key = tostring(bestPet) .. tostring(math.floor(st.frac * 24 + 0.5)) .. tostring(st.ready)
		if key == lastKey then
			if M.cost then M.cost.TextColor3 = s.gems >= s.rollCost and Color3.fromRGB(70, 36, 10) or Color3.fromRGB(150, 20, 20) end
			return
		end
		lastKey = key
		st.role = bestPet and roleOf[bestPet] or nil
		st.color = def and def.color or P.gold
		st.name = def and def.name:upper() or ""
		ultSkin()
		if M.cost then M.cost.TextColor3 = s.gems >= s.rollCost and Color3.fromRGB(70, 36, 10) or Color3.fromRGB(150, 20, 20) end
	end

	-- ===== quiet motion: the roll spiral turns slowly, the AUTO dot orbits while on =====
	local a = 0
	RunService.RenderStepped:Connect(function(dt)
		if reduced() then return end
		a += dt
		M.spin = math.max(0, (M.spin or 0) - dt * 1.5)
		if M.spiral then M.spiral.Rotation = (M.spiral.Rotation + dt * (14 + 500 * M.spin)) % 360 end
		if autoIcon and autoIcon:GetAttribute("on") then
			local d = autoIcon:FindFirstChild("AF_hr_dot")
			if d then d.Position = UDim2.fromScale(0.5 + 0.34 * math.sin(a * 2.5), 0.5 - 0.34 * math.cos(a * 2.5)) end
		end
	end)

	-- ===== FAMILIARS (the collection button, built by CollectionScreen) under the left bar, same plaque style =====
	local fam
	local function famButton()
		if fam and fam.Parent then return fam end
		local g = player.PlayerGui:FindFirstChild("Collection")
		local b = g and g:FindFirstChild("Open")
		if not b then return nil end
		fam = b
		b:SetAttribute("KeepFont", true)
		for _, c in b:GetChildren() do if c:IsA("UIStroke") or c:IsA("UIGradient") then c:Destroy() end end
		b.AutoButtonColor, b.BackgroundColor3, b.BackgroundTransparency, b.FontFace, b.TextColor3 = false, Color3.new(1, 1, 1), 1, FONTB, P.text
		brass(b, "wide", 0)
		b.TextScaled = true
		new("UITextSizeConstraint", { MaxTextSize = 30, MinTextSize = 8 }, b)
		local ic = b:FindFirstChildOfClass("UICorner") or round(b, 0.2)
		ic.CornerRadius = UDim.new(0.2, 0)
		b.Text = "FAMILIARS"
		b.TextTransparency = 1
		local ot = b:FindFirstChild("OpenText")
		if ot then ot:SetAttribute("KeepFont", true) ot.FontFace, ot.TextColor3, ot.AnchorPoint, ot.Position, ot.Size = FONTB, P.text, C0, UDim2.fromScale(0.6, 0.5), UDim2.fromScale(0.68, 0.56) end
		local fi = ibox(b, 0.15, 0.5, 0.5)
		ICON.crystal(fi, P.gold)
		return b
	end

	-- ===== layout, re-applied every half second (GameClient and ScreenRouter also place these) =====
	local function layout()
		local ty = topY()
		cur.Position = UDim2.fromScale(0.012, ty)
				dock.Position = UDim2.fromScale(0.012, ty + 0.27)
		for _, m in mine do
			local o, pos, size, anchor = m[1], m[2], m[3], m[4]
			if o.Parent then
				if o == cur then pos = UDim2.fromScale(0.012, ty) elseif o == dock then pos = UDim2.fromScale(0.012, ty + 0.27) end
				if o.Position ~= pos then o.Position = pos end
				if size and o.Size ~= size then o.Size = size end
				if anchor and o.AnchorPoint ~= anchor then o.AnchorPoint = anchor end
			end
		end
		dockLayout()
		menuTile()
		local fb = famButton()
		if fb then
			local rv = hud.Parent and hud.Parent:FindFirstChild("Reveal")
			fb.Text, fb.TextTransparency = "", 1
			fb.Visible = hud.Visible and not (rv and rv.Visible) and (dock.Visible or fb:GetAttribute("PanelOpen") == true)
			fb.AnchorPoint, fb.Position, fb.Size = Vector2.zero, UDim2.fromScale(0.012, ty + 0.27 + 0.44 + 0.012), UDim2.fromScale(0.075, 0.055)
		end
		hide(env.rail) hide(env.stagePill) hide(env.hpPill) hide(env.oddsChip)
		for _, c in hud:GetChildren() do -- the abstract layer's leftover lines and points
			if c:IsA("Frame") and c.Visible and ((c.Name:match("^Abs_") or c.Name == "AF_bannerline") or (c.Name == "Frame" and c.AbsoluteSize.X <= 12 and c.AbsoluteSize.Y <= 12 and not c:FindFirstChildWhichIsA("GuiObject"))) then c.Visible = false end
		end
		local hp = player.PlayerGui:FindFirstChild("HudPolish") -- the old contrast plates (they stayed behind as empty frames when a panel opened)
		if hp then hp:Destroy() end
	end
	task.spawn(function()
		while hud.Parent do layout() task.wait(0.5) end
	end)
	layout()

	-- Settings body: the rows add up to more than the panel, so they scroll (GameClient passes the panel body through this)
	function M.scrollBody(body)
		local sc = new("ScrollingFrame", { Name = "AF_hr_scroll", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -30), CanvasSize = UDim2.fromScale(0, 1), ScrollBarThickness = 4, ScrollBarImageColor3 = P.gold, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 8 }, body)
		local inner = new("Frame", { Name = "Inner", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 8 }, sc)
		inner.DescendantAdded:Connect(function(d) -- slider knobs become small brass bosses (the baked disc), not flat web dots
			if d:IsA("Frame") then
				task.defer(function()
					if d.Size ~= UDim2.fromScale(0.09, 2.6) or d:FindFirstChild("AF_hr_knob") then return end
					d.BackgroundTransparency = 1
					for _, c in d:GetChildren() do if c:IsA("UIStroke") then c.Enabled = false end end
					new("ImageLabel", { Name = "AF_hr_knob", BackgroundTransparency = 1, Image = ART.ring.id, AnchorPoint = C0, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.5, 1.5), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = d.ZIndex + 1 }, d)
				end)
			end
		end)
		-- children scale against the canvas, not the window, so the inner frame is pinned to the window height in pixels
		local list
		local function f()
			local h = sc.AbsoluteWindowSize.Y
			if h <= 0 then return end
			inner.Size = UDim2.new(1, 0, 0, h)
			sc.CanvasSize = UDim2.fromOffset(0, math.max(h, list and list.AbsoluteContentSize.Y + 12 or h))
		end
		sc:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(f)
		inner.ChildAdded:Connect(function(c)
			if c:IsA("UIListLayout") then
				list = c
				c:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(f)
				f()
			end
		end)
		f()
		return inner
	end
	return M
end
