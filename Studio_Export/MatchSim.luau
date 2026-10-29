--!strict
-- Pure run simulation: no Instances, no remotes. The server runs it; tests drive it directly.
-- You cannot lose. If the crystal falls, the run is pushed back and you lose some coins and your streak.

local Config = require(script.Parent.Config)
local Path = require(script.Parent.Path)

-- Units are keyed by id (the client still calls it "slot") and stand anywhere legal: see Config.canPlace.
export type Unit = { pet: string, tier: number, cd: number, x: number, z: number }
export type Enemy = { id: number, kind: string, hp: number, maxHp: number, dist: number, dead: boolean }

local MatchSim = {}
MatchSim.__index = MatchSim

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
	return { level = self.level, xp = self.xp, sp = self.sp, gems = self.gems, tree = table.clone(self.tree) }
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
	for _, i in order do
		local p = Config.SLOTS[i]
		if Config.canPlace(self.grid, pet, p.X, p.Z) then
			return p.X, p.Z
		end
	end
	local b = Config.PLACE_BOUNDS
	local bestX, bestZ, bestD = nil, nil, math.huge
	for x = b.minX + 2, b.maxX - 2, 3 do
		for z = b.minZ + 2, b.maxZ - 2, 3 do
			if Config.canPlace(self.grid, pet, x, z) then
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
	if self.tutorial and #self.forced > 0 then
		pet = self.forced[1]
		rarity = Config.PETS[pet].rarity
		local p = Config.SLOTS[self.forcedSlots[1]]
		if p and Config.canPlace(self.grid, pet, p.X, p.Z) then
			x, z = p.X, p.Z
		else
			x, z = self:findSpot(pet)
		end
	else
		rarity = self:pickRarity()
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
	local id = self:addUnit(pet, x, z)
	self.maxTier = math.max(self.maxTier, 1)
	self.emit("Roll", { slot = id, pet = pet, rarity = rarity, x = x, z = z })
	-- Double Hatch: a free bonus pet
	local chance = self:sv("doubleHatch")
	if chance > 0 and not self.tutorial and self.rng:NextNumber() < chance and self:unitCount() < Config.MAX_UNITS then
		local bonusPet, bonusRarity = self:pickPet(self:pickRarity())
		local bx, bz
		if bonusPet then
			bx, bz = self:findSpot(bonusPet)
		end
		if bx and bz then
			local bid = self:addUnit(bonusPet, bx, bz)
			self.emit("Roll", { slot = bid, pet = bonusPet, rarity = bonusRarity, bonus = true, x = bx, z = bz })
		end
	end
	return true, nil
end

-- Move a pet to any legal spot on the street.
function MatchSim.move(self: Sim, id: number, x: number, z: number): (boolean, string?)
	local u = self.grid[id]
	if not u then
		return false, "Pick a pet"
	end
	local ok, reason = Config.canPlace(self.grid, u.pet, x, z, id)
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
	e.hp -= amount
	if e.hp <= 0 and not e.dead then
		e.dead = true
		local def = Config.ENEMIES[e.kind]
		local coins = math.floor(def.coins * (1 + 0.1 * (self.stage - 1)) * (1 + self:sv("coins")) + 0.5)
		local gems = math.floor(def.gems * Config.comboMult(self.combo) * (1 + self:sv("gems")) + 0.5)
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
	for i, kind in list do
		table.insert(self.queue, { at = self.t + (i - 1) * Config.SPAWN_GAP, kind = kind, stage = self.stage })
	end
	self.emit("Stage", { stage = self.stage, boss = Config.isBossStage(self.stage), combo = self.combo })
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

function MatchSim.effective(self: Sim, u: Unit): (number, number, number)
	local up = self.upgrades[u.pet]
	local dmg = Config.petDamage(u.pet, u.tier) * (1 + Config.UPGRADES.Power.per * up.Power) * (1 + self:sv("damage"))
	local cd = Config.PETS[u.pet].cooldown / ((1 + Config.UPGRADES.Haste.per * up.Haste) * (1 + self:sv("haste")))
	local crit = math.min(Config.CRIT_CAP, Config.UPGRADES.Crit.per * up.Crit + self:sv("crit"))
	return dmg, cd, crit
end

function MatchSim.step(self: Sim, dt: number)
	if self.paused then
		return
	end
	self.t += dt

	if self.state == "ready" and self.autoWave then
		self.breakClock -= dt
		if self.breakClock <= 0 then
			self:startStage()
		end
	end

	while self.queue[1] and self.queue[1].at <= self.t do
		local q = table.remove(self.queue, 1) :: { at: number, kind: string, stage: number }
		local def = Config.ENEMIES[q.kind]
		local hp = def.hp * Config.hpScale(q.stage)
		local e: Enemy = { id = self.nextId, kind = q.kind, hp = hp, maxHp = hp, dist = 0, dead = false }
		self.nextId += 1
		table.insert(self.enemies, e)
		if q.kind == "Boss" then
			self.bossClock = Config.BOSS_TIME + self:sv("bossTime")
		end
		self.emit("Spawn", { id = e.id, kind = e.kind, t = self.t, maxHp = hp })
	end

	for _, e in self.enemies do
		e.dist += Config.ENEMIES[e.kind].speed * dt
		if e.dist >= Path.length and not e.dead then
			e.dead = true
			if not self.tutorial then
				self.crystalHp -= Config.ENEMIES[e.kind].leak
			end
			self.leakCount += 1
			if self.leakCount > self:sv("streakGuard") then
				self.leaked = true
				self.combo = 0
			end
			self.emit("Leak", { id = e.id, streakKept = not self.leaked })
		end
	end

	for slot, u in self.grid do
		u.cd -= dt
		if u.cd <= 0 then
			local def = Config.PETS[u.pet]
			local origin = Vector3.new(u.x, 0, u.z)
			local best: Enemy? = nil
			for _, e in self.enemies do
				if not e.dead and (not best or e.dist > best.dist) then
					local p = Path.positionAt(e.dist)
					local dx, dz = p.X - origin.X, p.Z - origin.Z
					if dx * dx + dz * dz <= def.range * def.range then
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
				u.cd = cd
				self.emit("Shot", { slot = slot, id = best.id, dmg = dmg, crit = isCrit })
				self:damage(best, dmg, true)
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
		tutorial = self.tutorial,
		paused = self.paused,
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
		upgrades = ups,
		grid = grid,
	}
end

return MatchSim
