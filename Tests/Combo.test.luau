--!nocheck
-- Headless checks for the faction adjacency combo (T012): Config.SYNERGIES is a data table of faction pairs; a familiar touching a partner gets the bonus once per entry, capped.
-- Run in Studio (Edit mode) through a temporary ModuleScript with a fresh Shared clone:  return require(tempModule)(game.ReplicatedStorage.Shared)
-- Clones Config, Path, MatchSim and Familiars (so the factions load in the clone); nothing is changed. Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_ComboTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim", "Familiars" } do
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
	local function newSim()
		return MatchSim.new(Random.new(1), function() end, false)
	end
	-- pets of a faction, in roster order, that have no aura or global role (so damage comparisons are clean)
	local function petsOf(faction)
		local list = {}
		for _, id in Config.PET_ORDER do
			local def = Config.PETS[id]
			local role = Config.ROLES[id]
			if def.faction == faction and not (role and (role.aura or role.global)) then
				table.insert(list, id)
			end
		end
		return list
	end
	local function put(sim, pet, x, z)
		local id = sim.nextUnit
		sim.nextUnit += 1
		sim.grid[id] = { pet = pet, tier = 1, cd = 0.3, x = x, z = z }
		return id
	end

	local ok, err = pcall(function()
		check("the combo is on and has a data table of entries", Config.SYNERGY_ON == true and #Config.SYNERGIES >= 4)
		local entryOk = true
		for _, s in Config.SYNERGIES do
			if type(s.id) ~= "string" or type(s.a) ~= "string" or type(s.b) ~= "string" or ((s.damage or 0) <= 0 and (s.haste or 0) <= 0) then
				entryOk = false
			end
		end
		check("every entry has an id, two factions and a damage or haste bonus", entryOk)
		local capOk = true
		for _, s in Config.SYNERGIES do
			if (s.damage or 0) > Config.SYNERGY_CAP.damage or (s.haste or 0) > Config.SYNERGY_CAP.haste then
				capOk = false
			end
		end
		check("no single entry exceeds the cap", capOk)

		local tested = 0
		for _, s in Config.SYNERGIES do
			local pa, pb = petsOf(s.a), petsOf(s.b)
			local a, b
			if s.a == s.b then
				a, b = pa[1], pa[2]
			else
				a, b = pa[1], pb[1]
			end
			if a and b then
				tested += 1
				local sim = newSim()
				local ia = put(sim, a, 0, 0)
				local ib = put(sim, b, 5, 0)
				local d, h = sim:synergy(sim.grid[ia])
				check(s.id .. ": a touching pair gets exactly the entry bonus", near(d, s.damage or 0) and near(h, s.haste or 0), d .. "/" .. h)
				local d2, h2 = sim:synergy(sim.grid[ib])
				check(s.id .. ": the partner gets it too", near(d2, s.damage or 0) and near(h2, s.haste or 0))
				sim.grid[ib].x = 60
				local d3, h3 = sim:synergy(sim.grid[ia])
				check(s.id .. ": not touching gives nothing", d3 == 0 and h3 == 0)
			end
		end
		check("at least four of the entries could be tested with real familiars", tested >= 4, tested)

		-- same-faction pair: one neighbour or three give the same bonus (once per entry)
		local entry = Config.SYNERGIES[1]
		local pool = petsOf(entry.a)
		if #pool >= 2 then
			local sim = newSim()
			local i1 = put(sim, pool[1], 0, 0)
			put(sim, pool[2], 5, 0)
			local d1 = sim:synergy(sim.grid[i1])
			put(sim, pool[2], -5, 0)
			put(sim, pool[2], 0, 5)
			local d3 = sim:synergy(sim.grid[i1])
			check("three partners give the same bonus as one", near(d1, d3) and d1 > 0, d1 .. "/" .. d3)
		else
			check("a pool of two for the first entry", false)
		end
		-- a lone familiar gets nothing
		do
			local sim = newSim()
			local i1 = put(sim, pool[1], 0, 0)
			local d, h = sim:synergy(sim.grid[i1])
			check("a lone familiar gets no bonus", d == 0 and h == 0)
		end
		-- the cap
		do
			local savedList, savedCap = Config.SYNERGIES, Config.SYNERGY_CAP
			local fa = Config.PETS[pool[1]].faction
			Config.SYNERGIES = {}
			for i = 1, 10 do
				table.insert(Config.SYNERGIES, { id = "x" .. i, a = fa, b = fa, damage = 0.1, haste = 0.1 })
			end
			local sim = newSim()
			local i1 = put(sim, pool[1], 0, 0)
			put(sim, pool[2], 5, 0)
			local d, h = sim:synergy(sim.grid[i1])
			check("stacked entries stop at the cap", near(d, Config.SYNERGY_CAP.damage) and near(h, Config.SYNERGY_CAP.haste), d .. "/" .. h)
			Config.SYNERGIES, Config.SYNERGY_CAP = savedList, savedCap
		end
		-- the switch and the unaligned
		do
			local sim = newSim()
			local i1 = put(sim, pool[1], 0, 0)
			put(sim, pool[2], 5, 0)
			Config.SYNERGY_ON = false
			local d, h = sim:synergy(sim.grid[i1])
			check("with the combo off nothing changes", d == 0 and h == 0)
			Config.SYNERGY_ON = true
			local un
			for _, id in Config.PET_ORDER do
				if Config.PETS[id].faction == "Unaligned" or Config.PETS[id].faction == nil then
					un = id
					break
				end
			end
			if un then
				local s2 = newSim()
				local a = put(s2, un, 0, 0)
				put(s2, pool[1], 5, 0)
				local d2, h2 = s2:synergy(s2.grid[a])
				check("an unaligned familiar gets no combo", d2 == 0 and h2 == 0)
			else
				check("an unaligned familiar exists to test", true, "none in the roster; skipped")
			end
		end
		-- the sim uses it: damage and cooldown with and without a partner
		do
			local entry2
			for _, s in Config.SYNERGIES do
				if s.a == s.b and #petsOf(s.a) >= 2 and (s.damage or 0) > 0 then
					entry2 = s
					break
				end
			end
			if entry2 then
				local p = petsOf(entry2.a)
				local lone = newSim()
				local l1 = put(lone, p[1], 0, 0)
				local pair = newSim()
				local q1 = put(pair, p[1], 0, 0)
				put(pair, p[2], 5, 0)
				local dl, cl = lone:effective(lone.grid[l1])
				local dp, cp = pair:effective(pair.grid[q1])
				check("effective() adds the combo damage", near(dp / dl, 1 + (entry2.damage or 0), 1e-9), dp / dl)
				check("effective() shortens the cooldown when the entry has haste", (entry2.haste or 0) == 0 or cp < cl)
			else
				check("a same-faction damage entry with two usable familiars exists", false)
			end
		end
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " Combo: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
