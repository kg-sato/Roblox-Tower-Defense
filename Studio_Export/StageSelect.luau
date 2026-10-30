--!nocheck
-- StarterPlayerScripts.StageSelect (ModuleScript, T093): the stage map, one row per stage set, one tile per stage. DISPLAY ONLY.
--   StageSelect.render(root, { best = n }, close)
-- Data: Shared.StageSets (set names and stage counts), Config.isBossStage (boss tiles). `best` is the highest stage reached, from the player
-- attribute BestStage when the server publishes it (otherwise 1: only stage 1 is open). Stages above best + 1 are locked (disabled tiles).
-- Picking a tile only fills the detail line; there is no request to start or jump to a stage (the server decides the run).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local StageSets = require(Shared:WaitForChild("StageSets"))
local Shell = require(script.Parent:WaitForChild("ScreenShell"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Shell.P

local StageSelect = {}

function StageSelect.data()
	return { best = tonumber(Players.LocalPlayer:GetAttribute("BestStage")) or 1 }
end

function StageSelect.render(root, d, close)
	local h = Shell.frame(root, { name = "Stages", title = "STAGES", sub = "Best stage " .. d.best }, close)
	local grid = K.box(h.body, { name = "Sets", y = 0.4, w = 1, h = 0.8 })
	local detail = Dialogs.text(h.body, { name = "Detail", text = "Pick a stage.", y = 0.9, w = 0.96, h = 0.14, size = 20, color3 = P.cream, z = 13 })
	local n = #StageSets.list
	local stage = 0
	local firstOpen
	for si, set in StageSets.list do
		local row = K.box(grid, { name = "Set" .. si, y = (si - 0.5) / n, w = 1, h = 0.93 / n, z = 13 })
		Dialogs.text(row, { name = "SetName", text = set.name, x = 0.17, w = 0.32, h = 0.6, size = 20, color3 = P.gold, left = false, z = 14 })
		for k = 1, set.stages do
			stage += 1
			local s = stage
			local boss = Config.isBossStage(s)
			local locked = s > d.best + 1
			local tile = Dialogs.button(row, { name = "Stage" .. s, text = tostring(s), fill = boss and P.goldDark or P.ghost, stroke = boss and P.gold or P.goldDark, x = 0.42 + k * 0.105, w = 0.095, h = 0.92, size = 22, z = 14, onClick = function()
				detail.Text = string.format("Stage %d, %s.%s", s, set.name, boss and " Boss stage." or "")
			end })
			if locked then
				K.setDisabled(tile, true)
			elseif not firstOpen then
				firstOpen = tile
			end
		end
	end
	h.first = firstOpen or h.close
	return h
end

Shell.register("Stages", StageSelect)
return StageSelect
