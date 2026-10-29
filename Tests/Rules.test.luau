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

	local ok, err = pcall(function()
		-- enemy scaling per stage (T150)
		check("hpScale(1) is 1", near(Config.hpScale(1), 1))
		check("hpScale(25) is 1.2^24", near(Config.hpScale(25), 1.2 ^ 24, 1e-6), Config.hpScale(25))
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
		check("luck 0 gives 60 percent Common", near(p0.Common, 60, 1e-6), p0.Common)
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
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " Rules: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
