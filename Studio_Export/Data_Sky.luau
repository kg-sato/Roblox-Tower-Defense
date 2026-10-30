--!strict
-- Balance data: Sky (T199). Config re-exports these fields; edit the numbers here.
local D = {}

D.SKY_EFFECTS = {
	night = { damage = { light = 0.2, shadow = 0.1 } },
	Fog = { enemySpeed = 0.92, range = -0.1 },
	Rain = { damage = { fire = -0.2 }, enemySpeed = 0.95 },
	Storm = { enemySpeed = 1.1, damage = { cosmic = 0.15 } },
	Embers = { damage = { fire = 0.2 }, enemySpeed = 1.05 },
}

return D
