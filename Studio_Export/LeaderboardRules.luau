--!strict
-- Weekly leaderboard rules (T025): pure functions only, no DataStore calls. The server measures `elapsed` and `wave` itself from the run's sim
-- (never from a client message), asks validate() and, if ok, writes pack(wave, secondsIntoWeek) to an OrderedDataStore named storeName(week) keyed by userId
-- (UpdateAsync with math.max so a lower score never overwrites). The live OrderedDataStore calls are NOT in this module and are untested in Studio.

export type Run = { userId: number, wave: number, elapsed: number, startedAt: number }

local L = {}

L.DAY = 86400
L.WEEK = 7 * 86400
L.MAX_WAVE = 200 -- endless mode is tested to wave 100; a run past 200 is refused until someone raises this on purpose
L.MIN_SEC_PER_WAVE = 4 -- the fastest honest wave: the lean bot averages 8 s on stage 1 at normal speed, so 4 s allows double speed
L.MAX_ELAPSED = 86400 -- one run longer than a day is not a run
L.MIN_GAP = 20 -- seconds between two submissions of one player
L.TIE_SPAN = 1000000 -- packed score = wave * TIE_SPAN + (TIE_SPAN - 1 - secondsIntoWeek)

-- Weeks start on Monday 00:00 UTC. Epoch day 0 (1970-01-01) was a Thursday, so Monday 1970-01-05 starts week 1.
function L.weekKey(now: number): number
	return math.floor((math.floor(now / L.DAY) + 3) / 7)
end

function L.weekStart(week: number): number
	return (week * 7 - 3) * L.DAY
end

function L.storeName(week: number): string
	return "WeeklyBestWave_" .. tostring(math.floor(week))
end

local function finite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

local function whole(n: any): boolean
	return finite(n) and n == math.floor(n)
end

-- Checks one finished run. ctx = { now, lastSubmit (sim-independent clock of the player's last accepted or tried submit, or nil), best (this week's stored score as a wave, or nil) }.
-- Returns ok, reason (when refused), and { week, wave, packed } when ok.
function L.validate(run: any, ctx: any): (boolean, string?, any?)
	if type(run) ~= "table" or type(ctx) ~= "table" or not finite(ctx.now) then
		return false, "Bad request", nil
	end
	if not whole(run.userId) or run.userId < 1 then
		return false, "Bad player", nil
	end
	if not whole(run.wave) or run.wave < 1 then
		return false, "Bad wave", nil
	end
	if run.wave > L.MAX_WAVE then
		return false, "Wave above the cap", nil
	end
	if not finite(run.elapsed) or run.elapsed <= 0 or run.elapsed > L.MAX_ELAPSED then
		return false, "Bad run time", nil
	end
	if run.elapsed < run.wave * L.MIN_SEC_PER_WAVE then
		return false, "Too fast for that wave", nil
	end
	if not finite(run.startedAt) or run.startedAt > ctx.now or run.startedAt < ctx.now - L.MAX_ELAPSED - run.elapsed then
		return false, "Bad start time", nil
	end
	local week = L.weekKey(ctx.now)
	if run.startedAt < L.weekStart(week) then
		return false, "Run began in an earlier week", nil
	end
	if ctx.lastSubmit ~= nil and (not finite(ctx.lastSubmit) or ctx.now - ctx.lastSubmit < L.MIN_GAP) then
		return false, "Submitting too often", nil
	end
	if ctx.best ~= nil and (not whole(ctx.best) or run.wave <= ctx.best) then
		return false, "No improvement", nil
	end
	return true, nil, { week = week, wave = run.wave, packed = L.pack(run.wave, ctx.now - L.weekStart(week)) }
end

-- OrderedDataStore needs one integer: more waves wins, then the earlier finish in the week wins.
function L.pack(wave: number, secondsIntoWeek: number): number
	local s = math.clamp(math.floor(secondsIntoWeek), 0, L.TIE_SPAN - 1)
	return wave * L.TIE_SPAN + (L.TIE_SPAN - 1 - s)
end

function L.unpack(packed: number): (number, number)
	local wave = math.floor(packed / L.TIE_SPAN)
	return wave, L.TIE_SPAN - 1 - (packed - wave * L.TIE_SPAN)
end

-- Sorts packed entries { userId, packed } best first, one row per player (their best), and numbers the ranks. Bad rows are skipped.
function L.rank(entries: any, limit: number?): { { userId: number, packed: number, wave: number, rank: number } }
	local best: { [number]: number } = {}
	if type(entries) == "table" then
		for _, e in entries do
			if type(e) == "table" and whole(e.userId) and e.userId >= 1 and whole(e.packed) and e.packed >= L.TIE_SPAN and e.packed <= L.MAX_WAVE * L.TIE_SPAN + (L.TIE_SPAN - 1) then
				if not best[e.userId] or e.packed > best[e.userId] then
					best[e.userId] = e.packed
				end
			end
		end
	end
	local rows = {}
	for id, packed in best do
		table.insert(rows, { userId = id, packed = packed, wave = math.floor(packed / L.TIE_SPAN), rank = 0 })
	end
	table.sort(rows, function(a, b)
		if a.packed ~= b.packed then
			return a.packed > b.packed
		end
		return a.userId < b.userId
	end)
	local out = {}
	for i, r in rows do
		if limit and i > limit then
			break
		end
		r.rank = i
		table.insert(out, r)
	end
	return out
end

return L
