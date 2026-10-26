--!nocheck
-- UIScreens: example screens that recreate the reference screenshots using only UIKit components.
-- Each entry is a function(K, parent) that builds one ScreenGui and returns it. The image it recreates is in the
-- comment (files are in Roblox Dev/Research). These are MOCK screens: no game logic, placeholder text.
-- A new screen = copy one, change the theme and the components. That is the "one prompt" step.
-- Not yet tested in Studio.

local S = {}
S.order = { "FishHud", "CatchHud", "PetHud", "Shop", "WelcomeBack", "DailyTasks", "Settings", "TutorialHud", "CollectionLog", "AuraRoll", "UpgradeHex", "Inventory", "Rebirth", "Loading" }

local V2 = Vector2.new
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local LEFT = V2(0, 0.5)
local RIGHT = V2(1, 0.5)

-- fishing-hud-start.png, fishing-head-to-pier-stalls.png: sparse HUD. Heavy outlined text, no frames; a level + cash
-- readout bottom-left, a numbered hotbar bottom-centre, round dark buttons top-right, an objective line, an event timer.
S.FishHud = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("FishHud", parent)
	K.backdrop(root, rgb(120, 215, 255), rgb(245, 175, 70))
	K.text(root, { text = "Next Event in: 19:02", x = 0.5, y = 0.05, w = 0.3, h = 0.065, size = 46, name = "EventTimer" })
	local hint = K.text(root, { text = 'Head to the <font color="#FFD62A">Pier</font>', x = 0.5, y = 0.21, w = 0.42, h = 0.11, size = 76, name = "Objective" })
	hint.RichText = true
	K.button(root, { icon = "icon_bell", color = "dark", x = 0.925, y = 0.055, w = 0.1, h = 0.075, aspect = 1, corner = "pill", badge = "1" })
	K.button(root, { icon = "icon_gear", color = "dark", x = 0.972, y = 0.055, w = 0.1, h = 0.075, aspect = 1, corner = "pill" })
	K.button(root, { icon = "icon_gear", color = "dark", x = 0.032, y = 0.80, w = 0.1, h = 0.07, aspect = 1, corner = "pill", name = "SettingsSmall" })
	K.text(root, { text = "Level: 1 (0%)", x = 0.012, y = 0.875, w = 0.14, h = 0.04, size = 34, color = "green", left = true, name = "Level" })
	K.icon(root, { icon = "icon_coin", x = 0.028, y = 0.93, w = 0.04, h = 0.056, aspect = 1, name = "CoinIcon" })
	K.text(root, { text = "$0", x = 0.055, y = 0.93, w = 0.1, h = 0.062, size = 54, color = "yellow", left = true, name = "Cash" })
	local bar = K.box(root, { name = "Hotbar", x = 0.5, y = 0.9, w = 0.14, h = 0.12 })
	local slots = { { "1", "icon_rod", "Wooden Rod" }, { "2", "icon_bag", "Items" } }
	for i, c in ipairs(K.cells(2, 1, 0.06)) do
		local d = slots[i]
		local slot = K.box(bar, { name = "Slot" .. i, x = c.x, y = c.y, w = c.w, h = c.h, fill = "panelDark", alpha = 0.18, corner = "md", stroke = "md", strokeColor = "yellowDark" })
		K.icon(slot, { icon = d[2], y = 0.42, w = 0.78, h = 0.62, aspect = 1 })
		K.text(slot, { text = d[3], y = 0.86, w = 0.92, h = 0.2, size = 20 })
		local n = K.box(slot, { name = "Number", x = 0.18, y = 0.16, w = 0.28, h = 0.28, aspect = 1, fill = "panelDark", corner = "pill", stroke = "thin", strokeColor = "text", z = 4 })
		K.text(n, { text = d[1], w = 0.7, h = 0.7, size = 24, outline = false })
	end
	K.icon(root, { icon = "icon_clover", x = 0.962, y = 0.87, w = 0.06, h = 0.09, aspect = 1, name = "LuckIcon" })
	K.text(root, { text = "100%", x = 0.962, y = 0.94, w = 0.06, h = 0.038, size = 30, name = "LuckValue" })
	K.stagger(bar, { step = 0.08 })
	return g
end

-- fishing-minigame.png, fishing-title-depth-meter.png: underwater catch screen. Depth ruler on the right edge,
-- rarity-coloured price callouts, hook counter, one instruction line with two highlighted words.
S.CatchHud = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("CatchHud", parent)
	K.backdrop(root, rgb(30, 130, 235), rgb(10, 60, 170))
	K.bar(root, { value = 0.45, color = "orange", text = "HALLOWEEN EVENT", x = 0.5, y = 0.04, w = 0.34, h = 0.04, size = 22, name = "EventBar" })
	K.text(root, { text = "22m", x = 0.5, y = 0.115, w = 0.14, h = 0.08, size = 64, name = "Depth" })
	K.text(root, { text = "New Best!!!", x = 0.5, y = 0.178, w = 0.14, h = 0.04, size = 30, color = "yellow", name = "NewBest" })
	local band = K.box(root, { name = "InstructionBand", x = 0.5, y = 0.245, w = 0.62, h = 0.11, fill = "dim", alpha = 0.55, corner = "pill" })
	local line = K.text(band, { text = 'Catch fish as your <font color="#FFD62A">bait</font> floats <font color="#FFD62A">UP</font>', w = 0.94, h = 0.7, size = 66, name = "Instruction" })
	line.RichText = true
	local callouts = {
		{ "$15", "UNCOMMON", "green", 0.3, "icon_fish" },
		{ "$3", "COMMON", "text", 0.5, "icon_fish" },
	}
	for _, c in ipairs(callouts) do
		local cell = K.box(root, { name = "Callout_" .. c[2], x = 0.14, y = c[4], w = 0.16, h = 0.17 })
		K.icon(cell, { icon = c[5], y = 0.22, w = 0.5, h = 0.42, aspect = 1 })
		K.text(cell, { text = c[1], y = 0.62, w = 0.8, h = 0.22, size = 50, color = "green" })
		K.text(cell, { text = c[2], y = 0.86, w = 0.9, h = 0.2, size = 36, color = c[3] })
	end
	K.icon(root, { icon = "icon_hook", x = 0.205, y = 0.8, w = 0.05, h = 0.1, aspect = 1, name = "HookIcon" })
	K.text(root, { text = "0/3", x = 0.275, y = 0.8, w = 0.09, h = 0.1, size = 80, name = "HookCount" })
	K.text(root, { text = "Move your mouse", x = 0.5, y = 0.86, w = 0.3, h = 0.07, size = 48, name = "Hint" })
	local ruler = K.box(root, { name = "Ruler", x = 0.965, y = 0.5, w = 0.02, h = 0.5 })
	K.box(ruler, { name = "Line", x = 0.5, y = 0.5, w = 0.06, h = 1, fill = "text", corner = "pill" })
	for i = 0, 4 do
		K.box(ruler, { name = "Tick" .. i, x = 0.5, y = i / 4, w = 0.6, h = 0.008, fill = "text", corner = "pill" })
	end
	local mark = K.box(root, { name = "DepthMarker", x = 0.935, y = 0.68, w = 0.06, h = 0.055, fill = "text", corner = "sm" })
	K.text(mark, { text = "36m", w = 0.8, h = 0.7, size = 34, color = "textDark", outline = false })
	local fishMark = K.box(root, { name = "FishMarker", x = 0.925, y = 0.48, w = 0.1, h = 0.07 })
	K.text(fishMark, { text = "UNCOMMON", x = 0.28, w = 0.58, h = 0.4, size = 22, color = "green" })
	K.icon(fishMark, { icon = "icon_fish", x = 0.86, w = 0.3, h = 1.0, aspect = 1 })
	K.stagger(root:FindFirstChild("Ruler"), { step = 0.05 })
	return g
end

-- pet-main-hud-tap-button.png, egg-main-hud-auto-swing.png: nav column, goal banner, big action button, pills
S.PetHud = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("PetHud", parent)
	K.backdrop(root, rgb(80, 175, 255), rgb(110, 215, 60))
	K.nav(root, {
		y = 0.42, w = 0.11, h = 0.46,
		items = {
			{ text = "Shop", icon = "🛒", color = "green", badge = "!" },
			{ text = "Index", icon = "📖", color = "blue" },
			{ text = "Trade", icon = "🔁", color = "orange" },
		},
	})
	K.banner(root, { title = "NEXT UP!", text = "Make a Golden pet!", x = 0.5, y = 0.085, w = 0.4, h = 0.13 })
	K.button(root, { text = "Auto Swing", icon = "⛏️", color = "red", x = 0.5, y = 0.9, w = 0.32, h = 0.14, size = 46 })
	K.pill(root, { icon = "icon_bolt", value = "10", color = "blue", plus = true, x = 0.012, y = 0.85, w = 0.17, h = 0.07, anchor = LEFT, reason = "HUD pinned to the left screen edge" })
	K.pill(root, { icon = "💵", value = "$0", color = "green", x = 0.012, y = 0.94, w = 0.17, h = 0.07, anchor = LEFT, reason = "HUD pinned to the left screen edge" })
	K.text(root, { text = "In: 18m 22s", right = true, x = 0.985, y = 0.94, w = 0.18, h = 0.07, size = 40, color = "yellow" })
	K.button(root, { icon = "🥚", color = "red", x = 0.985, y = 0.45, w = 0.055, h = 0.1, aspect = 1, anchor = RIGHT, reason = "HUD pinned to the right screen edge" })
	K.button(root, { icon = "🐾", color = "orange", x = 0.985, y = 0.6, w = 0.055, h = 0.1, aspect = 1, anchor = RIGHT, reason = "HUD pinned to the right screen edge" })
	return g
end

-- pet-shop-featured.png, duel-shop-home.png, pet-shop-chronos-egg-odds.png: tabs + cards + price buttons
S.Shop = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("Shop", parent)
	K.backdrop(root, rgb(70, 160, 240), rgb(90, 200, 70))
	local panel, content = K.modal(root, { title = "Shop", color = "green", aspect = 1.75, w = 0.66 })
	K.tabs(content, { tabs = { "Featured", "Pets", "Passes", "Gems" }, y = 0.07, w = 0.96, h = 0.12, color = "blue" })
	local region = K.box(content, { name = "Cards", y = 0.58, w = 1, h = 0.8 })
	local cards = {
		{ title = "Starter Pack", icon = "🎁", price = 49, tag = "SALE", note = "Save 20%", color = "orange" },
		{ title = "Lucky Egg", icon = "🥚", price = "2.5K", kind = "coin", note = "See odds", color = "blue" },
		{ title = "Mythic Pet", icon = "icon_crown", price = 399, tag = "BEST VALUE", color = "purple" },
	}
	for i, c in ipairs(K.cells(3, 1, 0.025)) do
		local d = cards[i]
		d.x, d.y, d.w, d.h = c.x, c.y, c.w, c.h
		K.card(region, d)
	end
	K.popIn(panel)
	K.stagger(region, { step = 0.07 })
	return g
end

-- pet-offline-earnings-popup.png: "Welcome Back" with a big counted number and a Claim button
S.WelcomeBack = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("WelcomeBack", parent)
	K.backdrop(root, rgb(255, 170, 60), rgb(255, 110, 120))
	local panel, content = K.modal(root, { title = "Welcome Back!", color = "orange", aspect = 1.8, w = 0.5 })
	K.text(content, { text = "Your pets kept tapping for 10h", y = 0.12, w = 0.9, h = 0.14, size = 34 })
	K.icon(content, { icon = "icon_coin", x = 0.3, y = 0.46, w = 0.2, h = 0.5, aspect = 1 })
	local amount = K.text(content, { text = "+0", x = 0.62, y = 0.46, w = 0.5, h = 0.34, size = 90, color = "yellow", name = "Amount" })
	K.countUp(amount, 266221, { prefix = "+", time = 1.2 })
	K.button(content, { text = "Claim!", color = "green", y = 0.85, w = 0.46, h = 0.2, size = 52 })
	K.popIn(panel)
	return g
end

-- duel-daily-tasks-streak-contracts.png: streak row + task rows with progress bars and rewards
S.DailyTasks = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("DailyTasks", parent)
	K.backdrop(root, rgb(50, 60, 110), rgb(90, 50, 130))
	local panel, content = K.modal(root, { title = "Daily Tasks", color = "blue", aspect = 1.55, w = 0.6 })
	local streak = K.box(content, { name = "Streak", y = 0.14, w = 1, h = 0.24 })
	for i, c in ipairs(K.cells(7, 1, 0.012)) do
		local done = i <= 3
		local cell = K.box(streak, { name = "Day" .. i, x = c.x, y = c.y, w = c.w, h = c.h, fill = done and "greenDark" or "panelLight", gradient = true, corner = "md", stroke = "md" })
		K.text(cell, { text = "Day " .. i, y = 0.22, w = 0.9, h = 0.22, size = 22 })
		K.icon(cell, { icon = done and "icon_check" or "icon_gift", y = 0.64, w = 0.62, h = 0.5, aspect = 1 })
	end
	local tasks = {
		{ "Hatch 5 eggs", 0.6, "icon_coin", "200" },
		{ "Merge 3 pets", 1.0, "icon_gem", "5" },
		{ "Play 10 minutes", 0.3, "icon_coin", "500" },
	}
	local list = K.box(content, { name = "Tasks", y = 0.69, w = 1, h = 0.58 })
	for i, r in ipairs(K.rows(3, 0.05)) do
		local t = tasks[i]
		local row = K.box(list, { name = "Task" .. i, y = r.y, w = 1, h = r.h, fill = "panelDark", alpha = 0.2, corner = "md", stroke = "thin" })
		K.text(row, { text = t[1], x = 0.03, w = 0.3, h = 0.4, size = 32, left = true })
		K.bar(row, { value = t[2], x = 0.5, w = 0.34, h = 0.46, color = t[2] >= 1 and "green" or "blue", text = t[2] >= 1 and "Done" or (math.round(t[2] * 100) .. "%") })
		K.icon(row, { icon = t[3], x = 0.735, w = 0.05, h = 0.7, aspect = 1 })
		K.text(row, { text = t[4], x = 0.76, w = 0.12, h = 0.4, size = 30, color = "yellow", left = true })
		local claim = K.button(row, { text = "Claim", color = t[2] >= 1 and "green" or "gray", x = 0.92, w = 0.14, h = 0.7, size = 26 })
		if t[2] >= 1 then
			K.pulse(claim, { scale = 1.08, period = 0.7 })
		end
	end
	K.popIn(panel)
	K.stagger(streak, { step = 0.04 })
	return g
end

-- card-settings-display-options.png: exactly the settings in the Game Design Doc
S.Settings = function(K, parent)
	K.use("Pixel")
	local g, root = K.screen("Settings", parent)
	K.backdrop(root, rgb(30, 16, 60), rgb(12, 8, 30))
	local panel, content = K.modal(root, { title = "SETTINGS", aspect = 0.98, w = 0.4 })
	local r = K.rows(8, 0.012)
	local _, music = K.slider(content, { label = "MUSIC", value = 1, y = r[1].y, h = r[1].h, valueText = "100%" })
	local _, sfx = K.slider(content, { label = "SFX", value = 1, y = r[2].y, h = r[2].h, valueText = "100%" })
	local _, flashes = K.segmented(content, { label = "FLASHES", options = { "ON", "OFF" }, y = r[3].y, h = r[3].h })
	local _, particles = K.segmented(content, { label = "PARTICLES", options = { "LOW", "DEFAULT", "HIGH" }, value = 2, y = r[4].y, h = r[4].h })
	local _, backdrop = K.segmented(content, { label = "BACKDROP", options = { "MOVING", "STILL" }, y = r[5].y, h = r[5].h })
	local _, numbers = K.segmented(content, { label = "NUMBERS", options = { "1.5M", "1,500,000", "1.5E6" }, y = r[6].y, h = r[6].h })
	-- Reduced motion drives K.setReducedMotion at once; turning it ON also switches Flashes off and Backdrop to still
	-- (as the Game Design Doc says). Nothing is saved yet.
	local _, reduced = K.segmented(content, {
		label = "REDUCED MOTION", options = { "ON", "OFF" }, value = 2, y = r[7].y, h = r[7].h,
		onChange = function(i)
			local on = i == 1
			K.setReducedMotion(on)
			if on then
				flashes.set(2)
				backdrop.set(2)
			end
		end,
	})
	K.button(content, {
		text = "RESET TO DEFAULTS", color = "red", y = r[8].y, w = 0.5, h = r[8].h, size = 28,
		onClick = function()
			music.set(1)
			sfx.set(1)
			flashes.set(1)
			particles.set(2)
			backdrop.set(1)
			numbers.set(1)
			reduced.set(2)
			K.setReducedMotion(false)
		end,
	})
	return g
end

-- fruit-tutorial-3-click-fruits.png: numbered tutorial banner, "New!" toasts, edge offer buttons
S.TutorialHud = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("TutorialHud", parent)
	K.backdrop(root, rgb(255, 150, 60), rgb(170, 90, 200))
	K.banner(root, { title = "TUTORIAL • 3/11", text = "Click your fruits to turn them into coins! (0/3)", x = 0.5, y = 0.1, w = 0.62, h = 0.17 })
	K.nav(root, {
		y = 0.45, w = 0.12, h = 0.5,
		items = {
			{ text = "Shop", icon = "🛒", color = "yellow" },
			{ text = "Rebirth", icon = "🔄", color = "blue" },
			{ text = "Upgrade", icon = "⬆️", color = "green", badge = "1" },
			{ text = "Index", icon = "📖", color = "green" },
		},
	})
	K.toast(root, { icon = "🧄", title = "Garlic!", text = "You've discovered this for the first time!", tag = "New!", x = 0.985, y = 0.3, w = 0.27, h = 0.11, anchor = RIGHT, reason = "toast stack pinned to the right edge" })
	K.toast(root, { icon = "🍎", title = "Normal!", text = "You've discovered this for the first time!", tag = "New!", x = 0.985, y = 0.43, w = 0.27, h = 0.11, anchor = RIGHT, reason = "toast stack pinned to the right edge" })
	K.button(root, { text = "5m Time Skip  39", icon = "⏱", color = "purple", x = 0.985, y = 0.6, w = 0.2, h = 0.09, anchor = RIGHT, reason = "offer pinned to the right edge", size = 24 })
	K.button(root, { text = "x2 Coin!  19", icon = "💰", color = "pink", x = 0.985, y = 0.71, w = 0.2, h = 0.09, anchor = RIGHT, reason = "offer pinned to the right edge", size = 24 })
	K.text(root, { text = "Ends In: 06d 19h", left = true, x = 0.012, y = 0.86, w = 0.2, h = 0.05, size = 30, color = "orange", font = K.T.font })
	K.pill(root, { icon = "🍬", value = "0", color = "purple", x = 0.012, y = 0.92, w = 0.16, h = 0.06, anchor = LEFT, reason = "HUD pinned to the left screen edge" })
	return g
end

-- card-collection-log.png: left nav, filter chips, empty-state grid, detail pane
S.CollectionLog = function(K, parent)
	K.use("Pixel")
	local g, root = K.screen("CollectionLog", parent)
	K.backdrop(root, rgb(30, 16, 60), rgb(12, 8, 30))
	local panel, content = K.modal(root, { title = "COLLECTION LOG", aspect = 1.6, w = 0.72 })
	local nav = K.box(content, { name = "Nav", x = 0.12, w = 0.22, h = 1 })
	local items = { { "UPGRADES", "yellow" }, { "COLLECTION", "green" }, { "PROFILE", "purple" } }
	for i, r in ipairs(K.rows(3, 0.04)) do
		K.button(nav, { text = items[i][1], color = items[i][2], y = r.y, h = math.min(r.h, 0.18), w = 1, size = 30 })
	end
	local center = K.box(content, { name = "Center", x = 0.49, w = 0.46, h = 1 })
	local chips = { "ALL", "RAREST", "THIS RUN", "TODAY", "PINNED" }
	for i, c in ipairs(K.cells(5, 1, 0.01)) do
		K.button(center, { text = chips[i], color = i == 1 and "yellow" or "grayDark", x = c.x, y = 0.06, w = c.w, h = 0.1, size = 20, corner = "sm" })
	end
	local grid = K.box(center, { name = "Grid", y = 0.58, w = 1, h = 0.8 })
	for _, c in ipairs(K.cells(6, 4, 0.015)) do
		local slot = K.box(grid, { x = c.x, y = c.y, w = c.w, h = c.h, fill = "panelDark", corner = "sm", stroke = "thin", strokeColor = "panelLight" })
		K.text(slot, { text = "?", w = 0.5, h = 0.5, size = 40, color = "grayDark", outline = false })
	end
	local detail = K.box(content, { name = "Detail", x = 0.87, w = 0.23, h = 1, fill = "panelDark", corner = 0.04, stroke = 0.006 })
	K.text(detail, { text = "TAP A CARD TO READ IT", y = 0.08, w = 0.9, h = 0.08, size = 18, color = "gray", outline = false })
	return g
end

-- sols-roll-result-crowned-1-in-20000.png: odds line, big rarity-coloured name, controls, leaderboard
S.AuraRoll = function(K, parent)
	K.use("Aura")
	local g, root = K.screen("AuraRoll", parent)
	K.backdrop(root, rgb(10, 16, 40), rgb(2, 4, 14))
	K.rarityTitle(root, { odds = "1 in 20,000", name = "Crowned", rarity = "Legendary", x = 0.5, y = 0.25, w = 0.5, h = 0.34 })
	local lb = K.bracketPanel(root, { x = 0.985, y = 0.3, w = 0.25, h = 0.46, anchor = RIGHT, reason = "leaderboard pinned to the right edge" })
	K.text(lb, { text = "Player            Rolls", y = 0.06, w = 0.9, h = 0.07, size = 24, color = "gray" })
	local names = { "Satocry  2.18M", "Tridie  62.6M", "Nova  25.8M", "Red  7.82M", "Wat  2.30M" }
	for i, r in ipairs(K.rows(5, 0.02)) do
		local row = K.box(lb, { y = 0.14 + 0.82 * r.y, w = 0.92, h = 0.82 * r.h, fill = "panelLight", alpha = 0.4, corner = "sm" })
		K.text(row, { text = names[i], w = 0.9, h = 0.55, size = 24 })
	end
	local function ctrl(text, x, w, h)
		local p = K.bracketPanel(root, { x = x, y = 0.93, w = w, h = h or 0.07 })
		K.text(p, { text = text, w = 0.8, h = 0.55, size = 26 })
		return p
	end
	ctrl("Auto roll : ON", 0.3, 0.14)
	local roll = ctrl("Roll", 0.5, 0.2, 0.09)
	roll:FindFirstChild("Text").Font = Enum.Font.GothamBold
	roll:FindFirstChild("Text").TextColor3 = Color3.new(1, 1, 1)
	ctrl("Quick roll : ON", 0.7, 0.14)
	return g
end

-- fruit-hex-upgrade-tree.png: honeycomb upgrade tree with locked "?" nodes
S.UpgradeHex = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("UpgradeHex", parent)
	K.backdrop(root, rgb(90, 70, 40), rgb(50, 40, 30))
	local board = K.box(root, { name = "Board", w = 0.8, h = 0.8, aspect = 1.6 })
	local W = 0.2 -- hex width as a fraction of the board width
	local dx = 0.75 * W
	local dy = 0.866 * W * 1.6 -- one hex height as a fraction of the board height
	local function pos(qx, qy)
		return 0.5 + qx * dx, 0.5 + qy * dy
	end
	local nodes = {
		{ 0, 0, "Start", "blue", "icon_star" },
		{ 0, -1, "Tools", "orange", "icon_gear" },
		{ 0, 1, "Player", "orange", "icon_heart" },
		{ -1, -0.5, "2 Slots", "blue", "icon_index" },
		{ -1, 0.5, "Gold Machine\n150", "gray", "icon_coin" },
		{ 1, -0.5, "Hole Size I\n100", "gray", "icon_crystal" },
		{ 1, 0.5, "Roll Speed I\n25", "gray", "icon_bolt" },
		{ -2, 0, "?", "gray" },
		{ 2, 0, "?", "gray" },
		{ -1, -1.5, "?", "gray" },
		{ 1, 1.5, "?", "gray" },
	}
	for _, n in ipairs(nodes) do
		local x, y = pos(n[1], n[2])
		local locked = n[3] == "?"
		local hex = K.hex(board, { x = x, y = y, w = W, fill = locked and "grayDark" or n[4], outline = "outline" })
		if locked then
			K.text(hex, { text = "?", y = 0.4, w = 0.5, h = 0.4, size = 54, outline = false, color = "gray", z = 5 })
		else
			K.icon(hex, { icon = n[5], y = 0.36, w = 0.4, h = 0.4, aspect = 1, z = 5 })
		end
		if not locked then
			K.text(hex, { text = (string.gsub(n[3], "\n", " ")), y = 0.74, w = 0.9, h = 0.22, size = 30, z = 5 })
		end
	end
	K.button(root, { text = "Close", color = "red", y = 0.96, w = 0.18, h = 0.07, size = 30 })
	return g
end

-- duel-backpack-inventory-grid.png, fruit-inventory-equip-best.png: slot grid with counts, Sort / Equip Best, search
S.Inventory = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("Inventory", parent)
	K.backdrop(root, rgb(255, 150, 60), rgb(170, 90, 200))
	local panel, content = K.modal(root, { title = "Pets", color = "orange", aspect = 1.7, w = 0.66 })
	K.pill(content, { icon = "icon_paw", value = "8/1000", color = "orange", x = 0.17, y = 0.06, w = 0.3, h = 0.11 })
	K.text(content, { text = "Income: 4/6 sec", x = 0.35, y = 0.06, w = 0.26, h = 0.09, size = 34, color = "yellow", left = true })
	K.button(content, { text = "Sort", color = "blue", x = 0.69, y = 0.06, w = 0.12, h = 0.11, size = 28 })
	K.button(content, { text = "Equip Best", color = "green", x = 0.99, y = 0.06, w = 0.2, h = 0.11, size = 26, anchor = V2(1, 0.5), reason = "right-aligned toolbar" })
	local grid = K.box(content, { name = "Grid", y = 0.6, w = 1, h = 0.84 })
	local items = {
		{ "icon_egg", "x3", "Common" }, { "icon_paw", "x12", "Rare" }, { "icon_gift", "x1", "Epic" }, { "icon_chest", "x2", "Rare" },
		{ "icon_key", "x5", "Common" }, { "icon_potion", "x4", "Epic" }, { "icon_shard", "x9", "Rare" }, { "icon_crystal", "x1", "Legendary" },
	}
	for i, c in ipairs(K.cells(8, 3, 0.012)) do
		local it = items[i]
		local frame = K.sprite(grid, { sprite = "slot_dark", name = "Slot" .. i, x = c.x, y = c.y, w = c.w, h = c.h, aspect = 1 })
		if it then
			local rc = K.T.rarity[it[3]] or K.col("gray")
			K.box(frame, { name = "RarityGlow", w = 0.82, h = 0.82, fill = rc, alpha = 0.78, corner = 0.3, z = 1 })
			K.icon(frame, { icon = it[1], w = 0.8, h = 0.8, z = 2 })
			K.text(frame, { text = it[2], x = 0.95, y = 0.88, w = 0.5, h = 0.26, size = 28, right = true, z = 3 })
		end
	end
	K.popIn(panel)
	K.stagger(grid, { step = 0.02, from = 0.6 })
	return g
end

-- pet-rebirth-panel.png: requirement checklist, benefit list, one confirm button that lights up when met
S.Rebirth = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("Rebirth", parent)
	K.backdrop(root, rgb(90, 190, 255), rgb(60, 110, 220))
	local panel, content = K.modal(root, { title = "Rebirth", color = "purple", aspect = 1.75, w = 0.62 })
	local left = K.box(content, { name = "Needs", x = 0.26, y = 0.4, w = 0.46, h = 0.78, fill = "panelDark", alpha = 0.3, corner = 0.05, stroke = 0.008 })
	K.text(left, { text = "You need", y = 0.1, w = 0.8, h = 0.12, size = 34, color = "gray" })
	local reqs = { { "icon_coin", "1M Coins", true }, { "icon_paw", "10 Pets", true }, { "icon_gem", "250 Gems", false } }
	for i, r in ipairs(K.rows(3, 0.03)) do
		local row = K.box(left, { y = 0.22 + 0.76 * r.y, w = 0.92, h = 0.76 * r.h, fill = "panelLight", alpha = 0.35, corner = 0.2 })
		K.icon(row, { icon = reqs[i][1], x = 0.12, w = 0.2, h = 0.8, aspect = 1 })
		K.text(row, { text = reqs[i][2], x = 0.34, w = 0.44, h = 0.5, size = 36, left = true })
		K.icon(row, { icon = reqs[i][3] and "icon_check" or "icon_lock", x = 0.9, w = 0.14, h = 0.7, aspect = 1 })
	end
	local right = K.box(content, { name = "Gets", x = 0.75, y = 0.4, w = 0.46, h = 0.78, fill = "panelDark", alpha = 0.3, corner = 0.05, stroke = 0.008 })
	K.text(right, { text = "You get", y = 0.1, w = 0.8, h = 0.12, size = 34, color = "gray" })
	local gets = { { "icon_coin", "x2 Coin boost" }, { "icon_paw", "+1 Pet slot" }, { "icon_star", "New eggs" } }
	for i, r in ipairs(K.rows(3, 0.03)) do
		local row = K.box(right, { y = 0.22 + 0.76 * r.y, w = 0.92, h = 0.76 * r.h, fill = "panelLight", alpha = 0.35, corner = 0.2 })
		K.icon(row, { icon = gets[i][1], x = 0.12, w = 0.2, h = 0.8, aspect = 1 })
		K.text(row, { text = gets[i][2], x = 0.34, w = 0.62, h = 0.5, size = 34, left = true })
	end
	K.button(content, { text = "Rebirth!", color = "gray", y = 0.92, w = 0.42, h = 0.15, size = 44 })
	K.popIn(panel)
	return g
end

-- card-loading-screen-flash-warning.png: logo, progress bar with percent, tip, photosensitivity notice
S.Loading = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("Loading", parent)
	K.backdrop(root, rgb(110, 70, 220), rgb(40, 24, 110))
	K.text(root, { text = "GUARDIAN GRID", y = 0.3, w = 0.7, h = 0.2, size = 120, font = K.T.titleFont, color = "yellow" })
	K.icon(root, { icon = "icon_crystal", y = 0.55, w = 0.15, h = 0.24, aspect = 1 })
	K.bar(root, { value = 0.62, color = "green", text = "62%", y = 0.78, w = 0.5, h = 0.075 })
	K.text(root, { text = "Loading icons...", y = 0.855, w = 0.4, h = 0.04, size = 24, color = "gray", outline = false })
	K.text(root, { text = "Tip: merge three of the same pet to make a stronger one!", y = 0.92, w = 0.7, h = 0.045, size = 28, outline = false })
	local warn = K.box(root, { name = "FlashWarning", x = 0.5, y = 0.115, w = 0.34, h = 0.1, fill = "panelDark", alpha = 0.2, corner = 0.2, stroke = 0.01 })
	K.icon(warn, { icon = "icon_bolt", x = 0.1, w = 0.14, h = 0.8, aspect = 1 })
	K.text(warn, { text = "Flashing lights. You can turn them off in Settings.", x = 0.58, w = 0.78, h = 0.7, size = 22, outline = false })
	return g
end

return S
