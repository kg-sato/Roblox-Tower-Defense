--!strict
-- FXScale (T602): the one place that decides how strong hit-stop, screen shake and the camera nudge are. Pure, no Instances.
-- Installed as ReplicatedStorage.Shared.FXScale. Reduced motion zeroes all three; the Screen shake setting zeroes shake and nudge only.

local FXScale = {}

type Settings = { reducedMotion: boolean?, shake: boolean? }

local function num(v: any): number
	return (type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge) and v or 0
end

local function still(s: Settings?): boolean
	return s ~= nil and s.reducedMotion == true
end

-- hit-stop in frames at 60 fps, 0..5
function FXScale.hitStop(frames: any, s: Settings?): number
	if still(s) then
		return 0
	end
	return math.clamp(math.floor(num(frames) + 0.5), 0, 5)
end

-- shake amount (the recipe weight: 0.05 .. 1)
function FXScale.shake(amount: any, s: Settings?): number
	if still(s) or (s ~= nil and s.shake == false) then
		return 0
	end
	return math.max(num(amount), 0)
end

-- one small camera shove toward the hit, in studs, grows with the shake weight and never exceeds 0.8
function FXScale.nudge(weight: any, s: Settings?): number
	if FXScale.shake(weight, s) == 0 then
		return 0
	end
	return math.min(0.3 + FXScale.shake(weight, s) * 0.5, 0.8)
end

return FXScale
