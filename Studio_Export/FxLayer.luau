--!nocheck
-- FxLayer (overnight fx-audio, 2026-10-29): LocalScript in StarterPlayerScripts that connects the new effect modules to the game
-- WITHOUT touching GameClient. It listens to the same server event remote (Remotes.Event) and watches workspace.ClientVisuals:
--   Settings            -> FxCommon.apply (reduced motion, flashes, effect detail)
--   Merge + new model   -> MergeTierFX.play (tier ladder 1 to 8) + MergeTierFX.morph (morph cut)          [T135]
--   new familiar model  -> LanternFX.spawn (spawn sparkle, at most 4 a second)                            [T144]
--   Upgrade             -> LanternFX.column (level column on every familiar of that kind)                 [T144]
--   LevelUp             -> LanternFX.column on the crystal                                               [T144]
--   Clear               -> LanternFX.ash (stage clear ash over the street)                               [T144]
--   State               -> LanternFX.vignette (crystal at or under 35%)                                   [T144]
--   enemy model         -> EnemyFamilyFX.hit (its Highlight flashes on a shot) and .death (health bar removed by a kill) [T134]
-- Test hooks: script attribute "Log" is not used; modules keep their own .log tables (ReplicatedStorage modules).
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local C = require(RS:WaitForChild("FxCommon"))
local MergeTier = require(RS:WaitForChild("MergeTierFX"))
local Lantern = require(RS:WaitForChild("LanternFX"))
local EnemyFam = require(RS:WaitForChild("EnemyFamilyFX"))
local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local Path = require(RS:WaitForChild("Shared"):WaitForChild("Path"))
local okT, TDF = pcall(function() return require(RS:WaitForChild("TDFeedback", 5)) end)
if okT then TDF.mergeTier = true C.note("fxlayer_ready") end -- TDFeedback.upgrade steps aside: MergeTierFX is the merge look

local EventRemote = RS:WaitForChild("Remotes"):WaitForChild("Event")
local visuals = workspace:WaitForChild("ClientVisuals")

local petByName = {}
for id, def in Config.PETS do petByName[def.name] = id end

local pendingMerge
local spawnWindow, spawnCount = 0, 0
local crystalMax = Config.CRYSTAL_HP or 1

local function groundOf(model)
	local cf, size = model:GetBoundingBox()
	return Vector3.new(cf.Position.X, cf.Position.Y - size.Y / 2, cf.Position.Z)
end

local function colorOf(petId)
	local def = Config.PETS[petId]
	return def and def.color or C.GOLD
end

local function onPet(model)
	task.wait() -- setPet parents the model, then moves it to its slot in the same step
	if not model.Parent then return end
	local id = petByName[model.Name]
	local base = groundOf(model)
	local pm = pendingMerge
	if pm and pm.pet == id and os.clock() - pm.t < 4 then
		pendingMerge = nil
		MergeTier.play(base, colorOf(id), pm.tier)
		MergeTier.morph(model, colorOf(id), pm.tier)
		return
	end
	local now = os.clock()
	if now - spawnWindow > 1 then spawnWindow, spawnCount = now, 0 end
	spawnCount += 1
	if spawnCount <= 4 then Lantern.spawn(base, colorOf(id)) end
end

local function onEnemy(model)
	local hl = model:WaitForChild("Highlight", 3)
	if hl then
		local prev = 1
		hl:GetPropertyChangedSignal("FillTransparency"):Connect(function()
			local v = hl.FillTransparency
			if prev >= .9 and v <= .35 then EnemyFam.hit(model) end -- a shot sets flash = 1 (fill 0.2); status tints stay above 0.4
			prev = v
		end)
	end
	local root = model:WaitForChild("Root", 3)
	if root then
		root.ChildRemoved:Connect(function(c)
			if c:IsA("BillboardGui") and model.Parent == visuals then EnemyFam.death(model) end -- the kill path removes the bar and keeps the model for its exit
		end)
	end
end

visuals.ChildAdded:Connect(function(model)
	if not model:IsA("Model") then return end
	if Config.ENEMIES[model.Name] then
		task.spawn(onEnemy, model)
	elseif petByName[model.Name] then
		task.spawn(onPet, model)
	end
end)
for _, m in visuals:GetChildren() do -- already there at start (no sparkle for those)
	if m:IsA("Model") and Config.ENEMIES[m.Name] then task.spawn(onEnemy, m) end
end

EventRemote.OnClientEvent:Connect(function(kind, data)
	if kind == "Settings" then
		C.apply(data)
	elseif kind == "Merge" and type(data) == "table" then
		pendingMerge = { pet = data.pet, tier = data.tier, t = os.clock() }
	elseif kind == "State" and type(data) == "table" and type(data.crystal) == "number" then
		crystalMax = math.max(crystalMax, data.crystal)
		Lantern.vignette(data.crystal / crystalMax)
	elseif kind == "Upgrade" and type(data) == "table" then
		local def = Config.PETS[data.pet]
		if def then
			local n = 0
			for _, m in visuals:GetChildren() do
				if m:IsA("Model") and m.Name == def.name and n < 4 then
					n += 1
					Lantern.column(groundOf(m), def.color, data.level)
				end
			end
		end
	elseif kind == "LevelUp" then
		local crystal = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Crystal")
		if crystal then Lantern.column(crystal.Position - Vector3.new(0, crystal.Size.Y / 2, 0), C.GOLD_HI, 6) end
	elseif kind == "Clear" then
		local pts = {}
		for k = 1, 7 do pts[k] = Path.positionAt(Path.length * (k - .5) / 7) end
		Lantern.ash(pts)
	elseif kind == "Overrun" or kind == "BossEscaped" then
		Lantern.vignette(nil)
	end
end)
