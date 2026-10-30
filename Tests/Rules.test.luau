--!nocheck
-- Headless checks for the pure rules in Config and the roll pity in MatchSim (T150, T192, T195, T200 parts): enemy scaling per stage, rarity odds, tier damage,
-- recycle value, upgrade cost, trainer luck, combo clamp and the pity streak. Nothing in the game changes: it clones Config, Path and MatchSim.
-- Run in Studio (Edit mode) with execute_luau: put this file's text in a temporary ModuleScript, require it and call the result with a fresh Shared clone:
--   return require(tempModule)(game.ReplicatedStorage.Shared)
-- Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_RulesTest"
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
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local function near(a, b, eps)
		return math.abs(a - b) <= (eps or 1e-6)
	end

	local ok, err = pcall(function()
		-- enemy scaling per stage (T150)
		check("hpScale(1) is 1", near(Config.hpScale(1), 1))
		check("hpScale(25) is HP_GROWTH^24", near(Config.hpScale(25), Config.HP_GROWTH ^ 24, 1e-6), Config.hpScale(25))
		local mono = true
		for s = 2, 25 do
			if Config.hpScale(s) <= Config.hpScale(s - 1) then
				mono = false
			end
		end
		check("hpScale rises every stage", mono)
		local countOk, bossOk, kindOk = true, true, true
		for s = 1, 25 do
			local list = Config.stageSpawns(s)
			local boss = Config.isBossStage(s)
			local want = math.min(5 + math.floor(s * 1.3), 28) + (boss and 1 or 0)
			if #list ~= want then
				countOk = false
			end
			if boss ~= (s % 5 == 0) or (boss and list[#list] ~= "Boss") or (not boss and table.find(list, "Boss")) then
				bossOk = false
			end
			for _, k in list do
				if not Config.ENEMIES[k] then
					kindOk = false
				end
			end
		end
		check("enemy count is min(5 + 1.3 x stage, 28) plus a boss", countOk)
		check("a boss only on stages 5, 10, 15, 20, 25, and last in the list", bossOk)
		check("every spawned kind has a definition", kindOk)
		check("no Swift before stage 3", not table.find(Config.stageSpawns(2), "Swift"))
		check("no Tank before stage 6", not table.find(Config.stageSpawns(5), "Tank"))
		check("Tank appears by stage 6", table.find(Config.stageSpawns(6), "Tank") ~= nil)

		-- rarity odds
		for _, luck in { 0, 0.25, 0.5, 0.8 } do
			local p = Config.rarityPercents(luck)
			local sum = 0
			for _, v in p do
				sum += v
			end
			check("rarity percents sum to 100 at luck " .. luck, near(sum, 100, 1e-6), sum)
		end
		local p0, p5 = Config.rarityPercents(0), Config.rarityPercents(0.5)
		local oddsTotal = 0
		for _, r in Config.RARITY_ORDER do
			if #Config.petsOfRarity(r) > 0 then
				oddsTotal += Config.RARITIES[r].odds
			end
		end
		check("luck 0 gives Common its odds share (60 over the odds of rarities that have familiars)", near(p0.Common, 100 * 60 / oddsTotal, 1e-6), p0.Common)
		check("luck raises Legendary", p5.Legendary > p0.Legendary)
		check("luck lowers Common", p5.Common < p0.Common)
		check("trainer luck is clamped at 0.5", near(Config.luck(25), 0.5) and near(Config.luck(1), 0))

		-- tier damage and recycle
		for _, name in { "Ember", "Frostling", "VoltFox", "StarDrake" } do
			if Config.PETS[name] then
				local r = Config.petDamage(name, 2) / Config.petDamage(name, 1)
				check(name .. " gains 3.5x per tier", near(r, Config.TIER_MULT, 1e-6), r)
			end
		end
		local rv1, rv2 = Config.recycleValue("Ember", 1), Config.recycleValue("Ember", 2)
		check("recycle grows 3x per tier", rv2 == rv1 * 3, rv1 .. " -> " .. rv2)
		check("recycle is never zero", rv1 > 0)
		if Config.PETS.StarDrake then
			check("a Legendary recycles for more than a Common", Config.recycleValue("StarDrake", 1) > Config.recycleValue("Ember", 1))
		end

		-- upgrades, xp and combo
		local costOk = true
		for l = 1, Config.UPGRADE_MAX - 1 do
			if Config.upgradeCost(l) <= Config.upgradeCost(l - 1) then
				costOk = false
			end
		end
		check("upgrade cost rises each level", costOk)
		check("first upgrade costs 12", Config.upgradeCost(0) == 12)
		local xpOk = true
		for l = 2, Config.LEVEL_MAX do
			if Config.xpNeed(l) <= Config.xpNeed(l - 1) then
				xpOk = false
			end
		end
		check("xp needed rises each level", xpOk)
		check("combo multiplier is clamped at 8 kills", near(Config.comboMult(8), Config.comboMult(50)) and near(Config.comboMult(0), 1))
		check("crit chance stays under 50 percent at max level", Config.UPGRADES.Crit.per * Config.UPGRADE_MAX < 0.5, Config.UPGRADES.Crit.per * Config.UPGRADE_MAX)

		-- familiar power curve per rarity (T192): tier-1 damage per second, no upgrades. Rarity must climb and no familiar may be an outlier inside its rarity.
		local dps, byRarity = {}, {}
		for _, id in Config.PET_ORDER do
			local d = Config.PETS[id]
			local v = d.damage * Config.RARITIES[d.rarity].mult / d.cooldown
			dps[id] = v
			byRarity[d.rarity] = byRarity[d.rarity] or {}
			table.insert(byRarity[d.rarity], v)
		end
		local mean = {}
		for r, list in byRarity do
			local sum, lo, hi = 0, math.huge, 0
			for _, v in list do
				sum += v
				lo, hi = math.min(lo, v), math.max(hi, v)
			end
			mean[r] = sum / #list
			check(r .. ": the highest tier-1 dps is under 4x the lowest", hi / lo < 4, string.format("%.1f to %.1f", lo, hi))
		end
		check("mean tier-1 dps climbs Common < Rare < Epic < Legendary", mean.Common < mean.Rare and mean.Rare < mean.Epic and mean.Epic < mean.Legendary)
		check("a Legendary is under 30x a Common at tier 1 (dps ratio)", mean.Legendary / mean.Common < 30, string.format("%.1f", mean.Legendary / mean.Common))
		if mean.Mythic then
			check("Mythic familiars out-damage Legendary on average and stay under 80x Common", mean.Mythic > mean.Legendary and mean.Mythic / mean.Common < 80, string.format("%.1f", mean.Mythic))
		end
		if mean.Celestial then
			check("Celestial familiars out-damage Mythic on average and stay under 160x Common", mean.Celestial > (mean.Mythic or mean.Legendary) and mean.Celestial / mean.Common < 160, string.format("%.1f", mean.Celestial))
		end

		-- next-best skill hint (T199)
		local nb, nbCost = Config.nextBestSkill({ Start = 1 }, 0)
		check("no hint with zero skill points", nb == nil)
		nb, nbCost = Config.nextBestSkill({ Start = 1 }, 5)
		check("the hint is a neighbour of Start", nb ~= nil and table.find(Config.TREE_NEIGHBORS.Start, nb) ~= nil, nb)
		check("the hint is the cheapest reachable node", nbCost == 1, nbCost)
		nb = Config.nextBestSkill({ Start = 1, Claws = 5 }, 5)
		check("a maxed node is never suggested", nb ~= "Claws")
		nb = Config.nextBestSkill({ Start = 1 }, 1)
		check("an unreachable node is never suggested", nb ~= "Heavy" and nb ~= "Mega")
		nb = Config.nextBestSkill({ Start = 1, Claws = 4 }, 2)
		check("a node costing more than the points held is skipped", nb ~= "Claws" or select(2, Config.nextBestSkill({ Start = 1, Claws = 4 }, 2)) <= 2)
		local allMax = { Start = 1 }
		for _, node in Config.TREE do
			allMax[node.id] = node.max
		end
		check("nothing to suggest when everything is maxed", Config.nextBestSkill(allMax, 99) == nil)
		check("crit cap is below 1", Config.CRIT_CAP > 0 and Config.CRIT_CAP < 1)

		-- more tiers and rarities
		check("the tier cap is 8", Config.TIER_MAX == 8, Config.TIER_MAX)
		check("six rarities in order", #Config.RARITY_ORDER == 6 and Config.RARITY_ORDER[5] == "Mythic" and Config.RARITY_ORDER[6] == "Celestial")
		local ordOk = true
		for i, r in Config.RARITY_ORDER do
			if Config.RARITIES[r].order ~= i or (i > 1 and Config.RARITIES[r].mult <= Config.RARITIES[Config.RARITY_ORDER[i - 1]].mult) then
				ordOk = false
			end
		end
		check("rarity orders count up and multipliers rise", ordOk)
		local w = Config.rarityWeights(0.3)
		local emptyZero = true
		for _, r in Config.RARITY_ORDER do
			if #Config.petsOfRarity(r) == 0 and w[r] ~= 0 then
				emptyZero = false
			end
			if #Config.petsOfRarity(r) > 0 and w[r] <= 0 then
				emptyZero = false
			end
		end
		check("a rarity has weight only when a familiar has it", emptyZero)
		check("tier 8 damage is TIER_MULT^7 of tier 1", near(Config.petDamage("Ember", 8) / Config.petDamage("Ember", 1), Config.TIER_MULT ^ 7, 1e-3))
		check("recycle at tier 8 is 3^7 of tier 1", Config.recycleValue("Ember", 8) == Config.recycleValue("Ember", 1) * 3 ^ 7)

		-- pity (T200): over many rolls the dry streak without an Epic or better never reaches the pity interval
		local worst, rolls, pityHits = 0, 0, 0
		for seed = 1, 6 do
			local sim = MatchSim.new(Random.new(seed), function() end, false)
			sim.gems = 1e9
			local dry = 0
			for _ = 1, 300 do
				local done = sim:roll()
				if done then
					rolls += 1
					local id = sim.nextUnit - 1
					local u = sim.grid[id]
					local order = Config.RARITIES[Config.PETS[u.pet].rarity].order
					sim.grid[id] = nil -- keep room on the grid
					if order >= 3 then
						dry = 0
					else
						dry += 1
						worst = math.max(worst, dry)
					end
				end
			end
		end
		check("pity: no dry streak of Epic or better reaches " .. Config.PITY_EVERY .. " rolls", worst < Config.PITY_EVERY, "worst streak " .. worst .. " over " .. rolls .. " rolls")
		check("pity: the roll loop really ran", rolls >= 1500, rolls)
		-- roster slot unlocks (T185)
		check("rosterSlots at level 1 is the full unit cap today", Config.rosterSlots(1) == Config.MAX_UNITS, Config.rosterSlots(1))
		local saved = Config.ROSTER_SLOT_UNLOCKS
		Config.ROSTER_SLOT_UNLOCKS = { { level = 1, slots = 6 }, { level = 5, slots = 8 }, { level = 10, slots = 99 } }
		check("a row below its level is not open yet", Config.rosterSlots(4) == 6, Config.rosterSlots(4))
		check("the row at its level opens", Config.rosterSlots(5) == 8, Config.rosterSlots(5))
		check("slots never exceed MAX_UNITS", Config.rosterSlots(25) == Config.MAX_UNITS, Config.rosterSlots(25))
		check("slots are never below 1", (function()
			Config.ROSTER_SLOT_UNLOCKS = { { level = 99, slots = 4 } }
			return Config.rosterSlots(1)
		end)() == 1)
		Config.ROSTER_SLOT_UNLOCKS = saved

		-- recycle refund per tier (T019)
		local pctOk = true
		for t = 1, Config.TIER_MAX do
			if Config.refundPct(t) ~= 1 then
				pctOk = false
			end
		end
		check("default refund is 100 percent at every tier (economy unchanged)", pctOk)
		local base = Config.recycleValue("Ember", 3)
		check("default recycle value is the old formula", base == math.floor(5 * Config.RARITIES[Config.PETS.Ember.rarity].order * 3 ^ 2), base)
		local savedPct = table.clone(Config.REFUND_PCT)
		Config.REFUND_PCT[3] = 0.5
		check("a 50 percent tier pays half", Config.recycleValue("Ember", 3) == math.floor(base * 0.5), Config.recycleValue("Ember", 3))
		check("other tiers are untouched", Config.recycleValue("Ember", 2) == math.floor(5 * Config.RARITIES[Config.PETS.Ember.rarity].order * 3), Config.recycleValue("Ember", 2))
		Config.REFUND_PCT[3] = 7
		check("a refund above 100 percent is clamped to 100", Config.refundPct(3) == 1)
		Config.REFUND_PCT[3] = -1
		check("a negative refund is clamped to 0", Config.refundPct(3) == 0 and Config.recycleValue("Ember", 3) == 0)
		Config.REFUND_PCT[3] = 0 / 0
		check("a NaN refund falls back to 100 percent", Config.refundPct(3) == 1)
		check("a tier without an entry refunds 100 percent", Config.refundPct(99) == 1)
		Config.REFUND_PCT = savedPct
		check("recycle() adds the refunded coins", (function()
			local sim = MatchSim.new(Random.new(3), function() end, false)
			sim.grid[1] = { pet = "Ember", tier = 3 }
			local c0 = sim.coins
			Config.REFUND_PCT[3] = 0.5
			sim:recycle(1)
			Config.REFUND_PCT[3] = 1
			return sim.coins - c0 == math.floor(base * 0.5)
		end)())

		-- difficulty modes (T004)
		local function plain(seed)
			return MatchSim.new(Random.new(seed or 1), function() end, false)
		end
		do
			local sim = plain(1)
			check("a new run is Normal", sim.difficulty == "Normal")
			check("Normal and Hard are labelled in data", Config.DIFFICULTY.Normal.label == "Normal" and Config.DIFFICULTY.Hard.label == "Hard" and #Config.DIFFICULTY_ORDER == 2)
			check("Normal changes nothing (all multipliers are 1)", Config.DIFFICULTY.Normal.hp == 1 and Config.DIFFICULTY.Normal.coins == 1 and Config.DIFFICULTY.Normal.gems == 1)
			check("an unknown id reads as Normal", Config.difficulty("Nightmare") == Config.DIFFICULTY.Normal and Config.difficulty(5) == Config.DIFFICULTY.Normal)
			local okHard, why = sim:setDifficulty("Hard")
			check("Hard is locked until the best stage reaches its unlock stage", okHard == false and sim.difficulty == "Normal", why)
			check("junk difficulty ids are refused", select(1, sim:setDifficulty("Nightmare")) == false and select(1, sim:setDifficulty(5)) == false and select(1, sim:setDifficulty({})) == false and select(1, sim:setDifficulty(nil)) == false)
			sim.bestStage = Config.DIFFICULTY.Hard.unlockStage
			check("Hard can be picked once unlocked", select(1, sim:setDifficulty("Hard")) == true and sim.difficulty == "Hard")
			check("Normal can be picked again before the first wave", select(1, sim:setDifficulty("Normal")) == true and sim.difficulty == "Normal")
			sim:setDifficulty("Hard")
			sim:startWave()
			check("the difficulty is locked once a wave has started", select(1, sim:setDifficulty("Normal")) == false and sim.difficulty == "Hard")
			local tut = MatchSim.new(Random.new(2), function() end, true)
			tut.bestStage = 50
			check("no difficulty change in the tutorial", select(1, tut:setDifficulty("Hard")) == false)
			local later = plain(3)
			later.bestStage = 50
			later.stage = 4
			check("no difficulty change after stage 1", select(1, later:setDifficulty("Hard")) == false)
			check("snapshot carries the difficulty", sim:snapshot().difficulty == "Hard")
		end
		do
			-- hp and rewards scale by difficulty; Normal is exactly the old numbers
			local function firstSpawn(diff)
				local hp
				local sim = MatchSim.new(Random.new(5), function(kind, p)
					if kind == "Spawn" and not hp then
						hp = p.maxHp
					end
				end, false)
				sim.bestStage = 99
				sim:setDifficulty(diff)
				sim:startWave()
				sim:step(0.1)
				return hp
			end
			local hn, hh = firstSpawn("Normal"), firstSpawn("Hard")
			check("Normal spawns Grunts at base hp", near(hn, Config.ENEMIES.Grunt.hp), hn)
			check("Hard spawns the same enemy with the Hard hp multiplier", near(hh, Config.ENEMIES.Grunt.hp * Config.DIFFICULTY.Hard.hp, 1e-6), hh)
			local function killTank(diff)
				local sim = plain(6)
				sim.bestStage = 99
				sim:setDifficulty(diff)
				local e = { id = 1, kind = "Tank", hp = 1, maxHp = 1, dist = 0, dead = false }
				table.insert(sim.enemies, e)
				local c0, g0 = sim.coins, sim.gems
				sim:damage(e, 5, false)
				return sim.coins - c0, sim.gems - g0
			end
			local cn, gn = killTank("Normal")
			local ch, gh = killTank("Hard")
			check("Normal kill reward is the old reward", cn == Config.ENEMIES.Tank.coins and gn == Config.ENEMIES.Tank.gems, cn .. "/" .. gn)
			check("Hard pays more coins and gems", ch == math.floor(Config.ENEMIES.Tank.coins * Config.DIFFICULTY.Hard.coins + 0.5) and gh == math.floor(Config.ENEMIES.Tank.gems * Config.DIFFICULTY.Hard.gems + 0.5) and ch > cn and gh > gn, ch .. "/" .. gh)
		end
		do
			-- the saved difficulty (T004): only a known, unlocked id loads
			local sim = plain(7)
			sim:loadMeta({ bestStage = 3, difficulty = "Hard" })
			check("a saved Hard that is not unlocked loads as Normal", sim.difficulty == "Normal")
			sim = plain(7)
			sim:loadMeta({ bestStage = Config.DIFFICULTY.Hard.unlockStage, difficulty = "Hard" })
			check("a saved unlocked Hard loads", sim.difficulty == "Hard")
			check("meta() holds the difficulty for the profile", sim:meta().difficulty == "Hard")
			sim = plain(7)
			sim:loadMeta({ bestStage = 50, difficulty = { evil = true } })
			check("a junk saved difficulty loads as Normal", sim.difficulty == "Normal")
			sim = plain(7)
			sim:loadMeta({ bestStage = 50, difficulty = "Godmode" })
			check("an unknown saved difficulty loads as Normal", sim.difficulty == "Normal")
		end
		do
			-- placement rules per map (T177): data in StageSets place, read through Config.mapRules, flag Config.MAP_RULES
			local SS = require(tmp.StageSets)
			local pet = Config.PET_ORDER[1]
			local fp = Config.footprint(pet)
			check("MAP_RULES is off by default and mapRules gives nil", Config.MAP_RULES == false and Config.mapRules(7) == nil)
			local function gridLegal(rules, label)
				local map, n = {}, 0
				for x = -50, 46, 2 do
					for z = -26, 28, 2 do
						local ok2 = Config.canPlace({}, pet, x, z, nil, rules)
						map[x .. "," .. z] = ok2
						n += ok2 and 1 or 0
					end
				end
				return map, n
			end
			local base, baseCount = gridLegal(nil)
			local function sameMap(a, b)
				for k, v in a do
					if b[k] ~= v then
						return false
					end
				end
				return true
			end
			Config.MAP_RULES = true
			Config.PATH_PER_SET = true -- the zones and decorations are authored against each set's own lane
			local first = Config.mapRules(1)
			check("flag on: rules for stage 1 carry bounds, path, noBuild and decor", first ~= nil and first.bounds == Config.PLACE_BOUNDS and #first.path == #Config.PATH and #first.noBuild == 0 and #first.decor == 2)
			check("flag on: the first set's legal spots equal today's rules everywhere", sameMap(base, (gridLegal(first))) and sameMap((gridLegal(first)), base))
			for si, set in SS.list do
				local stage = 1
				for k = 1, si - 1 do
					stage += SS.list[k].stages
				end
				local rules = Config.mapRules(stage)
				local n = set.id
				check(n .. ": rules come from the set (path and no-build zones)", rules ~= nil and #rules.noBuild == #(set.place and set.place.noBuild or {}) and #rules.path == #Config.pathFor(stage))
				for zi, zone in set.place.noBuild do
					local ok3, why = Config.canPlace({}, pet, zone.x, zone.z, nil, rules)
					check(n .. ": no-build zone " .. zi .. " centre is refused as a blocked area", ok3 == false and why == "Blocked area", why)
					check(n .. ": the same spot is legal under the old rules unless it is on the path", select(1, Config.canPlace({}, pet, zone.x, zone.z)) == (Config.distToPath(zone.x, zone.z) >= Config.PATH_HALF_WIDTH + fp * 0.6))
					check(n .. ": just outside the zone is legal", select(1, Config.canPlace({}, pet, zone.x + zone.r + fp * 0.6 + 0.2, zone.z, nil, rules)) == true)
				end
				for di, d in set.place.decor do
					check(n .. ": decoration " .. di .. " never blocks placement on it", select(1, Config.canPlace({}, pet, d.x, d.z, nil, rules)) == true)
				end
				local noDecor = { bounds = rules.bounds, path = rules.path, noBuild = rules.noBuild, decor = {} }
				local m1, count = gridLegal(rules)
				check(n .. ": removing every decoration changes no spot", sameMap(m1, (gridLegal(noDecor))))
				check(n .. ": at least 60 legal spots on the 2 stud grid", count >= 60, count)
				local wp = rules.path[3]
				local okp, whyp = Config.canPlace({}, pet, wp.X, wp.Z, nil, rules)
				check(n .. ": the set's own lane is refused", okp == false and whyp == "Not on the path", whyp)
			end
			-- the sim follows the rules for its stage
			local function simAt(stage)
				local sim = plain(11)
				sim.stage = stage
				return sim
			end
			local zone = SS.list[2].place.noBuild[1]
			Config.MAP_RULES = false
			local sim = simAt(6)
			local id = sim:addUnit(pet, 0, 24)
			check("flag off: the sim lets a unit stand in the Harbour no-build circle", select(1, sim:move(id, zone.x, zone.z)) == true)
			Config.MAP_RULES = true
			sim = simAt(6)
			id = sim:addUnit(pet, 0, 24)
			local okm, whym = sim:move(id, zone.x, zone.z)
			check("flag on: the sim refuses a move into the Harbour no-build circle", okm == false and whym == "Blocked area", whym)
			local sim1 = simAt(1)
			check("flag on: the same move at stage 1 is allowed (set 1 has no zones)", select(1, sim1:move(sim1:addUnit(pet, 0, 24), zone.x, zone.z)) == (Config.distToPath(zone.x, zone.z) >= Config.PATH_HALF_WIDTH + fp * 0.6))
			sim = simAt(6)
			local allLegal = true
			for _ = 1, 10 do
				local fx, fz = sim:findSpot(pet)
				if fx == nil or not Config.canPlace(sim.grid, pet, fx, fz, nil, Config.mapRules(6)) then
					allLegal = false
					break
				end
				sim:addUnit(pet, fx, fz)
			end
			check("flag on: ten auto-placed units at stage 6 all stand on legal spots", allLegal)
			Config.MAP_RULES, Config.PATH_PER_SET = false, false
		end
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " Rules: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
