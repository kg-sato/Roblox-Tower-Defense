--!nocheck
-- Headless checks for ReplicatedStorage.Shared.Familiars and its wiring into Shared.Config (T101). Run in Studio (Edit mode) with execute_luau.
-- loadstring is not available there, so put this file's text in a temporary ModuleScript, require it and call the result with the Shared folder:
--   return require(tempModule)(game.ReplicatedStorage.Shared)
-- Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local F = require(Shared.Familiars)
	local Config = require(Shared.Config)
	local results, failed = {}, 0
	local function check(name, got, want)
		local ok = got == want
		if not ok then
			failed += 1
		end
		table.insert(results, (ok and "ok   " or "FAIL ") .. name .. " -> " .. tostring(got) .. (ok and "" or " (want " .. tostring(want) .. ")"))
	end

	check("20 familiars", #F.list, 20)
	check("order has 20 ids", #F.order, 20)

	local rarity, names, ids, roles, lores, empty, badRarity = {}, {}, {}, {}, {}, 0, 0
	local dupName, dupId, dupRole, dupLore = 0, 0, 0, 0
	local voiceBad, tierBad, colourBad = 0, 0, 0
	for _, f in F.list do
		rarity[f.rarity] = (rarity[f.rarity] or 0) + 1
		if not Config.RARITIES[f.rarity] then
			badRarity += 1
		end
		if names[f.name] then dupName += 1 end
		if ids[f.id] then dupId += 1 end
		if roles[f.role] then dupRole += 1 end
		if lores[f.loreId] then dupLore += 1 end
		names[f.name], ids[f.id], roles[f.role], lores[f.loreId] = true, true, true, true
		for _, k in { "id", "name", "epithet", "rarity", "role", "roleText", "faction", "element", "home", "loreId", "tier2", "tier3" } do
			if type(f[k]) ~= "string" or #f[k] < 2 then
				empty += 1
			end
		end
		if typeof(f.color) ~= "Color3" then
			colourBad += 1
		end
		if #f.voice.tone ~= 3 or #f.voice.summon < 2 or #f.voice.attack < 2 or #f.voice.victory < 2 then
			voiceBad += 1
		end
		if f.tier2 == f.tier3 then
			tierBad += 1
		end
		if f.charId ~= nil and type(f.charId) ~= "string" then
			empty += 1
		end
	end
	check("rarity Common 4", rarity.Common, 4)
	check("rarity Rare 4", rarity.Rare, 4)
	check("rarity Epic 4", rarity.Epic, 4)
	check("rarity Legendary 4", rarity.Legendary, 4)
	check("rarity Mythic 2", rarity.Mythic, 2)
	check("rarity Celestial 2", rarity.Celestial, 2)
	check("every rarity exists in Config.RARITIES", badRarity, 0)
	check("names unique", dupName, 0)
	check("ids unique", dupId, 0)
	check("role verbs unique", dupRole, 0)
	check("lore ids unique", dupLore, 0)
	check("no empty text field", empty, 0)
	check("every colour is a Color3", colourBad, 0)
	check("3 tone words and 3 voice lines each", voiceBad, 0)
	check("tier 2 and tier 3 features differ", tierBad, 0)

	local factions = {}
	for _, f in F.list do
		factions[f.faction] = true
	end
	for _, want in { "Lantern Keepers", "Clockwork Guild", "Hollow Court", "Star Choir", "Unaligned" } do
		check("faction present: " .. want, factions[want], true)
	end

	-- wiring into Config
	check("Config.FAMILIARS has 20", (function()
		local n = 0
		for _ in Config.FAMILIARS do
			n += 1
		end
		return n
	end)(), 20)
	check("Config.FAMILIAR_ORDER has 20", #Config.FAMILIAR_ORDER, 20)
	local mapped, mappedBad, unmappedInPets = 0, 0, 0
	for _, f in F.list do
		local def = f.charId and Config.PETS[f.charId]
		if def then
			mapped += 1
			if def.name ~= f.name or def.role ~= f.role or def.faction ~= f.faction or def.loreId ~= f.loreId or def.familiar ~= f.id or def.rarity ~= f.rarity then
				mappedBad += 1
			end
		else
			unmappedInPets += 1
		end
	end
	check("all 20 familiars map onto a character folder", mapped, 20)
	check("mapped pets carry name, role, faction, loreId and the same rarity", mappedBad, 0)
	check("no familiar is missing from Config.PETS", unmappedInPets, 0)
	check("forChar finds Zap as Moth-Lantern", F.forChar("Zap") and F.forChar("Zap").id, "MothLantern")
	check("forChar returns nil for retired Sprout", F.forChar("Sprout"), nil)
	check("retired Sprout is gone from Config.PETS", Config.PETS.Sprout, nil)
	check("roster is the 20 familiars", #Config.PET_ORDER, 20)
	local perRarity = { Common = 0, Rare = 0, Epic = 0, Legendary = 0, Mythic = 0, Celestial = 0 }
	for _, id in Config.PET_ORDER do
		perRarity[Config.PETS[id].rarity] += 1
	end
	check("roster rarity spread 4/4/4/4/2/2", perRarity.Common .. "/" .. perRarity.Rare .. "/" .. perRarity.Epic .. "/" .. perRarity.Legendary .. "/" .. perRarity.Mythic .. "/" .. perRarity.Celestial, "4/4/4/4/2/2")

	return (failed == 0 and "PASS" or "FAIL") .. " Familiars: " .. (#results - failed) .. "/" .. #results .. " checks ok\n" .. table.concat(results, "\n")
end
