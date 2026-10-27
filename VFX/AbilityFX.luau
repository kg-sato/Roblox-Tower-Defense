--!nocheck
-- AbilityFX: in-match ability effects. Standalone, client-side, nothing replicates (the server already decided the damage).
-- Source: VFX/AbilityFX.luau, installed as ReplicatedStorage.AbilityFX.
--
--   local AbilityFX = require(game.ReplicatedStorage.AbilityFX)
--   AbilityFX.rend(origin, direction, { length = 40, color = ..., settings = { particles = "Low" } })
--   AbilityFX.audit()   -- plays every settings combination and checks budgets and clean-up
--
-- "Verdant Rend" (original; lessons from the TikTok reference batch, no copied assets):
--   1 wind-up  0.00-0.35 s  three motes spiral in and converge on the caster (reads as "something is coming")
--   2 sweep    0.35-0.60 s  a curved crescent travels down the lane in the attack direction (reads the direction)
--   3 impact   0.60-0.90 s  flat ground ring at the far end + one particle burst (reads the area)
--   4 decay    0.90-1.30 s  shards drift and fade; everything is destroyed by 1.4 s
-- Silhouette first: one hero colour, one near-white core, no screen flash. Sound is part of the timing:
--   vortex on wind-up, surge on sweep, ring on impact (all already uploaded, see AudioIds).
-- Settings (shared with RevealFX.settings): particles Low/Default/High, reducedMotion => no spiral, no shake,
--   ring and fade only; flashes=false => no light flare. Touch devices use the Low budget at most.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local AbilityFX = {}

-- per quality: max parts alive, burst particles, shards, motes
AbilityFX.budget = {
	Low = { parts = 6, particles = 8, shards = 2, motes = 1 },
	Default = { parts = 12, particles = 18, shards = 4, motes = 3 },
	High = { parts = 16, particles = 28, shards = 6, motes = 3 },
}
AbilityFX.duration = 1.4

local okR, RevealFX = pcall(function()
	return require(script.Parent:WaitForChild("RevealFX", 2))
end)
local okS, SoundFX = pcall(function()
	return require(script.Parent:WaitForChild("SoundFX", 2))
end)

local function settings(over)
	local s = { flashes = true, particles = "Default", reducedMotion = false }
	if okR and RevealFX and RevealFX.settings then
		for k, v in pairs(RevealFX.settings) do
			s[k] = v
		end
	end
	if over then
		for k, v in pairs(over) do
			s[k] = v
		end
	end
	return s
end

local function tween(inst, dur, props, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function part(folder, stats, props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = folder
	stats.parts += 1
	return p
end

local function sfx(name, o, stats, silent)
	table.insert(stats.sounds, name)
	if not silent and okS and SoundFX then
		pcall(SoundFX.play, name, o)
	end
end

-- origin: Vector3 (caster, on the ground), dir: Vector3 (lane direction), opts: length, color, settings, headless, forceTouch
function AbilityFX.rend(origin, dir, opts)
	opts = opts or {}
	local S = settings(opts.settings)
	local q = S.particles
	if (opts.forceTouch or UserInputService.TouchEnabled) and q ~= "Low" then
		q = "Low"
	end
	local B = AbilityFX.budget[q] or AbilityFX.budget.Default
	local color = opts.color or Color3.fromRGB(170, 110, 255) -- violet: tested to stand out on the grass map, the sand lane and the white pads
	local core = Color3.fromRGB(225, 200, 255)
	local length = opts.length or 36
	dir = Vector3.new(dir.X, 0, dir.Z)
	dir = dir.Magnitude > 0 and dir.Unit or Vector3.new(0, 0, -1)
	local target = origin + dir * length
	local look = CFrame.lookAt(origin, origin + dir)
	local stats = { parts = 0, particles = 0, sounds = {}, quality = q, phases = {} }
	local silent = opts.headless

	local folder = Instance.new("Folder")
	folder.Name = "AbilityFX_Rend"
	folder.Parent = workspace
	Debris:AddItem(folder, AbilityFX.duration + 0.2)
	local handle = { folder = folder, stats = stats }

	task.spawn(function()
		local t0 = os.clock()
		local function mark(name)
			stats.phases[name] = os.clock() - t0
		end
		-- wait until a time measured from the start, so frame overshoot does not add up across phases
		local function waitUntil(at)
			task.wait(math.max(0, t0 + at - os.clock()))
		end

		-- 1 wind-up
		mark("windup")
		sfx("vortex", { volume = 0.5, length = 0.45 }, stats, silent)
		if not S.reducedMotion then
			for i = 1, B.motes do
				local m = part(folder, stats, { Shape = Enum.PartType.Ball, Size = Vector3.one * 1.1, Color = core })
				local a0 = (i / B.motes) * math.pi * 2
				task.spawn(function()
					local s = os.clock()
					while os.clock() - s < 0.35 and m.Parent do
						local k = (os.clock() - s) / 0.35
						local r = 6 * (1 - k) ^ 2 -- ease in towards the caster
						local a = a0 + k * math.pi * 3
						m.Position = origin + Vector3.new(math.cos(a) * r, 2 + 2 * (1 - k), math.sin(a) * r)
						m.Transparency = 0.6 * (1 - k)
						task.wait()
					end
					m:Destroy()
				end)
			end
		else
			local pre = part(folder, stats, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 4, 4), Color = color, Transparency = 0.6,
				CFrame = CFrame.new(origin + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
			tween(pre, 0.35, { Transparency = 1 })
		end
		waitUntil(0.35)

		-- 2 sweep: a curved crescent (beam between two attachments) slides along the lane
		mark("sweep")
		sfx("surge", { volume = 0.6, length = 0.5 }, stats, silent)
		local carrier = part(folder, stats, { Transparency = 1, Size = Vector3.one * 0.2, CFrame = look + Vector3.new(0, 2, 0) })
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(-6, 0, 0)
		a0.Parent = carrier
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(6, 0, 0)
		a1.Parent = carrier
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, color), ColorSequenceKeypoint.new(0.5, core), ColorSequenceKeypoint.new(1, color) })
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
		beam.LightEmission, beam.FaceCamera, beam.Segments = 1, true, 12
		beam.Width0, beam.Width1 = 4, 4
		beam.CurveSize0, beam.CurveSize1 = 5, -5 -- bows forward into a crescent
		beam.Parent = carrier
		if S.flashes and q ~= "Low" then
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness = color, 12, 2
			light.Parent = carrier
		end
		tween(carrier, 0.25, { CFrame = CFrame.lookAt(target, target + dir) + Vector3.new(0, 2, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		waitUntil(0.6)

		-- 3 impact: ground ring + one burst
		mark("impact")
		sfx("ring", { volume = 0.7 }, stats, silent)
		carrier:Destroy()
		local ring = part(folder, stats, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 2, 2), Color = color, Transparency = 0.15,
			CFrame = CFrame.new(target + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
		tween(ring, 0.3, { Size = Vector3.new(0.2, 14, 14) }, Enum.EasingStyle.Quart)
		tween(ring, 0.5, { Transparency = 1 }, Enum.EasingStyle.Sine)
		local emitterHost = part(folder, stats, { Transparency = 1, Size = Vector3.one * 0.2, CFrame = CFrame.new(target + Vector3.new(0, 1, 0)) })
		local pe = Instance.new("ParticleEmitter")
		pe.Enabled = false
		pe.Color = ColorSequence.new(color, core)
		pe.LightEmission = 1
		pe.Lifetime = NumberRange.new(0.25, 0.45)
		pe.Speed = NumberRange.new(14, 26)
		pe.SpreadAngle = Vector2.new(180, 25)
		pe.Drag = 6
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		pe.Transparency = NumberSequence.new(0.1, 1)
		pe.Parent = emitterHost
		pe:Emit(B.particles)
		stats.particles += B.particles
		waitUntil(0.9)

		-- 4 decay: shards drift up and fade
		mark("decay")
		for i = 1, B.shards do
			local a = (i / B.shards) * math.pi * 2
			local sh = part(folder, stats, { Size = Vector3.new(0.4, 1.2, 0.4), Color = core, Transparency = 0.2,
				CFrame = CFrame.new(target + Vector3.new(math.cos(a) * 3, 0.8, math.sin(a) * 3)) * CFrame.Angles(0, a, 0.4) })
			local up = S.reducedMotion and 0 or 2.5
			tween(sh, 0.4, { Transparency = 1, CFrame = sh.CFrame + Vector3.new(0, up, 0) }, Enum.EasingStyle.Sine)
		end
		waitUntil(1.32)
		mark("done")
		stats.peakAlive = stats.parts
		folder:Destroy()
	end)
	return handle
end

-- In-engine audit: every quality x reducedMotion x touch combination. Checks the part/particle budget, the phase timing
-- (within 60 ms of the spec), that the three cue sounds fire in order, and that nothing is left in Workspace.
function AbilityFX.audit()
	local results, allOk = {}, true
	local spec = { windup = 0, sweep = 0.35, impact = 0.6, decay = 0.9 }
	local handles = {}
	for _, q in { "Low", "Default", "High" } do
		for _, reduced in { false, true } do
			for _, touch in { false, true } do
				local h = AbilityFX.rend(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), { headless = true, forceTouch = touch,
					settings = { particles = q, reducedMotion = reduced } })
				table.insert(handles, { h = h, q = q, reduced = reduced, touch = touch })
			end
		end
	end
	task.wait(AbilityFX.duration + 0.4)
	for _, e in handles do
		local s, bad = e.h.stats, {}
		local B = AbilityFX.budget[s.quality]
		if s.parts > B.parts then
			table.insert(bad, ("parts %d > %d"):format(s.parts, B.parts))
		end
		if s.particles > B.particles then
			table.insert(bad, ("particles %d > %d"):format(s.particles, B.particles))
		end
		if e.touch and s.quality ~= "Low" then
			table.insert(bad, "touch not Low")
		end
		for name, at in spec do
			local got = s.phases[name]
			if not got or math.abs(got - at) > 0.06 then
				table.insert(bad, ("%s at %s (want %.2f)"):format(name, tostring(got and ("%.3f"):format(got)), at))
			end
		end
		if table.concat(s.sounds, ",") ~= "vortex,surge,ring" then
			table.insert(bad, "sounds " .. table.concat(s.sounds, ","))
		end
		if e.h.folder.Parent then
			table.insert(bad, "not cleaned up")
		end
		allOk = allOk and #bad == 0
		table.insert(results, ("%s %-7s reduced=%-5s touch=%-5s parts=%d particles=%d done=%.2fs %s"):format(#bad == 0 and "PASS" or "FAIL",
			e.q, tostring(e.reduced), tostring(e.touch), s.parts, s.particles, s.phases.done or -1, table.concat(bad, "; ")))
	end
	return allOk, table.concat(results, "\n")
end

return AbilityFX
