--!strict
-- Achievements (T002): 30 achievements as data plus pure server-side unlock logic. No design list existed in the vault, so this set was
-- written by the sim worker from stats the sim already produces; swap the rows in `list` freely (the logic reads only the data).
-- The server calls record/setMax with trusted numbers from MatchSim events (never from a client message), then unlock(state) and pays the gems.
-- State is a plain table that can sit in the profile: { stats = { [stat] = number }, unlocked = { [id] = true } }.
-- Not wired into MatchService yet.

export type State = { stats: { [string]: number }, unlocked: { [string]: boolean } }

local Achievements = {}

-- kind "count" stats add up (record), kind "max" stats keep the best seen (setMax)
Achievements.stats = {
	rolls = "count", merges = "count", recycles = "count", upgrades = "count", stagesCleared = "count", perfectStages = "count",
	bossKills = "count", lanternUses = "count", ultCasts = "count", runsPlayed = "count",
	bestStage = "max", bestStreak = "max", maxTier = "max", familiarsSeen = "max",
}

Achievements.STEP_CAP = 1000 -- the most one record call may add

Achievements.list = {
	{ id = "FirstSummon", name = "First Summon", stat = "rolls", goal = 1, gems = 5 },
	{ id = "Summoner", name = "Summoner", stat = "rolls", goal = 25, gems = 10 },
	{ id = "Conjurer", name = "Conjurer", stat = "rolls", goal = 100, gems = 20 },
	{ id = "FirstMerge", name = "Two Become One", stat = "merges", goal = 1, gems = 5 },
	{ id = "Weaver", name = "Weaver", stat = "merges", goal = 25, gems = 15 },
	{ id = "TierThree", name = "Third Rung", stat = "maxTier", goal = 3, gems = 10 },
	{ id = "TierFive", name = "Fifth Rung", stat = "maxTier", goal = 5, gems = 25 },
	{ id = "FirstLamp", name = "The First Lamp", stat = "stagesCleared", goal = 1, gems = 5 },
	{ id = "TenLamps", name = "Ten Lamps", stat = "stagesCleared", goal = 10, gems = 10 },
	{ id = "LampLighter", name = "Lamplighter", stat = "stagesCleared", goal = 25, gems = 20 },
	{ id = "Keeper", name = "Keeper of the Street", stat = "stagesCleared", goal = 100, gems = 40 },
	{ id = "MetTheUnbound", name = "Met the Unbound", stat = "bestStage", goal = 5, gems = 10 },
	{ id = "AcrossTheHarbour", name = "Across the Harbour", stat = "bestStage", goal = 10, gems = 15 },
	{ id = "ChoirHeard", name = "The Choir Heard", stat = "bestStage", goal = 15, gems = 20 },
	{ id = "BehindTheClock", name = "Behind the Clock", stat = "bestStage", goal = 25, gems = 40 },
	{ id = "PastTheClock", name = "Past the Clock", stat = "bestStage", goal = 26, gems = 50 },
	{ id = "BossBane", name = "Bane of the First", stat = "bossKills", goal = 1, gems = 15 },
	{ id = "BossHunter", name = "Hunter of Giants", stat = "bossKills", goal = 10, gems = 40 },
	{ id = "Clean", name = "Clean Street", stat = "perfectStages", goal = 1, gems = 5 },
	{ id = "Spotless", name = "Spotless", stat = "perfectStages", goal = 10, gems = 15 },
	{ id = "Untouched", name = "Untouched", stat = "perfectStages", goal = 50, gems = 35 },
	{ id = "Streak5", name = "Steady Hand", stat = "bestStreak", goal = 5, gems = 15 },
	{ id = "Streak10", name = "Unbroken", stat = "bestStreak", goal = 10, gems = 30 },
	{ id = "Recycler", name = "Nothing Wasted", stat = "recycles", goal = 10, gems = 10 },
	{ id = "Tinkerer", name = "Tinkerer", stat = "upgrades", goal = 25, gems = 15 },
	{ id = "LanternBearer", name = "Lantern Bearer", stat = "lanternUses", goal = 5, gems = 10 },
	{ id = "Finale", name = "Grand Finale", stat = "ultCasts", goal = 10, gems = 15 },
	{ id = "Collector", name = "Collector", stat = "familiarsSeen", goal = 5, gems = 10 },
	{ id = "Menagerie", name = "Menagerie", stat = "familiarsSeen", goal = 20, gems = 35 },
	{ id = "Regular", name = "A Regular", stat = "runsPlayed", goal = 5, gems = 10 },
}

local byId: { [string]: any } = {}
for _, a in Achievements.list do
	byId[a.id] = a
end
Achievements.byId = byId

function Achievements.new(): State
	return { stats = {}, unlocked = {} }
end

local function cleanNumber(n: any): number?
	if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge or n < 0 then
		return nil
	end
	return math.floor(n)
end

-- Adds to a "count" stat. Unknown stats, wrong kinds, negative, fractional-garbage and non-number amounts are refused; one call adds at most STEP_CAP.
function Achievements.record(state: State, stat: any, amount: any): boolean
	if type(stat) ~= "string" or Achievements.stats[stat] ~= "count" then
		return false
	end
	local n = cleanNumber(amount)
	if not n or n == 0 then
		return false
	end
	state.stats[stat] = (state.stats[stat] or 0) + math.min(n, Achievements.STEP_CAP)
	return true
end

-- Raises a "max" stat; it never goes down.
function Achievements.setMax(state: State, stat: any, value: any): boolean
	if type(stat) ~= "string" or Achievements.stats[stat] ~= "max" then
		return false
	end
	local n = cleanNumber(value)
	if not n then
		return false
	end
	if n > (state.stats[stat] or 0) then
		state.stats[stat] = n
	end
	return true
end

function Achievements.progress(state: State, id: string): (number, number)
	local a = byId[id]
	if not a then
		return 0, 0
	end
	return math.min(state.stats[a.stat] or 0, a.goal), a.goal
end

-- Unlocks everything whose goal is met and was not unlocked yet. Returns the new ids (list order) and the gems to pay. Each id unlocks once.
function Achievements.unlock(state: State): ({ string }, number)
	local fresh, gems = {}, 0
	for _, a in Achievements.list do
		if not state.unlocked[a.id] and (state.stats[a.stat] or 0) >= a.goal then
			state.unlocked[a.id] = true
			table.insert(fresh, a.id)
			gems += a.gems
		end
	end
	return fresh, gems
end

-- Loads a saved state: keeps only known stats and ids, repairs bad numbers.
function Achievements.load(d: any): State
	local s = Achievements.new()
	if type(d) ~= "table" then
		return s
	end
	if type(d.stats) == "table" then
		for k, v in d.stats do
			local n = cleanNumber(v)
			if type(k) == "string" and Achievements.stats[k] and n then
				s.stats[k] = n
			end
		end
	end
	if type(d.unlocked) == "table" then
		for k, v in d.unlocked do
			if type(k) == "string" and byId[k] and v == true then
				s.unlocked[k] = true
			end
		end
	end
	return s
end

return Achievements
