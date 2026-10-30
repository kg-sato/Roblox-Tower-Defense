--!nocheck
-- StarterPlayerScripts.SummonScreen (ModuleScript, 2026-10-30): the Summon menu, behind Config.SUMMON_MENU (default off).
-- Layout from Roblox Dev/Research/Game Design/Gacha Retention Study.md ("Recommended layout"): banner on the left; pity, luck, Rates,
-- Skip, Roll x1 and Roll x10 on the right; a strip of the latest pulls along the bottom. Odds live here (the HUD odds chip is hidden).
--   SummonScreen.attach({ rollBtn, oddsChip })  -- called by GameClient when the flag is on: hides the HUD roll button and odds chip outside
--                                                  the tutorial and puts a brass SUMMON button in the roll button's place
--   Opened through ScreenShell/ScreenRouter as "Summon" (ReplicatedStorage.OpenRouter:Fire("Summon")).
-- The server decides everything: a roll is the existing Action "Roll"; x10 is ten of them, each one paid and checked by the server.
-- The client only reads the server's State snapshot (gems, rollCost, pity, luck, gacha) and the Roll / Denied events.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Shell = require(script.Parent:WaitForChild("ScreenShell"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Shell.P

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action, Event = remotes:WaitForChild("Action"), remotes:WaitForChild("Event")
local player = Players.LocalPlayer

local ART = { ring = "rbxassetid://119143998198845", card = "rbxassetid://93758813189086", plate = "rbxassetid://125691901559686", gear = "rbxassetid://74207288462160" }
local X10_GAP = 0.12 -- seconds between the ten rolls of a x10; above the server's 0.05 s action gap so none is dropped

local Summon = {}
local snap = {} -- last State snapshot from the server
local pulls = {} -- newest first, at most 10: { pet, rarity }
local ui = nil -- live refs while the screen is open
local status = ""
local busy = false

local function pct(n)
	return (n >= 10 and string.format("%.0f", n) or string.format("%.1f", n)) .. "%"
end

-- chance per rarity from the same table the server rolls with
function Summon.odds(luck)
	local w = Config.rarityWeights(luck or 0)
	local total = 0
	for _, v in w do
		total += v
	end
	local out = {}
	for _, r in Config.RARITY_ORDER do
		table.insert(out, { rarity = r, chance = total > 0 and (w[r] or 0) / total * 100 or 0 })
	end
	return out
end

local function cost()
	return snap.rollCost or Config.ROLL_COST
end

local function refresh()
	if not (ui and ui.panel.Parent) then
		ui = nil
		return
	end
	local gems, c = snap.gems or 0, cost()
	ui.gems.Text = "Gems  " .. gems
	local left = math.max(1, (snap.pityEvery or Config.PITY_EVERY) - (snap.sincePity or 0))
	ui.pity.Text = "Epic or better within " .. left .. (left == 1 and " roll" or " rolls")
	local g = snap.gacha or {}
	local extra = {}
	if g.floorOn then
		table.insert(extra, "Rare or better in " .. tostring(g.rollsToFloor or 10))
	end
	if g.oilOn then
		table.insert(extra, "Lantern Oil " .. tostring(g.oil or 0) .. " / " .. tostring(g.oilNeed or 100))
	end
	ui.extra.Text = table.concat(extra, "   ")
	ui.luck.Text = "Luck +" .. math.floor((snap.luck or 0) * 100 + 0.5) .. "%"
	ui.x1.Text = "ROLL x1   " .. c
	ui.x10.Text = "ROLL x10   " .. c * 10
	ui.x1.TextTransparency = gems >= c and 0 or 0.45
	ui.x10.TextTransparency = gems >= c * 10 and 0 or 0.45
	ui.skip.Text = "Skip reveal: " .. (player:GetAttribute("SummonSkip") and "ON" or "OFF")
	ui.status.Text = status
	for i = 1, 10 do
		local chip, p = ui.chips[i], pulls[i]
		chip.Visible = p ~= nil
		if p then
			local col = Config.RARITIES[p.rarity] and Config.RARITIES[p.rarity].color or P.cream
			chip.BackgroundColor3 = col:Lerp(Color3.new(0, 0, 0), 0.55)
			chip:FindFirstChildOfClass("UIStroke").Color = col
			chip.Name_.Text = (Config.PETS[p.pet] and Config.PETS[p.pet].name or tostring(p.pet))
			chip.Rar.Text = string.upper(p.rarity)
			chip.Rar.TextColor3 = col
		end
	end
	for _, row in ui.oddsRows do
		row.label.Text = string.upper(row.rarity) .. "   " .. pct(row.get())
	end
end

local function roll(n)
	if busy then
		return
	end
	busy = true
	status = ""
	task.spawn(function()
		if (snap.gems or 0) < cost() * n then -- a x10 needs all ten up front, so it never stops half way
			status = n > 1 and ("A x" .. n .. " needs " .. cost() * n .. " gems.") or "Not enough gems. Gems come from waves, level-ups and bosses."
			n = 0
		end
		for i = 1, n do
			if (snap.gems or 0) < cost() then
				if i == 1 then
					status = "Not enough gems. Gems come from waves, level-ups and bosses."
				end
				break
			end
			Action:FireServer("Roll")
			task.wait(X10_GAP)
		end
		busy = false
		refresh()
	end)
end

function Summon.data()
	return {}
end

function Summon.render(root, _, close)
	local h = Shell.frame(root, { name = "Summon", title = "SUMMON", sub = "Lampwick Draw" }, close)
	local body = h.body
	-- banner: ironwork ring turning slowly around a tarot card
	local banner = K.box(body, { name = "Banner", x = 0.27, y = 0.42, w = 0.52, h = 0.8, fill = P.ink, corner = 0.04, stroke = 0.006, strokeColor = P.goldDark, z = 13 })
	banner.ClipsDescendants = true
	local ring = Instance.new("ImageLabel")
	ring.Name, ring.BackgroundTransparency, ring.Image, ring.ScaleType = "Ring", 1, ART.ring, Enum.ScaleType.Fit
	ring.AnchorPoint, ring.Position, ring.Size, ring.ZIndex = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.47), UDim2.fromScale(0.9, 0.9), 14
	ring.Parent = banner
	TweenService:Create(ring, TweenInfo.new(60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 }):Play()
	local card = ring:Clone()
	card.Name, card.Image, card.Size, card.ZIndex, card.Rotation = "Card", ART.card, UDim2.fromScale(0.36, 0.62), 15, 0
	card.ImageColor3 = Color3.fromRGB(255, 214, 150)
	card.Parent = banner
	Dialogs.text(banner, { name = "BannerTitle", text = "THE LAMPWICK DRAW", x = 0.5, y = 0.88, w = 0.9, h = 0.1, size = 24, color3 = P.gold, font = K.T.titleFont, z = 16 })
	Dialogs.text(banner, { name = "BannerSub", text = "Every familiar can answer. One pool, no time limit.", x = 0.5, y = 0.95, w = 0.9, h = 0.06, size = 15, color3 = P.muted, z = 16 })

	-- odds list: drawn over the banner when Rates is on
	local oddsBox = K.box(banner, { name = "Odds", fill = P.panel, alpha = 0, z = 17 })
	oddsBox.Visible = false
	Dialogs.text(oddsBox, { name = "OddsTitle", text = "RATES", x = 0.5, y = 0.08, w = 0.8, h = 0.1, size = 24, color3 = P.gold, font = K.T.titleFont, z = 18 })
	local oddsRows = {}
	for i, r in Config.RARITY_ORDER do
		local col = Config.RARITIES[r].color
		local l = Dialogs.text(oddsBox, { name = "Odds_" .. r, text = r, x = 0.5, y = 0.2 + i * 0.1, w = 0.8, h = 0.08, size = 20, color3 = col, z = 18 })
		table.insert(oddsRows, { rarity = r, label = l, get = function()
			for _, o in Summon.odds(snap.luck) do
				if o.rarity == r then
					return o.chance
				end
			end
			return 0
		end })
	end
	Dialogs.text(oddsBox, { name = "OddsNote", text = "These are the server's own odds at your luck.", x = 0.5, y = 0.92, w = 0.9, h = 0.07, size = 15, color3 = P.muted, z = 18 })

	-- right column
	local col = K.box(body, { name = "Side", x = 0.77, y = 0.42, w = 0.44, h = 0.8, z = 13 })
	local function line(name, y, size, color)
		return Dialogs.text(col, { name = name, text = "", x = 0, y = y, w = 1, h = 0.09, size = size, color3 = color, left = true, z = 14 }) -- left labels anchor on their left edge
	end
	local gemsL = line("Gems", 0.05, 24, P.gold)
	local pityL = line("Pity", 0.16, 20, P.cream)
	local extraL = line("Extra", 0.25, 18, P.cream)
	local luckL = line("Luck", 0.34, 18, P.muted)
	local rates = Dialogs.button(col, { name = "Rates", text = "Rates", fill = P.ghost, stroke = P.goldDark, x = 0.24, y = 0.47, w = 0.46, h = 0.1, size = 20, z = 14, onClick = function()
		oddsBox.Visible = not oddsBox.Visible
	end })
	local skip = Dialogs.button(col, { name = "Skip", text = "Skip reveal", fill = P.ghost, stroke = P.goldDark, x = 0.76, y = 0.47, w = 0.46, h = 0.1, size = 18, z = 14, onClick = function()
		player:SetAttribute("SummonSkip", not player:GetAttribute("SummonSkip"))
		refresh()
	end })
	local x1 = Dialogs.button(col, { name = "Roll1", text = "ROLL x1", fill = P.goldDark, x = 0.5, y = 0.64, w = 1, h = 0.13, size = 24, z = 14, onClick = function() roll(1) end })
	local x10 = Dialogs.button(col, { name = "Roll10", text = "ROLL x10", fill = P.goldDark, x = 0.5, y = 0.8, w = 1, h = 0.13, size = 24, z = 14, onClick = function() roll(10) end })
	local statusL = line("Status", 0.93, 15, P.muted)
	statusL.TextWrapped = true
	-- Dialogs.button keeps its text in a child label; point the refresh at that label
	local function textOf(b)
		local l = b:FindFirstChildWhichIsA("TextLabel", true)
		return l or b
	end

	-- result strip: the latest ten pulls, newest on the left
	local strip = K.box(body, { name = "Pulls", x = 0.5, y = 0.93, w = 1, h = 0.13, z = 13 })
	local chips = {}
	for i = 1, 10 do
		local c = K.box(strip, { name = "Pull" .. i, x = (i - 0.5) / 10, y = 0.5, w = 0.094, h = 0.94, fill = P.ink, corner = 0.12, stroke = 0.04, strokeColor = P.goldDark, z = 14 })
		local n = Dialogs.text(c, { name = "Name_", text = "", x = 0.5, y = 0.36, w = 0.94, h = 0.42, size = 14, color3 = P.cream, z = 15 })
		n.Name = "Name_"
		local r = Dialogs.text(c, { name = "Rar", text = "", x = 0.5, y = 0.76, w = 0.94, h = 0.32, size = 14, color3 = P.muted, z = 15 })
		r.Name = "Rar"
		c.Visible = false
		chips[i] = c
	end
	if #pulls == 0 then
		status = "Your pulls appear along the bottom."
	end
	ui = { panel = h.panel, gems = gemsL, pity = pityL, extra = extraL, luck = luckL, x1 = textOf(x1), x10 = textOf(x10), skip = textOf(skip), status = statusL, chips = chips, oddsRows = oddsRows }
	refresh()
	h.first = x1
	return h
end

-- HUD side: hide the roll button and odds chip outside the tutorial, and put a brass SUMMON button where the roll button was
function Summon.attach(env)
	local rollBtn, oddsChip = env.rollBtn, env.oddsChip
	local holder = rollBtn.Parent
	local btn = Instance.new("ImageButton")
	btn.Name, btn.BackgroundTransparency, btn.Image, btn.ScaleType, btn.AutoButtonColor = "AF_hr_summon", 1, "", Enum.ScaleType.Stretch, false
	btn.Visible = false
	local velvet = Instance.new("Frame")
	velvet.Name, velvet.BorderSizePixel, velvet.AnchorPoint = "AF_hr_velvet", 0, Vector2.new(0.5, 0.5)
	velvet.Position, velvet.Size, velvet.ZIndex, velvet.BackgroundColor3 = UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.93, 0.74), 5, Color3.new(1, 1, 1)
	Instance.new("UICorner", velvet).CornerRadius = UDim.new(0.34, 0)
	local grad = Instance.new("UIGradient")
	grad.Rotation, grad.Color = 90, ColorSequence.new(Color3.fromRGB(96, 66, 44), Color3.fromRGB(34, 22, 26))
	grad.Parent = velvet
	local st = Instance.new("UIStroke")
	st.Color, st.Thickness, st.Transparency = Color3.fromRGB(226, 182, 96), 2, 0.2
	st.Parent = velvet
	velvet.Parent = btn
	local plate = Instance.new("ImageLabel")
	plate.Name, plate.BackgroundTransparency, plate.Image, plate.ScaleType = "AF_hr_img", 1, ART.plate, Enum.ScaleType.Stretch
	plate.Size, plate.ZIndex, plate.ImageTransparency = UDim2.fromScale(1, 1), 6, 0.25
	plate.Parent = btn
	local gear = Instance.new("ImageLabel")
	gear.Name, gear.BackgroundTransparency, gear.Image, gear.ScaleType = "AF_hr_gear", 1, ART.gear, Enum.ScaleType.Fit
	gear.AnchorPoint, gear.Position, gear.Size, gear.ZIndex = Vector2.new(0.5, 0.5), UDim2.fromScale(0.17, 0.5), UDim2.fromScale(0.3, 0.9), 7
	gear.Parent = btn
	TweenService:Create(gear, TweenInfo.new(40, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 }):Play()
	local title = Instance.new("TextLabel")
	title.Name, title.BackgroundTransparency, title.Text, title.Font, title.TextScaled = "AF_hr_title", 1, "SUMMON", Enum.Font.Fantasy, true
	title.TextColor3, title.AnchorPoint, title.Position, title.Size, title.ZIndex = Color3.fromRGB(255, 222, 150), Vector2.new(0.5, 0.5), UDim2.fromScale(0.6, 0.42), UDim2.fromScale(0.56, 0.34), 8
	title.Parent = btn
	local sub = title:Clone()
	sub.Name, sub.Text, sub.Font, sub.Position, sub.Size, sub.TextColor3 = "AF_hr_sub", "Lampwick Draw", Enum.Font.GothamMedium, UDim2.fromScale(0.6, 0.7), UDim2.fromScale(0.5, 0.2), Color3.fromRGB(214, 190, 150)
	sub.Parent = btn
	btn.Parent = holder
	local function follow()
		btn.AnchorPoint, btn.Position, btn.Size = rollBtn.AnchorPoint, rollBtn.Position, rollBtn.Size
	end
	follow()
	rollBtn:GetPropertyChangedSignal("Position"):Connect(follow)
	rollBtn:GetPropertyChangedSignal("Size"):Connect(follow)
	btn.Activated:Connect(function()
		local ev = ReplicatedStorage:FindFirstChild("OpenRouter")
		if ev then
			ev:Fire("Summon")
		else
			Shell.open("Summon")
		end
	end)
	-- outside the tutorial the roll button and odds chip give way to the menu; the tutorial still teaches ROLL on the HUD
	local function apply()
		local tut = snap.tutorial == true
		btn.Visible = not tut
		rollBtn.Visible = tut
		if oddsChip then
			oddsChip.Visible = tut
		end
	end
	rollBtn:GetPropertyChangedSignal("Visible"):Connect(function()
		if rollBtn.Visible ~= (snap.tutorial == true) then
			apply()
		end
	end)
	Summon.apply = apply
	apply()
end

function Summon.init() end

Event.OnClientEvent:Connect(function(kind, data)
	if kind == "State" and type(data) == "table" then
		snap = data
	elseif kind == "Begin" and type(data) == "table" and type(data.snapshot) == "table" then
		snap = data.snapshot
		table.clear(pulls)
	elseif kind == "Roll" and type(data) == "table" and type(data.pet) == "string" and not data.chosen then
		table.insert(pulls, 1, { pet = data.pet, rarity = tostring(data.rarity or (Config.PETS[data.pet] and Config.PETS[data.pet].rarity) or "Common") })
		if #pulls > 10 then
			table.remove(pulls)
		end
		status = ""
	elseif kind == "Denied" and type(data) == "table" and ui then
		status = tostring(data.reason or "")
	else
		return
	end
	if Summon.apply then
		Summon.apply()
	end
	refresh()
end)

Shell.register("Summon", Summon)
return Summon
