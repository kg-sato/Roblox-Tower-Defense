--!nocheck
-- LoadingScreen (LocalScript in ReplicatedFirst). Replaces Roblox's default loading screen with ours.
-- v4 (2026-10-28, the user: "higher quality... the eyes very detailed like the future character references, the clocks
-- more steampunk, the tree an actual high quality one instead of pixels, the font like Beyond Wonderland"): painted
-- art replaces the drawn shapes. Brass pocket-watch faces with gears form the tunnel; the title is an image in
-- Beyond Wonderland that smears in; the tree is a painted tree of light that assembles from glitching slices; the
-- eyes are etched eyes with clockwork irises that open through a widening slit. Art: UI Kit/art/make_menu_art.py + render_title.py,
-- ids in ART below (this script runs before ReplicatedStorage is ready, so it can't use ReplicatedStorage.ArtIds).
-- v3 (2026-10-28): the seal and light shafts are replaced by the clock tunnel and the tree / eyes / vortex finale
-- below (the user's design). v2 (2026-10-28, from the user's reference set 2: Bit Tensei, Fishing Master, Prehistoric Farm, neildegracce; see
-- Roblox Dev/Research/UI/Loading, Intro and UI References 2.md):
--   * a seal at the centre: two squares turning against each other inside three rings, eight points on the outer
--     ring and a breathing amber core; every line has a faint, thicker ghost copy so it glows (duplicate-for-glare)
--   * two warm light shafts drift slowly across the dark field, with gold motes
--   * the title arrives letter by letter, each letter dropping in with two fading echo copies (kinetic type)
--   * the progress line's head is our moth (a point with two beating line wings) flying along it
--   * status and rotating tips; when loading ends, the seal ignites: the rings fly outward and the screen opens
-- Real progress: ContentProvider queue + game.Loaded, with a minimum display time (pattern per
-- https://create.roblox.com/docs/players/loading-screens). Reduced motion is not known yet at this point (settings load
-- later), so motion here stays slow and short.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local MIN_TIME = 3.0 -- seconds: long enough for the title to land, short enough not to annoy
local GOLD, GOLD_DIM, INK = Color3.fromRGB(255, 214, 120), Color3.fromRGB(150, 110, 50), Color3.fromRGB(8, 6, 18)
local AMBER, VIOLET, PALE = Color3.fromRGB(255, 176, 70), Color3.fromRGB(150, 110, 230), Color3.fromRGB(236, 228, 255)
local SERIF = Font.new("rbxasset://fonts/families/AccanthisADFStd.json", Enum.FontWeight.Bold)
local ART = {
	title = "rbxassetid://136306198395346", clock = "rbxassetid://83067528514085", gear = "rbxassetid://115869383084851",
	tree = "rbxassetid://135946607416458", ring = "rbxassetid://127862980270309", treeGlitch = "rbxassetid://126424928512371", rays = "rbxassetid://112008873412775", socket = "rbxassetid://133137332599356", iris = "rbxassetid://123781250890962", glow = "rbxassetid://122630907915085", pupilDisc = "rbxassetid://76589767635756", irisInE = "rbxassetid://117521992225366", irisOutE = "rbxassetid://131055110018506",
}
task.spawn(function() -- fetch the art first thing; the tunnel fades its faces in, so a late image never pops
	local list = {}
	for _, id in ART do table.insert(list, id) end
	pcall(function() ContentProvider:PreloadAsync(list) end)
end)
local STATUS = { "Lighting the gas lamps", "Waking the familiars", "Paving Lampwick Lane", "Polishing the crystal", "Almost there" }
local TIPS = {
	"Three familiars that touch merge into a stronger one.",
	"A perfect stage grows your streak and multiplies the gems you earn.",
	"Drag a familiar to move it; drop it on a twin to merge.",
	"Bosses escape if the timer runs out: keep your strongest near the end of the lane.",
	"Skill points come from level-ups, bosses and the tutorial.",
}

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in props do i[k] = v end
	i.Parent = parent
	return i
end
local function tw(i, t, p, style, dir)
	local x = TweenService:Create(i, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), p)
	x:Play()
	return x
end
local function spin(i, secs)
	TweenService:Create(i, TweenInfo.new(math.abs(secs), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = i.Rotation + (secs > 0 and 360 or -360) }):Play()
end

local gui = new("ScreenGui", { Name = "LoadingScreen", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 200, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))
local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BorderSizePixel = 0 }, gui)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 20, 10)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(14, 9, 6)), ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 3, 3)) }) }, bg)
ReplicatedFirst:RemoveDefaultLoadingScreen() -- after our gui is up, so there is no blank frame

-- texture pass (2026-10-28, measured: references have texture in their darks and one hue family; ours was flat black
-- with five mixed hues). FrameArt paints these at runtime (EditableImage, no uploads); without it the screen keeps
-- the plain look.
local FA
pcall(function()
	local m = game:GetService("ReplicatedStorage"):WaitForChild("FrameArt", 4)
	FA = m and require(m)
	if FA and not FA.ok then FA = nil end
end)
local function art(content, props, parent)
	local i = new("ImageLabel", { BackgroundTransparency = 1, ImageContent = content }, parent)
	for k, v in props do i[k] = v end
	return i
end
local nebulae = {}
if FA then
	for i, spec in { { 0.25, 0.3, 0.9, 1 }, { 0.78, 0.62, 1.0, 2 }, { 0.5, 0.42, 0.7, 3 } } do -- warm dust clouds, slowly drifting
		local n = art(FA.nebula(Color3.fromRGB(150, 70, 20), Color3.fromRGB(255, 180, 90), spec[4]), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(spec[1], spec[2]), Size = UDim2.fromScale(spec[3], spec[3] * 1.6), ImageTransparency = 0.25, ZIndex = 1 }, bg)
		TweenService:Create(n, TweenInfo.new(14 + i * 3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.fromScale(spec[1] + 0.05, spec[2] - 0.04), Rotation = (i % 2 == 0 and 8 or -8) }):Play()
		nebulae[i] = n
	end
	art(FA.rays(), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1.02), Size = UDim2.fromScale(1.3, 1.1), ImageColor3 = Color3.fromRGB(255, 190, 110), ImageTransparency = 0.72, ZIndex = 1 }, bg)
	art(FA.vignette(), { Size = UDim2.fromScale(1, 1), ZIndex = 28 }, bg)
	art(FA.grain(), { Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(128, 128), ImageTransparency = 0.82, ZIndex = 29 }, bg)
end

-- drifting motes (cheap: 26 frames tweened upward, looping)
for _ = 1, 26 do
	local s = math.random(2, 5)
	local m = new("Frame", { BackgroundColor3 = GOLD, BackgroundTransparency = 0.35, BorderSizePixel = 0, Size = UDim2.fromOffset(s, s), Position = UDim2.fromScale(math.random(), math.random()), ZIndex = 2 }, bg)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, m)
	task.spawn(function()
		local first = true
		while m.Parent do
			local x = first and m.Position.X.Scale or math.random()
			if not first then m.Position = UDim2.fromScale(x, 1.05) end
			first = false
			m.BackgroundTransparency = 0.2 + math.random() * 0.6
			local t = 6 + math.random() * 6
			tw(m, t, { Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.1, -0.05) }, Enum.EasingStyle.Linear)
			task.wait(t)
		end
	end)
end

-- 2026-10-28 night (the user: "more fog / effects during the whole thing so it's more mysterious"): banks of fog drift
-- across the screen the whole time in two layers, behind the tunnel and low in front of everything but the vignette,
-- and roll in thick for the great eye at the end. Texture: Roblox's built-in smoke puff.
local FOG = "rbxasset://textures/particles/smoke_main.dds"
local fog = {}
for i = 1, 24 do
	local front, mid = i > 11, i > 18
	local f = new("ImageLabel", { BackgroundTransparency = 1, Image = FOG, ImageColor3 = front and Color3.fromRGB(150, 160, 190) or Color3.fromRGB(125, 110, 125), ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromScale(0.6 + math.random() * 0.5, 0.45 + math.random() * 0.35), ZIndex = front and 27 or 5 }, bg)
	fog[i] = { img = f, x = math.random() * 1.4 - 0.2, y = mid and 0.2 + math.random() * 0.6 or front and 0.78 + math.random() * 0.3 or 0.1 + math.random() * 0.85, v = (0.02 + math.random() * 0.03) * (i % 2 == 0 and 1 or -1), base = mid and 0.7 or front and 0.66 or 0.5, ph = math.random() * 6 }
	tw(f, 2, { ImageTransparency = fog[i].base })
end
local swirlV, suckV = Instance.new("NumberValue"), Instance.new("NumberValue") -- the finale's whirlpool (0 = off)
local fogConn = RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	local sw, k = swirlV.Value, 1 - suckV.Value
	for _, F in fog do
		F.x = (F.x + F.v * dt + 0.4) % 1.8 - 0.4 -- drift, wrapping off one side and back on the other
		local px, py = F.x, F.y + math.sin(t * 0.3 + F.ph) * 0.02
		local a = 0
		if sw > 0 then -- the fog turns around the eye, inner banks faster, and is drawn in (counter-clockwise)
			local dx, dy = px - 0.5, py - 0.5
			a = -sw / (0.3 + math.sqrt(dx * dx + dy * dy))
			px, py = 0.5 + (dx * math.cos(a) - dy * math.sin(a)) * k, 0.5 + (dx * math.sin(a) + dy * math.cos(a)) * k
		end
		F.img.Position = UDim2.fromScale(px, py)
		F.img.Rotation = math.sin(t * 0.1 + F.ph) * 10 + math.deg(a)
	end
end)
gui.Destroying:Connect(function() fogConn:Disconnect() end)

-- v3 (2026-10-28, the user's decision): travelling through time. The main effect is a tunnel of brass clock faces
-- rushing toward the viewer (each face grows from the centre, turns, and fades as it passes). See the finale below for
-- the tree, the eyes and the vortex.
local tunnel = new("Frame", { Name = "Tunnel", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromScale(1, 1), ZIndex = 3 }, bg)
new("UIAspectRatioConstraint", { AspectRatio = 1 }, tunnel)
local light = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.16, 0.16), BackgroundColor3 = Color3.fromRGB(255, 236, 190), ZIndex = 3 }, tunnel)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, light)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.3, 0.85), NumberSequenceKeypoint.new(1, 1) }) }, light) -- soft: v3a read as a solid disc
light:FindFirstChildOfClass("UIGradient").Rotation = 90
if FA then -- the painted glow falls off smoothly; the frame disc had a visible edge
	light.BackgroundTransparency = 1
	light = art(FA.glow(), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.55, 0.55), ImageColor3 = Color3.fromRGB(255, 214, 150), ZIndex = 3 }, tunnel)
	art(FA.glow(), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.16, 0.16), ImageColor3 = Color3.new(1, 1, 1), ZIndex = 3 }, tunnel)
end
TweenService:Create(light, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromScale(light:IsA("ImageLabel") and 0.68 or 0.2, light:IsA("ImageLabel") and 0.68 or 0.2) }):Play()
local faces = {}
for f = 1, 7 do
	-- v4: a painted brass pocket-watch face (gears showing through) with a gear turning behind every other one
	local face = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.1, 0.1), BackgroundTransparency = 1, ZIndex = 4 }, tunnel)
	local gear = f % 2 == 0 and new("ImageLabel", { BackgroundTransparency = 1, Image = ART.gear, ImageColor3 = Color3.fromRGB(220, 190, 150), ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.5), ZIndex = 4 }, face) or nil -- concentric (layout audit 2026-10-29)
	local img = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.ring, ImageTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4 }, face) -- open centre: the tunnel shows depth
	local hands = {} -- v4: the painted face has its own hands; the whole face turns instead
	faces[f] = { face = face, img = img, gear = gear, hands = hands, z = (f - 1) / 7, dir = f % 2 == 0 and -1 or 1 }
end
local tunnelSpeed = 0.16 -- faces per second (fraction of the tunnel); rises with progress so the fall accelerates
-- round 3 (review: "no falling feel"): speed lines stream outward from the centre, faster as the fall speeds up,
-- and each clock face drags a fading motion-blur copy behind it
local streaks = {}
for k = 1, 28 do
	local a = k / 28 * math.pi * 2 + math.random() * 0.2
	local l = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Color3.fromRGB(255, 226, 170), BorderSizePixel = 0, Rotation = math.deg(a), Size = UDim2.fromScale(0.0, 0.003), ZIndex = 5 }, tunnel)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 1) }) }, l)
	streaks[k] = { f = l, a = a, r = math.random(), sp = 0.6 + math.random() * 0.8 }
end
for _, F in faces do
	F.blur = F.img:Clone()
	F.blur.ZIndex = 3
	F.blur.Parent = F.face
end
local tunnelConn = RunService.RenderStepped:Connect(function(dt)
	for _, F in faces do
		F.z += dt * tunnelSpeed
		if F.z >= 1 then F.z -= 1 end
		local s = 0.06 * 40 ^ F.z -- exponential growth reads as depth
		F.face.Size = UDim2.fromScale(s, s)
		F.face.Rotation += dt * 14 * F.dir
		local fade = math.clamp(F.z * 6, 0, 1) * math.clamp((1 - F.z) * 3, 0, 1) -- fade in from the centre, out as it passes
		local t = 1 - fade * 0.85
		F.img.ImageTransparency = t
		F.blur.Size = UDim2.fromScale(0.86, 0.86) -- the copy trails a step behind (smaller = further back) and fainter
		F.blur.Position = UDim2.fromScale(0.07, 0.07)
		F.blur.ImageTransparency = math.min(1, t + 0.45)
		if F.gear then F.gear.ImageTransparency = math.min(1, t + 0.25); F.gear.Rotation -= dt * 40 * F.dir end
	end
	for _, S in streaks do
		S.r += dt * S.sp * (0.5 + tunnelSpeed * 3)
		if S.r > 1 then S.r -= 1 end
		local r0 = 0.06 + S.r ^ 2 * 0.7
		S.f.Position = UDim2.fromScale(0.5 + math.cos(S.a) * r0, 0.5 + math.sin(S.a) * r0)
		S.f.Size = UDim2.fromScale(0.04 + S.r * 0.25 * (0.5 + tunnelSpeed), 0.003)
		S.f.BackgroundTransparency = 1 - math.sin(S.r * math.pi) * 0.6
	end
end)
-- v4 title: the Beyond Wonderland image. Ink spreads left to right (a gradient wipe) while two echo copies slide in
-- from above-left and fade (the smear); a dark band behind keeps it readable over the clock faces.
-- 2026-10-29 (the user: "move it", after the audit showed the gold title, bar and status drawn over the gold clock
-- tunnel): the text moves into a dark panel along the bottom, under the tunnel, and the tunnel rides higher (0.36)
local textPanel = new("Frame", { Name = "TextPanel", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1, 0.34), BackgroundColor3 = Color3.fromRGB(6, 4, 3), BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 5 }, bg)
local panelGrad = new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.12), NumberSequenceKeypoint.new(1, 0.05) }) }, textPanel)
local titleRow = new("Frame", { Name = "Title", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.79), Size = UDim2.fromScale(0.5, 0.118), BackgroundTransparency = 1, ZIndex = 6 }, bg)
new("UIAspectRatioConstraint", { AspectRatio = 4.3 }, titleRow)
local band = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.5, 1.1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6 }, titleRow) -- review: the band read cheap; a shadow copy below does the job
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0), NumberSequenceKeypoint.new(0.75, 0), NumberSequenceKeypoint.new(1, 1) }) }, band)
local titleImg = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.title, Size = UDim2.fromScale(1, 1), ZIndex = 8 }, titleRow)
local shadow = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.title, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.25, Position = UDim2.fromScale(0.004, 0.05), Size = UDim2.fromScale(1, 1), ZIndex = 7 }, titleRow)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.45, 0), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1) }), Offset = Vector2.new(-1, 0) }, shadow)
task.delay(0.35, function() tw(shadow.UIGradient, 1.1, { Offset = Vector2.new(0.6, 0) }, Enum.EasingStyle.Sine) end)
local wipe = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.45, 0), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1) }), Offset = Vector2.new(-1, 0) }, titleImg)
task.delay(0.35, function() tw(wipe, 1.1, { Offset = Vector2.new(0.6, 0) }, Enum.EasingStyle.Sine) end)
for k = 1, 2 do
	local e = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.title, Position = UDim2.fromScale(-0.04 * k, -0.25 * k), Size = UDim2.fromScale(1, 1), ImageTransparency = 1, ZIndex = 7 }, titleRow)
	task.delay(0.35 + k * 0.08, function()
		e.ImageTransparency = 0.45 + k * 0.15
		tw(e, 0.9, { Position = UDim2.fromScale(0, 0), ImageTransparency = 1 }, Enum.EasingStyle.Quint)
	end)
end
local TITLE = "" -- v3's per-letter drop below no longer runs (empty title); kept so the finale code stays the same
for i = 1, #TITLE do
	local ch = TITLE:sub(i, i)
	local slot = new("Frame", { Size = UDim2.fromScale(ch == " " and 0.03 or 0.052, 1), BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 6 }, titleRow)
	if ch ~= " " then
		local letters = {}
		for k = 0, 2 do -- k = 0 is the letter; 1 and 2 are its echoes
			local l = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, -0.9 - k * 0.35), Size = UDim2.fromScale(1.5, 1.5), BackgroundTransparency = 1, Text = ch, TextScaled = true, Font = Enum.Font.GrenzeGotisch, TextColor3 = GOLD, TextTransparency = 1, ZIndex = 7 - k }, slot)
			if k == 0 then
				new("UIStroke", { Color = Color3.fromRGB(40, 20, 8), Thickness = 2, Transparency = 1 }, l)
				new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 240, 200), Color3.fromRGB(230, 160, 60)) }, l)
			end
			letters[k] = l
		end
		task.delay(0.35 + i * 0.06, function()
			for k = 0, 2 do
				local l = letters[k]
				l.TextTransparency = k == 0 and 0 or (0.55 + k * 0.15)
				tw(l, 0.42 + k * 0.06, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Back)
				if k > 0 then tw(l, 0.5, { TextTransparency = 1 }) end
			end
			tw(letters[0].UIStroke, 0.3, { Transparency = 0 })
		end)
	end
end

-- progress line with the moth as its head (Fishing Master put a fish there)
local track = new("Frame", { Name = "ProgressBar", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.872), Size = UDim2.new(0.32, 0, 0, 2), BackgroundColor3 = GOLD_DIM, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 6 }, bg)
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 7 }, track)
new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = GOLD, BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 6 }, fill) -- ghost glow
local moth = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, -10), Size = UDim2.fromOffset(44, 22), BackgroundTransparency = 1, ZIndex = 9 }, fill)
local body = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = PALE, BorderSizePixel = 0, ZIndex = 10 }, moth)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, body)
local wings = {}
for i, sgn in { -1, 1 } do
	local pivot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 2), BackgroundTransparency = 1, ZIndex = 9 }, moth)
	new("Frame", { BackgroundColor3 = PALE, BorderSizePixel = 0, Position = UDim2.fromScale(sgn > 0 and 0.5 or 0, 0), Size = UDim2.fromScale(0.5, 1), ZIndex = 9 }, pivot)
	wings[i] = pivot
end
local status = new("TextLabel", { Name = "Status", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.886), Size = UDim2.fromScale(0.5, 0.03), BackgroundTransparency = 1, Text = STATUS[1] .. "...", TextScaled = true, FontFace = SERIF, TextColor3 = Color3.fromRGB(235, 225, 210), ZIndex = 6 }, bg)
local tip = new("TextLabel", { Name = "Tip", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.95), Size = UDim2.fromScale(0.7, 0.028), BackgroundTransparency = 1, Text = "Tip: " .. TIPS[math.random(#TIPS)], TextScaled = true, FontFace = SERIF, TextColor3 = Color3.fromRGB(224, 212, 188), ZIndex = 6 }, bg) -- warm cream: the violet grey failed contrast
task.spawn(function()
	while tip.Parent do
		task.wait(4)
		if not tip.Parent then break end
		tw(tip, 0.3, { TextTransparency = 1 }).Completed:Wait()
		tip.Text = "Tip: " .. TIPS[math.random(#TIPS)]
		tw(tip, 0.3, { TextTransparency = 0 })
	end
end)

-- skip after 2 s (Sol's RNG has one); it ends the wait once the game has loaded
local skipped = false
local skip = new("TextButton", { Name = "SkipButton", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -24), Size = UDim2.fromOffset(120, 40), BackgroundTransparency = 1, Text = "SKIP  >", TextColor3 = GOLD, FontFace = SERIF, TextSize = 20, Visible = false, ZIndex = 9 }, bg)
new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.fromOffset(70, 1), BackgroundColor3 = GOLD_DIM, BorderSizePixel = 0, ZIndex = 9 }, skip)
skip.Activated:Connect(function() skipped = true end)
task.delay(2, function() if skip.Parent then skip.Visible = true end end)

-- progress = blend of elapsed minimum time, the asset queue draining, and game.Loaded; eases, never jumps back
local t0 = os.clock()
local shown, peakQueue = 0, 1
local conn = RunService.RenderStepped:Connect(function(dt)
	local q = ContentProvider.RequestQueueSize
	peakQueue = math.max(peakQueue, q)
	local target = math.min(1, (os.clock() - t0) / MIN_TIME) * 0.45 + (1 - q / peakQueue) * 0.35 + (game:IsLoaded() and 0.2 or 0)
	shown = math.max(shown, shown + (target - shown) * math.min(1, dt * 4))
	fill.Size = UDim2.fromScale(shown, 1)
	local open = math.abs(math.cos((os.clock() - t0) * 14)) -- wingbeat
	wings[1].Rotation, wings[2].Rotation = 60 * (1 - open), -60 * (1 - open)
	moth.Position = UDim2.new(1, 0, 0.5, -10 + math.sin((os.clock() - t0) * 5) * 4)
	tunnelSpeed = 0.16 + shown * 0.3 -- the fall through time speeds up as loading completes
	local i = math.clamp(math.floor(shown * #STATUS) + 1, 1, #STATUS)
	status.Text = STATUS[i] .. "..."
end)

if not game:IsLoaded() then
	game.Loaded:Wait()
end
-- preload the HUD art so the first frame of the HUD is not empty squares
pcall(function()
	local ids = {}
	for _, id in { 93007984461409, 130417417090960, 82753242617563, 103702070307340, 87280674486491, 90060877131480, 121738926400945, 103109177610563, 75132842759812, 136446507511717, 108574647086501 } do
		table.insert(ids, "rbxassetid://" .. id)
	end
	ContentProvider:PreloadAsync(ids)
end)
while (os.clock() - t0 < MIN_TIME or shown < 0.98) and not skipped do
	task.wait()
	if os.clock() - t0 > MIN_TIME + 4 then
		break -- never hang on a slow asset
	end
end
conn:Disconnect()
fill.Size = UDim2.fromScale(1, 1)
status.Text = "Welcome, " .. player.DisplayName .. "."
task.wait(0.5)

-- finale (the user's story): the time tunnel glitches; a tree of light forms from scattered pieces (the player's
-- future); eyes open around it (the gods watching); then everything is swallowed into a vortex and the game appears.
local stage = new("Frame", { Name = "Stage", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(1, 1), ZIndex = 20 }, bg)
new("UIAspectRatioConstraint", { AspectRatio = 1 }, stage)
-- 1) glitch: the tunnel jumps sideways, colour-split bars flash across the screen
local glitching = true
local glideT0 = os.clock()
task.spawn(function()
	while glitching do
		-- layout audit 2026-10-29 (the tunnel sat 78 px above the eye): while it judders it also glides from 0.36 (above
		-- the title during loading) to the screen centre, so the clock faces are concentric with the tree and the eye
		local k = math.min(1, (os.clock() - glideT0) / 0.6)
		tunnel.Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.03, 0.36 + 0.14 * (1 - (1 - k) ^ 2) + (math.random() - 0.5) * 0.01)
		for _ = 1, 0 do -- review: the pink and cyan bars read as artefacts; the tunnel judder alone carries the glitch
			local bar = new("Frame", { Position = UDim2.fromScale(math.random() * 0.3 - 0.1, math.random()), Size = UDim2.new(0.4 + math.random() * 0.8, 0, 0, math.random(2, 10)), BackgroundColor3 = math.random() < 0.5 and Color3.fromRGB(80, 230, 255) or Color3.fromRGB(255, 70, 190), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 30 }, bg)
			task.delay(0.06, function() bar:Destroy() end)
		end
		task.wait(0.06)
	end
	tunnel.Position = UDim2.fromScale(0.5, 0.5)
end)
tunnelSpeed = 0.9
for _, d in titleRow:GetDescendants() do -- the title steps aside so the tree and the eyes own the centre
	if d:IsA("TextLabel") then tw(d, 0.3, { TextTransparency = 1 }) end
	if d:IsA("ImageLabel") then tw(d, 0.3, { ImageTransparency = 1 }) end
	if d:IsA("Frame") then tw(d, 0.3, { BackgroundTransparency = 1 }) end
	if d:IsA("UIStroke") then tw(d, 0.3, { Transparency = 1 }) end
end
tw(status, 0.3, { TextTransparency = 1 })
tw(textPanel, 0.6, { BackgroundTransparency = 1 }) -- the panel goes with the text; the finale owns the screen
tw(track, 0.3, { BackgroundTransparency = 1 })
tw(fill, 0.3, { BackgroundTransparency = 1 })
for _, d in fill:GetDescendants() do if d:IsA("Frame") then tw(d, 0.3, { BackgroundTransparency = 1 }) end end
-- the tunnel sinks into the dark so the tree and the eyes own the screen
local hush = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 10 }, bg)
tw(hush, 0.6, { BackgroundTransparency = 0.35 })
task.wait(0.45)
-- 2) v4: the painted tree assembles from eight horizontal slices, bottom first; each slice arrives shifted sideways
-- with a colour-split ghost and snaps into place (the glitch), while a few motes still fly in as "pieces"
local TREE_PX = 768 -- source image size
local treeBox = new("Frame", { Name = "Tree", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.9), Size = UDim2.fromScale(0.66, 0.66), ZIndex = 21 }, stage)
local SL = 8
-- once every slice has landed, one whole image replaces them (review round 3: a seam showed between slices)
local whole = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.tree, Size = UDim2.fromScale(1, 1), ImageTransparency = 1, ZIndex = 23 }, treeBox)
task.delay(SL * 0.07 + 0.35, function()
	whole.ImageTransparency = 0
	for _, c in treeBox:GetChildren() do if c ~= whole then c.Visible = false end end
end)
-- 2026-10-28 night (the user: "the intro tree is 2D"): the tree lives. A soft halo breathes behind it, the crown sways
-- a little, the camera pushes in slowly, and sparks of light lift off the branches and drift up
local halo = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.glow, ImageColor3 = Color3.fromRGB(140, 200, 255), ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(1.1, 0.9), ZIndex = 20 }, treeBox)
task.delay(0.5, function()
	tw(halo, 0.8, { ImageTransparency = 0.55 })
	tw(treeBox, 2.6, { Size = UDim2.fromScale(0.74, 0.74) }, Enum.EasingStyle.Sine) -- the slow push-in
end)
local sparks = {}
for i = 1, 22 do
	local sp = new("Frame", { BackgroundColor3 = i % 3 == 0 and Color3.fromRGB(255, 230, 170) or Color3.fromRGB(190, 230, 255), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromScale(0.008, 0.008), BackgroundTransparency = 1, ZIndex = 24 }, treeBox)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, sp)
	sparks[i] = { f = sp, x = 0.2 + math.random() * 0.6, y = 0.15 + math.random() * 0.4, t = math.random(), v = 0.25 + math.random() * 0.3 }
end
-- 2026-10-28 night (the user: "make the tree glitch and corrupt"): once whole, the tree breaks up in short digital
-- bursts of 2-4 frames. Copies of a few bands are shoved sideways (one shows the wrong rows: corrupt data), cyan and
-- magenta copies split off, and a scanline flashes across; then it snaps back. The copies use a haze-free cut of the
-- tree (only the lit branches), so a shifted band never shows the painting's dark haze as a black box (review r1).
-- Bursts come faster as the vortex nears.
local GLITCH = ART.treeGlitch
local tears = {}
for i = 1, 4 do
	tears[i] = new("ImageLabel", { BackgroundTransparency = 1, Image = GLITCH, Visible = false, ZIndex = 25 }, treeBox)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.1), NumberSequenceKeypoint.new(0.8, 0.1), NumberSequenceKeypoint.new(1, 1) }) }, tears[i])
end
local ghostR = new("ImageLabel", { BackgroundTransparency = 1, Image = GLITCH, ImageColor3 = Color3.fromRGB(255, 70, 200), ImageTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 24 }, treeBox)
local ghostC = ghostR:Clone()
ghostC.ImageColor3, ghostC.Parent = Color3.fromRGB(70, 240, 255), treeBox
local scan = new("Frame", { BackgroundColor3 = Color3.fromRGB(200, 245, 255), BorderSizePixel = 0, Size = UDim2.new(1.1, 0, 0, 2), Position = UDim2.fromScale(-0.05, 0), BackgroundTransparency = 1, ZIndex = 26 }, treeBox)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, scan)
local TEAR_TINT = { Color3.fromRGB(150, 245, 255), Color3.fromRGB(255, 150, 230), Color3.new(1, 1, 1), Color3.fromRGB(190, 255, 235) }
local frenzy = false -- set when the watchers have seen the tree: it corrupts faster and faster
local burstUntil, nextBurst = 0, os.clock() + SL * 0.07 + 0.9
local function reslice()
	for i, tr in tears do -- a few bands of the tree, copied and shoved sideways
		local h = 0.04 + math.random() * 0.1
		local y = 0.1 + math.random() * (0.7 - h)
		local src = i == 1 and math.clamp(y + (math.random() - 0.5) * 0.3, 0, 1 - h) or y -- band 1 shows the wrong rows
		tr.ImageRectOffset, tr.ImageRectSize = Vector2.new(0, TREE_PX * src), Vector2.new(TREE_PX, TREE_PX * h)
		local dx = (0.03 + math.random() * 0.07) * (math.random() < 0.5 and -1 or 1)
		tr.Position, tr.Size, tr.ImageColor3 = UDim2.fromScale(dx, y), UDim2.fromScale(1, h), TEAR_TINT[i]
		tr.Visible = true
	end
end
local function burst(now)
	burstUntil = now + 0.07 + math.random() * 0.1
	reslice()
	local d = 0.006 + math.random() * 0.006 -- about 4-8 px of colour split
	ghostR.Position, ghostC.Position = UDim2.fromScale(-d, 0), UDim2.fromScale(d, 0)
	ghostR.ImageTransparency, ghostC.ImageTransparency = 0.35, 0.35
	scan.Position, scan.BackgroundTransparency = UDim2.fromScale(-0.05, 0.1 + math.random() * 0.7), 0.1
end
local function mend()
	burstUntil = 0
	for _, tr in tears do tr.Visible = false end
	ghostR.ImageTransparency, ghostC.ImageTransparency, scan.BackgroundTransparency = 1, 1, 1
end
local treeT0 = os.clock()
local treeLife = RunService.RenderStepped:Connect(function(dt)
	local t = os.clock() - treeT0
	local now = os.clock()
	if burstUntil > 0 then
		if now > burstUntil then mend() else reslice() end
	end
	if now > nextBurst then
		burst(now)
		nextBurst = now + (frenzy and 0.06 + math.random() * 0.1 or math.max(0.25, 1.1 - (t - 1) * 0.18) * (0.6 + math.random() * 0.8))
	end
	whole.Rotation = math.sin(t * 1.3) * 1.2 -- the crown sways (pivot is the image centre; small enough to read as wind)
	whole.Position = UDim2.fromScale(math.sin(t * 1.3) * 0.006, 0)
	for _, S in sparks do
		S.t = (S.t + dt * S.v) % 1
		S.f.Position = UDim2.fromScale(S.x + math.sin(S.t * 6 + S.x * 9) * 0.02, S.y - S.t * 0.25)
		S.f.BackgroundTransparency = t < 0.9 and 1 or (1 - math.sin(S.t * math.pi) * 0.85)
	end
end)
stage.Destroying:Connect(function() treeLife:Disconnect() end)
for k = 0, SL - 1 do
	local y0 = k / SL
	local slice = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.tree, ImageRectOffset = Vector2.new(0, TREE_PX * y0), ImageRectSize = Vector2.new(TREE_PX, TREE_PX / SL), Position = UDim2.fromScale((math.random() - 0.5) * 0.3, y0), Size = UDim2.fromScale(1, 1 / SL), ImageTransparency = 1, ZIndex = 22 }, treeBox)
	local ghost = slice:Clone()
	ghost.ImageColor3, ghost.ZIndex = Color3.fromRGB(80, 230, 255), 21
	ghost.Parent = treeBox
	task.delay((SL - 1 - k) * 0.07, function()
		slice.ImageTransparency, ghost.ImageTransparency = 0, 0.5
		tw(slice, 0.28, { Position = UDim2.fromScale(0, y0) }, Enum.EasingStyle.Back)
		tw(ghost, 0.4, { Position = UDim2.fromScale(0.02, y0), ImageTransparency = 1 })
	end)
end
local pts = {}
local function limb(x, y, ang, len, depth)
	local x2, y2 = x + math.cos(ang) * len, y - math.sin(ang) * len
	for k = 0, 5 do table.insert(pts, { x + (x2 - x) * k / 5, y + (y2 - y) * k / 5 }) end
	if depth > 0 then
		limb(x2, y2, ang + 0.45, len * 0.72, depth - 1)
		limb(x2, y2, ang - 0.45, len * 0.72, depth - 1)
	end
end
limb(0.5, 0.82, math.pi / 2, 0.15, 5)
for k = 1, 14 do table.insert(pts, { 0.5 + (math.random() - 0.5) * 0.18, 0.82 + math.random() * 0.03 }) end -- roots
local bits = {}
for i, p in pts do
	if true then continue end -- round 3: no square "pixels" at all (the user asked for a real tree, not pixels)
	local sq = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(math.random(), math.random()), Size = UDim2.fromScale(0.011, 0.011), BackgroundColor3 = i % 5 == 0 and Color3.fromRGB(140, 220, 255) or PALE, BorderSizePixel = 0, Rotation = math.random(0, 90), ZIndex = 21 }, stage)
	bits[i] = sq
	task.delay(math.random() * 0.25, function()
		tw(sq, 0.55, { Position = UDim2.fromScale(p[1], p[2]), Rotation = 0 }, Enum.EasingStyle.Quint)
		task.delay(0.6, function() tw(sq, 0.3, { BackgroundTransparency = 1, Size = UDim2.fromScale(0.002, 0.002) }) end)
	end)
end
local treeGlow = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(0.05, 0.05), BackgroundColor3 = Color3.fromRGB(200, 235, 255), BackgroundTransparency = 1, ZIndex = 20 }, stage)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, treeGlow)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }) }, treeGlow)
for _, n in nebulae do tw(n, 1.2, { ImageColor3 = Color3.fromRGB(120, 170, 255) }) end -- warm dust cools to starlight: the arc's cosmic end
tw(bg, 1.2, { BackgroundColor3 = Color3.fromRGB(4, 6, 14) })
tw(treeGlow, 0.9, { Size = UDim2.fromScale(0.8, 0.8), BackgroundTransparency = 0.8 }, Enum.EasingStyle.Sine)
task.wait(0.85)
glitching = false
-- 2026-10-28 night (the user: "after the other eyes look at the tree, it becomes glitched and slowly the big eye comes
-- in and sucks in the player"; "the eye pops in so abruptly"): four small watchers open around the tree and stare at
-- it; under their gaze the tree corrupts faster and faster; then it tears apart while the great eye materialises out of
-- the same glitch, and the watchers are pulled into it.
local watchers = {}
for i, spec in ipairs({ { 0.13, 0.33, 0.22 }, { 0.87, 0.33, 0.22 }, { 0.16, 0.72, 0.19 }, { 0.84, 0.72, 0.19 } }) do
	local w = spec[3]
	local holder = new("Frame", { Name = "Watcher" .. i, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(spec[1], spec[2]), Size = UDim2.fromScale(w, w * 0.5), ZIndex = 22 }, stage)
	local sock = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.socket, ImageColor3 = Color3.fromRGB(255, 226, 180), ImageRectOffset = Vector2.new(0, 1024 * 0.15), ImageRectSize = Vector2.new(1024, 1024 * 0.66), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1.32), ZIndex = 22 }, holder)
	local back = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.iris, ImageColor3 = Color3.fromRGB(10, 8, 6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.506, 0.5), Size = UDim2.fromScale(424 / 1024 * 1.05, 424 / 676 * 1.05), ZIndex = 22 }, sock)
	local iris = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.iris, ImageColor3 = Color3.fromRGB(255, 214, 150), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.506, 0.5), Size = UDim2.fromScale(424 / 1024, 424 / 676), ZIndex = 23 }, sock)
	local slit = new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1) }, sock)
	local g2 = slit:Clone()
	g2.Parent = iris
	local g3 = slit:Clone()
	g3.Parent = back
	local openV = Instance.new("NumberValue")
	openV.Changed:Connect(function(v) -- the eye opens through a soft slit that widens
		local lo, hi = math.clamp(0.5 - v, 0.002, 0.49), math.clamp(0.5 + v, 0.51, 0.998)
		local e = math.min(0.06, math.max(0.002, (hi - lo) / 3))
		slit.Transparency = hi - lo < 0.01 and NumberSequence.new(1) or NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(lo, 1), NumberSequenceKeypoint.new(lo + e, 0), NumberSequenceKeypoint.new(hi - e, 0), NumberSequenceKeypoint.new(hi, 1), NumberSequenceKeypoint.new(1, 1) })
		local span, base = 424 / 676, 0.5 - 0.5 * 424 / 676 -- the iris box inside the eye image
		local ilo, ihi = math.clamp((lo - base) / span, 0.002, 0.49), math.clamp((hi - base) / span, 0.51, 0.998)
		local iseq = ihi - ilo < 0.01 and NumberSequence.new(1) or NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(ilo, 1), NumberSequenceKeypoint.new(ilo + 0.02, 0), NumberSequenceKeypoint.new(ihi - 0.02, 0), NumberSequenceKeypoint.new(ihi, 1), NumberSequenceKeypoint.new(1, 1) })
		g2.Transparency, g3.Transparency = iseq, iseq
	end)
	local dir = Vector2.new(0.5 - spec[1], 0.5 - spec[2]).Unit
	-- 2026-10-29 (review: "the watchers stare at the camera, not the tree"): the iris swings further and narrows as it
	-- turns (foreshortened), and a faint beam of their gaze runs to the tree's heart
	local tx, ty = 0.5, 0.52
	local bx, by = tx - spec[1], ty - spec[2]
	local beam = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale((spec[1] + tx) / 2, (spec[2] + ty) / 2), Size = UDim2.fromScale(math.sqrt(bx * bx + by * by), 0.004), Rotation = math.deg(math.atan2(by, bx)), BackgroundColor3 = Color3.fromRGB(255, 214, 150), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 20 }, stage)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.75, 0.6), NumberSequenceKeypoint.new(1, 1) }) }, beam)
	watchers[i] = { holder = holder, iris = iris, back = back, sock = sock, beam = beam, look = Vector2.new(dir.X * 0.19, dir.Y * 0.1) }
	task.delay(i * 0.12, function()
		tw(openV, 0.6, { Value = 0.5 }, Enum.EasingStyle.Quart)
		task.wait(0.35)
		for _, x in { iris, back } do -- the iris turns to the tree
			tw(x, 0.45, { Position = UDim2.fromScale(0.506 + watchers[i].look.X, 0.5 + watchers[i].look.Y), Size = UDim2.fromScale(x.Size.X.Scale * 0.82, x.Size.Y.Scale) }, Enum.EasingStyle.Sine)
		end
		tw(watchers[i].beam, 0.6, { BackgroundTransparency = 0.6 })
	end)
end
task.wait(1.6) -- they stare
frenzy = true
nextBurst = os.clock()
for _, W in watchers do tw(W.beam, 1.1, { BackgroundTransparency = 0.2 }, Enum.EasingStyle.Sine) end -- their gaze burns brighter
task.wait(1.1) -- under their gaze the tree corrupts faster and faster
-- 2026-10-29 (the user: "the image is not very refined with a lot of overlapping parts... fix this or go to 2D"): the
-- great eye is the 2D etched eye again, the one the user liked ("I really like the coloring", "the eyelashes are why
-- it was so defined"): the watchers' socket and clock iris, tinted gold, at full size. No brass layers, lids or lash
-- overlays. It opens through a soft slit like the watchers. The iris is cut into two rings
-- (UI Kit/art/make_etched_iris_rings.py) that turn against each other once it is open, and a black pupil opens in the
-- pull.
local EW, EYE_Y, EA = 0.95, 0.58, 676 / 1024 -- EA: the socket crop's height / width; EYE_Y 0.58 puts the eye at the screen's centre (the stage sits at 0.42)
local SOCK_TINT, IRIS_TINT = Color3.fromRGB(255, 226, 180), Color3.fromRGB(255, 214, 150)
local great = new("Frame", { Name = "GreatEye", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, EYE_Y), Size = UDim2.fromScale(EW, EW * EA), ZIndex = 22 }, stage)
local eyeArt = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.socket, ImageColor3 = SOCK_TINT, ImageRectOffset = Vector2.new(0, 1024 * 0.15), ImageRectSize = Vector2.new(1024, 676), ImageTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 22 }, great)
local IX, IY = 0.506, 0.5
local function irisPart(img, frac, tint)
	return new("ImageLabel", { BackgroundTransparency = 1, Image = img, ImageColor3 = tint or IRIS_TINT, ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(IX, IY), Size = UDim2.fromScale(424 / 1024 * frac, 424 / 676 * frac), ZIndex = 23 }, great)
end
local irisBack = irisPart(ART.iris, 1.05, Color3.fromRGB(10, 8, 6)) -- dark backing so the socket's hole never shows
local ringOut, ringIn = irisPart(ART.irisOutE, 1), irisPart(ART.irisInE, 1)
local PUPIL = 120 / 0.92 -- iris px; the disc's dark part is 92 % of its image
local function pupilSize(k) return UDim2.fromScale(PUPIL * k / 1024, PUPIL * k / 676) end
local pupilDisc = irisPart(ART.pupilDisc, 1, Color3.new(1, 1, 1))
pupilDisc.Size = pupilSize(0)
local pupil = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.glow, ImageColor3 = Color3.fromRGB(236, 206, 140), ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(IX, IY), Size = UDim2.fromScale(0.16, 0.26), ZIndex = 23 }, great)
local ringSpin = Instance.new("NumberValue") -- 0 until the eye is open (the slit's gradients must not turn with the rings)
local ringConn = RunService.RenderStepped:Connect(function(dt)
	ringOut.Rotation += dt * 7 * ringSpin.Value
	ringIn.Rotation -= dt * 12 * ringSpin.Value
end)
gui.Destroying:Connect(function() ringConn:Disconnect() end)
-- the slit (same as the watchers): the eye shows through a soft horizontal band that widens from the middle
local slitE = new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1) }, eyeArt)
local slitI = {}
for _, x in { irisBack, ringOut, ringIn } do table.insert(slitI, new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1) }, x)) end
local openV = Instance.new("NumberValue")
openV.Changed:Connect(function(v)
	local lo, hi = math.clamp(0.5 - v, 0.002, 0.49), math.clamp(0.5 + v, 0.51, 0.998)
	local e = math.min(0.06, math.max(0.002, (hi - lo) / 3))
	slitE.Transparency = hi - lo < 0.01 and NumberSequence.new(1) or NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(lo, 1), NumberSequenceKeypoint.new(lo + e, 0), NumberSequenceKeypoint.new(hi - e, 0), NumberSequenceKeypoint.new(hi, 1), NumberSequenceKeypoint.new(1, 1) })
	local span, base = 424 / 676, 0.5 - 0.5 * 424 / 676 -- the iris box inside the eye
	local ilo, ihi = math.clamp((lo - base) / span, 0.002, 0.49), math.clamp((hi - base) / span, 0.51, 0.998)
	local iseq = ihi - ilo < 0.01 and NumberSequence.new(1) or NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(ilo, 1), NumberSequenceKeypoint.new(ilo + 0.02, 0), NumberSequenceKeypoint.new(ihi - 0.02, 0), NumberSequenceKeypoint.new(ihi, 1), NumberSequenceKeypoint.new(1, 1) })
	for _, g in slitI do g.Transparency = iseq end
end)
-- forming (review: "the tree draws over the forming eye", the user: "the eye pops in so abruptly"): under the
-- watchers' gaze the tree is wrung into a spinning point where the eye will be; the great eye unfurls out of that point,
-- turning as it grows and already solid, so nothing shows through it. Its glitch: bands of the eye shoved sideways and
-- colour copies that slide together as it steadies. Everything in the finale turns counter-clockwise, one whirlpool.
local s0 = treeBox.Size.X.Scale
treeBox.AnchorPoint, treeBox.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.9 - s0 / 2) -- same place, centre pivot
local COLLAPSE = 0.9
tw(treeBox, COLLAPSE, { Size = UDim2.fromScale(0.02, 0.02), Position = UDim2.fromScale(0.5, EYE_Y), Rotation = -240 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
for _, i in { whole, halo } do tw(i, COLLAPSE, { ImageTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In) end
for _, W in watchers do tw(W.beam, COLLAPSE * 0.8, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end
task.wait(COLLAPSE - 0.2)
task.delay(0.25, function()
	frenzy = false
	nextBurst = math.huge
	mend()
	treeBox.Visible = false
end)
great.Size, great.Rotation = UDim2.fromScale(EW * 0.08, EW * EA * 0.08), 110
tw(great, 1.6, { Size = UDim2.fromScale(EW, EW * EA), Rotation = 0 }, Enum.EasingStyle.Quint)
for _, x in { eyeArt, irisBack, ringOut, ringIn, pupilDisc } do tw(x, 0.45, { ImageTransparency = 0 }) end
openV.Value = 0.03 -- it arrives closed: a thin glowing slit, spinning out of the point
treeGlow.Position, treeGlow.Size, treeGlow.BackgroundTransparency = UDim2.fromScale(0.5, EYE_Y), UDim2.fromScale(0.05, 0.05), 0.2
tw(treeGlow, 0.8, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, Enum.EasingStyle.Quart) -- a soft shock of light behind it
task.spawn(function() -- glitch bands across the whole eye, fewer and smaller shoves as it steadies
	local bands = {}
	for k = 1, 4 do
		bands[k] = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.socket, ImageColor3 = TEAR_TINT[k], ImageTransparency = 0.4, Visible = false, ZIndex = 26 }, great)
	end
	local t0g = os.clock()
	while os.clock() - t0g < 1.2 do
		local age = (os.clock() - t0g) / 1.2
		for _, bd in bands do
			if math.random() < 0.85 - age * 0.5 then
				local h = 0.05 + math.random() * 0.1
				local y = 0.15 + math.random() * (0.7 - h)
				bd.ImageRectOffset, bd.ImageRectSize = Vector2.new(0, 1024 * 0.15 + 676 * y), Vector2.new(1024, 676 * h)
				bd.Position, bd.Size = UDim2.fromScale((0.03 + math.random() * 0.06) * (1 - age) * (math.random() < 0.5 and -1 or 1), y), UDim2.fromScale(1, h)
				bd.Visible = true
			end
		end
		task.wait(0.06 + math.random() * 0.04)
		for _, bd in bands do bd.Visible = false end
		task.wait(0.04 + age * 0.25 * math.random())
	end
	for _, bd in bands do bd:Destroy() end
end)
for _, F in fog do tw(F.img, 1.2, { ImageTransparency = F.base - 0.15 }) end -- the fog thickens
task.delay(0.15, function() -- the watchers spiral into the great eye
	local t0w, starts = os.clock(), {}
	for i, W in watchers do
		local p = W.holder.Position
		local dx, dy = p.X.Scale - 0.5, p.Y.Scale - EYE_Y
		starts[i] = { r = math.sqrt(dx * dx + dy * dy), a = math.atan2(dy, dx), w = W.holder.Size }
		W.holder.ZIndex = 27
	end
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local q = math.min(1, (os.clock() - t0w) / 1.1)
		local e = q * q
		for i, W in watchers do
			local S = starts[i]
			local r, ang = S.r * (1 - e), S.a - e * 3.2
			W.holder.Position = UDim2.fromScale(0.5 + math.cos(ang) * r, EYE_Y + math.sin(ang) * r)
			W.holder.Size = UDim2.fromScale(S.w.X.Scale * (1 - e), S.w.Y.Scale * (1 - e))
			W.holder.Rotation = -math.deg(e * 3.2)
			for _, x in { W.sock, W.iris, W.back } do x.ImageTransparency = e end
		end
		if q >= 1 then conn:Disconnect() end
	end)
end)
task.wait(1.5)
-- it opens: the slit parts a little, rests, then opens wide (one smooth motion each, no reversal). Once fully open
-- the slit's gradients come off, the dials start turning against each other, and a steady warm light comes up.
tw(openV, 0.7, { Value = 0.09 }, Enum.EasingStyle.Sine)
task.wait(0.85)
tw(openV, 1.7, { Value = 0.5 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
task.wait(1.75)
slitE.Enabled = false
for _, g in slitI do g.Enabled = false end
tw(ringSpin, 1.2, { Value = 1 }, Enum.EasingStyle.Sine)
tw(pupil, 1.0, { ImageTransparency = 0.55 }, Enum.EasingStyle.Sine)
task.wait(0.6)
-- the pull (the user: "sucks in the player", "more rotational movement so the suck in is more immersive"): the dials
-- spin up against each other, the pupil opens into a hole that swallows the inner dial and its light, the eye turns
-- and draws closer, a sunburst wheels behind it, the clock tunnel and the fog turn into a whirlpool, and streaks of
-- light spiral into the pupil
local PULL = 1.8
tw(great, PULL, { Size = UDim2.fromScale(EW * 1.4, EW * EA * 1.4), Rotation = -35 }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
tw(ringSpin, PULL, { Value = 35 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
tw(pupilDisc, PULL, { Size = pupilSize(2.15) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
tw(pupil, PULL * 0.7, { ImageTransparency = 1 })
tw(tunnel, PULL, { Rotation = -40 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
tw(swirlV, PULL, { Value = 1.6 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
tw(suckV, PULL, { Value = 0.35 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local arms = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.rays, ImageColor3 = Color3.fromRGB(255, 180, 90), ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, EYE_Y), Size = UDim2.fromScale(1.6, 1.6), ZIndex = 21 }, stage)
tw(arms, PULL, { ImageTransparency = 0.55, Rotation = -220 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
do
	local cc = pupil.AbsolutePosition + pupil.AbsoluteSize / 2
	local vs = workspace.CurrentCamera.ViewportSize
	local streaks = {}
	for i = 1, 70 do
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 214, 150):Lerp(Color3.fromRGB(200, 222, 255), (i % 3) / 3), BorderSizePixel = 0, Size = UDim2.fromOffset(46, 2), BackgroundTransparency = 1, ZIndex = 58 }, gui)
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, f)
		streaks[i] = { f = f, a0 = math.random() * math.pi * 2, r0 = 0.45 + math.random() * 0.6, d = math.random() * 0.5 }
	end
	local t0p = os.clock()
	local pull = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - t0p) / PULL
		for _, S in streaks do
			local q = math.clamp(k * 1.5 - S.d, 0, 1)
			local r = S.r0 * (1 - q) ^ 1.5 * vs.Y
			local ang = S.a0 - q * 7 -- counter-clockwise, tighter as it nears the pupil
			S.f.Position = UDim2.fromOffset(cc.X + math.cos(ang) * r, cc.Y + math.sin(ang) * r)
			S.f.Rotation = math.deg(ang) - 70
			S.f.Size = UDim2.fromOffset(30 + 60 * q, 2)
			S.f.BackgroundTransparency = 1 - 0.85 * math.sin(q * math.pi)
		end
	end)
	task.wait(PULL)
	pull:Disconnect()
	for _, S in streaks do S.f:Destroy() end
end
local c = pupil.AbsolutePosition + pupil.AbsoluteSize / 2
local DIVE = 0.8
tw(great, DIVE, { Size = UDim2.fromScale(EW * 9, EW * EA * 9), Rotation = -150 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
tw(tunnel, DIVE, { Size = UDim2.fromScale(3, 3), Rotation = -130 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
tw(ringSpin, DIVE, { Value = 70 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
tw(swirlV, DIVE, { Value = 3.2 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
tw(arms, DIVE, { Rotation = -420, Size = UDim2.fromScale(3, 3) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- polish (review: "a second off-centre watch", "a flat beige wash"): a hot white-gold core and gold rays that spin
-- out of the pupil; no ring; the light never fills the screen flat, and the menu appears as it fades
local bloom = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.glow, ImageColor3 = Color3.fromRGB(255, 165, 55), ImageTransparency = 0.3, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(c.X, c.Y), Size = UDim2.fromScale(0.08, 0.08), SizeConstraint = Enum.SizeConstraint.RelativeXX, ZIndex = 60 }, gui)
local core = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.glow, ImageColor3 = Color3.fromRGB(255, 246, 220), ImageTransparency = 0.2, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(c.X, c.Y), Size = UDim2.fromScale(0.03, 0.03), SizeConstraint = Enum.SizeConstraint.RelativeXX, ZIndex = 62 }, gui)
local rays = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.rays, ImageColor3 = Color3.fromRGB(255, 170, 70), ImageTransparency = 0.6, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(c.X, c.Y), Size = UDim2.fromScale(0.1, 0.1), SizeConstraint = Enum.SizeConstraint.RelativeXX, ZIndex = 61 }, gui)
tw(bloom, DIVE, { Size = UDim2.fromScale(1.5, 1.5), ImageTransparency = 0.05 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
tw(core, DIVE, { Size = UDim2.fromScale(0.6, 0.6), ImageTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
tw(rays, DIVE, { Size = UDim2.fromScale(1.8, 1.8), Rotation = -40, ImageTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
for _, F in fog do tw(F.img, DIVE, { ImageTransparency = F.base - 0.1 }) end
for _, d in gui:GetDescendants() do
	if (d:IsA("TextLabel") or d:IsA("TextButton")) then tw(d, 0.3, { TextTransparency = 1 }) end
end
task.wait(DIVE)
stage.Visible, tunnel.Visible = false, false
tunnelConn:Disconnect()
for _, d in gui:GetDescendants() do
	if d:IsA("UIStroke") then tw(d, 0.6, { Transparency = 1 }) end
	if d:IsA("Frame") then tw(d, 0.45, { BackgroundTransparency = 1 }) end
	if d:IsA("ImageLabel") and d ~= bloom and d ~= core and d ~= rays then tw(d, 0.45, { ImageTransparency = 1 }) end
end
tw(bloom, 0.5, { ImageTransparency = 1, Size = UDim2.fromScale(2.6, 2.6) }, Enum.EasingStyle.Quad)
tw(core, 0.4, { ImageTransparency = 1, Size = UDim2.fromScale(1.2, 1.2) }, Enum.EasingStyle.Quad)
tw(rays, 0.5, { ImageTransparency = 1, Size = UDim2.fromScale(3, 3), Rotation = -70 }, Enum.EasingStyle.Quad)
task.wait(0.55)
gui:Destroy()
