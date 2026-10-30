--!nocheck
-- CutsceneDirector (StarterPlayerScripts, LocalScript): the story captions and the boss-defeat cutscene, driven only by the server's events
-- (Begin, Stage, Kill, Clear, Settings), so it does not touch GameClient. Captions come from Shared.StageCaptions (generated from
-- Roblox Dev/Lore/Story/Stage Captions.md). Respects the player's settings: cinematics "off" shows nothing extra, "short" shows captions only,
-- reducedMotion shows captions without the typewriter, no pulse and no ash, flashes false drops the brightness flash.
-- Debug: fire the BindableEvent ReplicatedStorage.DirectorDebug with (kind, data) to run any event by hand.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local Captions = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StageCaptions"))
local events = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Event")
local TextAnim = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TextAnim"))

local settings = { cinematics = "full", reducedMotion = false, flashes = true, textAnim = "full" }
TextAnim.setSettings(settings) -- T607: the other screens read the same live table
local seenIntro = {}

local gui = Instance.new("ScreenGui")
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder = "CutsceneCaptions", true, false, 90
gui.Parent = player:WaitForChild("PlayerGui")
local label = Instance.new("TextLabel")
label.AnchorPoint, label.Position, label.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.7), UDim2.fromScale(0.9, 0.09)
label.BackgroundTransparency, label.Text, label.TextTransparency, label.TextStrokeTransparency = 1, "", 1, 1
label.Font, label.TextScaled = Enum.Font.Garamond, true
label.TextColor3, label.TextStrokeColor3 = Color3.fromRGB(255, 214, 120), Color3.fromRGB(10, 8, 14)
label.Parent = gui
local limit = Instance.new("UITextSizeConstraint")
limit.MaxTextSize, limit.MinTextSize = 40, 14
limit.Parent = label

-- one caption at a time, in order
local queue, running = {}, false
local function play(text)
	label.Text = text
	if TextAnim.mode(settings) ~= "off" then
		TweenService:Create(label, TweenInfo.new(0.2), { TextTransparency = 0, TextStrokeTransparency = 0.35 }):Play()
	else
		label.TextTransparency, label.TextStrokeTransparency = 0, 0.35
	end
	TextAnim.run(label, text, "typewrite", settings) -- T607: static when reduced motion, cinematics off or textAnim off
	task.wait(1.8)
	TweenService:Create(label, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.wait(0.7)
end
local function say(text)
	if not text then
		return
	end
	table.insert(queue, text)
	if running then
		return
	end
	running = true
	task.spawn(function()
		while #queue > 0 do
			play(table.remove(queue, 1))
		end
		running = false
	end)
end

local function fullCinema()
	return settings.cinematics == "full" and not settings.reducedMotion
end

-- the boss-defeat cutscene: the world drains of colour for a beat, then a warm bloom and a fall of gold lantern-ash
local function defeatCut()
	if not fullCinema() then
		return
	end
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name, cc.Parent = "DirectorGrade", Lighting
	TweenService:Create(cc, TweenInfo.new(0.35), { Saturation = -0.7, Brightness = -0.1, TintColor = Color3.fromRGB(200, 206, 255) }):Play()
	task.delay(0.9, function()
		local warm = { Saturation = 0.25, TintColor = Color3.fromRGB(255, 232, 190) }
		if settings.flashes then
			warm.Brightness = 0.1
		else
			warm.Brightness = 0
		end
		TweenService:Create(cc, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), warm):Play()
		task.delay(0.8, function()
			TweenService:Create(cc, TweenInfo.new(1.4), { Saturation = 0, Brightness = 0, TintColor = Color3.new(1, 1, 1) }):Play()
			task.delay(1.5, function()
				cc:Destroy()
			end)
		end)
	end)
	-- ash: a thin emitter that follows the camera for a few seconds
	local cam = workspace.CurrentCamera
	local p = Instance.new("Part")
	p.Name, p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = "DirectorAsh", true, false, false, false, 1
	p.Size = Vector3.new(40, 1, 6)
	p.Parent = workspace
	local em = Instance.new("ParticleEmitter")
	em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	em.Color = ColorSequence.new(Color3.fromRGB(255, 214, 120))
	em.LightEmission = 0.8
	em.Size = NumberSequence.new(0.28)
	em.Lifetime = NumberRange.new(2, 3.2)
	em.Rate = 0
	em.Speed = NumberRange.new(0.5, 2)
	em.Acceleration = Vector3.new(0, -3, 0)
	em.SpreadAngle = Vector2.new(25, 25)
	em.EmissionDirection = Enum.NormalId.Bottom
	em.Parent = p
	local conn
	conn = RunService.RenderStepped:Connect(function()
		p.CFrame = cam.CFrame * CFrame.new(0, 9, -16)
	end)
	task.delay(0.9, function()
		em.Rate = 90
		task.delay(1.4, function()
			em.Rate = 0
			task.delay(3.5, function()
				conn:Disconnect()
				p:Destroy()
			end)
		end)
	end)
end

local function introFor(stage)
	if seenIntro[stage] then
		return
	end
	seenIntro[stage] = true
	local c = Captions[stage]
	if c and c.intro then
		say(c.intro)
	end
end

local lastStage = 0
local lastSaid = {}
local function sayOnce(key, text) -- a caption for a recurring event at most once every 20 s
	local now = os.clock()
	if now - (lastSaid[key] or -1e9) >= 20 then
		lastSaid[key] = now
		say(text)
	end
end

local function handle(kind, data)
	if kind == "Settings" and type(data) == "table" then
		settings.cinematics = data.cinematics or settings.cinematics
		settings.reducedMotion = data.reducedMotion == true
		settings.flashes = data.flashes ~= false
		settings.textAnim = data.textAnim or "full"
	elseif kind == "Begin" and type(data) == "table" and data.snapshot then
		table.clear(seenIntro)
		lastStage = data.snapshot.stage or 1
		task.delay(1.5, introFor, lastStage)
	elseif kind == "Stage" and type(data) == "table" and data.stage then
		lastStage = data.stage
		introFor(data.stage)
		if data.boss then
			local c = Captions[data.stage]
			if c and c.boss_warning then
				task.delay(2.6, say, c.boss_warning)
			end
		end
	elseif kind == "Kill" and type(data) == "table" and data.kind == "Boss" then
		defeatCut()
		-- the Kill event carries no stage, so use the last stage a Stage event announced
		local c = Captions[lastStage]
		if c and c.boss_defeated then
			task.delay(0.6, say, c.boss_defeated)
		end
	elseif kind == "Perch" then
		sayOnce("perch", "[ A CROW PERCHES ]")
	elseif kind == "Steal" then
		sayOnce("steal", "[ A LAMP GOES DARK ]")
	elseif kind == "Drop" then
		sayOnce("drop", "[ THE LIGHT RETURNS ]")
	elseif kind == "Clear" and type(data) == "table" and data.stage then
		local c = Captions[data.stage]
		if c and c.set_clear then
			task.delay(3.4, say, c.set_clear)
		end
	end
end

events.OnClientEvent:Connect(handle)

local debug = ReplicatedStorage:FindFirstChild("DirectorDebug") or Instance.new("BindableEvent")
debug.Name = "DirectorDebug"
debug.Parent = ReplicatedStorage
debug.Event:Connect(handle)
