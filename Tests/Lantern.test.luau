--!nocheck
-- Headless checks for the Lantern power (T011): the player lights a spot, familiars inside the radius fire faster and harder for a while, then it recharges.
-- Run in Studio (Edit mode) through a temporary ModuleScript with a fresh Shared clone:  return require(tempModule)(game.ReplicatedStorage.Shared)
-- Clones Config, Path and MatchSim; nothing is changed. Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_LanternTest"
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
		return math.abs(a - b) <= (eps or 1e-9)
	end
	local events
	local function newSim(seed, tutorial)
		events = {}
		return MatchSim.new(Random.new(seed or 1), function(kind, p)
			table.insert(events, kind)
		end, tutorial or false)
	end
	local function has(kind)
		return table.find(events, kind) ~= nil
	end
	local function put(sim, pet, x, z)
		local id = sim.nextUnit
		sim.nextUnit += 1
		sim.grid[id] = { pet = pet, tier = 1, cd = 0.3, x = x, z = z }
		return id
	end

	local ok, err = pcall(function()
		local L = Config.LANTERN
		check("the Lantern numbers are data", L.radius > 0 and L.dur > 0 and L.cooldown > L.dur and L.haste > 0 and L.damage >= 0)
		local pet = "Ember"
		if not Config.PETS[pet] then
			pet = Config.PET_ORDER[1]
		end
		local sim = newSim(1)
		local near1 = put(sim, pet, 0, -10)
		local far1 = put(sim, pet, 0 + L.radius + 30, -10) -- outside the radius
		Config.SYNERGY_ON = false -- keep this suite about the Lantern only
		local d0, c0 = sim:effective(sim.grid[near1])
		check("the Lantern starts ready", sim.lanternReady == 0 and sim:snapshot().lanternCd == 0 and sim:snapshot().lanternOn == false)
		check("a bad position is refused", select(1, sim:lantern("x", 0)) == false and select(1, sim:lantern(0, nil)) == false and select(1, sim:lantern(0 / 0, 0)) == false)
		local tut = newSim(2, true)
		check("no Lantern in the tutorial", select(1, tut:lantern(0, 0)) == false)
		check("lighting the Lantern works and emits an event", select(1, sim:lantern(0, -10)) == true and has("Lantern"))
		local d1, c1 = sim:effective(sim.grid[near1])
		check("a familiar inside the radius hits harder", near(d1 / d0, 1 + L.damage, 1e-9), d1 / d0)
		check("a familiar inside the radius fires faster", near(c0 / c1, 1 + L.haste, 1e-9), c0 / c1)
		local d2, c2 = sim:effective(sim.grid[far1])
		check("a familiar outside the radius is unchanged", near(d2, d0) and near(c2, c0))
		check("the snapshot shows the Lantern lit and recharging", sim:snapshot().lanternOn == true and sim:snapshot().lanternCd > 0)
		local again, why = sim:lantern(0, -10)
		check("it cannot be lit again while recharging", again == false and why ~= nil, why)
		for _ = 1, math.floor(L.dur / 0.1) + 2 do
			sim:step(0.1)
		end
		local d3, c3 = sim:effective(sim.grid[near1])
		check("the light fades after its duration", near(d3, d0) and near(c3, c0) and sim:snapshot().lanternOn == false)
		check("the cooldown is still running after the light fades", select(1, sim:lantern(0, -10)) == false)
		for _ = 1, math.floor(L.cooldown / 0.1) do
			sim:step(0.1)
		end
		check("it can be lit again after the cooldown", select(1, sim:lantern(10, -10)) == true)
		check("the new spot is used", near(sim.lanternX, 10) and near(sim.lanternZ, -10))
		-- a paused run does not recharge
		local ps = newSim(3)
		ps:lantern(0, 0)
		local left = ps:snapshot().lanternCd
		ps:pause(true)
		for _ = 1, 50 do
			ps:step(0.1)
		end
		check("a paused run does not recharge the Lantern", near(ps:snapshot().lanternCd, left))
		-- the spot is clamped to the street
		local cs = newSim(4)
		cs:lantern(1e9, -1e9)
		check("a far-away position is clamped to the street", cs.lanternX == Config.PLACE_BOUNDS.maxX and cs.lanternZ == Config.PLACE_BOUNDS.minZ)
		-- it speeds up real shooting: same seed, same enemy, more shots with the Lantern
		local function shots(lit)
			local s = newSim(9)
			local count = 0
			s.emit = function(kind)
				if kind == "Shot" then
					count += 1
				end
			end
			put(s, pet, 0, -10)
			local e = { id = 1, kind = "Grunt", hp = 1e9, maxHp = 1e9, dist = 0, dead = false }
			table.insert(s.enemies, e)
			if lit then
				s:lantern(0, -10)
			end
			for _ = 1, 40 do
				e.dist = 44 -- keep it on the path, 10 studs from the familiar
				s:step(0.1)
			end
			return count
		end
		local plainShots, litShots = shots(false), shots(true)
		check("a lit Lantern gives more shots in the same time", litShots > plainShots, plainShots .. " -> " .. litShots)
		Config.SYNERGY_ON = true
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " Lantern: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
