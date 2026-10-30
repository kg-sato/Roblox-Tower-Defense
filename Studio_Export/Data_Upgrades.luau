--!strict
-- Balance data: Upgrades (T199). Config re-exports these fields; edit the numbers here.
local D = {}

D.UPGRADES = {
	Power = { name = "Power", desc = "+30% damage per level", per = 0.30 },
	Haste = { name = "Haste", desc = "+14% attack speed per level", per = 0.14 },
	Crit = { name = "Crit", desc = "+8% chance for 2.5x damage per level", per = 0.08 },
}
D.UPGRADE_ORDER = { "Power", "Haste", "Crit" }

return D
