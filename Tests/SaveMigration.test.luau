--!nocheck
-- Save migration checks (T204): old-shaped profiles load into the current rules without losing what is still valid. Run in Studio (Edit mode) through a temporary ModuleScript with a fresh Shared clone:
--   return require(tempModule)(game.ReplicatedStorage.Shared)
-- Clones Config, Path, MatchSim and SettingsDefaults; nothing is changed. Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_SaveMigrationTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim", "SettingsDefaults" } do
		Shared[n]:Clone().Parent = tmp
	end
	local Config = require(tmp.Config)
	local MatchSim = require(tmp.MatchSim)
	local Settings = require(tmp.SettingsDefaults)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local function newSim(seed)
		return MatchSim.new(Random.new(seed), function() end, false)
	end
	local ok, err = pcall(function()
		local startGems = newSim(1).gems
		-- the first template: only level, xp and gems (no sp, no tree, no settings, no seen)
		local a = newSim(2)
		a:loadMeta({ version = 1, level = 3, xp = 5, gems = startGems + 40 })
		check("an old profile with only level, xp and gems keeps them", a.level == 3 and a.xp == 5 and a.gems == startGems + 40, a.level .. "/" .. a.xp .. "/" .. a.gems)
		check("missing skill points default to zero", a.sp == 0)
		check("a missing tree still has the Start node", a.tree.Start == 1)

		-- extra and renamed fields from other versions are ignored, valid ones kept
		local b = newSim(3)
		b:loadMeta({ version = 7, level = 5, xp = 9, sp = 2, gems = 100, tree = { Start = 1, Claws = 3, RemovedNode = 4 }, futureField = { x = 1 }, tutorialDone = true })
		check("valid tree levels survive a load", b.tree.Claws == 3, b.tree.Claws)
		check("a tree node that no longer exists is dropped", b.tree.RemovedNode == nil)
		check("unknown top-level fields do not break the load", b.level == 5 and b.sp == 2 and b.gems == 100)
		-- known data loss, stated: skill points spent on a removed node are not refunded
		check("KNOWN GAP: points spent on a removed node are not refunded (sp stays 2)", b.sp == 2)

		-- meta() writes what loadMeta reads
		local c = newSim(4)
		c.level, c.xp, c.sp, c.gems = 9, 40, 6, 321
		c.tree.Claws, c.tree.Magnet = 2, 1
		local m = c:meta()
		check("meta() has level, xp, sp, gems and tree", m.level == 9 and m.xp == 40 and m.sp == 6 and m.gems == 321 and type(m.tree) == "table")
		local d = newSim(5)
		d:loadMeta(m)
		check("meta() then loadMeta restores the tree", d.tree.Claws == 2 and d.tree.Magnet == 1)
		local twice = newSim(6)
		twice:loadMeta(d:meta())
		check("a second round trip changes nothing", twice.level == 9 and twice.sp == 6 and twice.gems == 321 and twice.tree.Claws == 2)

		-- the profile level can never exceed the cap, and a lowered cap would clamp rather than error
		local e = newSim(7)
		e:loadMeta({ level = Config.LEVEL_MAX + 10, xp = 1, sp = 0, gems = 0 })
		check("a level above the cap loads clamped", e.level <= Config.LEVEL_MAX, e.level)

		-- stage progress (T411): bestStage and lastStage are new fields; old saves lack them
		local f = newSim(8)
		f:loadMeta({ version = 1, level = 2, xp = 0, sp = 0, gems = 0 })
		check("an old save without bestStage loads with best stage 1", f.bestStage == 1, f.bestStage)
		check("a load never moves the run's own stage", f.stage == 1)
		local g = newSim(9)
		g:loadMeta({ bestStage = 12, lastStage = 9 })
		check("a saved best stage loads", g.bestStage == 12, g.bestStage)
		local h = newSim(10)
		h:loadMeta({ bestStage = 4, lastStage = 9 })
		check("the best stage is never below the last stage", h.bestStage == 9, h.bestStage)
		for label, bad in { ["huge"] = 1e12, ["negative"] = -5, ["NaN"] = 0 / 0, ["string"] = "9", ["table"] = {} } do
			local x = newSim(11)
			x:loadMeta({ bestStage = bad, lastStage = bad })
			check("a " .. label .. " best stage is clamped into 1 to 1000", x.bestStage >= 1 and x.bestStage <= 1000, x.bestStage)
		end
		local y = newSim(12)
		y.stage = 7
		local ym = y:meta()
		check("meta() carries best and last stage", ym.bestStage == 7 and ym.lastStage == 7, ym.bestStage .. "/" .. ym.lastStage)
		y.stage = 3 -- an overrun sets the stage back; the best stays
		y.bestStage = 7
		local ym2 = y:meta()
		check("after a setback the best stage stays and the last stage drops", ym2.bestStage == 7 and ym2.lastStage == 3, ym2.bestStage .. "/" .. ym2.lastStage)
		local z = newSim(13)
		z:loadMeta(ym2)
		check("best and last stage survive a round trip", z.bestStage == 7)
		check("meta() of a fresh sim reports stage 1", newSim(15):meta().bestStage == 1)

		-- settings: an old profile without settings, or with only some, gets full defaults and keeps its valid values
		local def = Settings.copyDefaults()
		local s0 = Settings.sanitize(nil)
		local sameDefaults = true
		for k, v in def do
			if s0[k] ~= v then
				sameDefaults = false
			end
		end
		check("missing settings become the defaults", sameDefaults)
		local firstKey, firstVal
		for k, v in def do
			firstKey, firstVal = k, v
			break
		end
		local partial = Settings.sanitize({ [firstKey] = firstVal, notASetting = 5 })
		check("partial settings are filled in and junk keys dropped", partial[firstKey] == firstVal and partial.notASetting == nil)
		local complete = true
		for k in def do
			if partial[k] == nil then
				complete = false
			end
		end
		check("every default key is present after sanitize", complete)

		-- collection: duplicates and shards (T186)
		do
			local coll = {}
			local pet = Config.PET_ORDER[1]
			local rarity = Config.PETS[pet].rarity
			check("the first pull is new and holds one copy and no shards", Config.collectionAdd(coll, pet) == true and coll[pet].count == 1 and coll[pet].shards == 0)
			check("a duplicate is not new, adds a copy and shards by rarity", Config.collectionAdd(coll, pet) == false and coll[pet].count == 2 and coll[pet].shards == Config.SHARDS_PER_DUPLICATE[rarity], coll[pet].shards)
			Config.collectionAdd(coll, pet)
			check("shards grow with every duplicate", coll[pet].count == 3 and coll[pet].shards == 2 * Config.SHARDS_PER_DUPLICATE[rarity])
			check("shardsFor an unknown pet is 0", Config.shardsFor("NotAPet") == 0)
			local ok2 = true
			for _, r in Config.RARITY_ORDER do
				if type(Config.SHARDS_PER_DUPLICATE[r]) ~= "number" or Config.SHARDS_PER_DUPLICATE[r] <= 0 then
					ok2 = false
				end
			end
			check("every rarity pays shards", ok2)
			local lastR, rising = 0, true
			for _, r in Config.RARITY_ORDER do
				if Config.SHARDS_PER_DUPLICATE[r] < lastR then
					rising = false
				end
				lastR = Config.SHARDS_PER_DUPLICATE[r]
			end
			check("rarer familiars pay more shards", rising)
			coll[pet].count = Config.COLLECTION_MAX
			coll[pet].shards = Config.COLLECTION_MAX
			Config.collectionAdd(coll, pet)
			check("counts and shards stop at the cap", coll[pet].count == Config.COLLECTION_MAX and coll[pet].shards == Config.COLLECTION_MAX)
			-- migration of the older `seen` list and clamping of a damaged save
			local second = Config.PET_ORDER[2]
			local m = Config.sanitizeCollection(nil, { [pet] = true, [second] = true, NotAPet = true, [Config.PET_ORDER[3]] = false })
			check("an old save with only `seen` gives one copy each of the real ones", m[pet] and m[pet].count == 1 and m[pet].shards == 0 and m[second] and m[second].count == 1 and m.NotAPet == nil and m[Config.PET_ORDER[3]] == nil)
			local raw = { [pet] = { count = 5, shards = 12 }, [second] = { count = -4, shards = 1e99 }, NotAPet = { count = 1, shards = 1 }, [Config.PET_ORDER[3]] = "bad", [Config.PET_ORDER[4]] = { count = 0 / 0, shards = "x" } }
			local c2 = Config.sanitizeCollection(raw, {})
			check("a saved collection keeps good counts", c2[pet].count == 5 and c2[pet].shards == 12)
			check("a damaged collection is clamped to whole numbers in range", c2[second].count == 1 and c2[second].shards == Config.COLLECTION_MAX and c2[Config.PET_ORDER[4]].count == 1 and c2[Config.PET_ORDER[4]].shards == 0)
			check("a damaged collection drops unknown pets and non-table entries", c2.NotAPet == nil and c2[Config.PET_ORDER[3]] == nil)
			check("a non-table collection gives an empty one", next(Config.sanitizeCollection("junk", nil)) == nil and next(Config.sanitizeCollection(5, 7)) == nil)
			local both = Config.sanitizeCollection({ [pet] = { count = 4, shards = 9 } }, { [pet] = true, [second] = true })
			check("seen never lowers a stored count and fills the missing ones", both[pet].count == 4 and both[pet].shards == 9 and both[second].count == 1)
		end
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " SaveMigration: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
