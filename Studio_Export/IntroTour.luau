--!nocheck
-- IntroTour (StarterPlayerScripts, 2026-10-28): a first-time guided camera tour of the board, from the user's reference
-- "Intro Video Loading Screen" (Descend: a slow shot of each place with a caption title and a smaller line, cut through
-- black, SKIP in the corner) and "Good Intro or Tutorial" (Dao Cultivation: a centred quest title card).
-- Notes: Roblox Dev/Research/UI/Loading, Intro and UI References 2.md.
-- 2026-10-28 night (the user: "the first cutscene starts after the camera already panned to the playing view; it
-- should be one smooth animation"): it now starts the moment PLAY is pressed and is one continuous camera move. It
-- blends out of whatever camera the game is showing (the menu shot, then the opening crane), glides from shot to shot
-- instead of cutting through black, and at the end glides into the live play camera instead of fading.
-- GameClient calls it once, for a player whose tutorial is active, when PLAY is pressed:
--   require(IntroTour).play({ hud = hud, camera = camera, sfx = FXK.play, reduced = bool }, onDone)
-- Client only, visual only. The camera is driven at a render priority just after GameClient's camera.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local SERIF = Font.new("rbxasset://fonts/families/AccanthisADFStd.json", Enum.FontWeight.Bold)
local GOLD, PALE = Color3.fromRGB(255, 214, 130), Color3.fromRGB(236, 228, 255)

-- each beat: camera from -> to (positions), what it looks at, a title and a line under it
local BEATS = {
	{ from = Vector3.new(-70, 46, 72), to = Vector3.new(-40, 40, 80), at = Vector3.new(0, 0, 0), title = "WELCOME TO LAMPWICK LANE", line = "a gaslit street, and the night wants it" },
	{ from = Vector3.new(-26, 8, -2), to = Vector3.new(-33, 7, -9), at = Vector3.new(-49, 6, -20), title = "THE NIGHT COMES THROUGH THE GATE", line = "creatures walk the lane, stage after stage" },
	{ from = Vector3.new(-24, 6, 8), to = Vector3.new(-10, 6, 8), at = Vector3.new(6, 1, -14), title = "SUMMON AND MERGE FAMILIARS", line = "three that touch become one, stronger" },
	{ from = Vector3.new(26, 12, 44), to = Vector3.new(34, 9, 38), at = Vector3.new(45, 5, 22), title = "KEEP THE CRYSTAL LIT", line = "if they reach it, the lane goes dark" },
}
local BEAT_T = 2.8

local M = {}

function M.play(ctx, onDone)
	local camera = ctx.camera or workspace.CurrentCamera
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder = "IntroTour", true, false, 150
	gui.Parent = pg
	local function new(class, props, parent)
		local i = Instance.new(class)
		for k, v in props do i[k] = v end
		i.Parent = parent
		return i
	end
	local function tw(i, t, p, s)
		local x = TweenService:Create(i, TweenInfo.new(t, s or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
		x:Play()
		return x
	end
	-- letterbox bars slide in
	local top = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 0), ZIndex = 2 }, gui)
	local bot = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), ZIndex = 2 }, gui)
	tw(top, 0.5, { Size = UDim2.fromScale(1, 0.11) })
	tw(bot, 0.5, { Size = UDim2.fromScale(1, 0.11) })
	local black = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5 }, gui)
	-- caption: title with a short gold line and a point at each end (our banner form), the smaller line under it
	local cap = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.8, 0.12), ZIndex = 3 }, gui)
	local title = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.5), TextScaled = true, FontFace = SERIF, TextColor3 = GOLD, Text = "", ZIndex = 3 }, cap)
	new("UIStroke", { Color = Color3.fromRGB(20, 12, 6), Thickness = 1.5 }, title)
	new("UITextSizeConstraint", { MaxTextSize = 40 }, title)
	local rule = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58), Size = UDim2.fromOffset(0, 2), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 3 }, cap)
	for _, x in { 0, 1 } do
		local p = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.5), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 3 }, rule)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, p)
	end
	local line = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0.66), Size = UDim2.fromScale(1, 0.3), TextScaled = true, FontFace = SERIF, TextColor3 = PALE, Text = "", ZIndex = 3 }, cap)
	new("UITextSizeConstraint", { MaxTextSize = 22 }, line)
	-- SKIP: underlined text, bottom right inside the bar
	local skipped = false
	local skip = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -28, 0.945, 0), Size = UDim2.fromOffset(110, 34), BackgroundTransparency = 1, Text = "SKIP  >", FontFace = SERIF, TextSize = 18, TextColor3 = GOLD, ZIndex = 6 }, gui)
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, -5), Size = UDim2.fromOffset(64, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 6 }, skip)
	skip.Activated:Connect(function() skipped = true end)

	local hudWas = ctx.hud and ctx.hud.Visible
	if ctx.hud then ctx.hud.Visible = false end
	local beat, t0 = 1, os.clock()
	local fov0 = camera.FieldOfView
	local IN_T, GLIDE_T, OUT_T = 1.6, 1.0, 1.6
	local tStart, tOut = os.clock(), nil
	local lastCF, prevCF, prevBeat = nil, nil, 1
	local function smooth(x) x = math.clamp(x, 0, 1) return x * x * (3 - 2 * x) end
	RunService:BindToRenderStep("IntroTour", Enum.RenderPriority.Camera.Value + 5, function()
		local base = camera.CFrame -- this frame's game camera (menu shot, opening crane or play view), set before us
		local b = BEATS[beat]
		if not b then return end
		if beat ~= prevBeat then prevCF, prevBeat = lastCF, beat end -- start a glide from where the last shot ended
		local k = math.clamp((os.clock() - t0) / BEAT_T, 0, 1)
		local e = 1 - (1 - k) ^ 2 -- slow push that eases out
		local shot = CFrame.lookAt(b.from:Lerp(b.to, e), b.at)
		if prevCF then shot = prevCF:Lerp(shot, smooth((os.clock() - t0) / GLIDE_T)) end
		lastCF = shot
		local w = smooth((os.clock() - tStart) / IN_T) -- blend in from the game camera
		if tOut then w = w * (1 - smooth((os.clock() - tOut) / OUT_T)) end -- and back out into it at the end
		camera.CFrame = base:Lerp(shot, w)
		camera.FieldOfView = fov0 + (58 - fov0) * w
	end)
	for i, b in BEATS do
		if skipped then break end
		beat, t0 = i, os.clock()
		title.Text, line.Text = b.title, b.line
		title.TextTransparency, line.TextTransparency = 1, 1
		title.Position = UDim2.fromScale(0, 0.12)
		rule.Size = UDim2.fromOffset(0, 2)
		task.delay(0.25, function()
			tw(title, 0.6, { TextTransparency = 0, Position = UDim2.fromScale(0, 0) })
			tw(rule, 0.6, { Size = UDim2.fromOffset(math.min(420, 14 * #b.title), 2) }, Enum.EasingStyle.Quint)
			task.delay(0.3, function() tw(line, 0.5, { TextTransparency = 0.1 }) end)
		end)
		if ctx.sfx then pcall(ctx.sfx, "spotlight") end
		local tEnd = os.clock() + BEAT_T - 0.25
		while os.clock() < tEnd and not skipped do task.wait() end
		tw(title, 0.2, { TextTransparency = 1 })
		tw(line, 0.2, { TextTransparency = 1 })
		task.wait(0.25) -- no cut to black: the camera glides on into the next shot
	end
	-- glide back into the live play camera while the letterbox opens, then hand the camera back
	tOut = os.clock()
	tw(top, OUT_T, { Size = UDim2.fromScale(1, 0) })
	tw(bot, OUT_T, { Size = UDim2.fromScale(1, 0) })
	task.wait(OUT_T)
	RunService:UnbindFromRenderStep("IntroTour")
	camera.FieldOfView = fov0
	if ctx.hud then ctx.hud.Visible = hudWas end
	if onDone then onDone() end
	tw(black, 0.45, { BackgroundTransparency = 1 })
	for _, d in gui:GetDescendants() do
		if d:IsA("TextLabel") or d:IsA("TextButton") then tw(d, 0.3, { TextTransparency = 1 }) end
	end
	task.delay(0.5, function() gui:Destroy() end)
end

return M
