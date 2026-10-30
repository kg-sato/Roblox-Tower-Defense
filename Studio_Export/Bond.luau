--!strict
-- Familiar bond (T007): a bond level from use, plus a mood from how long ago the familiar last fought. Pure data and functions; the server calls
-- use() with trusted run events and pays the returned gems. No design note existed, so levels, mood names and numbers here are the sim worker's placeholders.
-- State (can sit in the profile): { [familiarId] = { xp, lastUsed, day, dayXp } }. Not wired into MatchService yet.

export type Entry = { xp: number, lastUsed: number, day: number, dayXp: number }
export type State = { [string]: Entry }

local Bond = {}

Bond.MAX_LEVEL = 10
Bond.DAY = 86400
Bond.DAILY_XP_CAP = 200 -- most bond xp one familiar can earn in a UTC day (no grinding)
Bond.MAX_FAMILIARS = 64
Bond.XP = { run = 10, minute = 1, merge = 3, bossKill = 8 } -- xp per unit of each kind of use
Bond.STEP_CAP = 100 -- most units one use() call counts
-- gems paid on reaching a level (level 1 is the start)
Bond.REWARD = { [2] = 5, [3] = 5, [4] = 10, [5] = 10, [6] = 15, [7] = 15, [8] = 20, [9] = 20, [10] = 30 }
-- days away -> mood, and the catch-up multiplier on bond xp (a lonely familiar warms quickly)
Bond.MOODS = {
	{ id = "Delighted", maxDays = 1, mult = 1 },
	{ id = "Content", maxDays = 4, mult = 1 },
	{ id = "Wistful", maxDays = 10, mult = 1.25 },
	{ id = "Lonely", maxDays = math.huge, mult = 1.5 },
}
Bond.NEW_MOOD = { id = "Curious", mult = 1 } -- never used yet

-- total xp needed for a level: 25 * n * (n - 1) (level 2 at 50, level 10 at 2,250)
function Bond.xpFor(level: number): number
	return 25 * level * (level - 1)
end

function Bond.level(xp: number): number
	local lv = 1
	while lv < Bond.MAX_LEVEL and xp >= Bond.xpFor(lv + 1) do
		lv += 1
	end
	return lv
end

-- xp into the current level, xp the level needs (0, 0 at the maximum)
function Bond.progress(xp: number): (number, number)
	local lv = Bond.level(xp)
	if lv >= Bond.MAX_LEVEL then
		return 0, 0
	end
	return xp - Bond.xpFor(lv), Bond.xpFor(lv + 1) - Bond.xpFor(lv)
end

function Bond.validId(id: any): boolean
	return type(id) == "string" and #id >= 1 and #id <= 40 and string.match(id, "^[%w_]+$") ~= nil
end

function Bond.new(): State
	return {}
end

function Bond.mood(state: State, id: string, now: number): any
	local e = state[id]
	if not e or e.lastUsed <= 0 then
		return Bond.NEW_MOOD
	end
	local days = math.max(0, (now - e.lastUsed) / Bond.DAY)
	for _, m in Bond.MOODS do
		if days <= m.maxDays then
			return m
		end
	end
	return Bond.MOODS[#Bond.MOODS]
end

-- Counts `amount` units of a kind of use for one familiar. Returns ok, reason, and { xp, level, levels = { reached levels }, gems }.
function Bond.use(state: State, id: any, kind: any, amount: any, now: any): (boolean, string?, any?)
	if not Bond.validId(id) then
		return false, "Bad familiar", nil
	end
	local per = type(kind) == "string" and Bond.XP[kind] or nil
	if not per then
		return false, "Bad kind", nil
	end
	if type(amount) ~= "number" or amount ~= amount or amount < 1 or amount == math.huge then
		return false, "Bad amount", nil
	end
	if type(now) ~= "number" or now ~= now or now < 0 or now == math.huge then
		return false, "Bad time", nil
	end
	local e = state[id :: string]
	if not e then
		local count = 0
		for _ in state do
			count += 1
		end
		if count >= Bond.MAX_FAMILIARS then
			return false, "Too many familiars", nil
		end
		e = { xp = 0, lastUsed = 0, day = 0, dayXp = 0 }
		state[id :: string] = e
	end
	local entry = e :: Entry
	local day = math.floor(now / Bond.DAY)
	if entry.day ~= day then
		entry.day, entry.dayXp = day, 0
	end
	local mood = Bond.mood(state, id :: string, now)
	local gain = math.floor(math.min(math.floor(amount), Bond.STEP_CAP) * per * mood.mult)
	gain = math.min(gain, Bond.DAILY_XP_CAP - entry.dayXp, Bond.xpFor(Bond.MAX_LEVEL) - entry.xp)
	gain = math.max(gain, 0)
	local before = Bond.level(entry.xp)
	entry.xp += gain
	entry.dayXp += gain
	entry.lastUsed = math.max(entry.lastUsed, now)
	local after = Bond.level(entry.xp)
	local levels, gems = {}, 0
	for lv = before + 1, after do
		table.insert(levels, lv)
		gems += Bond.REWARD[lv] or 0
	end
	return true, nil, { xp = gain, level = after, levels = levels, gems = gems }
end

local function cleanNumber(n: any): number
	if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge or n < 0 then
		return 0
	end
	return math.floor(n)
end

function Bond.load(d: any): State
	local s = Bond.new()
	if type(d) ~= "table" then
		return s
	end
	local count = 0
	for id, v in d do
		if Bond.validId(id) and type(v) == "table" and count < Bond.MAX_FAMILIARS then
			count += 1
			s[id] = {
				xp = math.min(cleanNumber(v.xp), Bond.xpFor(Bond.MAX_LEVEL)),
				lastUsed = cleanNumber(v.lastUsed),
				day = cleanNumber(v.day),
				dayXp = math.min(cleanNumber(v.dayXp), Bond.DAILY_XP_CAP),
			}
		end
	end
	return s
end

return Bond
