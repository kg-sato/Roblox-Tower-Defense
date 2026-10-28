--!nocheck
-- Headless checks for ReplicatedStorage.Shared.StageSets. Run in Studio (Edit mode) with execute_luau:
--   local body = game:GetService("HttpService"):GetAsync("http://127.0.0.1:8792/StageSets.test.luau")
--   return loadstring(body)()(game.ReplicatedStorage.Shared)
-- Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local S = require(Shared.StageSets)
	local results, failed = {}, 0
	local function check(name, got, want)
		local ok = got == want
		if not ok then
			failed += 1
		end
		table.insert(results, (ok and "ok   " or "FAIL ") .. name .. " -> " .. tostring(got) .. (ok and "" or " (want " .. tostring(want) .. ")"))
	end
	local id = function(stage)
		return S.forStage(stage).id
	end

	for st = 1, 5 do
		check("stage " .. st, id(st), "LampwickLane")
	end
	for st = 6, 10 do
		check("stage " .. st, id(st), "HarbourOfBrass")
	end
	for st = 11, 15 do
		check("stage " .. st, id(st), "SilentCathedral")
	end
	check("stage 16 wraps to the first set", id(16), "LampwickLane")
	check("stage 21 is the second set again", id(21), "HarbourOfBrass")
	check("stage 0 clamps to the first set", id(0), "LampwickLane")
	check("negative stage clamps", id(-7), "LampwickLane")
	check("fractional stage floors (5.9 -> 5)", id(5.9), "LampwickLane")
	check("huge stage stays valid", id(1e6) ~= nil, true)
	check("stage 1e6: (1e6 - 1) mod 15 + 1 = 10 -> Harbour", id(1000000), "HarbourOfBrass")
	local ok = true
	for _, s in S.list do
		ok = ok and type(s.id) == "string" and s.stages > 0 and s.lighting.ClockTime ~= nil
	end
	check("every set has id, stage count and lighting", ok, true)

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
