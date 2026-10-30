--!nocheck
-- Headless checks for the server rules (placement, merge, roll cap, empty-rarity fallback, ultimate caster).
-- Run in Studio (Edit mode) with execute_luau:
--   local body = game:GetService("HttpService"):GetAsync("http://127.0.0.1:8765/MatchSim.test.luau")  -- serve Tests/ locally
--   return loadstring(body)()(game.ReplicatedStorage.Shared)
-- or paste the file and call the returned function. It clones Config/Path/MatchSim, so nothing is changed.
-- Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_MatchSimTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim", "StageSets" } do
		Shared[n]:Clone().Parent = tmp
	end
	local Config = require(tmp.Config)
	local MatchSim = require(tmp.MatchSim)

	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail and (" (" .. tostring(detail) .. ")") or ""))
	end
	local function newSim(seed, tutorial)
		return MatchSim.new(Random.new(seed or 1), function() end, tutorial or false)
	end

	local ok, err = pcall(function()
		-- placement rules
		local sim = newSim(1, true)
		for _ = 1, 3 do
			sim:roll()
		end
		local p = Config.PATH[2]
		check("move onto the path is refused", select(1, sim:move(1, p.X, p.Z)) == false)
		check("move out of bounds is refused", select(1, sim:move(1, 500, 0)) == false)
		local u2 = sim.grid[2]
		check("move onto another pet is refused", select(1, sim:move(1, u2.x + 0.5, u2.z)) == false)

		-- merge needs a touching third
		sim:move(3, 30, 12)
		check("merge with no touching pair is refused", select(1, sim:drop(1, 2)) == false)
		sim:move(3, sim.grid[2].x, sim.grid[2].z + 7)
		check("merge with a touching pair works", select(1, sim:drop(1, 2)) == true)
		local count, tier = 0, 0
		for _, u in sim.grid do
			count += 1
			tier = u.tier
		end
		check("a merge leaves one pet of tier 2", count == 1 and tier == 2, count .. "," .. tier)

		-- roll cap and legal spots
		sim.tutorial, sim.forced, sim.gems = false, {}, 1e6
		local rolled = 0
		for _ = 1, Config.MAX_UNITS + 5 do
			if sim:roll() then
				rolled += 1
			end
		end
		local total = 0
		for _ in sim.grid do
			total += 1
		end
		check("roll stops at the unit cap", total == Config.MAX_UNITS, total)
		local bad = 0
		for id, u in sim.grid do
			if not Config.canPlace(sim.grid, u.pet, u.x, u.z, id) then
				bad += 1
			end
		end
		check("every placed pet is on a legal spot", bad == 0, bad)

		-- a pet shoots from its free position and the wave pays out
		local fight = newSim(2, false)
		fight.gems = 1e6
		for _ = 1, 4 do
			fight:roll()
		end
		fight:startWave()
		local c0 = fight.coins
		for _ = 1, 100 do
			fight:step(0.1)
		end
		check("pets placed freely still kill and earn", fight.coins > c0)

		-- empty rarity falls back instead of erroring (audit finding 2)
		local saved = Config.petsOfRarity
		Config.petsOfRarity = function(r)
			return r == "Epic" and {} or saved(r)
		end
		local sim2 = newSim(3, false)
		local pet, rarity = sim2:pickPet("Epic")
		Config.petsOfRarity = saved
		check("empty Epic steps down to Rare", pet ~= nil and rarity == "Rare", tostring(rarity))
		local noErr = true
		for _ = 1, 30 do
			local s3 = newSim(_, false)
			s3.gems, s3.sincePity = 1e6, 100 -- pity forces Epic or better
			if not pcall(s3.roll, s3) then
				noErr = false
			end
		end
		check("pity roll never throws", noErr)

		-- saving: progress round-trips and a corrupt save can't create an impossible state
		local a = newSim(5, false)
		a.level, a.xp, a.sp, a.gems = 7, 12, 3, 999
		a.tree.Claws = 2
		local b = newSim(6, false)
		b:loadMeta(a:meta())
		check("saved progress round-trips", b.level == 7 and b.xp == 12 and b.sp == 3 and b.gems == 999 and b.tree.Claws == 2)
		local c = newSim(7, false)
		local startGems = c.gems
		c:loadMeta({ level = -5, xp = "x", sp = 1e99, gems = -1, tree = { Claws = 99, Bogus = 5, [1] = 3 } })
		check("corrupt save is clamped", c.level == 1 and c.xp == 0 and c.sp <= 1e6 and c.tree.Bogus == nil and c.tree.Claws <= Config.TREE_BY_ID.Claws.max and c.tree.Start == 1)
		check("returning player keeps at least the starting gems", c.gems >= startGems, c.gems)
		local d = newSim(8, false)
		d:loadMeta(nil)
		check("missing save leaves defaults", d.level == 1 and d.gems == startGems)

		-- ultimate picks the highest-tier signature familiar
		local sim3 = newSim(4, false)
		local events = {}
		sim3.emit = function(k, payload)
			table.insert(events, { k, payload })
		end
		local withSig
		for id, def in Config.PETS do
			if def.signature then
				withSig = id
				break
			end
		end
		if withSig then
			local x, z = sim3:findSpot(withSig)
			sim3:addUnit(withSig, x, z)
			sim3.ult = sim3:ultNeed()
			sim3:castUlt()
			local ult
			for _, e in events do
				if e[1] == "Ult" then
					ult = e[2]
				end
			end
			check("ultimate announces the signature caster", ult and ult.pet == withSig, ult and ult.pet)
		end

		-- stage, wave and boss flow; the leak rule (decision in Systems.md: a leaked wave still advances and pays)
		local function runUntil(s, pred, maxSteps)
			for _ = 1, maxSteps or 3000 do
				s:step(0.1)
				if pred(s) then
					return true
				end
			end
			return false
		end
		local function record(s)
			local log = {}
			s.emit = function(k, p)
				log[k] = log[k] or {}
				table.insert(log[k], p)
			end
			return log
		end

		local leakSim = newSim(11, false)
		local leakLog = record(leakSim)
		local gems0, hp0 = leakSim.gems, leakSim.crystalHp
		leakSim:startWave()
		check("leaked wave still clears", runUntil(leakSim, function(s) return s.stage == 2 end))
		check("leaked wave pays the clear bonus", leakSim.gems > gems0, leakSim.gems - gems0)
		check("leaked wave resets the streak and costs crystal hp", leakSim.combo == 0 and leakSim.crystalHp < hp0 + 2 and leakLog.Leak ~= nil)
		check("leak clear is reported as not perfect", leakLog.Clear ~= nil and leakLog.Clear[1].perfect == false)

		local perfect = newSim(12, false)
		perfect.gems = 1e6
		for _ = 1, 8 do
			perfect:roll()
		end
		perfect:startWave()
		runUntil(perfect, function(s) return s.stage == 2 end)
		check("a clean wave advances the stage", perfect.stage == 2, perfect.stage)
		check("a clean wave keeps the streak", perfect.leaked == false and perfect.combo == 1, tostring(perfect.combo))

		local boss = newSim(13, false)
		local bossLog = record(boss)
		boss.stage = Config.BOSS_EVERY
		boss.crystalHp = 1e6
		boss:startWave()
		check("boss stage is flagged", Config.isBossStage(Config.BOSS_EVERY) and bossLog.Stage[1].boss == true)
		local queuedBoss = false
		for _, q in boss.queue do
			if q.kind == "Boss" then
				queuedBoss = true
			end
		end
		check("boss stage queues a Boss", queuedBoss)
		runUntil(boss, function(s) return s.bossClock ~= nil end)
		check("boss arrival starts the boss clock", boss.bossClock ~= nil)
		boss.bossClock = 0.05
		runUntil(boss, function(s) return bossLog.BossEscaped ~= nil end, 20)
		check("an unkilled boss sends the run back one stage", bossLog.BossEscaped ~= nil and boss.stage == Config.BOSS_EVERY - 1 and boss.state == "ready", boss.stage)

		local over = newSim(14, false)
		local overLog = record(over)
		over.stage, over.coins, over.crystalHp = 6, 100, 1
		over:startWave()
		runUntil(over, function(s) return overLog.Overrun ~= nil end)
		check("falling crystal pushes the stage back", over.stage == 6 - Config.OVERRUN_STAGE_LOSS, over.stage)
		check("overrun costs a share of coins and the streak", over.coins <= math.ceil(100 * (1 - Config.OVERRUN_COIN_LOSS)) and over.combo == 0, over.coins)
		check("overrun heals the crystal and waits for a new wave", over.crystalHp == over:maxHp() and over.state == "ready")

		local low = newSim(15, false)
		low.stage, low.crystalHp = 2, 1
		local lowLog = record(low)
		low:startWave()
		runUntil(low, function(s) return lowLog.Overrun ~= nil end)
		check("overrun never drops below stage 1", low.stage == 1, low.stage)

		local tut = newSim(16, true)
		local tutHp = tut.crystalHp
		tut:startWave()
		runUntil(tut, function(s) return s.stage == 2 end)
		check("tutorial leaks cost no crystal hp", tut.crystalHp == tutHp, tut.crystalHp)

		-- path blockers and gates (T157): StageSets blockers, flag Config.PATH_BLOCKERS
		do
			local Path = require(tmp.Path)
			local SS = require(tmp.StageSets)
			check("PATH_BLOCKERS is off by default", Config.PATH_BLOCKERS == false and #Config.blockersFor(11) == 0)
			local function started(stage, seed)
				local s = newSim(seed or 21, false)
				local log = record(s)
				s.stage, s.crystalHp = stage, 1e6
				s:startWave()
				return s, log
			end
			-- flag off: nothing in the way
			local off, offLog = started(11)
			local passed = runUntil(off, function(s)
				for _, e in s.enemies do
					if e.dist > 0.45 * Path.length then
						return true
					end
				end
				return false
			end, 2000)
			check("flag off: no blockers and enemies walk past 45% of the lane", #off.blockers == 0 and offLog.Blockers == nil and passed)

			Config.PATH_BLOCKERS = true
			-- the data
			local ids, dataOk = {}, true
			for _, set in SS.list do
				local last = -1
				for _, b in set.blockers or {} do
					local good = ids[b.id] == nil and (b.kind == "fence" or b.kind == "gate") and b.at > 0.1 and b.at < 0.9 and b.at - last >= 0.1
					if b.kind == "fence" then
						good = good and b.hp > 0 and b.breakDps > 0
					elseif b.kind == "gate" then
						good = good and b.open > 0 and b.closed > 0
					end
					dataOk = dataOk and good
					ids[b.id] = true
					last = b.at
				end
			end
			check("every set's blockers are well formed, unique, and 0.1 of the lane apart", dataOk)
			check("the first set has no blockers (stage 1 to 5 play as today)", SS.list[1].blockers == nil and #Config.blockersFor(3) == 0)
			local copy = Config.blockersFor(11)
			copy[1].hp = 0
			check("blockersFor hands out a fresh copy each time", Config.blockersFor(11)[1].hp == SS.list[3].blockers[1].hp and SS.list[3].blockers[1].hp > 0)

			-- a fence holds enemies until they break it
			local sim, log = started(11)
			local fence = sim.blockers[1]
			check("flag on: stage 11 loads the Cathedral fence at 40% of the lane", #sim.blockers == 1 and fence.kind == "fence" and math.abs(fence.D - 0.4 * Path.length) < 1e-6 and log.Blockers ~= nil and log.Blockers[1].list[1].id == "PewBarrier")
			local past, waited, stopPace = false, false, false
			local startHp = fence.hp
			for _ = 1, 3000 do
				sim:step(0.1)
				for _, e in sim.enemies do
					if fence.hp > 0 and e.dist > fence.D + 1e-6 then
						past = true
					end
					if e.dist == fence.D and fence.hp > 0 then
						waited = true
					end
				end
				if log.BlockerBroken then
					break
				end
			end
			for _, ev in log.Pace or {} do
				if ev.speed == 0 then
					stopPace = true
				end
			end
			check("no enemy passes a standing fence", not past)
			check("enemies wait at the fence and the client is told their speed is 0", waited and stopPace)
			check("waiting enemies break the fence and one BlockerBroken event is sent", log.BlockerBroken ~= nil and #log.BlockerBroken == 1 and fence.hp <= 0 and startHp > 0)
			local gone = runUntil(sim, function(s)
				for _, e in s.enemies do
					if e.dist > fence.D + 5 then
						return true
					end
				end
				return false
			end, 600)
			check("after the fence breaks enemies walk on", gone)

			-- a gate holds enemies while closed
			local g, glog = started(6)
			local gate = g.blockers[1]
			check("stage 6 loads the Harbour gate, open first", #g.blockers == 1 and gate.kind == "gate" and g:blockerActive(gate) == false)
			gate.open, gate.closed = 1, 1000 -- closed from 1 s on
			local reached = runUntil(g, function(s)
				for _, e in s.enemies do
					if e.dist >= gate.D then
						return true
					end
				end
				return false
			end, 2000)
			local stuck = true
			for _ = 1, 100 do
				g:step(0.1)
				for _, e in g.enemies do
					if e.dist > gate.D + 1e-6 then
						stuck = false
					end
				end
			end
			check("enemies reach a closed gate and stay behind it", reached and stuck and g:blockerActive(gate) == true)
			check("a Gate event announced the closing", glog.Gate ~= nil and glog.Gate[1].closed == true and glog.Gate[1].id == "QuayGate")
			gate.open = 1e6 -- open for good
			local through = runUntil(g, function(s)
				for _, e in s.enemies do
					if e.dist > gate.D + 4 then
						return true
					end
				end
				return false
			end, 300)
			check("when the gate opens the waiting enemies pass", through and glog.Gate[#glog.Gate].closed == false)

			-- a gate that is open as they arrive costs nothing
			local fast, flog = started(6, 22)
			fast.blockers[1].open, fast.blockers[1].closed = 1e6, 1
			local free = runUntil(fast, function(s)
				for _, e in s.enemies do
					if e.dist > fast.blockers[1].D + 4 then
						return true
					end
				end
				return false
			end, 2000)
			check("an open gate lets enemies straight through, no Gate event", free and flog.Gate == nil)
			Config.PATH_BLOCKERS = false
		end
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL test crashed: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
