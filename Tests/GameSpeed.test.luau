--!nocheck
-- Headless checks for the game speed setting: validation (only 1, 2 or 3) and that 2x and 3x run the same sim in half the real time.
-- Run in Studio (Edit mode) with execute_luau:
--   local body = game:GetService("HttpService"):GetAsync("http://127.0.0.1:8792/GameSpeed.test.luau")
--   return loadstring(body)()(game.ReplicatedStorage.Shared)
-- Returns a report string; the first line says PASS or FAIL. Clones Config/Path/MatchSim, so nothing is changed.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_GameSpeedTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim" } do
		Shared[n]:Clone().Parent = tmp
	end
	local Config = require(tmp.Config)
	local MatchSim = require(tmp.MatchSim)
	local S = require(Shared.SettingsDefaults)

	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end

	-- validation: only 1, 2 and 3 are accepted
	check("speed 1 accepted", (S.validate("gameSpeed", 1)))
	check("speed 2 accepted", (S.validate("gameSpeed", 2)))
	check("speed 3 accepted", (S.validate("gameSpeed", 3)))
	for _, bad in { 0, 4, 2.5, -1, 100, 1e9, 0 / 0, math.huge, "2", true, {}, false } do
		check("speed " .. tostring(bad) .. " rejected", not (S.validate("gameSpeed", bad)))
	end
	check("missing speed rejected", not (S.validate("gameSpeed", nil)))
	check("default speed is 1", S.defaults.gameSpeed == 1)
	check("sanitize replaces a bad saved speed by 1", S.sanitize({ gameSpeed = 5 }).gameSpeed == 1)
	check("sanitize keeps a saved 2", S.sanitize({ gameSpeed = 2 }).gameSpeed == 2)
	check("sanitize keeps a saved 3", S.sanitize({ gameSpeed = 3 }).gameSpeed == 3)
	local last, p = {}, {}
	check("a speed save is rate limited like every setting", S.allowSave(last, p, 10) and not S.allowSave(last, p, 10.4))

	-- the scheduler: equal sim steps for equal game time
	local TICK, FRAME, STEPS = 0.1, 1 / 60, 1200
	local function run(speed, seed)
		local sim = MatchSim.new(Random.new(seed), function() end, false)
		sim.gems = 1e6
		for _ = 1, 6 do
			sim:roll()
		end
		sim:setAuto(true)
		sim:startWave()
		local accum, done, realTime = 0, 0, 0
		while done < STEPS do
			realTime += FRAME
			local n
			n, accum = S.stepsFor(accum, FRAME, speed, TICK)
			for _ = 1, n do
				if done < STEPS then
					sim:step(TICK)
					done += 1
				end
			end
		end
		return sim, realTime
	end
	local a, realA = run(1, 7)
	local b, realB = run(2, 7)
	check("same seed reaches the same stage at 1x and 2x", a.stage == b.stage, a.stage .. " vs " .. b.stage)
	check("same seed earns the same coins", a.coins == b.coins, a.coins .. " vs " .. b.coins)
	check("same seed earns the same gems", a.gems == b.gems, a.gems .. " vs " .. b.gems)
	check("same seed leaves the same crystal hp", a.crystalHp == b.crystalHp, a.crystalHp .. " vs " .. b.crystalHp)
	check("same seed leaves the same enemies alive", #a.enemies == #b.enemies, #a.enemies .. " vs " .. #b.enemies)
	check("equal sim time", math.abs(a.t - b.t) < 1e-6, a.t .. " vs " .. b.t)
	check("the run did something (stage above 1)", a.stage > 1, a.stage)
	check("2x takes half the real time", math.abs(realB * 2 - realA) / realA < 0.03, string.format("%.1fs vs %.1fs", realA, realB))
	local b3, realB3 = run(3, 7)
	check("same seed reaches the same stage at 3x", a.stage == b3.stage, a.stage .. " vs " .. b3.stage)
	check("3x earns the same coins and gems", a.coins == b3.coins and a.gems == b3.gems, a.coins .. "/" .. a.gems .. " vs " .. b3.coins .. "/" .. b3.gems)
	check("3x leaves the same crystal hp and enemies", a.crystalHp == b3.crystalHp and #a.enemies == #b3.enemies)
	check("3x equal sim time", math.abs(a.t - b3.t) < 1e-6, a.t .. " vs " .. b3.t)
	check("3x takes a third of the real time", math.abs(realB3 * 3 - realA) / realA < 0.03, string.format("%.1fs vs %.1fs", realA, realB3))
	-- game clock line (MatchService gclock): real time times speed, so 3 s at 3x is 9 game seconds
	local g = 0
	for _ = 1, 180 do
		g += (1 / 60) * 3
	end
	check("gclock advances 3 game seconds per real second at 3x", math.abs(g - 9) < 1e-6, g)
	local c = run(2, 8)
	check("a different seed differs or at least runs", c.t == a.t)

	tmp:Destroy()
	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
