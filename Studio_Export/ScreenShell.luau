--!nocheck
-- StarterPlayerScripts.ScreenShell (ModuleScript, T090-T093): the shared frame for the standalone menu screens
-- (InventoryScreen, QuestScreen, PassScreen, ShopScreen, BoardScreen, StageSelect).
--   ScreenShell.frame(root, { name, title, sub }, close) -> { dim, panel, body, close }   -- dark gold-ink panel, title, Close button, body area
--   ScreenShell.register(name, module)          -- a screen module needs render(root, data, close) and optionally data()
--   ScreenShell.open(name) / ScreenShell.close() / ScreenShell.current()
-- Opening: fire the BindableEvent ReplicatedStorage.OpenScreen with the screen name, or set the player attribute QAScreen (tests).
-- Screens read server-published state only (player attributes, Shared data); none of them sends a purchase or a reward request.
-- All sizes are Scale; text goes through Dialogs.text so the 14 px floor holds. The ScreenGui is called "Screens" (NavFocus treats it as a modal).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local TextAnim = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TextAnim"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Dialogs.PALETTE

local Shell = { P = P }
local player = Players.LocalPlayer
local registry, gui, current = {}, nil, nil

function Shell.register(name, mod)
	registry[name] = mod
end

function Shell.frame(root, o, close)
	K.use("Sols")
	local dim = K.dim(root, 0.5)
	dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dim.Name = o.name .. "Dim"
	local panel = K.box(dim, { name = o.name .. "Panel", w = 0.92, h = 0.92, fill = P.panel, corner = 0.03, stroke = 0.008, strokeColor = P.gold, z = 11 })
	Dialogs.text(panel, { name = "Title", text = o.title, x = 0.04, y = 0.07, w = 0.4, h = 0.1, size = 32, color3 = P.gold, font = K.T.titleFont, left = true, z = 12 })
	if o.sub then
		Dialogs.text(panel, { name = "Sub", text = o.sub, x = 0.46, y = 0.07, w = 0.3, h = 0.07, size = 18, color3 = P.muted, left = true, z = 12 })
	end
	K.box(panel, { name = "Rule", y = 0.135, w = 0.94, h = 0.005, fill = P.goldDark, z = 12 })
	local closeBtn = Dialogs.button(panel, { name = "Close", text = "Close", fill = P.ghost, stroke = P.goldDark, x = 0.9, y = 0.07, w = 0.15, h = 0.09, size = 22, z = 13, onClick = function() if close then close() end end })
	local body = K.box(panel, { name = "Body", x = 0.5, y = 0.57, w = 0.94, h = 0.8, z = 12 })
	return { dim = dim, panel = panel, body = body, close = closeBtn }
end

-- a plain text button-like cell: used by the grid screens
function Shell.cell(parent, o)
	local c = K.box(parent, { class = "TextButton", name = o.name, x = o.x, y = o.y, w = o.w, h = o.h, fill = o.fill or P.ink, corner = 0.1, stroke = 0.03, strokeColor = o.strokeColor or P.goldDark, z = 13 })
	c.Text, c.AutoButtonColor = "", false
	c:SetAttribute("Label", o.label or o.name)
	K.pressFx(c)
	return c
end

local function ensureGui()
	if gui and gui.Parent then
		return gui
	end
	gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "Screens", false, 140, true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	K.box(gui, { name = "Root" })
	return gui
end

function Shell.current()
	return current and current.name or nil
end

function Shell.close()
	if current then
		current.h.dim:Destroy()
		current = nil
		GuiService.SelectedObject = nil
	end
end

function Shell.open(name)
	local mod = registry[name]
	if not mod then
		return false
	end
	Shell.close()
	local h
	h = mod.render(ensureGui().Root, mod.data and mod.data() or {}, function()
		if current and current.h == h then
			Shell.close()
		end
	end)
	current = { name = name, h = h }
	if TextAnim.settings.reducedMotion ~= true then
		K.popIn(h.panel)
	end
	GuiService.SelectedObject = h.first or h.close
	return true
end

function Shell.init()
	local ev = ReplicatedStorage:FindFirstChild("OpenScreen")
	if not ev then
		ev = Instance.new("BindableEvent")
		ev.Name = "OpenScreen"
		ev.Parent = ReplicatedStorage
	end
	ev.Event:Connect(function(name)
		if name == "" or name == nil then
			Shell.close()
		else
			Shell.open(name)
		end
	end)
	player:GetAttributeChangedSignal("QAScreen"):Connect(function()
		local n = player:GetAttribute("QAScreen")
		if type(n) == "string" and n ~= "" then
			Shell.open(n)
		else
			Shell.close()
		end
	end)
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape and current and not Dialogs.isOpen() then
			Shell.close()
		end
	end)
end

return Shell
