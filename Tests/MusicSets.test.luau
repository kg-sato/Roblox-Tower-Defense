--!nocheck
-- Headless checks for per-set music and the wave tension layer (T160): ReplicatedStorage.MusicFX against Shared.StageSets.
return function(Shared)
	local RS = game:GetService("ReplicatedStorage")
	local Music = require(RS.MusicFX)
	local Sets = require(Shared.StageSets)
	local ids = require(RS.AudioIds).music
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end

	check("there are five stage sets", #Sets.list == 5, #Sets.list)
	local seen, distinct = {}, 0
	for i, set in Sets.list do
		local list = Music.states[set.music]
		check("set " .. i .. " " .. set.id .. " names a music state", list ~= nil and #list > 0, set.music)
		for _, track in list or {} do
			check("  track " .. track .. " is in the catalog and uploaded", Music.catalog[track] ~= nil and ids[track] ~= nil)
		end
		if not seen[set.music] then
			seen[set.music] = true
			distinct += 1
		end
	end
	check("every set has its own music state", distinct == 5, distinct)
	-- tension ladder
	local prev, rises = -1, true
	for stage = 1, 4 do
		local t = Music.tensionFor(stage, false)
		if t <= prev then rises = false end
		prev = t
	end
	check("tension rises through stages 1 to 4 of a set", rises)
	check("tension restarts low in the next set", Music.tensionFor(6, false) == Music.tensionFor(1, false))
	check("a boss stage is full tension", Music.tensionFor(5, true) == 1 and Music.tensionFor(10, true) == 1)
	check("stage 5 without a boss flag stays under full", Music.tensionFor(5, false) < 1)
	local inRange = true
	for stage = 1, 60 do
		local t = Music.tensionFor(stage, stage % 5 == 0)
		if t < 0 or t > 1 then inRange = false end
	end
	check("tension stays within 0..1", inRange)
	check("tension bed is a catalog track", Music.catalog[Music.tensionBed] ~= nil)

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
