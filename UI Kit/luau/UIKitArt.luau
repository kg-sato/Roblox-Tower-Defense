--!nocheck
-- UIKitArt: upgrades UIKit components from flat frames to real artwork (sprites listed in UIArt).
-- Every override checks that its sprites exist and otherwise calls the original frame-based component,
-- so nothing breaks before art exists (or on a machine without the local preview files).
-- Scale-only rules still hold: 9-slice sprites set SliceScale from the on-screen size at runtime, which is not
-- a UI Offset. Sprites come from UI Kit/art (make_chrome.py, Blender renders, Kimi images).

return function(K, UIArt)
	K.Art = UIArt

	-- emoji used in older screens -> sprite icon (so they upgrade automatically where a sprite exists)
	K.iconForEmoji = {
		["💰"] = "icon_coin", ["💵"] = "icon_coin", ["💎"] = "icon_gem", ["⭐"] = "icon_star", ["🌟"] = "icon_star",
		["❤️"] = "icon_heart", ["⚡"] = "icon_bolt", ["⬆️"] = "icon_arrow_up", ["✅"] = "icon_check",
		["👑"] = "icon_crown", ["🔒"] = "icon_lock", ["➕"] = "icon_plus",
		["🔄"] = "icon_rebirth", ["🔁"] = "icon_trade", ["🛒"] = "icon_shop", ["📖"] = "icon_index", ["🥚"] = "icon_egg", ["🐾"] = "icon_paw", ["🎁"] = "icon_gift",
		["⚙️"] = "icon_gear", ["🍎"] = "icon_apple", ["🍬"] = "icon_candy", ["🧄"] = "icon_garlic", ["⛏️"] = "icon_pickaxe", ["⏱"] = "icon_stopwatch", ["🏆"] = "icon_trophy", ["🔑"] = "icon_key", ["🧪"] = "icon_potion", ["🐉"] = "icon_paw",
	}

	-- accepts a sprite name or an emoji; returns a sprite name that can be shown, or nil
	local function spriteFor(icon)
		if not icon then
			return nil
		end
		if UIArt.has(icon) then
			return icon
		end
		local mapped = K.iconForEmoji[icon]
		if mapped and UIArt.has(mapped) then
			return mapped
		end
		return nil
	end
	K.spriteFor = spriteFor

	---------------------------------------------------------------------------------------------
	-- sprite and icon
	---------------------------------------------------------------------------------------------

	-- o: sprite (name), class ("ImageLabel" | "ImageButton"), x, y, w, h, anchor, reason, z, aspect, tint (colour token),
	--    alpha (image transparency), fit ("stretch" to disable 9-slice), rotation
	function K.sprite(parent, o)
		local s = assert(UIArt.sprites[o.sprite], "unknown sprite " .. tostring(o.sprite))
		local img = K.box(parent, {
			class = o.class or "ImageLabel", name = o.name or o.sprite, x = o.x, y = o.y, w = o.w, h = o.h,
			anchor = o.anchor, reason = o.reason, z = o.z, aspect = o.aspect, rotation = o.rotation,
		})
		img.Image = UIArt.image(o.sprite)
		img.ScaleType = Enum.ScaleType.Stretch
		if s.slice and o.fit ~= "stretch" then
			img.ScaleType = Enum.ScaleType.Slice
			img.SliceCenter = Rect.new(s.slice[1], s.slice[2], s.w - s.slice[3], s.h - s.slice[4])
			local function update()
				local a = img.AbsoluteSize
				if a.X > 0 and a.Y > 0 then
					img.SliceScale = math.clamp(math.min(a.X / s.w, a.Y / s.h), 0.02, s.cap or 4)
				end
			end
			update()
			img:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		end
		if o.tint then
			img.ImageColor3 = K.col(o.tint)
		end
		if o.alpha then
			img.ImageTransparency = o.alpha
		end
		return img
	end

	-- o: icon (sprite name or emoji), x, y, w, aspect (default 1), h (emoji fallback only), size (emoji max px)
	function K.icon(parent, o)
		local sp = spriteFor(o.icon)
		if sp then
			local img = K.sprite(parent, { sprite = sp, name = o.name or "Icon", x = o.x, y = o.y, w = o.w or 0.5, h = o.h or 0.5, aspect = o.aspect or 1, z = o.z, anchor = o.anchor, reason = o.reason })
			if o.byHeight then
				-- size from the parent's height so the icon fills a button of any width
				local ar = img:FindFirstChildOfClass("UIAspectRatioConstraint")
				if ar then
					ar.DominantAxis = Enum.DominantAxis.Height
				end
			end
			return img
		end
		return K.text(parent, { text = o.icon or "?", name = o.name or "Icon", x = o.x, y = o.y, w = o.w or 0.5, h = o.h or 0.62, size = o.size or 44, outline = false, z = o.z })
	end

	---------------------------------------------------------------------------------------------
	-- buttons, badges, pills
	---------------------------------------------------------------------------------------------

	local origButton = K.button
	function K.button(parent, o)
		local pill = o.corner == "pill"
		local sname = (pill and "pill_btn_" or "btn_") .. tostring(o.color or "green")
		if type(o.color) ~= "string" or not UIArt.has(sname) then
			return origButton(parent, o)
		end
		local b = K.sprite(parent, {
			sprite = sname, class = "ImageButton", name = o.name or ("Button_" .. tostring(o.text or o.icon or "")),
			x = o.x, y = o.y, w = o.w or 0.3, h = o.h or 0.12, anchor = o.anchor, reason = o.reason, z = o.z, aspect = o.aspect,
		})
		b.AutoButtonColor = false
		local ty = 0.45 -- centre of the lit face (the sprite has a darker lip along the bottom)
		if o.icon and o.text then
			K.icon(b, { icon = o.icon, x = 0.16, y = ty, h = 0.64, aspect = 1, size = 40, byHeight = true })
			K.text(b, { text = o.text, x = 0.6, y = ty, w = 0.52, h = 0.5, size = o.size or 34, name = "Label" })
		elseif o.icon then
			K.icon(b, { icon = o.icon, x = 0.5, y = ty, h = 0.8, aspect = 1, size = 44, byHeight = true })
		elseif o.text then
			K.text(b, { text = o.text, y = ty, w = 0.84, h = 0.5, size = o.size or 36, name = "Label" })
		end
		if o.badge then
			K.badge(b, { text = o.badge, x = 0.97, y = 0.0 })
		end
		K.pressFx(b)
		if o.onClick then
			b.Activated:Connect(o.onClick)
		end
		return b
	end


	local origToast = K.toast
	function K.toast(parent, o)
		if not UIArt.has("panel_dark") then
			return origToast(parent, o)
		end
		local t = K.sprite(parent, { sprite = "panel_dark", name = "Toast", x = o.x, y = o.y, w = o.w or 0.22, h = o.h or 0.1, anchor = o.anchor, reason = o.reason, alpha = 0.12 })
		K.icon(t, { icon = o.icon or "icon_star", x = 0.12, w = 0.2, h = 0.8, aspect = 1, size = 44 })
		K.text(t, { text = o.title, x = 0.36, y = 0.32, w = 0.6, h = 0.36, size = 32, left = true })
		K.text(t, { text = o.text or "", x = 0.36, y = 0.7, w = 0.6, h = 0.26, size = 18, left = true, color = "gray", outline = false })
		if o.tag then
			K.text(t, { text = o.tag, x = 0.06, y = 0.0, w = 0.22, h = 0.2, size = 22, color = "yellow", outline = true })
		end
		return t
	end

	local origBadge = K.badge
	function K.badge(parent, o)
		if not UIArt.has("badge_red") then
			return origBadge(parent, o)
		end
		local b = K.sprite(parent, { sprite = "badge_red", name = "Badge", x = o.x or 0.9, y = o.y or 0.1, w = o.w or 0.34, aspect = 1, z = 5 })
		K.text(b, { text = o.text, w = 0.62, h = 0.62, size = 24, outline = false })
		if K.pulse then
			K.pulse(b, { scale = 1.12, period = 0.7 })
		end
		return b
	end

	local origPill = K.pill
	function K.pill(parent, o)
		if not UIArt.has("pill_dark") then
			return origPill(parent, o)
		end
		local p = K.sprite(parent, {
			sprite = "pill_dark", name = o.name or "Pill", x = o.x, y = o.y, w = o.w or 0.3, h = o.h or 0.08,
			anchor = o.anchor, reason = o.reason,
		})
		-- the icon overlaps the left end of the capsule, like the reference games
		K.icon(p, { icon = o.sprite or o.icon or "", x = 0.1, y = 0.5, h = 1.15, aspect = 1, size = 36, z = 3, byHeight = true })
		K.text(p, { text = tostring(o.value), x = o.plus and 0.52 or 0.6, w = o.plus and 0.4 or 0.6, h = 0.62, size = 40, color = o.valueColor or "text", name = "Value" })
		if o.plus then
			K.button(p, { text = "+", color = "green", corner = "pill", x = 0.9, w = 0.17, h = 0.8, aspect = 1, size = 40, name = "Plus" })
		end
		return p
	end

	---------------------------------------------------------------------------------------------
	-- modal, bars, tabs, cards
	---------------------------------------------------------------------------------------------

	local origModal = K.modal
	function K.modal(root, o)
		local hcolor = o.color or K.T.headerColor or "green"
		local hname = "header_" .. tostring(hcolor)
		if type(hcolor) ~= "string" or not (UIArt.has("panel_dark") and UIArt.has(hname) and UIArt.has("close_x")) then
			return origModal(root, o)
		end
		local dim = K.dim(root, 0.5)
		local panel = K.sprite(dim, { sprite = "panel_dark", name = "Panel", w = o.w or 0.62, h = 0.9, aspect = o.aspect or 1.7, z = 11 })
		local header = K.sprite(panel, { sprite = hname, name = "Header", y = 0.085, w = 1, h = 0.17, z = 12 })
		K.text(header, { text = o.title, x = 0.035, y = 0.46, w = 0.7, h = 0.66, size = 72, left = true, font = K.T.titleFont, name = "Title" })
		local close = K.sprite(panel, { sprite = "close_x", class = "ImageButton", name = "Close", x = 0.985, y = 0, w = 0.09, aspect = 1, z = 20 })
		close.AutoButtonColor = false
		K.pressFx(close)
		close.Activated:Connect(function()
			dim:Destroy()
			if o.onClose then
				o.onClose()
			end
		end)
		local content = K.box(panel, { name = "Content", y = 0.6, w = 0.94, h = 0.76, z = 12 })
		return panel, content, dim
	end

	local origBar = K.bar
	function K.bar(parent, o)
		local fillName = "bar_fill_" .. tostring(o.color or "green")
		if type(o.color or "green") ~= "string" or not (UIArt.has("bar_track") and UIArt.has(fillName)) then
			return origBar(parent, o)
		end
		local track = K.sprite(parent, { sprite = "bar_track", name = o.name or "Bar", x = o.x, y = o.y, w = o.w or 0.8, h = o.h or 0.08, anchor = o.anchor, reason = o.reason })
		local v = math.clamp(o.value or 0, 0, 1)
		local fill
		if v > 0 then
			fill = K.sprite(track, {
				sprite = fillName, name = "Fill", x = 0.014, y = 0.5, w = math.max(0.12, 0.972 * v), h = 0.86,
				anchor = Vector2.new(0, 0.5), reason = "progress fill grows from the left", z = 2,
			})
		end
		local label
		if o.text then
			label = K.text(track, { text = o.text, w = 0.9, h = 0.7, size = o.size or 34, z = 4 })
		end
		return track, fill, label
	end

	local origTabs = K.tabs
	function K.tabs(parent, o)
		local onName = "btn_" .. tostring(o.color or "blue")
		if not (UIArt.has(onName) and UIArt.has("btn_gray")) then
			return origTabs(parent, o)
		end
		local strip = K.box(parent, { name = "Tabs", x = o.x, y = o.y, w = o.w or 0.9, h = o.h or 0.1, anchor = o.anchor, reason = o.reason })
		local n = #o.tabs
		local buttons = {}
		local current = o.value or 1
		local function paint()
			for i, b in ipairs(buttons) do
				local on = i == current
				b.Image = UIArt.image(on and onName or "btn_gray")
				b.Label.TextColor3 = on and K.col("text") or K.col("gray")
			end
		end
		for i, name in ipairs(o.tabs) do
			local b = K.sprite(strip, { sprite = "btn_gray", class = "ImageButton", name = "Tab" .. i, x = (i - 0.5) / n, w = 0.96 / n, h = 1 })
			b.AutoButtonColor = false
			K.text(b, { text = name, y = 0.45, w = 0.86, h = 0.5, size = 32, name = "Label" })
			b.Activated:Connect(function()
				current = i
				paint()
				if o.onChange then
					o.onChange(i, name)
				end
			end)
			buttons[i] = b
		end
		paint()
		return strip
	end

	local origCard = K.card
	function K.card(parent, o)
		local cname = "card_" .. tostring(o.color or "blue")
		if type(o.color or "blue") ~= "string" or not UIArt.has(cname) then
			return origCard(parent, o)
		end
		local accent = o.color or "blue"
		local c = K.sprite(parent, { sprite = cname, name = o.name or "Card", x = o.x, y = o.y, w = o.w or 0.3, h = o.h or 0.8 })
		if UIArt.has("glow_soft") then
			K.sprite(c, { sprite = "glow_soft", name = "Glow", y = 0.44, w = 0.95, h = 0.55, tint = accent, alpha = 0.15, z = 1 })
		end
		K.text(c, { text = o.title, y = 0.115, w = 0.78, h = 0.11, size = 34, name = "Title" })
		K.icon(c, { icon = o.sprite or o.icon or "?", y = 0.45, w = 0.62, h = 0.4, aspect = 1, size = 130, name = "Icon" })
		if o.note then
			K.text(c, { text = o.note, y = 0.73, w = 0.78, h = 0.065, size = 24, color = "yellow", outline = false, name = "Note" })
		end
		if o.tag and UIArt.has("pill_btn_red") then
			local t = K.sprite(c, { sprite = "pill_btn_" .. tostring(o.tagColor or "red"), name = "Tag", x = 0.24, y = 0.0, w = 0.4, h = 0.085, z = 6 })
			K.text(t, { text = o.tag, y = 0.45, w = 0.84, h = 0.5, size = 24, outline = false })
		end
		local kind = o.kind or "robux"
		local btnColor = kind == "robux" and "green" or (kind == "free" and "green" or (kind == "gem" and "blue" or "yellow"))
		local symbol = kind == "robux" and "R$ " or ""
		local buy = K.button(c, { text = symbol .. tostring(o.price or "Free"), icon = (kind == "gem" and "icon_gem") or (kind == "coin" and "icon_coin") or nil, color = btnColor, y = 0.885, w = 0.76, h = 0.15, size = 40, onClick = o.onClick, name = "Buy" })
		return c
	end
end
