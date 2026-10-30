--!nocheck
-- StarterPlayerScripts.Tooltips (ModuleScript, T085): one tooltip for every icon and stat. Hover (mouse, after 0.35 s) or long
-- press (touch or held click, 0.45 s) shows it; leaving or letting go hides it.
--   local Tooltips = require(script.Parent.Tooltips)
--   Tooltips.attach(iconButton, { title = "Gems", body = "Buy rolls with gems." })
--   Tooltips.attach(icon, { kind = "familiars", id = "Ember" })          -- text comes from Shared.Strings
--   Tooltips.autoAttach(PlayerGui)  -- also picks up any GuiObject with the attribute Tooltip="Title|body" or TooltipKind+TooltipId,
--                                   -- and any button with the attribute Label (icon-only buttons made by Dialogs.button)
-- Tag a new icon with SetAttribute("Tooltip", "Gems|Buy rolls with gems.") and it gets a tooltip with no other code.
-- Built from UIKit parts (Scale only, 14 px text floor). Reduced motion: no fade.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local TextAnim = require(Shared:WaitForChild("TextAnim"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Dialogs.PALETTE

local Tooltips = {}
Tooltips.HOVER_DELAY, Tooltips.PRESS_DELAY = 0.35, 0.45
local TIP_W, TIP_H = 0.3, 0.22 -- fractions of the screen

-- Pure: where the tooltip centre goes (screen fractions). Above the target if it fits, else below; clamped on screen.
function Tooltips.place(pos: Vector2, size: Vector2, viewport: Vector2, tipW: number?, tipH: number?): (number, number)
	local w, h = tipW or TIP_W, tipH or TIP_H
	local cx = (pos.X + size.X / 2) / viewport.X
	local above = (pos.Y / viewport.Y) - h / 2 - 0.02
	local below = ((pos.Y + size.Y) / viewport.Y) + h / 2 + 0.02
	local cy = above - h / 2 >= 0 and above or below
	return math.clamp(cx, w / 2 + 0.01, 1 - w / 2 - 0.01), math.clamp(cy, h / 2 + 0.01, 1 - h / 2 - 0.01)
end

-- Pure: the title and body for a spec ({title, body} or {kind, id}); nil when there is nothing to say.
function Tooltips.content(spec: any): (string?, string?)
	if spec.kind and spec.id then
		local e = Strings.get(spec.kind, spec.id)
		return e.name, e.blurb
	end
	if spec.title or spec.body then
		return spec.title or "", spec.body or ""
	end
	return nil, nil
end

-- Pure: reads the attributes autoAttach understands off an instance.
function Tooltips.specFromAttributes(inst: Instance): any?
	local kind, id = inst:GetAttribute("TooltipKind"), inst:GetAttribute("TooltipId")
	if type(kind) == "string" and type(id) == "string" then
		return { kind = kind, id = id }
	end
	local tip = inst:GetAttribute("Tooltip")
	if type(tip) == "string" and tip ~= "" then
		local title, body = string.match(tip, "^(.-)|(.*)$")
		return { title = title or tip, body = body or "" }
	end
	local label = inst:GetAttribute("Label")
	if type(label) == "string" and label ~= "" and inst:IsA("GuiButton") and not (inst:IsA("TextButton") and inst.Text ~= "") then
		return { title = label, body = "" }
	end
	return nil
end

-- Builds the tooltip panel into root (used by show() and by the tests); returns the panel.
function Tooltips.render(root, title: string, body: string)
	K.use("Sols")
	local hasBody = body ~= ""
	local panel = K.box(root, { name = "Tooltip", w = TIP_W, h = hasBody and TIP_H or 0.12, fill = P.ink, corner = 0.1, stroke = 0.025, strokeColor = P.gold, z = 5 })
	if hasBody then
		Dialogs.text(panel, { name = "Title", text = title, y = 0.26, w = 0.9, h = 0.34, size = 22, color3 = P.gold, z = 6 })
		Dialogs.text(panel, { name = "Body", text = body, y = 0.68, w = 0.9, h = 0.4, size = 18, color3 = P.cream, z = 6 })
	else
		Dialogs.text(panel, { name = "Title", text = title, w = 0.9, h = 0.6, size = 22, color3 = P.gold, z = 6 })
	end
	return panel
end

local gui: ScreenGui? = nil
local shownFor, token = nil, 0

local function ensureRoot()
	if gui and gui.Parent then
		return gui.Root
	end
	local g = Instance.new("ScreenGui")
	g.Name, g.ResetOnSpawn, g.DisplayOrder, g.IgnoreGuiInset = "Tooltips", false, 220, true
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local root = K.box(g, { name = "Root" })
	root.Active = false
	gui = g
	return root
end

function Tooltips.hide()
	token += 1
	shownFor = nil
	if gui and gui.Parent then
		local old = gui.Root:FindFirstChild("Tooltip")
		if old then
			old:Destroy()
		end
	end
end

function Tooltips.show(target: GuiObject, spec: any)
	local title, body = Tooltips.content(spec)
	if not title or not target.Parent then
		return
	end
	Tooltips.hide()
	shownFor = target
	local root = ensureRoot()
	local panel = Tooltips.render(root, title, body)
	local vp = workspace.CurrentCamera.ViewportSize
	local x, y = Tooltips.place(target.AbsolutePosition, target.AbsoluteSize, vp, panel.Size.X.Scale, panel.Size.Y.Scale)
	panel.Position = UDim2.fromScale(x, y)
	if TextAnim.settings.reducedMotion ~= true then
		panel.BackgroundTransparency = 1
		TweenService:Create(panel, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play()
	end
end

local attached = setmetatable({}, { __mode = "k" })

local function schedule(target: GuiObject, delay: number)
	token += 1
	local mine = token
	task.delay(delay, function()
		if token == mine and target.Parent and attached[target] then
			Tooltips.show(target, attached[target])
		end
	end)
end

-- Long press: pressBegin starts the timer, pressEnd cancels it or, if the tooltip is up, hides it after 1.2 s.
-- The Touch handler below calls these; the tests call them directly (a headless run has no finger).
function Tooltips.pressBegin(target: GuiObject)
	schedule(target, Tooltips.PRESS_DELAY)
end

function Tooltips.pressEnd(target: GuiObject)
	if shownFor == target then
		local mine = token
		task.delay(1.2, function()
			if token == mine and shownFor == target then
				Tooltips.hide()
			end
		end)
	else
		token += 1 -- let go before the delay: no tooltip
	end
end

function Tooltips.attach(target: GuiObject, spec: any)
	attached[target] = spec
	if target:GetAttribute("TooltipBound") then
		return
	end
	target:SetAttribute("TooltipBound", true)
	target.MouseEnter:Connect(function()
		if UserInputService.MouseEnabled then
			schedule(target, Tooltips.HOVER_DELAY)
		end
	end)
	target.MouseLeave:Connect(Tooltips.hide)
	target.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then -- the mouse uses hover
			Tooltips.pressBegin(target)
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					c:Disconnect()
					Tooltips.pressEnd(target)
				end
			end)
		end
	end)
end

-- Watches a container (default PlayerGui) and attaches to every tagged descendant, now and later (also when the
-- attribute is set after the object was made).
function Tooltips.autoAttach(container: Instance)
	local function consider(d: Instance)
		if d:IsA("GuiObject") and not d:GetAttribute("TooltipBound") then
			local spec = Tooltips.specFromAttributes(d)
			if spec then
				Tooltips.attach(d, spec)
			end
		end
	end
	local function watch(d: Instance)
		if d:IsA("GuiObject") then
			consider(d)
			d.AttributeChanged:Connect(function()
				consider(d)
			end)
		end
	end
	for _, d in container:GetDescendants() do
		watch(d)
	end
	container.DescendantAdded:Connect(function(d)
		task.defer(watch, d) -- after the maker has set its attributes
	end)
end

return Tooltips
