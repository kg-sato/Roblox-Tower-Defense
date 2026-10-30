--!nocheck
-- Headless checks for the P3 roll floor (every 10 rolls hold a Rare or better, behind Config.P3_ROLL_FLOOR). Nothing in the game changes: it clones Config, Path, MatchSim, Gacha and Bond.
-- Run through RunAll (serve Tests/ with python -m http.server). Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_P3FloorTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim", "StageSets", "Gacha", "Bond" } do
		Shared[n]:Clone().Parent = tmp
	end
	local Config = require(tmp.Config)
	local MatchSim = require(tmp.MatchSim)
	local Gacha = require(tmp.Gacha)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local events
	local function newSim(seed, tutorial)
		events = {}
		local sim = MatchSim.new(Random.new(seed or 1), function(kind, p)
			table.insert(events, { kind = kind, p = p })
		end, tutorial or false)
		sim.gems = 1e9
		return sim
	end
	-- one roll on a clear board (the unit cap is not under test); returns the rarity and the Roll payload
	local function rollOnce(sim)
		sim.grid = {}
		events = {}
		local ok, why = sim:roll()
		assert(ok, why)
		for _, e in events do
			if e.kind == "Roll" and not e.p.bonus then
				return e.p.rarity, e.p
			end
		end
		error("no Roll event")
	end
	local function order(r)
		return Config.RARITIES[r].order
	end

	local ok, err = pcall(function()
		-- pure module
		local g = Gacha.new()
		check("a fresh state is empty", g.oil == 0 and g.sinceRare == 0 and g.claims == 0)
		local bad = Gacha.load({ oil = -5, sinceRare = 99, claims = 0 / 0 })
		check("load clamps damaged values", bad.oil == 0 and bad.sinceRare == Gacha.FLOOR_EVERY - 1 and bad.claims == 0)
		check("load of a missing field (old profile) gives a fresh state", Gacha.load(nil).oil == 0 and Gacha.load("x").sinceRare == 0)
		check("the floor counter moves only when its flag is on", (function()
			local s = Gacha.new()
			Gacha.afterRoll(s, 1, false, false)
			return s.sinceRare == 0 and s.oil == 0
		end)())
		check("floorDue after 9 dry rolls", (function()
			local s = Gacha.new()
			for _ = 1, 8 do
				Gacha.afterRoll(s, 1, true, false)
			end
			local before = Gacha.floorDue(s)
			Gacha.afterRoll(s, 1, true, false)
			return not before and Gacha.floorDue(s) and Gacha.rollsToFloor(s) == 1
		end)())
		check("weightedPick follows the weights", Gacha.weightedPick({ Rare = 1, Epic = 1 }, { "Rare", "Epic" }, 0.1) == "Rare" and Gacha.weightedPick({ Rare = 1, Epic = 1 }, { "Rare", "Epic" }, 0.9) == "Epic" and Gacha.weightedPick({ Rare = 0, Epic = 1 }, { "Rare", "Epic" }, 0) == "Epic")

		-- flag OFF keeps the old behaviour and never moves the counter
		Config.P3_ROLL_FLOOR = false
		local sim = newSim(11)
		local longestOff, run = 0, 0
		for _ = 1, 4000 do
			local r = rollOnce(sim)
			run = order(r) >= 2 and 0 or run + 1
			longestOff = math.max(longestOff, run)
		end
		check("flag off: dry streaks past 9 still happen (old behaviour)", longestOff > 9, longestOff)
		check("flag off: the counter stays at 0", sim.gacha.sinceRare == 0 and sim.gacha.oil == 0)
		check("flag off: snapshot says off", sim:snapshot().gacha.floorOn == false)

		-- flag ON: every 10 rolls hold at least one Rare or better
		Config.P3_ROLL_FLOOR = true
		sim = newSim(12)
		local longestOn, flooredN, total = 0, 0, 4000
		run = 0
		local rare = 0
		local allFlooredRare = true
		for _ = 1, total do
			local r, p = rollOnce(sim)
			run = order(r) >= 2 and 0 or run + 1
			longestOn = math.max(longestOn, run)
			if p.floored then
				flooredN += 1
				allFlooredRare = allFlooredRare and order(r) >= 2
			end
			if order(r) >= 2 then
				rare += 1
			end
		end
		check("flag on: never more than 9 dry rolls, so every 10 rolls hold a Rare or better", longestOn <= Gacha.FLOOR_EVERY - 1, longestOn)
		check("flag on: the floor fired", flooredN > 0, flooredN)
		check("flag on: every floored roll is Rare or better", allFlooredRare)
		check("flag on: Rare-or-better share is above the 40 percent base odds", rare / total > 0.40, rare / total)
		check("flag on: oil is untouched while P2 is off", sim.gacha.oil == 0)

		-- the counter is saved and loaded; a new run does not reset it
		local m = sim:meta()
		local sim2 = newSim(13)
		sim2:loadMeta(m)
		check("meta() carries the counter and loadMeta restores it", sim2.gacha.sinceRare == sim.gacha.sinceRare)
		local snap = sim2:snapshot().gacha
		check("snapshot shows the rule and the count", snap.floorOn and snap.floorEvery == 10 and snap.sinceRare == sim2.gacha.sinceRare and snap.rollsToFloor == math.max(1, 10 - sim2.gacha.sinceRare))

		-- deterministic: nine dry rolls banked, the 10th must be Rare or better
		local sim3 = newSim(14)
		sim3.gacha.sinceRare = 9
		local r10 = rollOnce(sim3)
		check("with 9 dry rolls banked the next roll is Rare or better", order(r10) >= 2, r10)
		check("and the counter resets", sim3.gacha.sinceRare == 0)

		-- the existing Epic pity still wins when it is due
		local sim4 = newSim(15)
		sim4.sincePity = sim4:pityEvery() - 1
		sim4.gacha.sinceRare = 9
		check("Epic pity still outranks the floor", order(rollOnce(sim4)) >= 3)

		-- tutorial rolls never count
		local tut = newSim(16, true)
		tut.grid = {}
		tut:roll()
		check("a tutorial roll does not move the counter", tut.gacha.sinceRare == 0)
	end)
	Config.P3_ROLL_FLOOR = false
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " P3Floor: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
