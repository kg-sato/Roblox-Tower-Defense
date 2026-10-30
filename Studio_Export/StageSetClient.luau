--!nocheck
-- StageSetClient (StarterPlayerScripts, LocalScript): shows the stage set for this player's current stage and applies
-- its light and fog (Shared.StageSets). The sets are built once on the server under workspace.StageSets; the inactive
-- ones are moved to a local hidden folder, so other players in the server can be on other sets (T32: the map is shared).
-- 2026-10-29: a set change is now a MORPH instead of a snap: a fog-coloured veil rises (0.6 s), the backdrop swaps behind it,
-- then the light, fog and sky colours ease to the new set over 2.4 s while the veil lifts. The first set, Settings with
-- cinematics other than "full", and reducedMotion still snap.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local StageSets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StageSets"))
local Music = require(ReplicatedStorage:WaitForChild("MusicFX"))
local events = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Event")
local setsFolder = workspace:WaitForChild("StageSets")
local BossArena = require(script.Parent:WaitForChild("BossArena")) -- T172 boss arena dressing

local hidden = Instance.new("Folder") -- client-only parking spot for the sets that are not shown
hidden.Name = "HiddenStageSets"
hidden.Parent = ReplicatedStorage

local settings = { cinematics = "full", reducedMotion = false }
local current = nil
local morphing, pendingStage = false, nil

local veilGui = Instance.new("ScreenGui")
veilGui.Name, veilGui.IgnoreGuiInset, veilGui.ResetOnSpawn, veilGui.DisplayOrder = "SetMorph", true, false, 80
veilGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local veil = Instance.new("Frame")
veil.Size, veil.BackgroundTransparency, veil.BorderSizePixel = UDim2.fromScale(1, 1), 1, 0
veil.BackgroundColor3 = Color3.new(0, 0, 0)
veil.Parent = veilGui
local veilGradient = Instance.new("UIGradient") -- darker at the edges, so it reads as fog closing in rather than a flat fade
veilGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 0) })
veilGradient.Rotation = 90
veilGradient.Parent = veil

local function find(id)
	return setsFolder:FindFirstChild(id) or hidden:FindFirstChild(id)
end

local function swap(set)
	Music.play(set.music) -- crossfades (Music.fade) to this set's track state
	for _, s in StageSets.list do
		local f = find(s.id)
		if f then
			f.Parent = s.id == set.id and setsFolder or hidden
		end
	end
end

local function snapLighting(L)
	Lighting.ClockTime, Lighting.Brightness = L.ClockTime, L.Brightness
	Lighting.Ambient, Lighting.OutdoorAmbient = L.Ambient, L.OutdoorAmbient
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		atmo.Color, atmo.Decay, atmo.Density, atmo.Haze = L.AtmosphereColor, L.AtmosphereDecay, L.Density, L.Haze
	end
end

-- ease every light and fog value to the target over t seconds (ClockTime takes the short way round the clock)
local function easeLighting(L, t)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	local from = { ct = Lighting.ClockTime, br = Lighting.Brightness, am = Lighting.Ambient, oa = Lighting.OutdoorAmbient }
	if atmo then
		from.ac, from.ad, from.den, from.haze = atmo.Color, atmo.Decay, atmo.Density, atmo.Haze
	end
	local dct = ((L.ClockTime - from.ct + 12) % 24) - 12
	local alpha = Instance.new("NumberValue")
	local tween = TweenService:Create(alpha, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = 1 })
	alpha.Changed:Connect(function(a)
		Lighting.ClockTime = (from.ct + dct * a) % 24
		Lighting.Brightness = from.br + (L.Brightness - from.br) * a
		Lighting.Ambient = from.am:Lerp(L.Ambient, a)
		Lighting.OutdoorAmbient = from.oa:Lerp(L.OutdoorAmbient, a)
		if atmo then
			atmo.Color = from.ac:Lerp(L.AtmosphereColor, a)
			atmo.Decay = from.ad:Lerp(L.AtmosphereDecay, a)
			atmo.Density = from.den + (L.Density - from.den) * a
			atmo.Haze = from.haze + (L.Haze - from.haze) * a
		end
	end)
	tween.Completed:Connect(function()
		snapLighting(L) -- land exactly on the target
		alpha:Destroy()
	end)
	tween:Play()
end

local apply
local function morph(set)
	morphing = true
	veil.BackgroundColor3 = set.lighting.FogColor
	TweenService:Create(veil, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { BackgroundTransparency = 0 }):Play()
	task.wait(0.65)
	swap(set)
	easeLighting(set.lighting, 2.4)
	TweenService:Create(veil, TweenInfo.new(1.4, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
	task.wait(1.5)
	morphing = false
	if pendingStage then
		local st = pendingStage
		pendingStage = nil
		apply(st)
	end
end

apply = function(stage)
	BossArena.setStage(stage)
	local set = StageSets.forStage(stage or 1)
	if morphing then
		pendingStage = stage
		return
	end
	if set.id == current then
		return
	end
	local first = current == nil
	current = set.id
	script:SetAttribute("CurrentSet", set.id)
	if first or settings.cinematics ~= "full" or settings.reducedMotion then
		swap(set)
		snapLighting(set.lighting)
		return
	end
	task.spawn(morph, set)
end

-- wait for every set the data lists (they are built by separate server scripts)
for _, s in StageSets.list do
	setsFolder:WaitForChild(s.id, 10)
end
apply(1)
events.OnClientEvent:Connect(function(kind, data)
	if kind == "Settings" and type(data) == "table" then
		settings.cinematics = data.cinematics or settings.cinematics
		settings.reducedMotion = data.reducedMotion == true
	elseif kind == "Begin" and type(data) == "table" and data.snapshot then
		apply(data.snapshot.stage)
	elseif (kind == "State" or kind == "Stage") and type(data) == "table" and data.stage then
		apply(data.stage)
	end
end)
