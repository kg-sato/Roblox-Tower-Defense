--!nocheck
-- Coverage checks for Shared.Strings (T087): every familiar, enemy, item (upgrade), status and skill id in Config has a
-- name and blurb; familiar names match Config; no stray keys. Run via Tests/RunAll or:
--   return loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:8796/Strings.test.luau"))()(game.ReplicatedStorage.Shared)

return function(Shared)
	local S = require(Shared.Strings)
	local Config = require(Shared.Config)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local function covered(kind, ids)
		local missing, bad = {}, {}
		for _, id in ids do
			local e = S[kind][id]
			if not e then
				table.insert(missing, id)
			elseif type(e.name) ~= "string" or e.name == "" or type(e.blurb) ~= "string" or e.blurb == "" then
				table.insert(bad, id)
			end
		end
		check(kind .. ": every id has a name and blurb (" .. #ids .. ")", #missing == 0 and #bad == 0, table.concat(missing, ",") .. "|" .. table.concat(bad, ","))
	end
	local function noExtras(kind, set)
		local extra = {}
		for id in S[kind] do
			if not set[id] then
				table.insert(extra, id)
			end
		end
		check(kind .. ": no keys without a Config id", #extra == 0, table.concat(extra, ","))
	end
	local function idsOf(t)
		local ids, set = {}, {}
		for k in t do
			table.insert(ids, k)
			set[k] = true
		end
		return ids, set
	end

	local ids, set = idsOf(Config.PETS)
	covered("familiars", ids)
	noExtras("familiars", set)
	local nameOk = true
	for id, p in Config.PETS do
		if S.familiars[id] and S.familiars[id].name ~= p.name then
			nameOk = false
		end
	end
	check("familiar names match Config.PETS[id].name", nameOk)
	ids, set = idsOf(Config.ENEMIES)
	covered("enemies", ids)
	noExtras("enemies", set)
	ids, set = idsOf(Config.UPGRADES)
	covered("items", ids)
	noExtras("items", set)
	ids, set = idsOf(Config.STATUS)
	covered("statuses", ids)
	noExtras("statuses", set)
	local treeIds, treeSet = {}, {}
	for _, n in Config.TREE do
		if not treeSet[n.id] then
			treeSet[n.id] = true
			table.insert(treeIds, n.id)
		end
	end
	covered("skills", treeIds)
	noExtras("skills", treeSet)

	check("get returns the entry", S.get("enemies", "Grunt").name == "Grunt")
	check("get falls back to the id for unknown ids", S.get("enemies", "Nope").name == "Nope" and S.get("nokind", "x").name == "x")
	check("name shortcut", S.name("familiars", "Zap") == "Moth-Lantern")

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
