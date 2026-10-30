--!nocheck
-- LanternFX (T144, overnight fx-audio, 2026-10-29): one lantern-light language for the small feedback of the board.
-- Every piece is warm antique gold + cream light on near-black ink, like a wick catching: it flares, steadies, gutters out.
--   LanternFX.spawn(pos, color)        -- a familiar appears: ground ring decal + motes rising like sparks off a wick
--   LanternFX.column(pos, color, lvl)  -- an upgrade level: slim light column with `lvl` gold ticks climbing it (max 6) + level decal
--   LanternFX.ash(points)              -- stage clear: ash flecks drift down over the street (one emitter per point)
--   LanternFX.vignette(frac)           -- low lantern (crystal at or under 35%): a warm ink vignette that breathes; frac nil or above hides it
--   LanternFX.decal(pos, color, size, life, art)  -- ground sigil / ring decals (FrameArt images on a SurfaceGui)
-- Installed as ReplicatedStorage.LanternFX; FxLayer drives it from the server events. Budget: 1 emitter per spawn / column, one per ash point
-- (3 points on Low, 5 otherwise), all through FxCommon.take. Reduced motion: no drift or breathing, a static fade. Flashes off: no pulse.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local C = require(RS:WaitForChild("FxCommon"))

local M = { log = {} }
local V3 = Vector3.new
M.decal = C.decal

function M.spawn(pos, color)
	table.insert(M.log, "spawn")
	C.note("spawn")
	C.decal(pos, C.GOLD:Lerp(color, .35), 7, .7, "ring")
	local a = C.part({ Transparency = 1, Size = Vector3.one * .2, Position = pos + V3(0, 1.2, 0) })
	C.emit(a, { c0 = C.CREAM, c1 = C.GOLD, n = 7, life = .9, speed = C.still() and 1 or 4, size = .4, accel = V3(0, C.still() and 0 or 3, 0), light = .9 })
	C.gone(a, 1.8)
	if not C.still() then
		local flare = C.part({ Shape = Enum.PartType.Ball, Color = C.GOLD_HI, Transparency = C.softAlpha(.35), Size = Vector3.one * .6, Position = pos + V3(0, 1.2, 0) })
		C.tw(flare, .35, { Size = Vector3.one * 2.4, Transparency = 1 })
		C.gone(flare, .4)
	end
end

function M.column(pos, color, level)
	level = math.clamp(math.floor(tonumber(level) or 1), 1, 6)
	table.insert(M.log, "column" .. level)
	C.note("column")
	local acc = C.GOLD:Lerp(color, .25)
	local h = 11
	local col = C.part({ Shape = Enum.PartType.Cylinder, Color = acc, Transparency = .45, Size = V3(h, .9, .9), CFrame = CFrame.new(pos + V3(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
	C.tw(col, .15, { Size = V3(h, 1.8, 1.8) }, Enum.EasingStyle.Back)
	task.delay(.4 * C.slow, function() if col.Parent then C.tw(col, .45, { Transparency = 1, Size = V3(h, .2, .2) }) end end)
	C.gone(col, .95)
	for i = 1, level do -- one tick per level, spaced up the column
		local t = C.part({ Color = C.CREAM, Size = V3(1.8, .2, .2), CFrame = CFrame.new(pos + V3(0, 1.2 + i * 1.3, 0)) })
		C.tw(t, .6, { Transparency = 1, Position = t.Position + V3(0, C.still() and 0 or 1.2, 0) })
		C.gone(t, .65)
	end
	C.decal(pos, acc, 4 + level, .8, "sigil")
	local a = C.part({ Transparency = 1, Size = Vector3.one * .2, Position = pos + V3(0, 2, 0) })
	C.emit(a, { c0 = C.CREAM, c1 = acc, n = 4 + level * 2, life = .8, speed = C.still() and 1 or 3, size = .35, accel = V3(0, C.still() and 0 or 4, 0) })
	C.gone(a, 1.6)
end

function M.ash(points)
	table.insert(M.log, "ash")
	C.note("ash")
	if C.still() then return end
	local n = C.quality == "low" and 3 or 5
	for i = 1, math.min(#points, n) do
		local p = points[math.max(1, math.floor((i - .5) / n * #points + .5))]
		local a = C.part({ Transparency = 1, Size = V3(12, .2, 4), Position = p + V3(0, 9, 0) })
		C.emit(a, { texture = "rbxasset://textures/particles/smoke_main.dds", c0 = C.INK:Lerp(C.GOLD, .35), c1 = C.GOLD, n = 8, life = 2.4, speed = .6, size = .45, accel = V3(0, -1.6, 0), light = .15, spread = 60 })
		C.gone(a, 3)
	end
end

-- low-lantern vignette: four soft edges of warm ink, breathing slowly (static when flashes are off or motion is reduced)
local gui, edges, breathing
local function ensure()
	if gui and gui.Parent then return end
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder = "LanternVignette", true, false, 1
	gui.Parent = pg
	edges = {}
	for _, e in { { 0, 0, 1, .22, 90 }, { 0, .78, 1, .22, 270 }, { 0, 0, .14, 1, 0 }, { .86, 0, .14, 1, 180 } } do
		local f = Instance.new("Frame")
		f.BorderSizePixel, f.BackgroundColor3, f.BackgroundTransparency = 0, Color3.fromRGB(46, 22, 10), 1
		f.Position, f.Size, f.Active = UDim2.fromScale(e[1], e[2]), UDim2.fromScale(e[3], e[4]), false
		local g = Instance.new("UIGradient")
		g.Rotation, g.Transparency = e[5], NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		g.Parent = f
		f.Parent = gui
		edges[#edges + 1] = f
	end
end

function M.vignette(frac)
	local want = frac ~= nil and frac <= .35
	M.vignetteOn = want
	C.note(want and "vignette_on" or "vignette_off")
	if not want then
		breathing = nil
		if edges then for _, f in edges do C.tw(f, .6, { BackgroundTransparency = 1 }) end end
		return
	end
	ensure()
	local depth = math.clamp(1 - frac / .35, 0, 1) -- the lower the lantern, the darker the edge
	local base = .62 - .2 * depth -- BackgroundTransparency at rest (0 = solid)
	M.base = base
	for _, f in edges do C.tw(f, .5, { BackgroundTransparency = base }) end
	if breathing or C.still() or not C.flashes then return end
	local token = {}
	breathing = token
	task.spawn(function()
		local t0 = os.clock()
		while breathing == token and gui and gui.Parent do
			local b = M.base + .08 * math.sin((os.clock() - t0) * 2.4)
			for _, f in edges do f.BackgroundTransparency = b end
			task.wait(1 / 20)
		end
	end)
end

return M
