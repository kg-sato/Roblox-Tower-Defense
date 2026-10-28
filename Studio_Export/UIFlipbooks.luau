--!nocheck
-- UIFlipbooks: small animated UI sheets painted at runtime by FrameArt (EditableImage, no upload), played by the
-- FlipbookFX UI player (T17). Each sheet is a 4x4 grid of 64 px frames (256 x 256), painted once on first use and
-- cached. Glow sheets are additive-looking light on transparent pixels, so they are only played over dark panels.
-- Install as ReplicatedStorage.UIFlipbooks.
--
--   UIFlipbooks.play(label, "frame_Epic" | "claim" | "achievement", { loop, seconds }) -> stop() or nil
--   UIFlipbooks.sheet(kind)  -> Content (paints on first call)
--   UIFlipbooks.painted      -> kind -> times the painter ran (should stay 1)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FA = require(ReplicatedStorage:WaitForChild("FrameArt"))
local F = require(ReplicatedStorage:WaitForChild("FlipbookFX"))

local M = { painted = {}, GRID = 4, CELL = 64 }
local N = M.GRID * M.GRID

local COLORS = {
	Common = { 0.78, 0.8, 0.86 },
	Rare = { 0.31, 0.69, 1 },
	Epic = { 0.73, 0.5, 1 },
	Legendary = { 1, 0.82, 0.38 },
}

local function smooth(a, b, x)
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

local function hash(x, y)
	local n = math.sin(x * 12.9898 + y * 78.233) * 43758.5453
	return n - math.floor(n)
end

-- distance to a rounded square frame border (cell coords 0..64), negative inside the stroke
local function border(x, y)
	local cx, cy, h, r = 32, 32, 25, 8
	local qx, qy = math.abs(x - cx) - h + r, math.abs(y - cy) - h + r
	local d = math.min(math.max(qx, qy), 0) + math.sqrt(math.max(qx, 0) ^ 2 + math.max(qy, 0) ^ 2) - r
	return math.abs(d) - 1.6
end

-- position along the border, 0..1 clockwise from the top-left (for glints and comets)
local function along(x, y)
	local a = math.atan2(y - 32, x - 32)
	return (a / (2 * math.pi)) % 1
end

local PAINTERS = {}

-- rarity frames: a border in the rarity colour plus a loop that grows richer with rarity
local function framePainter(rarity)
	local c = COLORS[rarity]
	return function(x, y, f)
		local t = f / N -- loop phase 0..1
		local b = border(x, y)
		local stroke = 1 - smooth(-0.6, 1.2, b)
		local glow = (1 - smooth(0, 5, b)) * 0.35
		local a = math.max(stroke * 0.9, glow)
		local light = 0
		if rarity == "Common" then -- drifting dust: a few faint motes rising past the frame
			for k = 1, 6 do
				local px = 8 + hash(k, 1) * 48
				local py = (64 - ((hash(k, 2) * 64 + t * 64) % 64))
				light = math.max(light, (1 - smooth(0.5, 2.2, math.sqrt((x - px) ^ 2 + (y - py) ^ 2))) * 0.55)
			end
		elseif rarity == "Rare" then -- pulsing glints at the corners
			for k, p in { { 12, 12 }, { 52, 12 }, { 52, 52 }, { 12, 52 } } do
				local pulse = 0.5 + 0.5 * math.cos(2 * math.pi * (t - k / 4))
				local dx, dy = math.abs(x - p[1]), math.abs(y - p[2])
				local star = (1 - smooth(0, 1.2, math.min(dx, dy))) * (1 - smooth(1, 7, math.max(dx, dy)))
				light = math.max(light, star * pulse)
			end
		elseif rarity == "Epic" then -- a comet orbiting the border with a fading tail
			local s = along(x, y)
			local behind = (t - s) % 1
			local tail = behind < 0.35 and (1 - behind / 0.35) or 0
			light = math.max(light, tail ^ 1.5 * (1 - smooth(-1, 3, b)))
		else -- Legendary: flames licking up from the border
			local flick = hash(math.floor(x / 3), math.floor((y + t * 64) / 3) + f)
			local up = (1 - smooth(-2, 6, b)) * (y < 40 and 1 or 0.4)
			light = math.max(light, up * (0.45 + 0.55 * flick) * (0.6 + 0.4 * math.sin(2 * math.pi * t + x * 0.2)))
		end
		a = math.max(a, light)
		local w = math.clamp(light, 0, 1) -- bright bits lean white
		return c[1] + (1 - c[1]) * w, c[2] + (1 - c[2]) * w, c[3] + (1 - c[3]) * w, a
	end
end
for r in COLORS do
	PAINTERS["frame_" .. r] = framePainter(r)
end

-- claim button sparkle: four-point stars that pop and fade around the edges, looping
PAINTERS.claim = function(x, y, f)
	local t = f / N
	local a = 0
	for k = 1, 5 do
		local phase = (t + k / 5) % 1
		local px, py = 6 + hash(k, 3) * 52, 6 + hash(k, 4) * 52
		local s = math.sin(math.pi * math.clamp(phase / 0.5, 0, 1))
		local dx, dy = math.abs(x - px), math.abs(y - py)
		local star = (1 - smooth(0, 1, math.min(dx, dy))) * (1 - smooth(1, 6 * s + 1, math.max(dx, dy)))
		a = math.max(a, star * s)
	end
	return 1, 0.95, 0.75, a
end

-- achievement burst: a ring and eight rays expand from the centre and fade (one-shot)
PAINTERS.achievement = function(x, y, f)
	local k = f / (N - 1)
	local dx, dy = x - 32, y - 32
	local r = math.sqrt(dx * dx + dy * dy)
	local ringR = 4 + 24 * (1 - (1 - k) ^ 3)
	local ring = (1 - smooth(0, 2.2 * (1 - k) + 0.6, math.abs(r - ringR))) * (1 - k)
	local ang = math.atan2(dy, dx)
	local ray = math.max(0, math.cos(ang * 8)) ^ 12 * (1 - smooth(ringR * 0.6, ringR * 1.2, r)) * (1 - k) ^ 1.5
	local core = (1 - smooth(0, 6 * (1 - k) + 1, r)) * (1 - k) ^ 2
	local a = math.clamp(ring + ray * 0.9 + core, 0, 1)
	return 1, 0.86, 0.5, a
end

function M.sheet(kind)
	local key = "uiflip_" .. kind
	if FA.cache[key] then
		return FA.cache[key]
	end
	local fn = PAINTERS[kind]
	if not fn then
		return nil
	end
	M.painted[kind] = (M.painted[kind] or 0) + 1
	local cell, grid = M.CELL, M.GRID
	return FA.paint(key, cell * grid, cell * grid, function(px, py)
		local col, row = math.floor(px / cell), math.floor(py / cell)
		local f = row * grid + col
		local x, y = px - col * cell, py - row * cell
		-- keep a transparent margin so frames never bleed into each other
		if x < 1 or y < 1 or x > cell - 1 or y > cell - 1 then
			return 0, 0, 0, 0
		end
		return fn(x, y, f)
	end)
end

-- Is the panel behind this label dark enough for a glow sheet? (light on a bright panel washes out)
local function darkBehind(label)
	local p = label.Parent
	while p and p:IsA("GuiObject") do
		if p.BackgroundTransparency < 0.5 then
			local c = p.BackgroundColor3
			return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B < 0.35
		end
		p = p.Parent
	end
	return true -- over the 3D scene at night
end

function M.play(label, kind, opts)
	opts = opts or {}
	if not darkBehind(label) then
		warn("UIFlipbooks: " .. kind .. " is a glow sheet and needs a dark panel behind it; not played")
		return nil
	end
	local content = M.sheet(kind)
	if not content then
		return nil
	end
	label.Image = ""
	label.ImageContent = content
	local loop = opts.loop
	if loop == nil then
		loop = kind ~= "achievement"
	end
	return F.ui(label, { grid = M.GRID, sheetSize = M.CELL * M.GRID, frames = N, seconds = opts.seconds or 1.2, loop = loop })
end

return M
