--!nocheck
-- StarterPlayerScripts.PassScreen (ModuleScript, T092): the battle pass track, 40 levels, cosmetic only. DISPLAY ONLY.
--   PassScreen.render(root, { xp = n, premium = false }, close)
-- Rewards follow Roblox Dev/Design/Content Plans.md "Battle pass" (free: 20 gems at levels 5,10..40, lantern colours at 8, 24, 32, title cards
-- 12 and 36, a frame at 16; premium: outfits 1,10,20,30, palette skins 5,15,25,35, emotes 3,13,23,33, golden trail at 40, frames and title
-- cards on the other multiples of 4). The Robux price is NOT decided (the design says the user decides), so none is shown and the premium
-- button is disabled ("Not on sale yet"). There is no purchase code of any kind in this module. XP is the player attribute PassXP (server).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Shell = require(script.Parent:WaitForChild("ScreenShell"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Shell.P

local PassScreen = {}
PassScreen.XP_PER_LEVEL = 100 -- PROPOSAL in the design notes
PassScreen.LEVELS = 40
local PER_PAGE = 8

local function has(levels, lv)
	return table.find(levels, lv) ~= nil
end

-- what a level gives on each track (strings or nil), from the design notes
function PassScreen.reward(lv)
	local free, prem
	if lv % 5 == 0 then
		free = "20 gems"
	end
	if has({ 8, 24, 32 }, lv) then
		free = "Lantern colour"
	elseif has({ 12, 36 }, lv) then
		free = "Title card"
	elseif lv == 16 then
		free = "Frame"
	end
	if has({ 1, 10, 20, 30 }, lv) then
		prem = "Outfit"
	elseif has({ 5, 15, 25, 35 }, lv) then
		prem = "Palette skin"
	elseif has({ 3, 13, 23, 33 }, lv) then
		prem = "Emote"
	elseif lv == 40 then
		prem = "Golden trail"
	elseif lv % 4 == 0 then
		prem = (lv // 4) % 2 == 0 and "Frame" or "Title card"
	end
	return free, prem
end

function PassScreen.data()
	local p = Players.LocalPlayer
	return { xp = tonumber(p:GetAttribute("PassXP")) or 0, premium = p:GetAttribute("PassPremium") == true }
end

function PassScreen.render(root, d, close)
	local level = math.min(PassScreen.LEVELS, d.xp // PassScreen.XP_PER_LEVEL)
	local h = Shell.frame(root, { name = "Pass", title = "LANTERN PASS", sub = string.format("Level %d of %d", level, PassScreen.LEVELS) }, close)
	K.box(h.body, { name = "XpBack", x = 0.5, y = 0.04, w = 0.96, h = 0.035, fill = P.ghost, corner = "pill", z = 13 })
	local frac = level >= PassScreen.LEVELS and 1 or math.clamp((d.xp % PassScreen.XP_PER_LEVEL) / PassScreen.XP_PER_LEVEL, 0, 1)
	K.box(h.body, { name = "XpFill", x = 0.02 + 0.48 * frac, y = 0.04, w = math.max(0.0001, 0.96 * frac), h = 0.035, fill = P.gold, corner = "pill", z = 14 })
	Dialogs.text(h.body, { name = "Tracks", text = "Free track on top, premium (cosmetic only) below. Premium never gives gems, rolls or power.", y = 0.12, w = 0.96, h = 0.07, size = 16, color3 = P.muted, z = 13 })
	local page = 1
	local pages = PassScreen.LEVELS // PER_PAGE
	local strip = K.box(h.body, { name = "Strip", y = 0.52, w = 1, h = 0.58 })
	local pageLabel
	local function build()
		strip:ClearAllChildren()
		for i = 1, PER_PAGE do
			local lv = (page - 1) * PER_PAGE + i
			local free, prem = PassScreen.reward(lv)
			local reached = lv <= level
			local col = K.box(strip, { name = "Level" .. lv, x = (i - 0.5) / PER_PAGE, w = 0.118, h = 1, fill = P.ink, corner = 0.08, stroke = 0.03, strokeColor = reached and P.gold or P.goldDark, z = 13 })
			Dialogs.text(col, { name = "Num", text = tostring(lv), y = 0.1, w = 0.8, h = 0.14, size = 22, color3 = reached and P.gold or P.muted, z = 14 })
			Dialogs.text(col, { name = "Free", text = free or "-", y = 0.36, w = 0.92, h = 0.3, size = 16, color3 = free and P.cream or P.muted, z = 14 })
			K.box(col, { name = "Split", y = 0.55, w = 0.8, h = 0.012, fill = P.goldDark, z = 14 })
			Dialogs.text(col, { name = "Premium", text = prem or "-", y = 0.76, w = 0.92, h = 0.3, size = 16, color3 = (prem and d.premium) and P.cream or P.muted, z = 14 })
		end
		if pageLabel then
			pageLabel.Text = string.format("Levels %d to %d", (page - 1) * PER_PAGE + 1, page * PER_PAGE)
		end
	end
	local prev = Dialogs.button(h.body, { name = "Prev", text = "Back", fill = P.ghost, stroke = P.goldDark, x = 0.1, y = 0.94, w = 0.16, h = 0.1, size = 20, z = 13, onClick = function() page = (page - 2) % pages + 1 build() end })
	pageLabel = Dialogs.text(h.body, { name = "Page", text = "", x = 0.3, y = 0.94, w = 0.2, h = 0.08, size = 18, color3 = P.muted, z = 13 })
	Dialogs.button(h.body, { name = "Next", text = "Next", fill = P.ghost, stroke = P.goldDark, x = 0.5, y = 0.94, w = 0.16, h = 0.1, size = 20, z = 13, onClick = function() page = page % pages + 1 build() end })
	local buy = Dialogs.button(h.body, { name = "Premium", text = d.premium and "Premium unlocked" or "Not on sale yet", fill = P.goldDark, x = 0.87, y = 0.94, w = 0.24, h = 0.1, size = 18, z = 13 })
	K.setDisabled(buy, true) -- no purchase path exists here
	build()
	h.first = prev
	return h
end

Shell.register("Pass", PassScreen)
return PassScreen
