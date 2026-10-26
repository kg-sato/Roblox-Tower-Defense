--!nocheck
-- AnimKit: the Roblox Studio half of the fwjelaa animation method.
-- Put this ModuleScript in ServerStorage (name it AnimKit) and require it from the command bar:
--     local AnimKit = require(game.ServerStorage.AnimKit)
--
-- It does four things:
--   1. AnimKit.new(...)       write an animation in code, straight in Studio (Studio MCP path)
--   2. AnimKit.fromData(...)  turn a Blender export (out/<Name>.json) into a KeyframeSequence
--   3. AnimKit.dummy(...)     a test rig (R6 or R15) with the exact joints of a real character
--   4. AnimKit.preview(...)   play or scrub an animation in Edit mode, without publishing
-- and AnimKit.save(...) files the KeyframeSequence where the Animation Editor and Moon Animator 2
-- find it (ServerStorage.RBX_ANIMSAVES.<rig name>).
--
-- Pose language (same as kit/animkit.py): every joint gets {x, y, z} degrees, applied like
-- CFrame.Angles(rad(x), rad(y), rad(z)) in the PARENT part's axes (X right, Y up, Z back).
-- Add {x, y, z, px, py, pz} to also move the joint in studs (only useful on the root joint:
-- Torso on R6, LowerTorso on R15).
--   +x  arm/leg swings FORWARD, head looks UP, torso leans BACK
--   +y  turns to the character's LEFT
--   +z  right arm/leg OUT; left arm/leg ACROSS the body (use -z for left out)

local TweenService = game:GetService("TweenService")
local AnimationClipProvider = game:GetService("AnimationClipProvider")
local ServerStorage = game:GetService("ServerStorage")

local AnimKit = {}

---------------------------------------------------------------------------------------------------
-- Rigs (numbers measured in Studio, identical to kit/rigs.py)
---------------------------------------------------------------------------------------------------

local function rot(...)
	return CFrame.new(0, 0, 0, ...)
end
local R6_ROOT = rot(-1, 0, 0, 0, 0, 1, 0, 1, 0)
local R6_R = rot(0, 0, 1, 0, 1, 0, -1, 0, 0)
local R6_L = rot(0, 0, -1, 0, 1, 0, 1, 0, 0)

local function joint(motor, p0, p1, c0, c1)
	return { motor = motor, p0 = p0, p1 = p1, c0 = c0, c1 = c1 }
end

local YELLOW = Color3.fromRGB(245, 205, 48)
local BLUE = Color3.fromRGB(13, 105, 172)
local GREEN = Color3.fromRGB(164, 189, 71)

AnimKit.Rigs = {
	R6 = {
		root = "HumanoidRootPart",
		rootJoint = "Torso",
		hipHeight = 3,
		humanoidHipHeight = 0,
		sizes = {
			HumanoidRootPart = Vector3.new(2, 2, 1),
			Torso = Vector3.new(2, 2, 1),
			Head = Vector3.new(2, 1, 1),
			["Right Arm"] = Vector3.new(1, 2, 1),
			["Left Arm"] = Vector3.new(1, 2, 1),
			["Right Leg"] = Vector3.new(1, 2, 1),
			["Left Leg"] = Vector3.new(1, 2, 1),
		},
		joints = {
			joint("RootJoint", "HumanoidRootPart", "Torso", R6_ROOT, R6_ROOT),
			joint("Neck", "Torso", "Head", CFrame.new(0, 1, 0) * R6_ROOT, CFrame.new(0, -0.5, 0) * R6_ROOT),
			joint("Right Shoulder", "Torso", "Right Arm", CFrame.new(1, 0.5, 0) * R6_R, CFrame.new(-0.5, 0.5, 0) * R6_R),
			joint("Left Shoulder", "Torso", "Left Arm", CFrame.new(-1, 0.5, 0) * R6_L, CFrame.new(0.5, 0.5, 0) * R6_L),
			joint("Right Hip", "Torso", "Right Leg", CFrame.new(1, -1, 0) * R6_R, CFrame.new(0.5, 1, 0) * R6_R),
			joint("Left Hip", "Torso", "Left Leg", CFrame.new(-1, -1, 0) * R6_L, CFrame.new(-0.5, 1, 0) * R6_L),
		},
		colors = {
			Torso = BLUE, Head = YELLOW, ["Right Arm"] = YELLOW, ["Left Arm"] = YELLOW,
			["Right Leg"] = GREEN, ["Left Leg"] = GREEN,
		},
	},
}

do -- block R15, from the rig attachments of a BodyTypeScale 0 / ProportionScale 0 character
	local sizes = {
		HumanoidRootPart = Vector3.new(2, 2, 1),
		LowerTorso = Vector3.new(2, 0.4, 1),
		UpperTorso = Vector3.new(2, 1.6, 1),
		Head = Vector3.new(1.2, 1.2, 1.2),
	}
	local joints = {
		joint("Root", "HumanoidRootPart", "LowerTorso", CFrame.new(0, -1, 0), CFrame.new(0, -0.2, 0)),
		joint("Waist", "LowerTorso", "UpperTorso", CFrame.new(0, 0.2, 0), CFrame.new(0, -0.8, 0)),
		joint("Neck", "UpperTorso", "Head", CFrame.new(0, 0.8, 0), CFrame.new(0, -0.586, 0)),
	}
	local colors = { LowerTorso = BLUE, UpperTorso = BLUE, Head = YELLOW }
	for _, sideInfo in ipairs({ { "Right", 1 }, { "Left", -1 } }) do
		local side, s = sideInfo[1], sideInfo[2]
		sizes[side .. "UpperArm"] = Vector3.new(1, 1.169, 1)
		sizes[side .. "LowerArm"] = Vector3.new(1, 1.052, 1)
		sizes[side .. "Hand"] = Vector3.new(1, 0.3, 1)
		sizes[side .. "UpperLeg"] = Vector3.new(1, 1.217, 1)
		sizes[side .. "LowerLeg"] = Vector3.new(1, 1.193, 1)
		sizes[side .. "Foot"] = Vector3.new(1, 0.3, 1)
		table.insert(joints, joint(side .. "Shoulder", "UpperTorso", side .. "UpperArm", CFrame.new(s, 0.563, 0), CFrame.new(-0.5 * s, 0.394, 0)))
		table.insert(joints, joint(side .. "Elbow", side .. "UpperArm", side .. "LowerArm", CFrame.new(0, -0.334, 0), CFrame.new(0, 0.259, 0)))
		table.insert(joints, joint(side .. "Wrist", side .. "LowerArm", side .. "Hand", CFrame.new(0, -0.501, 0), CFrame.new(0, 0.125, 0)))
		table.insert(joints, joint(side .. "Hip", "LowerTorso", side .. "UpperLeg", CFrame.new(0.5 * s, -0.2, 0), CFrame.new(0, 0.421, 0)))
		table.insert(joints, joint(side .. "Knee", side .. "UpperLeg", side .. "LowerLeg", CFrame.new(0, -0.401, 0), CFrame.new(0, 0.379, 0)))
		table.insert(joints, joint(side .. "Ankle", side .. "LowerLeg", side .. "Foot", CFrame.new(0, -0.547, 0), CFrame.new(0, 0.102, 0)))
		for _, p in ipairs({ "UpperArm", "LowerArm", "Hand" }) do
			colors[side .. p] = YELLOW
		end
		for _, p in ipairs({ "UpperLeg", "LowerLeg", "Foot" }) do
			colors[side .. p] = GREEN
		end
	end
	AnimKit.Rigs.R15 = {
		root = "HumanoidRootPart",
		rootJoint = "LowerTorso",
		hipHeight = 3,
		humanoidHipHeight = 2,
		sizes = sizes,
		joints = joints,
		colors = colors,
	}
end

-- Props (weapons) hang off the right hand through an extra Motor6D; the Pose is named after the prop part
-- ("Handle", like a Tool). The business end is the prop's +Y, pointing forward when the arm hangs down;
-- `grip` is how far below the part's centre the hand holds it. Same numbers as kit/rigs.py.
local HAND = {
	R6 = { "Right Arm", CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0) },
	R15 = { "RightHand", CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(-90), 0, 0) },
}
local function prop(size, grip)
	return { part = "Handle", size = size, c1 = CFrame.new(0, -grip, 0), attach = HAND }
end
AnimKit.Props = {
	Sword = prop(Vector3.new(0.3, 4.2, 0.3), 1.3),
	Spear = prop(Vector3.new(0.3, 8, 0.3), 2.2),
	Dagger = prop(Vector3.new(0.2, 1.8, 0.2), 0.55),
	Axe = prop(Vector3.new(0.3, 3.6, 0.3), 1.2),
}

local function rigWith(rigName, props)
	local base = AnimKit.Rigs[rigName]
	assert(base, "unknown rig " .. tostring(rigName) .. " (use R6 or R15)")
	local rig = table.clone(base)
	rig.joints = table.clone(base.joints)
	rig.sizes = table.clone(base.sizes)
	for _, propName in ipairs(props or {}) do
		local p = assert(AnimKit.Props[propName], "unknown prop " .. tostring(propName))
		local attach = p.attach[rigName]
		table.insert(rig.joints, joint(p.part, attach[1], p.part, attach[2], p.c1))
		rig.sizes[p.part] = p.size
	end
	rig.parentOf = {}
	rig.jointOf = {}
	for _, j in ipairs(rig.joints) do
		rig.parentOf[j.p1] = j.p0
		rig.jointOf[j.p1] = j
	end
	return rig
end
AnimKit.rigWith = rigWith

---------------------------------------------------------------------------------------------------
-- Pose language and easing (measured in Studio)
---------------------------------------------------------------------------------------------------

-- Pose.CFrame (= Motor6D.Transform) for a pose-language value on one joint.
function AnimKit.poseCFrame(rig, part, v)
	local j = assert(rig.jointOf[part], tostring(part) .. " is not an animatable joint")
	local r = j.c0.Rotation
	local q = CFrame.Angles(math.rad(v[1] or 0), math.rad(v[2] or 0), math.rad(v[3] or 0))
	local t = CFrame.new(v[4] or 0, v[5] or 0, v[6] or 0)
	return r:Inverse() * t * q * r
end

-- A Pose's easing shapes the move FROM it to the next pose. Constant+Out = hold; Constant+In snaps
-- to the next pose at once. Legacy Cubic has In/Out swapped, so cubic eases use CubicV2.
AnimKit.Eases = {
	linear = { "Linear", "In" },
	constant = { "Constant", "Out" },
	cubic_in = { "CubicV2", "In" },
	cubic_out = { "CubicV2", "Out" },
	cubic_inout = { "CubicV2", "InOut" },
	elastic_out = { "Elastic", "Out" },
	bounce_out = { "Bounce", "Out" },
	-- not in Roblox's pose easing: baked into in-betweens with TweenService curves
	sine_inout = { bake = { Enum.EasingStyle.Sine, Enum.EasingDirection.InOut } },
	quad_in = { bake = { Enum.EasingStyle.Quad, Enum.EasingDirection.In } },
	quad_out = { bake = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out } },
	quart_out = { bake = { Enum.EasingStyle.Quart, Enum.EasingDirection.Out } },
	quint_out = { bake = { Enum.EasingStyle.Quint, Enum.EasingDirection.Out } },
	expo_in = { bake = { Enum.EasingStyle.Exponential, Enum.EasingDirection.In } },
	expo_out = { bake = { Enum.EasingStyle.Exponential, Enum.EasingDirection.Out } },
	back_out = { bake = { Enum.EasingStyle.Back, Enum.EasingDirection.Out } },
}
local BAKE_STEP = 2 -- frames between baked in-betweens

local function bounceOut(t)
	if t < 1 / 2.75 then
		return 7.5625 * t * t
	elseif t < 2 / 2.75 then
		t -= 1.5 / 2.75
		return 7.5625 * t * t + 0.75
	elseif t < 2.5 / 2.75 then
		t -= 2.25 / 2.75
		return 7.5625 * t * t + 0.9375
	end
	t -= 2.625 / 2.75
	return 7.5625 * t * t + 0.984375
end

local function elasticOut(t) -- Roblox's pose Elastic: period 0.3 (TweenService's differs)
	if t <= 0 then
		return 0
	elseif t >= 1 then
		return 1
	end
	return 2 ^ (-10 * t) * math.sin((t - 0.075) * 2 * math.pi / 0.3) + 1
end

-- How far between two poses Roblox is at t (0..1) for an ease name.
local function alpha(easeName, t)
	local e = AnimKit.Eases[easeName]
	if e.bake then
		return TweenService:GetValue(t, e.bake[1], e.bake[2])
	end
	local style, dir = e[1], e[2]
	if style == "Linear" then
		return t
	elseif style == "Constant" then
		return t >= 1 and 1 or 0
	elseif style == "CubicV2" then
		return TweenService:GetValue(t, Enum.EasingStyle.Cubic, Enum.EasingDirection[dir])
	elseif style == "Bounce" then
		return dir == "Out" and bounceOut(t) or 1 - bounceOut(1 - t)
	elseif style == "Elastic" then
		return dir == "Out" and elasticOut(t) or 1 - elasticOut(1 - t)
	end
	error("no curve for " .. easeName)
end

---------------------------------------------------------------------------------------------------
-- Building KeyframeSequences
---------------------------------------------------------------------------------------------------

-- frames: { [frame] = { poses = { [part] = {cf, style, dir} }, markers = { {name, value} } } }
local function assemble(name, loop, priority, fps, parentOf, rootName, frames)
	local kfs = Instance.new("KeyframeSequence")
	kfs.Name = name
	kfs.Loop = loop
	kfs.Priority = Enum.AnimationPriority[priority]
	local order = {}
	for f in pairs(frames) do
		table.insert(order, f)
	end
	table.sort(order)
	for _, f in ipairs(order) do
		local data = frames[f]
		local kf = Instance.new("Keyframe")
		kf.Time = math.floor(f / fps * 1e5) / 1e5 -- rounded down so a Constant hold snaps on its own frame
		local made = {}
		local function poseFor(part)
			if made[part] then
				return made[part]
			end
			local p = Instance.new("Pose")
			p.Name = part
			p.Weight = 0 -- placeholder: measured to be ignored by playback
			local parent = parentOf[part]
			p.Parent = parent and poseFor(parent) or kf
			made[part] = p
			return p
		end
		for part, pose in pairs(data.poses or {}) do
			local p = poseFor(part)
			p.CFrame = pose[1]
			p.EasingStyle = Enum.PoseEasingStyle[pose[2]]
			p.EasingDirection = Enum.PoseEasingDirection[pose[3]]
			p.Weight = 1
		end
		if not made[rootName] and next(data.poses or {}) then
			poseFor(rootName)
		end
		for _, m in ipairs(data.markers or {}) do
			local marker = Instance.new("KeyframeMarker")
			marker.Name = m[1]
			marker.Value = m[2] or ""
			marker.Parent = kf
		end
		kf.Parent = kfs
	end
	return kfs
end

-- Blender export (out/<Name>.json, already decoded) -> KeyframeSequence
function AnimKit.fromData(data)
	local frames = {}
	for _, k in ipairs(data.keyframes) do
		local f = math.round(k.time * data.fps)
		local entry = { poses = {}, markers = k.markers }
		for part, pose in pairs(k.poses) do
			entry.poses[part] = { CFrame.new(table.unpack(pose.cf)), pose.style, pose.dir }
		end
		frames[f] = entry
	end
	return assemble(data.name, data.loop, data.priority, data.fps, data.parents, data.root, frames)
end

---------------------------------------------------------------------------------------------------
-- Writing animations in code (Studio MCP path)
---------------------------------------------------------------------------------------------------

local Anim = {}
Anim.__index = Anim

-- AnimKit.new("R6_Punch", {rig = "R6", length = 30, fps = 60, loop = false, priority = "Action", props = {"Sword"}})
function AnimKit.new(name, opts)
	opts = opts or {}
	local self = setmetatable({}, Anim)
	self.name = name
	self.rigName = opts.rig or "R6"
	self.props = opts.props or {}
	self.length = opts.length or 60
	self.fps = opts.fps or 60
	self.loop = opts.loop == true
	self.priority = opts.priority or "Action"
	self.rig = rigWith(self.rigName, self.props)
	self.keys = {} -- { frame, joint, value, ease }
	self.markers = {}
	return self
end

function Anim:key(frame, pose, ease)
	ease = ease or "cubic_inout"
	assert(AnimKit.Eases[ease], "unknown ease " .. tostring(ease))
	for part, v in pairs(pose) do
		assert(self.rig.jointOf[part], tostring(part) .. " is not an animatable joint of " .. self.rigName)
		assert(#v == 3 or #v == 6, part .. ": give {x, y, z} or {x, y, z, px, py, pz}")
		for i = #self.keys, 1, -1 do
			if self.keys[i][1] == frame and self.keys[i][2] == part then
				table.remove(self.keys, i)
			end
		end
		table.insert(self.keys, { frame, part, v, ease })
	end
	return self
end

function Anim:valueAt(part, frame)
	local best, bestF = { 0, 0, 0 }, -math.huge
	for _, k in ipairs(self.keys) do
		if k[2] == part and k[1] <= frame and k[1] > bestF then
			best, bestF = k[3], k[1]
		end
	end
	return best
end

function Anim:joints()
	local list = {}
	for _, j in ipairs(self.rig.joints) do
		table.insert(list, j.p1)
	end
	return list
end

-- Key every joint: listed ones get the new value, the rest keep their last keyed value.
function Anim:full(frame, pose, ease)
	local all = {}
	for _, part in ipairs(self:joints()) do
		all[part] = pose[part] or self:valueAt(part, frame)
	end
	return self:key(frame, all, ease)
end

function Anim:hold(frame, untilFrame, ease)
	local all = {}
	for _, part in ipairs(self:joints()) do
		all[part] = self:valueAt(part, frame)
	end
	return self:key(untilFrame, all, ease)
end

-- Overlap / follow-through: delay one joint's keys (wraps around on loops).
function Anim:offset(part, frames)
	local kept = {}
	for _, k in ipairs(self.keys) do
		if k[2] == part then
			if not (self.loop and k[1] == self.length) then
				local f = k[1] + frames
				f = self.loop and (f % self.length) or math.clamp(f, 0, self.length)
				table.insert(kept, { f, k[2], k[3], k[4] })
			end
		else
			table.insert(kept, k)
		end
	end
	self.keys = kept
	return self
end

function Anim:marker(frame, name, value)
	table.insert(self.markers, { frame, name, tostring(value or "") })
	return self
end

function Anim:_track(part)
	local track = {}
	for _, k in ipairs(self.keys) do
		if k[2] == part then
			table.insert(track, k)
		end
	end
	table.sort(track, function(a, b)
		return a[1] < b[1]
	end)
	if self.loop and #track > 0 then -- periodic: repeat the cycle once before and after
		local L = self.length
		local period = {}
		local hasZero = false
		for _, k in ipairs(track) do
			hasZero = hasZero or k[1] == 0
		end
		for _, k in ipairs(track) do
			if k[1] >= 0 and k[1] < L then
				table.insert(period, k)
			elseif k[1] == L and not hasZero then
				table.insert(period, 1, { 0, k[2], k[3], k[4] })
			end
		end
		track = {}
		for _, shift in ipairs({ -L, 0, L }) do
			for _, k in ipairs(period) do
				table.insert(track, { k[1] + shift, k[2], k[3], k[4] })
			end
		end
	end
	return track
end

function Anim:_evaluate(track, frame)
	for i = 1, #track - 1 do
		local a, b = track[i], track[i + 1]
		if frame >= a[1] and frame <= b[1] then
			local ca = AnimKit.poseCFrame(self.rig, a[2], a[3])
			local cb = AnimKit.poseCFrame(self.rig, b[2], b[3])
			if b[1] == a[1] then
				return cb
			end
			return ca:Lerp(cb, alpha(a[4], (frame - a[1]) / (b[1] - a[1])))
		end
	end
	local edge = frame <= track[1][1] and track[1] or track[#track]
	return AnimKit.poseCFrame(self.rig, edge[2], edge[3])
end

function Anim:build()
	local frames = {}
	local function put(f, part, cf, style, dir)
		frames[f] = frames[f] or { poses = {}, markers = {} }
		frames[f].poses[part] = { cf, style, dir }
	end
	local L = self.length
	for _, part in ipairs(self:joints()) do
		local track = self:_track(part)
		if #track > 0 then
			for i = 1, #track - 1 do
				local a, b = track[i], track[i + 1]
				local e = AnimKit.Eases[a[4]]
				local inside = a[1] >= 0 and b[1] <= L
				if inside and not e.bake then
					put(a[1], part, AnimKit.poseCFrame(self.rig, part, a[3]), e[1], e[2])
				else
					local from, to = math.max(a[1], 0), math.min(b[1], L)
					for f = from, to - 1, BAKE_STEP do
						put(f, part, self:_evaluate(track, f), "Linear", "In")
					end
				end
			end
			local lastF = math.min(track[#track][1], L)
			put(lastF, part, self:_evaluate(track, lastF), "Linear", "In")
		end
	end
	for _, m in ipairs(self.markers) do
		frames[m[1]] = frames[m[1]] or { poses = {}, markers = {} }
		table.insert(frames[m[1]].markers, { m[2], m[3] })
	end
	return assemble(self.name, self.loop, self.priority, self.fps, self.rig.parentOf, self.rig.root, frames)
end

---------------------------------------------------------------------------------------------------
-- Test rigs, props, saving, previewing
---------------------------------------------------------------------------------------------------

-- A test character with the exact joints of a real one. AnimKit.dummy("R6", CFrame.new(0, 0, -10))
-- puts it standing on y = 0 there (Moon Animator 2 and the Animation Editor can both use it).
function AnimKit.dummy(rigName, where, props, name)
	local rig = rigWith(rigName, props)
	local model = Instance.new("Model")
	model.Name = name or (rigName .. "Dummy")
	local parts = {}
	for partName, size in pairs(rig.sizes) do
		local p = Instance.new("Part")
		p.Name = partName
		p.Size = size
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Color = rig.colors[partName] or Color3.fromRGB(200, 200, 200)
		p.CanCollide = false
		p.Parent = model
		parts[partName] = p
	end
	local root = parts[rig.root]
	root.Transparency = 1
	root.Anchored = true
	if rigName == "R6" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Head
		mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
		mesh.Parent = parts.Head
	end
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = parts.Head
	if parts.Handle then
		parts.Handle.Color = Color3.fromRGB(190, 195, 205)
		parts.Handle.Material = Enum.Material.Metal
	end
	root.CFrame = (where or CFrame.new()) * CFrame.new(0, rig.hipHeight, 0)
	-- place every part at rest: P1 = P0 * C0 * C1:Inverse()
	local placed = { [rig.root] = true }
	local pending = table.clone(rig.joints)
	while #pending > 0 do
		for i = #pending, 1, -1 do
			local j = pending[i]
			if placed[j.p0] then
				parts[j.p1].CFrame = parts[j.p0].CFrame * j.c0 * j.c1:Inverse()
				local m = Instance.new("Motor6D")
				m.Name = j.motor
				m.Part0, m.Part1 = parts[j.p0], parts[j.p1]
				m.C0, m.C1 = j.c0, j.c1
				m.Parent = parts[j.p0]
				placed[j.p1] = true
				table.remove(pending, i)
			end
		end
	end
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType[rigName]
	hum.HipHeight = rig.humanoidHipHeight
	hum.Parent = model
	Instance.new("Animator").Parent = hum
	model.PrimaryPart = root
	model.Parent = workspace
	return model
end

-- Give an existing character a prop (e.g. the Sword) on the same Motor6D the animation expects.
function AnimKit.addProp(model, propName)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local rigName = hum.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15"
	local p = AnimKit.Props[propName]
	local attach = p.attach[rigName]
	local parent = model:FindFirstChild(attach[1])
	local part = model:FindFirstChild(p.part) or Instance.new("Part")
	part.Name = p.part
	part.Size = p.size
	part.CanCollide = false
	part.Massless = true
	part.Color = Color3.fromRGB(190, 195, 205)
	part.Material = Enum.Material.Metal
	part.CFrame = parent.CFrame * attach[2] * p.c1:Inverse()
	part.Parent = model
	local m = parent:FindFirstChild(p.part) or Instance.new("Motor6D")
	m.Name = p.part
	m.Part0, m.Part1, m.C0, m.C1 = parent, part, attach[2], p.c1
	m.Parent = parent
	return part
end

-- File the animation where editors look: ServerStorage.RBX_ANIMSAVES.<rig name> (Animation Editor's
-- "Load" list; Moon Animator 2 imports it with File > Import, then click it in the Explorer), plus a
-- copy in ServerStorage.Animations.
function AnimKit.save(kfs, model)
	local folder = ServerStorage:FindFirstChild("Animations") or Instance.new("Folder")
	folder.Name = "Animations"
	folder.Parent = ServerStorage
	local old = folder:FindFirstChild(kfs.Name)
	if old then
		old:Destroy()
	end
	kfs.Parent = folder
	if model then
		local saves = ServerStorage:FindFirstChild("RBX_ANIMSAVES") or Instance.new("Model")
		saves.Name = "RBX_ANIMSAVES"
		saves.Parent = ServerStorage
		local slot = saves:FindFirstChild(model.Name) or Instance.new("ObjectValue")
		slot.Name = model.Name
		slot.Value = model
		slot.Parent = saves
		local prev = slot:FindFirstChild(kfs.Name)
		if prev then
			prev:Destroy()
		end
		kfs:Clone().Parent = slot
	end
	return kfs
end

-- Play or scrub in Edit mode, no publishing:
--   local p = AnimKit.preview(rig, kfs); p.at(0.25); ...; p.stop()
--   AnimKit.preview(rig, kfs).play(3)   -- plays live for 3 seconds, then stops
function AnimKit.preview(model, kfs)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local anim = Instance.new("Animation")
	anim.AnimationId = AnimationClipProvider:RegisterAnimationClip(kfs)
	local track = animator:LoadAnimation(anim)
	track:Play(0, 1, 0)
	local t0 = os.clock()
	while track.Length == 0 and os.clock() - t0 < 3 do
		task.wait()
	end
	task.wait()
	local ctl = { track = track, length = track.Length }
	function ctl.at(seconds)
		-- measured: stepping a one-shot track onto its very end leaves a stuck track on the Animator that
		-- keeps posing the rig, so stop a hair short of it
		track.TimePosition = kfs.Loop and seconds % ctl.length or math.min(seconds, ctl.length - 1e-3)
		animator:StepAnimations(0)
	end
	function ctl.stop()
		track:Stop(0)
		animator:StepAnimations(0) -- in Edit mode a stop only takes effect on the next step
		track:Destroy()
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("Motor6D") then
				d.Transform = CFrame.identity
			end
		end
	end
	function ctl.play(seconds, speed)
		local start = os.clock()
		local conn
		conn = game:GetService("RunService").Heartbeat:Connect(function()
			local t = (os.clock() - start) * (speed or 1)
			if t > (seconds or ctl.length) then
				conn:Disconnect()
				ctl.stop()
				return
			end
			ctl.at(t)
		end)
		return ctl
	end
	return ctl
end

---------------------------------------------------------------------------------------------------
-- Talking to the pack folder (kit/serve.py serves it on http://127.0.0.1:8765 while you work)
---------------------------------------------------------------------------------------------------

AnimKit.PORT = 8765

-- GET a file from the pack folder. HTTP is switched on only for the request and restored after.
function AnimKit.fetch(path)
	local HttpService = game:GetService("HttpService")
	local was = HttpService.HttpEnabled
	HttpService.HttpEnabled = true
	local ok, res = pcall(HttpService.GetAsync, HttpService, ("http://127.0.0.1:%d/%s"):format(AnimKit.PORT, path), true)
	HttpService.HttpEnabled = was
	if not ok and tostring(res):find("404") then
		error(path .. " doesn't exist yet: export it from Blender first", 2)
	end
	assert(ok, "could not reach kit/serve.py (is it running?): " .. tostring(res))
	return res
end

-- Build out/<name>.json into a KeyframeSequence and file it for the editors (and `model`'s slot).
function AnimKit.load(name, model)
	local data = game:GetService("HttpService"):JSONDecode(AnimKit.fetch("out/" .. name .. ".json"))
	return AnimKit.save(AnimKit.fromData(data), model), data
end

-- Roblox's playback vs what Blender showed, every frame and joint. Returns a report string.
function AnimKit.verify(name, model)
	local HttpService = game:GetService("HttpService")
	local kfs, data = AnimKit.load(name, model)
	local want = HttpService:JSONDecode(AnimKit.fetch("out/verify/" .. name .. ".json"))
	local got = AnimKit.sample(model, kfs, data.fps)
	local worst, at, worstPos, missing = 0, "-", 0, {}
	for f = 0, data.length do
		for jointName, comps in pairs(want[f + 1]) do
			local b = got[f] and got[f][jointName]
			if b then
				local d = CFrame.new(table.unpack(comps)):ToObjectSpace(b)
				local _, ang = d:ToAxisAngle()
				ang = math.deg(math.abs(ang))
				ang = math.min(ang, 360 - ang)
				if ang > worst then
					worst, at = ang, ("%s, frame %d"):format(jointName, f)
				end
				worstPos = math.max(worstPos, d.Position.Magnitude)
			else
				missing[jointName] = true
			end
		end
	end
	local miss = {}
	for j in pairs(missing) do
		table.insert(miss, j)
	end
	local verdict = (worst <= 1.5 and worstPos <= 0.03 and #miss == 0) and "MATCHES BLENDER" or "DIFFERS"
	return ("%s: %s. Worst rotation %.2f deg (%s), worst offset %.3f studs%s"):format(
		name, verdict, worst, at, worstPos, #miss > 0 and (", joints missing on the rig: " .. table.concat(miss, ", ")) or ""
	)
end

-- Every joint's Transform on every frame, as Roblox plays it (for checking against Blender).
function AnimKit.sample(model, kfs, fps)
	local p = AnimKit.preview(model, kfs)
	local motors = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part1 then
			motors[d.Part1.Name] = d
		end
	end
	local frames = {}
	for f = 0, math.round(p.length * fps) do
		p.at(f / fps)
		local row = {}
		for name, m in pairs(motors) do
			row[name] = m.Transform
		end
		frames[f] = row
	end
	p.stop()
	return frames
end

return AnimKit
