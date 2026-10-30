--!nocheck
-- StarterPlayerScripts.FamiliarPanel (ModuleScript, T095): the detail panel for one familiar.
--   local FamiliarPanel = require(script.Parent.FamiliarPanel)
--   FamiliarPanel.open("Ember")                       -- live panel (own ScreenGui); FamiliarPanel.close()
--   FamiliarPanel.render(root, "Ember", { owned = true, xp = 130, lastUsed = 1.7e9, now = 1.7e9 })   -- builds one panel (tests)
-- Shows: art (silhouette until the player has met it), name, epithet, rarity, faction, element, home, a lore quote, damage /
-- speed / range, bond level with progress and mood (Shared.Bond), and the evolve preview (tier 2 and tier 3 text and damage).
-- Reads only server-set state: the player attribute SeenPets (which familiars were met; set by MatchService) and the player attribute
-- BondState (JSON of Shared.Bond state, { [familiarId] = { xp, lastUsed, day, dayXp } }). MatchService does not publish BondState
-- yet (T007 left Bond unwired), so until it does every familiar shows bond level 1 and mood Curious.
-- init() adds a "Details" button under the card in the Collection screen (CollectionScreen sets the gui attribute Selected).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Familiars = require(Shared:WaitForChild("Familiars"))
local Bond = require(Shared:WaitForChild("Bond"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local TextAnim = require(Shared:WaitForChild("TextAnim"))
local Art = require(ReplicatedStorage:WaitForChild("FamiliarArt"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local Icons = require(script.Parent:WaitForChild("StatusIcons")) -- T641 rarity chip and faction badge
local P = Dialogs.PALETTE

local FamiliarPanel = {}
local player = Players.LocalPlayer

local function fmt(n)
	return NumberFormat.format(n)
end

-- the bond entry the server published for a familiar (nil when none)
function FamiliarPanel.bondFor(id: string)
	local raw = player:GetAttribute("BondState")
	if type(raw) ~= "string" then
		return nil
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok then
		return nil
	end
	return Bond.load(decoded)[id]
end

function FamiliarPanel.isOwned(id: string): boolean
	local f = Familiars.byId[id]
	local csv = player:GetAttribute("SeenPets")
	if not f or type(csv) ~= "string" then
		return false
	end
	for seen in string.gmatch(csv, "[^,]+") do
		if seen == (f.charId or f.id) then
			return true
		end
	end
	return false
end

-- numbers shown on the panel: damage at a tier, shots per second, range, bond
function FamiliarPanel.facts(id: string, data)
	local f = Familiars.byId[id]
	local key = f.charId or f.id
	local pet = Config.PETS[key]
	local out = { rarity = f.rarity }
	if pet then
		out.dmg1, out.dmg2, out.dmg3 = Config.petDamage(key, 1), Config.petDamage(key, 2), Config.petDamage(key, 3)
		out.speed, out.range = 1 / math.max(pet.cooldown, 0.05), pet.range
	end
	local entry = data.xp and { xp = data.xp, lastUsed = data.lastUsed or 0, day = 0, dayXp = 0 } or nil
	local xp = entry and entry.xp or 0
	out.level = Bond.level(xp)
	local into, need = Bond.progress(xp)
	out.into, out.need = into, need
	out.mood = (Bond.mood(entry and { [id] = entry } or {}, id, data.now or workspace:GetServerTimeNow())).id
	return out
end

local function cell(parent, name, x, y, w, h, label, value, valueSize)
	local c = K.box(parent, { name = name, x = x, y = y, w = w, h = h, fill = P.ink, corner = 0.15, stroke = 0.02, strokeColor = P.goldDark, z = 12 })
	Dialogs.text(c, { name = "Label", text = label, y = 0.27, w = 0.92, h = 0.4, size = 16, color3 = P.muted, z = 13 })
	Dialogs.text(c, { name = "Value", text = value, y = 0.72, w = 0.92, h = 0.5, size = valueSize or 24, color3 = P.gold, z = 13 })
	return c
end

-- data: owned, xp, lastUsed, now
function FamiliarPanel.render(root, id, data, onClose)
	K.use("Sols")
	local f = Familiars.byId[id]
	local owned = data.owned == true
	local facts = FamiliarPanel.facts(id, data)
	local dim = K.dim(root, 0.5)
	dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dim.Name = "FamiliarDim"
	local panel = K.box(dim, { name = "FamiliarPanel", w = 0.92, h = 0.9, fill = P.panel, corner = 0.04, stroke = 0.01, strokeColor = Config.RARITIES[f.rarity].color, z = 11 })

	-- left: art (black silhouette until met)
	local art = Art[id]
	local frame = K.box(panel, { name = "ArtFrame", x = 0.17, y = 0.5, w = 0.28, h = 0.86, fill = P.ink, corner = 0.06, stroke = 0.012, strokeColor = P.goldDark, z = 12 })
	local img = K.box(frame, { class = "ImageLabel", name = "Art", w = 0.9, h = 0.9, z = 13 })
	img.Image = art and art.cutout or ""
	img.ScaleType = Enum.ScaleType.Fit
	img.ImageColor3 = owned and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)

	-- right: text blocks
	local X0, W = 0.325, 0.64 -- left edge and width of the right column (fractions of the panel)
	local function line(name, text, y, h, size, color, font)
		return Dialogs.text(panel, { name = name, text = text, x = X0, y = y, w = W, h = h, size = size, color3 = color, left = true, font = font, z = 12 })
	end
	line("Name", owned and f.name or "???", 0.1, 0.12, 34, P.gold, K.T.titleFont)
	local rc = Config.RARITIES[f.rarity].color
	local sub = Dialogs.text(panel, { name = "Rarity", text = owned and (f.rarity .. "  -  " .. f.epithet) or (f.rarity .. " familiar"), x = X0, y = 0.2, w = W, h = 0.07, size = 18, color3 = rc:Lerp(Color3.new(1, 1, 1), 0.35), left = true, z = 12 })
	Icons.badge(panel, Icons.rarity(f.rarity), { Name = "RarityChip", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.94, 0.235), Size = UDim2.fromScale(0.07, 0.07), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 13 })
	if owned then
		Icons.badge(panel, Icons.faction(f.faction), { Name = "FactionBadge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.94, 0.3), Size = UDim2.fromScale(0.07, 0.07), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 13 })
		line("Meta", f.faction .. "  -  " .. f.element .. "  -  " .. f.home, 0.27, 0.06, 16, P.muted)
		line("Quote", "\u{201C}" .. f.voice.summon .. "\u{201D}", 0.345, 0.08, 18, P.cream)
		line("Role", string.upper(f.role) .. ": " .. f.roleText, 0.445, 0.105, 16, P.muted)
	else
		line("Locked", "Not yet met. Pull this familiar to read its story.", 0.36, 0.2, 20, P.muted)
	end
	-- stats row
	local stats = K.box(panel, { name = "Stats", x = X0 + W / 2, y = 0.605, w = W, h = 0.12, z = 12 })
	cell(stats, "DamageStat", 0.17, 0.5, 0.32, 1, "DAMAGE", owned and facts.dmg1 and fmt(facts.dmg1) or "?")
	cell(stats, "SpeedStat", 0.5, 0.5, 0.32, 1, "SHOTS / SEC", owned and facts.speed and string.format("%.1f", facts.speed) or "?")
	cell(stats, "RangeStat", 0.83, 0.5, 0.32, 1, "RANGE", owned and facts.range and fmt(facts.range) or "?")
	-- bond
	local bondRow = K.box(panel, { name = "Bond", x = X0 + W / 2, y = 0.735, w = W, h = 0.09, z = 12 })
	Dialogs.text(bondRow, { name = "BondLabel", text = string.format("BOND %d  -  %s", facts.level, facts.mood), x = 0.0, y = 0.5, w = 0.46, h = 1, size = 18, color3 = P.cream, left = true, z = 13 })
	local track = K.box(bondRow, { name = "BondTrack", x = 0.74, y = 0.5, w = 0.5, h = 0.5, fill = P.ink, corner = "pill", stroke = 0.03, strokeColor = P.goldDark, clip = true, z = 13 })
	local frac = facts.need > 0 and facts.into / facts.need or 1
	local fill = K.box(track, { name = "BondFill", x = 0, y = 0.5, w = math.max(frac, 0.02), h = 1, anchor = Vector2.new(0, 0.5), reason = "progress fill grows from the left", fill = P.gold, corner = "pill", z = 14 })
	-- evolve preview
	local ev = K.box(panel, { name = "Evolve", x = X0 + W / 2, y = 0.905, w = W, h = 0.16, z = 12 })
	local function tierCell(name, x, tier, text, dmg)
		local c = K.box(ev, { name = name, x = x, y = 0.5, w = 0.48, h = 1, fill = P.ink, corner = 0.12, stroke = 0.02, strokeColor = P.goldDark, z = 13 })
		local head = string.format("TIER %d%s", tier, (owned and dmg) and ("  -  " .. fmt(dmg) .. " dmg") or "")
		Dialogs.text(c, { name = "Head", text = head, y = 0.2, w = 0.94, h = 0.3, size = 16, color3 = P.gold, z = 14 })
		Dialogs.text(c, { name = "Text", text = owned and text or "???", y = 0.66, w = 0.94, h = 0.56, size = 16, color3 = P.cream, z = 14 })
	end
	tierCell("Tier2", 0.255, 2, f.tier2, facts.dmg2)
	tierCell("Tier3", 0.745, 3, f.tier3, facts.dmg3)

	local closeBtn = Dialogs.button(panel, { name = "Close", text = "Close", fill = P.ghost, stroke = P.goldDark, x = 0.92, y = 0.07, w = 0.12, h = 0.1, size = 20, onClick = function() if onClose then onClose() end end })
	return { dim = dim, panel = panel, close = closeBtn }
end

local gui, current
function FamiliarPanel.close()
	if current then
		current.dim:Destroy()
		current = nil
		GuiService.SelectedObject = nil
	end
end

function FamiliarPanel.isOpen()
	return current ~= nil
end

function FamiliarPanel.open(id: string)
	if not Familiars.byId[id] then
		return false
	end
	FamiliarPanel.close()
	if not gui or not gui.Parent then
		gui = Instance.new("ScreenGui")
		gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "FamiliarDetail", false, 120, true
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = player:WaitForChild("PlayerGui")
		K.box(gui, { name = "Root" })
	end
	local entry = FamiliarPanel.bondFor(id)
	current = FamiliarPanel.render(gui.Root, id, { owned = FamiliarPanel.isOwned(id), xp = entry and entry.xp, lastUsed = entry and entry.lastUsed }, FamiliarPanel.close)
	if TextAnim.settings.reducedMotion ~= true then
		K.popIn(current.panel)
	end
	GuiService.SelectedObject = current.close
	return true
end

function FamiliarPanel.init()
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape and current and not Dialogs.isOpen() then
			FamiliarPanel.close()
		end
	end)
	-- a Details button under the card in the Collection screen
	task.spawn(function()
		local col = player:WaitForChild("PlayerGui"):WaitForChild("Collection", 30)
		local detail = col and col:WaitForChild("Panel"):WaitForChild("Detail", 10)
		if not detail then
			return
		end
		local btn = Dialogs.button(detail, { name = "DetailsButton", text = "Details", fill = P.goldDark, x = 0.5, y = 0.955, w = 0.5, h = 0.075, size = 18, onClick = function()
			local id = col:GetAttribute("Selected")
			if type(id) == "string" then
				FamiliarPanel.open(id)
			end
		end, z = 20 })
		btn.ZIndex = 20
	end)
end

return FamiliarPanel
