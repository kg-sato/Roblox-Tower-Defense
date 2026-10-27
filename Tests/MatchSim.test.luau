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
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL test crashed: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
