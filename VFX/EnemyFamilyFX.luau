--!nocheck
-- EnemyFamilyFX (T134, overnight fx-audio, 2026-10-29): a hit and a death effect for each of the six enemy families.
-- Installed as ReplicatedStorage.EnemyFamilyFX. FxLayer calls hit(model) when an enemy takes a shot (its Highlight flashes) and death(model) when
-- the health bar goes (a kill). Cosmetic only; the server already decided. Families (model name -> family):
--   hollow  Grunt, Parishioner     robe dust and cold lantern sparks / the robe slumps in cloth shards, the lantern gutters out
--   fog     Swift, FogWisp         a mist ripple / five mist puffs drift apart and thin out
--   brass   Tank (Sentinel)        brass sparks and a clang ring / three gears pop off, steam puff
--   crow    Crow                   feathers scatter / a feather burst falls, one gear drops
--   thief   Thief                  a coin glint and violet smoke / the lantern drops, glass shards and a gold flare
--   clockwork Boss                 spark shower and steam / big gear burst, double ring, steam column
-- Budget: hits use no emitter (parts only, at most 5); deaths use 1 emitter (FxCommon.take) and at most 10 parts. A model gets one hit effect
-- per 0.12 s. Reduced motion: only a short static glow where the effect would be. Flashes off: glows start fainter.
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("FxCommon"))

local M = { log = {} }
local V3 = Vector3.new
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

M.FAMILY = { Grunt = "hollow", Parishioner = "hollow", Swift = "fog", FogWisp = "fog", Tank = "brass", Crow = "crow", Thief = "thief", Boss = "clockwork" }
M.NAMES = { "hollow", "fog", "brass", "crow", "thief", "clockwork" }
local ACCENT = { hollow = rgb(150, 230, 215), fog = rgb(170, 200, 230), brass = rgb(201, 162, 75), crow = rgb(120, 126, 150), thief = rgb(190, 130, 230), clockwork = rgb(140, 230, 110) }

local function glow(pos, color, d0, d1, life)
	local b = C.part({ Shape = Enum.PartType.Ball, Color = color, Transparency = C.softAlpha(.35), Size = Vector3.one * d0, Position = pos })
	C.tw(b, life, { Size = Vector3.one * d1, Transparency = 1 })
	C.gone(b, life)
end
local function ring(pos, color, d1, life, dy)
	local p = C.part({ Shape = Enum.PartType.Cylinder, Color = color, Transparency = .3, Size = V3(.1, d1 * .3, d1 * .3), CFrame = CFrame.new(pos.X, pos.Y + (dy or 0), pos.Z) * CFrame.Angles(0, 0, math.pi / 2) })
	C.tw(p, life, { Size = V3(.1, d1, d1), Transparency = 1 }, Enum.EasingStyle.Quint)
	C.gone(p, life)
end
-- n small pieces flung outward; shape "wedge" | "ball" | "gear" (a thin cylinder)
local function pieces(pos, n, shape, color, size, reach, life, fall)
	if C.still() then return end
	n = math.max(1, math.floor(n * (C.quality == "low" and .5 or 1) + .5))
	for _ = 1, n do
		local props = { Color = color:Lerp(C.CREAM, math.random() * .25), Size = size, Position = pos }
		if shape == "ball" then props.Shape = Enum.PartType.Ball
		elseif shape == "wedge" then props.Shape = Enum.PartType.Wedge
		elseif shape == "gear" then props.Shape, props.Size, props.Material = Enum.PartType.Cylinder, V3(size.X * .4, size.X * 2.2, size.X * 2.2), Enum.Material.Metal end
		local p = C.part(props)
		p.CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		local dir = V3(math.random() - .5, math.random() * .8 + (fall and 0 or .3), math.random() - .5).Unit
		local land = pos + dir * reach + V3(0, fall and -1.2 or 0, 0)
		C.tw(p, life, { Position = land, Transparency = 1, Orientation = V3(math.random(0, 360), math.random(0, 360), 0) }, Enum.EasingStyle.Quad)
		C.gone(p, life)
	end
end

local function centre(model)
	local cf, size = model:GetBoundingBox()
	return cf.Position, size
end

local HIT = {
	hollow = function(p) glow(p, ACCENT.hollow, .5, 2, .25); pieces(p, 3, "ball", ACCENT.hollow, Vector3.one * .18, 2.2, .35) end,
	fog = function(p) ring(p, ACCENT.fog, 4, .4, -.5); glow(p, C.CREAM, .8, 2.6, .3) end,
	brass = function(p) ring(p, C.GOLD_HI, 4.5, .3, -.4); pieces(p, 4, "wedge", C.GOLD_HI, V3(.1, .45, .25), 2.8, .3) end,
	crow = function(p) pieces(p, 4, "wedge", ACCENT.crow, V3(.08, .6, .3), 2.4, .5, true) end,
	thief = function(p) glow(p, ACCENT.thief, .6, 2.2, .3); pieces(p, 2, "ball", C.GOLD_HI, Vector3.one * .22, 2, .4) end,
	clockwork = function(p) pieces(p, 5, "wedge", C.GOLD_HI, V3(.12, .6, .3), 4, .4); glow(p, C.CREAM, 1, 3.4, .3) end,
}

local function emitter(p, o)
	local a = C.part({ Transparency = 1, Size = Vector3.one * .2, Position = p })
	C.emit(a, o)
	C.gone(a, 2)
end

local DEATH = {
	hollow = function(p, size)
		pieces(p, 6, "wedge", rgb(80, 72, 108), V3(.15, .7, .5), 2.6, .6, true)
		glow(p + V3(1, -.5, 0), ACCENT.hollow, 1.2, .1, .5) -- the cold lantern shrinks out
		emitter(p, { c0 = ACCENT.hollow, c1 = C.INK, n = 6, life = .8, speed = 2, size = .4, accel = V3(0, -1, 0), light = .5 })
	end,
	fog = function(p, size)
		for i = 1, 5 do
			local d = V3(math.cos(i * 1.26) * 2.4, 1 + i * .3, math.sin(i * 1.26) * 2.4)
			local b = C.part({ Shape = Enum.PartType.Ball, Color = i % 2 == 0 and ACCENT.fog or C.CREAM, Transparency = .4, Size = Vector3.one * 1.4, Position = p })
			C.tw(b, .8, { Position = p + (C.still() and V3(0, 0, 0) or d), Size = Vector3.one * 3, Transparency = 1 })
			C.gone(b, .85)
		end
		emitter(p, { c0 = ACCENT.fog, c1 = C.CREAM, n = 5, life = .9, speed = 1.5, size = .3, accel = V3(0, 1, 0), light = .6 })
	end,
	brass = function(p, size)
		pieces(p, 3, "gear", C.GOLD, Vector3.one * .5, 3.6, .7, true)
		glow(p, C.CREAM, 1.5, 4.5, .45)
		emitter(p, { texture = "rbxasset://textures/particles/smoke_main.dds", c0 = C.CREAM, c1 = C.GOLD, n = 5, life = .9, speed = 2, size = 1.6, accel = V3(0, 3, 0), light = .15 })
	end,
	crow = function(p, size)
		pieces(p, 8, "wedge", ACCENT.crow, V3(.08, .7, .3), 3, .8, true)
		pieces(p, 1, "gear", C.GOLD, Vector3.one * .4, 1.6, .7, true)
		emitter(p, { c0 = C.CREAM, c1 = ACCENT.crow, n = 4, life = .7, speed = 3, size = .3, accel = V3(0, -3, 0) })
	end,
	thief = function(p, size)
		pieces(p, 5, "wedge", rgb(190, 235, 235), V3(.1, .5, .25), 3, .6) -- glass shards of the dropped lantern
		glow(p + V3(0, -.6, 0), C.GOLD_HI, 1.2, 4, .5)
		emitter(p, { c0 = C.GOLD_HI, c1 = ACCENT.thief, n = 7, life = .8, speed = 4, size = .4, accel = V3(0, 2, 0) })
	end,
	clockwork = function(p, size)
		pieces(p, 5, "gear", C.GOLD, Vector3.one * .8, 6, .9, true)
		ring(p, C.GOLD_HI, 12, .6, -size.Y * .5 + .2)
		task.delay(.15 * C.slow, function() ring(p, C.CREAM, 18, .7, -size.Y * .5 + .2) end)
		glow(p, C.CREAM, 3, 9, .5)
		emitter(p, { texture = "rbxasset://textures/particles/smoke_main.dds", c0 = C.CREAM, c1 = C.GOLD, n = 8, life = 1.1, speed = 3, size = 3, accel = V3(0, 5, 0), light = .15 })
	end,
}

local lastHit = setmetatable({}, { __mode = "k" })

function M.family(model) return M.FAMILY[model.Name] end

function M.hit(model)
	local fam = M.FAMILY[model.Name]
	if not fam or not model.Parent then return false end
	local now = os.clock()
	if now - (lastHit[model] or 0) < .12 then return false end
	lastHit[model] = now
	local p = model:GetPivot().Position + V3(0, 1.2, 0)
	if C.still() then glow(p, ACCENT[fam], 1, 2, .2) else HIT[fam](p) end
	table.insert(M.log, { fam = fam, ev = "hit" })
	C.note("hit_" .. fam)
	return true
end

function M.death(model)
	local fam = M.FAMILY[model.Name]
	if not fam then return false end
	local p, size = centre(model)
	if C.still() then glow(p, ACCENT[fam], 1.5, 4, .5) else DEATH[fam](p, size) end
	table.insert(M.log, { fam = fam, ev = "death" })
	C.note("death_" .. fam)
	return true
end

return M
