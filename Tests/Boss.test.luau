--!nocheck
-- Headless checks for the boss framework (Config.BOSSES, MatchSim bossTick/checkPhase/bossSlow/bossSnapshot).
-- Run in Studio (Edit mode) with execute_luau, serving Tests/ locally (see RunAll.luau). It clones Config/Path/MatchSim, so nothing is changed.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_BossTest"
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

	local ok, err = pcall(function()
		check("five boss definitions", #Config.BOSSES == 5, #Config.BOSSES)
		for i, b in Config.BOSSES do
			check("boss " .. i .. " has three phases at 1, 0.66, 0.33", #b.phases == 3 and b.phases[1].at == 1 and b.phases[2].at == 0.66 and b.phases[3].at == 0.33, b.id)
			check("boss " .. i .. " has hpMult and rewardMult", b.hpMult > 0 and b.rewardMult > 0, b.id)
		end
		check("stage 5 is boss 1, stage 25 is boss 5, stage 30 repeats boss 1", Config.bossDef(5).id == Config.BOSSES[1].id and Config.bossDef(25).id == Config.BOSSES[5].id and Config.bossDef(30).id == Config.BOSSES[1].id)

		local events = {}
		local function newSim(stage)
			events = {}
			local sim = MatchSim.new(Random.new(1), function(kind, p)
				table.insert(events, { kind = kind, p = p })
			end, false)
			sim.stage = stage
			sim:setAuto(false)
			return sim
		end
		local function boss(sim)
			for _, e in sim.enemies do
				if e.kind == "Boss" then
					return e
				end
			end
		end
		local function count(kind)
			local n = 0
			for _, ev in events do
				if ev.kind == kind then
					n += 1
				end
			end
			return n
		end
		local function runUntilBoss(sim)
			sim:startWave()
			for _ = 1, 4000 do
				sim:step(0.1)
				if boss(sim) then
					return boss(sim)
				end
			end
		end

		-- spawn: hp multiplier, boss state, snapshot
		local sim = newSim(10)
		local e = runUntilBoss(sim)
		check("a boss spawns on stage 10", e ~= nil)
		local base = Config.ENEMIES.Boss.hp * Config.hpScale(10)
		check("boss hp uses the definition's hpMult", math.abs(e.maxHp - base * Config.bossDef(10).hpMult) < 1e-6, e.maxHp)
		local snap = sim:snapshot()
		check("snapshot carries the boss (phase 1 of 3)", snap.boss ~= nil and snap.boss.phase == 1 and snap.boss.phases == 3 and snap.boss.id == e.id)
		check("the Spawn event names the boss", events and (function()
			for _, ev in events do
				if ev.kind == "Spawn" and ev.p.kind == "Boss" then
					return ev.p.boss == "Automaton"
				end
			end
		end)())

		-- phases follow hp
		sim.crystalHp = 1e9
		sim:damage(e, e.maxHp * 0.40, false) -- 60% left: past 66%
		check("below 66% hp the boss is in phase 2", e.boss.phase == 2, e.boss.phase)
		check("one BossPhase event for phase 2", count("BossPhase") == 1)
		sim:damage(e, e.maxHp * 0.40, false) -- 20% left: past 33%
		check("below 33% hp the boss is in phase 3", e.boss.phase == 3, e.boss.phase)
		check("two BossPhase events in total", count("BossPhase") == 2)
		sim:damage(e, e.maxHp * 0.01, false)
		check("phases never go back or repeat", e.boss.phase == 3 and count("BossPhase") == 2)

		-- a big hit skips straight through both thresholds
		local sim2 = newSim(10)
		local e2 = runUntilBoss(sim2)
		sim2:damage(e2, e2.maxHp * 0.80, false)
		check("one big hit passes both thresholds, two events", e2.boss.phase == 3 and count("BossPhase") == 2, e2.boss.phase)

		-- rewards scale with rewardMult
		local sim3 = newSim(25)
		local e3 = runUntilBoss(sim3)
		local c0, g0 = sim3.coins, sim3.gems
		sim3:damage(e3, e3.maxHp * 2, false)
		local def = Config.ENEMIES.Boss
		local want = math.floor(def.coins * Config.bossDef(25).rewardMult * (1 + 0.1 * 24) + 0.5)
		check("killing the stage 25 boss pays rewardMult x coins", sim3.coins - c0 == want, (sim3.coins - c0) .. " vs " .. want)
		check("the boss kill still gives a skill point", sim3.sp >= 1)

		-- timed effects: deny disables the newest unit
		local sim4 = newSim(5)
		sim4.coins, sim4.gems = 1e6, 1e6
		sim4:roll()
		sim4:roll()
		local e4 = runUntilBoss(sim4)
		sim4.crystalHp = 1e9
		local newest = 0
		for id in sim4.grid do
			newest = math.max(newest, id)
		end
		for _ = 1, 120 do -- 12 s at 0.1: the phase 1 deny of the Unbound fires every 10 s
			sim4:step(0.1)
		end
		check("deny fired and names the newest unit", (function()
			for _, ev in events do
				if ev.kind == "BossFx" and ev.p.kind == "deny" then
					return ev.p.slot == newest
				end
			end
			return false
		end)())
		check("the denied unit is disabled for a moment", (sim4.grid[newest].disabledUntil or 0) > 0)

		-- freeze disables every unit, speed multiplier moves the boss faster
		local sim5 = newSim(15)
		local e5 = runUntilBoss(sim5)
		check("Echo phase 1 has no speed change", (e5.boss.def.phases[1].fx.speedMult or 1) == 1)
		local sim6 = newSim(20)
		local e6 = runUntilBoss(sim6)
		sim6.crystalHp = 1e9
		sim6:damage(e6, e6.maxHp * 0.7, false) -- phase 3 of the Regent: speedMult 2
		local before = e6.dist
		sim6:step(0.1)
		local moved = e6.dist - before
		check("Regent phase 3 moves at twice the speed", math.abs(moved - Config.ENEMIES.Boss.speed * 2 * 0.1) < 1e-6, moved)

		-- damageTaken: Regent phase 2 takes 85%
		local sim7 = newSim(20)
		local e7 = runUntilBoss(sim7)
		sim7:damage(e7, e7.maxHp * 0.40, false)
		local hp0 = e7.hp
		sim7:damage(e7, 100, false)
		check("Regent phase 2 takes 85% damage", math.abs((hp0 - e7.hp) - 85) < 1e-6, hp0 - e7.hp)

		-- summon adds enemies to the queue
		local sim8 = newSim(20)
		local e8 = runUntilBoss(sim8)
		sim8.crystalHp = 1e9
		for _ = 1, 125 do
			sim8:step(0.1)
		end
		check("the Regent's bell summons Grunts (summon event)", count("BossFx") >= 1)

		-- with the flag off the old generic boss is unchanged
		Config.BOSS_PHASES = false
		local sim9 = newSim(10)
		local e9 = runUntilBoss(sim9)
		check("BOSS_PHASES off: plain boss, no phases, base hp", e9.boss == nil and math.abs(e9.maxHp - Config.ENEMIES.Boss.hp * Config.hpScale(10)) < 1e-6)
		Config.BOSS_PHASES = true
	end)
	tmp:Destroy()
	if not ok then
		failed += 1
		table.insert(results, "FAIL test crashed: " .. tostring(err))
	end
	return (failed == 0 and "PASS" or "FAIL") .. " Boss: " .. (#results - failed) .. "/" .. #results .. " checks ok\n" .. table.concat(results, "\n")
end
