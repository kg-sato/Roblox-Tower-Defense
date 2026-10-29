--!nocheck
-- HideUI (StarterPlayerScripts, LocalScript), T118: H shows or hides the whole HUD screen (for recording).
-- The saved Hide UI setting (hideUi) sets the state whenever the server sends the settings. Kept out of GameClient
-- because GameClient is at Studio's 200,000-character source limit.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer

local gui = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 15)
if not gui then
	return
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.H then
		gui.Enabled = not gui.Enabled
	end
end)

local events = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Event")
events.OnClientEvent:Connect(function(kind, data)
	if kind == "Settings" and type(data) == "table" then
		gui.Enabled = data.hideUi ~= true
	end
end)
