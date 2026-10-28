--!strict
-- Lane math: position along the waypoint path by distance travelled.

local Config = require(script.Parent.Config)

local Path = {}

local points = Config.PATH
local lengths: { number } = {}
local total = 0
for i = 1, #points - 1 do
	local len = (points[i + 1] - points[i]).Magnitude
	lengths[i] = len
	total += len
end

Path.length = total

function Path.positionAt(dist: number): Vector3
	if dist <= 0 then
		return points[1]
	end
	local remaining = dist
	for i = 1, #lengths do
		if remaining <= lengths[i] then
			return points[i]:Lerp(points[i + 1], remaining / lengths[i])
		end
		remaining -= lengths[i]
	end
	return points[#points]
end

return Path
