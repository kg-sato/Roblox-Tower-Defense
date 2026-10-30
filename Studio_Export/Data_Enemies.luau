--!strict
-- Balance data: Enemies (T199). Config re-exports these fields; edit the numbers here.
local D = {}

D.ENEMIES = {
	Grunt = { hp = 30, speed = 8, coins = 2, gems = 1, leak = 1, size = 2.4, color = Color3.fromRGB(110, 100, 150), armor = "flesh" },
	Swift = { hp = 18, speed = 13, coins = 2, gems = 1, leak = 1, size = 2, color = Color3.fromRGB(160, 205, 235), armor = "fog" },
	Tank = { hp = 120, speed = 5, coins = 6, gems = 3, leak = 2, size = 3.6, color = Color3.fromRGB(176, 136, 72), armor = "brass" },
	Boss = { hp = 700, speed = 4, coins = 60, gems = 25, leak = 5, size = 6.5, color = Color3.fromRGB(140, 230, 110), armor = "none" },
	-- new kinds (Design/Enemy Bible.md); they appear in waves only when Config.NEW_ENEMIES is true (the client has no model for them yet)
	Crow = { hp = 12, speed = 16, coins = 3, gems = 1, leak = 1, size = 2.2, color = Color3.fromRGB(70, 74, 86), armor = "flesh" },
	Thief = { hp = 40, speed = 11, coins = 4, gems = 2, leak = 1, size = 2.4, color = Color3.fromRGB(104, 74, 118), armor = "flesh" },
	-- Hollow Court kinds (T417): they appear in waves only when Config.HOLLOW_ENEMIES is true (the client has no models for them yet)
	Parishioner = { hp = 70, speed = 7, coins = 4, gems = 2, leak = 1, size = 2.6, color = Color3.fromRGB(96, 90, 108), armor = "hollow" },
	FogWisp = { hp = 22, speed = 14, coins = 3, gems = 1, leak = 1, size = 2, color = Color3.fromRGB(170, 190, 210), armor = "fog", eatsLamp = true },
}

return D
