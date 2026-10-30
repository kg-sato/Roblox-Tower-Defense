--!nocheck
-- Headless checks for endless mode (T016, Config.ENDLESS): hp scaling past stage 25, spawn lists and the boss cycle to wave 100, and a full sim sweep
-- of stages 26 to 100 (every enemy is killed the moment it spawns, so this tests the stage loop and numbers, not player strength).
-- Run in Studio (Edit mode) with execute_luau, serving Tests/ locally (see RunAll.luau). It clones Config/Path/MatchSim, so nothing is changed.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_EndlessTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim" } do
		Shared[n]:Clone().Parent = tmp
	end
	local Config = require(tmp.Config)
	local MatchSim = require(tmp.MatchSim)

	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end

	-- plays stages `from` to `to` with every enemy killed as it spawns; returns stats
	local function sweep(from, to, seed)
		local events = {}
		local sim = MatchSim.new(Random.new(seed), function(kind, p)
			table.insert(events, { kind = kind, p = p })
		end, false)
		sim.stage = from
		sim:setAuto(false)
		sim.crystalHp = 1e9
		local st = { spawns = 0, bosses = 0, bossNames = {}, clears = 0, badHp = 0, maxHp = 0, steps = 0, stuck = false, escaped = 0, overrun = 0 }
		while sim.stage <= to do
			local stage = sim.stage
			local ok, why = sim:startWave()
			if not ok then
				st.stuck = tostring(why)
				break
			end
			for _ = 1, 20000 do
				sim:step(0.1)
				st.steps += 1
				for _, e in sim.enemies do
					if not e.dead then
						if e.hp ~= e.hp or e.hp == math.huge or e.hp <= 0 then
							st.badHp += 1
						end
						st.maxHp = math.max(st.maxHp, e.maxHp)
						sim:damage(e, e.hp + 1, false)
					end
				end
				sim:cleanup()
				sim.crystalHp = 1e9
				if sim.stage > stage then
					break
				end
			end
			if sim.stage == stage then
				st.stuck = "stage " .. stage .. " did not clear"
				break
			end
		end
		for _, ev in events do
			if ev.kind == "Spawn" then
				st.spawns += 1
				if ev.p.kind == "Boss" then
					st.bosses += 1
					st.bossNames[ev.p.boss or "plain"] = (st.bossNames[ev.p.boss or "plain"] or 0) + 1
				end
			elseif ev.kind == "Clear" then
				st.clears += 1
			elseif ev.kind == "BossEscaped" then
				st.escaped += 1
			elseif ev.kind == "Overrun" then
				st.overrun += 1
			end
		end
		st.sim = sim
		return st
	end

	local ok, err = pcall(function()
		check("endless is off by default", Config.ENDLESS == false)
		check("flag off: hp scaling is the old exponent up to stage 100", (function()
			for s = 1, 100 do
				if Config.hpScale(s) ~= Config.HP_GROWTH ^ (s - 1) then
					return false
				end
			end
			return true
		end)())
		local offAt100 = Config.hpScale(100)

		Config.ENDLESS = true
		local same, mono, finite = true, true, true
		local prev = 0
		for s = 1, 100 do
			local h = Config.hpScale(s)
			if s <= Config.ENDLESS_FROM and h ~= Config.HP_GROWTH ^ (s - 1) then
				same = false
			end
			if h <= prev then
				mono = false
			end
			if h ~= h or h == math.huge then
				finite = false
			end
			prev = h
		end
		check("flag on: stages 1 to 25 are unchanged", same)
		check("flag on: hp rises every stage from 1 to 100 and stays finite", mono and finite)
		check("flag on: stage 26 grows by exactly the endless rate", math.abs(Config.hpScale(26) / Config.hpScale(25) - Config.ENDLESS_GROWTH) < 1e-9)
		check("flag on: stage 100 is far below the old curve and still large", Config.hpScale(100) < offAt100 * 1e-3 and Config.hpScale(100) > Config.hpScale(25) * 100, Config.hpScale(100))

		-- spawn lists and bosses 26 to 100
		local badKind, tooMany, bossWrong = 0, 0, 0
		for s = 26, 100 do
			local list = Config.stageSpawns(s)
			if #list > 29 or #list < 5 then
				tooMany += 1
			end
			for _, k in list do
				if not Config.ENEMIES[k] then
					badKind += 1
				end
			end
			local isBoss = Config.isBossStage(s)
			if isBoss ~= (list[#list] == "Boss") or (isBoss and Config.bossDef(s) == nil) then
				bossWrong += 1
			end
		end
		check("waves 26 to 100: every enemy kind is defined", badKind == 0, badKind)
		check("waves 26 to 100: 5 to 29 enemies each (28 plus the boss)", tooMany == 0, tooMany)
		check("waves 26 to 100: a boss exactly on every fifth stage", bossWrong == 0, bossWrong)
		check("the boss cycle carries on: 30 is the first boss again, 35 the second, 100 the fifth", Config.bossDef(30).id == Config.BOSSES[1].id and Config.bossDef(35).id == Config.BOSSES[2].id and Config.bossDef(100).id == Config.BOSSES[5].id, Config.bossDef(100).id)

		-- the full sim sweep, stage 26 to 100
		local st = sweep(26, 100, 7)
		check("sim sweep 26 to 100: every wave cleared, no stuck stage", st.stuck == false and st.clears == 75 and st.sim.stage == 101, tostring(st.stuck) .. " clears " .. st.clears)
		check("sim sweep: no NaN, infinite or non-positive enemy hp", st.badHp == 0, st.badHp)
		check("sim sweep: 15 bosses (stages 30, 35 ... 100) with the phase framework", st.bosses == 15 and st.escaped == 0 and st.overrun == 0, st.bosses)
		check("sim sweep: the biggest hp seen is finite and matches the curve", st.maxHp > 0 and st.maxHp < 1e9, st.maxHp)
		check("sim sweep: coins and gems stay finite numbers", st.sim.coins == st.sim.coins and st.sim.coins < math.huge and st.sim.gems == st.sim.gems and st.sim.gems < math.huge)
		check("sim sweep: bestStage follows to 101", st.sim.bestStage >= 101, st.sim.bestStage)

		-- with the other wave flags on as well
		Config.WAVES_V2, Config.SKY_ON, Config.HOLLOW_ENEMIES, Config.NEW_ENEMIES = true, true, true, true
		local st2 = sweep(26, 100, 11)
		check("sim sweep 26 to 100 with WAVES_V2, SKY_ON, HOLLOW and NEW enemies on", st2.stuck == false and st2.clears == 75 and st2.badHp == 0 and st2.sim.stage == 101, tostring(st2.stuck) .. " clears " .. st2.clears)
		Config.WAVES_V2, Config.SKY_ON, Config.HOLLOW_ENEMIES, Config.NEW_ENEMIES = false, false, false, false
		Config.ENDLESS = false
		local st3 = sweep(26, 40, 3)
		check("flag off: the same sweep still runs (the old curve is only steeper)", st3.stuck == false and st3.clears == 15 and st3.badHp == 0)
	end)
	tmp:Destroy()
	if not ok then
		failed += 1
		table.insert(results, "FAIL test crashed: " .. tostring(err))
	end
	return (failed == 0 and "PASS" or "FAIL") .. " Endless: " .. (#results - failed) .. "/" .. #results .. " checks ok\n" .. table.concat(results, "\n")
end
