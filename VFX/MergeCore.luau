--!nocheck
-- MergeCore: the rules of the 2048-style character merge, as pure logic (no UI, no Roblox objects), so it can be tested and
-- simulated headless. Source: VFX/MergeCore.luau, installed as ReplicatedStorage.MergeCore. Design: Roblox Dev/Planning/Game Redesign - Merge Academy.md
--
--   local C = require(...MergeCore)
--   local g = C.new(C.defaults, 12345)      -- cells = cols*rows, each 0 (empty) or a tier 1..maxTier
--   C.summon(g)                             -- spend a charge, put a new character on a random empty cell
--   C.merge(g, a, b)                        -- drag cell a onto cell b: equal tiers -> b becomes tier+1, a empties
--   C.autoMerge(g)                          -- the "Merge!" assist: merges the best available pair
--   C.test() / C.simulate(...)              -- invariants and difficulty measurements
-- Light difficulty is built in: nothing can be lost, a full board never ends the run (the oldest tier-1 is banked into stardust),
-- merges sometimes refund a tile ("echo") or jump two tiers ("surge"), and the spawn tier creeps up with rank, so reaching the next
-- tier takes roughly the same time instead of doubling like classic 2048. The server must own the real state in the game
-- (CLAUDE.md: the server decides currency, rewards and inventory); this module is the shared rule set both sides can run.

local C = {}

C.defaults = {
	cols = 5, rows = 4, maxTier = 8,
	charges = 5, regen = 2.5, -- summon charges: stored up to `charges`, one back every `regen` seconds
	spawn = { 0.85, 0.15 }, -- base chance of spawning the base tier, one tier higher (rank raises the higher chance)
	rankSpawnStep = 0.03, -- each rank adds this much chance of a higher spawn
	catchUp = 4, -- spawns start at (best tier reached - catchUp), so late tiers do not take twice as long as the one before
	autoEvery = 8, -- seconds between the Hearth's free automatic merges (0 = off); the low-attention safety net
	echo = 0.35, -- merging tier >= 2 can refund a tier-1 tile
	surge = 0.08, -- merging can jump two tiers instead of one
	stardust = function(tier) return tier * 3 end,
}

-- small deterministic generator (xorshift) so tests and simulations repeat
local function rng(seed)
	local s = (seed or 1) % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function()
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
end

function C.new(cfg, seed)
	local g = {
		cfg = cfg or C.defaults,
		cells = {},
		rand = rng(seed),
		charges = (cfg or C.defaults).charges,
		rank = 0,
		stardust = 0,
		banked = 0,
		ascended = 0,
		best = 0,
		merges = 0,
		echoes = 0,
		surges = 0,
		reached = {}, -- first time (merge count) each tier appeared
	}
	for i = 1, g.cfg.cols * g.cfg.rows do
		g.cells[i] = 0
	end
	return g
end

local function emptyCells(g)
	local list = {}
	for i, v in ipairs(g.cells) do
		if v == 0 then
			table.insert(list, i)
		end
	end
	return list
end

function C.isFull(g)
	for _, v in ipairs(g.cells) do
		if v == 0 then
			return false
		end
	end
	return true
end

function C.count(g)
	local n = 0
	for _, v in ipairs(g.cells) do
		if v > 0 then
			n += 1
		end
	end
	return n
end

-- the tier a summon produces: the base tier catches up with the best tier reached (best - catchUp, at least 1), with a chance
-- of one tier higher (rises with rank) and a small chance of two higher once tier 5 has been reached
function C.spawnTier(g)
	local c = g.cfg
	local base = math.max(1, g.best - c.catchUp)
	local pUp = math.min(0.5, c.spawn[2] + c.rankSpawnStep * g.rank)
	local pUp2 = g.best >= 5 and 0.06 or 0
	local r = g.rand()
	local t = base
	if r < pUp2 then
		t = base + 2
	elseif r < pUp2 + pUp then
		t = base + 1
	end
	return math.min(t, c.maxTier - 1)
end

local function note(g, tier)
	if tier > g.best then
		g.best = tier
	end
	if not g.reached[tier] then
		g.reached[tier] = g.merges
	end
end

-- returns the cell index, or nil if there was no charge. A full board never fails: the oldest tier-1 is banked first.
function C.summon(g)
	if g.charges < 1 then
		return nil, "no charge"
	end
	local empties = emptyCells(g)
	if #empties == 0 then
		if not C.bank(g) then
			return nil, "full"
		end
		empties = emptyCells(g)
	end
	g.charges -= 1
	local cell = empties[math.floor(g.rand() * #empties) + 1]
	local t = C.spawnTier(g)
	g.cells[cell] = t
	note(g, t)
	return cell, t
end

-- the "Hearth" turns the lowest tile into stardust so a full board is never a dead end
function C.bank(g)
	local low, li = 99, nil
	for i, v in ipairs(g.cells) do
		if v > 0 and v < low then
			low, li = v, i
		end
	end
	if not li then
		return false
	end
	g.cells[li] = 0
	g.banked += 1
	g.stardust += g.cfg.stardust(low)
	return true
end

-- merge cell a into cell b. Returns { tier = new tier, echo = bool, surge = bool, ascend = bool } or nil, reason.
function C.merge(g, a, b)
	if a == b then
		return nil, "same cell"
	end
	local ta, tb = g.cells[a], g.cells[b]
	if ta == 0 or tb == 0 or ta ~= tb then
		return nil, "not a pair"
	end
	local c = g.cfg
	g.cells[a] = 0
	g.merges += 1
	if ta >= c.maxTier then -- two top characters ascend together: both leave, big reward, never a dead end
		g.cells[b] = 0
		g.ascended += 1
		g.rank += 1
		g.stardust += c.stardust(ta + 2)
		return { tier = ta + 1, ascend = true }
	end
	local surge = g.rand() < c.surge and ta + 2 <= c.maxTier
	local newTier = surge and ta + 2 or ta + 1
	g.cells[b] = newTier
	g.stardust += c.stardust(newTier)
	if surge then
		g.surges += 1
	end
	note(g, newTier)
	local echo = false
	if ta >= 2 and g.rand() < c.echo then
		local empties = emptyCells(g)
		if #empties > 0 then
			g.cells[empties[math.floor(g.rand() * #empties) + 1]] = 1
			g.echoes += 1
			echo = true
		end
	end
	return { tier = newTier, echo = echo, surge = surge }
end

-- the sound cues a merge result should play, in order (names exist in SoundCatalog; tested). The UI controller calls these.
C.cueNames = { "summon", "surge", "echo", "bank", "charge_ready", "merge_fail", "wish_pull", "merge_1", "merge_2", "merge_3", "merge_4", "merge_5", "merge_6", "merge_7", "merge_8" }
function C.cuesFor(result)
	local cues = {}
	if not result then
		return { "merge_fail" }
	end
	if result.ascend then
		return { "merge_8" }
	end
	table.insert(cues, "merge_" .. math.min(result.tier - 1, 8)) -- the merge cue is for the tier the pair WAS (a tier 1+1 pair plays merge_1)
	if result.surge then
		table.insert(cues, "surge")
	end
	if result.echo then
		table.insert(cues, "echo")
	end
	return cues
end

-- every equal pair as {a, b, tier}
function C.pairs(g)
	local byTier = {}
	for i, v in ipairs(g.cells) do
		if v > 0 then
			byTier[v] = byTier[v] or {}
			table.insert(byTier[v], i)
		end
	end
	local out = {}
	for t, list in pairs(byTier) do
		for i = 1, #list - 1, 2 do
			table.insert(out, { list[i], list[i + 1], t })
		end
	end
	table.sort(out, function(x, y)
		return x[3] < y[3]
	end)
	return out
end

-- the assist button: merges the lowest equal pair (frees the most room). Returns the merge result or nil.
function C.autoMerge(g)
	local p = C.pairs(g)[1]
	if not p then
		return nil, "no pair"
	end
	local r = C.merge(g, p[1], p[2])
	if r then
		r.a, r.b = p[1], p[2]
	end
	return r
end

function C.tick(g, dt)
	g._acc = (g._acc or 0) + dt
	while g._acc >= g.cfg.regen do
		g._acc -= g.cfg.regen
		if g.charges < g.cfg.charges then
			g.charges += 1
		end
	end
	local every = g.cfg.autoEvery
	if every and every > 0 then
		g._auto = (g._auto or 0) + dt
		if g._auto >= every then
			g._auto = 0
			if C.autoMerge(g) then
				g.autoMerges = (g.autoMerges or 0) + 1
			end
		end
	end
end

-- value of the board in tier-1 units; a merge keeps it unless echo/surge add some
function C.value(g)
	local v = 0
	for _, t in ipairs(g.cells) do
		if t > 0 then
			v += 2 ^ (t - 1)
		end
	end
	return v
end

---------------------------------------------------------------------------------------------------
-- tests: rules and invariants. Returns (report, failures)
---------------------------------------------------------------------------------------------------
function C.test()
	local lines, fails = {}, 0
	local function check(ok, msg)
		if not ok then
			fails += 1
			table.insert(lines, "FAIL " .. msg)
		end
	end
	local plain = {}
	for k, v in pairs(C.defaults) do
		plain[k] = v
	end
	plain.echo, plain.surge = 0, 0
	-- merge rules
	local g = C.new(plain, 1)
	g.cells[1], g.cells[2], g.cells[3] = 1, 1, 2
	check(C.merge(g, 1, 1) == nil, "merged a cell with itself")
	check(C.merge(g, 1, 3) == nil, "merged unequal tiers")
	check(C.merge(g, 1, 4) == nil, "merged with an empty cell")
	local before = C.value(g)
	local r = C.merge(g, 1, 2)
	check(r and r.tier == 2 and g.cells[1] == 0 and g.cells[2] == 2, "basic merge failed")
	check(C.value(g) == before, "merge without echo/surge must conserve value")
	-- conservation over a long random game with echo and surge off: a merge never changes the board's value
	g = C.new(plain, 42)
	local merged = 0
	for _ = 1, 600 do
		g.charges = 1
		C.summon(g)
		local v1 = C.value(g)
		local had = #C.pairs(g) > 0
		local res = C.autoMerge(g)
		if had then
			merged += 1
			check(res ~= nil, "autoMerge found no merge although a pair existed")
			if res and not res.ascend then
				check(C.value(g) == v1, "merge changed the board value")
			end
		end
	end
	check(merged > 50, "too few merges happened in the conservation test (" .. merged .. ")")
	-- no negative or out-of-range cells
	for _, v in ipairs(g.cells) do
		check(v >= 0 and v <= plain.maxTier, "cell out of range: " .. tostring(v))
	end
	-- full board never dead-ends
	g = C.new(C.defaults, 7)
	for i = 1, #g.cells do
		g.cells[i] = (i % 7) + 1 -- no equal pairs next to each other is not required: only fullness matters
	end
	g.charges = 3
	local ok = C.summon(g)
	check(ok ~= nil, "summon on a full board failed instead of banking")
	check(g.banked == 1, "full board did not bank a tile")
	-- no charge, no summon
	g.charges = 0
	check(C.summon(g) == nil, "summon without a charge succeeded")
	-- top tier ascends and removes both
	g = C.new(C.defaults, 3)
	g.cells[1], g.cells[2] = C.defaults.maxTier, C.defaults.maxTier
	r = C.merge(g, 1, 2)
	check(r and r.ascend and g.cells[1] == 0 and g.cells[2] == 0 and g.rank == 1, "top-tier pair did not ascend")
	-- determinism
	local function run(seed)
		local s = C.new(C.defaults, seed)
		for _ = 1, 40 do
			C.summon(s)
			s.charges = 5
			C.autoMerge(s)
		end
		return table.concat(s.cells, ",") .. "|" .. s.stardust
	end
	check(run(5) == run(5), "same seed gave different games")
	check(run(5) ~= run(6), "different seeds gave identical games")
	-- surge and echo stay inside the board and the tier range
	g = C.new(C.defaults, 99)
	local known = {}
	for _, n in ipairs(C.cueNames) do
		known[n] = true
	end
	local seenCues = {}
	for _ = 1, 400 do
		g.charges = 5
		C.summon(g)
		local res = C.autoMerge(g)
		for _, cue in ipairs(C.cuesFor(res)) do
			seenCues[cue] = true
			check(known[cue], "cuesFor produced an unknown cue " .. cue)
		end
		for _, v in ipairs(g.cells) do
			if v < 0 or v > C.defaults.maxTier then
				check(false, "echo/surge produced an invalid tier " .. v)
				break
			end
		end
	end
	check(C.cuesFor(nil)[1] == "merge_fail", "a failed merge must play merge_fail")
	check(C.cuesFor({ tier = 2 })[1] == "merge_1" and C.cuesFor({ tier = 8 })[1] == "merge_7" and C.cuesFor({ ascend = true })[1] == "merge_8", "merge cue ladder mapping is wrong")
	table.insert(lines, fails == 0 and "MERGECORE TESTS PASS (rules, conservation, no dead end, ascend, determinism, ranges)" or ("MERGECORE TEST FAILURES: " .. fails))
	return table.concat(lines, "\n"), fails
end

---------------------------------------------------------------------------------------------------
-- difficulty simulation: bots with different attention levels play for a number of simulated seconds
---------------------------------------------------------------------------------------------------
-- bot: { act = seconds between actions, attention = chance to use "Merge!" when a pair exists, mergeFirst = prefers merging }
C.bots = {
	focused = { act = 1.2, attention = 0.95 },
	casual = { act = 1.8, attention = 0.6 },
	distracted = { act = 3.5, attention = 0.3 }, -- low attention span: acts rarely, often forgets to merge
}

function C.simulate(botName, seconds, runs, cfg)
	local bot = C.bots[botName]
	local times = {} -- per tier, list of times reached
	local fullEvents, bankedTotal, merges = 0, 0, 0
	for run = 1, runs do
		local g = C.new(cfg or C.defaults, run * 7919)
		local t, nextAct = 0, 0
		local rr = rng(run * 31 + 5)
		local reached = {}
		local wasFull = false
		while t < seconds do
			C.tick(g, 0.25)
			t += 0.25
			if t >= nextAct then
				nextAct = t + bot.act * (0.6 + rr() * 0.8)
				local pairsNow = C.pairs(g)
				if #pairsNow > 0 and rr() < bot.attention then
					C.autoMerge(g)
				elseif g.charges >= 1 then
					local b0 = g.banked
					C.summon(g)
					if g.banked > b0 then
						fullEvents += 1
					end
				end
				for tier = 1, g.cfg.maxTier do
					if g.best >= tier and not reached[tier] then
						reached[tier] = t
						times[tier] = times[tier] or {}
						table.insert(times[tier], t)
					end
				end
			end
		end
		bankedTotal += g.banked
		merges += g.merges
	end
	local out = { fullPerRun = fullEvents / runs, mergesPerRun = merges / runs, tiers = {} }
	for tier = 1, (cfg or C.defaults).maxTier do
		local list = times[tier]
		if list then
			table.sort(list)
			out.tiers[tier] = { median = list[math.ceil(#list / 2)], share = #list / runs }
		else
			out.tiers[tier] = { median = nil, share = 0 }
		end
	end
	return out
end

return C
