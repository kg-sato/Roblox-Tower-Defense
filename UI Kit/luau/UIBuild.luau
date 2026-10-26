--!nocheck
-- UIBuild: builds screens from UIScreens into a parent (default StarterGui), validates each, returns a report.
--   local Build = require(game.ReplicatedStorage.UIKit.UIBuild)
--   print(Build.all())            -- every screen, all hidden except the first
--   print(Build.one("Shop"))      -- one screen
-- In Studio's Edit mode, StarterGui is not drawn. To LOOK at a screen, enter Play mode (or build into
-- PlayerGui in Play mode): Build.one("Shop", game.Players.LocalPlayer.PlayerGui)

local K = require(script.Parent:WaitForChild("UIKit"))
local Screens = require(script.Parent:WaitForChild("UIScreens"))
local validate = require(script.Parent:WaitForChild("UIValidate"))

local Build = {}

function Build.one(name, parent)
	local fn = assert(Screens[name], "no screen called " .. tostring(name))
	local gui = fn(K, parent)
	local problems = validate(gui)
	local report = ("%s: %s"):format(name, #problems == 0 and "OK (Scale only, centered)" or (#problems .. " problems"))
	if #problems > 0 then
		report ..= "\n  " .. table.concat(problems, "\n  ", 1, math.min(#problems, 15))
	end
	return report, gui
end

function Build.all(parent)
	local lines = {}
	for i, name in ipairs(Screens.order) do
		local report, gui = Build.one(name, parent)
		gui.Enabled = i == 1
		table.insert(lines, report)
	end
	return table.concat(lines, "\n")
end

return Build
