--!nonstrict
-- CollectionScreen (LocalScript, StarterPlayerScripts, T103). The familiar collection: a FAMILIARS button opens a panel with the 12 familiars.
-- A familiar the player has pulled (server attribute Players.LocalPlayer:GetAttribute("SeenPets"), a comma list set by MatchService) shows its
-- picture, name and rarity; one not yet pulled shows only its silhouette (the same cutout tinted black), "???" and its rarity colour.
-- Selecting a familiar shows its lore card (full bio, uploaded art in ReplicatedStorage.FamiliarArt) or, for an unseen one, the big silhouette.
-- T058: a faction filter row (All + each faction, from Shared.Familiars) hides the cells of other factions; the count always shows all familiars.
-- The server decides what counts as seen; this script only displays it. All sizes are Scale (the cards keep their aspect ratio with a constraint).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Familiars = require(Shared:WaitForChild("Familiars"))
local Art = require(ReplicatedStorage:WaitForChild("FamiliarArt"))
local Icons = require(script.Parent:WaitForChild("StatusIcons")) -- T641 rarity chips

local BRASS = Color3.fromRGB(214, 170, 96)
local INK = Color3.fromRGB(26, 23, 34)
local PARCH = Color3.fromRGB(238, 226, 196)
local FONT = Enum.Font.Merriweather

local gui = Instance.new("ScreenGui")
gui.Name = "Collection"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in props do
		i[k] = v
	end
	i.Parent = parent
	return i
end

local function label(parent, props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextColor3 = PARCH, TextScaled = true, TextWrapped = true,
		Size = props.size, Position = props.pos or UDim2.new(), AnchorPoint = props.anchor or Vector2.zero, Text = props.text or "",
		TextXAlignment = props.align or Enum.TextXAlignment.Center, Name = props.name or "Label", ZIndex = props.z or 1,
	}, parent)
	if props.color then
		l.TextColor3 = props.color
	end
	new("UITextSizeConstraint", { MaxTextSize = props.max or 28, MinTextSize = 8 }, l)
	return l
end

-- the open button: small, in the left rail under SETTINGS
local openBtn = new("TextButton", {
	Name = "Open", Size = UDim2.fromScale(0.075, 0.05), Position = UDim2.fromScale(0.008, 0.745), BackgroundColor3 = INK, AutoButtonColor = true,
	Text = "", ZIndex = 5,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0.25, 0) }, openBtn)
new("UIStroke", { Color = BRASS, Thickness = 2 }, openBtn)
local openText = label(openBtn, { text = "FAMILIARS", size = UDim2.fromScale(0.9, 0.62), pos = UDim2.fromScale(0.05, 0.19), color = BRASS, max = 22, z = 6 })
openText.Name = "OpenText"

local dim = new("Frame", { Name = "Dim", Visible = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 9, Active = true }, gui) -- T640: the HUD no longer shows through
local panel = new("Frame", {
	Name = "Panel", Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.84),
	BackgroundColor3 = INK, ZIndex = 10,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0.025, 0) }, panel)
new("UIStroke", { Color = BRASS, Thickness = 3 }, panel)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(38, 32, 46), Color3.fromRGB(20, 17, 28)) }, panel)
label(panel, { name = "Title", text = "FAMILIARS", size = UDim2.fromScale(0.4, 0.075), pos = UDim2.fromScale(0.03, 0.02), color = BRASS, align = Enum.TextXAlignment.Left, max = 40, z = 11 })
local countLabel = label(panel, { name = "Count", text = "0/12", size = UDim2.fromScale(0.2, 0.07), pos = UDim2.fromScale(0.45, 0.025), color = Color3.fromRGB(255, 226, 150), align = Enum.TextXAlignment.Left, max = 30, z = 11 })
local closeBtn = new("TextButton", { Name = "Close", Size = UDim2.fromScale(0.05, 0.07), Position = UDim2.fromScale(0.94, 0.02), BackgroundColor3 = Color3.fromRGB(60, 44, 40), Text = "X", Font = FONT, TextColor3 = PARCH, TextScaled = true, ZIndex = 12 }, panel)
new("UICorner", { CornerRadius = UDim.new(0.2, 0) }, closeBtn)
new("UIAspectRatioConstraint", { AspectRatio = 1 }, closeBtn)

local grid = new("ScrollingFrame", {
	Name = "Grid", Size = UDim2.fromScale(0.56, 0.76), Position = UDim2.fromScale(0.03, 0.2), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 11,
}, panel)
new("UIGridLayout", { CellSize = UDim2.fromScale(0.3, 0.3), CellPadding = UDim2.fromScale(0.03, 0.02), SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal }, grid)

local detail = new("Frame", { Name = "Detail", Size = UDim2.fromScale(0.34, 0.76), Position = UDim2.fromScale(0.63, 0.2), BackgroundTransparency = 1, ZIndex = 11 }, panel)
local cardImg = new("ImageLabel", { Name = "Card", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 12 }, detail)
new("UIAspectRatioConstraint", { AspectRatio = 630 / 880 }, cardImg)
local lockedNote = label(detail, { name = "Locked", text = "", size = UDim2.fromScale(1, 0.2), pos = UDim2.fromScale(0, 0.8), color = Color3.fromRGB(255, 236, 190), max = 26, z = 13 })

local cells = {}
local selected = nil

-- faction filter row: chips across the panel, labels are the first word of the faction name (at 14 px or more)
local factions, seenFaction = { "All" }, {}
for _, id in Familiars.order do
	local fa = Familiars.byId[id].faction
	if not seenFaction[fa] then
		seenFaction[fa] = true
		table.insert(factions, fa)
	end
end
local filter = "All"
local emptyNote = label(panel, { name = "Empty", text = "No familiars in this faction yet.", size = UDim2.fromScale(0.5, 0.1), pos = UDim2.fromScale(0.04, 0.5), color = Color3.fromRGB(196, 184, 156), max = 24, z = 12 })
local chips = {}
local filterRow = new("Frame", { Name = "FilterRow", Position = UDim2.fromScale(0.03, 0.115), Size = UDim2.fromScale(0.94, 0.07), BackgroundTransparency = 1, ZIndex = 11 }, panel)
local function applyFilter()
	local shown = 0
	for id, c in cells do
		local vis = filter == "All" or Familiars.byId[id].faction == filter
		c.cell.Visible = vis
		if vis then
			shown += 1
		end
	end
	for fa, chip in chips do
		local on = fa == filter
		chip.BackgroundColor3 = on and BRASS or Color3.fromRGB(38, 34, 48)
		chip.Label.TextColor3 = on and INK or PARCH
	end
	emptyNote.Visible = shown == 0
	gui:SetAttribute("Filter", filter)
	gui:SetAttribute("VisibleCells", shown)
end
for i, fa in factions do
	local chip = new("TextButton", { Name = "Chip_" .. fa, Position = UDim2.fromScale((i - 1) / #factions, 0), Size = UDim2.fromScale(1 / #factions - 0.012, 1), BackgroundColor3 = Color3.fromRGB(38, 34, 48), Text = "", AutoButtonColor = true, ZIndex = 12 }, filterRow)
	new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, chip)
	new("UIStroke", { Color = BRASS, Thickness = 1 }, chip)
	local lbl = label(chip, { name = "Label", text = fa == "All" and "All" or (fa:match("^%S+")), size = UDim2.fromScale(0.94, 0.8), pos = UDim2.fromScale(0.03, 0.1), max = 18, z = 13 })
	lbl.TextTransparency = 0
	lbl:FindFirstChildOfClass("UITextSizeConstraint").MinTextSize = 14
	chip:SetAttribute("Label", fa)
	chip.Activated:Connect(function()
		filter = fa
		applyFilter()
	end)
	chips[fa] = chip
end

local function seenSet()
	local set = {}
	local csv = player:GetAttribute("SeenPets")
	if type(csv) == "string" then
		for id in string.gmatch(csv, "[^,]+") do
			set[id] = true
		end
	end
	return set
end

local function refresh()
	local seen = seenSet()
	local n = 0
	for id in Familiars.byId do
		local def = Familiars.byId[id]
		if def.charId and seen[def.charId] then
			n += 1
		end
	end
	countLabel.Text = n .. "/" .. #Familiars.order
	for _, c in cells do
		local f = Familiars.byId[c.id]
		local known = seen[f.charId or f.id] == true
		c.known = known
		c.img.ImageColor3 = known and Color3.new(1, 1, 1) or Color3.fromRGB(70, 64, 88) -- lighter than the cell so the silhouette reads
		c.img.ImageTransparency = known and 0 or 0.35
		c.lock.Visible = not known
		c.name.Text = known and f.name or "???"
		c.name.TextColor3 = known and PARCH or Color3.fromRGB(140, 134, 150)
	end
	if selected then
		local c = cells[selected]
		local f = Familiars.byId[selected]
		if c.known then
			cardImg.Image = Art[selected].lore
			cardImg.ImageColor3 = Color3.new(1, 1, 1)
			lockedNote.Text = ""
		else
			cardImg.Image = Art[selected].cutout
			cardImg.ImageColor3 = Color3.new(0, 0, 0)
			lockedNote.Text = "Not yet met. " .. f.rarity .. " familiar. Pull it to read its story."
		end
		for id, cc in cells do
			cc.stroke.Thickness = id == selected and 5 or 2
			cc.cell.BackgroundColor3 = id == selected and Color3.fromRGB(74, 62, 96) or (cc.known and Color3.fromRGB(52, 44, 64) or Color3.fromRGB(26, 22, 34))
			cc.stroke.Transparency = cc.known and 0 or 0.55
		end
	end
end

local function select(id)
	selected = id
	gui:SetAttribute("Selected", id) -- read by FamiliarPanel's Details button
	refresh()
end

for i, id in Familiars.order do
	local f = Familiars.byId[id]
	local rarity = Config.RARITIES[f.rarity]
	local cell = new("TextButton", { Name = id, LayoutOrder = i, BackgroundColor3 = Color3.fromRGB(38, 34, 48), Text = "", AutoButtonColor = true, ZIndex = 12 }, grid)
	new("UICorner", { CornerRadius = UDim.new(0.08, 0) }, cell)
	local stroke = new("UIStroke", { Color = rarity.color, Thickness = 2 }, cell)
	local img = new("ImageLabel", { Name = "Img", BackgroundTransparency = 1, Image = Art[id].cutout, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.86, 0.68), Position = UDim2.fromScale(0.07, 0.04), ZIndex = 13 }, cell)
	local name = label(cell, { name = "Name", text = "???", size = UDim2.fromScale(0.9, 0.17), pos = UDim2.fromScale(0.05, 0.69), max = 26, z = 13 })
	local pill = new("Frame", { Name = "RarityPill", BackgroundColor3 = rarity.color, Size = UDim2.fromScale(0.62, 0.1), Position = UDim2.fromScale(0.19, 0.895), ZIndex = 13 }, cell)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, pill)
	label(pill, { name = "Rarity", text = string.upper(f.rarity), size = UDim2.fromScale(0.9, 0.9), pos = UDim2.fromScale(0.05, 0.05), color = INK, max = 18, z = 14 }).FontFace = Font.fromName("Merriweather", Enum.FontWeight.Bold)
	local lock = label(cell, { name = "Lock", text = "?", size = UDim2.fromScale(0.5, 0.4), pos = UDim2.fromScale(0.25, 0.18), color = Color3.fromRGB(200, 190, 215), max = 44, z = 14 })
	cells[id] = { id = id, cell = cell, img = img, name = name, stroke = stroke, known = false, lock = lock }
	cell.Activated:Connect(function()
		select(id)
	end)
end

applyFilter()
gui:GetAttributeChangedSignal("SetFilter"):Connect(function() -- test hook: a Studio check sets the attribute instead of clicking
	local want = gui:GetAttribute("SetFilter")
	if type(want) == "string" and table.find(factions, want) then
		filter = want
		applyFilter()
	end
end)

-- the open button is hidden while the panel is open and while GameClient's start menu frame (HUD > StartMenu) is showing
local startMenu = nil
local function updateButton()
	openBtn.Visible = not panel.Visible and not (startMenu ~= nil and startMenu.Visible)
end
task.spawn(function()
	local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 30)
	startMenu = hud and hud:WaitForChild("StartMenu", 30) or (hud and hud:FindFirstChild("StartMenu", true))
	if startMenu then
		startMenu:GetPropertyChangedSignal("Visible"):Connect(updateButton)
	end
	updateButton()
end)

local function setOpen(open)
	panel.Visible = open
	dim.Visible = open
	updateButton()
	if open then
		refresh()
	end
end
openBtn.Activated:Connect(function()
	setOpen(not panel.Visible)
end)
closeBtn.Activated:Connect(function()
	setOpen(false)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		setOpen(false)
	end
end)
player:GetAttributeChangedSignal("SeenPets"):Connect(refresh)
select(Familiars.order[1])
-- test hooks (read by the Studio check, not used by the game)
gui:SetAttribute("Cells", #Familiars.order)
