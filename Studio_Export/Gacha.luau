--!strict
-- Gacha rules (P3 roll floor, P2 chosen guarantee with Lantern Oil). Pure data and functions; MatchSim calls them, the server owns the state.
-- State (saved in the profile as `gacha`, never reset by a run, a stage or a banner change): { oil, sinceRare, claims }.
--   sinceRare: rolls since the last Rare or better. At FLOOR_EVERY - 1 the next roll is forced to Rare or better (P3_ROLL_FLOOR).
--   oil: Lantern Oil, +1 per counted roll, earned only, never sold, never expires. OIL_NEED buys one chosen Rare-or-better familiar (P2_CHOSEN_GUARANTEE).
-- Each feature sits behind its own Config flag (default OFF); with a flag off its counter is not touched.

export type State = { oil: number, sinceRare: number, claims: number }

local Gacha = {}

Gacha.FLOOR_EVERY = 10 -- one Rare or better in every 10 rolls
Gacha.OIL_NEED = 100 -- Lantern Oil for one chosen familiar
Gacha.OIL_MAX = 1000000
Gacha.CLAIMS_MAX = 1000000
Gacha.MIN_CLAIM_ORDER = 2 -- Rarities with order >= 2 (Rare and up) can be chosen

function Gacha.new(): State
	return { oil = 0, sinceRare = 0, claims = 0 }
end

local function clean(n: any, hi: number): number
	if type(n) ~= "number" or n ~= n or n < 0 then
		return 0
	end
	return math.min(math.floor(n), hi)
end

-- Clamp a saved value (also the profile migration: a profile from before this field gets a fresh state).
function Gacha.load(d: any): State
	local s = Gacha.new()
	if type(d) == "table" then
		s.oil = clean(d.oil, Gacha.OIL_MAX)
		s.sinceRare = clean(d.sinceRare, Gacha.FLOOR_EVERY - 1)
		s.claims = clean(d.claims, Gacha.CLAIMS_MAX)
	end
	return s
end

-- True when the next roll must be Rare or better.
function Gacha.floorDue(g: State): boolean
	return g.sinceRare >= Gacha.FLOOR_EVERY - 1
end

-- Rolls left until the floor fires (1 means the next roll).
function Gacha.rollsToFloor(g: State): number
	return math.max(1, Gacha.FLOOR_EVERY - g.sinceRare)
end

-- Weighted pick among `names` using `weights`; r01 is a uniform number in [0, 1). Falls back to the last name.
function Gacha.weightedPick(weights: { [string]: number }, names: { string }, r01: number): string
	local total = 0
	for _, n in names do
		total += weights[n] or 0
	end
	local x = r01 * total
	for _, n in names do
		x -= weights[n] or 0
		if x < 0 and (weights[n] or 0) > 0 then
			return n
		end
	end
	return names[#names]
end

-- Counts one finished roll. `order` is the rarity order of what was pulled (1 = Common). Only the features that are on move their counter.
function Gacha.afterRoll(g: State, order: number, floorOn: boolean, oilOn: boolean)
	if floorOn then
		g.sinceRare = order >= 2 and 0 or math.min(g.sinceRare + 1, Gacha.FLOOR_EVERY - 1)
	end
	if oilOn then
		g.oil = math.min(g.oil + 1, Gacha.OIL_MAX)
	end
end

function Gacha.canClaim(g: State): boolean
	return g.oil >= Gacha.OIL_NEED
end

-- Spends the oil. Call only after canClaim and after every other check passed.
function Gacha.spend(g: State)
	g.oil -= Gacha.OIL_NEED
	g.claims = math.min(g.claims + 1, Gacha.CLAIMS_MAX)
end

-- What the client may show (read only data; the server never trusts a value coming back).
function Gacha.snapshot(g: State, floorOn: boolean, oilOn: boolean): { [string]: any }
	return {
		floorOn = floorOn,
		floorEvery = Gacha.FLOOR_EVERY,
		sinceRare = g.sinceRare,
		rollsToFloor = Gacha.rollsToFloor(g),
		oilOn = oilOn,
		oil = g.oil,
		oilNeed = Gacha.OIL_NEED,
		oilReady = oilOn and Gacha.canClaim(g),
		claims = g.claims,
	}
end

return Gacha
