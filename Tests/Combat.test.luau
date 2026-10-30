--!nocheck
-- Headless checks for familiar roles, statuses, armour and enemy behaviour (Design/Familiar Systems.md, Design/Enemy Bible.md).
-- Run in Studio (Edit mode) through a temporary ModuleScript with a fresh Shared clone:  return require(tempModule)(game.ReplicatedStorage.Shared)
-- Clones Config, Path and MatchSim; nothing is changed. Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_CombatTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim" } do
		Shared[n]:Clone().Parent = tmp
	end
	local Config = require(tmp.Config)
	local Path = require(tmp.Path)
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
	local events
	local function newSim(seed)
		events = {}
		return MatchSim.new(Random.new(seed or 1), function(kind, p)
			table.insert(events, kind)
		end, false)
	end
	local function has(kind)
		return table.find(events, kind) ~= nil
	end
	local nextId = 100
	local function enemy(sim, kind, dist, hp)
		nextId += 1
		local e = { id = nextId, kind = kind, hp = hp or 1000, maxHp = hp or 1000, dist = dist or 20, dead = false }
		table.insert(sim.enemies, e)
		return e
	end

	local ok, err = pcall(function()
		-- statuses
		local sim = newSim(1)
		local e = enemy(sim, "Grunt")
		sim:applyStatus(e, "burn", 100)
		check("burn stores damage per second from the hit", near(e.status.burn.dps, 100 * Config.STATUS.burn.dps), e.status.burn.dps)
		local hp0 = e.hp
		sim.t += 0.1
		sim:enemyTick(e, 0.1)
		check("burn damages over time", near(hp0 - e.hp, e.status.burn.dps * 0.1, 1e-6), hp0 - e.hp)
		sim.t += Config.STATUS.burn.dur + 1
		hp0 = e.hp
		sim:enemyTick(e, 0.1)
		check("burn ends after its duration", e.hp == hp0)
		check("a Status event is emitted", has("Status"))

		sim = newSim(2)
		e = enemy(sim, "Grunt")
		local u = { pet = "Ember", x = 0, z = 0 }
		local base = sim:armourDamage(u, e, 100)
		sim:applyStatus(e, "mark")
		check("mark adds 25 percent damage from every source", near(sim:armourDamage(u, e, 100), base * 1.25, 1e-6), sim:armourDamage(u, e, 100))

		sim = newSim(3)
		e = enemy(sim, "Grunt")
		for _ = 1, Config.STATUS.chill.max - 1 do
			sim:applyStatus(e, "chill")
		end
		check("chill stacks up to the maximum", e.status.chill.stacks == Config.STATUS.chill.max - 1)
		sim:applyStatus(e, "chill")
		check("a full stack freezes and resets the stack", e.status.freeze ~= nil and e.status.chill.stacks == 0)
		local boss = enemy(sim, "Boss")
		for _ = 1, 4 do
			sim:applyStatus(boss, "chill")
		end
		check("a boss is never frozen", boss.status.freeze == nil)
		sim:applyStatus(boss, "stun")
		check("boss status durations are halved", near(boss.status.stun.untilT - sim.t, Config.STATUS.stun.dur * 0.5))
		sim.t += 10
		sim:applyStatus(e, "stun")
		local first = e.status.stun.untilT
		sim.t += Config.STATUS.stun.dur + 0.1
		sim:applyStatus(e, "stun")
		check("a stunned enemy is immune to a second stun for a while", e.status.stun.untilT == first)

		-- armour and piercing
		sim = newSim(4)
		local tank, grunt, wisp = enemy(sim, "Tank"), enemy(sim, "Grunt"), enemy(sim, "Swift")
		check("fire does less against brass", near(sim:armourDamage({ pet = "Ember" }, tank, 100), 70, 1e-6))
		check("fire does more against flesh", near(sim:armourDamage({ pet = "Ember" }, grunt, 100), 120, 1e-6))
		check("ice does more against brass", near(sim:armourDamage({ pet = "Frostling" }, tank, 100), 130, 1e-6))
		check("stone does less against fog", near(sim:armourDamage({ pet = "Boulder" }, wisp, 100), 70, 1e-6))
		check("light does more against fog", near(sim:armourDamage({ pet = "Zap" }, wisp, 100), 130, 1e-6))
		Config.DAMAGE_TYPE.Sentinel = "ice"
		Config.DAMAGE_TYPE.GreyVeilWraith = "ice"
		check("the Sentinel pierces brass armour", near(sim:armourDamage({ pet = "Sentinel" }, tank, 100), 100, 1e-6))
		check("the Wraith pierces every armour", near(sim:armourDamage({ pet = "GreyVeilWraith" }, tank, 100), 100, 1e-6))
		check("a boss has no armour", near(sim:armourDamage({ pet = "Ember" }, enemy(sim, "Boss"), 100), 100, 1e-6))

		-- auras (touching familiars)
		sim = newSim(5)
		local a = sim:addUnit("Ember", 0, 0)
		local b = sim:addUnit("Ward", 3, 0)
		local c = sim:addUnit("Archivist", -3, 0)
		local far = sim:addUnit("Frostling", 90, 90)
		local rangeA, hasteA = sim:auras(sim.grid[a])
		check("a Ward next to a familiar adds range", near(rangeA, 0.2), rangeA)
		check("an Archivist next to a familiar adds attack speed", near(hasteA, 0.15), hasteA)
		local rf, hf = sim:auras(sim.grid[far])
		check("a far familiar gets no aura", rf == 0 and hf == 0)
		local _, cdWith = sim:effective(sim.grid[a])
		sim.grid[c], sim.grid[b] = nil, nil
		local _, cdWithout = sim:effective(sim.grid[a])
		check("the Archivist aura shortens the cooldown", cdWith < cdWithout, cdWith .. " < " .. cdWithout)

		-- roles on hit
		sim = newSim(6)
		local id1 = sim:addUnit("Ember", 0, 0)
		e = enemy(sim, "Grunt")
		sim:roleHit(id1, sim.grid[id1], e, 50, false)
		check("an Ember hit lights a burn", e.status and e.status.burn ~= nil)
		local idZ = sim:addUnit("Zap", 20, 0)
		sim:roleHit(idZ, sim.grid[idZ], e, 10, false)
		check("a Moth-Lantern hit marks", e.status.mark ~= nil)
		local idF = sim:addUnit("Frostling", 40, 0)
		sim:roleHit(idF, sim.grid[idF], e, 10, false)
		check("a Frostling hit chills", e.status.chill ~= nil and e.status.chill.stacks == 1)
		local idM = sim:addUnit("Mourner", 60, 0)
		sim:roleHit(idM, sim.grid[idM], e, 10, false)
		check("a Mourner hit hushes", e.status.hush ~= nil)
		local idG = sim:addUnit("Boulder", 80, 0)
		e = enemy(sim, "Grunt")
		sim:roleHit(idG, sim.grid[idG], e, 10, false)
		check("a plain Gargoyle hit does not stun", not (e.status and e.status.stun))
		sim:roleHit(idG, sim.grid[idG], e, 10, true)
		check("a Gargoyle crit stuns", e.status and e.status.stun ~= nil)

		-- every-Nth bonuses
		sim = newSim(7)
		local idH = sim:addUnit("BrassHound", 0, 0)
		e = enemy(sim, "Grunt", 20, 1e6)
		for i = 1, Config.ROLES.BrassHound.nth.n - 1 do
			sim:roleHit(idH, sim.grid[idH], e, 10, false)
		end
		check("no extra hit before the fifth shot", e.hp == 1e6)
		sim:roleHit(idH, sim.grid[idH], e, 10, false)
		check("the fifth shot of a Brass Hound hits twice", e.hp == 1e6 - 10, 1e6 - e.hp)
		sim = newSim(8)
		local idS = sim:addUnit("StarDrake", 0, 0)
		e = enemy(sim, "Grunt", 20, 1e6)
		local near1 = enemy(sim, "Grunt", 21, 1e6)
		local far1 = enemy(sim, "Grunt", 150, 1e6)
		for _ = 1, Config.ROLES.StarDrake.nth.n do
			sim:roleHit(idS, sim.grid[idS], e, 100, false)
		end
		check("every eighth Star Drake shot splashes nearby enemies", near1.hp == 1e6 - 50, 1e6 - near1.hp)
		check("splash does not reach far enemies", far1.hp == 1e6)

		-- echo and drain
		sim = newSim(9)
		local idX = sim:addUnit("Ember", 0, 0)
		local idE = sim:addUnit("VoltFox", 3, 0)
		e = enemy(sim, "Grunt", 20, 1e6)
		sim:roleHit(idX, sim.grid[idX], e, 100, false)
		check("a touching Mirror Chorister echoes 35 percent", near(1e6 - e.hp, 100 * 0.35, 1e-6), 1e6 - e.hp)
		sim = newSim(10)
		local idW = sim:addUnit("GreyVeilWraith", 0, 0)
		e = enemy(sim, "Grunt", 20, 1e6)
		sim.crystalHp = sim:maxHp() - 5
		for _ = 1, 10 do
			sim:roleHit(idW, sim.grid[idW], e, 1, false)
		end
		check("ten Wraith hits heal the crystal by one", sim.crystalHp == sim:maxHp() - 4, sim.crystalHp)
		sim.crystalHp = sim:maxHp()
		for _ = 1, 10 do
			sim:roleHit(idW, sim.grid[idW], e, 1, false)
		end
		check("drain never heals past the maximum", sim.crystalHp == sim:maxHp())

		-- enemy behaviour: the Brass Sentinel's plant
		sim = newSim(11)
		local t1 = enemy(sim, "Tank", 20, 1e6)
		local planted = false
		for _ = 1, 140 do
			sim.t += 0.05
			sim:enemyTick(t1, 0.05)
		end
		check("a Brass Sentinel telegraphs a plant", has("Telegraph"))
		local sawPlant = has("Plant")
		check("the telegraph is followed by a plant", sawPlant)
		sim = newSim(12)
		t1 = enemy(sim, "Tank", 20, 1e6)
		for _ = 1, 85 do
			sim.t += 0.05
			sim:enemyTick(t1, 0.05)
		end
		check("a telegraph is running before the plant", t1.telegraph ~= nil or t1.plant ~= nil)
		sim:applyStatus(t1, "hush")
		check("hush cancels the plant", t1.telegraph == nil and t1.plant == nil)
		t1.plant = 0.5
		sim:applyStatus(t1, "chill")
		check("a planted enemy ignores chill", not (t1.status and t1.status.chill))

		-- Lantern Thief and Clockwork Crow
		sim = newSim(13)
		local th = enemy(sim, "Thief", 0.3 * Path.length + 1, 1)
		sim:enemyTick(th, 0.05)
		check("a thief steals at 30 percent of the path", th.carrying == true and has("Steal"))
		local coins0 = sim.coins
		sim:damage(th, 5, false)
		local def = Config.ENEMIES.Thief
		check("a killed thief drops 10 coins on top of its reward", sim.coins - coins0 >= 10 and has("Drop"), sim.coins - coins0)
		sim = newSim(14)
		local idP = sim:addUnit("Ember", 0, 0)
		local crow = enemy(sim, "Crow", 0.5 * Path.length + 1, 1000)
		local pos = Path.positionAt(crow.dist)
		sim.grid[idP].x, sim.grid[idP].z = pos.X + 2, pos.Z
		sim:enemyTick(crow, 0.05)
		check("a crow perches on the nearest familiar", crow.perched == idP and has("Perch"))
		check("the perched familiar cannot fire", (sim.grid[idP].disabledUntil or 0) > sim.t)
		sim.grid[idP].cd = 0
		local shots0 = 0
		sim.emit = function(kind)
			if kind == "Shot" then
				shots0 += 1
			end
		end
		sim:step(0.1)
		check("no shot while perched", shots0 == 0)
		sim:damage(crow, 5000, false)
		check("killing the crow frees the familiar", (sim.grid[idP].disabledUntil or 0) == 0)

		-- Mythic and Celestial humans: Hymn aura, Rewind, Kindle and Veil
		sim = newSim(20)
		local idE2 = sim:addUnit("Ember", 0, 0)
		local plain = select(1, sim:effective(sim.grid[idE2]))
		local idV = sim:addUnit("CantorVesper", 3, 0)
		local withHymn = select(1, sim:effective(sim.grid[idE2]))
		check("a touching Cantor Vesper adds 20 percent damage (Hymn)", near(withHymn / plain, 1.2, 1e-6), withHymn / plain)
		local idFar = sim:addUnit("Frostling", 90, 90)
		local farPlain = select(1, sim:effective(sim.grid[idFar]))
		sim.grid[idV] = nil
		local farBefore = select(1, sim:effective(sim.grid[idFar]))
		local idL = sim:addUnit("TheLamplighter", 70, 70)
		local farAfter, _, critAfter = sim:effective(sim.grid[idFar])
		check("the Lamplighter adds 10 percent damage to every familiar (Kindle), even far away", near(farAfter / farBefore, 1.1, 1e-6), farAfter / farBefore)
		local idW2 = sim:addUnit("VeilWalker", 50, 50)
		local _, _, critWith = sim:effective(sim.grid[idFar])
		check("the Veil Walker adds 12 percent crit chance to every familiar", near(critWith - critAfter, 0.12, 1e-9), critWith - critAfter)
		sim.tree.Eye = 50
		local _, _, critCap = sim:effective(sim.grid[idFar])
		check("global crit is still clamped to the cap", critCap == Config.CRIT_CAP, critCap)
		sim.tree.Eye = nil
		sim = newSim(21)
		local idO = sim:addUnit("DameOrrery", 0, 0)
		local idN = sim:addUnit("Ember", 3, 0)
		local idFar2 = sim:addUnit("Ember", 90, 90)
		e = enemy(sim, "Grunt", 20, 1e6)
		sim.grid[idN].cd, sim.grid[idFar2].cd = 5, 5
		for _ = 1, Config.ROLES.DameOrrery.rewind.every - 1 do
			sim:roleHit(idO, sim.grid[idO], e, 10, false)
		end
		check("no rewind before the tenth shot", sim.grid[idN].cd == 5)
		sim:roleHit(idO, sim.grid[idO], e, 10, false)
		check("the tenth Dame Orrery shot resets a touching familiar's cooldown", sim.grid[idN].cd == 0)
		check("a far familiar keeps its cooldown", sim.grid[idFar2].cd == 5)

		-- movement effects stay off until the client supports them
		sim = newSim(15)
		e = enemy(sim, "Grunt", 10, 1e6)
		sim:applyStatus(e, "stun")
		Config.MOVEMENT_EFFECTS = false
		local d0 = e.dist
		sim:step(0.3)
		local moved = e.dist - d0
		check("with the flag off a stunned enemy still moves at normal speed", near(moved, Config.ENEMIES.Grunt.speed * 0.3, 1e-6), moved)
		Config.MOVEMENT_EFFECTS = true
		e.pace = nil -- the flag is constant in a real game; force the next tick to report its pace
		d0 = e.dist
		sim:step(0.3)
		check("with the flag on a stunned enemy stops", near(e.dist - d0, 0, 1e-6), e.dist - d0)
		check("a Pace event is emitted when the flag is on", has("Pace"))
		Config.MOVEMENT_EFFECTS = false

		-- new enemies keep the wave size; the flag is on in the game (2026-10-29), so the "off" check sets it off first
		Config.NEW_ENEMIES = false
		local plainOk = true
		for s = 1, 25 do
			for _, k in Config.stageSpawns(s) do
				if k == "Crow" or k == "Thief" then
					plainOk = false
				end
			end
		end
		check("Crow and Thief stay out of the waves when the flag is off", plainOk)
		Config.NEW_ENEMIES = true
		local sawCrow, sawThief, sizeOk = false, false, true
		for s = 1, 25 do
			local list = Config.stageSpawns(s)
			local want = math.min(5 + math.floor(s * 1.3), 28) + (Config.isBossStage(s) and 1 or 0)
			if #list ~= want then
				sizeOk = false
			end
			for _, k in list do
				sawCrow = sawCrow or k == "Crow"
				sawThief = sawThief or k == "Thief"
			end
		end
		check("with the flag on both new kinds appear and wave sizes are unchanged", sawCrow and sawThief and sizeOk)
		Config.NEW_ENEMIES = false

		-- Hollow Parishioner and Fog Wisp (T417)
		do
			check("both Hollow Court kinds are defined", Config.ENEMIES.Parishioner ~= nil and Config.ENEMIES.FogWisp ~= nil)
			check("the Hollow flag is off by default", Config.HOLLOW_ENEMIES == false)
			local seenNew = false
			for s = 1, 60 do
				for _, k in Config.stageSpawns(s) do
					if k == "Parishioner" or k == "FogWisp" then
						seenNew = true
					end
				end
			end
			check("with the flag off the client never meets a Parishioner or a Wisp", seenNew == false)
			Config.HOLLOW_ENEMIES = true
			local firstP, firstW, sizeOk, kindOk = nil, nil, true, true
			for s = 1, 60 do
				local list = Config.stageSpawns(s)
				local want = math.min(5 + math.floor(s * 1.3), 28) + (Config.isBossStage(s) and 1 or 0)
				if #list ~= want then
					sizeOk = false
				end
				for _, k in list do
					if not Config.ENEMIES[k] then
						kindOk = false
					end
					if k == "Parishioner" and not firstP then
						firstP = s
					elseif k == "FogWisp" and not firstW then
						firstW = s
					end
				end
			end
			check("with the flag on both appear, Parishioner from stage 11 and Wisp from stage 12", firstP == 11 and firstW == 12, tostring(firstP) .. "/" .. tostring(firstW))
			check("with the flag on wave sizes are unchanged and every kind is defined", sizeOk and kindOk)
			check("no Hollow kind before stage 11", (function()
				for s = 1, 10 do
					for _, k in Config.stageSpawns(s) do
						if k == "Parishioner" or k == "FogWisp" then
							return false
						end
					end
				end
				return true
			end)())
			Config.HOLLOW_ENEMIES = false
			-- the Parishioner's hollow armour
			local sim = newSim(21)
			local par = { id = 1, kind = "Parishioner", hp = 100, maxHp = 100, dist = 0, dead = false }
			local light = { pet = "Zap" }
			local shadow = { pet = "Mourner" }
			local fire = { pet = "Ember" }
			if Config.DAMAGE_TYPE.Zap == "light" and Config.DAMAGE_TYPE.Mourner == "shadow" then
				check("hollow armour takes more from light", near(sim:armourDamage(light, par, 100), 130, 1e-6))
				check("hollow armour takes less from shadow", near(sim:armourDamage(shadow, par, 100), 75, 1e-6))
				check("hollow armour takes fire normally", near(sim:armourDamage(fire, par, 100), 100, 1e-6))
			else
				check("damage types for the hollow armour test are in Config.DAMAGE_TYPE", false)
			end
			-- Fog Wisp lamp-eating
			local function wispSim(seed)
				local s2 = newSim(seed)
				local w = { id = 1, kind = "FogWisp", hp = 1000, maxHp = 1000, dist = Config.LAMP_EAT.at * Path.length - 1.0, dead = false }
				table.insert(s2.enemies, w)
				return s2, w
			end
			local s2, w = wispSim(22)
			s2:lantern(0, -10)
			local litUntil = s2.lanternUntil
			s2:step(0.1)
			check("before the eating point the Lantern is left alone", s2.lanternUntil == litUntil and not w.ate)
			events = {}
			s2:step(0.1)
			check("a Wisp past the eating point snuffs a lit Lantern", w.ate == true and s2.lanternUntil <= s2.t and has("LampEaten"))
			check("a snuffed Lantern takes longer to recharge", s2.lanternReady >= s2.t + Config.LAMP_EAT.snuffCooldown - 1e-6 and select(1, s2:lantern(0, -10)) == false)
			local ready0 = s2.lanternReady
			for _ = 1, 20 do
				s2:step(0.1)
			end
			check("a Wisp eats only once", s2.lanternReady == ready0)
			local s3, w3 = wispSim(23)
			s3:step(0.1)
			s3:step(0.1)
			check("a ready, unlit Lantern is darkened for a while", w3.ate and s3.lanternReady >= s3.t + Config.LAMP_EAT.darkFor - 0.3 and select(1, s3:lantern(0, -10)) == false)
			local s4, w4 = wispSim(24)
			s4:lantern(0, -10)
			s4:step(Config.LANTERN.dur + 1)
			local before = s4.lanternReady
			w4.dist = Config.LAMP_EAT.at * Path.length + 1
			s4:step(0.1)
			check("a recharging Lantern is left alone", w4.ate == true and s4.lanternReady == before)
			local s5 = newSim(25)
			local g = { id = 1, kind = "Grunt", hp = 1000, maxHp = 1000, dist = 0.9 * Path.length, dead = false }
			table.insert(s5.enemies, g)
			s5:lantern(0, -10)
			local u5 = s5.lanternUntil
			s5:step(0.1)
			check("other enemies never eat the lamp", g.ate == nil and s5.lanternUntil == u5)
		end
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " Combat: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
