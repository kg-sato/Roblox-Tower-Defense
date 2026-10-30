--!nocheck
-- PlacementHint (T178, 2026-10-29): a heat map of good tiles for a familiar. Toggle with H (or M.toggle(pet)). A tile is good when
-- Config.canPlace allows it (same rules as the server, including the stage's map rules) and the pet's range covers a lot of the lane:
-- the score is the lane length inside range, sampled every 2 studs. Green = best, yellow = good; weak tiles are not drawn.
-- The pet is the one given, else the selected familiar, else the first on the board, else Ember (range 20). Cosmetic only; the server still validates.
-- GameClient makes it with one line (FXK.hint = require(...)({...})). M.last = { pet, tiles, best } for the Studio test. Look UNVERIFIED.
return function(env)
	local Config, UI, visuals, getStage, selectedPet, firstPet = env.Config, env.UI, env.visuals, env.getStage, env.selectedPet, env.firstPet
	local UserInputService = game:GetService("UserInputService")
	local STEP, SAMPLE = 4, 2
	local M = { on = false, last = nil }
	local folder

	-- pure: lane samples inside `range` of (x, z)
	local function score(route, x, z, range)
		local n, r2 = 0, range * range
		for i = 1, #route - 1 do
			local a, b = route[i], route[i + 1]
			local len = math.sqrt((b.X - a.X) ^ 2 + (b.Z - a.Z) ^ 2)
			for s = 0, math.floor(len / SAMPLE) do
				local t = len > 0 and (s * SAMPLE / len) or 0
				local dx, dz = a.X + (b.X - a.X) * t - x, a.Z + (b.Z - a.Z) * t - z
				if dx * dx + dz * dz <= r2 then n += 1 end
			end
		end
		return n
	end
	M.score = score

	function M.clear()
		if folder then folder:Destroy() folder = nil end
		M.on = false
	end

	function M.show(pet)
		M.clear()
		pet = pet or selectedPet() or firstPet() or "Ember"
		local def = Config.PETS[pet] or Config.PETS.Ember
		local stage = getStage()
		local rules = Config.mapRules(stage)
		local b = rules and rules.bounds or Config.PLACE_BOUNDS
		local route = rules and rules.path or Config.pathFor and Config.pathFor(stage) or Config.PATH
		local units = UI.unitTable()
		local tiles, best = {}, 0
		for x = b.minX, b.maxX, STEP do
			for z = b.minZ, b.maxZ, STEP do
				if Config.canPlace(units, pet, x, z, nil, rules) then
					local s = score(route, x, z, def.range)
					if s > 0 then
						best = math.max(best, s)
						table.insert(tiles, { x, z, s })
					end
				end
			end
		end
		folder = Instance.new("Folder")
		folder.Name = "PlacementHint"
		folder.Parent = visuals
		local drawn = 0
		for _, t in tiles do
			local k = t[3] / math.max(best, 1)
			if k >= 0.6 then
				drawn += 1
				local p = Instance.new("Part")
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
				p.Material = Enum.Material.Neon
				p.Color = k >= 0.85 and Color3.fromRGB(110, 235, 130) or Color3.fromRGB(240, 220, 90)
				p.Transparency = k >= 0.85 and 0.55 or 0.72
				p.Size = Vector3.new(STEP - 0.6, 0.12, STEP - 0.6)
				p.Position = Vector3.new(t[1], 1.12, t[2]) -- just above the pads (GROUND = 1.0)
				p.Parent = folder
			end
		end
		M.on = true
		M.last = { pet = pet, tiles = drawn, candidates = #tiles, best = best, stage = stage }
		folder:SetAttribute("Pet", pet)
		script:SetAttribute("Last", game:GetService("HttpService"):JSONEncode(M.last))
		return M.last
	end

	function M.toggle(pet)
		if M.on then M.clear() else M.show(pet) end
		return M.on
	end

	script:GetAttributeChangedSignal("Toggle"):Connect(function() -- Studio test hook: set the script attribute Toggle (any new value; a familiar id picks the pet)
		local v = script:GetAttribute("Toggle")
		M.toggle(type(v) == "string" and Config.PETS[v] and v or nil)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.H then M.toggle() end
	end)

	return M
end
