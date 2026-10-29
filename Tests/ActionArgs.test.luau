--!nocheck
-- Headless checks for ReplicatedStorage.Shared.ActionArgs (the MatchService argument rules, T125).
-- Run in Studio (Edit mode) with execute_luau, with Tests/ served locally:
--   local body = game:GetService("HttpService"):GetAsync("http://127.0.0.1:8796/ActionArgs.test.luau")
--   return loadstring(body)()(game.ReplicatedStorage.Shared)
-- Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local A = require(Shared.ActionArgs)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end

	-- slots
	check("slot 1 accepted", A.isSlot(1))
	check("slot 1e7 accepted", A.isSlot(1e7))
	check("slot 0 rejected", not A.isSlot(0))
	check("slot negative rejected", not A.isSlot(-1))
	check("slot fraction rejected", not A.isSlot(1.5))
	check("slot above 1e7 rejected", not A.isSlot(1e7 + 1))
	check("slot NaN rejected", not A.isSlot(0 / 0))
	check("slot inf rejected", not A.isSlot(math.huge))
	check("slot string rejected", not A.isSlot("1"))
	check("slot nil rejected", not A.isSlot(nil))

	-- coordinates
	check("coord 0 accepted", A.isCoord(0))
	check("coord -999.5 accepted", A.isCoord(-999.5))
	check("coord 1000 rejected", not A.isCoord(1000))
	check("coord NaN rejected", not A.isCoord(0 / 0))
	check("coord inf rejected", not A.isCoord(math.huge))
	check("coord string rejected", not A.isCoord("3"))

	-- setting args
	local one = A.settingChanges("musicVolume", 0.5)
	check("single key becomes a map", one ~= nil and one.musicVolume == 0.5)
	local batch = {}
	for i = 1, 20 do
		batch["k" .. i] = i
	end
	local capped = A.settingChanges(batch, nil)
	local n = 0
	for _ in capped do
		n += 1
	end
	check("batch capped at 16 keys", n == 16, n)
	check("nil key rejected", A.settingChanges(nil, 1) == nil)
	check("number key rejected", A.settingChanges(5, 1) == nil)
	check("empty batch gives an empty map", next(A.settingChanges({}, nil)) == nil)
	local small = A.settingChanges({ sfxVolume = 0.2, flashes = false }, nil)
	check("small batch keeps every key", small ~= nil and small.sfxVolume == 0.2 and small.flashes == false)

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
