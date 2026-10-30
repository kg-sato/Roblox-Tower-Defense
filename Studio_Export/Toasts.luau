--!nocheck
-- StarterPlayerScripts.Toasts (ModuleScript, T098): the shared toast queue.
--   local Toasts = require(script.Parent.Toasts)
--   Toasts.show("Saved.")                                   -- info
--   Toasts.show("Not enough gems.", { kind = "error", title = "Cannot roll" })   -- kinds: info, success, warn, error
-- One toast on screen at a time, the rest wait in order (max 8 waiting; the oldest is dropped). A message equal to one
-- already waiting or showing is not added twice. Reduced motion: no slide, no fade, shown for the same time.
-- Toasts.render(root, spec) builds one toast into any root (used by the tests and the UIKit validator).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local TextAnim = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TextAnim"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Dialogs.PALETTE

local Toasts = {}

local ACCENT = {
	info = P.gold,
	success = Color3.fromRGB(118, 176, 98),
	warn = Color3.fromRGB(214, 150, 58),
	error = Color3.fromRGB(226, 104, 92),
}
Toasts.MAX_WAITING = 8

-- Pure queue rules (testable): returns the new list of waiting specs after adding `spec` to `waiting` while `showing` is on screen.
function Toasts.enqueue(waiting: { any }, showing: any?, spec: any): { any }
	if showing and showing.text == spec.text and showing.kind == spec.kind then
		return waiting
	end
	for _, w in waiting do
		if w.text == spec.text and w.kind == spec.kind then
			return waiting
		end
	end
	table.insert(waiting, spec)
	while #waiting > Toasts.MAX_WAITING do
		table.remove(waiting, 1)
	end
	return waiting
end

function Toasts.render(root, spec)
	K.use("Sols")
	local kind = ACCENT[spec.kind or "info"] and (spec.kind or "info") or "info"
	local hasTitle = spec.title ~= nil
	local t = K.box(root, { name = "Toast", y = 0.16, w = 0.44, h = hasTitle and 0.2 or 0.13, fill = P.panel, corner = 0.12, stroke = 0.03, strokeColor = ACCENT[kind], z = 5 })
	t:SetAttribute("Kind", kind)
	K.box(t, { name = "Accent", x = 0.018, w = 0.012, h = 0.7, fill = ACCENT[kind], z = 6 })
	if hasTitle then
		Dialogs.text(t, { name = "Title", text = spec.title, x = 0.56, y = 0.3, w = 0.86, h = 0.36, size = 20, color3 = ACCENT[kind], z = 6 })
		Dialogs.text(t, { name = "Message", text = spec.text, x = 0.56, y = 0.7, w = 0.86, h = 0.4, size = 18, color3 = P.cream, z = 6 })
	else
		Dialogs.text(t, { name = "Message", text = spec.text, x = 0.56, w = 0.86, h = 0.64, size = 20, color3 = P.cream, z = 6 })
	end
	return t
end

local gui: ScreenGui? = nil
local waiting, showing, running = {}, nil, false

local function ensureRoot()
	if gui and gui.Parent then
		return gui.Root
	end
	local g = Instance.new("ScreenGui")
	g.Name, g.ResetOnSpawn, g.DisplayOrder, g.IgnoreGuiInset = "Toasts", false, 210, true
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local root = K.box(g, { name = "Root" })
	root.Active = false
	gui = g
	return root
end

local function pump()
	if running then
		return
	end
	running = true
	task.spawn(function()
		while #waiting > 0 do
			local spec = table.remove(waiting, 1)
			showing = spec
			local frame = Toasts.render(ensureRoot(), spec)
			local still = TextAnim.settings.reducedMotion == true
			local home = frame.Position
			if not still then
				frame.Position = UDim2.fromScale(home.X.Scale, home.Y.Scale - 0.06)
				TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = home }):Play()
			end
			task.wait(spec.duration or 2.6)
			if not still then
				TweenService:Create(frame, TweenInfo.new(0.2), { Position = UDim2.fromScale(home.X.Scale, home.Y.Scale - 0.06) }):Play()
				task.wait(0.22)
			end
			frame:Destroy()
			showing = nil
		end
		running = false
	end)
end

function Toasts.show(text: string, opts: { kind: string?, title: string?, duration: number? }?)
	local o = opts or {}
	Toasts.enqueue(waiting, showing, { text = tostring(text), kind = o.kind or "info", title = o.title, duration = o.duration })
	pump()
end

function Toasts.clear()
	table.clear(waiting)
end

return Toasts
