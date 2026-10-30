--!nocheck
-- Headless checks for the P2 chosen guarantee (Lantern Oil, behind Config.P2_CHOSEN_GUARANTEE). Nothing in the game changes: it clones Config, Path, MatchSim, Gacha and Bond.
-- Run through RunAll (serve Tests/ with python -m http.server). Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local tmp = Instance.new("Folder")
	tmp.Name = "_P2GuaranteeTest"
	tmp.Parent = game:GetService("ReplicatedStorage")
	for _, n in { "Config", "Path", "MatchSim", "StageSets", "Gacha", "Bond" } do
		Shared[n]:Clone().Parent = tmp
	end
	local Config = require(tmp.Config)
	local MatchSim = require(tmp.MatchSim)
	local Gacha = require(tmp.Gacha)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local events
	local function newSim(seed, tutorial)
		events = {}
		local sim = MatchSim.new(Random.new(seed or 1), function(kind, p)
			table.insert(events, { kind = kind, p = p })
		end, tutorial or false)
		sim.gems = 1e9
		return sim
	end
	local function rollOnce(sim)
		sim.grid = {}
		events = {}
		local ok, why = sim:roll()
		assert(ok, why)
	end
	local function order(r)
		return Config.RARITIES[r].order
	end

	local ok, err = pcall(function()
		local rarePet, commonPet
		for id, def in Config.PETS do
			if order(def.rarity) >= 2 and not rarePet then
				rarePet = id
			end
			if order(def.rarity) == 1 and not commonPet then
				commonPet = id
			end
		end
		check("the roster has a Common and a Rare-or-better familiar", rarePet ~= nil and commonPet ~= nil)

		Config.P2_CHOSEN_GUARANTEE = true
		local sim = newSim(21)
		for _ = 1, 30 do
			rollOnce(sim)
		end
		check("each roll earns 1 Lantern Oil", sim.gacha.oil == 30, sim.gacha.oil)
		local okc, why = sim:claimGuarantee(rarePet)
		check("below 100 oil the claim is refused and nothing is spent", not okc and why == "Not enough Lantern Oil" and sim.gacha.oil == 30, why)

		sim.gacha.oil = 130
		sim.grid = {}
		events = {}
		okc, why = sim:claimGuarantee(commonPet)
		check("a Common cannot be chosen", not okc and sim.gacha.oil == 130, why)
		okc, why = sim:claimGuarantee("NoSuchPet")
		check("an unknown id is refused", not okc and sim.gacha.oil == 130, why)
		okc, why = sim:claimGuarantee(42)
		check("a non-string is refused", not okc and sim.gacha.oil == 130, why)
		okc, why = sim:claimGuarantee(rarePet)
		check("100 oil buys the chosen Rare-or-better familiar", okc, why)
		check("exactly 100 oil is spent, the rest stays", sim.gacha.oil == 30 and sim.gacha.claims == 1, sim.gacha.oil)
		local placed
		for _, u in sim.grid do
			if u.pet == rarePet then
				placed = u
			end
		end
		check("the familiar stands on the board at tier 1", placed ~= nil and placed.tier == 1)
		local ev
		for _, e in events do
			if e.kind == "Roll" then
				ev = e.p
			end
		end
		check("a Roll event goes out marked chosen and bonus (no shared banner, no roll counter)", ev ~= nil and ev.chosen == true and ev.bonus == true and ev.pet == rarePet)

		-- a full board refuses and keeps the oil
		sim.gacha.oil = 100
		sim.grid = {}
		for _ = 1, Config.MAX_UNITS do
			local x, z = sim:findSpot(rarePet)
			sim:addUnit(rarePet, x, z)
		end
		okc, why = sim:claimGuarantee(rarePet)
		check("a full board refuses the claim and keeps the oil", not okc and sim.gacha.oil == 100, why)

		-- saved, never expires, and a new run does not reset it
		local m = sim:meta()
		local sim2 = newSim(22)
		sim2:loadMeta(m)
		check("oil survives meta/loadMeta", sim2.gacha.oil == 100 and sim2.gacha.claims == 1)
		local s = sim2:snapshot().gacha
		check("snapshot shows oil, need and ready", s.oilOn and s.oil == 100 and s.oilNeed == 100 and s.oilReady == true)

		-- flag off: no earning, no claiming
		Config.P2_CHOSEN_GUARANTEE = false
		local off = newSim(23)
		rollOnce(off)
		off.gacha.oil = 500
		okc, why = off:claimGuarantee(rarePet)
		check("flag off: the claim is refused", not okc and off.gacha.oil == 500, why)
		local earn = newSim(24)
		for _ = 1, 5 do
			rollOnce(earn)
		end
		check("flag off: rolls earn no oil", earn.gacha.oil == 0)
		check("flag off: snapshot says off and not ready", off:snapshot().gacha.oilOn == false and off:snapshot().gacha.oilReady == false)

		-- tutorial never claims
		Config.P2_CHOSEN_GUARANTEE = true
		local tut = newSim(25, true)
		tut.gacha.oil = 500
		check("tutorial: no claim", not tut:claimGuarantee(rarePet))

		-- clamp on load
		check("oil is clamped on load", Gacha.load({ oil = 9e12 }).oil == Gacha.OIL_MAX)

		-- a claim leaves the Epic pity counter and the rolls count alone
		local s5 = newSim(26)
		s5.gacha.oil = 100
		local pityBefore, rollsBefore = s5.sincePity, s5.rolls
		s5:claimGuarantee(rarePet)
		check("a claim leaves the Epic pity counter and the roll count alone", s5.sincePity == pityBefore and s5.rolls == rollsBefore)
	end)
	Config.P2_CHOSEN_GUARANTEE = false
	if not ok then
		failed += 1
		table.insert(results, "FAIL error: " .. tostring(err))
	end
	tmp:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " P2Guarantee: " .. (#results - failed) .. " of " .. #results .. " checks\n" .. table.concat(results, "\n")
end
