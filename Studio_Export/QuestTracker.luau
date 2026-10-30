--!nocheck
-- StarterPlayerScripts.QuestTracker (ModuleScript, T091): one pinned quest line in the HUD, collapsible.
--   QuestTracker.init()                  -- called by the UILane2 LocalScript; builds nothing unless enabled
--   QuestTracker.lineFor(state, pinned)  -- pure: the text, e.g. "Roll 5 familiars  2/5", for tests
-- Shows the quest named by the player attribute PinnedQuest (set by the Pin button on QuestScreen), else the first unfinished daily.
-- Click the line to fold it into a small "Q" chip and click again to open it. Reads server state only (QuestScreen.stateNow).
-- Off unless Config.QUEST_TRACKER is true (or the player attribute QATracker, set for tests).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Quests = require(Shared:WaitForChild("Quests"))
local QuestScreen = require(script.Parent:WaitForChild("QuestScreen"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Dialogs.PALETTE

local QuestTracker = {}
local player = Players.LocalPlayer

function QuestTracker.lineFor(state, pinned)
	local q = pinned and Quests.byId[pinned]
	if not q then
		for _, id in Quests.dailyIds(state.day) do
			local _, _, done = Quests.status(state, id)
			if not done then
				q = Quests.byId[id]
				break
			end
		end
	end
	if not q then
		return "All of today's quests are done"
	end
	local have, goal, done = Quests.status(state, q.id)
	return q.name .. "  " .. (done and "done" or (have .. "/" .. goal))
end

function QuestTracker.build(parent)
	K.use("Sols")
	local frame = K.box(parent, { name = "Tracker", x = 0.01, y = 0.2, w = 0.3, h = 0.075, anchor = Vector2.new(0, 0.5), reason = "left-pinned HUD line" })
	local line = K.box(frame, { class = "TextButton", name = "Line", fill = P.panel, alpha = 0.15, corner = 0.2, stroke = 0.04, strokeColor = P.goldDark })
	line.Text, line.AutoButtonColor = "", false
	line:SetAttribute("Label", "Quest tracker")
	local text = Dialogs.text(line, { name = "Text", text = "", x = 0.04, w = 0.92, h = 0.8, size = 18, color3 = P.cream, left = true })
	local chip = K.box(frame, { class = "TextButton", name = "Chip", x = 0.1, w = 0.2, h = 1, fill = P.panel, corner = "pill", stroke = 0.05, strokeColor = P.gold })
	chip.Text, chip.AutoButtonColor, chip.Visible = "", false, false
	chip:SetAttribute("Label", "Open quest tracker")
	Dialogs.text(chip, { name = "Q", text = "Q", w = 0.7, h = 0.7, size = 22, color3 = P.gold })
	local collapsed = false
	local function set(c)
		collapsed = c
		line.Visible, chip.Visible = not c, c
	end
	line.Activated:Connect(function() set(true) end)
	chip.Activated:Connect(function() set(false) end)
	local function refresh()
		text.Text = QuestTracker.lineFor(QuestScreen.stateNow(), player:GetAttribute("PinnedQuest"))
	end
	refresh()
	return { frame = frame, line = line, chip = chip, text = text, refresh = refresh, set = set, isCollapsed = function() return collapsed end }
end

function QuestTracker.init()
	if not (Config.QUEST_TRACKER == true or player:GetAttribute("QATracker") == true) then
		player:GetAttributeChangedSignal("QATracker"):Once(QuestTracker.init)
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "QuestTracker", false, 25, true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local h = QuestTracker.build(K.box(gui, { name = "Root" }))
	for _, a in { "PinnedQuest", "QuestState" } do
		player:GetAttributeChangedSignal(a):Connect(h.refresh)
	end
end

return QuestTracker
