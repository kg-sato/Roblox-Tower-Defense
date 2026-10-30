--!nocheck
-- StarterPlayerScripts.ResultsScreen (ModuleScript, T074): the panel shown after a stage clear.
--   require(script.Parent.ResultsScreen).init()          -- called once by the UILane2 LocalScript
--   ResultsScreen.render(root, { stage, perfect, boss, gems, gold, combo, lore, nextText })   -- builds one panel (tests, validator)
-- Reads only what the server sends: the "Clear" event (stage, perfect, gem bonus, combo) and the latest "State" snapshot
-- (coins). The only action it sends is the same "StartWave" the HUD button sends; the server validates it.
-- Off unless Config.RESULTS_SCREEN is true (or the player attribute QAResults, set by the server for tests).
-- Built from Dialogs.text / Dialogs.button so it uses the shared palette and the 14 px floor; Scale-only (UIKit validator).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LoreFragments = require(Shared:WaitForChild("LoreFragments"))
local StageCaptions = require(Shared:WaitForChild("StageCaptions"))
local TextAnim = require(Shared:WaitForChild("TextAnim"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Dialogs.PALETTE

local ResultsScreen = {}

-- one lore line for a cleared stage: a found-note text for that stage, else the stage caption, else a plain line
function ResultsScreen.loreFor(stage: number, boss: boolean?): string
	if boss then
		local cap = StageCaptions[stage]
		if cap and cap.boss_defeated then
			return cap.boss_defeated
		end
	end
	local found = LoreFragments.forStage(stage)
	if #found > 0 then
		return found[1].text
	end
	local cap = StageCaptions[stage]
	return cap and cap.intro or "The lamps burn a little brighter."
end

local function stat(parent, name, x, label, value)
	local cell = K.box(parent, { name = name, x = x, y = 0.5, w = 0.3, h = 1, fill = P.ink, corner = 0.12, stroke = 0.02, strokeColor = P.goldDark })
	Dialogs.text(cell, { name = "Label", text = label, y = 0.27, w = 0.9, h = 0.3, size = 18, color3 = P.muted })
	Dialogs.text(cell, { name = "Value", text = value, y = 0.68, w = 0.9, h = 0.5, size = 30, color3 = P.gold })
	return cell
end

-- d: stage, perfect, boss, gems (bonus), gold, combo, lore, nextText
function ResultsScreen.render(root, d, close)
	K.use("Sols")
	local dim = K.dim(root, 0.4)
	dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dim.Name = "ResultsDim"
	local panel = K.box(dim, { name = "ResultsPanel", w = 0.62, h = 0.84, fill = P.panel, corner = 0.05, stroke = 0.012, strokeColor = P.gold, z = 11 })
	Dialogs.text(panel, { name = "Title", text = string.format("STAGE %d CLEARED", d.stage), y = 0.1, w = 0.88, h = 0.13, size = 32, color3 = P.gold, font = K.T.titleFont, z = 12 })
	local sub = d.boss and "The guardian is down." or (d.perfect and "Perfect: nothing leaked." or "The lamps held.")
	if d.combo and d.combo > 1 then
		sub = sub .. "  Streak " .. d.combo
	end
	Dialogs.text(panel, { name = "Sub", text = sub, y = 0.2, w = 0.88, h = 0.08, size = 18, color3 = P.muted, z = 12 })
	K.box(panel, { name = "Rule", y = 0.27, w = 0.88, h = 0.006, fill = P.goldDark, z = 12 })
	local row = K.box(panel, { name = "Stats", y = 0.42, w = 0.9, h = 0.2, z = 12 })
	stat(row, "WaveStat", 0.17, "WAVE", tostring(d.stage))
	stat(row, "GoldStat", 0.5, "GOLD", NumberFormat and NumberFormat.format and NumberFormat.format(d.gold or 0) or tostring(d.gold or 0))
	stat(row, "GemStat", 0.83, "GEMS", "+" .. tostring(d.gems or 0))
	Dialogs.text(panel, { name = "Lore", text = d.lore or "", y = 0.665, w = 0.84, h = 0.2, size = 20, color3 = P.cream, z = 12 })
	local next = Dialogs.button(panel, { name = "Next", text = d.nextText or ("Start stage " .. (d.stage + 1)), fill = P.goldDark, x = 0.7, y = 0.87, w = 0.5, h = 0.14, onClick = function() if close then close(true) end end })
	local closeBtn = Dialogs.button(panel, { name = "Close", text = "Close", fill = P.ghost, stroke = P.goldDark, x = 0.2, y = 0.87, w = 0.3, h = 0.14, onClick = function() if close then close(false) end end })
	return { dim = dim, panel = panel, next = next, close = closeBtn }
end

local gui, current, coins = nil, nil, 0
local player = Players.LocalPlayer

local function enabled()
	return Config.RESULTS_SCREEN == true or player:GetAttribute("QAResults") == true
end

function ResultsScreen.isOpen()
	return current ~= nil
end

function ResultsScreen.hide()
	if current then
		current.dim:Destroy()
		current = nil
	end
end

function ResultsScreen.show(d)
	ResultsScreen.hide()
	if not gui or not gui.Parent then
		gui = Instance.new("ScreenGui")
		gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "Results", false, 150, true
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = player:WaitForChild("PlayerGui")
		K.box(gui, { name = "Root" })
	end
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local h
	h = ResultsScreen.render(gui.Root, d, function(startNext)
		if current ~= h then
			return
		end
		ResultsScreen.hide()
		if startNext then
			remotes:WaitForChild("Action"):FireServer("StartWave") -- same request as the HUD button; the server decides
		end
	end)
	current = h
	if TextAnim.settings.reducedMotion ~= true then
		K.popIn(h.panel)
	end
	game:GetService("GuiService").SelectedObject = h.next
end

function ResultsScreen.init()
	local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Event")
	event.OnClientEvent:Connect(function(kind, data)
		if kind == "State" and type(data) == "table" and type(data.coins) == "number" then
			coins = data.coins
		elseif kind == "Clear" and type(data) == "table" and enabled() then
			task.delay(0.9, function() -- let the stage-clear banner and the next State arrive first
				local stage = data.stage
				ResultsScreen.show({
					stage = stage, perfect = data.perfect, boss = Config.isBossStage(stage), gems = data.bonus, combo = data.combo, gold = coins,
					lore = ResultsScreen.loreFor(stage, Config.isBossStage(stage)),
				})
			end)
		elseif (kind == "Stage" or kind == "Begin" or kind == "Overrun") and current then
			ResultsScreen.hide() -- a new wave started: the panel is stale
		end
	end)
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape and current and not Dialogs.isOpen() then
			ResultsScreen.hide()
		end
	end)
end

return ResultsScreen
