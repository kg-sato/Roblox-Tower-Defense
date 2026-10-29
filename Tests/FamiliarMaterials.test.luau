--!nocheck
-- Headless checks for ReplicatedStorage.Shared.FamiliarMaterials (T105). Run in Studio (Edit mode) with execute_luau through a temporary ModuleScript:
--   return require(tempModule)(game.ReplicatedStorage.Shared)
-- Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local M = require(Shared.FamiliarMaterials)
	local results, failed = {}, 0
	local function check(name, got, want)
		local ok = got == want
		if not ok then
			failed += 1
		end
		table.insert(results, (ok and "ok   " or "FAIL ") .. name .. " -> " .. tostring(got) .. (ok and "" or " (want " .. tostring(want) .. ")"))
	end

	local want = { "brass", "bone", "glass", "stone", "ember", "frost", "ink", "starDust" }
	check("8 recipes in order", #M.order, 8)
	for i, n in want do
		check("order " .. i .. " is " .. n, M.order[i], n)
		check("recipe exists: " .. n, M.recipes[n] ~= nil, true)
	end

	-- every recipe applies to a part and leaves exactly what it declares
	local folder = Instance.new("Folder")
	local pairsSeen, dup, lumas = {}, 0, {}
	local function luma(c)
		return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
	end
	for _, n in want do
		local p = Instance.new("Part")
		p.Parent = folder
		local ex = M.apply(p, n)
		local r = M.recipes[n]
		check(n .. ": material applied", p.Material, r.material)
		check(n .. ": colour applied", p.Color, r.color)
		check(n .. ": reflectance and transparency applied (float32 tolerance)", math.abs(p.Reflectance - r.reflectance) < 1e-4 and math.abs(p.Transparency - r.transparency) < 1e-4, true)
		check(n .. ": light only if declared", (ex.light ~= nil) == (r.light ~= nil), true)
		check(n .. ": emitter only if declared", (ex.emitter ~= nil) == (r.emitter ~= nil), true)
		local key = tostring(r.material) .. tostring(r.color)
		if pairsSeen[key] then
			dup += 1
		end
		pairsSeen[key] = true
		table.insert(lumas, luma(r.color))
		M.apply(p, n) -- a second apply replaces the extras, never stacks them
		local lights, emitters = 0, 0
		for _, c in p:GetChildren() do
			if c.Name == "FM_Light" then lights += 1 end
			if c.Name == "FM_Emitter" then emitters += 1 end
		end
		check(n .. ": second apply does not stack extras", lights + emitters, (r.light and 1 or 0) + (r.emitter and 1 or 0))
	end
	check("no two recipes share material and colour", dup, 0)
	table.sort(lumas)
	check("lightest colour is above 0.7 luminance (bone)", lumas[#lumas] > 0.7, true)
	check("darkest colour is below 0.05 luminance (ink)", lumas[1] < 0.05, true)

	-- unknown recipe errors
	local okCall = pcall(function()
		M.apply(Instance.new("Part"), "nope")
	end)
	check("unknown recipe raises an error", okCall, false)

	folder:Destroy()
	return (failed == 0 and "PASS" or "FAIL") .. " FamiliarMaterials: " .. (#results - failed) .. "/" .. #results .. " checks ok\n" .. table.concat(results, "\n")
end
