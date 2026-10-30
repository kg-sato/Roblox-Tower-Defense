--!strict
-- Balance data: Combat (T199). Config re-exports these fields; edit the numbers here.
local D = {}

-- Familiar roles, damage types, armour and statuses (Design/Familiar Systems.md, Design/Enemy Bible.md). Keys are the Characters folder ids.
D.DAMAGE_TYPE = {
	Ember = "fire", Zap = "light", BrassHound = "spring", Sentinel = "brass", Frostling = "ice", Boulder = "stone",
	Ward = "light", Archivist = "brass", Mourner = "shadow", VoltFox = "cosmic", StarDrake = "cosmic", GreyVeilWraith = "shadow",
	CantorVesper = "cosmic", DameOrrery = "brass", TheLamplighter = "light", VeilWalker = "cosmic",
}
-- multiplier by armour type and damage type; anything not listed is 1
D.ARMOR_MULT = {
	brass = { fire = 0.7, ice = 1.3 },
	fog = { stone = 0.7, light = 1.3 },
	flesh = { fire = 1.2 },
	stone = { spring = 0.7, cosmic = 1.3 },
	hollow = { light = 1.3, shadow = 0.75 },
}
D.STATUS = {
	burn = { dur = 3, dps = 0.2 }, -- damage per second as a share of the hit that lit it
	chill = { dur = 2, max = 3, slow = 0.15, freeze = 0.5 }, -- 3 stacks freeze for 0.5 s (movement: needs MOVEMENT_EFFECTS)
	stun = { dur = 1, immune = 5 }, -- 5 s immunity afterwards
	mark = { dur = 4, bonus = 0.25 }, -- +25% damage from every source
	hush = { dur = 2 }, -- cancels the enemy's special move
}
-- roles: onHit statuses, every-Nth-shot bonuses, auras on touching units, armour piercing, echo and drain
D.ROLES = {
	Ember = { onHit = { "burn" } },
	Zap = { onHit = { "mark" } },
	BrassHound = { nth = { n = 5, extraHit = true } },
	Sentinel = { pierce = { "brass" } },
	Frostling = { onHit = { "chill" } },
	Boulder = { critStun = true },
	Ward = { aura = { range = 0.2 } },
	Archivist = { aura = { haste = 0.15 } },
	Mourner = { onHit = { "hush" } },
	VoltFox = { echo = 0.35 },
	StarDrake = { nth = { n = 8, splash = { radius = 8, mult = 0.5 } } },
	GreyVeilWraith = { pierce = "all", drain = { every = 10, heal = 1 } },
	-- Mythic and Celestial humans: Hymn (touching familiars +20% damage), Rewind (every 10th shot resets touching cooldowns), Kindle (every familiar +10% damage), Veil (every familiar +12% crit chance)
	CantorVesper = { aura = { damage = 0.20 } },
	DameOrrery = { rewind = { every = 10 } },
	TheLamplighter = { global = { damage = 0.10 } },
	VeilWalker = { global = { crit = 0.12 } },
	-- Epic and Legendary humans (2026-10-29): Whistle, Annotate, Lockstep, Crossing
	ConstableWren = { nth = { n = 4, splash = { radius = 6, mult = 0.6 } } },
	MadamQuill = { onHit = { "mark", "hush" } },
	CogWarden = { critStun = true, nth = { n = 6, extraHit = true } },
	FerrymanOfFog = { onHit = { "chill", "mark" }, aura = { range = 0.15 } },
}

return D
