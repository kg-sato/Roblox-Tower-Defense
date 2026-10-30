--!strict
-- Pure run simulation: no Instances, no remotes. The server runs it; tests drive it directly.
-- You cannot lose. If the crystal falls, the run is pushed back and you lose some coins and your streak.

local Config = require(script.Parent.Config)
local Path = require(script.Parent.Path)
-- pure rule modules (Gacha, Bond); a test that clones MatchSim alone finds them through ReplicatedStorage.Shared
local function sibling(name: string): any
	local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
	local mod = script.Parent:FindFirstChild(name) or (shared and shared:FindFirstChild(name))
	assert(mod, "Shared." .. name .. " is missing")
	return require(mod :: ModuleScript)
end
local Gacha = sibling("Gacha")
local Bond = sibling("Bond")

-- Units are keyed by id (the client still calls it "slot") and stand anywhere legal: see Config.canPlace.
export type Unit = { pet: string, tier: number, cd: number, x: number, z: number }
export type Enemy = { id: number, kind: string, hp: number, maxHp: number, dist: number, dead: boolean }

local MatchSim = {}
MatchSim.__index = MatchSim

-- the current phase's effects of a boss enemy (see Config.BOSSES), nil for other enemies
local function bossFx(e: any): any
	local b = e.boss
	return b and b.def.phases[b.phase].fx or nil
end

export type Sim = typeof(setmetatable({} :: {
	t: number,
	coins: number,
	gems: number,
	grid: { [number]: Unit },
	enemies: { Enemy },
	queue: { { at: number, kind: string, stage: number } },
	nextId: number,
	crystalHp: number,
	stage: number,
	bestStage: number, -- highest stage reached, saved in the profile
	state: string, -- "ready" (waiting for Start Wave or Auto) | "active"
	autoWave: boolean,
	breakClock: number,
	leaked: boolean,
	combo: number,
	ult: number,
	bossClock: number?,
	upgrades: { [string]: { [string]: number } },
	rolls: number,
	sincePity: number,
	gacha: any, -- Shared.Gacha state (floor counter, Lantern Oil), saved in the profile
	owned: { [string]: number }, -- copies pulled per familiar (profile collection counts plus this run), for the P7 bond bonus
	tutorial: boolean,
	paused: boolean,
	forced: { string },
	forcedSlots: { number },
	nextUnit: number,
	maxTier: number,
	upgradeCount: number,
	moves: number,
	xp: number,
	level: number,
	sp: number,
	tree: { [string]: number },
	leakCount: number,
	difficulty: string, -- Config.DIFFICULTY id (T004)
	userPaused: boolean, -- the player's pause (T006), separate from the tutorial's `paused`
	pauseLeft: number,
	lanternReady: number, -- sim time the Lantern can be lit again (T011)
	lanternUntil: number,
	lanternX: number,
	lanternZ: number,
	skyKey: string,
	rng: Random,
	emit: (string, any) -> (),
}, MatchSim))

function MatchSim.new(rng: Random, emit: (string, any) -> (), tutorial: boolean): Sim
	local upgrades = {}
	for id in Config.PETS do
		upgrades[id] = { Power = 0, Haste = 0, Crit = 0 }
	end
	local self = setmetatable({
		t = 0,
		coins = Config.START_COINS,
		gems = tutorial and Config.START_GEMS or Config.START_GEMS + 20,
		grid = {},
		enemies = {},
		queue = {},
		nextId = 1,
		crystalHp = Config.CRYSTAL_HP,
		stage = 1,
		bestStage = 1,
		state = "ready",
		autoWave = false,
		breakClock = 1.5,
		leaked = false,
		combo = 0,
		ult = 0,
		bossClock = nil,
		upgrades = upgrades,
		rolls = 0,
		sincePity = 0,
		gacha = Gacha.new(),
		owned = {},
		tutorial = tutorial,
		paused = tutorial,
		forced = tutorial and { "Ember", "Ember", "Ember" } or {},
		forcedSlots = tutorial and { 2, 3, 4 } or {}, -- old pad spots, used as tutorial positions
		nextUnit = 1,
		maxTier = 0,
		upgradeCount = 0,
		moves = 0,
		xp = 0,
		level = 1,
		sp = tutorial and 0 or 2,
		tree = { Start = 1 },
		leakCount = 0,
		difficulty = "Normal",
		userPaused = false,
		pauseLeft = 0,
		lanternReady = 0,
		lanternUntil = 0,
		lanternX = 0,
		lanternZ = 0,
		skyKey = "",
		rng = rng,
		emit = emit,
	}, MatchSim)
	return self
end

-- Total value of one skill-tree effect for this run.
function MatchSim.sv(self: Sim, kind: string): number
	return Config.skillValue(self.tree, kind)
end

-- Progress that carries between visits (what the server saves with ProfileStore).
function MatchSim.meta(self: Sim): { [string]: any }
	return { level = self.level, xp = self.xp, sp = self.sp, gems = self.gems, tree = table.clone(self.tree), bestStage = math.max(self.bestStage, self.stage), lastStage = self.stage, difficulty = self.difficulty, gacha = table.clone(self.gacha) }
end

-- Load saved progress, clamping every value so a corrupt or edited save can't give an impossible state.
-- Gems never drop below the starting amount, so a returning player can always roll.
function MatchSim.loadMeta(self: Sim, d: any)
	if type(d) ~= "table" then
		return
	end
	local function num(v: any, lo: number, hi: number, fallback: number): number
		if type(v) ~= "number" or v ~= v then
			return fallback
		end
		return math.clamp(math.floor(v), lo, hi)
	end
	self.level = num(d.level, 1, Config.LEVEL_MAX, 1)
	self.xp = num(d.xp, 0, 1e9, 0)
	self.sp = num(d.sp, 0, 1e6, 0)
	self.gems = math.max(self.gems, num(d.gems, 0, 1e9, 0))
	local tree = { Start = 1 }
	if type(d.tree) == "table" then
		for id, lvl in d.tree do
			local node = type(id) == "string" and Config.TREE_BY_ID[id]
			if node and id ~= "Start" and type(lvl) == "number" and lvl == lvl then
				tree[id] = math.clamp(math.floor(lvl), 0, node.max)
			end
		end
	end
	self.tree = tree
	-- stage progress (T411): the best stage can never be below the last one; the run itself still starts at stage 1
	self.bestStage = math.max(num(d.bestStage, 1, 1000, 1), num(d.lastStage, 1, 1000, 1))
	-- difficulty (T004): only a known id the saved progress has unlocked
	local diff = type(d.difficulty) == "string" and Config.DIFFICULTY[d.difficulty] or nil
	self.difficulty = (diff and self.bestStage >= diff.unlockStage) and d.difficulty or "Normal"
	self.gacha = Gacha.load(d.gacha)
	self.owned = {}
	if type(d.collection) == "table" then
		for id, e in d.collection do
			if type(id) == "string" and Config.PETS[id] and type(e) == "table" and type(e.count) == "number" and e.count == e.count then
				self.owned[id] = math.clamp(math.floor(e.count), 0, Config.COLLECTION_MAX)
			end
		end
	end
end

-- Pick the difficulty (T004). Only before the first wave of a run (stage 1, ready), never in the tutorial, and only once unlocked by bestStage.
function MatchSim.setDifficulty(self: Sim, id: any): (boolean, string?)
	local def = type(id) == "string" and Config.DIFFICULTY[id] or nil
	if not def then
		return false, "Bad difficulty"
	end
	if self.tutorial then
		return false, "Not in the tutorial"
	end
	if self.state ~= "ready" or self.stage ~= 1 or #self.enemies > 0 or #self.queue > 0 then
		return false, "Change it before the first wave"
	end
	if self.bestStage < def.unlockStage then
		return false, def.label .. " unlocks at stage " .. def.unlockStage
	end
	self.difficulty = id
	self.emit("Difficulty", { id = id, label = def.label })
	return true, nil
end

-- Pause and resume (T006). The pause belongs to the run and is capped at Config.PAUSE_MAX real seconds (tickPause); boss clocks and cooldowns stand still while it lasts.
function MatchSim.pause(self: Sim, on: any): (boolean, string?)
	if type(on) ~= "boolean" then
		return false, "Bad value"
	end
	if self.tutorial then
		return false, "Not in the tutorial"
	end
	if on and not self.userPaused then
		self.userPaused, self.pauseLeft = true, Config.PAUSE_MAX
		self.emit("Pause", { on = true, left = self.pauseLeft })
	elseif not on and self.userPaused then
		self.userPaused, self.pauseLeft = false, 0
		self.emit("Pause", { on = false })
	end
	return true, nil
end

-- Counts a pause down in real seconds (the server calls it every frame while paused); at zero the run resumes.
function MatchSim.tickPause(self: Sim, dt: number)
	if self.userPaused then
		self.pauseLeft -= dt
		if self.pauseLeft <= 0 then
			self.userPaused, self.pauseLeft = false, 0
			self.emit("Pause", { on = false, auto = true })
		end
	end
end

-- The run as a plain table (what a run save would hold) and its clamped re-load. A loaded run starts paused so the player can look first.
function MatchSim.exportRun(self: Sim): { [string]: any }
	local grid, ups = {}, {}
	for id, u in self.grid do
		grid[tostring(id)] = { pet = u.pet, tier = u.tier, x = u.x, z = u.z }
	end
	for pet, t in self.upgrades do
		ups[pet] = { Power = t.Power, Haste = t.Haste, Crit = t.Crit }
	end
	return { stage = self.stage, coins = self.coins, crystal = self.crystalHp, combo = self.combo, difficulty = self.difficulty, userPaused = self.userPaused, pauseLeft = self.pauseLeft, grid = grid, upgrades = ups, nextUnit = self.nextUnit }
end

function MatchSim.importRun(self: Sim, d: any): boolean
	if type(d) ~= "table" or self.tutorial then
		return false
	end
	local function num(v: any, lo: number, hi: number, fallback: number): number
		if type(v) ~= "number" or v ~= v then
			return fallback
		end
		return math.clamp(math.floor(v), lo, hi)
	end
	self.stage = num(d.stage, 1, 1000, 1)
	self.bestStage = math.max(self.bestStage, self.stage)
	self.coins = num(d.coins, 0, 1e12, self.coins)
	self.crystalHp = num(d.crystal, 1, self:maxHp(), self:maxHp())
	self.combo = num(d.combo, 0, 1000, 0)
	local diff = type(d.difficulty) == "string" and Config.DIFFICULTY[d.difficulty] or nil
	self.difficulty = (diff and self.bestStage >= diff.unlockStage) and d.difficulty or "Normal"
	self.grid, self.nextUnit = {}, 1
	if type(d.grid) == "table" then
		for _, u in d.grid do
			if type(u) == "table" and type(u.pet) == "string" and Config.PETS[u.pet] and type(u.x) == "number" and type(u.z) == "number" and self:unitCount() < Config.MAX_UNITS then
				if Config.canPlace(self.grid, u.pet, u.x, u.z, nil, Config.mapRules(self.stage)) then
					local id = self:addUnit(u.pet, u.x, u.z)
					self.grid[id].tier = num(u.tier, 1, Config.TIER_MAX, 1)
				end
			end
		end
	end
	if type(d.upgrades) == "table" then
		for pet, t in d.upgrades do
			if self.upgrades[pet] and type(t) == "table" then
				for kind in self.upgrades[pet] do
					self.upgrades[pet][kind] = num(t[kind], 0, Config.UPGRADE_MAX, 0)
				end
			end
		end
	end
	self.state, self.enemies, self.queue = "ready", {}, {}
	self.userPaused, self.pauseLeft = true, Config.PAUSE_MAX
	return true
end

function MatchSim.maxHp(self: Sim): number
	return Config.CRYSTAL_HP + self:sv("crystal")
end

function MatchSim.ultNeed(self: Sim): number
	return math.max(4, Config.ULT_NEED - self:sv("ultNeed"))
end

function MatchSim.rollCost(self: Sim): number
	return math.max(5, Config.ROLL_COST - self:sv("rollDiscount"))
end

function MatchSim.pityEvery(self: Sim): number
	return math.max(8, Config.PITY_EVERY - self:sv("pity"))
end

function MatchSim.luck(self: Sim): number
	return math.min(0.8, Config.luck(self.level) + self:sv("luck"))
end

-- Buy one level of a skill-tree node. Needs Skill Points and an owned neighbour.
function MatchSim.skill(self: Sim, id: any): (boolean, string?)
	if type(id) ~= "string" then
		return false, "Bad skill"
	end
	local node = Config.TREE_BY_ID[id]
	if not node or id == "Start" then
		return false, "Bad skill"
	end
	local level = self.tree[id] or 0
	if level >= node.max then
		return false, "Maxed"
	end
	local reachable = false
	for _, n in Config.TREE_NEIGHBORS[id] do
		if (self.tree[n] or 0) > 0 then
			reachable = true
			break
		end
	end
	if not reachable then
		return false, "Unlock a neighbouring skill first"
	end
	local cost = Config.skillCost(node, level)
	if self.sp < cost then
		return false, "Not enough skill points"
	end
	self.sp -= cost
	self.tree[id] = level + 1
	self.emit("SkillBought", { id = id, level = level + 1 })
	return true, nil
end

-- Reset the skill tree: every point spent comes back as Skill Points, for a gem fee and a cooldown (T198).
-- The cooldown counts sim seconds within one run (it is not saved between runs); nothing is refunded for nodes that no longer exist.
function MatchSim.respec(self: Sim): (boolean, string?)
	local spent = 0
	for id, level in self.tree do
		local node = Config.TREE_BY_ID[id]
		if node and id ~= "Start" then
			for l = 0, level - 1 do
				spent += Config.skillCost(node, l)
			end
		end
	end
	if spent == 0 then
		return false, "Nothing to refund"
	end
	if self.t - ((self :: any).lastRespec or -1e9) < Config.RESPEC_COOLDOWN then
		return false, "Respec is cooling down"
	end
	if self.gems < Config.RESPEC_COST then
		return false, "Not enough gems"
	end
	self.gems -= Config.RESPEC_COST
	self.sp += spent
	self.tree = { Start = 1 }
	;(self :: any).lastRespec = self.t
	self.crystalHp = math.min(self.crystalHp, self:maxHp()) -- Crystal Armor may have been refunded
	self.emit("Respec", { refunded = spent, cost = Config.RESPEC_COST })
	return true, nil
end

-- Lantern power (T011): the player lights a spot; familiars inside Config.LANTERN.radius fire faster and harder for Config.LANTERN.dur sim seconds, then it recharges.
function MatchSim.lantern(self: Sim, x: any, z: any): (boolean, string?)
	if self.tutorial then
		return false, "Not in the tutorial"
	end
	if type(x) ~= "number" or type(z) ~= "number" or x ~= x or z ~= z then
		return false, "Bad position"
	end
	if self.t < self.lanternReady then
		return false, "The Lantern is recharging"
	end
	local L, b = Config.LANTERN, Config.PLACE_BOUNDS
	self.lanternX, self.lanternZ = math.clamp(x, b.minX, b.maxX), math.clamp(z, b.minZ, b.maxZ)
	self.lanternUntil = self.t + L.dur
	self.lanternReady = self.t + L.cooldown
	self.emit("Lantern", { x = self.lanternX, z = self.lanternZ, radius = L.radius, dur = L.dur, cooldown = L.cooldown })
	return true, nil
end

-- (damage share, haste share) a unit gets from the lit Lantern
function MatchSim.lanternBonus(self: Sim, u: any): (number, number)
	if self.t >= self.lanternUntil then
		return 0, 0
	end
	local L = Config.LANTERN
	local dx, dz = u.x - self.lanternX, u.z - self.lanternZ
	if dx * dx + dz * dz <= L.radius * L.radius then
		return L.damage, L.haste
	end
	return 0, 0
end

-- A Fog Wisp reached its lamp-eating point (T417): it snuffs a lit Lantern, or darkens a ready one for a while.
function MatchSim.eatLamp(self: Sim, e: any)
	local L = Config.LAMP_EAT
	if self.t < self.lanternUntil then
		self.lanternUntil = self.t
		self.lanternReady = math.max(self.lanternReady, self.t) + L.snuffCooldown
		self.emit("LampEaten", { id = e.id, how = "snuffed" })
	elseif self.t >= self.lanternReady then
		self.lanternReady = self.t + L.darkFor
		self.emit("LampEaten", { id = e.id, how = "darkened" })
	end
end

-- Faction combo (T012): (damage share, haste share) from touching familiars whose factions pair up in Config.SYNERGIES; each entry counts once.
function MatchSim.synergy(self: Sim, u: any): (number, number)
	if not Config.SYNERGY_ON then
		return 0, 0
	end
	local def = Config.PETS[u.pet]
	local fa = def and def.faction
	if not fa then
		return 0, 0
	end
	local near = self:neighbours(u)
	local d, h = 0, 0
	for _, s in Config.SYNERGIES do
		local partner = (fa == s.a and s.b) or (fa == s.b and s.a) or nil
		if partner then
			for _, o in near do
				local od = Config.PETS[o.pet]
				if od and od.faction == partner then
					d += s.damage or 0
					h += s.haste or 0
					break
				end
			end
		end
	end
	return math.min(d, Config.SYNERGY_CAP.damage), math.min(h, Config.SYNERGY_CAP.haste)
end

-- A merge needs two matching pets that touch plus a third matching pet dragged onto one of them.
-- Dragging a onto b is valid if a third pet touches b, or a touches b and the third touches a.
-- "Touching" = footprints within Config.TOUCH_GAP of each other (Config.touching).
function MatchSim.findThird(grid: any, a: number, b: number): number?
	local ua, ub = grid[a], grid[b]
	if not ua or not ub or a == b or ua.pet ~= ub.pet or ua.tier ~= ub.tier or not ua.x or not ub.x then
		return nil
	end
	for i, u in grid do
		if i ~= a and i ~= b and u.pet == ub.pet and u.tier == ub.tier and u.x then
			if Config.touching(u, ub) or (Config.touching(ua, ub) and Config.touching(u, ua)) then
				return i
			end
		end
	end
	return nil
end

function MatchSim.unitCount(self: Sim): number
	local n = 0
	for _ in self.grid do
		n += 1
	end
	return n
end

-- A free legal spot for a new pet: the old pad spots first (in random order), then a scan of the street.
function MatchSim.findSpot(self: Sim, pet: string): (number?, number?)
	local order = {}
	for i = 1, #Config.SLOTS do
		table.insert(order, i)
	end
	for i = #order, 2, -1 do
		local j = self.rng:NextInteger(1, i)
		order[i], order[j] = order[j], order[i]
	end
	local rules = Config.mapRules(self.stage)
	for _, i in order do
		local p = Config.SLOTS[i]
		if Config.canPlace(self.grid, pet, p.X, p.Z, nil, rules) then
			return p.X, p.Z
		end
	end
	local b = rules and rules.bounds or Config.PLACE_BOUNDS
	local bestX, bestZ, bestD = nil, nil, math.huge
	for x = b.minX + 2, b.maxX - 2, 3 do
		for z = b.minZ + 2, b.maxZ - 2, 3 do
			if Config.canPlace(self.grid, pet, x, z, nil, rules) then
				local d = x * x + (z + 8) * (z + 8) -- prefer spots near the middle of the board
				if d < bestD then
					bestX, bestZ, bestD = x, z, d
				end
			end
		end
	end
	return bestX, bestZ
end

function MatchSim.addUnit(self: Sim, pet: string, x: number, z: number): number
	local id = self.nextUnit
	self.nextUnit += 1
	self.grid[id] = { pet = pet, tier = 1, cd = 0.3, x = x, z = z }
	return id
end

-- Rarity pick. Pity forces Epic or better so a long dry streak always ends.
function MatchSim.pickRarity(self: Sim): string
	if self.sincePity >= self:pityEvery() - 1 then
		local e, l = Config.RARITIES.Epic.odds, Config.RARITIES.Legendary.odds
		return self.rng:NextNumber() * (e + l) < l and "Legendary" or "Epic"
	end
	local weights = Config.rarityWeights(self:luck())
	local total = 0
	for _, r in Config.RARITY_ORDER do
		total += weights[r]
	end
	local roll = self.rng:NextNumber() * total
	for _, r in Config.RARITY_ORDER do
		roll -= weights[r]
		if roll < 0 then
			return r
		end
	end
	return "Common"
end

-- A random pet of this rarity; an empty rarity (its Characters folders removed) steps down to the next lower one.
function MatchSim.pickPet(self: Sim, rarity: string): (string?, string)
	local at = table.find(Config.RARITY_ORDER, rarity) or 1
	for i = at, 1, -1 do
		local list = Config.petsOfRarity(Config.RARITY_ORDER[i])
		if #list > 0 then
			return list[self.rng:NextInteger(1, #list)], Config.RARITY_ORDER[i]
		end
	end
	return nil, rarity
end

function MatchSim.roll(self: Sim): (boolean, string?)
	if self:unitCount() >= Config.MAX_UNITS then
		return false, "Too many pets (max " .. Config.MAX_UNITS .. ")"
	end
	if self.gems < self:rollCost() then
		return false, "Not enough gems"
	end
	local pet, rarity, x, z
	local floored = false
	if self.tutorial and #self.forced > 0 then
		pet = self.forced[1]
		rarity = Config.PETS[pet].rarity
		local p = Config.SLOTS[self.forcedSlots[1]]
		if p and Config.canPlace(self.grid, pet, p.X, p.Z, nil, Config.mapRules(self.stage)) then
			x, z = p.X, p.Z
		else
			x, z = self:findSpot(pet)
		end
	else
		rarity = self:pickRarity()
		if Config.P3_ROLL_FLOOR and not self.tutorial and Gacha.floorDue(self.gacha) and Config.RARITIES[rarity].order < 2 then
			-- P3: the 10th roll without a Rare or better is a Rare or better (picked by the same luck-weighted odds)
			local names = {}
			for _, r in Config.RARITY_ORDER do
				if Config.RARITIES[r].order >= 2 then
					table.insert(names, r)
				end
			end
			rarity = Gacha.weightedPick(Config.rarityWeights(self:luck()), names, self.rng:NextNumber())
			floored = true
		end
		pet, rarity = self:pickPet(rarity)
		if not pet then
			return false, "No characters configured"
		end
		x, z = self:findSpot(pet)
	end
	if not x or not z then
		return false, "No room left on the street"
	end
	if self.tutorial and #self.forced > 0 then
		table.remove(self.forced, 1)
		table.remove(self.forcedSlots, 1)
	end
	self.gems -= self:rollCost()
	self.rolls += 1
	self.sincePity = Config.RARITIES[rarity].order >= 3 and 0 or self.sincePity + 1
	local id = self:addUnit(pet :: string, x, z)
	self.maxTier = math.max(self.maxTier, 1)
	local dupeGems = self:countCopy(pet :: string)
	if not self.tutorial then
		Gacha.afterRoll(self.gacha, Config.RARITIES[rarity].order, Config.P3_ROLL_FLOOR, Config.P2_CHOSEN_GUARANTEE)
	end
	self.emit("Roll", { slot = id, pet = pet, rarity = rarity, x = x, z = z, floored = floored or nil, dupeGems = dupeGems > 0 and dupeGems or nil })
	-- Double Hatch: a free bonus pet
	local chance = self:sv("doubleHatch")
	if chance > 0 and not self.tutorial and self.rng:NextNumber() < chance and self:unitCount() < Config.MAX_UNITS then
		local bonusPet, bonusRarity = self:pickPet(self:pickRarity())
		local bx, bz
		if bonusPet then
			bx, bz = self:findSpot(bonusPet)
		end
		if bx and bz then
			local bid = self:addUnit(bonusPet :: string, bx, bz)
			local bonusGems = self:countCopy(bonusPet :: string)
			self.emit("Roll", { slot = bid, pet = bonusPet, rarity = bonusRarity, bonus = true, x = bx, z = bz, dupeGems = bonusGems > 0 and bonusGems or nil })
		end
	end
	return true, nil
end

-- Counts one pulled copy of a familiar (not in the tutorial, which never touches the collection). With P7 on, a copy past the last bond step pays gems; returns the gems paid.
function MatchSim.countCopy(self: Sim, pet: string): number
	if self.tutorial then
		return 0
	end
	local before = self.owned[pet] or 0
	self.owned[pet] = math.min(before + 1, Config.COLLECTION_MAX)
	if Config.P7_DUPE_BOND and before >= 1 and Bond.dupeSurplus(before - 1) then
		self.gems += Bond.DUPE_SURPLUS_GEMS
		return Bond.DUPE_SURPLUS_GEMS
	end
	return 0
end

-- Permanent damage fraction from extra copies of this familiar (P7_DUPE_BOND; 0 when off).
function MatchSim.dupePower(self: Sim, pet: string): number
	if not Config.P7_DUPE_BOND then
		return 0
	end
	return Bond.dupePower(math.max(0, (self.owned[pet] or 0) - 1))
end

-- P2: spend 100 Lantern Oil on one chosen familiar of Rare or better. Nothing is spent unless the familiar can be placed.
function MatchSim.claimGuarantee(self: Sim, pet: any): (boolean, string?)
	if not Config.P2_CHOSEN_GUARANTEE then
		return false, "Not available"
	end
	if self.tutorial then
		return false, "Not in the tutorial"
	end
	local def = type(pet) == "string" and Config.PETS[pet] or nil
	if not def or Config.RARITIES[def.rarity].order < Gacha.MIN_CLAIM_ORDER then
		return false, "Pick a Rare or better familiar"
	end
	if not Gacha.canClaim(self.gacha) then
		return false, "Not enough Lantern Oil"
	end
	if self:unitCount() >= Config.MAX_UNITS then
		return false, "Too many pets (max " .. Config.MAX_UNITS .. ")"
	end
	local x, z = self:findSpot(pet :: string)
	if not x or not z then
		return false, "No room left on the street"
	end
	Gacha.spend(self.gacha)
	local id = self:addUnit(pet :: string, x, z)
	self.maxTier = math.max(self.maxTier, 1)
	local gems = self:countCopy(pet :: string)
	-- bonus = true keeps it out of the roll counters and the shared Legendary banner; chosen = true lets the client stage it
	self.emit("Roll", { slot = id, pet = pet, rarity = def.rarity, x = x, z = z, bonus = true, chosen = true, dupeGems = gems > 0 and gems or nil })
	return true, nil
end

-- Gacha data for the client: floor counter, Lantern Oil, and (P7) the bond bonus of every familiar owned.
function MatchSim.gachaSnapshot(self: Sim): { [string]: any }
	local g = Gacha.snapshot(self.gacha, Config.P3_ROLL_FLOOR, Config.P2_CHOSEN_GUARANTEE)
	g.dupeOn = Config.P7_DUPE_BOND
	if Config.P7_DUPE_BOND then
		local dupes = {}
		for pet, n in self.owned do
			local extra = math.max(0, n - 1)
			dupes[pet] = { copies = n, step = Bond.dupeStep(extra), power = Bond.dupePower(extra), nextAt = Bond.dupeNext(extra) }
		end
		g.dupes = dupes
	end
	return g
end

-- Move a pet to any legal spot on the street.
function MatchSim.move(self: Sim, id: number, x: number, z: number): (boolean, string?)
	local u = self.grid[id]
	if not u then
		return false, "Pick a pet"
	end
	local ok, reason = Config.canPlace(self.grid, u.pet, x, z, id, Config.mapRules(self.stage))
	if not ok then
		return false, reason
	end
	u.x, u.z = x, z
	self.moves += 1
	self.emit("Move", { id = id, x = x, z = z })
	return true, nil
end

function MatchSim.merge(self: Sim, a: number, b: number): (boolean, string?)
	local ua, ub = self.grid[a], self.grid[b]
	if a == b or not ua or not ub then
		return false, "Pick two pets"
	end
	if ua.pet ~= ub.pet or ua.tier ~= ub.tier then
		return false, "Must match"
	end
	if ub.tier >= Config.TIER_MAX then
		return false, "Max tier"
	end
	local c = MatchSim.findThird(self.grid, a, b)
	if not c then
		return false, "Drop on a touching pair"
	end
	self.grid[a] = nil
	self.grid[c] = nil
	ub.tier += 1
	self.maxTier = math.max(self.maxTier, ub.tier)
	local coins = math.floor(5 * ub.tier * self:sv("merge"))
	self.coins += coins
	self.emit("Merge", { from = { a, c }, to = b, tier = ub.tier, pet = ub.pet, coins = coins })
	return true, nil
end

-- Drop a pet onto another pet: same pet+tier = merge (needs a touching third); anything else is refused.
-- Moving to empty ground is MatchSim.move.
function MatchSim.drop(self: Sim, a: number, b: number): (boolean, string?)
	local ua, ub = self.grid[a], self.grid[b]
	if a == b or not ua or not ub then
		return false, "Pick a pet"
	end
	if ua.pet == ub.pet and ua.tier == ub.tier then
		return self:merge(a, b)
	end
	return false, "Only matching pets merge"
end

-- Recycle a pet for coins so a full grid of mismatches never soft-locks rolling.
function MatchSim.recycle(self: Sim, slot: number): (boolean, string?)
	local u = self.grid[slot]
	if not u then
		return false, "Pick a pet"
	end
	local def = Config.PETS[u.pet]
	local coins = Config.recycleValue(u.pet, u.tier)
	self.grid[slot] = nil
	self.coins += coins
	self.emit("Recycle", { slot = slot, coins = coins })
	return true, nil
end

function MatchSim.upgradeCostFor(self: Sim, pet: string, kind: string): number
	return Config.upgradeCost(self.upgrades[pet][kind])
end

function MatchSim.upgrade(self: Sim, pet: any, kind: any): (boolean, string?)
	if type(pet) ~= "string" or type(kind) ~= "string" or not Config.PETS[pet] or not Config.UPGRADES[kind] then
		return false, "Bad upgrade"
	end
	local owned = false
	for _, u in self.grid do
		if u.pet == pet then
			owned = true
			break
		end
	end
	if not owned then
		return false, "Place one first"
	end
	local level = self.upgrades[pet][kind]
	if level >= Config.UPGRADE_MAX then
		return false, "Maxed"
	end
	local cost = Config.upgradeCost(level)
	if self.coins < cost then
		return false, "Not enough coins"
	end
	self.coins -= cost
	self.upgrades[pet][kind] = level + 1
	self.upgradeCount += 1
	self.emit("Upgrade", { pet = pet, kind = kind, level = level + 1 })
	return true, nil
end

function MatchSim.castUlt(self: Sim): (boolean, string?)
	if self.ult < self:ultNeed() then
		return false, "Not charged"
	end
	self.ult = math.min(self:ultNeed() - 1, self:sv("ultRefund"))
	-- a featured familiar on the board performs its signature instead (highest tier, then rarity)
	local caster, best = nil, -1
	for id, u in self.grid do
		local def = Config.PETS[u.pet]
		if def and def.signature then
			local score = u.tier * 10 + Config.RARITIES[def.rarity].order
			if score > best then
				caster, best = id, score
			end
		end
	end
	local power = 1
	if caster then
		local def = Config.PETS[self.grid[caster].pet]
		power = def.signaturePower
		self.emit("Ult", { signature = def.signature, slot = caster, pet = self.grid[caster].pet })
	else
		self.emit("Ult", {})
	end
	local dmg = Config.ULT_DAMAGE * Config.hpScale(self.stage) * (1 + self:sv("ultDamage")) * power
	for _, e in self.enemies do
		if not e.dead then
			self:damage(e, dmg, false)
		end
	end
	self:cleanup()
	return true, nil
end

function MatchSim.damage(self: Sim, e: Enemy, amount: number, chargeUlt: boolean)
	local bossFxNow = bossFx(e)
	if bossFxNow and bossFxNow.candles and Config.BOSS_V2 then
		-- candles (T416): each lit candle takes off a share, a slain mourner snuffs one
		amount *= math.max(bossFxNow.candles.min, 1 - (e :: any).boss.lit * bossFxNow.candles.per)
	elseif bossFxNow and bossFxNow.damageTaken then
		amount *= bossFxNow.damageTaken
	end
	e.hp -= amount
	if (e :: any).boss and e.hp > 0 then
		self:checkPhase(e)
	end
	if e.hp <= 0 and not e.dead then
		e.dead = true
		local def = Config.ENEMIES[e.kind]
		local rewardMult = (e :: any).boss and (e :: any).boss.def.rewardMult or 1
		local diff = Config.difficulty(self.difficulty)
		local coins = math.floor(def.coins * rewardMult * (1 + 0.1 * (self.stage - 1)) * (1 + self:sv("coins")) * diff.coins * ((e :: any).coinMult or 1) + 0.5)
		local gems = math.floor(def.gems * rewardMult * Config.comboMult(self.combo) * (1 + self:sv("gems")) * diff.gems * ((e :: any).gemMult or 1) + 0.5)
		if (e :: any).carrying then
			self.coins += 10 -- the stolen light drops as coins
			self.emit("Drop", { id = e.id, coins = 10 })
		end
		if (e :: any).mourner then
			for _, o in self.enemies do
				local ob = (o :: any).boss
				if ob and not o.dead and ob.lit and ob.lit > 0 then
					ob.lit -= 1
					self.emit("BossFx", { id = o.id, kind = "snuff", lit = ob.lit })
					break
				end
			end
		end
		local perched = (e :: any).perched
		if perched and self.grid[perched] then
			(self.grid[perched] :: any).disabledUntil = 0 -- the perched familiar is free again
		end
		local sp = 0
		if e.kind == "Boss" then
			sp = 1
			self.sp += 1
		end
		self.coins += coins
		self.gems += gems
		if chargeUlt then
			self.ult = math.min(self:ultNeed(), self.ult + 1)
		end
		self.emit("Kill", { id = e.id, kind = e.kind, coins = coins, gems = gems, sp = sp })
		self:addXp(def.coins)
	end
end

function MatchSim.addXp(self: Sim, amount: number)
	if self.level >= Config.LEVEL_MAX then
		return
	end
	amount = math.floor(amount * (1 + self:sv("xp")) + 0.5)
	self.xp += amount
	while self.level < Config.LEVEL_MAX and self.xp >= Config.xpNeed(self.level) do
		self.xp -= Config.xpNeed(self.level)
		self.level += 1
		local gems = Config.levelGems(self.level)
		self.gems += gems
		self.sp += 1
		self.emit("LevelUp", { level = self.level, gems = gems, luck = Config.luck(self.level) })
	end
end

function MatchSim.cleanup(self: Sim)
	local alive = {}
	for _, e in self.enemies do
		if not e.dead then
			table.insert(alive, e)
		end
	end
	self.enemies = alive
end

function MatchSim.startStage(self: Sim)
	self.state = "active"
	self.leaked = false
	self.leakCount = 0
	local list = Config.stageSpawns(self.stage)
	local v2 = Config.WAVES_V2
	local elites = v2 and Config.stageElites(self.stage, list) or {}
	local mod = v2 and Config.waveModifier(self.stage) or nil
	local eliteCount = 0
	for i, kind in list do
		local q: any = { at = self.t + (i - 1) * Config.SPAWN_GAP, kind = kind, stage = self.stage }
		if elites[i] then
			q.elite, eliteCount = true, eliteCount + 1
		end
		if mod then
			q.mod = mod.id
		end
		table.insert(self.queue, q)
	end
	-- fences and gates (T157): a fresh copy per stage; the lane position is a fraction of Path.length
	local blockers = Config.blockersFor(self.stage)
	for _, b in blockers do
		b.D, b.t0, b.closedNow = b.at * Path.length, self.t, false
		if b.kind == "fence" then
			b.hp = b.hp or 50
		end
	end
	;(self :: any).blockers = blockers
	if #blockers > 0 then
		local info = {}
		for _, b in blockers do
			table.insert(info, { id = b.id, kind = b.kind, at = b.at })
		end
		self.emit("Blockers", { stage = self.stage, list = info })
	end
	self.emit("Stage", { stage = self.stage, boss = Config.isBossStage(self.stage), combo = self.combo, mod = mod and mod.id or nil, modName = mod and mod.name or nil, elites = eliteCount })
end

-- The crystal fell: pushed back, not out.
function MatchSim.overrun(self: Sim)
	local lost = math.floor(self.coins * Config.OVERRUN_COIN_LOSS)
	self.coins -= lost
	self.stage = math.max(1, self.stage - Config.OVERRUN_STAGE_LOSS)
	self.combo = 0
	self.crystalHp = self:maxHp()
	self.enemies = {}
	self.queue = {}
	self.bossClock = nil
	self.state = "ready"
	self.breakClock = 2.5
	self.emit("Overrun", { stage = self.stage, lostCoins = lost })
end

function MatchSim.bossEscaped(self: Sim)
	self.stage = math.max(1, self.stage - 1)
	self.combo = 0
	self.enemies = {}
	self.queue = {}
	self.bossClock = nil
	self.state = "ready"
	self.breakClock = 2.5
	self.emit("BossEscaped", { stage = self.stage })
end

function MatchSim.clearStage(self: Sim)
	local perfect = not self.leaked
	if perfect then
		self.combo += 1
	end
	local bonus = math.floor(3 * Config.comboMult(self.combo) + 0.5)
	self.gems += bonus
	self.crystalHp = math.min(self:maxHp(), self.crystalHp + 2)
	self.emit("Clear", { stage = self.stage, perfect = perfect, bonus = bonus, combo = self.combo })
	self:addXp(8 + 2 * self.stage)
	self.stage += 1
	self.bestStage = math.max(self.bestStage, self.stage)
	self.state = "ready"
	self.breakClock = Config.STAGE_BREAK
	self.bossClock = nil
end

function MatchSim.startWave(self: Sim): (boolean, string?)
	if self.state ~= "ready" then
		return false, "Wave already running"
	end
	self.paused = false
	self:startStage()
	return true, nil
end

function MatchSim.setAuto(self: Sim, on: any): (boolean, string?)
	if type(on) ~= "boolean" then
		return false, "Bad value"
	end
	self.autoWave = on
	self.breakClock = Config.STAGE_BREAK
	return true, nil
end

function MatchSim.resume(self: Sim)
	self.paused = false
end

function MatchSim.endTutorial(self: Sim)
	if self.tutorial then
		self.tutorial = false
		self.gems += 50
		self.sp += 2
		self.emit("TutorialDone", { gems = 50, sp = 2 })
	end
end

-- ===== Statuses, roles and enemy behaviour (Design/Familiar Systems.md, Design/Enemy Bible.md) =====
-- Server-only and data-driven (Config.STATUS, Config.ROLES, Config.ARMOR_MULT). Movement effects (slow, stun, freeze, plant, thief speed-up) only change
-- enemy speed when Config.MOVEMENT_EFFECTS is true, because the client moves enemies at constant speed; they emit "Pace" {id, dist, speed, t} then.

local function hasStatus(e: any, kind: string, t: number): boolean
	local st = e.status and e.status[kind]
	return st ~= nil and st.untilT > t
end

function MatchSim.applyStatus(self: Sim, e: any, kind: string, power: number?)
	local def = Config.STATUS[kind]
	if not def or e.dead then
		return
	end
	e.status = e.status or {}
	if (kind == "chill" or kind == "stun") and e.plant then
		return -- planted enemies shrug off slows and stuns
	end
	if kind == "stun" and (e.stunImmune or 0) > self.t then
		return
	end
	local dur = def.dur * (e.kind == "Boss" and 0.5 or 1)
	local st = e.status[kind]
	if not st then
		st = { stacks = 0, untilT = 0 }
		e.status[kind] = st
	end
	st.untilT = self.t + dur
	if kind == "chill" then
		st.stacks = math.min(def.max, st.stacks + 1)
		if st.stacks >= def.max and e.kind ~= "Boss" then
			e.status.freeze = { stacks = 1, untilT = self.t + def.freeze }
			st.stacks = 0
		end
	elseif kind == "burn" then
		st.dps = math.max(st.dps or 0, (power or 0) * def.dps)
		st.stacks = 1
	else
		st.stacks = 1
	end
	if kind == "stun" then
		e.stunImmune = self.t + dur + def.immune
	end
	if kind == "hush" then
		e.telegraph, e.plant, e.plantTimer = nil, nil, 4
	end
	self.emit("Status", { id = e.id, kind = kind, dur = dur, stacks = st.stacks })
end

function MatchSim.neighbours(self: Sim, u: any): { any }
	local list = {}
	for _, o in self.grid do
		if o ~= u and Config.touching(u, o) then
			table.insert(list, o)
		end
	end
	return list
end

-- aura multipliers from touching familiars: range (Ward) and attack speed (Archivist)
function MatchSim.auras(self: Sim, u: any): (number, number, number)
	local range, haste, damage = 0, 0, 0
	for _, o in self:neighbours(u) do
		local role = Config.ROLES[o.pet]
		if role and role.aura then
			range += role.aura.range or 0
			haste += role.aura.haste or 0
			damage += role.aura.damage or 0
		end
	end
	return range, haste, damage
end

-- bonuses every familiar gets from Celestial familiars on the board (Kindle: damage, Veil: crit chance)
function MatchSim.globals(self: Sim): (number, number)
	local damage, crit = 0, 0
	for _, o in self.grid do
		local role = Config.ROLES[o.pet]
		if role and role.global then
			damage += role.global.damage or 0
			crit += role.global.crit or 0
		end
	end
	return damage, crit
end

-- damage after armour and marks; Sentinel pierces brass, the Wraith pierces everything
function MatchSim.armourDamage(self: Sim, u: any, e: any, dmg: number): number
	local role = Config.ROLES[u.pet]
	local armor = Config.ENEMIES[e.kind].armor
	local pierce = role and role.pierce
	if armor and armor ~= "none" and not (pierce == "all" or (type(pierce) == "table" and table.find(pierce, armor))) then
		local mult = Config.ARMOR_MULT[armor]
		dmg *= (mult and mult[Config.DAMAGE_TYPE[u.pet] or ""]) or 1
	end
	if hasStatus(e, "mark", self.t) then
		dmg *= 1 + Config.STATUS.mark.bonus
	end
	return dmg
end

-- what a shot does beyond its own damage: statuses, every-Nth bonuses, echo, drain
function MatchSim.roleHit(self: Sim, slot: number, u: any, e: any, dmg: number, isCrit: boolean)
	local role = Config.ROLES[u.pet]
	if role then
		if role.onHit and not e.dead then
			for _, kind in role.onHit do
				self:applyStatus(e, kind, dmg)
			end
		end
		if role.critStun and isCrit and not e.dead then
			self:applyStatus(e, "stun")
		end
		u.shots = (u.shots or 0) + 1
		if role.nth and u.shots % role.nth.n == 0 then
			if role.nth.extraHit and not e.dead then
				self:damage(e, dmg, false)
				self.emit("Echo", { slot = slot, id = e.id, dmg = dmg, kind = "extra" })
			end
			local sp = role.nth.splash
			if sp then
				local centre = Path.positionAt(e.dist)
				for _, o in self.enemies do
					if o ~= e and not o.dead then
						local p = Path.positionAt(o.dist)
						if (p - centre).Magnitude <= sp.radius then
							self:damage(o, dmg * sp.mult, false)
						end
					end
				end
				self.emit("Echo", { slot = slot, id = e.id, dmg = dmg * sp.mult, kind = "splash" })
			end
		end
		if role.rewind and u.shots % role.rewind.every == 0 then
			for _, o in self:neighbours(u) do
				o.cd = 0
			end
			self.emit("Echo", { slot = slot, id = e.id, dmg = 0, kind = "rewind" })
		end
		if role.drain then
			u.hits = (u.hits or 0) + 1
			if u.hits % role.drain.every == 0 then
				self.crystalHp = math.min(self:maxHp(), self.crystalHp + role.drain.heal)
				self.emit("Drain", { slot = slot, heal = role.drain.heal })
			end
		end
	end
	for _, o in self:neighbours(u) do
		local r2 = Config.ROLES[o.pet]
		if r2 and r2.echo and not e.dead then
			self:damage(e, dmg * r2.echo, false)
			self.emit("Echo", { slot = slot, id = e.id, dmg = dmg * r2.echo, kind = "echo" })
		end
	end
end

-- per-enemy ticks: burn damage, the Brass Sentinel's plant, the Lantern Thief's steal, the Clockwork Crow's perch; returns the speed multiplier
-- Is this fence standing or this gate closed right now (T157)? A gate opens first: open seconds, then closed, repeating.
function MatchSim.blockerActive(self: Sim, b: any): boolean
	if b.kind == "fence" then
		return b.hp > 0
	end
	local cycle = (b.open or 0) + (b.closed or 0)
	return cycle > 0 and (self.t - b.t0) % cycle >= (b.open or 0)
end

-- The nearest active blocker at or ahead of an enemy, or nil.
function MatchSim.blockerAhead(self: Sim, e: any): any
	local best: any = nil
	for _, b in (self :: any).blockers do
		if b.D >= e.dist and (not best or b.D < best.D) and self:blockerActive(b) then
			best = b
		end
	end
	return best
end

function MatchSim.enemyTick(self: Sim, e: any, dt: number): number
	local mult = 1
	if e.status then
		local burn = e.status.burn
		if burn and burn.untilT > self.t and burn.dps then
			self:damage(e, burn.dps * dt, false)
			if e.dead then
				return 0
			end
		end
		if hasStatus(e, "stun", self.t) or hasStatus(e, "freeze", self.t) then
			mult = 0
		elseif hasStatus(e, "chill", self.t) then
			mult = 1 - Config.STATUS.chill.slow * e.status.chill.stacks
		end
	end
	if e.kind == "Tank" then
		e.plantTimer = (e.plantTimer or 4) - dt
		if e.telegraph then
			e.telegraph -= dt
			if e.telegraph <= 0 then
				e.telegraph, e.plant = nil, 0.6
				self.emit("Plant", { id = e.id, dur = 0.6 })
			end
		elseif e.plant then
			e.plant -= dt
			if e.plant <= 0 then
				e.plant, e.plantTimer = nil, 4
			end
		elseif e.plantTimer <= 0 then
			e.telegraph = 1
			self.emit("Telegraph", { id = e.id, kind = "plant", delay = 1 })
		end
		if e.plant then
			mult = 0
		end
	elseif e.kind == "Thief" then
		if not e.carrying and e.dist >= 0.3 * Path.length then
			e.carrying = true
			self.emit("Steal", { id = e.id })
		end
		if e.carrying then
			mult *= 1.3
		end
	elseif e.kind == "Crow" then
		if e.perched == nil and e.dist >= 0.5 * Path.length then
			local here = Path.positionAt(e.dist)
			local bestSlot, bestD
			for slot, u in self.grid do
				local d = (Vector3.new(u.x, 0, u.z) - here).Magnitude
				if d <= 30 and (not bestD or d < bestD) then
					bestSlot, bestD = slot, d
				end
			end
			e.perched = bestSlot or false
			e.perchEnd = self.t + 6
			if bestSlot then
				(self.grid[bestSlot] :: any).disabledUntil = e.perchEnd
				self.emit("Perch", { id = e.id, slot = bestSlot, dur = 6 })
			end
		end
		if e.perched ~= nil and e.perchEnd and self.t < e.perchEnd then
			mult = 0
		end
	end
	if Config.ENEMIES[e.kind].eatsLamp and not e.ate and e.dist >= Config.LAMP_EAT.at * Path.length then
		e.ate = true
		self:eatLamp(e)
	end
	return mult
end

function MatchSim.effective(self: Sim, u: Unit): (number, number, number)
	local up = self.upgrades[u.pet]
	local dmg = Config.petDamage(u.pet, u.tier) * (1 + Config.UPGRADES.Power.per * up.Power) * (1 + self:sv("damage")) * (1 + self:dupePower(u.pet))
	local _, auraHaste, auraDamage = self:auras(u)
	local globalDamage, globalCrit = self:globals()
	local synDamage, synHaste = self:synergy(u)
	local lanDamage, lanHaste = self:lanternBonus(u)
	local sky = (self :: any).skyFx
	local skyDamage = sky and sky.damage[Config.DAMAGE_TYPE[u.pet] or ""] or 0
	dmg *= 1 + auraDamage + globalDamage + synDamage + lanDamage + skyDamage
	local cd = Config.PETS[u.pet].cooldown / ((1 + Config.UPGRADES.Haste.per * up.Haste) * (1 + self:sv("haste")) * (1 + auraHaste + synHaste + lanHaste))
	local crit = math.min(Config.CRIT_CAP, Config.UPGRADES.Crit.per * up.Crit + self:sv("crit") + globalCrit)
	return dmg, cd, crit
end

-- Boss framework (see Config.BOSSES). The boss state lives on the enemy as e.boss = { def, phase, stage, timers }.
function MatchSim.checkPhase(self: Sim, e: any)
	local b = e.boss
	while b.phase < #b.def.phases and e.hp / e.maxHp <= b.def.phases[b.phase + 1].at do
		b.phase += 1
		b.timers = {}
		b.lit = 0
		self.emit("BossPhase", { id = e.id, boss = b.def.id, name = b.def.name, phase = b.phase, phases = #b.def.phases, banner = b.def.phases[b.phase].banner, hpFrac = e.hp / e.maxHp })
	end
end

-- Runs the current phase's timed effects; returns the boss's speed multiplier.
function MatchSim.bossTick(self: Sim, e: any, dt: number): number
	local b = e.boss
	if not b or e.dead then
		return 1
	end
	local fx = bossFx(e)
	local T = b.timers
	local function due(key: string, every: number): boolean
		T[key] = (T[key] or 0) + dt
		if T[key] >= every then
			T[key] -= every
			return true
		end
		return false
	end
	if fx.regen and due("regen", fx.regen.every) then
		e.hp = math.min(e.maxHp, e.hp + e.maxHp * fx.regen.pct)
		self.emit("BossFx", { id = e.id, kind = "regen" })
	end
	if fx.deny and due("deny", fx.deny.every) then
		local newest
		for id in self.grid do
			if not newest or id > newest then
				newest = id
			end
		end
		if newest then
			(self.grid[newest] :: any).disabledUntil = self.t + fx.deny.dur
			self.emit("BossFx", { id = e.id, kind = "deny", slot = newest, dur = fx.deny.dur })
		end
	end
	if fx.freeze and due("freeze", fx.freeze.every) then
		for _, u in self.grid do
			(u :: any).disabledUntil = math.max((u :: any).disabledUntil or 0, self.t + fx.freeze.dur)
		end
		self.emit("BossFx", { id = e.id, kind = "freeze", dur = fx.freeze.dur })
	end
	if fx.summon and due("summon", fx.summon.every) then
		for i = 1, fx.summon.count do
			table.insert(self.queue, { at = self.t + (i - 1) * Config.SPAWN_GAP, kind = fx.summon.kind, stage = b.stage, mourner = (Config.BOSS_V2 and fx.candles ~= nil) or nil })
		end
		self.emit("BossFx", { id = e.id, kind = "summon", enemy = fx.summon.kind, count = fx.summon.count })
	end
	if Config.BOSS_V2 then
		if fx.lamp and due("lamp", fx.lamp.every) and not self.tutorial then
			self.crystalHp = math.min(self:maxHp(), self.crystalHp + fx.lamp.heal)
			self.emit("BossFx", { id = e.id, kind = "lamp", heal = fx.lamp.heal })
		end
		if fx.candles and (b.lit or 0) < fx.candles.count and due("candle", fx.candles.every) then
			b.lit = (b.lit or 0) + 1
			self.emit("BossFx", { id = e.id, kind = "candle", lit = b.lit })
		end
		if fx.push and due("push", fx.push.every) then
			self:bossPush(e, fx.push)
		end
	end
	if Config.BOSS_UNMERGE and fx.unmerge and due("unmerge", fx.unmerge.every) then
		self:unmerge(e)
	end
	return fx.speedMult or 1
end

-- Echo push (T416): the unit nearest the boss slides `dist` studs straight away from it, or is stunned for a second when the spot is not legal.
function MatchSim.bossPush(self: Sim, e: any, push: any)
	local bp = Path.positionAt(e.dist)
	local done: { [number]: boolean } = {}
	for _ = 1, push.count do
		local near, nd
		for id, u in self.grid do
			local d = (u.x - bp.X) ^ 2 + (u.z - bp.Z) ^ 2
			if not done[id] and (not nd or d < nd) then
				near, nd = id, d
			end
		end
		if not near then
			return
		end
		done[near] = true
		local u = self.grid[near] :: any
		local len = math.max(math.sqrt(nd), 1e-6)
		local x, z = u.x + (u.x - bp.X) / len * push.dist, u.z + (u.z - bp.Z) / len * push.dist
		local ok = Config.canPlace(self.grid, u.pet, x, z, near, Config.mapRules(self.stage))
		if ok then
			u.x, u.z = x, z
			self.emit("Move", { id = near, x = x, z = z })
		else
			u.disabledUntil = math.max(u.disabledUntil or 0, self.t + 1)
		end
		self.emit("BossFx", { id = e.id, kind = "push", slot = near, moved = ok })
	end
end

-- Clockmaker (T416, BOSS_UNMERGE): the highest merged unit falls back one tier into its three parts; skipped when the street has no room for the two new parts.
function MatchSim.unmerge(self: Sim, e: any): boolean
	local best, bt
	for id, u in self.grid do
		if u.tier >= 2 and (not bt or u.tier > bt) then
			best, bt = id, u.tier
		end
	end
	if not best or self:unitCount() + 2 > Config.MAX_UNITS then
		return false
	end
	local u = self.grid[best]
	local spots = {}
	for _ = 1, 2 do
		local x, z = self:findSpot(u.pet)
		if not x or not z then
			return false
		end
		local id = self:addUnit(u.pet, x, z)
		self.grid[id].tier = u.tier - 1
		table.insert(spots, id)
	end
	u.tier -= 1
	self.emit("BossFx", { id = e.id, kind = "unmerge", slot = best, tier = u.tier, parts = spots })
	return true
end

-- The slow aura of a live boss: { x, z, r2, factor } or nil. Units inside it cool down more slowly.
function MatchSim.bossSlow(self: Sim): any
	for _, e in self.enemies do
		local fx = not e.dead and bossFx(e)
		if fx and fx.slowAura then
			local p = Path.positionAt(e.dist)
			return { x = p.X, z = p.Z, r2 = fx.slowAura.radius * fx.slowAura.radius, factor = 1 / (1 + fx.slowAura.slow) }
		end
	end
	return nil
end

function MatchSim.step(self: Sim, dt: number)
	if self.paused or self.userPaused then
		return
	end
	self.t += dt

	-- day, night and weather (T009): the effects of this moment, and an "Sky" event when they change
	;(self :: any).skyFx = nil
	if Config.SKY_ON then
		local now = Config.skyAt(self.stage, self.t)
		if now then
			local key = (now.night and "night" or "day") .. ":" .. (now.weather or "")
			if key ~= self.skyKey then
				self.skyKey = key
				self.emit("Sky", { night = now.night, weather = now.weather, stage = self.stage })
			end
			local fx = { enemySpeed = 1, range = 0, damage = {} :: { [string]: number } }
			for _, name in { now.night and "night" or "", now.weather or "" } do
				local eff = Config.SKY_EFFECTS[name]
				if eff then
					fx.enemySpeed *= eff.enemySpeed or 1
					fx.range += eff.range or 0
					for k, v in eff.damage or {} do
						fx.damage[k] = (fx.damage[k] or 0) + v
					end
				end
			end
			;(self :: any).skyFx = fx
		end
	end
	local skyFx = (self :: any).skyFx

	if self.state == "ready" and self.autoWave then
		self.breakClock -= dt
		if self.breakClock <= 0 then
			self:startStage()
		end
	end

	while self.queue[1] and self.queue[1].at <= self.t do
		local q = table.remove(self.queue, 1) :: { at: number, kind: string, stage: number }
		local def = Config.ENEMIES[q.kind]
		local bossDef = (q.kind == "Boss" and Config.BOSS_PHASES) and Config.bossDef(q.stage) or nil
		local hp = def.hp * Config.hpScale(q.stage) * (bossDef and bossDef.hpMult or 1) * Config.difficulty(self.difficulty).hp
		local qa: any = q
		local mod = (Config.WAVES_V2 and qa.mod) and Config.waveModifier(q.stage) or nil
		local speedMult, coinMult, gemMult = 1, 1, 1
		if mod then
			hp *= mod.hp or 1
			speedMult, coinMult, gemMult = mod.speed or 1, mod.coins or 1, mod.gems or 1
		end
		if Config.WAVES_V2 and qa.elite then
			local E = Config.ELITE
			hp *= E.hp
			speedMult, coinMult, gemMult = speedMult * E.speed, coinMult * E.coins, gemMult * E.gems
		end
		local e: Enemy = { id = self.nextId, kind = q.kind, hp = hp, maxHp = hp, dist = 0, dead = false }
		if speedMult ~= 1 then
			(e :: any).speedMult = speedMult
		end
		if coinMult ~= 1 or gemMult ~= 1 then
			(e :: any).coinMult, (e :: any).gemMult = coinMult, gemMult
		end
		if Config.WAVES_V2 and qa.elite then
			(e :: any).elite = true
		end
		if (q :: any).mourner then
			(e :: any).mourner = true
		end
		if bossDef then
			(e :: any).boss = { def = bossDef, phase = 1, stage = q.stage, timers = {}, lit = 0 }
		end
		self.nextId += 1
		table.insert(self.enemies, e)
		if q.kind == "Boss" then
			self.bossClock = Config.BOSS_TIME + self:sv("bossTime")
		end
		self.emit("Spawn", { id = e.id, kind = e.kind, t = self.t, maxHp = hp, boss = bossDef and bossDef.id or nil, bossName = bossDef and bossDef.name or nil, elite = (e :: any).elite })
	end

	local blockers = (self :: any).blockers
	if blockers and #blockers > 0 then
		for _, b in blockers do
			if b.kind == "gate" then
				local closed = self:blockerActive(b)
				if closed ~= b.closedNow then
					b.closedNow = closed
					self.emit("Gate", { id = b.id, closed = closed })
				end
			end
		end
	else
		blockers = nil
	end
	for _, e in self.enemies do
		local pace = self:enemyTick(e, dt)
		-- the speed multiplier the client must follow: movement effects (when on) times the boss phase's speedMult; "Pace" tells the client when it changes
		local mult = (Config.MOVEMENT_EFFECTS and pace or 1) * self:bossTick(e, dt) * ((e :: any).speedMult or 1) * (skyFx and skyFx.enemySpeed or 1)
		local blk = blockers and self:blockerAhead(e) or nil
		if blk and blk.D - e.dist < 1e-6 then
			mult = 0 -- waiting at the fence or gate; a fence takes damage from each enemy at it
			if blk.kind == "fence" and not e.dead then
				blk.hp -= (blk.breakDps or 8) * dt
				if blk.hp <= 0 then
					self.emit("BlockerBroken", { id = blk.id })
				end
			end
		end
		if ((e :: any).mult or 1) ~= mult then
			(e :: any).mult = mult
			self.emit("Pace", { id = e.id, dist = e.dist, speed = Config.ENEMIES[e.kind].speed * mult, t = self.t })
		end
		e.dist += Config.ENEMIES[e.kind].speed * mult * dt
		if blk and e.dist > blk.D then
			e.dist = blk.D
		end
		if e.dist >= Path.length and not e.dead then
			e.dead = true
			if not self.tutorial then
				self.crystalHp -= Config.ENEMIES[e.kind].leak + ((e :: any).carrying and 1 or 0)
			end
			self.leakCount += 1
			if self.leakCount > self:sv("streakGuard") then
				self.leaked = true
				self.combo = 0
			end
			self.emit("Leak", { id = e.id, streakKept = not self.leaked })
		end
	end

	local slowAura = self:bossSlow()
	for slot, u in self.grid do
		local slow = 1
		if slowAura then
			local dx, dz = u.x - slowAura.x, u.z - slowAura.z
			if dx * dx + dz * dz <= slowAura.r2 then
				slow = slowAura.factor
			end
		end
		u.cd -= dt * slow
		if ((u :: any).disabledUntil or 0) > self.t then
			u.cd = math.max(u.cd, 0.1) -- a perched crow keeps this familiar from firing
		elseif u.cd <= 0 then
			local def = Config.PETS[u.pet]
			local origin = Vector3.new(u.x, 0, u.z)
			local rangeAura = self:auras(u)
			local range = def.range * (1 + rangeAura + (skyFx and skyFx.range or 0))
			local best: Enemy? = nil
			for _, e in self.enemies do
				if not e.dead and (not best or e.dist > best.dist) then
					local p = Path.positionAt(e.dist)
					local dx, dz = p.X - origin.X, p.Z - origin.Z
					if dx * dx + dz * dz <= range * range then
						best = e
					end
				end
			end
			if best then
				local dmg, cd, crit = self:effective(u)
				local isCrit = crit > 0 and self.rng:NextNumber() < crit
				if isCrit then
					dmg *= 2.5
				end
				if best.kind == "Boss" then
					dmg *= 1 + self:sv("bossDamage")
				end
				dmg = self:armourDamage(u, best, dmg)
				u.cd = cd
				self.emit("Shot", { slot = slot, id = best.id, dmg = dmg, crit = isCrit })
				self:damage(best, dmg, true)
				self:roleHit(slot, u, best, dmg, isCrit)
			else
				u.cd = 0.1
			end
		end
	end

	self:cleanup()

	if self.bossClock then
		local bossAlive = false
		for _, e in self.enemies do
			if e.kind == "Boss" then
				bossAlive = true
			end
		end
		if bossAlive then
			self.bossClock -= dt
			if self.bossClock <= 0 then
				self:bossEscaped()
				return
			end
		else
			self.bossClock = nil
		end
	end

	if self.crystalHp <= 0 then
		self:overrun()
		return
	end

	if self.state == "active" and #self.queue == 0 and #self.enemies == 0 then
		self:clearStage()
	end
end

function MatchSim.bossSnapshot(self: Sim): any
	for _, e in self.enemies do
		local b = (e :: any).boss
		if b and not e.dead then
			return { id = e.id, name = b.def.name, phase = b.phase, phases = #b.def.phases, hp = e.hp, maxHp = e.maxHp }
		end
	end
	return nil
end

function MatchSim.snapshot(self: Sim): { [string]: any }
	local grid = {}
	for i, u in self.grid do
		grid[tostring(i)] = { pet = u.pet, tier = u.tier, x = u.x, z = u.z }
	end
	local ups = {}
	for id, t in self.upgrades do
		ups[id] = { Power = t.Power, Haste = t.Haste, Crit = t.Crit }
	end
	return {
		coins = self.coins,
		gems = self.gems,
		rollCost = self:rollCost(),
		crystal = self.crystalHp,
		maxHp = self:maxHp(),
		ultNeed = self:ultNeed(),
		sp = self.sp,
		tree = self.tree,
		pityEvery = self:pityEvery(),
		stage = self.stage,
		combo = self.combo,
		ult = self.ult,
		bossClock = self.bossClock,
		boss = self:bossSnapshot(),
		tutorial = self.tutorial,
		paused = self.paused,
		userPaused = self.userPaused,
		pauseLeft = self.pauseLeft,
		difficulty = self.difficulty,
		lanternCd = math.max(0, self.lanternReady - self.t),
		lanternOn = self.t < self.lanternUntil,
		state = self.state,
		autoWave = self.autoWave,
		rolls = self.rolls,
		maxTier = self.maxTier,
		upgradeCount = self.upgradeCount,
		moves = self.moves,
		level = self.level,
		xp = self.xp,
		xpNeed = Config.xpNeed(self.level),
		luck = self:luck(),
		sincePity = self.sincePity,
		gacha = self:gachaSnapshot(),
		upgrades = ups,
		grid = grid,
	}
end

return MatchSim
