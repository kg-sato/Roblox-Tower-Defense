--!nocheck
-- Headless checks for Shared.Achievements (T002): 30 data rows, count/max stats, once-only unlocks, input cleaning, save load.
-- Run in Studio (Edit mode) with execute_luau, serving Tests/ locally (see RunAll.luau).

return function(Shared)
	local A = require(Shared.Achievements)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end

	local ok, err = pcall(function()
		check("exactly 30 achievements", #A.list == 30, #A.list)
		local ids, bad, gems = {}, 0, 0
		for _, a in A.list do
			if ids[a.id] or not A.stats[a.stat] or type(a.name) ~= "string" or a.goal < 1 or a.gems < 1 or a.gems > 60 then
				bad += 1
			end
			ids[a.id] = true
			gems += a.gems
		end
		check("ids unique, stats known, goals and gem rewards sane", bad == 0, bad)
		check("all rewards together stay small (under 700 gems)", gems < 700, gems)

		local s = A.new()
		check("a new state unlocks nothing", #(A.unlock(s)) == 0)
		check("record adds to a count stat", A.record(s, "rolls", 1) and s.stats.rolls == 1)
		local fresh, g = A.unlock(s)
		check("one roll unlocks First Summon for 5 gems", #fresh == 1 and fresh[1] == "FirstSummon" and g == 5, tostring(fresh[1]) .. "/" .. g)
		fresh, g = A.unlock(s)
		check("an achievement unlocks only once", #fresh == 0 and g == 0)
		A.record(s, "rolls", 24)
		fresh, g = A.unlock(s)
		check("25 rolls unlock Summoner only", #fresh == 1 and fresh[1] == "Summoner" and g == 10)
		A.record(s, "rolls", 500)
		fresh = A.unlock(s)
		check("several thresholds in one call unlock together", table.find(fresh, "Conjurer") ~= nil)

		-- input cleaning
		local before = s.stats.rolls
		check("unknown stat refused", A.record(s, "coins", 5) == false)
		check("a max stat cannot be added to", A.record(s, "bestStage", 5) == false and s.stats.bestStage == nil)
		check("a count stat cannot be set as max", A.setMax(s, "rolls", 999) == false and s.stats.rolls == before)
		check("negative, NaN, infinite and text amounts refused", not A.record(s, "rolls", -3) and not A.record(s, "rolls", 0 / 0) and not A.record(s, "rolls", math.huge) and not A.record(s, "rolls", "9") and not A.record(s, 5, 1) and s.stats.rolls == before)
		A.record(s, "rolls", 1e9)
		check("one call adds at most the step cap", s.stats.rolls == before + A.STEP_CAP, s.stats.rolls - before)
		A.record(s, "merges", 2.9)
		check("fractions round down", s.stats.merges == 2)

		-- max stats
		local m = A.new()
		A.setMax(m, "bestStage", 12)
		A.setMax(m, "bestStage", 7)
		check("a max stat never goes down", m.stats.bestStage == 12)
		fresh = A.unlock(m)
		check("best stage 12 unlocks the 5 and 10 stage rows only", table.find(fresh, "MetTheUnbound") and table.find(fresh, "AcrossTheHarbour") and not table.find(fresh, "ChoirHeard"))
		A.setMax(m, "bestStage", 26)
		fresh = A.unlock(m)
		check("reaching stage 26 unlocks Past the Clock", table.find(fresh, "PastTheClock") ~= nil)
		check("progress reports capped value and goal", select(1, A.progress(m, "PastTheClock")) == 26 and select(2, A.progress(m, "PastTheClock")) == 26)
		local p, goal = A.progress(A.new(), "Keeper")
		check("progress of an untouched row", p == 0 and goal == 100)
		check("progress of an unknown id is 0, 0", select(2, A.progress(A.new(), "Nope")) == 0)

		-- every row can be reached with the right stat
		local all = A.new()
		for _, a in A.list do
			if A.stats[a.stat] == "count" then
				while (all.stats[a.stat] or 0) < a.goal do
					A.record(all, a.stat, math.min(a.goal, A.STEP_CAP))
				end
			else
				A.setMax(all, a.stat, a.goal)
			end
		end
		local freshAll, gAll = A.unlock(all)
		check("every one of the 30 can be unlocked", #freshAll == 30 and gAll == gems, #freshAll)

		-- saved data
		local loaded = A.load({ stats = { rolls = 40, junk = 5, bestStage = -3, merges = "x" }, unlocked = { FirstSummon = true, Fake = true, Summoner = "yes" } })
		check("load keeps known good values", loaded.stats.rolls == 40 and loaded.unlocked.FirstSummon == true)
		check("load drops unknown stats, bad numbers, unknown ids and non-true flags", loaded.stats.junk == nil and loaded.stats.bestStage == nil and loaded.stats.merges == nil and loaded.unlocked.Fake == nil and loaded.unlocked.Summoner == nil)
		check("load of a non-table gives a fresh state", next(A.load(nil).stats) == nil and next(A.load(7).unlocked) == nil)
		local again = A.unlock(loaded)
		check("a loaded state does not re-pay an unlocked row", not table.find(again, "FirstSummon"))

		-- T652: hooked behaviour (Shared.ProgressHooks)
		do
			local H = require(Shared.ProgressHooks)
			local T0 = 20000 * 86400
			local function fresh(flags)
				local d = {}
				H.sanitize(d)
				return d, H.start(d, flags, T0, { userId = 9 })
			end
			local on = { achievements = true }
			local d, ctx = fresh(on)
			local out = H.event(ctx, "Roll", { pet = "Ember" }, T0 + 1, false)
			check("T652 first roll unlocks FirstSummon: gems and one Achievement event", out.gems == 5 and #out.events == 1 and out.events[1].kind == "Achievement" and out.events[1].payload.id == "FirstSummon" and out.events[1].payload.gems == 5)
			local again = H.event(ctx, "Roll", { pet = "Ember" }, T0 + 2, false)
			check("T652 an unlocked row is not paid or sent twice", again.gems == 0 and #again.events == 0)
			local rollsBefore = d.achievements.stats.rolls
			H.event(ctx, "Roll", { pet = "Ember", bonus = true }, T0 + 3, false)
			check("T652 a bonus roll is not counted as a roll", d.achievements.stats.rolls == rollsBefore)
			H.event(ctx, "Merge", { tier = 3, pet = "Ember" }, T0 + 4, false)
			check("T652 merge counts and raises maxTier; TierThree and FirstMerge unlock", d.achievements.stats.merges == 1 and d.achievements.stats.maxTier == 3 and d.achievements.unlocked.TierThree == true and d.achievements.unlocked.FirstMerge == true)
			H.event(ctx, "Kill", { kind = "Grunt" }, T0 + 5, false)
			check("T652 a non-boss kill is not a boss kill", d.achievements.stats.bossKills == nil)
			local k = H.event(ctx, "Kill", { kind = "Boss" }, T0 + 6, false)
			check("T652 a boss kill counts and unlocks BossBane", d.achievements.stats.bossKills == 1 and k.events[1] ~= nil and k.events[1].payload.id == "BossBane")
			H.event(ctx, "Clear", { stage = 1, perfect = true }, T0 + 7, false)
			H.event(ctx, "Clear", { stage = 2, perfect = false }, T0 + 8, false)
			check("T652 clears and perfect stages count; a leak resets the streak", d.achievements.stats.stagesCleared == 2 and d.achievements.stats.perfectStages == 1 and ctx.streak == 0 and d.achievements.stats.bestStreak == 1)
			local d2, c2 = fresh({ achievements = false })
			local o2 = H.event(c2, "Roll", { pet = "Ember" }, T0 + 1, false)
			check("T652 flag off: no counting, no unlock, no gems", next(d2.achievements.stats) == nil and o2.gems == 0 and #o2.events == 0)
			local d3, c3 = fresh(on)
			for i = 1, 25 do
				H.event(c3, "Roll", { pet = "Ember" }, T0 + i, false)
			end
			check("T652 25 rolls unlock Summoner once", d3.achievements.unlocked.Summoner == true and d3.achievements.stats.rolls == 25)
			local saved = A.load(d3.achievements)
			check("T652 a saved state reloads and does not re-pay", saved.unlocked.Summoner == true and #A.unlock(saved) == 0)
		end
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL test crashed: " .. tostring(err))
	end
	return (failed == 0 and "PASS" or "FAIL") .. " Achievements: " .. (#results - failed) .. "/" .. #results .. " checks ok\n" .. table.concat(results, "\n")
end
