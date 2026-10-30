--!strict
-- Balance data: Bosses (T199). Config re-exports these fields; edit the numbers here.
local D = {}

D.BOSSES = {
	{ id = "Unbound", name = "The Unbound", hpMult = 1.0, rewardMult = 1.0, phases = {
		{ at = 1, banner = "A bank of fog", fx = { deny = { every = 10, dur = 1.5 } } },
		{ at = 0.66, banner = "It rises", fx = { deny = { every = 6, dur = 1.5 } } },
		{ at = 0.33, banner = "The cloak falls", fx = { deny = { every = 6, dur = 1.5 }, speedMult = 1.2 } },
	} },
	{ id = "Automaton", name = "The Clockmaker's Automaton", hpMult = 1.3, rewardMult = 1.6, phases = {
		{ at = 1, banner = "The gears wind", fx = { slowAura = { radius = 12, slow = 0.15 }, regen = { every = 8, pct = 0.03 } } },
		{ at = 0.66, banner = "A bargain is offered", fx = { slowAura = { radius = 12, slow = 0.15 }, freeze = { every = 14, dur = 3 }, lamp = { every = 14, heal = 1 } } },
		{ at = 0.33, banner = "The gears overheat", fx = { slowAura = { radius = 12, slow = 0.25 }, speedMult = 1.15 } },
	} },
	{ id = "Echo", name = "The Star Choir's Echo", hpMult = 1.4, rewardMult = 2.0, phases = {
		{ at = 1, banner = "One voice", fx = { deny = { every = 9, dur = 2 }, push = { every = 9, dist = 6, count = 1 } } },
		{ at = 0.66, banner = "The echoes answer", fx = { deny = { every = 9, dur = 2 }, push = { every = 9, dist = 6, count = 2 }, summon = { every = 10, kind = "Swift", count = 2 } } },
		{ at = 0.33, banner = "A chord", fx = { slowAura = { radius = 10, slow = 0.25 }, summon = { every = 10, kind = "Swift", count = 2 } } },
	} },
	{ id = "Regent", name = "The Hollow Court Regent", hpMult = 1.3, rewardMult = 2.5, phases = {
		{ at = 1, banner = "The bell tolls", fx = { summon = { every = 12, kind = "Grunt", count = 3 } } },
		{ at = 0.66, banner = "The candles are lit", fx = { damageTaken = 0.85, candles = { count = 7, every = 2, per = 0.08, min = 0.4 }, summon = { every = 12, kind = "Grunt", count = 2 } } },
		{ at = 0.33, banner = "The crown burns down", fx = { speedMult = 2.0 } },
	} },
	{ id = "Clockmaker", name = "The Clockmaker", hpMult = 1.2, rewardMult = 4.0, phases = {
		{ at = 1, banner = "Behind its own clock", fx = { deny = { every = 12, dur = 2 }, unmerge = { every = 20 } } },
		{ at = 0.66, banner = "Time stops", fx = { freeze = { every = 20, dur = 3 } } },
		{ at = 0.33, banner = "The hands run backwards", fx = { regen = { every = 6, pct = 0.02 }, speedMult = 1.1 } },
	} },
}

return D
