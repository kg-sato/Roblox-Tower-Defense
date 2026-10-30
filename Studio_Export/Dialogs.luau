--!nocheck
-- StarterPlayerScripts.Dialogs (ModuleScript, T098): the shared confirm dialog, error dialog and empty state.
--   local Dialogs = require(script.Parent.Dialogs)
--   Dialogs.confirm({ title = "Release Ember?", body = "...", confirmText = "Release", danger = true, onConfirm = fn, onCancel = fn })
--   local yes = Dialogs.confirmAsync({ ... })            -- yields; true when confirmed
--   Dialogs.error({ title = "Could not save", body = "...", code = "E12", retryText = "Try again", onRetry = fn })
--   Dialogs.emptyState(parentFrame, { title = "No familiars yet", body = "Roll to meet one.", actionText = "Roll", onAction = fn })
-- One dialog at a time (the rest wait in a queue). Built only from the UIKit parts (Scale only, centred anchors, TextScaled
-- with a 14 px floor) so UIValidate reports 0 problems; Dialogs.render(root, spec) builds a panel into any root for tests.
-- Palette: near-black ink, antique gold, cream (Dialogs.PALETTE). Reduced motion: no pop-in. Esc cancels; the primary
-- button takes gamepad selection.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local TextAnim = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TextAnim"))

local Dialogs = {}

Dialogs.PALETTE = {
	ink = Color3.fromRGB(14, 11, 8),
	panel = Color3.fromRGB(24, 19, 13),
	gold = Color3.fromRGB(201, 162, 74),
	goldDark = Color3.fromRGB(122, 92, 36),
	cream = Color3.fromRGB(240, 229, 200),
	muted = Color3.fromRGB(196, 184, 156),
	danger = Color3.fromRGB(126, 34, 30),
	ghost = Color3.fromRGB(44, 35, 24),
}
local P = Dialogs.PALETTE

local MIN_TEXT = 14 -- px floor for every label (T235 checks it at 844x390)

-- K.text with the project floor and a chosen colour; the label name is kept for the tests
function Dialogs.text(parent, o)
	local t = K.text(parent, o)
	t.TextColor3 = o.color3 or P.cream
	local c = t:FindFirstChildOfClass("UITextSizeConstraint")
	if c then
		c.MinTextSize = MIN_TEXT
	end
	local s = t:FindFirstChildOfClass("UIStroke")
	if s then
		s:Destroy() -- ink on ink: the stroke only muddies small text
	end
	return t
end

-- one house button: fill colour, label colour, label attribute for the "labelled buttons" check
function Dialogs.button(parent, o)
	local b = K.button(parent, {
		name = o.name, text = o.text, color = o.fill, x = o.x, y = o.y, w = o.w, h = o.h, size = o.size or 26, corner = "md", stroke = 0.03, onClick = o.onClick, z = o.z,
	})
	b:SetAttribute("Label", o.text)
	local lbl = b:FindFirstChild("Label")
	if lbl then
		lbl.TextColor3 = o.textColor or P.cream
		local c = lbl:FindFirstChildOfClass("UITextSizeConstraint")
		if c then
			c.MinTextSize = MIN_TEXT
		end
		local s = lbl:FindFirstChildOfClass("UIStroke")
		if s then
			s:Destroy()
		end
	end
	local grad = b:FindFirstChildOfClass("UIGradient")
	if grad then
		grad:Destroy() -- flat fill so the label contrast is the measured colour pair
	end
	b.BackgroundColor3 = o.fill
	local st = b:FindFirstChildOfClass("UIStroke")
	if st then
		st.Color = o.stroke or P.gold
	end
	return b
end

-- spec: title, body, kind ("confirm" | "error"), confirmText, cancelText, danger, code, retryText
-- Returns { dim, panel, confirm, cancel } and wires the callbacks (onConfirm/onCancel run after the dialog has closed).
function Dialogs.render(root, spec, close)
	local kind = spec.kind or "confirm"
	K.use("Sols")
	local dim = K.dim(root, 0.35)
	dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dim.Name = "DialogDim"
	local panel = K.box(dim, { name = "DialogPanel", w = 0.56, h = 0.72, fill = P.panel, corner = 0.05, stroke = 0.012, strokeColor = kind == "error" and P.danger or P.gold, z = 11 })
	K.box(panel, { name = "Rule", y = 0.27, w = 0.86, h = 0.006, fill = P.goldDark, z = 12 })
	Dialogs.text(panel, { name = "Title", text = spec.title or "", y = 0.14, w = 0.86, h = 0.17, size = 30, color3 = P.gold, font = K.T.titleFont, z = 12 })
	local hasCode = spec.code ~= nil
	Dialogs.text(panel, { name = "Body", text = spec.body or "", y = hasCode and 0.46 or 0.5, w = 0.86, h = hasCode and 0.3 or 0.38, size = 22, color3 = P.cream, z = 12 })
	if hasCode then
		Dialogs.text(panel, { name = "Code", text = "Code: " .. tostring(spec.code), y = 0.68, w = 0.6, h = 0.08, size = 16, color3 = P.muted, z = 12 })
	end
	local confirm, cancel
	local function done(ok)
		if close then
			close(ok)
		end
	end
	if kind == "error" then
		confirm = Dialogs.button(panel, { name = "Retry", text = spec.retryText or "Try again", fill = P.goldDark, x = 0.3, y = 0.84, w = 0.38, h = 0.2, onClick = function() done(true) end })
		cancel = Dialogs.button(panel, { name = "Dismiss", text = spec.cancelText or "Close", fill = P.ghost, stroke = P.goldDark, x = 0.7, y = 0.84, w = 0.38, h = 0.2, onClick = function() done(false) end })
	else
		cancel = Dialogs.button(panel, { name = "Cancel", text = spec.cancelText or "Cancel", fill = P.ghost, stroke = P.goldDark, x = 0.3, y = 0.84, w = 0.38, h = 0.2, onClick = function() done(false) end })
		confirm = Dialogs.button(panel, { name = "Confirm", text = spec.confirmText or "Confirm", fill = spec.danger and P.danger or P.goldDark, stroke = spec.danger and P.danger or P.gold, x = 0.7, y = 0.84, w = 0.38, h = 0.2, onClick = function() done(true) end })
	end
	return { dim = dim, panel = panel, confirm = confirm, cancel = cancel, dismiss = function() done(false) end }
end

-- inline empty state for a list or screen: ring, title, one line of advice, optional action button.
function Dialogs.emptyState(parent, spec)
	K.use("Sols")
	local f = K.box(parent, { name = "EmptyState", x = spec.x, y = spec.y, w = spec.w or 0.8, h = spec.h or 0.8 })
	local ring = K.box(f, { name = "Ring", y = 0.24, w = 0.2, h = 0.3, aspect = 1, corner = "pill", stroke = 0.04, strokeColor = P.goldDark })
	Dialogs.text(ring, { name = "Glyph", text = spec.glyph or "?", w = 0.6, h = 0.6, size = 36, color3 = P.gold })
	Dialogs.text(f, { name = "Title", text = spec.title or "Nothing here yet", y = 0.5, w = 0.9, h = 0.14, size = 26, color3 = P.gold })
	Dialogs.text(f, { name = "Body", text = spec.body or "", y = 0.66, w = 0.9, h = 0.16, size = 20, color3 = P.muted })
	local btn
	if spec.actionText then
		btn = Dialogs.button(f, { name = "Action", text = spec.actionText, fill = P.goldDark, y = 0.88, w = 0.34, h = 0.16, onClick = spec.onAction })
	end
	return f, btn
end

---------------------------------------------------------------------------------------------------
-- runtime: one ScreenGui, a queue, Esc to cancel
---------------------------------------------------------------------------------------------------
local gui: ScreenGui? = nil
local queue, current = {}, nil

local function ensureGui()
	if gui and gui.Parent then
		return gui
	end
	local g = Instance.new("ScreenGui")
	g.Name, g.ResetOnSpawn, g.DisplayOrder, g.IgnoreGuiInset = "Dialogs", false, 200, true
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local root = K.box(g, { name = "Root" })
	root.Active = false
	gui = g
	return g
end

local function showNext()
	if current or #queue == 0 then
		return
	end
	local spec = table.remove(queue, 1)
	local g = ensureGui()
	local root = g:FindFirstChild("Root")
	local h
	h = Dialogs.render(root, spec, function(ok)
		if current ~= h then
			return
		end
		current = nil
		h.dim:Destroy()
		GuiService.SelectedObject = nil
		local cb = ok and (spec.kind == "error" and spec.onRetry or spec.onConfirm) or spec.onCancel
		if cb then
			task.spawn(cb)
		end
		showNext()
	end)
	current = h
	if TextAnim.settings.reducedMotion ~= true then
		K.popIn(h.panel)
	end
	GuiService.SelectedObject = h.confirm
end

function Dialogs.confirm(spec)
	spec.kind = "confirm"
	table.insert(queue, spec)
	showNext()
end

function Dialogs.error(spec)
	spec.kind = "error"
	table.insert(queue, spec)
	showNext()
end

-- yields until the player chooses; true = confirmed
function Dialogs.confirmAsync(spec): boolean
	local result
	local co = coroutine.running()
	local function finish(v)
		result = v
		task.spawn(co)
	end
	spec.onConfirm, spec.onCancel = function() finish(true) end, function() finish(false) end
	Dialogs.confirm(spec)
	if result == nil then
		coroutine.yield()
	end
	return result == true
end

function Dialogs.dismiss()
	if current then
		current.dismiss()
	end
end

function Dialogs.isOpen(): boolean
	return current ~= nil
end

UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.Escape and current then
		current.dismiss()
	end
end)

return Dialogs
