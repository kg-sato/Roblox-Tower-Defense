--!strict
-- Balance data: Waves (T199). Config re-exports these fields; edit the numbers here.
local D = {}

D.ELITE = { first = 8, every = 4, max = 4, hp = 3, speed = 0.9, coins = 3, gems = 2 }
D.MOD_FIRST = 4
D.WAVE_MODIFIERS = {
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

return D
