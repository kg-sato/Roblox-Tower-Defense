--!nocheck
-- Headless checks for the server rules not covered by MatchSim.test.luau (T202): roll cost, recycle, upgrade, skill tree, merge refusals, kill rewards, xp and level-up, ultimate charge.
-- Run in Studio (Edit mode) with execute_luau: put this file's text in a temporary ModuleScript, require it and call the result with a fresh Shared clone:
--   return require(tempModule)(game.ReplicatedStorage.Shared)
-- It clones Config, Path and MatchSim, so nothing is changed. Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_ServerRulesTest"
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
	local events
	local function newSim(seed)
		events = {}
		local sim = MatchSim.new(Random.new(seed or 1), function(kind, p)
			table.insert(events, kind)
		end, false)
		return sim
	end
	local function has(kind)
		return table.find(events, kind) ~= nil
	end
	local function firstUnit(sim)
		for id, u in sim.grid do
			return id, u
		end
	end

	local ok, err = pcall(function()
		-- roll
		local sim = newSim(1)
		sim.gems = sim:rollCost() - 1
		check("roll with too few gems is refused", select(1, sim:roll()) == false and sim:unitCount() == 0)
		sim.gems = 100
		local before = sim.gems
		check("roll succeeds with enough gems", select(1, sim:roll()) == true)
		check("roll takes exactly the roll cost", before - sim.gems == sim:rollCost(), before - sim.gems)
		check("roll puts one unit on the grid and emits Roll", sim:unitCount() == 1 and has("Roll"))

		-- recycle
		local id, u = firstUnit(sim)
		local coins0 = sim.coins
		check("recycle of an empty slot is refused", select(1, sim:recycle(99999)) == false)
		check("recycle succeeds", select(1, sim:recycle(id)) == true and sim.grid[id] == nil)
		check("recycle pays the recycle value", sim.coins - coins0 == Config.recycleValue(u.pet, u.tier), sim.coins - coins0)
		check("a recycled unit cannot be recycled twice", select(1, sim:recycle(id)) == false)

		-- upgrade
		sim = newSim(2)
		sim.gems = 100
		sim:roll()
		local _, pet = firstUnit(sim)
		local name = pet.pet
		check("upgrade with a number as pet is refused", select(1, sim:upgrade(5, "Power")) == false)
		check("upgrade with nil kind is refused", select(1, sim:upgrade(name, nil)) == false)
		check("upgrade of an unknown pet is refused", select(1, sim:upgrade("NoSuchPet", "Power")) == false)
		check("upgrade of an unknown kind is refused", select(1, sim:upgrade(name, "Teleport")) == false)
		local other
		for _, p in Config.PET_ORDER do
			if p ~= name then
				other = p
				break
			end
		end
		check("upgrade of a pet not on the grid is refused", select(1, sim:upgrade(other, "Power")) == false)
		sim.coins = Config.upgradeCost(0) - 1
		check("upgrade with too few coins is refused", select(1, sim:upgrade(name, "Power")) == false and sim.upgrades[name].Power == 0)
		sim.coins = 100000
		local spent = 0
		for lvl = 0, Config.UPGRADE_MAX - 1 do
			local c0 = sim.coins
			local okU = select(1, sim:upgrade(name, "Power"))
			if okU then
				spent += c0 - sim.coins
			end
			check("upgrade level " .. (lvl + 1) .. " costs " .. Config.upgradeCost(lvl), okU and c0 - sim.coins == Config.upgradeCost(lvl), c0 - sim.coins)
		end
		check("upgrade stops at the maximum level", select(1, sim:upgrade(name, "Power")) == false and sim.upgrades[name].Power == Config.UPGRADE_MAX)
		check("the three upgrade kinds are independent", sim.upgrades[name].Haste == 0 and sim.upgrades[name].Crit == 0)

		-- skill tree
		sim = newSim(3)
		check("skill with a non-string id is refused", select(1, sim:skill(5)) == false and select(1, sim:skill(nil)) == false)
		check("skill Start cannot be bought", select(1, sim:skill("Start")) == false)
		check("skill with an unknown id is refused", select(1, sim:skill("NoSuchNode")) == false)
		sim.sp = 100
		check("a node with no owned neighbour is refused", select(1, sim:skill("Mega")) == false)
		sim.sp = 0
		check("a reachable node with no skill points is refused", select(1, sim:skill("Claws")) == false)
		sim.sp = 100
		local node = Config.TREE_BY_ID.Claws
		local totalCost = 0
		for lvl = 0, node.max - 1 do
			totalCost += Config.skillCost(node, lvl)
		end
		for _ = 1, node.max do
			sim:skill("Claws")
		end
		check("Claws reaches its maximum level", sim.tree.Claws == node.max, sim.tree.Claws)
		check("buying Claws to max spends exactly the listed costs", 100 - sim.sp == totalCost, 100 - sim.sp .. " of " .. totalCost)
		check("a maxed node is refused", select(1, sim:skill("Claws")) == false)
		check("a node next to an owned node can now be bought", select(1, sim:skill("Heavy")) == true and sim.tree.Heavy == 1)

		-- merge refusals
		sim = newSim(4)
		sim.gems = 1000
		for _ = 1, 3 do
			sim:roll()
		end
		local ids = {}
		for i in sim.grid do
			table.insert(ids, i)
		end
		check("merge of a unit with itself is refused", select(1, sim:merge(ids[1], ids[1])) == false)
		check("merge with a missing unit is refused", select(1, sim:merge(ids[1], 99999)) == false)
		sim.grid[ids[1]].tier = 2
		check("merge of different tiers is refused", select(1, sim:merge(ids[1], ids[2])) == false)
		sim.grid[ids[1]].pet, sim.grid[ids[2]].pet = "Ember", "Ember"
		sim.grid[ids[1]].tier, sim.grid[ids[2]].tier = Config.TIER_MAX, Config.TIER_MAX
		check("merge at the maximum tier is refused", select(1, sim:merge(ids[1], ids[2])) == false)

		-- kill rewards, xp and level-up
		sim = newSim(5)
		local gems0, coins0b, ult0 = sim.gems, sim.coins, sim.ult
		local e = { id = 1, kind = "Grunt", hp = 5, dead = false }
		sim:damage(e, 10, true)
		check("a killed enemy is marked dead and pays", e.dead and sim.coins > coins0b and sim.gems > gems0)
		check("a kill charges the ultimate when asked", sim.ult == ult0 + 1)
		local c1 = sim.coins
		sim:damage(e, 10, true)
		check("a dead enemy pays only once", sim.coins == c1)
		local boss = { id = 2, kind = "Boss", hp = 1, dead = false }
		local sp1, level1 = sim.sp, sim.level
		sim:damage(boss, 5, false)
		check("a boss kill gives one skill point plus one per level it triggers", sim.sp - sp1 == 1 + (sim.level - level1), sim.sp - sp1)
		sim = newSim(6)
		local gemsA, spA = sim.gems, sim.sp
		sim:addXp(Config.xpNeed(1))
		check("enough xp raises the level to 2 and pays level gems and a skill point", sim.level == 2 and sim.gems - gemsA == Config.levelGems(2) and sim.sp - spA == 1, sim.level .. " / " .. (sim.gems - gemsA) .. " / " .. (sim.sp - spA))
		check("level-up emits LevelUp", has("LevelUp"))
		sim:addXp(1e12)
		check("the level never passes the cap", sim.level == Config.LEVEL_MAX, sim.level)
		check("xp stays non-negative", sim.xp >= 0, sim.xp)

		-- respec (T198): refund, fee, cooldown, clamps
		sim = newSim(8)
		sim.gems, sim.sp = 1000, 100
		check("respec with nothing spent is refused", select(1, sim:respec()) == false)
		sim:skill("Claws")
		sim:skill("Claws")
		sim:skill("Armor")
		local spentSp = 100 - sim.sp
		local hpBefore = sim:maxHp()
		sim.crystalHp = sim:maxHp()
		local gemsR, spR = sim.gems, sim.sp
		check("respec succeeds after spending points", select(1, sim:respec()) == true)
		check("respec refunds every point spent", sim.sp - spR == spentSp, sim.sp - spR .. " of " .. spentSp)
		check("respec costs the fee in gems", gemsR - sim.gems == Config.RESPEC_COST, gemsR - sim.gems)
		check("respec resets the tree to Start only", sim.tree.Start == 1 and sim.tree.Claws == nil and sim.tree.Armor == nil)
		check("respec emits Respec", has("Respec"))
		check("crystal hp is clamped to the new maximum", sim.crystalHp <= sim:maxHp() and sim:maxHp() < hpBefore, sim.crystalHp .. " / " .. sim:maxHp())
		sim:skill("Claws")
		check("a second respec inside the cooldown is refused", select(1, sim:respec()) == false)
		sim.t += Config.RESPEC_COOLDOWN + 1
		check("a respec after the cooldown works", select(1, sim:respec()) == true)
		sim:skill("Claws")
		sim.t += Config.RESPEC_COOLDOWN + 1
		sim.gems = Config.RESPEC_COST - 1
		check("a respec without enough gems is refused and keeps the tree", select(1, sim:respec()) == false and sim.tree.Claws == 1)

		-- crit clamp (T195)
		sim = newSim(9)
		sim.gems = 1000
		sim:roll()
		local _, cu = firstUnit(sim)
		sim.upgrades[cu.pet].Crit = Config.UPGRADE_MAX
		sim.tree.Eye = 50 -- far more crit than any real tree allows
		local _, _, critChance = sim:effective(cu)
		check("crit chance is clamped to the cap", critChance == Config.CRIT_CAP, critChance)
		sim.tree.Eye = nil
		sim.upgrades[cu.pet].Crit = 0
		local dmg0, cd0, crit0 = sim:effective(cu)
		check("with no crit upgrades the chance is zero and damage and cooldown are positive", crit0 == 0 and dmg0 > 0 and cd0 > 0)
		sim.upgrades[cu.pet].Crit = 2
		local _, _, crit2 = sim:effective(cu)
		check("crit rises with upgrade levels below the cap", math.abs(crit2 - 2 * Config.UPGRADES.Crit.per) < 1e-9, crit2)

		-- ultimate
		sim = newSim(7)
		check("an uncharged ultimate is refused", select(1, sim:castUlt()) == false)
		sim.ult = sim:ultNeed()
		check("a charged ultimate casts", select(1, sim:castUlt()) == true and has("Ult"))
		check("casting spends the charge", sim.ult < sim:ultNeed(), sim.ult)
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " ServerRules: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
