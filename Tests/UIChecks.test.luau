--!nocheck
-- UI checks (T235). Two parts:
--  1. Pure helpers (contrast maths, text fitting rules): run anywhere, including Tests/RunAll in Edit mode.
--  2. The UI pass, only in a Play client: the shared overlay modules (Dialogs, Toasts, Tooltips) are built inside an
--     844 x 390 px frame and checked for: the UIKit validator (0 problems), every text label at least 14 px (TextScaled
--     labels are measured with TextService at their real box size), primary text contrast at least 4.5:1 against the
--     composited background, and every button labelled. The live PlayerGui is also scanned and REPORTED (never failed)
--     so other owners can see their violations.
-- Run in Play (Client datamodel): require a ModuleScript holding this file, call it with (Shared, { scripts = PlayerScripts }).
-- Returns a report string; the first line is PASS, FAIL (n) or "PASS (pure part only, ...)".

return function(Shared, ctx)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end

	local function lin(v)
		return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
	end
	local function lum(c: Color3)
		return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B)
	end
	local function contrast(a: Color3, b: Color3)
		local la, lb = lum(a), lum(b)
		if la < lb then
			la, lb = lb, la
		end
		return (la + 0.05) / (lb + 0.05)
	end
	-- colour of a UIGradient's ColorSequence at its middle
	local function gradMid(seq: ColorSequence): Color3
		local k = seq.Keypoints
		for i = 1, #k - 1 do
			if k[i + 1].Time >= 0.5 then
				local a = (0.5 - k[i].Time) / math.max(1e-6, k[i + 1].Time - k[i].Time)
				return k[i].Value:Lerp(k[i + 1].Value, a)
			end
		end
		return k[#k].Value
	end

	-- pure checks
	check("contrast black on white is 21", math.abs(contrast(Color3.new(0, 0, 0), Color3.new(1, 1, 1)) - 21) < 0.01)
	check("contrast of equal colours is 1", contrast(Color3.new(0.3, 0.3, 0.3), Color3.new(0.3, 0.3, 0.3)) == 1)
	check("contrast is symmetric", contrast(Color3.new(1, 0, 0), Color3.new(0, 0, 1)) == contrast(Color3.new(0, 0, 1), Color3.new(1, 0, 0)))
	check("grey 119 on white is just under 4.5 (WCAG reference)", contrast(Color3.fromRGB(119, 119, 119), Color3.new(1, 1, 1)) > 4.4 and contrast(Color3.fromRGB(118, 118, 118), Color3.new(1, 1, 1)) > 4.5)

	local RunService = game:GetService("RunService")
	local inPlayClient = RunService:IsRunning() and RunService:IsClient() and ctx and ctx.scripts
	if not inPlayClient then
		return (failed == 0 and "PASS (pure part only; the UI pass runs in a Play client, see the evidence file)" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
	end

	local Players = game:GetService("Players")
	local TextService = game:GetService("TextService")
	local RS = game:GetService("ReplicatedStorage")
	local K = require(RS.UIKit.UIKit)
	local validate = require(RS.UIKit.UIValidate)
	local Dialogs = require(ctx.scripts.Dialogs)
	local Toasts = require(ctx.scripts.Toasts)
	local Tooltips = require(ctx.scripts.Tooltips)
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local MIN_PX, MIN_CONTRAST = 14, 4.5

	-- largest size at which the label's text fits its box (what TextScaled would pick), capped by UITextSizeConstraint
	local function effectiveSize(l)
		if not l.TextScaled then
			return l.TextSize
		end
		local cap = 100
		local c = l:FindFirstChildOfClass("UITextSizeConstraint")
		if c then
			cap = c.MaxTextSize
		end
		local box = l.AbsoluteSize
		local lo, hi = 1, cap
		local params = Instance.new("GetTextBoundsParams")
		params.Text, params.Font, params.Width = l.Text, l.FontFace, math.max(1, box.X)
		while lo < hi do
			local mid = math.ceil((lo + hi) / 2)
			params.Size = mid
			local ok, b = pcall(function() return TextService:GetTextBoundsAsync(params) end)
			if ok and b.Y <= box.Y + 0.5 then
				lo = mid
			else
				hi = mid - 1
			end
		end
		return lo
	end

	-- the colour behind a label: layers from the outermost opaque-ish ancestor in, over an assumed near-black world
	local function backdrop(l)
		local layers = {}
		local p = l.Parent
		while p and p:IsA("GuiObject") do
			if p.BackgroundTransparency < 1 then
				local c = p.BackgroundColor3
				local g = p:FindFirstChildOfClass("UIGradient")
				if g then
					c = Color3.new(c.R * gradMid(g.Color).R, c.G * gradMid(g.Color).G, c.B * gradMid(g.Color).B)
				end
				table.insert(layers, 1, { c, p.BackgroundTransparency })
			end
			p = p.Parent
		end
		local color = Color3.fromRGB(10, 8, 6)
		for _, layer in layers do
			color = layer[1]:Lerp(color, layer[2])
		end
		return color
	end

	local function labelled(b)
		if b:GetAttribute("Label") or b:GetAttribute("Tooltip") then
			return true
		end
		if b:IsA("TextButton") and b.Text ~= "" then
			return true
		end
		for _, d in b:GetDescendants() do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
				return true
			end
		end
		return false
	end

	-- build everything into an 844x390 px frame
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "UIChecksHarness", false, 999, true
	gui.Parent = pg
	local screen = Instance.new("Frame") -- the phone screen: exact pixels on purpose (not part of the checked UI)
	screen.Size, screen.BackgroundColor3, screen.BorderSizePixel = UDim2.fromOffset(844, 390), Color3.fromRGB(10, 8, 6), 0
	screen.Parent = gui
	local cases = {}
	local function slot(name)
		local r = K.box(screen, { name = name, w = 1, h = 1 })
		r.ClipsDescendants = false
		table.insert(cases, r)
		return r
	end
	Dialogs.render(slot("ConfirmDialog"), { title = "Release Ember?", body = "Ember will leave your lantern and you will get 12 coins back.", confirmText = "Release", cancelText = "Keep" }, nil)
	Dialogs.render(slot("DangerDialog"), { title = "Reset your progress?", body = "This cannot be undone. Every stage, familiar and skill will be lost.", confirmText = "Reset", danger = true }, nil)
	Dialogs.render(slot("ErrorDialog"), { kind = "error", title = "Could not save", body = "The lantern keeper did not answer. Your progress is safe. Please try again.", code = "E12", retryText = "Try again" }, nil)
	do
		local r = slot("EmptyState")
		Dialogs.emptyState(r, { title = "No familiars yet", body = "Roll once to meet your first familiar.", actionText = "Roll", glyph = "?" })
	end
	for _, kind in { "info", "success", "warn", "error" } do
		Toasts.render(slot("Toast_" .. kind), { text = "Not enough gems for another roll.", kind = kind })
		Toasts.render(slot("ToastTitled_" .. kind), { title = "Cannot roll", text = "You need 20 gems.", kind = kind })
	end
	Tooltips.render(slot("Tooltip_body"), "Moth-Lantern", "Shows what hides in the fog.")
	Tooltips.render(slot("Tooltip_title"), "Gems", "")
	task.wait(0.3) -- layout and fonts

	local texts, buttons, minSize, minContrast = 0, 0, 1e9, 1e9
	local sizeBad, contrastBad, buttonBad, validBad = {}, {}, {}, {}
	for _, r in cases do
		for _, p in validate(r) do
			table.insert(validBad, p)
		end
		for _, d in r:GetDescendants() do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and d.AbsoluteSize.X > 0 then
				texts += 1
				local sz = effectiveSize(d)
				minSize = math.min(minSize, sz)
				if sz < MIN_PX then
					table.insert(sizeBad, r.Name .. "/" .. d.Name .. " size " .. sz)
				end
				local cr = contrast(d.TextColor3, backdrop(d))
				minContrast = math.min(minContrast, cr)
				if cr < MIN_CONTRAST then
					table.insert(contrastBad, string.format("%s/%s %.2f", r.Name, d.Name, cr))
				end
			end
			if d:IsA("GuiButton") then
				buttons += 1
				if not labelled(d) then
					table.insert(buttonBad, r.Name .. "/" .. d.Name)
				end
			end
		end
	end
	check("harness built " .. #cases .. " panels with text and buttons", texts > 20 and buttons >= 7, texts .. " texts, " .. buttons .. " buttons")
	check("UIKit validator: 0 problems in Dialogs, Toasts, Tooltips and empty state", #validBad == 0, table.concat(validBad, " | "):sub(1, 400))
	check(string.format("every text >= %d px at 844x390 (smallest %d)", MIN_PX, minSize), #sizeBad == 0, table.concat(sizeBad, " | "):sub(1, 400))
	check(string.format("text contrast >= %.1f:1 (lowest %.2f)", MIN_CONTRAST, minContrast), #contrastBad == 0, table.concat(contrastBad, " | "):sub(1, 400))
	check("every button is labelled", #buttonBad == 0, table.concat(buttonBad, " | "):sub(1, 400))

	-- also through the real queue: a toast and a dialog on the live ScreenGuis, then removed
	local opened = false
	Toasts.show("Queue check one", { kind = "info", duration = 0.3 })
	Toasts.show("Queue check one", { kind = "info", duration = 0.3 })
	Toasts.show("Queue check two", { kind = "error", duration = 0.3 })
	task.wait(0.15)
	local toastGui = pg:FindFirstChild("Toasts")
	check("live toast shows, equal message not queued twice", toastGui ~= nil and #toastGui.Root:GetChildren() == 1 and not Toasts.enqueue({ { text = "a", kind = "info" } }, nil, { text = "a", kind = "info" })[2])
	task.wait(1.2)
	check("toast queue drains", toastGui.Root:FindFirstChild("Toast") == nil)
	Dialogs.confirm({ title = "Queue check", body = "x", onConfirm = function() opened = "yes" end })
	task.wait(0.1)
	check("live dialog opens", Dialogs.isOpen() and pg:FindFirstChild("Dialogs") ~= nil)
	Dialogs.dismiss()
	task.wait(0.1)
	check("dialog closes on dismiss (Esc path) and runs no confirm", not Dialogs.isOpen() and opened == false)
	gui:Destroy()

	-- report-only scan of everything else in PlayerGui
	local live, liveSmall, liveUnlabelled = 0, {}, {}
	for _, d in pg:GetDescendants() do
		if d:IsA("GuiObject") and d:IsDescendantOf(pg) and not d:IsDescendantOf(gui) then
			local top = d:FindFirstAncestorOfClass("ScreenGui")
			if top and top.Name ~= "UIChecksHarness" and top.Name ~= "Toasts" and top.Name ~= "Dialogs" and top.Name ~= "Tooltips" then
				if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and d.Visible then
					live += 1
					if not d.TextScaled and d.TextSize < MIN_PX then
						table.insert(liveSmall, top.Name .. "/" .. d.Name .. " TextSize " .. d.TextSize)
					end
				end
				if d:IsA("GuiButton") and d.Visible and not labelled(d) then
					table.insert(liveUnlabelled, top.Name .. "/" .. d.Name)
				end
			end
		end
	end
	table.insert(results, string.format("REPORT live PlayerGui (not failures, other owners): %d visible text objects, %d fixed TextSize < %d px, %d unlabelled buttons", live, #liveSmall, MIN_PX, #liveUnlabelled))
	for i = 1, math.min(12, #liveSmall) do
		table.insert(results, "REPORT small: " .. liveSmall[i])
	end
	for i = 1, math.min(12, #liveUnlabelled) do
		table.insert(results, "REPORT unlabelled: " .. liveUnlabelled[i])
	end

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
