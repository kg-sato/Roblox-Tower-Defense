--!strict
-- Pure argument rules for the MatchService remote (T125). No Instances, so Tests/ActionArgs.test.luau can load it headless.

local ActionArgs = {}

ActionArgs.MAX_BATCH = 16

-- Unit ids are positive integers handed out by the sim (the client calls them slots).
function ActionArgs.isSlot(n: any): boolean
	return type(n) == "number" and n % 1 == 0 and n >= 1 and n <= 1e7
end

function ActionArgs.isCoord(n: any): boolean
	return type(n) == "number" and n == n and math.abs(n) < 1000
end

-- Setting args: one key (a = key, b = value) or a batch (a = { key = value }). Returns the map to validate, at most
-- MAX_BATCH entries, or nil when the shape is wrong (a missing or non-string key must not reach the table constructor).
function ActionArgs.settingChanges(a: any, b: any): { [any]: any }?
	if type(a) == "string" then
		return { [a] = b }
	end
	if type(a) ~= "table" then
		return nil
	end
	local out, n = {}, 0
	for key, value in a do
		if n >= ActionArgs.MAX_BATCH then
			break
		end
		n += 1
		out[key] = value
	end
	return out
end

return ActionArgs
