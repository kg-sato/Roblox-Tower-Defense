--!strict
-- Balance data: Synergies (T199). Config re-exports these fields; edit the numbers here.
local D = {}

-- ===== Lantern power (T011): the player lights an area; familiars inside fire faster and harder for a while =====
D.LANTERN = { radius = 22, dur = 6, cooldown = 30, haste = 0.35, damage = 0.1 }
D.SYNERGIES = {
	{ id = "GuildGears", name = "Guild Gears", a = "Clockwork Guild", b = "Clockwork Guild", damage = 0.06 },
	{ id = "CourtVigil", name = "Court Vigil", a = "Hollow Court", b = "Hollow Court", haste = 0.06 },
	{ id = "KeepersFlame", name = "Keepers' Flame", a = "Lantern Keepers", b = "Lantern Keepers", damage = 0.04, haste = 0.04 },
	{ id = "ChoirHarmony", name = "Choir Harmony", a = "Star Choir", b = "Star Choir", damage = 0.08 },
	{ id = "LightAndSong", name = "Light and Song", a = "Lantern Keepers", b = "Star Choir", haste = 0.08 },
	{ id = "GearsAndLamps", name = "Gears and Lamps", a = "Clockwork Guild", b = "Lantern Keepers", damage = 0.05 },
}
D.SYNERGY_CAP = { damage = 0.2, haste = 0.2 }

return D
