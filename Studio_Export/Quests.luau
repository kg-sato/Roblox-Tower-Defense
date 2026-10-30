--!strict
-- Quests (T023): the 20 designed quests (10 daily, 10 story; Roblox Dev/Design/Content Plans.md "Twenty quests") as data plus pure server logic.
-- The server feeds record/setMax with trusted numbers from MatchSim events, calls rollover(state, now) at login and at midnight UTC, and pays what claim returns.
-- State (plain table, can sit in the profile): { day, stats = { [stat] = n } (daily, reset each day), claimed = { [id] = true } (today's dailies), life = { bestStage, bestCleared }, storyClaimed = { [id] = true } }.
-- Rewards stay small: three dailies are 60 gems at the most, the story set pays 300 gems and 2 skill points. Not wired into MatchService yet.

export type State = { day: number, stats: { [string]: number }, claimed: { [string]: boolean }, life: { [string]: number }, storyClaimed: { [string]: boolean } }

local Quests = {}

Quests.DAILY_SHOWN = 3
Quests.STEP_CAP = 1000
Quests.DAY = 86400

-- daily stats: "count" adds up (record), "max" keeps the best seen today (setMax)
Quests.dailyStats = {
	rolls = "count", merges = "count", stagesCleared = "count", bossKills = "count", perfectStages = "count", lanternUses = "count", recycles = "count",
	factionsInRun = "max", upgradeLevel = "max", streak = "max",
}
Quests.lifeStats = { bestStage = true, bestCleared = true } -- max stats kept for good, read by the story quests

Quests.daily = {
	{ id = "D1", name = "Roll 5 familiars", stat = "rolls", goal = 5, gems = 15, bp = 10 },
	{ id = "D2", name = "Merge 3 times", stat = "merges", goal = 3, gems = 15, bp = 10 },
	{ id = "D3", name = "Clear 3 stages", stat = "stagesCleared", goal = 3, gems = 20, bp = 10 },
	{ id = "D4", name = "Defeat a boss", stat = "bossKills", goal = 1, gems = 30, bp = 10 },
	{ id = "D5", name = "Finish a stage with no leaks", stat = "perfectStages", goal = 1, gems = 25, bp = 10 },
	{ id = "D6", name = "Place familiars of 2 factions in one run", stat = "factionsInRun", goal = 2, gems = 20, bp = 10 },
	{ id = "D7", name = "Upgrade any familiar to level 3", stat = "upgradeLevel", goal = 3, gems = 15, bp = 10 },
	{ id = "D8", name = "Use the lantern power twice", stat = "lanternUses", goal = 2, gems = 20, bp = 10 },
	{ id = "D9", name = "Recycle 2 units", stat = "recycles", goal = 2, gems = 10, bp = 10 },
	{ id = "D10", name = "Reach a perfect streak of 5", stat = "streak", goal = 5, gems = 25, bp = 10 },
}

-- story quests: life stat reaches goal ("clear stage N" = bestCleared, "reach stage N" = bestStage); lore is a Shared.LoreFragments id
Quests.story = {
	{ id = "S1", name = "Light the first lamp on Lampwick Lane", stat = "bestCleared", goal = 1, gems = 20, sp = 0, lore = "LF-C1-01" },
	{ id = "S2", name = "Meet the Unbound", stat = "bestStage", goal = 5, gems = 25, sp = 0, lore = "LF-C1-11" },
	{ id = "S3", name = "Cross the Harbour", stat = "bestCleared", goal = 10, gems = 30, sp = 0, lore = "LF-C2-11" },
	{ id = "S4", name = "Find the child's lantern", stat = "bestStage", goal = 12, gems = 25, sp = 0, lore = "LF-C3-03" },
	{ id = "S5", name = "Sing with the Choir", stat = "bestCleared", goal = 15, gems = 30, sp = 1, lore = "LF-C3-12" },
	{ id = "S6", name = "Ring the Foundry bell", stat = "bestStage", goal = 18, gems = 30, sp = 0, lore = "LF-C4-07" },
	{ id = "S7", name = "Look behind the clock", stat = "bestCleared", goal = 20, gems = 35, sp = 0, lore = "LF-C4-12" },
	{ id = "S8", name = "Climb above the grey veil", stat = "bestStage", goal = 21, gems = 30, sp = 0, lore = "LF-C5-01" },
	{ id = "S9", name = "Wake the apprentice's lamp", stat = "bestStage", goal = 24, gems = 35, sp = 0, lore = "LF-C5-10" },
	{ id = "S10", name = "Turn the clock", stat = "bestCleared", goal = 25, gems = 40, sp = 1, lore = "LF-C5-12" },
}

local byId: { [string]: any } = {}
for _, q in Quests.daily do
	q.kind = "daily"
	byId[q.id] = q
end
for _, q in Quests.story do
	q.kind = "story"
	byId[q.id] = q
end
Quests.byId = byId

function Quests.new(): State
	return { day = 0, stats = {}, claimed = {}, life = {}, storyClaimed = {} }
end

function Quests.dayKey(now: number): number
	return math.floor(now / Quests.DAY)
end

-- The three dailies of a day: the same for every player and every call (a seeded shuffle), always distinct.
function Quests.dailyIds(day: number): { string }
	local rng = Random.new(day)
	local pool = {}
	for _, q in Quests.daily do
		table.insert(pool, q.id)
	end
	for i = #pool, 2, -1 do
		local j = rng:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local out = {}
	for i = 1, Quests.DAILY_SHOWN do
		table.insert(out, pool[i])
	end
	return out
end

-- Starts a new day when the day key changed: daily progress and daily claims reset, story progress stays. Returns true if it reset.
function Quests.rollover(state: State, now: number): boolean
	local day = Quests.dayKey(now)
	if state.day == day then
		return false
	end
	if day < state.day then
		return false -- a clock that went backwards never replays a day
	end
	state.day = day
	state.stats = {}
	state.claimed = {}
	return true
end

local function cleanNumber(n: any): number?
	if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge or n < 0 then
		return nil
	end
	return math.floor(n)
end

function Quests.record(state: State, stat: any, amount: any): boolean
	if type(stat) ~= "string" or Quests.dailyStats[stat] ~= "count" then
		return false
	end
	local n = cleanNumber(amount)
	if not n or n == 0 then
		return false
	end
	state.stats[stat] = (state.stats[stat] or 0) + math.min(n, Quests.STEP_CAP)
	return true
end

-- Raises a daily "max" stat or a life stat.
function Quests.setMax(state: State, stat: any, value: any): boolean
	local n = cleanNumber(value)
	if not n or type(stat) ~= "string" then
		return false
	end
	if Quests.dailyStats[stat] == "max" then
		state.stats[stat] = math.max(state.stats[stat] or 0, n)
		return true
	elseif Quests.lifeStats[stat] then
		state.life[stat] = math.max(state.life[stat] or 0, n)
		return true
	end
	return false
end

function Quests.isActive(state: State, id: string): boolean
	local q = byId[id]
	if not q then
		return false
	end
	return q.kind == "story" or table.find(Quests.dailyIds(state.day), id) ~= nil
end

-- progress, goal, done, claimed
function Quests.status(state: State, id: string): (number, number, boolean, boolean)
	local q = byId[id]
	if not q then
		return 0, 0, false, false
	end
	local have = (q.kind == "daily" and state.stats[q.stat] or state.life[q.stat]) or 0
	local claimed = if q.kind == "daily" then state.claimed[id] == true else state.storyClaimed[id] == true
	return math.min(have, q.goal), q.goal, have >= q.goal, claimed
end

-- Claims a finished quest once. Returns ok, reason (when refused) and the reward { gems, bp, sp, lore } the server must pay.
function Quests.claim(state: State, id: any): (boolean, string?, any?)
	if type(id) ~= "string" or not byId[id] then
		return false, "Unknown quest", nil
	end
	if not Quests.isActive(state, id) then
		return false, "Not one of today's quests", nil
	end
	local _, _, done, claimed = Quests.status(state, id)
	if claimed then
		return false, "Already claimed", nil
	end
	if not done then
		return false, "Not finished", nil
	end
	local q = byId[id]
	if q.kind == "daily" then
		state.claimed[id] = true
	else
		state.storyClaimed[id] = true
	end
	return true, nil, { gems = q.gems, bp = q.bp or 0, sp = q.sp or 0, lore = q.lore }
end

-- Loads a saved state; unknown keys, bad numbers and claims for unknown ids are dropped.
function Quests.load(d: any): State
	local s = Quests.new()
	if type(d) ~= "table" then
		return s
	end
	s.day = cleanNumber(d.day) or 0
	if type(d.stats) == "table" then
		for k, v in d.stats do
			local n = cleanNumber(v)
			if type(k) == "string" and Quests.dailyStats[k] and n then
				s.stats[k] = n
			end
		end
	end
	if type(d.life) == "table" then
		for k, v in d.life do
			local n = cleanNumber(v)
			if type(k) == "string" and Quests.lifeStats[k] and n then
				s.life[k] = n
			end
		end
	end
	for _, pair in { { "claimed", "daily" }, { "storyClaimed", "story" } } do
		local src = d[pair[1]]
		if type(src) == "table" then
			for k, v in src do
				if type(k) == "string" and byId[k] and byId[k].kind == pair[2] and v == true then
					(s :: any)[pair[1]][k] = true
				end
			end
		end
	end
	return s
end

return Quests
