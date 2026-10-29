--!nocheck
-- StageSetClient (StarterPlayerScripts, LocalScript): shows the stage set for this player's current stage and applies
-- its light and fog (Shared.StageSets). The sets are built once on the server under workspace.StageSets; the inactive
-- ones are moved to a local hidden folder, so other players in the server can be on other sets (T32: the map is shared).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local StageSets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StageSets"))
local Music = require(ReplicatedStorage:WaitForChild("MusicFX"))
local events = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Event")
local setsFolder = workspace:WaitForChild("StageSets")

local hidden = Instance.new("Folder") -- client-only parking spot for the sets that are not shown
hidden.Name = "HiddenStageSets"
hidden.Parent = ReplicatedStorage

local current = nil

local function find(id)
	return setsFolder:FindFirstChild(id) or hidden:FindFirstChild(id)
end

local function apply(stage)
	local set = StageSets.forStage(stage or 1)
	if set.id == current then
		return
	end
	current = set.id
	Music.play(set.music) -- crossfades (Music.fade) to this set's track state
	for _, s in StageSets.list do
		local f = find(s.id)
		if f then
			f.Parent = s.id == set.id and setsFolder or hidden
		end
	end
	local L = set.lighting
	Lighting.ClockTime, Lighting.Brightness = L.ClockTime, L.Brightness
	Lighting.Ambient, Lighting.OutdoorAmbient = L.Ambient, L.OutdoorAmbient
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		atmo.Color, atmo.Decay, atmo.Density, atmo.Haze = L.AtmosphereColor, L.AtmosphereDecay, L.Density, L.Haze
	end
	script:SetAttribute("CurrentSet", set.id)
end

-- wait for every set the data lists (they are built by separate server scripts)
for _, s in StageSets.list do
	setsFolder:WaitForChild(s.id, 10)
end
apply(1)
events.OnClientEvent:Connect(function(kind, data)
	if kind == "Begin" and type(data) == "table" and data.snapshot then
		apply(data.snapshot.stage)
	elseif (kind == "State" or kind == "Stage") and type(data) == "table" and data.stage then
		apply(data.stage)
	end
end)
