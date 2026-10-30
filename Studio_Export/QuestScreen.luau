--!nocheck
-- StarterPlayerScripts.QuestScreen (ModuleScript, T091): Daily and Story quest lists, progress bars, a Pin button for the HUD tracker.
--   QuestScreen.render(root, { state = Quests.State, now = os.time() }, close)
-- Reads Shared.Quests (data) and the quest state the server publishes as the player attribute QuestState (JSON). Until the server
-- publishes it (Quests is not wired into MatchService yet) every quest shows 0 progress. There is no claim button: the server has no
-- claim request yet, so a finished quest only shows "Done". Pin stores the player attribute PinnedQuest (local UI choice), read by QuestTracker.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Quests = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Quests"))
local Shell = require(script.Parent:WaitForChild("ScreenShell"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Shell.P

local QuestScreen = {}
local player = Players.LocalPlayer

-- the server's quest state for this player (empty state when none is published or it cannot be read)
function QuestScreen.stateNow()
	local raw = player:GetAttribute("QuestState")
	local ok, decoded = pcall(function()
		return type(raw) == "string" and HttpService:JSONDecode(raw) or nil
	end)
	local s = Quests.load(ok and decoded or nil)
	s.day = Quests.dayKey(os.time())
	return s
end

function QuestScreen.data()
	return { state = QuestScreen.stateNow() }
end

local function row(parent, q, state, o)
	local have, goal, done = Quests.status(state, q.id)
	local r = K.box(parent, { name = "Quest_" .. q.id, x = o.x, y = o.y, w = o.w, h = o.h, fill = P.ink, corner = 0.1, stroke = 0.03, strokeColor = done and P.gold or P.goldDark, z = 13 })
	Dialogs.text(r, { name = "Name", text = q.name, x = 0.03, y = 0.3, w = 0.62, h = 0.5, size = 20, color3 = P.cream, left = true, z = 14 })
	Dialogs.text(r, { name = "Progress", text = done and "Done" or (have .. "/" .. goal), x = 0.7, y = 0.3, w = 0.14, h = 0.4, size = 18, color3 = done and P.gold or P.muted, z = 14 })
	local pin = Dialogs.button(r, { name = "Pin", text = "Pin", fill = P.goldDark, x = 0.91, y = 0.3, w = 0.15, h = 0.5, size = 18, z = 14, onClick = function()
		player:SetAttribute("PinnedQuest", q.id)
	end })
	K.box(r, { name = "BarBack", y = 0.82, w = 0.94, h = 0.12, fill = P.ghost, corner = "pill", z = 14 })
	K.box(r, { name = "BarFill", x = 0.03 + 0.47 * (have / goal), y = 0.82, w = math.max(0.0001, 0.94 * have / goal), h = 0.12, fill = P.gold, corner = "pill", z = 15 })
	return r, pin
end

function QuestScreen.render(root, d, close)
	local h = Shell.frame(root, { name = "Quests", title = "QUESTS", sub = "Progress comes from the server" }, close)
	local list = K.box(h.body, { name = "List", y = 0.55, w = 1, h = 0.88 })
	local tab = "Daily"
	local function build()
		list:ClearAllChildren()
		if tab == "Daily" then
			for i, id in Quests.dailyIds(d.state.day) do
				local _, pin = row(list, Quests.byId[id], d.state, { x = 0.5, y = (i - 0.5) / 3, w = 1, h = 0.3 })
				if i == 1 then
					h.first = h.first or pin
				end
			end
		else
			for i, q in Quests.story do
				row(list, q, d.state, { x = ((i - 1) // 5 + 0.5) / 2, y = ((i - 1) % 5 + 0.5) / 5, w = 0.49, h = 0.18 })
			end
		end
	end
	local daily = Dialogs.button(h.body, { name = "TabDaily", text = "Daily", fill = P.goldDark, x = 0.1, y = 0.05, w = 0.18, h = 0.09, size = 22, z = 13, onClick = function() tab = "Daily" build() end })
	Dialogs.button(h.body, { name = "TabStory", text = "Story", fill = P.ghost, stroke = P.goldDark, x = 0.3, y = 0.05, w = 0.18, h = 0.09, size = 22, z = 13, onClick = function() tab = "Story" build() end })
	build()
	h.first = daily
	return h
end

Shell.register("Quests", QuestScreen)
return QuestScreen
