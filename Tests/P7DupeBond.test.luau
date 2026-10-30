--!nocheck
-- Headless checks for the P7 duplicate bond bonus (behind Config.P7_DUPE_BOND). Nothing in the game changes: it clones Config, Path, MatchSim, Gacha and Bond.
-- Run through RunAll (serve Tests/ with python -m http.server). Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_P7DupeBondTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim", "StageSets", "Gacha", "Bond" } do
		Shared[n]:Clone().Parent = tmp
	end
	local Config = require(tmp.Config)
	local MatchSim = require(tmp.MatchSim)
	local Bond = require(tmp.Bond)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local function newSim(seed, tutorial)
		local sim = MatchSim.new(Random.new(seed or 1), function() end, tutorial or false)
		sim.gems = 1e9
		return sim
	end

	local ok, err = pcall(function()
		-- pure steps
		check("0 extra copies give no bonus", Bond.dupePower(0) == 0 and Bond.dupeStep(0) == 0)
		check("steps at 1, 3, 6, 10, 15 extra copies give 3, 6, 9, 12, 15 percent", Bond.dupePower(1) == 0.03 and Bond.dupePower(2) == 0.03 and Bond.dupePower(3) == 0.06 and Bond.dupePower(6) == 0.09 and Bond.dupePower(10) == 0.12 and Bond.dupePower(15) == 0.15 and Bond.dupePower(500) == 0.15)
		check("dupeNext says how many extra copies the next step needs", Bond.dupeNext(0) == 1 and Bond.dupeNext(1) == 3 and Bond.dupeNext(15) == nil)
		check("only a copy past the last step is surplus", not Bond.dupeSurplus(14) and Bond.dupeSurplus(15))

		local pet = "Ember"
		local function withCopies(n, seed)
			local s = newSim(seed or 31)
			s:loadMeta({ collection = { [pet] = { count = n, shards = 0 } } })
			s.gems = 1e9
			s.upgrades[pet] = s.upgrades[pet] or { Power = 0, Haste = 0, Crit = 0 }
			return s
		end
		local unit = { pet = pet, tier = 1, cd = 0, x = 0, z = 0 }

		-- flag OFF: no change
		Config.P7_DUPE_BOND = false
		local a, fresh = withCopies(10), withCopies(1)
		check("flag off: ten copies do no extra damage", math.abs(a:effective(unit) - fresh:effective(unit)) < 1e-9 and a:dupePower(pet) == 0)
		check("flag off: the snapshot has no dupes table", a:snapshot().gacha.dupes == nil and a:snapshot().gacha.dupeOn == false)
		check("flag off: no surplus gems", withCopies(40):countCopy(pet) == 0)

		-- flag ON
		Config.P7_DUPE_BOND = true
		local one, eleven = withCopies(1), withCopies(11) -- 10 extra copies = +12%
		local d1, d11 = one:effective(unit), eleven:effective(unit)
		check("flag on: one copy gets no bonus", one:dupePower(pet) == 0)
		check("flag on: 10 extra copies raise damage by exactly 12 percent", math.abs(d11 / d1 - 1.12) < 1e-9, d11 / d1)
		local s11 = eleven:snapshot().gacha
		check("flag on: the snapshot lists copies, step, power and next step", s11.dupeOn and s11.dupes[pet].copies == 11 and s11.dupes[pet].step == 4 and s11.dupes[pet].power == 0.12 and s11.dupes[pet].nextAt == 15)

		local c = withCopies(1)
		c:countCopy(pet)
		check("a pulled copy counts at once (2 copies = +3 percent)", c.owned[pet] == 2 and c:dupePower(pet) == 0.03)
		local sur = withCopies(16)
		local gems0 = sur.gems
		local paid = sur:countCopy(pet)
		check("a copy past the last step pays 10 gems", paid == Bond.DUPE_SURPLUS_GEMS and sur.gems == gems0 + 10, paid)
		check("a copy that still fills a step pays nothing", withCopies(15):countCopy(pet) == 0)

		-- real rolls count as owned copies; the tutorial does not
		local r = newSim(32)
		r:loadMeta({ collection = {} })
		for _ = 1, 300 do
			r.grid = {}
			r:roll()
		end
		local total = 0
		for _, n in r.owned do
			total += n
		end
		check("300 rolls were all counted as owned copies", total >= 300, total)
		local tut = newSim(33, true)
		tut.grid = {}
		tut:roll()
		check("tutorial rolls are not counted", next(tut.owned) == nil)

		-- damaged collection data cannot break loadMeta
		local junk = newSim(34)
		junk:loadMeta({ collection = { Ember = { count = 0 / 0 }, Nope = { count = 5 }, [7] = {}, Zap = "x" } })
		check("junk collection entries are ignored", junk.owned.Ember == nil and junk.owned.Nope == nil)
	end)
	Config.P7_DUPE_BOND = false
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " P7DupeBond: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
