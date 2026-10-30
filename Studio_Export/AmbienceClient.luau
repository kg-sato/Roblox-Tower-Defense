--!nocheck
-- AmbienceClient (T166, 2026-10-29): LocalScript in StarterPlayer.StarterPlayerScripts. Starts the ambient bed (MusicFX.ambient) for the lobby and for
-- each stage set, plays set_morph when the fog veil closes on a new set, and caption_tick when a caption appears. It touches no one else's script: it reads
-- StageSetClient's CurrentSet attribute, the CutsceneCaptions label text and the server's Begin event. Lobby = before the first Begin; after that the
-- bed follows the set. Publishes the Studio test log as the script attribute "Log" (JSON { amb = {...}, cues = {...} }). Ear quality is UNVERIFIED.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Music = require(RS:WaitForChild("MusicFX"))
local Cues = require(RS:WaitForChild("SoundCues"))
local SoundFX = require(RS:WaitForChild("SoundFX"))
local player = Players.LocalPlayer
local psc = player:WaitForChild("PlayerScripts")
local ssc = psc:WaitForChild("StageSetClient", 20)

local inMatch, setId, firstSet = false, nil, true
local ambLog = {}
local function publish()
	script:SetAttribute("Log", game:GetService("HttpService"):JSONEncode({ amb = ambLog }))
end
local function bed()
	local key = inMatch and setId or "lobby"
	Music.ambient(key)
	table.insert(ambLog, { key, Music.ambBeds[key], os.clock() })
	publish()
end

if ssc then
	setId = ssc:GetAttribute("CurrentSet")
	ssc:GetAttributeChangedSignal("CurrentSet"):Connect(function()
		local new = ssc:GetAttribute("CurrentSet")
		if new == setId then return end
		setId = new
		if firstSet then
			firstSet = false
		elseif inMatch then
			Cues.fire(SoundFX, "set_morph", { volume = 0.8 }) -- the veil closes now; the bed swaps under it
		end
		bed()
	end)
end

RS:WaitForChild("Remotes"):WaitForChild("Event").OnClientEvent:Connect(function(kind)
	if kind == "Begin" and not inMatch then
		inMatch = true
		bed()
	end
end)

task.spawn(function() -- captions: the director's label changes its Text for every caption
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("CutsceneCaptions", 30)
	local label = gui and gui:FindFirstChildOfClass("TextLabel")
	if label then
		label:GetPropertyChangedSignal("Text"):Connect(function()
			if label.Text ~= "" then
				Cues.fire(SoundFX, "caption_tick", { volume = 0.8 })
			end
		end)
	end
end)

bed() -- lobby until the first Begin
