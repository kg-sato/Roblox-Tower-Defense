-- MusicBootstrap: plays the soundtrack during Studio playtests. Separate from GameClient on purpose (no gameplay code is touched).
-- The tracks load from local Studio files (rbxasset://sounds/music/), so this only runs in Studio. For a published game the tracks must
-- be uploaded to Roblox (owner's OK), MusicCatalog switched to asset ids, and the Studio check removed. Delete this script to silence it.
-- Credits for the tracks: Audio/CREDITS.md. To change the mood later: Music.play("menu"), Music.setTension(0..1), Music.duck(...).
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end
local Music = require(game:GetService("ReplicatedStorage"):WaitForChild("MusicFX"))
Music.setVolumes({ music = 0.8 })
Music.play("play")
