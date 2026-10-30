--!nocheck
-- Headless checks for Shared.Bond (T007): level curve, use() xp with daily cap, mood by days away, rewards, input cleaning, save load.
-- Run in Studio (Edit mode) with execute_luau, serving Tests/ locally (see RunAll.luau).

return function(Shared)
	local B = require(Shared.Bond)
	local Familiars = require(Shared.Familiars)
	local Config = require(Shared.Config)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end

	local ok, err = pcall(function()
		local DAY = B.DAY
		local t0 = 20000 * DAY + 100
		check("level thresholds: 1 at 0, 2 at 50, 10 at 2,250", B.level(0) == 1 and B.level(49) == 1 and B.level(50) == 2 and B.level(2249) == 9 and B.level(2250) == 10 and B.level(1e9) == 10)
		local into, need = B.progress(70)
		check("progress inside a level", into == 20 and need == 100, into .. "/" .. need)
		check("no progress needed at the maximum", select(2, B.progress(5000)) == 0)
		check("every level has a reward from 2 to 10", (function()
			for lv = 2, B.MAX_LEVEL do
				if not B.REWARD[lv] or B.REWARD[lv] > 30 then
					return false
				end
			end
			return B.REWARD[1] == nil
		end)())

		local s = B.new()
		check("an unused familiar is Curious", B.mood(s, "Ember", t0).id == "Curious")
		local okU, _, r = B.use(s, "Ember", "run", 1, t0)
		check("one run gives 10 xp at level 1", okU and r.xp == 10 and r.level == 1 and #r.levels == 0 and r.gems == 0)
		okU, _, r = B.use(s, "Ember", "run", 4, t0 + 60)
		check("four more runs reach level 2 and pay its reward", okU and r.level == 2 and r.levels[1] == 2 and r.gems == 5, r and r.level)
		check("fielded minutes, merges and boss kills count", select(3, B.use(s, "Ember", "minute", 10, t0)).xp == 10 and select(3, B.use(s, "Ember", "merge", 2, t0)).xp == 6 and select(3, B.use(s, "Ember", "bossKill", 1, t0)).xp == 8)

		-- daily cap
		local c = B.new()
		local got = 0
		for _ = 1, 10 do
			got += select(3, B.use(c, "Zap", "run", 10, t0)).xp
		end
		check("a familiar earns at most the daily cap", got == B.DAILY_XP_CAP and c.Zap.xp == B.DAILY_XP_CAP, got)
		local nextDay = select(3, B.use(c, "Zap", "run", 1, t0 + DAY))
		check("the cap resets on the next UTC day", nextDay.xp > 0)

		-- several levels at once and the maximum
		local big = B.new()
		big.Sprout = { xp = 40, lastUsed = t0, day = 0, dayXp = 0 }
		local _, _, jump = B.use(big, "Sprout", "bossKill", 100, t0 + 5 * DAY)
		check("one big use can cross several levels and pays each reward", #jump.levels >= 1 and jump.gems >= 5, #jump.levels)
		local top = B.new()
		top.Sprout = { xp = 2250, lastUsed = t0, day = 0, dayXp = 0 }
		local _, _, topR = B.use(top, "Sprout", "run", 10, t0)
		check("at the maximum no xp is added and nothing is paid", topR.xp == 0 and topR.gems == 0 and top.Sprout.xp == 2250)

		-- mood
		local m = B.new()
		B.use(m, "Boulder", "run", 1, t0)
		check("used today: Delighted", B.mood(m, "Boulder", t0 + 3600).id == "Delighted")
		check("3 days away: Content", B.mood(m, "Boulder", t0 + 3 * DAY).id == "Content")
		check("7 days away: Wistful", B.mood(m, "Boulder", t0 + 7 * DAY).id == "Wistful")
		check("30 days away: Lonely", B.mood(m, "Boulder", t0 + 30 * DAY).id == "Lonely")
		local lonely = select(3, B.use(m, "Boulder", "run", 2, t0 + 30 * DAY))
		check("a lonely familiar warms 1.5 times as fast", lonely.xp == 30, lonely.xp)
		local wist = B.new()
		B.use(wist, "Zap", "run", 1, t0)
		check("a wistful familiar gets 1.25 times", select(3, B.use(wist, "Zap", "run", 4, t0 + 7 * DAY)).xp == 50)
		check("a clock that goes back is Delighted, never negative", B.mood(m, "Boulder", t0 - 5 * DAY).id == "Delighted")

		-- input cleaning
		local x = B.new()
		check("bad familiar ids refused", not B.use(x, 5, "run", 1, t0) and not B.use(x, "", "run", 1, t0) and not B.use(x, "a b", "run", 1, t0) and not B.use(x, string.rep("a", 41), "run", 1, t0) and next(x) == nil)
		check("bad kind, amount and time refused", not B.use(x, "Ember", "fish", 1, t0) and not B.use(x, "Ember", "run", 0, t0) and not B.use(x, "Ember", "run", -2, t0) and not B.use(x, "Ember", "run", 0 / 0, t0) and not B.use(x, "Ember", "run", math.huge, t0) and not B.use(x, "Ember", "run", "3", t0) and not B.use(x, "Ember", "run", 1, -1) and not B.use(x, "Ember", "run", 1, nil))
		check("a single call counts at most the step cap", select(3, B.use(B.new(), "Ember", "minute", 1e9, t0)).xp == B.STEP_CAP)
		local many = B.new()
		for i = 1, B.MAX_FAMILIARS do
			B.use(many, "F" .. i, "run", 1, t0)
		end
		check("the number of tracked familiars is capped", select(1, B.use(many, "Extra", "run", 1, t0)) == false and select(1, B.use(many, "F1", "run", 1, t0)) == true)

		-- real familiars
		local realBad = 0
		for id in Config.PETS do
			if not B.validId(id) then
				realBad += 1
			end
		end
		for _, f in Familiars.list or {} do
			if f.id and not B.validId(f.id) then
				realBad += 1
			end
		end
		check("every real familiar id is a valid bond id", realBad == 0, realBad)

		-- saved data
		local l = B.load({ Ember = { xp = 120, lastUsed = t0, day = 20000, dayXp = 50 }, ["bad id!"] = { xp = 5 }, Zap = { xp = -4, lastUsed = "x", dayXp = 9999 }, Skip = 7 })
		check("load keeps good entries", l.Ember.xp == 120 and l.Ember.lastUsed == t0 and l.Ember.dayXp == 50)
		check("load repairs numbers, drops bad ids and non-table entries", l["bad id!"] == nil and l.Skip == nil and l.Zap.xp == 0 and l.Zap.lastUsed == 0 and l.Zap.dayXp == B.DAILY_XP_CAP)
		check("load of a non-table is empty", next(B.load(nil)) == nil and next(B.load("x")) == nil)
		check("a loaded xp above the maximum is clamped", B.load({ Ember = { xp = 1e9 } }).Ember.xp == 2250)

		-- T652: hooked behaviour (Shared.ProgressHooks)
		do
			local H = require(Shared.ProgressHooks)
			local T1 = 20000 * DAY + 100
			local d = {}
			H.sanitize(d)
			local ctx = H.start(d, { bond = true }, T1, nil)
			H.event(ctx, "Roll", { pet = "Ember" }, T1 + 10, false)
			H.event(ctx, "Roll", { pet = "Zap" }, T1 + 11, false)
			H.event(ctx, "Merge", { tier = 2, pet = "Ember" }, T1 + 12, false)
			H.event(ctx, "Kill", { kind = "Boss" }, T1 + 13, false)
			H.flush(ctx, T1 + 125)
			check("T652 flush gives each used familiar run + minute + boss xp", d.bond.Zap ~= nil and d.bond.Zap.xp == 10 + 2 + 8, d.bond.Zap and d.bond.Zap.xp)
			check("T652 a merge adds its xp to the familiar involved", d.bond.Ember.xp == 10 + 2 + 3 + 8, d.bond.Ember.xp)
			local before = d.bond.Ember.xp
			local again = H.flush(ctx, T1 + 500)
			check("T652 a second flush adds nothing", again.gems == 0 and d.bond.Ember.xp == before)
			local d2 = { bond = { Ember = { xp = 48, lastUsed = T1 - 100, day = 20000, dayXp = 0 } } }
			H.sanitize(d2)
			local c2 = H.start(d2, { bond = true }, T1, nil)
			H.event(c2, "Roll", { pet = "Ember" }, T1, false)
			local o2 = H.flush(c2, T1)
			check("T652 reaching level 2 pays its gems and sends a Bond event", o2.gems == B.REWARD[2] and o2.events[1] ~= nil and o2.events[1].kind == "Bond" and o2.events[1].payload.level == 2)
			local d3 = {}
			H.sanitize(d3)
			local c3 = H.start(d3, { bond = true }, T1, nil)
			H.event(c3, "Roll", { pet = "Ember" }, T1, false)
			for i = 1, 90 do
				H.event(c3, "Merge", { tier = 2, pet = "Ember" }, T1 + i, false)
			end
			H.flush(c3, T1 + 600)
			check("T652 the daily cap still binds through the hook", d3.bond.Ember.xp <= B.DAILY_XP_CAP, d3.bond.Ember.xp)
			local d4 = {}
			H.sanitize(d4)
			local c4 = H.start(d4, { bond = false }, T1, nil)
			H.event(c4, "Roll", { pet = "Ember" }, T1, false)
			local o4 = H.flush(c4, T1 + 600)
			check("T652 flag off: no bond xp, no gems", next(d4.bond) == nil and o4.gems == 0)
			local d5 = {}
			H.sanitize(d5)
			local c5 = H.start(d5, { bond = true }, T1, nil)
			H.event(c5, "Roll", { pet = "bad id!" }, T1, false)
			check("T652 a bad familiar id is refused by Bond and the flush does not crash", pcall(function() H.flush(c5, T1 + 100) end) and next(d5.bond) == nil)
		end
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL test crashed: " .. tostring(err))
	end
	return (failed == 0 and "PASS" or "FAIL") .. " Bond: " .. (#results - failed) .. "/" .. #results .. " checks ok\n" .. table.concat(results, "\n")
end
