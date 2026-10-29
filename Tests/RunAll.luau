--!nocheck
-- One test runner (T126). Runs every Tests/*.test.luau served from the local Tests folder and returns one summary line per
-- suite plus a total. Run in Studio (Edit mode) with execute_luau, after serving Tests/ on a local port:
--   local body = game:GetService("HttpService"):GetAsync("http://127.0.0.1:8796/RunAll.luau")
--   return loadstring(body)()("http://127.0.0.1:8796", game.ReplicatedStorage.Shared)
-- Each suite gets a fresh copy of the Shared folder, so modules are not reused from an earlier run (Edit-mode caching).

return function(base, Shared)
	local HS = game:GetService("HttpService")
	local listing = HS:GetAsync(base .. "/")
	local names, seen = {}, {}
	for name in string.gmatch(listing, 'href="([^"/]+%.test%.luau)"') do
		if not seen[name] then
			seen[name] = true
			table.insert(names, name)
		end
	end
	table.sort(names)

	local lines, passed = {}, 0
	for _, name in names do
		local status
		local okFetch, body = pcall(function()
			return HS:GetAsync(base .. "/" .. name)
		end)
		if not okFetch then
			status = "FETCH-FAIL " .. tostring(body)
		else
			local fresh = Shared:Clone()
			fresh.Parent = nil
			local okRun, rep = pcall(function()
				return loadstring(body)()(fresh)
			end)
			fresh:Destroy()
			if not okRun then
				status = "ERROR " .. tostring(rep)
			else
				status = string.match(tostring(rep), "^[^\n]*") or "?"
			end
		end
		if string.match(status, "^PASS") then
			passed += 1
		end
		table.insert(lines, string.format("%-34s %s", name, status))
	end
	table.insert(lines, string.format("SUMMARY %d of %d suites PASS", passed, #names))
	return table.concat(lines, "\n")
end
