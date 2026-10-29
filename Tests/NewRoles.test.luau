--!nocheck
-- Headless checks for the roles of the four Epic and Legendary humans (2026-10-29): Constable Wren (Whistle), Madam Quill (Annotate),
-- The Cog-Warden (Lockstep), The Ferryman of Fog (Crossing). Same method as Combat.test.luau. Clones Config, Path and MatchSim; nothing is changed.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_NewRolesTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim" } do
		Shared[n]:Clone().Parent = tmp
	end
	local Config = require(tmp.Config)
	local MatchSim = require(tmp.MatchSim)
	local Path = require(tmp.Path)
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
			table.insert(events, { kind = kind, p = p })
		end, false)
	end
	local function count(kind, sub)
		local n = 0
		for _, ev in events do
			if ev.kind == kind and (sub == nil or ev.p.kind == sub) then
				n += 1
			end
		end
		return n
	end
	local nextId = 500
	local function enemy(sim, kind, dist, hp)
		nextId += 1
		local e = { id = nextId, kind = kind, hp = hp or 1e6, maxHp = hp or 1e6, dist = dist or 20, dead = false }
		table.insert(sim.enemies, e)
		return e
	end

	local ok, err = pcall(function()
		-- the four exist with the right rarity, a role and a sane raw dps band
		for _, row in { { "ConstableWren", "Epic" }, { "MadamQuill", "Epic" }, { "CogWarden", "Legendary" }, { "FerrymanOfFog", "Legendary" } } do
			local pet, rarity = row[1], row[2]
			local def = Config.PETS[pet]
			check(pet .. " is in Config.PETS as " .. rarity, def ~= nil and def.rarity == rarity)
			check(pet .. " has a role", Config.ROLES[pet] ~= nil)
			if def then
				local dps = def.damage / def.cooldown
				check(pet .. " raw dps is within the 15 to 30 band", dps >= 15 and dps <= 30, dps)
			end
		end

		-- Whistle: every 4th shot splashes 60% to enemies within 6 studs of the target
		local sim = newSim(1)
		local id = sim:addUnit("ConstableWren", 0, 0)
		local e = enemy(sim, "Grunt", 20)
		local nearby = enemy(sim, "Grunt", 21)
		local far = enemy(sim, "Grunt", 150)
		for _ = 1, 3 do
			sim:roleHit(id, sim.grid[id], e, 100, false)
		end
		check("Wren: no splash before the 4th shot", nearby.hp == 1e6 and count("Echo", "splash") == 0)
		sim:roleHit(id, sim.grid[id], e, 100, false)
		check("Wren: the 4th shot splashes 60% to a nearby enemy", near(1e6 - nearby.hp, 60, 1e-6), 1e6 - nearby.hp)
		check("Wren: the splash does not reach a far enemy", far.hp == 1e6)
		check("Wren: one splash event", count("Echo", "splash") == 1)

		-- Annotate: every hit marks and hushes
		sim = newSim(2)
		id = sim:addUnit("MadamQuill", 0, 0)
		e = enemy(sim, "Grunt")
		sim:roleHit(id, sim.grid[id], e, 10, false)
		check("Quill: a hit marks", e.status ~= nil and e.status.mark ~= nil)
		check("Quill: a hit hushes", e.status ~= nil and e.status.hush ~= nil)

		-- Lockstep: a crit stuns, a plain hit does not; every 6th shot strikes twice
		sim = newSim(3)
		id = sim:addUnit("CogWarden", 0, 0)
		e = enemy(sim, "Grunt")
		sim:roleHit(id, sim.grid[id], e, 10, false)
		check("Cog-Warden: a plain hit does not stun", not (e.status and e.status.stun))
		sim:roleHit(id, sim.grid[id], e, 10, true)
		check("Cog-Warden: a crit stuns", e.status ~= nil and e.status.stun ~= nil)
		sim = newSim(4)
		id = sim:addUnit("CogWarden", 0, 0)
		e = enemy(sim, "Grunt")
		for _ = 1, 5 do
			sim:roleHit(id, sim.grid[id], e, 10, false)
		end
		check("Cog-Warden: no extra hit before the 6th shot", e.hp == 1e6)
		sim:roleHit(id, sim.grid[id], e, 10, false)
		check("Cog-Warden: the 6th shot hits twice", near(1e6 - e.hp, 10, 1e-6), 1e6 - e.hp)

		-- Crossing: hits chill and mark; touching familiars gain 15% range
		sim = newSim(5)
		id = sim:addUnit("FerrymanOfFog", 0, 0)
		e = enemy(sim, "Grunt")
		sim:roleHit(id, sim.grid[id], e, 10, false)
		check("Ferryman: a hit chills", e.status ~= nil and e.status.chill ~= nil and e.status.chill.stacks == 1)
		check("Ferryman: a hit marks", e.status ~= nil and e.status.mark ~= nil)
		local idE = sim:addUnit("Ember", 3, 0)
		local idFar = sim:addUnit("Frostling", 90, 90)
		local rangeNear = sim:auras(sim.grid[idE])
		local rangeFar = sim:auras(sim.grid[idFar])
		check("Ferryman: a touching familiar gains 15% range", near(rangeNear, 0.15, 1e-6), rangeNear)
		check("Ferryman: a far familiar gains nothing", rangeFar == 0, rangeFar)

		-- a shot through the real step: Quill damages with the armour rules and applies her statuses
		sim = newSim(6)
		sim.coins, sim.gems = 1e6, 1e6
		local pp = Path.positionAt(20)
		sim:addUnit("MadamQuill", pp.X + 4, pp.Z + 4)
		e = enemy(sim, "Grunt", 20, 1e6)
		for _ = 1, 30 do
			sim:step(0.1)
		end
		check("a stepped sim lets Quill shoot and annotate", e.hp < 1e6 and e.status ~= nil and e.status.mark ~= nil, e.hp)
	end)
	tmp:Destroy()
	if not ok then
		failed += 1
		table.insert(results, "FAIL test crashed: " .. tostring(err))
	end
	return (failed == 0 and "PASS" or "FAIL") .. " NewRoles: " .. (#results - failed) .. "/" .. #results .. " checks ok\n" .. table.concat(results, "\n")
end
