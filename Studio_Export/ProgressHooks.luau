--!strict
-- ProgressHooks (T652): glue between MatchSim events and the pure data modules Achievements, Quests, Bond and LeaderboardRules.
-- Server only. Every part sits behind its own Config flag (ACHIEVEMENTS_ON, QUESTS_ON, BOND_ON, LEADERBOARD_ON), all default OFF; with a flag off the
-- matching profile field is still loaded and clamped (so saves stay valid) but nothing is counted, paid or sent.
-- MatchService calls fields() for the profile TEMPLATE, sanitize(d) in loadProfile, start(...) per run, event(...) per sim event, flush(...) at run end.
-- Rewards are returned (gems, sp) for the caller to add to the sim; this module never touches a sim or a DataStore.

local Shared = script.Parent
local Achievements = require(Shared:WaitForChild("Achievements"))
local Quests = require(Shared:WaitForChild("Quests"))
local Bond = require(Shared:WaitForChild("Bond"))
local LeaderboardRules = require(Shared:WaitForChild("LeaderboardRules"))

local H = {}

export type Flags = { achievements: boolean?, quests: boolean?, bond: boolean?, leaderboard: boolean? }
export type Out = { gems: number, sp: number, events: { { kind: string, payload: any } } }

function H.flagsFrom(Config: any): Flags
	return { achievements = Config.ACHIEVEMENTS_ON == true, quests = Config.QUESTS_ON == true, bond = Config.BOND_ON == true, leaderboard = Config.LEADERBOARD_ON == true }
end

-- profile fields for TEMPLATE (fresh tables each call)
function H.fields(): { [string]: any }
	return { achievements = Achievements.new(), quests = Quests.new(), bond = Bond.new() }
end

-- loadProfile clamp: always runs, flags or not, so a damaged or hand-edited save cannot hold bad values
function H.sanitize(d: any)
	d.achievements = Achievements.load(d.achievements)
	d.quests = Quests.load(d.quests)
	d.bond = Bond.load(d.bond)
end

local function newOut(): Out
	return { gems = 0, sp = 0, events = {} }
end

-- opts = { userId = number?, petFaction = (petId) -> string? }
function H.start(d: any, flags: Flags, now: number, opts: any?): any
	if type(d.achievements) ~= "table" or type(d.quests) ~= "table" or type(d.bond) ~= "table" then
		H.sanitize(d) -- a profile that skipped loadProfile (QA reset) still gets valid fields
	end
	local o = opts or {}
	local ctx = { d = d, flags = flags, startedAt = now, userId = o.userId, petFaction = o.petFaction, pets = {}, factions = {}, bondN = {}, streak = 0, maxStage = 0, flushed = false, lastSubmit = nil, best = nil, lbPending = nil, notified = {} }
	if flags.quests then
		Quests.rollover(d.quests, now)
		local ids = Quests.dailyIds(d.quests.day)
		for _, q in Quests.story do
			table.insert(ids, q.id)
		end
		for _, id in ids do
			local _, _, done = Quests.status(d.quests, id)
			ctx.notified[id] = done
		end
	end
	if flags.achievements then
		Achievements.record(d.achievements, "runsPlayed", 1)
	end
	return ctx
end

local function bondBump(ctx: any, pet: string, kind: string, n: number)
	local t = ctx.bondN[pet]
	if not t then
		t = { merge = 0, bossKill = 0 }
		ctx.bondN[pet] = t
	end
	t[kind] += n
end

-- Fires the unlock / completion messages after the counters moved.
local function settle(ctx: any, out: Out)
	local d = ctx.d
	if ctx.flags.achievements then
		local fresh, gems = Achievements.unlock(d.achievements)
		for _, id in fresh do
			local a = Achievements.byId[id]
			table.insert(out.events, { kind = "Achievement", payload = { id = id, name = a.name, gems = a.gems } })
		end
		out.gems += gems
	end
	if ctx.flags.quests then
		local ids = Quests.dailyIds(d.quests.day)
		for _, q in Quests.story do
			table.insert(ids, q.id)
		end
		for _, id in ids do
			if not ctx.notified[id] then
				local have, goal, done = Quests.status(d.quests, id)
				if done then
					ctx.notified[id] = true
					table.insert(out.events, { kind = "Quest", payload = { id = id, name = Quests.byId[id].name, progress = have, goal = goal, done = true } })
				end
			end
		end
	end
end

-- One sim event. `now` is os.time()-style seconds. Returns gems / sp to add to the run and messages for the client.
function H.event(ctx: any, kind: string, p: any, now: number, tutorial: boolean?): Out
	local out = newOut()
	if tutorial or ctx.flushed or type(p) ~= "table" then
		return out
	end
	local d, f = ctx.d, ctx.flags
	local function count(stat: string)
		if f.achievements then
			Achievements.record(d.achievements, stat, 1)
		end
		if f.quests then
			Quests.record(d.quests, stat, 1)
		end
	end
	local function max(stat: string, v: number)
		if f.achievements then
			Achievements.setMax(d.achievements, stat, v)
		end
		if f.quests then
			Quests.setMax(d.quests, stat, v)
		end
	end
	if kind == "Roll" then
		if not p.bonus then
			count("rolls")
		end
		local pet = p.pet
		if type(pet) == "string" then
			ctx.pets[pet] = true
			local fa = ctx.petFaction and ctx.petFaction(pet)
			if fa then
				ctx.factions[fa] = true
				local n = 0
				for _ in ctx.factions do
					n += 1
				end
				max("factionsInRun", n)
			end
		end
		local seen = 0
		if type(d.seen) == "table" then
			for _ in d.seen do
				seen += 1
			end
		end
		max("familiarsSeen", seen)
	elseif kind == "Merge" then
		count("merges")
		if type(p.tier) == "number" then
			max("maxTier", p.tier)
		end
		if type(p.pet) == "string" then
			bondBump(ctx, p.pet, "merge", 1)
		end
	elseif kind == "Recycle" then
		count("recycles")
	elseif kind == "Upgrade" then
		count("upgrades")
		if type(p.level) == "number" then
			max("upgradeLevel", p.level)
		end
	elseif kind == "Lantern" then
		count("lanternUses")
	elseif kind == "Ult" then
		count("ultCasts")
	elseif kind == "Kill" then
		if p.kind == "Boss" then
			count("bossKills")
			for pet in ctx.pets do
				bondBump(ctx, pet, "bossKill", 1)
			end
		end
	elseif kind == "Stage" then
		if type(p.stage) == "number" then
			max("bestStage", p.stage)
		end
	elseif kind == "Clear" then
		local stage = type(p.stage) == "number" and p.stage or 0
		count("stagesCleared")
		max("bestCleared", stage)
		max("bestStage", stage)
		ctx.maxStage = math.max(ctx.maxStage, stage)
		if p.perfect then
			count("perfectStages")
			ctx.streak += 1
			max("bestStreak", ctx.streak)
			max("streak", ctx.streak)
		else
			ctx.streak = 0
		end
		if f.leaderboard and ctx.userId then
			local ok, _, res = H.submit(ctx, now)
			if ok then
				ctx.lbPending = res -- the live OrderedDataStore write is NOT built (UNVERIFIED); the accepted score waits here
			end
		end
	end
	settle(ctx, out)
	return out
end

-- Leaderboard: the best wave THIS run cleared, validated by LeaderboardRules. No DataStore write.
function H.submit(ctx: any, now: number): (boolean, string?, any?)
	if ctx.maxStage < 1 or not ctx.userId then
		return false, "Nothing to submit", nil
	end
	local run = { userId = ctx.userId, wave = ctx.maxStage, elapsed = now - ctx.startedAt, startedAt = ctx.startedAt }
	local ok, reason, res = LeaderboardRules.validate(run, { now = now, lastSubmit = ctx.lastSubmit, best = ctx.best })
	if ok then
		ctx.lastSubmit, ctx.best = now, ctx.maxStage
	end
	return ok, reason, res
end

-- Quest claim from a client request ("Quest" action, only when QUESTS_ON). The server decides; returns ok, reason, Out.
function H.claimQuest(ctx: any, id: any): (boolean, string?, Out)
	local out = newOut()
	if not ctx.flags.quests then
		return false, "Quests are off", out
	end
	local ok, reason, r = Quests.claim(ctx.d.quests, id)
	if ok and r then
		out.gems, out.sp = r.gems, r.sp
		table.insert(out.events, { kind = "QuestClaimed", payload = { id = id, gems = r.gems, sp = r.sp, bp = r.bp, lore = r.lore } })
	end
	return ok, reason, out
end

-- Run end (leave, or a new run replacing this one): bond xp for every familiar used, once.
function H.flush(ctx: any, now: number): Out
	local out = newOut()
	if ctx.flushed then
		return out
	end
	ctx.flushed = true
	if not ctx.flags.bond then
		return out
	end
	local minutes = math.floor(math.max(0, now - ctx.startedAt) / 60)
	for pet in ctx.pets do
		local n = ctx.bondN[pet] or { merge = 0, bossKill = 0 }
		local steps = { { "run", 1 }, { "minute", minutes }, { "merge", n.merge }, { "bossKill", n.bossKill } }
		for _, s in steps do
			if s[2] >= 1 then
				local ok, _, r = Bond.use(ctx.d.bond, pet, s[1], s[2], now)
				if ok and r then
					out.gems += r.gems
					if #r.levels > 0 then
						table.insert(out.events, { kind = "Bond", payload = { id = pet, level = r.level } })
					end
				end
			end
		end
	end
	return out
end

return H
