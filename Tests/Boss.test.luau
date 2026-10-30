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

		-- T416: lamp, pushes, candles (Config.BOSS_V2) and un-merge (Config.BOSS_UNMERGE), both off by default
		check("BOSS_V2 and BOSS_UNMERGE are off by default", Config.BOSS_V2 == false and Config.BOSS_UNMERGE == false)
		local pet1 = next(Config.PETS)
		local function toPhase2(sim, e)
			sim.crystalHp = 1e9
			sim:damage(e, e.maxHp * 0.40, false)
		end

		-- flags off: nothing new happens
		local s1 = newSim(10)
		local a1 = runUntilBoss(s1)
		toPhase2(s1, a1)
		s1.crystalHp = 10
		s1:bossTick(a1, 14)
		check("flag off: the Automaton's lamp does not heal", s1.crystalHp == 10 and (function()
			for _, ev in events do
				if ev.kind == "BossFx" and ev.p.kind == "lamp" then
					return false
				end
			end
			return true
		end)())

		-- Automaton lamp
		Config.BOSS_V2 = true
		local s2 = newSim(10)
		local a2 = runUntilBoss(s2)
		s2.crystalHp = 10
		s2:bossTick(a2, 14)
		check("Automaton phase 1 has no lamp", s2.crystalHp == 10)
		toPhase2(s2, a2)
		s2.crystalHp = 10
		s2:bossTick(a2, 14)
		check("Automaton phase 2 lamp heals one life", s2.crystalHp == 11, s2.crystalHp)
		s2.crystalHp = s2:maxHp()
		s2:bossTick(a2, 14)
		check("the lamp never heals above the maximum", s2.crystalHp == s2:maxHp(), s2.crystalHp)

		-- Echo pushes
		local s3 = newSim(15)
		s3.coins, s3.gems = 1e6, 1e6
		s3:roll()
		s3:roll()
		local a3 = runUntilBoss(s3)
		s3.crystalHp = 1e9
		local snapPos = {}
		for id, u in s3.grid do
			snapPos[id] = { u.x, u.z }
		end
		events = {}
		s3:bossTick(a3, 9)
		local pushes, movedOrStunned = 0, false
		for _, ev in events do
			if ev.kind == "BossFx" and ev.p.kind == "push" then
				pushes += 1
				local u, was = s3.grid[ev.p.slot], snapPos[ev.p.slot]
				local d = math.sqrt((u.x - was[1]) ^ 2 + (u.z - was[2]) ^ 2)
				movedOrStunned = (ev.p.moved and math.abs(d - 6) < 1e-3) or (not ev.p.moved and (u.disabledUntil or 0) > s3.t)
			end
		end
		check("Echo phase 1 pushes one unit, six studs away or stunned", pushes == 1 and movedOrStunned, pushes)
		toPhase2(s3, a3)
		events = {}
		s3:bossTick(a3, 9)
		check("Echo phase 2 pushes in pairs", (function()
			local n = 0
			for _, ev in events do
				if ev.kind == "BossFx" and ev.p.kind == "push" then
					n += 1
				end
			end
			return n == 2
		end)())
		Config.BOSS_V2 = false
		local s3b = newSim(15)
		s3b.coins, s3b.gems = 1e6, 1e6
		s3b:roll()
		local a3b = runUntilBoss(s3b)
		s3b.crystalHp = 1e9
		events = {}
		s3b:bossTick(a3b, 9)
		check("flag off: no pushes", (function()
			for _, ev in events do
				if ev.kind == "BossFx" and ev.p.kind == "push" then
					return false
				end
			end
			return true
		end)())

		-- Regent candles
		Config.BOSS_V2 = true
		local s4 = newSim(20)
		local a4 = runUntilBoss(s4)
		toPhase2(s4, a4)
		local function hit(sim, e)
			local h = e.hp
			sim:damage(e, 100, false)
			return h - e.hp
		end
		check("no candle lit at the start of phase 2: full damage", math.abs(hit(s4, a4) - 100) < 1e-6)
		local function ticks(sim, e, dt, n)
			for _ = 1, n do
				sim:bossTick(e, dt)
			end
		end
		ticks(s4, a4, 2, 3) -- one candle per call that is due: three candles
		check("three candles take 24%, not a flat 85%", math.abs(hit(s4, a4) - 76) < 1e-6)
		ticks(s4, a4, 2, 12)
		check("candles stop at seven (44% damage taken)", a4.boss.lit == 7 and math.abs(hit(s4, a4) - 44) < 1e-6, a4.boss.lit)
		-- killing a mourner snuffs one
		s4.queue = {}
		table.insert(s4.queue, { at = s4.t, kind = "Grunt", stage = 20, mourner = true })
		s4:step(0.1)
		local mourner
		for _, en in s4.enemies do
			if en.mourner then
				mourner = en
			end
		end
		check("a summoned Grunt is marked as a mourner", mourner ~= nil)
		if mourner then
			local lit0 = a4.boss.lit
			s4:damage(mourner, mourner.maxHp * 10, false)
			check("killing a mourner snuffs one candle", a4.boss.lit == lit0 - 1, a4.boss.lit)
		end
		Config.BOSS_V2 = false
		local s5 = newSim(20)
		local a5 = runUntilBoss(s5)
		toPhase2(s5, a5)
		ticks(s5, a5, 2, 12)
		check("flag off: the Regent still takes a flat 85%", math.abs(hit(s5, a5) - 85) < 1e-6)

		-- Clockmaker un-merge
		local function mergedSim()
			local sim = newSim(25)
			for i = 1, 3 do
				local x, z = sim:findSpot(pet1)
				local id = sim:addUnit(pet1, x, z)
				if i == 1 then
					sim.grid[id].tier = 2
				end
			end
			local e = runUntilBoss(sim)
			sim.crystalHp = 1e9
			return sim, e
		end
		local s6, a6 = mergedSim()
		s6:bossTick(a6, 20)
		check("BOSS_UNMERGE off: nothing is un-merged", s6:unitCount() == 3)
		Config.BOSS_UNMERGE = true
		local s7, a7 = mergedSim()
		s7:bossTick(a7, 20)
		local tiers = 0
		for _, u in s7.grid do
			tiers += u.tier
		end
		check("the Clockmaker un-merges a tier 2 unit into three tier 1 units", s7:unitCount() == 5 and tiers == 5, s7:unitCount() .. "/" .. tiers)
		local s8, a8 = mergedSim()
		while s8:unitCount() < Config.MAX_UNITS - 1 do
			local x, z = s8:findSpot(pet1)
			if not x then
				break
			end
			s8:addUnit(pet1, x, z)
		end
		local n8 = s8:unitCount()
		check("no room: the un-merge is skipped and nothing is lost", n8 >= Config.MAX_UNITS - 1 and s8:unmerge(a8) == false and s8:unitCount() == n8)
		Config.BOSS_UNMERGE = false
	end)
	tmp:Destroy()
	if not ok then
		failed += 1
		table.insert(results, "FAIL test crashed: " .. tostring(err))
	end
	return (failed == 0 and "PASS" or "FAIL") .. " Boss: " .. (#results - failed) .. "/" .. #results .. " checks ok\n" .. table.concat(results, "\n")
end
