--!nocheck
-- Headless checks for Shared.Quests (T023): 10 daily + 10 story quests, the daily draw, rollover, claims, input cleaning, save load.
-- Run in Studio (Edit mode) with execute_luau, serving Tests/ locally (see RunAll.luau).

return function(Shared)
	local Q = require(Shared.Quests)
	local Lore = require(Shared.LoreFragments)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end

	local ok, err = pcall(function()
		check("ten daily and ten story quests", #Q.daily == 10 and #Q.story == 10)
		local seen, bad = {}, 0
		for _, q in Q.daily do
			if seen[q.id] or not Q.dailyStats[q.stat] or q.goal < 1 or q.gems < 10 or q.gems > 30 then
				bad += 1
			end
			seen[q.id] = true
		end
		check("daily rows: unique ids, known stats, small rewards", bad == 0, bad)
		local gems, sp, loreBad = 0, 0, 0
		local fragments = {}
		for _, f in Lore.list do
			fragments[f.id] = true
		end
		for _, q in Q.story do
			if seen[q.id] or not Q.lifeStats[q.stat] or not q.lore or not fragments[q.lore] then
				loreBad += 1
			end
			seen[q.id] = true
			gems += q.gems
			sp += q.sp
		end
		check("story rows: unique ids, life stats, every lore fragment id exists", loreBad == 0, loreBad)
		check("story set pays 300 gems and 2 skill points", gems == 300 and sp == 2, gems .. "/" .. sp)

		-- the daily draw
		local ids = Q.dailyIds(20000)
		local d = {}
		for _, id in ids do
			d[id] = true
		end
		check("three distinct dailies each day", #ids == 3 and (function()
			local n = 0
			for _ in d do
				n += 1
			end
			return n == 3
		end)())
		check("the draw is the same on every call", table.concat(ids, ",") == table.concat(Q.dailyIds(20000), ","))
		local differs, all = false, {}
		for day = 20000, 20030 do
			if table.concat(Q.dailyIds(day), ",") ~= table.concat(ids, ",") then
				differs = true
			end
			for _, id in Q.dailyIds(day) do
				all[id] = true
			end
		end
		local covered = 0
		for _ in all do
			covered += 1
		end
		check("the draw changes from day to day and reaches all ten over a month", differs and covered == 10, covered)

		-- rollover
		local now = 20000 * 86400 + 100
		local s = Q.new()
		check("first rollover starts the day", Q.rollover(s, now) and s.day == 20000)
		check("same day: no reset", Q.rollover(s, now + 3600) == false)
		Q.record(s, "rolls", 7)
		Q.setMax(s, "bestStage", 6)
		check("a clock that goes backwards does not reset", Q.rollover(s, now - 86400) == false and s.stats.rolls == 7)
		Q.rollover(s, now + 86400)
		check("next day: daily progress resets, story life stat stays", s.stats.rolls == nil and s.life.bestStage == 6 and s.day == 20001)

		-- progress and claims
		local p = Q.new()
		Q.rollover(p, now)
		local today = Q.dailyIds(20000)
		local pick = today[1]
		local def = Q.byId[pick]
		check("a daily of today is active, one outside the draw is not", Q.isActive(p, pick) and not Q.isActive(p, (function()
			for _, q in Q.daily do
				if not table.find(today, q.id) then
					return q.id
				end
			end
		end)()))
		local okc, why = Q.claim(p, pick)
		check("an unfinished quest cannot be claimed", okc == false and why == "Not finished")
		local function feed(sim, q)
			if Q.dailyStats[q.stat] == "count" then
				Q.record(sim, q.stat, q.goal)
			else
				Q.setMax(sim, q.stat, q.goal)
			end
		end
		feed(p, def)
		local prog, goal, done = Q.status(p, pick)
		check("status shows full progress", prog == goal and done == true)
		local okc2, _, reward = Q.claim(p, pick)
		check("a finished daily pays its reward once", okc2 and reward.gems == def.gems and reward.bp == def.bp)
		local okc3, why3 = Q.claim(p, pick)
		check("a second claim is refused", okc3 == false and why3 == "Already claimed")
		for _, q in Q.daily do
			if not table.find(today, q.id) then
				feed(p, q)
				local o, w = Q.claim(p, q.id)
				check("a finished quest outside today's draw cannot be claimed", o == false and w == "Not one of today's quests")
				break
			end
		end
		check("unknown or non-string ids are refused", Q.claim(p, "Z9") == false and Q.claim(p, 5) == false and Q.claim(p, nil) == false)
		Q.rollover(p, now + 86400)
		check("claims reset on a new day", next(p.claimed) == nil)

		-- story quests
		local st = Q.new()
		Q.rollover(st, now)
		Q.setMax(st, "bestStage", 5)
		local o1, _, r1 = Q.claim(st, "S2")
		check("reaching stage 5 finishes Meet the Unbound and pays 25 gems + lore", o1 and r1.gems == 25 and r1.lore == "LF-C1-11")
		check("clearing needs bestCleared, not bestStage", select(1, Q.claim(st, "S1")) == false)
		Q.setMax(st, "bestCleared", 25)
		Q.setMax(st, "bestStage", 26)
		local total, spTotal = 0, 0
		for _, q in Q.story do
			local o, _, r = Q.claim(st, q.id)
			if o then
				total += r.gems
				spTotal += r.sp
			end
		end
		check("all ten story quests can be finished and paid (S2 was paid before)", total == 275 and spTotal == 2, total .. "/" .. spTotal)
		check("a story quest keeps its claim across days", (function()
			Q.rollover(st, now + 5 * 86400)
			return select(1, Q.claim(st, "S10")) == false
		end)())

		-- input cleaning
		local c = Q.new()
		Q.rollover(c, now)
		check("record refuses unknown, max-kind, negative, NaN, infinite and text", not Q.record(c, "bestStage", 1) and not Q.record(c, "streak", 1) and not Q.record(c, "rolls", -1) and not Q.record(c, "rolls", 0 / 0) and not Q.record(c, "rolls", math.huge) and not Q.record(c, "rolls", "5") and not Q.record(c, nil, 1))
		check("setMax refuses unknown stats and count stats", not Q.setMax(c, "rolls", 5) and not Q.setMax(c, "junk", 5) and not Q.setMax(c, "streak", -2))
		Q.record(c, "rolls", 1e9)
		check("one call adds at most the step cap", c.stats.rolls == Q.STEP_CAP)
		Q.setMax(c, "streak", 6)
		Q.setMax(c, "streak", 3)
		check("a max stat never falls", c.stats.streak == 6)

		-- saved data
		local l = Q.load({ day = 20000, stats = { rolls = 4, junk = 9, streak = -1 }, life = { bestStage = 12, nope = 1 }, claimed = { D1 = true, S1 = true, Z = true }, storyClaimed = { S1 = true, D1 = true } })
		check("load keeps good values", l.day == 20000 and l.stats.rolls == 4 and l.life.bestStage == 12 and l.claimed.D1 == true and l.storyClaimed.S1 == true)
		check("load drops junk stats, bad numbers, unknown ids and wrong-kind claims", l.stats.junk == nil and l.stats.streak == nil and l.life.nope == nil and l.claimed.S1 == nil and l.claimed.Z == nil and l.storyClaimed.D1 == nil)
		check("load of a non-table is a fresh state", Q.load(nil).day == 0 and next(Q.load(3).stats) == nil)

		-- T652: hooked behaviour (Shared.ProgressHooks)
		do
			local H = require(Shared.ProgressHooks)
			local LR = require(Shared.LeaderboardRules)
			local T0 = 20000 * 86400 + 5
			local d = {}
			H.sanitize(d)
			local ctx = H.start(d, { quests = true }, T0, { userId = 77 })
			check("T652 start rolls the quest day over to today", d.quests.day == 20000)
			local sent = {}
			local function feed(kind, p)
				for _, e in H.event(ctx, kind, p, T0 + 30, false).events do
					table.insert(sent, e)
				end
			end
			-- drive each daily stat to its goal with real event kinds (factionsInRun needs a sim, covered in ServerRules)
			local drive = {
				rolls = function() feed("Roll", { pet = "Ember" }) end, merges = function() feed("Merge", { tier = 2, pet = "Ember" }) end,
				stagesCleared = function() feed("Clear", { stage = 1, perfect = false }) end, bossKills = function() feed("Kill", { kind = "Boss" }) end,
				perfectStages = function() feed("Clear", { stage = 1, perfect = true }) end, lanternUses = function() feed("Lantern", {}) end,
				recycles = function() feed("Recycle", {}) end, upgradeLevel = function() feed("Upgrade", { level = 3 }) end,
				streak = function() feed("Clear", { stage = 1, perfect = true }) end,
			}
			local covered = 0
			for _, id in Q.dailyIds(20000) do
				local q = Q.byId[id]
				if drive[q.stat] then
					for _ = 1, q.goal do
						drive[q.stat]()
					end
					covered += 1
					local _, _, done = Q.status(d.quests, id)
					check("T652 daily " .. id .. " (" .. q.stat .. ") completes from its events", done)
				end
			end
			check("T652 at least two of today's dailies could be driven", covered >= 2, covered)
			local counts = {}
			for _, e in sent do
				if e.kind == "Quest" then
					counts[e.payload.id] = (counts[e.payload.id] or 0) + 1
				end
			end
			local once = true
			for _, n in counts do
				once = once and n == 1
			end
			check("T652 each Quest event fires exactly once", next(counts) ~= nil and once)
			local first = Q.dailyIds(20000)[1]
			local okc, _, outc = H.claimQuest(ctx, first)
			if drive[Q.byId[first].stat] then
				check("T652 claimQuest pays a finished daily once", okc and outc.gems == Q.byId[first].gems and outc.events[1].kind == "QuestClaimed")
				local ok2, why2 = H.claimQuest(ctx, first)
				check("T652 the same claim twice is refused", ok2 == false and why2 == "Already claimed")
			end
			local bad, why = H.claimQuest(ctx, "Z9")
			check("T652 claimQuest refuses an unknown quest", bad == false and why == "Unknown quest")
			-- flag off
			local d2 = {}
			H.sanitize(d2)
			local c2 = H.start(d2, { quests = false }, T0, nil)
			H.event(c2, "Clear", { stage = 3, perfect = true }, T0, false)
			local okOff, whyOff = H.claimQuest(c2, "S1")
			check("T652 flag off: no progress and claims are refused", next(d2.quests.stats) == nil and next(d2.quests.life) == nil and okOff == false and whyOff == "Quests are off")
			-- story quest S1 from the first Clear
			local d3 = {}
			H.sanitize(d3)
			local c3 = H.start(d3, { quests = true }, T0, nil)
			local o3 = H.event(c3, "Clear", { stage = 1, perfect = false }, T0, false)
			local s1 = false
			for _, e in o3.events do
				s1 = s1 or (e.kind == "Quest" and e.payload.id == "S1")
			end
			local okS, _, outS = H.claimQuest(c3, "S1")
			check("T652 a first Clear completes story quest S1; claimQuest pays its gems and skill points", s1 and okS and outS.gems == Q.byId.S1.gems and outS.sp == (Q.byId.S1.sp or 0))
			-- next day: dailies reset, story claim stays
			H.start(d3, { quests = true }, T0 + 86400, nil)
			check("T652 next day: dailies reset, story claim stays", d3.quests.day == 20001 and next(d3.quests.stats) == nil and d3.quests.storyClaimed.S1 == true)
			-- leaderboard hook
			local d5 = {}
			H.sanitize(d5)
			local start = math.max(LR.weekStart(LR.weekKey(T0)), T0 - 1000)
			local c5 = H.start(d5, { leaderboard = true }, start, { userId = 12 })
			H.event(c5, "Clear", { stage = 2, perfect = false }, start + 5, false)
			check("T652 a run too short for its wave is refused by LeaderboardRules", c5.lbPending == nil)
			H.event(c5, "Clear", { stage = 3, perfect = false }, start + 120, false)
			check("T652 a plausible clear is accepted and waits in memory only (no DataStore)", c5.lbPending ~= nil and c5.lbPending.wave == 3 and c5.lbPending.week == LR.weekKey(start + 120))
			H.event(c5, "Clear", { stage = 4, perfect = false }, start + 130, false)
			check("T652 a second submit inside the 20 s gap is refused", c5.lbPending.wave == 3)
			H.event(c5, "Clear", { stage = 5, perfect = false }, start + 200, false)
			check("T652 a later, better clear replaces it", c5.lbPending.wave == 5)
			local c6 = H.start({}, { leaderboard = false }, start, { userId = 12 })
			H.event(c6, "Clear", { stage = 3, perfect = false }, start + 120, false)
			check("T652 leaderboard flag off: no submit", c6.lbPending == nil)
		end
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL test crashed: " .. tostring(err))
	end
	return (failed == 0 and "PASS" or "FAIL") .. " Quests: " .. (#results - failed) .. "/" .. #results .. " checks ok\n" .. table.concat(results, "\n")
end
