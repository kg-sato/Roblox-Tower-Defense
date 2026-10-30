--!nocheck
-- StarterPlayerScripts.ScreenRouter (ModuleScript, T642): the one place that opens the standalone screens. Started by UILane2.
--   ScreenRouter.open(name)   name = Inventory | Quests | Pass | Shop | Board | Stages | Collection | Details:<familiarId> | Menu | Pause
--   ReplicatedStorage.OpenRouter (BindableEvent): Fire(name) = open, Fire("") = close.
--   ScreenRouter.close()      closes whatever modal is open (also resumes a paused run, so Esc toggles the pause menu)
--   ScreenRouter.isOpen()     true while any modal screen is open
-- One modal at a time: open() closes the others first. A "Menu" dock button is cloned from a HUD dock tile (same wax-seal style) and
-- opens a small list. Esc: closes the open screen, else opens the Pause menu (only when PauseMenu is enabled by its own flag).
-- The Results screen opens itself after a "Clear" (ResultsScreen.init, flag Config.RESULTS_SCREEN or attribute QAResults); the router only
-- makes it part of the one-modal rule. Read-only: no purchase or reward request is sent from here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Familiars = require(Shared:WaitForChild("Familiars"))
local TextAnim = require(Shared:WaitForChild("TextAnim"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local Shell = require(script.Parent:WaitForChild("ScreenShell"))
local Results = require(script.Parent:WaitForChild("ResultsScreen"))
local FamiliarPanel = require(script.Parent:WaitForChild("FamiliarPanel"))
local PauseMenu = require(script.Parent:WaitForChild("PauseMenu"))
local P = Dialogs.PALETTE

local Router = {}
local player = Players.LocalPlayer
local menuGui, snapshot = nil, false
local ENTRIES = { { "Inventory", "Inventory" }, { "Quests", "Quests" }, { "Pass", "Pass" }, { "Shop", "Shop" }, { "Leaderboard", "Board" }, { "Stage select", "Stages" }, { "Familiars", "Collection" } }

local function collection()
	local g = player.PlayerGui:FindFirstChild("Collection")
	return g and g:FindFirstChild("Panel")
end

local function closeMenu()
	if menuGui then
		menuGui:Destroy()
		menuGui = nil
		game:GetService("GuiService").SelectedObject = nil
	end
end

function Router.isOpen(): boolean
	local c = collection()
	return menuGui ~= nil or Shell.current() ~= nil or Results.isOpen() or FamiliarPanel.isOpen() or PauseMenu.isOpen() or (c ~= nil and c.Visible)
end

-- closes every modal; resume = also end a pause the player opened
local function closeAll(resume)
	closeMenu()
	Shell.close()
	Results.hide()
	FamiliarPanel.close()
	local c = collection()
	if c then
		c.Visible = false
	end
	if resume and PauseMenu.isOpen() then
		PauseMenu.setPaused(false) -- the server decides; the panel follows its "Pause" event
	end
end

function Router.close()
	closeAll(true)
end

local function pauseEnabled()
	return Config.PAUSE_MENU == true or player:GetAttribute("QAPause") == true
end

local function openMenu()
	closeAll(false)
	menuGui = Instance.new("ScreenGui")
	menuGui.Name, menuGui.ResetOnSpawn, menuGui.DisplayOrder, menuGui.IgnoreGuiInset = "ScreenMenu", false, 135, true
	menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	menuGui.Parent = player:WaitForChild("PlayerGui")
	local root = K.box(menuGui, { name = "Root" })
	K.use("Sols")
	local dim = K.dim(root, 0.5)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	local panel = K.box(dim, { name = "MenuPanel", w = 0.62, h = 0.8, fill = P.panel, corner = 0.04, stroke = 0.01, strokeColor = P.gold, z = 11 })
	Dialogs.text(panel, { name = "Title", text = "MENU", x = 0.5, y = 0.11, w = 0.5, h = 0.12, size = 30, color3 = P.gold, font = K.T.titleFont, z = 12 })
	K.box(panel, { name = "Rule", y = 0.19, w = 0.9, h = 0.006, fill = P.goldDark, z = 12 })
	local first
	for i, e in ENTRIES do
		local col, row = (i - 1) % 2, (i - 1) // 2
		local b = Dialogs.button(panel, { name = e[2], text = e[1], fill = P.goldDark, x = 0.27 + col * 0.46, y = 0.31 + row * 0.17, w = 0.42, h = 0.14, size = 22, z = 13, onClick = function() Router.open(e[2]) end })
		first = first or b
	end
	local closeBtn = Dialogs.button(panel, { name = "Close", text = "Close", fill = P.ghost, stroke = P.goldDark, x = 0.73, y = 0.31 + 3 * 0.17, w = 0.42, h = 0.14, size = 22, z = 13, onClick = closeMenu })
	if TextAnim.settings.reducedMotion ~= true then
		K.popIn(panel)
	end
	game:GetService("GuiService").SelectedObject = first or closeBtn
end

-- Inventory gets a Details button: the selected slot's familiar opens in the detail panel
local function addDetails()
	local screens = player.PlayerGui:FindFirstChild("Screens")
	local panel = screens and screens:FindFirstChild("InventoryPanel", true)
	if not panel then
		return
	end
	local sel = Familiars.order[1]
	for _, id in Familiars.order do
		local slot = panel:FindFirstChild("Slot_" .. id, true)
		if slot then
			slot.Activated:Connect(function() sel = id end)
		end
	end
	Dialogs.button(panel, { name = "Details", text = "Details", fill = P.goldDark, x = 0.7, y = 0.07, w = 0.17, h = 0.09, size = 22, z = 13, onClick = function() Router.open("Details:" .. sel) end })
end

function Router.open(name: string): boolean
	if name == "Menu" then
		openMenu()
		return true
	elseif name == "Pause" then
		closeAll(false)
		if pauseEnabled() then
			PauseMenu.setPaused(true)
			return true
		end
		return false
	elseif name == "Collection" then
		closeAll(false)
		local c = collection()
		if c then
			c.Visible = true
		end
		return c ~= nil
	elseif string.sub(name, 1, 8) == "Details:" then
		closeAll(false)
		local ok = FamiliarPanel.open(string.sub(name, 9))
		local g = player.PlayerGui:FindFirstChild("FamiliarDetail")
		if g then
			g.DisplayOrder = 145 -- above the Pause button (130) and the menu screens (140), which otherwise cover its Close button
		end
		return ok
	end
	closeAll(false)
	local ok = Shell.open(name)
	if ok and name == "Inventory" then
		addDetails()
	end
	return ok
end

-- the dock button: a clone of an existing dock tile, so the seal, icon and caption keep the HUD style
local function addDockButton()
	local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 30)
	local dock = hud and hud:WaitForChild("Hud", 10) and hud.Hud:WaitForChild("Dock", 10)
	if not dock or dock.Parent:FindFirstChild("Menu") then
		return
	end
	local src = dock:WaitForChild("Settings", 15) -- the Settings tile is added later by another script; clone it once it exists
	if not src then
		return
	end
	task.wait(1) -- let the HUD dressing finish restyling the tiles
	local tile = src:Clone()
	tile.Name = "Menu"
	for _, d in tile:GetChildren() do
		if d:IsA("TextLabel") then
			d.Text = "MENU"
		end
	end
	local btn = tile:FindFirstChildOfClass("TextButton")
	if btn then
		local form = btn:FindFirstChild("AF_form")
		local dot = form and form:FindFirstChild("AF_point")
		if form then -- replace the cloned gear glyph with three bars
			local color = dot and dot.BackgroundColor3 or Color3.fromRGB(255, 208, 110)
			for _, c in form:GetChildren() do
				c:Destroy()
			end
			for i = 1, 3 do
				local bar = Instance.new("Frame")
				bar.Name, bar.BackgroundColor3, bar.BorderSizePixel = "AF_line", color, 0
				bar.AnchorPoint, bar.Position, bar.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.3 + 0.2 * (i - 1)), UDim2.fromScale(0.6, 0.08)
				bar.Parent = form
			end
		end
		btn.Activated:Connect(function()
			if menuGui then
				closeMenu()
			else
				Router.open("Menu")
			end
		end)
	end
	-- beside the dock, not in it: a fourth dock tile would land on the Collection "Familiars" button and run off a short screen
	tile.AnchorPoint = Vector2.new(0, 0.5)
	local function place()
		local right = dock.AnchorPoint.X == 1 -- phone layout: the dock sits on the right edge
		tile.Position = UDim2.new(right and 1 or 0, right and -184 or 100, dock.Position.Y.Scale, dock.Position.Y.Offset - 100)
	end
	place()
	dock:GetPropertyChangedSignal("Position"):Connect(place)
	tile.Parent = dock.Parent
end

function Router.init()
	task.spawn(addDockButton)
	local ev = ReplicatedStorage:FindFirstChild("OpenRouter") -- other scripts and tests: ev:Fire("Quests"), ev:Fire("") closes
	if not ev then
		ev = Instance.new("BindableEvent")
		ev.Name, ev.Parent = "OpenRouter", ReplicatedStorage
	end
	ev.Event:Connect(function(name)
		if name == nil or name == "" then
			Router.close()
		else
			Router.open(name)
		end
	end)
	RunService.Heartbeat:Connect(function()
		snapshot = Router.isOpen() -- state before this frame's input: the screens' own Esc handlers may close theirs first
	end)
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.Escape or Dialogs.isOpen() then
			return
		end
		if snapshot then
			closeAll(true)
		elseif pauseEnabled() then
			local hud = player.PlayerGui:FindFirstChild("HUD")
			local h = hud and hud:FindFirstChild("Hud")
			if h and h.Visible then
				Router.open("Pause")
			end
		end
	end)
end

return Router
