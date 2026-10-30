--!nocheck
-- Headless checks for the Summon menu (SummonScreen, behind Config.SUMMON_MENU). The screen itself is client UI; this covers the rules it relies on:
-- the flag is off by default, the rates it shows (normalised Config.rarityWeights) add up to 100, and a x10 is ten server rolls, each paid,
-- with a roll the player cannot afford refused and nothing spent. Clones Config, Path, MatchSim, Gacha and Bond, so nothing in the game changes.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_SummonMenuTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim", "StageSets", "Gacha", "Bond" } do
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
	-- same formula as SummonScreen.odds
	local function odds(luck)
		local w, total = Config.rarityWeights(luck), 0
		for _, v in w do
			total += v
		end
		local out = {}
		for _, r in Config.RARITY_ORDER do
			out[r] = (w[r] or 0) / total * 100
		end
		return out
	end
	local ok, err = pcall(function()
		check("SUMMON_MENU defaults off", Config.SUMMON_MENU == false)
		for _, luck in { 0, 0.25, 0.8 } do
			local sum = 0
			for _, v in odds(luck) do
				sum += v
			end
			check("rates add up to 100 at luck " .. luck, math.abs(sum - 100) < 1e-6, sum)
		end
		local o0, o8 = odds(0), odds(0.8)
		check("luck raises the Legendary rate", o8.Legendary > o0.Legendary, string.format("%.2f -> %.2f", o0.Legendary, o8.Legendary))
		check("Common is the most likely at luck 0", o0.Common > o0.Rare)

		local sim = MatchSim.new(Random.new(7), function() end, false)
		local cost = sim:rollCost()
		sim.gems = cost * 10
		local paid = 0
		for _ = 1, 10 do
			sim.grid = {} -- the unit cap is not under test
			local before = sim.gems
			local okRoll, why = sim:roll()
			check("x10 roll accepted", okRoll, why)
			paid += before - sim.gems
		end
		check("x10 spends exactly ten roll costs", paid == cost * 10, paid .. " of " .. cost * 10)
		local before = sim.gems
		local okRoll = sim:roll()
		check("an eleventh roll with no gems is refused", not okRoll)
		check("a refused roll spends nothing", sim.gems == before, sim.gems)
	end)
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " SummonMenu: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
