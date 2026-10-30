--!nocheck
-- FamiliarShots (T133, overnight fx-audio, 2026-10-29): one attack / trail / star look for each of the 20 familiars.
-- A shot style is "fs_<PetId>" (the Characters folder's Shot attribute). install() adds the 20 styles, their hit reactions and
-- a small hit accent to ProjectileFX (called by one line at the end of ProjectileFX). Cosmetic only: the server already did the damage.
-- Look rules: gold-ink palette (cream core, near-black / antique-gold trail ends) with the familiar's own colour as the shell.
-- Budget: at most 1 ParticleEmitter per shot, all through FxCommon.take (Low 10, Default 20, High 32 live). No Highlights.
-- Reduced motion: no wave, spiral, spin or orbit, no scattering shards (rings and puffs only). Flashes off: softer impact.
-- Contact sheet: FamiliarShots.sheet(origin) fires all 20 side by side (used for the captures).
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("FxCommon"))

local M = { live = 0 }
local V3 = Vector3.new
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- col: identity colour (= Characters Color). head: ball block disc wedge. s: size factors of the shot width w.
-- path: straight arc wave spiral lob. hit: ring (studs), puff (studs), shards (n), star (rays), glint, ash, splat, ink (dark puff).
M.SPECS = {
	Ember = { col = rgb(255, 110, 64), head = "ball", s = V3(.6, .6, .6), path = "arc", h = 1.2, dur = .2, trail = "fire", hit = { puff = 1.8, shards = 4, glint = true } },
	Zap = { col = rgb(255, 225, 80), head = "wedge", s = V3(.35, .35, .8), path = "wave", amp = .9, f = 3, dur = .12, spin = 12, trail = "spark", hit = { star = 4, glint = true } },
	BrassHound = { col = rgb(227, 176, 122), head = "block", mat = Enum.Material.Metal, s = V3(.5, .5, .9), path = "straight", dur = .1, trail = "line", hit = { ring = 4, shards = 3 } },
	Sentinel = { col = rgb(196, 150, 70), head = "block", mat = Enum.Material.Metal, s = V3(.9, .9, .9), path = "straight", dur = .22, trail = "line", hit = { ring = 7, puff = 1.6 } },
	Frostling = { col = rgb(110, 210, 255), head = "wedge", s = V3(.3, .3, 1.4), path = "straight", dur = .13, trail = "spark", hit = { shards = 6, ring = 3, star = 6 } },
	Boulder = { col = rgb(150, 130, 110), head = "ball", mat = Enum.Material.Slate, s = V3(.9, .9, .9), path = "lob", h = 4, dur = .3, trail = "line", hit = { ring = 8, puff = 2, shards = 5 }, heavy = true },
	Ward = { col = rgb(127, 160, 192), head = "disc", s = V3(.2, 1.1, 1.1), path = "straight", dur = .15, spin = 10, trail = "line", hit = { ring = 6, glint = true } },
	Archivist = { col = rgb(43, 166, 154), head = "block", s = V3(.8, .06, 1), path = "spiral", r = .5, dur = .22, spin = 14, trail = "line", hit = { shards = 5, glint = true } },
	Mourner = { col = rgb(31, 34, 48), head = "wedge", s = V3(1.2, .12, .6), path = "wave", amp = 1.4, f = 2, dur = .24, spin = 6, trail = "ink", hit = { ink = 1.8, shards = 3 } },
	VoltFox = { col = rgb(190, 110, 255), head = "block", s = V3(.7, .05, 1), path = "arc", h = .6, dur = .2, spin = 18, trail = "spark", hit = { star = 6, ring = 4 } },
	GreyVeilWraith = { col = rgb(237, 238, 244), head = "ball", s = V3(.8, .8, .8), alpha = .3, path = "wave", amp = .5, f = 2, dur = .24, trail = "fog", hit = { puff = 2.6, ring = 5 } },
	StarDrake = { col = rgb(255, 190, 70), head = "ball", s = V3(.7, .7, .7), path = "arc", h = 1, dur = .18, trail = "spark", hit = { star = 5, glint = true } },
	DameOrrery = { col = rgb(226, 170, 80), head = "ball", s = V3(.5, .5, .5), orbit = 2, path = "straight", dur = .2, trail = "line", hit = { ring = 5, star = 4 } },
	CantorVesper = { col = rgb(170, 190, 255), head = "disc", s = V3(.1, .6, .6), grow = 3, path = "straight", dur = .22, trail = "line", hit = { ring = 8, glint = true, ring2 = 12 } },
	VeilWalker = { col = rgb(190, 230, 255), head = "wedge", s = V3(.3, .3, 1.1), cross = true, path = "spiral", r = .7, dur = .18, spin = 8, trail = "spark", hit = { star = 6, ring = 3 } },
	TheLamplighter = { col = rgb(255, 214, 120), head = "ball", s = V3(.8, .8, .8), path = "lob", h = 5, dur = .32, trail = "ash", hit = { ring = 6, ash = true, puff = 1.8 }, heavy = true },
	CogWarden = { col = rgb(230, 180, 80), head = "disc", mat = Enum.Material.Metal, s = V3(.25, 1.1, 1.1), path = "straight", dur = .17, spin = 14, trail = "spark", hit = { shards = 5, ring = 4 } },
	ConstableWren = { col = rgb(224, 164, 88), head = "block", s = V3(.2, .2, 1.6), path = "straight", dur = .09, trail = "line", hit = { ring = 3, glint = true, star = 2 } },
	MadamQuill = { col = rgb(154, 140, 255), head = "wedge", s = V3(.18, .18, 1.2), path = "wave", amp = .5, f = 5, dur = .2, trail = "ink", hit = { splat = 2.4, shards = 3 } },
	FerrymanOfFog = { col = rgb(143, 211, 208), head = "block", s = V3(1.2, .25, .55), path = "arc", h = .6, dur = .26, trail = "fog", hit = { puff = 2.4, ring = 7 } },
}
M.ORDER = { "Ember", "Zap", "BrassHound", "Sentinel", "Frostling", "Boulder", "Ward", "Archivist", "Mourner", "VoltFox", "GreyVeilWraith", "StarDrake", "DameOrrery", "CantorVesper", "VeilWalker", "TheLamplighter", "CogWarden", "ConstableWren", "MadamQuill", "FerrymanOfFog" }

local function luma(c) return (c.R + c.G + c.B) / 3 end
-- dark familiar colours (Mourner) would vanish on the dusk street: lift them toward cream
local function shell(color) return luma(color) < 0.25 and color:Lerp(C.CREAM, 0.6) or color:Lerp(C.CREAM, 0.12) end

local function flatRing(pos, color, d0, d1, life, alpha)
	local p = C.part({ Shape = Enum.PartType.Cylinder, Color = color, Transparency = alpha or .25, Size = V3(.1, d0, d0), CFrame = CFrame.new(pos.X, pos.Y - 1.35, pos.Z) * CFrame.Angles(0, 0, math.pi / 2) })
	C.tw(p, life, { Size = V3(.1, d1, d1), Transparency = 1 }, Enum.EasingStyle.Quint)
	C.gone(p, life)
end

local function puffBall(pos, color, d, life, dark)
	local b = C.part({ Shape = Enum.PartType.Ball, Color = color, Material = dark and Enum.Material.SmoothPlastic or Enum.Material.Neon, Transparency = dark and .2 or C.softAlpha(.3), Size = Vector3.one * d * .35, Position = pos })
	C.tw(b, life, { Size = Vector3.one * d, Transparency = 1 })
	C.gone(b, life)
end

local function shardsAt(pos, color, n, parent)
	if C.still() then return end
	n = math.max(1, math.floor(n * (C.quality == "low" and .5 or 1) + .5))
	for _ = 1, n do
		local s = C.part({ Shape = Enum.PartType.Wedge, Color = color:Lerp(C.CREAM, math.random() * .4), Size = V3(.12, .5, .3), CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, 0) })
		local dir = V3(math.random() - .5, math.random() * .8 + .3, math.random() - .5).Unit
		C.tw(s, .34, { CFrame = s.CFrame + dir * 3, Transparency = 1, Size = V3(.04, .15, .1) })
		C.gone(s, .36)
	end
end

local function starAt(pos, color, rays, w)
	if C.still() then return end
	for i = 0, rays - 1 do
		local ray = C.part({ Color = C.GOLD_HI:Lerp(color, .35), Transparency = C.softAlpha(.1), Size = V3(w * .15, w * .15, w * 1.2), CFrame = CFrame.new(pos) * CFrame.Angles(0, i * math.pi * 2 / rays, .4) * CFrame.new(0, 0, -w * .5) })
		C.tw(ray, .24, { Transparency = 1, Size = V3(.04, .04, w * 2.2) })
		C.gone(ray, .26)
	end
end

-- impact at the enemy; `k` scales (crit 1.25, reaction accent 0.5)
local function impact(spec, to, color, w, k)
	local h = spec.hit
	local c = shell(color)
	if h.ring then flatRing(to, c, h.ring * .3 * k, h.ring * k, .45) end
	if h.ring2 then task.delay(.12 * C.slow, function() flatRing(to, C.CREAM, h.ring2 * .25 * k, h.ring2 * k, .5, .4) end) end
	if h.puff then puffBall(to, c, h.puff * k, .3) end
	if h.ink then puffBall(to, rgb(34, 28, 44), h.ink * k, .35, true) end
	if h.splat then
		local d = C.part({ Shape = Enum.PartType.Cylinder, Color = rgb(24, 18, 34), Material = Enum.Material.SmoothPlastic, Transparency = .1, Size = V3(.06, h.splat * k, h.splat * k), CFrame = CFrame.new(to.X, to.Y - 1.38, to.Z) * CFrame.Angles(0, 0, math.pi / 2) })
		local edge = C.part({ Shape = Enum.PartType.Cylinder, Color = c, Transparency = .3, Size = V3(.05, h.splat * k * 1.15, h.splat * k * 1.15), CFrame = d.CFrame })
		C.tw(d, .6, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		C.tw(edge, .6, { Transparency = 1 })
		C.gone(d, .65)
		C.gone(edge, .65)
	end
	if h.shards then shardsAt(to, c, h.shards * k, nil) end
	if h.star then starAt(to, c, h.star, w * k) end
	if h.glint then
		local a = C.part({ Transparency = 1, Size = Vector3.one * .2, Position = to })
		C.emit(a, { c0 = C.CREAM, c1 = c, n = 6, life = .5, speed = 6, size = .5 })
		C.gone(a, 1.2)
	end
	if h.ash and not C.still() then
		local a = C.part({ Transparency = 1, Size = Vector3.one * .2, Position = to })
		C.emit(a, { c0 = C.GOLD_HI, c1 = C.INK, n = 8, life = .9, speed = 2, size = .35, accel = V3(0, -3, 0), light = .3 })
		C.gone(a, 1.5)
	end
end

local function trailOf(spec, head, color, w)
	local kind = spec.trail
	if kind == "line" or kind == "ink" or kind == "fog" or kind == "ash" or kind == "fire" or kind == "spark" then
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		local half = math.max(.1, math.min(w * spec.s.Y, w * .5) * .5)
		a0.Position, a1.Position = V3(0, half, 0), V3(0, -half, 0)
		a0.Parent, a1.Parent = head, head
		local t = Instance.new("Trail")
		t.Attachment0, t.Attachment1 = a0, a1
		local dark = kind == "ink"
		t.Color = ColorSequence.new(dark and rgb(60, 50, 80) or shell(color), kind == "fog" and C.CREAM or (kind == "fire" and rgb(255, 70, 20) or C.GOLD))
		t.Transparency = NumberSequence.new(kind == "fog" and .5 or .2, 1)
		t.Lifetime = (kind == "fog" and .4 or .2) * C.slow
		t.LightEmission = dark and 0 or .9
		t.LightInfluence = 0
		t.Parent = head
	end
	if (kind == "fire" or kind == "spark" or kind == "ash") and C.quality ~= "low" and not C.still() and C.take(1, .8) then
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(kind == "fire" and rgb(255, 170, 70) or C.GOLD_HI, shell(color))
		pe.LightEmission = 1
		pe.LightInfluence = 0
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, w * .4), NumberSequenceKeypoint.new(1, 0) })
		pe.Lifetime = NumberRange.new(.2 * C.slow, .35 * C.slow)
		pe.Rate = C.quality == "high" and 70 or 45
		pe.Speed = NumberRange.new(.5, 1.5)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Acceleration = kind == "ash" and V3(0, -4, 0) or Vector3.zero
		pe.TimeScale = 1 / C.slow
		pe.Parent = head
	end
end

local function makeHead(spec, from, color, w, parent)
	local S = spec.s * w
	local cls = { ball = Enum.PartType.Ball, block = Enum.PartType.Block, disc = Enum.PartType.Cylinder, wedge = Enum.PartType.Wedge }
	local size = S
	if spec.head == "ball" then size = Vector3.one * math.max(S.X, .25) end
	local p = C.part({ Shape = cls[spec.head], Color = shell(color), Material = spec.mat or Enum.Material.Neon, Transparency = spec.alpha or 0, Size = size, CFrame = CFrame.new(from) }, parent)
	local core
	if spec.head == "ball" or spec.head == "block" then
		core = C.part({ Shape = spec.head == "ball" and Enum.PartType.Ball or nil, Color = C.flashes and C.CREAM or shell(color):Lerp(C.CREAM, .4), Size = size * .5, CFrame = p.CFrame }, parent)
	end
	return p, core
end

local function pathPos(spec, from, to, a, dir, side, up)
	local pos = from:Lerp(to, a)
	local still = C.still()
	if spec.path == "arc" or spec.path == "lob" then
		pos += up * math.sin(a * math.pi) * (spec.h or 1)
	elseif spec.path == "wave" and not still then
		pos += side * math.sin(a * math.pi * (spec.f or 3)) * (spec.amp or .6) * math.sin(a * math.pi)
	elseif spec.path == "spiral" and not still then
		local ang = a * math.pi * 4
		pos += (side * math.cos(ang) + up * math.sin(ang)) * (spec.r or .5) * math.sin(a * math.pi)
	end
	return pos
end

function M.shoot(id, from, to, color, w, parent, crit, PFX)
	local spec = M.SPECS[id]
	C.note("shot_" .. id)
	local len = (to - from).Magnitude
	local dir = len > .01 and (to - from).Unit or V3(0, 0, -1)
	local up = V3(0, 1, 0)
	local side = dir:Cross(up)
	side = side.Magnitude > .01 and side.Unit or V3(1, 0, 0)
	local still = C.still()
	local scale = PFX and PFX.timeScale or 1
	local dur = spec.dur * C.slow / scale
	local head, core = makeHead(spec, from, color, w, parent)
	trailOf(spec, head, color, w)
	local extras = {}
	if spec.cross then
		local x = head:Clone()
		for _, d in x:GetChildren() do if d:IsA("Trail") or d:IsA("ParticleEmitter") or d:IsA("Attachment") then d:Destroy() end end
		x.Parent = parent
		extras[1] = { part = x, roll = math.pi / 2 }
	end
	if spec.orbit and C.quality ~= "low" and not still then
		for i = 1, spec.orbit do
			local o = C.part({ Shape = Enum.PartType.Ball, Color = C.GOLD_HI, Size = Vector3.one * w * .22, Position = from }, parent)
			extras[#extras + 1] = { part = o, orbit = i }
		end
	end
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local a = math.min(1, (os.clock() - t0) / dur)
		local pos = pathPos(spec, from, to, a, dir, side, up)
		local look = dir
		local roll = spec.spin and not still and a * spec.spin or 0
		local cf = CFrame.lookAt(pos, pos + look) * CFrame.Angles(0, 0, roll)
		if spec.head == "disc" then cf = CFrame.lookAt(pos, pos + look) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, 0, roll) end
		if spec.grow then head.Size = V3(spec.s.X * w, spec.s.Y * w * (1 + (spec.grow - 1) * a), spec.s.Z * w * (1 + (spec.grow - 1) * a)) end
		if head.Parent then head.CFrame = cf end
		if core and core.Parent then core.CFrame = cf end
		for _, e in extras do
			if e.roll then e.part.CFrame = cf * CFrame.Angles(0, 0, e.roll)
			elseif e.orbit then
				local ang = a * 14 + e.orbit * math.pi
				e.part.Position = pos + (side * math.cos(ang) + up * math.sin(ang)) * w * .7
			end
		end
		if a >= 1 then
			conn:Disconnect()
			head:Destroy()
			if core then core:Destroy() end
			for _, e in extras do e.part:Destroy() end
			impact(spec, to, color, w, crit and 1.25 or 1)
		end
	end)
	return spec.dur
end

-- the small accent a hit leaves on the enemy (ProjectileFX.react calls ext[style])
local function accent(id)
	return function(at, parent, crit)
		local spec = M.SPECS[id]
		flatRing(at, shell(spec.col), .8, 2.4 * (crit and 1.3 or 1), .25)
	end
end

function M.install(PFX, STYLES)
	PFX.ext = PFX.ext or {}
	for _, id in M.ORDER do
		local key = "fs_" .. id
		local spec = M.SPECS[id]
		STYLES[key] = function(from, to, color, w, parent, crit) return M.shoot(id, from, to, color, w, parent, crit, PFX) end
		local c = shell(spec.col)
		PFX.REACT[key] = { tint = c, jolt = spec.heavy and 1.2 or (spec.dur < .12 and .3 or .6), wobble = spec.path == "wave" and .3 or 0, tilt = spec.heavy and .12 or 0, jitter = spec.trail == "spark" and .3 or 0, hold = spec.trail == "fog" and .3 or 0, dur = spec.heavy and .35 or .22 }
		PFX.ext[key] = accent(id)
	end
	M.installed = true
end

-- Contact sheet: all 20 attacks in a 5 x 4 grid under `origin`, every one fired from its left edge to its right edge.
-- slowDown stretches flights and impacts (captures); returns how many shots were fired.
function M.sheet(origin, PFX, slowDown, impactOnly)
	C.slow = slowDown or 1
	local fired = 0
	for i, id in M.ORDER do
		local col, row = (i - 1) % 5, math.floor((i - 1) / 5)
		local base = origin + V3(col * 16, 0, row * 9)
		local from, to = base + V3(-6, 3, 0), base + V3(5, 1.5, 0)
		local marker = C.part({ Color = rgb(60, 52, 70), Material = Enum.Material.SmoothPlastic, Size = V3(1.6, 3, 1.6), Position = to - V3(0, 0, 0) })
		marker.Transparency = .4
		marker.Name = "SheetTarget"
		local fn = PFX.styles["fs_" .. id]
		if impactOnly then
			impact(M.SPECS[id], to, M.SPECS[id].col, 0.6 + 3 * .25, 1)
		else
			fn(from, to, M.SPECS[id].col, 0.6 + 3 * .25, C.folder(), false)
		end
		fired += 1
	end
	return fired
end

return M
