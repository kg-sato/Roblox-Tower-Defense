--!nocheck
-- FrameArt: paints UI art at runtime with EditableImage (no uploads). Installed as ReplicatedStorage.FrameArt.
-- Soft-edged glass panels (9-slice), glowing capsule buttons, emblems, tapered dividers, glow and vignette sprites.
-- Live games need Experience Settings > Security > "Allow Mesh / Image APIs" (owner must be 13+ and ID verified);
-- if creation fails, FrameArt.ok is false and callers keep the old frame style.
-- Research: [[Research/UI Methods and Magic Effects]].

local AssetService = game:GetService("AssetService")

local FA = { cache = {} }

local function clamp01(x)
	return x < 0 and 0 or (x > 1 and 1 or x)
end
local function smooth(a, b, x)
	local t = clamp01((x - a) / (b - a))
	return t * t * (3 - 2 * t)
end
local function lerp(a, b, t)
	return a + (b - a) * t
end
-- signed distance to a rounded rectangle centred at (cx, cy); negative inside
local function rrect(px, py, cx, cy, hw, hh, r)
	local qx = math.abs(px - cx) - hw + r
	local qy = math.abs(py - cy) - hh + r
	return math.min(math.max(qx, qy), 0) + math.sqrt(math.max(qx, 0) ^ 2 + math.max(qy, 0) ^ 2) - r
end
local function hash(x, y)
	local n = math.sin(x * 12.9898 + y * 78.233) * 43758.5453
	return n - math.floor(n)
end

-- fn(x, y) -> r, g, b, a in 0..1 (straight alpha)
local function paint(key, w, h, fn)
	if FA.cache[key] then
		return FA.cache[key]
	end
	local img = AssetService:CreateEditableImage({ Size = Vector2.new(w, h) })
	local buf = buffer.create(w * h * 4)
	local i = 0
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local r, g, b, a = fn(x + 0.5, y + 0.5)
			buffer.writeu8(buf, i, math.floor(clamp01(r) * 255 + 0.5))
			buffer.writeu8(buf, i + 1, math.floor(clamp01(g) * 255 + 0.5))
			buffer.writeu8(buf, i + 2, math.floor(clamp01(b) * 255 + 0.5))
			buffer.writeu8(buf, i + 3, math.floor(clamp01(a) * 255 + 0.5))
			i += 4
		end
	end
	img:WritePixelsBuffer(Vector2.zero, Vector2.new(w, h), buf)
	local c = Content.fromObject(img)
	FA.cache[key] = c
	return c
end

local function ckey(c)
	return string.format("%d_%d_%d", c.R * 255, c.G * 255, c.B * 255)
end

-- Glass panel: dark, translucent, edges feather out (no border line), faint inner rim, top glow, film grain.
-- Returns content, sliceCenter, feather. Size the ImageLabel to the frame + 2*feather so the solid body matches the frame.
function FA.panel(accent, feather, radius, alpha)
	feather, radius, alpha = feather or 48, radius or 28, alpha or 0.9
	local S = 2 * (feather + radius) + 32
	local key = "panel" .. ckey(accent) .. feather .. "_" .. radius .. "_" .. alpha
	local ar, ag, ab = accent.R, accent.G, accent.B
	local c = paint(key, S, S, function(x, y)
		local d = rrect(x, y, S / 2, S / 2, S / 2 - feather, S / 2 - feather, radius)
		local t = y / S
		local r = lerp(16, 4, t) / 255
		local g = lerp(12, 4, t) / 255
		local b = lerp(26, 9, t) / 255
		r, g, b = lerp(r, ar * 0.35, 0.08), lerp(g, ag * 0.35, 0.08), lerp(b, ab * 0.35, 0.08)
		local top = (1 - t) ^ 3 * 0.06
		r, g, b = r + ar * top, g + ag * top, b + ab * top
		local n = (hash(x, y) - 0.5) * 0.02
		r, g, b = r + n, g + n, b + n
		local a = alpha * (1 - smooth(-feather * 0.2, feather * 0.85, d))
		-- faint inner rim a few px inside the body edge, top only (a full rim reads as a box outline)
		local rim = (1 - smooth(0, 1.6, math.abs(d + 7))) * 0.12 * (1 - t) ^ 3
		r, g, b = lerp(r, lerp(ar, 1, 0.4), rim), lerp(g, lerp(ag, 1, 0.4), rim), lerp(b, lerp(ab, 1, 0.4), rim)
		a = math.max(a, rim * alpha)
		return r, g, b, a
	end)
	local e = feather + radius + 2
	return c, Rect.new(e, e, S - e, S - e), feather
end

-- Capsule button: dark accent body, glossy top sheen, bright rim (brighter on top), soft outer glow.
-- bright = true for fills (health bars): the body glows in the accent instead of being a dark tint
function FA.button(accent, bright)
	local W, H, F, R = 96, 64, 12, 18
	local ar, ag, ab = accent.R, accent.G, accent.B
	local c = paint("btn" .. ckey(accent) .. (bright and "b" or ""), W, H, function(x, y)
		local d = rrect(x, y, W / 2, H / 2, W / 2 - F, H / 2 - F, R)
		local t = clamp01((y - F) / (H - 2 * F))
		local k = bright and lerp(1.0, 0.62, t) or lerp(0.42, 0.16, t)
		local r, g, b = ar * k, ag * k, ab * k
		-- glossy sheen on the upper half
		local sheen = (1 - smooth(0.0, 0.5, t)) * 0.12
		r, g, b = r + sheen, g + sheen, b + sheen
		local inside = 1 - smooth(-0.8, 0.8, d)
		local rimW = 1 - smooth(1.2, 2.6, math.abs(d + 1.4))
		local rimK = lerp(1.0, 0.55, t)
		r, g, b = lerp(r, lerp(ar, 1, 0.35), rimW * rimK), lerp(g, lerp(ag, 1, 0.35), rimW * rimK), lerp(b, lerp(ab, 1, 0.35), rimW * rimK)
		local a = inside * 0.96
		if d > 0 then
			local glow = (1 - smooth(0, F, d)) ^ 2 * 0.45
			if glow > a then
				return ar, ag, ab, glow
			end
		end
		return r, g, b, a
	end)
	local e = F + R + 1
	return c, Rect.new(e, e, W - e, H - e), F
end

-- Round emblem: radial body, double ring with four diamond ticks, outer glow.
function FA.emblem(accent)
	local S = 192
	local ar, ag, ab = accent.R, accent.G, accent.B
	return paint("emb" .. ckey(accent), S, S, function(x, y)
		local dx, dy = x - S / 2, y - S / 2
		local r = math.sqrt(dx * dx + dy * dy)
		local col, a = { 0, 0, 0 }, 0
		if r < 64 then
			local k = lerp(0.62, 0.18, (r / 64) ^ 1.4)
			col = { ar * k + 0.03, ag * k + 0.02, ab * k + 0.05 }
			a = 1 - smooth(62.5, 64, r)
		end
		local ring1 = 1 - smooth(1.6, 3.2, math.abs(r - 68))
		local ring2 = (1 - smooth(0.4, 1.4, math.abs(r - 80))) * 0.7
		-- diamond ticks at N, E, S, W on the outer ring
		local tick = 0
		for _, p in { { 0, -80 }, { 80, 0 }, { 0, 80 }, { -80, 0 } } do
			local md = math.abs(dx - p[1]) + math.abs(dy - p[2])
			tick = math.max(tick, 1 - smooth(6, 7.5, md))
		end
		local line = math.max(ring1, ring2, tick)
		if line > 0 then
			local lc = { lerp(ar, 1, 0.45), lerp(ag, 1, 0.45), lerp(ab, 1, 0.45) }
			col = { lerp(col[1], lc[1], line), lerp(col[2], lc[2], line), lerp(col[3], lc[3], line) }
			a = math.max(a, line)
		end
		if r > 64 then
			local glow = (1 - smooth(66, 96, r)) ^ 2 * 0.5
			if glow > a then
				return ar, ag, ab, glow
			end
		end
		return col[1], col[2], col[3], a
	end)
end

-- Tapered divider with a soft glow; white, tint with ImageColor3.
function FA.divider()
	local W, H = 512, 16
	return paint("div", W, H, function(x, y)
		local u = math.abs(2 * x / W - 1)
		local taper = (1 - u ^ 1.8)
		local dy = math.abs(y - H / 2)
		local core = 1 - smooth(0.3, 1.3, dy)
		local glow = (1 - smooth(0, H / 2, dy)) ^ 2 * 0.35
		return 1, 1, 1, math.max(core, glow) * taper
	end)
end

-- Soft round glow; white, tint with ImageColor3.
function FA.glow()
	local S = 128
	return paint("glow", S, S, function(x, y)
		local r = math.sqrt((x - S / 2) ^ 2 + (y - S / 2) ^ 2) / (S / 2)
		return 1, 1, 1, clamp01(1 - r) ^ 2.2
	end)
end

-- Screen vignette: transparent centre, dark violet edges.
function FA.vignette()
	local S = 256
	return paint("vig", S, S, function(x, y)
		local u, v = (x / S - 0.5) * 2, (y / S - 0.5) * 2
		local r = math.sqrt(u * u * 0.8 + v * v)
		return 0.02, 0.01, 0.06, smooth(0.6, 1.35, r) * 0.6
	end)
end

-- signed distance to a polygon (Inigo Quilez's sdPolygon); pts = { {x, y}, ... }
local function sdPoly(px, py, pts)
	local n = #pts
	local dx, dy = px - pts[1][1], py - pts[1][2]
	local d = dx * dx + dy * dy
	local s = 1
	local j = n
	for i = 1, n do
		local vi, vj = pts[i], pts[j]
		local ex, ey = vj[1] - vi[1], vj[2] - vi[2]
		local wx, wy = px - vi[1], py - vi[2]
		local t = clamp01((wx * ex + wy * ey) / (ex * ex + ey * ey))
		local bx, by = wx - ex * t, wy - ey * t
		d = math.min(d, bx * bx + by * by)
		local c1, c2, c3 = py >= vi[2], py < vj[2], ex * wy > ey * wx
		if (c1 and c2 and c3) or (not c1 and not c2 and not c3) then
			s = -s
		end
		j = i
	end
	return s * math.sqrt(d)
end

local SHAPES = {}
do
	local star = {}
	for i = 0, 9 do
		local a = -math.pi / 2 + i * math.pi / 5
		local r = (i % 2 == 0) and 40 or 17
		table.insert(star, { 48 + math.cos(a) * r, 50 + math.sin(a) * r })
	end
	SHAPES.star = function(x, y)
		return sdPoly(x, y, star)
	end
	local gem = { { 26, 36 }, { 36, 22 }, { 60, 22 }, { 70, 36 }, { 48, 76 } }
	SHAPES.gem = function(x, y)
		local d = sdPoly(x, y, gem)
		-- a thin dark facet line across the crown of the gem
		if d < -2 and math.abs(y - 36) < 1 then
			return 1
		end
		return d
	end
	SHAPES.crown = function(x, y)
		return sdPoly(x, y, { { 22, 70 }, { 18, 32 }, { 34, 48 }, { 48, 24 }, { 62, 48 }, { 78, 32 }, { 74, 70 } })
	end
	SHAPES.paw = function(x, y)
		local function circ(cx, cy, r)
			return math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2) - r
		end
		local pad = math.sqrt(((x - 48) / 1.15) ^ 2 + (y - 60) ^ 2) - 15
		return math.min(pad, circ(28, 42, 7.5), circ(40, 30, 8), circ(56, 30, 8), circ(68, 42, 7.5))
	end
end

-- White symbol (star, gem, crown, paw) with a soft glow; tint with ImageColor3.
function FA.symbol(name)
	local fn = SHAPES[name]
	if not fn then
		return nil
	end
	return paint("sym" .. name, 96, 96, function(x, y)
		local d = fn(x, y)
		local body = 1 - smooth(-0.8, 0.8, d)
		local glow = (1 - smooth(0, 10, d)) ^ 2 * 0.35
		return 1, 1, 1, math.max(body, glow)
	end)
end

do
	FA.ok = pcall(function()
		FA.glow()
	end)
end

return FA
