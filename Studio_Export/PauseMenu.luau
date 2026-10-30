--!nocheck
-- StarterPlayerScripts.PauseMenu (ModuleScript, T097): a Pause button (and the P key), and the pause menu: Resume, Speed, Settings, Quit.
--   require(script.Parent.PauseMenu).init()                       -- called once by the UILane2 LocalScript
--   PauseMenu.render(root, { left = 300, speed = 1 }, handlers)   -- builds the panel (tests, validator); handlers: onResume, onSpeed, onSettings, onQuit
-- The server pauses: this only sends Action "Pause" true/false (MatchSim.pause, T006: the server counts the pause down and
-- resumes the run by itself at Config.PAUSE_MAX) and reads the "Pause", "State" and "Settings" events back. The panel is shown
-- only while the server says the run is paused. Speed sends Setting {gameSpeed} (server validates and rate limits).
-- Settings fires the BindableEvent ReplicatedStorage.OpenSettings, which GameClient listens to (one line there) to open its panel.
-- Quit asks first with Dialogs.confirmAsync and then leaves the game with LocalPlayer:Kick (there is no menu-to-run flow to go back
-- to); the profile is saved by the server on leave, the wave in progress is not kept.
-- Off unless Config.PAUSE_MENU is true (or the player attribute QAPause, set by the server for tests).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local TextAnim = require(Shared:WaitForChild("TextAnim"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Dialogs.PALETTE

local PauseMenu = {}
local player = Players.LocalPlayer

local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function PauseMenu.render(root, d, h)
	h = h or {}
	K.use("Sols")
	local dim = K.dim(root, 0.5)
	dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dim.Name = "PauseDim"
	local panel = K.box(dim, { name = "PausePanel", w = 0.46, h = 0.9, fill = P.panel, corner = 0.05, stroke = 0.012, strokeColor = P.gold, z = 11 })
	Dialogs.text(panel, { name = "Title", text = "PAUSED", y = 0.09, w = 0.8, h = 0.12, size = 34, color3 = P.gold, font = K.T.titleFont, z = 12 })
	local sub = Dialogs.text(panel, { name = "Sub", text = d.left and ("Resumes by itself in " .. clock(d.left)) or "The run is paused.", y = 0.18, w = 0.86, h = 0.07, size = 18, color3 = P.muted, z = 12 })
	K.box(panel, { name = "Rule", y = 0.235, w = 0.86, h = 0.006, fill = P.goldDark, z = 12 })
	local resume = Dialogs.button(panel, { name = "Resume", text = "Resume", fill = P.goldDark, y = 0.34, w = 0.8, h = 0.15, size = 28, onClick = h.onResume })
	local speed = Dialogs.button(panel, { name = "Speed", text = string.format("Speed: %dx", d.speed or 1), fill = P.ghost, stroke = P.goldDark, y = 0.52, w = 0.8, h = 0.15, size = 26, onClick = h.onSpeed })
	local settings = Dialogs.button(panel, { name = "Settings", text = "Settings", fill = P.ghost, stroke = P.goldDark, y = 0.7, w = 0.8, h = 0.15, size = 26, onClick = h.onSettings })
	local quit = Dialogs.button(panel, { name = "Quit", text = "Quit game", fill = P.ghost, stroke = P.danger, y = 0.88, w = 0.8, h = 0.15, size = 26, onClick = h.onQuit })
	return { dim = dim, panel = panel, sub = sub, resume = resume, speed = speed, settings = settings, quit = quit }
end

local state = { paused = false, left = nil, speed = 1, running = false }
local gui, btnGui, button, current, endsAt

local function enabled()
	return Config.PAUSE_MENU == true or player:GetAttribute("QAPause") == true
end

local function action(...)
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Action"):FireServer(...)
end

local function refreshButton()
	if not button then
		return
	end
	local show = enabled() and state.running
	btnGui.Enabled = show
	local lbl = button:FindFirstChild("Label")
	if lbl then
		lbl.Text = state.paused and "Resume" or "Pause"
		button:SetAttribute("Label", lbl.Text)
	end
end

local function hidePanel()
	if current then
		current.dim:Destroy()
		current = nil
		GuiService.SelectedObject = nil
	end
end

local function showPanel()
	if current or not enabled() then
		return
	end
	if not gui or not gui.Parent then
		gui = Instance.new("ScreenGui")
		gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "PauseMenu", false, 140, true
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = player:WaitForChild("PlayerGui")
		K.box(gui, { name = "Root" })
	end
	local h
	h = PauseMenu.render(gui.Root, { left = endsAt and (endsAt - os.clock()) or nil, speed = state.speed }, {
		onResume = function() PauseMenu.setPaused(false) end,
		onSpeed = function()
			state.speed = state.speed == 1 and 2 or 1 -- the server decides; the Settings echo corrects this if it refuses
			action("Setting", { gameSpeed = state.speed })
			h.speed:FindFirstChild("Label").Text = string.format("Speed: %dx", state.speed)
		end,
		onSettings = function()
			hidePanel() -- the run stays paused; the HUD button now reads Resume
			local ev = ReplicatedStorage:FindFirstChild("OpenSettings")
			if ev then
				ev:Fire()
			end
		end,
		onQuit = function()
			task.spawn(function()
				if Dialogs.confirmAsync({ title = "Quit the game?", body = "Your profile is kept. The wave in progress is not.", confirmText = "Quit", cancelText = "Keep playing", danger = true }) then
					player:Kick("You left the game. Come back any time.")
				end
			end)
		end,
	})
	current = h
	if TextAnim.settings.reducedMotion ~= true then
		K.popIn(h.panel)
	end
	GuiService.SelectedObject = h.resume
	task.spawn(function() -- the countdown label follows the server's pause time
		while current == h and endsAt do
			h.sub.Text = "Resumes by itself in " .. clock(endsAt - os.clock())
			task.wait(1)
		end
	end)
end

-- ask the server; the panel itself follows the server's "Pause" event
function PauseMenu.setPaused(on: boolean)
	action("Pause", on)
end

function PauseMenu.isPaused()
	return state.paused
end

function PauseMenu.isOpen()
	return current ~= nil
end

local function onPauseEvent(on: boolean, left: number?)
	state.paused = on
	endsAt = (on and left) and (os.clock() + left) or nil
	if on then
		showPanel()
	else
		hidePanel()
	end
	refreshButton()
end

function PauseMenu.init()
	btnGui = Instance.new("ScreenGui")
	btnGui.Name, btnGui.ResetOnSpawn, btnGui.DisplayOrder, btnGui.IgnoreGuiInset, btnGui.Enabled = "PauseButton", false, 130, true, false
	btnGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	btnGui.Parent = player:WaitForChild("PlayerGui")
	local root = K.box(btnGui, { name = "Root" })
	root.Active = false
	K.use("Sols")
	button = Dialogs.button(root, { name = "PauseButton", text = "Pause", fill = P.ghost, stroke = P.gold, x = 0.935, y = 0.075, w = 0.11, h = 0.085, size = 22, onClick = function()
		if state.paused then
			PauseMenu.setPaused(false)
		else
			PauseMenu.setPaused(true)
		end
	end })

	local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Event")
	event.OnClientEvent:Connect(function(kind, data)
		if type(data) ~= "table" then
			return
		end
		if kind == "Begin" then
			state.running = true
			onPauseEvent(data.snapshot and data.snapshot.userPaused == true or false, data.snapshot and data.snapshot.pauseLeft)
		elseif kind == "Pause" then
			onPauseEvent(data.on == true, data.left)
		elseif kind == "State" then
			state.running = true
			if (data.userPaused == true) ~= state.paused then
				onPauseEvent(data.userPaused == true, data.pauseLeft)
			end
		elseif kind == "Settings" and type(data.gameSpeed) == "number" then
			state.speed = data.gameSpeed
			if current then
				current.speed:FindFirstChild("Label").Text = string.format("Speed: %dx", state.speed)
			end
		end
	end)
	player:GetAttributeChangedSignal("QAPause"):Connect(refreshButton)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.P and enabled() and state.running and not Dialogs.isOpen() then
			PauseMenu.setPaused(not state.paused)
		end
	end)
end

return PauseMenu
