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
	for st = 16, 20 do
		check("stage " .. st, id(st), "ClockworkFoundry")
	end
	for st = 21, 25 do
		check("stage " .. st, id(st), "AboveTheGreyVeil")
	end
	check("stage 26 wraps to the first set", id(26), "LampwickLane")
	check("stage 31 is the second set again", id(31), "HarbourOfBrass")
	check("stage 0 clamps to the first set", id(0), "LampwickLane")
	check("negative stage clamps", id(-7), "LampwickLane")
	check("fractional stage floors (5.9 -> 5)", id(5.9), "LampwickLane")
	check("huge stage stays valid", id(1e6) ~= nil, true)
	check("stage 1e6: (1e6 - 1) mod 25 + 1 = 25 -> Veil", id(1000000), "AboveTheGreyVeil")
	local ok = true
	for _, s in S.list do
		ok = ok and type(s.id) == "string" and s.stages > 0 and s.lighting.ClockTime ~= nil
	end
	check("every set has id, stage count and lighting", ok, true)


	-- per-set lane shapes (T167)
	local Config = require(Shared.Config)
	local function yes(name, cond, detail)
		check(name .. (detail ~= nil and (" [" .. tostring(detail) .. "]") or ""), cond and true or false, true)
	end
	check("Config.PATH_PER_SET is off by default", Config.PATH_PER_SET, false)
	local HW = Config.PATH_HALF_WIDTH
	local B = Config.PLACE_BOUNDS
	local function lenOf(pts)
		local t = 0
		for i = 1, #pts - 1 do
			t += (Vector3.new(pts[i + 1][1], 0, pts[i + 1][2]) - Vector3.new(pts[i][1], 0, pts[i][2])).Magnitude
		end
		return t
	end
	local function segDist(a, b, c, d) -- closest approach of segment ab to segment cd, sampled
		local best = math.huge
		for i = 0, 40 do
			local t = i / 40
			local px, pz = a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t
			local dx, dz = d[1] - c[1], d[2] - c[2]
			local u = math.clamp(((px - c[1]) * dx + (pz - c[2]) * dz) / (dx * dx + dz * dz), 0, 1)
			best = math.min(best, math.sqrt((c[1] + dx * u - px) ^ 2 + (c[2] + dz * u - pz) ^ 2))
		end
		return best
	end
	local todayLen = 0
	for i = 1, #Config.PATH - 1 do
		todayLen += (Config.PATH[i + 1] - Config.PATH[i]).Magnitude
	end
	local sigs = {}
	for _, set in S.list do
		local p = set.path
		local n = set.id
		yes(n .. " has a path of 4 or more waypoints", p ~= nil and #p >= 4, p and #p)
		if p and #p >= 4 then
			local inB, minSeg, minTurn, maxTurn, turns = true, math.huge, 180, 0, 0
			for i, w in p do
				inB = inB and w[1] >= B.minX + HW and w[1] <= B.maxX - HW and w[2] >= B.minZ + HW and w[2] <= B.maxZ - HW
				if i > 1 then
					minSeg = math.min(minSeg, lenOf({ p[i - 1], w }))
				end
				if i > 1 and i < #p then
					local a1 = math.atan2(w[2] - p[i - 1][2], w[1] - p[i - 1][1])
					local a2 = math.atan2(p[i + 1][2] - w[2], p[i + 1][1] - w[1])
					local turn = math.abs(math.deg(a2 - a1))
					turn = turn > 180 and 360 - turn or turn
					minTurn, maxTurn, turns = math.min(minTurn, turn), math.max(maxTurn, turn), turns + 1
				end
			end
			yes(n .. " waypoints stay inside the build bounds", inB, true)
			yes(n .. " every segment is 8 or longer", minSeg >= 8, minSeg)
			yes(n .. " every bend turns 20 to 135 degrees (no kink, no hairpin)", minTurn >= 20 and maxTurn <= 135, math.floor(minTurn) .. " to " .. math.floor(maxTurn))
			yes(n .. " has 4 or more bends", turns >= 4, turns)
			local apart = math.huge
			for i = 1, #p - 1 do
				for j = i + 2, #p - 1 do
					apart = math.min(apart, segDist(p[i], p[i + 1], p[j], p[j + 1]), segDist(p[j], p[j + 1], p[i], p[i + 1]))
				end
			end
			yes(n .. " lanes never come within two lane widths of themselves", apart >= 2 * HW, apart)
			local ratio = lenOf(p) / todayLen
			yes(n .. " length is 0.6 to 1.8 times today's lane", ratio >= 0.6 and ratio <= 1.8, ratio)
			local sig = {}
			for _, w in p do
				table.insert(sig, w[1] .. "," .. w[2])
			end
			sig = table.concat(sig, ";")
			yes(n .. " shape differs from every other set", sigs[sig] == nil, sig)
			sigs[sig] = true
		end
	end
	local first = S.list[1].path
	local same = #first == #Config.PATH
	for i, w in first do
		same = same and Config.PATH[i] ~= nil and Config.PATH[i].X == w[1] and Config.PATH[i].Z == w[2]
	end
	yes("the first set's lane is exactly today's Config.PATH", same, true)
	yes("flag off: pathFor is the single Config.PATH for every stage", Config.pathFor(1) == Config.PATH and Config.pathFor(7) == Config.PATH and Config.pathFor(24) == Config.PATH, true)
	Config.PATH_PER_SET = true
	yes("flag on: stage 3 still gets today's lane", Config.pathFor(3)[3] == Config.PATH[3] or (Config.pathFor(3)[3] - Config.PATH[3]).Magnitude < 1e-6, true)
	local h = Config.pathFor(7)
	yes("flag on: stage 7 gets the Harbour lane", #h == #S.list[2].path and h[1].X == S.list[2].path[1][1] and h[1].Z == S.list[2].path[1][2], #h)
	yes("flag on: stage 32 wraps to the Harbour lane", #Config.pathFor(32) == #S.list[2].path, #Config.pathFor(32))
	check("flag on: lane points sit at lane height 1", Config.pathFor(12)[2].Y, 1)
	Config.PATH_PER_SET = false
	yes("flag back off: single path again", Config.pathFor(12) == Config.PATH, true)

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
