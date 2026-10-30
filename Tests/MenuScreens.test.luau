--!nocheck
-- Menu screens (T090-T093) and button states (T084). Two parts, like UIChecks:
--  1. Pure part (Edit mode, RunAll): roster/quest/pass/board data rules, no purchase API in the Pass and Shop sources.
--  2. UI pass, only in a Play client (ctx.scripts = the PlayerScripts folder): every screen rendered into an 844 x 390 px frame; UIKit validator
--     0 problems, every text >= 14 px (measured with TextService at its real box), contrast >= 4.5:1, every button labelled; the four button
--     states (idle, hover, pressed, disabled) on one button kit; the quest tracker collapses and opens.
-- Returns a report string; the first line is PASS, FAIL (n) or "PASS (pure part only, ...)".

return function(Shared, ctx)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local RS = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local TextService = game:GetService("TextService")
	local scripts = (ctx and ctx.scripts) or game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	local function load(n)
		return require(scripts:WaitForChild(n))
	end

	-- ---------- pure part ----------
	local Pass, Board, Tracker, Inv = load("PassScreen"), load("BoardScreen"), load("QuestTracker"), load("InventoryScreen")
	local Quests = require(Shared:WaitForChild("Quests"))
	local Familiars = require(Shared:WaitForChild("Familiars"))
	local f1, p1 = Pass.reward(5)
	check("pass level 5: 20 gems free, palette skin premium", f1 == "20 gems" and p1 == "Palette skin")
	local f40, p40 = Pass.reward(40)
	check("pass level 40: 20 gems free, golden trail premium", f40 == "20 gems" and p40 == "Golden trail")
	local f8 = Pass.reward(8)
	check("pass level 8 free is a lantern colour; level 16 a frame", f8 == "Lantern colour" and Pass.reward(16) == "Frame")
	local premGems = false
	for lv = 1, Pass.LEVELS do
		local _, prem = Pass.reward(lv)
		if prem and string.find(prem:lower(), "gem") then
			premGems = true
		end
	end
	check("premium track never gives gems", not premGems)
	local rows = Board.fakeRows()
	local sorted = #rows == 10
	for i = 2, #rows do
		sorted = sorted and rows[i - 1].wave >= rows[i].wave and rows[i].rank == i
	end
	check("board: 10 fake rows ranked by LeaderboardRules, best wave first", sorted, #rows)
	local st = Quests.new()
	st.day = 20000
	local ids = Quests.dailyIds(st.day)
	local pinned = Quests.byId[ids[2]]
	check("tracker line: pinned quest with progress", Tracker.lineFor(st, pinned.id) == pinned.name .. "  0/" .. pinned.goal)
	check("tracker line: unpinned shows the first unfinished daily", Tracker.lineFor(st, nil) == Quests.byId[ids[1]].name .. "  0/" .. Quests.byId[ids[1]].goal)
	local known = Familiars.byId[Familiars.order[1]]
	check("inventory lore: unmet slot hides the name, names home and faction", not string.find(Inv.loreLine(known, false), known.name) and string.find(Inv.loreLine(known, false), known.home) ~= nil and string.find(Inv.loreLine(known, false), known.faction) ~= nil)
	local noPurchase = true
	local scanned = 0
	for _, n in { "PassScreen", "ShopScreen" } do
		local ok, src = pcall(function() return scripts[n].Source end)
		if ok and src then
			scanned += 1
			for _, bad in { "ProcessReceipt", "PromptPurchase", "PromptProductPurchase", "PromptGamePassPurchase", "MarketplaceService", "PromptRobux" } do
				-- the comments name the forbidden API; only code lines count
				for line in string.gmatch(src, "[^\n]+") do
					if not string.match(line, "^%s*%-%-") and string.find(line, bad, 1, true) then
						noPurchase = false
					end
				end
			end
		end
	end
	check("no purchase API in code lines of PassScreen and ShopScreen (" .. scanned .. " sources scanned)", noPurchase and (scanned == 2 or RunService:IsRunning()))

	local inPlayClient = RunService:IsRunning() and RunService:IsClient() and ctx and ctx.scripts
	if not inPlayClient then
		return (failed == 0 and "PASS (pure part only; the UI pass runs in a Play client, see the evidence file)" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
	end

	-- ---------- UI pass ----------
	local Players = game:GetService("Players")
	local K = require(RS.UIKit.UIKit)
	local validate = require(RS.UIKit.UIValidate)
	local Dialogs = load("Dialogs")
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local MIN_PX, MIN_CONTRAST = 14, 4.5
	local function lin(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
	local function lum(c) return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B) end
	local function contrast(a, b)
		local la, lb = lum(a), lum(b)
		if la < lb then la, lb = lb, la end
		return (la + 0.05) / (lb + 0.05)
	end
	local function effectiveSize(l)
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
		return math.max(lo, c and c.MinTextSize or 0) -- the constraint floor wins over the fit
	end
	local function backdrop(l)
		local color = Color3.fromRGB(10, 8, 6)
		local layers = {}
		local p = l.Parent
		while p and p:IsA("GuiObject") do
			if p.BackgroundTransparency < 1 then table.insert(layers, 1, { p.BackgroundColor3, p.BackgroundTransparency }) end
			p = p.Parent
		end
		for _, layer in layers do color = layer[1]:Lerp(color, layer[2]) end
		return color
	end
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "MenuChecksHarness", false, 999, true
	gui.Parent = pg
	local screen = Instance.new("Frame") -- the phone screen: exact pixels on purpose (not part of the checked UI)
	screen.Size, screen.BackgroundColor3, screen.BorderSizePixel = UDim2.fromOffset(844, 390), Color3.fromRGB(10, 8, 6), 0
	screen.Parent = gui
	local cases = {}
	local st2 = Quests.new()
	st2.day = Quests.dayKey(os.time())
	Quests.record(st2, "rolls", 2)
	for _, n in { "InventoryScreen", "QuestScreen", "PassScreen", "ShopScreen", "BoardScreen", "StageSelect" } do
		local m = load(n)
		local r = K.box(screen, { name = n, w = 1, h = 1 })
		local d = m.data and m.data() or {}
		if n == "QuestScreen" then d = { state = st2 } elseif n == "PassScreen" then d = { xp = 1250, premium = false } elseif n == "StageSelect" then d = { best = 7 } end
		m.render(r, d, nil)
		table.insert(cases, r)
	end
	local tr = load("QuestTracker").build(K.box(screen, { name = "TrackerCase", w = 1, h = 1 }))
	table.insert(cases, tr.frame.Parent)
	task.wait(0.4)
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
				if not (d:GetAttribute("Label") or d:GetAttribute("Tooltip") or (d:IsA("TextButton") and d.Text ~= "")) then
					local has = false
					for _, c in d:GetDescendants() do
						if (c:IsA("TextLabel") or c:IsA("TextButton")) and c.Text ~= "" then has = true end
					end
					if not has then table.insert(buttonBad, r.Name .. "/" .. d.Name) end
				end
			end
		end
	end
	check("harness built " .. #cases .. " cases with " .. texts .. " texts and " .. buttons .. " buttons", texts > 100 and buttons > 30)
	check("UIKit validator: 0 problems on all six screens and the tracker", #validBad == 0, table.concat(validBad, " | "):sub(1, 400))
	check(string.format("every text >= %d px at 844x390 (smallest %d)", MIN_PX, minSize), #sizeBad == 0, table.concat(sizeBad, " | "):sub(1, 500))
	check(string.format("text contrast >= %.1f:1 (lowest %.2f)", MIN_CONTRAST, minContrast), #contrastBad == 0, table.concat(contrastBad, " | "):sub(1, 500))
	check("every button is labelled", #buttonBad == 0, table.concat(buttonBad, " | "):sub(1, 400))

	-- quest tracker: shows, collapses, opens
	check("tracker shows the line and hides the chip", tr.line.Visible and not tr.chip.Visible and tr.text.Text ~= "", tr.text.Text)
	tr.set(true) -- the click handlers call exactly this
	task.wait(0.05)
	check("tracker collapses to the chip", not tr.line.Visible and tr.chip.Visible and tr.isCollapsed())
	tr.set(false)
	task.wait(0.05)
	check("tracker opens again from the chip", tr.line.Visible and not tr.chip.Visible)

	-- button states from one kit (T084)
	local row = K.box(screen, { name = "StateRow", w = 1, h = 0.2 })
	local P = Dialogs.PALETTE
	local kit = {}
	for i, name in { "idle", "hover", "pressed", "disabled" } do
		kit[name] = Dialogs.button(row, { name = "State_" .. name, text = name, fill = P.goldDark, x = (i - 0.5) / 4, w = 0.2, h = 0.8, size = 22 })
	end
	task.wait(0.1)
	local base = kit.idle.AbsoluteSize.X
	for name, b in kit do K.setState(b, name) end
	task.wait(0.5)
	local w = {}
	for name, b in kit do w[name] = b.AbsoluteSize.X / base end
	check(string.format("hover grows (%.3f), pressed squashes (%.3f), idle and disabled stay 1", w.hover, w.pressed), w.hover > 1.04 and w.pressed < 0.96 and math.abs(w.idle - 1) < 0.01 and math.abs(w.disabled - 1) < 0.01)
	check("State attributes read idle, hover, pressed, disabled", kit.idle:GetAttribute("State") == "idle" and kit.hover:GetAttribute("State") == "hover" and kit.pressed:GetAttribute("State") == "pressed" and kit.disabled:GetAttribute("State") == "disabled")
	check(string.format("disabled button is dimmed (fill transparency %.2f) and ignores input", kit.disabled.BackgroundTransparency), kit.disabled.BackgroundTransparency > 0.4 and kit.disabled.Interactable == false and kit.idle.Interactable == true)
	local fired = 0
	kit.disabled.Activated:Connect(function() fired += 1 end)
	K.setState(kit.disabled, "idle")
	task.wait(0.4)
	check("button returns from disabled to idle (interactable, opaque)", kit.disabled.Interactable and kit.disabled.BackgroundTransparency < 0.05)

	gui:Destroy()
	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
