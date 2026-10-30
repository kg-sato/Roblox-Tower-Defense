--!strict
-- Data tables for the run. Gameplay and UI both read from here.

local Config = {}

-- Balance numbers live in Shared.Data.* (T199), one module per system; Config re-exports every field below, so no other script changes.
-- Data sits beside Config; a test that clones Config alone finds it through ReplicatedStorage.Shared. Each load gets its own deep copy.
local function loadData(name: string): any
	local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
	local folder = script.Parent:FindFirstChild("Data") or (shared and shared:FindFirstChild("Data"))
	local mod = folder and folder:FindFirstChild(name)
	assert(mod, "Shared.Data." .. name .. " is missing")
	local function copy(t: any): any
		local c = table.clone(t)
		for k, v in c do
			if type(v) == "table" then
				c[k] = copy(v)
			end
		end
		return c
	end
	return copy(require(mod :: ModuleScript))
end
local Economy = loadData("Economy")
local Rarities = loadData("Rarities")
local Upgrades = loadData("Upgrades")
local Enemies = loadData("Enemies")
local Combat = loadData("Combat")
local Bosses = loadData("Bosses")
local Waves = loadData("Waves")
local Difficulty = loadData("Difficulty")
local Synergies = loadData("Synergies")
local Sky = loadData("Sky")

Config.START_COINS = Economy.START_COINS
Config.START_GEMS = Economy.START_GEMS
Config.CRYSTAL_HP = Economy.CRYSTAL_HP
Config.TIER_MAX = Economy.TIER_MAX
Config.TIER_MULT = Economy.TIER_MULT
Config.ULT_NEED = Economy.ULT_NEED
Config.ULT_DAMAGE = Economy.ULT_DAMAGE
Config.SPAWN_GAP = Economy.SPAWN_GAP
Config.STAGE_BREAK = Economy.STAGE_BREAK
Config.BOSS_EVERY = Economy.BOSS_EVERY
Config.BOSS_TIME = Economy.BOSS_TIME
Config.OVERRUN_STAGE_LOSS = Economy.OVERRUN_STAGE_LOSS
Config.OVERRUN_COIN_LOSS = Economy.OVERRUN_COIN_LOSS
Config.ROLL_COST = Economy.ROLL_COST
Config.PITY_EVERY = Economy.PITY_EVERY
Config.UPGRADE_MAX = Economy.UPGRADE_MAX
Config.CRIT_CAP = Economy.CRIT_CAP
Config.RESPEC_COST = Economy.RESPEC_COST
Config.RESPEC_COOLDOWN = Economy.RESPEC_COOLDOWN

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

Config.RARITIES = Rarities.RARITIES
Config.RARITY_ORDER = Rarities.RARITY_ORDER

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
-- Roster slots (T185): how many pets may stand at once, by trainer level. Each row opens `slots` from `level` on; the last row
-- whose level is reached wins. Today every slot is open from level 1, so nothing changes; raise a row's level to gate it.
Config.ROSTER_SLOT_UNLOCKS = { { level = 1, slots = 12 } }
function Config.rosterSlots(level: number): number
	local n = 0
	for _, row in Config.ROSTER_SLOT_UNLOCKS do
		if level >= row.level then
			n = math.max(n, row.slots)
		end
	end
	return math.clamp(n, 1, Config.MAX_UNITS)
end
Config.PLACE_BOUNDS = { minX = -50, maxX = 46, minZ = -26, maxZ = 28 }
Config.PATH_PER_SET = false -- T167: each stage set uses its own lane (StageSets path); OFF = the single Config.PATH everywhere
Config.MAP_RULES = false -- T177: per-set placement rules (StageSets place) feed canPlace; OFF = the old rules
Config.PATH_BLOCKERS = false -- T157: fences and gates from StageSets blockers stop enemies mid-lane; OFF = none
Config.PATH_HALF_WIDTH = 4.8 -- lane half width (4) plus kerb
Config.TOUCH_GAP = 2.5 -- extra distance that still counts as touching for merges

function Config.footprint(pet: string): number
	local def = Config.PETS[pet]
	return def and def.footprint or Config.FOOTPRINT_DEFAULT
end

function Config.distToPath(x: number, z: number, route: { Vector3 }?): number
	local best = math.huge
	local pts = route or Config.PATH
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
-- rules (optional, T177): { bounds, path, noBuild = { { x, z, r } } } from Config.mapRules; decorations are not in the rules, they never block.
function Config.canPlace(units: any, pet: string, x: number, z: number, ignoreId: any, rules: any): (boolean, string?)
	local b = rules and rules.bounds or Config.PLACE_BOUNDS
	if x ~= x or z ~= z or x < b.minX or x > b.maxX or z < b.minZ or z > b.maxZ then
		return false, "Out of bounds"
	end
	local fp = Config.footprint(pet)
	local route = rules and rules.path or Config.PATH
	if Config.distToPath(x, z, route) < Config.PATH_HALF_WIDTH + fp * 0.6 then
		return false, "Not on the path"
	end
	if rules and rules.noBuild then
		for _, zone in rules.noBuild do
			local zx, zz, zr = x - zone.x, z - zone.z, zone.r + fp * 0.6
			if zx * zx + zz * zz < zr * zr then
				return false, "Blocked area"
			end
		end
	end
	local last = route[#route]
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

Config.UPGRADES = Upgrades.UPGRADES
Config.UPGRADE_ORDER = Upgrades.UPGRADE_ORDER

function Config.upgradeCost(level: number): number
	return math.floor(12 * 1.75 ^ level)
end

Config.ENEMIES = Enemies.ENEMIES
Config.HOLLOW_ENEMIES = false -- Hollow Parishioner and Fog Wisp in the wave lists; keep false until the client has models for both
Config.LAMP_EAT = { at = 0.4, snuffCooldown = 10, darkFor = 8 } -- a Fog Wisp past `at` of the path snuffs the Lantern (+snuffCooldown s to recharge) or, if it is ready, darkens it for darkFor s
Config.NEW_ENEMIES = true -- Clockwork Crow and Lantern Thief in the wave lists (needs client models first)
Config.MOVEMENT_EFFECTS = true -- slows, stuns, plants and speed-ups change enemy speed; the client moves enemies at a constant speed, so keep false until GameClient handles the "Pace" event {id, dist, speed, t}

Config.DAMAGE_TYPE = Combat.DAMAGE_TYPE
Config.ARMOR_MULT = Combat.ARMOR_MULT
Config.STATUS = Combat.STATUS
Config.ROLES = Combat.ROLES

Config.HP_GROWTH = 1.27 -- enemy hp multiplier per stage (was 1.2; raised 2026-10-29: 1.25 gave a perfect bot 6 minutes, 1.3 made it fail or take 18 minutes)
-- Endless mode (T016, OFF): past stage ENDLESS_FROM the hp growth drops from HP_GROWTH to ENDLESS_GROWTH per stage so waves 26 to 100 stay playable and finite
-- (stage 100: about 1e5 times the stage 1 hp instead of 1.8e10). The rest (spawn counts, boss cycle, rewards) already carries on past stage 25.
Config.ENDLESS = false
Config.ENDLESS_FROM = 25
Config.ENDLESS_GROWTH = 1.08
function Config.hpScale(stage: number): number
	if Config.ENDLESS and stage > Config.ENDLESS_FROM then
		return Config.HP_GROWTH ^ (Config.ENDLESS_FROM - 1) * Config.ENDLESS_GROWTH ^ (stage - Config.ENDLESS_FROM)
	end
	return Config.HP_GROWTH ^ (stage - 1)
end

function Config.isBossStage(stage: number): boolean
	return stage % Config.BOSS_EVERY == 0
end

-- Boss framework (2026-10-29): one definition per boss, three phases at 100%, 66% and 33% hp. `Config.bossDef(stage)` picks the boss of a stage set
-- (the five repeat after stage 25). Each phase has `fx` that the sim runs generically (Shared.MatchSim bossTick): regen { every, pct }, deny { every, dur } (the
-- newest unit cannot fire), freeze { every, dur } (every unit cannot fire), summon { every, kind, count }, slowAura { radius, slow } (units within radius
-- cool down 1/(1+slow) as fast), speedMult, damageTaken. Design notes: Roblox Dev/Design/Boss Designs.md and Boss Framework.md. Numbers are placeholders.
-- BOSS_PHASES off gives the old single generic Boss.
Config.BOSS_PHASES = true
-- BOSS_V2 (T416, OFF): the Automaton's lamp (heals a life), the Echo's pushes, the Regent's candles instead of the flat damageTaken. BOSS_UNMERGE (OFF): the Clockmaker un-merges one unit.
-- Phase fx keys: lamp { every, heal }, push { every, dist, count }, candles { count, every, per, min }, unmerge { every }. The sim ignores them while the flag is off.
Config.BOSS_V2 = false
Config.BOSS_UNMERGE = false
Config.BOSSES = Bosses.BOSSES
function Config.bossDef(stage: number)
	local n = #Config.BOSSES
	return Config.BOSSES[((math.floor(stage / Config.BOSS_EVERY) - 1) % n) + 1]
end

-- Ordered enemy kinds for a stage.
function Config.stageSpawns(stage: number): { string }
	local list = {}
	local count = math.min(5 + math.floor(stage * 1.3), 28)
	local mod = Config.WAVES_V2 and Config.waveModifier(stage) or nil
	if mod and mod.count then
		count = math.clamp(math.floor(count * mod.count), 3, 40)
	end
	for i = 1, count do
		local kind = "Grunt"
		if stage >= 3 and i % 3 == 0 then
			kind = "Swift"
		end
		if stage >= 6 and i % 5 == 0 then
			kind = "Tank"
		end
		if Config.NEW_ENEMIES and kind == "Grunt" then
			if stage >= 7 and i % 7 == 0 then
				kind = "Crow"
			elseif stage >= 9 and i % 4 == 0 then
				kind = "Thief"
			end
		end
		if Config.HOLLOW_ENEMIES and kind == "Grunt" then
			if stage >= 11 and i % 6 == 1 then
				kind = "Parishioner"
			elseif stage >= 12 and i % 6 == 5 then
				kind = "FogWisp"
			end
		end
		table.insert(list, kind)
	end
	if Config.isBossStage(stage) then
		table.insert(list, "Boss")
	end
	return list
end

-- ===== Wave variety (T015): elite enemies and ten wave modifiers, all data, off by default (WAVES_V2) =====
-- An elite is a normal kind with more hp, a slower walk and a bigger reward; the sim marks it (`elite`), the kind is unchanged so the client needs no new model.
-- Modifiers are picked from the stage number, so a stage always has the same one; boss stages and the first stages have none.
Config.WAVES_V2 = false
-- Client UI screens (T074, T097), off by default: the result panel after a stage clear and the pause menu button
Config.RESULTS_SCREEN = false
Config.PAUSE_MENU = false
Config.ELITE = Waves.ELITE
Config.MOD_FIRST = Waves.MOD_FIRST
Config.WAVE_MODIFIERS = Waves.WAVE_MODIFIERS
function Config.waveModifier(stage: number): any?
	if stage < Config.MOD_FIRST or Config.isBossStage(stage) then
		return nil
	end
	local k = math.floor(stage) - math.floor(stage / Config.BOSS_EVERY) -- counts only non-boss stages, so ten in a row use all ten modifiers
	return Config.WAVE_MODIFIERS[(k * 3) % #Config.WAVE_MODIFIERS + 1]
end
-- how many elites a stage holds, and which positions of its spawn list they are (evenly spread, never the boss)
function Config.eliteCount(stage: number): number
	if stage < Config.ELITE.first then
		return 0
	end
	return math.min(1 + math.floor((stage - Config.ELITE.first) / Config.ELITE.every), Config.ELITE.max)
end
function Config.stageElites(stage: number, list: { string }): { [number]: boolean }
	local out = {}
	local n = #list - (list[#list] == "Boss" and 1 or 0)
	local c = math.min(Config.eliteCount(stage), n)
	for j = 1, c do
		out[math.max(1, math.floor(j * n / (c + 1)))] = true
	end
	return out
end

Config.DIFFICULTY = Difficulty.DIFFICULTY
Config.DIFFICULTY_ORDER = Difficulty.DIFFICULTY_ORDER
function Config.difficulty(id: any): any
	return (type(id) == "string" and Config.DIFFICULTY[id]) or Config.DIFFICULTY.Normal
end

-- ===== Pause (T006) =====
Config.PAUSE_MAX = 300 -- real seconds one pause may last before the server resumes the run

-- ===== Collection (T186): duplicates and shards per familiar =====
-- A pull of a familiar already owned adds a duplicate and shards by rarity. Saved in the profile as collection[pet] = { count, shards }.
Config.SHARDS_PER_DUPLICATE = { Common = 1, Rare = 2, Epic = 5, Legendary = 10, Mythic = 25, Celestial = 50 }
Config.COLLECTION_MAX = 1000000
function Config.shardsFor(pet: string): number
	local def = Config.PETS[pet]
	return def and Config.SHARDS_PER_DUPLICATE[def.rarity] or 0
end
-- Records one pull in `coll` (mutated). Returns true when the familiar is new to the collection.
function Config.collectionAdd(coll: any, pet: string): boolean
	local e = coll[pet]
	if not e then
		coll[pet] = { count = 1, shards = 0 }
		return true
	end
	e.count = math.min(e.count + 1, Config.COLLECTION_MAX)
	e.shards = math.min(e.shards + Config.shardsFor(pet), Config.COLLECTION_MAX)
	return false
end
-- Clean a saved collection: only real familiars, whole numbers in range; every familiar in `seen` (the older save format) owns at least one.
function Config.sanitizeCollection(raw: any, seen: any): { [string]: { count: number, shards: number } }
	local out = {}
	local function num(v: any, lo: number): number
		if type(v) ~= "number" or v ~= v then
			return lo
		end
		return math.clamp(math.floor(v), lo, Config.COLLECTION_MAX)
	end
	if type(raw) == "table" then
		for id, e in raw do
			if type(id) == "string" and Config.PETS[id] and type(e) == "table" then
				out[id] = { count = num(e.count, 1), shards = num(e.shards, 0) }
			end
		end
	end
	if type(seen) == "table" then
		for id, v in seen do
			if v == true and type(id) == "string" and Config.PETS[id] and not out[id] then
				out[id] = { count = 1, shards = 0 }
			end
		end
	end
	return out
end

Config.LANTERN = Synergies.LANTERN

-- ===== Faction adjacency combos (T012): data table of pairs; a familiar touching a partner gets the bonus once per entry =====
-- a and b are factions (Shared.Familiars). a == b needs two touching familiars of that faction. Bonuses are capped per familiar.
Config.SYNERGY_ON = true
Config.SYNERGIES = Synergies.SYNERGIES
Config.SYNERGY_CAP = Synergies.SYNERGY_CAP

-- ===== Day, night and weather (T009): per-set windows are data in Shared.StageSets (`sky`); the effects are here, off by default =====
-- sky = { cycle = sim seconds per day, night = { from, to } as fractions of the cycle, weather = { { kind, at, dur } } } (at is a fraction, dur seconds).
-- An effect may hold enemySpeed (multiplier), range (added share of every familiar's range) and damage[damageType] (added share).
Config.SKY_ON = false
Config.SKY_EFFECTS = Sky.SKY_EFFECTS
local stageSetsMod: any = nil
function Config.setFor(stage: number): any
	if stageSetsMod == nil then
		local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
		local m = script.Parent:FindFirstChild("StageSets") or (shared and shared:FindFirstChild("StageSets"))
		local ok, mod = pcall(function()
			return require(m :: ModuleScript)
		end)
		stageSetsMod = ok and mod or false
	end
	return stageSetsMod and stageSetsMod.forStage(stage) or nil
end
function Config.skyFor(stage: number): any
	local set = Config.setFor(stage)
	return set and set.sky or nil
end

-- The lane for a stage (T167): the set's own waypoints with Config.PATH_PER_SET, else the single Config.PATH.
function Config.pathFor(stage: number): { Vector3 }
	if not Config.PATH_PER_SET then
		return Config.PATH
	end
	local set = Config.setFor(stage)
	local wp = set and set.path
	if not wp or #wp < 2 then
		return Config.PATH
	end
	local out = {}
	for _, p in wp do
		table.insert(out, Vector3.new(p[1], 1, p[2]))
	end
	return out
end

-- Placement rules for a stage (T177): nil (old rules) unless Config.MAP_RULES. decor is data for the client; canPlace never reads it.
function Config.mapRules(stage: number): any
	if not Config.MAP_RULES then
		return nil
	end
	local set = Config.setFor(stage)
	local pl = set and set.place or {}
	return { bounds = pl.bounds or Config.PLACE_BOUNDS, path = Config.pathFor(stage), noBuild = pl.noBuild or {}, decor = pl.decor or {} }
end

-- Fences and gates of a stage (T157), as a fresh copy per call: {} unless Config.PATH_BLOCKERS.
function Config.blockersFor(stage: number): { any }
	local out = {}
	if not Config.PATH_BLOCKERS then
		return out
	end
	local set = Config.setFor(stage)
	for _, b in set and set.blockers or {} do
		table.insert(out, table.clone(b))
	end
	return out
end
-- { night: boolean, weather: string? } at sim time t in a stage, or nil without sky data
function Config.skyAt(stage: number, t: number): any
	local sky = Config.skyFor(stage)
	if not sky then
		return nil
	end
	local phase = (t % sky.cycle) / sky.cycle
	local night = sky.night ~= nil and phase >= sky.night[1] and phase < sky.night[2]
	local weather
	for _, w in sky.weather or {} do
		local into = (t - w.at * sky.cycle) % sky.cycle
		if into < w.dur then
			weather = w.kind
			break
		end
	end
	return { night = night, weather = weather }
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
-- A rarity with no familiar has weight 0, so adding a rarity to the table is harmless until a familiar uses it.
function Config.rarityWeights(luck: number): { [string]: number }
	local out = {
		Common = Config.RARITIES.Common.odds,
		Rare = Config.RARITIES.Rare.odds * (1 + luck),
		Epic = Config.RARITIES.Epic.odds * (1 + 2 * luck),
		Legendary = Config.RARITIES.Legendary.odds * (1 + 3 * luck),
		Mythic = Config.RARITIES.Mythic.odds * (1 + 4 * luck),
		Celestial = Config.RARITIES.Celestial.odds * (1 + 5 * luck),
	}
	for rarity in out do
		if #Config.petsOfRarity(rarity) == 0 then
			out[rarity] = 0
		end
	end
	return out
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

-- Refund share of a recycled pet by its tier (T019). 1 = the full value, as before; lower a tier's entry to pay less.
Config.REFUND_PCT = { 1, 1, 1, 1, 1, 1, 1, 1 }
function Config.refundPct(tier: number): number
	local p = Config.REFUND_PCT[tier]
	return if type(p) == "number" and p == p then math.clamp(p, 0, 1) else 1
end

function Config.recycleValue(pet: string, tier: number): number
	local def = Config.PETS[pet]
	return math.floor(5 * Config.RARITIES[def.rarity].order * 3 ^ (tier - 1) * Config.refundPct(tier))
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
	if #Config.petsOfRarity(r) == 0 and Config.RARITIES[r].order <= 4 then -- Mythic and Celestial are empty on purpose (weight 0 until a familiar uses them)
		warn("Config: no characters for rarity " .. r)
	end
end

return Config
