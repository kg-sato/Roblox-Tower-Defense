--!nocheck
-- Headless checks for elite enemies and the ten wave modifiers (T015). All data in Config; off by default (Config.WAVES_V2).
-- Run in Studio (Edit mode) through a temporary ModuleScript with a fresh Shared clone:  return require(tempModule)(game.ReplicatedStorage.Shared)
-- Clones Config, Path and MatchSim; nothing is changed. Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_WavesTest"
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
	local function near(a, b, eps)
		return math.abs(a - b) <= (eps or 1e-6)
	end
	local events, payloads
	local function newSim(seed)
		events, payloads = {}, {}
		return MatchSim.new(Random.new(seed or 1), function(kind, p)
			table.insert(events, kind)
			payloads[kind] = payloads[kind] or {}
			table.insert(payloads[kind], p)
		end, false)
	end
	local function baseCount(s)
		return math.min(5 + math.floor(s * 1.3), 28) + (Config.isBossStage(s) and 1 or 0)
	end
	-- the first stage >= from that is not a boss stage and has the modifier
	local function stageWith(id)
		for s = Config.MOD_FIRST, 200 do
			local m = Config.waveModifier(s)
			if m and m.id == id then
				return s
			end
		end
	end

	local ok, err = pcall(function()
		check("the wave switch is off by default", Config.WAVES_V2 == false)
		-- data
		check("there are ten wave modifiers", #Config.WAVE_MODIFIERS == 10)
		local ids, dataOk = {}, true
		for _, m in Config.WAVE_MODIFIERS do
			ids[m.id] = (ids[m.id] or 0) + 1
			for _, k in { "hp", "speed", "coins", "gems", "count" } do
				if m[k] ~= nil and (type(m[k]) ~= "number" or m[k] <= 0) then
					dataOk = false
				end
			end
			if type(m.name) ~= "string" or type(m.desc) ~= "string" then
				dataOk = false
			end
		end
		local uniq = 0
		for _ in ids do
			uniq += 1
		end
		check("modifier ids are unique", uniq == 10)
		check("every modifier has a name, a description and positive multipliers", dataOk)
		check("elite numbers are data", Config.ELITE.hp > 1 and Config.ELITE.speed > 0 and Config.ELITE.coins > 1 and Config.ELITE.first >= 1)
		-- modifier choice
		local noneEarly, noneBoss, always = true, true, true
		for s = 1, Config.MOD_FIRST - 1 do
			noneEarly = noneEarly and Config.waveModifier(s) == nil
		end
		for s = 1, 200 do
			if Config.isBossStage(s) then
				noneBoss = noneBoss and Config.waveModifier(s) == nil
			elseif s >= Config.MOD_FIRST then
				always = always and Config.waveModifier(s) ~= nil
			end
		end
		check("no modifier on the first stages", noneEarly)
		check("no modifier on boss stages", noneBoss)
		check("every other stage from the first modifier stage has one", always)
		local seen = {}
		for s = Config.MOD_FIRST, 200 do
			local m = Config.waveModifier(s)
			if m then
				seen[m.id] = true
			end
		end
		local n = 0
		for _ in seen do
			n += 1
		end
		check("all ten modifiers come up", n == 10, n)
		check("a stage always has the same modifier", Config.waveModifier(13) == Config.waveModifier(13))
		-- elites
		check("no elites before the first elite stage", Config.eliteCount(1) == 0 and Config.eliteCount(Config.ELITE.first - 1) == 0)
		check("the first elite stage has one", Config.eliteCount(Config.ELITE.first) == 1)
		check("elites rise with the stage", Config.eliteCount(Config.ELITE.first + Config.ELITE.every) == 2)
		check("elites stop at the maximum", Config.eliteCount(500) == Config.ELITE.max)
		local posOk, countOk = true, true
		for s = 1, 100 do
			local list = Config.stageSpawns(s)
			local el = Config.stageElites(s, list)
			local c = 0
			for i in el do
				c += 1
				if i < 1 or i > #list or list[i] == "Boss" then
					posOk = false
				end
			end
			if c ~= math.min(Config.eliteCount(s), #list - (list[#list] == "Boss" and 1 or 0)) then
				countOk = false
			end
		end
		check("elite positions are inside the list and never the boss", posOk)
		check("the number of elite positions matches the count", countOk)

		-- off: nothing changes
		for s = 1, 40 do
			if #Config.stageSpawns(s) ~= baseCount(s) then
				check("with the switch off wave sizes are the old formula", false, s)
			end
		end
		check("with the switch off wave sizes are the old formula", true)
		do
			local sim = newSim(1)
			sim.stage = 12
			sim:startWave()
			local q = sim.queue
			local clean = true
			for _, e in q do
				clean = clean and e.elite == nil and e.mod == nil
			end
			check("with the switch off no queue entry is elite or modified", clean)
			check("with the switch off the Stage event carries no modifier", payloads.Stage[1].mod == nil and payloads.Stage[1].elites == 0)
		end

		-- on
		Config.WAVES_V2 = true
		local swarm, thinned, giants = stageWith("Swarm"), stageWith("Thinned"), stageWith("Giants")
		local baseSwarm = math.min(5 + math.floor(swarm * 1.3), 28)
		check("Swarm makes the wave bigger", #Config.stageSpawns(swarm) == math.clamp(math.floor(baseSwarm * 1.4), 3, 40) + (Config.isBossStage(swarm) and 1 or 0) and #Config.stageSpawns(swarm) > baseSwarm)
		local baseThin = math.min(5 + math.floor(thinned * 1.3), 28)
		check("Thinned makes the wave shorter", #Config.stageSpawns(thinned) == math.floor(baseThin * 0.7) and #Config.stageSpawns(thinned) < baseThin)
		check("Giants makes it much shorter", #Config.stageSpawns(giants) < math.min(5 + math.floor(giants * 1.3), 28))
		local sizeSane = true
		for s = 1, 200 do
			local c = #Config.stageSpawns(s)
			if c < 3 or c > 41 then
				sizeSane = false
			end
		end
		check("wave sizes always stay between 3 and 41", sizeSane)

		-- run a modified, elite stage and read the spawns
		local function spawnStage(stage)
			local sim = newSim(4)
			sim.stage = stage
			sim:startWave()
			for _ = 1, 400 do
				sim:step(0.1)
				if #sim.queue == 0 then
					break
				end
			end
			return sim
		end
		local mid = 14 -- an elite stage that is not a boss stage
		local mod = Config.waveModifier(mid)
		local sim = spawnStage(mid)
		local st = payloads.Stage[1]
		check("the Stage event names the modifier and elite count", st.mod == mod.id and st.modName == mod.name and st.elites == Config.eliteCount(mid), tostring(st.mod) .. "/" .. tostring(st.elites))
		local elites, plain, eliteSpawnEvents = {}, {}, 0
		for _, e in sim.enemies do
			table.insert(e.elite and elites or plain, e)
		end
		for _, p in payloads.Spawn do
			if p.elite then
				eliteSpawnEvents += 1
			end
		end
		check("the right number of elites spawn", #elites == Config.eliteCount(mid), #elites)
		check("the Spawn event tells the client which are elites", eliteSpawnEvents == #elites)
		if elites[1] and plain[1] then
			local e, p = elites[1], plain[1]
			local def = Config.ENEMIES[e.kind]
			local want = def.hp * Config.hpScale(mid) * (mod.hp or 1) * Config.ELITE.hp
			check("an elite has the elite hp multiplier on top of the modifier", near(e.maxHp, want, 1e-6), e.maxHp .. " vs " .. want)
			local pdef = Config.ENEMIES[p.kind]
			check("a normal enemy of the wave only has the modifier", near(p.maxHp, pdef.hp * Config.hpScale(mid) * (mod.hp or 1), 1e-6))
			check("an elite is slower by the elite and modifier speed", near(e.speedMult or 1, Config.ELITE.speed * (mod.speed or 1), 1e-9), e.speedMult)
			check("an elite pays the elite reward multiplier", near(e.coinMult or 1, Config.ELITE.coins * (mod.coins or 1), 1e-9))
			local before = sim.coins
			e.hp = 1
			sim:damage(e, 5, false)
			local expect = math.floor(def.coins * (1 + 0.1 * (sim.stage - 1)) * (e.coinMult or 1) + 0.5)
			check("killing an elite pays the scaled coins", sim.coins - before == expect, (sim.coins - before) .. " vs " .. expect)
		else
			check("the test stage has both elites and normal enemies", false)
		end
		-- speed: the client follows "Pace", so a slowed enemy must announce it
		local pace = payloads.Pace and payloads.Pace[1]
		local anyScaled = false
		for _, e in sim.enemies do
			if e.speedMult then
				anyScaled = true
			end
		end
		check("scaled enemies announce their speed with Pace", not anyScaled or pace ~= nil)
		-- a boss stage keeps its boss clean
		local bossSim = newSim(5)
		bossSim.stage = 10
		bossSim:startWave()
		for _ = 1, 500 do
			bossSim:step(0.1)
		end
		local bossOk = true
		for _, e in bossSim.enemies do
			if e.kind == "Boss" and (e.elite or e.speedMult or e.coinMult) then
				bossOk = false
			end
		end
		check("the boss is never an elite and has no modifier", bossOk and payloads.Stage[1].mod == nil)
		-- rewards of a Gemstorm / Plentiful wave
		local gs = stageWith("Gemstorm")
		local gsim = newSim(6)
		gsim.stage = gs
		gsim:startWave()
		for _ = 1, 40 do
			gsim:step(0.1)
		end
		local g = gsim.enemies[1]
		check("a Gemstorm wave multiplies gem rewards", g and near(g.gemMult or 1, Config.waveModifier(gs).gems * (g.elite and Config.ELITE.gems or 1), 1e-9))
		Config.WAVES_V2 = false
	end)
	Config.WAVES_V2 = false
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " Waves: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
