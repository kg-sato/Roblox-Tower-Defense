--!nocheck
-- UIScreens2: screens added after the first set. Same rules as UIScreens (Scale only, tokens, kit components).
-- Built 2026-10-25 in Studio from the reference screenshots named in each comment.
-- Use: local S = require(UIKit.UIScreens2); S.LobbyHud(require(UIKit), parent)

local S = {}
S.order = { "LobbyHud", "BattlePass", "CrateClaim", "UnitView", "ModeSelect", "EventShop", "PassShop", "Profile", "FirstDraw", "NowPlaying", "UnlockToast", "EquipBest", "FreeReward" }

local LEFT = Vector2.new(0, 0.5)
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Sols-style Lobby HUD (redesigned 2026-10-26 after sols-roll-result-crowned-1-in-20000.png and
-- sols-daily-rewards-leaderboard.png): a column of square bracket-frame menu buttons on the left, three coloured
-- currency counters bottom-left, a ranked leaderboard top-right, an Auto / Roll / Quick cluster bottom-centre and a
-- 7-slot item bar bottom-right. A transparent overlay: it draws over the 3D world (opts.backdrop adds a mock one).
-- Phone layout (opts.phone, or auto when the viewport is under 1000 px wide): bigger touch targets, counters moved to
-- the top so the thumbstick (bottom-left) and jump button (bottom-right) stay free, item bar and hints dropped.
-- Returns the ScreenGui; g:GetAttribute("Layout") is "phone" or "desktop". Live hooks: g.Hud.<Name> frames.
S.LobbyHud = function(K, parent, opts)
	K.use("Candy")
	opts = opts or {}
	local phone = opts.phone
	if phone == nil then
		phone = K.isPhone()
	end
	local g, root = K.screen("LobbyHud", parent)
	g:SetAttribute("Layout", phone and "phone" or "desktop")
	if opts.backdrop then
		K.backdrop(root, rgb(16, 20, 44), rgb(4, 5, 14))
	end
	local hud = K.box(root, { name = "Hud", w = 1, h = 1 })

	local ACCENT = { gem = "blue", key = "purple", coin = "yellow" }

	-- left menu column ---------------------------------------------------------------------------
	local menu = {
		{ "Pets", "icon_paw" },
		{ "Relics", "icon_weapons" },
		{ "Quests", "icon_check", "3" },
		{ "Shop", "icon_shop" },
		{ "Pass", "icon_trophy", "!" },
		{ "Index", "icon_index" },
	}
	if phone then
		table.remove(menu, 6)
	end
	-- desktop: a column on the left edge. phone: a row along the top, right of Roblox's own buttons, so the
	-- thumbstick (bottom-left) and jump button (bottom-right) stay free.
	local col = K.box(hud, {
		name = "Menu", x = phone and 0.215 or 0.011, y = phone and 0.09 or 0.5, w = phone and 0.33 or 0.03, h = phone and 0.13 or 0.5,
		anchor = LEFT, reason = "HUD pinned to the left of the screen",
	})
	for i, it in ipairs(menu) do
		local cp = (i - 0.5) / #menu
		local b = K.sprite(col, {
			sprite = "hud_slot", class = "ImageButton", name = "Menu_" .. it[1], x = phone and cp or 0.5, y = phone and 0.5 or cp,
			w = phone and 0.19 or 1, h = phone and 1 or nil, aspect = 1,
		})
		b.AutoButtonColor = false
		K.icon(b, { icon = it[2], w = 0.84, aspect = 1 })
		if it[3] then
			K.badge(b, { text = it[3], x = 0.92, y = 0.1, w = 0.42 })
		end
		K.pressFx(b)
	end

	-- currency counters ----------------------------------------------------------------------------
	local counters = { { "gem", "icon_gem", "cyan", "0" }, { "key", "icon_key", "violet", "10,148" }, { "coin", "icon_coin", "gold", "961,609" } }
	local cbox
	if phone then
		cbox = K.box(hud, { name = "Counters", x = 0.395, y = 0.235, w = 0.37, h = 0.1 })
	else
		cbox = K.box(hud, {
			name = "Counters", x = 0.0055, y = 0.915, w = 0.112, h = 0.14, anchor = LEFT, reason = "HUD pinned to the left screen edge",
		})
	end
	for i, c in ipairs(counters) do
		local cell
		if phone then
			cell = K.sprite(cbox, { sprite = "hud_counter_" .. c[3], name = "Counter_" .. c[1], x = (i - 0.5) / 3, w = 0.325, h = 0.95 })
		else
			cell = K.sprite(cbox, { sprite = "hud_counter_" .. c[3], name = "Counter_" .. c[1], y = 0.17 + (i - 1) * 0.33, w = 1, h = 0.3 })
		end
		K.icon(cell, { icon = c[2], x = 0.12, h = 0.86, aspect = 1, byHeight = true })
		K.text(cell, { text = c[4], x = 0.27, w = 0.68, h = 0.6, size = 34, left = true, outline = false, color = "text", font = K.T.numberFont })
	end
	if not phone then
		K.text(hud, { name = "Version", text = "v0.1  [ NORMAL ]", x = 0.0055, y = 0.797, w = 0.1, h = 0.022, size = 22, left = true, outline = true, color = "gray" })
		K.text(hud, { name = "Clock", text = "DUSK  03:58", x = 0.0055, y = 0.823, w = 0.1, h = 0.026, size = 26, left = true, outline = true, color = "purple" })
	end

	-- Auto / Roll / Quick cluster -------------------------------------------------------------------
	local cluster = K.box(hud, { name = "RollCluster", x = 0.5, y = phone and 0.87 or 0.94, w = phone and 0.5 or 0.36, h = phone and 0.22 or 0.11 })
	local function wide(name, text, on, x, w)
		local b = K.sprite(cluster, { sprite = on and "hud_btn_on" or "hud_btn", class = "ImageButton", name = name, x = x, y = 0.45, w = w, h = 0.55 })
		b.AutoButtonColor = false
		K.text(b, { text = text, w = 0.86, h = 0.56, size = 32, outline = false })
		K.pressFx(b)
		return b
	end
	wide("Auto", "Auto: ON", true, 0.1, 0.19)
	wide("Quick", "Quick: ON", true, 0.9, 0.19)
	local roll = K.sprite(cluster, { sprite = "hud_roll", class = "ImageButton", name = "Roll", x = 0.5, y = 0.45, w = 0.4, h = 0.7 })
	roll.AutoButtonColor = false
	K.text(roll, { text = "Roll", y = 0.45, w = 0.7, h = 0.62, size = 70, color = "yellow", outline = false, font = K.T.titleFont })
	K.text(cluster, { name = "RollCount", text = "4 / 10", x = 0.5, y = 0.93, w = 0.2, h = 0.2, size = 20, outline = true, color = "text" })
	K.pressFx(roll)
	K.pulse(roll, { scale = 1.03, period = 1.1 })
	if not phone then
		K.text(hud, { name = "Hint", text = "Merge three matching pets to level them up", x = 0.5, y = 0.862, w = 0.3, h = 0.024, size = 24, outline = true, color = "text" })
	end

	-- item bar (desktop only) -----------------------------------------------------------------------
	if not phone then
		local bar = K.box(hud, {
			name = "ItemBar", x = 0.998, y = 0.956, w = 0.285, h = 0.075, anchor = Vector2.new(1, 0.5), reason = "HUD pinned to the right screen edge",
		})
		local items = { { "icon_potion", "x3" }, { "icon_potion", "x1" }, { "icon_key", "x2" }, { "icon_gift", "x1" }, { "icon_crystal", "x4" }, { "icon_shard", "x1" }, { "icon_lock", "" } }
		for i, it in ipairs(items) do
			local slot = K.sprite(bar, { sprite = i == 1 and "hud_slot_hot" or "hud_slot", name = "Slot" .. i, x = (i - 0.5) / 7, w = 0.138, aspect = 1 })
			K.icon(slot, { icon = it[1], w = 0.64, aspect = 1, y = 0.46 })
			if it[2] ~= "" then
				K.text(slot, { text = it[2], x = 0.88, y = 0.86, w = 0.5, h = 0.26, size = 16, right = true, color = "yellow", outline = false })
			end
			K.text(slot, { text = tostring(i), x = 0.14, y = 0.14, w = 0.3, h = 0.24, size = 14, left = true, color = "gray", outline = false })
		end
	end

	-- leaderboard ---------------------------------------------------------------------------------------
	local players = {
		{ "Satocry", "2.18M", "icon_star", "Mythic" }, { "Tridie", "62.6M", "icon_dragon", "Legendary" }, { "Mario", "38.0M", "icon_crown", "Legendary" },
		{ "DaBoss_013", "31.4M", "icon_crystal", "Epic" }, { "Novo", "25.8M", "icon_gem", "Epic" }, { "liam", "17.8M", "icon_shard", "Rare" },
		{ "NEYMAR_JRFAN", "17.3M", "icon_heart", "Rare" }, { "Kenis50002", "13.7M", "icon_paw", "Uncommon" }, { "kyy", "9.30M", "icon_egg", "Common" },
	}
	local nrows = phone and 5 or #players
	local board = K.box(hud, {
		name = "Leaderboard", x = 0.998, y = phone and 0.02 or 0.012, w = phone and 0.205 or 0.2, h = phone and 0.44 or 0.5,
		anchor = Vector2.new(1, 0), reason = "HUD pinned to the top-right screen corner",
	})
	local head = K.sprite(board, { sprite = "hud_row", name = "Header", y = 0.05, w = 1, h = 0.085 })
	K.text(head, { text = "Player", x = 0.36, w = 0.4, h = 0.6, size = 22, outline = false, color = "text" })
	K.text(head, { text = "Rolls", x = 0.88, w = 0.3, h = 0.6, size = 22, outline = false, color = "text" })
	for i = 1, nrows do
		local p = players[i]
		local y = 0.145 + (i - 0.5) * (0.855 / nrows)
		local row = K.sprite(board, { sprite = "hud_row", name = "Row" .. i, y = y, w = 1, h = 0.855 / nrows * 0.94, z = 2 })
		K.icon(row, { icon = p[3], x = 0.075, w = 0.12, aspect = 1, byHeight = true })
		K.text(row, { text = p[1], x = 0.17, w = 0.5, h = 0.58, size = 24, left = true, color = K.T.rarity[p[4]], outline = false })
		K.text(row, { text = p[2], x = 0.96, w = 0.28, h = 0.58, size = 24, right = true, outline = false })
	end
	local fold = K.sprite(hud, { sprite = "hud_slot", class = "ImageButton", name = "BoardToggle", x = phone and 0.735 or 0.775, y = phone and 0.1 or 0.033, w = phone and 0.058 or 0.016, aspect = 1 })
	fold.AutoButtonColor = false
	K.text(fold, { text = ">", w = 0.6, h = 0.6, size = 22, outline = false })

	K.stagger(col, { step = 0.04 })
	K.stagger(board, { step = 0.03 })
	return g
end

-- duel-battle-pass-track.png: level block + progress bar with a tooltip, two reward rows (free and premium)
-- with 7 columns, a level tab strip, two bundle cards with sale prices, red close button.
S.BattlePass = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("BattlePass", parent)
	K.backdrop(root, rgb(20, 40, 18), rgb(8, 14, 8))

	K.button(root, { text = "X", color = "red", x = 0.943, y = 0.075, w = 0.056, h = 0.05, size = 44, name = "Close" })

	-- level block, tooltip, progress bar and arrows
	local level = K.box(root, { name = "LevelBlock", x = 0.135, y = 0.185, w = 0.078, h = 0.1, fill = "panelDark", alpha = 0.3 })
	K.text(level, { text = "1", y = 0.36, w = 0.5, h = 0.6, size = 80, outline = false })
	K.text(level, { text = "Level", y = 0.8, w = 0.7, h = 0.28, size = 34, outline = false, color = "gray" })
	local tip = K.box(root, { name = "Tooltip", x = 0.337, y = 0.147, w = 0.34, h = 0.036, fill = rgb(10, 13, 28), corner = 0.2, stroke = 0.02, strokeColor = "blue" })
	local tipText = K.text(tip, { text = "Win (<b>24</b> / 25) rounds in duels or play for (<b>12.9</b> / 20) minutes to level up", w = 0.96, h = 0.72, size = 24, outline = false })
	tipText.RichText = true
	K.bar(root, { value = 0.96, x = 0.323, y = 0.2, w = 0.292, h = 0.03, color = "blue", text = "Level 2", size = 26 })
	-- arrows: left is disabled (grey), right is white with a dark arrow, as in the reference
	local prev = K.button(root, { text = "<", color = "gray", x = 0.81, y = 0.2, w = 0.052, h = 0.06, name = "Prev", size = 60 })
	local nextBtn = K.button(root, { text = ">", color = "blue", x = 0.874, y = 0.2, w = 0.052, h = 0.06, name = "Next", size = 60 })
	local nextLabel = nextBtn:FindFirstChild("Label", true)
	if nextLabel then
		nextLabel.TextColor3 = rgb(240, 244, 255)
		local stroke = nextLabel:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Enabled = false
		end
	end

	-- reward rows: free (dark) and premium (gold)
	local columns = { 0.23, 0.332, 0.435, 0.537, 0.64, 0.742, 0.844 }
	local free = { { "icon_potion", "" }, { "icon_gift", "Ruined Pillars" }, { "icon_key", "x1" }, { "icon_potion", "" }, { "icon_potion", "" }, { "icon_paw", "AAAND.. CUT!" }, { "icon_egg", "Ruined Pillars" } }
	local prem = { { "icon_pickaxe", "Grapple" }, { "icon_crystal", "Police Siren" }, { "icon_gift", "Ruined Pillars" }, { "icon_key", "x1" }, { "icon_potion", "" }, { "icon_star", "Impact Frame" }, { "icon_gift", "Ruined Pillars" } }
	local function tile(y, color, icon)
		local t = K.box(root, { name = "RowTile", x = 0.139, y = y, w = 0.07, h = 0.166, fill = color, corner = 0.04 })
		K.icon(t, { icon = icon, w = 0.7, aspect = 1 })
	end
	tile(0.33, rgb(30, 34, 60), "icon_trophy")
	tile(0.512, rgb(88, 58, 8), "icon_crown")
	local function row(y, data, premium)
		local r = K.box(root, { name = premium and "PremiumRow" or "FreeRow", y = y, w = 1, h = 0.17 })
		for i, d in ipairs(data) do
			local c = K.box(r, { name = "Reward" .. i, x = columns[i], y = 0.5, w = 0.0932, h = 1, fill = premium and rgb(60, 44, 8) or rgb(14, 14, 14), alpha = 0.15, corner = 0.03 })
			K.icon(c, { icon = d[1], y = 0.4, w = 0.7, aspect = 1 })
			if d[2] ~= "" then
				K.text(c, { text = d[2], y = 0.82, w = 0.96, h = 0.2, size = 28 })
			end
			K.box(c, { name = "Foot", y = 0.965, w = 1, h = 0.07, fill = premium and rgb(255, 208, 96) or rgb(150, 160, 200), corner = 0.3 })
		end
		return r
	end
	local freeRow = row(0.33, free, false)
	local premRow = row(0.512, prem, true)

	-- level tabs
	local strip = K.box(root, { name = "LevelTabs", x = 0.497, y = 0.636, w = 0.8, h = 0.05, fill = rgb(8, 8, 8), alpha = 0.1, corner = 0.15 })
	for i, c in ipairs(columns) do
		local x = (c - 0.097) / 0.8
		K.text(strip, { text = tostring(i), x = x, y = 0.34, w = 0.07, h = 0.5, size = 32, color = "text" })
		K.box(strip, { name = "Tab" .. i, x = x, y = 0.8, w = 0.12, h = 0.14, fill = i == 1 and "green" or "grayDark", corner = "pill" })
	end

	-- bundle cards
	local function bundle(name, x, top, bottom, was, now)
		local card = K.box(root, { name = name, x = x, y = 0.9, w = 0.38, h = 0.26, fill = bottom:Lerp(rgb(0, 0, 0), 0.6), gradient = { top:Lerp(rgb(0, 0, 0), 0.62), bottom:Lerp(rgb(0, 0, 0), 0.85) }, corner = 0.05, stroke = 0.006, strokeColor = top, clip = true })
		K.text(card, { text = name, x = 0.05, y = 0.2, w = 0.6, h = 0.22, size = 64, left = true, font = K.T.titleFont, color = "yellow" })
		K.icon(card, { icon = "icon_crystal", x = 0.4, y = 0.62, w = 0.3, aspect = 1 })
		local tag = K.box(card, { name = "WasPrice", x = 0.82, y = 0.38, w = 0.25, h = 0.2, fill = "redDark", corner = 0.2, stroke = 0.03, strokeColor = "red" })
		local was_ = K.text(tag, { text = "<s>" .. was .. "</s>", w = 0.8, h = 0.66, size = 32, outline = false })
		was_.RichText = true
		K.button(card, { text = now, icon = "icon_gem", color = "green", x = 0.82, y = 0.78, w = 0.32, h = 0.3, size = 46 })
		return card
	end
	bundle("Prime Bundle", 0.286, rgb(255, 214, 40), rgb(190, 130, 10), "724", "689")
	bundle("Contraband Bundle", 0.708, rgb(170, 90, 255), rgb(70, 30, 150), "2,499", "749")

	K.stagger(freeRow, { step = 0.04 })
	K.stagger(premRow, { step = 0.04 })
	return g
end

-- duel-welcome-back-crate-claim.png: dim banner with a welcome line, a crate with a count, a big Claim button
S.CrateClaim = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("CrateClaim", parent)
	K.backdrop(root, rgb(34, 70, 12), rgb(6, 16, 4))
	local banner = K.box(root, { name = "Welcome", x = 0.5, y = 0.345, w = 0.38, h = 0.092, fill = rgb(0, 0, 0), alpha = 0.55, corner = 0.06 })
	K.text(banner, { text = "Welcome back, Satocry!", y = 0.36, w = 0.94, h = 0.5, size = 54 })
	K.text(banner, { text = "Here's a free pet crate, just for you!", y = 0.76, w = 0.8, h = 0.3, size = 30, color = "gray", outline = false })
	local crate = K.icon(root, { icon = "icon_chest", x = 0.5, y = 0.5, w = 0.13, aspect = 1 })
	K.text(root, { text = "x1", x = 0.5, y = 0.585, w = 0.06, h = 0.07, size = 60 })
	local claim = K.button(root, { text = "Claim", color = "green", x = 0.5, y = 0.655, w = 0.108, h = 0.076, size = 56 })
	K.pulse(claim, { scale = 1.07, period = 0.7 })
	K.popIn(banner)
	return g
end

-- duel-weapon-view-level-up.png, shown here for a pet: collection panel and list on the left, big model in the middle,
-- action row at the bottom, name, level bar and three action rows on the right.
S.UnitView = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("UnitView", parent)
	K.backdrop(root, rgb(30, 38, 34), rgb(14, 18, 16))
	K.pill(root, { icon = "icon_key", value = "73", color = "yellow", plus = true, x = 0.5, y = 0.06, w = 0.14, h = 0.07 })

	-- left: collection panel
	local career = K.box(root, { name = "Collection", x = 0.006, y = 0.482, w = 0.175, h = 0.2, anchor = LEFT, reason = "HUD pinned to the left screen edge", fill = "panelDark", alpha = 0.35, corner = 0.05 })
	K.icon(career, { icon = "icon_paw", x = 0.2, y = 0.26, w = 0.2, aspect = 1 })
	K.text(career, { text = "Collection", x = 0.62, y = 0.26, w = 0.6, h = 0.2, size = 36, color = "gray" })
	for i, ic in ipairs({ "icon_dragon", "icon_paw", "icon_crystal", "icon_heart", "icon_bolt" }) do
		K.icon(career, { icon = ic, x = 0.1 + (i - 1) * 0.2, y = 0.58, w = 0.14, aspect = 1 })
	end
	K.button(career, { text = "Dismiss 5 Notifications", color = "red", x = 0.5, y = 0.86, w = 0.94, h = 0.2, size = 30, corner = "pill" })

	-- left: list
	local list = K.box(root, { name = "PetList", x = 0.006, y = 0.795, w = 0.175, h = 0.41, anchor = LEFT, reason = "HUD pinned to the left screen edge", fill = "panelDark", alpha = 0.35, corner = 0.03 })
	K.text(list, { text = "Legendary", y = 0.07, w = 0.6, h = 0.07, size = 30, color = "gray", outline = false })
	local names = { { "Star Drake", true }, { "Volt Fox" }, { "Boulder" }, { "Frostling" }, { "Sprout", false, "1" } }
	for i, n in ipairs(names) do
		local y = 0.2 + (i - 1) * 0.17
		if n[2] then
			K.box(list, { name = "Selected", y = y, w = 1, h = 0.15, fill = rgb(10, 10, 14), alpha = 0.2 })
		end
		K.text(list, { text = n[1], x = 0.45, y = y, w = 0.7, h = n[2] and 0.12 or 0.1, size = n[2] and 40 or 32, color = n[2] and "text" or "gray" })
		K.icon(list, { icon = "icon_paw", x = 0.86, y = y, w = 0.18, aspect = 1 })
		if n[3] then
			K.badge(list, { text = n[3], x = 0.65, y = y, w = 0.1, h = 0.1 })
		end
	end

	-- centre: model stand-in (a big icon), with a soft glow disc behind it
	K.box(root, { name = "Glow", x = 0.5, y = 0.46, w = 0.3, aspect = 1, fill = rgb(70, 46, 150), alpha = 0.55, corner = "pill", stroke = 0.004, strokeColor = "purple" })
	K.icon(root, { icon = "icon_dragon", x = 0.5, y = 0.46, w = 0.3, aspect = 1 })

	-- bottom action row
	local acts = K.box(root, { name = "Actions", x = 0.5, y = 0.955, w = 0.34, h = 0.075, fill = rgb(0, 0, 0), alpha = 0.55, corner = 0.1 })
	local aitems = { { "Leave", "X" }, { "Skin", "icon_paw" }, { "Aura", "icon_star" }, { "Charm", "icon_bell" }, { "Evolve", "icon_crown" } }
	for i, it in ipairs(aitems) do
		local x = (i - 0.5) / #aitems
		local cell = K.box(acts, { x = x, w = 0.19, h = 1 })
		if it[2] == "X" then
			K.text(cell, { text = "X", y = 0.3, w = 0.7, h = 0.9, size = 70, color = "red" })
		else
			K.icon(cell, { icon = it[2], y = 0.3, w = 0.62, aspect = 1 })
		end
		K.text(cell, { text = it[1], y = 0.84, w = 1.0, h = 0.3, size = 28 })
	end

	-- right: name block
	local info = K.box(root, { name = "Info", x = 0.994, y = 0.587, w = 0.175, h = 0.09, anchor = Vector2.new(1, 0.5), reason = "HUD pinned to the right screen edge", fill = "panelDark", alpha = 0.35, corner = 0.06 })
	K.text(info, { text = "Star Drake", x = 0.05, y = 0.28, w = 0.8, h = 0.42, size = 48, left = true })
	K.text(info, { text = "Legendary pet", x = 0.05, y = 0.64, w = 0.9, h = 0.2, size = 24, left = true, color = "gray", outline = false })
	K.text(info, { text = "Fast fire, long range", x = 0.05, y = 0.84, w = 0.9, h = 0.2, size = 24, left = true, color = "gray", outline = false })

	-- right: level block
	local lvl = K.box(root, { name = "LevelBlock", x = 0.994, y = 0.72, w = 0.175, h = 0.155, anchor = Vector2.new(1, 0.5), reason = "HUD pinned to the right screen edge", fill = "panelDark", alpha = 0.35, corner = 0.05 })
	K.bar(lvl, { value = 0.4, y = 0.16, w = 0.94, h = 0.17, color = "blue" })
	K.text(lvl, { text = "54", y = 0.16, w = 0.2, h = 0.22, size = 50, z = 5 })
	K.text(lvl, { text = "Level up now!", x = 0.05, y = 0.52, w = 0.5, h = 0.2, size = 30, left = true })
	K.button(lvl, { text = "5", icon = "icon_key", color = "yellow", x = 0.82, y = 0.52, w = 0.34, h = 0.3, size = 40 })
	K.text(lvl, { text = "Reward at Level 99", x = 0.05, y = 0.84, w = 0.6, h = 0.18, size = 26, left = true })
	K.icon(lvl, { icon = "icon_gift", x = 0.9, y = 0.84, w = 0.16, aspect = 1 })

	-- right: three action rows
	local rowsBox = K.box(root, { name = "Rows", x = 0.994, y = 0.895, w = 0.175, h = 0.2, anchor = Vector2.new(1, 0.5), reason = "HUD pinned to the right screen edge", fill = "panelDark", alpha = 0.35, corner = 0.05 })
	local rr = { { "Quests", "Earn free rewards", ">" }, { "Overview", "View pet metrics", "View" }, { "Statistics", "See lifetime data", "View" } }
	for i, r in ipairs(K.rows(3, 0.04)) do
		K.text(rowsBox, { text = rr[i][1], x = 0.08, y = r.y - r.h * 0.18, w = 0.5, h = r.h * 0.42, size = 32, left = true })
		K.text(rowsBox, { text = rr[i][2], x = 0.08, y = r.y + r.h * 0.22, w = 0.55, h = r.h * 0.3, size = 20, left = true, color = "gray", outline = false })
		K.button(rowsBox, { text = rr[i][3], color = "blue", x = 0.82, y = r.y, w = 0.32, h = r.h * 0.9, size = 30 })
	end

	-- bottom-left: red lock tab
	local tab = K.box(root, { name = "LockTab", x = 0.225, y = 0.958, w = 0.044, h = 0.05, fill = "redDark", gradient = true, corner = 0.2, stroke = 0.06, strokeColor = "red" })
	K.icon(tab, { icon = "icon_lock", w = 0.6, aspect = 1 })
	K.stagger(list, { step = 0.04 })
	return g
end

-- duel-mode-select-tiles.png: a grid of mode tiles (one selected with a white border), a big locked tile with a
-- level requirement, a "limited time" strip with reward chips, two big event banners, a red close button.
S.ModeSelect = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("ModeSelect", parent)
	K.backdrop(root, rgb(46, 84, 16), rgb(12, 28, 6))
	K.button(root, { text = "X", color = "red", x = 0.9156, y = 0.17, w = 0.058, h = 0.054, size = 44, name = "Close" })

	local function tile(name, x, y, w, h, top, bottom, selected)
		local t = K.box(root, { name = "Tile_" .. name, x = x, y = y, w = w, h = h, fill = bottom:Lerp(rgb(0, 0, 0), 0.6), gradient = { top:Lerp(rgb(0, 0, 0), 0.62), bottom:Lerp(rgb(0, 0, 0), 0.85) }, corner = 0.04, stroke = selected and 0.012 or 0.006, strokeColor = selected and "yellow" or top })
		K.text(t, { text = name, w = 0.7, h = 0.42, size = 90 })
		return t
	end
	local sky1, sky2 = rgb(120, 140, 220), rgb(60, 70, 150)
	local pink1, pink2 = rgb(240, 90, 200), rgb(110, 50, 190)
	tile("Easy", 0.2185, 0.2556, 0.168, 0.254, sky1, sky2)
	tile("Normal", 0.3902, 0.2556, 0.168, 0.254, sky1, sky2)
	tile("Hard", 0.5617, 0.2556, 0.168, 0.254, sky1, sky2)
	tile("Nightmare", 0.261, 0.5167, 0.255, 0.254, sky1, sky2)
	tile("Endless", 0.518, 0.5167, 0.25, 0.254, pink1, pink2, true)

	local ranked = K.box(root, { name = "Ranked", x = 0.756, y = 0.4306, w = 0.2167, h = 0.515, fill = rgb(10, 12, 16), alpha = 0.1, corner = 0.03 })
	K.text(ranked, { text = "Ranked", y = 0.1, w = 0.9, h = 0.14, size = 80 })
	K.icon(ranked, { icon = "icon_lock", y = 0.48, w = 0.36, aspect = 1 })
	K.text(ranked, { text = "Unlocked at Level 25", y = 0.84, w = 0.8, h = 0.16, size = 42, outline = false })

	local strip = K.box(root, { name = "Limited", x = 0.295, y = 0.778, w = 0.325, h = 0.065, fill = rgb(0, 0, 0), alpha = 0.5, corner = 0.1 })
	K.icon(strip, { icon = "icon_star", x = 0.08, w = 0.1, aspect = 1 })
	K.text(strip, { text = "Here for a limited time only!", x = 0.56, w = 0.8, h = 0.6, size = 44 })
	local chips = { { "Gem Crown", "icon_crown" }, { "Zombie", "icon_dragon" }, { "Fists", "icon_pickaxe" }, { "Gargoyle", "icon_shard" }, { "Frost", "icon_crystal" }, { "Wildcat", "icon_paw" } }
	local chipBox = K.box(root, { name = "Chips", x = 0.7, y = 0.755, w = 0.31, h = 0.1 })
	for i, c in ipairs(chips) do
		local x = (i - 0.5) / #chips
		local chip = K.box(chipBox, { x = x, y = 0.4, w = 0.15, h = 0.8, fill = rgb(8, 40, 28), gradient = true, corner = 0.12, stroke = 0.03, strokeColor = "green" })
		K.icon(chip, { icon = c[2], y = 0.45, w = 0.7, aspect = 1 })
		K.text(chipBox, { text = c[1], x = x, y = 0.95, w = 0.17, h = 0.2, size = 22, outline = false })
	end

	local function banner(name, sub, x, w, top, bottom)
		local b = K.box(root, { name = "Banner_" .. name, x = x, y = 0.92, w = w, h = 0.2, fill = bottom:Lerp(rgb(0, 0, 0), 0.6), gradient = { top:Lerp(rgb(0, 0, 0), 0.62), bottom:Lerp(rgb(0, 0, 0), 0.85) }, corner = 0.03, stroke = 0.004, strokeColor = top, clip = true })
		K.text(b, { text = name, y = 0.38, w = 0.9, h = 0.4, size = 100, font = K.T.titleFont })
		if sub then
			K.text(b, { text = sub, y = 0.72, w = 0.5, h = 0.18, size = 40, color = "gray", outline = false })
		end
		return b
	end
	banner("Spooky Tower", "There's more?", 0.389, 0.509, rgb(40, 100, 110), rgb(14, 30, 40))
	banner("CO-OP", nil, 0.753, 0.218, rgb(30, 70, 100), rgb(10, 24, 40))

	return g
end

-- duel-event-shop-candy.png: two currency pills, an event banner, a locked-earning strip, a "spend" grid with
-- price tags (green = Robux, orange = event currency), and a big limited bundle.
S.EventShop = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("EventShop", parent)
	K.backdrop(root, rgb(18, 40, 16), rgb(4, 10, 4))
	K.pill(root, { icon = "icon_key", value = "73", color = "yellow", plus = true, x = 0.43, y = 0.06, w = 0.12, h = 0.065 })
	K.pill(root, { icon = "icon_candy", value = "0", color = "orange", plus = true, x = 0.57, y = 0.06, w = 0.12, h = 0.065 })
	K.button(root, { text = "X", color = "red", x = 0.757, y = 0.215, w = 0.044, h = 0.05, size = 40, name = "Close" })

	local col = K.box(root, { name = "Column", x = 0.5, y = 0.62, w = 0.431, h = 0.82 })
	local banner = K.box(col, { name = "Banner", y = 0.1, w = 1, h = 0.15, fill = rgb(24, 44, 70), gradient = { rgb(26, 50, 82), rgb(6, 12, 28) }, corner = 0.03, stroke = 0.004, strokeColor = "blue" })
	K.text(banner, { text = "SPOOKY EVENT", y = 0.46, w = 0.8, h = 0.62, size = 100, font = K.T.titleFont })
	K.text(banner, { text = "Here for a limited time only!", y = 0.88, w = 0.5, h = 0.2, size = 34, color = "gray", outline = false })
	local lock = K.box(col, { name = "LockStrip", y = 0.235, w = 1, h = 0.07, fill = rgb(0, 0, 0), alpha = 0.4, corner = 0.12 })
	K.icon(lock, { icon = "icon_lock", x = 0.06, w = 0.05, aspect = 1 })
	K.text(lock, { text = "Complete your Daily Tasks to start earning Candy!", w = 0.8, h = 0.6, size = 40 })
	K.icon(lock, { icon = "icon_lock", x = 0.94, w = 0.05, aspect = 1 })

	local spend = K.box(col, { name = "Spend", y = 0.52, w = 1, h = 0.4, fill = rgb(0, 0, 0), alpha = 0.35, corner = 0.03 })
	K.icon(spend, { icon = "icon_gift", x = 0.07, y = 0.09, w = 0.07, aspect = 1 })
	K.text(spend, { text = "Spend Candy!", x = 0.37, y = 0.09, w = 0.4, h = 0.1, size = 46, left = false })
	local items = {
		{ "icon_chest", "30", "robux" }, { "icon_chest", "289", "robux" }, { "icon_chest", "30", "candy" },
		{ "icon_dragon", "1,000", "candy" }, { "icon_crystal", "2,000", "candy" }, { "icon_gift", "3,000", "candy" },
		{ "icon_paw", "5,000", "candy" }, { "icon_crown", "1,199", "robux" },
	}
	for i, it in ipairs(items) do
		local col_, row_ = (i - 1) % 6, (i - 1) // 6
		local cx, cy = 0.1 + col_ * 0.158, 0.37 + row_ * 0.36
		local tile = K.box(spend, { name = "Item" .. i, x = cx, y = cy, w = 0.125, h = 0.3, fill = "panelLight", gradient = true, corner = 0.1, stroke = 0.03, strokeColor = "yellow" })
		K.icon(tile, { icon = it[1], y = 0.42, w = 0.78, aspect = 1 })
		local color = it[3] == "robux" and "green" or "orange"
		K.button(tile, { text = it[2], icon = it[3] == "robux" and "icon_gem" or "icon_candy", color = color, y = 1.0, w = 0.86, h = 0.3, size = 26, corner = "pill" })
	end

	local bundle = K.box(col, { name = "Bundle", y = 0.93, w = 1, h = 0.26, fill = rgb(50, 20, 96), gradient = { rgb(62, 26, 116), rgb(10, 5, 28) }, corner = 0.03, stroke = 0.004, strokeColor = "purple", clip = true })
	for i = 1, 4 do
		local slot = K.box(bundle, { x = 0.46 + (i - 1) * 0.14, y = 0.4, w = 0.125, h = 0.5, fill = "panelLight", gradient = true, corner = 0.08, stroke = 0.03, strokeColor = "yellow" })
		K.icon(slot, { icon = ({ "icon_crown", "icon_heart", "icon_dragon", "icon_shard" })[i], w = 0.8, aspect = 1 })
	end
	K.text(bundle, { text = "Bat Bundle", x = 0.28, y = 0.82, w = 0.45, h = 0.2, size = 70, font = K.T.titleFont })
	local tag = K.box(bundle, { name = "Limited", x = 0.9, y = 0.84, w = 0.15, h = 0.16, fill = "redDark", corner = 0.1, stroke = 0.03, strokeColor = "red" })
	K.text(tag, { text = "LIMITED", w = 0.86, h = 0.6, size = 36, outline = false })
	K.stagger(spend, { step = 0.03 })
	return g
end

-- pet-shop-gamepasses.png: tab strip, a "Gamepasses" header, a Hatching section with one wide bundle card and six
-- pass cards (tag line, description, green price button, "or tokens" line), and the top of a Pets section.
S.PassShop = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("PassShop", parent)
	K.backdrop(root, rgb(34, 90, 70), rgb(16, 44, 36))
	local tabs = K.box(root, { name = "TabStrip", x = 0.44, y = 0.14, w = 0.46, h = 0.07, fill = rgb(10, 36, 70), alpha = 0.1, corner = 0.5, stroke = 0.04, strokeColor = rgb(80, 170, 255) })
	local names = { "Featured", "Chronos Egg", "Passes", "Giveaways", "Tokens" }
	for i, n in ipairs(names) do
		local x = (i - 0.5) / #names
		if i == 3 then
			K.box(tabs, { x = x, w = 0.2, h = 0.9, fill = "green", gradient = true, corner = 0.5 })
		end
		K.text(tabs, { text = n, x = x + 0.01, w = 0.17, h = 0.5, size = 36 })
	end
	K.icon(root, { icon = "icon_crown", x = 0.095, y = 0.27, w = 0.04, aspect = 1 })
	K.text(root, { text = "Gamepasses", x = 0.255, y = 0.27, w = 0.22, h = 0.07, size = 80, left = false })
	K.text(root, { text = "Permanent - pay with Robux or Tokens", x = 0.5, y = 0.272, w = 0.3, h = 0.04, size = 30, color = "text" })

	local function section(y, h, title, owned, note)
		local sec = K.box(root, { name = "Section_" .. title, x = 0.5, y = y, w = 0.87, h = h, fill = rgb(8, 11, 24), corner = 0.03, stroke = 0.006, strokeColor = "blue" })
		K.icon(sec, { icon = "icon_egg", x = 0.035, y = 0.12, w = 0.04, aspect = 1 })
		K.text(sec, { text = title, x = 0.155, y = 0.12, w = 0.14, h = 0.12, size = 64, color = "blue", outline = false })
		local o = K.box(sec, { x = 0.255, y = 0.12, w = 0.06, h = 0.08, fill = rgb(20, 40, 80), corner = 0.5 })
		K.text(o, { text = owned, w = 0.8, h = 0.6, size = 26, outline = false })
		if note then
			K.text(sec, { text = note, x = 0.95, y = 0.12, w = 0.3, h = 0.08, size = 30, right = true, color = "gray", outline = false })
		end
		return sec
	end
	local hatching = section(0.52, 0.4, "Hatching", "0/6 owned", nil)
	-- wide bundle card
	local wide = K.box(hatching, { name = "HatchBundle", x = 0.18, y = 0.6, w = 0.28, h = 0.7, fill = rgb(90, 46, 10), gradient = { rgb(112, 62, 14), rgb(30, 14, 6) }, corner = 0.06, stroke = 0.01, strokeColor = "yellow", clip = true })
	local incl = K.box(wide, { name = "Included", x = 0.3, y = 0.3, w = 0.5, h = 0.5, fill = rgb(0, 0, 0), alpha = 0.7, corner = 0.08 })
	for i, line in ipairs({ "Octo Hatch", "Fast Hatch", "Magic Eggs", "Lucky Eggs", "Super Lucky", "Secret Hunter" }) do
		K.text(incl, { text = line, x = 0.1, y = 0.1 + (i - 1) * 0.16, w = 0.85, h = 0.13, size = 22, left = true, outline = false })
	end
	K.icon(wide, { icon = "icon_egg", x = 0.76, y = 0.34, w = 0.3, aspect = 1 })
	K.text(wide, { text = "Hatch Bundle", x = 0.62, y = 0.62, w = 0.7, h = 0.1, size = 40 })
	local ribbon = K.box(wide, { x = 0.88, y = 0.1, w = 0.4, h = 0.09, rotation = 40, fill = "redDark", corner = 0.1, stroke = 0.03, strokeColor = "red" })
	K.text(ribbon, { text = "BEST DEAL", w = 0.9, h = 0.7, size = 22, outline = false })
	K.text(wide, { text = "SAVE 5%", x = 0.3, y = 0.76, w = 0.3, h = 0.07, size = 24, color = "yellow" })
	K.text(wide, { text = "<s>6,049</s>", x = 0.7, y = 0.76, w = 0.3, h = 0.07, size = 24, color = "red" }).RichText = true
	K.button(wide, { text = "5,749", icon = "icon_gem", color = "green", y = 0.9, w = 0.92, h = 0.14, size = 44 })
	local cards = {
		{ "Octo Hatch", "x8 per hatch", "Open 8 eggs at once.", "995", rgb(180, 70, 255), rgb(90, 20, 160) },
		{ "Fast Hatch", "1.5x speed", "Open eggs at a greater speed!", "199", rgb(110, 200, 255), rgb(40, 120, 230) },
		{ "Magic Eggs", "1/20 Golden", "Plus 1 in 100 Rainbow on every hatch", "1,799", rgb(200, 90, 255), rgb(110, 40, 180) },
		{ "Lucky Eggs", "Best of 2", "Extra luck. Stacks with Super Lucky!", "249", rgb(90, 220, 90), rgb(30, 150, 40) },
		{ "Super Lucky", "Best of 3", "Super luck. Stacks with Lucky Eggs!", "799", rgb(255, 230, 60), rgb(240, 180, 20) },
		{ "Secret Hunter", "+30% secret luck", "Better secret odds & 2x faster pity!", "1,999", rgb(150, 80, 200), rgb(50, 20, 100) },
	}
	for i, c in ipairs(cards) do
		local x = 0.4 + (i - 1) * 0.105
		local card = K.box(hatching, { name = c[1], x = x, y = 0.6, w = 0.1, h = 0.7, fill = c[6]:Lerp(rgb(0, 0, 0), 0.7), gradient = { c[5]:Lerp(rgb(0, 0, 0), 0.62), c[6]:Lerp(rgb(0, 0, 0), 0.85) }, corner = 0.08, stroke = 0.02, strokeColor = c[5] })
		K.icon(card, { icon = "icon_egg", y = 0.2, w = 0.5, aspect = 1 })
		K.text(card, { text = c[1], y = 0.4, w = 0.94, h = 0.1, size = 34 })
		local tag = K.box(card, { y = 0.51, w = 0.8, h = 0.08, fill = rgb(0, 0, 0), alpha = 0.55, corner = 0.5 })
		K.text(tag, { text = c[2], w = 0.9, h = 0.7, size = 24, outline = false, color = "yellow" })
		K.text(card, { text = c[3], y = 0.68, w = 0.92, h = 0.13, size = 22 })
		K.button(card, { text = c[4], icon = "icon_gem", color = "green", y = 0.86, w = 0.9, h = 0.11, size = 34 })
		K.text(card, { text = "or  " .. c[4], y = 0.96, w = 0.7, h = 0.06, size = 20 })
	end
	section(0.9, 0.3, "Pets", "0/4 owned", "Equip and store more pets")
	K.stagger(hatching, { step = 0.03 })
	return g
end

-- card-profile.png: profile header with chips, a TABLE frame, BEST HIT box, LIFETIME tiles, CUSTOMIZE tabs and cards,
-- and a wide Collection Log button (pixel theme).
S.Profile = function(K, parent)
	K.use("Pixel")
	local g, root = K.screen("Profile", parent)
	K.backdrop(root, rgb(22, 12, 40), rgb(8, 4, 20))
	local panel, content = K.modal(root, { title = "", color = "night", aspect = 1.45, w = 0.62 })
	local header = panel:FindFirstChild("Header")
	if header then
		header.Visible = false
	end
	K.icon(panel, { icon = "icon_paw", x = 0.07, y = 0.09, w = 0.06, aspect = 1 })
	K.text(panel, { text = "SATOCRY", x = 0.27, y = 0.085, w = 0.3, h = 0.09, size = 60, color = "yellow", left = false })
	local function chip(text, x, color)
		local c = K.box(panel, { x = x, y = 0.165, w = 0.1, h = 0.04, fill = color, corner = 0.3 })
		K.text(c, { text = text, w = 0.9, h = 0.6, size = 22, outline = false })
	end
	chip("#11 SERVER", 0.19, "panelLight")
	chip("IN THIS SERVER", 0.3, "greenDark")
	local seg = K.box(panel, { x = 0.86, y = 0.095, w = 0.12, h = 0.06, fill = "panelDark", corner = 0.2 })
	K.text(seg, { text = "VIEW", x = 0.26, w = 0.4, h = 0.5, size = 22, color = "gray", outline = false })
	K.box(seg, { x = 0.73, w = 0.48, h = 0.8, fill = "purple", corner = 0.2 })
	K.text(seg, { text = "EDIT", x = 0.73, w = 0.4, h = 0.5, size = 22, outline = false })

	K.text(content, { text = "TABLE", x = 0.03, y = 0.04, w = 0.1, h = 0.04, size = 22, left = true, color = "gray", outline = false })
	local table_ = K.box(content, { name = "Table", x = 0.33, y = 0.27, w = 0.64, h = 0.4, fill = "panelDark", corner = 0.03, stroke = 0.006, strokeColor = "purple" })
	K.box(table_, { name = "DeckBack", w = 0.18, h = 0.66, fill = rgb(20, 22, 44), corner = 0.06, stroke = 0.04, strokeColor = "purple" })
	K.icon(table_, { icon = "icon_egg", w = 0.14, aspect = 0.8 })
	K.text(content, { text = "BEST HIT", x = 0.77, y = 0.04, w = 0.12, h = 0.04, size = 22, left = true, color = "gray", outline = false })
	local best = K.box(content, { x = 0.86, y = 0.14, w = 0.3, h = 0.17, fill = "panelDark", corner = 0.04, stroke = 0.006, strokeColor = "purple" })
	K.text(best, { text = "NO BEST HIT YET", x = 0.06, y = 0.14, w = 0.9, h = 0.14, size = 22, left = true, color = "gray", outline = false })
	K.text(content, { text = "LIFETIME", x = 0.77, y = 0.35, w = 0.12, h = 0.04, size = 22, left = true, color = "gray", outline = false })
	local stats = { { "REBIRTHS", "0" }, { "MULTIPLIER", "x1" }, { "DRAWS", "0" }, { "COINS EARNED", "0" } }
	for i, c in ipairs(K.cells(2, 2, 0.04)) do
		local tile = K.box(content, { x = 0.71 + c.x * 0.3, y = 0.41 + c.y * 0.26, w = c.w * 0.3, h = c.h * 0.26, fill = "panelLight", alpha = 0.4, corner = 0.1 })
		K.text(tile, { text = stats[i][1], x = 0.08, y = 0.25, w = 0.9, h = 0.22, size = 18, left = true, color = "gray", outline = false })
		K.text(tile, { text = stats[i][2], x = 0.08, y = 0.68, w = 0.8, h = 0.34, size = 38, left = true, color = i == 4 and "yellow" or "text", outline = false })
	end
	K.text(content, { text = "CUSTOMIZE", x = 0.03, y = 0.685, w = 0.12, h = 0.04, size = 22, left = true, color = "gray", outline = false })
	local custom = K.box(content, { x = 0.5, y = 0.815, w = 1, h = 0.2, fill = "panelDark", corner = 0.03 })
	local tabs = { "BACKDROP", "SKIN", "BADGE", "PINS" }
	for i, t in ipairs(tabs) do
		local x = 0.07 + (i - 1) * 0.095
		if i == 1 then
			K.box(custom, { x = x, y = 0.17, w = 0.09, h = 0.18, fill = "purple", corner = 0.2 })
		end
		K.text(custom, { text = t, x = x, y = 0.17, w = 0.085, h = 0.12, size = 20, outline = false, color = i == 1 and "text" or "gray" })
	end
	local cards = { { "DIM", true }, { "REBIRTH REWARDS" }, { "SKINS SHOP" } }
	for i, c in ipairs(cards) do
		local card = K.box(custom, { x = 0.1 + (i - 1) * 0.165, y = 0.64, w = 0.155, h = 0.64, fill = "purple", alpha = 0.3, corner = 0.08, stroke = c[2] and 0.02 or nil, strokeColor = "green" })
		K.box(card, { y = 0.38, w = 0.92, h = 0.56, fill = "panelDark", corner = 0.06 })
		if i == 2 then K.icon(card, { icon = "icon_rebirth", y = 0.38, w = 0.3, aspect = 1 }) end
		if i == 3 then K.icon(card, { icon = "icon_shop", y = 0.38, w = 0.3, aspect = 1 }) end
		K.text(card, { text = c[1], x = 0.06, y = 0.88, w = 0.88, h = 0.12, size = 18, left = true, outline = false })
	end
	local log = K.button(content, { text = "COLLECTION LOG", color = "purple", y = 0.975, w = 1, h = 0.06, size = 28, name = "CollectionLogButton" })
	K.popIn(panel)
	return g
end

-- card-first-draw-tutorial.png: a single deck in the middle, a pulsing tap ring and a pointer, a small "NEXT" note on
-- the left, one ability square below the deck, and two buttons bottom-left (pixel theme).
S.FirstDraw = function(K, parent)
	K.use("Pixel")
	local g, root = K.screen("FirstDraw", parent)
	K.backdrop(root, rgb(46, 26, 90), rgb(14, 8, 34))
	local note = K.box(root, { name = "Next", x = 0.034, y = 0.6, w = 0.14, h = 0.07, anchor = LEFT, reason = "tutorial note pinned to the left edge", fill = "panelDark", alpha = 0.3, corner = 0.1 })
	K.box(note, { x = 0.02, w = 0.015, h = 0.8, fill = "yellow" })
	K.text(note, { text = "NEXT", x = 0.1, y = 0.2, w = 0.2, h = 0.22, size = 18, left = true, color = "yellow", outline = false })
	K.text(note, { text = "TAP THE EGG TO HATCH A PET.", x = 0.1, y = 0.62, w = 0.86, h = 0.5, size = 26, left = true, outline = false })
	local deck = K.box(root, { name = "Deck", x = 0.5, y = 0.5, w = 0.11, h = 0.3, fill = rgb(20, 22, 44), corner = 0.06, stroke = 0.04, strokeColor = "yellow" })
	K.box(deck, { y = 0.45, w = 0.82, h = 0.84, fill = rgb(26, 36, 90), corner = 0.04 })
	K.icon(deck, { icon = "icon_egg", y = 0.45, w = 0.5, aspect = 1 })
	local ring = K.box(root, { name = "TapRing", x = 0.532, y = 0.592, w = 0.065, aspect = 1, fill = rgb(255, 255, 255), alpha = 0.9, corner = "pill" })
	K.pulse(ring, { scale = 1.15, period = 0.8 })
	local pointer = K.text(root, { text = ">", x = 0.565, y = 0.65, w = 0.06, h = 0.1, size = 120, color = "orange", rotation = 0 })
	pointer.Rotation = -135
	local ability = K.box(root, { name = "Ability", x = 0.5, y = 0.85, w = 0.056, aspect = 1, fill = rgb(10, 40, 40), corner = 0.15, stroke = 0.05, strokeColor = rgb(80, 230, 200) })
	K.icon(ability, { icon = "icon_bolt", w = 0.7, aspect = 1 })
	K.button(root, { icon = "icon_index", color = "blue", x = 0.051, y = 0.74, w = 0.05, aspect = 1, name = "Book" })
	K.text(root, { text = "BOOK", x = 0.051, y = 0.805, w = 0.06, h = 0.03, size = 18, outline = false })
	K.button(root, { icon = "icon_gear", color = "gray", x = 0.051, y = 0.87, w = 0.05, aspect = 1, name = "Settings" })
	K.text(root, { text = "SETTINGS", x = 0.051, y = 0.935, w = 0.07, h = 0.03, size = 18, outline = false })
	return g
end

-- "Now Playing" popup, bottom right (the music card in the Sols RNG aura viewer, aura-view-*.png, shown as a popup):
-- a note bubble with equaliser bars, "NOW PLAYING", the track title, the artist and a thin progress bar. It slides in
-- when a track starts, holds for a few seconds, then slides out.
--   Live:  S.NowPlaying(K, PlayerGui, require(ReplicatedStorage.MusicFX))   (needs Music.TrackStarted and Music.getPlaying)
--   Mock:  S.NowPlaying(K, parent)  (no Music: stays on screen with a sample track, used by the validator and screenshots)
-- Credits come from MusicCatalog ("Artist - Title").
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

function S.splitCredit(credit)
	local artist, title = string.match(credit or "", "^(.-)%s+%-%s+(.+)$")
	return title or credit or "Unknown", artist or ""
end

S.NowPlaying = function(K, parent, Music)
	K.use("Candy")
	local g, root = K.screen("NowPlaying", parent)
	local live = Music ~= nil
	if not live then
		K.backdrop(root, rgb(30, 44, 70), rgb(12, 16, 30))
	end
	local HOME_X, AWAY_X = 0.995, 1.4
	local card = K.box(root, {
		name = "Card", x = live and AWAY_X or HOME_X, y = 0.83, w = 0.24, h = 0.1, anchor = Vector2.new(1, 0.5),
		reason = "popup pinned to the right screen edge", fill = "panelDark", alpha = 0.12, corner = 0.14,
		stroke = 0.02, strokeColor = "outline", z = 20,
	})
	local bubble = K.box(card, { name = "NoteBubble", x = 0.115, y = 0.46, h = 0.62, aspect = 1, fill = "purple", gradient = true, corner = "pill", stroke = "md" })
	K.text(bubble, { text = "♪", w = 0.8, h = 0.8, size = 60, outline = false })
	local bars = {}
	for i = 1, 3 do
		bars[i] = K.box(card, { name = "Eq" .. i, x = 0.235 + (i - 1) * 0.022, y = 0.46, w = 0.012, h = 0.3, fill = "yellow", corner = "pill" })
	end
	K.text(card, { text = "NOW PLAYING", x = 0.33, y = 0.2, w = 0.6, h = 0.17, size = 18, left = true, color = "yellow", outline = false, name = "Label" })
	local title = K.text(card, { text = "Shinsei", x = 0.33, y = 0.43, w = 0.64, h = 0.29, size = 34, left = true, name = "Title" })
	local artist = K.text(card, { text = "Gichco", x = 0.33, y = 0.67, w = 0.64, h = 0.18, size = 22, left = true, color = "gray", outline = false, name = "Artist" })
	-- own progress bar (K.bar with sprites returns no fill at value 0, and this fill is resized every frame)
	local track = K.box(card, { name = "Progress", x = 0.5, y = 0.92, w = 0.92, h = 0.07, fill = "panelDark", corner = "pill", clip = true })
	local fill = K.box(track, {
		name = "Fill", x = 0, y = 0.5, w = live and 0.001 or 0.35, h = 1, anchor = Vector2.new(0, 0.5),
		reason = "progress fill grows from the left", fill = "yellow", gradient = true, corner = "pill",
	})

	local token = 0
	local function setX(x, time)
		local reduced = K.Motion and K.Motion.reduced
		if reduced or time <= 0 then
			card.Position = UDim2.fromScale(x, 0.83)
		else
			TweenService:Create(card, TweenInfo.new(time, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(x, 0.83) }):Play()
		end
	end
	local function show(name)
		local entry = Music and Music.catalog and Music.catalog[name]
		local t, a = S.splitCredit(entry and entry.credit or name)
		title.Text, artist.Text = t, a ~= "" and ("by " .. a) or ""
		token += 1
		local mine = token
		setX(HOME_X, 0.5)
		task.delay(7, function()
			if mine == token and card.Parent then
				TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(AWAY_X, 0.83) }):Play()
			end
		end)
	end
	if live and RunService:IsStudio() then
		-- Studio-only test hook: game.ReplicatedStorage.DebugNowPlaying:Fire("shinsei") replays the popup
		local ev = game:GetService("ReplicatedStorage"):FindFirstChild("DebugNowPlaying") or Instance.new("BindableEvent")
		ev.Name = "DebugNowPlaying"
		ev.Parent = game:GetService("ReplicatedStorage")
		ev.Event:Connect(show)
	end
	if live then
		local conn = Music.TrackStarted.Event:Connect(show)
		g.Destroying:Connect(function() conn:Disconnect() end)
		local current = Music.getPlaying()
		if current then
			show(current)
		end
	end
	local hb = RunService.Heartbeat:Connect(function()
		local t = os.clock()
		if not (K.Motion and K.Motion.reduced) then
			for i, b in ipairs(bars) do
				b.Size = UDim2.fromScale(0.012, 0.12 + 0.28 * (0.5 + 0.5 * math.sin(t * (4 + i * 1.7) + i)))
			end
		end
		if live then
			local _, snd = Music.getPlaying()
			if snd and snd.TimeLength > 0 then
				fill.Size = UDim2.fromScale(math.clamp(snd.TimePosition / snd.TimeLength, 0.001, 1), 1)
			end
		end
	end)
	g.Destroying:Connect(function() hb:Disconnect() end)
	return g
end

-- pet-hud-unlock-toast-chevrons.png: unlock banner and "NEXT UP" card at the top, left nav, a sign, a row of ground
-- chevrons, a glowing egg, a big tap button with a count, locked buttons on the right, an offline-rewards line.
S.UnlockToast = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("UnlockToast", parent)
	K.backdrop(root, rgb(90, 190, 255), rgb(110, 210, 70))
	local ban = K.box(root, { name = "UnlockBanner", x = 0.5, y = 0.052, w = 0.28, h = 0.085, fill = rgb(0, 0, 0), alpha = 0.35, corner = "pill" })
	K.text(ban, { text = "2 NEW EGGS UNLOCKED!", x = 0.56, y = 0.3, w = 0.78, h = 0.46, size = 54, color = "yellow" })
	K.icon(ban, { icon = "icon_egg", x = 0.1, y = 0.4, w = 0.1, aspect = 1 })
	K.text(ban, { text = "200K", x = 0.1, y = 0.82, w = 0.14, h = 0.26, size = 30, color = "yellow" })
	K.text(ban, { text = "You can afford the Spiked Egg!", x = 0.56, y = 0.74, w = 0.78, h = 0.3, size = 34 })
	local nxt = K.box(root, { name = "NextUp", x = 0.5, y = 0.16, w = 0.27, h = 0.092, fill = rgb(10, 13, 28), corner = 0.2, stroke = 0.02, strokeColor = "blue" })
	K.icon(nxt, { icon = "icon_paw", x = 0.1, w = 0.14, aspect = 1 })
	K.text(nxt, { text = "NEXT UP!", x = 0.36, y = 0.2, w = 0.3, h = 0.24, size = 34, color = "orange" })
	K.text(nxt, { text = "Make a Golden pet!", x = 0.58, y = 0.5, w = 0.8, h = 0.34, size = 50, color = "blue" })
	K.text(nxt, { text = "Use the Golden Machine!", x = 0.58, y = 0.8, w = 0.7, h = 0.2, size = 26, color = "gray", outline = false })
	K.nav(root, { y = 0.5, w = 0.075, h = 0.26, items = { { text = "Shop", icon = "icon_shop", color = "blue" }, { text = "Trade", icon = "icon_trade", color = "blue" } } })
	K.text(root, { text = "Tap to earn!", x = 0.3, y = 0.52, w = 0.24, h = 0.14, size = 90, color = "yellow" })
	K.chevrons(root, { x = 0.3, y = 0.665, w = 0.36, h = 0.14, count = 5, dir = "right" }) -- points at the egg
	K.box(root, { name = "Glow", x = 0.5, y = 0.42, w = 0.16, aspect = 0.8, fill = rgb(70, 46, 150), alpha = 0.5, corner = "pill", stroke = 0.01, strokeColor = "purple" })
	K.icon(root, { icon = "icon_egg", x = 0.5, y = 0.42, w = 0.14, aspect = 0.8 })
	K.text(root, { text = "+270,000 Coins from Offline Rewards!", x = 0.5, y = 0.78, w = 0.4, h = 0.04, size = 40 })
	K.text(root, { text = "+6", x = 0.5, y = 0.82, w = 0.05, h = 0.05, size = 60 })
	local tap = K.button(root, { text = "TAP", color = "blue", x = 0.5, y = 0.92, w = 0.1, h = 0.12, size = 56, name = "Tap" })
	K.pulse(tap, { scale = 1.05, period = 0.6 })
	K.pill(root, { icon = "icon_rebirth", value = "0 Rebirths", color = "green", x = 0.012, y = 0.8, w = 0.17, h = 0.065, anchor = LEFT, reason = "HUD pinned to the left screen edge" })
	K.pill(root, { icon = "icon_coin", value = "270,182", color = "coin", x = 0.012, y = 0.88, w = 0.17, h = 0.065, anchor = LEFT, reason = "HUD pinned to the left screen edge" })
	K.pill(root, { icon = "icon_gem", value = "0", color = "blue", x = 0.012, y = 0.96, w = 0.17, h = 0.065, anchor = LEFT, reason = "HUD pinned to the left screen edge" })
	for i = 1, 3 do
		K.button(root, { icon = "icon_lock", color = "gray", x = 0.975, y = 0.48 + (i - 1) * 0.12, w = 0.045, h = 0.08, aspect = 1, size = 30, name = "Locked" .. i })
	end
	return g
end

-- fruit-inventory-equip-best.png (pixel theme): tutorial line, nav tiles on the left, an inventory modal with an equipped
-- row, an item grid, search, Sort and Equip Best buttons, "new discovery" toasts on the right.
S.EquipBest = function(K, parent)
	K.use("Pixel")
	local g, root = K.screen("EquipBest", parent)
	K.backdrop(root, rgb(58, 42, 34), rgb(20, 12, 10))
	K.text(root, { text = "TUTORIAL - 11/11", x = 0.5, y = 0.115, w = 0.3, h = 0.035, size = 40 })
	K.text(root, { text = "Tap your Cucumber!", x = 0.5, y = 0.17, w = 0.4, h = 0.05, size = 54 })
	K.nav(root, { y = 0.5, w = 0.1, h = 0.55, items = {
		{ text = "SHOP", icon = "icon_shop", color = "orange" }, { text = "REBIRTH", icon = "icon_rebirth", color = "blue" },
		{ text = "UPGRADE", icon = "icon_arrow_up", color = "green", badge = "1" }, { text = "INDEX", icon = "icon_index", color = "green" },
		{ text = "PETS", icon = "icon_paw", color = "purple" },
	} })
	local panel, content = K.modal(root, { title = "PETS    2/1000", color = "orange", aspect = 1.75, w = 0.5 })
	K.text(content, { text = "1/2 EQUIPPED - 4/6 SEC.", y = 0.07, w = 0.5, h = 0.07, size = 28, color = "text", outline = false })
	for i = 1, 2 do
		local slot = K.box(content, { x = 0.12 + (i - 1) * 0.18, y = 0.25, w = 0.14, h = 0.2, fill = "panelDark", corner = 0.1, stroke = 0.01, strokeColor = "panelLight" })
		if i == 1 then
			K.icon(slot, { icon = "icon_paw", w = 0.7, aspect = 1 })
		end
	end
	local grid = K.box(content, { name = "Grid", y = 0.66, w = 1, h = 0.46 })
	for i, c in ipairs(K.cells(8, 2, 0.02)) do
		local cell = K.box(grid, { x = c.x, y = c.y, w = c.w, h = c.h, fill = "panelDark", alpha = i == 1 and 0.1 or 0.5, corner = 0.1 })
		if i == 1 then
			K.icon(cell, { icon = "icon_dragon", w = 0.8, aspect = 1 })
			K.text(cell, { text = "x1", x = 0.7, y = 0.85, w = 0.5, h = 0.25, size = 24, outline = false })
		end
	end
	local search = K.box(content, { name = "Search", x = 0.14, y = 0.97, w = 0.28, h = 0.085, fill = "panelDark", corner = 0.15 })
	K.text(search, { text = "SEARCH...", x = 0.1, w = 0.8, h = 0.5, size = 22, left = true, color = "gray", outline = false })
	K.button(content, { text = "SORT: VALUE", color = "purple", x = 0.62, y = 0.97, w = 0.2, h = 0.085, size = 24, name = "Sort" })
	K.button(content, { text = "EQUIP BEST", color = "green", x = 0.87, y = 0.97, w = 0.22, h = 0.085, size = 26, name = "EquipBest" })
	K.toast(root, { icon = "icon_dragon", title = "Star Drake!", text = "You've discovered this... for the first time!", tag = "New!", x = 0.88, y = 0.24, w = 0.22, h = 0.095, anchor = Vector2.new(0.5, 0.5), reason = "toast stack on the right" })
	K.toast(root, { icon = "icon_crystal", title = "Frostling!", text = "You've discovered this... for the first time!", tag = "New!", x = 0.88, y = 0.35, w = 0.22, h = 0.095, anchor = Vector2.new(0.5, 0.5), reason = "toast stack on the right" })
	K.popIn(panel)
	return g
end

-- egg-free-reward-popup.png: lime-headed popup with a reward picture, "LIMITED TIME!" and the reward text, three task tiles
-- with red arrows and a big Claim button. Tasks here are in-game ones (the reference asks for likes and favourites;
-- rewarding those may break Roblox rules, which I have not verified, so we do not copy that part).
S.FreeReward = function(K, parent)
	K.use("Candy")
	local g, root = K.screen("FreeReward", parent)
	K.backdrop(root, rgb(90, 180, 255), rgb(110, 210, 70))
	local panel, content = K.modal(root, { title = "Free Reward!", color = "green", aspect = 1.55, w = 0.64 })
	K.box(content, { name = "Rays", x = 0.5, y = 0.28, w = 1, h = 0.5, fill = rgb(0, 0, 0), alpha = 0.78, corner = 0.03 })
	K.icon(content, { icon = "icon_gift", x = 0.2, y = 0.28, w = 0.22, aspect = 1 })
	K.text(content, { text = "LIMITED TIME!", x = 0.67, y = 0.16, w = 0.56, h = 0.15, size = 80, color = "red" })
	K.text(content, { text = "+10 Gems", x = 0.67, y = 0.36, w = 0.5, h = 0.15, size = 80, color = "blue" })
	local tiles = { { "Invite a Friend", "icon_heart" }, { "Play 5 Minutes", "icon_stopwatch" }, { "Open a Crate", "icon_chest" } }
	for i, t in ipairs(tiles) do
		local x = 0.1 + (i - 1) * 0.3
		local tile = K.box(content, { name = "Task" .. i, x = x + 0.1, y = 0.7, w = 0.27, h = 0.22, fill = "panelDark", corner = 0.08 })
		K.icon(tile, { icon = t[2], y = 0.4, w = 0.4, aspect = 1 })
		K.text(content, { text = t[1], x = x + 0.1, y = 0.84, w = 0.29, h = 0.065, size = 36 })
		K.text(content, { text = "v", x = x + 0.17, y = 0.565, w = 0.05, h = 0.08, size = 70, color = "red" })
	end
	local claim = K.button(content, { text = "Claim!", color = "green", y = 0.965, w = 0.5, h = 0.12, size = 80, name = "Claim" })
	K.pulse(claim, { scale = 1.05, period = 0.7 })
	K.popIn(panel)
	return g
end

return S
