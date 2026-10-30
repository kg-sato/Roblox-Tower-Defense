--!nocheck
-- StarterPlayerScripts.InventoryScreen (ModuleScript, T090): silhouette grid of every familiar, tier stars, lore line for empty slots.
--   InventoryScreen.render(root, { seen = { [charId] = true } }, close)   -- builds one panel (tests, validator)
-- Reads Shared.Familiars (the roster) and the player attribute SeenPets (set by the server). Stars are the rarity rank
-- (Common 1 .. Celestial 6). An unmet familiar is a black silhouette with "???" and a hint line from its home and faction.
-- Open it with ScreenShell.open("Inventory").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Familiars = require(Shared:WaitForChild("Familiars"))
local Art = require(ReplicatedStorage:WaitForChild("FamiliarArt"))
local Shell = require(script.Parent:WaitForChild("ScreenShell"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Shell.P

local Inventory = {}
local RANK = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Celestial = 6 }
local COLS = 4

function Inventory.data()
	local seen = {}
	local csv = Players.LocalPlayer:GetAttribute("SeenPets")
	if type(csv) == "string" then
		for id in string.gmatch(csv, "[^,]+") do
			seen[id] = true
		end
	end
	return { seen = seen }
end

-- the line under the grid for one familiar
function Inventory.loreLine(f, known)
	if known then
		return string.format("%s, %s. %s (%s, %s).", f.name, f.epithet, ((f.roleText:gsub("^%l", string.upper))), f.faction, f.home)
	end
	return string.format("Not yet met. Somewhere near %s a %s familiar waits in the dark.", f.home, f.faction)
end

function Inventory.render(root, d, close)
	local n = #Familiars.order
	local owned = 0
	for _, id in Familiars.order do
		if d.seen[Familiars.byId[id].charId or id] then
			owned += 1
		end
	end
	local h = Shell.frame(root, { name = "Inventory", title = "FAMILIARS", sub = string.format("%d of %d met", owned, n) }, close)
	local rows = math.ceil(n / COLS)
	local grid = K.box(h.body, { name = "Grid", y = 0.39, w = 1, h = 0.76 })
	local lore = Dialogs.text(h.body, { name = "Lore", text = "", y = 0.88, w = 0.96, h = 0.22, size = 20, color3 = P.cream, z = 13 })
	local cw, ch = 1 / COLS, 1 / rows
	local cells = {}
	local function select(id)
		local f = Familiars.byId[id]
		lore.Text = Inventory.loreLine(f, d.seen[f.charId or id] == true)
		for cid, c in cells do
			c.UIStroke.Color = cid == id and P.gold or P.goldDark
		end
	end
	for i, id in Familiars.order do
		local f = Familiars.byId[id]
		local known = d.seen[f.charId or id] == true
		local col, row = (i - 1) % COLS, (i - 1) // COLS
		local c = Shell.cell(grid, { name = "Slot_" .. id, label = known and f.name or "Unknown familiar", x = (col + 0.5) * cw, y = (row + 0.5) * ch, w = cw * 0.94, h = ch * 0.92 })
		cells[id] = c
		local art = Art[id]
		local img = K.box(c, { class = "ImageLabel", name = "Art", x = 0.2, w = 0.3, h = 0.86, aspect = 1, z = 14 })
		img.BackgroundTransparency = 1
		img.ScaleType = Enum.ScaleType.Fit
		img.Image = art and art.cutout or ""
		img.ImageColor3 = known and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
		Dialogs.text(c, { name = "Name", text = known and f.name or "???", x = 0.62, y = 0.3, w = 0.6, h = 0.3, size = 20, color3 = known and P.cream or P.muted, z = 14 })
		for s = 1, 6 do
			local lit = s <= (RANK[f.rarity] or 1)
			K.box(c, { name = "Star" .. s, x = 0.44 + s * 0.07, y = 0.72, w = 0.05, h = 0.14, aspect = 1, rotation = 45, fill = lit and P.gold or P.ghost, z = 14 })
		end
		c.Activated:Connect(function()
			select(id)
		end)
		if i == 1 then
			h.first = c
		end
	end
	select(Familiars.order[1])
	return h
end

Shell.register("Inventory", Inventory)
return Inventory
