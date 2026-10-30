--!nocheck
-- Headless checks for the server rules not covered by MatchSim.test.luau (T202): roll cost, recycle, upgrade, skill tree, merge refusals, kill rewards, xp and level-up, ultimate charge.
-- Run in Studio (Edit mode) with execute_luau: put this file's text in a temporary ModuleScript, require it and call the result with a fresh Shared clone:
--   return require(tempModule)(game.ReplicatedStorage.Shared)
-- It clones Config, Path and MatchSim, so nothing is changed. Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_ServerRulesTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim", "ProgressHooks", "Achievements", "Quests", "Bond", "LeaderboardRules", "LoreFragments", "Familiars" } do
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

		-- pause and resume per run (T006)
		do
			local function near(x, y, eps)
				return math.abs(x - y) <= (eps or 1e-6)
			end
			local sim = newSim(11)
			sim:startWave()
			for _ = 1, 40 do
				sim:step(0.1)
			end
			local t0, dist0 = sim.t, sim.enemies[1] and sim.enemies[1].dist
			check("a wave is running before the pause test", sim.state == "active" and dist0 ~= nil)
			check("Pause refuses a non-boolean", select(1, sim:pause("yes")) == false and select(1, sim:pause(nil)) == false and sim.userPaused == false)
			check("Pause on works", select(1, sim:pause(true)) == true and sim.userPaused == true and has("Pause"))
			check("snapshot shows the pause", sim:snapshot().userPaused == true and sim:snapshot().pauseLeft == Config.PAUSE_MAX)
			for _ = 1, 100 do
				sim:step(0.1)
			end
			check("while paused the sim clock stands still", near(sim.t, t0, 1e-9), sim.t)
			check("while paused enemies do not move", sim.enemies[1] and near(sim.enemies[1].dist, dist0, 1e-9))
			check("pausing twice is harmless", select(1, sim:pause(true)) == true and sim.userPaused == true)
			check("Resume works", select(1, sim:pause(false)) == true and sim.userPaused == false)
			sim:step(0.5)
			check("after Resume time moves again", sim.t > t0 + 0.4)
			check("resuming when not paused is harmless", select(1, sim:pause(false)) == true)
			-- the pause ends by itself
			sim:pause(true)
			sim:tickPause(Config.PAUSE_MAX - 1)
			check("a pause still holds just before the cap", sim.userPaused == true)
			events = {}
			sim:tickPause(2)
			check("the pause ends by itself after Config.PAUSE_MAX", sim.userPaused == false and sim.pauseLeft == 0 and has("Pause"))
			sim:tickPause(100)
			check("tickPause does nothing while running", sim.userPaused == false)
			local tut = MatchSim.new(Random.new(2), function() end, true)
			check("no user pause in the tutorial", select(1, tut:pause(true)) == false and tut.userPaused == false)
			-- the run as a plain table
			local a = newSim(12)
			a.coins = 777
			a.stage = 7
			a.combo = 3
			local u1 = a:addUnit("Ember", -40, -2)
			a.grid[u1].tier = 3
			a.upgrades.Ember.Power = 2
			a.bestStage = 40
			a:setDifficulty("Hard")
			local saved = a:exportRun()
			local b = newSim(13)
			b.bestStage = 40
			check("a saved run loads", b:importRun(saved) == true)
			local only
			for _, u in b.grid do
				only = u
			end
			check("the loaded run keeps stage, coins and combo", b.stage == 7 and b.coins == 777 and b.combo == 3)
			check("the loaded run keeps units and upgrades", b:unitCount() == 1 and only.pet == "Ember" and only.tier == 3 and b.upgrades.Ember.Power == 2)
			check("a loaded run starts paused until the player resumes", b.userPaused == true and b.pauseLeft == Config.PAUSE_MAX)
			check("a loaded run is ready, not mid-wave", b.state == "ready" and #b.enemies == 0)
			local c = newSim(14)
			check("importRun refuses junk", c:importRun(nil) == false and c:importRun("x") == false and c:importRun(5) == false)
			check("the tutorial refuses a loaded run", tut:importRun(saved) == false)
			local d = newSim(15)
			d:importRun({ stage = -5, coins = -1, crystal = 1e9, combo = 1e9, difficulty = "Hard", grid = { a = { pet = "NotAPet", tier = 1, x = 0, z = 0 }, b = { pet = "Ember", tier = 99, x = -40, z = -2 }, c = { pet = "Ember", tier = 1, x = "no", z = 0 } }, upgrades = { Ember = { Power = 99, Haste = -3, Crit = 0 }, Nope = {} } })
			local ones = {}
			for _, u in d.grid do
				table.insert(ones, u)
			end
			check("a damaged run is clamped: stage, coins, crystal and combo", d.stage == 1 and d.coins == 0 and d.crystalHp <= d:maxHp() and d.combo <= 1000)
			check("a damaged run drops unknown pets and bad coordinates and clamps tiers", #ones == 1 and ones[1].tier == Config.TIER_MAX)
			check("a damaged run clamps upgrades", d.upgrades.Ember.Power == Config.UPGRADE_MAX and d.upgrades.Ember.Haste == 0)
			check("a loaded run cannot take a difficulty it has not unlocked", d.difficulty == "Normal")
		end

		-- T652: hooks fed by a real sim
		do
			local H = require(tmp.ProgressHooks)
			local T0 = 20000 * 86400
			local function runWith(flags)
				local d = { seen = {} }
				H.sanitize(d)
				local ctx = H.start(d, flags, T0 + 50, { userId = 5, petFaction = function(p) local x = Config.PETS[p]; return x and x.faction end })
				local paid, sent, rolls = 0, {}, 0
				local sim = MatchSim.new(Random.new(7), function(kind, payload)
					if kind == "Roll" and not payload.bonus then
						d.seen[payload.pet] = true
						rolls += 1
					end
					local out = H.event(ctx, kind, payload, T0 + 60, false)
					paid += out.gems
					for _, e in out.events do
						table.insert(sent, e.kind)
					end
				end, false)
				sim.gems = 500
				for _ = 1, 6 do
					sim:roll()
				end
				sim:startWave()
				for _ = 1, 4000 do
					sim:step(0.1)
					if sim.stage >= 2 then
						break
					end
				end
				return d, paid, sent, rolls, sim
			end
			local on = { achievements = true, quests = true, bond = true, leaderboard = false }
			local d, paid, sent, rolls, sim = runWith(on)
			check("T652 flags on: real rolls feed achievements and quests", rolls >= 1 and d.achievements.stats.rolls == rolls and d.quests.stats.rolls == rolls, tostring(d.achievements.stats.rolls) .. "/" .. rolls)
			check("T652 flags on: the first roll unlocks FirstSummon, pays gems and sends an Achievement event", d.achievements.unlocked.FirstSummon == true and paid >= 5 and table.find(sent, "Achievement") ~= nil)
			check("T652 flags on: runsPlayed counted at start and bestStage follows the stage", d.achievements.stats.runsPlayed == 1 and (d.achievements.stats.bestStage or 0) >= 1)
			check("T652 flags on: a cleared stage counts", sim.stage < 2 or ((d.achievements.stats.stagesCleared or 0) >= 1 and (d.quests.life.bestCleared or 0) >= 1), tostring(d.achievements.stats.stagesCleared) .. " stage " .. sim.stage)
			local off = { achievements = false, quests = false, bond = false, leaderboard = false }
			local d2, paid2, sent2 = runWith(off)
			check("T652 flags off: nothing is counted, paid or sent", next(d2.achievements.stats) == nil and next(d2.quests.stats) == nil and next(d2.achievements.unlocked) == nil and paid2 == 0 and #sent2 == 0)
			local d3 = {}
			H.sanitize(d3)
			local c3 = H.start(d3, on, T0, nil)
			local tut = H.event(c3, "Roll", { pet = "Ember" }, T0, true)
			check("T652 the tutorial run counts nothing", tut.gems == 0 and #tut.events == 0 and d3.achievements.stats.rolls == nil)
			check("T652 hostile payloads are ignored, not errors", (pcall(function()
				H.event(c3, "Roll", "x", 1, false)
				H.event(c3, "Merge", { tier = "big", pet = 5 }, 1, false)
				H.event(c3, "Clear", { stage = -1 / 0 }, 1, false)
			end)))
			H.flush(c3, T0 + 10)
			local before = d3.achievements.stats.rolls
			H.event(c3, "Roll", { pet = "Ember" }, T0 + 11, false)
			check("T652 a flushed run takes no more events", d3.achievements.stats.rolls == before)
		end
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " ServerRules: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
