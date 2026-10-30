--!nocheck
-- Headless checks for Shared.LeaderboardRules (T025): week keys, run validation (anti-cheat), packed scores, ranking. Pure functions only;
-- the live OrderedDataStore is NOT exercised (UNVERIFIED in Studio).
-- Run in Studio (Edit mode) with execute_luau, serving Tests/ locally (see RunAll.luau).

return function(Shared)
	local L = require(Shared.LeaderboardRules)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end

	local ok, err = pcall(function()
		-- weeks: Monday 2026-10-26 00:00 UTC, built with DateTime so no local time zone is involved
		local function dt(y, m, d, h)
			return DateTime.fromUniversalTime(y, m, d, h or 0, 0, 0).UnixTimestamp
		end
		local mon = dt(2026, 10, 26, 0)
		local week = L.weekKey(mon)
		check("a Monday 00:00 UTC starts a week", L.weekStart(week) == mon and L.weekKey(mon - 1) == week - 1)
		check("Sunday 23:59 UTC is still the same week", L.weekKey(mon + 7 * 86400 - 1) == week and L.weekKey(mon + 7 * 86400) == week + 1)
		check("the epoch week starts on the first Monday (1970-01-05)", L.weekStart(1) == 4 * 86400 and L.weekKey(4 * 86400) == 1 and L.weekKey(4 * 86400 - 1) == 0)
		check("store name carries the week", L.storeName(week) == "WeeklyBestWave_" .. week)

		local now = mon + 2 * 86400 + 3600
		local function run(over)
			local r = { userId = 1234, wave = 30, elapsed = 600, startedAt = now - 600 }
			for k, v in over or {} do
				r[k] = v
			end
			return r
		end
		local function ctx(over)
			local c = { now = now, lastSubmit = nil, best = nil }
			for k, v in over or {} do
				c[k] = v
			end
			return c
		end
		local okV, why, res = L.validate(run(), ctx())
		check("an honest run is accepted with a packed score", okV and res.wave == 30 and res.week == week and res.packed > 30 * L.TIE_SPAN, why)
		check("the packed score unpacks to the wave and the time into the week", (function()
			local w, secs = L.unpack(res.packed)
			return w == 30 and secs == now - mon
		end)())

		-- refusals
		local function refused(r, c, reason)
			local o, w = L.validate(r, c)
			return o == false and w == reason
		end
		check("non-table input refused", refused(nil, ctx(), "Bad request") and refused(run(), nil, "Bad request") and refused(run(), { now = "x" }, "Bad request"))
		check("bad player ids refused", refused(run({ userId = 0 }), ctx(), "Bad player") and refused(run({ userId = -5 }), ctx(), "Bad player") and refused(run({ userId = 1.5 }), ctx(), "Bad player") and refused(run({ userId = "7" }), ctx(), "Bad player"))
		check("bad waves refused (zero, fraction, NaN, text)", refused(run({ wave = 0 }), ctx(), "Bad wave") and refused(run({ wave = 2.5 }), ctx(), "Bad wave") and refused(run({ wave = 0 / 0 }), ctx(), "Bad wave") and refused(run({ wave = "30" }), ctx(), "Bad wave"))
		check("a wave above the cap is refused", refused(run({ wave = L.MAX_WAVE + 1, elapsed = 86000 }), ctx({}), "Wave above the cap"))
		check("bad run times refused (zero, negative, NaN, infinite, over a day)", refused(run({ elapsed = 0 }), ctx(), "Bad run time") and refused(run({ elapsed = -4 }), ctx(), "Bad run time") and refused(run({ elapsed = 0 / 0 }), ctx(), "Bad run time") and refused(run({ elapsed = math.huge }), ctx(), "Bad run time") and refused(run({ elapsed = 90000 }), ctx(), "Bad run time"))
		check("too fast for the wave is refused", refused(run({ wave = 100, elapsed = 399 }), ctx(), "Too fast for that wave") and select(1, L.validate(run({ wave = 100, elapsed = 400, startedAt = now - 400 }), ctx())) == true)
		check("a start time in the future or not a number is refused", refused(run({ startedAt = now + 10 }), ctx(), "Bad start time") and refused(run({ startedAt = "x" }), ctx(), "Bad start time"))
		check("a run that began in an earlier week is refused", refused(run({ elapsed = 800000 % 86400 + 100, startedAt = mon - 5 }), ctx({ now = mon + 3600 }), "Run began in an earlier week"))
		check("submitting twice within the gap is refused", refused(run(), ctx({ lastSubmit = now - 5 }), "Submitting too often") and select(1, L.validate(run(), ctx({ lastSubmit = now - L.MIN_GAP }))) == true)
		check("no improvement is refused, a better wave is accepted", refused(run(), ctx({ best = 30 }), "No improvement") and refused(run(), ctx({ best = 45 }), "No improvement") and select(1, L.validate(run(), ctx({ best = 29 }))) == true)

		-- packing
		check("more waves beat an earlier finish", L.pack(31, 600000) > L.pack(30, 0))
		check("same wave: the earlier finish ranks higher", L.pack(30, 100) > L.pack(30, 200))
		local w, s = L.unpack(L.pack(77, 12345))
		check("pack and unpack round trip", w == 77 and s == 12345)
		check("packing stays within the double-safe integer range", L.pack(L.MAX_WAVE, 0) < 2 ^ 53)

		-- ranking
		local rows = L.rank({
			{ userId = 1, packed = L.pack(40, 500) },
			{ userId = 2, packed = L.pack(40, 100) },
			{ userId = 3, packed = L.pack(55, 900) },
			{ userId = 1, packed = L.pack(20, 10) }, -- a worse second entry of player 1
			{ userId = 4, packed = L.pack(10, 10) },
			{ userId = "x", packed = 5 },
			{ userId = 5, packed = -1 },
			{ userId = 6, packed = 0.5 },
			{ userId = 7, packed = L.pack(L.MAX_WAVE + 50, 1) },
			"junk",
		})
		check("rank: best wave first, ties by earlier finish", rows[1].userId == 3 and rows[2].userId == 2 and rows[3].userId == 1 and rows[4].userId == 4)
		check("rank: one row per player (their best), bad rows skipped", #rows == 4 and rows[3].wave == 40)
		check("rank numbers run 1 to n", rows[1].rank == 1 and rows[4].rank == 4)
		check("rank limit", #L.rank({ { userId = 1, packed = L.pack(5, 1) }, { userId = 2, packed = L.pack(6, 1) } }, 1) == 1)
		check("rank of nothing is empty", #L.rank(nil) == 0 and #L.rank({}) == 0)
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL test crashed: " .. tostring(err))
	end
	return (failed == 0 and "PASS" or "FAIL") .. " Leaderboard: " .. (#results - failed) .. "/" .. #results .. " checks ok\n" .. table.concat(results, "\n")
end
