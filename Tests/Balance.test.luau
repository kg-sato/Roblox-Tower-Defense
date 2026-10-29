--!nocheck
-- Balance baseline: bots play headless runs on fixed seeds, nothing in the game changes.
-- Strategies: idle (auto waves only), roll (rolls gems), upgrade (roll + coin upgrades), full (roll + merge + upgrade + recycle when full).
-- Run in Studio (Edit mode) with execute_luau, serving Tests/ locally:
--   local body = game:GetService("HttpService"):GetAsync("http://127.0.0.1:8792/Balance.test.luau")
--   return loadstring(body)()(game.ReplicatedStorage.Shared)
-- Returns a report string; the first line says PASS or FAIL. It clones Config/Path/MatchSim, so nothing is changed.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_BalanceTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim" } do
		Shared[n]:Clone().Parent = tmp
	end
	local Config = require(tmp.Config)
	local MatchSim = require(tmp.MatchSim)

	local SEEDS = { 1, 2, 3 }
	local MARKS = { 1, 2, 3, 5, 10, 20 }
	local DT = 0.1
	local out, problems = {}, {}
	local function line(s)
		table.insert(out, s)
	end
	-- the numbers are a baseline, not assertions; only sanity of the runs is checked
	local function check(name, cond)
		if not cond then
			table.insert(problems, name)
		end
	end

	local function mergeAll(sim)
		local progressed = true
		while progressed do
			progressed = false
			local groups = {}
			for id, u in sim.grid do
				local k = u.pet .. ":" .. u.tier
				groups[k] = groups[k] or {}
				table.insert(groups[k], id)
			end
			for _, ids in groups do
				if #ids >= 3 then
					local b = ids[1]
					local ub = sim.grid[b]
					if ub and ub.tier < Config.TIER_MAX then
						local a, c = ids[2], ids[3]
						if not MatchSim.findThird(sim.grid, a, b) then
							local u = sim.grid[c]
							for _, off in { { 0, 7 }, { 0, -7 }, { 7, 0 }, { -7, 0 } } do
								if sim:move(c, ub.x + off[1], ub.z + off[2]) then
									break
								end
							end
						end
						if sim:drop(a, b) then
							progressed = true
							break
						end
					end
				end
			end
		end
	end

	local function spendUpgrades(sim)
		local best
		for pet, ups in sim.upgrades do
			for kind in ups do
				local owned = false
				for _, u in sim.grid do
					if u.pet == pet then
						owned = true
					end
				end
				if owned and ups[kind] < Config.UPGRADE_MAX then
					local cost = sim:upgradeCostFor(pet, kind)
					if cost <= sim.coins and (not best or cost < best.cost) then
						best = { pet = pet, kind = kind, cost = cost }
					end
				end
			end
		end
		if best then
			sim:upgrade(best.pet, best.kind)
			return true
		end
		return false
	end

	local function act(sim, strategy)
		if strategy == "idle" then
			return
		end
		local guard = 0
		while guard < 60 do
			guard += 1
			local did = false
			if sim.gems >= sim:rollCost() and sim:unitCount() < Config.MAX_UNITS then
				did = sim:roll() or did
			elseif strategy == "full" and sim:unitCount() >= Config.MAX_UNITS and sim.gems >= sim:rollCost() then
				local worst, wv
				for id, u in sim.grid do
					local v = Config.recycleValue(u.pet, u.tier)
					if not wv or v < wv then
						worst, wv = id, v
					end
				end
				if worst then
					sim:recycle(worst)
					did = true
				end
			end
			if strategy == "full" then
				local before = sim.maxTier
				mergeAll(sim)
				did = did or sim.maxTier ~= before
			end
			if strategy ~= "roll" then
				did = spendUpgrades(sim) or did
			end
			if not did then
				break
			end
		end
	end

	local function run(strategy, seed)
		local firsts = {}
		local sim
		sim = MatchSim.new(Random.new(seed), function(kind, p)
			if kind == "Roll" and not firsts[p.rarity] then
				firsts[p.rarity] = sim.t
			end
		end, false)
		sim:setAuto(true)
		local stageAt, last, earned = {}, sim.gems, 0
		local nextMark = 1
		local reached, top = { [1] = 0 }, 1 -- sim time (s) at which each stage was first reached, for the clear time per stage
		local steps = 20 * 60 / DT
		for _ = 1, steps do
			sim:step(DT)
			if sim.gems > last then
				earned += sim.gems - last
			end
			act(sim, strategy)
			last = sim.gems
			if sim.stage > top then
				for st = top + 1, sim.stage do
					reached[st] = sim.t
				end
				top = sim.stage
			end
			if nextMark <= #MARKS and sim.t >= MARKS[nextMark] * 60 then
				stageAt[MARKS[nextMark]] = sim.stage
				nextMark += 1
			end
		end
		check(strategy .. " seed " .. seed .. " ran the full 20 minutes (stage " .. sim.stage .. ", t " .. math.floor(sim.t) .. ")", sim.stage >= 1 and sim.t >= 1190)
		return { stageAt = stageAt, gpm = earned / (sim.t / 60), firsts = firsts, units = sim:unitCount(), maxTier = sim.maxTier, reached = reached }
	end

	local ok, err = pcall(function()
		local rarities = Config.RARITY_ORDER
		line("Balance baseline (seeds " .. table.concat(SEEDS, ",") .. ", dt " .. DT .. ", 20 min per run, auto waves on)")
		for _, strategy in { "idle", "roll", "upgrade", "full" } do
			local stage, gpm, units, tier, firsts = {}, 0, 0, 0, {}
			local clear = {} -- stage -> { sum, n }: seconds from reaching the stage to reaching the next one
			for _, seed in SEEDS do
				local r = run(strategy, seed)
				if strategy == "full" then
					check("integration: the full bot clears all 25 stages on seed " .. seed, r.reached[26] ~= nil)
					line("    integration: seed " .. seed .. " full bot " .. (r.reached[26] and string.format("cleared all 25 stages at %.0f s", r.reached[26]) or "did NOT clear stage 25"))
				end
				for st = 1, 25 do
					if r.reached[st] and r.reached[st + 1] then
						clear[st] = clear[st] or { sum = 0, n = 0 }
						clear[st].sum += r.reached[st + 1] - r.reached[st]
						clear[st].n += 1
					end
				end
				for _, m in MARKS do
					stage[m] = (stage[m] or 0) + r.stageAt[m] / #SEEDS
				end
				gpm += r.gpm / #SEEDS
				units += r.units / #SEEDS
				tier = math.max(tier, r.maxTier)
				for _, rar in rarities do
					local t = r.firsts[rar]
					firsts[rar] = firsts[rar] or { sum = 0, n = 0 }
					if t then
						firsts[rar].sum += t
						firsts[rar].n += 1
					end
				end
			end
			local parts = {}
			for _, m in MARKS do
				table.insert(parts, m .. "m=" .. string.format("%.1f", stage[m]))
			end
			line(("[%s] stage by minute: %s | gems/min %.0f | units at 20m %.1f | max tier %d"):format(strategy, table.concat(parts, " "), gpm, units, tier))
			local fp = {}
			for _, rar in rarities do
				local f = firsts[rar]
				table.insert(fp, rar .. "=" .. (f.n > 0 and string.format("%.0fs(%d/%d)", f.sum / f.n, f.n, #SEEDS) or "never"))
			end
			line("    first pull (avg s): " .. table.concat(fp, " "))
			local cl = {}
			for st = 1, 25 do
				local c = clear[st]
				table.insert(cl, "s" .. st .. "=" .. (c and string.format("%.0f(%d/%d)", c.sum / c.n, c.n, #SEEDS) or "-"))
			end
			line("    clear time per stage (avg s, runs that cleared it): " .. table.concat(cl, " "))
		end

		line("DPS by rarity (mean of pets) at tier 1.." .. Config.TIER_MAX .. " (damage / cooldown, no upgrades or skills):")
		for _, rar in rarities do
			local pets = Config.petsOfRarity(rar)
			local cells = {}
			for tier = 1, Config.TIER_MAX do
				local sum = 0
				for _, pet in pets do
					sum += Config.petDamage(pet, tier) / Config.PETS[pet].cooldown
				end
				table.insert(cells, string.format("t%d=%.1f", tier, #pets > 0 and sum / #pets or 0))
			end
			line(("  %s (%d pets): %s"):format(rar, #pets, table.concat(cells, " ")))
		end

		line("Enemy HP by stage (sum of the stage's spawns after hpScale, and the largest single enemy):")
		local cells = {}
		for _, s in { 1, 2, 3, 5, 10, 15, 20, 25, 30, 40, 50 } do
			local total, big = 0, 0
			for _, kind in Config.stageSpawns(s) do
				local hp = Config.ENEMIES[kind].hp * Config.hpScale(s)
				total += hp
				big = math.max(big, hp)
			end
			table.insert(cells, ("s%d=%.0f/%.0f"):format(s, total, big))
		end
		line("  " .. table.concat(cells, " "))
	end)
	tmp:Destroy()
	if not ok then
		table.insert(problems, "error: " .. tostring(err))
	end
	local head = (#problems == 0) and "PASS balance baseline ran (numbers are a baseline, not assertions)" or "FAIL " .. table.concat(problems, "; ")
	return head .. "\n" .. table.concat(out, "\n")
end
