--!nocheck
-- Headless checks for ReplicatedStorage.Shared.FXScale (T602) and the way FXRecipes uses it. Run through Tests/RunAll.luau.
-- Returns a report; the first line says PASS or FAIL.

return function(Shared)
	local F = require(Shared.FXScale)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local on, off, noShake = {}, { reducedMotion = true }, { shake = false }

	check("hit-stop passes through when motion is on", F.hitStop(3, on) == 3)
	check("hit-stop is zero with reduced motion", F.hitStop(5, off) == 0)
	check("hit-stop is clamped to 0..5 frames", F.hitStop(9, on) == 5 and F.hitStop(-2, on) == 0)
	check("hit-stop stays on when only screen shake is off", F.hitStop(3, noShake) == 3)
	check("shake passes through when motion is on", F.shake(0.4, on) == 0.4)
	check("shake is zero with reduced motion", F.shake(1, off) == 0)
	check("shake is zero with the shake setting off", F.shake(1, noShake) == 0)
	check("camera nudge is zero with reduced motion", F.nudge(1, off) == 0)
	check("camera nudge is zero with the shake setting off", F.nudge(1, noShake) == 0)
	local small, big = F.nudge(0.05, on), F.nudge(1, on)
	check("camera nudge grows with importance", small > 0 and big > small, small .. " < " .. big)
	check("camera nudge is capped at 0.8 studs", F.nudge(50, on) <= 0.8)
	check("nil settings behave like motion on", F.hitStop(2) == 2 and F.shake(0.1) == 0.1)
	check("garbage amounts give zero", F.hitStop("x", on) == 0 and F.shake(0 / 0, on) == 0 and F.nudge(nil, on) == 0)
	-- the importance ladder in FXRecipes keeps its order and every rung goes to zero when motion is off
	local ladderOk, zeroOk = true, true
	local W = { 2, 2, 2, 3, 3, 5 }
	for i, f in W do
		if F.hitStop(f, on) ~= f then ladderOk = false end
		if F.hitStop(f, off) ~= 0 then zeroOk = false end
	end
	check("every recipe weight keeps its frames when on and is zero when off", ladderOk and zeroOk)

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
