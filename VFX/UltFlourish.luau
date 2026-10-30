--!nocheck
-- UltFlourish (T601, overnight fx-audio, 2026-10-29): the signature of each familiar's ultimate, layered on the FirstPerson cutscene
-- at its impact beat, with its own camera move for the aftermath. CutsceneFX.FirstPerson calls UltFlourish.hit(...) in place of its
-- plain drift. Everything is parented to the cutscene stage (destroyed by the cutscene's own clean-up), so nothing can be left behind.
-- Installed as ReplicatedStorage.UltFlourish.
--   id -> { fx = effect kind, cam = camera move, roll = degrees of lean }
--   fx: columns (flame / light columns on the targets), web (zigzag lightning between targets), rush (rings streaking down the lane),
--       dome (a shield dome and slam), spikes (ice spikes), drops (rocks or stars falling on targets), pulses (concentric floor rings),
--       flutter (pages or cards spiralling up), tide (an ink or fog wave rolling out), orbits (tilted rings around the centre),
--       toll (bell rings rising and widening), blades (crossing blade sweeps), lanterns (lanterns lighting down the lane), gears (gears rising and turning)
--   cam: orbit, crane, push, pull, whip, dutch
-- Palette: the familiar's colour (ctx.color) with cream cores and antique gold. At most 1 emitter, at most about 45 parts per ultimate.
-- Reduced motion: no camera move beyond the plain drift and no lean. Flashes off: nothing here flashes (the cutscene owns the impact frame).
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local C = require(RS:WaitForChild("FxCommon"))

local M = { log = {} }
local V3 = Vector3.new

M.PLAN = {
	Ember = { fx = "columns", cam = "crane" }, Zap = { fx = "web", cam = "whip", roll = 6 }, BrassHound = { fx = "rush", cam = "push" },
	Sentinel = { fx = "dome", cam = "pull" }, Frostling = { fx = "spikes", cam = "orbit" }, Boulder = { fx = "drops", cam = "push", rock = true },
	Ward = { fx = "pulses", cam = "pull" }, Archivist = { fx = "flutter", cam = "crane" }, Mourner = { fx = "tide", cam = "dutch", roll = -7, ink = true },
	VoltFox = { fx = "flutter", cam = "orbit", cards = true }, GreyVeilWraith = { fx = "tide", cam = "whip", roll = 5 }, StarDrake = { fx = "drops", cam = "crane" },
	DameOrrery = { fx = "orbits", cam = "orbit" }, CantorVesper = { fx = "toll", cam = "pull" }, VeilWalker = { fx = "blades", cam = "dutch", roll = 8 },
	TheLamplighter = { fx = "lanterns", cam = "push" }, CogWarden = { fx = "gears", cam = "orbit" }, ConstableWren = { fx = "pulses", cam = "whip", fast = true },
	MadamQuill = { fx = "tide", cam = "dutch", roll = 6, ink = true, script = true }, FerrymanOfFog = { fx = "tide", cam = "pull" },
}
M.IDS = { "Ember", "Zap", "BrassHound", "Sentinel", "Frostling", "Boulder", "Ward", "Archivist", "Mourner", "VoltFox", "GreyVeilWraith", "StarDrake", "DameOrrery", "CantorVesper", "VeilWalker", "TheLamplighter", "CogWarden", "ConstableWren", "MadamQuill", "FerrymanOfFog" }

local nameToId
function M.idOf(model, title)
	if not nameToId then
		nameToId = {}
		local ok, Cfg = pcall(function() return require(RS:WaitForChild("Shared"):WaitForChild("Config")) end)
		if ok then for id, def in Cfg.PETS do nameToId[string.upper(def.name)] = id nameToId[id] = id end end
	end
	return (model and nameToId[model.Name] or model and nameToId[string.upper(model.Name)]) or (title and nameToId[title])
end

local function part(stage, props)
	local p = C.part(props, stage)
	Debris:AddItem(p, 4) -- belt and braces: the stage goes first, this only matters if the stage were kept
	return p
end

local function limit(targets, n) local t = {} for i = 1, math.min(#targets, n) do t[i] = targets[i] end return t end

local FX = {}
FX.columns = function(st, ctx, center, col)
	for _, t in limit(ctx.targets, 6) do
		local c = part(st, { Shape = Enum.PartType.Cylinder, Color = col, Transparency = .35, Size = V3(1, 2, 2), CFrame = CFrame.new(t + V3(0, .5, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
		C.tw(c, .35, { Size = V3(16, 3.2, 3.2), CFrame = CFrame.new(t + V3(0, 8, 0)) * CFrame.Angles(0, 0, math.pi / 2) }, Enum.EasingStyle.Quint)
		task.delay(.4, function() if c.Parent then C.tw(c, .5, { Transparency = 1, Size = V3(16, .3, .3) }) end end)
	end
end
FX.web = function(st, ctx, center, col)
	local pts = limit(ctx.targets, 7)
	for i = 1, #pts - 1 do
		local a, b = pts[i] + V3(0, 2, 0), pts[i + 1] + V3(0, 2, 0)
		local last = a
		for s = 1, 3 do
			local nxt = s == 3 and b or a:Lerp(b, s / 3) + V3((math.random() - .5) * 3, (math.random() - .5) * 2, (math.random() - .5) * 3)
			local seg = part(st, { Color = i % 2 == 0 and C.CREAM or col, Size = V3(.3, .3, math.max((nxt - last).Magnitude, .1)), CFrame = CFrame.lookAt(last:Lerp(nxt, .5), nxt) })
			C.tw(seg, .6, { Transparency = 1, Size = V3(.05, .05, seg.Size.Z) })
			last = nxt
		end
	end
end
FX.rush = function(st, ctx, center, col)
	local first = ctx.targets[1] or center
	for i = 1, 6 do
		local r = part(st, { Shape = Enum.PartType.Cylinder, Color = i % 2 == 0 and col or C.GOLD, Transparency = .3, Size = V3(.2, 4, 4), CFrame = CFrame.lookAt(first, center) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(0, 2, 0) })
		task.delay(i * .06, function() if r.Parent then C.tw(r, .5, { Position = r.Position + (center - first).Unit * 18 + V3(0, 0, 0), Size = V3(.2, 9, 9), Transparency = 1 }, Enum.EasingStyle.Quad) end end)
	end
end
FX.dome = function(st, ctx, center, col)
	local d = part(st, { Shape = Enum.PartType.Ball, Color = col, Transparency = .6, Size = Vector3.one * 2, Position = center + V3(0, 1, 0) })
	C.tw(d, .5, { Size = Vector3.one * 24 }, Enum.EasingStyle.Quint)
	task.delay(.6, function() if d.Parent then C.tw(d, .5, { Transparency = 1 }) end end)
	local r = part(st, { Shape = Enum.PartType.Cylinder, Color = C.GOLD_HI, Transparency = .2, Size = V3(.15, 3, 3), CFrame = CFrame.new(center + V3(0, .3, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
	C.tw(r, .6, { Size = V3(.15, 26, 26), Transparency = 1 }, Enum.EasingStyle.Quint)
end
FX.spikes = function(st, ctx, center, col)
	for _, t in limit(ctx.targets, 5) do
		for i = 1, 3 do
			local a = i * 2.1
			local sp = part(st, { Shape = Enum.PartType.Wedge, Material = Enum.Material.Glass, Color = col:Lerp(C.CREAM, .4), Transparency = .15, Size = V3(.6, .2, .6), CFrame = CFrame.new(t + V3(math.cos(a) * 1.2, 0, math.sin(a) * 1.2)) * CFrame.Angles(0, a, 0) })
			C.tw(sp, .25, { Size = V3(.6, 4.5 - i * .5, .6), Position = sp.Position + V3(0, 2, 0) }, Enum.EasingStyle.Back)
			task.delay(.55, function() if sp.Parent then C.tw(sp, .4, { Transparency = 1 }) end end)
		end
	end
end
FX.drops = function(st, ctx, center, col, plan)
	for i, t in limit(ctx.targets, 6) do
		local b = part(st, { Shape = Enum.PartType.Ball, Material = plan.rock and Enum.Material.Slate or Enum.Material.Neon, Color = col, Size = Vector3.one * (plan.rock and 2.4 or 1.5), Position = t + V3(-6, 30, -3) })
		if plan.rock then b.Color = Color3.fromRGB(176, 168, 160) else b.Color = C.GOLD_HI end
		task.delay((i - 1) * .08, function()
			if not b.Parent then return end
			local tw = C.tw(b, .3, { Position = t + V3(0, 1, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tw.Completed:Connect(function()
				if not b.Parent then return end
				local r = part(st, { Shape = Enum.PartType.Cylinder, Color = col, Transparency = .25, Size = V3(.1, 2, 2), CFrame = CFrame.new(t + V3(0, .2, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
				C.tw(r, .5, { Size = V3(.1, 9, 9), Transparency = 1 }, Enum.EasingStyle.Quint)
				C.tw(b, .3, { Transparency = 1, Size = Vector3.one * .3 })
			end)
		end)
	end
end
FX.pulses = function(st, ctx, center, col, plan)
	for i = 1, 4 do
		local r = part(st, { Shape = Enum.PartType.Cylinder, Color = i % 2 == 0 and C.CREAM or col, Transparency = .25, Size = V3(.15, 2, 2), CFrame = CFrame.new(center + V3(0, .3 + i * .05, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
		task.delay(i * (plan.fast and .06 or .14), function() if r.Parent then C.tw(r, .6, { Size = V3(.15, 14 + i * 5, 14 + i * 5), Transparency = 1 }, Enum.EasingStyle.Quint) end end)
	end
end
FX.flutter = function(st, ctx, center, col, plan)
	for i = 1, 14 do
		local a = i / 14 * math.pi * 2
		local f = part(st, { Color = plan.cards and C.CREAM or C.CREAM:Lerp(col, .3), Size = plan.cards and V3(.8, .05, 1.1) or V3(1, .04, 1.3), CFrame = CFrame.new(center + V3(math.cos(a) * 2, .5, math.sin(a) * 2)) })
		C.tw(f, 1, { Position = center + V3(math.cos(a + 2) * 9, 5 + (i % 4) * 2, math.sin(a + 2) * 9), Orientation = V3(math.random(0, 360), math.random(0, 360), 0), Transparency = 1 }, Enum.EasingStyle.Sine)
	end
end
FX.tide = function(st, ctx, center, col, plan)
	local dark = plan.ink and Color3.fromRGB(26, 20, 38) or C.CREAM
	local d = part(st, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.SmoothPlastic, Color = dark, Transparency = .15, Size = V3(.12, 3, 3), CFrame = CFrame.new(center + V3(0, .25, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
	local rim = part(st, { Shape = Enum.PartType.Cylinder, Color = col:Lerp(C.CREAM, .3), Transparency = .3, Size = V3(.1, 3.4, 3.4), CFrame = d.CFrame })
	C.tw(d, .9, { Size = V3(.12, 30, 30), Transparency = 1 }, Enum.EasingStyle.Quint)
	C.tw(rim, .9, { Size = V3(.1, 32, 32), Transparency = 1 }, Enum.EasingStyle.Quint)
	if plan.script then -- quill: a spiral of ink strokes written on the floor
		for i = 1, 8 do
			local a = i / 8 * math.pi * 2
			local s = part(st, { Material = Enum.Material.SmoothPlastic, Color = dark, Size = V3(.3, .1, 3), CFrame = CFrame.new(center + V3(math.cos(a) * 5, .35, math.sin(a) * 5)) * CFrame.Angles(0, -a, 0) })
			C.tw(s, .9, { Transparency = 1, Position = center + V3(math.cos(a) * 12, .35, math.sin(a) * 12) })
		end
	end
end
FX.orbits = function(st, ctx, center, col)
	for i = 1, 3 do
		local r = part(st, { Shape = Enum.PartType.Cylinder, Color = i == 2 and C.CREAM or C.GOLD, Transparency = .35, Size = V3(.12, 6 + i * 3, 6 + i * 3), CFrame = CFrame.new(center + V3(0, 3, 0)) * CFrame.Angles(i * .7, i * 1.1, math.pi / 2) })
		C.tw(r, 1, { Size = V3(.12, 16 + i * 5, 16 + i * 5), Orientation = r.Orientation + V3(0, 140 * i, 0), Transparency = 1 }, Enum.EasingStyle.Sine)
	end
end
FX.toll = function(st, ctx, center, col)
	for i = 1, 3 do
		local r = part(st, { Shape = Enum.PartType.Cylinder, Color = i == 2 and C.CREAM or col, Transparency = .3, Size = V3(.2, 4, 4), CFrame = CFrame.new(center + V3(0, 1 + i * 2, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
		task.delay(i * .18, function() if r.Parent then C.tw(r, .7, { Size = V3(.2, 22, 22), Position = r.Position + V3(0, 5, 0), Transparency = 1 }, Enum.EasingStyle.Quint) end end)
	end
end
FX.blades = function(st, ctx, center, col)
	for i = 1, 6 do
		local side = i % 2 == 0 and 1 or -1
		local b = part(st, { Shape = Enum.PartType.Wedge, Color = i % 3 == 0 and C.CREAM or col, Transparency = .1, Size = V3(.15, .5, 7), CFrame = CFrame.new(center + V3(-12 * side, 1.5 + i * .5, -5 + i * 2)) * CFrame.Angles(0, math.rad(40 * side), 0) })
		task.delay(i * .07, function() if b.Parent then C.tw(b, .4, { Position = b.Position + V3(24 * side, 0, 0), Transparency = 1 }, Enum.EasingStyle.Quint) end end)
	end
end
FX.lanterns = function(st, ctx, center, col)
	local pts = limit(ctx.targets, 6)
	for i, t in pts do
		local pole = part(st, { Material = Enum.Material.Metal, Color = C.GOLD, Size = V3(.3, 4, .3), Position = t + V3(0, 2, 0) })
		local lamp = part(st, { Shape = Enum.PartType.Ball, Color = C.GOLD_HI, Size = Vector3.one * .6, Position = t + V3(0, 4.2, 0) })
		task.delay((i - 1) * .1, function()
			if not lamp.Parent then return end
			C.tw(lamp, .3, { Size = Vector3.one * 2.4 }, Enum.EasingStyle.Back)
			local col2 = part(st, { Shape = Enum.PartType.Cylinder, Color = col, Transparency = .5, Size = V3(1, 1, 1), CFrame = CFrame.new(t + V3(0, 7, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
			C.tw(col2, .5, { Size = V3(14, 2, 2), Transparency = 1 })
			C.tw(lamp, .5, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			C.tw(pole, .5, { Transparency = 1 })
		end)
	end
end
FX.gears = function(st, ctx, center, col)
	for i = 1, 4 do
		local a = i / 4 * math.pi * 2
		local g = part(st, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal, Color = i % 2 == 0 and C.GOLD or C.GOLD_HI, Size = V3(.6, 4.5, 4.5), CFrame = CFrame.new(center + V3(math.cos(a) * 5, .5, math.sin(a) * 5)) * CFrame.Angles(0, 0, 0) })
		C.tw(g, .9, { Position = center + V3(math.cos(a) * 9, 6, math.sin(a) * 9), Orientation = V3(0, 0, 360 * (i % 2 == 0 and 1 or -1)), Transparency = 1 }, Enum.EasingStyle.Quad)
	end
end

local function camTarget(plan, vantage, center, side, up)
	local look = center + up
	local c = plan.cam
	if c == "orbit" then return CFrame.lookAt(center + CFrame.Angles(0, math.rad(55), 0) * (vantage - center), look)
	elseif c == "crane" then return CFrame.lookAt(vantage + up * 9, look)
	elseif c == "push" then return CFrame.lookAt(center + (vantage - center) * .42 + up * 1, look)
	elseif c == "pull" then return CFrame.lookAt(center + (vantage - center) * 1.6 + up * 4, look)
	elseif c == "whip" then return CFrame.lookAt(vantage + side * -16 - up * 3, look)
	end
	return CFrame.lookAt(vantage + side * 3 + up, look) -- dutch and default: plain drift, the lean comes from `roll`
end

-- Called at the impact beat. Returns the camera target for the aftermath (CutsceneFX tweens to it) and the log row.
function M.hit(stage, ctx, center, vantage, side, up)
	local id = M.idOf(ctx.model, ctx.title)
	local plan = id and M.PLAN[id]
	if not plan then return nil end
	local col = ctx.color
	if (col.R + col.G + col.B) / 3 < .25 then col = col:Lerp(C.CREAM, .6) end -- ink-dark familiars (Mourner) would vanish on the dusk street
	local ok, err = pcall(FX[plan.fx], stage, ctx, center, col, plan)
	local still = C.still() or (ctx.settings and ctx.settings.reducedMotion)
	local cf = still and CFrame.lookAt(vantage + side * 3 + up, center + up) or camTarget(plan, vantage, center, side, up)
	if not still and plan.roll then cf = cf * CFrame.Angles(0, 0, math.rad(plan.roll)) end
	table.insert(M.log, { id = id, fx = plan.fx, cam = plan.cam, ok = ok, err = err and tostring(err) or nil })
	C.note((ok and "ult_" or "ultFAIL_") .. id)
	local rx, ry, rz = cf:ToOrientation()
	script:SetAttribute("cam_" .. id, string.format("%s pos(%.0f,%.0f,%.0f) roll %.1f", plan.cam, cf.X - center.X, cf.Y - center.Y, cf.Z - center.Z, math.deg(rz)))
	if not ok then warn("UltFlourish " .. id .. ": " .. tostring(err)) end
	return cf
end

return M
