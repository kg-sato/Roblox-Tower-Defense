--!strict
-- Data tables for the run. Gameplay and UI both read from here.

local Config = {}

Config.START_COINS = 30
Config.START_GEMS = 30
Config.CRYSTAL_HP = 20
Config.TIER_MAX = 5
Config.TIER_MULT = 3.5
Config.ULT_NEED = 10
Config.ULT_DAMAGE = 60
Config.SPAWN_GAP = 0.45
Config.STAGE_BREAK = 1.2
Config.BOSS_EVERY = 5
Config.BOSS_TIME = 35
Config.OVERRUN_STAGE_LOSS = 2
Config.OVERRUN_COIN_LOSS = 0.3
Config.ROLL_COST = 10
Config.PITY_EVERY = 20 -- guaranteed Epic or better within this many rolls
Config.UPGRADE_MAX = 5
Config.CRIT_CAP = 0.75 -- crit chance never exceeds this, whatever upgrades and skills add
Config.RESPEC_COST = 50 -- gems for resetting the skill tree
Config.RESPEC_COOLDOWN = 120 -- sim seconds between respecs in one run

Config.PATH = {
	Vector3.new(-44, 1, -20),
	Vector3.new(24, 1, -20),
	Vector3.new(24, 1, 8),
	Vector3.new(-30, 1, 8),
	Vector3.new(-30, 1, 22),
	Vector3.new(40, 1, 22),
}

-- Two rows of six pads between the lanes. Row A is slots 1-6, row B is slots 7-12.
Config.SLOTS = {} :: { Vector3 }
for row = 0, 1 do
	for col = 0, 5 do
		table.insert(Config.SLOTS, Vector3.new(-18 + col * 7.2, 1, -12 + row * 8))
	end
end

-- Orthogonal neighbours only. Built from positions so the map and the rule never disagree.
Config.RARITIES = {
	Common = { order = 1, color = Color3.fromRGB(190, 196, 210), odds = 60, mult = 1 },
	Rare = { order = 2, color = Color3.fromRGB(80, 170, 255), odds = 28, mult = 2.2 },
	Epic = { order = 3, color = Color3.fromRGB(180, 100, 255), odds = 10, mult = 5 },
	Legendary = { order = 4, color = Color3.fromRGB(255, 200, 60), odds = 2, mult = 12 },
}
Config.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary" }

-- damage is for tier 1 before rarity multiplier
Config.PETS = {
	Ember = { name = "Ember", rarity = "Common", color = Color3.fromRGB(255, 110, 64), damage = 12, cooldown = 1.0, range = 20 },
	Sprout = { name = "Sprout", rarity = "Common", color = Color3.fromRGB(110, 220, 90), damage = 7, cooldown = 0.7, range = 22 },
	Zap = { name = "Zap", rarity = "Common", color = Color3.fromRGB(255, 225, 80), damage = 4, cooldown = 0.35, range = 18 },
	Frostling = { name = "Frostling", rarity = "Rare", color = Color3.fromRGB(110, 210, 255), damage = 10, cooldown = 0.8, range = 24 },
	Boulder = { name = "Boulder", rarity = "Rare", color = Color3.fromRGB(150, 130, 110), damage = 20, cooldown = 1.4, range = 20 },
	VoltFox = { name = "Volt Fox", rarity = "Epic", color = Color3.fromRGB(190, 110, 255), damage = 9, cooldown = 0.45, range = 24 },
	StarDrake = { name = "Star Drake", rarity = "Legendary", color = Color3.fromRGB(255, 190, 70), damage = 14, cooldown = 0.6, range = 28 },
}
Config.PET_ORDER = { "Ember", "Sprout", "Zap", "Frostling", "Boulder", "VoltFox", "StarDrake" }

-- ===== Character registry =====
-- Characters live in ReplicatedStorage.Characters: one Folder per character, named by its id. Attributes:
--   DisplayName, Rarity (Common/Rare/Epic/Legendary), Damage, Cooldown, Range, Footprint, Color, Order,
--   Shot (projectile style: bolt, flame, leaf, spark, ice, stone, card, star)
-- Optional children: Model (a Model or MeshPart; Tint/Height/Material/Yaw attributes style it),
-- Animations (KeyframeSequences or Animations named Idle/Attack), Effects (emitters/lights cloned onto it).
-- Adding a character = adding a folder; no code changes. The table above is ONLY a fallback (warns when used):
-- edit characters in the folders, not in the table.
Config.FOOTPRINT_DEFAULT = 2.5
do
	local ok, folder = pcall(function()
		return game:GetService("ReplicatedStorage"):WaitForChild("Characters", 5)
	end)
	if ok and folder then
		local pets, order = {}, {}
		for _, f in folder:GetChildren() do
			local rarity = f:GetAttribute("Rarity")
			if f:IsA("Folder") and Config.RARITIES[rarity] then
				pets[f.Name] = {
					name = f:GetAttribute("DisplayName") or f.Name,
					rarity = rarity,
					color = f:GetAttribute("Color") or Config.RARITIES[rarity].color,
					damage = f:GetAttribute("Damage") or 8,
					cooldown = f:GetAttribute("Cooldown") or 1,
					range = f:GetAttribute("Range") or 20,
					footprint = f:GetAttribute("Footprint") or Config.FOOTPRINT_DEFAULT,
					order = f:GetAttribute("Order") or 999,
					shot = f:GetAttribute("Shot") or "bolt", -- projectile style (ReplicatedStorage.ProjectileFX)
					signature = f:GetAttribute("Signature"), -- featured familiars: cutscene ultimate (ReplicatedStorage.CutsceneFX)
					signatureName = f:GetAttribute("SignatureName"),
					signaturePower = f:GetAttribute("SignaturePower") or 1.25, -- damage multiplier on the ultimate
				}
				table.insert(order, f.Name)
			end
		end
		if #order == 0 then
			warn("Config: ReplicatedStorage.Characters has no valid characters; using the fallback pet table")
		end
		if #order > 0 then
			table.sort(order, function(a, b)
				return pets[a].order < pets[b].order
			end)
			Config.PETS = pets
			Config.PET_ORDER = order
		end
	end
end

-- ===== Familiar data (T101) =====
-- The 12-familiar cast (Shared.Familiars, generated from Roblox Dev/Lore). Every familiar has a character folder (T102), and its Config.PETS
-- entry gets the cast's name, role, faction and loreId. Rarity, damage, range and cooldown stay the folder's attributes.
-- FindFirstChild, never WaitForChild: the headless tests clone only Config, Path and MatchSim into a temporary folder, and a wait would hang them.
do
	local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
	local mod = script.Parent:FindFirstChild("Familiars") or (shared and shared:FindFirstChild("Familiars"))
	if mod and mod:IsA("ModuleScript") then
		local Familiars = require(mod)
		Config.FAMILIARS = Familiars.byId
		Config.FAMILIAR_ORDER = Familiars.order
		for id, def in Config.PETS do
			local f = Familiars.forChar(id)
			if f then
				local d = def :: any
				d.name, d.role, d.faction, d.loreId, d.familiar = f.name, f.role, f.faction, f.loreId, f.id
			end
		end
	else
		warn("Config: Shared.Familiars not found; familiar data skipped")
		Config.FAMILIARS = {}
		Config.FAMILIAR_ORDER = {}
	end
end

-- ===== Free placement (Bloons-style) =====
-- Pets go anywhere on the street inside the fence, off the path, without footprints overlapping.
-- Shared by server (validation) and client (preview), so both always agree.
Config.MAX_UNITS = 12
Config.PLACE_BOUNDS = { minX = -50, maxX = 46, minZ = -26, maxZ = 28 }
Config.PATH_HALF_WIDTH = 4.8 -- lane half width (4) plus kerb
Config.TOUCH_GAP = 2.5 -- extra distance that still counts as touching for merges

function Config.footprint(pet: string): number
	local def = Config.PETS[pet]
	return def and def.footprint or Config.FOOTPRINT_DEFAULT
end

function Config.distToPath(x: number, z: number): number
	local best = math.huge
	local pts = Config.PATH
	for i = 1, #pts - 1 do
		local ax, az, bx, bz = pts[i].X, pts[i].Z, pts[i + 1].X, pts[i + 1].Z
		local dx, dz = bx - ax, bz - az
		local len2 = dx * dx + dz * dz
		local t = len2 > 0 and math.clamp(((x - ax) * dx + (z - az) * dz) / len2, 0, 1) or 0
		local px, pz = ax + dx * t - x, az + dz * t - z
		best = math.min(best, math.sqrt(px * px + pz * pz))
	end
	return best
end

-- units: { [id] = { pet, x, z } } (any table with pet/x/z works). Returns ok, reason.
function Config.canPlace(units: any, pet: string, x: number, z: number, ignoreId: any): (boolean, string?)
	local b = Config.PLACE_BOUNDS
	if x ~= x or z ~= z or x < b.minX or x > b.maxX or z < b.minZ or z > b.maxZ then
		return false, "Out of bounds"
	end
	local fp = Config.footprint(pet)
	if Config.distToPath(x, z) < Config.PATH_HALF_WIDTH + fp * 0.6 then
		return false, "Not on the path"
	end
	local last = Config.PATH[#Config.PATH]
	if math.abs(x - (last.X + 5)) < 6 and math.abs(z - last.Z) < 6 then
		return false, "Too close to the crystal"
	end
	for id, u in units do
		if id ~= ignoreId and u.x then
			local dx, dz = u.x - x, u.z - z
			local r = fp + Config.footprint(u.pet)
			if dx * dx + dz * dz < r * r then
				return false, "Too close to another pet"
			end
		end
	end
	return true, nil
end

function Config.touching(a: any, b: any): boolean
	local dx, dz = a.x - b.x, a.z - b.z
	local r = Config.footprint(a.pet) + Config.footprint(b.pet) + Config.TOUCH_GAP
	return dx * dx + dz * dz <= r * r
end

-- Pets per rarity, equal chance inside a rarity. One table feeds the roll AND the odds panel.
function Config.petsOfRarity(rarity: string): { string }
	local list = {}
	for _, id in Config.PET_ORDER do
		if Config.PETS[id].rarity == rarity then
			table.insert(list, id)
		end
	end
	return list
end

Config.UPGRADES = {
	Power = { name = "Power", desc = "+30% damage per level", per = 0.30 },
	Haste = { name = "Haste", desc = "+14% attack speed per level", per = 0.14 },
	Crit = { name = "Crit", desc = "+8% chance for 2.5x damage per level", per = 0.08 },
}
Config.UPGRADE_ORDER = { "Power", "Haste", "Crit" }

function Config.upgradeCost(level: number): number
	return math.floor(12 * 1.75 ^ level)
end

Config.ENEMIES = {
	Grunt = { hp = 30, speed = 8, coins = 2, gems = 1, leak = 1, size = 2.4, color = Color3.fromRGB(110, 100, 150) },
	Swift = { hp = 18, speed = 13, coins = 2, gems = 1, leak = 1, size = 2, color = Color3.fromRGB(160, 205, 235) },
	Tank = { hp = 120, speed = 5, coins = 6, gems = 3, leak = 2, size = 3.6, color = Color3.fromRGB(176, 136, 72) },
	Boss = { hp = 700, speed = 4, coins = 60, gems = 25, leak = 5, size = 6.5, color = Color3.fromRGB(140, 230, 110) },
}

function Config.hpScale(stage: number): number
	return 1.2 ^ (stage - 1)
end

function Config.isBossStage(stage: number): boolean
	return stage % Config.BOSS_EVERY == 0
end

-- Ordered enemy kinds for a stage.
function Config.stageSpawns(stage: number): { string }
	local list = {}
	local count = math.min(5 + math.floor(stage * 1.3), 28)
	for i = 1, count do
		local kind = "Grunt"
		if stage >= 3 and i % 3 == 0 then
			kind = "Swift"
		end
		if stage >= 6 and i % 5 == 0 then
			kind = "Tank"
		end
		table.insert(list, kind)
	end
	if Config.isBossStage(stage) then
		table.insert(list, "Boss")
	end
	return list
end

-- Trainer progression: XP from kills and stage clears. Each level pays gems and adds Luck.
Config.LEVEL_MAX = 25

function Config.xpNeed(level: number): number
	return math.floor(30 * level ^ 1.6)
end

function Config.levelGems(level: number): number
	return 10 + 5 * level
end

function Config.luck(level: number): number
	return math.min(0.5, 0.03 * (level - 1))
end

-- Odds as weights. Luck makes better rarities likelier. One function feeds the roll AND the odds panel.
function Config.rarityWeights(luck: number): { [string]: number }
	return {
		Common = Config.RARITIES.Common.odds,
		Rare = Config.RARITIES.Rare.odds * (1 + luck),
		Epic = Config.RARITIES.Epic.odds * (1 + 2 * luck),
		Legendary = Config.RARITIES.Legendary.odds * (1 + 3 * luck),
	}
end

function Config.rarityPercents(luck: number): { [string]: number }
	local w = Config.rarityWeights(luck)
	local total = 0
	for _, v in w do
		total += v
	end
	local out = {}
	for k, v in w do
		out[k] = v / total * 100
	end
	return out
end

function Config.recycleValue(pet: string, tier: number): number
	local def = Config.PETS[pet]
	return math.floor(5 * Config.RARITIES[def.rarity].order * 3 ^ (tier - 1))
end

function Config.comboMult(combo: number): number
	return 1 + 0.25 * math.min(combo, 8)
end

function Config.petDamage(pet: string, tier: number): number
	local def = Config.PETS[pet]
	return def.damage * Config.RARITIES[def.rarity].mult * Config.TIER_MULT ^ (tier - 1)
end

-- Skill tree: a honeycomb of permanent upgrades bought with Skill Points (SP).
-- SP come from trainer level-ups (+1), boss kills (+1) and finishing the tutorial (+2).
-- Axial hex coordinates (q, r). A node can be bought once a neighbouring node is owned.
local GOLD, RED, BLUE, PURPLE, GREEN, CYAN = Color3.fromRGB(255, 200, 60), Color3.fromRGB(236, 90, 90), Color3.fromRGB(80, 160, 255), Color3.fromRGB(170, 110, 255), Color3.fromRGB(80, 215, 120), Color3.fromRGB(100, 225, 255)

Config.TREE = {
	{ id = "Start", q = 0, r = 0, name = "Start", short = "GO", desc = "Your journey begins here.", max = 1, base = 0, kind = "none", per = 0, color = CYAN },
	-- inner ring
	{ id = "Claws", q = 1, r = 0, name = "Sharp Claws", short = "ATK", desc = "+6% damage for every pet", max = 5, base = 1, kind = "damage", per = 0.06, color = RED },
	{ id = "Magnet", q = 1, r = -1, name = "Coin Magnet", short = "$", desc = "+8% coins from monsters", max = 5, base = 1, kind = "coins", per = 0.08, color = GOLD },
	{ id = "Armor", q = 0, r = -1, name = "Crystal Armor", short = "HP", desc = "+4 crystal health", max = 5, base = 1, kind = "crystal", per = 4, color = BLUE },
	{ id = "Charge", q = -1, r = 0, name = "Quick Charge", short = "ULT", desc = "Ultimate needs 1 fewer kill", max = 4, base = 1, kind = "ultNeed", per = 1, color = PURPLE },
	{ id = "Charm", q = -1, r = 1, name = "Lucky Charm", short = "LCK", desc = "+3% roll luck", max = 5, base = 1, kind = "luck", per = 0.03, color = GREEN },
	{ id = "Finder", q = 0, r = 1, name = "Gem Finder", short = "GEM", desc = "+8% gems from monsters", max = 5, base = 1, kind = "gems", per = 0.08, color = CYAN },
	-- outer ring, straight out
	{ id = "Heavy", q = 2, r = 0, name = "Heavy Hitter", short = "BOSS", desc = "+15% damage to bosses", max = 3, base = 2, kind = "bossDamage", per = 0.15, color = RED },
	{ id = "Merger", q = 2, r = -2, name = "Merge Bonus", short = "MRG", desc = "Merging pays coins (5 x tier)", max = 3, base = 2, kind = "merge", per = 1, color = GOLD },
	{ id = "Clock", q = 0, r = -2, name = "Boss Clock", short = "TIME", desc = "+5 seconds before a boss escapes", max = 3, base = 2, kind = "bossTime", per = 5, color = BLUE },
	{ id = "Mega", q = -2, r = 0, name = "Mega Ultimate", short = "NOVA", desc = "+30% ultimate damage", max = 3, base = 2, kind = "ultDamage", per = 0.30, color = PURPLE },
	{ id = "Discount", q = -2, r = 2, name = "Gem Discount", short = "-1", desc = "Rolls cost 1 less gem", max = 3, base = 2, kind = "rollDiscount", per = 1, color = GREEN },
	{ id = "Guard", q = 0, r = 2, name = "Streak Guard", short = "SAFE", desc = "Ignore 1 leak per stage for your streak", max = 2, base = 2, kind = "streakGuard", per = 1, color = CYAN },
	-- outer ring, between branches
	{ id = "Eye", q = 2, r = -1, name = "Critical Eye", short = "CRT", desc = "+4% crit chance", max = 5, base = 2, kind = "crit", per = 0.04, color = RED },
	{ id = "Learner", q = 1, r = -2, name = "Fast Learner", short = "XP", desc = "+15% trainer XP", max = 3, base = 2, kind = "xp", per = 0.15, color = GOLD },
	{ id = "Refund", q = -1, r = -1, name = "Ult Refund", short = "RFD", desc = "Start with 2 ultimate charge after casting", max = 2, base = 2, kind = "ultRefund", per = 2, color = PURPLE },
	{ id = "Pity", q = -2, r = 1, name = "Pity Shortcut", short = "PTY", desc = "Guaranteed Epic 3 rolls sooner", max = 3, base = 2, kind = "pity", per = 3, color = GREEN },
	{ id = "Double", q = -1, r = 2, name = "Double Hatch", short = "x2", desc = "+6% chance to hatch a free bonus pet", max = 5, base = 2, kind = "doubleHatch", per = 0.06, color = CYAN },
	{ id = "Haste", q = 1, r = 1, name = "Haste Aura", short = "SPD", desc = "+5% attack speed", max = 4, base = 2, kind = "haste", per = 0.05, color = RED },
}

Config.TREE_BY_ID = {} :: { [string]: any }
for _, node in Config.TREE do
	Config.TREE_BY_ID[node.id] = node
end

local HEX_DIRS = { { 1, 0 }, { 1, -1 }, { 0, -1 }, { -1, 0 }, { -1, 1 }, { 0, 1 } }
Config.TREE_NEIGHBORS = {} :: { [string]: { string } }
for _, a in Config.TREE do
	Config.TREE_NEIGHBORS[a.id] = {}
	for _, d in HEX_DIRS do
		for _, b in Config.TREE do
			if b.q == a.q + d[1] and b.r == a.r + d[2] then
				table.insert(Config.TREE_NEIGHBORS[a.id], b.id)
			end
		end
	end
end

function Config.skillCost(node: any, level: number): number
	return node.base * math.ceil((level + 1) / 2)
end

-- The cheapest node the player can buy right now (reachable, not maxed, affordable), for the skill tree's next-best hint (T199).
-- Ties go to the node listed first in Config.TREE (the inner ring). Returns nil when nothing can be bought.
function Config.nextBestSkill(levels: { [string]: number }, sp: number): (string?, number?)
	local best: string?, bestCost: number? = nil, nil
	for _, node in Config.TREE do
		if node.id ~= "Start" then
			local level = levels[node.id] or 0
			if level < node.max then
				local reachable = false
				for _, n in Config.TREE_NEIGHBORS[node.id] do
					if (levels[n] or 0) > 0 then
						reachable = true
						break
					end
				end
				if reachable then
					local cost = Config.skillCost(node, level)
					if cost <= sp and (bestCost == nil or cost < bestCost) then
						best, bestCost = node.id, cost
					end
				end
			end
		end
	end
	return best, bestCost
end

-- Total effect of one kind, given a { [nodeId]: level } table.
function Config.skillValue(levels: { [string]: number }, kind: string): number
	local total = 0
	for id, level in levels do
		local node = Config.TREE_BY_ID[id]
		if node and node.kind == kind then
			total += node.per * level
		end
	end
	return total
end

-- Premium pets: fixed-price developer products. id = 0 means not set up yet (button disabled).
Config.PRODUCTS = {}

-- Load-time sanity check: every rarity needs at least one character or its rolls step down (MatchSim.pickPet).
for _, r in Config.RARITY_ORDER do
	if #Config.petsOfRarity(r) == 0 then
		warn("Config: no characters for rarity " .. r)
	end
end

return Config
