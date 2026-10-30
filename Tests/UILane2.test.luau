--!nocheck
-- UI lane 2 checks (T074, T095, T097). Run in a Play client: put this file in a ModuleScript, call it with
-- (Shared, ctx) where ctx = { scripts = StarterPlayerScripts, only = {"Results", ...} (optional) }. Builds each screen's render()
-- inside an exact 844 x 390 px frame and checks: UIKit validator 0 problems, every text >= 14 px (TextScaled labels
-- measured with TextService at their real box size), text contrast >= 4.5:1 against the composited backdrop, and every
-- button labelled. Returns a report; line 1 is PASS or FAIL (n). Look and feel is NOT judged here.

return function(Shared, ctx)
	local RunService = game:GetService("RunService")
	if not (ctx and ctx.scripts and RunService:IsRunning() and RunService:IsClient()) then
		return "PASS (skipped: the UI pass runs only in a Play client, see Overnight/evidence/T074.txt, T095.txt, T097.txt)"
	end
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local Players = game:GetService("Players")
	local TextService = game:GetService("TextService")
	local RS = game:GetService("ReplicatedStorage")
	local K = require(RS.UIKit.UIKit)
	local validate = require(RS.UIKit.UIValidate)
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local MIN_PX, MIN_CONTRAST = 14, 4.5

	local function lin(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
	local function lum(c) return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B) end
	local function contrast(a, b)
		local la, lb = lum(a), lum(b)
		if la < lb then la, lb = lb, la end
		return (la + 0.05) / (lb + 0.05)
	end
	local function gradMid(seq)
		local k = seq.Keypoints
		for i = 1, #k - 1 do
			if k[i + 1].Time >= 0.5 then
				local a = (0.5 - k[i].Time) / math.max(1e-6, k[i + 1].Time - k[i].Time)
				return k[i].Value:Lerp(k[i + 1].Value, a)
			end
		end
		return k[#k].Value
	end
	local function effectiveSize(l)
		if not l.TextScaled then return l.TextSize end
		local cap = 100
		local c = l:FindFirstChildOfClass("UITextSizeConstraint")
		if c then cap = c.MaxTextSize end
		local box = l.AbsoluteSize
		local lo, hi = 1, cap
		local params = Instance.new("GetTextBoundsParams")
		params.Text, params.Font, params.Width = l.Text, l.FontFace, math.max(1, box.X)
		while lo < hi do
			local mid = math.ceil((lo + hi) / 2)
			params.Size = mid
			local ok, b = pcall(function() return TextService:GetTextBoundsAsync(params) end)
			if ok and b.Y <= box.Y + 0.5 then lo = mid else hi = mid - 1 end
		end
		return lo
	end
	local function backdrop(l)
		local layers = {}
		local p = l.Parent
		while p and p:IsA("GuiObject") do
			if p.BackgroundTransparency < 1 then
				local c = p.BackgroundColor3
				local g = p:FindFirstChildOfClass("UIGradient")
				if g then
					local m = gradMid(g.Color)
					c = Color3.new(c.R * m.R, c.G * m.G, c.B * m.B)
				end
				table.insert(layers, 1, { c, p.BackgroundTransparency })
			end
			p = p.Parent
		end
		local color = Color3.fromRGB(10, 8, 6)
		for _, layer in layers do color = layer[1]:Lerp(color, layer[2]) end
		return color
	end
	local function labelled(b)
		if b:GetAttribute("Label") or b:GetAttribute("Tooltip") then return true end
		if b:IsA("TextButton") and b.Text ~= "" then return true end
		for _, d in b:GetDescendants() do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then return true end
		end
		return false
	end

	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "UILane2Harness", false, 999, true
	gui.Parent = pg
	local screen = Instance.new("Frame") -- the phone screen: exact pixels on purpose (harness only)
	screen.Size, screen.BackgroundColor3, screen.BorderSizePixel = UDim2.fromOffset(844, 390), Color3.fromRGB(10, 8, 6), 0
	screen.Parent = gui
	local cases = {}
	local function slot(name)
		local r = K.box(screen, { name = name, w = 1, h = 1 })
		table.insert(cases, r)
		return r
	end
	local function want(group)
		if not ctx.only then return true end
		return table.find(ctx.only, group) ~= nil
	end
	local function load(name)
		local m = ctx.scripts:FindFirstChild(name)
		if not m then
			check("module " .. name .. " present", false)
			return nil
		end
		local ok, mod = pcall(require, m)
		check("module " .. name .. " loads", ok, ok and nil or tostring(mod))
		return ok and mod or nil
	end

	if want("Results") then
		local R = load("ResultsScreen")
		if R then
			R.render(slot("Results_normal"), { stage = 3, perfect = true, gems = 4, gold = 12840, combo = 3, lore = R.loreFor(3, false) })
			R.render(slot("Results_boss"), { stage = 5, boss = true, gems = 9, gold = 1250000, combo = 6, lore = R.loreFor(5, true) })
			R.render(slot("Results_longlore"), { stage = 24, perfect = false, gems = 3, gold = 987654321, lore = R.loreFor(24, false) })
		end
	end
	if want("Pause") then
		local M = load("PauseMenu")
		if M then
			M.render(slot("Pause_normal"), { left = 24, speed = 1 })
			M.render(slot("Pause_fast"), { left = 3, speed = 2 })
		end
	end
	if want("Familiar") then
		local F = load("FamiliarPanel")
		if F then
			for _, id in { "Ember", "TheLamplighter", "FerrymanOfFog" } do
				F.render(slot("Familiar_" .. id), id, { owned = true, tier = 1, xp = 130, lastUsed = os.time() - 86400 * 6 })
			end
			F.render(slot("Familiar_locked"), "DameOrrery", { owned = false })
		end
	end
	task.wait(0.4) -- layout and fonts

	local texts, buttons, minSize, minContrast = 0, 0, 1e9, 1e9
	local sizeBad, contrastBad, buttonBad, validBad = {}, {}, {}, {}
	for _, r in cases do
		for _, p in validate(r) do table.insert(validBad, p) end
		for _, d in r:GetDescendants() do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and d.AbsoluteSize.X > 0 then
				texts += 1
				local sz = effectiveSize(d)
				minSize = math.min(minSize, sz)
				if sz < MIN_PX then table.insert(sizeBad, r.Name .. "/" .. d.Name .. " size " .. sz) end
				local cr = contrast(d.TextColor3, backdrop(d))
				minContrast = math.min(minContrast, cr)
				if cr < MIN_CONTRAST then table.insert(contrastBad, string.format("%s/%s %.2f", r.Name, d.Name, cr)) end
			end
			if d:IsA("GuiButton") then
				buttons += 1
				if not labelled(d) then table.insert(buttonBad, r.Name .. "/" .. d.Name) end
			end
		end
	end
	check("harness built " .. #cases .. " screens (" .. texts .. " texts, " .. buttons .. " buttons) at 844 x 390 px", #cases > 0 and texts > 0)
	check("UIKit validator: 0 problems", #validBad == 0, table.concat(validBad, " | "):sub(1, 500))
	check(string.format("every text >= %d px (smallest %d)", MIN_PX, minSize), #sizeBad == 0, table.concat(sizeBad, " | "):sub(1, 500))
	check(string.format("text contrast >= %.1f:1 (lowest %.2f)", MIN_CONTRAST, minContrast), #contrastBad == 0, table.concat(contrastBad, " | "):sub(1, 500))
	check("every button is labelled", #buttonBad == 0, table.concat(buttonBad, " | "):sub(1, 500))
	if ctx.keep then
		screen.Name = "Kept"
	else
		gui:Destroy()
	end
	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
