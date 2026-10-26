--!nocheck
-- AnimLoader (ModuleScript in ReplicatedStorage). Method by fwjelaa (FWJ STUDIOS).
-- Loads animations by name, so game scripts never deal with ids:
--   local track = AnimLoader.load(humanoid, "R6_M1_1")
--
-- Published animations: put their ids in the AnimationIds ModuleScript next to this one (kit/upload.py
-- writes out/AnimationIds.luau for you; or paste ids from "Save to Roblox").
-- Not published yet? In Studio it falls back to the KeyframeSequence of the same name in
-- ReplicatedStorage.AnimationSources (Play-test only: unpublished animations never work in a live game).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimLoader = {}

local idsModule = script.Parent:FindFirstChild("AnimationIds")
local ids = idsModule and require(idsModule) or {}
local cache = setmetatable({}, { __mode = "k" }) -- animator -> { name -> track }

local function animationFor(name)
	local id = ids[name]
	if not id and RunService:IsStudio() then
		local sources = ReplicatedStorage:FindFirstChild("AnimationSources")
		local kfs = sources and sources:FindFirstChild(name)
		if kfs then
			id = game:GetService("AnimationClipProvider"):RegisterAnimationClip(kfs)
		end
	end
	assert(id, ("no animation called %s: add its id to AnimationIds"):format(name))
	local anim = Instance.new("Animation")
	anim.Name = name
	anim.AnimationId = id
	return anim
end

function AnimLoader.load(humanoid, name)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	cache[animator] = cache[animator] or {}
	local track = cache[animator][name]
	if not track then
		track = animator:LoadAnimation(animationFor(name))
		cache[animator][name] = track
	end
	return track
end

return AnimLoader
