--!nocheck
-- StarterPlayerScripts.BoardScreen (ModuleScript, T093): the weekly best-wave leaderboard. FAKE ROWS in Studio.
--   BoardScreen.render(root, { rows = { {rank, name, wave} }, week = n }, close)
-- Data shape follows Shared.LeaderboardRules: entries { userId, packed } are ranked with LeaderboardRules.rank (best wave first, earlier finish wins).
-- BoardScreen.fakeRows() builds ten sample entries through pack/rank so the layout is tested with the real shape. The live OrderedDataStore read
-- is not written yet; until the server publishes real rows (player attribute BoardRows, JSON of { {userId, packed, name} }) the screen shows the samples
-- and says so.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local L = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LeaderboardRules"))
local Shell = require(script.Parent:WaitForChild("ScreenShell"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Shell.P

local BoardScreen = {}
local NAMES = { "Lampkeeper", "BrassFinch", "GreyVeil", "Tock", "Mirelle", "WickAndWax", "Foghorn", "Cogsworth", "Quill", "Nightjar" }

-- ten sample entries -> ranked rows { rank, name, wave }
function BoardScreen.fakeRows()
	local entries, byId = {}, {}
	for i, name in NAMES do
		local wave = 60 - i * 4 + (i % 3) * 2
		byId[1000 + i] = name
		table.insert(entries, { userId = 1000 + i, packed = L.pack(wave, i * 3600) })
	end
	local rows = {}
	for _, r in L.rank(entries, 10) do
		table.insert(rows, { rank = r.rank, name = byId[r.userId], wave = r.wave })
	end
	return rows
end

function BoardScreen.data()
	local raw = Players.LocalPlayer:GetAttribute("BoardRows")
	local ok, decoded = pcall(function()
		return type(raw) == "string" and HttpService:JSONDecode(raw) or nil
	end)
	if ok and type(decoded) == "table" and #decoded > 0 then
		local byId, entries = {}, {}
		for _, e in decoded do
			byId[e.userId] = tostring(e.name or e.userId)
			table.insert(entries, { userId = e.userId, packed = e.packed })
		end
		local rows = {}
		for _, r in L.rank(entries, 10) do
			table.insert(rows, { rank = r.rank, name = byId[r.userId], wave = r.wave })
		end
		return { rows = rows, week = L.weekKey(os.time()), fake = false }
	end
	return { rows = BoardScreen.fakeRows(), week = L.weekKey(os.time()), fake = true }
end

function BoardScreen.render(root, d, close)
	local h = Shell.frame(root, { name = "Board", title = "WEEKLY BEST WAVE", sub = d.fake and "Sample rows" or ("Week " .. d.week) }, close)
	local list = K.box(h.body, { name = "List", y = 0.5, w = 1, h = 0.98 })
	for i, r in d.rows do
		local col, row = (i - 1) // 5, (i - 1) % 5
		local f = K.box(list, { name = "Row" .. r.rank, x = (col + 0.5) / 2, y = (row + 0.5) / 5, w = 0.485, h = 0.17, fill = P.ink, corner = 0.12, stroke = 0.03, strokeColor = r.rank <= 3 and P.gold or P.goldDark, z = 13 })
		Dialogs.text(f, { name = "Rank", text = "#" .. r.rank, x = 0.09, w = 0.13, h = 0.55, size = 22, color3 = P.gold, z = 14 })
		Dialogs.text(f, { name = "Name", text = r.name, x = 0.25, w = 0.42, h = 0.55, size = 20, color3 = P.cream, left = true, z = 14 })
		Dialogs.text(f, { name = "Wave", text = "Wave " .. r.wave, x = 0.84, w = 0.28, h = 0.5, size = 20, color3 = P.muted, z = 14 })
	end
	h.first = h.close
	return h
end

Shell.register("Board", BoardScreen)
return BoardScreen
