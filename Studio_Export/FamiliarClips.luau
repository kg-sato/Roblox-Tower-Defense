--!nonstrict
-- FamiliarClips (T107): builds the Walk and Attack KeyframeSequence for a familiar rigged with the T106 template (Roblox Dev/Design/Rig Template.md).
-- Poses are written as rotations about MESH-space axes (X = right, Y = up, -Z = forward, the Roblox convention for these models); each is converted to the bone's own
-- frame with the bone's rest orientation, because the imported bones do not share one axis convention (legs and arms are flipped or tilted). Forward swing of a hanging limb
-- is +X, leaning forward is -X. Core chain bones (Root, Pelvis, Spine, Chest, Neck, Head) have the same orientation as the mesh, so a translation on them is in mesh space.
-- Usage (Studio Edit mode, authoring): FamiliarClips.build(model, archetype, "Walk" | "Attack") -> KeyframeSequence (loop for Walk, 1.0 s each).
-- The keyframe pose tree mirrors the bone tree, starting with a pose named after the MeshPart (weight 0).
local M = {}

local rad = math.rad
local TAU = math.pi * 2

-- each recipe(t) returns { [boneName] = { rx, ry, rz in degrees (mesh-space axes), tx, ty, tz in studs (mesh space) } }; missing bones stay at rest
local function walk(arch, ph)
	local s = math.sin(TAU * ph)
	local c = math.cos(TAU * ph)
	local p = {}
	local bob = 0.05 * math.abs(s)
	if arch == "biped" then
		p.Pelvis = { 0, 0, 3 * s, 0, bob, 0 }
		p.Chest = { 0, 0, -2 * s }
		p["UpperLeg.L"] = { 30 * s }
		p["UpperLeg.R"] = { -30 * s }
		p["LowerLeg.L"] = { -35 * math.max(0, -s) }
		p["LowerLeg.R"] = { -35 * math.max(0, s) }
		p["UpperArm.L"] = { -22 * s }
		p["UpperArm.R"] = { 22 * s }
		p["LowerArm.L"] = { -10 * math.max(0, s) }
		p["LowerArm.R"] = { -10 * math.max(0, -s) }
		p.Head = { 0, -4 * s, 2 * s }
	elseif arch == "quadruped" then
		p.Pelvis = { 0, 0, 2 * s, 0, bob, 0 }
		p.Chest = { -3, 3 * s, 0 }
		p["FrontUpperLeg.L"] = { 24 * s }
		p["HindUpperLeg.R"] = { 24 * s }
		p["FrontUpperLeg.R"] = { -24 * s }
		p["HindUpperLeg.L"] = { -24 * s }
		p["FrontLowerLeg.L"] = { -30 * math.max(0, -s) }
		p["HindLowerLeg.R"] = { -30 * math.max(0, -s) }
		p["FrontLowerLeg.R"] = { -30 * math.max(0, s) }
		p["HindLowerLeg.L"] = { -30 * math.max(0, s) }
		p.Head = { 4 * s, 0, 0 }
		p.Tail1 = { 0, 15 * s }
		p.Tail2 = { 0, 20 * math.sin(TAU * ph - 0.8) }
	elseif arch == "flyer" then
		-- wings flap about the forward axis (Z): on the left wing +Z moves it down, on the right wing -Z
		p.Pelvis = { 0, 0, 0, 0, 0.12 * s, 0 }
		p.Spine = { -4, 0, 2 * s }
		p.Head = { 3 * s, 0, 0 }
		p["WingInner.L"] = { 0, 0, 35 * s }
		p["WingInner.R"] = { 0, 0, -35 * s }
		p["WingOuter.L"] = { 0, 0, 25 * math.sin(TAU * ph - 0.6) }
		p["WingOuter.R"] = { 0, 0, -25 * math.sin(TAU * ph - 0.6) }
		p.Tail1 = { 0, 12 * s }
		p.Tail2 = { 0, 18 * math.sin(TAU * ph - 0.9) }
	elseif arch == "floater" then
		p.Pelvis = { 0, 0, 0, 0, 0.08 * s, 0 }
		p.Spine = { -6, 0, 3 * s }
		p.Chest = { -3, 0, -2 * s }
		p.Head = { 3 * s, 0, 0 }
		p.Trail1 = { 0, 14 * s }
		p.Trail2 = { 0, 20 * math.sin(TAU * ph - 1) }
		p["UpperArm.L"] = { 0, 0, 14 * c }
		p["UpperArm.R"] = { 0, 0, -14 * c }
	end
	return p
end

local function attack(arch, t)
	-- t in seconds, 0 to 1: rest 0, windup peak 0.27, release peak 0.37, hold 0.43, settle 0.8, rest 1.0
	local keys = { { 0, 0 }, { 0.27, -1 }, { 0.37, 1 }, { 0.43, 0.9 }, { 0.8, -0.12 }, { 1.0, 0 } }
	local v = 0
	for i = 1, #keys - 1 do
		local a, b = keys[i], keys[i + 1]
		if t >= a[1] and t <= b[1] then
			local u = (t - a[1]) / (b[1] - a[1])
			u = u * u * (3 - 2 * u)
			v = a[2] + (b[2] - a[2]) * u
			break
		end
	end
	-- v: -1 = full windup, +1 = full release
	local back, fwd = math.max(0, -v), math.max(0, v)
	local p = {}
	p.Spine = { 12 * back - 22 * fwd + 4 * math.min(0, v) * 0 }
	p.Chest = { 8 * back - 14 * fwd }
	p.Head = { 10 * back - 10 * fwd }
	p.Pelvis = { 0, 0, 0, 0, 0, 0.05 * back - 0.2 * fwd }
	if arch == "biped" then
		p["UpperArm.L"] = { 55 * back - 75 * fwd }
		p["UpperArm.R"] = { 55 * back - 75 * fwd }
		p["LowerArm.L"] = { -30 * back }
		p["LowerArm.R"] = { -30 * back }
		p["UpperLeg.L"] = { -10 * back + 12 * fwd }
		p["UpperLeg.R"] = { 10 * back - 12 * fwd }
	elseif arch == "quadruped" then
		p["FrontUpperLeg.L"] = { 35 * back - 55 * fwd }
		p["FrontUpperLeg.R"] = { 35 * back - 55 * fwd }
		p["HindUpperLeg.L"] = { -10 * back + 12 * fwd }
		p["HindUpperLeg.R"] = { -10 * back + 12 * fwd }
		p.Tail1 = { 0, 18 * fwd }
	elseif arch == "flyer" then
		p["WingInner.L"] = { 0, 0, -50 * back + 40 * fwd }
		p["WingInner.R"] = { 0, 0, 50 * back - 40 * fwd }
		p["WingOuter.L"] = { 0, 0, -30 * back + 25 * fwd }
		p["WingOuter.R"] = { 0, 0, 30 * back - 25 * fwd }
		p.Tail1 = { 0, 18 * fwd }
	elseif arch == "floater" then
		p["UpperArm.L"] = { 0, 0, 40 * back - 60 * fwd }
		p["UpperArm.R"] = { 0, 0, -(40 * back - 60 * fwd) }
		p.Trail1 = { 0, 20 * fwd }
		p.Trail2 = { 0, -25 * fwd }
	end
	return p
end

-- Idle (loop, 2 s): slow breathing. Hit (0.5 s): short flinch back. Death (1.2 s, no loop): sink and slump forward, holds the last pose.
-- Core chain bones only plus small arm and wing motion, so every archetype works. Back is +Z and +X rotation, forward is -X (see top note).
local function idle(arch, ph)
	local s = math.sin(TAU * ph)
	local p = { Pelvis = { 0, 0, 0, 0, 0.03 * s, 0 }, Spine = { -1.2 * s }, Chest = { 1.5 * s }, Head = { -1 * s, 3 * math.sin(TAU * ph + 1) } }
	if arch == "biped" or arch == "floater" then
		p["UpperArm.L"] = { 3 * s }
		p["UpperArm.R"] = { 3 * s }
	elseif arch == "flyer" then
		p.Pelvis = { 0, 0, 0, 0, 0.1 * s, 0 }
		p["WingInner.L"] = { 0, 0, 10 * s }
		p["WingInner.R"] = { 0, 0, -10 * s }
	elseif arch == "quadruped" then
		p.Tail1 = { 0, 8 * s }
	end
	return p
end

local function hit(arch, t)
	local e = t < 0.2 and t / 0.2 or math.max(0, 1 - (t - 0.2) / 0.8)
	e = e * e * (3 - 2 * e)
	local p = { Pelvis = { 0, 0, 0, 0, 0, 0.2 * e }, Spine = { 18 * e }, Chest = { 14 * e }, Head = { 26 * e } }
	if arch == "biped" or arch == "floater" then
		p["UpperArm.L"] = { 25 * e }
		p["UpperArm.R"] = { 25 * e }
	elseif arch == "flyer" then
		p["WingInner.L"] = { 0, 0, -30 * e }
		p["WingInner.R"] = { 0, 0, 30 * e }
	end
	return p
end

local function death(arch, t)
	local e = t * t * (3 - 2 * t)
	local p = { Pelvis = { 0, 0, 0, 0, -1.4 * e, -0.3 * e }, Spine = { -50 * e }, Chest = { -35 * e }, Head = { -40 * e } }
	if arch == "biped" then
		p["UpperLeg.L"] = { 50 * e }
		p["UpperLeg.R"] = { 50 * e }
		p["LowerLeg.L"] = { -90 * e }
		p["LowerLeg.R"] = { -90 * e }
		p["UpperArm.L"] = { 12 * e }
		p["UpperArm.R"] = { 12 * e }
	elseif arch == "quadruped" then
		p["FrontUpperLeg.L"] = { 40 * e }
		p["FrontUpperLeg.R"] = { 40 * e }
		p["HindUpperLeg.L"] = { -40 * e }
		p["HindUpperLeg.R"] = { -40 * e }
	elseif arch == "flyer" then
		p["WingInner.L"] = { 0, 0, 50 * e }
		p["WingInner.R"] = { 0, 0, -50 * e }
	end
	return p
end

-- length (s), steps, loop, priority, recipe(arch, 0..1)
local CLIPS = {
	Walk = { 1, 12, true, Enum.AnimationPriority.Movement, walk },
	Attack = { 1, 30, false, Enum.AnimationPriority.Action, attack },
	Idle = { 2, 16, true, Enum.AnimationPriority.Idle, idle },
	Hit = { 0.5, 10, false, Enum.AnimationPriority.Action, hit },
	Death = { 1.2, 24, false, Enum.AnimationPriority.Action, death },
}

local function restWorldRotations(mesh)
	local out = {}
	for _, b in mesh:GetDescendants() do
		if b:IsA("Bone") then
			out[b.Name] = mesh.CFrame:ToObjectSpace(b.WorldCFrame).Rotation -- the rest orientation in mesh space (author with every Transform at identity)
		end
	end
	return out
end

-- bone Transform for a mesh-space rotation (degrees) and translation (studs): conjugate by the bone's rest orientation
local function transformFor(restRot, spec)
	local rx, ry, rz, tx, ty, tz = spec[1] or 0, spec[2] or 0, spec[3] or 0, spec[4] or 0, spec[5] or 0, spec[6] or 0
	local worldRot = CFrame.Angles(rad(rx), rad(ry), rad(rz))
	local local_ = restRot:Inverse() * worldRot * restRot
	local t = restRot:Inverse() * CFrame.new(tx, ty, tz)
	return CFrame.new(t.Position) * local_.Rotation
end

function M.build(model, archetype, clip)
	local mesh = model:FindFirstChildWhichIsA("MeshPart")
	assert(mesh, "FamiliarClips: no MeshPart in " .. model.Name)
	local rest = restWorldRotations(mesh)
	local ks = Instance.new("KeyframeSequence")
	ks.Name = clip
	local def = assert(CLIPS[clip], "FamiliarClips: unknown clip " .. tostring(clip))
	local length, steps, loop, priority, recipe = def[1], def[2], def[3], def[4], def[5]
	ks.Loop = loop
	ks.Priority = priority
	local boneTree = {}
	for _, b in mesh:GetDescendants() do
		if b:IsA("Bone") then
			boneTree[b] = b.Parent
		end
	end
	for i = 0, steps do
		local t = i / steps
		local spec = recipe(archetype, (loop and t == 1) and 0 or t) -- looping clips end on their first pose
		local kf = Instance.new("Keyframe")
		kf.Time = t * length
		local rootPose = Instance.new("Pose")
		rootPose.Name = mesh.Name
		rootPose.Weight = 0
		rootPose.Parent = kf
		local poses = {}
		local function poseOf(b)
			if poses[b] then
				return poses[b]
			end
			local parentPose = (b.Parent and b.Parent:IsA("Bone")) and poseOf(b.Parent) or rootPose
			local p = Instance.new("Pose")
			p.Name = b.Name
			p.Weight = 1
			p.CFrame = spec[b.Name] and transformFor(rest[b.Name], spec[b.Name]) or CFrame.new()
			p.EasingStyle = Enum.PoseEasingStyle.Linear
			p.Parent = parentPose
			poses[b] = p
			return p
		end
		for b in boneTree do
			poseOf(b)
		end
		kf.Parent = ks
	end
	return ks
end

M.walk, M.attack, M.idle, M.hit, M.death = walk, attack, idle, hit, death
return M
