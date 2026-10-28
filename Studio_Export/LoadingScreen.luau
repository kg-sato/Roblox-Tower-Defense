--!nocheck
-- LoadingScreen (LocalScript in ReplicatedFirst, 2026-10-28). Replaces Roblox's default loading screen with ours:
-- dark violet backdrop, drifting gold motes, crown emblem inside two counter-rotating rings, title, a gold progress line
-- driven by real loading (ContentProvider queue + game.Loaded), themed status lines, rotating tips, then
-- "Welcome, <name>" and a fade out. Pattern per https://create.roblox.com/docs/players/loading-screens
-- (RemoveDefaultLoadingScreen after our gui is parented, a minimum display time, wait for game.Loaded).
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local MIN_TIME = 2.6 -- seconds: long enough to read the title, short enough not to annoy
local CROWN = "rbxassetid://74707140327748" -- UI Kit icon_crown (our art, uploaded 2026-10-28)
local GOLD, GOLD_DIM, INK = Color3.fromRGB(255, 214, 120), Color3.fromRGB(150, 110, 50), Color3.fromRGB(8, 6, 18)
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

local gui = new("ScreenGui", { Name = "LoadingScreen", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 200, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))
local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BorderSizePixel = 0 }, gui)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 16, 52)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(12, 9, 28)), ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 3, 10)) }) }, bg)
ReplicatedFirst:RemoveDefaultLoadingScreen() -- after our gui is up, so there is no blank frame

-- drifting motes (cheap: 26 frames tweened upward, looping)
local motes = {}
for i = 1, 26 do
	local s = math.random(2, 5)
	local m = new("Frame", { BackgroundColor3 = GOLD, BackgroundTransparency = 0.35, BorderSizePixel = 0, Size = UDim2.fromOffset(s, s), Position = UDim2.fromScale(math.random(), math.random()), ZIndex = 2 }, bg)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, m)
	motes[i] = m
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

-- emblem: crown in two counter-rotating rings with a soft glow
local holder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.22, 0.22), ZIndex = 3 }, bg)
new("UIAspectRatioConstraint", { AspectRatio = 1 }, holder)
local glow = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.4, 1.4), BackgroundColor3 = GOLD, BackgroundTransparency = 0.88, ZIndex = 3 }, holder)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, glow)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }) }, glow)
local function ring(scale, thick, dashes, speed)
	local r = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(scale, scale), BackgroundTransparency = 1, ZIndex = 4 }, holder)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, r)
	new("UIStroke", { Color = GOLD, Thickness = thick, Transparency = 0.15 }, r)
	for k = 1, dashes do -- small diamonds on the ring
		local a = k / dashes * math.pi * 2
		local d = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + math.cos(a) * 0.5, 0.5 + math.sin(a) * 0.5), Size = UDim2.fromOffset(8, 8), Rotation = 45, BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 5 }, r)
	end
	TweenService:Create(r, TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = speed > 0 and 360 or -360 }):Play()
	return r
end
ring(0.92, 2, 4, 14)
ring(0.72, 1.5, 6, -10)
-- abstract (2026-10-28): the crown art is gone; a single amber point breathes at the centre of the orbits
local crown = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.16, 0.16), BackgroundColor3 = GOLD, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6 }, holder)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, crown)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 235, 170), Color3.fromRGB(235, 130, 40)) }, crown)
tw(crown, 0.8, { BackgroundTransparency = 0 })
TweenService:Create(crown, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromScale(0.2, 0.2) }):Play()

local title = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromScale(0.6, 0.09), BackgroundTransparency = 1, Text = "GUARDIAN GRID", TextScaled = true, Font = Enum.Font.GrenzeGotisch, TextColor3 = GOLD, TextTransparency = 1, ZIndex = 6 }, bg)
new("UIStroke", { Color = Color3.fromRGB(40, 20, 8), Thickness = 2, Transparency = 1 }, title)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 240, 200), Color3.fromRGB(230, 160, 60)) }, title)
tw(title, 0.9, { TextTransparency = 0 })
tw(title.UIStroke, 0.9, { Transparency = 0 })

-- progress line, status and tip
local track = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.7), Size = UDim2.fromScale(0.3, 0), BackgroundColor3 = GOLD_DIM, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 6 }, bg)
track.Size = UDim2.new(0.3, 0, 0, 3)
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 7 }, track)
local spark = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(10, 10), Rotation = 45, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 8 }, fill)
local status = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.715), Size = UDim2.fromScale(0.5, 0.032), BackgroundTransparency = 1, Text = STATUS[1] .. "...", TextScaled = true, Font = Enum.Font.Fondamento, TextColor3 = Color3.fromRGB(235, 225, 210), ZIndex = 6 }, bg)
local tip = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.94), Size = UDim2.fromScale(0.7, 0.03), BackgroundTransparency = 1, Text = "Tip: " .. TIPS[math.random(#TIPS)], TextScaled = true, Font = Enum.Font.TitilliumWeb, TextColor3 = Color3.fromRGB(170, 160, 200), ZIndex = 6 }, bg)
task.spawn(function()
	while tip.Parent do
		task.wait(4)
		tw(tip, 0.3, { TextTransparency = 1 }).Completed:Wait()
		tip.Text = "Tip: " .. TIPS[math.random(#TIPS)]
		tw(tip, 0.3, { TextTransparency = 0 })
	end
end)

-- skip button after 2 s (Sol's RNG added one to its loading screen); it ends the wait once the game has loaded
local skipped = false
local skip = new("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -24), Size = UDim2.fromOffset(120, 40), BackgroundColor3 = Color3.fromRGB(30, 22, 50), BackgroundTransparency = 1, Text = "SKIP  >", TextColor3 = GOLD, Font = Enum.Font.Fondamento, TextSize = 22, Visible = false, ZIndex = 9, AutoButtonColor = true }, bg)
new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.fromOffset(70, 1), BackgroundColor3 = GOLD_DIM, BorderSizePixel = 0, ZIndex = 9 }, skip) -- abstract: underlined text, no box
skip.Activated:Connect(function() skipped = true end)
task.delay(2, function() if skip.Parent then skip.Visible = true end end)

-- progress = blend of elapsed minimum time, the asset queue draining, and game.Loaded; it eases and never jumps back
local t0 = os.clock()
local shown, peakQueue = 0, 1
local conn = RunService.RenderStepped:Connect(function(dt)
	local q = ContentProvider.RequestQueueSize
	peakQueue = math.max(peakQueue, q)
	local target = math.min(1, (os.clock() - t0) / MIN_TIME) * 0.45 + (1 - q / peakQueue) * 0.35 + (game:IsLoaded() and 0.2 or 0)
	shown = math.max(shown, shown + (target - shown) * math.min(1, dt * 4))
	fill.Size = UDim2.fromScale(shown, 1)
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
task.wait(0.7)
for _, d in gui:GetDescendants() do
	if d:IsA("TextLabel") then tw(d, 0.5, { TextTransparency = 1 }) end
	if d:IsA("ImageLabel") then tw(d, 0.5, { ImageTransparency = 1 }) end
	if d:IsA("UIStroke") then tw(d, 0.5, { Transparency = 1 }) end
	if d:IsA("Frame") then tw(d, 0.6, { BackgroundTransparency = 1 }) end
end
task.wait(0.65)
gui:Destroy()
