--!strict
-- Data tables for the run. Gameplay and UI both read from here.

local Config = {}

Config.START_COINS = 30
Config.START_GEMS = 60 -- was 30; the tutorial forces 3 rolls, so this stays 3 x ROLL_COST
Config.CRYSTAL_HP = 20
Config.TIER_MAX = 8 -- tiers 6 to 8 are the long game: tier t needs 3^(t-1) tier-1 units (2,187 for tier 8)
Config.TIER_MULT = 3.5
Config.ULT_NEED = 10
Config.ULT_DAMAGE = 60
Config.SPAWN_GAP = 0.45
Config.STAGE_BREAK = 1.2
Config.BOSS_EVERY = 5
Config.BOSS_TIME = 35
Config.OVERRUN_STAGE_LOSS = 2
Config.OVERRUN_COIN_LOSS = 0.3
Config.ROLL_COST = 20 -- was 10; 2026-10-29 tuning: with 16 familiars the full bot cleared 25 stages in 6 min, now a mean of 10.6 min over 10 seeds
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
	Mythic = { order = 5, color = Color3.fromRGB(255, 90, 170), odds = 0.4, mult = 30 }, -- no familiar yet: weight is 0 until one has this rarity
	Celestial = { order = 6, color = Color3.fromRGB(150, 245, 255), odds = 0.08, mult = 80 }, -- no familiar yet
}
Config.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Celestial" }

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
	Grunt = { hp = 30, speed = 8, coins = 2, gems = 1, leak = 1, size = 2.4, color = Color3.fromRGB(110, 100, 150), armor = "flesh" },
	Swift = { hp = 18, speed = 13, coins = 2, gems = 1, leak = 1, size = 2, color = Color3.fromRGB(160, 205, 235), armor = "fog" },
	Tank = { hp = 120, speed = 5, coins = 6, gems = 3, leak = 2, size = 3.6, color = Color3.fromRGB(176, 136, 72), armor = "brass" },
	Boss = { hp = 700, speed = 4, coins = 60, gems = 25, leak = 5, size = 6.5, color = Color3.fromRGB(140, 230, 110), armor = "none" },
	-- new kinds (Design/Enemy Bible.md); they appear in waves only when Config.NEW_ENEMIES is true (the client has no model for them yet)
	Crow = { hp = 12, speed = 16, coins = 3, gems = 1, leak = 1, size = 2.2, color = Color3.fromRGB(70, 74, 86), armor = "flesh" },
	Thief = { hp = 40, speed = 11, coins = 4, gems = 2, leak = 1, size = 2.4, color = Color3.fromRGB(104, 74, 118), armor = "flesh" },
	-- Hollow Court kinds (T417): they appear in waves only when Config.HOLLOW_ENEMIES is true (the client has no models for them yet)
	Parishioner = { hp = 70, speed = 7, coins = 4, gems = 2, leak = 1, size = 2.6, color = Color3.fromRGB(96, 90, 108), armor = "hollow" },
	FogWisp = { hp = 22, speed = 14, coins = 3, gems = 1, leak = 1, size = 2, color = Color3.fromRGB(170, 190, 210), armor = "fog", eatsLamp = true },
}
Config.HOLLOW_ENEMIES = false -- Hollow Parishioner and Fog Wisp in the wave lists; keep false until the client has models for both
Config.LAMP_EAT = { at = 0.4, snuffCooldown = 10, darkFor = 8 } -- a Fog Wisp past `at` of the path snuffs the Lantern (+snuffCooldown s to recharge) or, if it is ready, darkens it for darkFor s
Config.NEW_ENEMIES = true -- Clockwork Crow and Lantern Thief in the wave lists (needs client models first)
Config.MOVEMENT_EFFECTS = true -- slows, stuns, plants and speed-ups change enemy speed; the client moves enemies at a constant speed, so keep false until GameClient handles the "Pace" event {id, dist, speed, t}

-- Familiar roles, damage types, armour and statuses (Design/Familiar Systems.md, Design/Enemy Bible.md). Keys are the Characters folder ids.
Config.DAMAGE_TYPE = {
	Ember = "fire", Zap = "light", BrassHound = "spring", Sentinel = "brass", Frostling = "ice", Boulder = "stone",
	Ward = "light", Archivist = "brass", Mourner = "shadow", VoltFox = "cosmic", StarDrake = "cosmic", GreyVeilWraith = "shadow",
	CantorVesper = "cosmic", DameOrrery = "brass", TheLamplighter = "light", VeilWalker = "cosmic",
}
-- multiplier by armour type and damage type; anything not listed is 1
Config.ARMOR_MULT = {
	brass = { fire = 0.7, ice = 1.3 },
	fog = { stone = 0.7, light = 1.3 },
	flesh = { fire = 1.2 },
	stone = { spring = 0.7, cosmic = 1.3 },
	hollow = { light = 1.3, shadow = 0.75 },
}
Config.STATUS = {
	burn = { dur = 3, dps = 0.2 }, -- damage per second as a share of the hit that lit it
	chill = { dur = 2, max = 3, slow = 0.15, freeze = 0.5 }, -- 3 stacks freeze for 0.5 s (movement: needs MOVEMENT_EFFECTS)
	stun = { dur = 1, immune = 5 }, -- 5 s immunity afterwards
	mark = { dur = 4, bonus = 0.25 }, -- +25% damage from every source
	hush = { dur = 2 }, -- cancels the enemy's special move
}
-- roles: onHit statuses, every-Nth-shot bonuses, auras on touching units, armour piercing, echo and drain
Config.ROLES = {
	Ember = { onHit = { "burn" } },
	Zap = { onHit = { "mark" } },
	BrassHound = { nth = { n = 5, extraHit = true } },
	Sentinel = { pierce = { "brass" } },
	Frostling = { onHit = { "chill" } },
	Boulder = { critStun = true },
	Ward = { aura = { range = 0.2 } },
	Archivist = { aura = { haste = 0.15 } },
	Mourner = { onHit = { "hush" } },
	VoltFox = { echo = 0.35 },
	StarDrake = { nth = { n = 8, splash = { radius = 8, mult = 0.5 } } },
	GreyVeilWraith = { pierce = "all", drain = { every = 10, heal = 1 } },
	-- Mythic and Celestial humans: Hymn (touching familiars +20% damage), Rewind (every 10th shot resets touching cooldowns), Kindle (every familiar +10% damage), Veil (every familiar +12% crit chance)
	CantorVesper = { aura = { damage = 0.20 } },
	DameOrrery = { rewind = { every = 10 } },
	TheLamplighter = { global = { damage = 0.10 } },
	VeilWalker = { global = { crit = 0.12 } },
	-- Epic and Legendary humans (2026-10-29): Whistle, Annotate, Lockstep, Crossing
	ConstableWren = { nth = { n = 4, splash = { radius = 6, mult = 0.6 } } },
	MadamQuill = { onHit = { "mark", "hush" } },
	CogWarden = { critStun = true, nth = { n = 6, extraHit = true } },
	FerrymanOfFog = { onHit = { "chill", "mark" }, aura = { range = 0.15 } },
}

Config.HP_GROWTH = 1.27 -- enemy hp multiplier per stage (was 1.2; raised 2026-10-29: 1.25 gave a perfect bot 6 minutes, 1.3 made it fail or take 18 minutes)
function Config.hpScale(stage: number): number
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
Config.BOSSES = {
	{ id = "Unbound", name = "The Unbound", hpMult = 1.0, rewardMult = 1.0, phases = {
		{ at = 1, banner = "A bank of fog", fx = { deny = { every = 10, dur = 1.5 } } },
		{ at = 0.66, banner = "It rises", fx = { deny = { every = 6, dur = 1.5 } } },
		{ at = 0.33, banner = "The cloak falls", fx = { deny = { every = 6, dur = 1.5 }, speedMult = 1.2 } },
	} },
	{ id = "Automaton", name = "The Clockmaker's Automaton", hpMult = 1.3, rewardMult = 1.6, phases = {
		{ at = 1, banner = "The gears wind", fx = { slowAura = { radius = 12, slow = 0.15 }, regen = { every = 8, pct = 0.03 } } },
		{ at = 0.66, banner = "A bargain is offered", fx = { slowAura = { radius = 12, slow = 0.15 }, freeze = { every = 14, dur = 3 } } },
		{ at = 0.33, banner = "The gears overheat", fx = { slowAura = { radius = 12, slow = 0.25 }, speedMult = 1.15 } },
	} },
	{ id = "Echo", name = "The Star Choir's Echo", hpMult = 1.4, rewardMult = 2.0, phases = {
		{ at = 1, banner = "One voice", fx = { deny = { every = 9, dur = 2 } } },
		{ at = 0.66, banner = "The echoes answer", fx = { deny = { every = 9, dur = 2 }, summon = { every = 10, kind = "Swift", count = 2 } } },
		{ at = 0.33, banner = "A chord", fx = { slowAura = { radius = 10, slow = 0.25 }, summon = { every = 10, kind = "Swift", count = 2 } } },
	} },
	{ id = "Regent", name = "The Hollow Court Regent", hpMult = 1.3, rewardMult = 2.5, phases = {
		{ at = 1, banner = "The bell tolls", fx = { summon = { every = 12, kind = "Grunt", count = 3 } } },
		{ at = 0.66, banner = "The candles are lit", fx = { damageTaken = 0.85, summon = { every = 12, kind = "Grunt", count = 2 } } },
		{ at = 0.33, banner = "The crown burns down", fx = { speedMult = 2.0 } },
	} },
	{ id = "Clockmaker", name = "The Clockmaker", hpMult = 1.2, rewardMult = 4.0, phases = {
		{ at = 1, banner = "Behind its own clock", fx = { deny = { every = 12, dur = 2 } } },
		{ at = 0.66, banner = "Time stops", fx = { freeze = { every = 20, dur = 3 } } },
		{ at = 0.33, banner = "The hands run backwards", fx = { regen = { every = 6, pct = 0.02 }, speedMult = 1.1 } },
	} },
}
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
Config.ELITE = { first = 8, every = 4, max = 4, hp = 3, speed = 0.9, coins = 3, gems = 2 }
Config.MOD_FIRST = 4
Config.WAVE_MODIFIERS = {
	{ id = "Swarm", name = "Swarm", desc = "Many more, but frail", count = 1.4, hp = 0.8 },
	{ id = "Armoured", name = "Armoured", desc = "Tougher and slower", hp = 1.4, speed = 0.9 },
	{ id = "Rush", name = "Rush", desc = "Everyone runs", speed = 1.3 },
	{ id = "Sluggish", name = "Sluggish", desc = "Slow but sturdy", speed = 0.75, hp = 1.2 },
	{ id = "Plentiful", name = "Plentiful", desc = "More coins", coins = 1.5, hp = 1.2 },
	{ id = "Gemstorm", name = "Gemstorm", desc = "More gems", gems = 1.5, hp = 1.15 },
	{ id = "Frail", name = "Frail", desc = "Low hp, low pay", hp = 0.6, coins = 0.8 },
	{ id = "Giants", name = "Giants", desc = "Few, huge and rich", count = 0.6, hp = 1.8, speed = 0.8, coins = 1.5 },
	{ id = "Thinned", name = "Thinned", desc = "A short wave", count = 0.7 },
	{ id = "Mist", name = "Mist", desc = "Quicker and a little tougher", speed = 1.1, hp = 1.1 },
}
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

-- ===== Difficulty (T004): the server picks it; labels and numbers live here =====
-- hp scales enemy health, coins and gems scale kill rewards. Hard opens once the player has reached `unlockStage`. Changeable only at stage 1, before a wave.
Config.DIFFICULTY = {
	Normal = { label = "Normal", desc = "The intended challenge.", unlockStage = 1, hp = 1, coins = 1, gems = 1 },
	Hard = { label = "Hard", desc = "Tougher enemies, richer rewards.", unlockStage = 10, hp = 1.6, coins = 1.4, gems = 1.25 },
}
Config.DIFFICULTY_ORDER = { "Normal", "Hard" }
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

-- ===== Lantern power (T011): the player lights an area; familiars inside fire faster and harder for a while =====
Config.LANTERN = { radius = 22, dur = 6, cooldown = 30, haste = 0.35, damage = 0.1 }

-- ===== Faction adjacency combos (T012): data table of pairs; a familiar touching a partner gets the bonus once per entry =====
-- a and b are factions (Shared.Familiars). a == b needs two touching familiars of that faction. Bonuses are capped per familiar.
Config.SYNERGY_ON = true
Config.SYNERGIES = {
	{ id = "GuildGears", name = "Guild Gears", a = "Clockwork Guild", b = "Clockwork Guild", damage = 0.06 },
	{ id = "CourtVigil", name = "Court Vigil", a = "Hollow Court", b = "Hollow Court", haste = 0.06 },
	{ id = "KeepersFlame", name = "Keepers' Flame", a = "Lantern Keepers", b = "Lantern Keepers", damage = 0.04, haste = 0.04 },
	{ id = "ChoirHarmony", name = "Choir Harmony", a = "Star Choir", b = "Star Choir", damage = 0.08 },
	{ id = "LightAndSong", name = "Light and Song", a = "Lantern Keepers", b = "Star Choir", haste = 0.08 },
	{ id = "GearsAndLamps", name = "Gears and Lamps", a = "Clockwork Guild", b = "Lantern Keepers", damage = 0.05 },
}
Config.SYNERGY_CAP = { damage = 0.2, haste = 0.2 }

-- ===== Day, night and weather (T009): per-set windows are data in Shared.StageSets (`sky`); the effects are here, off by default =====
-- sky = { cycle = sim seconds per day, night = { from, to } as fractions of the cycle, weather = { { kind, at, dur } } } (at is a fraction, dur seconds).
-- An effect may hold enemySpeed (multiplier), range (added share of every familiar's range) and damage[damageType] (added share).
Config.SKY_ON = false
Config.SKY_EFFECTS = {
	night = { damage = { light = 0.2, shadow = 0.1 } },
	Fog = { enemySpeed = 0.92, range = -0.1 },
	Rain = { damage = { fire = -0.2 }, enemySpeed = 0.95 },
	Storm = { enemySpeed = 1.1, damage = { cosmic = 0.15 } },
	Embers = { damage = { fire = 0.2 }, enemySpeed = 1.05 },
}
local stageSetsMod: any = nil
function Config.skyFor(stage: number): any
	if stageSetsMod == nil then
		local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
		local m = script.Parent:FindFirstChild("StageSets") or (shared and shared:FindFirstChild("StageSets"))
		local ok, mod = pcall(function()
			return require(m :: ModuleScript)
		end)
		stageSetsMod = ok and mod or false
	end
	return stageSetsMod and stageSetsMod.forStage(stage).sky or nil
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
