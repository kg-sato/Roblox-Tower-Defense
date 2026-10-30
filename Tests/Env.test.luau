--!nocheck
-- Headless checks for the per-set day/night window and weather events (T009). Windows are data in Shared.StageSets (`sky`), effects in Config.SKY_EFFECTS; off by default (Config.SKY_ON).
-- Run in Studio (Edit mode) through a temporary ModuleScript with a fresh Shared clone:  return require(tempModule)(game.ReplicatedStorage.Shared)
-- Clones Config, Path, MatchSim and StageSets; nothing is changed. Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_EnvTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim", "StageSets" } do
		Shared[n]:Clone().Parent = tmp
	end
	local Config = require(tmp.Config)
	local MatchSim = require(tmp.MatchSim)
	local StageSets = require(tmp.StageSets)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local function near(a, b, eps)
		return math.abs(a - b) <= (eps or 1e-9)
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
	local function put(sim, pet, x, z)
		local id = sim.nextUnit
		sim.nextUnit += 1
		sim.grid[id] = { pet = pet, tier = 1, cd = 0.3, x = x, z = z }
		return id
	end

	local ok, err = pcall(function()
		check("the sky switch is off by default", Config.SKY_ON == false)
		-- data, every set
		local dataOk, effOk = true, true
		for _, set in StageSets.list do
			local sky = set.sky
			if not sky or type(sky.cycle) ~= "number" or sky.cycle <= 0 then
				dataOk = false
			else
				if sky.night and not (sky.night[1] >= 0 and sky.night[2] <= 1 and sky.night[1] <= sky.night[2]) then
					dataOk = false
				end
				for _, w in sky.weather or {} do
					if not (w.at >= 0 and w.at < 1 and w.dur > 0 and w.dur < sky.cycle) then
						dataOk = false
					end
					if not Config.SKY_EFFECTS[w.kind] then
						effOk = false
					end
				end
			end
		end
		check("all " .. #StageSets.list .. " stage sets have a valid day/night window and weather list", dataOk)
		check("every weather kind has an effect in Config.SKY_EFFECTS, and night does too", effOk and Config.SKY_EFFECTS.night ~= nil)
		check("Config.skyFor finds the set's data for stages 1 to 25", (function()
			for s = 1, 25 do
				if Config.skyFor(s) ~= StageSets.forStage(s).sky then
					return false
				end
			end
			return true
		end)())

		-- skyAt on stage 1 (cycle 80, night 0.65 to 1, Fog at 0.2 for 14 s)
		local sky1 = Config.skyFor(1)
		local cyc = sky1.cycle
		local w = sky1.weather[1]
		local wStart = w.at * cyc
		local a = Config.skyAt(1, 1)
		check("early in the cycle it is day with no weather", a.night == false and a.weather == nil)
		check("the weather starts at its time", Config.skyAt(1, wStart + 1).weather == w.kind)
		check("the weather ends after its duration", Config.skyAt(1, wStart + w.dur + 1).weather == nil)
		check("the weather repeats every cycle", Config.skyAt(1, wStart + 1 + cyc * 3).weather == w.kind)
		check("night falls in its window", Config.skyAt(1, sky1.night[1] * cyc + 1).night == true)
		check("night ends at the end of the cycle", Config.skyAt(1, cyc + 1).night == false)
		check("the last set is night all cycle", Config.skyAt(21, 3).night == true and Config.skyAt(21, 70).night == true)
		check("two sets differ", Config.skyFor(1) ~= Config.skyFor(6))

		-- sim, off: nothing changes
		do
			local sim = newSim(1)
			local e = { id = 1, kind = "Grunt", hp = 1e9, maxHp = 1e9, dist = 0, dead = false }
			table.insert(sim.enemies, e)
			sim.t = wStart + 1
			sim:step(0.1)
			check("with the switch off the weather does not slow enemies", near(e.dist, Config.ENEMIES.Grunt.speed * 0.1, 1e-9), e.dist)
			check("with the switch off no Sky event is sent", payloads.Sky == nil)
		end

		Config.SKY_ON = true
		Config.SYNERGY_ON = false
		-- sim, on: weather slows enemies and announces itself
		do
			local sim = newSim(2)
			local e = { id = 1, kind = "Grunt", hp = 1e9, maxHp = 1e9, dist = 0, dead = false }
			table.insert(sim.enemies, e)
			sim.t = wStart + 1
			sim:step(0.1)
			local fx = Config.SKY_EFFECTS[w.kind]
			check("a Sky event announces the weather", payloads.Sky ~= nil and payloads.Sky[1].weather == w.kind and payloads.Sky[1].night == false)
			check("weather changes the enemy speed", near(e.dist, Config.ENEMIES.Grunt.speed * (fx.enemySpeed or 1) * 0.1, 1e-9), e.dist)
			check("the client is told the new speed with Pace", payloads.Pace ~= nil and near(payloads.Pace[1].speed, Config.ENEMIES.Grunt.speed * (fx.enemySpeed or 1), 1e-9))
			local count = #payloads.Sky
			sim:step(0.1)
			check("the Sky event is sent once per change, not every step", #payloads.Sky == count)
			sim.t = wStart + w.dur + 2
			sim:step(0.1)
			check("a new Sky event when the weather ends", #payloads.Sky == count + 1 and payloads.Sky[#payloads.Sky].weather == nil)
		end
		-- night: light familiars hit harder
		do
			local pet
			for id, kind in Config.DAMAGE_TYPE do
				if kind == "light" and Config.PETS[id] and not (Config.ROLES[id] and (Config.ROLES[id].aura or Config.ROLES[id].global)) then
					pet = id
					break
				end
			end
			if pet then
				local day, night = newSim(3), newSim(3)
				local d1, n1 = put(day, pet, 0, -10), put(night, pet, 0, -10)
				day.t = 1
				night.t = sky1.night[1] * cyc + 1
				day:step(0.001)
				night:step(0.001)
				local dd = day:effective(day.grid[d1])
				local nd = night:effective(night.grid[n1])
				check("at night a light familiar hits harder by the night effect", near(nd / dd, 1 + Config.SKY_EFFECTS.night.damage.light, 1e-9), nd / dd)
				check("a Sky event announces the night", (function() for _, p in payloads.Sky or {} do if p.night then return true end end return false end)())
				-- a fire familiar is unchanged at night
				local fire
				for id, kind in Config.DAMAGE_TYPE do
					if kind == "fire" and Config.PETS[id] and not (Config.ROLES[id] and (Config.ROLES[id].aura or Config.ROLES[id].global)) then
						fire = id
					end
				end
				if fire and not (Config.SKY_EFFECTS.night.damage.fire) then
					local fd, fn = newSim(4), newSim(4)
					local f1, f2 = put(fd, fire, 0, -10), put(fn, fire, 0, -10)
					fd.t, fn.t = 1, sky1.night[1] * cyc + 1
					fd:step(0.001)
					fn:step(0.001)
					check("a fire familiar is unchanged by night", near(fd:effective(fd.grid[f1]), fn:effective(fn.grid[f2])))
				end
			else
				check("a light-damage familiar exists to test the night effect", false)
			end
		end
		-- range: the Fog effect shortens reach
		do
			local sim = newSim(5)
			sim.t = wStart + 1
			sim:step(0.001)
			local fx = Config.SKY_EFFECTS[w.kind]
			check("the weather's range effect reaches the sim", near(sim.skyFx.range, (fx.range or 0) + (Config.skyAt(1, sim.t).night and (Config.SKY_EFFECTS.night.range or 0) or 0)))
		end
		-- a paused run does not advance the sky
		do
			local sim = newSim(6)
			sim:pause(true)
			sim.t = wStart + 1
			sim:step(0.1)
			check("a paused run sends no Sky event", payloads.Sky == nil)
		end
		Config.SKY_ON = false
		Config.SYNERGY_ON = true
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " Env: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
