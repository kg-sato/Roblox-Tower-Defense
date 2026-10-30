--!nocheck
-- StarterPlayerScripts.ProgressToastsClient (LocalScript, T652): shows a toast when the server reports an unlocked achievement or a finished quest.
-- Does nothing unless Config.ACHIEVEMENTS_ON or Config.QUESTS_ON is true (both default OFF), so it never touches GameClient.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
if not (Config.ACHIEVEMENTS_ON or Config.QUESTS_ON) then
	return
end
local Toasts = require(script.Parent:WaitForChild("Toasts"))
local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Event")
event.OnClientEvent:Connect(function(kind, p)
	if type(p) ~= "table" then
		return
	end
	if kind == "Achievement" and Config.ACHIEVEMENTS_ON then
		Toasts.show(tostring(p.name or "Achievement") .. (p.gems and (" (+" .. tostring(p.gems) .. " gems)") or ""), { kind = "success", title = "Achievement" })
	elseif kind == "Quest" and Config.QUESTS_ON then
		Toasts.show(tostring(p.name or "Quest") .. " is ready to claim", { kind = "success", title = "Quest" })
	end
end)
