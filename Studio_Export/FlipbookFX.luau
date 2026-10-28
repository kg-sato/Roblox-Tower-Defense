--!nocheck
-- FlipbookFX: plays flipbook effects in the world and in UI. No uploads: templates use Roblox's built-in particle textures
-- until real sheets have asset ids (a ParticleEmitter cannot show an EditableImage, see Overnight/evidence/T18.txt).
-- Install as ReplicatedStorage.FlipbookFX (HTTP pull from VFX/, like CutsceneFX). Clients render; the server only says
-- which effect and where.
--
--   FlipbookFX.define(name, spec)          -- template in ReplicatedStorage.Effects (spec: texture, grid, lifetime, size,
--                                          --   color, light, orientation, zOffset, emitCount, emitDelay, emitDuration)
--   local h = FlipbookFX.play(name, cframe, { scale, color, loop, parent }) -- h.stop(); one-shots clean themselves up
--   FlipbookFX.emit(instance)              -- play every emitter under it by its EmitCount / EmitDelay / EmitDuration
--   FlipbookFX.resize(instance, k)         -- Size, Speed and part sizes x k
--   FlipbookFX.recolor(instance, color)    -- emitters, beams and trails
--   local stop = FlipbookFX.ui(imageLabel, { image, grid, sheetSize, seconds, loop })
--
-- Emitter recipe (Roblox docs and the ParticleFX Studio guide): Rate 0, Clear() then Emit(1) per play, Lifetime Min = Max,
-- LightInfluence 0, LockedToPart, FlipbookMode OneShot. One-shots are removed at Debris(lifetime + delay + duration + 1).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FlipbookFX = {}
FlipbookFX.frozen = false -- tests set this to hold effects on screen; clean-up waits until it is false again

-- Remove `inst` after `t` seconds, but never while frozen (freeze-frame captures).
local function later(inst, t)
	task.delay(t, function()
		while FlipbookFX.frozen do
			task.wait(0.1)
		end
		inst:Destroy()
	end)
end

local GRIDS = {
	[1] = Enum.ParticleFlipbookLayout.None,
	[2] = Enum.ParticleFlipbookLayout.Grid2x2,
	[4] = Enum.ParticleFlipbookLayout.Grid4x4,
	[8] = Enum.ParticleFlipbookLayout.Grid8x8,
}

function FlipbookFX.registry(): Folder
	local f = ReplicatedStorage:FindFirstChild("Effects")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Effects"
		f.Parent = ReplicatedStorage
	end
	return f
end

local function emitterFrom(spec)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = spec.texture or "rbxasset://textures/particles/sparkles_main.dds"
	pe.FlipbookLayout = GRIDS[spec.grid or 1] or Enum.ParticleFlipbookLayout.None
	pe.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	local life = spec.lifetime or 0.6
	pe.Lifetime = NumberRange.new(life, life)
	pe.Rate = 0
	pe.Speed = NumberRange.new(spec.speed or 0)
	pe.SpreadAngle = Vector2.new(spec.spread or 0, spec.spread or 0)
	pe.Size = NumberSequence.new(spec.size or 6)
	pe.Color = ColorSequence.new(spec.color or Color3.new(1, 1, 1))
	pe.LightEmission = spec.light == nil and 1 or spec.light
	pe.LightInfluence = 0
	pe.ZOffset = spec.zOffset or 1
	pe.Orientation = spec.orientation or Enum.ParticleOrientation.FacingCamera
	pe.LockedToPart = true
	-- full curves (ported recipes): keypoint lists { time, value, envelope } and colour { time, r, g, b, envelope }
	local function seq(keys)
		local kps = {}
		for _, k in keys do
			table.insert(kps, NumberSequenceKeypoint.new(k[1], k[2], k[3] or 0))
		end
		return NumberSequence.new(kps)
	end
	if spec.sizeKeys then
		pe.Size = seq(spec.sizeKeys)
	end
	if spec.transparencyKeys then
		pe.Transparency = seq(spec.transparencyKeys)
	end
	if spec.squashKeys then
		pe.Squash = seq(spec.squashKeys)
	end
	if spec.colorKeys then
		local kps = {}
		for _, k in spec.colorKeys do
			table.insert(kps, ColorSequenceKeypoint.new(k[1], Color3.new(k[2], k[3], k[4])))
		end
		pe.Color = ColorSequence.new(kps)
	end
	if spec.lifeRange then
		pe.Lifetime = NumberRange.new(spec.lifeRange[1], spec.lifeRange[2])
	end
	if spec.speedRange then
		pe.Speed = NumberRange.new(spec.speedRange[1], spec.speedRange[2])
	end
	if spec.rotation then
		pe.Rotation = NumberRange.new(spec.rotation[1], spec.rotation[2])
	end
	if spec.rotSpeed then
		pe.RotSpeed = NumberRange.new(spec.rotSpeed[1], spec.rotSpeed[2])
	end
	if spec.spread2 then
		pe.SpreadAngle = Vector2.new(spec.spread2[1], spec.spread2[2])
	end
	if spec.drag then
		pe.Drag = spec.drag
	end
	if spec.timeScale then
		pe.TimeScale = spec.timeScale
	end
	pe:SetAttribute("EmitCount", spec.emitCount or 1)
	pe:SetAttribute("EmitDelay", spec.emitDelay or 0)
	pe:SetAttribute("EmitDuration", spec.emitDuration or 0)
	return pe
end

-- A template is an Attachment holding one emitter per layer (spec.layers, or the spec itself as one layer).
function FlipbookFX.define(name: string, spec)
	local reg = FlipbookFX.registry()
	local old = reg:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local a = Instance.new("Attachment")
	a.Name = name
	for i, layer in spec.layers or { spec } do
		local pe = emitterFrom(layer)
		pe.Name = layer.name or ("Layer" .. i)
		pe.Parent = a
	end
	a.Parent = reg
	return a
end

local function lifeOf(inst): number
	local longest = 0
	for _, d in inst:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			local t = d.Lifetime.Max + (d:GetAttribute("EmitDelay") or 0) + (d:GetAttribute("EmitDuration") or 0)
			longest = math.max(longest, t)
		end
	end
	return longest
end

local function emitOne(pe: ParticleEmitter)
	local count = pe:GetAttribute("EmitCount") or 1
	local delay = pe:GetAttribute("EmitDelay") or 0
	local duration = pe:GetAttribute("EmitDuration") or 0
	local function go()
		if not pe.Parent then
			return
		end
		if duration > 0 then
			-- spread the count over the duration (a short burst stream instead of one pop)
			pe.Rate = count / duration
			pe.Enabled = true
			task.delay(duration, function()
				if pe.Parent then
					pe.Enabled = false
					pe.Rate = 0
				end
			end)
		else
			pe:Clear()
			pe:Emit(count)
		end
	end
	if delay > 0 then
		task.delay(delay, go)
	else
		go()
	end
end

function FlipbookFX.emit(inst: Instance)
	if inst:IsA("ParticleEmitter") then
		emitOne(inst)
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			emitOne(d)
		end
	end
end

function FlipbookFX.resize(inst: Instance, k: number)
	local function scaleSeq(seq: NumberSequence)
		local kps = {}
		for _, kp in seq.Keypoints do
			table.insert(kps, NumberSequenceKeypoint.new(kp.Time, kp.Value * k, kp.Envelope * k))
		end
		return NumberSequence.new(kps)
	end
	for _, d in { inst, table.unpack(inst:GetDescendants()) } do
		if d:IsA("ParticleEmitter") then
			d.Size = scaleSeq(d.Size)
			d.Speed = NumberRange.new(d.Speed.Min * k, d.Speed.Max * k)
		elseif d:IsA("Beam") then
			d.Width0, d.Width1 = d.Width0 * k, d.Width1 * k
		elseif d:IsA("BasePart") and d.Name ~= "FlipbookAnchor" then
			d.Size *= k
		end
	end
end

function FlipbookFX.recolor(inst: Instance, color: Color3)
	for _, d in { inst, table.unpack(inst:GetDescendants()) } do
		if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
			d.Color = ColorSequence.new(color)
		end
	end
end

local holder
local function worldFolder()
	if not holder or not holder.Parent then
		holder = workspace:FindFirstChild("FlipbookFX") or Instance.new("Folder")
		holder.Name = "FlipbookFX"
		holder.Parent = workspace
	end
	return holder
end

-- Play a registry effect (or any template instance) at a CFrame. Returns { stop = function, anchor = Part }.
function FlipbookFX.play(name, cf: CFrame, opts)
	opts = opts or {}
	local template = typeof(name) == "Instance" and name or FlipbookFX.registry():FindFirstChild(name)
	if not template then
		warn("FlipbookFX: no effect named " .. tostring(name))
		return { stop = function() end }
	end
	local anchor = Instance.new("Part")
	anchor.Name = "FlipbookAnchor"
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.CFrame = cf
	local fx = template:Clone()
	fx.Parent = anchor
	if opts.scale and opts.scale ~= 1 then
		FlipbookFX.resize(fx, opts.scale)
	end
	if opts.color then
		FlipbookFX.recolor(fx, opts.color)
	end
	anchor.Parent = opts.parent or worldFolder()
	local life = lifeOf(fx)
	local stopped = false
	local function stop()
		if stopped then
			return
		end
		stopped = true
		for _, d in fx:GetDescendants() do
			if d:IsA("ParticleEmitter") then
				d.Enabled = false
			end
		end
		later(anchor, life + 1)
	end
	FlipbookFX.emit(fx)
	if opts.loop then
		task.spawn(function()
			while not stopped and anchor.Parent do
				task.wait(math.max(life, 0.1))
				if not stopped then
					FlipbookFX.emit(fx)
				end
			end
		end)
	else
		later(anchor, math.ceil(life) + 1)
	end
	return { stop = stop, anchor = anchor }
end

-- UI flipbook: step ImageRectOffset through a grid sheet. Returns stop().
function FlipbookFX.ui(label: ImageLabel, opts)
	local grid = opts.grid or 8
	local sheet = opts.sheetSize or 1024
	local frames = opts.frames or grid * grid
	local seconds = opts.seconds or 1
	local cell = sheet / grid
	if opts.image then
		label.Image = opts.image
	end
	label.ImageRectSize = Vector2.new(cell, cell)
	local t0 = os.clock()
	local conn
	local function stop()
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end
	local function show(i)
		label.ImageRectOffset = Vector2.new((i % grid) * cell, math.floor(i / grid) * cell)
	end
	show(0)
	conn = RunService.Heartbeat:Connect(function()
		if not label.Parent then
			stop()
			return
		end
		local i = math.floor((os.clock() - t0) / seconds * frames)
		if i >= frames then
			if opts.loop then
				t0 = os.clock()
				i = 0
			else
				show(frames - 1)
				stop()
				if opts.onDone then
					opts.onDone()
				end
				return
			end
		end
		show(i)
	end)
	return stop
end

-- Starter effects so the kit works with no uploads (built-in textures; swap in real sheets later).
function FlipbookFX.defineDefaults()
	FlipbookFX.define("Sparkle", { texture = "rbxasset://textures/particles/sparkles_main.dds", lifetime = 0.6, size = 3, emitCount = 6, speed = 6, spread = 180 })
	FlipbookFX.define("Smoke", { texture = "rbxasset://textures/particles/smoke_main.dds", lifetime = 1, size = 4, light = 0, emitCount = 4, speed = 2, spread = 60, color = Color3.fromRGB(150, 140, 160) })
	FlipbookFX.define("Ember", { layers = {
		{ name = "Flash", texture = "rbxasset://textures/particles/sparkles_main.dds", lifetime = 0.25, size = 6, emitCount = 1, zOffset = 2 },
		{ name = "Fire", texture = "rbxasset://textures/particles/fire_main.dds", lifetime = 0.7, size = 3, emitCount = 5, speed = 4, spread = 90, emitDelay = 0.05, color = Color3.fromRGB(255, 170, 80) },
		{ name = "Trail", texture = "rbxasset://textures/particles/sparkles_main.dds", lifetime = 0.5, size = 1.2, emitCount = 10, emitDuration = 0.3, speed = 8, spread = 180 },
	} })
end

-- Studio audit: spawn n effects and check that parts and emitters return to the baseline after lifetime + 1.
function FlipbookFX.audit(n)
	FlipbookFX.defineDefaults()
	local function count()
		local parts, emitters = 0, 0
		for _, d in workspace:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
			elseif d:IsA("ParticleEmitter") then
				emitters += 1
			end
		end
		return parts, emitters
	end
	local p0, e0 = count()
	local names = { "Sparkle", "Smoke", "Ember" }
	local longest = 0
	for i = 1, n do
		local name = names[(i - 1) % #names + 1]
		longest = math.max(longest, lifeOf(FlipbookFX.registry()[name]))
		FlipbookFX.play(name, CFrame.new((i % 5) * 4 - 8, 6, math.floor(i / 5) * 4 - 8), { scale = 1 + (i % 3) * 0.25, color = i % 2 == 0 and Color3.fromRGB(180, 140, 255) or nil })
	end
	local p1, e1 = count()
	local loop = FlipbookFX.play("Sparkle", CFrame.new(0, 8, 0), { loop = true })
	task.wait(1.5)
	local p2, e2 = count()
	loop.stop()
	task.wait(math.ceil(longest) + 1.6)
	local p3, e3 = count()
	return {
		baseline = { p0, e0 }, spawned = { p1, e1 }, withLoop = { p2, e2 }, after = { p3, e3 }, longest = longest,
		ok = p3 == p0 and e3 == e0 and p1 == p0 + n and e1 > e0,
	}
end

return FlipbookFX
